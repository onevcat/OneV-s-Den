---
layout: post
title: WWDC 2013 Session笔记 - iOS7中的ViewController切换
date: 2013-10-11 00:59:56.000000000 +09:00
tags: 能工巧匠集
---

![iOS7中的ViewController切换](/assets/images/2013/ios-transition-banner.jpg)

这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 201 Building User Interfaces for iOS 7
* Session 218 Custom Transitions Using View Controllers
* Session 226 Implementing Engaging UI on iOS

毫无疑问，ViewController（在本文中简写为VC）是使用MVC构建Cocoa或者CocoaTouch程序时最重要的一个类，我们的日常工作中一般来说最花费时间和精力的也是在为VC部分编写代码。苹果产品是注重用户体验的，而对细节进行琢磨也是苹果对于开发者一直以来的要求和希望。在用户体验中，VC之间的关系，比如不同VC之间迁移和转换动画效果一直是一个值得不断推敲的重点。在iOS7中，苹果给出了一套完整的VC制作之间迁移效果的方案，可以说是为现在这部分各种不同实现方案指出了一条推荐的统一道路。

### iOS 7 SDK之前的VC切换解决方案

在深入iOS 7的VC切换效果的新API实现之前，先让我们回顾下现在的一般做法吧。这可以帮助理解为什么iOS7要对VC切换给出新的解决方案，如果您对iOS 5中引入的VC容器比较熟悉的话，可以跳过这节。

在iOS5和iOS6中，除了标准的Push，Tab和PresentModal之外，一般是使用ChildViewController的方式来完成VC之间切换的过渡效果。ChildViewController和自定义的Controller容器是iOS 5 SDK中加入的，可以用来生成自定义的VC容器，简单来说典型的一种用法类似这样：

```objc
//ContainerVC.m

[self addChildViewController:toVC];
[fromVC willMoveToParentViewController:nil];
[self.view addSubview:toVC.view];

__weak id weakSelf = self;
[self transitionFromViewController:fromVC
                  toViewController:toVC duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{}
                        completion:^(BOOL finished) {
    [fromVC.view removeFromSuperView];
    [fromVC removeFromParentViewController];
    [toVC didMoveToParentViewController:weakSelf];
}];
```

在自己对view进行管理的同时，可以使用transitionFromViewController:toViewController:...的Animation block中可以实现一些简单的切换效果。去年年初我写的[UIViewController的误用](http://onevcat.com/2012/02/uiviewcontroller/)一文中曾经指出类似`[viewController.view addSubview:someOtherViewController.view];`这样的代码的存在，一般就是误用VC。这个结论适用于非Controller容器，对于自定义的Controller容器来说，向当前view上添加其他VC的view是正确的做法（当然不能忘了也将VC本身通过`addChildViewController:`方法添加到容器中）。

VC容器的主要目的是解决将不同VC添加到同一个屏幕上的需求，以及可以提供一些简单的自定义切换效果。使用VC容器可以使view的关系正确，使添加的VC能够正确接收到例如屏幕旋转，viewDidLoad:等VC事件，进而进行正确相应。VC容器确实可以解决一部分问题，但是也应该看到，对于自定义切换效果来说，这样的解决还有很多不足。首先是代码高度耦合，VC切换部分的代码直接写在container中，难以分离重用；其次能够提供的切换效果比较有限，只能使用UIView动画来切换，管理起来也略显麻烦。iOS 7提供了一套新的自定义VC切换，就是针对这两个问题的。

### iOS 7 自定义ViewController动画切换

#### 自定义动画切换的相关的主要API

在深入之前，我们先来看看新SDK中有关这部分内容的相关接口以及它们的关系和典型用法。这几个接口和类的名字都比较相似，但是还是能比较好的描述出各自的职能的，一开始的话可能比较迷惑，但是当自己动手实现一两个例子之后，它们之间的关系就会逐渐明晰起来。（相关的内容都定义在UIKit的[UIViewControllerTransitioning.h](https://gist.github.com/onevcat/6944809)中了）


#### @protocol [UIViewControllerContextTransitioning](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewControllerContextTransitioning_protocol/Reference/Reference.html)

这个接口用来提供切换上下文给开发者使用，包含了从哪个VC到哪个VC等各类信息，一般不需要开发者自己实现。具体来说，iOS7的自定义切换目的之一就是切换相关代码解耦，在进行VC切换时，做切换效果实现的时候必须要需要切换前后VC的一些信息，**系统在新加入的API的比较的地方都会提供一个实现了该接口的对象**，以供我们使用。

**对于切换的动画实现来说**（这里先介绍简单的动画，在后面我会再引入手势驱动的动画），这个接口中最重要的方法有：

* -(UIView *)containerView; VC切换所发生的view容器，开发者应该将切出的view移除，将切入的view加入到该view容器中。
* -(UIViewController *)viewControllerForKey:(NSString *)key; 提供一个key，返回对应的VC。现在的SDK中key的选择只有UITransitionContextFromViewControllerKey和UITransitionContextToViewControllerKey两种，分别表示将要切出和切入的VC。
* -(CGRect)initialFrameForViewController:(UIViewController *)vc; 某个VC的初始位置，可以用来做动画的计算。
* -(CGRect)finalFrameForViewController:(UIViewController *)vc; 与上面的方法对应，得到切换结束时某个VC应在的frame。
* -(void)completeTransition:(BOOL)didComplete; 向这个context报告切换已经完成。


#### @protocol [UIViewControllerAnimatedTransitioning](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewControllerAnimatedTransitioning_Protocol/Reference/Reference.html)

这个接口负责切换的具体内容，也即“切换中应该发生什么”。开发者在做自定义切换效果时大部分代码会是用来实现这个接口。它只有两个方法需要我们实现：

* -(NSTimeInterval)transitionDuration:(id < UIViewControllerContextTransitioning >)transitionContext; 系统给出一个切换上下文，我们根据上下文环境返回这个切换所需要的花费时间（一般就返回动画的时间就好了，SDK会用这个时间来在百分比驱动的切换中进行帧的计算，后面再详细展开）。

* -(void)animateTransition:(id < UIViewControllerContextTransitioning >)transitionContext; 在进行切换的时候将调用该方法，我们对于切换时的UIView的设置和动画都在这个方法中完成。

#### @protocol [UIViewControllerTransitioningDelegate](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewControllerTransitioningDelegate_protocol/Reference/Reference.html)

这个接口的作用比较简单单一，在需要VC切换的时候系统会像实现了这个接口的对象询问是否需要使用自定义的切换效果。这个接口共有四个类似的方法：

* -(id< UIViewControllerAnimatedTransitioning >)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source;
 
* -(id< UIViewControllerAnimatedTransitioning >)animationControllerForDismissedController:(UIViewController *)dismissed;
 
* -(id< UIViewControllerInteractiveTransitioning >)interactionControllerForPresentation:(id < UIViewControllerAnimatedTransitioning >)animator;
 
* -(id< UIViewControllerInteractiveTransitioning >)interactionControllerForDismissal:(id < UIViewControllerAnimatedTransitioning >)animator;
 
前两个方法是针对动画切换的，我们需要分别在呈现VC和解散VC时，给出一个实现了UIViewControllerAnimatedTransitioning接口的对象（其中包含切换时长和如何切换）。后两个方法涉及交互式切换，之后再说。

### Demo

还是那句话，一百行的讲解不如一个简单的小Demo，于是..it's demo time～ 整个demo的代码我放到了github的[这个页面](https://github.com/onevcat/VCTransitionDemo)上，有需要的朋友可以参照着看这篇文章。

我们打算做一个简单的自定义的modalViewController的切换效果。普通的present modal VC的效果大家都已经很熟悉了，这次我们先实现一个自定义的类似的modal present的效果，与普通效果不同的是，我们希望modalVC出现的时候不要那么乏味的就简单从底部出现，而是带有一个弹性效果（这里虽然是弹性，但是仅指使用UIView的模拟动画，而不设计iOS 7的另一个重要特性UIKit Dynamics。用UIKit Dynamics当然也许可以实现更逼真华丽的效果，但是已经超出本文的主题范畴了，因此不在这里展开了。关于UIKit Dynamics，可以参看我之前关于这个主题的[一篇介绍](http://onevcat.com/2013/06/uikit-dynamics-started/)）。我们首先实现简单的ModalVC弹出吧..这段非常基础，就交待了一下背景，非初级人士请跳过代码段..

先定义一个ModalVC，以及相应的protocal和delegate方法：

```objc
//ModalViewController.h

@class ModalViewController;
@protocol ModalViewControllerDelegate <NSObject>

-(void) modalViewControllerDidClickedDismissButton:(ModalViewController *)viewController;

@end

@interface ModalViewController : UIViewController
@property (nonatomic, weak) id<ModalViewControllerDelegate> delegate;
@end

//ModalViewController.m
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [button setTitle:@"Dismiss me" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

-(void) buttonClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(modalViewControllerDidClickedDismissButton:)]) {
        [self.delegate modalViewControllerDidClickedDismissButton:self];
    }
}

```

这个是很标准的modalViewController的实现方式了。需要多嘴一句的是，在实际使用中有的同学喜欢在-buttonClicked:中直接给self发送dismissViewController的相关方法。在现在的SDK中，如果当前的VC是被显示的话，这个消息会被直接转发到显示它的VC去。但是这并不是一个好的实现，违反了程序设计的哲学，也很容易掉到坑里，具体案例可以参看[这篇文章的评论](http://onevcat.com/2011/11/objc-block/)。

所以我们用标准的方式来呈现和解散这个VC：

```objc
//MainViewController.m

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [button setTitle:@"Click me" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

-(void) buttonClicked:(id)sender
{
    ModalViewController *mvc =  [[ModalViewController alloc] init];
    mvc.delegate = self;
    [self presentViewController:mvc animated:YES completion:nil];
}

-(void)modalViewControllerDidClickedDismissButton:(ModalViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
```

测试一下，没问题，然后我们可以开始实现自定义的切换效果了。首先我们需要一个实现了UIViewControllerAnimatedTransitioning的对象..嗯，新建一个类来实现吧，比如BouncePresentAnimation：

```objc
//BouncePresentAnimation.h
@interface BouncePresentAnimation : NSObject<UIViewControllerAnimatedTransitioning>

@end

//BouncePresentAnimation.m
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // 1. Get controllers from transition context
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // 2. Set init frame for toVC
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    toVC.view.frame = CGRectOffset(finalFrame, 0, screenBounds.size.height);
    
    // 3. Add toVC's view to containerView
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    
    // 4. Do animate now
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         toVC.view.frame = finalFrame;
                     } completion:^(BOOL finished) {
                         // 5. Tell context that we completed.
                         [transitionContext completeTransition:YES];
                     }];
}
```

解释一下这个实现：

1. 我们首先需要得到参与切换的两个ViewController的信息，使用context的方法拿到它们的参照；
2. 对于要呈现的VC，我们希望它从屏幕下方出现，因此将初始位置设置到屏幕下边缘；
3. 将view添加到containerView中；
4. 开始动画。这里的动画时间长度和切换时间长度一致，都为0.8s。usingSpringWithDamping的UIView动画API是iOS7新加入的，描述了一个模拟弹簧动作的动画曲线，我们在这里只做使用，更多信息可以参看[相关文档](https://developer.apple.com/library/ios/documentation/uikit/reference/uiview_class/UIView/UIView.html#//apple_ref/occ/clm/UIView/animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)；（顺便多说一句，iOS7中对UIView动画添加了一个很方便的Category，UIViewKeyframeAnimations。使用其中方法可以为UIView动画添加关键帧动画）
5. 在动画结束后我们必须向context报告VC切换完成，是否成功（在这里的动画切换中，没有失败的可能性，因此直接pass一个YES过去）。系统在接收到这个消息后，将对VC状态进行维护。

接下来我们实现一个UIViewControllerTransitioningDelegate，应该就能让它工作了。简单来说，一个比较好的地方是直接在MainViewController中实现这个接口。在MainVC中声明实现这个接口，然后加入或变更为如下代码：

```objc
@interface MainViewController ()<ModalViewControllerDelegate, UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) BouncePresentAnimation *presentAnimation;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _presentAnimation = [BouncePresentAnimation new];
    }
    return self;
}

-(void) buttonClicked:(id)sender
{
    //...
    mvc.transitioningDelegate = self;
    //...
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self.presentAnimation;
}
```

Believe or not, we have done. 跑一下，应该可以得到如下效果：

![BouncePresentAnimation的实际效果](/assets/images/2013/custom-vc-transition-1.gif)

### 手势驱动的百分比切换

iOS7引入了一种手势驱动的VC切换的方式（交互式切换）。如果你使用系统的各种应用，在navViewController里push了一个新的VC的话，返回时并不需要点击左上的Back按钮，而是通过从屏幕左侧划向右侧即可完成返回操作。而在这个操作过程中，我们甚至可以撤销我们的手势，以取消这次VC转移。在新版的Safari中，我们甚至可以用相同的手势来完成网页的后退功能（所以很大程度上来说屏幕底部的工具栏成为了摆设）。如果您还不知道或者没太留意过这个改动，不妨现在就拿手边的iOS7这辈试试看，手机浏览的朋友记得切回来哦 :)

我们这就动手在自己的VC切换中实现这个功能吧，首先我们需要在刚才的知识基础上补充一些东西：

首先是UIViewControllerContextTransitioning，刚才提到这个是系统提供的VC切换上下文，如果您深入看了它的头文件描述的话，应该会发现其中有三个关于InteractiveTransition的方法，正是用来处理交互式切换的。但是在初级的实际使用中我们其实可以不太理会它们，而是使用iOS 7 SDK已经给我们准备好的一个现成转为交互式切换而新加的类：UIPercentDrivenInteractiveTransition。

#### [UIPercentDrivenInteractiveTransition](https://developer.apple.com/library/ios/documentation/uikit/reference/UIPercentDrivenInteractiveTransition_class/Reference/Reference.html)是什么

这是一个实现了UIViewControllerInteractiveTransitioning接口的类，为我们预先实现和提供了一系列便利的方法，可以用一个百分比来控制交互式切换的过程。一般来说我们更多地会使用某些手势来完成交互式的转移（当然用的高级的话用其他的输入..比如声音，iBeacon距离或者甚至面部微笑来做输入驱动也无不可，毕竟想象无极限嘛..），这样使用这个类（一般是其子类）的话就会非常方便。我们在手势识别中只需要告诉这个类的实例当前的状态百分比如何，系统便根据这个百分比和我们之前设定的迁移方式为我们计算当前应该的UI渲染，十分方便。具体的几个重要方法：

* -(void)updateInteractiveTransition:(CGFloat)percentComplete 更新百分比，一般通过手势识别的长度之类的来计算一个值，然后进行更新。之后的例子里会看到详细的用法
* -(void)cancelInteractiveTransition 报告交互取消，返回切换前的状态
* –(void)finishInteractiveTransition 报告交互完成，更新到切换后的状态

#### @protocol [UIViewControllerInteractiveTransitioning](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewControllerInteractiveTransitioning_protocol/Reference/Reference.html)

就如上面提到的，UIPercentDrivenInteractiveTransition只是实现了这个接口的一个类。为了实现交互式切换的功能，我们需要实现这个接口。因为大部分时候我们其实不需要自己来实现这个接口，因此在这篇入门中就不展开说明了，有兴趣的童鞋可以自行钻研。

还有就是上面提到过的UIViewControllerTransitioningDelegate中的返回Interactive实现对象的方法，我们同样会在交互式切换中用到它们。

### 继续Demo

Demo time again。在刚才demo的基础上，这次我们用一个向上划动的手势来吧之前呈现的ModalViewController给dismiss掉～当然是交互式的切换，可以半途取消的那种。

首先新建一个类，继承自UIPercentDrivenInteractiveTransition，这样我们可以省不少事儿。

```objc
//SwipeUpInteractiveTransition.h
@interface SwipeUpInteractiveTransition : UIPercentDrivenInteractiveTransition

@property (nonatomic, assign) BOOL interacting;

- (void)wireToViewController:(UIViewController*)viewController;

@end

//SwipeUpInteractiveTransition.m
@interface SwipeUpInteractiveTransition()
@property (nonatomic, assign) BOOL shouldComplete;
@property (nonatomic, strong) UIViewController *presentingVC;
@end

@implementation SwipeUpInteractiveTransition
-(void)wireToViewController:(UIViewController *)viewController
{
    self.presentingVC = viewController;
    [self prepareGestureRecognizerInView:viewController.view];
}

- (void)prepareGestureRecognizerInView:(UIView*)view {
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [view addGestureRecognizer:gesture];
}

-(CGFloat)completionSpeed
{
    return 1 - self.percentComplete;
}

- (void)handleGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            // 1. Mark the interacting flag. Used when supplying it in delegate.
            self.interacting = YES;
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            break;
        case UIGestureRecognizerStateChanged: {
            // 2. Calculate the percentage of guesture
            CGFloat fraction = translation.y / 400.0;
            //Limit it between 0 and 1
            fraction = fminf(fmaxf(fraction, 0.0), 1.0);
            self.shouldComplete = (fraction > 0.5);

            [self updateInteractiveTransition:fraction];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 3. Gesture over. Check if the transition should happen or not
            self.interacting = NO;
            if (!self.shouldComplete || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            break;
        }
        default:
            break;
    }
}

@end

```

有点长，但是做的事情还是比较简单的。

1. 我们设定了一个BOOL变量来表示是否处于切换过程中。这个布尔值将在监测到手势开始时被设置，我们之后会在调用返回这个InteractiveTransition的时候用到。
2. 计算百分比，我们设定了向下划动400像素或以上为100%，每次手势状态变化时根据当前手势位置计算新的百分比，结果被限制在0～1之间。然后更新InteractiveTransition的百分数。
3. 手势结束时，把正在切换的标设置回NO，然后进行判断。在2中我们设定了手势距离超过设定一半就认为应该结束手势，否则就应该返回原来状态。在这里使用其进行判断，已决定这次transition是否应该结束。

接下来我们需要添加一个向下移动的UIView动画，用来表现dismiss。这个十分简单，和BouncePresentAnimation很相似，写一个NormalDismissAnimation的实现了UIViewControllerAnimatedTransitioning接口的类就可以了，本文里略过不写了，感兴趣的童鞋可以自行查看源码。

最后调整MainViewController的内容，主要修改点有三个地方：

```objc
//MainViewController.m
@interface MainViewController ()<ModalViewControllerDelegate,UIViewControllerTransitioningDelegate>
//...
// 1. Add dismiss animation and transition controller
@property (nonatomic, strong) NormalDismissAnimation *dismissAnimation;
@property (nonatomic, strong) SwipeUpInteractiveTransition *transitionController;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
 	//...
        _dismissAnimation = [NormalDismissAnimation new];
        _transitionController = [SwipeUpInteractiveTransition new];
	//...
}

-(void) buttonClicked:(id)sender
{
	//...
	// 2. Bind current VC to transition controller.
    [self.transitionController wireToViewController:mvc];
	//...
}

// 3. Implement the methods to supply proper objects.
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self.dismissAnimation;
}

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.transitionController.interacting ? self.transitionController : nil;
}

```

1. 在其中添加dismiss时候的动画和交互切换Controller
2. 在初始化modalVC的时候为交互切换的Controller绑定VC 
3. 为UIViewControllerTransitioningDelegate实现dismiss时候的委托方法，包括返回对应的动画以及交互切换Controller

完成了，如果向下划动时，效果如下：

![交互驱动的VC转移](/assets/images/2013/custom-vc-transition-2.gif)


### 关于iOS 7中自定义VC切换的一些总结

demo中只展示了对于modalVC的present和dismiss的自定义切换效果，当然对与Navigation Controller的Push和Pop切换也是有相应的一套方法的。实现起来和dismiss十分类似，只不过对应UIViewControllerTransitioningDelegate的询问动画和交互的方法换到了UINavigationControllerDelegate中（为了区别push或者pop，看一下这个接口应该能马上知道）。另外一个很好的福利是，对于标准的navController的Pop操作，苹果已经替我们实现了手势驱动返回，我们不用再费心每个去实现一遍了，cheers～

另外，可能你会觉得使用VC容器其提供的transition动画方法来进行VC切换就已经够好够方便了，为什么iOS7中还要引入一套自定义的方式呢。其实从根本来说它们所承担的是两类完全不同的任务：自定义VC容器可以提供自己定义的VC结构，并保证系统的各类方法和通知能够准确传递到合适的VC，它提供的transition方法虽然可以实现一些简单的UIView动画，但是难以重用，可以说是和containerVC完全耦合在一起的；而自定义切换并不改变VC的组织结构，只是负责提供view的效果，因为VC切换将动画部分、动画驱动部分都使用接口的方式给出，因此重用性非常优秀。在绝大多数情况下，精心编写的一套UIView动画是可以轻易地用在不同的VC中，甚至是不同的项目中的。

需要特别一提的是，Github上的[ColinEberhardt的VCTransitionsLibrary](https://github.com/ColinEberhardt/VCTransitionsLibrary)已经为我们提供了一系列的VC自定义切换动画效果，正是得益于iOS7中这一块的良好设计（虽然这几个接口的命名比较相似，在弄明白之前会有些confusing），因此这些效果使用起来非常方便，相信一般项目中是足够使用的了。而其他更复杂或者炫目的效果，亦可在其基础上进行扩展改进得到。可以说随着越来越多的应用转向iOS7，自定义VC切换将成为新的用户交互实现的基础和重要部分，对于今后会在其基础上会衍生出怎样让人眼前一亮的交互设计，不妨让我们拭目以待（或者自己努力去创造）。
