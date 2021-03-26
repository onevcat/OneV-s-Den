---
layout: post
title: "SwiftUI 中的 Text 插值和本地化 (下)"
date: 2021-03-26 12:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, swiftui]
typora-root-url: ..
---

在[上篇中][previous]，我们已经看到为什么 `Text`，或者更准确地说，`LocalizedStringKey`，可以接受 `Image` 和 `Date`，而不能接受 `Bool` 或者自定义的 `Person` 类型了。在这下篇中，让我们具体看看有哪些方法能让 `Text` 支持其他类型。

## 为 LocalizedStringKey 自定义插值

如果我们只是想让 `Text` 可以直接接受 `true` 或者 `false`，我们可以简单地为加上 `appendInterpolation` 的 `Bool` 重载。

```swift
extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ value: Bool) {
        appendLiteral(value.description)
    }
}
```

这样的话，我们就能避免编译错误了：

```swift
Text("3 == 3 is \(true)")
```

对于 `Person`，我们可以同样地添加 `appendInterpolation`，来直接为 `LocalizedStringKey` 增加 `Person` 版本的插值方法：

```swift
extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ person: Person, isFriend: Bool) {
        appendLiteral(person.title(isFriend: isFriend))
    }
}
```

上面的代码为 **LocalizedStringKey.StringInterpolation** 添加了 **Bool** 和 **Person** 的支持，但是这样的做法其实破坏了本地化的支持。这可能并不是你想要的效果，甚至造成预料之外的行为。在完全理解前，请谨慎使用。在本文稍后关于本地化的部分，会对这个话题进行更多讨论。
{: .alert .alert-warning}

## LocalizedStringKey 的真面目

### 通过 key 查找本地化值

我们花了大量篇幅，一直都在 `LocalizedStringKey` 和它的插值里转悠。回头想一想，我们似乎还完全没有关注过 `LocalizedStringKey` 本身到底是什么。正如其名，`LocalizedStringKey` 是 SwiftUI 用来在 Localization.strings 中查找 key 的类型。试着打印一下最简单的 `LocalizedStringKey` 值：

```swift
let key1: LocalizedStringKey = "Hello World"
print(key1)
// LocalizedStringKey(
//     key: "Hello World", 
//     hasFormatting: false,
//     arguments: []
// )
```

它会查找 "Hello World" key 对应的字符串。比如在本地化字符串文件中有这样的定义：

```
// Localization.strings
"Hello World"="你好，世界";
```

那是使用时，SwiftUI 将根据 `LocalizedStringKey.key` 的值选取结果：

```swift
Text("Hello World")
Text("Hello World")
    .environment(\.locale, Locale(identifier: "zh-Hans"))
```

![](/assets/images/2021/swiftui-text-4.png)

### 插值 LocalizedStringKey 的 key

那么有意思的部分来了，下面这个 `LocalizedStringKey` 的 key 会是什么呢？

```swift
let name = "onevcat"
let key2: LocalizedStringKey = "I am \(name)"
```

是 `"I am onevcat"` 吗？如果是的话，那这个字符串要如何本地化？如果不是的话，那 key 会是什么？

打印一下看看就知道了：

```swift
print(key2)

// LocalizedStringKey(
//     key: "I am %@", 
//     hasFormatting: true, 
//     arguments: [
//         SwiftUI.LocalizedStringKey.FormatArgument(
//             ...storage: Storage.value("onevcat", nil)
//         )
//     ]
// )
```

key 并不是固定的 "I am onevcat"，而是一个 String formatter："I am %@"。熟悉 [String format](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) 的读者肯定对此不会陌生：`name` 被作为变量，会被传递到 String format 中，并替换掉 `%@` 这个表示对象的占位符。所以，在本地化这个字符串的时候，我们需要指定的 key 是 "I am %@"。当然，这个 `LocalizedStringKey` 也可以对应其他任意的输入：

```swift
// Localization.strings
"I am %@"="我是%@";

// ContentView.swift
Text("I am \("onevcat")")
// 我是onevcat

Text("I am \("张三")")
// 我是张三
```

对于 `Image` 插值来说，情况很相似：`Image` 插值的部分会被转换为 `%@`，以满足本地化 key 的需求：

```swift
let key3: LocalizedStringKey = "Hello \(Image(systemName: "globe"))"

print(key3)
// LocalizedStringKey(
//     key: "Hello %@", 
//     ...
// )

// Localization.strings
// "Hello %@"="你好，%@";

Text("Hello \(Image(systemName: "globe"))")
Text("Hello \(Image(systemName: "globe"))")
    .environment(\.locale, Locale(identifier: "zh-Hans"))
```

![](/assets/images/2021/swiftui-text-5.png)

值得注意的一点是，`Image` 的插值对应的格式化符号是 `%@`，这和 `String` 的插值或者其他一切对象插值所对应的符号是一致的。也就是说，下面的两种插值方式所找到的本地化字符串是相同的：

```swift
Text("Hello \("onevcat")")
    .environment(\.locale, Locale(identifier: "zh-Hans"))
Text("Hello \(Image(systemName: "globe"))")
    .environment(\.locale, Locale(identifier: "zh-Hans"))
```

![](/assets/images/2021/swiftui-text-6.png)

### 其他类型的插值格式化

可能你已经猜到了，除了 `%@` 外，`LocalizedStringKey` 还支持其他类型的格式化，比如在插值 `Int` 时，会把 key 中的参数转换为 `%lld`；对 `Double` 则转换为 `%lf` 等：

```swift
let key4: LocalizedStringKey = "Hello \(1))"
// LocalizedStringKey(key: "Hello %lld)

let key5: LocalizedStringKey = "Hello \(1.0))"
// LocalizedStringKey(key: "Hello %lf)
```

使用 `Hello %lld` 或者 `Hello %lf`，是不能在本地化文件中匹配到之前的 `Hello %@` 的。

## 更合理的 appendInterpolation 实现

### 避免 appendLiteral

现在让我们回到 `Bool` 和 `Person` 的插值这个话题。在本篇一开始，我们添加了两个插值方法，来让 `LocalizedStringKey` 接受 `Bool` 和 `Person` 的插值：

```swift
mutating func appendInterpolation(_ value: Bool) {
    appendLiteral(value.description)
}

mutating func appendInterpolation(_ person: Person, isFriend: Bool) {
    appendLiteral(person.title(isFriend: isFriend))
}
```

在两个方法中，我们都使用了 `appendLiteral` 来将 `String` 直接添加到 key 里，这样做我们得到的会是一个完整的，不含参数的 `LocalizedStringKey`，在大多数情况下，这不会是我们想要的结果：

```swift
let key6: LocalizedStringKey = "3 == 3 is \(true)"
// LocalizedStringKey(key: "3 == 3 is true", ...)

let person = Person(name: "Geralt", place: "Rivia", nickName: "White Wolf")
let key7: LocalizedStringKey = "Hi, \(person, isFriend: false)"
// LocalizedStringKey(key: "Hi, Geralt of Rivia", ...)
```

在实现新的 `appendInterpolation` 时，尊重插入的参数，将实际的插入动作转发给已有的 `appendInterpolation` 实现，让 `LocalizedStringKey` 类型去处理 key 的合成及格式化字符，应该是更合理和具有一般性的做法：

```swift
mutating func appendInterpolation(_ value: Bool) {
    appendInterpolation(value.description)
}

mutating func appendInterpolation(_ person: Person, isFriend: Bool) {
    appendInterpolation(person.title(isFriend: isFriend))
}

let key6: LocalizedStringKey = "3 == 3 is \(true)"
// LocalizedStringKey(key: "3 == 3 is %@", ...)

let key7: LocalizedStringKey = "Hi, \(person, isFriend: false)"
// LocalizedStringKey(key: "Hi, %@", ...)
```

### 为 Text 添加样式

结合利用 `LocalizedStringKey` 参数插值和已有的 `appendInterpolation`，可以写出一些简便方法。比如可以添加一组字符串格式化的方法，来让 `Text` 的样式设置更简单一些：

```swift
extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(bold value: LocalizedStringKey){
        appendInterpolation(Text(value).bold())
    }

    mutating func appendInterpolation(underline value: LocalizedStringKey){
        appendInterpolation(Text(value).underline())
    }

    mutating func appendInterpolation(italic value: LocalizedStringKey) {
        appendInterpolation(Text(value).italic())
    }
    
    mutating func appendInterpolation(_ value: LocalizedStringKey, color: Color?) {
        appendInterpolation(Text(value).foregroundColor(color))
    }
}
```

```swift
Text("A \(bold: "wonderful") serenity \(italic: "has taken") \("possession", color: .red) of my \(underline: "entire soul").")
```

可以得到如下的效果：

![](/assets/images/2021/swiftui-text-7.png)

> 对应的 key 是 "A %@ serenity %@ %@ of my %@."。插值的地方都会被认为是需要参数的占位符。在一些情况下可能这不是你想要的结果，不过 attributed string 的本地化在 UIKit 中也是很恼人的存在。相对于 UIKit 来说，SwiftUI 在这方面的进步还是显而易见的。

## 关于 `_FormatSpecifiable`

最后我们来看看关于 `_FormatSpecifiable` 的问题。可能你已经注意到了，在内建的 `LocalizedStringKey.StringInterpolation` 有两个方法涉及到了 `_FormatSpecifiable`：

```swift
mutating func appendInterpolation<T>(_ value: T) where T : _FormatSpecifiable
mutating func appendInterpolation<T>(_ value: T, specifier: String) where T : _FormatSpecifiable
```

### 指定占位格式

Swift 中的部分基本类型，是满足 `_FormatSpecifiable` 这个私有协议的。**该协议帮助 `LocalizedStringKey` 在拼接 key 时选取合适的占位符表示**，比如对 `Int` 选取 `%lld`，对 `Double` 选取 `%lf` 等。当我们使用 `Int` 或 `Double` 做插值时，上面的重载方法将被使用：

```swift
Text("1.5 + 1.5 = \(1.5 + 1.5)")

// let key: LocalizedStringKey = "1.5 + 1.5 = \(1.5 + 1.5)"
// print(key)
// 1.5 + 1.5 = %lf
```

上面的 `Text` 等号右边将按照 `%lf` 渲染：

![](/assets/images/2021/swiftui-text-8.png)

如果只想要保留到小数点后一位，可以直接用带有 `specifier` 参数的版本。在生成 key 时，会用传入的 `specifier` 取代原本应该使用的格式：

```swift
Text("1.5 + 1.5 = \(1.5 + 1.5, specifier: "%.1lf")")

// key: 1.5 + 1.5 = %.1lf
```

![](/assets/images/2021/swiftui-text-9.png)

### 为自定义类型实现 `_FormatSpecifiable`

虽然是私有协议，但是 `_FormatSpecifiable` 相对还是比较简单的：

```swift
protocol _FormatSpecifiable: Equatable {
    associatedtype _Arg
    var _arg: _Arg { get }
    var _specifier: String { get }
}
```

让 `_arg` 返回需要被插值的实际值，让 `_specifier` 返回占位符的格式，就可以了。比如可以猜测 `Int: _FormatSpecifiable` 的实现是：

```swift
extension Int: _FormatSpecifiable {
    var _arg: Int { self }
    var _specifier: String { "%lld" }
}
```

对于我们在例子中多次用到的 `Person`，也可以用类似地手法让它满足 `_FormatSpecifiable`：

```swift
extension Person: _FormatSpecifiable {
    var _arg: String { "\(name) of \(place)" }
    var _specifier: String { "%@" }
}
```

这样一来，即使我们不去为 `LocalizedStringKey` 添加 `Person` 插值的方法，编译器也会为我们选择 `_FormatSpecifiable` 的插值方式，将 `Person` 的描述添加到最终的 key 中了。

## 总结

在[上篇][previous]的基础上，在本文中：

- 我们尝试扩展了 `LocalizedStringKey` 插值的方法，让它支持了 `Bool` 和 `Person`。
- `LocalizedStringKey` 插值的主要任务是自动生成合适的，带有参数的本地化 key。
- 在扩展 `LocalizedStringKey` 插值时，应该是尽可能使用 `appendInterpolation`，避免参数“被吞”。
- 插值的格式是由 `_FormatSpecifiable` 确定的。我们也可以通过让自定义类型实现这个协议的方式，来进行插值。

至此，为什么 `Text` 中可以插值 `Image`，以及它背后发生的所有事情，我们应该都弄清楚了。

[previous]: https://onevcat.com/2021/03/swiftui-text-1/