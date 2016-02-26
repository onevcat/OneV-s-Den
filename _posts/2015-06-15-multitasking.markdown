---
layout: post
title: WWDC15 Session笔记 - iOS 9 多任务分屏要点
date: 2015-06-15 16:25:07.000000000 +09:00
tags: 能工巧匠集
---
本文是我的 [WWDC15 笔记](http://onevcat.com/2015/06/ios9-sdk/)中的一篇，涉及的 Session 有

- [Getting Started with Multitasking on iPad in iOS 9](https://developer.apple.com/videos/wwdc/2015/?id=205)
- [Multitasking Essentials for Media-Based Apps on iPad in iOS 9](https://developer.apple.com/videos/wwdc/2015/?id=211)
- [Optimizing Your App for Multitasking on iPad in iOS 9](https://developer.apple.com/videos/wwdc/2015/?id=212)

### iOS 9 多任务综述

iOS 9 中最引人注目的新特性就是多任务了，在很久以前的越狱开发里就已经出现过类似的插件，而像是 Windows Surface 系列上也已经有分屏多任务的特性，可以让用户同时使用两个或多个 app。iOS 9 中也新加入类似的特性。iOS 9 中的多任务有三种表现形式，临时出现和交互的滑动覆盖 (Slide Over)，真正的分屏同时操作两个 app 的分割视图 (Split View)，以及在其他 app 里依然可以进行视频播放的画中画 (Picture in Picture) 模式。

![](/assets/images/2015/multitasking-1.jpg)

在关于多任务的文档中，Apple 明确指出：

> 绝大部分 app 都应当适配 Slide Over 和 Split View

因为这正是 iOS 9 的核心功能之一，也是你的用户所期望看到的。另一方面，支持多任务也增加了你的用户打开和使用你的 app 的可能。不过多任务有一点限制，那就是在能够安装 iOS 9 的 iPad 设备上，仅只有性能最强大的 iPad Air 2 和之后的机型支持分割视图模式，而其他像是 iPad mini 2，iPad mini 3 以及 iPad Air 只支持滑动覆盖和画中画两种模式。这在一定程度上应该还是基于移动设备资源和性能限制的考虑做出的决策，毕竟要保证良好的使用体验为前提，多任务才会有意义。

对于开发者来说，虽然多种布局看起来很复杂，但是实际上如果紧跟 Apple 的技术步伐的话，将自己的 iPad app 进行多任务适配并不会是一件非常困难的事情。因为滑动覆盖模式和分割视图模式所采用的布局其实就是 Compact Width 的布局，而这一概念就是 WWDC14 上引入的基于屏幕特征的 UI 布局方式。如果你已经在使用这套布局方式了的话，那么可以说多任务视图的支持也就顺带自动完成了。不过如果你完全没有使用过甚至没有听说过这套布局方法的话，我去年的[一篇笔记](http://onevcat.com/2014/07/ios-ui-unique/)可能能帮你对此有初步了解，在下一节里我也会稍微再稍微复习一下相关概念和基本用法。

### Adaptive UI 复习

Adaptive UI 是 Apple 在 iOS 8 提出的概念。在此之前，我们如果想要同时为 iPhone 和 iPad 开发 app 的话，很可能会写很多设备判断的代码，比如这样：

```swifts
if UI_USER_INTERFACE_IDIOM() == .Pad {
    // 设备是 iPad
}
```

除此之外，如果我们想要同时适配横向和纵向的话，我们会需要类似这样的代码：

```swift
if UIInterfaceOrientationIsPortrait(orientation) {
    // 屏幕是竖屏
}
```

这些判断和分支不仅难写难读，也使适配开发困难重重。从 iOS 8 之后，开发者不应该再依赖这样设备向来进行 UI 适配，而应该转而使用新的 Size Class 体系。Apple 将自家的移动设备按照尺寸区别，将纵横两个方向设计了 Regular 和 Compact 的组合。比如 iPhone 在竖屏时宽度是 Compact，高度是 Regular，横屏时 iPhone 6 Plus 宽度是 Regular，高度是 Compact，而其他 iPhone 在横屏时高度和宽度都是 Compact；iPad 不论型号和方向，宽度及高度都是 Regular。现有的设备的 Size Class 如下图所示：

![](/assets/images/2015/multitasking-2.jpg)

针对 Size Class 进行开发的思想下，我们不再关心具体设备的型号或者尺寸，而是根据特定的 Size Class 的特性来展示内容。在 Regular 的宽度下，我们可以在水平方向上展示更多的内容，比如同时显示 Master 和 Detail View Controller 等。同样地，我们也不应该再关心设备旋转的问题，而是转而关心 Size Class 的变化。在开发时，如果是使用 Interface Builder 的话，在制作 UI 时就注意为不同的 Size Class 配置合适的约束和布局，在大多数情况下就已经足够了。如果使用代码的话，`UITraitCollection` 类将是使用和操作 Size Class 的关键。我们可以根据当前工作的 `UIViewController` 的 `traitCollection` 属性来设置合适的布局，并且在 `
-willTransitionToTraitCollection:withTransitionCoordinator:` 和 `
-viewWillTransitionToSize:withTransitionCoordinator:` 被调用时对 UI 布局做出正确的响应。

虽然并不是理论上不可行，但是使用纯手写来操作 Size Class 会是一件异常痛苦的事情，我们还是应该尽可能地使用 IB 来减少这部分的工作量，加快开发效率。

### iPad 中的多任务适配

对于 iOS 9 中的多任务，滑动覆盖和分割视图的初始位置，新打开的 app 的尺寸都将是设备尺寸的 1/3。不过这个比例并不重要，我们需要记住的是新打开的 app 将运行在 Compact Width 和 Regular Height 的 Size Class 下。也就是说，如果你的 iPad app 使用了 Size Class 进行布局，并且是支持 iPhone 竖屏的，那么恭喜，你只需要换到 iOS 9 SDK 并且重新编译你的 app，就搞定了。

因为本文的重点不是教你怎么开发一个 Adaptive UI 的 app，所以并不打算在这方面深入下去。如果你在去年缺了课，不是很了解这方面的话，[这篇教程](http://www.raywenderlich.com/83276/beginning-adaptive-layout-tutorial)可能可以帮你快速了解并掌握这些内容。如果你想要直接上手看看 iOS 9 中的 多任务是如何工作的话，可以新建一个 Master-Detail Application，并将其安装到 iPad 模拟器上。Master-Detail 的模板工程为我们搭设了一个很好的适配 Size Class 的框架，让项目可以在任何设备上都表现良好。同样你也可以观察它在 iOS 9 的 iPad 上的表现。

但是其实并不是所有的 app 都应该适配多任务，比如一个需要全屏才能体验的游戏就是典型。如果你不想你的 app 可以作为多任务的副 app 被使用的话，你可以在 Info.plist 中添加 `UIRequiresFullScreen` 并将其设为 `true`。

Easy enough？没错，要适配 iPad 的多任务，你需要做的就只有按照标准流程开发一个全平台通用 app，仅此而已。

1. 使用 iOS 9 SDK 构建你的 app；
2. 支持所有的方向和对应的 Size Class；
3. 使用 launch storyboard 作为 app 启动页面。

虽说没太多特别值得一提的内容，但是也还是有一些需要注意的小细节。

### 一些值得注意的小细节

在以前是不存在 app 在前台还要和别的 app 共享屏幕这种事情的，所以 `UIScreen.bounds` 和主窗口的 `UIWindow.bounds` 使用上来说基本是同义词。但是在多任务时代，`UIWindow` 就有可能只有 1/3 或者 1/2 屏幕大小了。如果你在之前的 app 中有使用它来定义你的视图的话，就有必要为多任务做特殊的处理了。不过虽然滑动覆盖和分割视图都是在右侧展示，但是它们的 Window 的 origin 依然是 (0, 0)，这也方便了我们定义视图。

第二个细节是现在 iPad UI 的 Size Class 是会发生变化的。以前不论是竖直还是水平，iPad 屏幕的 Size 总是长宽均为 Regular 的。但是在 iOS 9 中情况就不一样了，你的 app 可能被作为附加 app 通过多任务模式打开，可能会在多任务时被用户拖动从而变成全屏 app (这时 Size Class 将从 Compact 的宽度变为 Regular)，甚至可能你的 app 作为主 app 被使用是会因为用户拖动而变成 Compact 宽度的 app：

![](/assets/images/2015/size_classes.png)

换句话说，你不知道你的 app 的 Size Class 会不会变化，以及何时变化，这都是用户操作的结果。因此在开发时，就必须充分考虑到这一点，力求在尺寸变化时呈现给用户良好的效果。根据屏幕大小进行合适的 UI 设计和调整自不用说，另外还应当注意在合适的时机利用 `transitionCoordinator` 的 `-animateAlongsideTransition:` 来进行布局动画，让切换更加自然。

由于多任务带来了多个 app 同台运行的可能性，因此你的 app 必定会面临和别的 app 一起运行的情况。在开发移动应用时永远不能忘记的是设备平台的限制。相比于桌面设备，移动端只有有限的内存，而两个甚至三个 app 同时在前台运行，就需要我们精心设计内存的使用。对于一般开发者来说，合理地分配内存，监听 Memory Warning 来释放 cache 和不必要的 view controller，避免循环引用等等，应该成为熟练掌握的日常开发基本功。

最后一个细节是对完美的苛求了。在 iOS 9 中多任务也通过 App Switcher 来进行 app 之间的切换的。所以在你的 app 被切换到后台时，系统会保存你的 app 的当前状态的截图，以供之后切换时显示。你的 app 现在有可能被作为 Regular 的全屏 app 使用，也可能使用 Compact 布局，所以在截图时系统也会依次保存两份截图。用户可能会在全屏模式下把你的 app 关闭，然后通过多任务再将你的 app 作为附加 app 打开，这时最好能保证 App Switcher 中的截图和 app 打开后用户看到的截图一致，以获取最好的体验。可能这并不是一个很大的问题，但是如果追求极致的用户体验的话，这也是必行的。对于那些含有用户敏感数据，需要将截图模糊处理的 app，现在也需要注意同时将两种布局的截图都进行处理。

### 画中画模式

iOS 9 中多任务的另一种表现形式就是视频的画中画模式：即使退出了，你的视频 app 也可以在用户使用别的 app 的时候保持播放，比如一边看美剧一边写日记或者发邮件。这大概会是所有的视频类 app 都必须要支持的特性了，实现起来也很容易：

1. 使用 iOS 9 SDK 构建你的 app；
2. 在 app 的 Capabilities 里，将 Background Modes 的 "Audio, AirPlay, and Picture in Picture" 勾选上 (Xcode 7 beta 中暂时为 "Audio and AirPlay")；
3. 将 AudioSession Catogory [设置为合适的选项](https://gist.github.com/onevcat/82defadf559968c6a3bc)，比如 `AVAudioSessionCategoryPlayback`
4. 使用 AVKit，AVFoundation 或者 WebKit 框架来播放视频。

在 iOS 9 中，一直伴随我们的 MediaPlayer 框架中的视频播放部分正式宣布寿终正寝。也就是说，如果你在使用 `MPMoviePlayerViewController` 或者 `MPMoviePlayerController` 在播放视频的话，你就无法使用画中画的特性了，因此尽快转型到新的视频播放框架会是急迫的适配任务。因为画中画模式是基于 `AVPlayerLayer` 的。当切换到画中画时，会将正在播放视频的 layer 取出，然后进行缩小后添加到新的界面的 layer 上。这也是旧的 MediaPlayer 框架无法支持画中画的主要原因。

如果你使用 `AVPlayerViewController` 的话，一旦满足这些简单的条件以后，你应该就可以在使用相应框架全屏播放视频时看到右下角的画中画按钮了。不论是点击这个按钮进入画中画模式还是直接使用 Home 键切换到后台，已经在播放的视频就将缩小到屏幕右下角成为画中画，并保持播放。在画中画模式下，系统会在视频的 AVPlayerLayer 上添加一套默认控件，用来控制暂停/继续，关闭，以及返回 app。前两个控制没什么可多说的，返回 app 的话需要我们自己处理返回后的操作。一般来说我们希望能够恢复到全屏模式并且继续播放这个视频，因为 `AVPlayerViewController` 进行播放时我们一般不会去操作 `AVPlayerLayer`，在恢复时就需要实现 `AVPlayerViewControllerDelegate` 中的 `-playerViewController:restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:` 来根据传入的 ViewController 重建 UI，并将 `true` 通过 CompletionHandler 返回给系统，已告知系统恢复成功 (当然如果无法恢复的话需要传递 false)。

我们也可以直接用 `AVPlayerLayer` 来构建的自定义的播放器。这时我们需要通过传入所使用的 `AVPlayerLayer` 来创建一个 `AVPictureInPictureController`。`AVPictureInPictureController` 提供了检查是否支持画中画模式的 API，以及其他一些控制画中画行为的方法。与直接使用 `AVPlayerViewController` 不太一样的是，在恢复时，系统将会把画中画时缩小的 `AVPlayerLayer` 返还到之前的 view 上。我们可以通过 `AVPictureInPictureControllerDelegate` 中的相应方法来获知画中画的执行情况，并结合自己 app 的情况来恢复 UI。

### 总结

通过之前几年的布局，在 AutoLayout 和 Size Class 的基础上，Apple 在 iOS 9 中放出了多任务这一杀手锏。可以说同屏执行多个 app 的需求从初代 iPad 开始就一直存在，而现在总算是姗姗来迟。在 OS X 10.11 中，Apple 也将类似的特性引入了 OSX app 的全屏模式中，可以说是统一 OSX 和 iOS 这两个平台的进一步尝试。

但是 iPad 上的多任务还是有一些不足的。最大的问题是 app 依然是运行在沙盒中的，这就意味着在 iOS 上我们还是无法在两个 app 之间进行通讯：比如同时打开照片和一个笔记 app，我们无法通过拖拽方式将某张图片直接拖到笔记中去。虽然在 iOS 中也有 [XPC 服务](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html)，但是第三方开发者现在并不能使用，这在一定程度上还是限制了多任务的可能性。

不过总体来说，多任务特性使得 iPad 的实用性大大上升，这也肯定会是未来用户最常用以及最希望在 app 中看到的特性之一。花一点时间，学习 Adaptive UI 的制作方式，让 app 支持多任务运行，会是一件很合算的事情。
