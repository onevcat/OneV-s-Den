---
layout: post
title: "使用 protocol 和 callAsFunction 改进 Delegate"
date: 2020-03-12 10:00:00.000000000 +09:00
tags: 能工巧匠集
---

2018 年 3 月的时候我写过一篇在 Swift 中如何[改进 Delegate Pattern](https://xiaozhuanlan.com/topic/6104325798) 的文章，主要思想是用遮蔽变量 (shadow variable) 声明的方式，来保证 `self` 变量可以被常时地标记为 `weak`。本文中，为了保证没有看过原文的读者能处在同一频道，我会先 (再次) 简单介绍一下这种方法。然后，结合 Swift 5.2 的新特性提出一些小的改进方式。

## Delegate

简单说，为了避免繁琐老式的 `protocol` 定义和实现，我们可能更倾向于选择提供闭包的方式完成回调。比如在一个收集用户输入的自定义 view 中，提供一个外部可以设置的函数类型变量 `onConfirmInput`，并在合适的时候调用它：

```swift
class TextInputView: UIView {

    @IBOutlet weak var inputTextField: UITextField!
    var onConfirmInput: ((String?) -> Void)?

    @IBAction func confirmButtonPressed(_ sender: Any) {
        onConfirmInput?(inputTextField.text)
    }
}
```

在 `TextInputView` 的 controller 中，检测 input 确定事件就不需要一堆 `textInputView.delegate = self` 和 `textInputView(_:didConfirmText:)` 之类 的麻烦事了，可以直接设置 `onConfirmInput`：

```swift
class ViewController: UIViewController {

    @IBOutlet weak var textLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let inputView = TextInputView(frame: /*...*/)
        inputView.onConfirmInput = { text in 
            self.textLabel.text = text
        }
        view.addSubview(inputView)
    }
}
```

但是这引入了一个 retain cycle！`TextInputView.onConfirmInput` 持有 `self`，而 `self` 通过 `view` 持有 `TextInputView` 这个 sub view，内存将会无法释放。

当然，解决方法也很简单，我们只需要在设置 `onConfirmInput` 的时候使用 `[weak self]` 来将闭包中的 `self` 换为弱引用即可：

```swift
inputView.onConfirmInput = { [weak self] text in
    self?.textLabel.text = text
}
```

这为使用 `onConfirmInput` 这样的闭包变量加上了一个前提：你大概率需要将 `self` 标记为 `weak` 以避免犯错，否则你将写出一个内存泄漏。这个泄漏无法在编译期间定位，运行时也不会有任何警告或者错误，这类问题也极易带到最终产品中。在开发界有一句话是真理：

> 如果一个问题可能发生，那么它必然会发生。

一个简单的 `Delegate` 类型可以解决这个问题：

```swift
class Delegate<Input, Output> {
    private var block: ((Input) -> Output?)?
    func delegate<T: AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = { [weak target] input in
            guard let target = target else { return nil }
            return block?(target, input)
        }
    }

    func call(_ input: Input) -> Output? {
        return block?(input)
    }
}
```

通过设置 `block` 时就将 `target` (通常是 `self`) 做 `weak` 化处理，并且在调用 `block` 时提供一个 weak 后的 `target` 的变量，就可以保证在调用侧不会意外地持有 `target`。举个例子，上面的 `TextInputView` 可以重写为：

```swift
class TextInputView: UIView {
    //...
    let onConfirmInput = Delegate<String?, Void>()
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        onConfirmInput.call(inputTextField.text)
    }
}
```

使用时，通过 `delegate(on:)` 完成订阅：

```swift
inputView.onConfirmInput.delegate(on: self) { (self, text) in
    self.textLabel.text = text
}
```

闭包的输入参数 `(self, text)` 和闭包 body `self.textLabel.text` 中的 `self`，**并不是**原来的代表 controller 的 self，而是由 `Delegate` 把 `self` 标为 `weak` 后的参数。因此，直接在闭包中使用这个遮蔽变量 `self`，也不会造成循环引用。

到这里为止的原始版本 `Delegate` 可以在[这个 Gist](https://gist.github.com/onevcat/3c8f7c4e8c96f288854688cf34111636/3674c944a420a09f473726043856f28c9c1014d0) 里找到，加上空行一共就 21 行代码。

## 问题和改进

上面的实现有三个小瑕疵，我们对它们进行一些分析和改进。

### 1. 更自然i的调用

现在，对 delegate 的调用时不如闭包变量那样自然，每次需要去使用 `call(_:)` 或者 `call()`。虽然不是什么大不了的事情，但是如果能直接使用类似 `onConfirmInput(inputTextField.text)` 的形式，会更简单。

Swift 5.2 中引入的 [`callAsFunction`](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md)，它可以让我们直接以“调用实例”的方式 call 一个方法。使用起来很简单，只需要创建一个名称为 `callAsFunction` 的实例方法就可以了：

```swift
struct Adder {
    let value: Int
    func callAsFunction(_ input: Int) -> Int {
      return input + value
    }
}

let add2 = Adder(value: 2)
add2(1)
// 3
```

这个特性非常适合把 `Delegate.call` 简化，只需要加入对应的 `callAsFunction` 实现，并调用 `block` 就行了：

```swift
public class Delegate<Input, Output> {
    // ...
    
    func callAsFunction(_ input: Input) -> Output? {
        return block?(input)
    }
}

class TextInputView: UIView {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        onConfirmInput(inputTextField.text)
    }
}
```

现在，`onConfirmInput` 的调用看起来就和一个闭包完全一样了。

> 类似于 `callAsFunction` 的直接在实例上调用方法的方式，在 Python 中有很多应用。在 Swift 语言中添加这个特性能让习惯于 Python 的开发者更容易地迁移到像是 Swift for TensorFlow 这样的项目。而这个提案的提出和审核相关人员，也基本是 Swift for TensorFlow 的成员。

### 2. 双层可选值

如果 `Delegate<Input, Output>` 中的 `Output` 是一个可选值的话，那么 `call` 之后的结果将会是双重可选的 `Output??`。

```swift
let onReturnOptional = Delegate<Int, Int?>()
let value = onReturnOptional.call(1)
// value : Int??
```

这可以让我们区分出 `block` 没有被设置的情况和 `Delegate` 确实返回 `nil` 的情况：当 `onReturnOptional.delegate(on:block:)` 没有被调用过 (`block` 为 `nil`) 时，`value` 是简单的 `nil`。但如果 `delegate` 被设置了，但是闭包返回的是 `nil` 时，`value` 的值将为 `.some(nil)`。在实际使用上这很容易造成困惑，绝大多数情况下，我们希望把 `.none`，`.some(.none)` 和 `.some(.some(value))` 这样的返回值展平到单层 `Optional` 的 `.none` 或 `.some(value)`。

要解决这个问题，可以对 `Delegate` 进行扩展，为那些 `Output` 是 `Optional` 情况提供重载的 `call(_:)` 实现。不过 `Optional` 是带有泛型参数的类型，所以我们没有办法写出像是 
`extension Delegate where Output == Optional` 这样的条件扩展。一个“取巧”的方式是自定义一个新的 `OptionalProtocol`，让 `extension` 基于 `where Output: OptionalProtocol` 来做条件扩展：

```swift
public protocol OptionalProtocol {
    static var createNil: Self { get }
}

extension Optional : OptionalProtocol {
    public static var createNil: Optional<Wrapped> {
         return nil
    }
}

extension Delegate where Output: OptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let result = block?(input) {
            return result
        } else {
            return .createNil
        }
    }
}
```

这样，即使 `Output` 为可选值，`block?(input)` 调用所得到的结果也可以经过 `if let` 解包，并返回单层的 `result` 或是 `nil`。

### 3. 遮蔽失效

由于使用了遮蔽变量 `self`，在闭包中的 `self` 其实是这个遮蔽变量，而非原本的 `self`。这样要求我们比较小心，否则可能造成意外的循环引用。比如下面的例子：

```swift
inputView.onConfirmInput.delegate(on: self) { (_, text) in
    self.textLabel.text = text
}
```

上面的代码编译和使用都没有问题，但是由于我们把 `(self, text)` 换成了 `(_, text)`，这导致闭包内部 `self.textLabel.text` 中的 `self` 直接参照了真正的 `self`，这是一个强引用，进而内存泄露。

这种错误和 `[weak self]` 声明一样，没有办法得到编译器的提示，所以也很难完全避免。也许一个可行方案是不要用 `(self, text)` 这样的隐式遮蔽，而是将参数名明确写成不一样的形式，比如 `(weakSelf, text)`，然后在闭包中只使用 `weakSelf`。但这么做其实和 `self` 遮蔽差距不大，依然摆脱不了用“人为规定”来强制统一代码规则。当然，你也可以依靠使用 linter 和添加对应规则来提醒自己，但是这些方式也都不是非常理想。如果你有什么好的想法或者建议，十分欢迎交流和指教。
