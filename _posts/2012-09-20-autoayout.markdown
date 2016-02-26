---
layout: post
title: WWDC 2012 Session笔记——202, 228, 232 AutoLayout（自动布局）入门
date: 2012-09-20 00:01:31.000000000 +09:00
tags: 能工巧匠集
---

![](http://www.onevcat.com/wp-content/uploads/2012/09/QQ20120920-8.png)

这是博主的WWDC2012笔记系列中的一篇，完整的笔记列表可以参看[这里](http://onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)。如果您是首次来到本站，也许您会有兴趣通过[RSS](http://onevcat.com/atom.xml)，或者通过页面左侧的邮件订阅的方式订阅本站。

AutoLayout在去年的WWDC上被引入Cocoa，而在今年的WWDC上，Apple不惜花费了三个Session的前所未见的篇幅来详细地向开发者讲解AutoLayout在iOS上的应用，是由起原因的：iPhone5的屏幕将变为4寸，开发者即将面临为不同尺寸屏幕进行应用适配的工作。Android平台开发中最令人诟病的适配工作的厄运现在似乎也将降临在iOS开发者的头上。基于这样的情况，Apple大力推广使用AutoLayout的方法来进行UI布局，以一举消除适配的烦恼。AutoLayout将是自Interface Builder和StoryBoard之后UI制作上又一次重要的变化，也必然是之后iOS开发的趋势，因此这个专题很值得学习。

## AutoLayout是什么？

使用一句Apple的官方定义的话

> AutoLayout是一种基于约束的，描述性的布局系统。
> Auto Layout Is a Constraint-Based, Descriptive Layout System.

关键词：

* 基于约束 － 和以往定义frame的位置和尺寸不同，AutoLayout的位置确定是以所谓相对位置的约束来定义的，比如_x坐标为superView的中心，y坐标为屏幕底部上方10像素_等
* 描述性 － 约束的定义和各个view的关系使用接近自然语言或者可视化语言（稍后会提到）的方法来进行描述
* 布局系统 － 即字面意思，用来负责界面的各个元素的位置。

总而言之，AutoLayout为开发者提供了一种不同于传统对于UI元素位置指定的布局方法。以前，不论是在IB里拖放，还是在代码中写，每个UIView都会有自己的frame属性，来定义其在当前视图中的位置和尺寸。使用AutoLayout的话，就变为了使用约束条件来定义view的位置和尺寸。这样的**最大好处是一举解决了不同分辨率和屏幕尺寸下view的适配问题，另外也简化了旋转时view的位置的定义**，原来在底部之上10像素居中的view，不论在旋转屏幕或是更换设备（iPad或者iPhone5或者以后可能出现的mini iPad）的时候，始终还在底部之上10像素居中的位置，不会发生变化。

总结

> 使用约束条件来描述布局，view的frame会依据这些约束来进行计算
> Describe the layout with constraints, and frames are calculated automatically.

* * *

## AutoLayout和Autoresizing Mask的区别

Autoresizing Mask是我们的老朋友了…如果你以前一直是代码写UI的话，你肯定写过UIViewAutoresizingFlexibleWidth之类的枚举；如果你以前用IB比较多的话，一定注意到过每个view的size inspector中都有一个红色线条的Autoresizing的指示器和相应的动画缩放的示意图，这就是Autoresizing Mask。在iOS6之前，关于屏幕旋转的适配和iPhone，iPad屏幕的自动适配，基本都是由Autoresizing Mask来完成的。但是随着大家对iOS app的要求越来越高，以及已经以及今后可能出现的多种屏幕和分辨率的设备来说，Autoresizing Mask显得有些落伍和迟钝了。AutoLayout可以完成所有原来Autoresizing Mask能完成的工作，同时还能够胜任一些原来无法完成的任务，其中包括：

* AutoLayout可以指定任意两个view的相对位置，而不需要像Autoresizing Mask那样需要两个view在直系的view hierarchy中。
* AutoLayout不必须指定相等关系的约束，它可以指定非相等约束（大于或者小于等）；而Autoresizing Mask所能做的布局只能是相等条件的。
* AutoLayout可以指定约束的优先级，计算frame时将优先按照满足优先级高的条件进行计算。

总结

> Autoresizing Mask是AutoLayout的子集，任何可以用Autoresizing Mask完成的工作都可以用AutoLayout完成。AutoLayout还具备一些Autoresizing Mask不具备的优良特性，以帮助我们更方便地构建界面。

* * *

## AutoLayout基本使用方法

### Interface Builder

最简单的使用方法是在IB中直接拖。在IB中任意一个view的File inspector下面，都有Use Autolayout的选择框（没有的同学可以考虑升级一下Xcode了=。=），钩上，然后按照平常那样拖控件就可以了。拖动控件后在左边的view hierarchy栏中会出现Constraints一向，其中就是所有的约束条件。

![](http://ww3.sinaimg.cn/mw690/83bbf18dgw1dwxkfbus7qj.jpg)

选中某个约束条件后，在右边的Attributes inspector中可以更改约束的条件，距离值和优先度等：
![](http://ww2.sinaimg.cn/mw690/83bbf18dgw1dwxklmxul8j.jpg)

对于没有自动添加的约束，可以在IB中手动添加。选择需要添加约束的view，点击菜单的Edit->Pin里的需要的选项，或者是点击IB主视图右下角的![](http://ww3.sinaimg.cn/mw690/83bbf18dgw1dwxkrarjvmj.jpg)按钮，即可添加格外的约束条件。

可视化的添加不仅很方便直观，而且基本不会出错，是优先推荐的添加约束的方式。但是有时候只靠IB是无法完成某些约束的添加的（比如跨view hierarchy的约束），有时候IB添加的约束不能满足要求，这时就需要使用约束的API进行补充。

### 手动使用API添加约束

#### 创建

iOS6中新加入了一个类：NSLayoutConstraint，一个形如这样的约束

* item1.attribute = multiplier ⨉ item2.attribute + constant

对应的代码为

```objc
[NSLayoutConstraint constraintWithItem:button
                             attribute:NSLayoutAttributeBottom
                             relatedBy:NSLayoutRelationEqual
                                toItem:superview
                             attribute:NSLayoutAttributeBottom
                            multiplier:1.0
                              constant:-padding]
```

这对应的约束是“button的底部（y） ＝ superview的底部 －10”。

#### 添加

在创建约束之后，需要将其添加到作用的view上。UIView（当然NSView也一样）加入了一个新的实例方法：

* -(void)addConstraint:(NSLayoutConstraint *)constraint;
用来将约束添加到view。在添加时唯一要注意的是添加的目标view要遵循以下规则：

	* 对于两个同层级view之间的约束关系，添加到他们的父view上
	
![](http://ww1.sinaimg.cn/mw690/83bbf18dgw1dx3236wmnnj.jpg)

	* 对于两个不同层级view之间的约束关系，添加到他们最近的共同父view上
	
![](http://ww1.sinaimg.cn/mw690/83bbf18dgw1dx3237dsbxj.jpg)

    * 对于有层次关系的两个view之间的约束关系，添加到层次较高的父view上

![](http://ww4.sinaimg.cn/mw690/83bbf18dgw1dx32384ardj.jpg)

#### 刷新

可以通过-setNeedsUpdateConstraints和-layoutIfNeeded两个方法来刷新约束的改变，使UIView重新布局。这和CoreGraphic的-setNeedsDisplay一套东西是一样的～

### Visual Format Language 可视格式语言

UIKit团队这次相当有爱，估计他们自己也觉得新加约束的API名字太长了，因此他们发明了一种新的方式来描述约束条件，十分有趣。这种语言是对视觉描述的一种抽象，大概过程看起来是这样的：

accept按钮在cancel按钮右侧默认间距处

![](http://ww2.sinaimg.cn/mw690/83bbf18dgw1dx32c2yth4j.jpg)

![](http://ww4.sinaimg.cn/mw690/83bbf18dgw1dx32c3win2j.jpg)

![](http://ww3.sinaimg.cn/mw690/83bbf18dgw1dx32c47ab9j.jpg)

最后使用VFL（Visual Format Language）描述变成这样：

```objc
[NSLayoutConstraint constraintsWithVisualFormat:@"[cancelButton]-[acceptButton]" 
                                        options:0 
                                        metrics:nil 
                                          views:viewsDictionary];</pre>
```

其中viewsDictionary是绑定了view的名字和对象的字典，对于这个例子可以用以下方法得到对应的字典：

```objc
UIButton *cancelButton = ... 
UIButton *acceptButton = ... 
viewsDictionary = NSDictionaryOfVariableBindings(cancelButton,acceptButton);
```

生成的字典为

`{ acceptButton = ""; cancelButton = ""; }`

当然，不嫌累的话自己手写也未尝不可。现在字典啊数组啊写法相对简化了很多了，因此也不复杂。关于Objective-C的新语法，可以参考我之前的一篇WWDC 2012笔记：[WWDC 2012 Session笔记——405 Modern Objective-C](http://www.onevcat.com/2012/06/modern-objective-c/)。

在view名字后面添加括号以及连接处的数字可以赋予表达式更多意义，以下进行一些举例：

* [cancelButton(72)]-12-[acceptButton(50)]
    * 取消按钮宽72point，accept按钮宽50point，它们之间间距12point
* [wideView(>=60@700)]
    * wideView宽度大于等于60point，该约束条件优先级为700（优先级最大值为1000，优先级越高的约束越先被满足）
* V:[redBox][yellowBox(==redBox)]
    * 竖直布局，先是一个redBox，其下方紧接一个宽度等于redBox宽度的yellowBox
* H:|-[Find]-[FindNext]-[FindField(>=20)]-|
    * 水平布局，Find距离父view左边缘默认间隔宽度，之后是FindNext距离Find间隔默认宽度；再之后是宽度不小于20的FindField，它和FindNext以及父view右边缘的间距都是默认宽度。（竖线'|‘ 表示superview的边缘）

* * *

## 容易出现的错误

因为涉及约束问题，因此约束模型下的所有可能出现的问题这里都会出现，具体来说包括两种：

* Ambiguous Layout 布局不能确定
* Unsatisfiable Constraints 无法满足约束

布局不能确定指的是给出的约束条件无法唯一确定一种布局，也即约束条件不足，无法得到唯一的布局结果。这种情况一般添加一些必要的约束或者调整优先级可以解决。无法满足约束的问题来源是有约束条件互相冲突，因此无法同时满足，需要删掉一些约束。两种错误在出现时均会导致布局的不稳定和错误，Ambiguous可以被容忍并且选择一种可行布局呈现在UI上，Unsatisfiable的话会无法得到UI布局并报错。

对于不能确定的布局，可以通过调试时暂停程序，在debugger中输入

* po [[UIWindow keyWindow] _autolayoutTrace]

来检查是否存在Ambiguous Layout以及存在的位置，来帮助添加条件。另外还有一些检查方法，来查看view的约束和约束状态：

* [view constraintsAffectingLayoutForOrientation/Axis: NSLayoutConstraintOrientationHorizontal/Vertical]
* [view hasAmbiguousLayout]
	* [view exerciseAmbiguityInLayout]

> 2013年9月1日作者更新：在iOS7和Xcode5中，IB在添加和检查Autolayout约束方面有了长足的进步。现在使用IB可以比较容易地完成复杂约束，而得益于新的IB的约束检查机制，我们也很少再会遇到遗漏或者多余约束情况的出现（有问题的约束条件将直接在IB中得到错误或者警告）。但是对于确实很奇葩的约束条件有可能使用IB无法达成，这时候还是有可能需要代码补充的。

* * *

## 布局动画

动画是UI体验的重要部分，更改布局以后的动画也非常关键。说到动画，Core Animation又立功了..自从CA出现以后，所有的动画效果都非常cheap，在auto layout中情况也和collection view里一样，很简单（可以参考[WWDC 2012 Session笔记——219 Advanced Collection Views and Building Custom Layouts](http://www.onevcat.com/2012/08/advanced-collection-view/)），只需要把layoutIfNeeded放到animation block中即可～

```objc
[UIView animateWithDuration:0.5 animations:^{
    [view layoutIfNeeded];
}];
```

如果对block不熟悉的话，可以看看我很早时候写的一篇[block的文章](http://blog.onevcat.com/2011/11/objc-block/)。
