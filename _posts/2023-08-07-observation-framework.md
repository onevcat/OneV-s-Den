---
layout: post
title: "深入理解 Observation - 原理，back porting 和性能"
date: 2023-08-07 09:15:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, swiftui, 状态管理, 兼容, 性能]
typora-root-url: ..
---

SwiftUI 遵循 Single Source of Truth 的原则，只有修改 View 所订阅的状态，才能改变 view tree 并触发对 body 的重新求值，进而刷新 UI。最初发布时，SwiftUI 提供了 `@State`、`@ObservedObject` 和 `@EnvironmentObject` 等属性包装器进行状态管理。在 iOS 14 中，Apple 添加了 `@StateObject`，它补全了 `View` 中持有引用类型实例的情况，使得 SwiftUI 的状态管理更加完善。

在订阅引用类型时，`ObservableObject` 扮演着 Model 类型的角色，但它存在一个严重的问题，即无法提供属性粒度的订阅。在 SwiftUI 的 View 中，对 `ObservableObject` 的订阅是基于整个实例的。只要 `ObservableObject` 上的任何一个 `@Published` 属性发生改变，都会触发整个实例的 `objectWillChange` 发布者发出变化，进而导致所有订阅了这个对象的 View 进行重新求值。在复杂的 SwiftUI 应用中，这可能会导致严重的性能问题，并且阻碍程序的可扩展性。因此，使用者需要精心设计数据模型，以避免大规模的性能退化。

在 WWDC 23 中，Apple 推出了全新的 Observation 框架，旨在解决 SwiftUI 上的状态管理混乱和性能问题。这个框架的工作方式看似非常神奇，甚至无需特别声明，就能在 View 中实现属性粒度的订阅，从而避免不必要的刷新。本篇文章将深入探讨背后的原理，帮助您：

- 理解 Observation 框架的实质和实现机制
- 比较其与之前解决方案的优势所在
- 探讨在处理 SwiftUI 状态管理时的一些权衡与考虑

通过阅读本文，您将对 SwiftUI 中的新 Observation 框架有更清晰的认识，了解它为开发者带来的好处，并掌握在实际应用中做出明智选择的能力。

我们先来看看 Observation 做了些什么吧。

## Observation 框架的工作方式

Observation 的使用非常简单，您只需要在模型类的声明前加上 `@Observable` 标记，就可以轻松地在 View 中使用了：一旦模型类实例的存储属性或计算属性发生变化，`View` 的 `body` 就会自动重新求值，并刷新 UI。

```swift
import Observation

@Observable final class Chat {
  var message: String
  var alreadyRead: Bool
  
  init(message: String, alreadyRead: Bool) {
    self.message = message
    self.alreadyRead = alreadyRead
  }
}

var chat = Chat(message: "Sample Message", alreadyRead: false)
struct ContentView: View {
  var body: some View {
    let _ = Self._printChanges()
    Label("Message",
      systemImage: chat.alreadyRead ? "envelope.open" : "envelope"
    )
    Button("Read") {
      chat.alreadyRead = true
    }
  }
}
```

> 虽然大多数情况下我们更倾向于使用 struct 来表示数据模型，但是 @Observable 只能用在 class 类型上。这是因为对于可变的内部状态，我们只能在引用类型的稳定实例上进行状态监测才有意义。

初次接触时，`@Observable` 的确有点像魔法：我们无需声明 chat 和 ContentView 之间的任何关系，只需在 `View.body` 中访问 `alreadyRead` 属性，就自动完成了订阅。关于 `@Observable` 在 SwiftUI 中的具体使用以及从 `ObservableObject` 迁移到 `@Observable` 的内容，WWDC 23 的 [Discover Observation in SwiftUI session](https://developer.apple.com/videos/play/wwdc2023/10149/) 提供了详细解释。我们建议您观看相关视频，深入了解这一新特性的使用方法和优势。

### Observable 宏，宏的展开

`@Observable` 虽然看起来和其他属性包装器有些相似，但是它实际上是 Swift 5.9 引入的宏。想要理解它背后做了什么，我们可以展开这个宏：

![](/assets/images/2023/expand-macro.png)

```swift
@Observable final class Chat {
  @ObservationTracked
  var message: String
  @ObservationTracked
  var alreadyRead: Bool
    
  @ObservationIgnored private var _message: String
  @ObservationIgnored private var _alreadyRead: Bool
    
  @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

  internal nonisolated func access<Member>(
    keyPath: KeyPath<Chat , Member>
  ) {
    _$observationRegistrar.access(self, keyPath: keyPath)
  }

  internal nonisolated func withMutation<Member, T>(
    keyPath: KeyPath<Chat , Member>,
    _ mutation: () throws -> T
  ) rethrows -> T {
    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
  }
}

extension Chat: Observation.Observable {
}
```

`@Observable` 宏主要完成以下三件事情：

1. 为所有的存储属性添加 `@ObservationTracked`，`@ObservationTracked` 也是一个宏，它会进一步展开，并将原来的存储属性转换为计算属性。同时，对于每个被转换的存储属性，`@Observable` 宏会为其添加一个带有下划线的新的存储属性。
2. 添加与 `ObservationRegistrar` 相关的内容，包括一个 `_$observationRegistrar` 实例，以及 `access` 和 `withMutation` 两个辅助方法。这两个方法接受 `Chat` 的 `KeyPath`，并将这些信息转发给 registrar 的相关方法。
3. 使 `Chat` 遵循 `Observation.Observable` 协议。该协议现在没有任何要求的方法，它只作为编译辅助。

`@ObservationTracked` 宏还可以进一步展开。以 `message` 为例，它的展开结果如下： 

```swift
var message: String
{
  init(initialValue) initializes (_message) {
    _message = initialValue
  }

  get {
    access(keyPath: \.message)
      return _message
    }

  set {
    withMutation(keyPath: \.message) {
      _message = newValue
    }
  }
}
```

1. `init(initialValue)` 是 Swift 5.9 中专门添加的新特性，称为 [Init Accessors](https://github.com/apple/swift-evolution/blob/main/proposals/0400-init-accessors.md)，它为计算属性添加 getter 和 setter 以外的第三种访问方式，`init`。由于宏无法改写已有的 `Chat` 初始化方法的实现，因此它为 `Chat.init` 提供了一种访问计算属性的途径，允许我们在初始化方法中调用计算属性的这个 init 声明，来为新生成的背后的存储属性 `_message` 进行初始化。
2. `@ObservationTracked` 将 `message` 转换为计算属性，并为其添加了 getter 和 setter。通过调用前面提到的 `access` 和 `withMutation` 方法，`@ObservationTracked` 将属性的读取和写入与 registrar 关联在一起，实现了对属性的监测和追踪。

由此，关于 Observation 框架在 SwiftUI 中的运作机制，我们可以得到如下大致图景：在 `View` 的 `body` 中，通过 getter 访问实例上的属性时，Observation Registrar 会记录这次访问，并为当前 `View` 注册一个能够刷新自身的方法；而当通过 setter 修改属性的值时，Registrar 会从记录中找到对应的刷新方法并执行，进而触发 View 的重新求值和刷新。

这种机制使得 SwiftUI 能够精确地追踪每个属性的变化，避免不必要的刷新，从而提高应用程序的性能和响应性。

### ObservationRegistrar 和 withObservationTracking

![](/assets/images/2023/access-tracking-keypath.png)

可能你已经注意到了，`ObservationRegistrar` 中的 `access` 方法具有如下签名：

```swift
func access<Subject, Member>(
  _ subject: Subject,
  keyPath: KeyPath<Subject, Member>
) where Subject : Observable
```

在这个方法里，我们可以获取到 model 类型的实例本身以及访问所涉及的 `KeyPath`。但是，仅凭这些信息，我们无法获取到关于调用者 (也就是 `View`) 的信息，也就不可能在属性变更时完成刷新。中间一定还缺少了一些东西。

Observation 框架中存在一个全局函数，`withObservationTracking`：

```swift
func withObservationTracking<T>(
  _ apply: () -> T,
  onChange: @autoclosure () -> () -> Void
) -> T
```

它接受两个闭包：在第一个 `apply` 闭包中所访问的 `Observable` 实例的变量将被观察；对于这些属性的任何变化，都将**触发一次且仅一次** `onChange` 闭包的调用。举例来说：

```swift
let chat = Chat(message: "Sample message", alreadyRead: false)
withObservationTracking {
  let _ = chat.alreadyRead
} onChange: {
  print("On Changed: \(chat.message) | \(chat.alreadyRead)")
}

chat.message = "Some text"
// 没有输出

chat.alreadyRead = true
// 打印: On Changed: Some text | false

chat.alreadyRead = false
// 没有输出
```

上面的示例中，有几点值得注意：

1. 由于在 `apply` 中，我们只访问了 `alreadyRead` 属性，因此在设置 `chat.message` 时，`onChange` 并没有被触发。这个属性并没有被添加到访问追踪里。
2. 当我们设置 `chat.alreadyRead = true` 时，`onChange` 被调用。不过这时所获取的 `alreadyRead` 依然是 `false`。`onChange` 将在属性的 `willSet` 时发生。也就是说，在这个闭包中，我们无法获取到新值。
3. 再次改变 `alreadyRead` 的值，不会再次触发 `onChange`。相关的观察在第一次触发时都被移除了。

`withObservationTracking` 扮演了重要的桥梁角色，在 SwiftUI 的 `View.body` 对 model 属性的观察中，它把两者联系了起来。

![](/assets/images/2023/withObservationTracking.png)

注意到观察只触发一次的事实，假设 SwiftUI 中有个 `renderUI` 的方法来重新对 `body` 求值，则我们可以把整个流程简化地看作是递归调用：

```swift
var chat: Chat //...
func renderUI() -> some View {
  withObservationTracking {
    VStack {
      Label("Message",
        systemImage: chat.alreadyRead ? "envelope.open" : "envelope")
      Button("Read") {
        chat.alreadyRead = true
      }
    }
  } onChange: {
    DispatchQueue.main.async { self.renderUI() }
  }
}
```

> 当然，实际上在 `onChange` 中，SwiftUI 仅只是把涉及到的 view 标记为 dirty，并统一在下一个 main runloop 进行重新绘制。在这里我们简化了这个过程。

## 实现细节

除去 SwiftUI 的相关部分，好消息是我们并不需要对 Observation 框架的实现进行任何猜测，因为它作为 Swift 项目的一部分开源了，你可以在这里找到[该框架的所有源码](https://github.com/apple/swift/tree/main/stdlib/public/Observation)。框架的实现非常简洁直接，也很巧妙。虽然整体和我们的假设十分类似，但在具体实现中，还是有一些值得注意的细节。

### 访问追踪

`withObservationTracking` 是一个全局函数，它提供了一个通用的 `apply` 闭包。全局函数本身没有对特定 registrar 的引用，因此要将 `onChange` 与 registrar 关联起来，必然需要利用一个全局变量来暂时保存 registrar (或者说其中所保存的 keypath) 和 `onChange` 闭包之间的关联。

在 Observation 框架的实现中，这是通过一个自定义的 `_ThreadLocal` 结构体来将 access list 保存在线程中的一个本地值来实现的。多个不同的 `withObservationTracking` 调用可以同时追踪多个不同的 `Observable` 对象上的属性，每个追踪对应一个 registrar。然而，所有的追踪都共享同一个 access list。

你可以将 access list 想象成一个字典，其中以对象的 `ObjectIdentifier` 为 key，而 value 则包含了这个对象上的 registrar 和访问到的 KeyPath。通过这些信息，我们最终能够找到 `onChange`，并执行我们想要的代码。

```swift
struct _AccessList {
  internal var entries = [ObjectIdentifier : Entry]()
  // ...
}

struct Entry {
  let context: ObservationRegistrar.Context
  var properties: Set<AnyKeyPath>
  // ...
}

struct ObservationRegistrar {
  internal struct Context {
    var lookups = [AnyKeyPath : Set<Int>]()
    var observations = [Int : () -> () /* content of onChange */ ]()
    // ...
  }
}
```

> 上面的代码只是示意，为了方便理解，进行了简化和部分修改。

### 线程安全

通过 `Observable` 属性中的 setter 进行的赋值，会通过 registrar 的 `withMutation` 方法，在全局 access list 和 registrar 中获取到观察了该对象上对应属性 keypath 的 `onChange` 方法。在建立观察关系 (也就是调用 `withObservationTracking`) 时，Observation 框架的内部实现使用了一个互斥锁来确保线程安全。因此，我们可以在任意线程安全地使用 `withObservationTracking`，而不必担心数据竞争的问题。

在观察触发时，对 observations 的调用没有进行额外的线程处理。`onChange` 将会在首个被观察的属性设置所发生的线程上进行调用。因此，如果我们希望在 `onChange` 中进行一些与线程安全有关的处理，需要注意调用发生的线程。在 SwiftUI 中，这大概率不是问题，因为对于 `View.body` 的重新求值会被“汇总”到主线程中进行。但是如果我们在 SwiftUI 之外的环境中单独使用 `withObservationTracking`，并且希望在 `onChange` 中刷新 UI，那么最好对当前线程进行一些判断，以确保安全性。

### 观察时机

Observation 框架当前的实现选择了在值 `willSet` 的时候对所有被观察的变更以“仅调用一次”的方式调用 `onChange`。这让我们产生联想，Observation 是否可以做到以下事情：

1. 在 `didSet` 时，而非 `willSet` 时进行调用。
2. 保持观察者的状态，在每次 `Observable` 属性发生变化时都进行调用。

在当前实现中，追踪观察所使用的 `Id` 具有如下定义：

```swift
enum Id {
  case willSet(Int)
  case didSet(Int)
  case full(Int, Int)
}
```

当前的实现已经考虑了 `didSet` 的情况，并且也有相应的实现，但是为 `didSet` 添加观察的接口没有暴露出来。目前，Observation 主要是与 SwiftUI 协作，因此 `willSet` 是首先被考虑的。未来，如果有需要，相信 `didSet` 以及设置属性前后都进行通知的 `.full` 模式也可以很容易地实现。

对于第二点，Observation 框架没有提供相关选项，也没有对应代码。不过，因为每个注册观察闭包都使用各自的 Id 进行管理，因此提供选项让用户可以进行长期观察，应该也是可以实现的。

## 利弊权衡

### 后向兼容和技术债

Observation 要求的 deploy target 为 iOS 17，在短期内对于大多数 app 来说这是难以达到的。于是开发者们面临巨大的困境：明明有更好更高效的方式，但却要在两三年后才能使用，而这期间所写的每一行传统方式的代码，都将在未来成为需要偿还的技术债，这是很令人沮丧的。

在技术层面来说，想要把 Observation 框架的内容进行前向兼容 (back-porting)，让它能跑在以前的系统版本，并没有什么难度。笔者也在[这个 repo](https://github.com/onevcat/ObservationBP) 进行了尝试和概念验证及[官方实现的同款测试](https://github.com/onevcat/ObservationBP/blob/master/ObservationBPTests/ObservationBPTests.swift)，把 Observation 的所有 API back port 到了 iOS 14。利用这个仓库的内容，只要导入 `ObservationBP`，我们可以以完全相同的方式使用这个框架，来缓解技术债的问题：

```swift
import ObservationBP

@Observable fileprivate class Person {
  init(name: String, age: Int) {
    self.name = name
    self.age = age
  }

  var name: String = ""
  var age: Int = 0
}

let p = Person(name: "Tom", age: 12)
withObservationTracking {
  _ = p.name
} onChange: {
  print("Changed!")
}
```

在将来有机会把最低版本升级到 iOS 17 后，可以简单地把 `import ObservationBP` 替换为 `import Observation`，就能无缝切换到 Apple 的官方版本。

事实上我们并没有太多单独使用 Observation 框架的理由，它总是和 SwiftUI 搭配使用的。确实，我们可以[提供一层包装](https://github.com/onevcat/ObservationBP/blob/master/ObservationBP/SwiftUI/ObservationView.swift)，来让我们的 SwiftUI 代码也能利用这个 back-porting 的实现：

```swift
import ObservationBP
public struct ObservationView<Content: View>: View {
  @State private var token: Int = 0
  private let content: () -> Content
  public init(@ViewBuilder _ content: @escaping () -> Content) {
    self.content = content
  }

  public var body: some View {
    _ = token
    return withObservationTracking {
      content()
    } onChange: {
      token += 1
    }
  }
}
```

如我们在上面说到的那样，在 `withObservationTracking` 的 `onChange` 中，我们需要一种方式，来重建 access list。这里我们在 `body` 里访问了 `token`，来让 `onChange` 再次触发 `body`，它会重新调用 `content()` 进行求值，建立新的观察关系。

使用上，只需要把带有观察需求的 `View` 包裹到 `ObservationView`：

```swift
var body: some View {
  ObservationView {
    VStack {
      Text(person.name)
      Text("\(person.age)")
        HStack {
          Button("+") { person.age += 1 }
          Button("-") { person.age -= 1 }
        }
    }
    .padding()
  }
}
```

在当前条件下，我们不可能做到 SwiftUI 5.0 那样透明和无缝利用 Observation。这大概也是 Apple 选择把 Observation 框架作为 Swift 5.9 标准库的一部分而非单独的 package 的原因：和新系统绑定的新版本的 SwiftUI 依赖这个框架，因此选择让框架也和新版本系统进行绑定。

### 不同的观察方式

到目前为止，在 iOS 开发中我们已经有不少观察的手段了。Observation 是不是可以替代掉它们呢？

#### 对比 KVO

KVO 是很常见的观察手段，在不少 UIKit 代码中，都存在着使用 KVO 进行观察的模式。KVO 要求被观察的属性具有 `dynamic` 标记，对于 UIKit 中基于 Objective-C 的属性来说这很容易满足，但是对于驱动 view 的模型类型来说，为每一个属性都添加 `dynamic` 则相对困难，也会带来额外的开销。

Observation 框架可以解决这部分问题，为一个属性添加 setter 和 getter，要比将整个属性转换为 `dynamic` 更轻量，特别是在 Swift 宏的帮助下，开发者们肯定更乐意使用 Observation。但是，当前 Observation 只支持单次订阅和 `willSet` 回调，在需要长期观察的场合，这种方法显然很难完全替代 KVO。

我们期待看到 Observation 支持更多选项，届时就可以进一步评估使用它来替代 KVO 的可能性。

#### 对比 Combine

在使用 Observation 框架后，我们已经找不到理由继续使用 Combine 中的 `ObservableObject`，因此在 SwiftUI 中对应的 `@ObservedObject`，`@StateObject` 和 `@EnvironmentObject` 理论上也不再被需要了。随着 SwiftUI 彻底摆脱 Combine，在 iOS 17 之后 Observation 框架可以完全取代 Combine 在绑定状态和 view 方面的工作。

但是 Combine 有着其他很多方面的使用案例，它的强项在于合并多个事件流并对它们进行变形。这和 Observation 框架要做的事情并不在同一个赛道。在决定要使用哪个框架时，我们还是应该根据需求，选取合适的工具。

### 性能

相比传统的基于实例整体进行观察的 `ObservableObject` 的 model 类型，使用 `@Observable` 进行属性粒度的观察，天然地能减少 `View.body` 重新求值的次数，这是因为对实例上属性的访问始终都会是对实例本身访问的子集。由于在 `@Observable` 中，单纯的对实例的访问不会触发重新求值，因此一些曾经的性能“优化方式”，比如尽量将 View 的 model 进行细粒度拆分，可能不再是最优方案。

举个例子，在使用 `ObservableObject` 时，如果我们的 Model 类型是：

```swift
final class Person: ObservableObject {
  @Published var name: String
  @Published var age: Int

  init(name: String, age: Int) {
    self.name = name
    self.age = age
  }
}
```

我们曾经会更倾向于这样做：

```swift
struct ContentView: View {
  @StateObject
  private var person = Person(name: "Tom", age: 12)

  var body: some View {
    NameView(name: person.name)
    AgeView(age: person.age)
  }
}

struct NameView: View {
  let name: String
  var body: some View {
    Text(name)
  }
}

struct AgeView: View {
  let age: Int
  var body: some View {
    Text("\(age)")
  }
}
```

这样，在 `person.age` 变动时，只需要刷新 `ContentView` 和 `AgeView`。

但是，在使用 `@Observable` 后：

```swift
@Observable final class Person {
  var name: String
  var age: Int

  init(name: String, age: Int) {
    self.name = name
    self.age = age
  }
}
```

则是直接把 `person` 向下传递会更高效：

```swift
struct ContentView: View {
  private var person = Person(name: "Tom", age: 12)

  var body: some View {
    PersonNameView(person: person)
    PersonAgeView(person: person)
  }
}

struct PersonNameView: View {
  let person: Person
  var body: some View {
    Text(person.name)
  }
}

struct PersonAgeView: View {
  let person: Person
  var body: some View {
    Text("\(person.age)")
  }
}
```

在这个小例子中，在 `person.age` 变动时，只有 `PersonAgeView` 需要刷新。当这类优化积少成多时，在大规模 app 中所能带来的性能提升将是可观的。

不过相对于原来的方式，`@Observable` 驱动的 `View` 在每次重新求值后，都要重新建立 access list 和观察关系。如果某一个属性被太多的 `View` 观察，那么这个重建时间也将会随之大幅提升。这具体会带来多少影响，还需要进一步的评估和听取社区反馈意见。

## 总结

1. 从 iOS 17 开始，使用 Observation 框架和 `@Observable` 宏将会是 SwiftUI 进行状态管理的最佳方式。它们不仅提供了简洁的语法，也带来了性能的提升。
2. Observation 框架可以单独使用，它通过宏来改写属性的 setter 和 getter，并使用一个 access tracking list 完成单次的 `willSet` 观察。不过，限于 Observation 框架所暴露的选项不足，当前暂时没有太多 SwiftUI 之外的使用场景。
3. 将 Observation 框架 back port 到早期版本并不存在技术上的困难，但是开发者难以提供透明的 SwiftUI wrapper。由于 SwiftUI 是该框架最大的用户，且 SwiftUI 的版本与系统版本绑定，因此 Observation 框架也被设计为与系统版本绑定。
4. 使用新的框架写法会带来新的性能优化实践，理解 Observation 的原理，会有助于我们写出性能更加优秀的 SwiftUI app。


1. 从 iOS 17 开始，使用 Observation 框架和 `@Observable` 宏将会是 SwiftUI 进行状态管理的最佳方式。它们不仅提供了简洁的语法，也带来了性能的提升。
2. Observation 框架可以单独使用，通过宏来改写属性的 setter 和 getter，并使用一个 access tracking list 完成单次的 `willSet` 观察。不过，由于目前 Observation 框架所暴露的选项有限，它的使用场景主要集中在 SwiftUI 内部，在 SwiftUI 之外的使用场景相对较少。
3. 虽然当前只支持 `willSet`，但 `didSet` 和 `full` 的支持已经实现，仅仅只是没有将接口暴露出来。所以未来某一天 Observation 支持其他属性设置时机的观察，并不足为奇。
4. 将 Observation 框架 back port 到早期版本并不存在技术上的困难，但是由于开发者难以提供透明的 SwiftUI wrapper，这使得将其应用于旧版本的 SwiftUI 有一定挑战。同时，考虑到 SwiftUI 是该框架的主要用户，并且与系统版本绑定，因此 Observation 框架也被设计为与系统版本绑定的特性。
5. 使用新的框架写法会带来新的性能优化实践，深入理解 Observation 的原理将有助于我们编写性能更加优秀的 SwiftUI app。

### 参考链接

- [WWDC 23 - Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [Observation 官方文档](https://developer.apple.com/documentation/observation)
- [Swift 标准库中的 Observation 源码](https://github.com/apple/swift/tree/main/stdlib/public/Observation)
- [Observation 前向兼容，概念验证](https://github.com/onevcat/ObservationBP)