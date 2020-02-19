---
layout: post
title: "在 Combine 中实现自定义 Publisher"
date: 2020-01-20 10:00:00.000000000 +09:00
tags: 能工巧匠集
---

> 本文是对我的《SwiftUI 和 Combine 编程》书籍的补充，对一些虽然很重要，但和书中上下文内容相去略远，或者一些不太适合以书本的篇幅详细展开解释的内容进行了追加说明。如果你对 SwiftUI 和 Combine 的更多话题有兴趣的话，可以考虑[参阅原书](https://objccn.io/products/swift-ui)。

[上一篇文章](https://onevcat.com/2019/12/backpressure-in-combine/)里，我们探索了 Combine 里对 back pressure 的处理。在那边，主要涉及到的是实现自定义的 `Subscriber`，来通过控制事件流终端的 pull 行为，实现合理的 back pressure 机制。

对于整个事件流的另一端，`Publisher`，有时候我们也有自定义的需求。在《SwiftUI 和 Combine 编程》中，在“打包”多个请求时，我们用了一种很 naive 的方法：

```swift
struct LoadPokemonRequest {
    static var all: AnyPublisher<[PokemonViewModel], AppError> {
        (1...30)
            .map { LoadPokemonRequest(id: $0).publisher }
            .zipAll
    }
}
```

其中，`zipAll` 是 `Array` 上的 extension：

```swift
extension Array where Element: Publisher {
    var zipAll: AnyPublisher<[Element.Output], Element.Failure> {
        let initial = Just([Element.Output]())
            .setFailureType(to: Element.Failure.self)
            .eraseToAnyPublisher()
        return reduce(initial) { result, publisher in
            result.zip(publisher) { $0 + [$1] }.eraseToAnyPublisher()
        }
    }
}
```

这个做法创建了多个“临时” `Publisher`，并通过 `reduce` 把它们组合在一起。对于 `zip` 来说，这么做侥幸可以工作，但是这并不是一个一般性的解决方案。和自定义 `Subscriber` 一样，Combine 中的 `Publisher` 也是 protocol，我们可以按照需求去创建那些 Combine 库中还不存在、但是很有用的 `Publisher`。在本文里，我们就以创建一个真正的 `ZipAll` 作为例子，来说明自定义 `Publisher` 的一般方法。

你可以打开一个 Playground，跟随本文键入代码，也可以[在这里](https://gist.github.com/onevcat/138ca5a41ee1a7f2994a6c366936744e)直接查看并尝试完整的代码。

在我们正式开始之前，我还是想强调下面这张图，它总结了 Combine 框架的完整工作流程。其实归根溯源，不管我们只是想很初级地使用 Combine 的内建内容，还是想更高级一些去自定义响应式的操作和事件流，归根结底，我们都是在如图定义的工作流中进行操作。只有真正理解和熟悉这张 Combine 的工作流程图，才能说是真正掌握了 Combine 的思维方式。

![](/assets/images/2019/publisher-subscriber-flow.svg)

## 主要角色和工作

按照上图，我们逐行来梳理在自定义一个 `Publisher` 时需要做些什么。这可以为自定义 `Publisher` 的设计提供一个概览性的指导。对于图中的每个步骤，说明如下：

1. `Subscriber` 可以通过调用 `Publisher.subscribe` 来告诉 `Publisher` 订阅开始。自然地，我们需要在 `Publisher` 上增加一个方法：`subscribe`。
2. `Publisher` 需要调用 `Subscriber` 上的 `receive(subscription:)` 方法。这个方法接收一个 `Subscription`。那么显然，`Publisher` 需要知道如何创建一个**合适的** `Subscription`。
3. `Subscriber` 通过调用 2 中创建的 `Subscription` 上的 `request` 方法，来首次表明自己需要多少个事件。也就是说，`Subscription` 上必须要有一个 `request` 方法，它接受并记录 `Subscribers.Demand` (这也是 `Subscription` 协议中所定义的方法)。如果你对这个过程还不太熟悉，建议你可以参考我之前关于自定义 `Subscriber` 和实现 back pressure 的[文章](https://onevcat.com/2019/12/backpressure-in-combine/)，那边对 `Demand` 的用法和原理进行了详细的说明。
4. 当新的事件发生，并且当前的 demand 满足要求 (也即 `Subscriber` 还需要更多事件) 时，调用 `Subscriber.receive(_:)` 来向下游发送一个事件。这件事情可以由 `Publisher` 完成，但是更多的时候，我们会倾向于保持 `Publisher` 的值语义，然后选择在 `Subscription` 中实现这些逻辑。因为 `Subscription` 在大部分情况下会保持某个 buffer，并随着时间进行响应并改变值 (毕竟这正是 Combine 或者说响应式编程所要解决的问题领域)，所以一般我们会选择将 `Subscription` 声明为 `class` 并使用引用语义。另外，`Subscriber.receive(_:)` 返回的 `Demand` 值应该被追加到剩余需要的事件个数中。
5. 同 4。
6. 如果事件结束 (比如异步操作完全完成，或者出现了错误)，需要调用 `Subscriber.receive(completion:)`。这一步也经常是由 `Subscription` 来实现的。

上面的 4，5，6 中涉及的都是在 `Subscription` 中调用 `Subscriber` 的方法，所以在我们的实现中，在 `Subscription` 里持有 `Subscriber` 是一个自然而然的选择。对于自定义的具体的 `Publisher` 类型来说，它只负责提供一个简单的接口封装，来满足 `Publisher` 协议的规定，并保持这个角色的值语义 (在 Combine 的实现中，绝大部分的 `Publisher` 都拥有值语义，这让订阅的声明周期和行为相对简单)。事件发送，值的保持等涉及到具体、时序上的操作，则由一个相对复杂的 `Subscription` 实现。

### Publisher

对于我们要实现的接受数组版本的 `zip` 来说，最直接的就是实现一个 `ZipAll`，让它实现 `Publisher` 协议。遵循 Combine 的一般方式，我们把 `ZipAll` 定义在 `Publishers` 中，并添加上 `Publisher` 协议所需要的方法：

```swift
extension Publishers {
    struct ZipAll<Collection: Swift.Collection>: Publisher 
    where Collection.Element: Publisher 
    {
        // 1
        typealias Output = [Collection.Element.Output]
        typealias Failure = Collection.Element.Failure
      
        private let publishers: Collection

        init(_ publishers: Collection) {
            self.publishers = publishers
        }

        // 2
        func receive<S>(subscriber: S)
            where S : Subscriber, Failure == S.Failure, Output == S.Input
        {
            // 3
        }
    }
}
```

1. 作为新的 `Publisher`，`ZipAll` 也需要自己的 `Output`。通过限定 `ZipAll` 所接收的子 `Publisher` 具有相同的类型，新的 `Publisher` 的 `Output` 也便可以被确定。
2. 这是 `Publisher` 协议所规定需要实现的方法，不论你自定义的 `Publisher` 具体是什么，这一部分是不会改变的。
3. 在 `receive(subscriber:)` 里，按照 Combine 工作流程，我们创建 `Subscription` 并调用 `Subscriber.receive(subscription:)` 来把这个新创建的 `Subscription` 发送给 `Subscriber`。(流程图中的 1 和 2)，然后等待 `Subscriber` 首次请求数据。现在我们还没有创建合适的 `Subscription` 类型，所以先把它留空。在后面我们会回到这个方法，并填上需要的内容。

在 `init` 里，我们接收了一个类型满足 `Swift.Collection`，且其中元素均为同类型 `Publisher` 的集合类型作为参数。在实际使用这个 `ZipAll` 时，我们大概会想要做的步骤如下：

1. 订阅每个输入的 publisher，并观察它们的事件。建立符合输入的 publisher 个数的缓冲区。
2. 某个 publisher 发出新的值后，先将它保存到对应的缓冲区里。然后检查所有这些缓冲区中是不是都有待处理的元素。如果都有，则将它们的首个元素移出来，形成一个数组并作为新的 `ZipAll` 值发送出去。
3. 某个输入 publisher 发出成功完成的事件后，将它记录下来，并检查是不是所有的输入 publisher 都完成了。如果是，则将 `.finish` 事件发送出去。
4. 如果某个输入 publisher 发出了错误，那么将错误直接作为新 `Publisher` 的结果发出。

暂时我们现在还不知道要怎么往 `receive(subscriber:)` 中填写内容，这要求我们需要知道如何创建 `Subscription`。好消息是，`Subscription` 本身也是一个被严格定义的协议，这为我们实现自定义订阅类型提供了一些基本的依据。

### Subscription

紧接着 `ZipAll` 的定义，在 `Publishers` 中创建一个私有的 `ZipAppSubscription` 类：

```swift
extension Publishers {
    struct ZipAll ... {
        // ...
    }
    
    private class ZipAppSubscription<Output, Failure: Error>: Subscription
    {
        // 1
    }
}
```

Combine 中，`Subscription` 协议定义了两个必须实现的方法：

```swift
func request(_ demand: Subscribers.Demand)
func cancel()
```

前者用来接收 `Subscriber` 的请求，后者用来取消当前订阅。

在 `ZipAppSubscription` 的 `// 1` 里添加下面这些内容：

```swift
// 1
private var leftDemand: Subscribers.Demand = .none
private var subscriber: AnySubscriber<[Output], Failure>? = nil
private var buffer: [[Output]]
private let publishers: [AnyPublisher<Output, Failure>]
private var childSubscriptions: [AnyCancellable] = []

private var finishedCount = 0

// 2
private var lock = NSRecursiveLock()

init<S: Subscriber>(
    subscriber: S,
    publishers: [AnyPublisher<Output, Failure>]
) where Failure == S.Failure, [Output] == S.Input
{
    self.subscriber = AnySubscriber(subscriber)
    self.buffer = Array(repeating: [], count: publishers.count)
    self.publishers = publishers
}

func request(_ demand: Subscribers.Demand) {
    lock.lock()
    defer { lock.unlock() }

    self.leftDemand += demand

    // 3
    send()
}

func cancel() {
    lock.lock()
    defer { lock.unlock() }

    childSubscriptions = []
    subscriber = nil
}
```

1. 既然生活在 Combine 的世界中，我们就得遵守 Combine 的游戏规则。`leftDemand` 将记录下游订阅者还需要的值的数量，这样我们可以遵守基于 pull 的行为规则。
2. 我们不能确定 zip 操作中涉及的各个 publisher 最终会在哪个线程向我们发送数据，这些数据在接收后会被放到 `buffer` 中待用，因此这里出现了多个线程共享资源的情况。让整个操作线程安全的最简单的方法就是上锁。
3. 当收到 `request(_:)` 调用时，除了将下游告知的需求 `demand` 累加到 `leftDemand` 以外，我们还需要检查 `buffer` 并尝试触发事件 `send` 就是做这件事情的。

另外，我们还需要一个开始订阅的方法 (`startSubscribing`)，它会负责开始订阅 `publishers` 发出的值和事件。

这个 `startSubscribing` 和 3 中的 `send` 是 `Subscription` 的关键内容。前者负责把对应的事件进行转发处理：对于接收到的值，将它缓存在 `buffer` 中，并判断是否应当触发 zip 合并后的事件；对于接收到的结束事件，如果是错误事件，则结束自身事件流，如果是子 publisher 的结束事件，则将它记录下来，直到所有的 publisher 都结束后，再向外发送自身的结束事件。

这些逻辑看起来有些麻烦，但是如果给翻译翻译的话，代码看起来还是比较简单的：

```swift
func startSubscribing() {
    for (i, publisher) in publishers.enumerated() {
        publisher.sink(
            receiveCompletion: {  [weak self] completion in
                self?.receiveCompletion(completion, at: i)
            },
            receiveValue: { [weak self] value in
                self?.receiveValue(value, at: i)
            }
        ).store(in: &childSubscriptions)
    }
}

private func receiveValue(
    _ value: Output, at index: Int
) {
    lock.lock()
    defer { lock.unlock() }
    buffer[index].append(value)

    send()
}

private func receiveCompletion(
    _ event: Subscribers.Completion<Failure>, at index: Int
)
{
    lock.lock()
    defer { lock.unlock() }

    guard let subscriber = subscriber else { return }

    switch event {
    case .finished:
        finishedCount += 1
        if finishedCount == buffer.count {
            subscriber.receive(completion: .finished)
            self.subscriber = nil
        }
    case .failure:
        subscriber.receive(completion: event)
        self.subscriber = nil
    }
}
```

然后是 `Subscription` 里的另一个重要方法 `send`，它负责检查 `buffer`，并在满足 zip 逻辑的时候向外发布一个新值：

```swift
private func send() {
    guard let subscriber = subscriber else { return }
    while leftDemand > .none, let outputs = firstRowOutputItems {
        self.leftDemand -= .max(1)
        let nextDemand = subscriber.receive(outputs)
        self.leftDemand += nextDemand
    }
}

private var firstRowOutputItems: [Output]? {
    guard buffer.allSatisfy({ !$0.isEmpty }) else { return nil }
    var outputs = [Output]()
    for i in 0 ..< buffer.count {
        var column = buffer[i]
        outputs.append(column.remove(at: 0))
        buffer[i] = column
    }
    return outputs
}
```

这样，我们就有一个完整的 `Subscription` 角色了。最后，让我们回到 `Publishers.ZipAll` 中，把刚才剩下的 `receive(subscriber:)` 方法补完。创建一个 `ZipAppSubscription` 实例，调用 `Subscriber` 协议所定义的 `receive(subscription:)` 方法，并开始订阅所有的 publisher：

```swift
struct ZipAll ... {

    // ...

    func receive<S>(subscriber: S)
        where S : Subscriber, Failure == S.Failure, Output == S.Input
    {
        let subscription = ZipAppSubscription<Collection.Element.Output, Failure>(
            subscriber: subscriber, publishers: publishers.map { $0.eraseToAnyPublisher() }
        )
        subscriber.receive(subscription: subscription)
        subscription.startSubscribing()
    }
}
```

现在，我们就可以通过 `Publishers.ZipAll` 来创建一个真正的 `ZipAll` 的 `Publisher` 了。比如：

```swift
let p1 = [1,2,3].publisher
let p2 = [4,5,6].publisher
let p3 = [7,8,9,10].publisher

let zipped = Publishers.ZipAll([p1, p2, p3])
let subscription = zipped.sink(
    receiveCompletion: {completion in
        print("receiveCompletion \(completion)")
    },
    receiveValue: { values in
        print("receiveValues: \(values)")
    }
)

// 输出：
// receiveValues: [1, 4, 7]
// receiveValues: [2, 5, 8]
// receiveValues: [3, 6, 9]
// receiveCompletion finished
```

当然，最后，我们可以学习 `Publishers` 中的其他类型那样，为 `ZipAll` 提供一个辅助方法，让创建 `Publishers.ZipAll` 变得简单一些：

```swift
extension Collection where Element: Publisher {
    var zipAll: Publishers.ZipAll<Self> {
        Publishers.ZipAll(self)
    }
}

let zipped = [p1, p2, p3].zipAll
```

## 不足之处和改进空间

虽然 `ZipAll` 应该已经可以正常工作了，但是还有一些值得优化的地方。

### 性能改进

首先是 `firstRowOutputItems` 中的数组操作的效率。`buffer` 的类型是 `[[Output]]`，它其中的元素也只是普通的 `Array`。因此 `firstRowOutputItems` 里的移除首个元素 `column.remove(at: 0)` 的操作，其实时间复杂度是 `O(n)`，而它又处于一个 `buffer.count` 的循环中，所以这里会带来一个 n^2 的复杂度，是难以接收的。我们可以自己创建一个队列的数据结构，把 `remove(at: 0)` 的操作简化为 `O(1)` 来避免这个问题。

其次，还是在 `firstRowOutputItems` 里，我们每次都对“是否 `buffer` 中所有的列都至少有一个元素”进行了判断：`buffer.allSatisfy({ !$0.isEmpty })`，这也是一个 `O(n)`。一种更简单的方式，是维护一个变量来记录当前已经收到的可合并值的个数：在每次收到值时，判断 `buffer` 对应的位置上是否已经有值，来确定需不需要更改这个变量。如果发现已经收到的可合并值的个数与 publishers 的数量相等的话，就说明所有数据都已经准备就绪，可以将它们 `zip` 并发送。通过这样一个变量，我们可以把这里的 `O(n)` 也简化为 `O(1)`。甚至更进一步，可以自然而然地做到去掉上面提到的 `buffer.count` 循环，把整个发送流程优化到 `O(1)`。

### 有限 Demand

除了速度优化外，`ZipAll` 现在的行为逻辑也有值得商榷的地方。在 `startSubscribing` 里，我们简单地使用了 `sink` 来对输入的 `publishers` 进行订阅。`Sink` subscriber 在通过 `receive(subscription:)` 接收到订阅后，会立即 `request(_:)` `.unlimited` 的 `Subscribers.Demand`。这其实没有尊重 Combine 事件的拉取模型原则：在我们的 `ZipAll` 实现中，下游订阅者可以通过控制 `Demand` 来控制收到的值的数量，但是内部的 `publishers` 的订阅却可以接受无限多的值。这么一来，一旦在 `ZipAll` 内部产生 back pressure，比如外部所需要的值的频率小于内部 publishers 产生值的频率的话，`buffer` 将可以大量积压，导致内存问题。实际上，我们可以根据下游订阅者需要的值的数量，来决定我们所需要的 publishers 给我们的值的数量。这样，我们就能将 back pressure 的处理也应用到被 zip 的 publishers 中去，从而避免溢出问题。

相对于使用 `Sink`，我们可以用 `AnySubscriber` 来在更细的力度上进行一些控制。比如在收到订阅后只请求有限个事件，在收到新值时尊重下游订阅的 `Demand` 等：

```swift
AnySubscriber(
    receiveSubscription: { subscription in
        
    }, 
    receiveValue: { value -> Subscribers.Demand in
    
    }, 
    receiveCompletion: { completion in 

    }
)
```

## 总结

可以看出，文中给出的实现有不少缺点，这个参考实现更多地是为了以最简单的方式说明自定义 `Publisher` 的一般方法，还远远没有达到可以用在产品代码中的质量。不过，通过这种直接的例子，我们可以总结出一些实现自定义 `Publisher` 时的一般经验：

1. `Publisher` 的接口和它需要完成的任务是相对固定的，遵循 Combine 的工作流程图，来实现其中各个职责类型的必要方法即可。
2. 如果没有特殊的需求，一般我们会将 `Publisher` 定义为 `struct` 而非 `class`，这可以让内存管理和多次订阅的行为更加容易预测。但是，如果一个 `Publisher` 有需要共享的话，应该将它定义为引用语义，比如 [`Publishers.Share`](https://developer.apple.com/documentation/combine/publishers/share)。
3. 相对于 `Publisher`，大部分有关时序的操作都被封装到了 `Subscription` 里。作为 `Publisher` 和 `Subscriber` 之间通讯的桥梁，`Subscription` 负责大部分逻辑，并维护 Combine 流程的正确性。一般来说，这也是在自定义 `Publisher` 时我们花费最多时间的地方。
4. 想要确保你的自定义 `Publisher` 能在 Combine 的世界中运行良好，需要遵守基本的规则。比如尊重下游的 demand，考虑性能因素等。

## 练习

为了保持和[《SwiftUI 和 Combine 编程》]((https://objccn.io/products/swift-ui))这本书的形式上的类似，我也准备了一些小练习，希望能帮助读者通过实际动手练习掌握本文的内容。

### 1. 优化 `ZipAll`

上面提出了关于优化 `ZipAll` 的一些想法，包括运行性能的优化和防止 `buffer` 堆积等。请你在力所能及的范围内对 `ZipAll` 进行修改和优化，并架设一些性能测试来验证你的修改确实发挥了作用。

> 提示，一般来说，在测试中我们可以使用 `PassthroughSubject` 作为数据源，并通过 [`measure(_:)`](https://developer.apple.com/documentation/xctest/xctestcase/1496290-measure) 来设立性能测试。如果在尝试后你还是对如何优化没有概念的话，不妨可以参考 RxSwift 中关于 ZipAll 的这个[高效实现](https://github.com/ReactiveX/RxSwift/blob/master/RxSwift/Observables/Zip%2BCollection.swift)。

### 2. 实现 `CombineLatestAll`

和 `Zip` 相对应的操作是 `CombineLatest`，我们对它应该已经非常熟悉了：和 `Zip` 等待**所有** `Publisher` 都发出值不同，它会在**任意** `Publisher` 发出值后即把各个 `Publisher` 的最新值合并且向外发送。Combine 中也只实现了 `CombineLatest`，`CombineLatest3` 和 `CombineLatest4`，但是没有更一般的接受任意多个 `Publisher` 的 `CombineLatestAll`。请你仿照 `ZipAll` 的方式，实现自定义的 `CombineLatestAll`。