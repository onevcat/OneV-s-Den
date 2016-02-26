---
layout: post
title: 符合iOS系统兼容性需求的方法
date: 2012-02-25 22:54:42.000000000 +09:00
tags: 能工巧匠集
---
<a href="http://www.onevcat.com/wp-content/uploads/2012/02/ios.jpg"><img class="aligncenter size-full wp-image-673" title="ios" src="http://www.onevcat.com/wp-content/uploads/2012/02/ios.jpg" alt=""/></a>

转载本文请保留以下原作者信息:
原作：OneV's Den
<a href="http://www.onevcat.com/2012/02/iosversion/">http://www.onevcat.com/2012/02/iosversion/</a>
<h2>兼容性，开发者之殇</h2>
兼容性问题是全世界所有开发这面临的最头疼的问题之一，这句话不会有开发者会反驳。往昔的Windows Vista的升级死掉一批应用的惨状历历在目，而如今火热的移动互联网平台上类似的问题也层出不穷。Andriod的开源导致产商繁多，不同的设备不仅硬件配置有差异，系统有差异，就连屏幕比例也有差异。想要开发出一款真正全Android平台都完美运行的app简直是不可能的..
iOS好很多，因为iPhone和iTouch的分辨率完全一致(就算retina也有Apple帮你打理好了)，因此需要关注的往往只有系统版本的差别。<strong>在使用到某些新系统才有的特性，或者被废弃的方法时，都需要对运行环境做出判定。</strong>

<h2>何时需要照顾兼容性</h2>
没有人可以记住所有系统新加入的类或者属性方法，也没有人可以开发出一款能针对全系统的还amazing的应用。

<strong>在iOS的话，首先要做的就是为自己所开发的app选择合适的最低版本</strong>，在XCode中的对应app的target属性中，设置iOS Deployment Target属性，这对应着你的app将会运行在的最低的系统版本。如果你设成iOS 4.3的话，那你就不需要考虑代码对4.3之前的系统的兼容性了——因为低于iOS 4.3的设备是无法通过正规渠道安装你的应用的。

<!--:--><!--more--><!--:zh-->
但是你仍然要考虑在此之后的系统的兼容性。随着Apple不断升级系统，有些功能或者特性在新系统版本上会有很容易很高效的实现方法，有些旧的API被废弃或者删除。如果没有对这些可能存在的兼容性问题做出处理的话，小则程序效率低下，之后难以维护，大则直接crash。对于这些可能存在的问题，开发者一定要明确自己所调用的API是否存在于所用的框架中。某个类或者方法所支持的系统版本可以在官方文档中查到，所有的条目都会有类似这样的说明
<pre>Availability Available in iOS 5.0 and later.</pre>
或者
<pre>Availability Available in iOS 2.1 and later. </pre>

Deprecated in iOS 5.0.
从Availability即可得知版本兼容的信息。
如果iOS Deployment Target要小于系统要求，则需要另写处理代码，否则所使用的特性在老版本的系统上将无法表现。

另外，Apple也不过是一家公司，Apple的开发人员也不过是牛一点的程序员，iOS本身就有可能有某些bug，导致在某些版本上存在瑕疵。开发人员会很care，并尽快修正，但是很多时候用户并不care，或者由于种种原因一直不升级系统。这时候便需要检测系统，去避开这些bug，以增加用户体验了(比如3.0时的UITableView插入行时可能crash)。


<h2>符合兼容性需求的代码</h2>
<h3>判定系统版本，按运行时的版本号运行代码</h3>
这不一定是最有效的方法，但这是最直接的方法。对系统版本的判定可以参考我的另一片文章:<a href="http://www.onevcat.com/2012/02/uiviewcontroller/">UIViewController的误用</a>。
顺便在这边也把比较的方法贴出来：

```
// System Versioning Preprocessor Macros

#define SYSTEM_VERSION_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
```

使用
···
if (SYSTEM_VERSION_LESS_THAN(@“5.0”))
{
    //系统版本不小于5.0...Do something
}
···

需要注意的是，`[@“5.0” compare:@“5” options:NSNumericSearch]`这样的输入将会返回一个NSOrderedDescending，而不是期望中的NSOrderedSame，因此在输入的时候需要特别小心。另外这个方法的局限还在于对于4.1.3这样的系统版本号比较无力，想要使用的话也许需要自己进行转换(也许去掉第二个小数点再进行比较是个可行的方案)。

<h3>对于类，可以检测其是否存在</h3>
如果要使用的新特性是个类，而不是某个特定的方法的话，可以用NSClassFromString来将字符串转为类，如果runtime没有这个类的存在，该方法将返回nil。比如对于iOS 5，在位置解析方面，Apple使用了CoreLocation中的新类CLGeocoder来替代原来的MKReverseGeocoder，要判定使用哪个类，可以用下面的代码：

```
if(NSClassFromString(@"CLGeocoder")) {
    //CLGeocoder存在，可以使用
}
else{
    //只能使用MKReverseGeocoder
}
```

这个方法应该是绝对靠谱的，但是只有类能够使用。而系统更新往往带来的不止类，也有很多新的方法和属性这样的东西，这个方式就无能为力了。

<h3>向特定的类或对象询问是否拥有某特性</h3>

对于某些类活期成员，他们本身有类似询问支不支持某种特性这样的方法，比如大家所熟知的UIImagePickerController里检测可用媒体类型的availableMediaTypesForSourceType:方法，以及CMMotionManager里检测三轴陀螺是否可用的方法gyroAvailable。但是有些类询问方法的类和成员所要使用的特性基本基本都是和设备硬件有关的。

另外当然也可以用respondsToSelector:方法来检测是否对某个方法响应。但是<strong>这是非常危险的做法</strong>，我本人不推荐使用。因为iOS系统里存在很多私有API，而Apple的审查机制对于私有API调用的格杀勿论是业界公知的。而respondsToSelector:如果想要检测的方法在老版本的系统中是作为私有API形式存在的话，你将得到错误的结果，从而去执行私有API，那就完了。这种应用往往是被拒了都不知道自己在哪儿使用了私有API…
