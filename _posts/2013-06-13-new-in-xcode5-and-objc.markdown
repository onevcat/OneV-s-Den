---
layout: post
title: WWDC 2013 Session笔记 - Xcode5和ObjC新特性
date: 2013-06-13 00:48:32.000000000 +09:00
tags: 能工巧匠集
---

![Welcome to Xcode 5](/assets/images/2013/xcode5-title.png)

这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 400 What's New in Xcode 5
* Session 401 Xcode Core Concepts
* Session 407 Debugging with Xcode
* Session 404 Advances in Objective-C


等Tools模块下的内容

随着iOS7 SDK的beta放出，以及Xcode 5 DP版本的到来，很多为iOS7开发应用的方式已经逐渐浮现。可以豪不夸张地讲，由于iOS7的UI发生了重大变革，此次的升级不同于以往，我们将会迎来iOS开发诞生以来最剧烈的变动，如何拥抱变化，快速适应新的世界和平台，值得每个Cocoa和CocoaTouch开发者研究。工欲善其事，必先利其器。想做iOS7的开发，就必须切换到Xcode5和新的ObjC体系（包括新引入的语法和编译器），在这里我简要地对新添加或重大变化的功能做一个小结。

## 说说新的Xcode

Xcode4刚出的时候存在茫茫多似乎无穷无尽的bug（如果是一路走来的同仁可能对此还记忆犹新），好消息是这次Xcode5 DP版本似乎相当稳定，如果你遇到了开启新Xcode就报错强退的话，多半原因是因为你在使用为Xcode4制作的插件，不同版本的Xcode是共用同一个文件夹下的插件的，请将`~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`目录下的内容清理一下，应该就能顺利进入Xcode5了。

<!-- more -->

Xcode 5现在使用了ARC，取代了原来的垃圾回收（Garbage collection）机制，因此不论从启动速度和使用速度上来说都比之前快了不少。现在大部分的AppStore提交应用也都使用了ARC，新SDK中加入的系统框架也全都是ARC的了。另外，在Xcode5中新建工程也不再提供是否使用ARC的选项（虽然也还是可以在Build Setting中关掉）。如果你还在使用手动内存管理的话，现在是时候抛弃release什么的了，如果你还在迷茫应该应该怎么使用ARC，可以参看一下去年这个时候我发的一篇[ARC的教程文章](http://onevcat.com/2012/06/arc-hand-by-hand/)。

### 界面变化

![Xcode5减小了顶栏宽度](/assets/images/2013/xcode5-header.png)

首先值得称赞的是顶部工具栏的变化，新版中贯彻了精简的原则，将顶栏砍掉了30%左右的宽度，对于小屏幕来说绝对是福音。另外，在外观上界面也向平面和简洁的方向迈进了一大步，可算是对iOS7的遥相呼应吧。

### 更易用的版本管理

![image](/assets/images/2013/xcode5-sourcecontrol.png)

虽然在Xcode 4里就集成了版本管理的内容，但是一直被藏的很深，很多时候开发者不得不打开Organizer才能找到对应操作的地方。与之相比，Xcode5为版本管理留出了专门的一个`Source Control`菜单，从此以后妈妈再也不用担心我找不到git放哪儿了。集成的版本管理可以方便地完成大部分初级功能，包括Check Out，Pull，Commit，Push，Merge等，特别是在建立仓库和检出仓库时十分方便。但是在遇到稍微复杂的git操作时还是感到力不从心（比如rebase或摘樱桃的时候），这点上毕竟Xcode并不是一个版本管理app，而最基本的几个操作在日常工作中也算能快速地应付绝大部分情况（在不将工程文件添加到版本管理的情况下）。

值得称赞的是在编辑代码的时候，可以直接对某一行进行blame了，在该行点击右键选Show Blame for Line，就能看到最后改动的人的信息。另外，Version Editor（View->Version Editor）也除了之前就有的版本对比之外，还新加了Blame和Log两种视图。在对代码历史追溯这块，Xcode5现在已经做的足够好了.

结论是，虽然有所进步，但是Xcode的内置版本管理仍然不堪大任，命令行或者一个专业的git管理工具还是必要的。

### 方便的工程配置

与版本管理的强化相比较，工程配置方面也进行了很多加强，简化了之前开发者的需要做的一些配置工作。首先是在Build Setting的General里，加入了Team的设置，只要填写对应的Apple ID和应用Bundle ID，Xcode就将自动去寻找对应的Provisioning Profile，并使用合适的Provisioning来进行应用打包。因为有了自动配置和将集成的版本管理放到了菜单栏中，Organizer的地位被大大削弱了。至少我现在在Organizer中没有找到本机的证书管理和Provisioning Profile管理的地方，唯一开Organizer的理由大概就是应用打包发布时了。想想从远古时代的Application Loader一步一步走到现在，Xcode可以说在简化流程，帮助开发者快速发布应用方面做了很大努力。

另一个重要改进是在Build选项中加入了`Capabilities`标签，如下图

![Xcode5的Capabilities](/assets/images/2013/xcode5-capabilities.png)

想想看以前为app配置iCloud要花的步骤吧：到Apple Developer里找到应用的ID，打开对应的app的iCloud功能，生成对应的Provisioning文件，回到Xcode创建一个Entitlements文件，定义Key-Value Store，Ubiquity Containers和Keychain Groups，然后你才能开始为应用创建UIDocument并且继续开发。哦天啊…作为学习来说做一次还能接受，但是如果每次开发应用都要来一遍这个过程，只能用枯燥乏味四个字来形容了。于是，正如你所看到的，现在你需要做的是，点一下iCloud的开关，然后…开始编程吧～轻松惬意。同样的方法也适用于Apple提供的其他服务，包括打开和配置GameCenter，Passbook，IAP，Maps，Keychain，后台模式和Data Protection，当然还有iOS7新加入的Inter-app Audio。这些小开关做的事情都很简单，但确实十分贴心。

### 资源管理，Asset Catalog和Image Slicing

资源目录(Asset Catalog)和图像切片(Image Slicing)是Xcode5新加入的功能。资源目录可以方便开发者管理工程中使用的图片素材，利用开发中的命名规则（比如高清图的@2x，图标的Icon，Splash的Default等），来筛选和分类图片。建立一个资源目录十分简单，如果是老版本导入的工程，在工程设置中图标或者splash图的设置中点击`Use Asset Catalog`，Xcode将建立新的资源目录；如果是直接使用Xcode 5建立的工程的话，那么资源目录应该已经默认躺在工程中了。

![添加一个Asset Catalog](/assets/images/2013/xcode5-asset-catalog.png)

添加资源目录后，在工程中会新加一个.xcassets后缀的目录用以整理和存放图片，该文件夹中存放了图片和对应的json文件来保存图片信息。为了能够使用资源目录的特性，以及更好的前向兼容性，建议将所有的图片资源都加入资源目录中：在工程中选择.xcassets文件，然后在资源目录中点击加号即可添加图片。另外，直接从工程外的Finder中将图片拖动到Xcode的资源目录界面中，也将把拖进来的图片拷贝并添加到资源目录中。对的，不再会有讨厌的弹窗出来，问你要拷贝还是要引用了。

![在Asset Catalog中添加图片](/assets/images/2013/xcode5-add-ac.png)

Asset Catalog的意义在于为工程中的图片提供了一个存储信息的地方，不仅可以描述资源对应的设备，资源的版本和更新信息等，更重要的在于可以为Image Slicing服务。所谓Image Slicing，相当于一个可视化的`resizableImageWithCapInsets:resizingMode:`，可以用于指定在图片缩放时用来填充的像素。在资源目录中选择要slicing的图片，点击图片界面右下方的Show Slicing按钮，在想要设定切片的图片上点击`Start Slicing`，将出现左中右（或者上中下）三条可以拖动的指示线，通过拖动它们来设定实际的缩放范围。

![设定Image Slicing](/assets/images/2013/xcode5-slicing.png)

在左侧线（或者上方线）和中间线之间的像素将在缩放时被填充，在中间线和右侧线（或者下方线）之间的像素将被隐藏。比如上面的例子，实际运行中如果对这张图片进行拉伸的话，会是下面的样子：

![拉升Image Slicing后的图片](/assets/images/2013/xcode5-slicing-image.png)

Image Slicing可以帮助开发者用可视化的方式完成resizable image，之后通过拖拖线就可以完成sliced image，而不必再写代码，也不用再一次次尝试输入的insets合不合适了。slicing可缩放的图片大量用于UI中可以节省打包的占用空间，而在Xcode 5中引入和加强图片资源管理的目的，很大一部分是为了配合SpriteKit将游戏引擎加入到SDK中，并将Xcode逐渐打造为一个全面的IDE工具。

### 新的调试和辅助功能

这应该是Xcode5最值得称赞的改进了，在调试中现在在编辑框内鼠标悬浮在变量名上，Xcode将会根据类型进行猜测，并输出最合适的结果以帮助观察。就像这样：

![鼠标悬浮就可以出现变量结果](/assets/images/2013/xcode5-debug-mouseover.png)

以前版本的Xcode虽然也有鼠标悬浮提示，但是想从中找到想要的value确实还是比较麻烦的事情，很多时候我们不得不参考下面Variables View的值或者直接p或者po它们，现在如果只是需要知道变量情况的话，在断到代码后一路用鼠标跟着代码走一遍，就差不多了然于胸了。如果你认为鼠标悬停只能打打字符串或者数字的话你就错了，数组，字典什么的也不在话下，更过分的是设计图像的也能很好地显示，只需要点击预览按钮，就像这样：

![直接悬停显示图片](/assets/images/2013/xcode5-debug-image.png)

Xcode5集成了一个Debug面板，用来实现一个简单的Profiler，可以在调试时直接看到应用的CPU消耗，内存使用等情况（其他的还有iCloud情况，功耗和图形性能等）。在Debug运行时Cmd+6即可切换到该Debug界面。监测的内容简单明了，CPU使用用来检查是否有高占用或者尖峰（特别是主线程中），内存检测用来检查内存使用和释放的情况是否符合预期。

![Debug的Profiler面板](/assets/images/2013/xcode5-debug-profiler.png)

如果养成开发过程的调试中就一直打开这个Profiler面板的话（至少我从之后会坚持这个做法了），相信是有助于在开发过程中就迅速的监测到潜在的问题，并迅速解决的。当然，对于明显的问题可以在Debug面板中发现后立即寻找对应代码解决，但是如果比较复杂的问题，想要知道详细情况的话，还是要使用Instruments，在Debug面板中提供了一个“Profile In Instruments”按钮，可以快速跳转到Instruments。

最后，Xcode在注释式文档方面也有进步，现在如下格式的注释将在Xcode中直接被检测到并集成进代码提示中了：

```objc
/**
 * Setup a recorder for a specified file path. After setting it, you can use the other control method to control the shared recorder.
 *
 * @param talkingPath An NSString indicates in which path the recording should be created
 * @returns YES if recorder setup correctly, NO if there is an error
 */
- (BOOL)recordWithFilePath:(NSString *)talkingPath;
```

得到的结果是这样的

![Xcode对代码注释的解析](/assets/images/2013/xcode5-comment-doc.png)

以及Quick Help中会有详细信息

![在Quick Help中显示详细文档](/assets/images/2013/xcode5-quickhelp.png)

Xcode现在可以识别Javadoc格式（类似于上面例子）的注释文档，可用的标识符除了上面的`@param`和`@return`外，还有例如`@see`，`@discussion`等，关于Javadoc的更多格式规则，可以参考[Wiki](http://en.wikipedia.org/wiki/Javadoc)。

## 关于Objective-C，Modules和Autolinking

OC自从Apple接手后，一直在不断改进。随着移动开发带来的OC开发者井喷式增加，客观上也要求Apple需要提供各种良好特性来支持这样一个庞大的开发者社区。iOS4时代的GCD，iOS5时代的ARC，iOS6时代的各种简化，每年我们都能看到OC在成为一种先进语言上的努力。基于SmallTalk和runtime，本身是C的超集，如此“根正苗红”的一门语言，在今年也迎来的新的变化。

今年OC的最大变化就是加入了Modules和Autolinking。

### 什么是Modules呢

在了解Modules之前我们需要先了解一下OC的import机制。`#import <FrameworkFoo/HeaderBar.h>`，我相信每个开发者都写过这样的代码，用来引用其他的头文件。熟悉C或者C++的童鞋可能会知道，在C和C++里是没有#import的，只有#include（虽然GCC现在为C和C++做了特殊处理使得import可以被编译），用来包含头文件。#include做的事情其实就是简单的复制粘贴，将目标.h文件中的内容一字不落地拷贝到当前文件中，并替换掉这句include，而#import实质上做的事情和#include是一样的，只不过OC为了避免重复引用可能带来的编译错误（这种情况在引用关系复杂的时候很可能发生，比如B和C都引用了A，D又同时引用了B和C，这样A中定义的东西就在D中被定义了两次，重复了），而加入了#import，从而保证每个头文件只会被引用一次。

> 如果想深究，import的实现是通过#ifndef一个标志进行判断，然后在引入后#define这个标志，来避免重复引用的

实质上import也还是拷贝粘贴，这样就带来一个问题：当引用关系很复杂，或者一个头文件被非常多的实现文件引用时，编译时引用所占的代码量就会大幅上升（因为被引用的头文件在各个地方都被copy了一遍）。为了解决这个问题，C系语言引入了预编译头文件（PreCompiled Header），将公用的头文件放入预编译头文件中预先进行编译，然后在真正编译工程时再将预先编译好的产物加入到所有待编译的Source中去，来加快编译速度。比如iOS开发中Supporting Files组内的.pch文件就是一个预编译头文件，默认情况下，它引用了UIKit和Foundation两个头文件--这是在iOS开发中基本每个实现文件都会用到的东西。

于是理论上说，想要提高编译速度，可以把所有头文件引用都放到pch中。但是这样面临的问题是在工程中随处可用本来不应该能访问的东西，而编译器也无法准确给出错误或者警告，无形中增加了出错的可能性。

于是Modules诞生了。Modules相当于将框架进行了封装，然后加入在实际编译之时加入了一个用来存放已编译添加过的Modules列表。如果在编译的文件中引用到某个Modules的话，将首先在这个列表内查找，找到的话说明已经被加载过则直接使用已有的，如果没有找到，则把引用的头文件编译后加入到这个表中。这样被引用到的Modules只会被编译一次，但是在开发时又不会被意外使用到，从而同时解决了编译时间和引用泛滥两方面的问题。

稍微追根问底，Modules是什么？其实无非是对框架进行了如下封装，拿UIKit为例：

```objc
framework module UIKit {
	umbrella header "UIKit.h"
	module * {export *}
	link framework "UIKit"
}
```

这个Module定义了首要头文件（UIKit.h），需要导出的子modules（所有），以及需要link的框架名称（UIKit）。需要指出的是，现在Module还不支持第三方的框架，所以只有SDK内置的框架能够从这个特性中受益。另外，在C++的源代码中，Modules也是被禁用的。

### 好了，说了那么多，这玩意儿怎么用呢

关于普通开发者使用的这个新特性的方法，Apple在LLVM5.0（也就是Xcode5带的最新的编译器前端中）引入了一个新的编译符号`@import`，使用@符号将告诉编译器去使用Modules的引用形式，从而获取好处，比如想引用MessageUI，可以写成

```objc
@import MessageUI;
```

在使用上，这将等价于以前的`#import <MessageUI/MessageUI.h>`，但是将使用Modules的特性。如果只想使用某个特性的.h文件，比如`#import <MessageUI/MFMailComposeViewController.h>`，对应写作

```objc
@import MessageUI.MFMailComposeViewController;
```
当然，如果对于以前的工程，想要使用新的Modules特性，如果要把所有头文件都这样一个一个改成`@import`的话，会是很大的一个工作量。Apple自然也考虑到了这一点，于是对于原来的代码，只要使用的是iOS7或者MacOS10.9的SDK，在Build Settings中将Enable Modules(C and Objective-C)打开，然后保持原来的`#import`写法就行了。是的，不需要任何代码上的改变，编译器会在编译的时候自动地把可能的地方换成Modules的写法去编译的。

Autolinking是Modules的附赠小惊喜，因为在module定义的时候指定来link framework，所以在编译module时LLVM会将所涉及到的框架自动帮你写到link里去，不再需要到编译设置里去添加了。
