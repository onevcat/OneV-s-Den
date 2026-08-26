---
layout: post
title: "Swift 正则速查手册"
date: 2022-11-15 23:00:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, 编程语言, 编译器, 正则表达式]
typora-root-url: ..
---

<style>
    table {
        width: 100%;
    }
</style>

Swift 5.7 中引入了正则表达式的语法支持，整理一下相关的一些话题、方法和示例，以备今后自己能够速查。

## 总览

Swift 正则由标准库中的 `Regex` 类型驱动，需要 iOS 16.0 或 macOS 13.0，早期的 deploy 版本无法使用。

构建一个正则表达式的方式，分为传统的正则字面量构建，以及通过 Regex Builder DSL 的更加易读的方式。后者可以内嵌使用前者，以及其他一些已有的 parser，在可读性和功能上要强力很多。实践中，推荐**结合使用字面量和 Builder API 在简洁和易读之间获取平衡**。

## 常见字面量

和其他各语言正则表达式的字面量没有显著不同。

直接将字面量包裹在 `/.../` 中使用，Swift 将把类似的声明转换为 `Regex` 类型的实例：

```swift
let bitcoinAddress_v1 = /([13][a-km-zA-HJ-NP-Z0-9]{26,33})/
```

一些常用的字面量表达以及示例。更多非常用的例子，可以参考[这里的 Cheat Sheet](https://github.com/niklongstone/regular-expression-cheat-sheet)。

### 字符集

| 表达式    | 说明       | 示例                              |
| --------- | ---------- | --------------------------------- |
| `[aeiou]` | 匹配指定字符集 | On**e**V's␣D**e**n␣**i**s␣**a**␣bl**o**g. |
| `[^aeiou]` | 排除字符集 | **On**e**V's␣D**e**n␣**i**s␣**a**␣bl**o**g.** |
| `[A-Z]` |      匹配字符范围       | **O**ne**V**'s␣**D**en␣is␣a␣blog. |
|   `.`        |   除换行符以外的任意字符。等效于 `[^\n\r]`         | **OneV's␣Den␣is␣a␣blog.** |
| `\s` | 匹配空格字符 (包括 tab 和换行) | OneV's**␣**Den**␣**is**␣**a**␣**blog. |
| `\S` | 匹配非空格字符 | **OneV's**␣**Den**␣**is**␣**a**␣**blog.** |
| `[\s\S]` | 匹配空格和非空格，也即任意字符。等效于 `[^]` | **OneV's␣Den␣is␣a␣blog.** |
| `\w` | 匹配字母数字下划线等低位 ASCII。等效于 `[A-Za-z0-9_]` | **OneV**'**s**␣**Den**␣**is**␣**a**␣**blog**. |
| `\W` | 等效于 `[^A-Za-z0-9_]` |  |
| `\d` | 匹配数字，等效于 `[0-9]` | +(**81**)**021**-**1234**-**5678** |
| `\D` | 非数字，等效于 `[^0-9]` | **+(**81**)**021**-**1234**-**5678 |

### 数量

| 表达式     | 说明                              | 示例        | 结果                                    |
| ---------- | --------------------------------- | ----------- | --------------------------------------- |
| `+`        | 匹配一个或多个                    | `b\w+`      | b **be** **bee** **beer** **beers**     |
| `*`        | 匹配零个或多个                    | `b\w*`      | **b** **be** **bee** **beer** **beers** |
| `{2,3}`    | 匹配若干个                        | `b\w{2,3}`  | b be **bee** **beer** **beer**s         |
| `?`        | 匹配零个或一个                    | `colou?r`   | **color** **colour**                    |
| 数量 + `?` | 使前置数量进行惰性匹配 (尽可能少) | `b\w+?`     | b **be** **be**e **be**er **be**ers     |
| `|`        | 逻辑或，择一匹配                  | `b(a|e|i)d` | **bad** bud bod **bed** **bid**         |

### 锚点

| 表达式 | 说明                           | 示例   | 结果                                |
| ------ | ------------------------------ | ------ | ----------------------------------- |
| `^`    | 匹配字符串开头                 | `^\w+` | **she** sells seashells             |
| `$`    | 匹配字符串结尾                 | `\w+$` | she sells **seashells**             |
| `\b`   | 匹配 `\w` 和非 `\w` 的边缘位置 | `s\b`  | she sell**s** seashell**s**         |
| `\B`   | 匹配非边缘位置                 | `s\B`  | **s**he **s**ells **s**ea**s**hells |

### 捕获组

| 表达式           | 说明                                               | 示例                      |
| ---------------- | -------------------------------------------------- | ------------------------- |
| `(OneV)+`        | 捕获括号内的匹配，使其成组并出现在匹配结果中       | **OneV**'s Den is a blog. |
| `(?<name>OneV)+` | 命名捕获匹配，在结果中可使用名字对匹配结果进行引用 |                           |
| `(?:OneV)+`      | 成组但不进行捕获，允许使用数量但不关心和捕获结果   |                           |

### Lookahead

| 表达式     | 说明                                                      | 示例                    |
| ---------- | --------------------------------------------------------- | ----------------------- |
| `\d(?=px)` | `?=` - Positive lookahead。预先检查，符合时再进行主体匹配 | 1pt **2**px 3em **4**px |
| `\d(?!px)` | `?!` - Negative lookahead。预先检查，不符合时进行主体匹配 | **1**pt 2px **3**em 4px |

## Builder DSL

字面量表达式虽然简洁，但是对应复杂情境会难以理解，也不便于修改。使用 [`RegexBuilder` 框架](https://developer.apple.com/documentation/regexbuilder)提供的 DSL 来描述正则表达式是更具有表达性的方法。

比如，

```swift
let bitcoinAddress_v1 = /([13][a-km-zA-HJ-NP-Z0-9]{26,33})/
```

等效于：

```swift
import RegexBuilder
let bitcoinAddress_v1 = Regex {
  Capture {
    One(.anyOf("13"))
    Repeat(26...33) {
      CharacterClass(
        ("a"..."k"),
        ("m"..."z"),
        ("A"..."H"),
        ("J"..."N"),
        ("P"..."Z"),
        ("0"..."9")
      )
    }
  }
}
```

`Regex.init(_:)` 接受一个 result builder 形式的闭包，你可以往闭包中塞入多个 `RegexComponent` 来构建完整的正则表达式。注意 `Regex` 类型本身也满足 `RegexComponent` 协议，所以你也可以直接把字面量传递给 `Regex` 初始化方法。

字面量所提供的特性，在 Regex Builder 中都有对应。除此之外，Swift Regex Builder 框架还提供了更易读的强类型描述。一些常见的对应 `RegexComponent` 如下：

### 字符集

字符集相关的 `RegexComponent` 基本被定义在 [`CharacterClass`](https://developer.apple.com/documentation/regexbuilder/characterclass) 中。

| 字面量表达式 | 等效的 `RegexComponent`                                      |
| ------------ | ------------------------------------------------------------ |
| `[aeiou]`    | `.anyOf("aeiou")`。为了可读性，可以考虑加上量词 `One(.anyOf("aeiou"))` |
| `[^aeiou]`   | `CharacterClass.anyOf("aeiou").inverted`                     |
| `[A-Z]`      | `("A"..."Z")`                                                |
| `.`          | `.any`                                                       |
| `\s`         | `.whitespace`                                                |
| `\S`         | `.whitespace.inverted`                                       |
| `[\s\S]`     | `CharacterClass(.whitespace, .whitespace.inverted)`          |
| `\w`         | `.word`                                                      |
| `\W`         | `.word.inverted`                                             |
| `\d`         | `.digit`                                                     |
| `\D`         | `.digit.inverted`                                            |

### 数量

| 字面量表达式 (例)    | 等效的 `RegexComponent`        |
| -------------------- | ------------------------------ |
| `+` (`b\w+`)         | `OneOrMore(.word)`             |
| `*` (`b\w*`)         | `ZeroOrMore(.word)`            |
| `{2,3}` (`b\w{2,3}`) | `Repeat(2...3) { .word }`      |
| `?` (`colou?r`)      | `Optionally { "u" }`           |
| 数量 + `?` (`b\w+?`) | `OneOrMore(.word, .reluctant)` |
| `|` (`b(a|e|i)d`)    | `ChoiceOf { "a" ↵ "e" ↵ "i" }` |

### 锚点

| 字面量表达式 (例) | 等效的 `RegexComponent`                              |
| ----------------- | ---------------------------------------------------- |
| `^` (`^\w+`)      | `Regex { Anchor.startOfSubject ↵ OneOrMore(.word) }` |
| `$` (`\w+$`)      | `Regex { OneOrMore(.word) ↵ Anchor.endOfSubject }`   |
| `\b` (`s\b`)      | `Regex { "s" ↵ Anchor.wordBoundary }`                |
| `\B` (`s\B`)      | `Regex { "s" ↵ Anchor.wordBoundary.inverted }`       |

此外：

- 对于多行匹配模式的情况 (如带有 `m` 的 `/^abc/m`)，此时 `^` 和 `$` 等效为 `.startOfLine`，`.endOfLine` 等。
- 对于 Unicode 支持，常用的还有 `.textSegmentBoundary (\y)` 等。

### 捕获

| 字面量表达式     | 等效的 `RegexComponent`                                      |
| ---------------- | ------------------------------------------------------------ |
| `(OneV)+`        | `OneOrMore { Capture { "OneV" } }`                           |
| `(?<name>OneV)+` | `let name = Reference(Substring.self)`<br />`OneOrMore { Capture(as: name) { "OneV" } }` |
| `(?:OneV)+`      | `OneOrMore { "OneV" }`                                       |

Regex Builder 支持在 `Capture` 的过程中同时进行 mapping，把结果转换为其他形式的字符串甚至是其他类型的强类型值：

```swift
Regex {
  TryCapture(as: kind) {
    OneOrMore(.word)
  } transform: {
    Transaction.Kind($0)
  } // 得到一个强类型 `Kind` 值
}
```

如果转换可能会失败并返回 `nil`，使用 `TryCapture`：失败时跳过匹配；如果转换一定会成功，使用普通的 `Capture`。

### Lookahead

| 字面量表达式 | 等效的 `RegexComponent`                         |
| ------------ | ----------------------------------------------- |
| `\d(?=px)`   | `Regex { .digit ↵ Lookahead { "px" } }`         |
| `\d(?!px)`   | `Regex { .digit ↵ NegativeLookahead { "px" } }` |

## 常用 Parser

相对于字面量，使用 Regex Builder 的最大优势，在于可以嵌套使用已经存在的 Parser 进行匹配。凡是满足 `RegexComponent` 的值，都可以放到 `Regex` 表达式中。Foundation 中，部分 `ParseStrategy` 满足 `RegexComponent` 并提供相应方法来创建 `Regex` 中可用的 parser。iOS 16 中，默认可用 Parser 有：

| 所属 Parser 类型                           | 方法签名                                                   | 可解析示例                        |
| ------------------------------------------ | ---------------------------------------------------------- | --------------------------------- |
| `Date.ParseStrategy`                       | `date(_:locale:timeZone:calendar:)`                        | Oct 21, 2015, 10/21/2015, etc |
| `Date.ParseStrategy`                       | `date(format:locale:timeZone:calendar:twoDigitStartDate:)` | 05_04_22                        |
| `Date.ParseStrategy`                       | `dateTime(date:time:locale:timeZone:calendar:)`            | 10/17/2020, 9:54:29 PM          |
| `Date.ISO8601FormatStyle`                  | `iso8601(timeZone:...)`                                    | 2021-06-21T211015               |
| `Date.ISO8601FormatStyle`                  | `iso8601Date(timeZone:dateSeparator:)`                     | 2015-11-14                      |
| `Date.ISO8601FormatStyle`                  | `iso8601WithTimeZone(...)`                                 | 2021-06-21T21:10:15+0800        |
| `Decimal.FormatStyle.Currency`             | `localizedCurrency(code:locale:)`                          | $52,249.98 -> `Decimal`         |
| `Decimal.FormatStyle`                      | `localizedDecimal(locale:)`                                | 1.234, 1E5 -> `Decimal`         |
| `FloatingPointFormatStyle<Double>`         | `localizedDouble(locale:)`                                 | 1.234,  1E5 ->  -> `Double`     |
| `FlatingPointFormatStyle<Double>.Percent` | `localizedDoublePercentage(locale:)`                       | 15.4%, `-200%` -> `Double`      |
| `IntegerFormatStyle<Int>`                  | `localizedInteger(locale:)`                                | 199, 1.234 -> `Int`           |
| `IntegerFormatStyle<Int>.Currency`        | `localizedIntegerCurrency(code:locale:)`                   | $52,249.98 -> `Int`             |
| `IntegerFormatStyle<Int>.Percent`          | `localizedIntegerPercentage(locale:)`                      | 15.4%, -200% -> `Int`         |

> 关于 Foundation 中 `ParseStrategy` 的相关内容，可以参看肘子兄的[这篇博客](https://www.fatbobman.com/posts/newFormatter/)，以及 WWDC 21 中[相关的视频](https://developer.apple.com/videos/play/wwdc2021/10109/)。

### 自定义 Parser 和 `CustomConsumingRegexComponent`

对于自己实现的或是第三方提供的 Parser，可以通过满足 `CustomConsumingRegexComponent` 来让它进而满足 `RegexComponent` 并用在 Regex 构造中。

```swift
func consuming(
    _ input: String,
    startingAt index: String.Index,
    in bounds: Range<String.Index>
) throws -> (upperBound: String.Index, output: Self.RegexOutput)?
```

返回匹配停止时的上界，以及比配得到的结果本身即可。对于这一点，WWDC 22 的 [Swift Regex: Beyond the basics](https://developer.apple.com/videos/play/wwdc2022/110358) 给了一个非常好的例子：

```swift
import Darwin

struct CDoubleParser: CustomConsumingRegexComponent {
    typealias RegexOutput = Double

    func consuming(
        _ input: String, startingAt index: String.Index, in bounds: Range<String.Index>
    ) throws -> (upperBound: String.Index, output: Double)? {
        input[index...].withCString { startAddress in
            var endAddress: UnsafeMutablePointer<CChar>!
            let output = strtod(startAddress, &endAddress)
            guard endAddress > startAddress else { return nil }
            let parsedLength = startAddress.distance(to: endAddress)
            let upperBound = input.utf8.index(index, offsetBy: parsedLength)
            return (upperBound, output)
        }
    }
}
```

在很多情况下，我们可能会进一步地使用 [protocol 中泛型上下文静态查找](https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md)的特性，为 `RegexComponent` 添加类型成员，以便在 `Regex` 中直接使用：

```swift
extension RegexComponent where Self == CDoubleParser {
    static var cDouble: Self { CDoubleParser() }
}
```

Foundation 中的各种 parser 基本都遵循了类似的实现方式。

## 匹配方式

### 常见的匹配方法

```swift
// 匹配所有可能项，并将全部结果返回
input.matches(of: regex) // [Regex<Output>.Match]

// 匹配时返回第一个结果
input.firstMatch(of: regex) // Regex<Output>.Match?

// 整个字符串能完整匹配时才返回结果
input.wholeMatch(of: regex) // Regex<Output>.Match?

// 字符串的开始部分匹配的话返回结果
// 如果只需要判断是否匹配，使用 `start(with:)`
input.prefixMatch(of: regex) // Regex<Output>.Match?
```

匹配后得到的结果中，`.0` 返回匹配到的整个字符串，从 `.1` 开始是捕获的组：

```swift
let regex = /Welcome to (.+?), a person blog from (\d+)/
let text = "Welcome to OneV's Den, a person blog from 2011"

if let result = text.wholeMatch(of: regex) {
    print("Title: \(result.1)") // OneV's Den
    print("Year: \(result.2)")  // 2011
}
```

`Regex.Match` 实现了 dynamic lookup，可以使用 `Reference` 直接获取命名的捕获：

```swift
let regex = /Welcome to (?<name>.+?), a person blog from (?<year>\d+)/
let text = "Welcome to OneV's Den, a person blog from 2011"

if let result = text.wholeMatch(of: regex) {
    print("Title: \(result.name)") // OneV's Den
    print("Year: \(result.year)")  // 2011
}
```

### 基于 Regex 的字符串算法/操作

- `input.ranges(of: regex)`
- `input.replacing(regex, with: "string")`
- `input.trimmingPrefix(regex)`

等..原来在 `Collection` 中可以针对字符串的操作，可以找到对应的 `Regex` 版本。

### Regex 变换/Flags

在创建 `Regex` 后，可以使用其上的实例方法来对 `Regex` 进行部分修改。最常用的大概有：

- `ignoresCase(_:)` - 匹配是否忽略大小写。等效于 `/[aeiou]/i` 中的 `i` flag。
- `anchorsMatchLineEndings(_:)` - `^` 和 `$` 是否也匹配每行。等效于 `/^[aeiou]$/m` 中的 `m` flag。
- `dotMatchesNewlines(_:)` - 字面量 `.` 是否应该匹配包括换行符在内的任意字符。等效于 `s` flag。

## 小结

Swift Regex 是符合 Swift 美学的正则写法，可以在标准库层面替代掉 Apple 平台上原有的被诟病已久的 `NSRegularExpression`。随着时代车轮的前行，`NSRegularExpression` 肯定将被逐渐扫进垃圾堆。

当前 Swift Regex 已经相对很完善了，它的优点非常明确：

- 使用 DSL 的方式构建易于理解和维护的正则
- 可以与 Parser 结合使用，提供高质量的匹配

当然，在本文写作时也还存在一些不足。

- 文档不足，实际用例和社区支持也相对匮乏
- 需求的系统版本较高，近几年内可能难以完全迁移
- 不论字面量还是 DSL，暂时还不支持 `if` 等条件控制
- Foundation 的 Parser 数量和种类不多

不过这些毒点相对都是容易改善的，个人还是十分看好 Swift Regex 的前景。特别是用来做一些简单的文本处理和本地工具的话，会非常方便。

和 Swift `String` 一样，`Regex` 从设计初期就考虑了 Unicode 安全。不过本文暂时没有涉及 Unicode 的处理，日后如果用到再继续补充。

### 参考

#### WWDC 22

- [Meet Swift Regex](https://developer.apple.com/videos/play/wwdc2022/110357/)
- [Swift Regex: Beyond the basics](https://developer.apple.com/videos/play/wwdc2022/110358/)

#### Swift Evolution

- [SE-0350: Regex type and overview](https://github.com/apple/swift-evolution/blob/main/proposals/0350-regex-type-overview.md)
- [SE-0351: Regex builder DSL](https://github.com/apple/swift-evolution/blob/main/proposals/0351-regex-builder.md)
- [SE-0354: Regex literals](https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md)
- [SE-0355: Regex syntax](https://github.com/apple/swift-evolution/blob/main/proposals/0355-regex-syntax-run-time-construction.md)
- [SE-0357: Regex-powered algorithms](https://github.com/apple/swift-evolution/blob/main/proposals/0357-regex-string-processing-algorithms.md)
- [SE-0363: Unicode for String Processing](https://github.com/apple/swift-evolution/blob/main/proposals/0363-unicode-for-string-processing.md)

#### 其他资源

- [Regex Playground](https://regexr.com)
- [Cheat Sheet](https://github.com/niklongstone/regular-expression-cheat-sheet)
