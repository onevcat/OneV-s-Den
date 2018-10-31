---
layout: post
title: "Result&lt;T&gt; 还是 Result&lt;T, E: Error&gt;"
date: 2018-10-31 11:38:00.000000000 +09:00
tags: 能工巧匠集
---

> 我之前在[专栏文章](https://xiaozhuanlan.com/topic/4718350296)里曾经发布这篇文章，由于这个话题其实还是挺重要的，可以说代表了 Swift 今后发展的方向流派，所以即使和专栏文章内容有些重复，我还是想把它再贴到博客来。经过半年以后，自己对于这个问题也有了更多的实践和想法，所以同时也更新了一下。我没有直接改动原文，而是把新的想法和需要补充的说明，用类似这段话的引用的方式写在合适的上下文里。

### 开始先打个广告

我个人经常会在[数码荔枝](https://www.lizhi.io)用优惠价格购买面向中国用户的一些软件，相比于花美金直接购买，价格非常实惠。近年来国内的正版风气和对知识知识产权的尊重的进步，是有目共睹的，这很大程度上也要归功于像数码荔枝这样的分销商可以和开发商讨论出更适合国内的定价和销售策略。让我，或者让像我一样的开发者，能节省出一些奶粉钱和尿布钱...

最近我和数码荔枝有一些接触，有一些长期合作的推广。如果大家对某款软件有兴趣，不妨先到数码荔枝的店面找找看，也许能为你省下不少银子。另外也可以访问我的[推广页面领取通用的优惠券](https://partner.lizhi.io/onevcat/cp)，然后再使用优惠券购买任意你中意的软件。优惠券也可以多次重复领取，任意使用。

最后，他们定期也会推出一些力度很大的半价促销，比如 ¥94 就能买到 $79.99 的 PDF Expert 这种不可思议的事情..这个促销到年底为止，如果有在 macOS 上看 PDF 又不满足于系统预览的羸弱功能和性能的小伙伴们可[千万不要错过](https://partner.lizhi.io/onevcat/pdf_expert_for_mac)。

[![](/assets/images/2018/pdf-expert.png)](https://partner.lizhi.io/onevcat/pdf_expert_for_mac)

### 背景知识

Cocoa API 中有很多接受回调的异步方法，比如 `URLSession` 的 `dataTask(with:completionHandler:)`。

```swift
URLSession.shared.dataTask(with: request) {
    data, response, error in
        if error != nil {
            handle(error: error!)
        } else {
            handle(data: data!)
        }
}
```

有些情况下，回调方法接受的参数比较复杂，比如这里有三个参数：`(Data?, URLResponse?, Error?)`，它们都是可选值。当 session 请求成功时，`Data` 参数包含 response 中的数据，`Error` 为 `nil`；当发生错误时，则正好相反，`Error` 指明具体的错误 (由于历史原因，它会是一个 `NSError` 对象)，`Data` 为 `nil`。

> 关于这个事实，`dataTask(with:completionHandler:)` 的[文档的 Discussion 部分](https://developer.apple.com/documentation/foundation/urlsession/1407613-datatask)有十分详细的说明。另外，`response: URLResponse?` 相对复杂一些：不论是请求成功还是失败，只要从 server 收到了 `response`，它就会被包含在这个变量里。

这么做虽然看上去无害，但其实存在改善的余地。显然 `data` 和 `error` 是互斥的：事实上是不可能存在 `data` 和 `error` 同时为 `nil` 或者同时非 `nil` 的情况的，但是编译器却无法静态地确认这个事实。编译器没有制止我们在错误的 `if` 语句中对 `nil` 值进行解包，而这种行为将导致运行时的意外崩溃。

我们可以通过一个简单的封装来改进这个设计：如果你实际写过 Swift，可能已经对 `Result` 很熟悉了。它的思想非常简单，用泛型将可能的返回值包装起来，因为结果是成功或者失败二选一，所以我们可以藉此去除不必要的可选值。

```swift
enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}
```

把它运用到 `URLSession` 中的话，包装一下 `URLSession` 方法，上面调用可以变为：

```swift
// 如果 Result 存在于标准库的话，
// 这部分代码应该由标准库的 Foundataion 扩展进行实现
extension URLSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Result<(Data, URLResponse), NSError>) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { data, response, error in
            if error != nil {
                completionHandler(.failure(error! as NSError))
            } else {
                completionHandler(.success((data!, response!)))
            }
        }
    }
}

URLSession.shared.dataTask(with: request) { result in
    switch result {
    case .success(let (data, _)):
        handle(data: data)
    case .failure(let error):
        handle(error: error)
    }
}
```

> 这里原文代码中 `completionHandler` 里 `(Result<(Data, URLResponse), NSError>) -> Void)` 这个类型是错误的。`Data` 存在时 `URLResponse` 一定存在，但是我们上面讨论过，当 `NSError` 不为 `nil` 时，`URLResponse` 也可能存在。原文代码忽略了这个事实，将导致 error 状况时无法获取到可能的 `URLResponse`。正确的类型应该是 `(Result<(Data), NSError>, URLResponse?) -> Void`
> 
> 当然，在回调中对 `result` 的处理也需要对应进行修改。

调用的时候看起来很棒，我们可以避免检查可选值的情况，让编译器保证在对应的 `case` 分支中有确定的非可选值。这个设计在很多存在异步代码的框架中被广泛使用，比如 [Swift Package Manager](https://github.com/apple/swift-package-manager/blob/master/Sources/Basic/Result.swift)，[Alamofire](https://github.com/Alamofire/Alamofire/blob/master/Source/Result.swift) 等中都可觅其踪。

> 上面代码注释中提到，「如果 Result 存在于标准库的话，这部分代码应该由标准库的 Foundataion 扩展进行实现」。但是考虑到原有的可选值参数 (`(Data?, URLResponse?, Error?)`) 作为回调的 API 将会共享同样的函数名，所以上面的函数命名是不可取的，否则将导致冲突。在这类 public API 发布后，如何改善和迭代确实是个难题。一个可行的方法是把 Foundation 的 `URLSession` deprecate 掉，提取出相关方法放到诸如 Network.framework 里，并让它跨平台。另一种可行方案是通过自动转换工具，强制 Swift 使用 `Result` 的回调，并保持 OC 中的多参数回调。如果你正在打算使用 `Result` 改善现有设计，并且需要考虑保持 API 的兼容性时，这会是一个不小的挑战。

### 错误类型泛型参数

如此常用的一个可以改善设计的定义，为什么没有存在于标准库中呢？关于 `Result`，其实已经有[相关的提案](https://github.com/apple/swift-evolution/pull/757)：

![](/assets/images/2018/result-type.png)

这个提案中值得注意的地方在于，`Result` 的泛型类型只对成功时的值进行了类型约束，而忽略了错误类型。给出的 `Result` 定义类似这样：

```swift
enum Result<T> {
    case success(T)
    case failure(Error)
}
```

很快，在 1 楼就有人质疑，问这样做的意义何在，因为毕竟很多已存在的 `Result` 实现都是包含了 `Error` 类型约束的。确定的 `Error` 类型也让人在使用时多了一份“安全感”。

不过，其实我们实际类比一下 Swift 中已经存在的错误处理的设计。Swift 中的 `Error` 只是一个协议，在 throw 的时候，我们也并不会指明需要抛出的错误的类型：

```swift
func methodCanThrow() throws {
    if somethingGoesWrong {
        // 在这里可以 throw 任意类型的 Error
    }
}

do {
    try methodCanThrow()
} catch {
    if error is SomeErrorType {
        // ...
    } else if error is AnotherErrorType {
        // ...
    }
}
```

但是，在带有错误类型约束的 `Result<T, E: Error>` 中，我们需要为 `E` 指定一个确定的错误类型 (或者说，Swift 并不支持在特化时使用协议，`Result<Response, Error>` 这样的类型是非法的)。这与现有的 Swift 错误处理机制是背道而驰的。

> 关于 Swift 是否应该抛出带有类型的错误，曾经存在过一段时间的争论。最终问题归结于，如果一个函数可以抛出多种错误 (不论是该函数自身产生的错误，还是在函数中 try 其他函数时它们所带来的更底层的错误)，那么 `throws` 语法将会变得非常复杂且不可控 (试想极端情况下某个函数可能会抛出数十种错误)。现在大家一致的看法是已有的用 `protocol Error` 来定义错误的做法是可取的，而且这也编码在了语言层级，我们对「依赖编译器来确定 `try catch` 会得到具体哪种错误」这件事，几乎无能为力。
> 
> 另外，半开玩笑地说，要是 Swift 能类似这样 `extension Swift.Error: Swift.Error {}`，支持协议遵守自身协议的话，一切就很完美了，XD。

### 选择哪个比较好？

两种方式各有优缺点，特别在如果需要考虑 Cocoa 兼容的情况下，更并说不上哪一个就是完胜。这里将两种写法的优缺点简单比较一下，在实践中最好是根据项目情况进行选择。

#### Result<T, E: Error>

##### 优点

1. 可以由编译器帮助进行确定错误类型

    当通过使用某个具体的错误类型扩展 `Error` 并将它设定为 `Result` 的错误类型约束后，在判断错误时我们就可以比较容易地检查错误处理的完备情况了：

    ```swift
    enum UserRegisterError: Error {
        case duplicatedUsername
        case unsafePassword
    }
        
    userService.register("user", "password") {
        result: Result<User, UserRegisterError> in
        switch result {
        case .success(let user):
            print("User registered: \(user)")
        case .failure(let error):
            if error == .duplicatedUsername {
                // ...
            } else if error == .unsafePassword {
                // ...
            }
        }
    }
    ```

    上例中，由于 `Error` 的类型已经可以被确定是 `UserRegisterError`，因此在 `failure` 分支中的检查变得相对容易。
    
    > 这种编译器的类型保证给了 API 使用者相当强的信心，来从容进行错误处理。如果只是一个单纯的 `Error` 类型，API 的用户将面临相当大的压力，因为不翻阅文档的话，就无从知晓需要处理怎样的错误，而更多的情况会是文档和事实不匹配...
    > 
    > 但是带有类型的错误就相当容易了，查看该类型的 public member 就能知道会面临的情况了。在制作和发布框架，以及提供给他人使用的 API 的时候，这一点非常重要。

2. 按条件的协议扩展

    使用泛型约束的另一个好处是可以方便地对某些情况的 `Result` 进行扩展。

    举例来说，某些异步操作可能永远不会失败，对于这些操作，我们没有必要再使用 switch 去检查分支情况。一个很好的例子就是 `Timer`，我们设定一个在一段时间后执行的 Timer 后，如果不考虑人为取消，这个 Timer 总是可以正确执行完毕，而不会发生任何错误的。我们可能会选择使用一个特定的类型来代表这种情况：

    ```swift
    enum NoError: Error {}
    
    func run(after: TimeInterval, done: @escaping (Result<Timer, NoError>) -> Void ) {
        Timer.scheduledTimer(withTimeInterval: after, repeats: false) { timer in
            done(.success(timer))
        }
    }
    ```

    在使用的时候，本来我们需要这样的代码：

    ```swift
    run(after: 2) { result in
        switch result {
        case .success(let timer):
            print(timer)
        case .failure:
            fatalError("Never happen")
        }
    }
    ```

    但是，通过对 `E` 为 `NoError` 的情况添加扩展，可以让事情简单不少：

    ```swift
    extension Result where E == NoError {
        var value: T {
            if case .success(let v) = self {
                return v
            }
            fatalError("Never happen")
        }
    }
    
    run(after: 2) {
        // $0.value is the timer object
        print($0.value)
    }
    ```

    > 这个 `Timer` 的例子虽然很简单，但是可能实际上意义不大，因为我们可以直接使用 `Timer.scheduledTimer` 并使用简单的 block 完成。但是当回调 block 有多个参数时，或者需要链式调用 (比如为 `Result` 添加 `map`，`filter` 之类的支持时)，类似 `NoError` 这样的扩展方式就会很有用。

    > 在 NSHipster 里有一篇[关于 `Never` 的文章](https://nshipster.com/never/)，提到使用 `Never` 来代表无值的方式。其中就给出了一个和 `Result` 一起使用的例子。我们只需要使 `extension Never: Error {}` 就可以将它指定为 `Result<T, E: Error>` 的第二个类型参数，从而去除掉代码中对 `.failure` case 的判断。这是比 `NoError` 更好的一种方式。
    > 
    > 当然，如果你需要一个只会失败不会成功的 `Result` 的话，也可以将 `Never` 放到第一个类型参数的位置：`Result<Never, E: Error>`。

##### 缺点

1. 与 Cocoa 兼容不良

    由于历史原因，Cocoa API 中表达的错误都是”无类型“的 `NSError` 的。如果你跳出 Swift 标准库，要去使用 Cocoa 的方法 (对于在 Apple 平台开发来说，这简直是一定的)，就不得不面临这个问题。很多时候，你可能会被迫写成 `Result<SomeValue, NSError>` 的形式，这样我们上面提到的优点几乎就丧失殆尽了。

2. 可能需要多层嵌套或者封装

    即使对于限定在 Swift 标准库的情况来说，也有可能存在某个 API 产生若干种不同的错误的情况。如果想要完整地按照类型处理这些情况，我们可能会需要将错误嵌套起来：

    ```swift    
    // 用户注册可能产生的错误
    // 当用户注册的请求完成且返回有效数据，但数据表明注册失败时触发
    enum UserRegisterError: Error {
        case duplicatedUsername
        case unsafePassword
    }
    
    // Server API 整体可能产生的错误
    // 当请求成功但 response status code 不是 200 时触发
    enum APIResponseError: Error {
        case permissionDenied // 403
        case entryNotFound    // 404
        case serverDied       // 500
    }
    
    // 所有的 API Client 可能发生的错误
    enum APIClientError: Error {
        // 没有得到响应
        case requestTimeout
    
        // 得到了响应，但是 HTTP Status Code 非 200
        case apiFailed(APIResponseError)
                
        // 得到了响应且为 200，但数据无法解析为期望数据
        case invalidResponse(Data)
    
        // 请求和响应一切正常，但 API 的结果是失败 (比如注册不成功)
        case apiResultFailed(Error)
    }
    ```
    
    > 上面的错误嵌套比较幼稚。更好的类型结构是将 `UserRegisterError` 和 `APIResponseError` 定义到 `APIClientError` 里，另外，因为不会直接抛出，因此没有必要让 `UserRegisterError` 和 `APIResponseError` 遵守 `Error` 协议，它们只需要承担说明错误原因的任务即可。
    > 
    > 对这几个类型加以整理，并重新命名，现在我认为比较合理的错误定义如下 (为了简短一些，我去除了注释)：
    > 
    > ```swift
    > enum APIClientError: Error {
    > 
    >     enum ResponseErrorReason {
    >         case permissionDenied
    >         case entryNotFound
    >         case serverDied
    >     }
    > 
    >     enum ResultErrorReason {
    >         enum UserRegisterError {
    >             case duplicatedUsername
    >             case unsafePassword
    >         }
    > 
    >         case userRegisterError(UserRegisterError)
    >     }
    > 
    >     case requestTimeout
    >     case apiFailed(ResponseErrorReason)
    >     case invalidResponse(Data)
    >     case apiResultFailed(ResultErrorReason)
    > }
    > ```
    > 
    > 当然，如果随着嵌套过深而缩进变多时，你也可以把内嵌的 `Reason` enum 放到 `APIClientError` 的 extension 里去。

    上面的 `APIClientError` 涵盖了进行一次 API 请求时所有可能的错误，但是这套方式在使用时会很痛苦：
    
    ```swift
    API.send(request) { result in
        switch result {
        case .success(let response): //...
        case .failure(let error):
            switch error {
            case .requestTimeout: print("Timeout!")
            case .apiFailed(let apiFailedError):
                switch apiFailedError: {
                    case .permissionDenied: print("403")
                    case .entryNotFound: print("404")
                    case .serverDied: print("500")
                }
            case .invalidResponse(let data):
                print("Invalid response body data: \(data)")
            case .apiResultFailed(let apiResultError):
                if let apiResultError = apiResultError as? UserRegisterError {
                    switch apiResultError {
                        case .duplicatedUsername: print("User already exists.")
                        case .unsafePassword: print("Password too simple.")
                    }
                }
            }
        }
    }
    ```
    
    相信我，你不会想要写这种代码的。
    
    > 经过半年的实践，事实是我发现这样的代码并没有想象中的麻烦，而它带来的好处远远超过所造成的不便。
    >
    > 这里代码中有唯一一个 `as?` 对 `UserRegisterError` 的转换，如果采用更上面引用中定义的 `ResultErrorReason`，则可以去除这个类型转换，而使类型系统覆盖到整个错误处理中。
    > 
    > 相较于对每个 API 都写这样一堆错误处理的代码，我们显然更倾向于集中在一个地方处理这些错误，这在某种程度上“强迫”我们思考如何将错误处理的代码抽象化和一般化，对于减少冗余和改善设计是有好处的。另外，在设计 API 时，我们可以提供一系列的便捷方法，来让 API 的用户能很快定位到某几个特定的感兴趣的错误，并作出处理。比如：
    > 
    > ```swift
    > extension APIClientError {
    >     var isLoginRequired: Bool {
    >         if case .apiFailed(.permissionDenied) = self {
    >             return true
    >         }
    >         return false
    >     }
    > }
    > ```
    > 
    > 用 `error.isLoginRequired` 即可迅速确定是否是由于用户权限不足，需要登录，产生的错误。这部分内容可以由 API 的提供者主动定义 (这样做也起到一种指导作用，来告诉 API 用户到底哪些错误是特别值得关心的)，也可以由使用者在之后自行进行扩展。
    
    另一种”方便“的做法是使用像是 `AnyError` 的类型来对 `Error` 提供封装：
    
    ```swift
    struct AnyError: Error {
        let error: Error
    }
    ```
    
    这可以把任意 `Error` 封装并作为 `Result<Value, AnyError>` 的 `.failure` 成员进行使用。但是这时 `Result<T, E: Error>` 中的 `E` 几乎就没有意义了。
    
    > Swift 中存在不少 `Any` 开头的类型，比如 `AnyIterator`，`AnyCollection`，`AnyIndex` 等等。这些类型起到的作用是类型抹消，有它们存在的历史原因，但是随着 Swift 的发展，特别是加入了 Conditional Conformance 以后，这一系列 `Any` 类型存在的意义就变小了。
    > 
    > 使用 `AnyError` 来进行封装 (或者说对具体 Error 类型进行抹消)，可以让我们抛出任意类型的错误。这更多的是一种对现有 Cocoa API 的妥协。对于纯 Swift 环境来说，`AnyError` 并不是理想中应该存在的类型。因此如果你选择了 `Result<T, E: Error>` 的话，我们就应该尽可能避免抛出这种无类型的错误。
    > 
    > 那问题就回到了，对于 Cocoa API 抛出的错误 (也就是以前的 `NSError`)，我们应该怎样处理？一种方式是按照文档进行封装，比如将所有 `NSURLSessionError` 归类到一个 `URLSessionErrorReason`，然后把从 Cocoa 得到的 `NSError` 作为关联值传递给使用者；另一种方式是在抛出给 API 使用者之前，在内部就对这个 Cocoa 错误进行“消化”，将它转换为有意义的特定的某个已经存在的 Error Reason。后者虽然减轻了 API 使用者的压力，但是势必会丢失一些信息，所以如果没有特别理由的话，第一种的做法可能更加合适。

3. 错误处理的 API 兼容存在风险

    现在来说，为 enum 添加一个 case 的操作是无法做到 API 兼容的。使用侧如果枚举了所有的 case 进行处理的话，在 case 增加时，原来的代码将无法编译。(不过对于错误处理来说，这倒可能对强制开发者对应错误情况是一种督促 233..)

    如果一个框架或者一套 API 严格遵守 [semantic version](https://semver.org) 的话，这意味着一个大版本的更新。但是其实我们都心知肚明，增加一个之前可能忽略了的错误情况，却带来一个大版本更新，带来的麻烦显然得不偿失。

    Swift 社区现在对于增加 enum case 时如何保持 API compatibility 也有一个[成熟而且已经被接受了的提案](https://github.com/apple/swift-evolution/blob/af284b519443d3d985f77cc366005ea908e2af59/proposals/0192-non-exhaustive-enums.md)。将 enum 定义为 `frozen` 和 `nonFrozen`，并对 `nonFrozen` 的 enum 使用 `unknown` 关键字来保证源码兼容。我们在下个版本的 Swift 中应该就可以使用这个特性了。

#### Result<T>

不带 `Error` 类型的优缺点正好和上面相反。

相对于 `Result<T, E: Error>`，`Result<T>` 不在外部对错误类型提出任何限制，API 的创建者可以摆脱 `AnyError`，直接将任意的 `Error` 作为 `.failure` 值使用。

但同时很明显，相对的，一个最重要的特性缺失就是我们无法针对错误类型的特点为 `Result` 进行扩展了。

### 结论

因为 Swift 并没有提供使用协议类型作为泛型中特化的具体类型的支持，这导致在 API 的强类型严谨性和灵活性上无法取得两端都完美的做法。硬要对比的话，可能 `Result<T, E: Error>` 对使用者更加友好一些，因为它提供了一个定义错误类型的机会。但是相对地，如果创建者没有掌握好错误类型的程度，而将多层嵌套的错误传递时，反而会增加使用者的负担。同时，由于错误类型被限定，导致 API 的变更要比只定义了结果类型的 `Result<T>` 困难得多。

不过 `Result` 暂时看起来不太可能被添加到标准库中，因为它背后存在一个更大的协程和整个语言的异步模型该如何处理错误的话题。在有更多的实践和讨论之前，如果没有革命性和语言创新的话，对如何进行处理的话题，恐怕很难达成完美的共识。

结论：错误处理真的是一件相当艰难的事情。

> 最近这半年，在不同项目里，我对  `Result<T, E: Error>` 和 `Result<T>` 两种方式都进行了一些尝试。现在看来，我会更多地选择带有错误类型的 `Result<T, E: Error>`  的形式，特别是在开发框架或者需要严谨的错误处理的时候。将框架中可能抛出的错误进行统一封装，可以很大程度上减轻使用者的压力，让错误处理的代码更加健壮。如果设计得当，它也能提供更好的扩展性。
