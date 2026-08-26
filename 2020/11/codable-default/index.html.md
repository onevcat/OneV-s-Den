---
layout: post
title: "使用 Property Wrapper 为 Codable 解码设定默认值"
date: 2020-11-10 14:00:00 +0900
categories: [能工巧匠集, Swift]
tags: [swift, 最佳实践, api, codable]
---

本文介绍了一个使用 Swift Codable 解码时难以设置默认值问题，并利用 Property Wrapper 给出了一种相对优雅的解决方式，来在 key 不存在时或者解码失败时，为某个属性设置默认值。这为编解码系统提供了更好的稳定性和可扩展性。最后，对 enum 类型在某些情况下是否胜任进行了简单讨论。

> [示例代码](https://gist.github.com/onevcat/0f055ece50bd0c07e882890129dfcfb8)

## Codable 类型中可选值的窘 (囧?) 境 

### 基础类型可选值

Codable 的引入极大简化了 JSON 和 Swift 中的类型之间相互转换的难度。当我们将 Swift 类型中的一个值设定为可选值 (Optional) 时，意味着即使 JSON 中这个值缺失了，我们也可以将 JSON 成功解码。比如 `Video` 类型代表了一段视频直播，其中 up 主可以设定是否接受评论：

```swift
struct Video: Decodable {
    let id: Int
    let title: String
    let commentEnabled: Bool?
}
```

下面的情况：

```js
{"id": 12345, "title": "My First Video"}
```

将解码得到：

> Video(id: 12345, title: "My First Video", commentEnabled: nil)

引入可选的 `commentEnabled`，会导致使用起来相当麻烦。很可能我们不得不在 view controller 层级上去写这样的代码：

```swift
if video.commentEnabled ?? false {
    // 在这里显示 comment UI
}
```

这让代码变得很丑，而且会散落在使用到 `commentEnabled` 的各个地方。如果我们想要的是，当 `"commentEnabled"` key 不存在时，将对应的属性设为 `false`，应该要怎么做呢？

Swift 的 `Decodable` 并不支持在声明存储属性时为它指定默认值。如果强制进行赋值，你将会收获一个警告，JSON 值也无法被正确解析：

```swift
// 错误的代码
struct Video: Decodable {
    let id: Int
    let title: String
    let commentEnabled: Bool = false
    
    // Warning: Immutable property will not be 
    // decoded because it is declared with an 
    // initial value which cannot be overwritten
}

// {"id": 12345, "title": "My First Video", "commentEnabled": true}
// => Video(id: 12345, title: "My First Video", commentEnabled: false)
```

显然这是不对的。

一个稍微好一些的做法是，为 `commentEnabled: Bool?` 设定一个特殊的 getter，来统一在一个地方返回不存在时的默认值：

```swift
struct Video: Decodable {
    // ...
    private let commentEnabled: Bool?
    var resolvedCommentEnabled: Bool { 
        commentEnabled ?? false
    }
}
```

相信你和我一样，会非常头疼 `resolvedCommentEnabled` 的名字到底应该怎么决定，这也带来了某种意义上的重复。

最不偷懒的解决方式，当然是为整个 `Video` 重写解码所需要的 `init(from:)` 方法，来在 `commentEnabled` key 不存在时直接设定默认值：

```swift
struct Video: Decodable {
    let id: Int
    let title: String
    let commentEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, commentEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        commentEnabled = try container.decodeIfPresent(Bool.self, forKey: .commentEnabled) ?? false
    }
}

// {"id": 12345, "title": "My First Video"}
// Video(id: 12345, title: "My First Video", commentEnabled: false)
```

问题在于，可能会有其他类型也有类似的需求。就算预先设置了模板，但去为每个类型添加这么一坨 `CodingKeys` 和 `init(from:)`，想象一下就觉得是很恶心的事情。就算在这里我们为 `commentEnabled` 这个 `Bool` 值添加了默认的解析，对于其他类型中类似需求的 `Bool` 属性，还是需要再来一次。我们有没有更好的方法来对应**“给 Decodable 的属性添加默认值”**这件事情呢？

### 更大的陷阱：自定义类型的可选值

在开始尝试解决问题之前，先来看一个更致命的情况。对于上面的 `Bool?`，最多只是让我们的代码麻烦一些，还不至于出现大问题。但是如果我们希望的是对一个更复杂的类型进行解码，情况就会迅速恶化。考虑下面的代码：

```swift
struct Video: Decodable {
    enum State: String, Decodable {
        case streaming // 正在直播
        case archived  // 已完成
    }
    
    // ...
    
    let state: State
}
```

这里添加了 `Video.State`，我们将它声明为 `String` enum，且满足 `Decodable`。对于这样的 enum 类型，我们不需要额外进行实现，编译器就会帮助我们补完解码代码，这会把 `"streaming"` 和 `"archived"` 分别解码到对应的 case 中去：

```js
{"id": 12345, "title": "My First Video", "state": "archived"}

// Video(
//   id: 12345, 
//   title: "My First Video",
//   commentEnabled: nil, 
//   state: Video.State.archived
// )
```

看起来很美好，但是考虑一下，如果将来服务器新增了一个状态，比如 up 主“提前预约”了一次直播时，服务器将返回 `"reserved"`。毫无疑问，我们上面的代码无法将 `"reserved"` 解析为 `State` 中的任何一个值，于是整个 `Video` 类型的解析就都挂掉了：

```js
{"id": 12345, "title": "My First Video", "state": "reserved"}

// error: Swift.DecodingError.dataCorrupted
// Cannot initialize State from invalid String value reserved
```

根据你想要实现的效果，在 client app 中，这可能是一个非常严重的问题。更麻烦的是，即使你将 `state` 声明为可选值的 `State?`，依然还是解决不了这个情况：可选值的解码所表达的是“如果不存在，则置为 nil”，而**不是**“如果解码失败，则置为 nil”。所以下面的改变不会对问题有任何帮助：

```swift
struct Video: Decodable {
    // ...
    let state: State?
}

// {"id": 12345, "title": "My First Video", "state": "reserved"}
// error: Swift.DecodingError.dataCorrupted
// Cannot initialize State from invalid String value reserved
```

只要 "state" key 在 JSON 中存在，那么解码就会发生；只要等待解码的数据无法初始化一个 `State`，那么整个值的解码就会失败。

当然，我们可以参照上面处理 `Bool` 的方法，在 `Video` 中把 `state` 声明为 `String`， 然后用一个 getter 设定默认值，比如：

```swift
enum State: String, Decodable {
    case streaming
    case archived
    case unknown
}

private let state: String
var resolvedState: State {
    State(rawValue: state) ?? .unknown
}
```

或者直接为 `Video` 重写 `init(from:)`。不过无论怎么做，都不是很理想。

有没有更好的方式来处理上面这两个问题呢？答案是使用 property wrapper。

## Default property wrapper 的设计

最正确且通用的解决方式当然是为每个需要默认值的类型重写 `init(from:)`。不过 Codable 系统最便利的地方就在于可以自动为满足 Codable 的类型和每个属性生成代码。我们例子中的矛盾在于，编译器为某个类型 (比如 `Bool` 或者 `Video.State`) 生成的解码代码不能满足要求。想要对某个 property “做手脚”，property wrapper 当然是首选。

> 如果你对 property wrapper 还不熟悉，可以先把它理解成一组特别的 getter 和 setter：它提供一个特殊的盒子，把原来值的类型包装进去。被 property wrapper 声明的属性，实际上在存储时的类型是 property wrapper 这个“盒子”的类型，只不过编译器施了一些魔法，让它对外暴露的类型依然是被包装的原来的类型。
> 
> 已经有很多关于 property wrapper 使用的详细解释了：[官方文档](https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID617) 或者 [NSHipster](https://nshipster.com/propertywrapper/) 上都有很优秀的阅读资料。

### 首次尝试

对 `Bool` 或者 `Video.State` 来说，设置 Default property wrapper 最理想的情况，是类似下面这样的声明方式：

```swift
@Default(value: true)
var commentEnabled: Bool

@Default(value: .unknown)
var state: State
```

这需要 `Default` 这个 property wrapper 具有这样的声明：

```swift
@propertyWrapper
struct Default<T: Decodable> {
    let value: T

    var wrappedValue: T {
        get { fatalError("未实现") }
    }
}
```

`wrappedValue` 的 getter 我们还没想好要怎么写，所以先 `fatalError` 留空。为了能让 `Default` 被直接解码，让它满足 `Decodable`：

```swift
extension Default: Decodable {
}
```

很“幸运”，因为泛型类型 `T` 也满足了 `Decodable`，所以我们不需要任何实现就可以让 `Default` 满足 `Decodable` 了。但这真的是我们想要的东西吗？

实际上，`Default` property wrapper 修饰的变量的类型，就是一个具体的 `Default` 类型：

```swift
@Default(value: true) var commentEnabled: Bool
```

`commentEnabled` 真正的类型并不是 `Bool`，而是 `Default<Bool>`。而 `Default<Bool>` 中只有 `let value: Bool` 这一个存储属性。所以它所规定的默认解码方式是寻找 `"value"` 这个 key 对应的布尔值。也就是说，在这个情况下，我们所期望的 JSON 形式其实是：

```swift
{
  "id": 12345,
  "title": "My First Video",
  "commentEnabled": {
    "value": true
  }
}
```

很显然，这不是我们想要的东西。我们需要从一个 `singleValueContainer` 中去解码单个值，而不是将它作为 object 的一部分。所以需要实现自定义的用来解码的 `init`：

```swift
// 错误代码
extension Default: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        let v = (try? container.decode(T.self)) ?? value
        // 在 init 方法中，value 还不可用，怎么办??
        
        self.wrappedValue = v
        // 如何把解码后的值交给 wrappedValue??
    }
}
```

在这种情况下，产生了矛盾：我们不能用 `Default` 的 `init(value:)` 来为 property wrapper 指定一个默认值。这么做将导致我们无法从 decoder 中利用这个默认值进行解码。

此路不通，需要另寻他法：我们需要一种不涉及具体的值，而是通过类型系统来传递值的方式。

### 使用类型约束传值

SwiftUI 中有很多使用类型来传递值的例子，在我的[前一篇文章](https://onevcat.com/2020/10/use-options-pattern/)中，也介绍了这种方式的另外一个用例。既然不能使用实例属性，那么我们不妨通过定义和类型绑定的 static 属性来设置默认值。

首先添加一个 protocol，用来规定默认值：

```swift
protocol DefaultValue {
    associatedtype Value: Decodable
    static var defaultValue: Value { get }
}
```

然后让 `Bool` 满足这个默认值：

```swift
extension Bool: DefaultValue {
    static let defaultValue = false
}
```

在这里，`DefaultValue.Value` 的类型会根据 `defaultValue` 的类型被自动推断为 `Bool`。

接下来，重新定义 `Default` property wrapper，以及用于解码的初始化方法：

```swift
@propertyWrapper
struct Default<T: DefaultValue> {
    var wrappedValue: T.Value
}

extension Default: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
    }
}
```

这样一来，我们就可以用这个新的 `Default` 修饰 `commentEnabled`，并对应解码失败的情况了：

```swift
struct Video: Decodable {
    let id: Int
    let title: String

    @Default<Bool> var commentEnabled: Bool
}

// {"id": 12345, "title": "My First Video", "commentEnabled": 123}
// Video(
//   id: 12345,
//   title: "My First Video", 
//   _commentEnabled: Default<Swift.Bool>(wrappedValue: false)
// )
```

虽然我们解码得到的是一个 `Default<Bool>` 的值，但是在使用时，property wrapper 是完全透明的。

```swift
if video.commentEnabled {
    // 在这里显示 comment UI
}
```

> 可能你已经注意到了，在这样的 `Video` 类型中，我们所使用的 `commentEnabled` 只是一个 `Bool` 类型的计算属性。在背后，编译器为我们生成了 `_commentEnabled` 这个存储属性。也就是说，如果我们手动为 `Video` 加一个 `_commentEnabled` 的话，会导致编译错误。
> 
> 虽然很多其他语言有这样的习惯，但在 Swift 中，并不建议使用下杠 `_` 作为变量的首字母。这可以帮助我们避免与编译器自动生成的代码产生冲突。

我们已经可以解码 `"commentEnabled": 123` 这类的意外输入了，但是现在，当 JSON 中 `"commentEnabled"` key 缺失时，解码依然会发生错误。这是因为我们所使用的解码器默认生成的代码是要求 key 存在的。想要改变这一行为，我们可以为 container 重写对于 `Default` 类型解码的实现：

```swift
extension KeyedDecodingContainer {
    func decode<T>(
        _ type: Default<T>.Type,
        forKey key: Key
    ) throws -> Default<T> where T: DefaultValue {
        try decodeIfPresent(type, forKey: key) ?? Default(wrappedValue: T.defaultValue)
    }
}
```

在键值编码的 container 中遇到要解码为 `Default` 的情况时，如果 key 不存在，则返回 `Default(wrappedValue: T.defaultValue)` 这个默认值。

有了这个，对于 JSON 中 `commentEnabled` 缺失的情况，也可以正确解码了：

```js
{"id": 12345, "title": "My First Video"}

// Video(id: 12345, title: "My First Video", commentEnabled: false)
```

相比对于每个类型编写单独的默认值解码代码，这套方式具有很好的扩展性。比如，如果想要为 `Video.State` 也添加默认行为，只需要让它满足 `DefaultValue` 即可：

```swift
extension Video.State: DefaultValue {
    static let defaultValue = Video.State.unknown
}

struct Video: Decodable {
    // ...
    
    @Default<State> var state: State
}

// {"id": 12345, "title": "My First Video", "state": "reserved"}
// Video(
//   id: 12345, 
//   title: "My First Video", 
//   _commentEnabled: Default<Swift.Bool>(wrappedValue: false),
//   _state: Default<Video.State>(wrappedValue: Video.State.unknown)
// )
```

### 整理 Default 类型

上面的方法还存在一个问题：像 `Default<Bool>` 这样的修饰，只能将默认值解码到 `false`。但有时候针对不同情况，我们需要设置不同的默认值。

`DefaultValue` 协议其实并没有对类型作出太多规定：只要所提供的默认值 `defaultValue` 满足 `Decodable` 协议就行。因此，我们可以让别的类型，甚至是新创建的类型，满足 `DefaultValue`：

```swift
extension Bool {
    enum False: DefaultValue {
        static let defaultValue = false
    }
    enum True: DefaultValue {
        static let defaultValue = true
    }
}
```

这样，我们就可以用这样的类型来定义不同的默认解码值了：

```swift
@Default<Bool.False> var commentEnabled: Bool
@Default<Bool.True> var publicVideo: Bool
```

或者为了可读性，更进一步，使用 typealias 给它们一些更好的名字：

```swift
extension Default {
    typealias True = Default<Bool.True>
    typealias False = Default<Bool.False>
}

@Default.False var commentEnabled: Bool
@Default.True var publicVideo: Bool
```

针对 `Video.State`，也可以做同样的整理，就留作给各位读者的练习啦！本文完整的示例代码可以在[这里](https://gist.github.com/onevcat/0f055ece50bd0c07e882890129dfcfb8)找到。

## 关于 API 设计的一点补充说明

虽然本文着重于 Codable 的小技巧，而非整体的 API 设计，但在例子中我们使用了 `Video.State` 这个 enum 来表示视频的状态，这其实是不太妥当的。

处理类似这种状态时，很多 server 会返回特定的字符串，比如 `"streaming"`、`"archived"`。看起来这很像一个“状态枚举”的行为，而且 Swift 中的 enum 实在是很好用，所以大家可能会偏向于直接用 enum 来表征。但如果客户端和服务器之间没有协定未来的情况的话，十分有可能出现像例子中 `"reserved"` 这样的新值追加，进而导致问题

相比于 enum，其实这里用一个带有 raw value 的 struct 来表示会更好：

```swift
struct Video: Decodable {
    struct State: RawRepresentable, Decodable {
        static let streaming = State(rawValue: "streaming")
        static let archived = State(rawValue: "archived")

        let rawValue: String
    }
    
    // ...
    
    let state: State
}

// {"id": 12345, "title": "My First Video", "state": "archived"}
// Video(
//   id: 12345, 
//   title: "My First Video",
//   state: Video.State(rawValue: "archived"))

print(value.state == .archived)  // true
print(value.state == .streaming) // false
```

这样一来，就算今后为 `state` 添加了新的字符串，现有的实现也不会被破坏。相比起原来的 enum `Video.State`，这个设计更加稳定。

和它很类似的，而且经常被用错的例子还有 HTTP method。不少地方把它设计成了类似这样的枚举：

```swift
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
```

确实，这几个 method 几乎能覆盖所有 (“增删查改”) 的情况，但是 HTTP 标准中还定义了[很多其他 method](https://tools.ietf.org/html/rfc2616#page-36)，比如 `HEAD` 或者 `OPTIONS` 也不算鲜见。而且只要服务端和客户端协商好，method 甚至是[可以随意扩展](https://tools.ietf.org/html/rfc2616#section-9)的。在这种情况下，其实 enum 是不太理想的。类似上面的例子，使用 `RawRepresentable` 的 struct，则可以提供更好的扩展性。