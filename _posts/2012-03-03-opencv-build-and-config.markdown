---
layout: post
title: OpenCV 在 iOS 开发环境下的编译和配置
date: 2012-03-03 23:06:23.000000000 +09:00
tags: 能工巧匠集
---

转载本文请保留以下原作者信息:

原作：OneV's Den [http://www.onevcat.com/2012/03/opencv-build-and-config/](http://www.onevcat.com/2012/03/opencv-build-and-config/)

## 2014.5.3 更新

现在一般都直接使用方便的 CocoaPods 来进行依赖管理了，特别是对于像 OpenCV 这样关系复杂的类库来说尤为如此。可以访问 [CocoaPods 的页面](http://cocoapods.org)并搜索 OpenCV 找到相关的 pod 信息就可以进行简单的导入了。如果您还不会或者没有开始使用 CocoaPods 的话，现在正是时候学习并实践了！

---

最近在写一个自己的app，用到一些图像识别和处理的东西。研究后发现用OpenCV是最为方便省事的，但是为iOS开发环境编译和配置OpenCV的库还是需要费点功夫，网上资料也并不是很全，而且有不少已经过期。在此进行一些总结，算是留底，也希望能对其他人有所帮助。

OpenCV (Open Source Computer Vision Library) 是跨平台的开源项目，由一系列C函数和少量C++类构成，提供了图像处理和计算机视觉方面很多通用的算法。在开发有关图像识别和处理的app的时候，OpenCV提供了一系列易用轻量的API，而且遵循BSD License。

## OpenCV For iOS一键编译

OpenCV用在iOS上，一般是以静态库的方式提供服务的，因此需要先将源码进行编译。如果你想省事，这里有一个我预先编译好的库，可以直接使用（OpenCV版本为2.3，虽然文件名字有part1，但是只有这一个包，开袋即食），如果需要最新版本的OpenCV，可以选择自行编译。

先从OpenCV的repository下载最新的OpenCV

```
svn co https://code.ros.org/svn/opencv/trunk
```

这里包含了源码和所有范例教程等，有1G多，小水管需谨慎。如果只想下载源码的话，可以从这里check out

```
svn co https://code.ros.org/svn/opencv/trunk/opencv
```

如果之前有check out过，那么用svn update进行更新即可拿到最新版的源码，或者到[sourceforge进行下载](http://sourceforge.net/projects/opencvlibrary/)。

由于darwin没有内置CMake，因此在编译前需要下载并安装CMake，在CMake的官网可以找到下载。
Eugene Khvedchenya写了一个超级棒的脚本，可以在这里找到下载，或者这里有一个本地的副本(不再更新)。将下载的脚本放到trunk目录中，运行

```
sh BuildOpenCV.sh opencv/ opencv_ios_build
```
数分钟后即可在opencv_ios_build目录下找到头文件和编译好的静态库。

如果是从官方库签出的OpenCV并且不怕麻烦的话，也可以使用官方的脚本完成编译，具体可以参看下载的`/opencv/ios/readme.txt`文件。

## OpenCV的库配置

和其他静态库的配置基本一致，以Xcode4为例。

* 将编译好的opencv文件夹拖入工程中，记得勾选Copy items into destination group’s folder (if needed)

![](http://www.onevcat.com/wp-content/uploads/2012/03/Xcode-1.jpg)

* 在Build Settings的Header Search Paths和Library Search Paths中填入相应的头文件位置和库文件位置，并将Always Search User Paths勾为Yes

![](http://www.onevcat.com/wp-content/uploads/2012/03/Xcode-2.jpg)

![](http://www.onevcat.com/wp-content/uploads/2012/03/Xcode-3.jpg)

* 在Build Phases中的Link Binary Libraries中添加用到的库文件即可 

## 编译脚本

编译OpenCV的脚本如下，请不要直接复制粘贴该脚本，可能某些符号会在字符转换过程中出现问题。可以访问这里下载该脚本的最新版本，或者[点击这里](http://www.onevcat.com/wp-content/uploads/2012/03/BuildOpenCV.sh_.zip)取得脚本的副本。
