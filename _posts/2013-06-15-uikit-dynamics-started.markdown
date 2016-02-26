---
layout: post
title: WWDC 2013 Session笔记 - UIKit Dynamics入门
date: 2013-06-15 00:50:00.000000000 +09:00
tags: 能工巧匠集
---
这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 206 Getting Started with UIKit Dynamics
* Session 221 Advanced Techniques with UIKit Dynamics

### 什么是UIKit动力学（UIKit Dynamics）

其实就是UIKit的一套动画和交互体系。我们现在进行UI动画基本都是使用CoreAnimation或者UIView animations。而UIKit动力学最大的特点是将现实世界动力驱动的动画引入了UIKit，比如重力，铰链连接，碰撞，悬挂等效果。一言蔽之，即是，将2D物理引擎引入了人UIKit。需要注意，UIKit动力学的引入，并不是以替代CA或者UIView动画为目的的，在绝大多数情况下CA或者UIView动画仍然是最优方案，只有在需要引入逼真的交互设计的时候，才需要使用UIKit动力学它是作为现有交互设计和实现的一种补充而存在的。

目的当然是更加自然和炫目的UI动画效果，比如模拟现实的拖拽和弹性效果，放在以前如果单用iOS SDK的动画实现起来还是相当困难的，而在UIKit Dynamics的帮助下，复杂的动画效果可能也只需要很短的代码（基本100行以内...其实现在用UIView animation想实现一个不太复杂的动画所要的代码行数都不止这个数了吧）。总之，便利多多，配合UI交互设计，以前很多不敢想和不敢写（至少不敢自己写）的效果实现起来会非常方便，也相信在iOS7的时代各色使用UIKit动力学的应用的在动画效果肯定会上升一个档次。

### 那么，应该怎么做呢

#### UIKit动力学实现的结构

为了实现动力UI，需要注册一套UI行为的体系，之后UI便会按照预先的设定进行运动了。我们应该了解的新的基本概念有如下四个：

<!--more-->

* UIDynamicItem：用来描述一个力学物体的状态，其实就是实现了UIDynamicItem委托的对象，或者抽象为有面积有旋转的质点；
* UIDynamicBehavior：动力行为的描述，用来指定UIDynamicItem应该如何运动，即定义适用的物理规则。一般我们使用这个类的子类对象来对一组UIDynamicItem应该遵守的行为规则进行描述；
* UIDynamicAnimator；动画的播放者，动力行为（UIDynamicBehavior）的容器，添加到容器内的行为将发挥作用；
* ReferenceView：等同于力学参考系，如果你的初中物理不是语文老师教的话，我想你知道这是啥..只有当想要添加力学的UIView是ReferenceView的子view时，动力UI才发生作用。

光说不练假把式，来做点简单的demo吧。比如为一个view添加重力行为：

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    aView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:aView];
    
    UIDynamicAnimator* animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior* gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[aView]];
    [animator addBehavior:gravityBeahvior];
    self.animator = animator;
}
```
代码很简单，

1. 以现在ViewController的view为参照系（ReferenceView），来初始化一个UIDynamicAnimator。
2. 然后分配并初始化一个动力行为，这里是UIGravityBehavior，将需要进行物理模拟的UIDynamicItem传入。`UIGravityBehavior`的`initWithItems:`接受的参数为包含id<UIDynamicItem>的数组，另外`UIGravityBehavior`实例还有一个`addItem:`方法接受单个的id<UIDynamicItem>。就是说，实现了UIDynamicItem委托的对象，都可以看作是被力学特性影响的，进而参与到计算中。UIDynamicItem委托需要我们实现`bounds`，`center`和`transform`三个属性，在UIKit Dynamics计算新的位置时，需要向Behavior内的item询问这些参数，以进行正确计算。iOS7中，UIView和UICollectionViewLayoutAttributes已经默认实现了这个接口，所以这里我们直接把需要模拟重力的UIView添加到UIGravityBehavior里就行了。
3. 把配置好的UIGravityBehavior添加到animator中。
4. strong持有一下animator，避免当前scope结束被ARC释放掉（后果当然就是UIView在哪儿傻站着不掉）

运行结果，view开始受重力影响了：

![重力作用下的UIview](/assets/images/2013/uikit-dynamics-gravity.gif)

#### 碰撞，我要碰撞

没有碰撞的话，物理引擎就没有任何意义了。和重力行为类似，碰撞也有一个`UIDynamicBehavior`子类来描述碰撞行为，即`UICollisionBehavior`。在上面的demo中加上几句：

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    aView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:aView];
    
    UIDynamicAnimator* animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior* gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[aView]];
    [animator addBehavior:gravityBeahvior];
    
    UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[aView]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:collisionBehavior];
    collisionBehavior.collisionDelegate = self;
    
    self.animator = animator;
}
```

也许聪明的你已经看到了，还是一样的，创建新的行为规则（UICollisionBehavior），然后加到animator中…唯一区别的地方是碰撞需要设定碰撞边界范围translatesReferenceBoundsIntoBoundary将整个参照view（也就是self.view）的边框作为碰撞边界（另外你还可以使用setTranslatesReferenceBoundsIntoBoundaryWithInsets:这样的方法来设定某一个区域作为碰撞边界，更复杂的边界可以使用addBoundaryWithIdentifier:forPath:来添加UIBezierPath，或者addBoundaryWithIdentifier:fromPoint:toPoint:来添加一条线段为边界，详细地还请查阅文档）；另外碰撞是有回调的，可以在self中实现`UICollisionBehaviorDelegate`。

最后，只是直直地掉下来的话未免太无聊了，加个角度吧：    

```objc
aView.transform = CGAffineTransformRotate(aView.transform, 45);
```

结果是这样的，帅死了…这在以前只用iOS SDK的话，够写上很长时间了吧..

![碰撞和重力同时作用的动力UI](/assets/images/2013/uikit-dynamics-collider.gif)

碰撞的delegate可以帮助我们了解碰撞的具体情况，包括哪个item和哪个item开始发生碰撞，碰撞接触点是什么，是否和边界碰撞，和哪个边界碰撞了等信息。这些回调方法保持了Apple一向的命名原则，所以通俗易懂。需要多说一句的是回调方法中对于ReferenceView的Bounds做边界的情况，BoundaryIdentifier将会是nil，自行添加的其他边界的话，ID自然是添加时指定的ID了。

* – collisionBehavior:beganContactForItem:withBoundaryIdentifier:atPoint:
* – collisionBehavior:beganContactForItem:withItem:atPoint:
* – collisionBehavior:endedContactForItem:withBoundaryIdentifier:
* – collisionBehavior:endedContactForItem:withItem:


#### 其他能实现的效果

除了重力和碰撞，iOS SDK还预先帮我们实现了一些其他的有用的物理行为，它们包括

* UIAttachmentBehavior 描述一个view和一个锚相连接的情况，也可以描述view和view之间的连接。attachment描述的是两个点之间的连接情况，可以通过设置来模拟无形变或者弹性形变的情况（再次希望你还记得这些概念，简单说就是木棒连接和弹簧连接两个物体）。当然，在多个物体间设定多个；UIAttachmentBehavior，就可以模拟多物体连接了..有了这些，似乎可以做个老鹰捉小鸡的游戏了- -…
* UISnapBehavior 将UIView通过动画吸附到某个点上。初始化的时候设定一下UISnapBehavior的initWithItem:snapToPoint:就行，因为API非常简单，视觉效果也很棒，估计它是今后非游戏app里会被最常用的效果之一了；
* UIPushBehavior 可以为一个UIView施加一个力的作用，这个力可以是持续的，也可以只是一个冲量。当然我们可以指定力的大小，方向和作用点等等信息。
* UIDynamicItemBehavior 其实是一个辅助的行为，用来在item层级设定一些参数，比如item的摩擦，阻力，角阻力，弹性密度和可允许的旋转等等

UIDynamicItemBehavior有一组系统定义的默认值，

* allowsRotation YES
* density 1.0
* elasticity 0.0
* friction 0.0
* resistance 0.0

所有的UIDynamicBehavior都是可以独立作用的，同时作用时也遵守力的合成。也就是说，组合使用行为可以达到一些较复杂的效果。举个例子，希望模拟一个drag物体然后drop后下落的过程，可以用如下代码：

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIDynamicAnimator* animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.square1]];

    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:collisionBehavior];

    UIGravityBehavior *g = [[UIGravityBehavior alloc] initWithItems:@[self.square1]];
    [animator addBehavior:g];
    
    self.animator = animator;
}


-(IBAction)handleAttachmentGesture:(UIPanGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan){
        
        CGPoint squareCenterPoint = CGPointMake(self.square1.center.x, self.square1.center.y - 100.0);
        CGPoint attachmentPoint = CGPointMake(-25.0, -25.0);

        UIAttachmentBehavior* attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.square1 point:attachmentPoint attachedToAnchor:squareCenterPoint];
        
        self.attachmentBehavior = attachmentBehavior;
        [self.animator addBehavior:attachmentBehavior];
        
    } else if ( gesture.state == UIGestureRecognizerStateChanged) {
        
        [self.attachmentBehavior setAnchorPoint:[gesture locationInView:self.view]];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.animator removeBehavior:self.attachmentBehavior];
    }
}
```

viewDidiLoad时先在现在环境中加入了重力，然后监测到pan时附加一个UIAttachmentBehavior，并在pan位置更新更新其锚点，此时UIAttachmentBehavior和UIGravityBehavior将同时作用（想象成一根木棒连着手指处和view）。在手势结束时将这个UIAttachmentBehavior移除，view将在重力作用下下落。整个过程如下图：

![Drag & Drop](/assets/images/2013/uikit-dynamics-dragdrop.gif)

### UIKit力学的物理学分析

既然是力学，那显然各种单位是很重要的。在现实世界中，理想情况下物体的运动符合牛顿第二运动定理，在国际单位制中，力的单位是牛顿（N），距离单位是米（m），时间单位是秒（s），质量单位是千克（kg）。根据地球妈妈的心情，我们生活在这样一套体制中：重力加速度约为9.8m/s^2 ，加速度的单位是m/s^2 ，速度单位是m/s，牛顿其实是kg·m/s^2 ，即1牛顿是让质量为1千克的物体产生1米每二次方秒的加速度所需要的力。

以上是帮助您回忆初中知识，而现在这一套体系在UIKit里又怎么样呢？这其实是每一个物理引擎都要讨论和明白的事情，UIKit的单位体制里由于m这个东西太过夸张，因此用等量化的点（point，之后简写为p）来代替。具体是这样的：UI重力加速度定义为1000p/s^2 ，这样的定义有两方面的考虑，一时为了简化，好记，确实1000比9.8来的只观好看，二是也算符合人们的直感：一个UIView从y=0开始自由落体落到屏幕底部所需的时间，在3.5寸屏幕上为0.98秒，4寸屏幕上为1.07秒，1秒左右的自由落体的视觉效果对人眼来说是很舒服能进行判断的。

那么UIView的质量又如何定义呢，这也是很重要的，并涉及到力作用和加速度下UIView的表现。苹果又给出了自己的“UIKit牛顿第二定律”，定义了1单位作用力相当于将一个100px100p的默认密度的UIView以100p/s^2 的加速度移动。这里需要注意默认密度这个假设，因为在UIDynamicItem的委托中并没有实现任何密度相关的定义，而是通过UIDynamicItemBehavior来附加指定的。默认情况下，密度值为1，这就相当于质量是10000单位的UIView在1单位的作用力下可以达到1/10的UI重力加速度。

这样类比之后的结论是，如果将1单位的UI力学中的力等同于1牛顿的话：

* 1000单位的UI质量，与现实世界中1kg的质量相当，即一个点等同一克；
* 屏幕的100像素的长度，约和现实世界中0.99米相当（完全可以看为1米）
* UI力学中的默认密度，约和现实世界的0.1kg/m^2 相当

可以说UIKit为我们构建了一套适应iOS屏幕的相当优雅的力学系统，不仅让人过目不忘，在实际的物理情景和用户体验中也近乎完美。在开发中，我们可以参照这些关系寻找现实中的例子，然后将其带入UIKit的力学系统中，以得到良好的模拟效果。

### UIKit动力学自定义

除了SDK预先定义好的行为以外，我们还可以自己定义想要的行为。这种定义可以发生在两个层级上，一种是将官方的行为打包，以简化实现。另一种是完全定义新的计算规则。

对于第一种，其实考虑一下上面的重力+边界碰撞，或者drag & drop行为，其实都是两个甚至多个行为的叠加。要是每次都这样设定一次的话，不是很辛苦么，还容易遗忘出错。于是一种好的方式是将它们打包封装一下。具体地，如下步骤：

1. 继承一下UIDynamicBehavior（在这里UIDynamicBehavior类似一个抽象类，并没有具体实现什么行为）
2. 在子类中实现一个类似其他内置行为初始化方法`initWithItems:`，用以添加物体和想要打包的规则。当然你如果喜欢用其他方式也行..只不过和自带的行为保持API统一对大家都有好处..添加item的话就用默认规则的initWithItems:就行，对于规则UIDynamicBehavior提供了一个addChildBehavior:的方法，来将其他规则加入到当前规则里
3. 没有第三步了，使用就行了。

一个例子，打包了碰撞和重力两种行为，定义之后使用时就只需要写一次了。当然这只是最简单的例子和运用，当行为复杂以后，这样的使用方法是不可避免的，否则管理起来会让人有想死的心。另外，将手势等交互的方式也集成之中，进一步封装调用细节会是不错的实践。

```objc
//GravityWithCollisionBehavior.h
@interface GravityWithCollisionBehavior : UIDynamicBehavior

-(instancetype) initWithItems:(NSArray *)items;

@end


//GravityWithCollisionBehavior.m
@implementation GravityWithCollisionBehavior

-(instancetype) initWithItems:(NSArray *)items
{
    if (self = [super init]) {
        UIGravityBehavior *gb = [[UIGravityBehavior alloc] initWithItems:items];
        UICollisionBehavior *cb = [[UICollisionBehavior alloc] initWithItems:items];
        cb.translatesReferenceBoundsIntoBoundary = YES;
        [self addChildBehavior:gb];
        [self addChildBehavior:cb];
    }
    return self;
}

@end
```

另一种比较高级一点，需要对计算完全定义。在默认的行为或者它们组合不能满足禽兽般的产品经理/设计师的需求是，亲爱的骚年..开始自己写吧..其实说简单也简单，UIDynamicBehavior里提供了一个`@property(nonatomic, copy) void (^action)(void)`，animator将在每次animation step（就是需要计算动画时）调用这个block。就是说，你可以通过设定这个block来实现自己的行为。基本思路就是在这个block中向所有item询问它们当前的center和transform状态，然后开始计算，然后把计算后的相应值再赋予item，从而改变在屏幕上的位置，大小，角度等。

### UIKit动力学的性能分析和限制

使用物理引擎不是没有代价的的，特别是在碰撞检测这块，是要耗费一定CPU资源的。但是以测试的情况来看，如果只是UI层面上的碰撞检测还是没有什么问题的，我自己实测iPhone4上同时进行数十个碰撞计算完全没有掉帧的情况。因此如果只是把其用在UI特效上，应该不用太在意资源的耗费。但是如果同时有成百上千的碰撞需要处理的情况，可能会出现卡顿吧。

对于UIDynamicItem来说，当它们被添加到动画系统后，我们只能通过动画系统来改变位置，而外部的对于UIDynamicItem的center,transform等设定是被忽略的（其实这也是大多数2D引擎的实现策略，算不上限制）。

主要的限制是在当计算迭代无法得到有效解的时候，动画将无法正确呈现。这对于绝大多数物理引擎都是一样的。迭代不能收敛时整个物理系统处于不确定的状态，比如初始时就设定了碰撞物体位于边界内部，或者在狭小空间内放入了过多的非弹性碰撞物体等。另外，这个引擎仅仅只是用来呈现UI效果，它并没有保证物理上的精确度，因此如果要用它来做UI以外的事情，有可能是无法得到很好的结果的。

### 总结

总之就是一套全新的UI交互的视觉体验和效果，但是并非处处适用。在合适的地方使用可以增加体验，但是也会有其他方式更适合的情况。所以拉上你的设计师好基友去开拓新的大陆吧…
