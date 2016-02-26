---
layout: post
title: WWDC 2013 Session笔记 - SpriteKit快速入门和新时代iOS游戏开发指南
date: 2013-06-16 00:51:18.000000000 +09:00
tags: 能工巧匠集
---

![SpriteKit，iOS/Mac游戏制作的新纪元](/assets/images/2013/spritekit-intro.png)

这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 502 Introduction to Sprite Kit
* Session 503 Designing Games with Sprite Kit

SpriteKit的加入绝对是iOS 7/OSX 10.9的SDK最大的亮点。从此以后官方SDK也可以方便地进行游戏制作了。

如果你在看这篇帖子，那我估计你应该稍微知道一些iOS平台上2D游戏开发的东西，比如cocos2d，那很好，因为SpriteKit的很多概念其实和cocos2d非常类似，你应该能很快掌握。如果上面这张图你看着眼熟，或者自己动手实践过，那更好，因为这篇文章的内容就是通过使用SpriteKit来一步一步带你重新实践一遍这个经典教程。如果你既不知道cocos2d，更没有使用游戏引擎开发iOS游戏的经验，只是想一窥游戏开发的天地，那现在，SpriteKit将是一个非常好的入口，因为是iOS SDK自带的框架，因此思想和用法上和现有的其他框架是统一的，这极大地降低了学习的难度和门槛。

### 什么是SpriteKit

首先要知道什么是`Sprite`。Sprite的中文译名就是精灵，在游戏开发中，精灵指的是以图像方式呈现在屏幕上的一个图像。这个图像也许可以移动，用户可以与其交互，也有可能仅只是游戏的一个静止的背景图。塔防游戏中敌方源源不断涌来的每个小兵都是一个精灵，我方防御塔发出的炮弹也是精灵。可以说精灵构成了游戏的绝大部分主体视觉内容，而一个2D引擎的主要工作，就是高效地组织，管理和渲染这些精灵。SpriteKit是在iOS7 SDK中Apple新加入的一个2D游戏引擎框架，在SpriteKit出现之前，iOS开发平台上已经出现了像cocos2d这样的比较成熟的2D引擎解决方案。SpriteKit展现出的是Apple将Xcode和iOS/Mac SDK打造成游戏引擎的野心，但是同时也确实与IDE有着更好的集成，减少了开发者的工作。

### Hello SpriteKit

废话不多说，本文直接上实例教程来说明SpriteKit的基本用法。

<!--more-->

好吧，我要做的是将非常风靡流行妇孺皆知的[raywenderlich的经典cocos2d教程](http://www.raywenderlich.com/25736/how-to-make-a-simple-iphone-game-with-cocos2d-2-x-tutorial)使用全新的SpriteKit重新实现一遍。重做这个demo的主要原因是cocos2d的这个入门实在是太经典了，包括了精灵管理，交互检测，声音播放和场景切换等等方面的内容，麻雀虽小，却五脏俱全。这个小demo讲的是一个无畏的英雄抵御外敌侵略的故事，英雄在画面左侧，敌人源源不断从右侧涌来，通过点击屏幕发射飞镖来消灭敌人，阻止它们越过屏幕左侧边缘。在示例中用到的素材，可以从[这里下载](/assets/images/2013/ResourcePackSpriteKit.zip)。另外为了方便大家，整个工程示例我也放在了github上，[传送门在此](https://github.com/onevcat/SpriteKitSimpleGame)。

### 配置工程

首先当然是建立工程，Xcode5提供了SpriteKit模板，使用该模板建立新工程，名字就叫做SpriteKitSimpleGame好了。

![新建一个SpriteKit工程](/assets/images/2013/spritekit-create.png)

因为我们需要一个横屏游戏，所以在新建工程后，在工程设定的General标签中，把Depoyment Info中Device Orientation中的Portrait勾去掉，使应用只在横屏下运行。另外，为了使之后的工作轻松一些，我们可以选择在初始的view显示完成，尺寸通过rotation计算完毕之后再添加新的Scene，这样得到的Scene的尺寸将是宽480（或者568）高320的size。如果在appear之前就使用bounds.size添加的话，将得到宽320 高480（568）的size，会很麻烦。将ViewController.m中的`-viewDidLoad:`方法全部替换成下面的`-viewDidAppear:`。

```objc
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}
```

然后编译运行，应如果一切正常，该显示类似于下面的画面，每点击画面时，会出现一架不停旋转的飞机。

![SpriteKit正常运行](/assets/images/2013/sprite-kit-begin-screen.png)

### 加入精灵

SpriteKit是基于场景（Scene）来组织的，每个SKView（专门用来呈现SpriteKit的View）中可以渲染和管理一个SKScene，每个Scene中可以装载多个精灵（或者其他Node，之后会详细说明），并管理它们的行为。

现在让我们在这个Scene里加一个精灵吧，先从我们的英雄开始。首先要做的是把刚才下载的素材导入到工程中。我们这次用资源目录（Asset Catalog）来管理资源吧。点击工程中的`Images.xcassets`，以打开Asset Catalog。将下载解压后Art文件夹中的图片都拖入到打开的资源目录中，资源目录会自动根据文件的命名规则识别图片，1x的图片将用于iPhone4和iPad3之前的非retina设备，2x的图片将用于retina设备。当然，如果你对设备性能有信心的话，也可以把1x的图片删除掉，这样在非retina设备中也将使用2x的高清图（画面上的大小自然会帮你缩小成2x的一半），以获取更好的视觉效果。做完这一步后，工程的资源目录会是这个样子的：

![将图片素材导入工程中](/assets/images/2013/spritekit-import-images.png)

开始coding吧～默认的SpriteKit模板做的事情就是在ViewController的self.view（这个view是一个SKView，可以到storyboard文件中确认一下）中加入并显示了一个SKScene的子类实例MyScene。正如在做app开发时我们主要代码量会集中在ViewController一样，在用SpriteKit进行游戏开发时，因为所有游戏逻辑和精灵管理都会在Scene中完成，我们的代码量会集中在SKScene中。在MyScene.m中，把原来的`-initWithSize`替换成这样：

```objc
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */

        //1 Set background color for this scene
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        //2 Create a new sprite
        SKSpriteNode *player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        
        //3 Set it's position to the center right edge of screen
        player.position = CGPointMake(player.size.width/2, size.height/2);
        
        //4 Add it to current scene
        [self addChild:player];
    }
    return self;
}
```

1. 因为默认工程的Scene背景偏黑，而我们的主角和怪物也都是黑色的，所以先设定为白色。SKColor只是一个define定义而已，在iOS平台下被定义为UIColor，在Mac下被定义为NSColor。在SpriteKit开发时，尽量使用SK开头的对应的UI类可以统一代码而减少跨iOS和Mac平台的成本。类似的定义还有SKView，它在iOS下是UIView的子类，在Mac下是NSView的子类。
2. 在SpriteKit中初始化一个精灵很简单，直接用`SKSpriteNode`的`+spriteNodeWithImageNamed:`，指定图片名就行。实际上一个SKSpriteNode中包含了贴图（SKTexture对象），颜色，尺寸等等参数，这个简便方法为我们读取图片，生成SKTexture，并设定精灵尺寸和图片大小一致。在实际使用中，绝大多数情况这个简便方法就足够了。
3. 设定精灵的位置。SpriteKit中的坐标系和其他OpenGL游戏坐标系是一致的，屏幕左下角为(0,0)。不过需要注意的是不论是横屏还是竖屏游戏，view的尺寸都是按照竖屏进行计算的，即对于iPhone来说在这里传入的sizewidth是320，height是480或者568，而不会因为横屏而发生交换。因此在开发时，请千万不要使用绝对数值来进行位置设定及计算（否则你会死的很难看啊很难看）。
4. 把player加入到当前scene中，addChild接受SKNode对象（SKSprite是SKNode的子类），关于SKNode稍后再说。

运行游戏，yes～主角出现在屏幕上了。

![在屏幕左侧添加了一个精灵](/assets/images/2013/sprite-kit-add-player.png)

### 源源不断涌来的怪物大军

没有怪物的陪衬，主角再潇洒也是寂寞。添加怪物精灵的方法和之前添加主角没什么两样，生成精灵，设定位置，加到scene中。区别在于怪物是会移动的 & 怪物是每隔一段时间就会出现一个的。

在MyScene.m中，加入一个方法`-addMonster`

```objc
- (void) addMonster {
    
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    //1 Determine where to spawn the monster along the Y axis
    CGSize winSize = self.size;
    int minY = monster.size.height / 2;
    int maxY = winSize.height - monster.size.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;

    //2 Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPointMake(winSize.width + monster.size.width/2, actualY);
    [self addChild:monster];
    
    //3 Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    //4 Create the actions. Move monster sprite across the screen and remove it from scene after finished.
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY)
                                   duration:actualDuration];
    SKAction *actionMoveDone = [SKAction runBlock:^{
        [monster removeFromParent];
    }];
    [monster runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
    
}
```

1. 计算怪物的出生点（移动开始位置）的Y值。怪物从右侧屏幕外随机的高度处进入屏幕，为了保证怪物图像都在屏幕范围内，需要指定最小和最大Y值。然后从这个范围内随机一个Y值作为出生点。
2. 设定出生点恰好在屏幕右侧外面，然后添加怪物精灵。
3. 怪物要是匀速过来的话太死板了，加一点随机量，这样怪物有快有慢不会显得单调
4. 建立SKAction。SKAction可以操作SKNode，完成诸如精灵移动，旋转，消失等等。这里声明了两个SKAction，`actionMove`负责将精灵在`actualDuration`的时间间隔内移动到结束点（直线横穿屏幕）；`actionMoveDone`负责将精灵移出场景，其实是run一段接受到的block代码。`runAction`方法可以让精灵执行某个操作，而在这里我们要做的是先将精灵移动到结束点，当移动结束后，移除精灵。我们需要的是一个顺序执行，这里sequence:可以让我们顺序执行多个action。

然后尝试在上面的`-initWithSize:`里调用这个方法看看结果

```objc
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
		//...
		[self addChild:player];
		[self addMonster];
    }
    return self;
}
```
![在游戏中加入会动的敌人](/assets/images/2013/spritekit-add-moving-monster.png)

Cool，我们的游戏有个能动的图像。知道么，游戏的本质是什么？就是一堆能动的图像！

只有一个怪物的话，英雄大大还是很寂寞，所以我们说好了会有源源不断的怪物..在`-initWithSize:`的4之后加入以下代码

```objc
	//...
    //5 Repeat add monster to the scene every 1 second.
    SKAction *actionAddMonster = [SKAction runBlock:^{
        [self addMonster];
    }];
    SKAction *actionWaitNextMonster = [SKAction waitForDuration:1];
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[actionAddMonster,actionWaitNextMonster]]]];
	//...
```

这里声明了一个SKAction的序列，run一个block，然后等待1秒。用这个动作序列用`-repeatActionForever:`生成一个无限重复的动作，然后让scene执行。这样就可以实现每秒调用一次`-addMonster`来向场景中不断添加敌人了。如果你对Cocoa（Touch）开发比较熟悉的话，可能会说，为什么不用一个NSTimer来做同样的事情，而要写这样的SKAction呢？能不能用NSTimer来达到同样的目的？答案是在对场景或者精灵等SpriteKit对象进行类似操作时，尽量不要用NSTimer。因为NSTimer将不受SpriteKit的影响和管理，使用SKAction可以不加入其它任何代码就获取如下好处：

* 自动暂停和继续，当设定一个SKNode的`paused`属性为YES时，这个SKNode和它管理的子node的action都会自动被暂停。这里详细说明一下SKNode的概念：SKNode是SpriteKit中要素的基本组织方式，它代表了SKView中的一种游戏资源的组织方式。我们现在接触到的SKScene和SKSprite都是SKNode的子类，而一个SKNode可以有很多的子Node，从而构成一个SKNode的树。在我们的例子中，MyScene直接加在SKView中作为最root的node存在，而英雄或者敌人的精灵都作为Scene这个node的子node被添加进来。SKAction和node上的各种属性的的作用范围是当前这个node和它的所有子node，在这里我们如果设定MySecnen这个node（也就是self）的`paused`属性被设为YES的话，所有的Action都会被暂停，包括这个每隔一秒调用一次的action，而如果你用NSTimer的话，恭喜，你必须自行维护它的状态。
* 当SKAction依附的结点被从结点树中拿掉的时候，这个action会自动结束并停止，这是符合一般逻辑的。

编译，运行，一切如我们所预期的那样，每个一秒有一个怪物从右侧进入，并以不同的速度穿过屏幕。

![添加了源源不断滚滚而来的敌人大军](/assets/images/2013/sprtekit-monsters.gif)

### 奥特曼打小怪兽是天经地义的

有了英雄，有了怪兽，就差一个“打”了。我们打算做的是在用户点击屏幕某个位置时，就由英雄所在的位置向点击位置发射一枚固定速度的飞镖。然后这每飞镖要是命中怪物的话，就把怪物从屏幕中移除。

先来实现发射飞镖吧。检测点击，然后让一个精灵朝向点击的方向以某个速度移动，有很多种SKAction可以实现，但是为了尽量保持简单，我们使用上面曾经使用过的`moveTo:duration:`吧。在发射之前，我们先要来做一点基本的数学运算，希望你还能记得相似三角形之类的概念。我们的飞镖是由英雄发出的，然后经过手指点击的点，两点决定一条直线。简单说我们需要求解出这条直线和屏幕右侧边缘外的交点，以此来确定飞镖的最终目的。一旦我们得到了这个终点，就可以控制飞镖moveTo到这个终点，从而模拟出发射飞镖的action了。如图所示，很简单的几何学，关于具体的计算就不再讲解了，要是算不出来的话，请考虑call你的中学数学老师并负荆请罪以示诚意。

![通过点击计算飞镖终止位置](/assets/images/2013/spritekit-math.png)

然后开始写代码吧，还记得我们之前点击会出现一个飞机的精灵么，找到相应的地方，MyScene.m里的`-touchesBegan:withEvent:`：，用下面的代码替换掉原来的。

```objc
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        //1 Set up initial location of projectile
        CGSize winSize = self.size;
        SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile.png"];
        projectile.position = CGPointMake(projectile.size.width/2, winSize.height/2);
        
        //2 Get the touch location tn the scene and calculate offset
        CGPoint location = [touch locationInNode:self];
        CGPoint offset = CGPointMake(location.x - projectile.position.x, location.y - projectile.position.y);
        
        // Bail out if you are shooting down or backwards
        if (offset.x <= 0) return;
        // Ok to add now - we've double checked position
        [self addChild:projectile];
        
        int realX = winSize.width + (projectile.size.width/2);
        float ratio = (float) offset.y / (float) offset.x;
        int realY = (realX * ratio) + projectile.position.y;
        CGPoint realDest = CGPointMake(realX, realY);
        
        //3 Determine the length of how far you're shooting
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
        float velocity = self.size.width/1; // projectile speed. 
        float realMoveDuration = length/velocity;
        
        //4 Move projectile to actual endpoint
        [projectile runAction:[SKAction moveTo:realDest duration:realMoveDuration] completion:^{
            [projectile removeFromParent];
        }];
    }
}
```

1. 为飞镖设定初始位置。
2. 将点击的位置转换为node的坐标系的坐标，并计算点击位置和飞镖位置的偏移量。如果点击位置在飞镖初始位置的后方，则直接返回
3. 根据相似三角形计算屏幕右侧外的结束位置。
4. 移动飞镖，并在移动结束后将飞镖从场景中移除。注意在移动怪物的时候我们用了两个action（actionMove和actionMoveDone来做移动+移除），这里只使用了一个action并用带completion block移除精灵。这里对飞镖的这种做法是比较简明常见高效的，之前的做法只是为了说明action的`sequence:`的用法。

运行看看现在的游戏吧，我们有英雄有怪物还有打怪物的小飞镖，好像气氛上已经开始有趣了！

![加入飞镖之后，游戏开始变得有趣了](/assets/images/2013/spritekit-add-projectile.gif)

### 飞镖击中的检测

但是一个严重的问题是，现在的飞镖就算接触到了怪物也是直穿而过，完全就是空气一般的存在。为什么？因为我们还没有写任何检测飞镖和怪物的接触的代码（废话）。我们想要做的是在飞镖和怪物接触到的时候，将它们都移出场景，这样看起来就像是飞镖打中了怪物，并且把怪物消灭了。

基本思路是在每隔一个小的时间间隔，就扫描一遍场景中现存的飞镖和怪物。这里就需要提到SpriteKit中最基本的每一帧的周期概念。

![SpriteKit的更新周期](/assets/images/2013/spritekit-update_loop.png)

在iOS传统的view的系统中，view的内容被渲染一次后就将一直等待，直到需要渲染的内容发生改变（比如用户发生交互，view的迁移等）的时候，才进行下一次渲染。这主要是因为传统的view大多工作在静态环境下，并没有需要频繁改变的需求。而对于SpriteKit来说，其本身就是用来制作大多数时候是动态的游戏的，为了保证动画的流畅和场景的持续更新，在SpriteKit中view将会循环不断地重绘。

动画和渲染的进程是和SKScene对象绑定的，只有当场景被呈现时，这些渲染以及其中的action才会被执行。SKScene实例中，一个循环按执行顺序包括

* 每一帧开始时，SKScene的`-update:`方法将被调用，参数是从开始时到调用时所经过的时间。在该方法中，我们应该实现一些游戏逻辑，包括AI，精灵行为等等，另外也可以在该方法中更新node的属性或者让node执行action
* 在update执行完毕后，SKScene将会开始执行所有的action。因为action是可以由开发者设定的（还记得runBlock:么），因此在这一个阶段我们也是可以执行自己的代码的。
* 在当前帧的action结束之后，SKScene的`-didEvaluateActions`将被调用，我们可以在这个方法里对结点做最后的调整或者限制，之后将进入物理引擎的计算阶段。
* 然后SKScene将会开始物理计算，如果在结点上添加了SKPhysicsBody的话，那么这个结点将会具有物理特性，并参与到这个阶段的计算。根据物理计算的结果，SpriteKit将会决定结点新的状态。
* 然后`-didSimulatePhysics`会被调用，这类似之前的`-didEvaluateActions`。这里是我们开发者能参与的最后的地方，是我们改变结点的最后机会。
* 一帧的最后是渲染流程，根据之前设定和计算的结果对整个呈现的场景进行绘制。完成之后，SpriteKit将开始新的一帧。

在了解了一些SpriteKit的基础概念后，回到我们的demo。检测场景上每个怪物和飞镖的状态，如果它们相撞就移除，这是对精灵的计算的和操作，我们可以将其放到`-update:`方法中来处理。在此之前，我们需要保存一下添加到场景中的怪物和飞镖，在MyScene.m的@implementation之前加入下面的声明：

```objc
@interface MyScene()
@property (nonatomic, strong) NSMutableArray *monsters;
@property (nonatomic, strong) NSMutableArray *projectiles;
@end
```

然后在`-initWithSize:`中配置场景之前，初始化这两个数组：

```objc
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        self.monsters = [NSMutableArray array];
        self.projectiles = [NSMutableArray array];
        
        //...
    }
    return self;
}
```
在将怪物或者飞镖加入场景中的同时，分别将它们加入到数组中，
```objc
-(void) addMonster {
	//...
	
	[self.monsters addObject:monster];
}
```

```objc
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
		//...
	
        [self.projectiles addObject:projectile];
	}
}
```

同时，在将它们移除场景时，将它们移出所在数组，分别在`[monster removeFromParent]`和`[projectile removeFromParent]`后加入`[self.monsters removeObject:monster]`和`[self.projectiles removeObject:projectile]`。接下来终于可以在`-update:`中检测并移除了：

```objc
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (SKSpriteNode *projectile in self.projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (SKSpriteNode *monster in self.monsters) {
            
            if (CGRectIntersectsRect(projectile.frame, monster.frame)) {
                [monstersToDelete addObject:monster];
            }
        }
        
        for (SKSpriteNode *monster in monstersToDelete) {
            [self.monsters removeObject:monster];
            [monster removeFromParent];
        }
        
        if (monstersToDelete.count > 0) {
            [projectilesToDelete addObject:projectile];
        }
    }
    
    for (SKSpriteNode *projectile in projectilesToDelete) {
        [self.projectiles removeObject:projectile];
        [projectile removeFromParent];
    }
}
```

代码比较简单，不多解释了。直接运行看结果

![发射飞镖，消灭敌人！](/assets/images/2013/spritekit-hit.gif)

### 播放声音

音效绝对是游戏的一个重要环节，还记得一开始下载的那个资源文件压缩包么？里面除了Art文件夹外还有个Sounds文件夹，我们把Sounds加入工程里，整个文件夹拖到工程导航里面，然后勾上“Copy item”。

我们想在发射飞镖时播出一个音效，对于音效的播放是十分简单的，SpriteKit为我们提供了一个action，用来播放单个音效。因为每次的音效是相同的，所以只需要在一开始加载一次action，之后就一直使用这个action，以提高效率。先在MyScene.m的@interface中加入

```objc
@property (nonatomic, strong) SKAction *projectileSoundEffectAction;
```

然后在`-initWithSize:`一开始的地方加入

```objc
self.projectileSoundEffectAction = [SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO];
```

最后，修改发射飞镖的action，使播放音效的action和移动精灵的action同时执行。将`-touchesBegan:withEvent:`最后runAction的部分改为

```objc
//...
//4 Move projectile to actual endpoint and play the throw sound effect
SKAction *moveAction = [SKAction moveTo:realDest duration:realMoveDuration];
SKAction *projectileCastAction = [SKAction group:@[moveAction,self.projectileSoundEffectAction]];
[projectile runAction:projectileCastAction completion:^{
    [projectile removeFromParent];
    [self.projectiles removeObject:projectile];
}];

//...
```

之前我们介绍了用`-sequence:`连接不同的action，使它们顺序串行执行。在这里我们用了另一个方便的方法，`-group:`可以范围一个新的action，这个action将并行同时开始执行传入的所有action。在这里我们在飞镖开始移动的同时，播放了一个pew-pew-lei的音效（音效效果请下载demo试听，或者自行脑补…）。

游戏中音效一般来说至少会有效果音（SE）和背景音（BGM）两种，SE可以用SpriteKit的action来解决，而BGM就要惨一些，至少写这篇教程的时候，SpriteKit还没有一个BGM的专门的对应方案（如果之后新加了的话我会更新本教程）。所以现在我们使用传统的播放较长背景音乐的方法来实现背景音，那就是用`AVAudioPlayer`。在@interface MyScene()中加入一个bgmPlayer的声明，然后在`-initWithSize:`中加载背景音并一直播放。

```objc
@interface MyScene()
//...
@property (nonatomic, strong) AVAudioPlayer *bgmPlayer;
//...
@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {
//...
        NSString *bgmPath = [[NSBundle mainBundle] pathForResource:@"background-music-aac" ofType:@"caf"];
        self.bgmPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:bgmPath] error:NULL];
        self.bgmPlayer.numberOfLoops = -1;
        [self.bgmPlayer play];
//...
}
```

AVAudioPlayer用来播放背景音乐相当的合适，唯一的问题是有可能你想在暂停的时候停止这个背景音乐的播放。因为使用的是SpriteKit以外的框架，而并非action，因此BGM的播放不会随着设置Scene为暂停或者移除这个Scene而停止。想要停止播放，必须手动显式地调用`[self.bgmPlayer stop]`，可以说是比较麻烦，不过有时候你不并不想在暂停或者场景切换的时候中断背景音乐的话，这反倒是一个好的选择。

### 结果计算和场景切换

到现在为止，整个关卡作为一个demo来说已经比较完善了。最后，我们可以为这个关卡设定一些条件，毕竟不是每个人都喜欢一直无意义地消灭怪物直到手机没电。我们设定规则，当打死30个怪物后切换到新的场景，以成功结束战斗的结果；另外，要是有任何一个怪物到达了屏幕左侧边缘，则本场战斗失败。另外我们在显示结果的场景中还需要一个交互按钮，以便我们重新开始一轮游戏。

首先是检测被打死的怪物数，在MyScene里添加一个`monstersDestroyed`，然后在打中怪物时使这个值+1，并在随后判断如果消灭怪物数量大于等于30，则切换场景（暂时没有实现，现在留了两个TODO，一会儿我们再实装场景切换）

```objc
@interface MyScene()
//...
@property (nonatomic, assign) int monstersDestroyed;
//...
@end


-(void)update:(CFTimeInterval)currentTime {
//...
  for (SKSpriteNode *monster in monstersToDelete) {
    [self.monsters removeObject:monster];
    [monster removeFromParent];
            
    self.monstersDestroyed++;
    if (self.monstersDestroyed >= 30) {
        //TODO: Show a win scene
    }
  }
//...
```

另外，在怪物到达屏幕边缘的时候也触发场景的切换：

```objc
- (void) addMonster {
	//...
    SKAction *actionMoveDone = [SKAction runBlock:^{
        [monster removeFromParent];
        [self.monsters removeObject:monster];
        
        //TODO: Show a lose scene
    }];
    //...
}

```

接下来就是制作新的表示结果的场景了。新建一个SKScene的子类很简单，和平时我们新建Cocoa或者CocoaTouch的类没有什么区别。菜单中File->New->File...，选择Objective-C class，然后将新建的文件取名为ResultScene，父类填写为SKScene，并在新建的时候选择合适的Target即可。在新建的ResultScene.m的@implementation中加入如下代码：

```objc
-(instancetype)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        //1 Add a result label to the middle of screen
        SKLabelNode *resultLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        resultLabel.text = won ? @"You win!" : @"You lose";
        resultLabel.fontSize = 30;
        resultLabel.fontColor = [SKColor blackColor];
        resultLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        [self addChild:resultLabel];
        
        //2 Add a retry label below the result label
        SKLabelNode *retryLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        retryLabel.text = @"Try again";
        retryLabel.fontSize = 20;
        retryLabel.fontColor = [SKColor blueColor];
        retryLabel.position = CGPointMake(resultLabel.position.x, resultLabel.position.y * 0.8);
        //3 Give a name for this node, it will help up to find the node later.
        retryLabel.name = @"retryLabel";
        [self addChild:retryLabel];
    }
    return self;
}
```

我们在ResultScene中自定义了一个含有结果的初始化方法初始化，之后我们将使用这个方法来初始化ResultScene。在这个init方法中我们做了以下这些事：

1. 根据输入添加了一个SKLabelNode来显示游戏的结果。SKLabelNode也是SKNode的子类，可以用来方便地显示不同字体、颜色或者样式的文字标签。
2. 在结果标签的下方加入了一个重开一盘的标签
3. 我们为这个node进行了命名，通过对node命名，我们可以在之后方便地拿到这个node的参照，而不必新建一个变量来持有它。在实际运用中，这个命名即可以用来存储一个唯一的名字，来帮助我们之后找到特定的node（使用`-childNodeWithName:`），也可以一堆特性类似的node共用一个名字，这样可以方便枚举（使用`-enumerateChildNodesWithName:usingBlock:`方法）。不过这次的demo中，我们只是简单地用字符串比较来确定node，稍后会看到具体的用法。

最后不要忘了这个方法名写到.h文件中去，这样我们才能在游戏场景中调用到。

回到游戏场景，在MyScene.m的加入对ResultScene.h的引用，然后在实现中加入一个切换场景的方法

```objc
#import "ResultScene.h"

//...
-(void) changeToResultSceneWithWon:(BOOL)won
{
    [self.bgmPlayer stop];
    self.bgmPlayer = nil;
    ResultScene *rs = [[ResultScene alloc] initWithSize:self.size won:won];
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0];
    [self.scene.view presentScene:rs transition:reveal];
}
```

`SKTransition`是专门用来做不同的Scene之前切换的类，这个类为我们提供了很多“廉价”的场景切换效果（相信我，你如果想要自己实现它们的话会颇费一番功夫）。在这里我们建立了一个将当前场景上推的切换效果，来显示新的ResultScene。另外注意我们在这里停止了BGM的播放。之后，将刚才留下来的两个TODO的地方，分别替换为以相应参数对这个方法的调用。

最后，我们想要在ResultScene中点击Retry标签时，重开一盘游戏。在ResultScene.m中加入代码

```objc
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        CGPoint touchLocation = [touch locationInNode:self];
        SKNode *node = [self nodeAtPoint:touchLocation];
        
        if ([node.name isEqualToString:@"retryLabel"]) {
            [self changeToGameScene];
        }
    }
}

-(void) changeToGameScene
{
    MyScene *ms = [MyScene sceneWithSize:self.size];
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:1.0];
    [self.scene.view presentScene:ms transition:reveal];
}
```

运行游戏，消灭足够多的敌人（或者漏过一个敌人），应该能够可能到场景切换和结果显示。然后点击再来一次的话，将重新开始新的游戏。

![结束时显示结果场景](/assets/images/2013/spritekit-result.png)

### 关于Sprite的一些个人补充

至此，整个Demo的主体部分结束。接下来对于当前的SpriteKit（iOS SDK beta1）说一些我个人的看法和理解。如果之后这部分内容有巨大变化的话，我会尽量更新。首先是性能问题，如果有在iOS平台下使用cocos2d开发的经验的话，很容易看出来SpriteKit在很多地方借鉴了cocos2d。作为SDK内置的框架来说，又有cocos2d的开源实现进行参考，效率方面超越cocos2d应该是理所当然的。在现有的一系列benchmark上来看，实际上SpriteKit在图形渲染方面也有着很不错的表现。另外，在编写过程中，也有不少技巧可以使用，以进一步进行优化，比如在内存中保持住常用的action，预先加载资源，使用Atlas等等。在进行比较全面和完整的优化后，SpriteKit的表现应该是可以期待的。

使用SpriteKit一个很明显的优点在于，SKView其实是基于UIKit的UIView的一套实现，而其中的所有SKNode对象都UIResponder的子类，并且实现了NSCoding等接口。也就是说，其实在SpriteKit中是可以很容易地使用其他的非游戏Cocoa/CocoaTouch框架的。比如可以使用UIKit或者Cocoa来简单地制作UI，然后只在需要每帧演算的时候使用SpriteKit，藉此来达到快速开发的目的。这点上cocos2d是无法与之比拟的。另外，因为SKSprite同时兼顾了iOS和Mac两者，因此在我们进行开发时如果能稍加注意，理论上可以比较容易地完成iOS和Mac的跨平台。

由于SKNode是UIResponder的子类，因此在真正制作游戏的时候，对于相应用户点击等操作我们是不必（也不应该）像demo中一样全部放在Scene点击事件中，而是应该尽量封装游戏中用到的node，并在node中处理用户的点击，并且委托到Scene中进行处理，可能逻辑上会更加清晰。关于用户交互事件的处理，另外一个需要注意的地方在于，使用UIResponder监测的用户交互事件和SKScene的事件循环是相互独立的。如果像我们的demo中那样直接处理用户点击并和SpriteKit交互的话，我们并不能确定这个执行时机在SKScene循环中的状态。比如点击的相关代码也许会在`-update`后执行，也可能在`-didSimulatePhysics`后被调用，这引入了执行顺序的不确定性。对于上面的这个简单的demo来说这没有什么太大关系，但是在对于时间敏感的游戏逻辑或者带有物理模拟的游戏中，也许时序会很关键。由于点击事件的时序和精灵动画和物理等的时序不确定，有可能造成奇怪的问题。对此现在暂时的解决方法是仅在点击事件中设置一个标志位记录点击状态，然后在接下来的`-update:`中进行检测并处理（苹果给出的官方SpriteKit的“Adventure”是这样处理的），以此来保证时序的正确性。代价是点击事件会延迟一帧才会被处理，虽然在绝大多数情况下并不是什么问题，但是其实这点上并不优雅，至少在现在的beta版中，算不上优雅。
