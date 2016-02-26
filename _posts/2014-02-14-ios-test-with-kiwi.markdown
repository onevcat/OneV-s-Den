---
layout: post
title: TDD的iOS开发初步以及Kiwi使用入门
date: 2014-02-14 01:06:19.000000000 +09:00
tags: 能工巧匠集
---

![Kiwi](/assets/images/2014/kiwi-title.jpg)

测试驱动开发(Test Driven Development，以下简称TDD)是保证代码质量的不二法则，也是先进程序开发的共识。Apple一直致力于在iOS开发中集成更加方便和可用的测试，在Xcode 5中，新的IDE和SDK引入了XCTest来替代原来的SenTestingKit，并且取消了新建工程时的“包括单元测试”的可选项（同样待遇的还有使用ARC的可选项）。新工程将自动包含测试的target，并且相关框架也搭建完毕，可以说测试终于摆脱了iOS开发中“二等公民”的地位，现在已经变得和产品代码一样重要了。我相信每个工程师在完成自己的业务代码的同时，也有最基本的编写和维护相应的测试代码的义务，以保证自己的代码能够正确运行。更进一步，如果能够使用TDD来进行开发，不仅能保证代码运行的正确性，也有助于代码结构的安排和思考，有助于自身的不断提高。我在最开始进行开发时也曾对测试嗤之以鼻，但后来无数的惨痛教训让我明白那么多工程师痴迷于测试或者追求更完美的测试，是有其深刻含义的。如果您之前还没有开始为您的代码编写测试，我强烈建议，从今天开始，从现在开始（也许做不到的话，也请从下一个项目开始），编写测试，或者尝试一下TDD的开发方式。

而[Kiwi](https://github.com/allending/Kiwi)是一个iOS平台十分好用的行为驱动开发(Behavior Driven Development，以下简称BDD)的测试框架，有着非常漂亮的语法，可以写出结构性强，非常容易读懂的测试。因为国内现在有关Kiwi的介绍比较少，加上在测试这块很能很多工程师们并没有特别留意，水平层次可能相差会很远，因此在这一系列的两篇博文中，我将从头开始先简单地介绍一些TDD的概念和思想，然后从XCTest的最简单的例子开始，过渡到Kiwi的测试世界。在下一篇中我将继续深入介绍一些Kiwi的其他稍高一些的特性，以期更多的开发者能够接触并使用Kiwi这个优秀的测试框架。

### 什么是TDD，为什么我们要TDD

测试驱动开发并不是一个很新鲜的概念了。软件开发工程师们（当然包括你我）最开始学习程序编写时，最喜欢干的事情就是编写一段代码，然后运行观察结果是否正确。如果不对就返回代码检查错误，或者是加入断点或者输出跟踪程序并找出错误，然后再次运行查看输出是否与预想一致。如果输出只是控制台的一个简单的数字或者字符那还好，但是如果输出必须在点击一系列按钮之后才能在屏幕上显示出来的东西呢？难道我们就只能一次一次地等待编译部署，启动程序然后操作UI，一直点到我们需要观察的地方么？这种行为无疑是对美好生命和绚丽青春的巨大浪费。于是有一些已经浪费了无数时间的资深工程师们突然发现，原来我们可以在代码中构建出一个类似的场景，然后在代码中调用我们之前想检查的代码，并将运行的结果与我们的设想结果在程序中进行比较，如果一致，则说明了我们的代码没有问题，是按照预期工作的。比如我们想要实现一个加法函数add，输入两个数字，输出它们相加后的结果。那么我们不妨设想我们真的拥有两个数，比如3和5，根据人人会的十以内的加法知识，我们知道答案是8.于是我们在相加后与预测的8进行比较，如果相等，则说明我们的函数实现至少对于这个例子是没有问题的，因此我们对“这个方法能正确工作”这一命题的信心就增加了。这个例子的伪码如下：

```c
//Product Code
add(float num1, float num 2) {...}

//Test code
let a = 3;
let b = 5;
let c = a + b;

if (c == 8) {
    // Yeah, it works!
} else {
    //Something wrong!
}

```

当测试足够全面和具有代表性的时候，我们便可以信心爆棚，拍着胸脯说，这段代码没问题。我们做出某些条件和假设，并以其为条件使用到被测试代码中，并比较预期的结果和实际运行的结果是否相等，这就是软件开发中测试的基本方式。

![为什么我们要test](/assets/images/2014/kiwi-manga.png)

而TDD是一种相对于普通思维的方式来说，比较极端的一种做法。我们一般能想到的是先编写业务代码，也就是上面例子中的`add`方法，然后为其编写测试代码，用来验证产品方法是不是按照设计工作。而TDD的思想正好与之相反，在TDD的世界中，我们应该首先根据需求或者接口情况编写测试，然后再根据测试来编写业务代码，而这其实是违反传统软件开发中的先验认知的。但是我们可以举一个生活中类似的例子来说明TDD的必要性：有经验的砌砖师傅总是会先拉一条垂线，然后沿着线砌砖，因为有直线的保证，因此可以做到笔直整齐；而新入行的师傅往往二话不说直接开工，然后在一阶段完成后再用直尺垂线之类的工具进行测量和修补。TDD的好处不言自明，因为总是先测试，再编码，所以至少你的所有代码的public部分都应该含有必要的测试。另外，因为测试代码实际是要使用产品代码的，因此在编写产品代码前你将有一次深入思考和实践如何使用这些代码的机会，这对提高设计和可扩展性有很好的帮助，试想一下你测试都很难写的接口，别人（或者自己）用起来得多纠结。在测试的准绳下，你可以有目的有方向地编码；另外，因为有测试的保护，你可以放心对原有代码进行重构，而不必担心破坏逻辑。这些其实都指向了一个最终的目的：让我们快乐安心高效地工作。

在TDD原则的指导下，我们先编写测试代码。这时因为还没有对应的产品代码，所以测试代码肯定是无法通过的。在大多数测试系统中，我们使用红色来表示错误，因此一个测试的初始状态应该是红色的。接下来我们需要使用最小的代价（最少的代码）来让测试通过。通过的测试将被表示为安全的绿色，于是我们回到了绿色的状态。接下来我们可以添加一些测试例，来验证我们的产品代码的实现是否正确。如果不幸新的测试例让我们回到了红色状态，那我们就可以修改产品代码，使其回到绿色。如此反复直到各种边界和测试都进行完毕，此时我们便可以得到一个具有测试保证，鲁棒性超强的产品代码。在我们之后的开发中，因为你有这些测试的保证，你可以大胆重构这段代码或者与之相关的代码，最后只需要保证项目处于绿灯状态，你就可以保证代码没重构没有出现问题。

简单说来，TDD的基本步骤就是“红→绿→大胆重构”。

### 使用XCTest来执行TDD

Xcode 5中已经集成了XCTest的测试框架（之前版本是SenTestingKit和OCUnit），所谓测试框架，就是一组让“将测试集成到工程中”以及“编写和实践测试”变得简单的库。我们之后将通过实现一个栈数据结构的例子，来用XCTest初步实践一下TDD开发。在大家对TDD有一些直观认识之后，再转到Kiwi的介绍。如果您已经在使用XCTest或者其他的测试框架了的话，可以直接跳过本节。

首先我们用Xcode新建一个工程吧，选择模板为空项目，在`Product Name`中输入工程名字VVStack，当然您可以使用自己喜欢的名字。如果您使用过Xcode之前的版本的话，应该有留意到之前在这个界面是可以选择是否使用Unit Test的，但是现在这个选框已经被取消。

![新建工程](/assets/images/2014/kiwi-1-1.png)

新建工程后，可以发现在工程中默认已经有一个叫做`VVStackTests`的target了，这就是我们测试时使用的target。测试部分的代码默认放到了{ProjectName}Tests的group中，现在这个group下有一个测试文件VVStackTests.m。我们的测试例不需要向别的类暴露接口，因此不需要.h文件。另外一般XCTest的测试文件都会以Tests来做文件名结尾。

![Test文件和target](/assets/images/2014/kiwi-1-2.png)

运行测试的快捷键是`⌘U`（或者可以使用菜单的Product→Test），我们这时候直接对这个空工程进行测试，Xcode在编译项目后会使用你选择的设备或者模拟器运行测试代码。不出意外的话，这次测试将会失败，如图：

![失败的初始测试](/assets/images/2014/kiwi-1-3.png)

`VVStackTests.m`是Xcode在新建工程时自动为我们添加的测试文件。因为这个文件并不长，所以我们可以将其内容全部抄录如下：

```objc
#import <XCTest/XCTest.h>

@interface VVStackTests : XCTestCase

@end

@implementation VVStackTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
```

可以看到，`VVStackTests`是`XCTestCase`的子类，而`XCTestCase`正是XCTest测试框架中的测试用例类。XCTest在进行测试时将会寻找测试target中的所有`XCTestCase`子类，并运行其中以`test`开头的所有实例方法。在这里，默认实现的`-testExample`将被执行，而在这个方法里，Xcode默认写了一个`XCTFail`的断言，来强制这个测试失败，用以提醒我们测试还没有实现。所谓断言，就是判断输入的条件是否满足。如果不满足，则抛出错误并输出预先规定的字符串作为提示。在这个Fail的断言一定会失败，并提示没有实现该测试。另外，默认还有两个方法`-setUp`和`-tearDown`，正如它们的注释里所述，这两个方法会分别在每个测试开始和结束的时候被调用。我们现在正要开始编写我们的测试，所以先将原来的`-testExample`删除掉。现在再使用`⌘U`来进行测试，应该可以顺利通过了（因为我们已经没有任何测试了）。

接下来让我们想想要做什么吧。我们要实现一个简单的栈数据结构，那么当然会有一个类来代表这种数据结构，在这个工程中我打算就叫它`VVStack`。按照常规，我们可以新建一个Cocoa Touch类，继承NSObject并且开始实现了。但是别忘了，我们现在在TDD，我们需要先写测试！那么首先测试的目标是什么呢？没错，是测试这个`VVStack`类是否存在，以及是否能够初始化。有了这个目标，我们就可以动手开始编写测试了。在文件开头加上`#import "VVStack.h"`，然后在`VVStackTests.m`的`@end`前面加上如下代码：

```objc
- (void)testStackExist {
    XCTAssertNotNil([VVStack class], @"VVStack class should exist.");
}

- (void)testStackObjectCanBeCreated {
    VVStack *stack = [VVStack new];
    XCTAssertNotNil(stack, @"VVStack object can be created.");
}
```

嘛，当然是不可能通过测试的，而且甚至连编译都无法完成，因为我们现在根本没有一个叫做`VVStack`的类。最简单的让测试通过的方法就是在产品代码中添加`VVStack`类。新建一个Cocoa Touch的Objective-C class，取名VVStack，作为NSObject的子类。注意在添加的时候，应该只将其加入产品的target中：

![添加类的时候注意选择合适的target](/assets/images/2014/kiwi-1-4.png)

由于`VVStack`是NSObject的子类，所以上面的两个断言应该都能通过。这时候再运行测试，成功变绿。接下来我们开始考虑这个类的功能：栈的话肯定需要能够push，并且push后的栈顶元素应该就是刚才所push进去的元素。那么建立一个push方法的测试吧，在刚才添加的代码之下继续写：

```objc
- (void)testPushANumberAndGetIt {
    VVStack *stack = [VVStack new];
    [stack push:2.3];
    double topNumber = [stack top];
    XCTAssertEqual(topNumber, 2.3, @"VVStack should can be pushed and has that top value.");
}
```

因为我们还没有实现`-push:`和`-top`方法，所以测试毫无疑问地失败了（在ARC环境中直接无法编译）。为了使测试立即通过我们首先需要在`VVStack.h`中声明这两个方法，然后在.m的实现文件中进行实现。令测试通过的最简单的实现是一个空的push方法以及直接返回2.3这个数：

```objc
//VVStack.h
@interface VVStack : NSObject
- (void)push:(double)num;
- (double)top;
@end

//VVStack.m
@implementation VVStack
- (void)push:(double)num {
    
}

- (double)top {
    return 2.3;
}
@end
```

再次运行测试，我们顺利回到了绿灯状态。也许你很快就会说，这算哪门子实现啊，如果再增加一组测试例，比如push一个4.6，然后检查top，不就失败了么？我们难道不应该直接实现一个真正的合理的实现么？对此的回答是，在实际开发中，我们肯定不会以这样的步伐来处理像例子中这样类似的简单问题，而是会直接跳过一些error-try的步骤，实现一个比较完整的方案。但是在更多的时候，我们所关心和需要实现的目标并不是这样容易。特别是在对TDD还不熟悉的时候，我们有必要放慢节奏和动作，将整个开发理念进行充分实践，这样才有可能在之后更复杂的案例中正确使用。于是我们发扬不怕繁杂，精益求精的精神，在刚才的测试例上增加一个测试，回到`VVStackTests.m`中，在刚才的测试方法中加上：

```objc
- (void)testPushANumberAndGetIt {
    //...
    [stack push:4.6];
    topNumber = [stack top];
    XCTAssertEqual(topNumber, 4.6, @"Top value of VVStack should be the last num pushed into it");
}
```

很好，这下子我们回到了红灯状态，这正是我们所期望的，现在是时候来考虑实现这个栈了。这个实现过于简单，也有非常多的思路，其中一种是使用一个`NSMutableArray`来存储数据，然后在`top`方法里返回最后加入的数据。修改`VVStack.m`，加入数组，更改实现：

```objc
//VVStack.m
@interface VVStack()
@property (nonatomic, strong) NSMutableArray *numbers;
@end

@implementation VVStack
- (id)init {
    if (self = [super init]) {
        _numbers = [NSMutableArray new];
    }
    return self;
}

- (void)push:(double)num {
    [self.numbers addObject:@(num)];
}

- (double)top {
    return [[self.numbers lastObject] doubleValue];
}
@end
```

测试通过，注意到在`-testStackObjectCanBeCreated`和`testPushANumberAndGetIt`两个测试中都生成了一个`VVStack`对象。在这个测试文件中基本每个测试都会需要初始化对象，因此我们可以考虑在测试文件中添加一个VVStack的实例成员，并将测试中的初始化代码移到`-setUp`中，并在`-tearDown`中释放。

接下来我们可以模仿继续实现`pop`等栈的方法。鉴于篇幅这里不再继续详细实现，大家可以自己动手试试看。记住先实现测试，然后再实现产品代码。一开始您可能会觉得这很无聊，效率低下，但是请记住这是起步练习不可缺少的一部分，而且在我们的例子中其实一切都是以“慢动作”在进行的。相信在经过实践和使用后，您将会逐渐掌握自己的节奏和重点测试。关于使用XCTest到这里为止的代码，可以在[github](https://github.com/onevcat/VVStack/tree/xctest)上找到。

### Kiwi和BDD的测试思想

`XCTest`是基于OCUnit的传统测试框架，在书写性和可读性上都不太好。在测试用例太多的时候，由于各个测试方法是割裂的，想在某个很长的测试文件中找到特定的某个测试并搞明白这个测试是在做什么并不是很容易的事情。所有的测试都是由断言完成的，而很多时候断言的意义并不是特别的明确，对于项目交付或者新的开发人员加入时，往往要花上很大成本来进行理解或者转换。另外，每一个测试的描述都被写在断言之后，夹杂在代码之中，难以寻找。使用XCTest测试另外一个问题是难以进行[mock或者stub](http://www.mockobjects.com)，而这在测试中是非常重要的一部分（关于mock测试的问题，我会在下一篇中继续深入）。

行为驱动开发（BDD）正是为了解决上述问题而生的，作为第二代敏捷方法，BDD提倡的是通过将测试语句转换为类似自然语言的描述，开发人员可以使用更符合大众语言的习惯来书写测试，这样不论在项目交接/交付，或者之后自己修改时，都可以顺利很多。如果说作为开发者的我们日常工作是写代码，那么BDD其实就是在讲故事。一个典型的BDD的测试用例包活完整的三段式上下文，测试大多可以翻译为`Given..When..Then`的格式，读起来轻松惬意。BDD在其他语言中也已经有一些框架，包括最早的Java的JBehave和赫赫有名的Ruby的[RSpec](http://rspec.info)和[Cucumber](http://cukes.info)。而在objc社区中BDD框架也正在欣欣向荣地发展，得益于objc的语法本来就非常接近自然语言，再加上[C语言宏的威力](http://onevcat.com/2014/01/black-magic-in-macro/)，我们是有可能写出漂亮优美的测试的。在objc中，现在比较流行的BDD框架有[cedar](https://github.com/pivotal/cedar)，[specta](https://github.com/specta/specta)和[Kiwi](https://github.com/allending/Kiwi)。其中个人比较喜欢Kiwi，使用Kiwi写出的测试看起来大概会是这个样子的：

```objc
describe(@"Team", ^{
    context(@"when newly created", ^{
        it(@"should have a name", ^{
            id team = [Team team];
            [[team.name should] equal:@"Black Hawks"];
        });

        it(@"should have 11 players", ^{
            id team = [Team team];
            [[[team should] have:11] players];
        });
    });
});
```

我们很容易根据上下文将其提取为`Given..When..Then`的三段式自然语言

> Given a team, when newly created, it should have a name, and should have 11 players

很简单啊有木有！在这样的语法下，是不是写测试的兴趣都被激发出来了呢。关于Kiwi的进一步语法和使用，我们稍后详细展开。首先来看看如何在项目中添加Kiwi框架吧。

### 在项目中添加Kiwi

最简单和最推荐的方法当然是[CocoaPods](http://cocoapods.org)，如果您对CocoaPods还比较陌生的话，推荐您花时间先看一看这篇[CocoaPods的简介](http://blog.devtang.com/blog/2012/12/02/use-cocoapod-to-manage-ios-lib-dependency/)。Xcode 5和XCTest环境下，我们需要在Podfile中添加类似下面的条目（记得将`VVStackTests`换成您自己的项目的测试target的名字）：

```
target :VVStackTests, :exclusive => true do
   pod 'Kiwi/XCTest'
end
```

之后`pod install`以后，打开生成的`xcworkspace`文件，Kiwi就已经处于可用状态了。另外，为了我们在新建测试的时候能省点事儿，可以在官方repo里下载并运行安装[Kiwi的Xcode Template](https://github.com/allending/Kiwi/tree/master/Xcode%20Templates)。如果您坚持不用CocoaPods，而想要自己进行配置Kiwi的话，可以参考[这篇wiki](https://github.com/allending/Kiwi/wiki/Setting-Up-Kiwi-2.x-without-CocoaPods)。


### 行为描述（Specs）和期望（Expectations），Kiwi测试的基本结构

我们先来新建一个Kiwi测试吧。如果安装了Kiwi的Template的话，在新建文件中选择`Kiwi/Kiwi Spec`来建立一个Specs，取名为`SimpleString`，注意选择目标target为我们的测试target，模板将会在新建的文件名字后面加上Spec后缀。传统测试的文件名一般以Tests为后缀，表示这个文件中含有一组测试，而在Kiwi中，一个测试文件所包含的是一组对于行为的描述（Spec），因此习惯上使用需要测试的目标类来作为名字，并以Spec作为文件名后缀。在Xcode 5中建立测试时已经不会同时创建.h文件了，但是现在的模板中包含有对同名.h的引用，可以在创建后将其删去。如果您没有安装Kiwi的Template的话，可以直接创建一个普通的Objective-C test case class，然后将内容替换为下面这样：

```objc
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(SimpleStringSpec)

describe(@"SimpleString", ^{

});

SPEC_END
```

你可能会觉得这不是objc代码，甚至怀疑这些语法是否能够编译通过。其实`SPEC_BEGIN`和`SPEC_END`都是宏，它们定义了一个`KWSpec`的子类，并将其中的内容包装在一个函数中（有兴趣的朋友不妨点进去看看）。我们现在先添加一些描述和测试语句，并运行看看吧，将上面的代码的`SPEC_BEGIN`和`SPEC_END`之间的内容替换为：

```objc
describe(@"SimpleString", ^{
    context(@"when assigned to 'Hello world'", ^{
        NSString *greeting = @"Hello world";
        it(@"should exist", ^{
            [[greeting shouldNot] beNil];
        });

        it(@"should equal to 'Hello world'", ^{
            [[greeting should] equal:@"Hello world"];
        });
    });
});
```

`describe`描述需要测试的对象内容，也即我们三段式中的`Given`，`context`描述测试上下文，也就是这个测试在`When`来进行，最后`it`中的是测试的本体，描述了这个测试应该满足的条件，三者共同构成了Kiwi测试中的行为描述。它们是可以nest的，也就是一个Spec文件中可以包含多个`describe`（虽然我们很少这么做，一个测试文件应该专注于测试一个类）；一个`describe`可以包含多个`context`，来描述类在不同情景下的行为；一个`context`可以包含多个`it`的测试例。让我们运行一下这个测试，观察输出：

```
VVStack[36517:70b] + 'SimpleString, when assigned to 'Hello world', should exist' [PASSED]
VVStack[36517:70b] + 'SimpleString, when assigned to 'Hello world', should equal to 'Hello world'' [PASSED]
```

可以看到，这三个关键字的描述将在测试时被依次打印出来，形成一个完整的行为描述。除了这三个之外，Kiwi还有一些其他的行为描述关键字，其中比较重要的包括

* `beforeAll(aBlock)` - 当前scope内部的所有的其他block运行之前调用一次
* `afterAll(aBlock)` - 当前scope内部的所有的其他block运行之后调用一次
* `beforeEach(aBlock)` - 在scope内的每个it之前调用一次，对于`context`的配置代码应该写在这里
* `afterEach(aBlock)` - 在scope内的每个it之后调用一次，用于清理测试后的代码
* `specify(aBlock)` - 可以在里面直接书写不需要描述的测试
* `pending(aString, aBlock)` - 只打印一条log信息，不做测试。这个语句会给出一条警告，可以作为一开始集中书写行为描述时还未实现的测试的提示。
* `xit(aString, aBlock)` - 和`pending`一样，另一种写法。因为在真正实现时测试时只需要将x删掉就是`it`，但是pending语意更明确，因此还是推荐pending

可以看到，由于有`context`的存在，以及其可以嵌套的特性，测试的流程控制相比传统测试可以更加精确。我们更容易把before和after的作用区域限制在合适的地方。

实际的测试写在`it`里，是由一个一个的期望(Expectations)来进行描述的，期望相当于传统测试中的断言，要是运行的结果不能匹配期望，则测试失败。在Kiwi中期望都由`should`或者`shouldNot`开头，并紧接一个或多个判断的的链式调用，大部分常见的是be或者haveSomeCondition的形式。在我们上面的例子中我们使用了should not be nil和should equal两个期望来确保字符串赋值的行为正确。其他的期望语句非常丰富，并且都符合自然语言描述，所以并不需要太多介绍。在使用的时候不妨直接按照自己的想法来描述自己的期望，一般情况下在IDE的帮助下我们都能找到想要的结果。如果您想看看完整的期望语句的列表，可以参看文档的[这个页面](https://github.com/allending/Kiwi/wiki/Expectations)。另外，您还可以通过新建`KWMatcher`的子类，来简单地自定义自己和项目所需要的期望语句。从这一点来看，Kiwi可以说是一个非常灵活并具有可扩展性的测试框架。

到此为止的代码可以从[这里](https://github.com/onevcat/VVStack/tree/kiwi-start)找到。

### Kiwi实际使用实例

最后我们来用Kiwi完整地实现VVStack类的测试和开发吧。首先重写刚才XCTest的相关测试：新建一个VVStackSpec作为Kiwi版的测试用例，然后把describe换成下面的代码：

```objc
describe(@"VVStack", ^{
    context(@"when created", ^{
        __block VVStack *stack = nil;
        beforeEach(^{
            stack = [VVStack new];
        });
        
        afterEach(^{
            stack = nil;
        });
        
        it(@"should have the class VVStack", ^{
            [[[VVStack class] shouldNot] beNil];
        });
        
        it(@"should exist", ^{
            [[stack shouldNot] beNil];
        });
        
        it(@"should be able to push and get top", ^{
            [stack push:2.3];
            [[theValue([stack top]) should] equal:theValue(2.3)];
            
            [stack push:4.6];
            [[theValue([stack top]) should] equal:4.6 withDelta:0.001];
        });
        
    });
});
```

看到这里的您看这段测试应该不成问题。需要注意的有两点：首先`stack`分别是在`beforeEach`和`afterEach`的block中的赋值的，因此我们需要在声明时在其前面加上`__block`标志。其次，期望描述的should或者shouldNot是作用在对象上的宏，因此对于标量，我们需要先将其转换为对象。Kiwi为我们提供了一个标量转对象的语法糖，叫做`theValue`，在做精确比较的时候我们可以直接使用例子中直接与2.3做比较这样的写法来进行对比。但是如果测试涉及到运算的话，由于浮点数精度问题，我们一般使用带有精度的比较期望来进行描述，即4.6例子中的`equal:withDelta:`（当然，这里只是为了demo，实际在这用和上面2.3一样的方法就好了）。

接下来我们再为这个context添加一个测试例，用来测试初始状况时栈是否为空。因为我们使用了一个Array来作为存储容器，根据我们之前用过的equal方法，我们很容易想到下面这样的测试代码

```objc
it(@"should equal contains 0 element", ^{
    [[theValue([stack.numbers count]) should] equal:theValue(0)];
});
```

这段测试在逻辑上没有太大问题，但是有非常多值得改进的地方。首先如果我们需要将原来写在Extension里的`numbers`暴露到头文件中，这对于类的封装是一种破坏，对于这个，一种常见的做法是只暴露一个`-count`方法，让其返回`numbers`的元素个数，从而保证`numbers`的私有性。另外对于取值和转换，其实theValue的存在在一定程度上是破坏了测试可读性的，我们可以想办法改善一下，比如对于0的来说，我们有`beZero`这样的期望可以使用。简单改写以后，这个`VVStack.h`和这个测试可以变成这个样子：

```objc
//VVStack.h
//...
- (NSUInteger)count;
//...


//VVStack.m
//...
- (NSUInteger)count {
    return [self.numbers count];
}
//...

it(@"should equal contains 0 element", ^{
    [[theValue([stack count]) should] beZero];
});
```

更进一步地，对于一个collection来说，Kiwi有一些特殊处理，比如`have`和`haveCountOf`系列的期望。如果测试的对象实现了`-count`方法的话，我们就可以使用这一系列期望来写出更好的测试语句。比如上面的测试还可以进一步写成

```objc
it(@"should equal contains 0 element", ^{
    [[stack should] haveCountOf:0];
});
```

在这种情况下，我们并没有显式地调用VVStack的`-count`方法，所以我们可以在头文件中将其删掉。但是我们需要保留这个方法的实现，因为测试时是需要这个方法的。如果测试对象不能响应count方法的话，如你所料，测试时会扔一个unrecognized selector的错。Kiwi的内部实现是一个大量依赖了一个个行为Matcher和objc的消息转发，对objcruntime特性比较熟悉，并想更深入的朋友不放可以看看Kiwi的源码，写得相当漂亮。

其实对于这个测试，我们还可以写出更漂亮的版本，像这样：

```objc
it(@"should equal contains 0 element", ^{
    [[stack should] beEmpty];
});
```

好了。关于空栈这个情景下的测试感觉差不多了。我们继续用TDD的思想来完善`VVStack`类吧。栈的话，我们当然需要能够`-pop`，也就是说在（Given）给定一个栈时，（When）当栈中有元素的时候，（Then）我们可以pop它，并且得到栈顶元素。我们新建一个context，然后按照这个思路书写行为描述（测试）：

```objc
    context(@"when new created and pushed 4.6", ^{
        __block VVStack *stack = nil;
        beforeEach(^{
            stack = [VVStack new];
            [stack push:4.6];
        });
        
        afterEach(^{
            stack = nil;
        });
        
        it(@"can be poped and the value equals 4.6", ^{
            [[theValue([stack pop]) should] equal:theValue(4.6)];
        });
        
        it(@"should contains 0 element after pop", ^{
            [stack pop];
            [[stack should] beEmpty];
        });
    });
```

完成了测试书写后，我们开始按照设计填写产品代码。在VVStack.h中完成申明，并在.m中加入相应实现。

```objc
- (double)pop {
    double result = [self top];
    [self.numbers removeLastObject];
    return result;
}
```

很简单吧。而且因为有测试的保证，我们在提供像Stack这样的基础类时，就不需要等到或者在真实的环境中检测了。因为在被别人使用之前，我们自己的测试代码已经能够保证它的正确性了。`VVStack`剩余的最后一个小问题是，在栈是空的时候，我们执行pop操作时应该给出一个错误，用以提示空栈无法pop。虽然在objc中异常并不常见，但是在这个情景下是抛异常的好时机，也符合一般C语言对于出空栈的行为。我们可以在之前的“when created”上下文中加入一个期望：

```objc
it(@"should raise a exception when pop", ^{
    [[theBlock(^{
        [stack pop];
    }) should] raiseWithName:@"VVStackPopEmptyException"];
});
```

和`theValue`配合标量值类似，`theBlock`也是Kiwi中的一个转换语法，用来将一段程序转换为相应的matcher，使其可以被施加期望。这里我们期望空的Stack在被pop时抛出一个叫做"VVStackPopEmptyException"的异常。我们可以重构pop方法，在栈为空时给一个异常：

```objc
- (double)pop {
    if ([self count] == 0) {
        [NSException raise:@"VVStackPopEmptyException" format:@"Can not pop an empty stack."];
    }
    double result = [self top];
    [self.numbers removeLastObject];
    return result;
}
```

### 进一步的Kiwi

VVStack的测试和实现就到这里吧，根据这套测试，您可以使用自己的实现来轻易地重构这个类，而不必担心破坏它的公共接口的行为。如果需要添加新的功能或者修正已有bug的时候，我们也可以通过添加或者修改相应的测试，来确保正确性。我将会在下一篇博文中继续介绍Kiwi，看看Kiwi在异步测试和mock/stub的使用和表现如何。Kiwi现在还在比较快速的发展中，官方repo的[wiki](https://github.com/allending/Kiwi/wiki)上有一些不错的资料和文档，可以参考。`VVStack`的项目代码可以在[这个repo](https://github.com/onevcat/VVStack)上找到，可以作为参考。

另外，Kiwi 不仅可以用来做简单的特性测试，它也包括了完整的 mock 和 stub 测试的功能。关于这部分内容我补充了一篇[文章](http://onevcat.com/2014/05/kiwi-mock-stub-test/)专门说明，有兴趣的同学不妨继续深入看看。
