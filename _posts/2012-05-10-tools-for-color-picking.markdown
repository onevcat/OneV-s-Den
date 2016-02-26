---
layout: post
title: 颜色选取和转换小工具
date: 2012-05-10 23:26:12.000000000 +09:00
tags: 能工巧匠集
---

iOS的app中，交互设计永远是重点中的重点，为用户界面选择合适的配色方法不仅对app整体美观有重要意义，同时也对用户体验的提升至关重要。但是在iOS开发中对于颜色的选取，转换和设定并不十分方便。通过配合使用下面的小工具可以提升颜色选取和转换的效率～

#### 颜色选择器

颜色选取不论在网页开发还是应用开发中都很常见。Mac虽然自带的颜色选择器，但是它并不单独存在，想要选取一个屏幕上的颜色，往往需要打开另外一些臃肿的应用。ColorPicker通过脚本做到只单独打开颜色选择器，从而快速地完成颜色选取工作。有关ColorPicker的详细信息可以参看[这里](http://www.robinwood.com/Catalog/Technical/OtherTuts/MacColorPicker/MacColorPicker.html#colorPickerApp)，下载[这个zip包](http://www.robinwood.com/Catalog/Technical/OtherTuts/MacColorPicker/ColorPicker.zip)，就可以将颜色选择器当做一个普通的Mac应用来使用了～

![](http://www.onevcat.com/wp-content/uploads/2012/05/tumblr_m3nr5xlftS1qd122y.png)

#### 16进制颜色选择器

由于大部分时候需要使用代码控制颜色，因此需要知道选取的颜色的十六进制或者RGB表示，以方便代码使用。[这里](http://wafflesoftware.net/hexpicker/)提供了一个插件，可以在系统的颜色选择面板上显示当前颜色的十六进制编码，恰好满足了要求～

![](http://www.onevcat.com/wp-content/uploads/2012/05/tumblr_m3nrcq9O4p1qd122y.png)

下载[这个zip包](http://wafflesoftware.net/hexpicker/download/1.6.1/)，将包里的HexColorPicker.colorPicker解压到至文件夹 [homefolder]/Library/ColorPickers/ 下(如果不存在的话需要手动创建)即可。再打开系统的颜色选择器时，可以看到标签栏最右边多了一个#符号，点击即可看到当前颜色的十六进制值。

#### 还没结束呢..

据我所知，Cocoa里貌似没有直接通过颜色十六进制字串生成颜色对象的方法..所以可能还需要一点小转换。这个很简单，只是一个十六进制换算而已～

```
UIColor* UIColorFromHex(NSInteger colorInHex) {
    // colorInHex should be value like 0xFFFFFF
    return [UIColor colorWithRed:((float) ((colorInHex & 0xFF0000) >> 16)) / 0xFF
                           green:((float) ((colorInHex & 0xFF00)   >> 8))  / 0xFF 
                            blue:((float)  (colorInHex & 0xFF))            / 0xFF
                           alpha:1.0];
}
```
