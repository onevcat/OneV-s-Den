---
layout: post
title: "关于 Backpressure 和 Combine 中的处理"
date: 2019-12-01 12:32:00.000000000 +09:00
tags: 能工巧匠集
---

> 本文是对我的《SwiftUI 和 Combine 编程》书籍的补充，对一些虽然很重要，但和书中上下文内容相去略远，或者一些不太适合以书本的篇幅详细展开解释的内容进行了追加说明。如果你对 SwiftUI 和 Combine 的更多话题有兴趣的话，可以考虑[参阅原书](https://objccn.io/products/swift-ui)。

Combine 在 API 设计上很多地方都参考了 Rx 系，特别是 [RxSwift](https://github.com/ReactiveX/RxSwift) 的做法。如果你已经对响应式编程很了解的话，从 RxSwift 迁移到 Combine 应该是轻而易举的。如果要说起 RxSwift 和 Combine 的最显著的不同，那就是 RxSwift 在可预期的未来[没有支持 backpressure 的计划](https://github.com/ReactiveX/RxSwift/issues/1666?source=post_page-----64780a150d89----------------------#issuecomment-395546338)；但是 Combine 中原生对这个特性进行了支持：在 Combine 中你可以在 `Subscriber` 中返回追加接收的事件数量，来定义 Backpressure 的响应行为。在这篇文章里，我们会解释这个行为。

## 什么是 Backpressure，为什么需要处理它

虽然在 iOS 客户端中，backpressure 也许不是那么常见，但是这在软件开发里可能是一个开发者或多或少都会遇到的话题。Backpressure 这个词来源于流体力学，一般被叫做**背压**或者**回压**，指的是**流体在管道中流动时，(由于高度差或者压力所产生的阻滞) 在逆流动方向上的阻力**。在响应式的编程世界中，我们经常会把由 Publisher，Operator 和 Subscriber 组成的事件处理方式比喻为“管道”，把对应的不断发生的事件叫做“事件流”。类比而言，在这个上下文中，backpressure 指的是**在事件流动中，下游 (Operator 或者 Subscriber) 对上游 Publisher 的阻力**。

为什么会产生这样的“阻力”呢？一个最常见的原因就是下游的 Subscriber 的处理速度无法跟上上游 Publisher 产生事件的速度。在理想世界中，如果我们的处理速度无穷，那么不管 Publisher 以多快的速度产生事件，Subscriber 都可以消化并处理这些事件。但是实际情况显然不会如此，有时候 Publisher 的事件生成速度可以远超 Subscriber 的处理速度，这种情况下就会产生一些问题。

举例来说，比如我们的 Publisher 从一个快速的 web socket 接受数据，经过一系列类似 [`Publishers.Map`](https://developer.apple.com/documentation/combine/publishers/map) 的变形操作，将接收到的数据转换为 app 中的 Model，最终的订阅者在接收到数据后执行 UI 渲染的工作，把数据添加到 Table View 里并绘制 UI。很显然，相对于 UI 渲染来说，接收数据和数据变形是非常快的。在一帧 (60 Hz 下的话，16ms) 中，我们可以接收和处理成千上万条数据，但是可能只能创建和渲染十多个 cell。如果我们想要处理这些数据，朴素来说，可能的方式有四种：

1. 阻塞主线程，在这一帧中处理完这成千上万的 cell。
2. 把接受到的数据暂存在一个 buffer 里，取出合适的量进行处理。剩余部分则等待下一帧或者稍后空闲时再进行渲染。
3. 在接收到数据后，使用采样方法丢弃掉一部分数据，只去处理部分数据，以满足满帧渲染。
4. 控制事件产生的速度，让事件的发生速度减慢，来“适应”订阅者处理的速度。

在客户端开发中，方案 1 是最不可取的，很显然它会把 UI 整个卡死，甚至让我们可爱的 [watchdog 0x8badf00d (ate bad food)](https://stackoverflow.com/a/36644249/1468886) 从而造成 app 崩溃。方案 2 在某些情况下可能会有用，但是如果数据一直堆积，buffer 迟早会发生溢出。对于方案 3，在“将大量数据渲染到 UI 上”这一情景中，UI 刷新的速率将远远超过人能看到和处理的信息量，所以它是可行的，丢弃掉部分数据并不会造成使用体验上的影响。方案 4 如果可以实现的话，则是相对理想的 backpressure 处理方式：让发送端去适配接收端，在保证体验的情况下同时也保障了数据完整性，并且 (至少对客户端来说) 不会存在 buffer 溢出的情况。

另外一个常见的例子是大型文件转存，例如从磁盘的某个位置通过一个 stream 读取数据，然后将它写入到另一个地方。磁盘的读写速度往往是存在差别的，通常来说读速要比写速快很多。假设磁盘读取速度为 100 MB/s，写入速度为 50 MB/s，如果两端都全速的话，每秒将会堆积 50 MB 的数据到 buffer 中，很多场景下这是难以接受的。我们可以通过限制读取速度，来完美解决这个速度差，而这就是上面的方案 4 中的思想。

简单来说，backpressure 提供了一种方案，来解决在异步操作中发送端和接收端速率无法匹配的问题 (通常是发送端快于接收端)。在一个 (像是 Combine 这样的) 异步处理框架中，是否能够支持控制上游速度来处理 backpressure，关键取决于一点：事件的发送到底是基于**拉取模型**还是**推送模型**。如果是拉取模型，那么所定义的 Publisher 会根据要求**按需发送**，那么我们就可以控制事件发送的频率，进而处理前述的上下游速度不匹配的问题。

## 自定义 Subscriber

### Combine 框架基于拉取的事件模型

好消息是，Combine 的事件发送确实是基于拉取模型的。我们回顾一下典型的 Combine 订阅和事件发送的流程：

![](/assets/images/2019/publisher-subscriber-flow.svg)

图中共有三种主要角色，除了两端的 `Publisher` 和 `Subscriber` 以外，还有一个负责作为“桥梁”连接两者的 `Subscription`。

步骤 3，4 和 5 中分别涉及到 `Subscription` 和 `Subscriber` 的下面两个方法：

```swift
protocol Subscription {
    func request(_ demand: Subscribers.Demand)
}
protocol Subscriber {
    func receive(_ input: Self.Input) -> Subscribers.Demand
}
```

它们都和 `Subscribers.Demand` 相关：这个值表示了 `Subscriber` 希望接收的事件数量。Combine 框架中有这样的约定：`Subscriber` 对应着的订阅所发出的事件总数，不应该超过 `Subscription.request(_:)` 所传入的 `Demand` 和接下来每次 `Subscriber.receive(_:)` 被调用时返回的 `Demand` 的值的累加。基于这个规则，`Subscriber` 可以根据自身情况通过使用合适的 `Demand` 来控制上游。

这么说会有些抽象。在这篇文章里，我们会把注意力集中在 `Subscriber` 上，首先来看看如何实现自定义的 `Subscriber`，由此理解 Combine 的拉取模型的意义。然后再尝试实现一个能够控制 `Publisher` 发送事件的特殊 `Subscriber`。

关于图中另外两种角色 `Publisher` 和 `Subscription`，我可能会在另外的文章里再进行更多说明。

### 重写 Sink

在订阅某个 `Publisher` 时，大概最常用的莫过于 `sink` 了：

```swift
[1,2,3,4,5].publisher.sink(
    receiveCompletion: { completion in
        print("Completion: \(completion)")
    },
    receiveValue: { value in
        print("Receive value: \(value)")
    }
)
```

定义在 `Publisher` 上的扩展方法 `sink(receiveCompletion:receiveValue:)` 只不过是标准的订阅流程的简写方式。按照“正规的”方式，我们可以明确地创建 `Subscriber` 并让它订阅 `Publisher`，上面的代码等效于：

```swift
let publisher = [1,2,3,4,5].publisher
let subscriber = Subscribers.Sink<Int, Never>(
    receiveCompletion: { completion in
        print("Completion: \(completion)")
    },
    receiveValue: { value in
        print("Receive value: \(value)")
    }
)

publisher.subscribe(subscriber)
```

`Sink` 做的事情非常简单，它在订阅时直接申请接受 `Subscribers.Demand.unlimited` 个元素。在每次收到事件时，调用预先设定的 block。现在，作为起始，我们来创建一个自定义的 `MySink`：

```swift
// 1
extension Subscribers {
    // 2
    class MySink<Input, Failure: Error>: Subscriber, Cancellable {
        let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
        let receiveValue: (Input) -> Void
        // 3
        var subscription: Subscription?
        
        // ...
    }
}
```

1. Combine 中的 `Publisher` 和 `Subscriber` 大都作为内嵌类型，定义在 `Publishers` 和 `Subscribers` 中。在这里，我们也遵循这个规则，把 `MySink` 写在 `Subscribers` 里。
2. 我们想让 `MySink` 满足 `Cancellable`，因此需要持有 `subscription`，才能在未来取消这个订阅。在语义上来说，我们也不希望发生复制，所以使用 `class` 来声明 `MySink`。这也是实现自定义 `Subscriber` 的一般做法。
3. 在 `Subscriber` 中持有 `subscription` 是很常见的操作，除了用来对应取消以外，这还可以让我们灵活处理额外的值的请求，稍后我们会看到这方面的内容。

接下来，创建一个初始化方法，它接受 `receiveCompletion` 和 `receiveValue`：

```swift
init(
    receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
    receiveValue: @escaping (Input) -> Void
)
{
    self.receiveCompletion = receiveCompletion
    self.receiveValue = receiveValue
}
```

想要实现 `Subscriber` 协议，我们需要实现协议中定义的所有三个方法：

```swift
public protocol Subscriber {
    func receive(subscription: Subscription)
    func receive(_ input: Self.Input) -> Subscribers.Demand
    func receive(completion: Subscribers.Completion<Self.Failure>)
}
```

在 `MySink` 里，我们可以完全遵循 `Sink` 的做法：在一开始收到订阅时，就请求无限多的事件；而在后续收到值时，则不再做 (也不需要做) 更多的请求：

```swift
func receive(subscription: Subscription) {
    self.subscription = subscription
    subscription.request(.unlimited)
}
        
func receive(_ input: Input) -> Subscribers.Demand {
    receiveValue(input)
    return .none
}
        
func receive(completion: Subscribers.Completion<Failure>) {
    receiveCompletion(completion)
    subscription = nil
}
```

最后，为了实现 `Cancellable`，我们需要将 `cancel()` 的调用“转发”给 `subscription`：

```swift
func cancel() {
    subscription?.cancel()
    subscription = nil
}
```

为了避免意外的循环引用 (因为 `Subscription` 很多情况下也会持有 `Subscriber`)，所以在收到完成事件或者收到取消请求时，不再继续需要订阅的情况下，要记得将 `subscription` 置回为 `nil`。

最后的最后，为了方便使用，不妨为 `Publisher` 提供一个扩展方法，来帮助我们用 `MySink` 做订阅：

```swift
extension Publisher {
    func mySink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) -> Cancellable
    {
        let sink = Subscribers.MySink<Output, Failure>(
            receiveCompletion: receiveCompletion,
            receiveValue: receiveValue
        )
        self.subscribe(sink)
        return sink
    }
}

[1,2,3,4,5].publisher.mySink(
    receiveCompletion: { completion in
        print("Completion: \(completion)")
    },
    receiveValue: { value in
        print("Receive value: \(value)")
    }
)

// 输出：
// Receive value: 1
// Receive value: 2
// Receive value: 3
// Receive value: 4
// Receive value: 5
// Completion: finished
```

`mySink` 的行为和原始的 `sink` 应该是完全一致的。现在我们就可以开始着手修改 `MySink` 的代码，让事情变得更有趣一些了。

### 按照 Demand 的需求来发送事件

我们可以对 `MySink` 做一点手脚，来控制它的拉取行为。比如将 `receive(subscription:)` 里初始的请求数量调整为 `.max(1)`：

```swift
func receive(subscription: Subscription) {
    self.subscription = subscription
    // subscription.request(.unlimited)
    subscription.request(.max(1))
}
```

这样一来，输出就停留在只有一行了：

```
Receive value: 1
```

这是因为现在我们只在订阅发生时去请求了一个值，而在 `receive(_:)` 里，我们返回的 `.none` 代表不再需要 `Publisher` 给出新值了。在这个方法中，我们有机会决定下一次的事件请求数量：可以将请求数从 `.none` 调整为 `.max(1)`：

```swift
func receive(_ input: Input) -> Subscribers.Demand {
    receiveValue(input)
    // return .none
    return .max(1)
}
```

输出将恢复原来的情况：每当 `MySink` 收到一个值时，它会再去**拉取**下一个值，直到最后结束。我们可以通过为 `Publisher` 添加 `print()` 来从控制台输出确定这个行为：

```swift
// [1,2,3,4,5].publisher
[1,2,3,4,5].publisher.print()
    .mySink(
        receiveCompletion: { completion in
            print("Completion: \(completion)")
        },
        receiveValue: { value in
            // print("Receive value: \(value)")
        }
    )

// 输出：
// receive subscription: ([1, 2, 3, 4, 5])
// request max: (1)
// receive value: (1)
// request max: (1) (synchronous)
// receive value: (2)
// request max: (1) (synchronous)
// receive value: (3)
// ... 
```

通过在 `Subscriber` 里的 `receive(subscription:)` 和 `receive(_:)` 来控制 `Subscribers.Demand`，我们做到了控制 `Publisher` 的事件发送。那要如何使用这个特性处理 backpressure 的情况呢？

## 能够处理 backpressure 的 Subscriber

### 让已停止的事件流继续

按照 Combine 约定，当 `Publisher` 发送的值满足 `Subscriber` 所要求的数量后，便不再发送新的值。在上面的 `MySink` 实现里，只要将 `receive(_:)` 的返回值设为 `.none`，那么就只会有第一个值被发出。这时候我们便遇到了一个问题，因为后续的值不会再被发送，`receive(_:)` 也不会再被调用，因此我们不再有机会在 `receive(_:)` 中返回新的 `Demand`，来让 `Publisher` 重新开始工作。

我们需要一种方式来“重新启动”这个流程，那就是 `Subscription` 上的 `request(_ demand: Subscribers.Demand)` 方法。在订阅刚开始时，我们已经使用过它来开始第一次发送。现在，当 `Publisher` “暂停”后，我也也可以从外部用它来重启发送流程，这也是我们要暂存 `subscription` 的另一个重要理由。

在 `MySink` 里添加 `resume` 方法：

```swift
func resume() {
    subscription?.request(.max(1))
}
```

创建一个 `Resumable` 协议，并让 `MySink` 遵守这个协议：

```swift
protocol Resumable {
    func resume()
}

extension Subscribers {
    class MySink<Input, Failure: Error>
    : Subscriber, Cancellable, Resumable 
    {
        //...
        // MySink 已经实现了 resume()
    }
}
```

最后，把 `Publisher.mySink` 的返回类型从 `Cancellable` 修改为 `Cancellable & Resumable` 的联合：

```swift
extension Publisher {
    func mySink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) -> Cancellable & Resumable
    {
      // ...
    }
}
```

现在，即使我们把 `MySink` 里 `receive(_:)` 的返回值改回 `.none`，让 `Publisher` 在被订阅后只发出一次值，我们也可以再通过反复调用 `resume(_:)` 来“分批次”拉取所有值了：

```swift
extension Subscribers {
    class MySink //... {
        func receive(_ input: Input) -> Subscribers.Demand {
            receiveValue(input)
            return .none
        }
    }
}

let subscriber = [1,2,3,4,5].publisher.print()
    .mySink(
        receiveCompletion: { completion in
            print("Completion: \(completion)")
        },
        receiveValue: { value in
            print("Receive value: \(value)")
        }
    )

subscriber.resume()
subscriber.resume()
subscriber.resume()
subscriber.resume()
```

### 注入控制逻辑，暂停 `Publisher` 发送

现在我们只差最后一块拼图了，那就是到底由谁来负责暂停 `Publisher` 的逻辑。当前的 `MySink` 中，由于开始订阅时只接受了 `.max(1)`，同时， `receive(_:)` 返回的是 `.none`，所以在接到第一个值后，`Publisher` 是无条件暂停的。实际上，和 `resume` 逻辑类似，我们会更希望将暂停的逻辑也“委托”出去，由调用者来决定合适的暂停时机：`receiveValue` 回调是一个不错的地方。将 `MySink` 中的 `receiveValue` 签名进行修改，让它返回一个 `Bool` 来表示是否应该继续下一次请求，并为 `MySink` 添加一个属性持有它：

```swift
class MySink // ... {
    // let receiveValue: (Input) -> Void
    let receiveValue: (Input) -> Bool
    
    var shouldPullNewValue: Bool = false
    
    init(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        // receiveValue: @escaping (Input) -> Void
        receiveValue: @escaping (Input) -> Bool
    )
    // ...
}

extension Publisher {
    func mySink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        // receiveValue: @escaping (Output) -> Void
        receiveValue: @escaping (Output) -> Bool
    ) -> Cancellable & Resumable
```

当 `shouldPullNewValue` 为 `true` 时，在收到新值后，应当继续请求下一个值；否则，便不再继续请求，将事件流关闭，等待外界调用 `resume` 再重启。

对 `MySink` 的相关方法进行修改：

```swift
func receive(subscription: Subscription) {
    self.subscription = subscription
    resume()
}

func receive(_ input: Input) -> Subscribers.Demand {
    shouldPullNewValue = receiveValue(input)
    return shouldPullNewValue ? .max(1) : .none
}

func resume() {
    guard !shouldPullNewValue else {
        return
    }
    shouldPullNewValue = true
    subscription?.request(.max(1))
}
```

这样，就可以在使用的时候通过 `receiveValue` 闭包返回 `false` 来暂停；在暂停后，通过调用 `resume` 来继续了。

假设我们有一个巨大 (甚至无限！) 的数据集，在使用 `sink` 的情况下由于处理速度无法跟上事件的发送速度，我们将会被直接卡死：

```swift
(1...).publisher.sink(
    receiveCompletion: { completion in
        print("Completion: \(completion)")
    },
    receiveValue: { value in
        print("Receive value: \(value)")
    }
)
```

但是如果我们通过使用 `mySink` 并设定一定条件，就可以很优雅地处理这个 backpressure。比如每秒只需要 `Publisher` 发送五个事件，并进行处理：

```swift
var buffer = [Int]()
let subscriber = (1...).publisher.print().mySink(
    receiveCompletion: { completion in
        print("Completion: \(completion)")
    },
    receiveValue: { value in
        print("Receive value: \(value)")
        buffer.append(value)
        return buffer.count < 5
    }
)

let cancellable  = Timer.publish(every: 1, on: .main, in: .default)
    .autoconnect()
    .sink { _ in
        buffer.removeAll()
        subscriber.resume()
    }
```

通过这种方式，我们自定义的 `MySink` 成为了一个可以用于处理 backpressure 的通用方案。

> 相关的代码可以[在这里找到](https://gist.github.com/onevcat/baecc584e3cbfa2cc161290b2dfd300a)。

## 练习

为了保持和[《SwiftUI 和 Combine 编程》]((https://objccn.io/products/swift-ui))这本书的形式上的类似，我也准备了一些小练习，希望能帮助读者通过实际动手练习掌握本文的内容。

### 1. 自定义实现 `Subscribers.Assign`

文中自定义了 `MySink`，来复现 `Sink` 的功能。现在请你依照类似的方式创建一个你自己的 `MyAssign` 类型，让它和 `Subscribers.Assign` 的行为一致。作为提示，下面是 Combine 框架中 `Subscribers.Assign` 的 (简化版的) public 声明：

```swift
class Assign<Root, Input> : Subscriber, Cancellable {
    typealias Failure = Never
    var object: Root? { get }
    let keyPath: ReferenceWritableKeyPath<Root, Input>
    
    // ...
}
```

### 2. 一次 request 超过 `.max(1)` 个数的事件

在引入 `resume` 时，我们将 `.max(1)` 硬编码在了方法内部：

```swift
func resume() {
    subscription?.request(.max(1))
}
```

我们能不能修改这个方法的签名，让它更灵活一些，接受一个 `Demand` 参数，让它可以向 `subscription` 请求多个值？比如：

```swift
func resume(_ demand: Subscribers.Demand) {
    subscription?.request(demand)
}
```

这么做会对 `Resumable` 产生影响吗？会对之后我们想要实现的暂停逻辑有什么影响？我们还能够使用这样的 `resume` 写出可靠的暂停和重启逻辑么？

### 3. 通用的 Subscriber 和专用的 Subscriber

本文最后我们实现的是一个相对通用的 Subscriber，但是如果逻辑更复杂，或者需要大规模重复使用时，把逻辑放在 `receiveValue` 闭包中会有些麻烦。

请尝试把原文中 「`buffer` 元素数到达 5 时，暂停一秒」这个逻辑封装起来，用一个新的专用的 `Subscriber` 替代。你可以尝试两个方向：

1. 使用一个新的类型，包装现有的 `MySink`，将判断逻辑放到新类型中；`Subscriber` 协调所需要定义的方法，通过转发的方式交给 `MySink` 处理。
2. 完全重新实现一个和 `MySink` 无关的 `Subscriber`，专门用来处理这类定时开关的事件流。