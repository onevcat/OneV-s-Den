---
layout: post
title: 手把手教你ARC——iOS/Mac开发ARC入门和使用
date: 2012-06-04 23:30:00.000000000 +09:00
tags: 能工巧匠集
---

![Revolution of Objective-c](/assets/images/2012/arctitle.png)

本文部分实例取自iOS 5 Toturail一书中关于ARC的[教程和公开内容](http://www.raywenderlich.com/5677/beginning-arc-in-ios-5-part-1)，仅用于技术交流和讨论。请不要将本文的部分或全部内容用于商用，谢谢合作。

欢迎转载本文，但是转载请注明本文出处：[http://www.onevcat.com/2012/06/arc-hand-by-hand/][3]

   [3]: http://www.onevcat.com/2012/06/arc-hand-by-hand/

本文适合人群：对iOS开发有一定基础，熟悉iOS开发中内存管理的Reference Counting机制，对ARC机制有听闻很向往但是一直由于种种原因没有使用的童鞋。本文将从ARC机理入手对这个解放广大iOS开发者的伟大机制进行一个剖析，并逐步引导你开始使用ARC。一旦习惯ARC，你一定会被它的简洁高效所征服。

## 写在开头

虽然距离WWDC2011和iOS 5已经快一年时间，但是很多开发者并没有利用新方法来提高自己的水平，这点在ARC的使用上非常明显(特别是国内，基本很少见到同行转向ARC)。我曾经询问过一些同行为什么不转向使用ARC，很多人的回答是担心内存管理不受自己控制..其实我个人认为这是对于ARC机制了解不足从而不自信，所导致的对新事物的恐惧。而作为最需要“追赶时髦”的职业，这样的心态将相当不利。谨以此文希望能清楚表述ARC的机理和用法，也希望能够成为现在中文入门教学缺失的补充。

* * *

## 什么是ARC

Automatic Reference Counting，自动引用计数，即ARC，可以说是WWDC2011和iOS5所引入的最大的变革和最激动人心的变化。ARC是新的LLVM 3.0编译器的一项特性，使用ARC，可以说一举解决了广大iOS开发者所憎恨的手动内存管理的麻烦。

在工程中使用ARC非常简单：只需要像往常那样编写代码，只不过永远不写`retain`,`release`和`autorelease`三个关键字就好～这是ARC的基本原则。当ARC开启时，编译器将自动在代码合适的地方插入`retain`, `release`和`autorelease`，而作为开发者，完全不需要担心编译器会做错（除非开发者自己错用ARC了）。好了，ARC相当简单吧～到此为止，本教程结束。

等等…也许还有其他问题，最严重的问题是“我怎么确定让ARC来管理不会出问题？”或者“用ARC会让程序性能下降吧”。对于ARC不能正处理内存管理的质疑自从ARC出生以来就一直存在，而现在越来越多的代码转向ARC并取得了很好的效果，这证明了ARC是一套有效的简化开发复杂程度的机制，另外通过研究ARC的原理，可以知道使用ARC甚至能提高程序的效率。在接下来将详细解释ARC的运行机理并且提供了一个step-by-step的教程，将非ARC的程序转换为ARC。

* * *

## ARC工作原理

手动内存管理的机理大家应该已经非常清楚了，简单来说，只要遵循以下三点就可以在手动内存管理中避免绝大部分的麻烦：

> 如果需要持有一个对象，那么对其发送retain 如果之后不再使用该对象，那么需要对其发送release（或者autorealse） 每一次对retain,alloc或者new的调用，需要对应一次release或autorealse调用

初学者可能仅仅只是知道这些规则，但是在实际使用时难免犯错。但是当开发者经常使用手动引用计数 Manual Referecen Counting(MRC)的话，这些规则将逐渐变为本能。你会发现少一个`release`的代码怎么看怎么别扭，从而减少或者杜绝内存管理的错误。可以说MRC的规则非常简单，但是同时也非常容易出错。往往很小的错误就将引起crash或者OOM之类的严重问题。

在MRC的年代里，为了避免不小心忘写`release`，Xcode提供了一个很实用的小工具来帮助可能存在的代码问题(Xcode3里默认快捷键Shift+A？不记得了)，可以指出潜在的内存泄露或者过多释放。而ARC在此基础上更进一步：ARC是Objective-C编译器的特性，而不是运行时特性或者垃圾回收机制，ARC所做的只不过是在代码编译时为你自动在合适的位置插入`release`或`autorelease`，就如同之前MRC时你所做的那样。因此，至少在效率上ARC机制是不会比MRC弱的，而因为可以在最合适的地方完成引用计数的维护，以及部分优化，使用ARC甚至能比MRC取得更高的运行效率。

### ARC机制

学习ARC很简单，在MRC时代你需要自己`retain`一个想要保持的对象，而现在不需要了。现在唯一要做的是用一个指针指向这个对象，只要指针没有被置空，对象就会一直保持在堆上。当将指针指向新值时，原来的对象会被`release`一次。这对实例变量，synthesize的变量或者局部变量都是适用的。比如

```objc    
NSString *firstName = self.textField.text;
```

`firstName`现在指向NSString对象，这时这个对象（`textField`的内容字符串）将被hold住。比如用字符串@“OneV"作为例子（虽然实际上不应该用字符串举例子，因为字符串的retainCount规则其实和普通的对象不一样，大家就把它当作一个普通的对象来看吧…），这个时候`firstName`持有了@"OneV"。

![一个strong指针](/assets/images/2012/arcpic1.png)

当然，一个对象可以拥有不止一个的持有者（这个类似MRC中的retainCount>1的情况）。在这个例子中显然`self.textField.text`也是@“OneV"，那么现在有两个指针指向对象@"OneV”(被持有两次，retainCount=2，其实对NSString对象说retainCount是有问题的，不过anyway～就这个意思而已.)。

![两个strong指向同一个对象](/assets/images/2012/arcpic2.png)

过了一会儿，也许用户在`textField`里输入了其他的东西，那么`self.textField.text`指针显然现在指向了别的字符串，比如@“onevcat"，但是这时候原来的对象已然是存在的，因为还有一个指针`firstName`持有它。现在指针的指向关系是这样的：

![其中一个strong指向了另一个对象](/assets/images/2012/arcpic3.png)

只有当`firstName`也被设定了新的值，或者是超出了作用范围的空间(比如它是局部变量但是这个方法执行完了或者它是实例变量但是这个实例被销毁了)，那么此时`firstName`也不再持有@“OneV"，此时不再有指针指向@"OneV"，在ARC下这种状况发生后对象@"OneV"即被销毁，内存释放。

![没有strong指向@"OneV"，内存释放](/assets/images/2012/arcpic4.png)

类似于`firstName`和`self.textField.text`这样的指针使用关键字`strong`进行标志，它意味着只要该指针指向某个对象，那么这个对象就不会被销毁。反过来说，ARC的一个基本规则即是，**只要某个对象被任一`strong`指针指向，那么它将不会被销毁。如果对象没有被任何strong指针指向，那么就将被销毁**。在默认情况下，所有的实例变量和局部变量都是`strong`类型的。可以说`strong`类型的指针在行为上和MRC时代`retain`的property是比较相似的。

既然有`strong`，那肯定有`weak`咯～`weak`类型的指针也可以指向对象，但是并不会持有该对象。比如：

```objc    
__weak NSString *weakName = self.textField.text
```

得到的指向关系是：

![一个strong和一个weak指向同一个对象](/assets/images/2012/arcpic5.png)

这里声明了一个`weak`的指针`weakName`，它并不持有@“onevcat"。如果`self.textField.text`的内容发生改变的话，根据之前提到的**"只要某个对象被任一strong指针指向，那么它将不会被销毁。如果对象没有被任何strong指针指向，那么就将被销毁”**原则，此时指向@“onevcat"的指针中没有`strong`类型的指针，@"onevcat"将被销毁。同时，在ARC机制作用下，所有指向这个对象的`weak`指针将被置为`nil`。这个特性相当有用，相信无数的开发者都曾经被指针指向已释放对象所造成的EXC_BAD_ACCESS困扰过，使用ARC以后，不论是`strong`还是`weak`类型的指针，都不再会指向一个dealloced的对象，从**根源上解决了意外释放导致的crash**。

![strong指向另外对象，内存释放，weak自动置nil](/assets/images/2012/arcpic6.png)

不过在大部分情况下，`weak`类型的指针可能并不会很常用。比较常见的用法是在两个对象间存在包含关系时：对象1有一个`strong`指针指向对象2，并持有它，而对象2中只有一个`weak`指针指回对象1，从而避免了循环持有。一个常见的例子就是oc中常见的delegate设计模式，viewController中有一个`strong`指针指向它所负责管理的UITableView，而UITableView中的`dataSource`和`delegate`指针都是指向viewController的`weak`指针。可以说，`weak`指针的行为和MRC时代的`assign`有一些相似点，但是考虑到`weak`指针更聪明些（会自动指向nil），因此还是有所不同的。细节的东西我们稍后再说。

![一个典型的delegate设计模式](/assets/images/2012/arcpic7.png)

注意类似下面的代码似乎是没有什么意义的：

```    
__weak NSString *str = [[NSString alloc] initWithFormat:…]; 
NSLog(@"%@",str); //输出是"(null)"
```

由于`str`是`weak`，它不会持有alloc出来的`NSString`对象，因此这个对象由于没有有效的`strong`指针指向，所以在生成的同时就被销毁了。如果我们在Xcode中写了上面的代码，我们应该会得到一个警告，因为无论何时这种情况似乎都是不太可能出现的。你可以把**weak换成**strong来消除警告，或者直接前面什么都不写，因为ARC中默认的指针类型就是`strong`。

property也可以用`strong`或`weak`来标记，简单地把原来写`retain`和`assign`的地方替换成`strong`或者`weak`就可以了。

```objc    
@property (nonatomic, strong) NSString *firstName; 
@property (nonatomic, weak) id  delegate;
```

ARC可以为开发者节省很多代码，使用ARC以后再也不需要关心什么时候`retain`，什么时候`release`，但是这并不意味你可以不思考内存管理，你可能需要经常性地问自己这个问题：谁持有这个对象？

比如下面的代码，假设`array`是一个`NSMutableArray`并且里面至少有一个对象：

```objc    
id obj = [array objectAtIndex:0]; 
[array removeObjectAtIndex:0]; 
NSLog(@"%@",obj);
```

在MRC时代这几行代码应该就挂掉了，因为`array`中0号对象被remove以后就被立即销毁了，因此obj指向了一个dealloced的对象，因此在NSLog的时候将出现EXC_BAD_ACCESS。而在ARC中由于obj是`strong`的，因此它持有了`array`中的首个对象，`array`不再是该对象的唯一持有者。即使我们从`array`中将obj移除了，它也依然被别的指针持有，因此不会被销毁。

### 一点提醒

ARC也有一些缺点，对于初学者来说，可能仅只能将ARC用在objective-c对象上(也即继承自NSObject的对象)，但是如果涉及到较为底层的东西，比如Core Foundation中的malloc()或者free()等，ARC就鞭长莫及了，这时候还是需要自己手动进行内存管理。在之后我们会看到一些这方面的例子。另外为了确保ARC能正确的工作，有些语法规则也会因为ARC而变得稍微严格一些。

ARC确实可以在适当的地方为代码添加`retain`或者`release`，但是这并不意味着你可以完全忘记内存管理，因为你必须在合适的地方把`strong`指针手动设置到nil，否则app很可能会oom。简单说还是那句话，你必须时刻清醒谁持有了哪些对象，而这些持有者在什么时候应该变为指向`nil`。

ARC必然是Objective-C以及Apple开发的趋势，今后也会有越来越多的项目采用ARC(甚至不排除MRC在未来某个版本被弃用的可能)，Apple也一直鼓励开发者开始使用ARC，因为它确实可以简化代码并增强其稳定性。可以这么说，使用ARC之后，由于内存问题造成的crash基本就是过去式了(OOM除外 :P)

我们正处于由MRC向ARC转变的节点上，因此可能有时候我们需要在ARC和MRC的代码间来回切换和适配。Apple也想到了这一点，因此为开发这提供了一些ARC和非ARC代码混编的机制，这些也将在之后的例子中列出。另外ARC甚至可以用在C++的代码中，而通过遵守一些代码规则，iOS 4里也可以使用ARC(虽然我个人认为在现在iOS 6都呼之欲出的年代已经基本没有需要为iOS 4做适配的必要了)、

总之，聪明的开发者总会尝试尽可能的自动化流程，已减轻自己的工作负担，而ARC恰恰就为我们提供了这样的好处：自动帮我们完成了很多以前需要手动完成的工作，因此对我来说，转向ARC是一件不需要考虑的事情。

* * *

## 具体操作

说了这么多，终于可以实践一下了。在决定使用ARC后，很多开发者面临的首要问题是不知如何下手。因为可能手上的项目已经用MRC写了一部分，不想麻烦做转变；或者因为新项目里用ARC时遇到了奇怪的问题，从而放弃ARC退回MRC。这都是常见的问题，而在下面，将通过一个demo引导大家彻底转向ARC的世界。

### Demo

![Demo](/assets/images/2012/arcpic8.png)

例子很简单，这是一个查找歌手的应用，包含一个简单的UITableView和一个搜索框，当用户在搜索框搜索时，调用[MusicBrainz][20]的API完成名字搜索和匹配。MusicBrainz是一个开放的音乐信息平台，它提供了一个免费的XML网页服务，如果对MusicBrainz比较有兴趣的话，可以到它的官网逛一逛。

   [20]: http://musicbrainz.org/

> AppDelegate.h/m 这是整个app的delegate，没什么特殊的，每个iOS/Mac程序在main函数以后的入口，由此进入app的生命周期。在这里加载了最初的viewController并将其放到Window中展示出来。另外appDelegate还负责处理程序开始退出等系统委托的事件

> MainViewController.h/m/xib 这个demo最主要的ViewController，含有一个TableView和一个搜索条。 SoundEffect.h/m 简单的播放声音的类，在MusicBrainz搜索完毕时播放一个音效。 main.m 程序入口，所有c程序都从main函数开始执行

> AFHTTPRequestOperation.h/m 这是有名的网络框架AFNetworking的一部分，用来帮助等简单地处理web服务请求。这里只包含了这一个类而没有将全部的AFNetworking包括进来，因为我们只用了这一个类。完整的框架代码可以在github的相关页面上找到[https://github.com/gowalla/AFNetworking][22]

   [22]: https://github.com/gowalla/AFNetworking

> SVProgresHUD.h/m/bundle 是一个常用的进度条指示，当搜索的时候出现以提示用户正在搜索请稍后。bundle是资源包，里面包含了几张该类用到的图片，打进bundle包的目的一方面是为了资源容易管理，另一方面也是主要方面时为了不和其他资源发生冲突(Xcode中资源名字是资源的唯一标识，同名字的资源只能出现一次，而放到bundle包里可以避免这个潜在的问题)。SVProgresHUD可以在这里找到[https://github.com/samvermette/SVProgressHUD][23]

   [23]: https://github.com/samvermette/SVProgressHUD

快速过一遍这个应用吧：`MainViewController`是`UIViewController`的子类，对应的xib文件定义了对应的`UITableView`和`UISearchBar`。`TableView中`显示`searchResult`数组中的内容。当用户搜索时，用AFHTTPRequestOperation发一个HTTP请求，当从MusicBrainz得到回应后将结果放入`searchResult`数组中并用`tableView`显示，当返回结果是空时在`tableView`中显示没找到。主要的逻辑都在MainViewController.m中的`-searchBarSearchButtonClicked:`方法中，生成了用于查询的URL，根据MusicBrainz的需求替换了请求的header，并且完成了返回逻辑，然后在主线程中刷新UI。整个程序还是比较简单的～

### MRC到ARC的自动转换

回到正题，我们讨论的是ARC，关于REST API和XML解析的技术细节就暂时先忽略吧..整个程序都是用MRC来进行内存管理的，首先来让我们把这个demo转成ARC吧。基本上转换为ARC意味着把所有的`retain`,`release`和`autorelease`关键字去掉，在之前我们明确几件事情:

* Xcode提供了一个ARC自动转换工具，可以帮助你将源码转为ARC  
* 当然你也可以自己动手完成ARC转换  
* 同时你也可以指定对于某些你不想转换的代码禁用ARC，这对于很多庞大复杂的还没有转至ARC的第三方库帮助很大，因为不是你写的代码你想动手修改的话代码超级容易mess…

对于我们的demo，为了说明问题，这三种策略我们都将采用，注意这仅仅只是为了展示如何转换。实际操作中不需要这么麻烦，而且今后的绝大部分情况应该是从工程建立开始就是ARC的。

![选择LLVM compiler 3.0](/assets/images/2012/arcpic9.png)

首先，ARC是LLVM3.0编译器的特性，而老的工程特别是Xcode3时代的工程的默认编译器很可能是GCC或者LLVM-GCC，因此第一步就是确认编译器是否正确。**在Project设置面板，选择target，在Build Settings中将Compiler for C/C++/Objective-C选为Apple LLVM compiler 3.0或以上。**为了确保之后转换的顺利，在这里我个人建议最好把Treat Warnings as Errors和 Run Static Analyzer都打开，确保在改变编译器后代码依旧没有警告或者内存问题(虽然静态分析可能不太能保证这一点，但是聊胜于无)。好了～clean(`Shift+Cmd+K`)以后Bulid一下试试看，经过修改后的demo工程没有任何警告和错误，这是很好的开始。（对于存在警告的代码，这里是很好的修复的时机..请在转换前确保原来的代码没有内存问题）。

![打开ARC](/assets/images/2012/arcpic10.png)

接下来就是完成从MRC到ARC的伟大转换了。还是在Build Settings页面，把Objective-C Automatic Reference Counting改成YES(如果找不到的话请看一看搜索栏前面的小标签是不是调成All了..这个选项在Basic里是不出现的)，这样我们的工程就将在所有源代码中启用ARC了。然后…试着编译一下看看，嗯..无数的错误。

![请耐心聆听编译器的倾诉，因为很多时候它是你唯一的伙伴](/assets/images/2012/arcpic11.png)

这是很正常的，因为ARC里不允许出现retain,release之类的，而MRC的代码这些是肯定会有的东西。我们可以手动一个一个对应地去修复这些错误，但是这很麻烦。Xcode为我们提供了一个自动转换工具，可以帮助重写源代码，简单来说就是去掉多余的语句并且重写一些property关键字。

![使用Xcode自带的转换ARC工具](/assets/images/2012/arcpic12.png)

![选择要转换的文件](/assets/images/2012/arcpic13.png)

这个小工具是Edit->Refactor下的Convert to Objective-C ARC，点击后会让我们选择要转换哪几个文件，在这里为了说明除了自动转换外的方法，我们不全部转换，而只是选取其中几个转换(`MainViewController.m`和`AFHTTPRequestOperation.m`不做转换，之后我们再手动将这两个转为ARC)。注意到这个对话框上有个警告标志告诉我们target已经是ARC了，这是由于之前我们在Build Settings里已经设置了启用ARC，其实直接在这里做转换后Xcode会自动帮我们开启ARC。点击检查后，Xcode告诉我们一个不幸的消息，不能转换，需要修复ARC readiness issues..后面还告诉我们要看到所有的所谓的ARC readiness issues，可以到设置的General里把Continue building after errors勾上…What the f**k…好吧～先乖乖听从Xcode的建议"Cmd+,“然后Continue building after errors打勾然后再build。

![乖乖听话，去把勾打上](/assets/images/2012/arcpic14.png)

问题依旧，不过在issue面板里应该可以看到所有出问题的代码了。在我们的例子里，问题出在SoundEffect.m里：
    
```objc
NSURL *fileURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
if (fileURL != nil) {
	SystemSoundID theSoundID;
	OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &theSoundID);
	if (error == kAudioServicesNoError) {
		soundID = theSoundID;
    }
}
```

这里代码尝试把一个`NSURL`指针强制转换为一个`CFURLRef`指针。这里涉及到一些Core Services特别是Core Foundation(CF)的东西，AudioServicesCreateSystemSoundID()函数接受CFURLRef为参数，这是一个CF的概念，但是我们在较高的抽象层级上所建立的是`NSURL`对象。在Cocoa框架中，有很多顶层对象对底层的抽象，而在使用中我们往往可以不加区别地对这两种对象进行同样的对待，这类对象即为可以"自由桥接"的对象(toll-free bridged)。NSURL和CFURLRef就是一对好基友好例子，在这里其实`CFURLRef`和`NSURL`是可以进行替换的。

通常来说为了代码在底层级上的正确，在iOS开发中对基于C的API的调用所传入的参数一般都是CF对象，而Objective-C的API调用都是传入NSObject对象。因此在采用自由桥接来调用C API的时候就需要进行转换。但是在使用ARC编译的时候，因为内存管理的原因，编译器需要知道对这些桥接对象要实行什么样的操作。如果一个NSURL对象替代了CFURLRef，那么在作用区域外，应该由谁来决定内存释放和对象销毁呢？为了解决这个问题，引入了**bridge,**bridge_transfer和__bridge_retained三个关键字。关于选取哪个关键字做转换，需要由实际的代码行为来决定。如果对于自由桥接机制感兴趣，大家可以自己找找的相关内容，比如[适用类型][36]、[内部机制][37]和[一个简介][38]～之后我也会对这个问题做进一步说明

   [36]: http://developer.apple.com/library/mac/#documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html#//apple_ref/doc/uid/20002401-767858
   [37]: http://www.mikeash.com/pyblog/friday-qa-2010-01-22-toll-free-bridging-internals.html
   [38]: http://ridiculousfish.com/blog/posts/bridge.html

回到demo，我们现在在上面的代码中(CFURLRef)前加上`__bridge`进行转换。然后再运行ARC转换工具，这时候检查应该没有其他问题了，那么让我们进行转换吧～当然在真正转换之前会有一个预览界面，在这里我们最好检查一下转换是不是都按照预想进行了..要是出现大面积错误又没有备份或者出现各种意外的话就可以哭了…

前后变化的话比较简单，基本就是去掉不需要的代码和改变property的类型而已，其实有信心的话不太需要每次都看，但是如果是第一次执行ARC转换的操作的话，我还是建议稍微看一下变化，这样能对ARC有个直观上的了解。检查一遍，应该没什么问题了..需要注意的是main.m里关于autoreleasepool的变化以及所有dealloc调用里的[super dealloc]的删除，它们同样是MRC到ARC的主要变化..

好了～转换完成以后我们再build看看..应该会有一些警告。对于原来`retain`的property，比较保险的做法是转为`strong`，在LLVM3.0中自动转换是这样做的，但是在3.1中property默认并不是`strong`，这样在使用property赋值时存在警告，我们在property声明里加上`strong`就好了～然后就是SVProgressHUD.m里可能存在问题，这是由于原作者把`release`的代码和其他代码写在一行了.导致自动转换时只删掉了部分，而留下了部分不应该存在的代码，删掉对变量的空的调用就好了..

### 自动转换之后的故事

然后再编译，没有任何错误和警告了，好棒～等等…我们刚才没有对MainViewController和AFHTTPRequestOperation进行处理吧，那么这两个文件里应该还存在`release`之类的东西吧..？看一看这两个文件，果然有各种`release`，但是为什么能编译通过呢？！明明刚才在自动转换前他们还有N多错的嘛…答案很简单，在自动转换的时候因为我们没有勾选这两个文件，因此编译器在自动转换过后为这两个文件标记了"不使用ARC编译"。可以看到在target的Building Phases下，MainViewController.m和AFHTTPRequestOperation.m两个文件后面被加上了`-fno-objc-arc`的编译标记，被加上该标记的文件将不使用ARC规则进行编译。（相对地，如果你想强制对某几个文件启用ARC的话，可以为其加上`-fobjc-arc`标记）

![强制不是用ARC](/assets/images/2012/arcpic15.png)

提供这样的编译标记的原因是显而易见的，因为总是有一部分的第三方代码并没有转换为ARC(可能是由于维护者犯懒或者已经终止维护)，所以对于这部分代码，为了迅速完成转换，最好是使用-fno-objc-arc标记来禁止在这些源码上使用ARC。

为了方便查找，再此列出一些在转换时可能出现的问题，当然在我们使用ARC时也需要注意避免代码中出现这些问题：

  * “Cast … requires a bridged cast”
  
  ***这是我们在demo中遇到的问题，不再赘述***
  
  * Receiver type ‘X’ for instance message is a forward declaration
  
  ***这往往是引用的问题。ARC要求完整的前向引用，也就是说在MRC时代可能只需要在.h中申明@class就可以，但是在ARC中如果调用某个子类中未覆盖的父类中的方法的话，必须对父类.h引用，否则无法编译。***

  * Switch case is in protected scope
  
  ***现在switch语句必须加上{}了，ARC需要知道局部变量的作用域，加上{}后switch语法更加严格，否则遇到没有break的分支的话内存管理会出现问题。***

  * A name is referenced outside the NSAutoreleasePool scope that it was declared in...
  
  ***这是由于写了自己的autoreleasepool，而在转换时在原来的pool中申明的变量在新的@autoreleasepool中作用域将被局限。解决方法是把变量申明拿到pool的申请之前。***

  * ARC forbids Objective-C objects in structs or unions
  
  ***可以说ARC所引入的最严格的限制是不能在C结构体中放OC对象了..因此类似下面这样的代码是不可用的***

```objc  
typedef struct { 
	UIImage *selectedImage; 
	UIImage *disabledImage; 
} ButtonImages;
```
 
这个问题只有乖乖想办法了..改变原来的结构什么的..

### 手动转换

刚才做了对demo的大部分转换，还剩下了MainViewController和AFHTTPRequestOperation是MRC。但是由于使用了`-fno-objc-arc`，因此现在编译和运行都没有问题了。下面我们看看如何手动把MainViewController转为ARC，这也有助于进一步理解ARC的规则。

首先，我们需要转变一下观念…对于MainViewController.h，在.h中申明了两个实例变量：
    
```objc
@interface MainViewController : UIViewController  
{ 
	NSOperationQueue *queue;
	NSMutableString *currentStringValue; 
}
```

我们不妨仔细考虑一下，为什么在interface里出现了实例变量的申明？通常来说，实例变量只是在类的实例中被使用，而你所写的类的使用者并没有太多必要了解你的类中有哪些实例变量。而对于绝大部分的实例变量，应该都是`protected`或者`private`的，对它们的操作只应该用`setter`和`getter`，而这正是property所要做的工作。可以说，**将实例变量写在头文件中是一种遗留的陋习**。更好的写实例变量名字的地方应当与类实现关系更为密切，为了隐藏细节，我们应该考虑将它们写在@implementation里。好消息是，在LLVM3.0中，不论是否开启ARC，编译器是支持将实例变量写到实现文件中的。甚至如果没有特殊需要又用了property，我们都不应该写无意义的实例变量申明，因为在@synthesize中进行绑定时，我们就可以设置变量名字了，这样写的话可以让代码更加简洁。

在这里我们对着两个实例变量不需要property(外部成员不应当能访问到它们)，因此我们把申明移到.m里中。修改后的.h是这样的，十分简洁一看就懂～

```objc    
#import 
@interface MainViewController : UIViewController
@property (nonatomic, retain) IBOutlet UITableView *tableView;  
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar; 
@end
```

然后.m的开头变成这样：

```objc    
@implementation MainViewController 
{ 
	NSOperationQueue *queue;  
	NSMutableString *currentStringValue;  
}
```

这样的写法让代码相当灵活，而且不得不承认.m确实是这些实例变量的应该在的地方…build一下，没问题..当然对于SoundEffect类也可以做相似的操作，这会让使用你的类的人很开心，因为.h越简单越好..P.S.另外一个好处可以减少.h里的引用，减少编译时间(虽然不明显=。=)

然后就可以在MainViewController里启用ARC了，方法很简单，删掉Build Phases里相关文件的-fno-objc-arc标记就可以了～然后..然后当然是一大堆错误啦。我们来手动一个个改吧，虽然谈不上乐趣，但是成功以后也会很有成就～(如果你不幸在启用ARC后build还是成功了，恭喜你遇到了Xcode的bug，请Cmd+Q然后重新打开Xcode把=_=)

#### dealloc

红色最密集的地方是`dealloc`，因为每一行都是`release`。由于在这里`dealloc`并没有做除了`release`和`super dealloc`之外的任何事情，因此简单地把整个方法删掉就好了。当然，在对象被销毁时，`dealloc`还是会被调用的，因此我们在需要对非ARC管理的内存进行管理和必要的逻辑操作的时候，还是应该保留`dealloc`的，当然这涉及到CF以及以下层的东西：比如对于`retain`的CF对象要`CFRelease()`，对于`malloc()`到堆上的东西要`free()`掉，对于添加的`observer`可以在这里remove，schedule的timer在这里`invalidate`等等～`[super dealloc]`这个消息也不再需要发了，ARC会自动帮你搞定。

另外，在MRC时代一个常做的事情是在`dealloc`里把指向自己的delegate设成nil(否则就等着EXC_BAD_ACCESS吧 :P)，而现在一般delegate都是`weak`的，因此在self被销毁后这个指针自动被置成`nil`了，你不用再为之担心，好棒啊..

#### 去掉各种release和autorelease

这个很直接，没有任何问题。去掉就行了～不再多说

#### 讨论一下Property

在MainViewController.m里的类扩展中定义了两个property：

```objc    
@interface MainViewController ()
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) SoundEffect *soundEffect; 
@end
```

申明的类型是`retain`，关于`retain`,`assign`和`copy`的讨论已经烂大街了，在此不再讨论。在MRC的年代使用property可以帮助我们使用dot notation的时候简化对象的`retain`和`copy`，而在ARC时代，这就显得比较多余了。<del>在我看来，使用property和点方法来调用setter和getter是不必要的。property只在将需要的数据在.h中暴露给其他类时才需要，而在本类中，只需要用实例变量就可以。</del>(更新，现在笔者在这点上已经不纠结了，随意就好，自己明白就行。但是也许还是用点方法会好一些，至少可以分清楚到底是操作了实例变量还是调用了setter和getter)。因此我们可以移去searchResults和soundEffect的@property和@synthesize，并将起移到实例变量申明中：

```objc
#import "plementation MainViewController
{ 
	NSOperationQueue *queue; 
	NSMutableString *currentStringValue;
	NSMutableArray *searchResults;
	SoundEffect *soundEffect; 
}
```

相应地，我们需要将对应的`self.searchResult`和`self.soundEffect`的self.都去去掉。在这里需要注意的是，虽然我们去掉了soundEffect的property和synthesize，但是我们依然有一个lazy loading的方法`-(SoundEffect *)soundEffect`，神奇之处在于(可能你以前也不知道)，点方法并不需要@property关键字的支持，虽然大部分时间是这么用的..(property只是对setter或者getter的申明，而点方法是对其的调用，在这个例子的实现中我们事实上实现了-soundEffect这个getter方法，所以点方法在等号右边的getter调用是没有问题的)。为了避免误解，建议把self.soundEffect的getter调用改写成[self soundEffect]。

然后我们看看.h里的property～里面有两个`retain`的IBOutlet。`retain`关键字在ARC中是依旧可用的，它在ARC中所扮演的角色和`strong`完全一样。为了避免迷惑，最好在需要的时候将其写为strong，那样更符合ARC的规则。对于这两个property，我们将其申明为`weak`(事实上，如果没有特别意外，除了最顶层的IBOutlet意外，自己写的outlet都应该是`weak`)。通过加载xib得到的用户界面，在其从xib文件加载时，就已经是view hierarchy的一部分了，而view hierarchy中的指向都是strong的。因此outlet所指向的UI对象不应当再被hold一次了。将这些outlet写为weak的最显而易见的好处是你就不用再viewDidUnload方法中再将这些outlet设为nil了(否则就算view被摧毁了，但是由于这些UI对象还在被outlet指针指向而无法释放，代码简洁了很多啊..)。

在我们的demo中将IBOutlet的property改为`weak`并且删掉viewDidUnload中关于这两个IBOutlet的内容～

总结一下新加入的property的关键字类型：

  * strong 和原来的retain比较相似，strong的property将对应__strong的指针，它将持有所指向的对象
  * weak 不持有所指向的对象，而且当所指对象销毁时能将自己置为nil，基本所有的outlet都应该用weak
  * unsafe_unretained 这就是原来的assign。当需要支持iOS4时需要用到这个关键字
  * copy 和原来基本一样..copy一个对象并且为其创建一个strong指针
  * assign 对于对象来说应该永远不用assign了，实在需要的话应该用unsafe_unretained代替(基本找不到这种时候，大部分assign应该都被weak替代)。但是对于基本类型比如int,float,BOOL这样的东西，还是要用assign。

特别地，对于`NSString`对象，在MRC时代很多人喜欢用copy，而ARC时代一般喜欢用strong…(我也不懂为什么..求指教)

#### 自由桥接的细节

MainViewController现在剩下的问题都是桥接转换问题了～有关桥接的部分有三处：

  * (NSString *)CFURLCreateStringByAddingPercentEscapes(…)：CFStringRef至NSString *
  * (CFStringRef)text：NSString *至CFStringRef
  * (CFStringRef)@“!_‘();:@&=+$,/?%#[]"：NSString _至CFStringRef

编译器对前两个进行了报错，最后一个是常量转换不涉及内存管理。

关于toll-free bridged，如果不进行细究，`NSString`和`CFStringRef`是一样的东西，新建一个`CFStringRef`可以这么做：

```objc    
CFStringRef s1 = [[NSString alloc] initWithFormat:@"Hello, %@!",name];
```

然后，这里`alloc`了而s1是一个CF指针，要释放的话，需要这样：

```objc    
CFRelease(s1);
```

相似地可以用`CFStringRef`来转成一个`NSString`对象(MRC)：
    
```objc
CFStringRef s2 = CFStringCreateWithCString(kCFAllocatorDefault,bytes, kCFStringEncodingMacRoman); 
NSString *s3 = (NSString *)s2; 

// release the object when you're done   
[s3 release]; 
```

在ARC中，编译器需要知道这些指针应该由谁来负责释放，如果把一个`NSObject`看做是CF对象的话，那么ARC就不再负责它的释放工作(记住ARC是only for NSObject的)。对于不需要改变持有者的对象，直接用简单的**bridge就可以了，比如之前在SoundEffect.m做的转换。在这里对于(CFStringRef)text这个转换，ARC已经负责了text这个NSObject的内存管理，因此这里我们需要一个简单的**bridge。而对于`CFURLCreateStringByAddingPercentEscapes`方法，方法中的create暗示了这个方法将形成一个新的对象，如果我们不需要`NSString`转换，那么为了避免内存的问题，我们需要使用`CFRelease`来释放它。而这里我们需要一个`NSString`，因此我们需要告诉编译器接手它的内存管理工作。这里我们使用**bridge_transfer关键字，将内存管理权由CF object移交给NSObject(或者说ARC)。如果这里我们只用**bridge的话，内存管理的负责人没有改变，那么这里就会出现一个内存泄露。另外有时候会看到`CFBridgingRelease()`，这其实就是transfer cast的内联写法..是一样的东西。总之，需要记住的原则是，当在涉及CF层的东西时，如果函数名中有含有Create, Copy, 或者Retain之一，就表示返回的对象的retainCount+1了，对于这样的对象，最安全的做法是将其放在`CFBridgingRelease()`里，来平衡`retain`和`release`。

还有一种bridge方式，`__bridge_retained`。顾名思义，这种转换将在转换时将retainCount加1。和`CFBridgingRelease()`相似，也有一个内联方法`CFBridgingRetain()`来负责和`CFRelease()`进行平衡。

需要注意的是，并非所有的CF对象都是自由桥接的，比如Core Graphics中的所有对象都不是自由桥接的(如`CGImage`和`UIImage`，`CGColor`和`UIColor`)。另外也不是只有自由桥接对象才能用bridge来桥接，一个很好的特例是void _(指向任意对象的指针，类似id)，对于void _和任意对象的转换，一般使用`_bridge`。(这在将ARC运用在Cocos2D中很有用)

#### 终于搞定了

至此整个工程都ARC了～对于AFHTTPRequestOperation这样的不支持ARC的第三方代码，我们的选择一般都是就不使用ARC了(或者等开源社区的大大们更新ARC适配版本)。可以预见，在近期会有越来越多的代码转向ARC，但是也一定会有大量的代码暂时或者永远保持MRC等个，所以对于这些代码就不用太纠结了～

* * *

## 写在最后

写了那么多，希望你现在能对ARC有个比较全面的了解和认识了。ARC肯定是以后的趋势，也确实能让代码量大大降低，减少了很多无意义的重复工作，还提高了app的稳定性。但是凡事还是纸上得来终觉浅，希望作为开发者的你，在下一个工程中去尝试用用ARC～相信你会和我一样，马上爱上这种make life easier的方式的～
