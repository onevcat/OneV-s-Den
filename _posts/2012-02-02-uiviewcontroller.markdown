---
layout: post
title: UIViewController的误用
date: 2012-02-02 22:50:53.000000000 +09:00
tags: 能工巧匠集
---
![](http://www.onevcat.com/wp-content/uploads/2012/02/vc.jpg)

转载本文请保留以下原作者信息:
原作：OneV [http://www.onevcat.com/2012/02/uiviewcontroller/](http://www.onevcat.com/2012/02/uiviewcontroller/)

## 什么是UIViewController的误用

UIViewController是iOS开发中最常见也最重要的部件之一，可以说绝大多数的app都用到了UIViewController来管理页面的view。它是MVC的核心结构和桥梁构成，可以说UIViewController是绝大多数开发者所花时间最多的部分了。

但是正是这样一个重要的类却经常被误用，从而导致app的不稳定，莫名奇妙的bug甚至无法通过appstore的审查。最常见和最可怕的误用在于在一个UIViewController里加入本来不应该由它管理的其他UIViewController，也即违反了Apple在开发者文档中关于UIViewController的描述：

> Each custom view controller object you create is responsible for managing all of the views in a single view hierarchy. In iPhone applications, the views in a view hierarchy traditionally cover the entire screen, but in iPad applications they may cover only a portion of the screen. The one-to-one correspondence between a view controller and the views in its view hierarchy is the key design consideration. You should not use multiple custom view controllers to manage different portions of the same view hierarchy. Similarly, you should not use a single custom view controller object to manage multiple screens worth of content.

一个ViewController应该且只应该管理一个view hierarchy，而通常来说一个完整的view hierarchy指的是整整占满的一个屏幕。而很多app满屏中会有各个区域分管不同的功能，一些开发者喜欢直接新建一个ViewController和一套相应的View来完成所要的功能（比如我自己=_=）。虽然十分方便，但是却面临很多风险..

一般来说，只要你的代码中含有类似这样的语句，那你一定是误用UIViewController了

```
viewController.view.bounds = CGRectMake(50, 50, 100, 200);
[viewController.view addSubview:someOtherViewController.view];
```

这样的代码可能导致莫名的bug，也会令接手的开发者无所适从。

### 小题大做吧，这样用会有什么问题呢

一个很麻烦的问题是，这将会导致你的app在不同的iOS版本上有不同的表现。在iOS5之前，能够对viewController进行管理的类有UINavigationController，UITabBarController和iPad专有的UISplitViewController。而在iOS5中加入了可自定义的ViewControllers的容器。由于新的SDK的处理机制，iOS4前通过addSubview加到当前controller的view上的view的呈现，将不会触发被加入view hierarchy的view的controller的viewWillAppear:方法。而且，新加入的viewController也不会接收到诸如didReceiveMemoryWarning等委托方法，而且也不能响应所有的旋转事件！而iOS5中由于所谓的custom container VC的出现，上述方法又能够运行良好，这导致了同样代码在不同终端产生不同的行为，为之后的维护和进一步开发埋下了隐患。另外，用这样的方法所添加的viewController显然违背了Apple的本意，它的parentViewController，interfaceOrientation显然都是错误的，有时候甚至会出现触摸事件无法响应等严重问题。

### 好吧，那我们要怎么办

如果你已经在一个app里这样误用了大量的viewController，那可能的办法也许是尽力去自行处理各种非正常的状况，比如在addSubview之后手动调用加入的vc的viewWillAppear:，以及在收到didReceiveMemoryWarning后顺次调用子VC的didReceiveMemoryWarning(显然都是很蛋疼的做法啊)。但是需要注意的是iOS5中这些方法的调用似乎是没有问题的（至少我测试是这样），因此需要对不同版本系统进行分别处理。可以用UIDevice的方法确定运行环境的系统版本：

```
// System Versioning Preprocessor Macros
#define SYSTEM_VERSION_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
```

在合适的时机判定判定系统版本，手动调用对应方法：

```
if (SYSTEM_VERSION_LESS_THAN(@“5.0”))
{ 
	//viewWillAppear或didReceiveMemoryWarning或其他
}
```

显然，这样的代码既非优雅亦难维护，而且随着iOS版本的更新，谁也不知道这段代码之后会不会有什么问题，无形中增加了开发成本。


## 真正的解决之道

当然是严格遵守Apple提供的设计规范，每个VC管理一个view hierarchy。在设计的时候，永远记住你的view和view controller都需要重用，而不恰当的使用view controller会导致重用性大打折扣。而通用的view有时也需要一个类似controller的东西来管理它的subview的行为，或者做出某些相应，这个时候我们不妨想一想一些Apple写的经典的view是如何实现的，比如UITableView和UIPickerView，依靠protocol的各种方法进行配置。
作为自定义的view的controller应当是直接继承自NSObject的类，而不应该是UIViewController。一个UIViewController可以包含若干个这样的controller来控制一个view中的不同部分的功能实现，而对于对应的自定义view是代码写的还是nib出来的就无所谓了。当然，如果是新接触iOS开发的话，我个人不建议使用Interface Builder，除非你确实清楚IB到底在背后为你做了什么。在当你完全清楚之后，IB确实能极大提升开发效率（特别是在Xcode4以后），但是如果你的对IB和view加载连接的概念如同毛线团的话，IB的使用只会让你以及让你的同事茫然失措。
在iOS5中提供了所谓的container of View Controllers，有兴趣的童鞋可以参看WWDC 2011的[Session 102 – Implementing UIViewController Containment](http://developer.apple.com/videos/wwdc/2011/)(需要一个野生开发者账号)

## 一些资料

作为iOS开发者，Apple的关于UIViewController的文档以及开发者的一些讨论是必读的，简单整理如下：

* [View Controller Programming Guide for iOS](http://developer.apple.com/library/ios/#featuredarticles/ViewControllerPGforiPhoneOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007457-CH1-SW1)
* [关于误用UIViewController而造成的私有API调用的讨论](https://devforums.apple.com/message/310806#310806)
* [stack overflow上关于误用view controller的讨论](http://stackoverflow.com/questions/5691226/am-i-abusing-uiviewcontroller-subclassing/5691708#comment-6507338)
