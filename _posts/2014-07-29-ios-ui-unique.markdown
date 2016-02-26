---
layout: post
title: WWDC 2014 Session笔记 - iOS界面开发的大一统
date: 2014-07-29 10:54:18.000000000 +09:00
tags: 能工巧匠集
---
![size-classes](/assets/images/2014/size-classes-header.png)

本文是我的 [WWDC 2014 笔记](http://onevcat.com/2014/07/developer-should-know-about-ios8/) 中的一篇，涉及的 Session 有

* [What's New in Cocoa Touch](http://devstreaming.apple.com/videos/wwdc/2014/202xx3ane09vxdz/202/202_hd_whats_new_in_cocoa_touch.mov?dl=1)
* [Building Adaptive Apps with UIKit](http://devstreaming.apple.com/videos/wwdc/2014/216xxcnxc6wnkf3/216/216_hd_building_adaptive_apps_with_uikit.mov?dl=1)
* [What's New in Interface Builder](http://devstreaming.apple.com/videos/wwdc/2014/411xx0xo98zzoor/411/411_hd_whats_new_in_interface_builder.mov?dl=1)
* [View Controller Advancements in iOS 8](http://devstreaming.apple.com/videos/wwdc/2014/214xxq2mdbtmp23/214/214_hd_view_controller_advancements_in_ios_8.mov?dl=1)
* [A Look Inside Presentation Controllers](http://devstreaming.apple.com/videos/wwdc/2014/228xxnfgueiskhi/228/228_hd_a_look_inside_presentation_controllers.mov?dl=1)

iOS 8 和 OS X 10.10 中一个被强调了多次的主题就是大一统，Apple 希望通过 Hand-off 和各种体验的无缝切换和集成将用户黏在由 Apple 设备构成的生态圈中。而对开发者而言，今年除了 Swift 的一个大主题也是平台的统一。在 What's New in Cocoa Touch 的 Seesion 一开始，UIKit 的工程师 Luke 就指出了 iOS 8 SDK 的最重要的关键字就是自适应 (adaptivity)。这是一个很激动人心的词，首先自适应是一种设计哲学，尽量使事情保持简单，我们便可从中擢取优雅；另一方面，可能这也是 Apple 不得不做的转变。随着传说中的更大屏和超大屏的 iPhone 6 的到来，开发者在为 iOS 进行开发的时候似乎也开始面临着和安卓一样的设备尺寸的碎片化的问题。而 iOS 8 所着重希望解决的，就是这一问题。

## Size Classes

首先最值得一说的是，iOS 8 应用在界面设计时，迎来了一个可以说是革命性的变化 - Size Classes。

### 基本概念

在 iPad 和 iPhone 5 出现之前，iOS 设备就只有一种尺寸。我们在做屏幕适配时需要考虑的仅仅有设备方向而已。而很多应用并不支持转向，这样的话就完全没有屏幕适配的工作了。随着 iPad 和 iPhone 5，以及接下来的 iPhone 6 的推出，屏幕尺寸也变成了需要考虑的对象。在 iOS 7 之前，为一个应用，特别是 universal 的应用制作 UI 时，我们总会首先想我们的目标设备的长宽各是多少，方向变换以后布局又应该怎么改变，然后进行布局。iOS 6 引入了 Auto Layout 来帮助开发者使用约束进行布局，这使得在某些情况下我们不再需要考虑尺寸，而可以专注于使用约束来规定位置。

既然我们有了 Auto Layout，那么其实通过约束来指定视图的位置和尺寸是没有什么问题的了，从这个方面来说，屏幕的具体的尺寸和方向已经不那么重要了。但是实战中这还不够，Auto Layout 正如其名，只是一个根据约束来进行**布局**的方案，而在对应不同设备的具体情况下的体验上还有欠缺。一个最明显的问题是它不能根据设备类型来确定不同的交互体验。很多时候你还是需要判断设备到底是 iPhone 还是 iPad，以及现在的设备方向究竟是竖直还是水平来做出判断。这样的话我们还是难以彻底摆脱对于设备的判断和依赖，而之后如果有新的尺寸和设备出现的话，这种依赖关系显然显得十分脆弱的（想想要是有 iWatch 的话..）。

所以在 iOS 8 里，Apple 从最初的设计哲学上将原来的方式推翻了，并引入了一整套新的理念，来适应设备不断的发展。这就是 Size Classes。

不再根据设备屏幕的具体尺寸来进行区分，而是通过它们的感官表现，将其分为**普通** (Regular) 和**紧密** (Compact) 两个种类 (class)。开发者便可以无视具体的尺寸，而是对这这两类和它们的组合进行适配。这样不论在设计时还是代码上，我们都可以不再受限于具体的尺寸，而是变成遵循尺寸的视觉感官来进行适配。

![Size classes](/assets/images/2014/size-classes-1.jpg)

简单来说，现在的 iPad 不论横屏还是竖屏，两个方向均是 Regular 的；而对于 iPhone，竖屏时竖直方向为 Regular，水平方向是 Compact，而在横屏时两个方向都是 Compact。要注意的是，这里和谈到的设备和方向，都仅仅只是为了给大家一个直观的印象。相信随着设备的变化，这个分类也会发生变动和更新。Size Classes 的设计哲学就是尺寸无关，在实际中我们也应该尽量把具体的尺寸抛开脑后，而去尽快习惯和适应新的体系。

### UITraitCollection 和 UITraitEnvironment

为了表征 Size Classes，Apple 在 iOS 8 中引入了一个新的类，`UITraitCollection`。这个类封装了像水平和竖直方向的 Size Class 等信息。iOS 8 的 UIKit 中大多数 UI 的基础类 (包括 `UIScreen`，`UIWindow`，`UIViewController` 和 `UIView`) 都实现了 `UITraitEnvironment` 这个接口，通过其中的 `traitCollection` 这个属性，我们可以拿到对应的 `UITraitCollection` 对象，从而得知当前的 Size Class，并进一步确定界面的布局。

和 UIKit 中的响应者链正好相反，`traitCollection` 将会在 view hierarchy 中自上而下地进行传递。对于没有指定 `traitCollection` 的 UI 部件，将使用其父节点的 `traitCollection`。这在布局包含 childViewController 的界面的时候会相当有用。在 `UITraitEnvironment` 这个接口中另一个非常有用的是 `-traitCollectionDidChange:`。在 `traitCollection` 发生变化时，这个方法将被调用。在实际操作时，我们往往会在 ViewController 中重写 `-traitCollectionDidChange:` 或者 `-willTransitionToTraitCollection:withTransitionCoordinator:` 方法 (对于 ViewController 来说的话，后者也许是更好的选择，因为提供了转场上下文方便进行动画；但是对于普通的 View 来说就只有前面一个方法了)，然后在其中对当前的 `traitCollection` 进行判断，并进行重新布局以及动画。代码看起来大概会是这个样子：

```
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection 
              withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection 
                 withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        if (newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            //To Do: modify something for compact vertical size
        } else {
            //To Do: modify something for other vertical size
        }
        [self.view setNeedsLayout];
    } completion:nil];
}
```

在两个 To Do 中，我们应该删除或者添加或者更改不同条件下的 Auto Layout 约束 (当然，你也可以干其他任何你想做的事情)，然后调用 `-setNeedsLayout` 来在上下文中触发转移动画。如果你坚持用代码来处理的话，可能需要面临对于不同 Size Classes 来做移除旧的约束和添加新的约束这样的事情，可以说是很麻烦 (至少我觉得是麻烦的要死)。但是如果我们使用 IB 的话，这些事情和代码都可以省掉，我们可以非常方便地在 IB 中指定各种 Size Classes 的约束 (稍后会介绍如何使用 IB 来对应 Size Classes)。另外使用 IB 不仅可以节约成百上千行的布局代码，更可以从新的 Xcode 和 IB 中得到很多设计时就可以实时监视，查看并且调试的特性。可以说手写 UI 和使用 IB 设计的时间消耗和成本差距被进一步拉大，并且出现了很多手写 UI 无法实现，但是 IB 可以不假思索地完成的任务。从这个意义上来说，新的 IB 和 Size Classes 系统可以说无情地给手写代码判了个死缓。

另外，新的 API 和体系的引入也同时给很多我们熟悉的 UIViewController 的有关旋转的老朋友判了死刑，比如下面这些 API 都弃用了：

```
@property(nonatomic, readonly) UIInterfaceOrientation interfaceOrientation

- willRotateToInterfaceOrientation:duration:
- willAnimateRotationToInterfaceOrientation:duration:
- didRotateFromInterfaceOrientation:
- shouldAutomaticallyForwardRotationMethods
```

现在全部统一到了 `viewWillTransitionToSize:withTransitionCoordinator:`，旋转的概念不再被提倡使用。其实仔细想想，所谓旋转，不过就是一种 Size 的改变而已，我们都被 Apple 骗了好多年，不是么？

Farewell, I will NOT miss you at all.

### 在 Interface Builder 中使用 Size Classes

第一次接触 Xcode 6 和打开 IB 的时候你可能会惊呼，为什么我的画布变成正方形了。我在第一天 Keynote 结束后在 Moscone Center 的食堂里第一次打开的时候，还满以为自己找到了 iWatch 方形显示屏的确凿证据。到后来才知道，这是新的 Size Classes 对应的编辑方式。

既然我们不需要关心实际的具体尺寸，那么我们也就完全没有必要在 IB 中使用像 3.5/4 寸的 iPhone 或是 10 寸的 iPad 来分开对界面进行编辑。使用一个通用的具有 "代表" 性质的尺寸在新体系中确实更不容易使人迷惑。

在现在的 IB 界面的正下方，你可以看到一个 `wAny hAny` 的按钮 (因为今年 NDA 的一个明确限制是不能发相关软件截图，虽然其实可能没什么太大问题，但是还是尊重 license 比较好)，这代表现在的 IB 是对应任意高度和任意宽度的。点击后便可以选择需要为哪种 Size Class 进行编辑。默认情况在 Any Any 下的修改会对任意设备和任意方向生效，而如果先进行选择后再进行编辑，就表示编辑只对选中的设定生效。这样我们就很容易在同一个 storyboard 文件里对不同的设备进行适配：按照设备需要添加或者编辑某些约束，或者是在特定尺寸下隐藏某些 view (使用 Attribute Inspector 里的 `Installed` 选框的加号添加)。这使得使用 IB 制作通用程序变简单了，我们不再需要为 iPhone 和 iPad 准备两套 storyboard 了。

可以发挥的想象空间实在太大，一套界面布局通吃所有设备的画面太美好，我都不敢想。

### Size Classes 和 Image Asset 及 UIAppearence

Image Asset 里也加入了对 Size Classes 的支持，也就是说，我们可以对不同的 Size Class 指定不同的图片了。在 Image Asset 的编辑面板中选择某张图片，Inspector 里现在多了一个 Width 和 Height 的组合，添加我们需要对应的 Size Class， 然后把合适的图拖上去，这样在运行时 SDK 就将从中挑选对应的 Size 的图进行替换了。不仅如此，在 IB 中我们也可以选择对应的 size 来直接在编辑时查看变化(新的 Xcode 和 IB 添加了非常多编辑时的可视化特性，关于这方面我有计划单独写一篇可视化开发的文章进行说明)。

这个特性一个最有用的地方在于对于不同屏幕尺寸可能我们需要的图像尺寸也有所不同。比如我们希望在 iPhone 竖屏或者 iPad 时的按钮高一些，而 iPhone 横屏时由于屏幕高度实在有限，我们希望得到一个扁一些的按钮。对于纯色按钮我们可以通过简单的约束和拉伸来实现，但是对于有图案的按钮，我们之前可能就需要在 VC 里写一些脏代码来处理了。现在，只需要指定好特定的 Image Asset，然后配置合适的 (比如不含有尺寸限制) 约束，我们就可以一行代码不写，就完成这样复杂的各个机型和方向的适配了。

实际做起来实在是太简单了..但拿个 demo 说明一下吧，比如下面这个实现了竖直方向 Compact 的时候将笑脸换成哭脸 -- 当然了，一行代码都不需要。

![根据 Size Classes 指定图片](/assets/images/2014/size-classes-2.gif)

另外，在 iOS 7 中 UIImage 添加了一个 `renderingMode` 属性。我们可以使用 `imageWithRenderingMode:` 并传入一个合适的 `UIImageRenderingMode` 来指定这个 image 要不要以 [Template 的方式进行渲染](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/UIKitUICatalog/index.html#//apple_ref/doc/uid/TP40012857-UIView-SW7)。在新的 Xcode 中，我们可以直接在 Image Asset 里的 `Render As` 选项来指定是不是需要作为 template 使用。而相应的，在 `UIApperance` 中，Apple 也为我们对于 Size Classes 添加了相应的方法。使用 `+appearanceForTraitCollection:` 方法，我们就可以针对不同 trait 下的应用的 apperance 进行很简单的设定。比如在上面的例子中，我们想让笑脸是绿色，而哭脸是红色的话，不要太简单。首先在 Image Asset 里的渲染选项设置为 `Template Image`，然后直接在 `AppDelegate` 里加上这样两行：

```
UIView.appearanceForTraitCollection(UITraitCollection(verticalSizeClass:.Compact)).tintColor = UIColor.redColor()
UIView.appearanceForTraitCollection(UITraitCollection(verticalSizeClass:.Regular)).tintColor = UIColor.greenColor()
```
![image](/assets/images/2014/size-classes-3.gif)

完成，只不过拖拖鼠标，两行简单的代码，随后还能随喜换色，果然是大快所有人心的大好事。

## UIViewController 的表现方式

### UISplitViewController

在用 Regular 和 Compact 统一了 IB 界面设计之后，Apple 的工程师可能发现了一个让人两难的历史问题，这就是 `UISplitViewController`。一直做 iPhone 而没太涉及 iPad 的童鞋可能对着这个类不是很熟悉，因为它们是 iPad Only 的。iPad 推出时为了适应突然变大的屏幕，并且远离 "放大版 iTouch" 的诟病，Apple 为 iPad 专门设计了这个主从关系的 ViewControlle容器。事实也证明了这个设计在 iPad 上确实是被广泛使用，是非常成功的。

现在的问题是，如果我们只有一套 UI 画布的话，我们要怎么在这个单一的画布上处理和表现这个 iPad Only 的类呢？

答案是，让它在 iPhone 上也能用就行了。没错，现在你可以直接在 iPhone 上使用 SplitViewController 了。在 Regular 的宽度时，它保持原来的特性，在 DetailViewController 中显示内容，这是毫无疑问的。而在 Compact 中，我们第一想法就是以 push 的表现形式展示。在以前，我们可能需要写不少代码来处理这些事情，比如在 AppDelegate 中就在一开始判断设备是不是 iPad，然后为应用设定两套完全不同的导航：一套基于 `UINavigationController`，另一套基于 `UISplitViewController`。而现在我们只需要一套 `UISplitViewController`，并将它的 MasterViewController 设定为一个 navgationController 就可以轻松搞定所有情况了。

也许你会想，即使这样，我是不是还是需要判断设备是不是 iPad，或者现在的话是判断 Size Class 是不是 Compact，来决定是要做的到底是 navVC 的 push 还是改变 splitVC 的 viewControllers。其实不用，我们现在可以无痛地不加判断，直接用统一的方式来完成两种表现方式。这其中的奥妙在于我们不需要使用 (事实上 iOS 8 后 Apple 也不再提倡使用) `UINavigationController` 的  `pushViewController:animated:` 方法了 (又一个老朋友要和我们说再见了)。其实虽然很常用，但是这个方法是一直受到社区的议论的：因为正是这个方法的存在使得 ViewController 的耦合特性上了一个档次。在某个 ViewController 中这个方法的存在时，就意味着我们需要确保当前的 ViewController 必须处于一个导航栈的上下文中，这是完全和上下文耦合的一种方式 (虽然我们也可以很蛋疼地用判断 `navController` 是不是 `nil` 来绕开，但是毕竟真的很丑，不是么)。

我们现在有了新的展示 viewController 的方法，`-showViewController:sender:` 以及 `-showDetailViewController:sender:`。调用这两个方法时，将顺着包括调用 vc 自身的响应链而上，寻找最近的实现了这个方法的 ViewController 来执行相应代码。在 iOS SDK 的默认实现中，在 `UISplitViewController` 这样的容器类中，已经有这两个方法的实现方式，而 `UINavigationController` 也实现了 `-showViewController:sender:` 的版本。对于在 navController 栈中的 vc，会调用 push 方式进行展示，而对 splitVC，`showViewController:sender:` 将在 MasterViewController 中进行 push。而 `showDetailViewController:sender:` 将根据水平方向的 Size 的情况进行选择：对于 Regular 的情况，将在 DetailViewController 中显示新的 vc，而对于 Compact 的情况，将由所在上下文情况发回给下级的 navController 或者是直接以 modal 的方式展现。关于这部分的具体内容，可以仔细看看这个[示例项目](https://developer.apple.com/devcenter/download.action?path=/wwdc_2014/wwdc_2014_sample_code/adaptivephotosanadaptiveapplication.zip)和相关的[文档 (beta版)](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UISplitViewController_class/)。

这么设计的好处是显而易见的，首先是解除了原来的耦合，使得我们的 ViewController 可以不被局限于导航控制器上下文中；另外，这几个方法都是公开的，也就是说我们的 ViewController 可以实现这两个方法，截断响应链的响应，并实现我们自己的呈现方式。这在自定义 Container Controller 的时候会非常有用。

### UIPresentationController

iOS 7 中加入了一套实现非常漂亮的自定义转场动画的方法 (如果你还不知道或者不记得了，可以看看我去年的[这篇笔记](http://onevcat.com/2013/10/vc-transition-in-ios7/))。Apple 在解耦和重用上的努力确实令人惊叹。而今年，顺着自适应和平台开发统一的东风，在呈现 ViewController 的方式上 Apple 也做出了从 iOS SDK 诞生以来最大的改变。iOS 8 中新加入了一个非常重要的类 `UIPresentationController`，这个 `NSObject` 的子类将用来管理所有的 ViewController 的呈现。在实现方式上，这个类和去年的自定义转场的几个类一样，是完全解耦合的。而 Apple 也在自己的各种 viewController 呈现上完全统一地使用了这个类。

#### 再见 UIPopoverController

和 SplitViewController 类似，`UIPopoverController` 原来也只是 iPad 使用的，现在 iPhone 上也将适用。准确地说，现在我们不再使用 `UIPopoverController` 这个类 (虽然现在文档还没有将其标为 deprecated，但是估计也是迟早的事儿了)，而是改用一个新的类 `UIPopoverPresentationController`。这是 `UIPresentationController` 的子类，专门用来负责呈现以 popover 的形式呈现内容，是 iOS 8 中用来替代原有的 `UIPopoverController` 的类。

比起原来的类，新的方式有什么优点呢？最大的优势是自适应，这和 `UISplitViewController` 在 iOS 8 下的表现是类似的。在 Compact 的宽度条件下，`UIPopoverPresentationController` 的呈现将会直接变成 modal 出来。这样我们基本就不再需要去判断 iPhone 还是 iPad (其实相关的判定方法也已经被标记成弃用了)，就可以对应不同的设备了。以前我们可能要写类似这样的代码：

```
if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
    let popOverController = UIPopoverController(contentViewController: nextVC)
    popOverController.presentPopoverFromRect(aRect, inView: self.view, permittedArrowDirections: .Any, animated: true)
} else {
    presentViewController(nextVC, animated: true, completion: nil)
}
```

而现在需要做的是：

```
nextVC.modalPresentationStyle = .Popover
let popover = nextVC.popoverPresentationController
popover.sourceRect = aRect
popover.permittedArrowDirections = .Any
        
presentViewController(nextVC, animated: true, completion: nil)
```

没有可恶的条件判断，一切配置井井有条，可读性也非常好。

除了自适应之外，新方式的另一个优点是非常容易自定义。我们可以通过继承 `UIPopoverPresentationController` 来实现我们自己想要的呈现方式。其实更准确地说，我们应该继承的是 `UIPresentationController`，主要通过实现 `-presentationTransitionWillBegin` 和 `-presentationTransitionDidEnd:` 来自定义我们的展示。像以前我们想要实现只占半个屏幕，后面原来的 view 还可见的 modal，或者是将从下到上的动画改为百叶窗或者渐隐渐现，那都是可费劲儿的事情。而在 `UIPresentationController` 的帮助下，一切变得十分自然和简单。在自己的 `UIPresentationController` 子类中：

```
override func presentationTransitionWillBegin() {
    let transitionCoordinator = self.presentingViewController.transitionCoordinator()
    transitionCoordinator.animateAlongsideTransition({context in
        //Do animation here
    }, completion: nil)
}
    
override func presentationTransitionDidEnd(completed: Bool)  {
    //Do clean here
}
```

具体的用法和 iOS 7 里的自定义转场很类似，设定需要进行呈现操作的 ViewController 的 transition delegate，在 `UIViewControllerTransitioningDelegate` 的 `-presentationControllerForPresentedViewController:sourceViewController:` 方法中使用 `-initWithPresentedViewController:presentingViewController:` 生成对应的 `UIPresentationController` 子类对象返回给 SDK，然后就可以喝茶看戏了。

#### 再见 UIAlertView， 再见 UIActionSheet

自适应和 `UIPresentationController` 给我们带来的另一个大变化是 `UIAlertView` 和 `UIActionSheet` 这两个类的消亡 (好吧其实算不上消亡，弃用而已)。现在，Alert 和 ActionSheet 的呈现也通过 `UIPresentationController` 来实现。原来在没有 Size Class 和需要处理旋转的黑暗年代 (抱歉在这里用了这个词，但是我真的一点也不怀念那段处理设备旋转的时光) 里，把这两个 view 显示出来其实幕后是一堆恶心的事情：创建新的 window，处理新 window 的大小和方向，然后将 alert 或者 action sheet 按合适的大小和方向加到窗口上，然后还要考虑处理转向，最后显示出来。虽然 Apple 帮我们做了这些事情，但是轮到我们使用时，往往它们也只能满足最基本的需求。在适配 iPhone 和 iPad 时，`UIAlertView` 还好，但是对于 `UIActionSheet` 我们往往又得进行不同处理，来选择是不是需要 popover。

另外一个要命的地方是因为这两个类是 iOS 2.0 开始就存在的爷爷级的类了，而最近一直也没什么大的更新，设计模式上还使用的是传统的 delegate 那一套东西。实际上对于这种很轻很明确的使用逻辑，block handler 才是最好的选择，君不见满 GitHub 的 block alert view 的代码，但是没辙，4.0 才出现的 block 一直由于种种原因，在这两个类中一直没有得到官方的认可和使用。

而作为替代品的 `UIAlertController` 正是为了解决这些问题而出现的，值得注意的是，这是一个 `UIViewController` 的子类。可能你会问 `UIAlertController` 对应替代 `UIAlertView`，这很好，但是 `UIActionSheet` 怎么办呢？哈..答案是也用 `UIAlertController`，在 `UIAlertController` 中有一个 `preferredStyle` 的属性，暂时给我们提供了两种选择 `ActionSheet` 和 `Alert`。在实际使用时，这个类的 API 还是很简单的，使用工厂方法创建对象，进行配置后直接 present 出来：

```
let alert = UIAlertController(title: "Test", message: "Msg", preferredStyle: .Alert)

let okAction = UIAlertAction(title: "OK", style: .Default) {
    [weak alert] action in
    print("OK Pressed")
    alert!.dismissViewControllerAnimated(true, completion: nil)
}
alert.addAction(okAction)
presentViewController(alert, animated: true, completion: nil)
```

使用上除了小心循环引用以外，并没有太多好说的。在 Alert 上加文本输入也变得非常简单了，使用 `-addTextFieldWithConfigurationHandler:` 每次向其上添加一个文本输入，然后在 handler 里拿数据就好了。

要记住的是，在幕后，做呈现的还是 `UIPresentationController`。

#### UISearchDisplayController -> UISearchController

最后想简单提一下在做搜索栏的时候的同样类似的改变。在 iOS 8 之前做搜索栏简直是一件让人崩溃的事情，而现在我们不再需要讨厌的 `UISearchDisplayController` 了，也没有莫名其妙的在视图树中强制插入 view 了 (如果你做过搜索栏，应该知道我在说什么)。这一切在 iOS 8 中也和前面说到的 alert 和 actionSheet 一样，被一个 `UIViewController` 的子类 `UISearchController` 替代了。背后的呈现机制自然也是 `UIPresentationController`，可见新的这个类在 iOS 8 中的重要性。

## 总结

对于广大 iOS 开发者赖以生存的 UIKit 来说，这次最大的变化就是 Size Classes 的引入和新的 Presentation 系统了。在 Keynote 上 Craig 就告诉我们，iOS 8 SDK 将是 iOS 开发诞生以来最大的一次变革，此言不虚。虽然 iOS 8 SDK 的广泛使用估计还有要有个两年时间，但是不同设备的开发的 API 的统一这一步已然迈出，这也正是 Apple 之后的发展方向。正如两年前的 Auto Layout 正在今天大放光彩一样，之后 Size Classes 和新的 ViewController 也必将成为日常开发的主力工具。

程序员嘛，果然需要每年不断学习，才能跟上时代。
