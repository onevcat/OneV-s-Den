---
layout: post
title: 宏定义的黑魔法 - 宏菜鸟起飞手册
date: 2014-01-17 01:03:36.000000000 +09:00
tags: 能工巧匠集
---

![Happy define :)](/assets/images/2014/define-title.png)

宏定义在C系开发中可以说占有举足轻重的作用。底层框架自不必说，为了编译优化和方便，以及跨平台能力，宏被大量使用，可以说底层开发离开define将寸步难行。而在更高层级进行开发时，我们会将更多的重心放在业务逻辑上，似乎对宏的使用和依赖并不多。但是使用宏定义的好处是不言自明的，在节省工作量的同时，代码可读性大大增加。如果想成为一个能写出漂亮优雅代码的开发者，宏定义绝对是必不可少的技能（虽然宏本身可能并不漂亮优雅XD）。但是因为宏定义对于很多人来说，并不像业务逻辑那样是每天会接触的东西。即使是能偶尔使用到一些宏，也更多的仅仅只停留在使用的层级，却并不会去探寻背后发生的事情。有一些开发者确实也有探寻的动力和意愿，但却在点开一个定义之后发现还有宏定义中还有其他无数定义，再加上满屏幕都是不同于平时的代码，既看不懂又不变色，于是乎心生烦恼，怒而回退。本文希望通过循序渐进的方式，通过几个例子来表述C系语言宏定义世界中的一些基本规则和技巧，从0开始，希望最后能让大家至少能看懂和还原一些相对复杂的宏。考虑到我自己现在objc使用的比较多，这个站点的读者应该也大多是使用objc的，所以有部分例子是选自objc，但是本文的大部分内容将是C系语言通用。

### 入门

如果您完全不知道宏是什么的话，可以先来热个身。很多人在介绍宏的时候会说，宏嘛很简单，就是简单的查找替换嘛。嗯，只说对了的一半。C中的宏分为两类，对象宏(object-like macro)和函数宏(function-like macro)。对于对象宏来说确实相对简单，但却也不是那么简单的查找替换。对象宏一般用来定义一些常数，举个例子：

```c
//This defines PI
#define M_PI        3.14159265358979323846264338327950288
```

<!--more-->

`#define`关键字表明即将开始定义一个宏，紧接着的`M_PI`是宏的名字，空格之后的数字是内容。类似这样的`#define X A`的宏是比较简单的，在编译时编译器会在语义分析认定是宏后，将X替换为A，这个过程称为宏的展开。比如对于上面的`M_PI`

```c
#define M_PI        3.14159265358979323846264338327950288

double r = 10.0;
double circlePerimeter = 2 * M_PI * r;
// => double circlePerimeter = 2 * 3.14159265358979323846264338327950288 * r;

printf("Pi is %0.7f",M_PI);
//Pi is 3.1415927
```

那么让我们开始看看另一类宏吧。函数宏顾名思义，就是行为类似函数，可以接受参数的宏。具体来说，在定义的时候，如果我们在宏名字后面跟上一对括号的话，这个宏就变成了函数宏。从最简单的例子开始，比如下面这个函数宏

```c
//A simple function-like macro
#define SELF(x)      x
NSString *name = @"Macro Rookie";
NSLog(@"Hello %@",SELF(name));
// => NSLog(@"Hello %@",name);
//   => Hello Macro Rookie
```

这个宏做的事情是，在编译时如果遇到`SELF`，并且后面带括号，并且括号中的参数个数与定义的相符，那么就将括号中的参数换到定义的内容里去，然后替换掉原来的内容。 具体到这段代码中，`SELF`接受了一个name，然后将整个SELF(name)用name替换掉。嗯..似乎很简单很没用，身经百战阅码无数的你一定会认为这个宏是写出来卖萌的。那么接受多个参数的宏肯定也不在话下了，例如这样的：

```c
#define PLUS(x,y) x + y
printf("%d",PLUS(3,2));
// => printf("%d",3 + 2);
//  => 5
```

相比对象宏来说，函数宏要复杂一些，但是看起来也相当简单吧？嗯，那么现在热身结束，让我们正式开启宏的大门吧。

### 宏的世界，小有乾坤

因为宏展开其实是编辑器的预处理，因此它可以在更高层级上控制程序源码本身和编译流程。而正是这个特点，赋予了宏很强大的功能和灵活度。但是凡事都有两面性，在获取灵活的背后，是以需要大量时间投入以对各种边界情况进行考虑来作为代价的。可能这么说并不是很能让人理解，但是大部分宏（特别是函数宏）背后都有一些自己的故事，挖掘这些故事和设计的思想会是一件很有意思的事情。另外，我一直相信在实践中学习才是真正掌握知识的唯一途径，虽然可能正在看这篇博文的您可能最初并不是打算亲自动手写一些宏，但是这我们不妨开始动手从实际的书写和犯错中进行学习和挖掘，因为只有肌肉记忆和大脑记忆协同起来，才能说达到掌握的水准。可以说，写宏和用宏的过程，一定是在在犯错中学习和深入思考的过程，我们接下来要做的，就是重现这一系列过程从而提高进步。

第一个题目是，让我们一起来实现一个`MIN`宏吧：实现一个函数宏，给定两个数字输入，将其替换为较小的那个数。比如`MIN(1,2)`出来的值是1。嗯哼，simple enough？定义宏，写好名字，两个输入，然后换成比较取值。比较取值嘛，任何一本入门级别的C程序设计上都会有讲啊，于是我们可以很快写出我们的第一个版本：

```c
//Version 1.0
#define MIN(A,B) A < B ? A : B
```

Try一下
```c
int a = MIN(1,2);
// => int a = 1 < 2 ? 1 : 2;
printf("%d",a);
// => 1
```

输出正确，打包发布！

![潇洒走一回](/assets/images/2014/shipit.png)

但是在实际使用中，我们很快就遇到了这样的情况
```c
int a = 2 * MIN(3, 4);
printf("%d",a);
// => 4
```

看起来似乎不可思议，但是我们将宏展开就知道发生什么了

```c
int a = 2 * MIN(3, 4);
// => int a = 2 * 3 < 4 ? 3 : 4;
// => int a = 6 < 4 ? 3 : 4;
// => int a = 4;
```

嘛，写程序这个东西，bug出来了，原因知道了，事后大家就都是诸葛亮了。因为小于和比较符号的优先级是较低的，所以乘法先被运算了，修正非常简单嘛，加括号就好了。

```c
//Version 2.0
#define MIN(A,B) (A < B ? A : B)
```
这次`2 * MIN(3, 4)`这样的式子就轻松愉快地拿下了。经过了这次修改，我们对自己的宏信心大增了...直到，某一天一个怒气冲冲的同事跑来摔键盘，然后给出了一个这样的例子：

```c
int a = MIN(3, 4 < 5 ? 4 : 5);
printf("%d",a);
// => 4
```

简单的相比较三个数字并找到最小的一个而已，要怪就怪你没有提供三个数字比大小的宏，可怜的同事只好自己实现4和5的比较。在你开始着手解决这个问题的时候，你首先想到的也许是既然都是求最小值，那写成`MIN(3, MIN(4, 5))`是不是也可以。于是你就随手这样一改，发现结果变成了3，正是你想要的..接下来，开始怀疑之前自己是不是看错结果了，改回原样，一个4赫然出现在屏幕上。你终于意识到事情并不是你想像中那样简单，于是还是回到最原始直接的手段，展开宏。

```c
int a = MIN(3, 4 < 5 ? 4 : 5);
// => int a = (3 < 4 < 5 ? 4 : 5 ? 3 : 4 < 5 ? 4 : 5);  //希望你还记得运算符优先级
//  => int a = ((3 < (4 < 5 ? 4 : 5) ? 3 : 4) < 5 ? 4 : 5);  //为了您不太纠结，我给这个式子加上了括号
//   => int a = ((3 < 4 ? 3 : 4) < 5 ? 4 : 5)
//    => int a = (3 < 5 ? 4 : 5)
//     => int a = 4
```

找到问题所在了，由于展开时连接符号和被展开式子中的运算符号优先级相同，导致了计算顺序发生了变化，实质上和我们的1.0版遇到的问题是差不多的，还是考虑不周。那么就再严格一点吧，3.0版！

```c
//Version 3.0
#define MIN(A,B) ((A) < (B) ? (A) : (B))
```

至于为什么2.0版本中的`MIN(3, MIN(4, 5))`没有出问题，可以正确使用，这里作为练习，大家可以试着自己展开一下，来看看发生了什么。

经过两次悲剧，你现在对这个简单的宏充满了疑惑。于是你跑了无数的测试用例而且它们都通过了，我们似乎彻底解决了括号问题，你也认为从此这个宏就妥妥儿的哦了。不过如果你真的这么想，那你就图样图森破了。生活总是残酷的，该来的bug也一定是会来的。不出意外地，在一个雾霾阴沉的下午，我们又收到了一个出问题的例子。

```c
float a = 1.0f;
float b = MIN(a++, 1.5f);
printf("a=%f, b=%f",a,b);
// => a=3.000000, b=2.000000
```

拿到这个出问题的例子你的第一反应可能和我一样，这TM的谁这么二货还在比较的时候搞++，这简直乱套了！但是这样的人就是会存在，这样的事就是会发生，你也不能说人家逻辑有错误。a是1，a++表示先使用a的值进行计算，然后再加1。那么其实这个式子想要计算的是取a和b的最小值，然后a等于a加1：所以正确的输出a为2，b为1才对！嘛，满眼都是泪，让我们这些久经摧残的程序员淡定地展开这个式子，来看看这次又发生了些什么吧：

```c
float a = 1.0f;
float b = MIN(a++, 1.5f);
// => float b = ((a++) < (1.5f) ? (a++) : (1.5f))
```

其实只要展开一步就很明白了，在比较a++和1.5f的时候，先取1和1.5比较，然后a自增1。接下来条件比较得到真以后又触发了一次a++，此时a已经是2，于是b得到2，最后a再次自增后值为3。出错的根源就在于我们预想的是a++只执行一次，但是由于宏展开导致了a++被多执行了，改变了预想的逻辑。解决这个问题并不是一件很简单的事情，使用的方式也很巧妙。我们需要用到一个GNU C的赋值扩展，即使用`({...})`的形式。这种形式的语句可以类似很多脚本语言，在顺次执行之后，会将最后一次的表达式的赋值作为返回。举个简单的例子，下面的代码执行完毕后a的值为3，而且b和c只存在于大括号限定的代码域中

```c
int a = ({
    int b = 1;
    int c = 2;
    b + c;
});
// => a is 3
```

有了这个扩展，我们就能做到之前很多做不到的事情了。比如彻底解决`MIN`宏定义的问题，而也正是GNU C中`MIN`的标准写法

```c
//GNUC MIN
#define MIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
```

这里定义了三个语句，分别以输入的类型申明了`__a`和`__b`，并使用输入为其赋值，接下来做一个简单的条件比较，得到`__a`和`__b`中的较小值，并使用赋值扩展将结果作为返回。这样的实现保证了不改变原来的逻辑，先进行一次赋值，也避免了括号优先级的问题，可以说是一个比较好的解决方案了。如果编译环境支持GNU C的这个扩展，那么毫无疑问我们应该采用这种方式来书写我们的`MIN`宏，如果不支持这个环境扩展，那我们只有人为地规定参数不带运算或者函数调用，以避免出错。

关于`MIN`我们讨论已经够多了，但是其实还存留一个悬疑的地方。如果在同一个scope内已经有`__a`或者`__b`的定义的话（虽然一般来说不会出现这种悲剧的命名，不过谁知道呢），这个宏可能出现问题。在申明后赋值将因为定义重复而无法被初始化，导致宏的行为不可预知。如果您有兴趣，不妨自己动手试试看结果会是什么。Apple在Clang中彻底解决了这个问题，我们把Xcode打开随便建一个新工程，在代码中输入`MIN(1,1)`，然后Cmd+点击即可找到clang中 `MIN`的写法。为了方便说明，我直接把相关的部分抄录如下：

```objc
//CLANG MIN
#define __NSX_PASTE__(A,B) A##B

#define MIN(A,B) __NSMIN_IMPL__(A,B,__COUNTER__)

#define __NSMIN_IMPL__(A,B,L) ({ __typeof__(A) __NSX_PASTE__(__a,L) = (A); __typeof__(B) __NSX_PASTE__(__b,L) = (B); (__NSX_PASTE__(__a,L) < __NSX_PASTE__(__b,L)) ? __NSX_PASTE__(__a,L) : __NSX_PASTE__(__b,L); })
```

似乎有点长，看起来也很吃力。我们先美化一下这宏，首先是最后那个`__NSMIN_IMPL__`内容实在是太长了。我们知道代码的话是可以插入换行而不影响含义的，宏是否也可以呢？答案是肯定的，只不过我们不能使用一个单一的回车来完成，而必须在回车前加上一个反斜杠`\`。改写一下，为其加上换行好看些：

```objc
#define __NSX_PASTE__(A,B) A##B

#define MIN(A,B) __NSMIN_IMPL__(A,B,__COUNTER__)

#define __NSMIN_IMPL__(A,B,L) ({ __typeof__(A) __NSX_PASTE__(__a,L) = (A); \
                                 __typeof__(B) __NSX_PASTE__(__b,L) = (B); \
                                 (__NSX_PASTE__(__a,L) < __NSX_PASTE__(__b,L)) ? __NSX_PASTE__(__a,L) : __NSX_PASTE__(__b,L); \
                              })
```

但可以看出`MIN`一共由三个宏定义组合而成。第一个`__NSX_PASTE__`里出现的两个连着的井号`##`在宏中是一个特殊符号，它表示将两个参数连接起来这种运算。注意函数宏必须是有意义的运算，因此你不能直接写`AB`来连接两个参数，而需要写成例子中的`A##B`。宏中还有一切其他的自成一脉的运算符号，我们稍后还会介绍几个。接下来是我们调用的两个参数的`MIN`，它做的事是调用了另一个三个参数的宏`__NSMIN_IMPL__`，其中前两个参数就是我们的输入，而第三个`__COUNTER__`我们似乎不认识，也不知道其从何而来。其实`__COUNTER__`是一个预定义的宏，这个值在编译过程中将从0开始计数，每次被调用时加1。因为唯一性，所以很多时候被用来构造独立的变量名称。有了上面的基础，再来看最后的实现宏就很简单了。整体思路和前面的实现和之前的GNUC MIN是一样的，区别在于为变量名`__a`和`__b`添加了一个计数后缀，这样大大避免了变量名相同而导致问题的可能性（当然如果你执拗地把变量叫做__a9527并且出问题了的话，就只能说不作死就不会死了）。

花了好多功夫，我们终于把一个简单的`MIN`宏彻底搞清楚了。宏就是这样一类东西，简单的表面之下隐藏了很多玄机，可谓小有乾坤。作为练习大家可以自己尝试一下实现一个`SQUARE(A)`，给一个数字输入，输出它的平方的宏。虽然一般这个计算现在都是用inline来做了，但是通过和`MIN`类似的思路我们是可以很好地实现它的，动手试一试吧 :)

### Log，永恒的主题

Log人人爱，它为我们指明前进方向，它为我们抓虫提供帮助。在objc中，我们最多使用的log方法就是`NSLog`输出信息到控制台了，但是NSLog的标准输出可谓残废，有用信息完全不够，比如下面这段代码：

```objc
NSArray *array = @[@"Hello", @"My", @"Macro"];
NSLog (@"The array is %@", array);
```

打印到控制台里的结果是类似这样的

```
2014-01-20 11:22:11.835 TestProject[23061:70b] The array is (
    Hello,
    My,
    Macro
)
```

我们在输出的时候关心什么？除了结果以外，很多情况下我们会对这行log的所在的文件位置方法什么的会比较关心。在每次NSLog里都手动加上方法名字和位置信息什么的无疑是个笨办法，而如果一个工程里已经有很多`NSLog`的调用了，一个一个手动去改的话无疑也是噩梦。我们通过宏，可以很简单地完成对`NSLog`原生行为的改进，优雅，高效。只需要在预编译的pch文件中加上

```objc
//A better version of NSLog
#define NSLog(format, ...) do {                                                                          \
                             fprintf(stderr, "<%s : %d> %s\n",                                           \
                             [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
                             __LINE__, __func__);                                                        \
                             (NSLog)((format), ##__VA_ARGS__);                                           \
                             fprintf(stderr, "-------\n");                                               \
                           } while (0)
```

嘛，这是我们到现在为止见到的最长的一个宏了吧...没关系，一点一点来分析就好。首先是定义部分，第2行的`NSLog(format, ...)`。我们看到的是一个函数宏，但是它的参数比较奇怪，第二个参数是`...`，在宏定义（其实也包括函数定义）的时候，写为`...`的参数被叫做可变参数(variadic)。可变参数的个数不做限定。在这个宏定义中，除了第一个参数`format`将被单独处理外，接下来输入的参数将作为整体一并看待。回想一下NSLog的用法，我们在使用NSLog时，往往是先给一个format字符串作为第一个参数，然后根据定义的格式在后面的参数里跟上写要输出的变量之类的。这里第一个格式化字符串即对应宏里的`format`，后面的变量全部映射为`...`作为整体处理。

接下来宏的内容部分。上来就是一个下马威，我们遇到了一个do while语句...想想看你上次使用do while是什么时候吧？也许是C程序设计课的大作业？或者是某次早已被遗忘的算法面试上？总之虽然大家都是明白这个语句的，但是实际中可能用到它的机会少之又少。乍一看似乎这个do while什么都没做，因为while是0，所以do肯定只会被执行一次。那么它存在的意义是什么呢，我们是不是可以直接简化一下这个宏，把它给去掉，变成这个样子呢？

```objc
//A wrong version of NSLog
#define NSLog(format, ...)   fprintf(stderr, "<%s : %d> %s\n",                                           \
                             [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
                             __LINE__, __func__);                                                        \
                             (NSLog)((format), ##__VA_ARGS__);                                           \
                             fprintf(stderr, "-------\n");                                               
```

答案当然是否定的，也许简单的测试里你没有遇到问题，但是在生产环境中这个宏显然悲剧了。考虑下面的常见情况

```objc
if (errorHappend)
    NSLog(@"Oops, error happened");
```

展开以后将会变成
```objc
if (errorHappend)
    fprintf((stderr, "<%s : %d> %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
(NSLog)((format), ##__VA_ARGS__); //I will expand this later
fprintf(stderr, "-------\n");
```
注意..C系语言可不是靠缩进来控制代码块和逻辑关系的。所以说如果使用这个宏的人没有在条件判断后加大括号的话，你的宏就会一直调用真正的NSLog输出东西，这显然不是我们想要的逻辑。当然在这里还是需要重新批评一下认为if后的单条执行语句不加大括号也没问题的同学，这是陋习，无需理由，请改正。不论是不是一条语句，也不论是if后还是else后，都加上大括号，是对别人和自己的一种尊重。

好了知道我们的宏是如何失效的，也就知道了修改的方法。作为宏的开发者，应该力求使用者在最大限度的情况下也不会出错，于是我们想到直接用一对大括号把宏内容括起来，大概就万事大吉了？像这样：

```objc
//Another wrong version of NSLog
#define NSLog(format, ...)   {
                               fprintf(stderr, "<%s : %d> %s\n",                                           \
                               [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],  \
                               __LINE__, __func__);                                                        \
                               (NSLog)((format), ##__VA_ARGS__);                                           \
                               fprintf(stderr, "-------\n");                                               \
                             }
```

展开刚才的那个式子，结果是
```objc
//I am sorry if you don't like { in the same like. But I am a fan of this style :P
if (errorHappend) {
    fprintf((stderr, "<%s : %d> %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
    (NSLog)((format), ##__VA_ARGS__);
    fprintf(stderr, "-------\n");
};
```

编译，执行，正确！因为用大括号标识代码块是不会嫌多的，所以这样一来的话我们的宏在不论if后面有没有大括号的情况下都能工作了！这么看来，前面例子中的do while果然是多余的？于是我们又可以愉快地发布了？如果你够细心的话，可能已经发现问题了，那就是上面最后的一个分号。虽然编译运行测试没什么问题，但是始终稍微有些刺眼有木有？没错，因为我们在写NSLog本身的时候，是将其当作一条语句来处理的，后面跟了一个分号，在宏展开后，这个分号就如同噩梦一般的多出来了。什么，你还没看出哪儿有问题？试试看展开这个例子吧：

```objc
if (errorHappend)
    NSLog(@"Oops, error happened");
else
	//Yep, no error, I am happy~ :)
```

No! I am not haapy at all! 因为编译错误了！实际上这个宏展开以后变成了这个样子：

```objc
if (errorHappend) {
    fprintf((stderr, "<%s : %d> %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
    (NSLog)((format), ##__VA_ARGS__);
    fprintf(stderr, "-------\n");
}; else {
    //Yep, no error, I am happy~ :)
}
```

因为else前面多了一个分号，导致了编译错误，很恼火..要是写代码的人乖乖写大括号不就啥事儿没有了么？但是我们还是有巧妙的解决方法的，那就是上面的do while。把宏的代码块添加到do中，然后之后while(0)，在行为上没有任何改变，但是可以巧妙地吃掉那个悲剧的分号，使用do while的版本展开以后是这个样子的

```objc
if (errorHappend) 
	do {
        fprintf((stderr, "<%s : %d> %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
        (NSLog)((format), ##__VA_ARGS__);
        fprintf(stderr, "-------\n");
    } while (0);
else {
    //Yep, no error, I am really happy~ :)
}
```

这个吃掉分号的方法被大量运用在代码块宏中，几乎已经成为了标准写法。而且while(0)的好处在于，在编译的时候，编译器基本都会为你做好优化，把这部分内容去掉，最终编译的结果不会因为这个do while而导致运行效率上的差异。在终于弄明白了这个奇怪的do while之后，我们终于可以继续深入到这个宏里面了。宏本体内容的第一行没有什么值得多说的`fprintf(stderr, "<%s : %d> %s\n",`，简单的格式化输出而已。注意我们使用了`\`将这个宏分成了好几行来写，实际在最后展开时会被合并到同一行内，我们在刚才`MIN`最后也用到了反斜杠，希望你还能记得。接下来一行我们填写这个格式输出中的三个token，

```
[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
```

这里用到了三个预定义宏，和刚才的`__COUNTER__`类似，预定义宏的行为是由编译器指定的。`__FILE__`返回当前文件的绝对路径，`__LINE__`返回展开该宏时在文件中的行数，`__func__`是改宏所在scope的函数名称。我们在做Log输出时如果带上这这三个参数，便可以加快解读Log，迅速定位。关于编译器预定义的Log以及它们的一些实现机制，感兴趣的同学可以移步到gcc文档的[PreDefine页面](http://gcc.gnu.org/onlinedocs/cpp/Predefined-Macros.html#Predefined-Macros)和clang的[Builtin Macro](http://clang.llvm.org/docs/LanguageExtensions.html#builtin-macros)进行查看。在这里我们将格式化输出的三个参数分别设定为文件名的最后一个部分（因为绝对路径太长很难看），行数，以及方法名称。

接下来是还原原始的NSLog，`(NSLog)((format), ##__VA_ARGS__);`中出现了另一个预定义的宏`__VA_ARGS__`（我们似乎已经找出规律了，前后双下杠的一般都是预定义）。`__VA_ARGS__`表示的是宏定义中的`...`中的所有剩余参数。我们之前说过可变参数将被统一处理，在这里展开的时候编译器会将`__VA_ARGS__`直接替换为输入中从第二个参数开始的剩余参数。另外一个悬疑点是在它前面出现了两个井号`##`。还记得我们上面在`MIN`中的两个井号么，在那里两个井号的意思是将前后两项合并，在这里做的事情比较类似，将前面的格式化字符串和后面的参数列表合并，这样我们就得到了一个完整的NSLog方法了。之后的几行相信大家自己看懂也没有问题了，最后输出一下试试看，大概看起来会是这样的。

```
-------
<AppDelegate.m : 46> -[AppDelegate application:didFinishLaunchingWithOptions:]
2014-01-20 16:44:25.480 TestProject[30466:70b] The array is (
    Hello,
    My,
    Macro
)
-------
```

带有文件，行号和方法的输出，并且用横杠隔开了（请原谅我没有质感的设计，也许我应该画一只牛，比如这样？），debug的时候也许会轻松一些吧 :)

![hello cowsay](/assets/images/2014/cowsay-lolcat.png)

这个Log有三个悬念点，首先是为什么我们要把format单独写出来，然后吧其他参数作为可变参数传递呢？如果我们不要那个format，而直接写成`NSLog(...)`会不会有问题？对于我们这里这个例子来说的话是没有变化的，但是我们需要记住的是`...`是可变参数列表，它可以代表一个、两个，或者是很多个参数，但同时它也能代表零个参数。如果我们在申明这个宏的时候没有指定format参数，而直接使用参数列表，那么在使用中不写参数的NSLog()也将被匹配到这个宏中，导致编译无法通过。如果你手边有Xcode，也可以看看Cocoa中真正的NSLog方法的实现，可以看到它也是接收一个格式参数和一个参数列表的形式，我们在宏里这么定义，正是为了其传入正确合适的参数，从而保证使用者可以按照原来的方式正确使用这个宏。

第二点是既然我们的可变参数可以接受任意个输入，那么在只有一个format输入，而可变参数个数为零的时候会发生什么呢？不妨展开看一看，记住`##`的作用是拼接前后，而现在`##`之后的可变参数是空：

```
NSLog(@"Hello");
=> do {
       fprintf((stderr, "<%s : %d> %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__);
       (NSLog)((@"Hello"), );
       fprintf(stderr, "-------\n");
   } while (0);

```

中间的一行`(NSLog)(@"Hello", );`似乎是存在问题的，你一定会有疑惑，这种方式怎么可能编译通过呢？！原来大神们其实早已想到这个问题，并且进行了一点特殊的处理。这里有个特殊的规则，在`逗号`和`__VA_ARGS__`之间的双井号，除了拼接前后文本之外，还有一个功能，那就是如果后方文本为空，那么它会将前面一个逗号吃掉。这个特性当且仅当上面说的条件成立时才会生效，因此可以说是特例。加上这条规则后，我们就可以将刚才的式子展开为正确的`(NSLog)((@"Hello"));`了。

最后一个值得讨论的地方是`(NSLog)((format), ##__VA_ARGS__);`的括号使用。把看起来能去掉的括号去掉，写成`NSLog(format, ##__VA_ARGS__);`是否可以呢？在这里的话应该是没有什么大问题的，首先format不会被调用多次也不太存在误用的可能性（因为最后编译器会检查NSLog的输入是否正确）。另外你也不用担心展开以后式子里的NSLog会再次被自己展开，虽然展开式中NSLog也满足了我们的宏定义，但是宏的展开非常聪明，展开后会自身无限循环的情况，就不会再次被展开了。

作为一个您读到了这里的小奖励，附送三个debug输出rect，size和point的宏，希望您能用上（嗯..想想曾经有多少次你需要打印这些结构体的某个数字而被折磨致死，让它们玩儿蛋去吧！当然请先加油看懂它们吧）

```
#define NSLogRect(rect) NSLog(@"%s x:%.4f, y:%.4f, w:%.4f, h:%.4f", #rect, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
#define NSLogSize(size) NSLog(@"%s w:%.4f, h:%.4f", #size, size.width, size.height)
#define NSLogPoint(point) NSLog(@"%s x:%.4f, y:%.4f", #point, point.x, point.y)
```

### 两个实际应用的例子

当然不是说上面介绍的宏实际中不能用。它们相对简单，但是里面坑不少，所以显得很有特点，非常适合作为入门用。而实际上在日常中很多我们常用的宏并没有那么多奇怪的问题，很多时候我们按照想法去实现，再稍微注意一下上述介绍的可能存在的共通问题，一个高质量的宏就可以诞生。如果能写出一些有意义价值的宏，小了从对你的代码的使用者来说，大了从整个社区整个世界和减少碳排放来说，你都做出了相当的贡献。我们通过几个实际的例子来看看，宏是如何改变我们的生活，和写代码的习惯的吧。

先来看看这两个宏

```objc
#define XCTAssertTrue(expression, format...) \
    _XCTPrimitiveAssertTrue(expression, ## format)

#define _XCTPrimitiveAssertTrue(expression, format...) \
({ \
    @try { \
        BOOL _evaluatedExpression = !!(expression); \
        if (!_evaluatedExpression) { \
            _XCTRegisterFailure(_XCTFailureDescription(_XCTAssertion_True, 0, @#expression),format); \
        } \
    } \
    @catch (id exception) { \
        _XCTRegisterFailure(_XCTFailureDescription(_XCTAssertion_True, 1, @#expression, [exception reason]),format); \
    }\
})
```

如果您常年做苹果开发，却没有见过或者完全不知道`XCTAssertTrue`是什么的话，强烈建议补习一下测试驱动开发的相关知识，我想应该会对您之后的道路很有帮助。如果你已经很熟悉这个命令了，那我们一起开始来看看幕后发生了什么。

有了上面的基础，相信您大体上应该可以自行解读这个宏了。`({...})`的语法和`##`都很熟悉了，这里有三个值得注意的地方，在这个宏的一开始，我们后面的的参数是`format...`，这其实也是可变参数的一种写法，和`...`与`__VA_ARGS__`配对类似，`{NAME}...`将于`{NAME}`配对使用。也就是说，在这里宏内容的`format`指代的其实就是定义的先对`expression`取了两次反？我不是科班出身，但是我还能依稀记得这在大学程序课上讲过，两次取反的操作可以确保结果是BOOL值，这在objc中还是比较重要的（关于objc中BOOL的讨论已经有很多，如果您还没能分清BOOL, bool和Boolean，可以参看[NSHisper的这篇文章](http://nshipster.com/bool/)）。然后就是`@#expression`这个式子。我们接触过双井号`##`，而这里我们看到的操作符是单井号`#`，注意井号前面的`@`是objc的编译符号，不属于宏操作的对象。单个井号的作用是字符串化，简单来说就是将替换后在两头加上""，转为一个C字符串。这里使用@然后紧跟#expression，出来后就是一个内容是expression的内容的NSString。然后这个NSString再作为参数传递给`_XCTRegisterFailure`和`_XCTFailureDescription`等，继续进行展开，这些是后话。简单一瞥，我们大概就可以想象宏帮助我们省了多少事儿了，如果各位看官要是写个断言还要来个十多行的话，想象都会疯掉的吧。

另外一个例子，找了人民群众喜闻乐见的[ReactiveCocoa(RAC)](https://github.com/ReactiveCocoa/ReactiveCocoa)中的一个宏定义。对于RAC不熟悉或者没听过的朋友，可以简单地看看[Limboy的一系列相关博文](http://blog.leezhong.com)（搜索ReactiveCocoa），介绍的很棒。如果觉得“哇哦这个好酷我很想学”的话，不妨可以跟随raywenderlich上这个[系列的教程](http://www.raywenderlich.com/55384/ios-7-best-practices-part-1)做一些实践，里面简单地用到了RAC，但是都已经包含了RAC的基本用法了。RAC中有几个很重要的宏，它们是保证RAC简洁好用的基本，可以说要是没有这几个宏的话，是不会有人喜欢RAC的。其中`RACObserve`就是其中一个，它通过KVC来为对象的某个属性创建一个信号返回（如果你看不懂这句话，不要担心，这对你理解这个宏的写法和展开没有任何影响）。对于这个宏，我决定不再像上面那样展开和讲解，我会在最后把相关的宏都贴出来，大家不妨拿它练练手，看看能不能将其展开到代码的状态，并且明白其中都发生了些什么。如果你遇到什么问题或者在展开过程中有所心得，欢迎在评论里留言分享和交流 :)

好了，这篇文章已经够长了。希望在看过以后您在看到宏的时候不再发怵，而是可以很开心地说这个我会这个我会这个我也会。最终目标当然是写出漂亮高效简洁的宏，这不论对于提高生产力还是~~~震慑你的同事~~~提升自己实力都会很有帮助。

另外，在这里一定要宣传一下关注了很久的[@hangcom](http://weibo.com/hangcom) 吴航前辈的新书《iOS应用逆向工程》。很荣幸能够在发布之前得到前辈的允许拜读了整本书，可以说看的畅快淋漓。我之前并没有越狱开发的任何基础，也对相关领域知之甚少，在这样的前提下跟随书中的教程和例子进行探索的过程可以说是十分有趣。我也得以能够用不同的眼光和高度来审视这几年所从事的iOS开发行业，获益良多。可以说《iOS应用逆向工程》是我近期所愉快阅读到的很cool的一本好书。现在这本书还在预售中，但是距离1月28日的正式发售已经很近，有兴趣的同学可以前往[亚马逊](http://www.amazon.cn/gp/product/B00HQW9AA6/ref=s9_simh_gw_p14_d0_i6?pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=center-2&pf_rd_r=1KY5VBPQDKMCCWC07ANV&pf_rd_t=101&pf_rd_p=108773272&pf_rd_i=899254051)或者[ChinaPub](http://product.china-pub.com/3769262)的相关页面预定，相信这本书将会是iOS技术人员非常棒的春节读物。

最后是我们说好的留给大家玩的练习，我加了一点注释帮助大家稍微理解每个宏是做什么的，在文章后面留了一块试验田，大家可以随便填写玩弄。总之，加油！

```
//调用 RACSignal是类的名字
RACSignal *signal = RACObserve(self, currentLocation);

//以下开始是宏定义
//rac_valuesForKeyPath:observer:是方法名
#define RACObserve(TARGET, KEYPATH) \
    [(id)(TARGET) rac_valuesForKeyPath:@keypath(TARGET, KEYPATH) observer:self]
    
#define keypath(...) \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__))(keypath1(__VA_ARGS__))(keypath2(__VA_ARGS__))

//这个宏在取得keypath的同时在编译期间判断keypath是否存在，避免误写
//您可以先不用介意这里面的巫术..
#define keypath1(PATH) \
    (((void)(NO && ((void)PATH, NO)), strchr(# PATH, '.') + 1))

#define keypath2(OBJ, PATH) \
    (((void)(NO && ((void)OBJ.PATH, NO)), # PATH))

//A和B是否相等，若相等则展开为后面的第一项，否则展开为后面的第二项
//eg. metamacro_if_eq(0, 0)(true)(false) => true
//    metamacro_if_eq(0, 1)(true)(false) => false
#define metamacro_if_eq(A, B) \
        metamacro_concat(metamacro_if_eq, A)(B)

#define metamacro_if_eq1(VALUE) metamacro_if_eq0(metamacro_dec(VALUE))

#define metamacro_if_eq0(VALUE) \
    metamacro_concat(metamacro_if_eq0_, VALUE)

#define metamacro_if_eq0_1(...) metamacro_expand_

#define metamacro_expand_(...) __VA_ARGS__

#define metamacro_argcount(...) \
        metamacro_at(20, __VA_ARGS__, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)

#define metamacro_at(N, ...) \
        metamacro_concat(metamacro_at, N)(__VA_ARGS__)
        
#define metamacro_concat(A, B) \
        metamacro_concat_(A, B)

#define metamacro_concat_(A, B) A ## B

#define metamacro_at2(_0, _1, ...) metamacro_head(__VA_ARGS__)

#define metamacro_at20(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, ...) metamacro_head(__VA_ARGS__)

#define metamacro_head(...) \
        metamacro_head_(__VA_ARGS__, 0)

#define metamacro_head_(FIRST, ...) FIRST

#define metamacro_dec(VAL) \
        metamacro_at(VAL, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
```

<div id="editor">//调用 RACSignal是类的名字
RACSignal *signal = RACObserve(self, currentLocation);</div>
    
<script src="/javascripts/src-min/ace.js" type="text/javascript" charset="utf-8"></script>
<script>
    var editor = ace.edit("editor");
    editor.setTheme("ace/theme/github");
    editor.getSession().setMode("ace/mode/objectivec");
</script>
