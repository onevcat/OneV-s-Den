---
layout: post
title: "Swift 中使用 Option Pattern 改善可选项的 API 设计"
date: 2020-10-21 14:00:00.000000000 +09:00
tags: 能工巧匠集
---

SwiftUI 中提供了很多“新颖”的 API 设计思路和 Swift 的使用方式，我们可以进行借鉴，并反过来使用到普通的 Swift 代码中。[`PreferenceKey`](https://developer.apple.com/documentation/swiftui/preferencekey) 的处理方式就是其中之一：它通过 protocol 的方式，为子 view 们提供了一套模式，让它们能将自定义值以类型安全的方式，向上传到父 view 去。如果有机会，我会再专门介绍 `PreferenceKey`，但这种设计的模式其实和 UI 无关，在一般的 Swift 里，我们也能使用这种方法来改善 API 设计。

在这篇文章里，我们就来看看要如何做。文中相关的代码可以[在这里找到](https://gist.github.com/onevcat/40f21b41a6b1ffa06ceb9f3ee0470bf3)。你可以将这些代码复制到 Playground 中执行并查看结果。

### 红绿灯

用一个交通信号灯作为例子。

![](/assets/images/2020/light-1.png)

作为 Model 类型的 `TrafficLight` 类型定义了 `.stop`、`.proceed` 和 `.caution` 三种 `State`，它们分别代表停止、通行和注意三种状态 (当然，通俗来说就是“红绿黄”，但是 Model 不应该和颜色，也就是 View 层级相关)。它还持有一个 `state` 来表示当前的状态，并在设置时将这个状态通过 `onStateChanged` 发送出去：

```swift
public class TrafficLight {

    public enum State {
        case stop
        case proceed
        case caution
    }

    public private(set) var state: State = .stop {
        didSet { onStateChanged?(state) }
    }
    
    public var onStateChanged: ((State) -> Void)?
}
```

其余部分的逻辑和本次主题无关，不过它们也比较简单。如果你有兴趣的话，可以点开下面的详情查看。但这不影响本文的理解。

<details>
  <summary>TrafficLight 的其他部分</summary>
  <p>为了能让信号灯进行状态转换，我们可以在 <code class="highlighter-rouge">TrafficLight</code> 里定义各个阶段的时间：</p>
<div class="language-swift highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="kd">public</span> <span class="k">var</span> <span class="nv">stopDuration</span> <span class="o">=</span> <span class="mf">4.0</span>
<span class="kd">public</span> <span class="k">var</span> <span class="nv">proceedDuration</span> <span class="o">=</span> <span class="mf">6.0</span>
<span class="kd">public</span> <span class="k">var</span> <span class="nv">cautionDuration</span> <span class="o">=</span> <span class="mf">1.5</span>
</code></pre></div></div>
<p>然后用一个 <code class="highlighter-rouge">Timer</code> 计时，并进行控制状态的转换：</p>
<div class="language-swift highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="kd">private</span> <span class="k">var</span> <span class="nv">timer</span><span class="p">:</span> <span class="kt">Timer</span><span class="p">?</span>

<span class="kd">private</span> <span class="kd">func</span> <span class="nf">turnState</span><span class="p">(</span><span class="n">_</span> <span class="nv">state</span><span class="p">:</span> <span class="kt">State</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">switch</span> <span class="n">state</span> <span class="p">{</span>
    <span class="k">case</span> <span class="o">.</span><span class="nv">proceed</span><span class="p">:</span>
        <span class="n">timer</span> <span class="o">=</span> <span class="kt">Timer</span><span class="o">.</span><span class="nf">scheduledTimer</span><span class="p">(</span><span class="nv">withTimeInterval</span><span class="p">:</span> <span class="n">proceedDuration</span><span class="p">,</span> <span class="nv">repeats</span><span class="p">:</span> <span class="kc">false</span><span class="p">)</span> <span class="p">{</span> <span class="n">_</span> <span class="k">in</span>
            <span class="k">self</span><span class="o">.</span><span class="nf">turnState</span><span class="p">(</span><span class="o">.</span><span class="n">caution</span><span class="p">)</span>
        <span class="p">}</span>
    <span class="k">case</span> <span class="o">.</span><span class="nv">caution</span><span class="p">:</span>
        <span class="n">timer</span> <span class="o">=</span> <span class="kt">Timer</span><span class="o">.</span><span class="nf">scheduledTimer</span><span class="p">(</span><span class="nv">withTimeInterval</span><span class="p">:</span> <span class="n">cautionDuration</span><span class="p">,</span> <span class="nv">repeats</span><span class="p">:</span> <span class="kc">false</span><span class="p">)</span> <span class="p">{</span> <span class="n">_</span> <span class="k">in</span>
            <span class="k">self</span><span class="o">.</span><span class="nf">turnState</span><span class="p">(</span><span class="o">.</span><span class="n">stop</span><span class="p">)</span>
        <span class="p">}</span>
    <span class="k">case</span> <span class="o">.</span><span class="nv">stop</span><span class="p">:</span>
        <span class="n">timer</span> <span class="o">=</span> <span class="kt">Timer</span><span class="o">.</span><span class="nf">scheduledTimer</span><span class="p">(</span><span class="nv">withTimeInterval</span><span class="p">:</span> <span class="n">stopDuration</span><span class="p">,</span> <span class="nv">repeats</span><span class="p">:</span> <span class="kc">false</span><span class="p">)</span> <span class="p">{</span> <span class="n">_</span> <span class="k">in</span>
            <span class="k">self</span><span class="o">.</span><span class="nf">turnState</span><span class="p">(</span><span class="o">.</span><span class="n">proceed</span><span class="p">)</span>
        <span class="p">}</span>
    <span class="p">}</span>
    <span class="k">self</span><span class="o">.</span><span class="n">state</span> <span class="o">=</span> <span class="n">state</span>
<span class="p">}</span>
</code></pre></div></div>
<p>最后，向外提供开启和结束的方法就可以了：</p>
<div class="language-swift highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="kd">public</span> <span class="kd">func</span> <span class="nf">start</span><span class="p">()</span> <span class="p">{</span>
    <span class="k">guard</span> <span class="n">timer</span> <span class="o">==</span> <span class="kc">nil</span> <span class="k">else</span> <span class="p">{</span> <span class="k">return</span> <span class="p">}</span>
    <span class="nf">turnState</span><span class="p">(</span><span class="o">.</span><span class="n">stop</span><span class="p">)</span>
<span class="p">}</span>

<span class="kd">public</span> <span class="kd">func</span> <span class="nf">stop</span><span class="p">()</span> <span class="p">{</span>
    <span class="n">timer</span><span class="p">?</span><span class="o">.</span><span class="nf">invalidate</span><span class="p">()</span>
    <span class="n">timer</span> <span class="o">=</span> <span class="kc">nil</span>
<span class="p">}</span>
</code></pre></div></div>
</details>

<!--
为了能让信号灯进行状态转换，我们可以在 `TrafficLight` 里定义各个阶段的时间：

```swift
public var stopDuration = 4.0
public var proceedDuration = 6.0
public var cautionDuration = 1.5
```

然后用一个 `Timer` 计时，并进行控制状态的转换：

```swift
private var timer: Timer?

private func turnState(_ state: State) {
    switch state {
    case .proceed:
        timer = Timer.scheduledTimer(withTimeInterval: proceedDuration, repeats: false) { _ in
            self.turnState(.caution)
        }
    case .caution:
        timer = Timer.scheduledTimer(withTimeInterval: cautionDuration, repeats: false) { _ in
            self.turnState(.stop)
        }
    case .stop:
        timer = Timer.scheduledTimer(withTimeInterval: stopDuration, repeats: false) { _ in
            self.turnState(.proceed)
        }
    }
    self.state = state
}
```

最后，向外提供开启和结束的方法就可以了：

```swift
public func start() {
    guard timer == nil else { return }
    turnState(.stop)
}

public func stop() {
    timer?.invalidate()
    timer = nil
}
```
-->

在 (ViewController 中) 使用这个红绿灯也很简单。我们按照红绿黄的颜色，在 `onStateChanged` 中设定 `view` 的颜色：

```swift
light = TrafficLight()
light.onStateChanged = { [weak self] state in
    guard let self = self else { return }
    let color: UIColor
    switch state {
    case .proceed: color = .green
    case .caution: color = .yellow
    case .stop: color = .red
    }
    UIView.animate(withDuration: 0.25) {
        self.view.backgroundColor = color
    }
}
light.start()
```

这样，View 的颜色就可以随着 `TrafficLight` 的变化而变更了：

![](/assets/images/2020/light-running.gif)

### 青色信号

世界很大，有些地方 (比如日本) 会使用倾向于青色，或者实际上应该是[绿松色 (turquoise)](https://www.color-hex.com/color/40e0d0)，来表示“可以通行”。有时候这也是技术的[限制或者进步](http://www.reuk.co.uk/wordpress/news/uk-traffic-lights-57000-tonnes-of-co2/)所带来的结果。

> The green light was traditionally green in colour (hence its name) though modern LED green lights are turquoise.
> 
> -- Wikipedia 中关于 Traffic light 的记述

![](/assets/images/2020/light-2.png)

假设我们想要让 `TrafficLight` 支持青色的绿灯，一个能想到的最简单的方式，就是在 `TrafficLight` 里为“绿灯颜色”提供一个选项：

```swift
public class TrafficLight {
    public enum GreenLightColor {
        case green
        case turquoise
    }
    public var preferredGreenLightColor: GreenLightColor = .green
    
    //...
}
```

然后在 `ViewController` 中使用对应的颜色：

```swift
extension TrafficLight.GreenLightColor {
    var color: UIColor {
        switch self {
        case .green: 
            return .green
        case .turquoise: 
            return UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1.00)
        }
    }
}

light.preferredGreenLightColor = .turquoise
light.onStateChanged = { [weak self, weak light] state in
    guard let self = self, let light = light else { return }
    // ...
    
    // case .proceed: color = .green
    case .proceed: color = light.preferredGreenLightColor.color
}
```

这样做当然能够解决问题，但是也会带来一些隐患。首先，需要在 `TrafficLight` 中添加一个额外的存储属性 `preferredGreenLightColor`，这使得 `TrafficLight` 示例所使用的内存开销增加了。在上例中，额外的 `GreenLightColor` 属性将会为每个实例带来 8 byte 的开销。 如果我们需要同时处理很多 `TrafficLight` 实例，而其中只有很少数需要 `.turquoise` 的话，这个开销就非常可惜了。

> 严格来说，上例的 TrafficLight.GreenLightColor 枚举其实只需要占用 1 byte。但是 64-bit 系统中在内存分配中的最小单位是 8 bytes。
> 
> 如果想要添加的属性不是像例子中这样简单的 enum，而是更加复杂的带有多个属性的类型的话，这一开销会更大。

另外，如果我们还要添加其他属性，很容易想到的方法是继续在 `TrafficLight` 上加入更多的存储属性。这其实是很没有扩展性的方法，我们并不能在 extension 中添加存储属性：

```swift
// 无法编译
extension TrafficLight {
    enum A {
        case a
    }
    var myOption: A = .a // Extensions must not contain stored properties
}
```

需要修改 `TrafficLight` 的源码，才能添加这个选项，而且还需要为添加的属性设置合适的初始值，或者提供额外的 init 方法。如果我们不能直接修改 `TrafficLight` 的源码 (比如这个类型是别人的代码，或者是被封装到 framework 里的)，那么像这样的添加选项的方式其实是无法实现的。

### Option Pattern

可以用 Option Pattern 来解决这个问题。在 `TrafficLight` 中，我们不去提供专用的 `preferredGreenLightColor`，而是定义一个泛用的 `options` 字典，来将需要的选项值放到里面。为了限定能放进字典中的值，新建一个 `TrafficLightOption` 协议：

```swift
public protocol TrafficLightOption {
    associatedtype Value

    /// 默认的选项值
    static var defaultValue: Value { get }
}
```

在 `TrafficLight` 中，加入下面的 `options` 属性和下标方法：

```swift
public class TrafficLight {

    // ...

    // 1
    private var options = [ObjectIdentifier: Any]()

    public subscript<T: TrafficLightOption>(option type: T.Type) -> T.Value {
        get {
            // 2
            options[ObjectIdentifier(type)] as? T.Value
                ?? type.defaultValue
        }
        set {
            options[ObjectIdentifier(type)] = newValue
        }
    }
    
    // ...    
}
```

1. 只有满足 `Hashable` 的类型，才能作为 `options` 字典的 key。[`ObjectIdentifier`](https://developer.apple.com/documentation/swift/objectidentifier) 通过给定的类型或者是 class 实例，可以生成一个唯一代表该类型和实例的值。它非常适合用来当作 `options` 的 key。
2. 通过 key 在 `options` 中寻找设置的值。如果没有找到的话，返回默认值 `type.defaultValue`。

现在，对 `TrafficLight.GreenLightColor` 进行扩展，让它满足 `TrafficLightOption`。如果 `TrafficLight` 已经被打包成 framework，我们甚至可以把这部分代码从 `TrafficLight` 所在的 target 中拿出来：

```swift
extension TrafficLight {
    public enum GreenLightColor: TrafficLightOption {
        case green
        case turquoise

        public static let defaultValue: GreenLightColor = .green
    }
}
```

我们将 `defaultValue` 声明为了 `GreenLightColor` 类型，这样`TrafficLightOption.Value` 的类型也将被编译器推断为 `GreenLightColor`。

最后，为这个选项提供 setter 和 getter：

```swift
extension TrafficLight {
    public var preferredGreenLightColor: TrafficLight.GreenLightColor {
        get { self[option: GreenLightColor.self] }
        set { self[option: GreenLightColor.self] = newValue }
    }
}
```

现在，你可以像之前那样，通过直接在 `light` 上设置 `preferredGreenLightColor` 来使用这个选项，而且它已经不是 `TrafficLight` 的存储属性了。只要不进行设置，它便不会带来额外的开销。

```swift
light.preferredGreenLightColor = .turquoise
```

有了 `TrafficLightOption`，现在想要为 `TrafficLight` 添加选项时，就不需要对类型本身的代码进行改动了，我们只需要声明一个满足 `TrafficLightOption` 的新类型，然后为它实现合适的计算属性就可以了。这大幅增加了原来类型的可扩展性。

### 总结

Option Pattern 是一种受到 SwiftUI 的启发的模式，它帮助我们在不添加存储属性的前提下，提供了一种向已有类型中以类型安全的方式添加“存储”的手段。

这种模式非常适合从外界对已有的类型进行功能上的添加，或者是自下而上地对类型的使用方式进行改造。这项技术可以对 Swift 开发和 API 设计的更新产生一定有益的影响。反过来，了解这种模式，相信对于理解 SwiftUI 中的很多概念，比如 `PreferenceKey` 和 `alignmentGuide` 等，也会有所帮助。