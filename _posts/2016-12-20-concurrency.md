---
layout: post
title: "Swift 并行编程现状和展望 - async/await 和参与者模式"
date: 2016-12-20 12:53:11.000000000 +09:00
tags: 能工巧匠集
---

> 这篇文章不是针对当前版本 Swift 3 的，而是对预计于 2018 年发布的 Swift 5 的一些特性的猜想。如果两年后我还记得这篇文章，可能会回来更新一波。在此之前，请当作一篇对现代语言并行编程特性的不太严谨科普文来看待。

CPU 速度已经很多年没有大的突破了，硬件行业更多地将重点放在多核心技术上，而与之对应，软件中并行编程的概念也越来越重要。如何利用多核心 CPU，以及拥有密集计算单元的 GPU，来进行快速的处理和计算，是很多开发者十分感兴趣的事情。在今年年初 Swift 4 的展望中，Swift 项目的负责人 Chris Lattern 表示可能并不会这么快提供语言层级的并行编程支持，不过最近 Chris 又在 IBM 的一次关于[编译器的分享](http://researcher.watson.ibm.com/researcher/files/us-lmandel/lattner.pdf)中明确提到，有很大可能会在 Swift 5 中添加语言级别的并行特性。

![](/assets/images/2016/chris.jpg)

这对 Swift 生态是一个好消息，也是一个大消息。不过这其实并不是什么新鲜的事情，甚至可以说是一门现代语言发展的必经路径和必备特性。因为 Objective-C/Swift 现在缺乏这方面的内容，所以很多专注于 iOS 的开发者对并行编程会很陌生。我在这篇文章里结合 Swift 现状简单介绍了一些这门语言里并行编程可能的使用方式，希望能帮助大家初窥门径。(虽然我自己也还摸不到门径在何方...)

## Swift 现有的并行模型

Swift 现在没有语言层面的并行机制，不过我们确实有一些基于库的线程调度的方案，来进行并行操作。

### 基于闭包的线程调度

虽然恍如隔世，不过 GCD (Grand Central Dispatch) 确实是从 iOS 4 才开始走进我们的视野的。在 GCD 和 block 被加入之前，我们想要新开一个线程需要用到 `NSThread` 或者 `NSOperation`，然后使用 delegate 的方式来接收回调。这种书写方式太过古老，也相当麻烦，容易出错。GCD 为我们带来了一套很简单的 API，可以让我们在线程中进行调度。在很长一段时间里，这套 API 成为了 iOS 中多线程编程的主流方式。Swift 继承了这套 API，并且在 Swift 3 中将它们重新导入为了更符合 Swift 语法习惯的形式。现在我们可以将一个操作很容易地派发到后台进行，首先创建一个后台队列，然后调用 `async` 并传入需要执行的闭包即可：

```swift
let backgroundQueue = DispatchQueue(label: "com.onevcat.concurrency.backgroundQueue")
backgroundQueue.async {
    let result = 1 + 2
}
```

在 `async` 的闭包中，我们还可以继续进行派发，最常见的用法就是开一个后台线程进行耗时操作 (从网络获取数据，或者 I/O 等)，然后在数据准备完成后，回到主线程更新 UI：

```swift
let backgroundQueue = DispatchQueue(label: "com.onevcat.concurrency.backgroundQueue")
backgroundQueue.async {
    let url = URL(string: "https://api.onevcat.com/users/onevcat")!
    guard let data = try? Data(contentsOf: url) else { return }
    
    let user = User(data: data)
    DispatchQueue.main.async {
        self.userView.nameLabel.text = user.name
        // ...
    }
}
```

当然，现在估计已经不会有人再这么做网络请求了。我们可以使用专门的 `URLSession` 来进行访问。`URLSession` 和对应的 `dataTask` 会将网络请求派发到后台线程，我们不再需要显式对其指定。不过更新 UI 的工作还是需要回到主线程：

```swift
let url = URL(string: "https://api.onevcat.com/users/onevcat")!
URLSession.shared.dataTask(with: url) { (data, res, err) in
    guard let data = try? Data(contentsOf: url) else {
        return
    }
    let user = User(data: data)
    DispatchQueue.main.async {
        self.userView.nameLabel.text = user.name
        // ...
    }
}.resume()
```

### 回调地狱

基于闭包模型的方式，不论是直接派发还是通过 `URLSession` 的封装进行操作，都面临一个严重的问题。这个问题最早在 JavaScript 中臭名昭著，那就是回调地狱 (callback hell)。

试想一下我们如果有一系列需要依次进行的网络操作：先进行登录，然后使用返回的 token 获取用户信息，接下来通过用户 ID 获取好友列表，最后对某个好友点赞。使用传统的闭包方式，这段代码会是这样：

```swift
LoginRequest(userName: "onevcat", password: "123").send() { token, err in
    if let token = token {
        UserProfileRequest(token: token).send() { user, err in
            if let user = user {
                GetFriendListRequest(user: user).send() { friends, err in
                    if let friends = friends {
                        LikeFriendRequest(target: friends.first).send() { result, err in
                            if let result = result, result {
                                print("Success")
                                self.updateUI()
                            }
                        } else {
                            print("Error: \(err)")
                        }
                    } else {
                        print("Error: \(err)")                    
                    }
                }
            } else {
                print("Error: \(err)")
            }
        }
    } else {
        print("Error: \(err)")
    }
}
```

这已经是使用了尾随闭包特性简化后的代码了，如果使用完整的闭包形式的话，你会看到一大堆 `})` 堆叠起来。`else` 路径上几乎不可能确定对应关系，而对于成功的代码路径来说，你也需要很多额外的精力来理解这些代码。一旦这种基于闭包的回调太多，并嵌套起来，阅读它们的时候就好似身陷地狱。

![](/assets/images/2016/confused.jpg)

不幸的是，在 Cocoa 框架中我们似乎对此没太多好办法。不过我们确实有很多方法来解决回调地狱的问题，其中最成功的应该是 Promise 或者 Future 的方案。

### Promise/Future

在深入 Promise 或 Future 之前，我们先来将上面的回调做一些整理。可以看到，所有的请求在回调时都包含了两个输入值，一个是像 `token`，`user` 这样我们接下来会使用到的结果，另一个是代表错误的 `err`。我们可以创建一个泛型类型来代表它们：

```swift
enum Result<T> {
    case success(T)
    case failure(Error)
}
```

重构 `send` 方法接收的回调类型后，上面的 API 调用就可以变为：

```swift
LoginRequest(userName: "onevcat", password: "123").send() { result in
    switch result {
    case .success(let token):
        UserProfileRequest(token: token).send() { result in
            switch result {
            case .success(let user):
               // ...
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

看起来并没有什么改善，对么？我们只不过使用一堆 `({})` 的地狱换成了 `switch...case` 的地狱。但是，我们如果将 request 包装一下，情况就会完全不同。

```swift
struct Promise<T> {
    init(resolvers: (_ fulfill: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        //...
        // 存储 fulfill 和 reject。
        // 当 fulfill 被调用时解析为 then；当 reject 被调用时解析为 error。
    }
    
    // 存储的 then 方法，调用者提供的参数闭包将在 fulfill 时调用
    func then<U>(_ body: (T) -> U) -> Promise<U> {
        return Promise<U>{
            //...
        }
    }

    // 调用者提供该方法，参数闭包当 reject 时调用
    func `catch`<Error>(_ body: (Error) -> Void) {
        //...
    }
}

extension Request {
    var promise: Promise<Response> {
        return Promise<Response> { fulfill, reject in
            self.send() { result in
                switch result {
                case .success(let r): fulfill(r)
                case .failure(let e): reject(e)
                }
            }
        }
    }
}
```

我们这里没有给出 `Promise` 的具体实现，而只是给出了概念性的说明。`Promise` 是一个泛型类型，它的初始化方法接受一个以 `fulfill` 和 `reject` 作为参数的函数作为参数 (一开始这可能有点拗口，你可以结合代码再读一次)。这个类型里还提供了 `then` 和 `catch` 方法，`then` 方法的参数是另一个闭包，在 `fulfill` 被调用时，我们可以执行这个闭包，并返回新的 `Promise` (之后会看到具体的使用例子)：而在 `reject` 被调用时，通过 `catch` 方法中断这个过程。

在接下来的 `Request` 的扩展中，我们定义了一个返回 `Promise` 的计算属性，它将初始化一个内容类型为 `Response` 的 `Promise` (这里的 `Response` 是定义在 `Request` 协议中的代表该请求对应的响应的类型，想了解更多相关的内容，可以看看我之前的一篇[使用面向协议编程](/2016/12/pop-cocoa-2/)的文章)。我们在 `.success` 时调用 `fulfill`，在 `.failure` 时调用 `reject`。

现在，上面的回调地狱可以用 `then` 和 `catch` 的形式进行展平了：

```swift
LoginRequest(userName: "onevcat", password: "123").promise
 .then { token in
    return UserProfileRequest(token: token).promise
}.then { user in
    return GetFriendListRequest(user: user).promise
}.then { friends in
    return LikeFriendRequest(target: friends.first).promise
}.then { _ in
    print("Succeed!")
    self.updateUI()
    // 我们这里还需要在 Promise 中添加一个无返回的 then 的重载
    // 篇幅有限，略过
    // ...
}.catch { error in
    print("Error: \(error)")
}
```

`Promise` 本质上就是一个对闭包或者说 `Result` 类型的封装，它将未来可能的结果所对应的闭包先存储起来，然后当确实得到结果 (比如网络请求返回) 的时候，再执行对应的闭包。通过使用 `then`，我们可以避免闭包的重叠嵌套，而是使用调用链的方式将异步操作串接起来。`Future` 和 `Promise` 其实是同样思想的不同命名，两者基本指代的是一件事儿。在 Swift 中，有一些封装得很好的第三方库，可以让我们以这样的方式来书写代码，[PromiseKit](https://github.com/mxcl/PromiseKit) 和 [BrightFutures](https://github.com/Thomvis/BrightFutures) 就是其中的佼佼者，它们确实能帮助避免回调地狱的问题，让嵌套的异步代码变得整洁。

![](/assets/images/2016/future.jpg)

## async/await，“串行”模式的异步编程

虽然 Promise/Future 的方式能解决一部分问题，但是我们看看上面的代码，依然有不少问题。

1. 我们用了很多并不直观的操作，对于每个 request，我们都生成了额外的 `Promise`，并用 `then` 串联。这些其实都是模板代码，应该可以被更好地解决。
2. 各个 `then` 闭包中的值只在自己固定的作用域中有效，这有时候很不方便。比如如果我们的 `LikeFriend` 请求需要同时发送当前用户的 token 的话，我们只能在最外层添加临时变量来持有这些结果：

    ```swift
    var myToken: String = ""
    LoginRequest(userName: "onevcat", password: "123").promise
     .then { token in
        myToken = token
        return UserProfileRequest(token: token).promise
    } //...
    .then {
        print("Token is \(myToken)")
        // ...
    }
    ```
    
3. Swift 内建的 throw 的错误处理方式并不能很好地和这里的 `Result` 和 `catch { error in ... }` 的方式合作。Swift throw 是一种同步的错误处理方式，如果想要在异步世界中使用这种的话，会显得格格不入。语法上有不少理解的困难，代码也会迅速变得十分丑陋。

如果从语言层面着手的话，这些问题都是可以被解决的。如果对微软技术栈有所关心的同学应该知道，早在 2012 年 C# 5.0  发布时，就包含了一个让业界惊为天人的特性，那就是 `async` 和 `await` 关键字。这两个关键字可以让我们用类似同步的书写方式来写异步代码，这让思维模型变得十分简单。Swift 5 中有望引入类似的语法结构，如果我们有 async/await，我们上面的例子将会变成这样的形式：

```swift
@IBAction func bunttonPressed(_ sender: Any?) {
    // 1
    doSomething()
    print("Button Pressed")
}

// 2
async func doSomething() {
    print("Doing something...")
    do {
        // 3
        let token   = await LoginRequest(userName: "onevcat", password: "123").sendAsync()
        let user    = await UserProfileRequest(token: token).sendAsync()
        let friends = await GetFriendListRequest(user: user).sendAsync()
        let result  = await LikeFriendRequest(target: friends.first).sendAsync()
        print("Finished")
        
        // 4
        updateUI()
    } catch ... {
        // 5
        //...
    }
}

extension Request {
    // 6
    async func sendAsync() -> Response {
        let dataTask = ...
        let data = await dataTask.resumeAsync()
        return Response.parse(data: data)
    }
}
```

> 注意，以上代码是根据现在 Swift 语法，对如果存在 `async` 和 `await` 时语言的形式的推测。虽然这不代表今后 Swift 中异步编程模型就是这样，或者说 `async` 和 `await` 就是这样使用，但是应该代表了一个被其他语言验证过的可行方向。

按照注释的编号，进行一些简单的说明：

1. 这就是我们通常的 `@IBAction`，点击后执行 `doSomething`。
2. `doSomething` 被 `async` 关键字修饰，表示这是一个异步方法。`async` 关键字所做的事情只有一件，那就是允许在这个方法内使用 `await` 关键字来等待一个长时间操作完成。在这个方法里的语句将被以同步方式执行，直到遇到第一个 `await`。控制台将会打印 "Doing something..."。
3. 遇到的第一个 await。此时这个 `doSomething` 方法将进入等待状态，该方法将会“返回”，也即离开栈域。接下来 `bunttonPressed` 中 `doSomething` 调用之后的语句将被执行，控制台打印 "Button Pressed"。
4. `token`，`user`，`friends` 和 `result` 将被依次 `await` 执行，直到获得最终结果，并进行 `updateUI`。
5. 理论上 `await` 关键字在语义上应该包含 `throws`，所以我们需要将它们包裹在 `do...catch` 中，而且可以使用 Swift 内建的异常处理机制来对请求操作中发生的错误进行捕获和处理。换句话说，我们如果对错误不感兴趣，也可以使用类似 `try?` 和 `try!` 的
6. 对于 `Request`，我们需要添加 `async` 版本的发送请求的方法。`dataTask` 的 `resumeAsync` 方法是在 Foundation 中针对内建异步编程所重写的版本。我们在此等待它的结果，然后将结果解析为 model 后返回。

我们上面已经说过，可以将 `Promise` 看作是对 `Result` 的封装，而这里我们依然可以类比进行理解，将 `async` 看作是对 `Promise` 的封装。对于 `sendAsync` 方法，我们完全可以将它理解返回 `Promise`，只不过配合 `await`，这个 `Promise` 将直接以同步的方式被解包为结果。(或者说，`await` 是这样一个关键字，它可以等待 `Promise` 完成，并获取它的结果。)

```swift
func sendAsync() throws -> Promise<Response> {
   // ...
}

// await request.sendAsync()
// doABC()

// 等价于

(try request.sendAsync()).then {
    // doABC()
}
```

不仅在网络请求中可以使用，对于所有的 I/O 操作，Cocoa 应当也会提供一套对应的异步 API。甚至于对于等待用户操作和输入，或者等待某个动画的结束，都是可以使用 `async/await` 的潜在场景。如果你对响应式编程有所了解的话，不难发现，其实响应式编程想要解决的就是异步代码难以维护的问题，而在使用 `async/await` 后，部分的异步代码可以变为以同步形式书写，这会让代码书写起来简单很多。

Swift 的 `async` 和 `await` 很可能将会是基于 [Coroutine](https://en.wikipedia.org/wiki/Coroutine) 进行实现的。不过也有可能和 C# 类似，编译器通过将 `async` 和 `await` 的代码编译为带有状态机的片段，并进行调度。Swift 5 的预计发布时间会是 2018 年底，所以现在谈论这些技术细节可能还为时过早。

## 参与者 (actor) 模型

讲了半天 `async` 和 `await`，它们所要解决的是异步编程的问题。而从异步编程到并行编程，我们还需要一步，那就是将多个异步操作组织起来同时进行。当然，我们可以简单地同时调用多个 `async` 方法来进行并行运算，或者是使用某些像是 GCD 里 `group` 之类的特殊语法来将复数个 `async` 打包放在一起进行调用。但是不论何种方式，都会面临一个问题，那就是这套方式使用的是命令式 (imperative) 的语法，而非描述性的 (declarative)，这将导致扩展起来相对困难。

并行编程相对复杂，而且与人类天生的思考方式相违背，所以我们希望尽可能让并行编程的模型保持简单，同时避免直接与线程或者调度这类事务打交道。基于这些考虑，Swift 很可能会参考 [Erlang](http://www.erlang.org) 和 [AKKA](http://akka.io) 中已经很成功的参与者模型 (actor model) 的方式实现并行编程，这样开发者将可以使用默认的分布式方式和描述性的语言来进行并行任务。

所谓参与者，是一种程序上的抽象概念，它被视为并发运算的基本单元。参与者能做的事情就是接收消息，并且基于收到的消息做某种运算。这和面向对象的想法有相似之处，一个对象也接收消息 (或者说，接受方法调用)，并且根据消息 (被调用的方法) 作出响应。它们之间最大的不同在于，参与者之间永远相互隔离，它们不会共享某块内存。一个参与者中的状态永远是私有的，它不能被另一个参与者改变。

和面向对象世界中“万物皆对象”的思想相同，参与者模式里，所有的东西也都是参与者。单个的参与者能力十分有限，不过我们可以创建一个参与者的“管理者”，或者叫做 actor system，它在接收到特定消息时可以创建新的参与者，并向它们发送消息。这些新的参与者将实际负责运算或者操作，在接到消息后根据自身的内部状态进行工作。在 Swift 5 中，可能会用下面的方式来定义一个参与者：

```swift
// 1
struct Message {
    let target: String
}

// 2
actor NetworkRequestHandler {
    var localState: UserID
    async func processRequest(connection: Connection) {
       // ...
       // 在这里你可以 await 一个耗时操作
       // 并改变 `localState` 或者向 system 发消息
    }
    
    // 3
    message {
        Message(let m): processRequest(connection: Connection(m.target))
    }
}

// 4
let system = ActorSystem(identifier: "MySystem")
let actor = system.actorOf<NetworkRequestHandler>()
actor.tell(Message(target: "https://onevcat.com"))
```

> 再次注意，这些代码只是对 Swift 5 中可能出现的参与者模式的一种猜想。最后的实现肯定会和这有所区别。不过如果 Swift 中要加入参与者，应该会和这里的表述类似。

1. 这里的 `Message` 是我们定义的消息类型。
2. 使用 `actor` 关键字来定义一个参与者模型，它其中包含了内部状态和异步操作，以及一个隐式的操作队列。
3. 定义了这个 actor 需要接收的消息和需要作出的响应。
4. 创建了一个 actor system (`ActorSystem` 这里没有给出实现，可能会包含在 Swift 标准库中)。然后创建了一个 `NetworkRequestHandler` 参与者，并向它发送一条消息。

这个参与者封装了一个异步方法以及一个内部状态，另外，因为该参与者会使用一个自己的 DispatchQueue 以避免和其他线程共享状态。通过 actor system 进行创建，并在接收到某个消息后执行异步的运算方法，我们就可以很容易地写出并行处理的代码，而不必关心它们的内部状态和调度问题了。现在，你可以通过 `ActorSystem` 来创建很多参与者，然后发送不同消息给它们，并进行各自的操作。并行编程变得前所未有的简单。

参与者模式相比于传统的自己调度有两个显著的优点：

首先，因为参与者之间的通讯是消息发送，这意味着并行运算不必被局限在一个进程里，甚至不必局限在一台设备里。只要保证消息能够被发送 (比如使用 [IPC](https://en.wikipedia.org/wiki/Inter-process_communication) 或者 [DMA](https://en.wikipedia.org/wiki/Direct_memory_access))，你就完全可以使用分布式的方式，使用多种设备 (多台电脑，或者多个 GPU) 进行并行操作，这带来的是无限可能的扩展性。

另外，由于参与者之间可以发送消息，那些操作发生异常的参与者有机会通知 system 自己的状态，而 actor system 也可以根据这个状态来重置这些出问题的参与者，或者甚至是无视它们并创建新的参与者继续任务。这使得整个参与者系统拥有“自愈”的能力，在传统并行编程中想要处理这件事情是非常困难的，而参与者模型的系统得益于此，可以最大限度保障系统的稳定性。

## 这些东西有什么用

两年下来，Swift 已经证明了自己是一门非常优秀的 app 语言。即使 Xcode 每日虐我千百遍，但是现在让我回去写 Objective-C 的话，我从内心是绝对抗拒的。Swift 的野心不仅于此，从 Swift 的开源和进化方向，我们很容易看出这门语言希望在服务器端也有所建树。而内建的异步支持以及参与者模式的并行编程，无疑会为 Swift 在服务器端的运用添加厚重的砝码。异步模型对写 app 也会有所帮助，更简化的控制流程以及隐藏起来的线程切换，会让我们写出更加简明优雅的代码。

C# 的 async/await 曾经为开发者们带来一股清流，Elixir 或者说 Erlang 可以说是世界上最优秀的并行编程语言，JVM 上的 AKKA 也正在支撑着无数的亿级服务。我很好奇当 Swift 遇到这一切的时候，它们之间的化学反应会迸发出怎样的火花。虽然每天还在 Swift 3 的世界中挣扎，但是我想我的心已经飞跃到 Swift 5 的并行世界中去了。


