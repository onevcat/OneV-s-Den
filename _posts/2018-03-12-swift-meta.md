---
layout: post
title: "不同角度看问题 - 从 Codable 到 Swift 元编程"
date: 2018-03-12 09:15:00.000000000 +09:00
tags: 能工巧匠集
---

> 最近开设了一个[小专栏](https://xiaozhuanlan.com/onevcat)，用来记录日常开发时遇到的问题和解决方案，同时也会收藏一些学习时记录的笔记，随想等。其中一些长文 (包括本文) 会首发于专栏，之后再同步到博客这边。虽然现在的文章还不多，但是因为计划更新比较勤快，所以适当进行收费，也算是对自己写作的一种鼓励和鞭笞。欢迎感兴趣的同学进行订阅，谢谢~

## 起源

前几天看到同事的一个 P-R，里面有将一个类型转换为字典的方法。在我们所使用的 API 中，某些方法需要接受 JSON 兼容的字典 (也就是说，字典中键值对的 `value` 只能是数字，字符串，布尔值，以及包含它们的嵌套字典或者数组等)，因为项目开始是在好几年前了，所以一直都是在需要的时候使用下面这样手写生成字典的方法：

```swift
struct Cat {
    let name: String
    let age: Int
    
    func toDictionary() -> [String: Any] {
        return ["name": name, "age": age]
    }
}

let kitten = Cat(name: "kitten", age: 2)
kitten.toDictionary()
// ["name": "kitten", "age": 2]
```

显然这是很蠢的做法：

1. 对于每一个需要处理的类型，我们都需要 `toDictionary()` 这样的模板代码；
2. 每次进行属性的更改或增删，都要维护该方法的内容；
3. 字典的 key 只是普通字符串，很可能出现 typo 错误或者没有及时根据类型定义变化进行更新的情况。

对于一个有所追求的项目来说，解决这部分遗留问题具有相当的高优先级。

## Codable

在 Swift 4 引入 `Codable` 之后，我们有更优秀的方式来做这件事：那就是将 `Cat` 声明为 `Codable` (或者至少声明为 `Encodable` - 记住 `Codable` 其实就是 `Decodable & Encodable`)，然后使用相关的 encoder 来进行编码。不过 Swift 标准库中并没有直接将一个对象编码为字典的编码器，我们可以进行一些变通，先将需要处理的类型声明为 `Codable`，然后使用 `JSONEncoder` 将其转换为 JSON 数据，最后再从 JSON 数据中拿到对应的字典：

```swift
struct Cat: Codable {
    let name: String
    let age: Int
}

let kitten = Cat(name: "kitten", age: 2)
let encoder = JSONEncoder()

do {
    let data = try encoder.encode(kitten)
    let dictionary = try JSONSerialization.jsonObject(with: data, options: [])
    // ["name": "kitten", "age": 2]
} catch {
    print(error)
}
```

这种方式也是同事提交的 P-R 中所使用的方式。我个人认为这种方法已经足够优秀了，它没有添加任何难以理解的部分，我们只需要将 `encoder` 在全局进行统一的配置，然后用它来对任意 `Codable` 进行编码即可。唯一美中不足的是，`JSONEncoder` 本身其实[在内部](https://github.com/apple/swift/blob/1e110b8f63836734113cdb28970ebcea8fd383c2/stdlib/public/SDK/Foundation/JSONEncoder.swift#L214-L231)就是先编码为字典，然后再从字典转换为数据的。在这里我们又“多此一举”地将数据转换回字典，稍显浪费。但是在非瓶颈的代码路径上，这一点性能损失完全可以接受的。

如果想要追求完美，那么我们可能需要仿照 [`_JSONEncoder`](https://github.com/apple/swift/blob/1e110b8f63836734113cdb28970ebcea8fd383c2/stdlib/public/SDK/Foundation/JSONEncoder.swift#L237) 重新实现 `KeyedEncodingContainer` 的部分，来将 `Encodable` 对象编码到容器中 (因为我们只需要编码为字典，所以可以忽略掉 `unkeyedContainer` 和 `singleValueContainer` 的部分)。整个过程不会很复杂，但是代码显得有些“啰嗦”。如果你没有自己手动实现过一个 Codable encoder 的话，参照着 `_JSONEncoder` 的源码实现一个 `DictionaryEncoder` 对于你理解 Codable 系统的运作和细节，会是很好的练习。不过因为这篇文章的重点并不是 `Codable` 教学，所以这里就先跳过了。

> 标准库中要求 Codable 的编码器要满足 `Encoder` 协议，不过要注意，公开的 [`JSONEncoder`](https://github.com/apple/swift/blob/1e110b8f63836734113cdb28970ebcea8fd383c2/stdlib/public/SDK/Foundation/JSONEncoder.swift#L18) 类型其实并不遵守 `Encoder`，它只提供了一套易用的 API 封装，并将具体的编码工作代理给一个内部类型 `_JSONEncoder`，后者实际实现了 `Encoder`，并负责具体的编码逻辑。

## Mirror

Codable 的解决方案已经够好了，不过“好用的方式千篇一律，有趣的解法万万千千”，就这样解决问题也实在有些无聊，我们有没有一些更 hacky 更 cool 更 for fun 一点的做法呢？

当然有，在 review P-R 的时候第一想到的就是 `Mirror`。使用 `Mirror` 类型，可以让我们在运行时一窥某个类型的实例的内容，它也是 Swift 中为数不多的与运行时特性相关的手段。`Mirror` 的最基本的用法如下，你也可以在[官方文档](https://developer.apple.com/documentation/swift/mirror)中查看它的一些其他定义：

```swift
struct Cat {
    let name: String
    let age: Int
}

let kitten = Cat(name: "kitten", age: 2)
let mirror = Mirror(reflecting: kitten)
for child in mirror.children {
    print("\(child.label!) - \(child.value)")
}
// 输出：
// name - kitten
// age - 2
```

通过访问实例中 `mirror.children` 的每一个 `child`，我们就可以得到所有的存储属性的 `label` 和 `value`。以 `label` 为字典键，`value` 为字典值，我们就能从任意类型构建出对应的字典了。

#### 字典中值的类型

不过注意，这个 `child` 中的值是以 `Any` 为类型的，也就是说，任意类型都可以在 `child.value` 中表达。而我们的需求是构建一个 JSON 兼容的字典，它不能包含我们自定义的 Swift 类型 (对于自定义类型，我们需要先转换为字典的形式)。所以还需要做一些额外的类型保证的工作，这里可以添加一个 `DictionaryValue` 协议，来表示目标字典能接受的类型：

```swift
protocol DictionaryValue {
    var value: Any { get }
}
```

对于 JSON 兼容的字典来说，数字，字符串和布尔值都是可以接受的，它们不需要进行转换，在字典中就是它们自身：

```swift
extension Int: DictionaryValue { var value: Any { return self } }
extension Float: DictionaryValue { var value: Any { return self } }
extension String: DictionaryValue { var value: Any { return self } }
extension Bool: DictionaryValue { var value: Any { return self } }
```

> 严格来说，我们还需要对像是 `Int16`，`Double` 之类的其他数字类型进行 `DictionaryValue` 适配。不过对于一个「概念验证」的 demo 来说，上面的定义就足够了。

有了这些，我们就可以进一步对 `DictionaryValue` 进行协议扩展，让满足它的其他类型通过 `Mirror` 的方式来构建字典：

```swift
extension DictionaryValue {
    var value: Any {
        let mirror = Mirror(reflecting: self)
        var result = [String: Any]()
        for child in mirror.children {
            // 如果无法获得正确的 key，报错
            guard let key = child.label else {
                fatalError("Invalid key in child: \(child)")
            }
            // 如果 value 无法转换为 DictionaryValue，报错
            if let value = child.value as? DictionaryValue {
                result[key] = value.value
            } else {
                fatalError("Invalid value in child: \(child)")
            }
        }
        return result
    }
}
```

现在，我们就可以将想要转换的类型声明为 `DictionaryValue`，然后调用 `value` 属性来获取字典了：

```swift
struct Cat: DictionaryValue {
    let name: String
    let age: Int
}

let kitten = Cat(name: "kitten", age: 2)
print(kitten.value)
// ["name": "kitten", "age": 2]
```

对于嵌套自定义 `DictionaryValue` 值的其他类型，字典转换也可以正常工作：

```swift
struct Wizard: DictionaryValue {
    let name: String
    let cat: Cat
}

let wizard = Wizard(name: "Hermione", cat: kitten)
print(wizard.value)
// ["name": "Hermione", "cat": ["name": "kitten", "age": 2]]
``` 

#### 字典中的嵌套数组和字典

上面处理了类型中属性是一般值 (JSON 原始值以及嵌套其他 `DictionaryValue` 类型) 的情况，不过对于 JSON 中的数组和字典的情况还无法处理 (因为我们还没有让 `Array` 和 `Dictionary` 遵守 `DictionaryValue`)。对于数组或字典这样的容器中的值，如果这些值满足 `DictionaryValue` 的话，那么容器本身显然也是 `DictionaryValue` 的。用代码表示的话类似这样：

```swift
extension Array: DictionaryValue where Element: DictionaryValue {
    var value: Any { return map { $0.value } }
}

extension Dictionary: DictionaryValue where Value: DictionaryValue {
    var value: Any { return mapValues { $0.value } }
}
```

在这里我们遇到一个非常“经典”的 Swift 的语言限制，那就是在 Swift 4.1 之前还不能写出上面这样的带有条件语句 (也就是 `where` 从句，`Element` 和 `Value` 满足 `DictionaryValue`) 的 extension。这个限制在 Swift 4.1 中[得到了解决](https://swift.org/blog/conditional-conformance/)，不过再此之前，我们只能强制做一些变化：

```swift
extension Array: DictionaryValue {
    var value: Any { return map { ($0 as! DictionaryValue).value } }
}
extension Dictionary: DictionaryValue {
    var value: Any { return mapValues { ($0 as! DictionaryValue).value } }
}
```

这么做我们失去了编译器的保证：对于任意的 `Array` 和 `Dictionary`，我们都将可以调用 `value`，不过，如果它们中的值不满足 `DictionaryValue` 的话，程序将会崩溃。当然，实际如果使用的时候可以考虑返回 `NSNull()`，来表示无法完成字典转换 (因为 `null` 也是有效的 JSON 值)。

有了数组和字典的支持，我们现在就可以使用 `Mirror` 的方法来对任意满足条件的类型进行转换了：

```swift
struct Cat: DictionaryValue {
    let name: String
    let age: Int
}

struct Wizard: DictionaryValue {
    let name: String
    let cat: Cat
}

struct Gryffindor: DictionaryValue {
    let wizards: [Wizard]
}

let crooks = Cat(name: "Crookshanks", age: 2)
let hermione = Wizard(name: "Hermione", cat: crooks)

let hedwig = Cat(name: "hedwig", age: 3)
let harry = Wizard(name: "Harry", cat: hedwig)

let gryffindor = Gryffindor(wizards: [harry, hermione])

print(gryffindor.value)
// ["wizards": 
//   [
//     ["name": "Harry", "cat": ["name": "hedwig", "age": 3]], 
//     ["name": "Hermione", "cat": ["name": "Crookshanks", "age": 2]]
//   ]
// ]
```

`Mirror` 很 cool，它让我们可以在运行时探索和列举实例的特性。除了上面用到的存储属性之外，对于集合类型，多元组以及枚举类型，`Mirror` 都可以对其进行探索。强大的运行时特性，也意味着额外的开销。`Mirror` 的文档明确告诉我们，这个类型更多是用来在 Playground 和调试器中进行输出和观察用的。如果我们想要以高效的方式来处理字典转换问题，也许应该试试看其他思路。

## 代码生成

最高效的方式应该还是像一开始我们提到的纯手写了。但是显然这种重复劳动并不符合程序员的美学，对于这种“机械化”和“模板化”的工作，定义模板自动生成代码会是不错的选择。

### Sourcery

[Sourcery](https://github.com/krzysztofzablocki/Sourcery) 是一个 Swift 代码生成的开源命令行工具，它 (通过 [SourceKitten](https://github.com/jpsim/SourceKitten)) 使用 Apple 的 SourceKit 框架，来分析你的源码中的各种声明和标注，然后套用你预先定义的 [Stencil](https://github.com/kylef/Stencil) 模板 (一种语法和 [Mustache](https://mustache.github.io/#demo) 很相似的 Swift 模板语言) 进行代码生成。我们下面会先看一个使用 Sourcery 最简单的例子，来说明如何使用这个工具。然后再针对我们的字典转换问题进行实现。

安装 Sourcery 非常简单，`brew install sourcery` 即可。不过，如果你想要在实际项目中使用这个工具的话，我建议直接[从发布页面](https://github.com/krzysztofzablocki/Sourcery/releases)下载二进制文件，放到 Xcode 项目目录中，然后添加 Run Script 的 Build Phase 来在每次编译的时候自动生成。

#### EnumSet

来看一个简单的例子，假设我们在文件夹中有以下源码：

```swift
// source.swift
enum HogwartsHouse {
    case gryffindor
    case hufflepuff
    case ravenclaw
    case slytherin
}
```

很多时候我们会有想要得到 enum 中所有 case 的集合，以及确定一共有多少个 case 成员的需求。如果纯手写的话，大概是这样的：

```swift
enum HogwartsHouse {
    // ...
    static let all: [HogwartsHouse] = [
        .gryffindor,
        .hufflepuff,
        .ravenclaw,
        .slytherin
    ]
    
    static let count = 4
}
```

显然这么做对于维护很不友好，没有人能确保时刻记住在添加新的 case 后一定会去更新 `all` 和 `count`。对其他有同样需求的 enum，我们也需要重复劳动。Sourcery 就是为了解决这样的需求而生的，相对于手写 `all` 和 `count`，我们可以定义一个空协议 `EnumSet`，然后让 `HogwartsHouse` 遵守它：

```swift
protocol EnumSet {}
extension HogwartsHouse: EnumSet {}
```

这个定义为 Sourcery 提供了一些提示，Sourcery 需要一些方式来确定为哪部分代码进行代码生成，“实现了某个协议”这个条件就是一个很有用的提示。现在，我们可以创建模板文件了，在同一个文件夹中，新建 `enumset.stencil`，并书写下面的内容：

<script src="https://gist.github.com/onevcat/f8321f3ebd7f8c189f09192f6f85db79.js"></script>

乍一看上去可能有些可怕，不过其实仔细辨识的话基底依然是 Swift。模板中被 {% raw %}`{% %}`{% endraw %} 包含的内容将被作为代码执行，{% raw %}`{{ }}`{% endraw %} 中的内容将被求值并嵌入到生成的文本中，而其他部分被直接作为文本复制到目标文件里。

第一行：

<script src="https://gist.github.com/onevcat/b47006a744e31539b73f370cc44ff2ac.js"></script>

即“选取那些实现了 `EnumSet` 的类型，滤出其中所有的 enum 类型，然后对每个 enum 进行枚举”。接下来，我们对这个选出的 enum 类型，为它创建了一个 extension，并对其所有 case 进行迭代，生成 `all` 数组。最后，将 `count` 设置为成员个数。

一开始你可能会有不少疑问，`types.implementing` 是什么，我怎么能知道 `enum` 在有 `name`, `cases`，`hasAssociatedValues` 之类的属性？Sourcery 有非常[详尽的文档](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/index.html)，对上述问题，你可以在 [Types](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/Classes/Types.html) 和 [Enum](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/Classes/Enum.html) 的相关页面找到答案。在初上手写模板逻辑时，参照文档是不可避免的。

一切就绪，现在我们可以将源文件喂给模板，来生成最后的代码了：

```bash
sourcery --sources ./source.swift --templates ./enumset.stencil
```

> `--sources` 和 `--templates` 都可以接受文件夹，Sourcery 会按照后缀自行寻找源文件和模板文件，所以也可以用 `sourcery --sources ./ --templates ./` 来替代上面的命令。不过实际操作中还是建议将源文件和模板文件放在不同的文件夹下，方便管理。

在同一个文件夹下，可以看到生成的 `enumset.generated.swift` 文件：

```swift
extension HogwartsHouse {
    static let all: [HogwartsHouse] = [
        .gryffindor,
        .hufflepuff,
        .ravenclaw,
        .slytherin
    ]
    static let count: Int = 4
}
```

问题解决。:]

#### 字典转换

下面来进行字典转换。类似上面的做法，定义一个空协议，让想要转换的自定义类型满足协议：

```swift
protocol DictionaryConvertible {}

struct Cat: DictionaryConvertible {
    let name: String
    let age: Int
}

struct Wizard: DictionaryConvertible {
    let name: String
    let cat: Cat
}

struct Gryffindor: DictionaryConvertible {
    let wizards: [Wizard]
}
```

接下来就可以尝试以下书写模板代码了。屏上得来终觉浅，有了上面 `EnumSet` 的经验，我强烈建议你花一点时间自己完成 `DictionaryConvertible` 的模板。你可以参照 [Sourcery 文档](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/index.html) 关于单个 [Type](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/Classes/Type.html) 和 [Variable](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/Classes/Variable.html) 的部分的内容来实现。另外，可以考虑使用 `--watch` 模式来在文件改变时自动生成代码，来实时观察结果。

```bash
sourcery --sources ./ --templates ./ --watch
```

最后，我的带有完整注释的对应的模板代码如下 (为了方便阅读，调整了一些格式)：

<script src="https://gist.github.com/onevcat/ace60350f1c9c8a189f2788bc5ae2750.js"></script>

生成的代码如下：

```swift
// 生成的代码
extension Cat {
    var value: [String: Any] {
        return [
            "name": name,
            "age": age
        ]
    }
}
extension Gryffindor {
    var value: [String: Any] {
        return [
            "wizards": wizards.map { $0.value }
        ]
    }
}
extension Wizard {
    var value: [String: Any] {
        return [
            "name": name,
            "cat": cat.value
        ]
    }
}
```

最后，我们还需要在原来的 Swift 文件中加上一些原始类型的扩展，这样对于原始类型值的数组和字典，我们的生成代码也能正确处理：

```swift
extension Int { var value: Int { return self } }
extension String { var value: String { return self } }
extension Bool { var value: Bool { return self } }
```

> 当然，你也可以考虑使用代码生成的方式来搞定，不过因为兼容的类型不会改变，直接写死亦无伤大雅。

相比于 JSON `Codable` 和 `Mirror` 的做法，这显然是运行时最高效的方式。除了使用 Sourcery 内建的类型匹配系统和 API 外，你还可以在源码中添加 Sourcery 的标注：`/// sourcery:`。被标注的内容将可以[通过 `annotations`](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/Protocols/Annotated.html#/s:15SourceryRuntime9AnnotatedP11annotationss10DictionaryVySSSo8NSObjectCGv)进行访问，这使得 Sourcery 几乎“无所不能”。

### gyb

代码生成方式的另一个“流行”选择时 gyb (Generate Your Boilerplate)。[gyb](https://github.com/apple/swift/blob/master/utils/gyb.py) 严格来说就是一个 Python 脚本，它将预定义的值填充到模板中。这个工具被大量用于 Swift 项目本身的开发，标准库中有不少以 `.gyb` 作为后缀的文件，比如 [Array](https://github.com/apple/swift/blob/32146274e73fe07bf3f9633f49624cc6728f1ae3/stdlib/public/core/Arrays.swift.gyb) 就是通过 gyb 生成的。

gyb 设计的最初目的主要是为了解决像是 `Int8`，`Int16`，`Int32` 等这一系列十分类似但又必须加以区分的类型中模板代码问题的。(鉴于 Apple 自己都有可能用其他工具来替换掉它，) 我们这里就不展开介绍了。如果你对 gyb 感兴趣，可以看看这篇[简明教程](http://swift.gg/2016/03/04/a-short-swift-gyb-tutorial/)。

这里引出 gyb，主要是想说明，挖掘 Swift 源码 (特别是标准库源码，因为标准库本身大部分也是由 Swift 写的)，是非常有意思的一件事情。今后如果有机会我可能也会写一些阅读 Swift 标准库源码的文章，和大家一起探讨 Swift 源码中一些有趣的事情 :P

## AST & libSyntax

我们说到，Sourcery 是依赖于 SourceKitten 获取源码信息的，而一路向下的话，SourceKitten 本身是对 SourceKit (`sourcekitd.framework`) 的高层级封装，最后它们都是对抽象语法树 (Abstract Syntax Tree, AST) 进行解析操作。编译器将源码 token 化，并构建 AST。

在上面的 Sourcery 的例子中，我们实际上做的首先是通过 AST 获取全部的源码信息，然后将语法单元进行组合，生成 Sourcery API 中的各个对象。接着，将这些对象传递给 Stencil 模板进行“渲染”，得到生成的源码。除了使用模板以外，还有一种直接操作 AST，通过代码“生成”代码的方式，那就是 libSyntax。

[libSyntax](https://github.com/apple/swift/tree/master/lib/Syntax) 相对鲜为人知，它作为 Swift 项目的一个工具库，现在被用于 Swift 代码的重构 (在 Xcode 9 中 Cmd + 点击，你应该可以看到重命名，提取方法等一系列重构操作的菜单)。通过 libSyntax 提供的 API，你可以生成结构化的代码，比如下面的代码片段，可以生成一个名成为 `name`，类型为 `type` 的 `let` 变量声明：

> 注意，为了使用 SwiftSyntax，你需要安装并切换为 Swift 4.1 的工具链 (至少在本文写作时如此，libSyntax 还没有确定会不会最终集成在 Swift 4.1 中)，并为 libSyntax 指定正确的 Runpath 和 Library 搜索路径。关于如何在 Xcode 中使用 libSyntax，可以参考[项目主页](https://github.com/apple/swift/tree/master/lib/Syntax#try-libsyntax-in-xcode)。

SwiftSyntax 这一封装为我们提供了 Swift 类型安全的方式，来操作和生成代码。结合使用工厂类 `SyntaxFactory` 和各种类型的 builder (希望你还记得设计模式那一整套东西 :P )，可以“方便”地生成我们需要的代码。比如下面的 `createLetDecl` 为我们生成一个 `let` 的变量声明，我们之后会用它作为更进一步的例子的构建模块：


```swift
import Foundation
import SwiftSyntax

// Trivia 指的是像空格，回车，tab，分号等元素
func createLetDecl(name: String, type: String,
                   leadingTrivia: Trivia = .zero, trailingTrivia: Trivia = .newlines(1)) -> VariableDeclSyntax
{
    // 创建 let 关键字 (`let`)
    let letKeyword = SyntaxFactory.makeLetKeyword(leadingTrivia: leadingTrivia, trailingTrivia: .spaces(1))
    
    // 根据 name 创建属性名 (`name`)
    let nameId = SyntaxFactory.makeIdentifier(name)

    // 组合类型标记 (比如 `: Int` 部分)
    let typeId = SyntaxFactory.makeTypeIdentifier(type, trailingTrivia: trailingTrivia)
    let colon = SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1))
    let typeAnnotation = SyntaxFactory.makeTypeAnnotation(colon: colon, type: typeId)

    let member = IdentifierPatternSyntax { builder in
        builder.useIdentifier(nameId)
    }
    
    let patterBinding = SyntaxFactory.makePatternBinding(pattern: member,
                                                         typeAnnotation: typeAnnotation,
                                                         initializer: nil, accessor: nil, trailingComma: nil)
    let list = SyntaxFactory.makePatternBindingList([patterBinding])
    
    // 生成属性声明
    return SyntaxFactory.makeVariableDecl(attributes: nil, modifiers: nil, letOrVarKeyword: letKeyword, bindings: list)
}

let nameDecl = createLetDecl("name", "String")
// let name: String

let ageDecl = createLetDecl("age", "Int")
// let age: Int
```

现在，可以尝试用类似的方式生成之前例子中的 `Cat` 结构体：

```swift
let keyword = SyntaxFactory.makeStructKeyword(trailingTrivia: .spaces(1))
let catId = SyntaxFactory.makeIdentifier("Cat", trailingTrivia: .spaces(1))
let members = MemberDeclBlockSyntax {
    $0.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))
    $0.addDecl(createLetDecl(name: "name", type: "String", leadingTrivia: .spaces(4)))
    $0.addDecl(createLetDecl(name: "age", type: "Int", leadingTrivia: .spaces(4), trailingTrivia: .zero))
    $0.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1)))
}

let catStruct = StructDeclSyntax {
    $0.useStructKeyword(keyword)
    $0.useIdentifier(catId)
    $0.useMembers(members)
}

print(catStruct)
/*
struct Cat {
    let name: String
    let age: Int
}
*/
```

SwiftSyntax 是一套功能完备的 Swift 源码生成工具，也就是说，除了变量声明和结构体，其他上至类、枚举、方法，下到访问控制关键字、冒号、逗号，都有对应的类型安全的方式进行操作。除了通过代码生成代码以外，SwiftSyntax 也支持遍历访问所有的 token。回到我们的字典转换的工作，我们需要做的就是，使用 libSyntax 遍历访问 token (或者想简单一些的话可以直接用 SourceKitten)，找到我们感兴趣的需要转换的类，然后遍历它的属性声明。接下来将这些属性声明再通过 libSyntax 的各种 maker 和 builder 组织为字典的形式，以 extension 的形式写回对应文件中去。

由于这样来进行字典转换实在没有什么实用价值，所以不再浪费篇幅贴代码了。不过使用 libSyntax 来完成一些像是缩进/对齐/括号换行之类的 formatter 工具会是很不错的选择。你也可以仔细思考看看如果你是 Xcode 的开发者，会如何实现像是重命名或者方法提取这样的重构功能。(也许下一份工作就可以投 Apple 的 Xcode 团队或者 JetBrains 的 AppCode 团队了呢~)

顺带一提，作为元编程库的 libSyntax 本身也大量使用了 gyb 的方式来生成代码，也许你可以把它叫做“元元编程”。😂

> SwiftSyntax 非常强大，不过它还在持续的开发中，并没有达到稳定。因此最好也不要现在将它用在实际的项目中，它的文档几乎没有，部分语法支持还[没有完整实现](https://github.com/apple/swift/blob/master/lib/Syntax/Status.md)，很多细节也还没有最终确定。(不过也正是这样，才满足一个好玩的“玩具”的特质。)


## 总结

不管是运行时的反射 (类似 `Mirror`)，还是编译前生成代码，都可以归类到“元编程”的范畴里。绕了一大圈，其实对于本文中的例子来说，可能简单地使用 Codable 就已经足够好。不过，从多个角度看这个问题的话，我们能发现不少有趣的其他解决方案，这有益无害。

实际上，有很多工作更适合使用元编程来处理：比如在处理事件统计时，我们可以自动通过定义生成所需要的统计类型；在写网络 API Client 时，可以生成请求的定义；对于重复的单元测试，可以用模板批量生成 mock 或者 stub 帮助简化流程和保持测试代码与产品代码的同步；在策划人员难以直接修改源码时，可以为他们提供配置文件，最后再按照将配置文件生成需要的代码等。每个方面都有值得进一步思考和研究的深度内容，而这种元编程的能力可以让我们避免直接对代码进行重复维护，依靠更加可靠的自动机制避免引入人为错误，这在已有代码需要大范围重复变更的时候尤为有效。

在今后有类似的重复体力劳动需求时，不妨考虑使用元编程的方法稍微放飞自我。:)



