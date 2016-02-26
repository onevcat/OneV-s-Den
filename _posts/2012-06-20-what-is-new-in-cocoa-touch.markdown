---
layout: post
title: WWDC 2012 Session笔记——200 What is new in Cocoa Touch
date: 2012-06-20 23:37:08.000000000 +09:00
tags: 能工巧匠集
---

这是博主的WWDC2012笔记系列中的一篇，完整的笔记列表可以参看[这里](http://onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)。如果您是首次来到本站，也许您会有兴趣通过[RSS](http://onevcat.com/atom.xml)，或者通过页面下方的邮件订阅的方式订阅本站。

之前写过[一篇iOS6 SDK新内容的总览](http://www.onevcat.com/2012/06/%e5%bc%80%e5%8f%91%e8%80%85%e6%89%80%e9%9c%80%e8%a6%81%e7%9f%a5%e9%81%93%e7%9a%84ios6-sdk%e6%96%b0%e7%89%b9%e6%80%a7/)，从这篇开始，将对WWDC 2012的我个人比较感兴趣的Session进行一些笔记，和之后的笔记一起应该可以形成一个比较完整的WWDC 2012 Session部分的个人记录。

因为WWDC的内容可谓众多，我自觉不太可能看完所有Session(其实也没有这个必要..)，所以对于内容覆盖上可能有所欠缺。另外我本身也只是一个iOS开发初学者加业余爱好者，因此很多地方也都不明白，不理解，因此难免有各种不足。这些笔记的最大作用是给自己做一些留底，同时帮助理解Session的内容。欢迎高手善意地指出我的错误和不足..谢谢！

所有的WWDC 2012 Session的视频和讲义可以在[这里](https://developer.apple.com/videos/wwdc/2012/)找到，如果想看或者下载的话可能需要一个野生开发者账号(就是不用交99美金那种)。iOS6 Beta和Xcode4.5预览版现在已经提供开发者下载(需要家养开发者的账号，就在iOS Resource栏里)，当然网上随便搜索一下不是开发者肯定也能下载到，不过如果你不太懂的话还是不建议尝试iOS6 Beta，有时间限制麻烦不说，而且可能存在各种bug，Xcode4.5预览版同理..

<!--more-->

作为WWDC 2012 Session部分的真正的开场环节，Session200可以说是iOS开发者必听必看的。这个Session介绍了关于Cocoa Touch的新内容，可以说是对整个iOS6 SDK的概览。

我也将这个Session作为之后可能会写的一系列的Session笔记的第一章，我觉得用Session 200作为一个开始，是再适合不过的了～

* * *

### 更多的外观自定义

从iOS5开始，Apple就逐渐致力于标准控件的可自定义化，基本包括颜色，图片等的替换。对于标准控件的行为，Apple一向控制的还是比较严格的。而开发者在做app时，最好还是遵守Apple的人机交互手册来确定控件的功能，否则可能遇到意想不到的麻烦…

iOS6中Apple继续扩展了一些控件的可定义性。对于不是特别追求UI的开发团队或者实力有限的个人开发者来说这会是一个不错的消息，使用现有的资源和新加的API，可以快速开发出界面还不错的应用。

#### UIPopoverBackgroundView

UIPopoverBackgroundView是iOS5引入的，可以为popover自定义背景。iOS6中新加入了询问是否以默认方式显示的方法：

`+ (BOOL)wantsDefaultContentAppearance;`

返回NO的话，将以新的立体方式显示popover。

具体关于UIPopoverBackgroundView的用法，可以参考[文档](http://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIPopoverBackgroundView_class/Reference/Reference.html)

#### UIStepper

UIStepper也是iOS5引入的新控件，在iOS5中Apple为标准控件自定义做出了相当大的努力（可以参看WWDC2011的相关内容），而对于新出生的UIStepper却没有相应的API。在iOS6里终于加上了..可以说是预料之中的。

`@property (nonatomic,retain) UIColor *tintColor;`

这个属性定义颜色。

![定义了tint之后的stepper](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120620-2.png)

```objc
- (void)setBackgroundImage:(UIImage*)image forState:(UIControlState)state;

- (void)setDividerImage:(UIImage*)image forLeftSegmentState:(UIControlState)left rightSegmentState:(UIControlState)right; 

- (void)setIncrementImage:(UIImage *)image forState:(UIControlState)state; 

- (void)setDecrementImage:(UIImage *)image forState:(UIControlState)state;
```

可以定义背景图片、分隔图片和增减按钮的图片，都很简单明了，似乎没什么好说的。

#### ￼￼￼UISwitch

同样地，现在有一系列属性可以自定义了。

```objc
@property (nonatomic, retain) UIColor *tintColor; </pre>

@property (nonatomic, retain) UIColor *thumbTintColor; 

@property (nonatomic, retain) UIImage *onImage; 

@property (nonatomic, retain) UIImage *offImage;
```

其中thumbTintColor指的是开关的圆形滑钮的颜色。另外对于on和off时候可以自定义图片，那么很大程度上其实开关控件已经可以完全自定义，基本不再需要自己再去实现一次了..

![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120620-3.png)

#### ￼UINavigationBar & UITabBar

加入了阴影图片的自定义：

`@property (nonatomic,retain) UIImage *shadowImage;`

这个不太清楚，没有自己实际试过。以后有机会做个小demo看看可以…

#### ￼￼UIBarButtonItem

现在提供设置背景图片的API：

```objc
(void)setBackgroundImage:(UIImage *)bgImage 
                  forState:(UIControlState)state 
                     style:(UIBarButtonItemStyle)style 
                barMetrics:(UIBarMetrics)barMetrics;
```
                
这个非常有用…以前在自定义UINavigationBar的时候，对于BarButtonItem的背景图片的处理非常复杂，通常需要和designer进行很多配合，以保证对于不同宽度的按钮背景图都可以匹配。现在直接提供一个UIImage就OK了..初步目测是用resizableImageWithCapInsets:做的实现..很赞，可以偷不少懒～

* * *

### UIImage的API变化

随着各类Retina设备的出现，对于图片的处理方面之前的API有点力不从心..反应最大的就是图片在不同设备上的适配问题。对于iPhone4之前，是普通图片。对于iPhone4和4S，由于Retina的原因，需要将图片宽高均乘2，并命名为@2x。对于遵循这样原则的图片，cocoa touch将会自动进行适配，将4个pixel映射到1个point上去，以保证图片不被拉伸以及比例的适配。对于iPhone开发，相关的文档是比较全面的，但是对于iPad就没那么好运了。Apple对于iPad开发的支持显然做的不如对iPhone那样好，所以很多iPad开发者在对图片进行处理的时候往往不知所措——特别是在retina的new iPad出现以后，更为严重。而这次UIImage的最大变化在于自己可以对scale进行指定了～这样虽然在coding的时候变麻烦了一点，但是图片的Pixel to Point对应关系可以自己控制了，在做适配的时候可以省心不少。具体相关几个API如下：

```objc
+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale;

- (id)initWithData:(NSData *)data scale:(CGFloat)scale; 

+ (UIImage *)imageWithCIImage:(CIImage *)ciImage 
                        scale:(CGFloat)scale 
                  orientation:(UIImageOrientation)orientation;

- (id)initWithCIImage:(CIImage *)ciImage 
                scale:(CGFloat)scale 
          orientation:(UIImageOrientation)orientation;
```
          
指定scale=2之后即可对retina屏幕适配，相对来说还是比较简单的。

* * *

### UITableView的改动

UITableView就不多介绍了，基础中的基础…在iOS5引入StoryBoard之后，由StoryBoard生成的UITableViewController中对cell进行操作时所有的cell的alloc语句都可以不写，可以为cell绑定nib等，都简化了UITableView的使用。在iOS6中，对cell的复用有一些新的方法：

`- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier;`

将一个类注册为某个重用ID。

`- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier 
                           forIndexPath:(NSIndexPath *)indexPath;`

将指定indexPath的cell重用(若不能重用则返回nil，在StoryBoard会自动生成一个新的cell)。

另外，对UITableView的Header、Footer和Section分隔添加了一系列的property以帮助自定义，并且加入了关于Header和Footer的delegate方法。可以说对于TableView的控制更强大了…

* * *

### ￼UIRefreshControl

这个是新加的东西，Apple的抄袭之作，官方版的下拉刷新。下拉刷新自出现的第一分钟起，就成为了人民群众喜闻乐见的手势，对于这种得到大众认可的手势，Apple是一定不会放过的。

相对与现在已有的开源下拉刷新来说，功能上还不那么强大，可自定义的内容不多，而且需要iOS6以后的系统，因此短期内还难以形成主流。但是相比开源代码，减去了拖源码加库之类的麻烦，并且和系统整合很好，再加上Apple的维护，相信未来是有机会成为主流的。现在来说的话，也就只是一种实现的选择而已。

* * *

### UICollectionView

这个是iOS的UIKit的重头戏..一定意义上可以把UICollectionView理解成多列的UITableView。开源社区有很多类似的实现，基本被称作GridView，我个人比较喜欢的实现有[AQGridView](https://github.com/AlanQuatermain/AQGridView)和[GMGridView](https://github.com/gmoledina/GMGridView).开源实现基本上都是采用了和UITableView类似的方法，继承自UIScrollView，来进行多列排列。功能上来说相对都比较简单..

而UICollectionView可以说是非常强大..强大到基本和UITableView一样了..至少使用起来和UITableView一样，用惯了UITableView的童鞋甚至可以不用看文档就能上手。一样的DataSource和Delegate，不同之处在于多了一个Layout对象对其进行排列的设定，这个稍后再讲。我们先来看Datasource和Delegate的API

```objc
//DataSource
-numberOfSectionsInCollectionView: 
-collectionView:numberOfItemsInSection: 
-collectionView:cellForItemAtIndexPath:

//Delegate
-collectionView:shouldHighlightItemAtIndexPath: 
-collectionView:shouldSelectItemAtIndexPath: 
-collectionView:didSelectItemAtIndexPath:
```

没什么值得说的，除了名字以外，和UITableView的DataSource和Delegate没有任何不同。值得一提的是对应的UICollectionViewCell和UITableViewCell略有不同，UICollectionViewCell没有所谓的默认style，cell的子view自下而上有Background View、Selected Background View和一个Content View。开发者将自定义内容扔到Content View里即可。

需要认真看看的是Layout对象，它控制了整个UICollectionView中每个Section甚至Section中的每个cell的位置和关系。Apple提供了几种不错的Layout，足以取代现在常用的几个开源库，其中包括了像Linkedin和Pinterest的视图。可以说Apple对于利用AppStore这个平台，向第三方开发者进行学习的能力是超强的。

关于UICollectionView，在之后有两个session专门进行了讨论，我应该也会着重看一看相关内容，之后再进行补充了～

* * *

### UIViewController

**这个绝对是重磅消息～**一直以来我们会在viewDidUnload方法中做一些清空outlet或者移除observer的事情。在viewDidUnload中清理observer其实并不是很安全，因此在iOS5中Apple引入了viewWillUnload，建议开发者们在viewWillUnload的时候就移除observer。而对于出现内存警告时，某些不用的view将被清理，这时候将自动意外执行viewWillUnload和viewDidUnload，很可能造成莫名其妙的crash，而这种内存警告造成的问题又因为其随机性难以debug。

于是Apple这次做了一个惊人的决定，直接在**iOS6里把viewWillUnload和viewDidUnload标注为了Deprecated**，并且不再再会调用他们。绝大部分开发者其实是对iOS3.0以来就伴随我们的viewDidUnload是有深深的感情的，但是现在需要和这个方法说再见了。对于使用iOS6 SDK的app来说不应该再去实现这两个方法，而之前在这两个方法中所做的工作需要重新考虑其更合适的位置：比如在viewWillDisappear中去移除observer，在dealloc中将outlet置为nil等。

* * *

### 状态恢复

在之前的一篇iOS6 SDK的简述中已经说过这个特性。简单讲就是对每个view现在都多了一个属性：

`@property (nonatomic, copy) NSString *restorationIdentifier;`

通过在用户点击Home键时的一系列delegate里对现有的view进行编码存储后，在下一次打开文件时进行解码恢复。更多的详细内容之后也会有session进行详细说明，待更新。

* * *

### 总结

其他的很多新特性，包括社交网络，GameCenter和PassKit等也会在之后逐渐深入WWDC 2012 Session的时候进行笔记..

作为开篇，就这样吧。
