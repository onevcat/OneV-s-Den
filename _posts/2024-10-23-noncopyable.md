---
layout: post
title: "逆流而上的设计 - Swift 所有权和 ~Copyable"
date: 2024-11-2 23:30:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, 开发者体验, 编程语言,编译器, 内存管理, 编译器]
typora-root-url: ..
---

在 Rust 中，绝对安全和高效的内存使用得益于其[独特的所有权（ownership）设计](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html)。七年前，Swift 团队发布了[《所有权宣言》](/2017/02/ownership/)，以前瞻性的方式介绍了 Swift 中关于值的内存管理变化的一系列愿景。Swift 5.9 中（以和宣言里略微不同的语法）实现了这一愿景，引入了不可复制类型的标记 `~Copyable`（non-copyable），以与 Rust 截然不同的（打补丁的）方式实现了更精确的所有权控制。在今年的 Swift 6 中，之前类型扩展（extension）和泛型（generic）不支持 `~Copyable` 的不足也得到了解决，`~Copyable` 的可用性得到了提升。回顾 `~Copyable` 及其设计，它为 Swift 引入了一种全新的设计思路：以往的协议是“为类型增加功能”，而 `~Copyable` 则是“为类型解除限制”。本文尝试解释 `~Copyable` 的设计和工作方式，以帮助读者更好地理解并利用这个特性。

## `~Copyable` 的工作方式

首先需要强调的是，即使目前完全不了解 `Copyable` 和 `~Copyable`，以及相关的 `consuming` 和 `borrowing` 等关键字，也不太会影响您成为一名优秀的 Swift 开发者或者继续保持这样的身份。在 Swift 学习的初期阶段，您无需完全理解其内存模型。然而，了解这些工具并在适当时机使用它们，不仅能帮助您编写更可靠、高效的代码，还能为您提供额外的设计思路。

我们先从一些最基础的知识开始，这也是纯新人容易搞混和迷惑的一个重要话题，值和引用。如果您对这些内容已经非常熟悉，也可以直接跳到[下一小节](#隐式-copyable-和不可复制的-copyable)。

### 值类型和引用类型

在 Swift 中，`struct` 和 `enum` 等是值类型，一个值类型的变量持有的是代表值本身的内存块。比如一个字符串，或者一个枚举成员：

```swift
let s1 = "Hello"
let e1 = Day.monday
```

当我们将这些变量赋值给其他变量，或是作为函数调用时的参数进行传递时，实际上这部分内存发生了复制。

```swift
var s2 = s1

func nextDay(of day: Day) -> Day {
  // `day` in the method body is a copy of content.
}
nextDay(e1)
```

在这些代码中，存在两个 `"Hello"` 和两个 `Day.monday`， 它们存在于内存的不同位置，是不同的值。

![](/assets/images/2024/value-type.png)

> 当然，Swift 中有被称为“写时复制” (copy on write, CoW) 的优化。对于某些数据结构，虽然表面上它们是值类型，但是在赋值或者传递时就进行无条件复制会造成大量性能损耗，因此它们会在内容被更改时才进行复制。不过这不是本文的话题，请允许我跳过。

而引用类型（主要是 `class`，`actor` 等）的行为则与此大相径庭。引用类型的变量所持有的内容是一个内存地址，并由运行时维护引用计数。将一个引用类型变量赋值给其他变量或者传递时，实际的内存并不会被复制，被复制的只有这个内存地址，且它的引用计数增加。

```swift
class MyView: UIView { }

let v1 = MyView()
let v2 = v1

func sample(_ view: MyView) {
  // `view` in the method is a copy of address (or, pointer).
}
sample(v1)
```

这段代码所对应的关系示意图为：

![](/assets/images/2024/ref-type.png)

不论对于以 `struct` 为代表的值类型还是以 `class` 为代表的引用类型，在赋值或传递时发生“复制”，是普遍现象。区别在于复制的是具体的值的内容，还是一个指针地址。这也决定了在赋值或者传递发生后，我们对这些值进行修改时，到底修改的是哪些内容：在上面的例子中，对 `s2` 的修改，比如为它指定一个新的字符串，并不会对 `s1` 造成影响（它们是两个不同的值，且内容现在也不相同了）；但是如果我们对 `v2` 中 `MyView` 的某个属性进行修改，`v1` 和 `view` 都会获取到修改后的属性，因为这三个变量保存了同样的地址，它们所指向的内容是同一个 `MyView`。

### 隐式 `Copyable` 和不可复制的 `~Copyable`

如果不加以声明，Swift 中所有东西都是可以被复制的。虽然大部分时候我们不太在意，但事实是对于 struct 或 enum 的复制并不是完全免费的。小体积的结构姑且不论，对于包含有很多数据，占用很多内存的值类型来说，复制的开销有时候并不能完全忽略；另外，有一些情况下我们会想要确保某个值只被使用一次。这些情况下，可以引入“不可复制的类型”，来明确表达值的所有权。

Swift 5.9 开始，为了规定类型的所有权，引入了两个协议：`Copyable` 和 `~Copyable`。两个协议都和 `Sendable` 类似，是不需要任何具体实现的标记类型。`Copyable` 代表可以被复制，它是 Swift 中所有类型和协议的默认行为，一般不需要额外声明。比如，下面的这些代码都是彼此等效的：

```swift
struct A { }
struct A: Copyable { }

protocol B { }
protocol B: Copyable { }

func foo<T>(t: T) { }
func foo<T>(t: T) where T: Copyable { }
```

如果你不希望某个类型可以被复制，那么可以将它声明为遵守 `~Copyable`。

`~Copyable` 是一个非常特殊的协议，虽然 `~` 符号确实表示“否定”，但是如果我们简单地把它看作是 `Copyable` 取反的话，可能会影响正确的理解。以往我们在使用协议时，它们所做的一般是“赋予类型某种能力”。比如 `Encodable` 赋予类型被编码的能力，`CustomStringConvertible` 赋予类型转换为字符串的能力。同理，`Copyable` 赋予了类型可被复制的能力。于是，你可能会简单地认为，`~Copyable` 做的事情是和普通协议类似，是赋予这些类型**“不可被复制”**的能力。不过如果你仔细考虑，会发现“不可被复制”**并不是**具有某种能力，而恰恰相反，它表达的是**不具有某种能力**。在其他普通协议的情况下，“不具备某种能力”是常态，是不需要特别说明的，只有满足协议的特定类型才具备这些能力。类比过来，其实 `~Copyable` 所定义的范围正式这种不具备能力的“常态”。只不过是由于语言现状下，`Copyable` 已经是应用于所有类型上的不需要明白写出的隐式默认实现，因此我们才需要使用 `~Copyable` 来做到和其他 protocol 相反的事情：它用来解除 `Copyable` 的能力，让一个类型回到“原本”的不具有可复制能力的状态。

如果用一张图来描述 `~Copyable`，`Copyable` 和 `Encodeable` 的关系，它会是这样的：

![](/assets/images/2024/protocol-relationship.png)

> 我们刚才说过，Swift 中所有类型和协议都默认有 `Copyable`。`Encodable` 的定义其实可以认为是：
>
> ```swift
> protocol Encodable: Copyable { }
> ```
>
> 因此，它在关系图上是 `Copyable` 的一部分。

## 所有权转移关键字

`~Copyable` 的值是不会被复制的，不过我们可以搭配一些关键字，稍微改变它的使用方式。具体来说，使用 `~Copyable` 时的关键字可能存在于三种位置：变量前，参数中和方法前。

### 用在变量前

一般是赋值时，比如等号的右侧，我们可以在赋值 `~Copyable` 值前加上 `consume`，来代表这个值的内容已经被消耗：

```swift
struct S: ~Copyable {
    func foo() { }
}

let s1 = S() // 报错：'s1' used after consume
let s2 = consume s1
s1.foo()
```

已消耗的变量将不可以再被使用，在上例中你可以理解为 `s1` 的内容被“移动”到了 `s2`，而原来的 `s1` 则处于类似于一种“没有初始化”的无效状态。编译器将确保它不会再被使用。

![](/assets/images/2024/copy-invalid-value.png)

> 如果你有兴趣，可以尝试用 `swiftc -emit-sil` 来生成对应的 [SIL](https://github.com/swiftlang/swift/blob/main/docs/SIL.rst)。事实上在 SIL 中，变量被使用后，会立即被 `debug_value undef` 命令撤销变量赋值，从而导致后续如果用到了这个变量，编译就无法完成。当前，对于使用被消耗后 `~Copyable` 的错误，编译器会将错误显示在变量被创建的位置。这并不是很直观，也许今后会有所改善。

在上面这样的变量赋值语句中，`consume` 是可以被省略的。比如，下面的代码相互等价：

```swift
let s2 = consume s1
let s2 = s1

var s3 = consume s2
var s3 = s2
```

不仅是普通的变量赋值，在涉及到 `if let` 这样的可选值时，`consume` 也可以被省略：

```swift
let s4: S? = S()
if let s = s4 { // 等价于 if let s = consume s4
    s4!.foo() // 错误。s4 已经被消耗了
    s.foo()   // s 可以正常使用
}
```

但是也有不可以被省略的时候。比如要是想自动将 `S` 值转为 `S?`：

```swift
let s1 = S()
var s5: S?
s5 = s1 // 报错：Implicit conversion to 'S?' is consuming
s3 = consume s1 // 正确
```

另外，有一些特殊情况，编译器会为我们自动按照不消耗 (consume) 而是借用 (borrowing) 的方式来使用变量，比如赋值给 `_` 或者针对 enum 进行 `switch`：

```swift
let s1 = S()
_ = s1
s1.foo() // OK
// 但是 let _ = s1 则会消耗

enum E { 
    case a
    func bar()
}
let e1 = E.a
switch e1 {
case .a: break
}
e1.bar() // OK
```

如果我们想要这样的下划线赋值或者 switch 语句也按照消耗内容的方式工作的话，可以明确加上 `consume`：

```swift
_ = consume s1
s1.foo() // error

switch consume e1 {
    // ...
}
e1.bar() // error
```

#### 小结

不论是否明确添加 `consume`，编译器能确保对于 `~Copyable` 变量的任何使用要么是 consume 的，要么是 borrowing 的，它们**都可以确保复制不会发生**。但是对于是否确实 consume 了原来的变量，则根据情况不同会有不同的行为。实际上，整个语言中 `consume` 是不是可以忽略不写，不写的时到底代表是 consume 还是 borrowing，可以说设计得比较混乱。如果对此介意，觉得隐式的 `consume` 关键字烧脑的话，不妨在使用时把需要消耗的地方都明确写出来。这样做相比默认情况下时而省略时而必须的状况来说，可能会更加清晰。

### 用在参数中

把 `~Copyable` 的值用在函数参数中则要明确得多，它要求我们必须从 `consuming`，`borrowing` 和 `inout` 中选择一个。

#### consuming

函数将会接管变量所有权，这相当于所有权发生转移。在函数内部，函数拥有这个输入参数的所有权：函数可以对它进行消耗（比如赋值，或者调用一次其他消耗函数等）：

```swift
let s = S()
consumeS(s)
let s1 = s // Fail，s 已经被 consumeS 消耗了。

func consumeS(_ s: consuming S) {
    let s1 = s // OK
}
```
要注意，即使 `consumeS` 的函数体内没有实际消耗掉 `s`，它的所有权也不会返回给调用者：

```swift
let s = S()
consumeS(s)
let s1 = s // Fail，s 已经被 consumeS 消耗了。

func consumeS(_ s: consuming S) {
    // let s1 = s
}
```

#### borrowing

暂时借出所有权，函数在内部可以访问 `s`，但是不能消耗它。也就是说，当参数是 borrowing 时，我们可以读取和使用它：

```swift
let s = S()
borrowS(s)
let s1 = s // OK，borrowS 不会消耗 s

func borrowS(_ s: borrowing S) {
    s.foo() // foo 是 S 上的非消耗函数
}
```

但是不能将它进行 consume 赋值或者用它当作 consuming 参数来调用别的函数：

```swift
func borrowS(_ s: borrowing S) {
    let s2 = s // 错误：借出的 s 不能被消耗
}
```

#### inout

这个关键字应该很熟悉了，原先的变量会被直接替换掉，在函数返回后，原有变量名所持有的已经是完全不同的新的值了。调用者对这个新的值拥有所有权。

```swift
var s = S()
inoutS(&s)
let s1 = s // OK，新的 s 在此处被消耗

func inoutS(_ s: inout S) {
    s = S()
}
```

当然了，在函数体内，原本的 s 的所有权发生了转移：原本值的所有权归函数所有，也会被正常消耗：

```swift
var s = S()
inoutS(&s)
let s1 = s // OK，新的 s 在此处被消耗

func inoutS(_ s: inout S) {
    let s2 = s
    // s.foo()  <- 将会报错，所有权已经交给了 s2
    s = S()
}
```

### 用于方法前

另一种所有权关键字出现的地点是 `~Copyable` 类型内部的方法前：我们可以在 `func` 前加上 `consuming` 或 `borrowing`。**默认不添加关键字时，相当于 `borrowing`**：

```swift
struct S: ~Copyable {
    consuming func consumeSelf() { }
    
    borrowing func borrowSelf() { }
    
    // 相当于 borrowing func
    func implictBorrowSelf() { }
}
```

在方法前添加所有权关键字，相当于为 `self` 参数添加一个关键字。举例来说，下面这两种写法和调用方式其实是等价的：

```swift
struct S: ~Copyable {
    consuming func consumeSelf() { }
}

func consumeS(_ s: consuming S) { }

let s1 = S()

// s1 (对于 S.consumeSelf 来说，它就是 `self`)
s1.consumeSelf()

let s2 = s1 // 错误，s1 已经被 `consumeSelf` 消耗了

let s3 = S()
consumeS(s3)
let s4 = s3 // 错误，s3 已经被 `consumeS` 消耗了
```

只要把对方法的调用，看作是第一个参数是 `self` 的静态方法，就能将这种情况归纳到上面的“用在参数中”中了：

```swift
// consuming func consumeSelf() 相当于：
func consumeSelf(self: consuming S) { }

// borrowing func borrowSelf() 相当于：
func borrowSelf(self: borrowing S) { }

// func implictBorrowSelf() 相当于：
func implictBorrowSelf(self: borrowing S) { }
```

在这些方法内部，`self` 也遵循同样的所有权行为：

```swift
consuming func consumeSelf() { 
    let s = self  // 可以消耗，`self` 的所有权归函数自身
    self.foo()    // 错误，`self` 已经被消耗了
}

borrowing func borrowSelf() { 
    let s = self // 错误，`self` 是借入的，不能被消耗。
    
}
```

### deinit 和 discard

#### deinit 的时机

对普通的 Copyable 的 struct 或者 enum，编译器不允许我们添加 `deinit`。但对于 `~Copyable` 的类型，因为它在 stack 上有 alloc 行为，我们可以向其中添加 `deinit`。如果在生命周期结束时，这个 `~Copyable` 变量都没有被消耗的话，`deinit` 就将被调用：

```swift
struct S: ~Copyable {
    deinit {
        print("Deinit")
    }
    
    func foo() {
        print("foo")
    }
}

func sample1() {
    print("sample1 start")
    let s = S()
    print("foo start")
    s.foo()
    print("foo end")
    print("sample1 end")
}

// 打印:
// sample1 start
// foo start
// foo
// foo end
// sample1 end
// Deinit
```

`S.deinit` 将在能够确定 `s` 的生命周期结束时调用（对应了 SIL 中的 `release_value` 指令）。在这里，由于 `S.foo` 是 borrowing 方法，`s` 将一直持有自己的所有权，直到 `sample1` 结束，因此 "Deinit" 将在 sample1 结束后才调用。

如果 `S` 中的是一个 consuming 函数，情况则不同：

```swift
struct S: ~Copyable {
    deinit {
        print("Deinit")
    }
    
    consuming func bar() {
        print("bar")
    }
}

func sample2() {
    print("sample2 start")
    let s = S()
    print("bar start")
    s.bar()
    print("bar end")
    print("sample2 end")
}

// 打印：
// sample2 start
// bar start
// bar
// Deinit
// bar end
// sample2 end
```

上例中，`bar` 被标记为 `consuming`，它获取 `self` 的所有权。即使在 `bar` 的函数体中我们没有进一步转移这个所有权，它依然被消耗了：于是 "Deinit" 将在从 `bar` 函数返回时被调用。这些行为赋予了 `~Copyable` 的 struct 或 enum 类似于 class 类型的能力。

#### discard

不过和 class 不同的是，Swift 给予了 `~Copyable` 类型放弃 `deinit` 调用的手段。我们可以在 `consuming` 方法中使用 `discard self` 来“放弃”对于 `self` 的所有权，从而让 `deinit` 不被调用。上例中，在 `bar` 中添加 `discard self`，`deinit` 就将不会再被调用：

```diff
consuming func bar() {
    print("bar")
+   discard self
}
```

## 在泛型或扩展中使用 ~Copyable

Swift 5.9 中尚不支持在泛型和扩展中使用 `~Copyable`，这使得 `~Copyable` 在很长时间内难堪大用。不过这一问题在 Swift 6.0 中得到了解决，这使得 `~Copyable` 已经完备。

### 扩展边界，突破 Copyable 约束

要记住，`Copyable` 是默认存在于所有类型声明中的。也就是说，对于一个平平无奇的泛型函数：

```swift
func foo<T>(t: T) -> Void
```

实际上，它的完整声明是：

```swift
func foo<T: Copyable>(t: T) -> Void
```

类似地，在定义协议时，`Copyable` 也是默认的：

```swift
protocol P { }

// 实际上，它是
protocol P: Copyable { }
```

如果我们在使用泛型或者定义协议时，希望它们是不可复制的，我们需要明确地写出来：

```swift
func bar<T: ~Copyable>(t: consuming T) -> Void

protocol Q: ~Copyable { }
```

然后我们就可以按照一般的方式通过 `~Copyable` 来使用它们了：

```swift
struct S: ~Copyable { }

bar(t: S())
extension S: Q { }
```

### ~Copyable 的设计哲学

看起来一切都很和谐，直到有一天我们发现，似乎一般的 `Copyable` 值也可以使用这些定义。比如 `Int` 就是一个完美的可复制值：

```swift
bar(t: 1)
extension Int: Q { }
```

我们来翻译翻译：

> 接受 `~Copyable` 的 `bar` 函数，现在接受了一个 `Copyable` 的 Int 值。
> 
> 一个 `Copyable` 的 Int 类型，符合 `~Copyable` 的协议 Q。

似乎哪里不对？

如果你这么想，就说明你还没有理解 `~Copyable`。在本文开篇，我们就提到过，`~Copyable` 的重点在于：

{: .alert .alert-info}
以往的协议是“为类型增加功能”，而 `~Copyable` 则是“为类型解除限制”。

我们可以把 `Copyable` 当作一个普通的协议，但是**不可以也不应该**把 `~Copyable` 也当成一个普通的协议：`~Copyable` 是不带有任何限制的全集，而 `Copyable` 仅仅是其中一个特别的子集。所以，上面的两句翻译，真正的正确的读法应该是：

> 一个可以接受包括 `Copyable` 在内的任意值的函数 `bar`，现在接受了一个 `Copyable` 的 Int 值。
> 
> 一个已经满足了 `Copyable` 协议的类型 Int，现在又满足了一个没有什么特别限制的协议 Q。

“当执行 `bar` 或者实现 `Q` 的时候，`~Copyable` 的存在解放了原本的隐式 `Copyable` 约束条件，给了像是 `S` 这样的 `~Copyable` 的具体类型能够作为参数执行 `bar` 或者去实现 `Q` 的机会”，这才是 `~Copyable` 在泛型或协议约束中的含义。如果在处理不可复制值的泛型和扩展相关的问题时遇到烧脑的部分，按照这个思路也许会更容易捋清其中各种关系。

## 总结

Copyable，Move-only 或者所有权的概念，不管名字怎么叫，在程序设计领域也不算新奇了。和 Rust 不同，Swift 没有强制要求我们使用和明确所有权。在默许开发者使用 `Copyable` 来完成绝大多数任务的同时，Swift 为更加精确的内存管理留出了 `~Copyable` 这个足够用的语言工具。

在需要的地方，如果不可复制特性确实能起到帮助，那使用它将会提升代码的效率和正确性。最常见的场景大致有两个：

1. 资源独占：当需要确保某个资源只能被一个持有者使用时，比如文件句柄、数据库连接、硬件设备访问等。这样可以在编译时就防止意外的资源共享。
2. 精确控制：对于使用值类型建模，但需要精确控制释放时机和生命周期的对象，比如自定义的内存管理、缓存系统等。

使用 `~Copyable` 时，需要清楚地理解什么时候发生了所有权转移，什么时候值的生命周期结束，以及用在泛型和协议时一些“违反直觉”的特性。因此，优先考虑普通的值类型，理解所有权这一工具的基本使用方式，只在确实需要独占资源或严格控制生命周期时才使用 `~Copyable`，可能会是更加平滑和正确的方式。
