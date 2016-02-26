---
layout: post
title: WWDC 2012 Session笔记——205 Introducing Collection Views
date: 2012-06-30 23:41:15.000000000 +09:00
tags: 能工巧匠集
---

这是博主的WWDC2012笔记系列中的一篇，完整的笔记列表可以参看[这里](http://onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)。如果您是首次来到本站，也许您会有兴趣通过[RSS](http://onevcat.com/atom.xml)，或者通过页面左侧的邮件订阅的方式订阅本站。

在之前的[iOS6 SDK新特性前瞻](http://www.onevcat.com/2012/06/%E5%BC%80%E5%8F%91%E8%80%85%E6%89%80%E9%9C%80%E8%A6%81%E7%9F%A5%E9%81%93%E7%9A%84ios6-sdk%E6%96%B0%E7%89%B9%E6%80%A7/)中我曾经提到过UICollectionView，当时只把CollectionView当作是一个现在已有的开源GridView，仔细研究了下WWDC2012相关的Session后发现并不是那么简单。Apple这次真的给广大开发者带来了一个非常powerful的view，其强大程度可以说远超UITableView。接下来的这篇笔记将对应Session 205，作为使用UICollectionView的入门，之后还将完成一篇关于深入使用UICollectionView以及相应的Layout的笔记。

废话到此，正式开始。

### 什么是UICollectionView

UICollectionView是一种新的数据展示方式，简单来说可以把他理解成多列的UITableView(请一定注意这是UICollectionView的最最简单的形式)。如果你用过iBooks的话，可能你还对书架布局有一定印象：一个虚拟书架上放着你下载和购买的各类图书，整齐排列。其实这就是一个UICollectionView的表现形式，或者iPad的iOS6中的原生时钟应用中的各个时钟，也是UICollectionView的最简单的一个布局，如图：

![iOS6 iPad版时钟应用](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-1.png)
最简单的UICollectionView就是一个GridView，可以以多列的方式将数据进行展示。标准的UICollectionView包含三个部分，它们都是UIView的子类：


* Cells 用于展示内容的主体，对于不同的cell可以指定不同尺寸和不同的内容，这个稍后再说
* Supplementary Views 追加视图 如果你对UITableView比较熟悉的话，可以理解为每个Section的Header或者Footer，用来标记每个section的view
* Decoration Views 装饰视图 这是每个section的背景，比如iBooks中的书架就是这个

![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-2.png)
![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-3.png)

不管一个UICollectionView的布局如何变化，这三个部件都是存在的。再次说明，复杂的UICollectionView绝不止上面的几幅图，关于较复杂的布局和相应的特性，我会在本文稍后和[下一篇笔记](http://www.onevcat.com/2012/08/advanced-collection-view/")中进行一些深入。

* * *

### 实现一个简单的UICollectionView

先从最简单的开始，UITableView是iOS开发中的非常非常非常重要的一个类，相信如果你是开发者的话应该是对这个类非常熟悉了。实现一个UICollectionView和实现一个UITableView基本没有什么大区别，它们都同样是datasource和delegate设计模式的：datasource为view提供数据源，告诉view要显示些什么东西以及如何显示它们，delegate提供一些样式的小细节以及用户交互的相应。因此在本节里会大量对比collection view和table view来进行说明，如果您还不太熟悉table view的话，也是个对照着复习的好机会。

#### ￼￼￼￼UICollectionViewDataSource

* section的数量 ￼-numberOfSectionsInCollection:
* 某个section里有多少个item ￼-collectionView:numberOfItemsInSection:
* 对于某个位置应该显示什么样的cell ￼-collectionView:cellForItemAtIndexPath:

实现以上三个委托方法，基本上就可以保证CollectionView工作正常了。当然，还有提供Supplementary View的方法

*   collectionView:viewForSupplementaryElementOfKind:atIndexPath:

对于Decoration Views，提供方法并不在UICollectionViewDataSource中，而是直接UICollectionViewLayout类中的(因为它仅仅是视图相关，而与数据无关)，放到稍后再说。

#### 关于重用

为了得到高效的View，对于cell的重用是必须的，避免了不断生成和销毁对象的操作，这与在UITableView中的情况是一致的。但值得注意的时，在UICollectionView中，不仅cell可以重用，Supplementary View和Decoration View也是可以并且应当被重用的。在iOS5中，Apple对UITableView的重用做了简化，以往要写类似这样的代码：

```objc
UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MY_CELL_ID"]; 
if (!cell) {    //如果没有可重用的cell，那么生成一个 
    cell = [[UITableViewCell alloc] init]; 
} 
//配置cell，blablabla 
return cell
```

而如果我们在TableView向数据源请求数据之前使用`-registerNib:forCellReuseIdentifier:`方法为@“MY_CELL_ID"注册过nib的话，就可以省下每次判断并初始化cell的代码，要是在重用队列里没有可用的cell的话，runtime将自动帮我们生成并初始化一个可用的cell。

这个特性很受欢迎，因此在UICollectionView中Apple继承使用了这个特性，并且把其进行了一些扩展。使用以下方法进行注册：

* -registerClass:forCellWithReuseIdentifier:
* -registerClass:forSupplementaryViewOfKind:withReuseIdentifier:
* -registerNib:forCellWithReuseIdentifier:
* -registerNib:forSupplementaryViewOfKind:withReuseIdentifier:

相比UITableView有两个主要变化：一是加入了对某个Class的注册，这样即使不用提供nib而是用代码生成的view也可以被接受为cell了；二是不仅只是cell，Supplementary View也可以用注册的方法绑定初始化了。在对collection view的重用ID注册后，就可以像UITableView那样简单的写cell配置了：

```objc
- (UICollectionView*)collectionView:(UICollectionView*)cv cellForItemAtIndexPath:(NSIndexPath*)indexPath { 
    MyCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@”MY_CELL_ID”]; 
    // Configure the cell's content 
    cell.imageView.image = ... 
    return cell; 
}
```

需要吐槽的是，对collection view，取重用队列的方法的名字和UITableView里面不一样了，在Identifier前面多加了Reuse五个字母，语义上要比以前清晰，命名规则也比以前严谨了..不知道Apple会不会为了追求完美而把UITableView中的命名不那么好的方法deprecate掉。

#### UICollectionViewDelegate

数据无关的view的外形啊，用户交互啊什么的，由UICollectionViewDelegate来负责：

*   cell的高亮
*   cell的选中状态
*   可以支持长按后的菜单

关于用户交互，UICollectionView也做了改进。每个cell现在有独立的高亮事件和选中事件的delegate，用户点击cell的时候，现在会按照以下流程向delegate进行询问：

1.  -￼collectionView:shouldHighlightItemAtIndexPath: 是否应该高亮？
2.  -￼collectionView:didHighlightItemAtIndexPath: 如果1回答为是，那么高亮
3.  -￼collectionView:shouldSelectItemAtIndexPath: 无论1结果如何，都询问是否可以被选中？
4.  -collectionView:didUnhighlightItemAtIndexPath: 如果1回答为是，那么现在取消高亮
5.  -collectionView:didSelectItemAtIndexPath: 如果3回答为是，那么选中cell

状态控制要比以前灵活一些，对应的高亮和选中状态分别由highlighted和selected两个属性表示。

#### 关于Cell

相对于UITableViewCell来说，UICollectionViewCell没有这么多花头。首先UICollectionViewCell不存在各式各样的默认的style，这主要是由于展示对象的性质决定的，因为UICollectionView所用来展示的对象相比UITableView来说要来得灵活，大部分情况下更偏向于图像而非文字，因此需求将会千奇百怪。因此SDK提供给我们的默认的UICollectionViewCell结构上相对比较简单，由下至上：

* 首先是cell本身作为容器view
* 然后是一个大小自动适应整个cell的backgroundView，用作cell平时的背景
* 再其上是selectedBackgroundView，是cell被选中时的背景
* 最后是一个contentView，自定义内容应被加在这个view上

这次Apple给我们带来的好康是被选中cell的自动变化，所有的cell中的子view，也包括contentView中的子view，在当cell被选中时，会自动去查找view是否有被选中状态下的改变。比如在contentView里加了一个normal和selected指定了不同图片的imageView，那么选中这个cell的同时这张图片也会从normal变成selected，而不需要额外的任何代码。

#### ￼UICollectionViewLayout

终于到UICollectionView的精髓了…这也是UICollectionView和UITableView最大的不同。UICollectionViewLayout可以说是UICollectionView的大脑和中枢，它负责了将各个cell、Supplementary View和Decoration Views进行组织，为它们设定各自的属性，包括但不限于：

* 位置
* 尺寸
* 透明度
* 层级关系
* 形状
* 等等等等…
* 
Layout决定了UICollectionView是如何显示在界面上的。在展示之前，一般需要生成合适的UICollectionViewLayout子类对象，并将其赋予CollectionView的collectionViewLayout属性。关于详细的自定义UICollectionViewLayout和一些细节，我将写在之后一篇笔记中。

Apple为我们提供了一个最简单可能也是最常用的默认layout对象，￼￼￼UICollectionViewFlowLayout。Flow Layout简单说是一个直线对齐的layout，最常见的Grid View形式即为一种Flow Layout配置。上面的照片架界面就是一个典型的Flow Layout。

* 首先一个重要的属性是itemSize，它定义了每一个item的大小。通过设定itemSize可以全局地改变所有cell的尺寸，如果想要对某个cell制定尺寸，可以使用-collectionView:layout:sizeForItemAtIndexPath:方法。
* 间隔 可以指定item之间的间隔和每一行之间的间隔，和size类似，有全局属性，也可以对每一个item和每一个section做出设定：

    * @property (CGSize) minimumInteritemSpacing
    * @property (CGSize) minimumLineSpacing
    * -collectionView:layout:minimumInteritemSpacingForSectionAtIndex:
    * -collectionView:layout:minimumLineSpacingForSectionAtIndex:

* 滚动方向 由属性scrollDirection确定scroll view的方向，将影响Flow Layout的基本方向和由header及footer确定的section之间的宽度

    * UICollectionViewScrollDirectionVertical
    * UICollectionViewScrollDirectionHorizontal

* Header和Footer尺寸 同样地分为全局和部分。需要注意根据滚动方向不同，header和footer的高和宽中只有一个会起作用。垂直滚动时section间宽度为该尺寸的高，而水平滚动时为宽度起作用，如图。

    * @property (CGSize) headerReferenceSize
    * @property (CGSize) footerReferenceSize
    * -collectionView:layout:referenceSizeForHeaderInSection:
    * -collectionView:layout:referenceSizeForFooterInSection:

* 缩进

    * @property UIEdgeInsets sectionInset;
    * -collectionView:layout:insetForSectionAtIndex:

#### 总结

一个UICollectionView的实现包括两个必要部分：UICollectionViewDataSource和UICollectionViewLayout，和一个交互部分：UICollectionViewDelegate。而Apple给出的UICollectionViewFlowLayout已经是一个很强力的layout方案了。

* * *

### 几个自定义的Layout

但是光是UICollectionViewFlowLayout的话，显然是不够用的，而且如果单单是这样的话，就和现有的开源各类Grid View没有区别了…UICollectionView的强大之处，就在于各种layout的自定义实现，以及它们之间的切换。先看几个相当exiciting的例子吧～

比如，堆叠布局：

![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-4.png)

圆形布局：

![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-5-300x290.png)

和Cover Flow布局：

![](http://www.onevcat.com/wp-content/uploads/2012/06/QQ20120630-6.png)

所有这些布局都采用了同样的数据源和委托方法，因此完全实现了model和view的解耦。但是如果仅这样，那开源社区也已经有很多相应的解决方案了。Apple的强大和开源社区不能比拟的地方在于对SDK的全局掌控，CollectionView提供了非常简单的API可以令开发者只需要一次简单调用，就可以使用CoreAnimation在不同的layout之间进行动画切换，这种切换必定将大幅增加用户体验，代价只是几十行代码就能完成的布局实现，以及简单的一句API调用，不得不说现在所有的开源代码与之相比，都是相形见拙了…不得不佩服和感谢UIKit团队的努力。

关于上面几种自定义Layout和实现细节，和其他高级CollectionView应用，将在[下一篇笔记](http://www.onevcat.com/2012/08/advanced-collection-view/ "WWDC 2012 Session笔记——219 Advanced Collection Views and Building Custom Layouts")中进行详细说明～
