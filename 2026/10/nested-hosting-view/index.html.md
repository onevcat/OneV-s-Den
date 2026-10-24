---
layout: post
title: "被拆掉的 NSHostingView 还会再建一次 View"
date: 2026-10-24 15:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, swiftui, appkit, 调试]
typora-root-url: ..
---

最近 [Prowl](https://prowl.cat/) 里出了一个有点诡异的 bug：切换到 Canvas 视图时，进入前选中的那个 tab，它在 Canvas 上对应的卡片是一片空白。其他卡片都好好的，切回 Default 或者 Shelf 视图，那个终端也完全正常，里面的 agent 该干嘛还在干嘛。只是 Canvas 上那一格，什么都画不出来。

最后的修复只有几行代码，但排查过程比预想中麻烦得多。尤其是中间发现了一件我之前完全没意识到的事：SwiftUI 居然会在一个 view 已经被 dismantle 之后，又去调用它下面的 makeNSView。这直接给人干懵了...甚至我第一次实际看到日志的时候，还以为是自己打错了。

最后踩到的根源是 SwiftUI 和 AppKit 混用时的一个生命周期问题，这里把排查过程记一下。

## Surface 和它的宿主

先简单介绍一下 Prowl 里终端是怎么显示的。每个终端 pane 背后是一个 `GhosttySurfaceView`，它是一个长寿的 `NSView`，持有 Ghostty 的 surface 和背后的 shell 进程。用户在不同视图之间切换时，这个 view 本身不会重建，而是在不同的“宿主”之间搬家：

- Default 和 Shelf 视图里，宿主是普通的 terminal host；
- Canvas 视图里，每张卡片也有一个自己的 canvas host。

宿主就是一个包了一层 scroll view 的 `GhosttySurfaceScrollView`，通过 `NSViewRepresentable` 放进 SwiftUI 里。它的 `init` 很直白，把 surface 拿过来，放进自己的 document view：

```swift
init(surfaceView: GhosttySurfaceView, hostKind: HostKind) {
  // ...
  documentView.addSubview(surfaceView)
  surfaceView.scrollWrapper = self
}
```

`addSubview` 会把 surface 从之前的父 view 上摘下来，所以“最新建出来的宿主拿走 surface”就是默认行为。为了防止新旧宿主你争我夺，今年四月我们还加过一条所有权规则：宿主之后在 `updateNSView` 里尝试重新挂载 surface 时，绝不从另一个活着的宿主（比如 Canvas）手里抢；terminal host 只领养没人要的 surface。这条规则让 Canvas 进出时的各种白屏消停了好几个月。

## 多出来的一个宿主

这个 bug 在我日常用的 Prowl 里就能稳定复现。先在宿主的 `init`、`viewDidMoveToWindow` 和 dismantle 里加上日志，切换到 Canvas 时的顺序大概是：

```
canvas host make        (拿走 surface)
terminal host dismantle (原来的 terminal 宿主退场)
terminal host make      (!? 又建了一个 terminal 宿主，拿走 surface)
```

看到第三行的时候就觉得不对了：原来的 terminal host 都已经 dismantle 了，怎么又 make 了一个？更糟糕的是，这个新建出来的 host 还真的把 surface 抢走了。Canvas 那边刚拿到 surface，转眼就被一个根本不会出现在屏幕上的 view 截胡。

到这里，白屏的直接原因完整找到了，我也可以做一个基本的修复了：比如用更清晰的 surface 所有权来避免被抢。但为什么退场的 view 树还会创建新 host，完全没有头绪。

## 先二分，结果被快捷键坑了

Prowl 是按日期发版的，旧版本的 Release 包都在 GitHub 上，可以用 `CFFIXED_USER_HOME` 配合独立的 socket，隔离地并排跑起来。于是我开始拿各个版本做二分查找。

但是第一轮二分就翻车了 😂。

明明当前版本可以稳定复现，往前找了几个版本却怎么测都是好的。更离谱的是，有些版本按代码来看明明已经包含了问题，实际跑起来却一点事没有。折腾了一阵才发现，问题出在重现方式上：平时复现是点侧边栏切换 Canvas，二分的时候为了省事，一直在按快捷键 ⌘⌥↩。

点控件和用 `prowl canvas show` 每次都能复现，但快捷键一次都不会。这就更诡异了：两条路径都是改同一个状态，但是背后的 view 刷新的顺序出现了不同！

换成点控件重新二分以后，结果很快收敛到一个 commit：给 SSH 远程 agent 加了一个小角标 `RemotePaneBadge`，作为 overlay 放在每个终端 pane 的右下角。

```swift
GeometryReader { _ in
  GhosttyTerminalView(surfaceView: surfaceView)
    // ...
    .overlay(alignment: .bottomTrailing) {
      RemotePaneBadge(indicator: surfaceView.bridge.state.remoteIndicator)
    }
}
```

讲道理的话，这个小角标和终端宿主没有任何关系，光看代码，我也完全想不出它怎么会让退场的 view 树多建一个宿主。这种和 pane 生命周期毫无关联的改动，相当难排查和确认，这也是为什么在该版本中完全没想过测这部分的原因：鬼才能想到加一个 overlay 会把宿主的生命周期也改了？

## `.task` 的嫌疑

我把 `RemotePaneBadge` 的内容换成各种最简单的东西，每个变体单独编译、各跑两次，看多出来的 make 还会不会出现：

| badge 的内容 | 多出来的宿主 |
|---|---|
| `EmptyView()` | 无 |
| `Color.clear` | 无 |
| `Color.clear.onAppear {}` | 无 |
| `Color.clear.onDisappear {}` | 无 |
| `Color.clear.task {}` | **有** |
| `Color.clear.task(id: indicator) {}` | **有** |

一个空的 `.task {}` 就能触发。`RemotePaneBadge` 里正好有一个 `.task(id:)`，用来给动画计时。

但“加一个 `.task` 就会多调用一次 `makeNSView`”，这怎么想都说不通。于是在多出来的那次 `makeNSView` 里打了调用栈：

```
GhosttyTerminalView.makeNSView(context:)
PlatformViewRepresentableAdaptor.makeViewProvider(context:)
PlatformViewChild.updateValue()
...
GeometryReaderLayout.placeSubviews(in:proposal:subviews:cache:)
...
AnimatableFrameAttribute.updateValue()
...
GraphHost.flushTransactions()
NSHostingView.beginTransaction()
```

外层的 `body` 并没有重新求值。是某个 `NSHostingView` 在 flush 事务时做布局，要算 `GeometryReader` 子 view 的 frame，发现子 view 的 platform view 还没建，就现场建了一个。这时候的 `LeafView`（包含终端和角标的那一层）也已经是 `@identity changed` 的新实例，不是原来那个了。

## 嵌套的 NSHostingView

这个 `NSHostingView` 在 split 树的外面一层。为了让 VoiceOver 之类的辅助功能能按顺序遍历各个 pane，Prowl 的 split 树外面包了一个 `NSViewRepresentable`，它是一个带 `AXSplitGroup` 角色的 AppKit view，里面再用 `NSHostingView` 托管真正的 SwiftUI split 树：

```swift
struct TerminalSplitTreeAXContainer: NSViewRepresentable {
  func makeNSView(context: Context) -> TerminalSplitAXContainerView {
    TerminalSplitAXContainerView()
  }

  func updateNSView(_ nsView: TerminalSplitAXContainerView, context: Context) {
    nsView.update(rootView: TerminalSplitTreeView(/* ... */), panes: /* ... */)
  }
}

final class TerminalSplitAXContainerView: NSView {
  private var hostingView: NSHostingView<TerminalSplitTreeView>?

  func update(rootView: TerminalSplitTreeView, panes: [GhosttySurfaceView]) {
    if let hostingView {
      hostingView.rootView = rootView
    } else {
      let hostingView = NSHostingView(rootView: rootView)
      addSubview(hostingView)
      // 用约束撑满 ...
      self.hostingView = hostingView
    }
    // 设置 accessibility 信息 ...
  }
}
```

SwiftUI 套 AppKit，AppKit 里再套 SwiftUI。要自定义 accessibility、接管某些 AppKit 事件，或者在 SwiftUI 里用 `NSSplitView` 的时候，经常会这么写。但里面这个 `NSHostingView` 是一个独立的 SwiftUI 宿主，graph 和布局循环都是它自己的。外层 SwiftUI 拆掉 `TerminalSplitTreeAXContainer` 时会调用 `dismantleNSView`，可在 AppKit 这边，container view 要稍后才会真正移出 window。这段时间里，内层的 `NSHostingView` 还挂在 window 上，手里也还握着那个 `rootView`。

调用栈也对得上：外层 dismantle 时，内层的内容 subgraph 先被作废（`AG::Subgraph::invalidate_now` → `PlatformViewChild.destroy`，也就是原来的 terminal host 被 dismantle）；紧接着在下一次 run loop observer 回调里，内层 `NSHostingView` 开始 flush 事务，它根据保存的 `rootView` 把内容重新实例化了一遍，于是对一棵已经在退场的树又调用了一次 `makeNSView`。

结论就是，**一个嵌套在 `NSViewRepresentable` 里的 `NSHostingView`，在外层已经调用过 `dismantleNSView` 之后，还会把自己的 root view 重新建一遍**，这比较反直觉，应该是个 SwiftUI 的 bug 或者没有仔细考虑的地方。

## 最小复现

为了确认这是 SwiftUI 的行为，而不是 Prowl 哪里写得有蹊跷，我写了一个和 Prowl 完全无关的最小 sample，放在 [onevcat/NestedHostingViewRepro](https://github.com/onevcat/NestedHostingViewRepro)。结构和 Prowl 一一对应：

```swift
struct Root: View {
  let model: Model
  var body: some View {
    if model.showsCanvas {
      Leaf(name: "canvas")
    } else {
      NestedHost(model: model)  // 返回 NSHostingView<Pane> 的 NSViewRepresentable
    }
  }
}
```

`Pane` 里是一个 `GeometryReader` 包着的 `Leaf`，`Leaf` 的 `makeNSView` 返回一个 `Wrapper`，它在 `init` 里把一个全局共享的 `NSView` 加为自己的 subview，模拟终端 surface 的搬家。把 `showsCanvas` 设成 `true` 以后：

```
make canvas#2 (takes the shared view from terminal#1)
dismantle NestedHost inWindow=true
dismantle terminal#1 inWindow=true
make terminal#3 (takes the shared view from canvas#2)
RESULT FAIL: holder=terminal#3 inWindow=false
```

和 Prowl 里一模一样。`Pane` 只存在于内层 `NSHostingView` 的 root view 里，所以这个 `terminal#3` 只能是内层 graph 建出来的。sample 里提供了几个开关，结果如下：

| 配置 | 结果 |
|---|---|
| 嵌套 `NSHostingView`，`.task`、状态变化、约束容器的所有组合 | 8/8 失败 |
| 不嵌套，`Pane` 直接放进 `Root` | 通过 |
| 嵌套，但在 `dismantleNSView` 里拆掉内层 `NSHostingView` | 通过 |

sample 里有没有 `.task` 都无所谓，只要嵌套就 100% 复现。sample 的布局很简单，退场的 hosting view 每次都会碰上一次要算子 view frame 的布局。Prowl 的 view 树复杂得多，平时那次 flush 不会去要 leaf 的几何信息，加了 `.task` 才会。所以 `.task` 只是让问题露了出来，根子在嵌套上。至于 `.task` 为什么会让 flush 去算 leaf 的 frame，调用栈里只能看到最后走到了 `AnimatableFrameAttribute`，我没找到公开的解释，也就没再往下挖。

回过头重新梳理，原先的 bug 应该是两个问题叠在了一起。一个是 SwiftUI 的行为：外层 representable 被 dismantle 之后，嵌套的 `NSHostingView` 只要还在 window 里，就照常更新，该重建 root view 就重建，该调用 `makeNSView` 就调用。在 AppKit 看来它只是一个还挂在 window 上的普通 view，并不知道外面的 SwiftUI 已经不要它了。另一个是我自己的实现把它放大了：宿主的 `init` 无条件拿走 surface，一次多余的 make 就有了实际的副作用；Canvas 宿主又不会主动收回，这个副作用也就一直留着。

前一个我觉得值得报告：`dismantleNSView` 都调用过了，下面的内容就不该再被建出来。sample 已经附在 Feedback 里报给了 Apple，算 bug 还是 by design，让他们判断吧。

## 修复

修复分两部分，都在 [PR #987](https://github.com/onevcat/Prowl/pull/987) 里。

### dismantle 时拆掉内层 hosting view

内层 `NSHostingView` 在外层 dismantle 之后还活着，那就在外层的 `dismantleNSView` 里把它从 view 树上拿掉并释放：

```swift
struct TerminalSplitTreeAXContainer: NSViewRepresentable {
  // ...
  static func dismantleNSView(_ nsView: TerminalSplitAXContainerView, coordinator: ()) {
    nsView.detachHostingView()
  }
}

extension TerminalSplitAXContainerView {
  func detachHostingView() {
    hostingView?.removeFromSuperview()
    hostingView = nil
  }
}
```

`NSHostingView` 一旦离开 window，就不会再 flush 事务，里面的 terminal host 也会随之正常 dismantle，不会有第二次 make。sample 里加上 `--detach` 开关后所有组合都能通过；在 Prowl 里，在没有下面第二部分修复的情况下单独加这几行，多出来的宿主从 3/3 次出现降到 0 次，Canvas 卡片 3/3 次正常显示。

如果你的项目里也有 `NSViewRepresentable` 套 `NSHostingView` 的写法，建议也补上这样一个 `dismantleNSView`，就几行的事。

### 让 window 里的宿主把 surface 要回来

只堵这一条路径，我还是不太放心。SwiftUI 什么时候会对一棵退场的树调用 `makeNSView`，我们控制不了，这次是 split 树外面的 AX 容器，下次可能是别的地方。所以 surface 的所有权规则自己也得能恢复过来。

原来的规则是“不从活着的宿主手里抢”，而“活着”只看 surface 有没有父 view。这次偏偏是 surface 有父 view，但那个父 view 已经不在任何 window 里了。所以规则改成了以 window 为准：

```swift
func ensureSurfaceAttached(requiresLiveHost: Bool = true) {
  // ...
  // A terminal host adopts an orphaned surface. A host in a window also takes the
  // surface back from a host outside every window.
  let isOrphaned = hostKind == .terminal && surfaceView.superview == nil
  let isStranded = window != nil && surfaceView.window == nil
  guard isOrphaned || isStranded else { return }
  // ...
}
```

另外，每个宿主在 `init` 里把自己登记到 surface 的一个弱引用表里。surface 在 `viewDidMoveToWindow` 发现自己离开了 window 时，就去问这些宿主里有没有还在 window 中的，有的话就让它把自己接回去：

```swift
private let hosts = NSHashTable<GhosttySurfaceScrollView>.weakObjects()

private func returnToLiveHost() {
  guard window == nil, !isPendingClose else { return }
  for host in hosts.allObjects where window == nil && host.window != nil {
    host.ensureSurfaceAttached()
  }
}
```

这样以后 SwiftUI 再多建出一个宿主，surface 被它带出 window 之后，也会马上回到还在 window 里的宿主手中。两个都在 window 里的宿主之间还是不会互相抢，正在关闭的 surface 也不会被挂回去。

## 最后

`makeNSView` 被调用，不代表这个 view 会出现在屏幕上。SwiftUI 从没这样承诺过，这次它甚至给一棵已经退场的树调用了 `makeNSView`。所以**在 `makeNSView` 或者 view 的 `init` 里改外部共享状态（比如把一个长寿的 view 抢过来）是有风险的**。稳妥一点的做法还是等进了 window 再接管，或者像这次一样，让所有权规则能自己恢复。嵌套的 `NSHostingView` 也是同样的道理：外层的 dismantle 管不到它，要在 `dismantleNSView` 里自己拆。

这次从定位、二分、变体实验到写最小 sample，大部分是 agent 在一个隔离的 Prowl 实例里自己跑的，我主要是在几个节点上多问了几句“为什么”。要是当时改完所有权规则、看到 Canvas 不白了就收工，那嵌套 `NSHostingView` 的问题大概会一直留在那里，等下一个 `.task` 把它再翻出来。至少现在我们比较有信心，能说这个行为不会再导致更多问题了！
