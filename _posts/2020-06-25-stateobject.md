---
layout: post
title: "@StateObject 和 @ObservedObject 的区别和使用"
date: 2020-06-25 12:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, swiftui, 设计模式, 最佳实践, 状态管理]
---

> WWDC 2020 中，SwiftUI 迎来了非常多的变更。相比于 2019 年的初版，可以说 SwiftUI 达到了一个相对可用的状态。从这篇文章开始，我打算写几篇文章来介绍一些重要的变化和新追加的内容。如果你需要 SwiftUI 的入门和基本概念的材料，我参与的两本书籍[《SwiftUI 与 Combine 编程》](https://objccn.io/products/swift-ui)和[《SwiftUI 编程思想》](https://objccn.io/products/thinking-in-swiftui)依然会是很好的选择。

### 字太多，不想看，长求总

`@ObservedObject` 不管存储，会随着 `View` 的创建被多次创建。而 `@StateObject` 保证对象只会被创建一次。因此，如果是在 `View` 里自行创建的 `ObservableObject` model 对象，大概率来说使用 `@StateObject` 会是更正确的选择。`@StateObject` 基本上来说就是一个针对 class 的 `@State` 升级版。

如果你对详细内容感兴趣，想知道整个故事的始末，可以继续阅读。

### 初版 SwiftUI 的状态管理

在 2019 年 SwiftUI 刚问世时，除去专门用来管理手势的 `@GestureState` 以外，有三个常用的和状态管理相关的 property wrapper，它们分别是 `@State`，`@ObservedObject` 和 `@EnvironmentObject`。根据职责和作用范围不同，它们各自的适用场景也有区别。一般来说：

- `@State` 用于 `View` 中的私有状态值，一般来说它所修饰的都应该是 struct 值，并且不应该被其他的 view 看到。它代表了 SwiftUI 中作用范围最小，本身也最简单的状态，比如一个 `Bool`，一个 `Int` 或者一个 `String`。简单说，如果一个状态能够被标记为 `private` 并且它是值类型，那么 `@State` 是适合的。
- 对于更复杂的一组状态，我们可以将它组织在一个 class 中，并让其实现 `ObservableObject` 协议。对于这样的 class 类型，其中被标记为 `@Published` 的属性，将会在变更时自动发出事件，通知对它有依赖的 `View` 进行更新。`View` 中如果需要依赖这样的 `ObservableObject` 对象，在声明时则使用 `@ObservedObject` 来订阅。
- `@EnvironmentObject` 针对那些需要传递到深层次的子 `View` 中的 `ObservableObject` 对象，我们可以在父层级的 `View` 上用 `.environmentObject` 修饰器来将它注入到环境中，这样任意子 `View` 都可以通过 `@EnvironmentObject` 来获取对应的对象。

这基本就是初版 SwiftUI 状态管理的全部了。

![](/assets/images/2020/48b8f3b0ed887f90b8d420b137fb3689.jpg)

看起来对于状态管理，SwiftUI 的覆盖已经很全面了，那为什么要新加一个 `@StateObject` property wrapper 呢？为了弄清这个问题，我们先要来看看 `@ObservedObject` 存在的问题。

### @ObservedObject 有什么问题

我们来考虑实现下面这样的界面：

![](/assets/images/2020/stateobject_app.png)

点击“Toggle Name”时，Current User 在真实名字和昵称之间转换。点击 “+1” 时，无条件为这个 `View` ~~续一秒~~  显示的 Score 增加 1。

来看看下面的代码，算上空行也就五十行不到：

```swift
struct ContentView: View {
    @State private var showRealName = false
    var body: some View {
        VStack {
            Button("Toggle Name") {
                showRealName.toggle()
            }
            Text("Current User: \(showRealName ? "Wei Wang" : "onevcat")")
            ScorePlate().padding(.top, 20)
        }
    }
}

class Model: ObservableObject {
    init() { print("Model Created") }
    @Published var score: Int = 0
}

struct ScorePlate: View {

    @ObservedObject var model = Model()
    @State private var niceScore = false

    var body: some View {
        VStack {
            Button("+1") {
                if model.score > 3 {
                    niceScore = true
                }
                model.score += 1
            }
            Text("Score: \(model.score)")
            Text("Nice? \(niceScore ? "YES" : "NO")")
            ScoreText(model: model).padding(.top, 20)
        }
    }
}

struct ScoreText: View {
    @ObservedObject var model: Model

    var body: some View {
        if model.score > 10 {
            return Text("Fantastic")
        } else if model.score > 3 {
            return Text("Good")
        } else {
            return Text("Ummmm...")
        }
    }
}
```

简单解释一下行为：

对于 Toggle Name 按钮和 Current User 标签，直接写在了 `ContentView` 中。+1 按钮和显示分数以及分数状态的部分，则被封装到一个叫 `ScorePlate` 的 `View` 里。它需要一个模型来记录分数，也就是 `Model`。在 `ScorePlate` 中，我们将它声明为了一个 `@ObservedObject` 变量：

```swift
struct ScorePlate: View {
    @ObservedObject var model = Model()
    //...
}
```

除了 `Model` 外，我们还在 `ScorePlate` 里添加了另一个私有的布尔状态 `@State niceScore`。每次 +1 时，除了让 `model.score` 增加外，还检查了它是否大于三，并且依此设置 `niceScore`。我们可以用它来考察 `@State` 和 `@ObservedObject` 行为上的不同。

最后，最下面一行是另外一个 `View`：`ScoreText`。它也含有一个 `@ObservedObject` 的 `Model`，并根据 score 值来决定要显示的文本内容。这个 `model` 会在初始化时传入：

```swift
struct ScorePlate: View {
    var body: some View {
        // ...
        ScoreText(model: model).padding(.top, 20)
    }
}
```

> 当然，在这个例子中，其实使用一个简单的 `@State` 的 `Int` 值就够了，但是为了说明问题，还是生造了一个 `Model` 这把牛刀来杀鸡。实际项目中 `Model` 肯定是会比一个 `Int` 要来得更复杂。

当我们尝试运行的时候，“+1” 按钮可以完美工作，“Nice” 和 “Ummmm...” 文本也能够按照预期改变，一切都很完美...直到我们想要用 “Toggle Name” 改变一下名字：

![](/assets/images/2020/stateobject_reset.gif)

除了 (被 `@State` 驱动的) Nice 标签，`ScorePlate` 的其他文本都被一个看似不相关的操作重置了！这显然不是我们想要的行为。

> (为节约流量和尊重 BLM，此处请自行脑补非洲裔问号图)

这是因为，和 `@State` 这种底层存储被 SwiftUI “全面接管” 的状态不同，`@ObservedObject` 只是在 `View` 和 `Model` 之间添加订阅关系，而不影响存储。因此，当 `ContentView` 中的状态发生变化，`ContentView.body` 被重新求值时，`ScorePlate` 就会被重新生成，其中的 `model` 也一同重新生成，导致了状态的“丢失”。运行代码，在 Xcode console 中可以看到每次点击 Toggle 按钮时都伴随着 `Model.init` 的输出。

> Nice 标签则不同，它是由 `@State` 驱动的：由于 `View` 是不可变的 struct，它的状态改变需要底层存储的支持。SwiftUI 将为 `@State` 创建额外的存储空间，来保证在 `View` 刷新 (也就是重新创建时)，状态能够保持。但这对 `@ObservedObject` 并不适用。

### 保证单次创建的 @StateObject

只要理解了 `@ObservedObject` 存在的问题，`@StateObject` 的意义也就很明显了。`@StateObject` 就是 `@State` 的升级版：`@State` 是针对 struct 状态所创建的存储，`@StateObject` 则是针对 `ObservableObject` class 的存储。它保证这个 class 实例不会随着 `View` 被重新创建。从而解决问题。

在上面这个具体的例子中，只要把 `ScorePlate` 中的 `@ObservedObject` 改成 `@StateObject`，就万事大吉了：

```swift
struct ScorePlate: View {
    // @ObservedObject var model = Model()
    @StateObject var model = Model()
}
```

现在，`ScorePlate` 和 `ScoreText` 里的状态不会被重置了。

那么，一个自然而然引申出的问题是，我们是不是应该把所有的 `@ObservedObject` 都换成 `@StateObject`？比如上面例子中需要把 `ScoreText` 里的声明也进行替换吗？这看实际上你的 `View` 到底期望怎样的行为：如果不希望 model 状态在 View 刷新时丢失，那确实可以进行替换，这 (虽然可能会对性能有一些影响，但) 不会影响整体的行为。但是，如果 `View` 本身就期望每次刷新时获得一个全新的状态，那么对于那些不是自己创建的，而是从外界接受的 `ObservableObject` 来说，`@StateObject` 反而是不合适的。

### 更多的讨论

#### 使用 `@EnvironmentObject` 保持状态

除了 `@StateObject` 外，另一种让状态 object 保持住的方式，是在更外层使用 `.environmentObject`：

```swift
struct SwiftUINewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(Model())
        }
    }
}
```

这样，model 对象将被注入到环境中，不再随着 `ContentView` 的刷新而变更。在使用时，只需要遵循普通的 environment 方式，把 `Model` 声明为 `@EnvironmentObject` 就行了：

```swift
struct ScorePlate: View {
    @EnvironmentObject var model: Model
    // ...
    
    // ScoreText(model: model).padding(.top, 20)
    ScoreText().padding(.top, 20)
}

struct ScoreText: View {
    @EnvironmentObject var model: Model
    // ...
}
```

#### 和 `@State` 保持同样的生命周期

除了确保单次创建外，`@StateObject` 的另一个重要特性是和 `@State` 的“生命周期”保持统一，让 SwiftUI 全面接管背后的存储，也可以避免一些不必要的 bug。

在 `ContentView` 上稍作修改，把 `ScorePlate()` 放到一个 `NavigationLink` 中，就能看到结果：

```swift
var body: some View {
  NavigationView {
    VStack {
      Button("Toggle Name") {
        showRealName.toggle()
      }
      Text("Current User: \(showRealName ? "Wei Wang" : "onevcat")")
      NavigationLink("Next", destination: ScorePlate().padding(.top, 20))
    }
  }
}
```

当点击 “Next” 时，会导航到 `ScorePlate` 页面，可以在那里进行 +1 操作。当点击 Back button 回到 `ContentView`，并再次点击 “Next” 时，一般情况下我们会希望 `ScorePlate` 的状态被重置，得到一个全新的，从 0 开始的状态。此时使用 `@StateObject` 可以工作良好，因为 SwiftUI 帮助我们重建了 `@State` 和 `@StateObject`。而如果我们将 `ScorePlate` 里的声明从 `@StateObject` 改回 `@ObservedObject` 的话，SwiftUI 将不再能够帮助我们进行状态管理，除非通过 “Toggle” 按钮刷新整个 `ContentView`，否则 `ScorePlate` 在再次展示时将保留原来的状态。

> 当然，如果你有意想要在 `ScorePlate` 保留这些状态的话，使用 `@ObservedObject` 或者上面的 `@EnvironmentObject` 的方式才是正确的选择。

### 总结

简单说，对于 `View` 自己创建的 `ObservableObject` 状态对象来说，极大概率你可能需要使用新的 `@StateObject` 来让它的存储和生命周期更合理：

```swift
struct MyView: View {
    @StateObject var model = Model()
}
```

而对于那些从外界接受 `ObservableObject` 的 `View`，究竟是使用 `@ObservedObject` 还是 `@StateObject`，则需要根据情况和需要确定。像是那些存在于 `NavigationLink` 的 `destination` 中的 `View`，由于 SwiftUI 对它们的构建时机并没有做 lazy 处理，在处理它们时，需要格外小心。

不论哪种情况，彻底弄清楚两者的区别和背后的逻辑，可以帮助我们更好地理解一个 SwiftUI app 的行为模式。

