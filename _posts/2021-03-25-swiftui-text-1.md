---
layout: post
title: "SwiftUI 中的 Text 插值和本地化 (上)"
date: 2021-03-25 19:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, swiftui]
typora-root-url: ..
---

## Text 中的插值

`Text` 是 SwiftUI 中最简单和最常见的 View 了，最基本的用法，我们可以直接把一个字符串字面量传入，来创建一个 `Text`：

```swift
Text("Hello World")
```

![](/assets/images/2021/swiftui-text-1.png)

在 iOS 14 (SwiftUI 2.0) 中，Apple 对 `Text` 插值进行了很多强化。除了简单的文本之外，我们还可以向 `Text` 中直接插入 `Image`：

```swift
Text("Hello \(Image(systemName: "globe"))")
```

![](/assets/images/2021/swiftui-text-2.png)

这是一个非常强大的特性，极大简化了图文混排的代码。除了普通的字符串和 `Image` 以外，`Text` 中的字符串插值还可以接受其他一些“奇奇怪怪”的类型，部分类型甚至还接受传入特性的 formatter，这给我们带来不少便利：

```swift
Text("Date: \(Date(), style: .date)")
Text("Time: \(Date(), style: .time)")
Text("Metting: \(DateInterval(start: Date(), end: Date(timeIntervalSinceNow: 3600)))")

let fomatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    return f
}()
Text("Pay: \(123 as NSNumber, formatter: fomatter)")
```

![](/assets/images/2021/swiftui-text-3.png)

但是同时，一些平时可能很常见的字符串插值用法，在 `Text` 中并不支持，最典型的，我们可能遇到下面两种关于 `appendInterpolation` 的错误：

```swift
Text("3 == 3 is \(true)")
// 编译错误：
// No exact matches in call to instance method 'appendInterpolation'

struct Person {
    let name: String
    let place: String
}
Text("Hi, \(Person(name: "Geralt", place: "Rivia"))")
// 编译错误：
// Instance method 'appendInterpolation' requires that 'Person' conform to '_FormatSpecifiable'
```

一开始遇到这些错误很可能会有点懵，`appendInterpolation` 是什么，`_FormatSpecifiable` 又是什么？要怎么才能让这些类型和 `Text` 一同工作？

我打算花两篇文章对这个话题和相关的 API 设计进行一些探索。

在本文中，我们会先来看看到底为什么 `Text` 可以接受 `Image` 或者 `Date` 作为插值，而不能接受 `Bool` 或 `Person` 这样的类型，这涉及到 Swift 5 中引入的自定义字符串插值的特性。在[稍后的下篇][next]里，我们会探索这个话题背后引出的更深层次的内容，来看看 SwiftUI 中的本地化到底是如何工作的。我们也会讨论应该如何解决对应的问题，并利用这些的特性写出更正确和漂亮的 SwiftUI 代码。

## 幕后英雄：LocalizedStringKey

SwiftUI 把多语言本地化的支持放到了首位，在直接使用字符串字面量去初始化一个 `Text` 的时候，所调用到的方法其实是 `init(_:tableName:bundle:comment:)`：

```swift
extension Text {
    init(
        _ key: LocalizedStringKey, 
        tableName: String? = nil, 
        bundle: Bundle? = nil, 
        comment: StaticString? = nil
    )
}
```

`Text` 使用输入的 `key` 去 bundle 中寻找本地化的字符串文件，并且把满足设备语言的结果渲染出来。

因为 `LocalizedStringKey` 满足 `ExpressibleByStringInterpolation` (以及其父协议 `ExpressibleByStringLiteral`)，它可以直接由字符串的字面量转换而来。也就是说，在上面例子中，不论被插值的是 `Image` 还是 `Date`，最后得到的，作为 `Text` 初始化方法的输入的，其实都是 `LocalizedStringKey` 实例。

> 对于字符串字面量来说，`Text` 会使用上面这个 `LocalizedStringKey` 重载。如果先把字符串存储在一个 `String` 里，比如 `let s = "hello"`，那么 `Text(s)` 将会选取另一个，接受 `StringProtocol` 的初始化方法：`init<S>(_ content: S) where S : StringProtocol`。

我们可以证明一下这一点：当按照普通字符串插值的方法，尝试简单地打印上面的插值字符串时，得到的结果如下：

```swift
print("Hello \(Image(systemName: "globe"))")
// Hello Image(provider: SwiftUI.ImageProviderBox<SwiftUI.Image.(unknown context at $1b472d684).NamedImageProvider>)

print("Date: \(Date(), style: .date)")
// 编译错误：
// Cannot infer contextual base in reference to member 'date'
```

`Image` 插值直接使用了 struct 的标准描述，给回了一个普通字符串；而 `Date` 的插值则直接不接受额外参数，给出了编译错误。无论哪个，都不可能作为简单字符串传给 `Text` 并得到最后的渲染结果。

实际上，在 `Text` 初始化方法里，这类插值使用的是 `LocalizedStringKey` 的相关插值方法。这也是在 Swift 5 中新加入的特性，它可以让我们进行对任意类型的输入进行插值 (比如 `Image`)，甚至在插值时设定一些参数 (比如 `Date` 以及它的 `.date` style 参数)。

## StringInterpolation

普通的字符串插值是 Swift 刚出现时就拥有的特性了。可以使用 `\(variable)` 的方式，将一个可以表示为 `String` 的值加到字符串字面量里：

```swift
print("3 == 3 is \(true)")
// 3 == 3 is true

let luckyNumber = 7
print("My lucky number is \(luckNumber).")
// My lucky number is 7.

let name = "onevcat"
print("I am \(name).")
// I am onevcat.
```

在 Swift 5 中，字面量插值得到了强化。我们可以通过让一个类型遵守 `ExpressibleByStringInterpolation` 来自定义插值行为。这个特性其实已经被讨论过不少了，但是为了让你更快熟悉和回忆起来，我们还是再来看看它的基本用法。

Swift 标准库中的 `String` 是满足该协议的，想要扩展 `String` 所支持的插值的类型，我们可以扩展 `String.StringInterpolation` 类型的实现，为它添加所需要的适当类型。用上面出现过的 `Person` 作为例子。不加修改的话，`print` 会按照 Swift struct 的默认格式打印 `Person` 值：

```swift
struct Person {
    let name: String
    let place: String
}

print("Hi, \(Person(name: "Geralt", place: "Rivia"))")
// Hi, Person(name: "Geralt", place: "Rivia")
```

如果我们想要一个[更 role play 一点的名字](https://witcher.fandom.com/wiki/Geralt_of_Rivia)的话，可以考虑扩展 `String.StringInterpolation`，添加一个 `appendInterpolation(_ person: Person)` 方法，来自定义字符串字面量接收到 `Person` 时的行为：

```swift
extension String.StringInterpolation {
    mutating func appendInterpolation(_ person: Person) {
        // 调用的 `appendLiteral(_ literal: String)` 接受 `String` 参数
        appendLiteral("\(person.name) of \(person.place)")
    }
}
```

现在，`String` 中 `Person` 插值的情况会有所变化：

```swift
print("Hi, \(Person(name: "Geralt", place: "Rivia"))")
// Hi, Geralt of Rivia
```

对于多个参数的情况，我们可以在 `String.StringInterpolation` 添加新的参数，并在插值时用类似“方法调用”写法，将参数传递进去：

```swift
struct Person {
    let name: String
    let place: String
    
    // 好朋友的话一般叫昵称就行了
    var nickName: String?
}

extension Person {
    var formalTitle: String { "\(name) of \(place)" }
    
    // 根据朋友关系，返回称呼
    func title(isFriend: Bool) -> String {
        isFriend ? (nickName ?? formalTitle) : formalTitle
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ person: Person, isFriend: Bool) {
        appendLiteral(person.title(isFriend: isFriend))
    }
}
```

调用时，加上 `isFriend`：

```swift
let person = Person(
    name: "Geralt", place: "Rivia", nickName: "White Wolf"
)
print("Hi, \(person, isFriend: true)")
// Hi, White Wolf
```

## LocalizedStringKey 的字符串插值

### Image 和 Date

了解了 `StringInterpolation` 后，我们可以来看看在 `Text` 语境下的 `LocalizedStringKey` 是如何处理插值的了。和普通的 `String` 类似，`LocalizedStringKey` 也遵守了 `ExpressibleByStringInterpolation`，而且 SwiftUI 中已经为它的 `StringInterpolation` 提供了一些常用的扩展实现。在当前 (iOS 14) 的 SwiftUI 实现中，它们包含了：

```swift
extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ string: String)
    mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : ReferenceConvertible
    mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : NSObject
    mutating func appendInterpolation<T>(_ value: T) where T : _FormatSpecifiable
    mutating func appendInterpolation<T>(_ value: T, specifier: String) where T : _FormatSpecifiable
    mutating func appendInterpolation(_ text: Text)
    mutating func appendInterpolation(_ image: Image)
    mutating func appendInterpolation(_ date: Date, style: Text.DateStyle)
    mutating func appendInterpolation(_ dates: ClosedRange<Date>)
    mutating func appendInterpolation(_ interval: DateInterval)
}
```

在本文第一部分的例子中，所涉及到的 `Image` 和 `Date` style 的插值，使用的正是上面所声明了的方法。在接受到正确的参数类型后，通过创建合适的 `Text` 进而得到最终的 `LocalizedStringKey`。我们很容易可以写出例子中的两个 `appendInterpolation` 的具体实现：

```swift
mutating func appendInterpolation(_ image: Image) {
    appendInterpolation(Text(image))
}

mutating func appendInterpolation(_ date: Date, style: Text.DateStyle) {
    appendInterpolation(Text(date, style: style))
}
```

### Bool 和 Person

那么现在，我们就很容易理解为什么在最上面的例子中，`Bool` 和 `Person` 不能直接用在 `Text` 里的原因了。

对于 `Bool`：

```swift
Text("3 == 3 is \(true)")
// 编译错误：
// No exact matches in call to instance method 'appendInterpolation'
```

`LocalizedStringKey` 没有针对 `Bool` 扩展 `appendInterpolation` 方法，于是没有办法使用插值的方式生成 `LocalizedStringKey` 实例。

对于 `Person`，最初的错误相对难以理解：

```swift
Text("Hi, \(Person(name: "Geralt", place: "Rivia"))")
// 编译错误：
// Instance method 'appendInterpolation' requires that 'Person' conform to '_FormatSpecifiable'
```

对照 SwiftUI 中已有的 `appendInterpolation` 实现，不难发现，其实它使用的是 ：

```swift
mutating func appendInterpolation<T>(_ value: T) where T : _FormatSpecifiable
```

这个最接近的重载方法，不过由于 `Person` 并没有实现 `_FormatSpecifiable` 这个私有协议，所以实质上还是找不到合适的插值方法。想要修正这个错误，我们可以选择为 `Person` 添加 `appendInterpolation`，或者是让它满足 `_FormatSpecifiable` 这个私有协议。不过两种方式其实本质上是**完全不同**的，而且根据实际的使用场景不同，有时候可能会带来意想不到的结果。我们会在这个[系列博文的下篇][next]中对这个话题做详细介绍。

## 小结

- SwiftUI 2.0 中可以向 `Text` 中插值 `Image` 和 `Date` 这样的非 `String` 值，这让图文混排或者格式化文字非常方便。
- 灵活的插值得益于 Swift 5.0 引入的 `ExpressibleByStringInterpolation`。你可以为 `String` 自定义插值方式，甚至可以为自定义的任意类型设定字符串插值。
- 用字符串字面量初始化 `Text` 的时候，参数的类型是 `LocalizedStringKey`。
- `LocalizedStringKey` 实现了接受 `Image` 或者 `Date` 的插值方法，所以我们可以在创建 `Text` 时直接插入 `Image` 或者格式化的 `Date`。
- `LocalizedStringKey` 不接受 `Bool` 或者自定义类型的插值参数。我们可以添加相关方法，不过这会带来副作用。


[next]: #