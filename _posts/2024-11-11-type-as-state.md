---
layout: post
title: "编译器，靠你了！使用类型改善状态设计"
date: 2024-11-11 21:00:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, 开发者体验, 编程语言, 编译器, 内存管理, 编译器]
typora-root-url: ..
---

在程序的开发和运行过程中，人往往是最不可靠的环节：一个不小心，逻辑错误（也就是 bug！）可能会悄然保留下来并进入最终的产品。与此相对，编译器要可靠得多。如果程序中存在错误，编译器通常会直接阻止生成产品。Swift 拥有非常强大的类型系统，通过它，我们可以尝试将一些运行时的逻辑“封装”到类型系统中，从而在编译期提前发现潜在的问题和错误。这种依靠类型系统来“保存”逻辑的设计方式可以称为类型状态。

## 一个简单例子：端到端加密

### 定义和使用

这个例子源自实际工作的需求。假设我们需要设计一个客户端之间的消息系统，并支持端到端加密：也就是说，这些消息可能包含用户的隐私敏感内容。在用户设备上，这些消息可以以明文形式显示，但一旦需要离开用户设备、发送到服务端（并进一步传递到另一个目标客户端），则必须加密。如果错误地将未加密的信息发送出去，可能会带来安全隐患，甚至损害用户的信任。

一个“简洁”的设计思路是设计一个带有状态的 `Message`，它包含文本并用一个状态来表示是否已加密：

```swift
struct Message {
    enum State {
        case raw
        case encrypted
    }

    private var text: String
    private var state: State
    
    init(rawText: String) {
        text = rawText
        state = .raw
    }
}
```

在此基础上，添加 `encrypt` 和 `send` 方法。

```swift
mutating func encrypt() {
    if state == .raw {
        text = text.encrypted()
    }
    state = .encrypted
}
    
func send() {
    if state == .encrypted {
        Service.send(text)
    }
}
```

在 `encrypt` 中，我们检查了 `state`，当它是 `.raw` 时才进行加密，这可以避免对已经加密过的文本进行重复加密；在 `send` 里，我们再次检查了 `state`，并当它在 `.encrypted` 时才发送。

一切看起来都没问题，按照正常流程，生成的 `Message` 可以在加密后发送：

```swift
var message = Message(rawText: "Credit Number: 12345")
message.encrypt()
message.send()
```

多次调用 `encrypt`，改变调用的顺序，都不会出现什么大问题（虽然看上去有点糟糕）：

```swift
// 情况 1，不会被多次加密
message.encrypt()
message.encrypt()
message.send()

// 情况 2，明文不会被发送
message.send()
message.encrypt()
message.send()
```

### 问题

这种实现方式存在一个潜在问题，即我们依赖运行时的状态逻辑来决定行为。与编译时的保证相比，运行时状态较为脆弱。

#### 问题例子 1

由于缺乏编译期的保障，这种方式在重构过程中很容易引入人为错误。例如，假设某天我们在 `State` 中新增了一个成员 `.secret`：

```diff
enum State {
    case raw
    case encrypted
+   case secret
}

+ init(secretText: String) {
+     text = secretText
+     state = .secret
+ }
```

这时，`encrypt` 方法就失效了！

```swift
mutating func encrypt() {
    // .secret 不是 .raw。不走加密
    if state == .raw {
        text = text.encrypted()
    }
    state = .encrypted
}

var message = Message(secretText: "Hey, my sweet!")
message.encrypt()  // text 没加密，但 state 更新了
message.send()     // 未加密文本被发送出去了！危！
```

> 如果要进行正确的实现，我们需要仔细阅读 `encrypt`，并在其中添加合适的状态检查和加密操作。如果代码库再复杂一点，并且长时间不维护相关代码，或者是突然接手，那往往会非常困难。

#### 问题例子 2

对于重构而言，如果测试用例不完善，这种基于状态判断的代码也相当危险。例如，在一次重构中不小心删掉了某些代码：


```diff
mutating func encrypt() {
-   if state == .raw {
        text = text.encrypted()
-   }
    state = .encrypted
}
```

如果 `encrypt` 被多次调用，就会导致消息被多次加密，从而发送错误的加密信息。

```swift
message.encrypt() // 得到正确密文
message.encrypt() // 对密文再次加密
message.send()    // 接收端无法解密
```

类似的问题还有很多，随着类型复杂度的增加，会出现更多类似情况，这里就不再一一列举了。

## 可行的解决方案：用类型来定义状态

产生上述问题的根本原因在于，我们试图用**同一个类型实例中的状态来区分其能执行的操作**。类型系统应当充当能力的蓝图，当一个类型的实例不应被 “send” 或 “encrypt” 时，这些操作就不应出现在蓝图中。

### 用类型状态解决问题

最简单的解决方案是将 `Message` 拆分成两个不同的类型：`RawMessage` 和 `EncryptedMessage`，并分别只在相关类型上定义 `encrypt` 和 `send` 方法。不过，借助 Swift 强大的泛型系统，我们可以通过一个泛型参数更好地表达这种设计思路。考虑以下代码：

```swift
enum Raw { }
enum Encrypted { }

struct Message<T> {
    private(set) var text: String
}
```

对于未加密文本，可以通过 `T == Raw` 的扩展，为它添加初始化方法和 `encrypt`：

```swift
extension Message where T == Raw {
    init(rawText: String) {
        text = rawText
    }
    
    func encrypted() -> Message<Encrypted> {
        .init(text: text.encrypted())
    }
}
```

而对于已加密文本，它唯一需要的只有一个 `send`：

```swift
extension Message where T == Encrypted {
    func send() {
        Service.send(text)
    }
}
```

如此一来，我们就将状态相关的逻辑“编码”到类型中了。唯一能让编译器通过的调用方式，就是生成 `Message<Raw>`，加密，最后发送：

```swift
Message(rawText: "Credit Number: 12345")
    .encrypted()
    .send()
```

像是多次加密，忘了加密，或者颠倒调用顺序，现在都不可能发生了：

```swift
Message(rawText: "Credit Number: 12345")
    .encrypted()
    .encrypted() // 编译错误，只有 Raw 有这个方法
    .send()
    
Message(rawText: "Credit Number: 12345")
    .send()  // 编译错误，只有 Encrypted 有这个方法
```

这样，我们就得到了一个编译时就保证安全的 `Message` 类型。

### 实际使用，添加 `.secret`

之前我们提到过添加一个 `.secret` case，它是一个比 `Encrypted` 更高的安全等级，我们希望它能做到两点。

1. 比 `Encrypted` 更复杂的加密：比如对使用 `encrypted` 得到的密文用不同的密钥再加密一次。
2. 实现“发后即焚”：发送以后在本机销毁这个 `Message`，不留下痕迹。

作为练习，我们先来看第一点。有了前面的架构，添加这个 `Secret` 简直是“无脑”的：

```swift
enum Secret { }

extension Message where T == Encrypted {
    // ...
    
    func secreted() -> Message<Secret> {
        .init(text: text.secretEncrypted())
    }
}

extension Message where T == Raw {
    // ...
    
    func secreted() -> Message<Secret> {
        encrypted().secreted()
    }
}
```

最后，为 `Message<Secret>` 也定义一个 `send`：

```swift
extension Message where T == Secret {
    func send() {
        Service.send(text)
    }
}
```

使用起来也非常直接，不论是从 Raw 还是 Encrypted，我们都可以安全地得到用于发送的二次加密的信息：

```swift
Message(rawText: "Hey, my sweet!")
    .encrypted()
    .secreted()
    .send()
        
Message(rawText: "Hey, my sweet!")
    .secreted()
    .send()
```

不需要再去关心加密解密和当前状态，类型系统保证了我们从一开始就不可能写出错误的代码，同时也大大降低了重构和添加新功能时的风险。

### 使用 `~Copyable`

“发后即焚”这个功能我们还没有实现。对于发送操作而言，`Message<Encrypted>` 和 `Message<Secret>` 并没有区别。尽管我们在上面的代码中通过链式调用直接进行了发送，但在发送前仍然可以保留中间状态，并在发送后读取并存储消息内容。编译器并不会阻止我们这样操作：

```swift
let message = Message(rawText: "Hey, my sweet!")
    .encrypted()
    .secreted()
message.send()

// 虽然加密了但是被存下来了！危！
writeToFile(message.text) 
```

当然，你可能会认为这是逻辑错误或误用：毕竟，只要我们不写出这样的代码，就不会引发安全问题。然而，这一假设并不可靠，我们需要更稳妥的保障。没错，或许你已经想到了，[上一篇文章](/2024/11/noncopyable/)中提到的不可复制类型，正是在这个场景下编译器能够提供的可靠保障。

将 `Message<T>` 扩展为 `~Copyable`，然后在 `Message<Secret>` 的 `send` 前加上 `consuming` 关键字，大功告成！

```diff
- struct Message<T> {
+ struct Message<T>: ~Copyable {
     private(set) var text: String
}

extension Message where T == Secret {
-   func send() {
+   consuming func send() {
        Service.send(text)
    }
}
```

现在，发送 secret message 后，对该消息的进一步访问将不再被允许：

```swift
let message = Message(rawText: "Hey, my sweet!")
    .encrypted()
    .secreted()
message.send()

// 'message' used after consume
writeToFile(message.text)
```

## 总结

通过使用类型系统对关键逻辑进行编码，借助编译器的力量来减轻大脑负担，无论是从心智模型还是维护难度来看，都是有益的。如果有合适的场景，不妨尝试这种编程方式，相信它会让开发过程更加轻松。