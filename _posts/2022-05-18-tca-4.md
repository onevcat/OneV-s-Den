---
layout: post
title: "TCA - SwiftUI 的救星？(四)"
date: 2022-05-18 12:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, 编程语言, swiftui, tca, elm]
typora-root-url: ..
---

这是一系列关于 TCA 文章的最后一篇。在系列中前面的几篇里，我们简述了 [TCA 的最小 Feature 核心思想](/2021/12/tca-1/)，并研究了[绑定和环境值的处理](/2021/12/tca-2/)，以及 [Effect 角色和 Feature 组合的方式](/2022/03/tca-3/)等话题。作为贯穿整个系列的示例 app，现在应该已经拥有一个可用的猜数字游戏了。这篇文章会综合运用之前的内容，来看看和 UI 以及日常操作更贴近的一些话题，比如如何用 TCA 的方式展示 `List` 并让结果可以被删除，如何处理导航以及 alert 弹窗等。

> 如果你想要跟做，可以直接使用上一篇文章完成练习后最后的状态，或者从[这里](https://github.com/onevcat/CounterDemo/releases/tag/part-3-finish)获取到起始代码。

## 展示结果 List

在前一篇文章[最后的练习中](/2022/03/tca-3/#记录结果并显示数据)，我们使用了 `var results: [GameResult]` 来存放结果并显示已完成的状态数字。现在我们的 app 还只有一个单一页面，我们打算为 app 添加一个展示所有已猜测结果，并且可以对结果进行删除的新页面。

### 使用 `IdentifiedArray` 进行改造

在实际开始之前，来对 `results` 数组进行一些改造：使用 TCA 中定义的 `IdentifiedArray` 来代替简单的 Swift `Array`：

```swift-diff
struct GameState: Equatable {
  var counter: Counter = .init()
  var timer: TimerState = .init()
  
- var results: [GameResult] = []
+ var results = IdentifiedArrayOf<GameResult>()
  var lastTimestamp = 0.0
}
```

这会导致编译无法通过，我们先把错误放一放，来看看相比起 `Array` 来说，`IdentifiedArray` 的优势：

- 和普通 `Array` 一样，`IdentifiedArray` 也尊重元素顺序，并支持基于 index 的 O(1) 随机存取。而且它提供了和 `Array` 兼容的 API。
- 但是和 `Array` 不同，`IdentifiedArray` 要求其中元素遵守 `Identifiable` 协议：也就是只有包含 `id` 属性的实例能被放入其中，而且需要确保唯一，不能有同样 `id` 的元素被放入。
- 有了 `Identifiable` 和唯一性的保证，`IdentifiedArray` 就可以利用类似字典的方式通过 `id` 快速地查找元素。

使用 `Array` 对一组数据建模，是最容易和最简单的想法。但当 app 更复杂时，处理 `Array` 很容易造成性能退化或者出错：

- 要根据相等 (也就是 `Array.firstIndex(of:)`) 来查找其中的某个元素会需要 O(n) 的复杂度。
- 使用 index 来获取元素虽然是 O(1)，但是如果处理异步的情况，异步操作开始时的 index 有可能和之后的 index 不一致，导致错误 (试想在异步期间，以同步的方式删除了某些元素的情况：异步操作之前保存的 index 将会失效，访问这个 index 可能获取到不同的元素，甚至引起崩溃)。

`IdentifiedArray` 通过提供基于 `Identifiable` 的访问方式，可以同时解决上面两个问题。虽然在我们的这个简单例子中使用 `Array` 也无伤大雅，但是在 TCA 的世界，甚至在普通的其他 Swift 开发时，如果被上面的问题困扰，我们都可以用 `IdentifiedArray` 来处理。

回到 app，为了让 `IdentifiedArrayOf<GameResult>` 能成立 (它是 `IdentifiedArray<Element.ID, Element>` 的类型别名)，我们需要 `GameResult` 满足 `Identifiable`。因为 `Counter` 已经满足 `Identifiable` 了，所以一个简单的方法就是重构一下 `GameResult`，让它直接包含 `Counter`：

```swift-diff
- struct GameResult: Equatable {
+ struct GameResult: Equatable, Identifiable {
-   let secret: Int
-   let guess: Int
+   let counter: Counter
    let timeSpent: TimeInterval

-   var correct: Bool { secret == guess }
+   var correct: Bool { counter.secret == counter.count }
+   var id: UUID { counter.id }
}
```

然后，更新 `reducer` 和 `body` 的部分，让编译通过：

```swift-diff
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    switch action {
    case .counter(.playNext):
      let result = GameResult(
-       secret: state.counter.secret,
-       guess: state.counter.count,
+       counter: state.counter,
        timeSpent: state.timer.duration - state.lastTimestamp
      )
      // ...
  },
  // ...
)

struct GameView: View {
  var body: some View {
    // ...
-      resultLabel(viewStore.state)
+      resultLabel(viewStore.state.elements)
  }
  
  // ...
}
```

编译并运行，app 的行为应该没有改变，不过在底层我们已经转为使用 `IdentifiedArray` 来存储结果数据了。

> 这个重构在我们的 app 中不是必要的，但是 TCA 里大量使用了 `IdentifiedArray`。有意识地从一开始就使用 `IdentifiedArray` 很多时候可以节省不必要的麻烦。

### 使用独立 feature 的方式进行构建

和之前的各个 feature 一样，result list 的画面也是由 state，reducer，environment 和 action 等要素组成的。需要再次强调，这就是 TCA 最优秀的一点：**我们只需要着眼创建简单的小组件，然后通过组合的方式把它们添加到大组件中**。

对于 State 角色，暂时只需要一个数组，我们可以简单地用 `IdentifiedArrayOf<GameResult>` 来表示。创建一个新的 `GameResultListView.swift` 文件，添加如下内容：

```swift
import ComposableArchitecture

typealias GameResultListState = IdentifiedArrayOf<GameResult>
```

除了展示外，我们还希望能够删除结果，所以 action 需要能反应这个操作。

```swift
enum GameResultListAction {
  case remove(offset: IndexSet)
}
```

`GameResultListView` 不需要特殊的 Environment，reducer 也非常简单：

```swift
struct GameResultListEnvironment {}

let gameResultListReducer = Reducer<GameResultListState, GameResultListAction, GameResultListEnvironment> { 
  state, action, environment in
  switch action {
  case .remove(let offset):
    state.remove(atOffsets: offset)
    return .none
  }
}
```

相信你已经对这些部分非常熟悉了。最后，创建 `GameResultListView` 并把这些东西组合起来就好了：

```swift
struct GameResultListView: View {
  let store: Store<GameResultListState, GameResultListAction>
  var body: some View {
    WithViewStore(store) { viewStore in
      List {
        ForEach(viewStore.state) { result in
          HStack {
            Image(systemName: result.correct ? "checkmark.circle" : "x.circle")
            Text("Secret: \(result.counter.secret)")
            Text("Answer: \(result.counter.count)")
          }.foregroundColor(result.correct ? .green : .red)
        }
      }
    }
  }
}
```

我们还没有把 `GameResultListView` 添加到 app 里，想要先验证它，可以添加 preview：

```swift
struct GameResultListView_Previews: PreviewProvider {
  static var previews: some View {
    GameResultListView(
      store: .init(
        initialState: .init(rows: [
          GameResult(
            counter: .init(
              count: 20, secret: 20, id: .init()
            ),
            timeSpent: 100),
          GameResult(
            counter: .init(),
            timeSpent: 100)
        ]),
        reducer: gameResultListReducer,
        environment: .init()
      )
    )
  }
}
```

![](/assets/images/2022/tca-resultlist-preview.png)

### 支持删除

在 SwiftUI 中添加默认的删除操作非常简单，只需要为 cell 添加 `onDelete` 就行了。作为通用 UI，我们也添加一个 `EditButton`：

```swift-diff
struct GameResultListView: View {
  let store: Store<GameResultListState, GameResultListAction>
  var body: some View {
    WithViewStore(store) { viewStore in
      List {
        ForEach(viewStore.rows) { result in
          // ...
        }
+       .onDelete { viewStore.send(.remove(offset: $0)) }
      }
+     .toolbar {
+       EditButton()
+     }
    }
  }
}
```

在 `onDelete` 中，向 `viewStore` 发送 `.remove` action，从而触发 reducer 并更新状态即可。如果在 Preview 中选择运行，我们就可以在预览画布中直接删除显示的项目了。

## Navigation 导航

### 基本导航

接下来通过导航的方式显示这个新创建的 `GameResultListView`。在 app 主页面中，我们已经看到过如何将小组件使用 `pullback` 的方式进行组合了。将 list feature 和 app 其他部分的 feature 进行组合的方式并没有什么不同：也就是把子组件的 state，action，reducer 和 view 都集成到父组件去。

在这里，我们计划在导航栏上添加一个 "Detail" 按钮，通过 `NavigationLink` 的方式显示结果列表。首先，在 `CounterDemoApp.swift` 中添加一个 `NavigationView`，作为整个 app 的容器：

```swift-diff
struct CounterDemoApp: App {
  var body: some Scene {
    WindowGroup {
+     NavigationView {
        GameView(
          store: Store(
            initialState: GameState(),
            reducer: gameReducer,
            environment: .live)
        )
+     }
    }
  }
}
```

##### State

在 `GameState` 中，已经存在 `var results: IdentifiedArrayOf<GameResult>` 数据源了，我们可以直接将它作为列表画面的数据源。


##### Action

在 `GameResultListView` 操作结果数组的同时，我们希望把结果拉回到 `GameState.results` 里，为此，我们需要一个能处理 `GameResultListAction` 的 action。在 `GameAction` 中新加入一个成员：

```swift-diff
enum GameAction {
  case counter(CounterAction)
  case timer(TimerAction)
+ case listResult(GameResultListAction) 
}
```

##### Reducer

更新 `gameReducer`，让 `gameResultListReducer` 根据 `.listResult` 的行为把操作的结果拉回到 `results`。在 `gameReducer` 中 `combine` 的最后，添加：

```swift-diff
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    // ...
  },
  // ...
  timerReducer.pullback(
    state: \.timer,
    action: /GameAction.timer,
    environment: { .init(date: $0.date, mainQueue: $0.mainQueue) }
+  ),
+ gameResultListReducer.pullback(
+   state: \.results,
+   action: /GameAction.listResult,
+   environment: { _ in .init() }
  )
)
```

这样，接收到 `.listResult` action 时 `gameResultListReducer` 造成的结果 (新的 result list state，也就是 `IdentifiedArrayOf<GameResult>`) 将通过 `\.results` 这个 `WritableKeyPath` 写回到 `GameState.results` 属性中，以完成 state 的更新。

##### View

最后，在 `body` 中创建 `NavigationLink`，用 `scope` 把 `results` 切割出来，把新的 store 传递给 `GameResultListView` 作为目标 view，导航就完成了：

```swift-diff
struct GameView: View {
  let store: Store<GameState, GameAction>
  var body: some View {
    WithViewStore(store.scope(state: \.results)) { viewStore in
      VStack {
        // ...
      }.onAppear {
        viewStore.send(.timer(.start))
      }
+   }.toolbar {
+     ToolbarItem(placement: .navigationBarTrailing) {
+       NavigationLink("Detail") {
+         GameResultListView(store: store.scope(state: \.results, action: GameAction.listResult))
+       }
+     }
    }
  }
```

##### 结果

运行 app，现在主页面 `GameView` 处于 `NavigationView` 环境中。当进行几个猜数字后，点击 "Detail" 按钮，app 可以导航到 `GameResultListView` 中，你也可以在详细页面里删除几个结果，然后返回到主页面：注意主页面上的计数将随着详细页面的修改而变动，它们共享单一的数据源，这避免了数据在两个页面中的不同步，一般来说是非常好的实践：

<video width="272" height="480" controls>
  <source src="/assets/images/2022/tca-navigation.mp4" type="video/mp4">
</video>

如果你对 pullback 的行为还不清楚，推荐对照前一篇文章中的这张流程图再次确认：

![](/assets/images/2022/tca-pullback-flow.png)

#### 存在的问题

TCA 这类类似 Elm 的架构形式，一大特点是 State 完全决定 UI，这也是在进行 UI 测试时很重要的手段：只要我们能构建出合适的 State (model 层)，我们就能期待固定的 UI，这让整个 app 的界面成为一个“纯函数”：`UI = F(State)`。

但不幸的是，上面这种简单的导航形式破坏了这个公式：显示主页面时的 State 和显示列表页面时的 State 是无法区分的，同一种状态可能会对应不同的 UI。这是因为管理导航的状态存在于 SwiftUI 内部，它在我们的 State 中没有体现出来。

如果不是很计较 app 的严肃性，那么这种简单的导航关系也不是不能接受。不过为了满足纯函数的要求，我们来看看 SwiftUI 提供的另一种导航方式，也就是基于 Binding 值控制的导航，要如何与 TCA 协同工作。

### 基于 Binding 的导航

除了上面用到的最简单的 `init(_:destination:)` 以外，`NavigationLink` 还有一些带有 `Binding` 的变种版本，比如：

```swift
init(
  _ titleKey: LocalizedStringKey, 
  isActive: Binding<Bool>, 
  @ViewBuilder destination: () -> Destination
)

init<V>(
  _ titleKey: LocalizedStringKey, 
  tag: V, 
  selection: Binding<V?>, 
  @ViewBuilder destination: () -> Destination
) where V : Hashable
```

前者接受 `Binding<Bool>`，这个 `Binding` 可以通过两种方式控制导航状态：

- 当用户通过 UI 触发导航时，SwiftUI 负责将这个值设为 `true`。在使用回退按钮返回时，SwiftUI 负责将这个值设为 `false`。
- 我们也可以通过代码把这个 `Binding` 值设置为 `true` 或 `false` 来触发相应的导航和回退行为。

相比起前者的 `Bool`，后者接受 `V?` 的绑定值和一个代表当前 `NavigationLink` 的 `tag` 值：当 `selection` 的 `V` 和 `tag` 的 `V` 相同时，导航生效并展示 `destination` 的内容。为了判断这个相同，SwiftUI 要求 `V` 满足 `Hashable`。

这两个变体为 TCA 提供了机会，可以通过 State 来控制导航状态：只要我们在 `GameState` 中添加一个代表的导航状态的变量，就可以通过把这个变量转换为 Binding 并设置它，来让状态和 UI 一一对应：即 state 为 `true` 或者 non-nil 值时，显示详细页面；否则为 `false` 或 `nil` 时，显示主页面。

#### Identified

在这个例子中，我们选用 `Binding<V?>` 的方法来控制。在 `GameState` 中添加一个属性：

```swift-diff
struct GameState: Equatable {
  // ...
+ var resultListState: Identified<UUID, GameResultListState>?
}
```

`Binding<V?>` 中需要 `V` 满足 `Hashable`，这里我们原本的目标是让 `GameResultListState` (也就是 `IdentifiedArrayOf<GameResult>`) 满足 `Hashable`。这是一个相对困难的任务：我们可以为 `IdentifiedArray` 添加 `Hashable` 实现，但是这并不是一个好选择：这两个类型定义都不属于我们，我们无法控制将来 TCA 是否会为 `IdentifiedArray` 引入 `Hashable` 实现。TCA 中将一个任意值转为 `Hashable` 更简单的方式就是用 `Identified` 包装它，手动为它赋予一个 id 值，用它作为 `V` 的类型。在我们的例子中，导航只有一个单一的状态，所以我们完全可以定义一个通用的 `UUID` 作为 `NavigationLink` 的 `tag`，在 `GameView.swift` 的顶层 scope 添加下面的定义：

```swift
let resultListStateTag = UUID()
```

> 使用 `Binding<V?>` 和 `tag` 的版本，更多是为了区分多个可能的导航情况 (比如一个列表中的各个选项都可能导航至下一个页面)。
> 
> 实际上，对于我们这里的例子，因为只有一个可能的触发导航的情况它，所以并没有必要使用 `tag` 的方式控制，只需要使用 `Binding<Bool>` 就可以了。不过我们还是选择 `Binding` 的版本作为例子，因为它更具一般性。

#### Binding 和导航 Action 处理

如果你还记得 [TCA 中绑定值的处理方式](/2021/12/tca-2/#在-tca-中实现单个绑定)，通过 `viewStore.binding` 操作绑定值时，可以在这个值发生变化时让 TCA 发送一个 action。我们需要在 reducer 中捕获这个 action 并为 `resultListState` 设置合适的值。在 `GameAction` 里添加控制导航的 action 成员：

```swift-diff
enum GameAction {
  case counter(CounterAction)
  case listResult(GameResultListAction)
  case timer(TimerAction)
+ case setNavigation(UUID?)
}
```

然后将 `body` 中 `NavigationLink` 的部分替换为基于 `Binding` 的方式：

```swift-diff
struct GameView: View {
  let store: Store<GameState, GameAction>
  var body: some View {
    WithViewStore(store.scope(state: \.results)) { viewStore in
      // ...
    }.toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
-       NavigationLink("Detail") {
-          GameResultListView(store: store.scope(state: \.results, action: GameAction.listResult))
-       }
+       WithViewStore(store) { viewStore in
+         NavigationLink(
+           "Detail",
+           tag: resultListStateTag,
+           selection: viewStore.binding(get: \.resultListState?.id, send: GameAction.setNavigation),
+           destination: {
+             Text("Sample")
+           }
+         )
+       }
      }
    }
  }
```

当 `NavigationLink` 的 selection 被触发时，`.setNavigation(resultListStateTag)` 被发送，在 `gameReducer` 中，捕获这个 action 并进行处理：

```swift-diff
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    switch action {
    // ...
+   case .setNavigation(.some(let id)):
+     state.resultListState = .init(state.results, id: id)
+     return .none
+   case .setNavigation(.none):
+     state.results = state.resultListState?.value ?? []
+     state.resultListState = nil
+     return .none
    }
  },
  // ...
)
```

接收到带有 `id` 的 `.setNavigation` action 时，我们手动设置 `resultListState`，这会触发导航。在用户退出导航时，接收到 `.setNavigation(.none)`，这时我们把 `resultListState.value` 设置回 `result`，然后把整个 `resultListState` 置为 `nil`，从导航中返回。

现在，`gameReducer` 对 `gameResultListReducer` 进行 `pullback` 时，将结果拉回 `results`。但是现在我们想要传递给 `GameResultListView` 的值已经是 `resultListState.value`，而非原来的 `results`。我们需要修改 `gameResultListReducer.pullback` 的部分：

```swift-diff
let gameReducer = 
  // ...
  gameResultListReducer
-   .pullback(
-     state: \.results,
-     action: /GameAction.listResult,
-     environment: { _ in .init() }
-   )
+   .pullback(
+     state: \Identified.value,
+     action: .self,
+     environment: { $0 }
+   )
+   .optional()
+   .pullback(
+     state: \.resultListState,
+     action: /GameAction.listResult,
+     environment: { _ in .init() }
+   )
) 
```

如果你还记得 `pullback` 的初衷，你应该记得，它的目的是把原本作用在本地域上的 reducer 转换为能够作用在全局域的 reducer。在这里，我们想要做的是把 `gameResultListReducer` 对 `GameResultListState` 造成的变更，拉回到 `GameState.resultListState.value` 中。因为 `resultListState` 是一个可选值，因此原本在 pullback 中我们应该把 `state` 写为 `\.resultListState?.value`。不过这种写法只能给我们不可写的 `KeyPath`，而非 `pullback` 要求的 `WritableKeyPath`。为了处理可选值，TCA 提供了 `optional()` 操作，来处理可选值的 `WritableKeyPath`。这里我们可以理解为，先把 `GameResultListState` 的结果写到某个 `Identified` 的 `value` 里，然后把这个 `Identified` 包裹在一个可选值里，最后再通过 `\.resultListState` 写到 `GameState` 里。

#### IfLetStore

整个过程的最后一步，是在 `NavigationLink` 的 `destination` 里创建正确的 `GameResultListView`。和上面 pullback 的情况类似，我们不再选择使用 `results`，而是使用 `\.resultListState?.value` 来切分 store：

```swift
// 注意，无法编译
store.scope(
  state: \.resultListState?.value, 
  action: GameAction.listResult
)
```

但这样做得到的是一个可选值 state 的类型 `Store<GameResultListState?, GameResultListAction>`，它并不能满足 `GameResultListView` 所需要的 `Store<GameResultListState, GameResultListAction>`。TCA 在处理 store 中可选值属性的切割时，使用 `IfLetStore` 来进行包装，它会根据其中状态可选值是否为 `nil` 来构建不同的 view：

```swift-diff
var body: some View {
  // ...
  NavigationLink(
    "Detail",
    tag: resultListStateTag,
    selection: viewStore.binding(get: \.resultListState?.id, send: GameAction.setNavigation),
    destination: {
-     Text("Sample")
+     IfLetStore(
+       store.scope(state: \.resultListState?.value, action: GameAction.listResult),
+       then: { GameResultListView(store: $0) }
+     )
    }
  )
}
```

至此，我们完成了最完整的使用 `Binding` 进行导航的方式。运行 app，你会发现看起来整个 app 的行为和简单导航时并没有什么区别。但是我们现在可以通过构建合适的 `GameState`，来直接显示结果详细页面。这在追踪和调试 app 中带来巨大便利，也正是 TCA 的强大之处。比如，在 `CounterDemoApp` 中，我们可以添加一些 sample：

```swift
let sample: GameResultListState = [
  .init(counter: .init(count: 10, secret: 10, id: .init()), timeSpent: 100),
  .init(counter: .init(), timeSpent: 100),
]

let testState = GameState(
  counter: .init(), 
  timer: .init(),
  resultListState: .init(sample, id: resultListStateTag),
  results: sample,
  lastTimestamp: 100
)
```

然后将它直接设置给 app：

```swift-diff
struct CounterDemoApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        GameView(
          store: Store(
-           initialState: GameState(),
+           initialState: testState
            reducer: gameReducer,
            environment: .live)
        )
      }
    }
  }
}
```

现在运行 app，我们会被直接导航到结果页面。确保唯一的 state 对应的唯一 UI，可以让开发快速定位问题：只需要提供 app 出现问题时的 state，理论上就可以稳定重现和立即开始调试。

### 更多讨论

#### SwiftUI 导航最佳实践

虽然 Apple 在 SwiftUI 导航上做了不少努力，但是传统的几种导航方式有一定缺失：不论是 navigation 还是 sheet，对于基于 Binding 的导航，控制导航状态的 Binding 值并不会被传递到 [`NavigationLink`](https://developer.apple.com/documentation/swiftui/navigationlink) 的 `destination` 或者 [`View.sheet`](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)) 的 `content` 中，这导致后续页面无法有效修改前置页面的数据，从而造成事实上的数据源不统一。

在 TCA 中因为不能直接修改 state，我们选择通过在 Binding 变化时发送 action 的方式更新 state。这种方法在 TCA 里非常合适，但在普通的 SwiftUI app 里虽然也可行，却显得有点儿格格不入。TCA 的维护者对此专门[开源了一套工具](https://github.com/pointfreeco/swiftui-navigation)，来补充原生 SwiftUI 架构在导航上的不足，其中也包含了对于这个话题的更深入的讨论。

#### ViewStore 的各种形式

在上面的例子中，我们看到了在 `View` 中使用 `IfLetStore` 来切分 state 中的可选值的方法；对于可选值，在组合 reducer 时，我们在 pullback 之前相应地使用了 `optional()` 方法将非可选的本地状态转换为可选值的全局状态，从而完成状态回拉。

另一种特殊的 Store 形式是 `ForEachStore`，它针对 State 中的 `IdentifiedArray`，将其中每一个元素切为一个新的 Store。如果 `List` 中的每个 cell 自成一套 feature 的话 (比如示例的猜数字 app 中，允许结果列表页面的每个结果 cell 再点击进去，并显示一个 `CounterView` 来修改内容的话)，这种方式将让我们很容易把 `List` 和 TCA 进行结合。与 `IfLetStore` 和 `optional()` 的关系类似，在组合 reducer 时，TCA 也为 `IdentifiedArray` 的属性准备了 [`forEach` 方法](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/reducer/foreach(state:action:environment:file:line:)-gvte)来把数组中的各个元素变更拉回到全局状态的对应元素中。我们将把关于数组切分和拉回的课题作为练习留给读者。

另外，对于 enum 形式的 State，TCA 也准备了相应的 `SwitchStore` 和 `CaseLet`，可以让我们以相似的语法根据不同 State 属性创建 view。关于这些内容，在理解了 TCA 的工作原理后，就都是一些类似语法糖的存在，可以在实际用到时再加以确认。

## Alert 和结果存储

可能有细心的同学会问，在上面 `Binding` 导航的时候，为什么不直接选择在 `.setNavigation(.some(let id))` 的时候单独只设置一个 `UUID`，而保持将结果直接 pullback 到 `results` 呢？`resultListState` 存在的意义是什么？或者甚至，为什么不直接使用 `Binding<Bool>` 的 `NavigationLink` 版本呢？

对于很多情况，在 list view 里直接操作 `results` 是完全可行的，不过如果我们有需要暂时保留原来数据的场景的话，在 `.setNavigation(.some(let id))` 中复制一份 `results` (在例子中我们通过创建新的 `Identified` 值进行复制)，在编辑过程中保持原来 `results` 的稳定，并在完全结束后再把更改后的 `resultListState` 重新赋给 `results` 就是必要的了。

我们通过一个例子来说明，比如现在我们希望在从列表界面返回后多加一次 alert 弹窗确认，当用户确认更改后通过网络请求向服务端“汇报”这次更改，然后在成功后再刷新 UI。如果用户选择放弃修改的话，则维持原来的结果不变。

### AlertState

显示一个 alert 在 app 开发中是非常常见的，TCA 为此内置了一个专门用来管理 alert 的类型：`AlertState`。为了让 alert 能够工作，我们可以为它添加一组 action，描述 alert 的按钮点击行为。在 `GameView.swift` 中添加：

```swift
enum GameAlertAction: Equatable {
  case alertSaveButtonTapped
  case alertCancelButtonTapped
  case alertDismiss
}
```

然后在 `GameState` 里新增 `alert` 属性：

```swift-diff
struct GameState: Equatable {
  // ...
  
+ var alert: AlertState<GameAlertAction>?
}
```

和处理导航关系时一样，通过在 reducer 里设置 `alert` 可选值，就可以控制 alert 的显示和隐藏。我们计划在从结果列表页面返回时展示这个 alert，修改 `gameReducer` 的 `setNavigation(.none)` 分支：

```swift-diff
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    switch action {
    // ...
    case .setNavigation(.none):
-     state.results = state.resultListState?.value ?? []
-     state.resultListState = nil
+     if state.resultListState?.value != state.results {
+       state.alert = .init(
+         title: .init("Save Changes?"),
+         primaryButton: .default(.init("OK"), action: .send(.alertSaveButtonTapped)),
+         secondaryButton: .cancel(.init("Cancel"), action: .send(.alertCancelButtonTapped))
+       )
+     } else {
+       state.resultListState = nil
+     }
      return .none
    }
    // ...
)
```

最后，在 `GameView` 中合适的地方加上这个 `alert` 就行了：

```swift-diff
struct GameView: View {
  // ...
  var body: some View {
    WithViewStore(store.scope(state: \.results)) { viewStore in
      // ...
    }.toolbar {
      // ...
+   }.alert(
+     store.scope(state: \.alert, action: GameAction.alertAction),
+     dismiss: .alertDismiss
+   )
  }
  // ...
}
```

### 处理 dismiss 和按钮事件

不过现在代码还无法编译，因为在 reducer 里我们还没有处理 alert 相关的 action。

`.alertDismiss` action 将会在 alert 被 dismiss 的时候触发，之后 TCA 再根据具体是哪个按钮被点击，向 reducer 发送对应按钮绑定的 action。因此常规做法是在 `.alertDismiss` 中将 `state.alert` 置回 `nil`，然后在 `.alertSaveButtonTapped` 和 `.alertCancelButtonTapped` 进行相应的逻辑。在 `gameReducer` 的 `.setNavigation(.none)` 之后追加：

```swift-diff
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    switch action {
    // ...
    case .setNavigation(.none):
    // ...
+   case .alertAction(.alertDismiss):
+     state.alert = nil
+     return .none
+   case .alertAction(.alertSaveButtonTapped):
+     // Todo: 暂时直接设置 results，实际应该发送请求。
+     state.results = state.resultListState?.value ?? []
+     state.resultListState = nil
+     return .none
+   case .alertAction(.alertCancelButtonTapped):
+     state.resultListState = nil
+     return .none
```

一切准备就绪，现在运行 app，尝试在结果列表中删除几个项目，并返回主页面。现在结果并不会直接更新了，而是先弹出确认框，并在用户点击保存时才进行更新。

![](/assets/images/2022/tca-alert.png)

### Effect 和 Loading UI

最后我们来处理上面代码中 "Todo" 的部分：发送实际请求，并在完成时再进行 `results` 的更新。为了简单起见，这里就只用一个 `delay` 的 `Effect` 来模拟这个请求了。实际的网络请求的实现 (以及错误处理)，就留作练习了。

在 `GameAction` 中添加一个 case 代表请求结果：

```swift-diff
enum GameAction {
  // ...
+ case saveResult(Result<Void, URLError>)
}
```

为了显示网络请求正在进行，我们可以在 state 里添加一个属性，表示加载正在进行：

```swift-diff
struct GameState: Equatable {
  // ...
+ var savingResults: Bool = false
}
```

然后将 `gameReducer` 里 `.alertSaveButtonTapped` case 中的处理替换，并添加对 `.saveResult` 的处理。

```swift-diff
    case .alertAction(.alertSaveButtonTapped):
-     // Todo: 暂时直接设置 results，实际应该发送请求。
-     state.results = state.resultListState?.value ?? []
-     state.resultListState = nil
-     return .none
+     state.savingResults = true
+     return Effect(value: .saveResult(.success(())))
+       .delay(for: 2, scheduler: environment.mainQueue)
+       .eraseToEffect()
    // ...
+   case .saveResult(let result):
+     state.savingResults = false
+     state.results = state.resultListState?.value ?? []
+     state.resultListState = nil
+     return .none
```

最后，稍微修改 `GameView` 中 `NavigationLink` 的部分，在请求途中显示一个 `ProgressView`：

```swift-diff
NavigationLink(
  // ...
  label: {
+   if viewStore.savingResults {
+     ProgressView()
+   } else {
      Text("Detail")
+   }
  }
)
```

<video width="272" height="480" controls>
  <source src="/assets/images/2022/tca-delay-effect-saving.mp4" type="video/mp4">
</video>

## 总结

到这里，我想应该可以为这一个系列的 TCA 教程画上句号了。我们看到了 TCA 的各个组件以及它们的组织方式，常见的一些用法和模式，并且对背后的思想进行了探索。虽然我们没有涉及到 TCA 框架的所有部分 (毕竟这系列文章并不是使用手册，篇幅上也不允许)，但是一旦我们理解和弄清了架构的思想，那么使用顶层 API 就只是手到擒来了。

对于更大和更复杂的 app 架构，TCA 框架会面临其他一些问题，比如数据在多个 feature 间共享的方式，state 过于庞大后可能带来的性能问题，以及跨越多个层级传递数据的方式等。本文写作时，这些问题都没有特别完美和通用的解决方式。不过，TCA 并没有到达 1.0 版本，它本身也在快速发展和演进中，几乎每个月都会有全新的特性甚至破坏性的变化被引入。如果你遇到了棘手的问题，或者对最佳实践有所疑问，不妨到 TCA 的[项目和 issue 页面中](https://github.com/pointfreeco/swift-composable-architecture)寻求答案或者帮助。将你的心得和体会总结，并通过某种方式回馈给社区，也将会对这个项目的建设带来好处。

想要进一步学习 TCA 的话，除了它本身带有的[几个 demo](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples) 以外，Point-Free 实际上还开源了一个相当完整的项目：[isowords](https://github.com/pointfreeco/isowords)。另外，他们主持的[每周教学节目](https://www.pointfree.co)，也对包括 TCA 在内的很多 Swift 话题进行了非常深刻的讨论，如果学有余力，我个人十分推荐。

## 练习

如果你没有跟随本文更新代码，你可以在[这里](https://github.com/onevcat/CounterDemo/releases/tag/part-4-start)找到下面练习的起始代码。

### 使用 modal 进行展示

在本文中，我们使用了 `NavigationLink` 来展示结果页面。iOS app 里另一种常见的迁移方式是 modal present。尝试使用 [`sheet(item:onDismiss:content:)`](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)) 来呈现结果列表页面。

### 实际的网络请求

在用户点击保存按钮时，我们使用了下面的 `Effect` 来模拟网络请求：

```swift
Effect(value: .saveResult(.success(())))
  .delay(for: 2, scheduler: environment.mainQueue)
```

请你尝试把这个用来模拟的 `Effect` 替换成实际的网络请求吧！不需要真的进行数据传递，只需要随意构建一个 `dataTask` 就好，比如：

```swift
let sampleRequest = URLSession.shared
  .dataTaskPublisher(for: URL(string: "https://example.com")!)
  .map { element -> String in
    return String(data: element.data, encoding: .utf8) ?? ""
  }
```

然后把结果用 `catchToEffect` 转换为我们需要的类型。需要注意，在 reducer 中应该要合理处理错误的情况；另外，为了能够测试，这个请求应该放在环境值中，而不是直接写在 reducer 里。如果你已经忘了如何使用 TCA 处理网络请求和进行测试，可以参考前一篇文章中关于[网络请求 Effect](/2022/03/tca-3/#网络请求-effect) 的部分。

### Loading UI 的问题

在进行保存请求时，`savingResults` 为 `true`。这种情况下，我们在 `GameView` 里把 "Detail" 按钮替换为了 `ProgressView`。但是主界面中的 "Next" 按钮依然可以点击，请求期间我们仍可把新的结果添加到 `results` 里。在网络请求结束后，`results` 里虽然可能存在新的结果，但它还是会被 `resultListState` 覆盖，导致请求期间的结果丢失。参见下面的重现步骤：

<video width="272" height="480" controls>
  <source src="/assets/images/2022/tca-saving-bug.mp4" type="video/mp4">
</video>

要解决这个问题，可以选择在请求期间禁用 "Next" 按钮 (比较简单的实现，但是很差很粗暴的用户体验)，或者引入一种机制来合并结果 (比较好的体验，但需要更多代码)。或者你可以自行考虑其他的解决方案。

### 尝试 ForEachStore

文中没有用到 `ForEachStore`。请参考 TCA 的相关文档，学习 `ForEachStore` 和 `Reducer.forEach` 的用法，在结果列表页面中添加一层导航，来增加对每个结果的“编辑”功能，让用户可以利用 `CounterView` 修改他们之前的猜测结果。