---
layout: post
title: 开发者所需要知道的iOS7 SDK新特性
date: 2013-06-11 00:45:02.000000000 +09:00
tags: 能工巧匠集
---

![iOS 7](/assets/images/2013/ios-7-logo.png)

春风又绿加州岸，物是人非又一年。WWDC 2013 keynote落下帷幕，新的iOS开发旅程也由此开启。在iOS7界面重大变革的背后，开发者们需要知道的又有哪些呢。同去年一样，我会先简单纵览地介绍iOS7中我个人认为开发者需要着重关注和学习的内容，之后再陆续对自己感兴趣章节进行探索。计划继承类似[WWDC2012的笔记](http://onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)的形式，希望对国内开发者有所帮助。

相关笔记整理如下：

* 总览 [开发者所需要知道的iOS7 SDK新特性](http://onevcat.com/2013/06/developer-should-know-about-ios7/)
* 工具 [WWDC2013笔记 Xcode5和ObjC新特性](http://onevcat.com/2013/06/new-in-xcode5-and-objc/) 
* UIKit动力学 [WWDC2013笔记 UIKit力学模型入门](http://onevcat.com/2013/06/uikit-dynamics-started/)
* SpriteKit入门 [WWDC2013笔记 SpriteKit快速入门和新时代iOS游戏开发指南](http://onevcat.com/2013/06/sprite-kit-start/)
* 后台应用运行和多任务新特性 [WWDC2013笔记 iOS7中的多任务](http://onevcat.com/2013/08/ios7-background-multitask/)
* iOS7中弹簧式列表的制作 [WWDC 2013 Session笔记 - iOS7中弹簧式列表的制作](http://onevcat.com/2013/09/spring-list-like-ios7-message) 
* iOS7中自定义ViewController切换效果 [WWDC 2013 Session笔记 - iOS7中的ViewController切换](http://onevcat.com/2013/10/vc-transition-in-ios7/)

---

### UI相关
#### 全新UI设计
iOS7最大的变化莫过于UI设计，也许你会说UI设计“这是设计师大大们应该关注的事情，不关开发者的事，我们只需要替换图片就行了”。那你就错了。UI的变化必然带来使用习惯和方式的转变，如何运用iOS7的UI，如何是自己的应用更切合新的系统，都是需要考虑的事情。另外值得注意的是，使用iOS7 SDK（现在只有Xcode5预览版提供）打包的应用在iOS7上运行时将会自动使用iOS7的新界面，所以原有应用可能需要对新界面进行重大调整。具体的iOS7中所使用的UI元素的人际交互界面文档，可以从[这里](https://developer.apple.com/library/prerelease/ios/design/index.html#//apple_ref/doc/uid/TP40013289)找到（应该是需要开发者账号才能看）。


简单总结来说，以现在上手体验看来新的UI变化改进有如下几点：

* 状态栏，导航栏和应用实际展示内容不再界限：系统自带的应用都不再区分状态栏和navigation bar，而是用统一的颜色力求简洁。这也算是一种趋势。
* BarItem的按钮全部文字化：这点做的相当坚决，所有的导航和工具条按钮都取消了拟物化，原来的文字（比如“Edit”，“Done”之类）改为了简单的文字，原来的图标（比如新建或者删除）也做了简化。
* 程序打开加入了动画：从主界面到图标所在位置的一个放大，同时显示应用的载入界面。

自己实验了几个现有的AppStore应用在iOS7上的运行情况：

* [Pomodoro Do](https://itunes.apple.com/app/id533469911?mt=8)： 这是我自己开发的应用，运行正常，但是因为不是iOS7 SDK打包，所以在UI上使用了之前系统的，问题是导航栏Tint颜色丢失，导致很难看，需要尽快更新。
* Facebook：因为使用了图片自定义导航栏，而没有直接使用系统提供的材质，所以没什么问题。
* 面包旅行：直接Crash，无法打开，原因未知。

这次UI大改可以说是一次对敏捷开发的检验，原来的应用（特别是拟物化用得比较重的应用）虽然也能运行，但是很多UI自定义的地方需要更改不说，还容易让用户产生一种“来到了另一个世界”的感觉，同时可以看到也有部分应用无法运行。而对于苹果的封闭系统和只升不降的特性，开发者以及其应用必须要尽快适应这个新系统，这对于迭代快速，还在继续维护的应用来说会是一个机会。相信谁先能适应新的UI，谁就将在iOS7上占到先机。

#### UIKit的力学模型（UIKit Dynamics）

这个专题的相关笔记

> UIKit动力学 [WWDC2013笔记 UIKit力学模型入门](http://onevcat.com/2013/06/uikit-dynamics-started/) http://onevcat.com/2013/06/uikit-dynamics-started/

新增了`UIDynamicItem`委托，用来为UIView制定力学模型行为，当然其他任何对象都能通过实现这组接口来定义动力学行为，只不过在UIKit中可能应用最多。所谓动力学行为，是指将现实世界的我们常见的力学行为或者特性引入到UI中，比如重力等。通过实现UIDynamicItem，UIKit现在支持如下行为：

* UIAttachmentBehavior 连接两个实现了UIDynamicItem的物体（以下简称动力物体），一个物体移动时，另一个跟随移动
* UICollisionBehavior 指定边界，使两个动力物体可以进行碰撞
* UIGravityBehavior 顾名思义，为动力物体增加重力模拟
* UIPushBehavior 为动力物体施加持续的力
* UISnapBehavior 为动力物体指定一个附着点，想象一下类似挂一幅画在图钉上的感觉

如果有开发游戏的童鞋可能会觉得这些很多都是做游戏时候的需求，一种box2d之类的2D物理引擎的既视感跃然而出。没错的亲，动态UI，加上之后要介绍的Sprite Kit，极大的扩展了使用UIKit进行游戏开发的可能性。另外要注意UIDynamicItem不仅适用于UIKit，任何对象都可以实现接口来获得动态物体的一些特性，所以说用来做一些3D的或者其他奇怪有趣的事情也不是没有可能。如果觉得Cocos2D+box2d这样的组合使用起来不方便的话，现在动态UIKit+SpriteKit给出了新的选择。

### 游戏方面

这个专题的相关笔记

> SpriteKit入门 [WWDC2013笔记 SpriteKit快速入门和新时代iOS游戏开发指南](http://onevcat.com/2013/06/sprite-kit-start/) http://onevcat.com/2013/06/sprite-kit-start/

iOS7 SDK极大加强了直接使用iOS SDK制作和分发游戏的体验，最主要的是引入了专门的游戏制作框架。

#### Sprite Kit Framework
这是个人认为iOS7 SDK最大的亮点，也是最重要的部分，iOS SDK终于有自己的精灵系统了。Sprite Kit Framework使用硬件加速的动画系统来表现2D和2.5D的游戏，它提供了制作游戏所需要的大部分的工具，包括图像渲染，动画系统，声音播放以及图像模拟的物理引擎。可以说这个框架是iOS SDK自带了一个较完备的2D游戏引擎，力图让开发者专注于更高层的实现和内容。和大多数游戏引擎一样，Sprite Kit内的内容都按照场景（Scene）来分开组织，一个场景可以包括贴图对象，视频，形状，粒子效果甚至是CoreImage滤镜等等。相对于现有的2D引擎来说，由于Sprite Kit是在系统层级进行的优化，渲染时间等都由框架决定，因此应该会有比较高的效率。

另外，Xcode还提供了创建粒子系统和贴图Atlas的工具。使用Xcode来管理粒子效果和贴图atlas，可以迅速在Sprite Kit中反应出来。

#### Game Controller Framework
为Made-for-iPhone/iPod/iPad (MFi) game controller设计的硬件的对应的框架，可以让用户用来连接和控制专门的游戏硬件。参考WWDC 2013开场视频中开始的赛车演示。现在想到的是，也许这货不仅可以用于游戏…或者苹果之后会扩展其应用，因为使用普及率很高的iPhone作为物联网的入口，似乎会是很有前途的事情。

#### GameCenter改进
GameCenter一直是苹果的败笔...虽然每年都在改进，但是一直没看到大的起色。今年也不例外，都是些小改动，不提也罢。

### 多任务强化

这个专题的相关笔记

> 后台应用运行和多任务新特性 [WWDC2013笔记 iOS7中的多任务](http://onevcat.com/2013/08/ios7-background-multitask/) http://onevcat.com/2013/08/ios7-background-multitask/

* 经常需要下载新内容的应用现在可以通过设置`UIBackgroundModes`为`fetch`来实现后台下载内容了，需要在AppDelegate里实现`setMinimumBackgroundFetchInterval:`以及`application:performFetchWithCompletionHandler: `来处理完成的下载，这个为后台运行代码提供了又一种选择。不过考虑到Apple如果继续严格审核的话，可能只有杂志报刊类应用能够取得这个权限吧。另外需要注意开发者仅只能指定一个最小间隔，最后下没下估计就得看系统娘的心情了。
* 同样是后台下载，以前只能推送提醒用户进入应用下载，现在可以接到推送并在后台下载。UIBackgroundModes设为remote-notification，并实现`application:didReceiveRemoteNotification:fetchCompletionHandler:`

为后台下载，开发者必须使用一个新的类`NSURLSession`，其实就是在NSURLConnection上加了个后台处理，使用类似，API十分简单，不再赘述。

### AirDrop
这个是iOS7的重头新功能，用户可以用它来分享照片，文档，链接，或者其他数据给附近的设备。但是不需要特别的实现，被集成在了标准的UIActivityViewController里，并没有单独的大块API提供。数据的话，可以通过实现UIActivityItemSource接口后进行发送。大概苹果也不愿意看到超出他们控制的文件分享功能吧，毕竟这和iOS设计的初衷不一样。如果你不使用UIActivityViewController的话，可能是无法在应用里实装AirDrop功能了。

另外，结合自定义的应用文件类型，可以容易地实现在后台接收到特定文件后使用自己的应用打开，也算是增加用户留存和回访的一个办法。但是这样做现在看来比较讨厌的是会有将所有文件都注册为可以打开的应用（比如Evernote或者Dropbox之类），导致接收到AirDrop发送的内容的时候会弹出很长一排选项，体验较差，只能说希望Apple以后能改进吧

### 地图
Apple在继续在地图应用上的探索，MapKit的改进也乏善可陈。我一直相信地图类应用的瓶颈一定在于数据，但是对于数据源的建立并不是一年两年能够完成的。Google在这一块凭借自己的搜索引擎有着得天独厚的优势，苹果还差的很远很远。看看有哪些新东西吧：

* MKMapCamera，可以将一个MKMapCamera对象添加到地图上，在指明位置，角度和方向后将呈现3D的样子…大概可以想象成一个数字版的Google街景..
* MKDirections 获取Apple提供的基于方向的路径，然后可以用来将路径绘制在自己的应用中。这可能对一些小的地图服务提供商产生冲击，但是还是那句话，地图是一个数据的世界，在拥有完备数据之前，Apple不是Google的对手。这个状况至少会持续好几年（也有可能是永远）。
* MKGeodesicPolyline 创建一个随地球曲率的线，并附加到地图上，完成一些视觉效果。
* MKMapSnapshotter 使用其拍摄基于地图的照片，也许各类签到类应用会用到
* 改变了overlay物件的渲染方式

### Inter-App Audio 应用间的音频
AudioUnit框架中加入了在同一台设备不同应用之间发送MIDI指令和传送音频的能力。比如在一个应用中使用AudioUnit录音，然后在另一个应用中打开以处理等。在音源应用中声明一个AURemoteIO实例来标为Inter-App可用，在目标应用中使用新的发现接口来发现并获取音频。

想法很好，也算是在应用内共享迈出了一步，不过我对现在使用AudioUnit这样的低层级框架的应用数量表示不乐观。也许今后会有一些为更高层级设计的共享API提供给开发者使用。毕竟要从AudioUnit开始处理音频对于大多数开发者来说并不是一件很容易的事情。

### 点对点连接 Peer-to-Peer Connectivity
可以看成是AirDrop不能直接使用的补偿，代价是需要自己实现。MultipeerConnectivity框架可以用来发现和连接附近的设备，并传输数据，而这一切并不需要有网络连接。可以看到Apple逐渐在文件共享方面一步步放开限制，但是当然所有这些都还是被限制在sandbox里的。

### Store Kit Framework
Store Kit在内购方面采用了新的订单系统，这将可以实现对订单的本机验证。这是一次对应内购破解和有可能验证失败导致内购失败的更新，苹果希望藉此减少内购的实现流程，减少出错，同时遏制内购破解泛滥。前者可能没有问题，但是后者的话，因为objc的动态特性，决定了只要有越狱存在，内购破解也是早晚的事情。不过这一点确实方便了没有能力架设验证服务器的小开发者，这方面来说还是很好的。

### 最后
当然还有一些其他小改动，包括MessageUI里添加了附件按钮，Xcode开始支持模块了等等。完整的iOS7新特性列表可以在[这里](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS7.html#//apple_ref/doc/uid/TP40013162-SW1)找到（暂时应该也需要开发者账号）。最后一个好消息是，苹果放慢了废弃API的速度，这个版本并没有特别重要的API被标为Deprecated，Cheers。
