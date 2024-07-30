---
layout: post
title: "Swift 6 适配的一些体会以及对现状的小吐槽"
date: 2024-07-30 22:00:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, kingfisher, 开发者体验, 编程语言,编译器]
typora-root-url: ..
---

最近对手上的两三个项目进行了 Swift 6 的迁移，整体过程并不算顺利，颇有一种梦回 Swift 3 的感觉。不过，最终还是有所收获和心得。趁着记忆还新鲜，我想稍微总结一下。此外，针对目前社区里的一些声音，以及自己这些年的感受，我会在文章后半部分对 Swift 生态进行一些不太重要的小唠叨。


## Swift 6 迁移

Swift 6 的最大“卖点”当然是并发编程和编译时就能保证的完全线程安全，这也是在进行 Swift 6 迁移时开发者工作量最大的来源。通过引入一系列语言工具 (主要是 actor 隔离和 Sendable 标注)，Swift 6 在开启完全的严格并发检查 (也就是`-strict-concurrency=complete`) 时，理想状态下可以完全确保在编译阶段就将数据竞争 (data race) 和线程问题排除掉。

关于 Swift 并发编程，我之前写过一些关于[并发初步](https://onevcat.com/2021/07/swift-concurrency/)以及[结构化并发](https://onevcat.com/2021/09/structured-concurrency/)的文章。对于 actor、Sendable 的概念及其如何确保数据竞争不再发生，我在[《Swift 异步和并发》](https://objccn.io/products/async-swift)中也有所介绍。近几年的 WWDC 上，Apple 通过[若干](https://developer.apple.com/videos/play/wwdc2021/10133/) [session](https://developer.apple.com/videos/play/wwdc2022/110351/)，向开发者介绍了这些概念。这些内容并不是本文的重点，而且我会假设你已经了解了这些内容，并正打算对你的项目进行 Swift 6 的迁移。

在进行迁移时，最好的阅读材料显然是官方的 [Migrating to Swift 6 文档](https://www.swift.org/migration/documentation/migrationguide/)。如果你没有时间仔细通读所有话题，至少你应该逐条确认 [Common Compiler Errors](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/commonproblems) 和 [Incremental Adoption](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/incrementaladoption) 这两篇指南里的内容，只要你理解了背后的故事，它们应该可以帮你正确完成绝大部分工作。

## 迁移体会

**结论先行：**Swift 6 的迁移并不算是乐事，但由于 Apple 明确表示 Swift 6 是可选择的，并且编译器级别依然提供对 Swift 4 及以上版本的兼容选项，所以大多数项目并没有迫切需要进行迁移。此外，可以看出无论是 Apple 官方还是社区，其实都没有完全准备好进行迁移：大量的官方框架和类型缺乏 Sendable 标记，部分使用例没有特别好的对应办法等。虽然迁移可能带来一些诱人的好处，但所需的投入成本也相当可观。因此，如果你还在犹豫是否要现在就进行迁移，我个人建议可以再等一两年。

不过，因为有这样的选择，如果不做任何改变，你会发现现写的代码在未来迁移时会变成“技术债”。因此，我推荐的方式是，如果要编写新代码，不妨将其引入新的 target 中，并开始按照 Swift 6 以及严格并发模型的写法进行书写。这样在未来需要迁移时，就不至于在新代码上也要重复工作。

**迁移体会：**如果你的项目有一定规模，当你首次将 `-strict-concurrency` 选项设置为 complete 时，必然会遇到一大堆错误。不过，这甚至还不是最让人沮丧的时刻。勾选“Continue building after errors”选项，并按编译器提示修改几处错误后，你可能会发现错误数量不仅没有减少，反而增加了。这往往是最绝望的时刻。然而，只要坚持下去，你会发现需要做的事情其实相对重复且单调。对于普通的 app 来说，主要任务无外乎以下三项：

- 添加 `@MainActor`
- 标记 `Sendable`
- 将回调函数改写成 async，并考虑在哪里加 `Task` 作为异步入口

如果你已经准备好现在就进行迁移，下面的一些小心得可能对你有帮助。这些心得不仅是对上面提到的三个任务的解释，也是对官方指南的补充。如果你还没有决定迁移，确实可以再等一段时间：因为无论是官方还是社区，目前都缺乏实际的迁移经验，有些工具甚至还未准备就绪。在未来很长一段时间内，Swift 编译器肯定会继续提供对 Swift 5 的版本兼容。你只需对新代码进行适配，而对于老代码，我们还有足够的时间进行观察。

## 一些小心得

### @MainActor，后向兼容和确保 main queue

View、View Controller 以及 UIKit 的其他类型都默认添加了 `@MainActor`。如果你需要在其他非 MainActor 部分的代码中调用它们，要么需要使用 `Task`，要么需要为自己的代码也添加 `@MainActor`，以确保同样的隔离域。而进一步，调用你自己的被标记为 `@MainActor` 代码的地方可能也要做出同样的选择：要么开始一个 `Task`，要么将自己添加到 Main Actor 隔离域中去。从某种意义上来说，`@MainActor` 会在项目中“传染”。

从安全角度看，这种“传染”是合理的：主线程安全可以说是 UI 应用中最重要的线程安全问题之一。但如果你准备迁移的是一个比较底层的模块，并需要为某些方法标记 `@MainActor`，这种“传染”将会立即造成问题：依赖这个模块的用户必须被迫立即做出选择，否则编译器会报错。当你无法决定其他模块的迁移计划时（在稍大一些的团队协作项目中，这种情况很常见），保留原来的方法，只是将它标记为“弃用”，并同时提供一个新的标记为 `@MainActor` 的方法，是相对现实的做法。

```swift
@available(*, deprecated, message:"Use the main actor version.")
func myMethod() {
  // 避免重复，将原实现移到 myMethodOnMain 中
  // 不过因为我们从原先的非 Main Actor 环境里调用了 Main Actor 里的方法，会编译报错
  myMethodOnMain()
}

@MainActor func myMethodOnMain() {
  // ..其他被隔离在 MainActor 中的 UI 操作
}
```

但 `myMethod` 里的调用标记为 `@MainActor` 的 `myMethodOnMain` 也是无法成功的，我们需要一些额外手段来绕开编译器的过于严格的机制。官方给出的方式是 [`MainActor.assumeIsolated`](https://developer.apple.com/documentation/swift/actor/assumeisolated(_:file:line:))：

```swift
func myMethod() {
  MainActor.assumeIsolated {
    myMethodOnMain()
  }
}
```

`assumeIsolated` 当然可以同步地给我们一个 main actor 隔离域，但是这完全依赖于开发者的判断。如果不小心从其他隔离域（或者说，main thread 以外）进行调用，那就直接 crash 了。更温柔一点的做法是使用 [`assertIsolated`](https://developer.apple.com/documentation/swift/actor/assertisolated(_:file:line:))：来让调用者在开发时得到一些提示：

```swift
func myMethod() {
  MainActor.assertIsolated("This method is expected to be called in main thread!")
  // ...
}
```

然而，单靠 `assertIsolated` 仍无法解决 `myMethodOnMain` 调用的问题。在实践中，对于 Main Actor，我们可以结合这两者，并加上线程判断，写一个临时方法。这样既能在迁移过程中对非主线程的调用进行断言（assert），又能尽量保持原有代码的正常运行。例如：

```swift
extension MainActor {
  static func runSafely<T>(_ block: @MainActor () -> T) throws -> T {
    if Thread.isMainThread {
      return MainActor.assumeIsolated { block() }
    } else {
      MainActor.assertIsolated("This method is expected to be called in main thread!")
      return DispatchQueue.main.sync {
        MainActor.assumeIsolated { block() }
      }
    }
  }
}
```

不过需要特别说明，这种方式并不是特别安全。为了确保在主线程上执行并获取返回值，我们只能使用 `DispatchQueue.main.sync`，但这样实际上很容易导致死锁：

```swift
DispatchQueue.global().async {
  try? MainActor.runSafely {
    DispatchQueue.main.sync { print("hello") }
  }
}
```

只要我们在 `runSafely` 里再次向主队列提交一个 `sync` 操作，就会导致严重的问题。如果项目中没有使用主队列的 `sync` 操作，那么这种方式可以作为过渡时期的暂行手段。但一旦迁移完成，最好尽快删除这样的代码：actor 隔离和 Dispatch queue 的隔离天然不兼容。


### Sendable class 以及 @unchecked Sendable

对于能够轻松标记为 `Sendable` 的类型，比如只含有值类型变量的 struct 或者只含有值类型关联值的 enum，添加 `Sendable` 是无痛的。但是，对于大部分的 class，只要其中含有 var 变量，编译器就无法将它接受为 `Sendable`。在这种情况下，如果我们确实希望这个 class 类型可以跨越隔离域，我们只能在类型内部实现线程安全机制。

对于 class 内部的变量，实现线程安全最简单和直接的方式莫过于加锁。如果你的项目是从 iOS 16 开始的，那么使用 [`OSAllocatedUnfairLock`](https://developer.apple.com/documentation/os/osallocatedunfairlock) 应该是一个不错的选择。它提供的 `withLock` 闭包让开发者可以用相对安全和先进的语法操作锁的生命周期。将你的 class 中的 var 都替换成带有 `OSAllocatedUnfairLock` 的 let 后，整个 class 就可以是 Sendable 的了：

```swift-diff
enum State: Sendable {
    case yes
    case no
}

final class A: Sendable {
-    var state: State
+    let state: OSAllocatedUnfairLock<State>
    
    init(state: State) {
-        self.state = state
+        self.state = OSAllocatedUnfairLock(initialState: state)
    }
    
    func update(newState: State) {
-        state = newState
+        state.withLock { state in
+            state = newState
+        }
    }
}
```

如果你还需要兼容 iOS 16 之前的系统，那么可以选择其他的锁，或者是更传统的用 dispatch queue 来隔离访问：

```swift

private let queue = DispatchQueue(label: "private queue")
var _state: State
var state: State {
  get { queue.sync { _state } }
  set { queue.sync { _state = newValue } }
}
```

但是这样的后果是，我们只能将这个类标记为 `@unchecked Sendable`。添加 `@unchecked Sendable` 并不是一件值得羞耻的事情，这相当于将以前只能写在文档中的“该类型是线程安全的”声明明确地告诉编译器。然而，这确实阻止了编译器在我们对这个类进行后续变更时进行提醒和检查。此外，基于队列的方式也可能带来一些性能问题，还需要继续观察。如果有条件，依赖加锁或者进一步尝试使用 actor，仍然会是更优的解决方案。

### 尽量避免 Sendable 的回调

项目中 async 普及之前，一定会有大量遗留的基于 completion handler 的代码。而在适配 Swift 6 时，也经常会遇到需要将某个闭包 (closure) 标记为 `@Sendable` 的情况。对于在 escaping closure 里使用了非 Sendable 的变量的情况而言，编译器确实无法判断 closure 是否跨越了隔离域，而如果我们能人为保证这一点的话，就可以通过为闭包添加 `@Sendable` 来给编译器提示。

但是和 `@MainActor` 的情况类似，闭包的 `@Sendable` 标记也很容易在项目里"传染"。而这带来了更多的需要检查的 case，以及更多原本不必要的 `Sendable` 类型适配。为了避免这种不必要的“跨域”，一个可行方法是尽量用 async 来重写这些带回调的方法。把在不同 actor 间切换 (即 actor hopping) 的工作交给运行时 (runtime) 来解决，这样我们可以省去很多标记 `@Sendable` 闭包的额外工作。

### deinit 问题

关于 deinit 的隔离问题，早在 2021 年 Swift 并发刚推出时就已在[社区中展开了讨论](https://forums.swift.org/t/deinit-and-mainactor/50132)：当前 deinit 是无法被 actor 隔离的。因为 deinit 是一个运行时的特性，可能发生在不同线程，因此在编译器层面无法确定 `deinit` 的隔离域。这导致了一些在 Swift 5 时代时没有问题的代码 (其实严格来说，是有数据安全问题的)，在 Swift 6 时代却没办法书写。在 `deinit` 中，我们一般会进行类似资源释放，如果 `deinit` 里用到了 actor 实例中的被隔离的存储属性，它就将无法被用在 `deinit` 里。[官方文档](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/commonproblems#Non-Isolated-Deinitialization)中当前给出的方法是把需要隔离的值捕获到一个 `Task` 里：

```swift
actor BackgroundStyler {
    private let store = StyleStore()

    deinit {
        // no actor isolation here, so none will be inherited by the task
        Task { [store] in
            await store.stopNotifications()
        }
    }
}
```

但是如果 `StyleStore` 不是 Sendable 的话，这个方法也无法绕开 `deinit` 限制。特别是如果我们想要在 `deinit` 里清理的类型不属于我们自己，而是引用了其他框架中的非 Sendable 类型时，几乎就束手无策了。

一种变通方法是利用 `withoutActuallyEscaping` 来["欺骗"编译器](https://github.com/onevcat/Kingfisher/blob/ee44579d71cf7ad21046b829aed074c0229a6ec6/Sources/Views/AnimatedImageView.swift#L485-L493)，让它无视掉隔离域的检查。这虽然让可能的数据竞争延续下来了，但至少不会比原来变得更差。如果我们能确定 deinit 发生的线程的话，在运行时也将不存在风险。

然而，关于 deinit 的隔离问题，在社区争论两年之后，似乎终于快要有结论了。之前被驳回的关于 [deinit 隔离的 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0371-isolated-synchronous-deinit.md)，最近也开始了[第二次 review](https://forums.swift.org/t/second-review-se-0371-isolated-synchronous-deinit/73406)。如果一切顺利，我们也许可以在后续的 Swift 版本中看到 deinit 隔离的实现，这应该是严格并发中的一块重要拼图。

## 关于 Swift 语言现状

从 [2014 年发布](https://onevcat.com/2014/06/my-opinion-about-swift/)第一天开始，我就开始关注和书写 Swift 代码。转眼间，Swift 已经成为我的主要编程语言十年了。回首这段历程，我经历了早期“每年学一门新语言”的适应期 (也可以说是“镇痛期”)，见证了 Swift 开源和 ABI 稳定的里程碑，亲历了 Concurrency 的实现和 Swift 6 的变革。现在回看这门语言一路走来的历程和重要节点，不禁对编程语言的发展路径有了更深刻的体会。

如果要用一句话来评价现在的 Swift，我会想说，它已经复杂到和一开始的 Swift 完全不同了。这个复杂度对于新人来说已经足够困难了。数一数最近几年的新增特性，从 [Result Builder](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0289-result-builders.md) 开始，一路有 [Property Wrapper](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)，再到[宏](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0382-expression-macros.md)以及[并发编程](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)，甚至还有 [ownership](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md)，不得不承认，Swift 团队真的非常努力：他们以令人称赞的效率为这门语言添加了许多的新特性，这些新特性也或多或少地借鉴了其他语言 (特别是 Rust) 的优秀之处。然而，当我们回顾这些特性时，会发现如果不使用 SwiftUI，这些特性大部分对于编写 app 这一 Swift 的主要任务来说其实没有发挥太大作用。绝大部分情况下，我们还是在使用 Swift 3 或者 4 就已经定型的语法来编写 app。

而在另一维度，这些复杂度不可避免地带来一些问题：

- 比如对于一个大型 app 来说，几乎每个 Swift 版本的编译速度都在退化。大公司往往需要专门的编译工程师来监测和优化编译速度。
- 而对于小开发者来说，强制的数据竞争安全则时常会打断创作时的[心流状态](https://zh.wikipedia.org/zh-cn/%E5%BF%83%E6%B5%81%E7%90%86%E8%AB%96)：编译错误会把开发者硬生生从创意性的工作中打断，转而去思考那些可能万年难得一见甚至根本就不存在的数据竞争问题。
- 复杂项目中 Xcode 的代码补全，SwiftUI 的预览，甚至是 LLDB 断点的速度，这些极其影响开发者体验的部分迟迟没有改善 (当然，可能这并不能怪罪 Swift。但是 Objective-C 时代确实这些问题并没有现在这样明显)。

个人的感想：Swift 现今的发展似乎并没有把绝对重点放在“帮助开发者更好更快地完成 app”上。我不清楚具体原因，但不论是团队更看重 KPI (比如一定要改造语言并匆忙发布 SwiftUI，或者是要把并发编程的饼尽早做出来)，还是急于在别的领域“大显身手” (比如 Server Side 或者其他操作系统平台)，我个人在 Swift 6 下写代码时，似乎并没有感觉到比 Swift 3 或者 4 时更快乐。

事实上，Apple 平台开发者面临着越来越重的学习负担。初学者不光需要学习基本语法，值类型和引用类型，以及基于 protocol 的编程思想这些基础内容，还要面临各种看不明白的宏和 Property Wrapper，最后甚至需要理解和正确使用 actor 和 Sendable 来在各个隔离域之间舞蹈并取悦编译器 (这绝对是中高级开发者才应该考虑的内容了)。十年积累如我，都略感力不从心，我很难想像刚接触 Swift 的新人在开发 app 时所面临的困难。

移动平台的原生开发日渐式微，这是所有从业者都无法逃避的市场规律和技术前提。Apple Vision Pro 设备向我们展示的新愿景似乎也还远不是人人能够负担的未来。我很好奇在 Swift 6 开启了一个绝对安全的并发先河之后，这门语言今后会何去何从，又会如何继续进化。无论如何，Swift 的未来无疑将继续影响和塑造 Apple 开发者的工作方式和应用的开发模式，让我们拭目以待。
