---
layout: post
title: "关于 SwiftUI State 的一些细节"
date: 2021-01-22 15:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, swiftui]
---

## @State 基础

在 SwiftUI 中，我们使用 `@State` 进行私有状态管理，并驱动 `View` 的显示，这是基础中的基础。比如，下面的 `ContentView` 将在点击加号按钮时将显示的数字 +1：

```swift
struct ContentView: View {
    @State private var value = 99
    var body: some View {
        VStack(alignment: .leading) {
            Text("Number: \(value)")
            Button("+") { value += 1 }
        }
    }
}
```

当我们想要将这个状态值传递给下层子 View 的时候，直接在子 View 中声明一个变量就可以了。下面的 View 在表现上来说完全一致：

```swift
struct DetailView: View {
    let number: Int
    var body: some View {
        Text("Number: \(number)")
    }
}

struct ContentView: View {
    @State private var value = 99
    var body: some View {
        VStack(alignment: .leading) {
            DetailView(number: value)
            Button("+") { value += 1 }
        }
    }
}
```

在 `ContentView` 中的 `@State value` 发生改变时，`ContentView.body` 被重新求值，`DetailView` 将被重新创建，包含新数字的 `Text` 被重新渲染。一切都很顺利。

## 子 View 中自己的 @State

如果我们希望的不完全是这种被动的传递，而是希望 `DetailView` 也拥有这个传入的状态值，并且可以自己对这个值进行管理的话，一种方法是在让 `DetailView` 持有自己的 `@State`，然后通过初始化方法把值传递进去：

```swift
struct DetailView0: View {
    @State var number: Int
    var body: some View {
        HStack {
            Text("0: \(number)")
            Button("+") { number += 1 }
        }
    }
}

// ContentView
@State private var value = 99
var body: some View {
    // ...
    DetailView0(number: value)
}
```

这种方法能够奏效，但是违背了 `@State` 文档中关于这个属性标签的说明：

> ... declare your state properties as private, to prevent clients of your view from accessing them.

**如果一个 `@State` 无法被标记为 private 的话，一定是哪里出了问题**。一种很朴素的想法是，将 `@State` 声明为 `private`，然后使用合适的 `init` 方法来设置它。更多的时候，我们可能需要初始化方法来解决另一个更“现实”的问题：那就是使用合适的初始化方法，来对传递进来的 `value` 进行一些处理。比如，如果我们想要实现一个可以对任何传进来的数据在显示前就进行 +1 处理的 View：

```swift
struct DetailView1: View {
    @State private var number: Int

    init(number: Int) {
        self.number = number + 1
    }
    //
}
```

但这会给出一个编译错误！

> Variable 'self.number' used before being initialized

一开始你可能对这个错误一头雾水。我们会在本文后面的部分再来看这个错误的原因。现在先把它放在一边，想办法让编译通过。最简单的方式就是把 `number` 声明为 `Int?`：

```swift
struct DetailView1: View {
    @State private var number: Int?

    init(number: Int) {
        self.number = number + 1
    }

    var body: some View {
        HStack {
            Text("1: \(number ?? 0)")
            Button("+") { number = (number ?? 0) + 1 }
        }
    }
}

// ContentView
@State private var value = 99
var body: some View {
    // ...
    DetailView1(number: value)
}
```

问答时间，你觉得 `DetailView1` 中的 `Text` 显示的会是什么呢？是 0，还是 100？

> 我有一个邪恶的想法，也许可以把这道题加到我的面试题列表里去问其他小朋友....

如果你回答的是 100 的话，恭喜，你答错掉“坑”里了。比较“出人意料”，虽然我们在 `init` 中设置了 `self.number = 100`，但在 `body` 被第一次求值时，`number` 的值是 `nil`，因此 `0` 会被显示在屏幕上。

## @State 内部

问题出在 `@State` 上：SwiftUI [通过 property wrapper](/2019/06/swift-ui-firstlook-2/#教程-3---handling-user-input) 简化并模拟了普通的变量读写，但是我们必须始终牢记，`@State Int` 并不等同于 `Int`，它根本就不是一个传统意义的存储属性。这个 property wrapper 做的事情大体上说有三件：

1. 为底层的存储变量 `State<Int>` 这个 struct 提供了一组 getter 和 setter，这个 `State` struct 中保存了 `Int` 的具体数字。
2. 在 body 首次求值前，将 `State<Int>` 关联到当前 `View` 上，为它在堆中对应当前 `View` 分配一个存储位置。
3. 为 `@State` 修饰的变量设置观察，当值改变时，触发新一次的 `body` 求值，并刷新屏幕。

我们可以看到的 `State` 的 public 的部分只有几个初始化方法和 property wrapper 的标准的 value：

```swift
struct State<Value> : DynamicProperty {
    init(wrappedValue value: Value)
    init(initialValue value: Value)
    var wrappedValue: Value { get nonmutating set }
    var projectedValue: Binding<Value> { get }
}
```

不过，通过打印和 dump `State` 的值，很容易知道它的几个私有变量。进一步地，可以大致猜测相对更完整和“私密”的 `State` 结构如下：

```swift
struct State<Value> : DynamicProperty {
    var _value: Value
    var _location: StoredLocation<Value>?
    
    var _graph: ViewGraph?
    
    var wrappedValue: Value {
        get { _value }
        set {
            updateValue(newValue)
        }
    }
    
    // 发生在 init 后，body 求值前。
    func _linkToGraph(graph: ViewGraph) {
        if _location == nil {
            _location = graph.getLocation(self)
        }
        if _location == nil {
            _location = graph.createAndStore(self)
        }
        _graph = graph
    }
    
    func _renderView(_ value: Value) {
        if let graph = _graph {
            // 有效的 State 值
            _value = value
            graph.triggerRender(self)
        }
    }
}

```

> SwiftUI 使用 meta data 来在 View 中寻找 `State` 变量，并将用来渲染的 `ViewGraph` 注入到 State 中。当 State 发生改变时，调用这个 Graph 来刷新界面。关于 `State` 渲染部分的原理，超出了本文的讨论范围。有机会在后面的博客再进一步探索。

对于 `@State` 的声明，会在当前 View 中带来一个自动生成的私有存储属性，来存储真实的 `State struct` 值。比如上面的 `DetailView1`，由于 `@State number` 的存在，实际上相当于：

```swift
struct DetailView1: View {
    @State private var number: Int?
    private var _number: State<Int?> // 自动生成
    // ...
}
```

这为我们解释了为什么刚才直接声明 `@State var number: Int` 无法编译：

```swift
struct DetailView1: View {
    @State private var number: Int

    init(number: Int) {
        self.number = number + 1
    }
    //
}
```

`Int?` 的声明在初始化时会默认赋值为 `nil`，让 `_number` 完成初始化 (它的值为 `State<Optional<Int>>(_value: nil, _location: nil)`)；而非 Optional 的 `number` 则需要明确的初始化值，否则在调用 `self.number` 的时候，底层 `_number` 是没有完成初始化的。

于是“为什么 init 中的设置无效”的问题也迎刃而解了。对于 `@State` 的设置，只有在 View 被添加到 graph 中以后 (也就是首次 body 被求值前) 才有效。

> 当前 SwiftUI 的版本中，自动生成的存储变量使用的是在 State 变量名前加下划线的方式。这也是一个代码风格的提示：我们在自己选择变量名时，虽然部分语言使用下划线来表示类型中的私有变量，但在 SwiftUI 中，最好是避免使用 `_name` 这样的名字，因为它有可能会被系统生成的代码占用 (类似的情况也发生在其他一些 property wrapper 中，比如 Binding 等)。


## 几种可选方案

在知道了 `State` struct 的工作原理后，为了达到最初的“在 init 中对传入数据进行一些操作”这个目的，会有几种选择。

首先是直接操作 `_number`：

```swift
struct DetailView2: View {
    @State private var number: Int

    init(number: Int) {
        _number = State(wrappedValue: number + 1)
    }

    var body: some View {
        return HStack {
            Text("2: \(number)")
            Button("+") { number += 1 }
        }
    }
}
```

因为现在我们直接插手介入了 `_number` 的初始化，所以它在被添加到 View 之前，就有了正确的初始值 100。不过，因为 `_number` 显然并不存在于任何文档中，这么做带来的风险是这个行为今后随时可能失效。

另一种可行方案是，将 init 中获取的 `number` 值先暂存，然后在 `@State number` 可用时 (也就是在 body ) 中，再进行赋值：

```swift
struct DetailView3: View {
    @State private var number: Int?
    private var tempNumber: Int

    init(number: Int) {
        self.tempNumber = number + 1
    }

    var body: some View {
        DispatchQueue.main.async {
            if (number == nil) {
                number = tempNumber
            }
        }
        return HStack {
            Text("3: \(number ?? 0)")
            Button("+") { number = (number ?? 0) + 1 }
        }
    }
}
```

不过，这样的做法也并不是很合理。`State` 文档中明确指出：

> You should only access a state property from inside the view’s body, or from methods called by it.

虽然 `DetailView3` 可以按照预期工作，但通过 `DispatchQueue.main.async` 中来访问和更改 state，是不是推荐的做法，还是存疑的。另外，由于实际上 `body` 有可能被多次求值，所以这部分代码会多次运行，你必须考虑它在 body 被重新求值时的正确性 (比如我们需要加入 `number == nil` 判断，才能避免重复设值)。在造成浪费的同时，这也增加了维护的难度。

对于这种方法，一个更好的设置初值的地方是在 `onAppear` 中：

```swift
struct DetailView4: View {
    @State private var number: Int = 0
    private var tempNumber: Int

    init(number: Int) {
        self.tempNumber = number + 1
    }

    var body: some View {
        HStack {
            Text("4: \(number)")
            Button("+") { number += 1 }
        }.onAppear {
            number = tempNumber
        }
    }
}
```

虽然 `ContentView`中每次 `body` 被求值时，`DetailView4.init` 都会将 `tempNumber` 设置为最新的传入值，但是 `DetailView4.body` 中的 `onAppear` 只在最初出现在屏幕上时被调用一次。在拥有一定初始化逻辑的同时，避免了多次设置。

## State, Binding, StateObject, ObservedObject

`@StateObject` 的情况和 `@State` 很类似：View 都拥有对这个状态的所有权，它们不会随着新的 View init 而重新初始化。这个行为和 `Binding` 以及 `ObservedObject` 是正好相反的：使用 `Binding` 和 `ObservedObject` 的话，意味着 View 不会负责底层的存储，开发者需要自行决定和维护“非所有”状态的声明周期。

当然，如果 `DetailView` 不需要自己拥有且独立管理的状态，而是想要直接使用 `ContentView` 中的值，且将这个值的更改反馈回去的话，使用标准的 `@Bining` 是毫无疑问的：

```swift
struct DetailView5: View {
    @Binding var number: Int
    var body: some View {
        HStack {
            Text("5: \(number)")
            Button("+") { number += 1 }
        }
    }
}
```

在[之前的一篇文章](/2020/06/stateobject/) 中，我们已经详细探讨了这方面的内容。如果有兴趣的话，不妨花时间读读看。

## 状态重设

对于文中的情景，想要对本地的 `State` (或者 `StateObject`) 在初始化时进行操作，最合适的方式还是通过在 `.onAppear` 里赋值来完成。如果想要在初次设置后，再次将父 view 的值“同步”到子 view 中去，可以选择使用 `id` modifier 来将子 view 上的已有状态清除掉。在一些场景下，这也会非常有用：

```swift
struct ContentView: View {
    @State private var value = 99

    var identifier: String {
        value < 105 ? "id1" : "id2"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            DetailView(number: value)
            Button("+") { value += 1 }
            Divider()
            DetailView4(number: value)
                .id(identifier)
    }
}
```

被 `id` modifier 修饰后，每次 `body` 求值时，`DetailView4` 将会检查是否具有相同的 `identifier`。如果出现不一致，在 graph 中的原来的 `DetailView4` 将被废弃，所有状态将被清除，并被重新创建。这样一来，最新的 `value` 值将被重新通过初始化方法设置到 `DetailView4.tempNumber`。而这个新 `View` 的 `onAppear` 也会被触发，最终把处理后的输入值再次显示出来。

## 总结

对于 `@State` 来说，严格遵循文档所预想的使用方式，避免在 body 以外的地方获取和设置它的值，会避免不少麻烦。正确理解 `@State` 的工作方式和各个变化发生的时机，能让我们在迷茫时找到正确的分析方向，并最终对这些行为给出合理的解释和预测。

