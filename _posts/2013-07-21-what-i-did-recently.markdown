---
layout: post
title: 近期做的两三事
date: 2013-07-21 00:53:10.000000000 +09:00
tags: 胡言乱语集
---
夏日炎炎，无心睡眠。

虽然已经有一段时间没有更新博客了，但是我确实是一直在努力干活儿的。这一个月以来大部分视线都在WWDC上，也写了几篇博文介绍个人觉得iOS7中需要深入挖掘和研究的API。但是因为NDA加上现在人在国外的缘故，还是不太好肆无忌惮地发出来。等到iOS7和Xcode5的NDA结束的时候（大概是9月中旬吧），我会一并把写的WWDC2013的笔记发出来，到时候还要请大家多多捧场。

另外在工作之外，也自己做了一些小项目，基本都是一些个人兴趣所致。虽然不值一提，但是还是想写下来主要作为记录。另外如果恰好能帮助到两三个同仁的话，那是最好不过。

### 一个Xcode插件，VVDocumenter

虽然ObjC代码因为其可读性极强，而不太需要时常查阅文档，但是其实对于大多数人（包括我自己）来说，可能为方法或变量取一个好名字并不是那么简单的事情。这时候可能就需要文档或者注释来帮助之后的开发者（包括大家自己）尽快熟悉和方便修改。但是用Xcode写文档是一件让人很头疼的事情，没有像VS之类的成熟IDE的方便的方法，一直以来都是依靠像Snippet这样的东西，然后自己辛苦填写大量已有的内容。


之前看到一个用[Ruby+系统服务来生成注释的方案](http://blog.chukong-inc.com/index.php/2012/05/16/xcode4_fast_doxygen/)，但是每次要自己去选还要按快捷键，总觉得是很麻烦的事情。借鉴其他平台IDE一般都是采用三个斜杠（`///`）来生成文档注释的方法，所以也为Xcode写了一个类似的。用法很简单，在要写文档的代码上面连打三个斜杠，就能自动提取参数等生成规范的Javadoc格式文档注释。**VVDocumenter**整个项目MIT开源，并且扔在github上了，有兴趣的童鞋可以[在这里](https://github.com/onevcat/VVDocumenter-Xcode)找到，欢迎大家加星fork以及给我发pull request来改善这个插件。

![VVDocumenter演示](https://raw.github.com/onevcat/VVDocumenter-Xcode/master/ScreenShot.gif)

### 一个Unity插件，UniRate

做了一个叫**UniRate**的Unity插件，可以完全解决Unity移动端游戏请求用户评价的需求。对于一款应用/游戏来说，一般都会在你使用若干次/天之后弹一个邀请你评价的窗口，你可以选择是否到AppStore/Android Market进行评价或者稍后提醒。分别在iOS或者Android中实现这样的功能可以说是小菜一碟，但是Unity里现在暂时没有很好的方案。很可能你会需要花不少时间来实现一个类似功能，又或者要是你对native plugin这方面不太熟悉的话，可能就比较头疼了。

现在可以用UniRate来解决，添加的方法很简单，导入资源包，将里面的UniRateManager拖拽到scene中，就可以了..是的..没有第三步，这时候你已经有一个会监测用户使用并在安装3天并且使用10次后弹出一个提示评价的框，用户可以选择评价并跳转到相应页面了。如果你想做更多细节的调整和控制，可以参看这里的[用户手册](https://github.com/onevcat/UniRate/wiki/UniRate-Manual)和[在线文档](http://unirate.onevcat.com/reference/class_uni_rate.html)。

![UniRate](/assets/images/2013/UniRate.jpg)

如果你感兴趣并且希望支持一下的话，UniRate现在可以在Unity Asset Store购买，[传送门在这里](https://www.assetstore.unity3d.com/#/content/10116)。

### Oculus VR Rift

如果你不知道Oculus的话，这里有张我的近照可以帮助你了解。

![我的Oculus Rift](/assets/images/2013/oculus-me.png)

其实就是一个虚拟现实用的眼镜，可以直接在眼前塞满屏幕的设备。之前也有索尼之类的厂家出过类似的眼镜，但是Oculus最大的特点是全屏无黑边，可以说提供了和以往完全不同的沉浸式游戏体验。难能可贵的是，在此同时还能做到价格厚道（坊间传闻今后希望能做到本体免费）。

回到主题，自从体验过Oculus VR Rift以后，我就相信这会是游戏的未来和方向。于是之前就下了订单预定了开发者版本，今天总算是到货。Oculus对于我来说最大的优点是支持Unity3D，所以自己可以用它来做一些好玩儿的东西，算是门槛比较低。相信之后会有一段时间来学习适配Oculus的Unity开发，并且每天沉浸在创造自娱自乐的虚拟现实之中，希望这段时光能成为自己之后美好的回忆。我在之后也会找机会在博客里分享一些关于Unity和Oculus集成，以及开发Oculus适配的游戏的一些经验和方法。

**如果有可能的话，真希望自己能够做一款好玩的Oculus的游戏，或者找到一个做Oculus游戏的企业，去创造这个未来，改变世界。**

### XUPorter更新

[XUPorter](https://github.com/onevcat/XUPorter)最早是写出来自己用的。因为每次从Unity build工程出来的时候，在Xcode里把各种依赖库拖来拖去简直是一件泯灭人性的事情。两年多前刚开始Unity的时候没有post build script这种东西，于是每次都要花上五到十分钟来配置Xcode的工程，时间一长就直接忘了需要依赖哪些文件和框架才能编译通过。后来有个post build脚本，但是每次写起来也很麻烦。XUPorter利用Unity3.5新加入的`PostProcessBuild`来根据配置修改Xcode工程文件，具体的介绍可以[看这里](http://onevcat.com/2012/12/xuporter/)。之前就是往Github上一扔而已，很高兴的是，有一些项目开始使用XUPorter做管理了，也有热心人在Github上帮助维护这个项目。于是最近对其进行了一些更新，添加了第三方库的添加等一些功能。

如果有需要的朋友可以了解一下并使用，可以节省不少时间。如果觉得好，也欢迎帮助推荐和支持，让更多人知道并受益。最简单的方法就是在[项目的Github页面](https://github.com/onevcat/XUPorter)加个星星～ :)
