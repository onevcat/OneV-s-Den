---
layout: post
title: WWDC 2013 Session笔记 - iOS7中弹簧式列表的制作
date: 2013-09-01 00:58:48.000000000 +09:00
tags: 能工巧匠集
---
这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 206 Getting Started with UIKit Dynamics
* Session 217 Exploring Scroll Views in iOS7

UIScrollView可以说是UIKit中最重要的类之一了，包括UITableView和UICollectionView等重要的数据容器类都是UIScrollView的子类。在历年的WWDC上，UIScrollView和相关的API都有专门的主题进行介绍，也可以看出这个类的使用和变化之快。今年也不例外，因为iOS7完全重新定义了UI，这使得UIScrollView里原来不太会使用的一些用法和实现的效果在新的系统中得到了很好的表现。另外，由于引入了UIKit Dynamics，我们还可以结合ScrollView做出一些以前不太可能或者需要花费很大力气来实现的效果，包括带有重力的swipe或者是类似新的信息app中的带有弹簧效果聊天泡泡等。如果您还不太了解iOS7中信息app的效果，这里有一张gif图可以帮您大概了解一下：

![iOS7中信息app的弹簧效果](/assets/images/2013/ios7-message-app-spring.gif)

这次笔记的内容主要就是实现一个这样的效果。为了避免重复造轮子，我对这个效果进行了一些简单的封装，并连同这篇笔记的demo一起扔在了Github上，有需要的童鞋可以[到这里](https://github.com/onevcat/VVSpringCollectionViewFlowLayout)自取。

iOS7的SDK中Apple最大的野心其实是想用SpriteKit来结束iOS平台游戏开发（至少是2D游戏开发）的乱战，统一游戏开发的方式并建立良性社区。而UIKit Dynamics，个人猜测Apple在花费力气为SpriteKit开发了物理引擎的同时，发现在UIKit中也可以使用，并能得到不错的效果，于是顺便革新了一下设计理念，在UI设计中引入了不少物理的概念。在iOS系统中，最为典型的应用是锁屏界面打开相机时中途放弃后的重力下坠+反弹的效果，另一个就是信息应用中的加入弹性的消息列表了。弹性列表在我自己上手试过以后觉得表现形式确实很生动，可以消除原来列表那种冷冰冰的感觉，是有可能在今后的设计中被大量使用的，因此决定学上一学。

首先我们需要知道要如何实现这样一种效果，我们会用到哪些东西。毋庸置疑，如果不使用UIKit Dynamics的话，自己从头开始来完成会是一件非常费力的事情，你可能需要实现一套位置计算和物理模拟来使效果看起来真实滑润。而UIKit Dynamics中已经给我们提供了现成的弹簧效果，可以用`UIAttachmentBehavior`进行实现。另外，在说到弹性效果的时候，我们其实是在描述一个列表中的各个cell之间的关系，对于传统的UITableView来说，描述UITableViewCell之间的关系是比较复杂的（因为Apple已经把绝大多数工作做了，包括计算cell位置和位移等。使用越简单，定制就会越麻烦在绝大多数情况下都是真理）。而UICollectionView则通过layout来完成cell之间位置关系的描述，给了开发者较大的空间来实现布局。另外，UIKit Dynamics为UICollectionView做了很多方便的Catagory，可以很容易地“指导”UICollectionView利用加入物理特性计算后的结果，在实现弹性效果的时候，UICollectionView是我们不二的选择。

如果您在阅读这篇笔记的时候遇到困难的话，建议您可以看看我之前的一些笔记，包括今年的[UIKit Dynamics的介绍](http://onevcat.com/2013/06/uikit-dynamics-started/)和去年的[UICollectionView介绍](http://onevcat.com/2012/06/introducing-collection-views/)。

话不多说，我们开工。首先准备一个UICollectionViewFlowLayout的子类（在这里叫做`VVSpringCollectionViewFlowLayout`），然后在ViewController中用这个layout实现一个简单的collectionView：

```objc
//ViewController.m

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) VVSpringCollectionViewFlowLayout *layout;
@end

static NSString *reuseId = @"collectionViewCellReuseId";

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
	self.layout = [[VVSpringCollectionViewFlowLayout alloc] init];
    self.layout.itemSize = CGSizeMake(self.view.frame.size.width, 44);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:self.layout];
    
    collectionView.backgroundColor = [UIColor clearColor];
    
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseId];
    
    collectionView.dataSource = self;
    [self.view insertSubview:collectionView atIndex:0];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 50;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];
    
    //Just give a random color to the cell. See https://gist.github.com/kylefox/1689973
    cell.contentView.backgroundColor = [UIColor randomColor];
    return cell;
}
@end
```

这部分没什么可以多说的，现在我们有一个标准的FlowLayout的UICollectionView了。通过使用UICollectionViewFlowLayout的子类来作为开始的layout，我们可以节省下所有的初始cell位置计算的代码，在上面代码的情况下，这个collectionView的表现和一个普通的tableView并没有太大不同。接下来我们着重来看看要如何实现弹性的layout。对于弹性效果，我们需要的是连接一个item和一个锚点间弹性连接的`UIAttachmentBehavior`，并能在滚动时设置新的锚点位置。我们在scroll的时候，只要使用UIKit Dynamics的计算结果，替代掉原来的位置更新计算（其实就是简单的scrollView的contentOffset的改变），就可以模拟出弹性的效果了。

首先在`-prepareLayout`中为cell添加`UIAttachmentBehavior`。

```objc
//VVSpringCollectionViewFlowLayout.m
@interface VVSpringCollectionViewFlowLayout()
@property (nonatomic, strong) UIDynamicAnimator *animator;
@end

@implementation VVSpringCollectionViewFlowLayout
//...

-(void)prepareLayout {
    [super prepareLayout];
    
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        CGSize contentSize = [self collectionViewContentSize];
        NSArray *items = [super layoutAttributesForElementsInRect:CGRectMake(0, 0, contentSize.width, contentSize.height)];
        
        for (UICollectionViewLayoutAttributes *item in items) {
            UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:item.center];
            
            spring.length = 0;
            spring.damping = 0.5;
            spring.frequency = 0.8;
            
            [_animator addBehavior:spring];
        }
    }
}
@end
```

prepareLayout将在CollectionView进行排版的时候被调用。首先当然是call一下super的prepareLayout，你肯定不会想要全都要自己进行设置的。接下来，如果是第一次调用这个方法的话，先初始化一个UIDynamicAnimator实例，来负责之后的动画效果。iOS7 SDK中，UIDynamicAnimator类专门有一个针对UICollectionView的Category，以使UICollectionView能够轻易地利用UIKit Dynamics的结果。在`UIDynamicAnimator.h`中能够找到这个Category：

```objc
@interface UIDynamicAnimator (UICollectionViewAdditions)

// When you initialize a dynamic animator with this method, you should only associate collection view layout attributes with your behaviors.
// The animator will employ thecollection view layout’s content size coordinate system.
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout;

// The three convenience methods returning layout attributes (if associated to behaviors in the animator) if the animator was configured with collection view layout
- (UICollectionViewLayoutAttributes*)layoutAttributesForCellAtIndexPath:(NSIndexPath*)indexPath;
- (UICollectionViewLayoutAttributes*)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewLayoutAttributes*)layoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind atIndexPath:(NSIndexPath *)indexPath;

@end
```

于是通过`-initWithCollectionViewLayout:`进行初始化后，这个UIDynamicAnimator实例便和我们的layout进行了绑定，之后这个layout对应的attributes都应该由绑定的UIDynamicAnimator的实例给出。就像下面这样：

```objc
//VVSpringCollectionViewFlowLayout.m
@implementation VVSpringCollectionViewFlowLayout

//...

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [_animator itemsInRect:rect];
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [_animator layoutAttributesForCellAtIndexPath:indexPath];
}
@end
```

让我们回到`-prepareLayout`方法中，在创建了UIDynamicAnimator实例后，我们对于这个layout中的每个attributes对应的点，都创建并添加一个添加一个`UIAttachmentBehavior`（在iOS7 SDK中，UICollectionViewLayoutAttributes已经实现了UIDynamicItem接口，可以直接参与UIKit Dynamic的计算中去）。创建时我们希望collectionView的每个cell就保持在原位，因此我们设定了锚点为当前attribute本身的center。

接下来我们考虑滑动时的弹性效果的实现。在系统的信息app中，我们可以看到弹性效果有两个特点：

* 随着滑动的速度增大，初始的拉伸和压缩的幅度将变大
* 随着cell距离屏幕触摸位置越远，拉伸和压缩的幅度

对于考虑到这两方面的特点，我们所期望的滑动时的各cell锚点的变化应该是类似这样的：

![向上拖动时的锚点变化示意](/assets/images/2013/spring-list-ios7.png)

现在我们来实现这个锚点的变化。既然都是滑动，我们是不是可以考虑在UIScrollView的`–scrollViewDidScroll:`委托方法中来设定新的Behavior锚点值呢？理论上来说当然是可以的，但是如果这样的话我们大概就不得不面临着将刚才的layout实例设置为collectionView的delegate这样一个事实。但是我们都知道layout应该做的事情是给collectionView提供必要的布局信息，而不应该负责去处理它的委托事件。处理collectionView的回调更恰当地应该由处于collectionView的controller层级的类来完成，而不应该由一个给collectionView提供数据和信息的类来响应。在`UICollectionViewLayout`中，我们有一个叫做`-shouldInvalidateLayoutForBoundsChange:`的方法，每次layout的bounds发生变化的时候，collectionView都会询问这个方法是否需要为这个新的边界和更新layout。一般情况下只要layout没有根据边界不同而发生变化的话，这个方法直接不做处理地返回NO，表示保持现在的layout即可，而每次bounds改变时这个方法都会被调用的特点正好可以满足我们更新锚点的需求，因此我们可以在这里面完成锚点的更新。

```objc
//VVSpringCollectionViewFlowLayout.m
@implementation VVSpringCollectionViewFlowLayout

//...

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    UIScrollView *scrollView = self.collectionView;
    CGFloat scrollDelta = newBounds.origin.y - scrollView.bounds.origin.y;
    
    //Get the touch point
    CGPoint touchLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
    
    for (UIAttachmentBehavior *spring in _animator.behaviors) {
        CGPoint anchorPoint = spring.anchorPoint;
        
        CGFloat distanceFromTouch = fabsf(touchLocation.y - anchorPoint.y);
        CGFloat scrollResistance = distanceFromTouch / 500;
        
        UICollectionViewLayoutAttributes *item = [spring.items firstObject];
        CGPoint center = item.center;

		//In case the added value bigger than the scrollDelta, which leads an unreasonable effect
        center.y += (scrollDelta > 0) ? MIN(scrollDelta, scrollDelta * scrollResistance)
                                      : MAX(scrollDelta, scrollDelta * scrollResistance);
        item.center = center;
        
        [_animator updateItemUsingCurrentState:item];
    }
    return NO;
}

@end
```

首先我们计算了这次scroll的距离`scrollDelta`，为了得到每个item与触摸点的之间的距离，我们当然还需要知道触摸点的坐标`touchLocation`。接下来，可以根据距离对每个锚点进行设置了：简单地计算了原来锚点与触摸点之间的距离`distanceFromTouch`，并由此计算一个系数。接下来，对于当前的item，我们获取其当前锚点位置，然后将其根据`scrollDelta`的数值和刚才计算的系数，重新设定锚点的位置。最后我们需要告诉UIDynamicAnimator我们已经完成了对冒点的更新，现在可以开始更新物理计算，并随时准备collectionView来取LayoutAttributes的数据了。

也许你还没有缓过神来？但是我们确实已经做完了，让我们来看看实际的效果吧：

![带有弹性效果的collecitonView](/assets/images/2013/spring-collection-view-over-ios7.gif)

当然，通过调节`damping`，`frequency`和`scrollResistance`的系数等参数，可以得到弹性不同的效果，比如更多的震荡或者更大的幅度等等。

这个layout实现起来非常简单，我顺便封装了一下放到了Github上，大家有需要的话可以[点击这里下载](https://github.com/onevcat/VVSpringCollectionViewFlowLayout)并直接使用。
			
