---
layout: post
title: WWDC 2012 Session笔记——405 Modern Objective-C
date: 2012-06-24 23:39:08.000000000 +09:00
tags: 能工巧匠集
---

这是博主的WWDC2012笔记系列中的一篇，完整的笔记列表可以参看[这里](http://onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)。如果您是首次来到本站，也许您会有兴趣通过[RSS](http://onevcat.com/atom.xml)，或者通过页面左侧的邮件订阅的方式订阅本站。

2007年的时候，Objective-C在TIOBE编程语言排名里还排在可怜的第45位，而随着移动互联网的迅速发展和iPhone，iPad等iOS设备的广阔市场前景，Objective-C也迅速崛起，走进了开发者的视野。在最近的TIOBE排名中，Objective-C达到了惊人的第4名，可以说已经成为当今世界上一门非常重要的编程语言。

而Objective-C现在主要是由Apple在负责维护了。一直以来Apple为了适应开发的发展需要，不断在完善OC以及相应的cocoa库，2.0中引入的property，随着iOS4引入的block，以及去年引入的ARC，都受到了绝大部分开发者的欢迎。几乎每年都有重大特性的加入，这不是每种语言都能做到的，更况且这些特性都为大家带来了众多的便利。

今年WWDC也不例外，OC和LLVM将得到重大的改进。本文将对这些改进进行一个简单整理和评述。

### 方法顺序

如果有以下代码：

```objc
@interface SongPlayer : NSObject 
- (void)playSong:(Song *)song; 
@end

@implementation SongPlayer 

- (void)playSong:(Song *)song { 
    NSError *error; 
    [self startAudio:&error]; 
    //... 
} 

- (void)startAudio:(NSError **)error { 
    //... 
} 

@end
```

在早一些的编译环境中，上面的代码会在[self startAudio:&error]处出现一个实例方法未找到的警告。由于编译顺序，编译器无法得知在-playSong:方法之后还有一个-startAudio:，因此给出警告。以前的解决方案有两种：要么将-startAudio:的实现移到-playSong:的上方，要么在类别中声明-startAudio:(顺便说一句..把-startAudio:直接拿到.h文件中是完全错误的做法，因为这个方法不应该是public的)。前者破坏.m文件的结构打乱了方法排列的顺序，导致以后维护麻烦；后者要写额外的不必要代码，使.m文件变长。其实两种方法都不是很好的解决方案。

现在不需要再头疼这个问题了，LLVM中加入了新特性，现在直接使用上面的代码，不需要做额外处理也可以避免警告了。新编译器改变了以往顺序编译的行为，改为先对方法申明进行扫描，然后在对方法具体实现进行编译。这样，在同一实现文件中，无论方法写在哪里，编译器都可以在对方法实现进行编译前知道所有方法的名称，从而避免了警告。

* * *

### 枚举改进

从Xcode4.4开始，有更好的枚举的写法了：

```objc
typedef enum NSNumberFormatterStyle : NSUInteger {
    NSNumberFormatterNoStyle, 
    NSNumberFormatterDecimalStyle, 
    NSNumberFormatterCurrencyStyle, 
    NSNumberFormatterPercentStyle, 
    NSNumberFormatterScientificStyle, 
    NSNumberFormatterSpellOutStyle 
} NSNumberFormatterStyle;
```

在列出枚举列表的同时绑定了枚举类型为NSUInteger，相比起以前的直接枚举和先枚举再绑定类型好处是方便编译器给出更准确的警告。个人觉得对于一般开发者用处并不是特别大，因为往往并不会涉及到很复杂的枚举，用以前的枚举申明方法也不至于就搞混。所以习惯用哪种枚举方式还是接着用就好了..不过如果有条件或者还没有形成自己的习惯或者要开新工程的话，还是尝试一下这种新方法比较好，因为相对来说要严格一些。

* * *

### 属性自动绑定

人人都爱用property，这是毋庸置疑的。但是写property的时候一般都要对应写实例变量和相应的synthesis，这实在是一件让人高兴不起来的事情。Apple之前做了一些努力，至少把必须写实例变量的要求去掉了。在synthesis中等号后面的值即为实力变量名。**现在Apple更进一步，给我们带来了非常好的消息：以后不用写synthesis了！**Xcode 4.4之后，synthesis现在会对应property自动生成。

默认行为下，对于属性foo，编译器会自动在实现文件中为开发者补全synthesis，就好像你写了@synthesis foo = _foo;一样。默认的实例变量以下划线开始，然后接属性名。如果自己有写synthesis的话，将以开发者自己写的synthesis为准，比如只写了@synthesis foo;那么实例变量名就是foo。如果没有synthesis，而自己又实现了-foo以及-setFoo:的话，该property将不会对应实例变量。而如果只实现了getter或者setter中的一个的话，另外的方法会自动帮助生成(即使没有写synthesis，当然readonly的property另说)。

对于写了@dynamic的实现，所有的对应的synthesis都将不生效(即使没有写synthesis，这是runtime的必然..)，可以理解为写了dynamic的话setter和getter就一定是运行时确定的。

总结一下，新的属性绑定规则如下：

* 除非开发者在实现文件中提供getter或setter，否则将自动生成
* 除非开发者同时提供getter和setter，否则将自动生成实例变量
* 只要写了synthesis，无论有没有跟实例变量名，都将生成实例变量
* dynamic优先级高于synthesis

* * *

### 简写

OC的语法一直被认为比较麻烦，绝大多数的消息发送都带有很长的函数名。其实这是一把双刃剑，好的方面，它使得代码相当容易阅读，因为几乎所有的方法都是以完整的英语进行描述的，而且如果遵守命名规则的话，参数类型和方法作用也一清二楚，但是不好的方面，它使得coding的时候要多不少不必要的键盘敲击，降低了开发效率。Apple意识到了这一点，在新的LLVM中引入了一系列列规则来简化OC。经过简化后，以降低部分可读性为代价，换来了开发时候稍微快速一些，可以说比较符合现在短开发周期的需要。简化后的OC代码的样子向Perl或者Python这样的快速开发语言靠近了一步，至于实际用起来好不好使，就还是仁智各异了…至少我个人对于某些简写不是特别喜欢..大概是因为看到简写的代码还没有形成直觉，总要反应一会儿才能知道这是啥…

#### NSNumber

所有的[NSNumber numberWith…:]方法都可以简写了：

* `[NSNumber numberWithChar:‘X’]` 简写为 `@‘X’`;
* `[NSNumber numberWithInt:12345]` 简写为 `@12345`
* `[NSNumber numberWithUnsignedLong:12345ul]` 简写为 `@12345ul`
* `[NSNumber numberWithLongLong:12345ll]` 简写为 `@12345ll`
* `[NSNumber numberWithFloat:123.45f]` 简写为 `@123.45f`
* `[NSNumber numberWithDouble:123.45]` 简写为 `@123.45`
* `[NSNumber numberWithBool:YES]` 简写为 `@YES`

嗯…方便很多啊～以前最讨厌的就是数字放Array里还要封装成NSNumber了…现在的话直接用@开头接数字，可以简化不少。

#### NSArray

部分NSArray方法得到了简化：

* `[NSArray array]` 简写为 `@[]`
* `[NSArray arrayWithObject:a]` 简写为 `@[ a ]`
* `[NSArray arrayWithObjects:a, b, c, nil]` 简写为 `@[ a, b, c ]`

可以理解为@符号就表示NS对象(和NSString的@号一样)，然后接了一个在很多其他语言中常见的方括号[]来表示数组。实际上在我们使用简写时，编译器会将其自动翻译补全为我们常见的代码。比如对于@[ a, b, c ]，实际编译时的代码是

```objc
// compiler generates:
id objects[] = { a, b, c }; 
NSUInteger count = sizeof(objects)/ sizeof(id); 
array = [NSArray arrayWithObjects:objects count:count];
```

需要特别注意，要是a,b,c中有nil的话，在生成NSArray时会抛出异常，而不是像[NSArray arrayWithObjects:a, b, c, nil]那样形成一个不完整的NSArray。其实这是很好的特性，避免了难以查找的bug的存在。

#### NSDictionary

既然数组都简化了，字典也没跑儿，还是和Perl啊Python啊Ruby啊很相似，意料之中的写法：

* `[NSDictionary dictionary]` 简写为 `@{}`
* `[NSDictionary dictionaryWithObject:o1 forKey:k1]` 简写为 `@{ k1 : o1 }`
* `[NSDictionary dictionaryWithObjectsAndKeys:o1, k1, o2, k2, o3, k3, nil]` 简写为 `@{ k1 : o1, k2 : o2, k3 : o3 }`

和数组类似，当写下@{ k1 : o1, k2 : o2, k3 : o3 }时，实际的代码会是

```objc
// compiler generates: 
id objects[] = { o1, o2, o3 }; 
id keys[] = { k1, k2, k3 }; 
NSUInteger count = sizeof(objects) / sizeof(id); 
dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
```

#### Mutable版本和静态版本

上面所生成的版本都是不可变的，想得到可变版本的话，可以对其发送-mutableCopy消息以生成一份可变的拷贝。比如

```objc
NSMutableArray *mutablePlanets = [@[ 
                                  @"Mercury", @"Venus", 
                                  @"Earth", @"Mars", 
                                  @"Jupiter", @"Saturn", 
                                  @"Uranus", @"Neptune" ] 
                                  mutableCopy];
```

另外，对于标记为static的数组(没有static的字典..哈希和排序是在编译时完成的而且cocoa框架的key也不是常数)，不能使用简写为其赋值(其实原来的传统写法也不行)。解决方法是在类方法+ (void)initialize中对static进行赋值，比如：

```objc
static NSArray *thePlanets; 
+ (void)initialize { 
    if (self == [MyClass class]) { 
        thePlanets = @[ @"Mercury", @"Venus", @"Earth", @"Mars", @"Jupiter", @"Saturn", @"Uranus", @"Neptune" ]; 
    } 
}
```

#### 下标

其实使用这些简写的一大目的是可以使用下标来访问元素：

* `[_array objectAtIndex:idx]` 简写为 `_array[idx]`;
* `[_array replaceObjectAtIndex:idx withObject:newObj]` 简写为 `_array[idx] = newObj`
* `[_dic objectForKey:key]` 简写为 `_dic[key]`
* `[_dic setObject:object forKey:key]` 简写为 `_dic[key] = newObject`

很方便，但是一定需要注意，对于字典用的也是方括号[]，而不是想象中的花括号{}。估计是想避免和代码块的花括号发生冲突吧…简写的实际工作原理其实真的就只是简单的对应的方法的简写，没有什么惊喜。

但是还是有惊喜的..那就是使用类似的一套方法，可以做到对于我们自己的类，也可以使用下标来访问。而为了达到这样的目的，我们需要实现以下方法，

对于类似数组的结构：

```objc
- (elementType)objectAtIndexedSubscript:(indexType)idx; </pre>
- (void)setObject:(elementType)object atIndexedSubscript:(indexType)idx;
```


对于类似字典的结构：
```objc
- (elementType)objectForKeyedSubscript:(keyType)key; </pre>
- (void)setObject:(elementType)object forKeyedSubscript:(keyType)key;
```

* * *

### 固定桥接

对于ARC来说，最让人迷惑和容易出错的地方大概就是桥接的概念。由于历史原因，CF对象和NSObject对象的转换一直存在一些微妙的关系，而在引入ARC之后，这些关系变得复杂起来：主要是要明确到底应该是由CF还是由NSObject来负责内存管理的问题(关于ARC和更详细的说明，可以参看我之前写的一篇[ARC入门教程](http://www.onevcat.com/2012/06/arc-hand-by-hand/ "手把手教你ARC——ARC入门和使用"))。

在Xcode4.4之后，之前区分到底谁拥有对象的工作可以模糊化了。在代码块区间加上CF_IMPLICIT_BRIDGING_ENABLED和CF_IMPLICIT_BRIDGING_DISABLED，在之前的桥接转换就都可以简单地写作CF和NS之间的强制转换，而不再需要加上__bridging的关键字了。谁来管这块内存呢？交给系统去头疼吧～

* * *

Objective-C确实是一门正在高速变化的语言。一方面，它的动态特性和small talk的烙印深深不去，另一方面，它又正积极朝着各种简单语言的语法方向靠近。各类的自动化处理虽然有些让人不放心，但是事实证明了它们工作良好，而且也确实为开发者节省了时间。尽快努力去拥抱新的变化吧～
