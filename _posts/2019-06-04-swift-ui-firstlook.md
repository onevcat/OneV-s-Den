---
layout: post
title: "SwiftUI 的一些初步探索 (一)"
date: 2019-06-04 15:32:00.000000000 +09:00
tags: 能工巧匠集
---

![](/assets/images/2019/swift-ui.png)

> 我已经计划写一本关于 SwiftUI 和 Combine 编程的书籍，希望能通过一些实践案例帮助您快速上手 SwiftUI 及 Combine 响应式编程框架，掌握下一代客户端 UI 开发技术。现在这本书已经开始预售，预计能在 10 月左右完成。如果您对此有兴趣，可以查看 [ObjC 中国的产品页面](https://objccn.io/products/)了解详情及购买。十分感谢！

## 总览

如果你想要入门 SwiftUI 的使用，那 Apple 这次给出的[官方教程](https://developer.apple.com/tutorials/swiftui)绝对给力。这个教程提供了非常详尽的步骤和说明，网页的交互也是一流，是觉得值得看和动手学习的参考。

不过，SwiftUI 中有一些值得注意的细节在教程里并没有太详细提及，也可能造成一些困惑。这篇文章以我的个人观点对教程的某些部分进行了补充说明，希望能在大家跟随教程学习 SwiftUI 的时候有点帮助。这篇文章的推荐阅读方式是，一边参照 SwiftUI 教程实际动手进行实现，一边在到达对应步骤时参照本文加深理解。在下面每段内容前我标注了对应的教程章节和链接，以供参考。

在开始学习 SwiftUI 之前，我们需要大致了解一个问题：为什么我们会需要一个新的 UI 框架。

## 为什么需要 SwiftUI

### UIKit 面临的挑战

对于 Swift 开发者来说，昨天的 WWDC 19 首日 Keynote 和 Platforms State of the Union 上最引人注目的内容自然是 SwiftUI 的公布了。从 iOS SDK 2.0 开始，UIKit 已经伴随广大 iOS 开发者经历了接近十年的风风雨雨。UIKit 的思想继承了成熟的 AppKit 和 MVC，在初出时，为 iOS 开发者提供了良好的学习曲线。

UIKit 提供的是一套符合直觉的，基于控制流的命令式的编程方式。最主要的思想是在确保 View 或者 View Controller 生命周期以及用户交互时，相应的方法 (比如 `viewDidLoad` 或者某个 target-action 等) 能够被正确调用，从而构建用户界面和逻辑。不过，不管是从使用的便利性还是稳定性来说，UIKit 都面临着巨大的挑战。我个人勉强也能算是 iOS 开发的“老司机”了，但是「掉到 UIKit 的坑里」这件事，也几乎还是我每天的日常。UIKit 的基本思想要求 View Controller 承担绝大部分职责，它需要协调 model，view 以及用户交互。这带来了巨大的 side effect 以及大量的状态，如果没有妥善安置，它们将在 View Controller 中混杂在一起，同时作用于 view 或者逻辑，从而使状态管理愈发复杂，最后甚至不可维护而导致项目失败。不仅是作为开发者我们自己写的代码，UIKit 本身内部其实也经常受困于可变状态，各种奇怪的 bug 也频频出现。

### 声明式的界面开发方式

近年来，随着编程技术和思想的进步，使用声明式或者函数式的方式来进行界面开发，已经越来越被接受并逐渐成为主流。最早的思想大概是来源于 [Elm](https://elm-lang.org)，之后这套方式被 [React](https://reactjs.org) 和 [Flutter](https://flutter.dev) 采用，这一点上 SwiftUI 也几乎与它们一致。总结起来，这些 UI 框架都遵循以下步骤和原则：

1. 使用各自的 DSL 来描述「UI 应该是什么样子」，而不是用一句句的代码来指导「要怎样构建 UI」。

    比如传统的 UIKit，我们会使用这样的代码来添加一个 “Hello World” 的标签，它负责“创建 label”，“设置文字”，“将其添加到 view 上”：

    ```swift
    func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "Hello World"
        view.addSubview(label)
        // 省略了布局的代码
    }
    ```
    
    而相对起来，使用 SwiftUI 我们只需要告诉 SDK 我们需要一个文字标签：
    
    ```swift
    var body: some View {
        Text("Hello World")
    }
    ```
    
2. 接下来，框架内部读取这些 view 的声明，负责将它们以合适的方式绘制渲染。

    注意，这些 view 的声明只是纯数据结构的描述，而不是实际显示出来的视图，因此这些结构的创建和差分对比并不会带来太多性能损耗。相对来说，将描述性的语言进行渲染绘制的部分是最慢的，这部分工作将交由框架以黑盒的方式为我们完成。
    
1. 如果 `View` 需要根据某个状态 (state) 进行改变，那我们将这个状态存储在变量中，并在声明 view 时使用它：

    ```swift
    @State var name: String = "Tom"
    var body: some View {
        Text("Hello \(name)")
    }
    ```
    
    > 关于代码细节可以先忽略，我们稍后会更多地解释这方面的内容。
    
1. 状态发生改变时，框架重新调用声明部分的代码，计算出新的 view 声明，并和原来的 view 进行差分，之后框架负责对变更的部分进行高效的重新绘制。

SwiftUI 的思想也完全一样，而且实际处理也不外乎这几个步骤。使用描述方式开发，大幅减少了在 app 开发者层面上出现问题的机率。

## 一些细节解读

[官方教程](https://developer.apple.com/tutorials/swiftui)中对声明式 UI 的编程思想有深刻的体现。另外，SwiftUI 中也采用了非常多 Swift 5.1 的新特性，会让习惯了 Swift 4 或者 5 的开发者“耳目一新”。接下来，我会分几个话题，对官方教程的一些地方进行解释和探索。

### [教程 1 - Creating and Combining Views](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views)

#### [Section 1 - Step 3: SwiftUI app 的启动](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views#create-a-new-project-and-explore-the-canvas)

创建 app 之后第一件好奇的事情是，SwiftUI app 是怎么启动的。

教程示例 app 在 AppDelegate 中通过 `application(_:configurationForConnecting:options)` 返回了一个名为 "Default Configuration" 的 `UISceneConfiguration` 实例：

```swift
func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions) -> UISceneConfiguration
{
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
}
```

这个名字的 Configuration 在 Info.plist 的 “UIApplicationSceneManifest -> UISceneConfigurations” 中进行了定义，指定了 Scene Session Delegate 类为 `$(PRODUCT_MODULE_NAME).SceneDelegate`。这部分内容是 iOS 13 中新加入的通过 Scene 管理 app 生命周期的方式，以及多窗口支持部分所需要的代码。这部分不是我们今天的话题。在 app 完成启动后，控制权被交接给 `SceneDelegate`，它的 `scene(_:willConnectTo:options:)` 将会被调用，进行 UI 的配置：

```swift
func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions)
    {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
```

这部分内容就是标准的 iOS app 启动流程了。`UIHostingController` 是一个 `UIViewController` 子类，它将负责接受一个 SwiftUI 的 View 描述并将其用 UIKit 进行渲染 (在 iOS 下的情况)。`UIHostingController` 就是一个普通的 `UIViewController`，因此完全可以做到将 SwiftUI 创建的界面一点点集成到已有的 UIKit app 中，而并不需要从头开始就是基于 SwiftUI 的构建。

由于 Swift ABI 已经稳定，SwiftUI 是一个搭载在用户 iOS 系统上的 Swift 框架。因此它的最低支持的版本是 iOS 13，可能想要在实际项目中使用，还需要等待一两年时间。

#### [Section 1 - Step 4: 关于 some View](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views#create-a-new-project-and-explore-the-canvas)

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello World")
    }
}
```

一眼看上去可能会对 `some` 比较陌生，为了讲明白这件事，我们先从 `View` 说起。

`View` 是 SwiftUI 的一个最核心的协议，代表了一个屏幕上元素的描述。这个协议中含有一个 associatedtype：

```swift
public protocol View : _View {
    associatedtype Body : View
    var body: Self.Body { get }
}
```

这种带有 associatedtype 的协议不能作为**类型**来使用，而只能作为**类型约束**使用：

```swift
// Error
func createView() -> View {

}

// OK
func createView<T: View>() -> T {
    
}
```

这样一来，其实我们是不能写类似这种代码的：

```swift
// Error，含有 associatedtype 的 protocol View 只能作为类型约束使用
struct ContentView: View {
    var body: View {
        Text("Hello World")
    }
}
```

想要 Swift 帮助自动推断出 `View.Body` 的类型的话，我们需要明确地指出 `body` 的真正的类型。在这里，`body` 的实际类型是 `Text`：

```swift
struct ContentView: View {
    var body: Text {
        Text("Hello World")
    }
}
```

当然我们可以明确指定出 `body` 的类型，但是这带来一些麻烦：

1. 每次修改 `body` 的返回时我们都需要手动去更改相应的类型。
2. 新建一个 `View` 的时候，我们都需要去考虑会是什么类型。
3. 其实我们只关心返回的是不是一个 `View`，而对实际上它是什么类型并不感兴趣。

`some View` 这种写法使用了 Swift 5.1 的 [Opaque return types 特性](https://github.com/apple/swift-evolution/blob/master/proposals/0244-opaque-result-types.md)。它向编译器作出保证，每次 `body` 得到的一定是某一个确定的，遵守 `View` 协议的类型，但是请编译器“网开一面”，不要再细究具体的类型。返回类型**确定单一**这个条件十分重要，比如，下面的代码也是无法通过的：

```swift

let someCondition: Bool

// Error: Function declares an opaque return type, 
// but the return statements in its body do not have 
// matching underlying types.
var body: some View {
    if someCondition {
        // 这个分支返回 Text
        return Text("Hello World")
    } else {
        // 这个分支返回 Button，和 if 分支的类型不统一
        return Button(action: {}) {
            Text("Tap me")
        }
    }
}
```

这是一个编译期间的特性，在保证 associatedtype protocol 的功能的前提下，使用 `some` 可以抹消具体的类型。这个特性用在 SwiftUI 上简化了书写难度，让不同 `View` 声明的语法上更加统一。

#### [Section 2 - Step 1: 预览 SwiftUI](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views#customize-the-text-view)

SwiftUI 的 Preview 是 Apple 用来对标 RN 或者 Flutter 的 Hot Reloading 的开发工具。由于 IBDesignable 的性能上的惨痛教训，而且得益于 SwiftUI 经由 UIKit 的跨 Apple 平台的特性，Apple 这次选择了直接在 macOS 上进行渲染。因此，你需要使用搭载有 SwiftUI.framework 的 macOS 10.15 才能够看到 Xcode Previews 界面。

Xcode 将对代码进行静态分析 (得益于 [SwiftSyntax 框架](https://github.com/apple/swift-syntax))，找到所有遵守 `PreviewProvider` 协议的类型进行预览渲染。另外，你可以为这些预览提供合适的数据，这甚至可以让整个界面开发流程不需要实际运行 app 就能进行。

笔者自己尝试下来，这套开发方式带来的效率提升相比 Hot Reloading 要更大。Hot Reloading 需要你有一个大致界面和准备相应数据，然后运行 app，停在要开发的界面，再进行调整。如果数据状态发生变化，你还需要 restart app 才能反应。SwiftUI 的 Preview 相比起来，不需要运行 app 并且可以提供任何的 dummy 数据，在开发效率上更胜一筹。

经过短短一天的使用，Option + Command + P 这个刷新 preview 的快捷键已经深入到我的肌肉记忆中了。

#### [Section 3 - Step 5: 关于 ViewBuilder](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views#combine-views-using-stacks)

创建 Stack 的语法很有趣：

```swift
VStack(alignment: .leading) {
    Text("Turtle Rock")
        .font(.title)
    Text("Joshua Tree National Park")
        .font(.subheadline)
}
```

一开始看起来好像我们给出了两个 `Text`，似乎是构成的是一个类似数组形式的 `[View]`，但实际上并不是这么一回事。这里调用了 `VStack` 类型的初始化方法：

```swift
public struct VStack<Content> where Content : View {
    init(
        alignment: HorizontalAlignment = .center, 
        spacing: Length? = nil, 
        content: () -> Content)
}
```

前面的 `alignment` 和 `spacing` 没啥好说，最后一个 `content` 比较有意思。看签名的话，它是一个 `() -> Content` 类型，但是我们在创建这个 `VStack` 时所提供的代码只是简单列举了两个 `Text`，而并没有实际返回一个可用的 `Content`。

这里使用了 Swift 5.1 的另一个新特性：[Funtion builders](https://github.com/apple/swift-evolution/blob/9992cf3c11c2d5e0ea20bee98657d93902d5b174/proposals/XXXX-function-builders.md)。如果你实际观察 `VStack` 的[这个初始化方法的签名](https://developer.apple.com/documentation/swiftui/vstack/3278367-init)，会发现 `content` 前面其实有一个 `@ViewBuilder` 标记：

```swift
init(
    alignment: HorizontalAlignment = .center, 
    spacing: Length? = nil, 
    @ViewBuilder content: () -> Content)
```


而 `ViewBuilder` 则是一个由 `@_functionBuilder` 进行标记的 struct：

```swift
@_functionBuilder public struct ViewBuilder { /* */ }
```

使用 `@_functionBuilder` 进行标记的类型 (这里的 `ViewBuilder`)，可以被用来对其他内容进行标记 (这里用 `@ViewBuilder` 对 `content` 进行标记)。被用 function builder 标记过的 `ViewBuilder` 标记以后，`content` 这个输入的 function 在被使用前，会按照 `ViewBuilder` 中合适的 `buildBlock` [进行 build](https://github.com/apple/swift-evolution/blob/9992cf3c11c2d5e0ea20bee98657d93902d5b174/proposals/XXXX-function-builders.md#function-building-methods) 后再使用。如果你阅读 `ViewBuilder` 的[文档](https://developer.apple.com/documentation/swiftui/viewbuilder)，会发现有很多接受不同个数参数的 `buildBlock` 方法，它们将负责把闭包中一一列举的 `Text` 和其他可能的 `View` 转换为一个 `TupleView`，并返回。由此，`content` 的签名 `() -> Content` 可以得到满足。

实际上构建这个 `VStack` 的代码会被转换为类似下面这样：

```swift
// 等效伪代码，不能实际编译。
VStack(alignment: .leading) { viewBuilder -> Content in
    let text1 = Text("Turtle Rock").font(.title)
    let text2 = Text("Joshua Tree National Park").font(.subheadline)
    return viewBuilder.buildBlock(text1, text2)
}
```

当然这种基于 funtion builder 的方式是有一定限制的。比如 `ViewBuilder` 就只实现了最多[十个参数](https://developer.apple.com/documentation/swiftui/viewbuilder/3278693-buildblock)的 `buildBlock`，因此如果你在一个 `VStack` 中放超过十个 `View` 的话，编译器就会不太高兴。不过对于正常的 UI 构建，十个参数应该足够了。如果还不行的话，你也可以考虑直接使用 `TupleView` 来用多元组的方式合并 `View`：

```swift
TupleView<(Text, Text)>(
    (Text("Hello"), Text("Hello"))
)
```

除了按顺序接受和构建 `View` 的 `buildBlock` 以外，`ViewBuilder` 还实现了两个特殊的方法：`buildEither` 和 `buildIf`。它们分别对应 block 中的 `if...else` 的语法和 `if` 的语法。也就是说，你可以在 `VStack` 里写这样的代码：

```swift
var someCondition: Bool

VStack(alignment: .leading) {
    Text("Turtle Rock")
        .font(.title)
    Text("Joshua Tree National Park")
        .font(.subheadline)
    if someCondition {
        Text("Condition")
    } else {
        Text("Not Condition")
    }
}
```

其他的命令式的代码在 `VStack` 的 `content` 闭包里是不被接受的，下面这样也不行：

```swift
VStack(alignment: .leading) {
    // let 语句无法通过 function builder 创建合适的输出
    let someCondition = model.condition
    if someCondition {
        Text("Condition")
    } else {
        Text("Not Condition")
    }
}
```

到目前为止，只有以下三种写法能被接受 (有可能随着 SwiftUI 的发展出现别的可接受写法)：

* 结果为 `View` 的语句
* `if` 语句
* `if...else...` 语句

#### [Section 4 - Step 7: 链式调用修改 View 的属性](https://developer.apple.com/tutorials/swiftui/creating-and-combining-views#create-a-custom-image-view)

教程到这一步的话，相信大家已经对 SwiftUI 的超强表达能力有所感悟了。

```swift
var body: some View {
    Image("turtlerock")
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white, lineWidth: 4))
        .shadow(radius: 10)
}
```

可以试想一下，在 UIKit 中要动手撸一个这个效果的困难程度。我大概可以保证，99% 的开发者很难在不借助文档或者 copy paste 的前提下完成这些事情，但是在 SwiftUI 中简直信手拈来。在创建 `View` 之后，用链式调用的方式，可以将 `View` 转换为一个含有变更后内容的对象。这么说比较抽象，我们可以来看一个具体的例子。比如简化一下上面的代码：

```swift
let image: Image = Image("turtlerock")
let modified: _ModifiedContent<Image, _ShadowEffect> = image.shadow(radius: 10)
```

`image` 通过一个 `.shadow` 的 modifier，`modified` 变量的类型将转变为 `_ModifiedContent<Image, _ShadowEffect>`。如果你查看 `View` 上的 `shadow` 的定义，它是这样的：

```swift
extension View {
    func shadow(
        color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), 
        radius: Length, x: Length = 0, y: Length = 0) 
    -> Self.Modified<_ShadowEffect>
}
```

`Modified` 是 `View` 上的一个 typealias，在 `struct Image: View` 的实现里，我们有：

```swift
public typealias Modified<T> = _ModifiedContent<Self, T>
```

`_ModifiedContent` 是一个 SwiftUI 的私有类型，它存储了待变更的内容，以及用来实施变更的 `Modifier`：

```swift
struct _ModifiedContent<Content, Modifier> {
    var content: Content
    var modifier: Modifier
}
```

在 `Content` 遵守 `View`，`Modifier` 遵守 `ViewModifier` 的情况下，`_ModifiedContent` 也将遵守 `View`，这是我们能够通过 `View` 的各个 modifier extension 进行链式调用的基础：

```swift
extension _ModifiedContent : _View 
    where Content : View, Modifier : ViewModifier 
{
}
```

在 `shadow` 的例子中，SwiftUI 内部会使用 `_ShadowEffect` 这个 `ViewModifier`，并把 `image` 自身和 `_ShadowEffect` 实例存放到 `_ModifiedContent` 里。不论是 image 还是 modifier，都只是对未来实际视图的描述，而不是直接对渲染进行的操作。在最终渲染前，`ViewModifier` 的 `body(content: Self.Content) -> Self.Body` 将被调用，以给出最终渲染层所需要的各个属性。

> 更具体来说，`_ShadowEffect` 是一个满足 [`EnvironmentalModifier` 协议](https://developer.apple.com/documentation/swiftui/environmentalmodifier)的类型，这个协议要求在使用前根据使用环境将自身解析为具体的 modifier。

其他的几个修改 View 属性的链式调用与 `shadow` 的原理几乎一致。


## 小结

上面是对 SwiftUI 教程的第一部分进行的一些说明，在之后的一篇文章里，我会对剩余的几个教程中有意思的部分再做些解释。

虽然公开还只有一天，但是 SwiftUI 已经经常被用来和 Flutter 等框架进行比较。试用下来，在 view 的描述表现力上和与 app 的结合方面，SwiftUI 要胜过 Flutter 和 Dart 的组合很多。Swift 虽然开源了，但是 Apple 对它的掌控并没有减弱。Swift 5.1 的很多特性几乎可以说都是为了 SwiftUI 量身定制的，我们已经在本文中看到了一些例子，比如 Opaque return types 和 Function builder 等。在接下来对后面几个教程的解读中，我们还会看到更多这方面的内容。

另外，Apple 在背后使用 Combine.framework 这个响应式编程框架来对 SwiftUI.framework 进行驱动和数据绑定，相比于现有的 RxSwift/RxCocoa 或者是 ReactiveSwift 的方案来说，得到了语言和编译器层级的大力支持。如果有机会，我想我也会对这方面的内容进行一些探索和介绍。