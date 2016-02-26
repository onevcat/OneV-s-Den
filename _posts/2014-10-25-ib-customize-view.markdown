---
layout: post
title: WWDC 2014 Session笔记 - 可视化开发，IB 的新时代
date: 2014-10-25 00:02:07.000000000 +09:00
tags: 能工巧匠集
---
本文是我的 [WWDC 2014 笔记](http://onevcat.com/2014/07/developer-should-know-about-ios8/) 中的一篇，涉及的 Session 有

* [What's New in Xcode 6](http://devstreaming.apple.com/videos/wwdc/2014/401xxfkzfrjyb93/401/401_whats_new_in_xcode_6.pdf?dl=1)
* [What's New in Interface Builder](http://devstreaming.apple.com/videos/wwdc/2014/411xx0xo98zzoor/411/411_whats_new_in_interface_builder.pdf?dl=1)

如果说在 WWDC 14 之前 Interface Builder (IB) 还是可选项的话，我相信在此之后 IB 已经是毫无疑问的 iOS 开发标配了，纯代码界面可以说已经渐行渐远，可以逐渐离开我们的视线了。

一言蔽之，就是 Apple 在催促大家使用 IB，特别是 Storyboard 做为界面开发的唯一选择这件事上，下定了决心，也做出了实际的行动。

如果是纯代码 UI 在此之前还能[有所挣扎](http://onevcat.com/2013/12/code-vs-xib-vs-storyboard/)的话，那么压死这个方案的最后一根稻草就是 Size Classes。我已经在[之前的笔记](http://onevcat.com/2014/07/ios-ui-unique/)中对这方面内容做了些简单的探索，但是还远远不够，也许在将来某一天我还会重新整理下 Size Classes 这个主题的内容，以及使用 IB 适配不同屏幕的一些实践，但是不是这次。这篇文章里想要介绍的是 Xcode 6 中为 IB 锦上添花的一个特性，那就是实时地预览自定义 view，这个特性让 IB 开发的流程更加直观可视，也可以减少很多无聊的参数配置和 UI 设置的时间。

## 以前 IB 的不足

作为可视化开发的工具，IB 和 Storyboard 在组织和构建 ViewController 及其导航关系时已经做得很好的。对于 ViewController 的 view 画布上的诸如 `UILabel` 或者 `UIImageView` 这样的基础的类，IB 是能够很好地支持并实时在设计的时候进行显示的。但是对于那些自定义的类，之前的 IB 就束手无策了。我们能做的仅仅是在 IB 中拖放一个 `UIView`，然后通过将 `Custom Class` 属性设置为我们自定义的 `UIView` 的子类来在 “暗示” IB 在运行时初始化一个对应的子类。这样的问题是在开发自定义的 view 时，我们不得不一遍遍地修改代码并运行，再根据运行结果进行调整和修正。而实际上，单一对某个 view 的调试这种问题只涉及到设计层面，而非运行层面，如果我们能够在设计时就有一个实时地对自定义 view 的预览该多好。

没错，Apple 也是这么想的，并且在 Xcode 6 中，我们就已经可以创建这样的 `UIView` 子类了：利用新加入的 `@IBDesignable` 和 `@IBInspectable`，我们可以非常方便地完成在 IB 中实时显示自定义视图，甚至和其他一些内置 `UIView` 子类一样，直接在 IB 的 Inspector 改变某些属性，甚至我们还能通过设置断点来在 IB 中显示视图时进行调试。新的这些特性非常强大，使用起来却出乎意料的简单。下面我将通过一个实际的小例子加以说明。最终的完整例子已经放在 [GitHub](https://github.com/onevcat/ClockFaceView) 上了，现在我们从开始一步步开始吧。这些代码基于 Xcode 6.1 和 Swift 1.1。

## 时钟 view 的例子

### 单纯的自定义 view

假设我们有一个自定义的 view，用来描画一个时钟，如果有在读 [objc.io](http://objc.io) 或者 [objc 中国](http://objccn.io) 的读者，可能会发现这段代码是[动画一章一篇文章里代码](http://objccn.io/issue-12-2/)的改造过的 Swift 版本。

在这里我们有一个自定义的 `UIView` 的子类：`ClockFaceView`，其中嵌套了一个 `ClockFaceLayer` 作为 layer。如果我们不需要动画，我们也可以简单地使用 `-drawRect:` 来完成绘制。但是在这里我们还是选择使用添加 `CALayer` 的方式，这会使之后做动画简单好几个数量级 -- 因为我们可以简单地通过 CA 动画而不是每帧去计算绘制来完成动画 (在这篇帖子里不会涉及这些内容)。

    // ClockFaceView.swift
    import UIKit

    class ClockFaceView : UIView {
        
        class ClockFaceLayer : CAShapeLayer {
            
            private let hourHand: CAShapeLayer
            private let minuteHand: CAShapeLayer
            
            override init() {
                hourHand = CAShapeLayer()
                minuteHand = CAShapeLayer()
                
                super.init()
                frame = CGRect(x: 0, y: 0, width: 200, height: 200)
                path = UIBezierPath(ovalInRect: CGRectInset(frame, 5, 5)).CGPath
                fillColor = UIColor.whiteColor().CGColor
                strokeColor = UIColor.blackColor().CGColor
                lineWidth = 4
                
                hourHand.path = UIBezierPath(rect: CGRect(x: -2, y: -70, width: 4, height: 70)).CGPath
                hourHand.fillColor = UIColor.blackColor().CGColor
                hourHand.position = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
                addSublayer(hourHand)
                
                minuteHand.path = UIBezierPath(rect: CGRect(x: -1, y: -90, width: 2, height: 90)).CGPath
                minuteHand.fillColor = UIColor.blackColor().CGColor
                minuteHand.position = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
                addSublayer(minuteHand)   
            }

            required init(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            func refreshToHour(hour: Int, minute: Int) {
                hourHand.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(Double(hour) / 12.0 * 2.0 * M_PI)))
                minuteHand.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(Double(minute) / 60.0 * 2.0 * M_PI)))
            }
        }
        
        private let clockFace: ClockFaceLayer
        
        var time: NSDate? {
            didSet {
                refreshTime()
            }
        }
        
        private func refreshTime() {
            if let realTime = time {
                if let calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar) {
                    let components = calendar.components(NSCalendarUnit.CalendarUnitHour |
                                                         NSCalendarUnit.CalendarUnitMinute, fromDate: realTime)
                    clockFace.refreshToHour(components.hour, minute: components.minute)
                }
            }
        }
        
        override init(frame: CGRect) {
            clockFace = ClockFaceLayer()
            super.init(frame: frame)
            layer.addSublayer(clockFace)
        }

        required init(coder aDecoder: NSCoder) {
            clockFace = ClockFaceLayer()
            super.init(coder: aDecoder)
            layer.addSublayer(clockFace)
        }
    }

如果你没有耐心看完的话也没有关系，简单来说就是 `ClockFaceView` 在被初始化时会向自己添加一个 `ClockFaceLayer`，用来显示分针和时针。通过设置 `time` 属性我们可以更新时钟的位置。因为提供了 `initWithCoder:`，因此我们是可以直接从 IB 里加载这个 view 的。方法就是最普通的类型指定，并让 app 在加载时初始化对应的类型：在新建的 Single View Application 的 Storyboard 中添加一个 `UIView` 控件，然后设置好约束，并且将 Class 设置为 `ClockFaceView`：

![](/assets/images/2014/ibdesign-1.png)

运行应用，可以看到 `ClockFaceView` 被正确地初始化了，指针指向默认的 12 点整。通过为这个 view 建立 outlet 或者用其他 (比如 tag 的方式，虽然我不太喜欢这么做，但是我见过不少人这么弄) 方法找到这个 `ClockFaceView` 并设置时间的话，我们可以正确地改变其时针和分针的指向：

    // ViewController.swift
    class ViewController: UIViewController {

        @IBOutlet weak var clockFaceView: ClockFaceView!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.

            clockFaceView.time = NSDate()
        }
    }

![](/assets/images/2014/ibdesign-2.png)

### IBDesignable，IB 中自定义 view 的渲染

把大象装进冰箱有三个步骤，而让 IB 显示自定义 view 居然只有一个步骤！

只要我们在 `class ClockFaceView : UIView` 这个类型定义上面加上一个 `@IBDesignable` 的标记，就完成了！

在进行更改并等待编译和 IB 自动识别后，我们就可以在 IB 中原来一块白色的地方看到初始化后的时钟了：

![](/assets/images/2014/ibdesign-4.png)

如你所想，这个标记的作用是告诉 IB 如果遇到对应的 `UIView` 子类的话，可以对其进行渲染。深入一些来说，IB 将寻找你的子类中的 `-initWithFrame:` 方法，并给入当前自定义 view 的 frame 对其进行调用。需要注意的是，在使用 IB 初始化 view 时，被调用的是 `-initWithCoder:` 而非 frame 版本，所以说在想要实现自定义 view 在 IB 中的预览的话，我们至少必须实现这两个版本的初始化方法。不过好消息是，如果我们只添加了 `@IBDesignable`，而忘了实现 `-initWithFrame:` 的话，在 IB 渲染 view 时会给我们抛出大大的错误，所以因为遗漏而花大量时间在查找哪里出了问题这种事情应该不太可能发生。

![](/assets/images/2014/ibdesign-3.png)

### 仅设计时的配置

现在在 IB 中我们显示的时钟只能默认地指向 0 点 0 分，这是因为在设计的时候，我们并没有机会去设定这个 view 的 `time` 属性，所以时针和分针都停留在了初始的位置上。在 Xcode 6 中可以在 `@IBDesignable` 标记的 `UIView` 子类中添加一个 `prepareForInterfaceBuilder` 方法。每次在 IB 即将把这个自定义的 view 渲染到画布之前会调用这个方法进行最后的配置。比如我们想在 IB 中这个时钟的 view 上显示当前时间的话，可以在 `ClockFaceView` 中加入这个方法：

    class ClockFaceView : UIView {
        //...

        override func prepareForInterfaceBuilder() {
            time = NSDate()
        }

        //...
    }

保存并切换到 IB，静待自动编译和执行，可以看到类似下面的结果：

![](/assets/images/2014/ibdesign-5.png)

挺好的...现在我们的 IB 不仅被用来设计界面了，还兼备了看时间的功能 - 虽然这个时钟并不是实时的，只有在切换编辑器界面到 IB 或者是修改了相关文件时才会进行刷新。

另外虽然这篇文章没有涉及，但是需要一提的是，如果你想要在 `prepareForInterfaceBuilder` 里加载图片的话，需要弄清楚 bundle 的概念。IB 使用的 bundle 和 app 运行时的 `mainBundle` 不是一个概念，我们需要在设计时的 IB 的 bundle 可以通过在自定义的 view 自身的 bundle 中进行查找并使用。比如想要加载一张名为 `image.png` 的图片的话：

    let bundle = NSBundle(forClass: self.dynamicType)
    if let fileName = bundle.pathForResource("image", ofType: "png") {
        if let image = UIImage(contentsOfFile: fileName) {
            // 在此处可以使用 image
        }
    }
    
在使用 IB 中的方法读取资源时一定要注意运行环境不同这一点。

### 用 IBInspectable 在 IB 中调整属性

IBDesignable 的 view 的另一个很方便的地方是我们可以向 Inspector 中添加自定义的内容了。通过这样做，就可以直接在 IB 中对 view 进行一些编辑和配置。以前对于自定义 view，我们通常只能通过用类似 `IBOutlet` 的方式在代码中进行设置，或者是配置 Runtime Attribute 来进行，而现在我们有能力直接通过像给一个 `UILabel` 设定字符串或者给 `UIImageView` 设定图片这样的方式来设置自定义 view 的部分属性了，这也使得在 IB 中的自定义 view 的易用性和完整性得到了极大增强。

使用方法也非常简单，只需要在某个属性前加上 `@IBInspectable` 标记即可。比如我们可以在 `ClockFaceView` 中加入以下代码：

    class ClockFaceView : UIView {
        //...
    
        @IBInspectable
        var color: UIColor? {
            didSet {
                refreshColor()
            }
        }
        
        private func refreshColor() {
            if let realColor = color {
                clockFace.refreshColor(realColor)
            }
        }

        //...
    }

然后在 `ClockFaceLayer` 中加入对应的 `refreshColor` 方法：

    class ClockFaceLayer : CAShapeLayer {
        //...

        func refreshColor(color: UIColor) {
            hourHand.fillColor = color.CGColor
            minuteHand.fillColor = color.CGColor
            strokeColor = color.CGColor
        }

        //...
    }

我们对 `ClockFaceView` 中的 `color` 属性添加了 `@IBInspectable`，在保存和编译后，这会在 IB 中对应的 view 的 Attribute Inspector 中添加一个颜色选取的属性：

![](/assets/images/2014/ibdesign-6.png)

当我们在 IB 中设置这个属性的时候，对应的 `didSet` 将会被执行，通过 `refreshColor` 方法就可以直接改变 IB 中这个 view 的时针和分针的颜色了。

注意这个改变并不像 `prepareForInterfaceBuilder` 那样仅发生在设计时，我们直接运行代码，会看到运行时的颜色也是发生了改变的。其实 `@IBInspectable` 并没有做什么太神奇的事情，我们如果查看 IB 中这个 view 的 Identity Inspector 的话会看到刚才所设定的颜色值被作为了 Runtime Attribute 被使用了。其实手动直接在 Runtime Attributes 中设定颜色也有同样的效果，因此 `@IBInspectable` 唯一做的事情就是在 IB 面板上为我们提供了一个很方便地修改属性的入口，别没有其他太多神奇之处。

这个原理同时也决定了 `@IBInspectable` 是有一定限制的，即只有能够在 Runtime Attributes 中指定的类型才能够被标记后显示在 IB 中，这些类型包括 `Boolean`，`Number`，`String`，`Ponit`，`Size`，`Rect`，`Range`，`Color` 和 `Image`。像是如果想要把类似 `time` 这样的属性标记为 `@IBInspectable` 的话，在 IB 中还是无法显示的，因为 Xcode 并没有准备 `NSDate` 类型。不过其实通过 KVC 进行动态设定这种事情在原理上是没有问题的，界面的支持应该也可以通过 [Xcode 插件](http://onevcat.com/2013/02/xcode-plugin/)进行扩展，感觉上并不是一件特别困难的事情，有兴趣的同学不妨尝试，应该挺有意思 (当然也有可能会是个坑)。

### 自定义渲染 view 的调试

对于简单的自定义 view 来说，实时显示和属性设定什么的并不是一件很难的事情。但是对于那些比较复杂的 view，如果我们遇到某些渲染上的问题的话，如果只能靠猜的话，就未免太可怜了。幸好，Apple 为 view 在 IB 中的渲染的调试也提供了相应的方法。在 view 的源代码中设置好断点，然后切到 IB，点选中我们的自定义的 view 后，我们就可以使用菜单里的 Editor -> Debug Selected Views 来让 IB 对这个自定义 view 进行渲染。如果触发了代码中的断点，那我们的代码就会被暂停在断点处，lldb 也会就位听我们调遣。一切都感觉良好，不是么？

![](/assets/images/2014/ibdesign-7.png)

## 总结

Xcode 6 中的很多 key feature 都是基于或者重度依赖 Interface Builder 的。比如 Size Classes，比如 xib 的启动画面，再比如本篇文章中说到的自定义 view 渲染等等。在 iOS 或者 Mac 开发中，IB 现在处于一个比以往任何时候都重要的时期，使用 IB 和这些方便的特性进行开发已经从可选项变为了必须项。很难想象没有 IB 的话要怎么才能使用这些工具，更进一步地说，很难想象没有 IB 的话开发者需要浪费多少时间在本应该迅速完成的工作中。

如果你还在使用代码来构建 UI 的话，现在也许是你最后的放下代码，拿起 IB 武装自己的机会了。一开始可能会有迷惑，会不习惯，会觉着被拽出了舒适区浑身无力。但是一旦适应以后，你不仅能够收获最新的技能和工具，也有机会站在一个全新的高度，来审视 app 中界面开发的种种，并从中找到乐趣。

P.S. 如果你不知道要从哪里入手，推荐可以从 raywenderlich 家的这篇 [AutoLayout 教程](http://www.raywenderlich.com/50317/beginning-auto-layout-tutorial-in-ios-7-part-1)开始你的 IB 之旅。
