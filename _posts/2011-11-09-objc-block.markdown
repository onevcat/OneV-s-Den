---
layout: post
title: Objective-C中的Block
date: 2011-11-09 23:55:12.000000000 +09:00
tags: 能工巧匠集
---
技术是需要沉淀的。接触iOS开发也有大半年时间了，从一开始的纯白到现在自我感觉略懂一点，其实进步是明显的。无数牛人表示技术博是完成菜鸟到高手蜕变的途径之一，虽然这个博客并非是为技术而生，但是也许作为工科背景下的我来说，每天都写文艺的东西显然并不现实。于是就有了这个集子：能工巧匠集。用这篇开篇，

写一些在开发过程中的积累和感悟，大部分应该是Objectiv-C和XCode的内容，包括基本语法特性和小技巧，或者自己喜欢的一些开源代码的用法分析等等。也许以后会扩展到Unity3D或者UDK的一些3D引擎的心得，当然也有可能会有别的一些自己认为值得分享的东西。这个集子的目的，一来是记录自己一步一步成长的脚印，二来也算是为新来者铺一条直一点的道路。集子里的东西仅仅是自己的心得体会，高手路过请一笑置之..感恩。

iOS SDK 4.0开始，Apple引入了block这一特性，而自从block特性诞生之日起，似乎它就受到了Apple特殊的照顾和青睐。字面上说，block就是一个代码块，但是它的神奇之处在于在内联(inline)执行的时候(这和C++很像)还可以传递参数。同时block本身也可以被作为参数在方法和函数间传递，这就给予了block无限的可能。

在日常的coding里绝大时间里开发者会是各种block的使用者，但是当你需要构建一些比较基础的，提供给别人用的类的时候，使用block会给别人的使用带来很多便利。当然如果你已经厌烦了一直使用delegate模式来编程的话，偶尔转转写一些block，不仅可以锻炼思维，也能让你写的代码看起来高端洋气一些，而且因为代码跳转变少，所以可读性也会增加。

先来看一个简单的block吧：

```objc
// Defining a block variable
BOOL (^isInputEven)(int) = ^(int input) {
	if (input % 2 == 0) {
		return YES;
	} else {
		return NO;
	}
};
```

以上定义了一个block变量，block本身就是一个程序段，因此有返回值有输入参数，这里这个block返回的类型为BOOL。天赋异秉的OC用了同样不走寻常路的"{% raw %}
^{% endraw %}"符号来表示block定义的开始（就像用减号和加号来定义方法一样），block的名称紧跟在{% raw %}
^{% endraw %}符号之后，这里是isInputEven（也即以后使用inline方式调用该block时所需要的名称）。这段block接受一个int型的参数，而在等号后面的int input是对这个传入int参数的说明：在该block内，将使用input这个名字来指代传入的int参数。一开始看block的定义和写法时可能会比较痛苦，但是请谨记它只是把我们常见的方法实现换了一种写法而已，请以习惯OC中括号发送消息的速度和决心，尽快习惯block的写法吧！

调用这个block的方法就非常简单和直观了，类似调用c函数的方式即可：

```objc
// Call similar to a C function call
int x = -101;
NSLog(@"%d %@ number", x, isInputEven(x) ? @"is an even" : @"is not an even");
```

不出意外的话输出为**-101 is not an even number**

以上的用法没有什么特别之处，只不过是类似内联函数罢了。但是block的神奇之处在于block外的变量可以无缝地直接在block内部使用，比如这样：

```objc
float price = 1.99; 
float (^finalPrice)(int) = ^(int quantity) {
	// Notice local variable price is 
	// accessible in the block
	return quantity * price;
};
int orderQuantity = 10;
NSLog(@"Ordering %d units, final price is: $%2.2f", orderQuantity, finalPrice(orderQuantity));
```

输出为**Ordering 10 units, final price is: $19.90**

相当开心啊，block外的`price`成功地在block内部也能使用了，这意味着内联函数可以使用处于同一scope里的局部变量。但是需要注意的是，你不能在block内部改变本地变量的值，比如在{% raw %}
^{% endraw %}{}里写`price = 0.99`这样的语句的话，你亲爱的compiler一定是会叫的。而更需要注意的是`price`这样的局部变量的变化是不会体现在block里的！比如接着上面的代码，继续写：

```objc
price = .99;
NSLog(@"Ordering %d units, final price is: $%2.2f", orderQuantity, finalPrice(orderQuantity));
```

输出还是**Ordering 10 units, final price is: $19.90，**这就比较忧伤了，可以理解为在block内的`price`是readonly的，只在定义block时能够被赋值（补充说明，实际上是因为`price`是value type，block内的`price`是在申明block时复制了一份到block内，block外面的`price`无论怎么变化都和block内的`price`无关了。如果是reference type的话，外部的变化实际上是会影响block内的）。

但是如果确实需要传递给block变量值的话，可以考虑下面两种方法：

1、将局部变量声明为`__block`，表示外部变化将会在block内进行同样操作，比如：  

```objc
// Use the __block storage modifier to allow changes to 'price'
__block float price = 1.99;
float (^finalPrice)(int) = ^(int quantity) {
	return quantity * price;
};

int orderQuantity = 10;
price = .99;

NSLog(@"With block storage modifier - Ordering %d units, final price is: $%2.2f", orderQuantity, finalPrice(orderQuantity));
```

此时输出为**With block storage modifier – Ordering 10 units, final price is: $9.90**

2、使用实例变量——这个比较没什么好说的，实例内的变量横行于整个实例内..可谓霸道无敌...=_=

block外的对象和基本数据一样，也可以作为block的参数。而让人开心的是，block将自动retain传递进来的参数，而不需担心在block执行之前局部对象变量已经被释放的问题。这里就不深究这个问题了，只要严格遵循Apple的thread safe来写，block的内存管理并不存在问题。（更新，ARC的引入再次简化了这个问题，完全不用担心内存管理的问题了）

由于block的灵活的机制，导致iOS SDK 4.0开始，Apple大力提倡在各种地方应用block机制。最典型的当属UIView的动画了：在4.0前写一个UIView的Animation大概是这样的：

```objc
[UIView beginAnimations:@"ToggleSiblings"context:nil];
[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
[UIViewsetAnimationDuration:1.0f];
// Make your changes
[UIView commitAnimations];
```

在一个不知名的小角落里的begin/commit两行代码间写下需要进行的动作，然后静待发生。而4.0后这样的方法直接被discouraged了(虽然还没Deprecated)，取而代之的正是block：

```objc
[UIView animateWithDuration:5.0f animations:^{
	view.opacity = 0.5f;
}];
```

简单明了，一切就这么发生了..

可能有人会觉得block的语法很奇怪，不像是OOP的风格，诚然直接使用的block看起来破坏了OOP的结构，也让实例的内存管理出现了某些“看上去奇怪”的现象。但是通过`typedef`的方法，可以将block进行简单包装，让它的行为更靠近对象一些： 

```objc
typedef double (^unary_operation_t)(double op);
```

定义了一个接受一个double型作为变量，类型为unary_operation_t的block，之后在使用前用类似C的语法声明一个unary_operation_t类型的"实例"，并且定义内容后便可以直接使用这个block了～

```objc
unary_operation_t square;
square = ^(double operand) {
	return operand * operand;
}
```

<del>啰嗦一句的还是内存管理的问题，block始终不是对象，而block的内存管理自然也是和普通对象不一样。系统会为block在堆上分配内存，而当把block当做对象进行处理时（比如将其压入一个NSMutableArray），我们需要获取它的一份copy（比如[square copy]），并且在Array retain了这个block后将其释放（[square autorelease]是不错的选择）。而对于block本身和调用该block的实例，则可以放心：SDK会将调用block的实例自动retain，直至block执行完毕后再对实例release，因此不会出现block执行到一半，实例就被dealloc这样的尴尬的局面。</del> 在ARC的时代，这些都是废话了。打开ARC，然后瞎用就可以了。ARC解决了block的最让开发者头疼的最大的也是唯一的问题，内存管理。关于block的内存管理方面，有一个很好玩的小quiz，可以做做玩～[传送门](http://blog.parse.com/2013/02/05/objective-c-blocks-quiz/)

iOS SDK 4.0以后，随着block的加入很多特性也随之添加或者发生了升级。Apple所推荐的block使用范围包括以下几个方面： 

  * 枚举——通过block获取枚举对象或控制枚举进程
  * View动画——简单明了的方式规定动画
  * 排序——在block内写排序算法
  * 通知——当某事件发生后执行block内的代码
  * 错误处理——当错误发生时执行block代码
  * 完成处理——当方法执行完毕后执行block代码
  * GCD多线程——多线程控制，关于这个以后有机会再写…

仔细研读4.0的SDK的话，会发现很多常用类中都加入了不少带block作为参数的方法，改变固有思维习惯，适应并尽可能利用block给程序上带来的便捷，无疑是提高效率和使代码优雅的很好的途径～
