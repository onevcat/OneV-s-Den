---
layout: post
title: 深入Objective-C的动态特性
date: 2012-04-22 23:18:44.000000000 +09:00
tags: 能工巧匠集
---

Objective-C具有相当多的动态特性，基本的，也是经常被提到和用到的有动态类型（Dynamic typing），动态绑定（Dynamic binding）和动态加载（Dynamic loading）。

这些动态特性都是在Cocoa程序开发时非常常用的语言特性，而在这之后，OC在底层也提供了相当丰富的运行时的特性，比如枚举类属性方法、获取方法实现等等。虽然在平常的Cocoa开发中这些较底层的运行特性基本用不着，但是在某些情况下如果你知道这些特性并合理加以运用的话，往往能事半功倍～

### 动态特性基础

1、动态类型

即运行时再决定对象的类型。这类动态特性在日常应用中非常常见，简单说就是id类型。id类型即通用的对象类，任何对象都可以被id指针所指，而在实际使用中，往往使用introspection来确定该对象的实际所属类：

```
id obj = someInstance;
if ([obj isKindOfClass:someClass])
{
    someClass *classSpecifiedInstance = (someClass *)obj;
    // Do Something to classSpecifiedInstance which now is an instance of someClass
    //...
}
```
`-isMemberOfClass:` 是 `NSObject` 的方法，用以确定某个 `NSObject` 对象是否是某个类的成员。与之相似的为 `-isKindOfClass:`，可以用以确定某个对象是否是某个类或其子类的成员。这两个方法为典型的introspection方法。在确定对象为某类成员后，可以安全地进行强制转换，继续之后的工作。

2、动态绑定

基于动态类型，在某个实例对象被确定后，其类型便被确定了。该对象对应的属性和响应的消息也被完全确定，这就是动态绑定。在继续之前，需要明确Objective-C中消息的概念。由于OC的动态特性，在OC中其实很少提及“函数”的概念，传统的函数一般在编译时就已经把参数信息和函数实现打包到编译后的源码中了，而在OC中最常使用的是消息机制。调用一个实例的方法，所做的是向该实例的指针发送消息，实例在收到消息后，从自身的实现中寻找响应这条消息的方法。

动态绑定所做的，即是在实例所属类确定后，将某些属性和相应的方法绑定到实例上。这里所指的属性和方法当然包括了原来没有在类中实现的，而是在运行时才需要的新加入的实现。在Cocoa层，我们一般向一个NSObject对象发送-respondsToSelector:或者-instancesRespondToSelector:等来确定对象是否可以对某个SEL做出响应，而在OC消息转发机制被触发之前，对应的类的+resolveClassMethod:和+resolveInstanceMethod:将会被调用，在此时有机会动态地向类或者实例添加新的方法，也即类的实现是可以动态绑定的。一个例子：

```
void dynamicMethodIMP(id self, SEL _cmd)
{
    // implementation ....
}



//该方法在OC消息转发生效前被调用
+ (BOOL) resolveInstanceMethod:(SEL)aSEL
{ 
    if (aSEL == @selector(resolveThisMethodDynamically)) {
        //向[self class]中新加入返回为void的实现，SEL名字为aSEL，实现的具体内容为dynamicMethodIMP class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, “v@:”);
        return YES;
    }
    return [super resolveInstanceMethod:aSel];
}  
```

当然也可以在任意需要的地方调用`class_addMethod`或者`method_setImplementation`（前者添加实现，后者替换实现），来完成动态绑定的需求。

3、动态加载

根据需求加载所需要的资源，这点很容易理解，对于iOS开发来说，基本就是根据不同的机型做适配。最经典的例子就是在Retina设备上加载@2x的图片，而在老一些的普通屏设备上加载原图。随着Retina iPad的推出，和之后可能的Retina Mac的出现，这个特性相信会被越来越多地使用。

### 深入运行时特性

基本的动态特性在常规的Cocoa开发中非常常用，特别是动态类型和动态绑定。由于Cocoa程序大量地使用Protocol-Delegate的设计模式，因此绝大部分的delegate指针类型必须是id，以满足运行时delegate的动态替换（在Java里这个设计模式被叫做Strategy？不是很懂Java，求纠正）。而Objective-C还有一些高级或者说更底层的运行时特性，在一般的Cocoa开发中较为少见，基本被运用与编写OC和其他语言的接口上。但是如果有所了解并使用得当的话，在Cocoa开发中往往可以轻易解决一些棘手问题。

这类运行时特性大多由`/usr/lib/libobjc.A.dylib`这个动态库提供，里面包括了对于类、实例成员、成员方法和消息发送的很多API，包括获取类实例变量列表，替换类中的方法，为类成员添加变量，动态改变方法实现等，十分强大。完整的API列表和手册可以在这里找到。虽然文档开头表明是对于Mac OS X Objective-C 2.0适用，但是由于这些是OC的底层方法，因此对于iOS开发来说也是完全相同的。

一个简单的例子，比如在开发Universal应用或者游戏时，如果使用IB构建了大量的自定义的UI，那么在由iPhone版转向iPad版的过程中所面临的一个重要问题就是如何从不同的nib中加载界面。在iOS5之前，所有的`UIViewController`在使用默认的界面加载时(`init`或者`initWithNibName:bundle:`)，都会走`-loadNibNamed:owner:options:`。而因为我们无法拿到`-loadNibNamed:owner:options`的实现，因此对其重载是比较困难而且存在风险的。因此在做iPad版本的nib时，一个简单的办法是将所有的nib的命名方式统一，然后使用自己实现的新的类似`-loadNibNamed:owner:options`的方法将原方法替换掉，同时保证非iPad的设备还走原来的`loadNibNamed:owner:options`方法。使用OC运行时特性可以较简单地完成这一任务。

代码如下，在程序运行时调用`+swizze`，交换自己实现的`loadPadNibNamed:owner:options`和系统的`loadNibNamed:owner:options`，之后所有的`loadNibNamed:owner:options`消息都将会发为`loadPadNibNamed:owner:options`，由自己的代码进行处理。

```
+(BOOL)swizze {
    Method oldMethod = class_getInstanceMethod(self, @selector(loadNibNamed:owner:options:));
    if (!oldMethod) {
        return NO;
    }
    Method newMethod = class_getInstanceMethod(self, @selector(loadPadNibNamed:owner:options:));
    if (!newMethod) {
        return NO;
    }
    method_exchangeImplementations(oldMethod, newMethod);
    return YES;
}  
```

`loadPadNibNamed:owner:options`的实现如下，注意在其中的`loadPadNibNamed:owner:options`由于之前已经进行了交换，因此实际会发送为系统的`loadNibNamed:owner:options`。以此完成了对不同资源的加载。

```
-(NSArray *)loadPadNibNamed:(NSString *)name owner:(id)owner options:(NSDictionary *)options {
    NSString *newName = [name stringByReplacingOccurrencesOfString:@"@pad" withString:@""];
    newName = [newName stringByAppendingFormat:@"@pad"];
    //判断是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:newName ofType:@”nib”];
    //这里调用的loadPadNibNamed:owner:options:实际为为交换后的方法，即loadNibNamed:owner:options:
    if ([fm fileExistsAtPath:filepath]) {
        return [self loadPadNibNamed:newName owner:owner options:options];
    } else {
        return [self loadPadNibNamed:name owner:owner options:options]; 
    }
}  
```

当然这只是一个简单的例子，而且这个功能也可以通过别的方法来实现。比如添加UIViewController的类别来重载init，但是这样的重载会比较危险，因为你UIViewController的实现你无法完全知道，因此可能会由于重载导致某些本来应有的init代码没有覆盖，从而出现不可预测的错误。当然在上面这个例子中重载VC的init的话没有什么问题(因为对于VC，init的方法会被自动转发为loadNibNamed:owner:options，因此init方法并没有做其他更复杂的事情，因此只要初始化VC时使用的都是init的话就没有问题)。但是并不能保证这样的重载对于其他类也是可行的。因此对于实现未知的系统方法，使用上面的运行时交换方法会是一个不错的选择～
