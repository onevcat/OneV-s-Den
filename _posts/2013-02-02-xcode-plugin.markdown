---
layout: post
title: Xcode 4 插件制作入门
date: 2013-02-02 00:32:39.000000000 +09:00
tags: 能工巧匠集
---

本文欢迎转载，但烦请保留此行出处信息：[http://www.onevcat.com/2013/02/xcode-plugin/](http://www.onevcat.com/2013/02/xcode-plugin/)

## 2014.5.4更新

对于 Xcode 5，本文有些地方显得过时了。Xcode 5 现在已经全面转向了 ARC，因此在插件初始化设置方面其实有所改变。另外由于一大批优秀插件的带动（可以参看文章底部链接），很多大神们逐渐加入了插件开发的行列，因此，一个简单的 Template 就显得很必要了。在 Github 上的[这个 repo](https://github.com/kattrali/Xcode5-Plugin-Template) 里，包含了一个 Xcode 5 的插件的 Template 工程，省去了每次从头开始建立插件工程的麻烦，大家可以直接下载使用。

另外值得一提的是，在 Xcode 5 中， Apple 为了防止过期插件导致的在 Xcode 升级后 IDE 的崩溃，添加了一个 UUID 的检查机制。只有包含声明了适配 UUID，才能够被 Xcode 正确加载。上面那个项目中也包含了这方面的更详细的说明，可以参考。

文中其他关于插件开发的思想和常用方法在新的 Xcode 中依然是奏效的。

---

本文将介绍创建一个Xcode4插件所需要的基本步骤以及一些常用的方法。请注意为Xcode创建插件并没有任何的官方支持，因此本文所描述的方法和提供的信息可能会随Apple在Xcode上做的变化而失效。另外，由于创建插件会使用到私有API，因此Xcode插件也不可能被提交到Mac App Store上进行出售。

本文内容是基于Xcode 4.6（4H127）完成的，但是应该可以适用于任意的Xcode 4.X版本。VVPlugInDemo的工程文件我放到了github上，有需要的话您可以从[这里下载](https://github.com/onevcat/VVPluginDemo)并作为参考和起始来使用。

## 综述

Xcode本身作为一个IDE来说已经可以算上优秀，但是依然会有很多缺失的功能，另外在开发中针对自己的开发需求，创建一些便利的IDE插件，必定将大为加快开发速度。由于苹果官方并不对Xcode插件提供任何技术和文档支持，因此对于大部分开发者来说可能难于上手。虽然没有官方支持，但是在Xcode中开发并使用插件是可能的，并且也是被默许的。在Xcode启动的时候，Xcode将会寻找位于~/Library/Application Support/Developer/Shared/Xcode/Plug-ins文件夹中的后缀名为.xcplugin的bundle作为插件进行加载（运行其中的可执行文件），这就可以令我们光明正大合法合理地将我们的代码注入（虽然这个词有点不好听）Xcode，并得到运行。因此，想要创建Xcode插件，**我们需要创建Bundle工程并将编译的bundle放到上面所说的插件目录中去**，这就是Xcode插件的原理。

需要特别说明的是，因为Xcode会在启动时加载你的插件，这样就相当于你的代码有机会注入Xcode。只要你的插件加载成功，那么它将和Xcode共用一个进程，也就是说当你的代码crash的时候，Xcode也会随之crash。同样的情况也可能在Xcode版本更新的时候，由于兼容性问题而出现（因为插件可能使用私有API，Apple没有义务去维护这些API的可用性）。在出现这种情况的时候，可以直接删除插件目录下的导致问题的xcplugin文件即可。

## 你的第一个插件

我将通过制作一个简单的demo插件来说明一般Xcode插件的编写方法，这个插件将在Xcode的Edit菜单中加入一个叫做“What is selected”的项目，当你点击这个菜单命令的时候，将弹出一个警告框，提示你现在在编辑器中所选中的内容。我相信这个例子能包含绝大部分在插件创建中所必须的步骤和一些有用的方法。由于我自己也只是个半吊子开发者，水平十分有限，因此错误和不当之处还恳请大家轻喷多原谅，并帮助我改正。那么开始..

### 创建Bundle工程

![image][5] 创建工程，OSX，Framework & Library，选择Bundle，点击Next。

   [5]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-1.png

![image][6]

   [6]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-2.png

在Project信息页面中，填入插件名字，在这个例子里，就叫做DemoPlugin，Framework使用默认的Cocoa就行。另外一定记住将Use Automatic Reference Counting前的勾去掉，由于插件只能使用GC来进行内存管理，因此不需要使用ARC。

### 工程设置

插件工程有别于一般工程，需要进行一些特别的设置，以确保能正确编译插件bundle。

![image][7]

   [7]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-3.png

首先，在编辑工程的Info.plist文件（直接编辑plist文件或者是修改TARGETS下对应target的Info都行），加入以下三个布尔值：

```
XCGCReady = YES
XCPluginHasUI = NO 
XC4Compatible = YES
```

这将告诉编译器工程已经使用了GC，没有另外的UI并且是Xcode4适配的，否则你的插件将不会被加载。接下来，对Bundle Setting进行一些设置：

![image][8]

   [8]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-4.png

  * Installation Build Products Location 设置为 ${HOME} 

    * Product的根目录

  * Installation Directory 设置为

    * /Library/Application Support/Developer/Shared/Xcode/Plug-ins
    * 这里指定了插件安装的位置，这样build之后就会将插件直接扔到Plug-ins的目录了。当然不嫌麻烦的话也可以每次自己复制粘贴过去。注意这里不是绝对路径，而是基于上面的${HOME}的路径。

  * Deployment Location 设置为 YES 

    * 告诉Xcode不要用设置里的build location，而是用Installation Directory来确定build后放哪儿

  * Wrapper extension 设置为 xcplugin 

    * 把产品后缀名改为xcplugin，否则Xcode不会加载插件

如一开始说的那样，Xcode会在每次启动的时候搜索插件目录并进行加载，做如上设置的目的是每次build之后你只需要重新启动Xcode就能看到重新编译后的插件的效果，而避免了自己再去寻找Product然后copy&paste的步骤。  
另外，还需要自己在User-Defined里添加一个键值对：

![image][9]

   [9]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-5.png

  * GCC_ENABLE_OBJC_GC 设置为 supported

至此所有配置工作完成，接下来终于可以开始实现插件了～

### Hello World

新建一个类，取名叫做VVPluginDemo（当然只要不重，随便什么名字都是可以的），继承自NSObject（做iOS开发的童鞋请不要忘记现在是写Xcode插件，您需要通过OS X的Cocoa里的Objective-C class模版，而不要用Cocoa Touch的模版..）。打开VVPluginDemo.m，加入以下代码：

```objc
+(void)pluginDidLoad:(NSBundle *)plugin { 
	NSLog(@"Hello World"); 
}
```

Build（对于OS X 10.8的SDK可能会有提示GC已经废弃的警告，不用管，Xcode本身是GC的，ARC的插件是无法load的），打开控制台（Control+空格 输入console），重新启动Xcode。应该能控制台中看到我们的插件的输出：

![image][10]

   [10]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-6.png

太好了。有句话叫做，写出一个Hello World，就说明你已经掌握了一半…那么，剩下的一半内容，将对开发插件时可能面临的问题和一些常用的手段进行介绍。

### 创建插件单例，监听事件

继续我们的插件，还记得我们的目的么？在Xcode的Edit菜单中加入一个叫做“What is selected”的项目，当你点击这个菜单命令的时候，将弹出一个警告框，提示你现在在编辑器中所选中的内容。一般来说，我们希望插件能够在整个Xcode的生命周期中都存在（不要忘记其实用来写Cocoa的Xcode本身也是一个Cocoa程序）。最好的办法就是在+pluginDidLoad:中初始化单例，如下：

```objc
+ (void) pluginDidLoad: (NSBundle*) plugin { 
	[self shared]; 
}
 

+(id) shared {   
	static dispatch_once_t once;   
	static id instance = nil;   
	dispatch_once(&once, ^{   
		instance = [[self alloc] init];   
	});   
	return instance;   
} 
```

这样，以后我们在别的类中，就可以简单地通过[VVPluginDemo shared]来访问到插件的实例了。

在init中，加入一个程序启动完成的事件监听，并在程序完成启动后，在菜单栏的Edit中添加我们所需要的菜单项，这个操作最好是在Xcode完全启动以后再进行，以避免一些潜在的危险和冲突。另外，由于想要在按下按钮时显示编辑器中显示的内容，我们可能需要监听NSTextViewDidChangeSelectionNotification事件（WTF，你为什么会知道要监听什么。别着急，后面会再说，先做demo先做demo）
   
```objc
- (id)init { 
	if (self = [super init]) { 
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(applicationDidFinishLaunching:) 
				    name:NSApplicationDidFinishLaunchingNotification 
				  object:nil]; 
	} 
	return self; 
} 

- (void) applicationDidFinishLaunching: (NSNotification*) noti {   
	[[NSNotificationCenter defaultCenter] addObserver:self   
			selector:@selector(selectionDidChange:)   
				name:NSTextViewDidChangeSelectionNotification
			  object:nil];   
	NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];   
	if (editMenuItem) {   
		[[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];   
		NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"What is selected" action:@selector(showSelected:) keyEquivalent:@""];
		[newMenuItem setTarget:self];   
		[newMenuItem setKeyEquivalentModifierMask: NSAlternateKeyMask];   
		[[editMenuItem submenu] addItem:newMenuItem];   
		[newMenuItem release];   
	}   
} 

-(void) selectionDidChange:(NSNotification *)noti {   
	//Nothing now. Just in case of crash.   
} 

-(void) showSelected:(NSNotification *)noti {   
	//Nothing now. Just in case of crash.   
} 
```

现在build，重启Xcode，如果一切顺利的话，你应该能看到菜单栏上的变化了：

![image][11]

   [11]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-8.png

### 完成Demo插件

剩下的事情就很简单了，在接收到TextView的ChangeSelection通知后把现在选中的文本更新一下，在点击按钮时显示一个含有储存文字的对话框就行了。Let's do it~

首先在.m文件中加上property声明（个人习惯，喜欢用ivar也可以）。在#import和@implementation之间加上：
    
```objc
@interface VVPluginDemo() 
@property (nonatomic,copy) NSString *selectedText; 
@end
```

得益于新的属性自动绑定，synthesis已经不需要写了（对此还不太了解的童鞋可以参看我的[这篇博文](http://www.onevcat.com/2012/06/modern-objective-c/)）。然后完成- selectionDidChange:和-showSelected:如下：

```objc
-(void) selectionDidChange:(NSNotification *)noti {
	if ([[noti object] isKindOfClass:[NSTextView class]]) {
		NSTextView* textView = (NSTextView *)[noti object];

		NSArray* selectedRanges = [textView selectedRanges];  
		if (selectedRanges.count==0) {  
			return;  
		}

		NSRange selectedRange = [[selectedRanges objectAtIndex:0] rangeValue];  
		NSString* text = textView.textStorage.string;  
		self.selectedText = [text substringWithRange:selectedRange];  
	}  
	//Hello, welcom to OneV's Den  
}

-(void) showSelected:(NSNotification *)noti {  
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];  
	[alert setMessageText: self.selectedText];  
	[alert runModal];  
} 
```

Build，重启Xcode，随便选中一段文本，然后点击Edit中的What is selected。OY～完成～

![image][13]

   [13]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-7.png

至此，您应该已经掌握了基本的Xcode插件制作方法了。接下来的就是根据您的需求实践了～但是在此之前，还有一些重要的技巧和常用方法可能您会有兴趣。

## 开发插件时有用的技巧

由于没有文档指导插件开发，调试也只能用打log的方式，因此会十分艰难。掌握一些常用的技巧和方法，将会很有帮助。

### I Need All Notifications!

一种很好的方法是监听需要的消息，并针对消息作出反应。就像demo里的NSTextViewDidChangeSelectionNotification。对于熟悉iOS或者Mac开发的童鞋来说，应该在日常开发里也接触过很多类型的Notification了，而因为插件开发没有文档，因此我们需要自己去寻找想要监听和接收的Notification。[NSNotificationCenter文档][14]中，关于加入Observer的方法-addObserver:selector:name:object:，当给name参数赋值nil时，将可以监听到所有的notification：

   [14]: https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/Reference/Reference.html

> notificationName: The name of the notification for which to register the observer; that is, only notifications with this name are delivered to the observer. If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.

因此可以用它来监测所有的Notification，并从中找到自己所需要的来进行处理：

```objc
-(id)init { 
	if (self = [super init]) { 
		[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(notificationListener:) 
				name:nil object:nil]; 
	} 
	return self; 
} 

-(void)notificationListener:(NSNotification *)noti {   
	NSLog(@" Notification: %@", [noti name]);   
} 
```

编译重启后在控制台得到的输出：

![image][15]

   [15]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-9.png

当然如果只是打印名字的话可能帮助不大，也许你需要从noti的object或者userinfo中获得更多的信息。按条件打印，配合控制台的搜索进行寻找会是一个不错的方法。

### Hack私有API

用OC的动态特性可以做很多事，比如在运行时替换掉某个Xcode的方法。记住Xcode本身也是Cocoa程序，本质上和我们用Xcode所开发的程序没有太大区别。因此如果可以知道Xcode在进行某些操作时候的方法的话，就可以将该方法与我们自己实现的方法进行运行时调换，从而改为执行我们自己的方法。这便是运行时的Method Swizzling（或者叫Monkey patch，管他呢），这在smalltalk类语言中是一种很有趣和方便的做法，关于这方面更详细的，我以前写过一篇关于[OC运行时特性的文章][16]。当时提到的method swizzling方法并没有对交换的函数进行检查等工作，通用性也比较差。现在针对OC已经有比较成熟的一套方法交换机制了，其中比较有名的有[rentzsch的jrswizzle][17]以及[OC社区的MethodSwizzling实现][18]。

   [16]: http://www.onevcat.com/2012/04/objective-c-runtime/
   [17]: https://github.com/rentzsch/jrswizzle
   [18]: http://cocoadev.com/wiki/MethodSwizzling

有了方法交换的办法，接下来需要寻找要交换的方法。Xcode所使用的所有库都包含在Xcode.app/Contents/的Frameworks，SharedFrameworks和OtherFrameworks三个文件夹下。其中和Xcode关系最为直接以及最为重要的是Frameworks中的IDEKit和IDEFoundation，以及SharedFrameworks中的DVTKit和DVTFoundation四个。其中DVT前缀表示Developer Toolkit，IDE和IDEFoundation中的类基本是DVT中类的子类。这四个framework将是我们在开发改变Xcode默认行为的Xcode插件时最主要要打交道的。另外如果想对IB进行注入，可能还需要用到Frameworks下的IBAutolayoutFoundation（待确定）。关于这些framework中的私有API，可以使用[class-dump][19]很简单地将头文件提取出来。当然，也有人为懒人们完成了这个工作，[probablycorey的xcode-class-dump][20]中有绝大部分类的头文件。

   [19]: http://stevenygard.com/projects/class-dump/
   [20]: https://github.com/probablycorey/xcode-class-dump

作为Demo，我们将简单地完成一个方法交换：在补全代码时，我们简单地输出一句log。

#### MethodSwizzle

为了交换方法，可以直接用现成的MethodSwizzle实现。MethodSwizzle可以在[这里][21]找到。将.h和.m导入插件工程即可～

   [21]: https://gist.github.com/4696790

#### 寻找对应API

通过搜索，补全代码的功能定义在DVKit中的DVTTextCompletionController类，其中有一个方法为- (BOOL)acceptCurrentCompletion，猜测返回的布尔值是否接受当前的补全结果。由于这些都是私有API，因此需要在我们的工程中自己进行声明。在新建文件中的C and C++中选Header File，为工程加入一个Header文件，并加入一下代码：
    
```objc
@interface DVTTextCompletionController : NSObject 
- (BOOL)acceptCurrentCompletion; 
@end
```

然后需要将DVKit.framework添加到工程中，在/Applications/Xcode.app/Contents/SharedFrameworks中找到DVTKit.framework，拷贝到任意正常能访问到的目录下，然后在插件工程的Build Phases中加入framework。嗯？你说找不到DVTKit.framework？亲，私有框架当然找不到，点击Add Other...然后去刚才copy出来的地方去找吧.. 

![image][22]

   [22]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-10.png

最后便是加入方法交换了～新建一个DVTTextCompletionController的Category，命名为PluginDemo

![image][23]

   [23]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-13.png

import之前定义的header和MethodSwizzle.h，在DVTTextCompletionController+PluginDemo.m中加入下面实现：

```objc
+ (void)load
{
	MethodSwizzle(self,
				  @selector(acceptCurrentCompletion),
			   	  @selector(swizzledAcceptCurrentCompletion));
}

- (BOOL)swizzledAcceptCurrentCompletion {  
NSLog(@"acceptCurrentCompletion is called by %@", self);  
return [self swizzledAcceptCurrentCompletion];  
} 

```

+load方法在每个NSObject类或子类被调用时都会被执行，可以用来在runtime配置当前类。这里交换了DVTTextCompletionController的acceptCurrentCompletion方法和我们自己实现的swizzledAcceptCurrentCompletion方法。在swizzledAcceptCurrentCompletion中，先打印了一句log，输出相应该方法的实例。接下来似乎是调用了自己，但是实际上swizzledAcceptCurrentCompletion的方法已经和原来的acceptCurrentCompletion交换，因此这里实际调用的将是原来的方法。那么这段代码所做的就是将Xcode想调用原来的acceptCurrentCompletion的行为，改变成了先打印一个log，之后再进行原来的acceptCurrentCompletion调用。

编译，重启Xcode，打开一个工程随便输入点东西，让补全出现。控制台中的输出符合我们的预期：

![image][24]

   [24]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-12.png

太棒了，有了对私有API的注入，能做的事情大为扩展了。

### 研究Xcode的View Hierarchy

另外一种常见的插件行为是修改某些界面。再一次说明，Xcode是一个标准Cocoa程序，一切都是那么熟悉（如果你为Cocoa或者CocoaTouch开发的话，应该是很熟悉）。拿到整个App的Window，然后依次递归打印subview。stackoverflow上有[一个UIView的版本](http://stackoverflow.com/questions/2715534/where-does-a-uialertview-live-while-not-dismissed/2715772#2715772)，稍微改变一下就可以得到一个NSView版本。新建一个NSView的Dumping Category，加入如下实现：

```objc
-(void)dumpWithIndent:(NSString *)indent {
	NSString *class = NSStringFromClass([self class]);
	NSString *info = @"";
	if ([self respondsToSelector:@selector(title)]) {
		NSString *title = [self performSelector:@selector(title)];
		if (title != nil && [title length] > 0) {
			info = [info stringByAppendingFormat:@" title=%@", title];
		}
	}
	if ([self respondsToSelector:@selector(stringValue)]) {
		NSString *string = [self performSelector:@selector(stringValue)];
		if (string != nil && [string length] > 0) {
			info = [info stringByAppendingFormat:@" stringValue=%@", string];
		}
	}
	NSString *tooltip = [self toolTip];
	if (tooltip != nil && [tooltip length] > 0) {
		info = [info stringByAppendingFormat:@" tooltip=%@", tooltip];
	}
	
	NSLog(@"%@%@%@", indent, class, info);

	if ([[self subviews] count] > 0) {  
		NSString *subIndent = [NSString stringWithFormat:@"%@%@", indent, ([indent length]/2)%2==0 ? @"| " : @": "];  
		for (NSView *subview in [self subviews]) {  
			[subview dumpWithIndent:subIndent];  
		}  
	}  
} 
```

在合适的时候（比如点击某个按钮时），调用下面一句代码，便可以打印当前Xcode的结构，非常方便。这对了解Xcode的构成和如何搭建一个如Xcode般复杂的程序很有帮助～
    
    
    [[[NSApp mainWindow] contentView] dumpWithIndent:@""];

在结果控制台中的输出结果类似这样：

![image][26]

   [26]: http://i758.photobucket.com/albums/xx224/onevcat/QQ20130202-14.png

根据自己需要去去相应的view吧～然后配合方法交换，基本可以做到尽情做想做的事情了。

## 最后的小bonus

/Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/Versions/A/Resources中有不少Xcode界面用的图片，pdf，png和tiff格式都有，想要自定义run，stop按钮或者想要让断点标记从蓝色块变成机器猫头像什么的…应该是可能的～

/Applications/Xcode.app/Contents/PlugIns目录里有很多Xcode自带的“官方版”外挂插件，显然通过class-dump和注入的方法，你可以为Xcode的插件写插件...嗯～比如改变debugger的行为或者让plist编辑器更聪明，就是这样的。

希望Apple能提供为Xcode编写插件的支持，所有东西都需要摸索虽然很有趣，但是也比较花时间。

另外，github等代码托管网站上有不少大神们写的插件，都开源放出。这些必须是学习插件编写的最优秀的教材和参考： 

  * [mneorr / Alcatraz](https://github.com/mneorr/Alcatraz) Xcode的包管理插件，管理其他插件的插件
  * [onevcat / VVDocumenter-Xcode](https://github.com/onevcat/VVDocumenter-Xcode) 帮助快速写文档注释的插件，自动提取参数返回值等
  * [omz / ColorSense-for-Xcode](https://github.com/omz/ColorSense-for-Xcode) 在UIColor/NSColor上显示出对应的颜色
  * [omz / Dash-Plugin-for-Xcode](https://github.com/omz/Dash-Plugin-for-Xcode) 在Xcode中集成Dash，方便看文档
  * [omz / MiniXcode](https://github.com/omz/MiniXcode) 隐藏Xcode臃肿的工具栏，获得更大的可视空间
  * [ksuther / KSImageNamed-Xcode](https://github.com/ksuther/KSImageNamed-Xcode) 输入imageNamed的时候自动补完图片名称
  * [JugglerShu / XVim](https://github.com/JugglerShu/XVim) 将Xcode编辑器改造成Vim
  * [davekeck / Xcode-4-Fixins](https://github.com/davekeck/Xcode-4-Fixins) 修正一些Xcode的bugs（应该已经没有太大用了）
  * [0xced / CLITool-InfoPlist](https://github.com/0xced/CLITool-InfoPlist) 方便修改Info.plist为CLI目标的插件
  * [questbeat / Lin](https://github.com/questbeat/Lin) 为NSLocalizedString显示补全
  * [stefanceriu / SCXcodeMiniMap](https://github.com/stefanceriu/SCXcodeMiniMap) 在侧边显示代码小地图

好了，就到这里吧。VVPlugInDemo的工程文件我放到了github上，有需要的话您可以从[这里下载][35]并作为参考和起始来使用。谢谢您看完这么长的文。正如一开始所说的，我自己水平十分有限，因此错误和不当之处还恳请大家轻喷多原谅，并帮助我改正，再次谢谢～

   [35]: https://github.com/onevcat/VVPluginDemo
