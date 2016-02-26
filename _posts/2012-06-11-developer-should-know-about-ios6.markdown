---
layout: post
title: 开发者所需要知道的iOS6 SDK新特性
date: 2014-06-11 23:35:11.000000000 +09:00
tags: 能工巧匠集
---

欢迎转载本文，但是转载请注明本文出处： **[http://2.gy/erSp](http://2.gy/erSp)**

iOS6 beta和相应的SDK已经放出了，WWDC2012要进入session环节了。iOS6无疑是这届WWDC的重点，在keynote上面对消费者展示了很多新鲜的特性，而之后的seesion对于开发者来说应该是更为重要。这里先大概把iOS6里新增的开发者可能用到的特性做个简单的整理。之后我也会挑一些自己感兴趣的session做一些整理和翻译工作，也算是对自己的一种锻炼吧～相关的笔记整理如下：

[Session 200 What's New in Cocoa Touch](http://www.onevcat.com/2012/06/what-is-new-in-cocoa-touch/)  Cocoa Touch新特性一览

[Session 405 Modern Objective-C](http://www.onevcat.com/2012/06/modern-objective-c/ "WWDC 2012 Session笔记——405 Modern Objective-C") 先进Objective-C

[Session 205 Introducing Collection Views](http://www.onevcat.com/2012/06/introducing-collection-views/ "WWDC 2012 Session笔记——205 Introducing Collection Views") Collection View入门

[Session 219 Advanced Collection Views and Building Custom Layouts](http://www.onevcat.com/2012/08/advanced-collection-view/ "WWDC 2012 Session笔记——219 Advanced Collection Views and Building Custom Layouts") 高级Collection View和自定义布局

[Session 202,228,232 AutoLayout使用](http://www.onevcat.com/2012/09/autoayout/ "WWDC 2012 Session笔记——202, 228, 232 AutoLayout（自动布局）入门")

* * *

### 地图

iOS6抛弃了一直用的google map，而使用了自家的地图服务。相应地，MapKit框架也自然变成和Apple自家的地图服务绑定了。随之而来的好处是因为都是自家的内容，所以整合和开放会更进一步，第三方app现在有机会和地图应用进行交互了。也就是说，不使用自身搭载地图信息的app现在可以打开地图应用，并且显示一些感兴趣的路线和地点，这对于路线规划和记录类的应用来说这是个好消息～

<!--more-->

* * *

### 深度社交网络集成

iOS5的时候深度集成了Twitter，而Apple似乎从中尝到了不少甜头。现在Apple深度集成了Facebook和Sina Weibo。是的你没看错..新浪微博现在被深度集成了。对于开发这来说，特别是中国开发者来说确实是个好消息，因为如果只是想发条信息的话，不再需要进行繁琐的API申请，不再需要接受新浪恶心的应用审核，也不再需要忍受新浪程序员写出来的错误百出的SDK了。使用新的Social.framework可以很简单的从系统中拿到认证然后向社交网络发送消息，这对app的推广来说是很好的补充。

另外，Apple提供了一类新的ViewController：UIActivityViewController来询问用户的社交行为，可以看做这是Apple为统一界面和用户体验做的努力，但是估计除了Apple自家的应用意外可能很少有人会用默认界面吧..毕竟冒了会和自己的UI风格不符的危险…

* * *

### Passbook和PassKit

Passbook是iOS6自带的新应用，可以用来存储一些优惠券啊电影票啊登机牌啊什么的。也许Passbook这个新应用不是很被大家看好，但是我坚持认为这会是一个很有前景的方向。这是又一次使用数字系统来取代物理实体的尝试，而且从Passbook里我看到了Apple以后在NFC领域发展的空间。因为iPhone的设备很容易统一，因此也许会由Apple首先制定NFC的新游戏标准也为可知，如果成真那电子钱包和电子支付将会变成一大桶金呐…

扯远了，PassKit是新加入的，可以说是配合或者呼应Passbook存在的框架。开发者可以使用PassKit生成和读取包含一些类似优惠券电影票之类信息的特殊格式的文件，然后以加密签名的方式发送给用户。然后在使用时，出示这些凭证即可按照类似物理凭证的方式进行使用。这给了类似电影院和餐馆这样的地方很多机会，可以利用PassKit进行售票系统或者优惠系统的开发，来引入更方便的购票体系，争取更多的客户。当然，现在还只能是当做物理凭证的补充来使用，我始终相信当iPhone里加入NFC模块以后，Passbook将摇身一变，而你的iPhone便理所当然的成了电子钱包。

* * *

### Game Center

这个iOS4引入的东东一直不是很好用，iOS6里Apple终于对这个体系进行了一些升级。简单说就是完善了一些功能，主要是联机对战匹配的东西，不过我依然不看好…想当时写小熊对战的时候曾经想使用GameCenter的匹配系统来写，结果各种匹配和网络的悲剧，导致白白浪费了一个月时间。而像水果忍者这类的游戏，使用了GameCenter的对战系统，但是也面临经常性的掉线之类的问题，可以说游戏体验是大打折扣的。虽然iOS6里新加了一些特性，但是整个机制和基本没有改变，因此我依旧不看好Game Center的表现(或者说是在中国的表现，如果什么时候Apple能在中国架GameCenter的服务器的话也许会有改善)。

不过值得注意的是，Mountain Lion里也加入了GameCenter。也就是说，我们在以后可能可以用iOS设备和Mac通过GameCenter进行联机对战，或者甚至是直接用Mac和Mac进行联机对战。这对于没有自己服务器/自己不会写服务器后端/没有精力维护的个人开发者提供了很好的思路。使用GameCenter做一些简单的网络游戏并不是很难，而因为GameCenter的特性，这个成本也将会非常低。这也许会是以后的一个不错的方向～

* * *

### 提醒

自带的提醒应用得到了加强，Apple终于开放了向Reminder里添加东西和从中读取的API(Event Kit框架)，以及一套标准的用户界面。这个没太多好说的，To-Do类应用已经在AppStore泛滥成灾，无非是提供了一个反向向系统添加list的功能，但是专业To-Do类应用的其他功能相信Apple现在不会以后也不想去替代。

* * *

### 新的IAP

IAP（应用内购买）现在能直接从iTunes Store购买音乐了。这配合iTunes Match什么的用很不错，但是和天朝用户无关…首先是iTunes Store在天朝不开，其次是要是我朝用户什么时候具有买正版音乐的意识的话，我们这些开发者可能就要笑惨了。

* * *

### Collection Views

不得不说Apple很无耻(或者说很聪明)。"会抄袭的艺术家是好的艺术家，会剽窃的艺术家是优秀的艺术家"这句话再次得到了诠释。基本新的UICollectionView实现了[PSCollectionView](https://github.com/ptshih/PSCollectionView)的功能，简单说就是类似Pinterest那样的"瀑布流"的展示方式。当然UICollectionView更灵活一些，可以根据要求变化排列的方式。嗯..Apple还很贴心地提供了相应的VC：UICollectionViewController。

可能这一套UI展现方式在iPhone上不太好用，但是在iPad上会很不错。不少照片展示之类的app可以用到.但是其实如果只是瀑布流的话估计短时间内大家还是会用开源代码，毕竟only for iOS6的话或多或少会减少用户的..

* * *

### UI状态保存

Apple希望用户关闭app，然后下一次打开时能保持关闭时的界面状态。对于支持后台且不被kill掉的app来说是天然的。但是如果不支持后台运行或者用户自己kill掉进程的话，就没那么简单了。现在的做法是从rootViewController开始把所有的VC归档后存成NSData，然后下次启动的时候做检查如果需要恢复的话就解压出来。

每次都要在appDelegate写这些代码的话，既繁杂又不优雅，于是Apple在iOS6里帮开发者做了这件脏活累活，还不错～其实机理应该没变，就是把这些代码放到app启动里去做了..

* * *

### 隐私控制

自从之前Apple被爆隐私门以后，就对这个比较重视了。现在除了位置信息以外，联系人、日历、提醒和照片的访问也强制需求用户的允许了。对普通开发者影响不大，因为如果确实需要的话用户一定会理解，但是可能对于360之流的流氓公司会造成冲击吧，对此只要呵呵就好了..= =？

* * *

### 其他一些值得一提的改动

*   整个UIView都支持NSAttributedString的格式化字符串了。特别是UITextView和UITextField～(再次抄袭开源社区，Apple你又赢了)
*   UIImage现在多了一个新方法，可以在生成UIImage对象时指定scale。为retina iPad开发的童鞋们解脱了..
*   NSUUID，用这个类现在可以很方便的创建一个uuid了.注意这个是uuid，不要和udid弄混了…Apple承诺的udid解决方案貌似还没出现..~~~现在要拿udid的话还是用[OpenUDID](https://github.com/ylechelle/OpenUDID)吧～~~~OpenUDID已死，udid暂时无解，请乖乖使用广告vendor id；或者将一个uuid存入keychain可以在大多数情况下替代udid（onevcat与2013.09.01更新）

* * *

按照以往WWDC的惯例，之后几天的开发者Session会对这些变化以及之前就存在在iOS里的一些issues和tips做解释和交流。在session公布之后我会挑选一些自己感兴趣并且可能比较实用的部分再进行整理～尽情期待～
