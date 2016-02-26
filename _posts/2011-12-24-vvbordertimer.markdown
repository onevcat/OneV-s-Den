---
layout: post
title: VVBorderTimer
date: 2011-12-24 22:04:43.000000000 +09:00
tags: 能工巧匠集
---
GitHub 链接: [https://github.com/onevcat/VVBorderTimerView](https://github.com/onevcat/VVBorderTimerView)

### 是什么

* **VVBorderTimer**是UIView的子类
* 它为UIView提供使用边界进行倒计时的效果
* 边框角落的半径和线宽在运行时可调
* 倒计时是有颜色渐变效果

### What’s this

* **VVBorderTimer** is a subclass of UIView.
* It provides an counting down effect using the view’s border.
* The radius of round corners and line width are configurable in runtime.
* There is also a color transition effect during the counting.

### 怎么用

* 将VVBorderTimerView.h和VVBorderTimerView.m导入您的工程。请根据您的情况选择使用ARC版本或非ARC版本
* 分配并初始化一个VVBorderTimerView. 设置其背景颜色
``` 
VVBorderTimerView *btv = [[VVBorderTimerView alloc] initWithFrame:CGRectMake(20, 20, 280, 280)];
//为计时器设置背景颜色
btv.backgroundColor = [UIColor clearColor];
``` 
3. 配置计时器属性，如: 颜色(可选), 总时间和delegate.
``` 
//上边界为绿色
UIColor *color0 = [UIColor greenColor];
//右边黄色
UIColor *color1 = [UIColor yellowColor];
//下边橙色
UIColor *color2 = [UIColor colorWithRed:1.0 green:140.0/255.0 blue:16.0/255.0 alpha:1.0];
//左边红色
UIColor *color3 = [UIColor redColor];
//为计时器指定颜色. 不同颜色将在转角处发生渐变.
//如果您没有指定颜色，或者指定其为nil(btv.colors = nil)，所有边将默认使用黑色
btv.colors = [NSArray arrayWithObjects:color0,color1,color2,color3,nil];
//为计时器设定总时间
btv.totalTime = 10;
//为计时器设定delegate
btv.delegate = self;
``` 
4. 实现计时器的delegate
``` 
//转角半径(0 代表矩形)
-(float) cornerRadius:(VVBorderTimerView *)requestor
{ return 30;
}
//计时器线宽
-(float) lineWidth:(VVBorderTimerView *)requestor
{ return 10;
}
//当计时器停止时，该方法被调用
-(void) timerViewDidFinishedTiming:(VVBorderTimerView *)aTimerView
{ //do something
}
``` 
5. 将计时器加入您的viewController的view，并使用 -(void)start 开始计时
``` 
[self.view addSubview:btv];
[btv start];
``` 

如果您使用的是非ARC，请不要忘记在将计时器加入view结构后释放它。可能您需要保留一个指向该计时器的指针，以便在即使结束后将其移除
在GitHub网站的这个页面上有一个简单的demo供您参考，如果您感兴趣，可以关注或者分支该项目。祝您好运～

### How to use

1. Import VVBorderTimerView.h and VVBorderTimerView.m to your project. Select either ARC version or non-ARC version for your situation.
2. Alloc and init a VVBorderTimerView. Set its background color.
``` 
VVBorderTimerView *btv = [[VVBorderTimerView alloc] initWithFrame:CGRectMake(20, 20, 280, 280)];
//Specify a background color for the timer
btv.backgroundColor = [UIColor clearColor];
``` 
3. Set the properties for the timer: colors(optional), totalTime and delegate.
``` 
//Top border will be green
UIColor *color0 = [UIColor greenColor];
//Right border yellow
UIColor *color1 = [UIColor yellowColor];
//Buttom border orange
UIColor *color2 = [UIColor colorWithRed:1.0 green:140.0/255.0 blue:16.0/255.0 alpha:1.0];
//Left border red
UIColor *color3 = [UIColor redColor];
//Set the colors for the timer. Color transition will be occured in the corner.
//If your DID NOT specify the colors or specify it to nil(btv.colors = nil), default black color for all edge will be used.
btv.colors = [NSArray arrayWithObjects:color0,color1,color2,color3,nil];
//Set the total time the timer should count in second
btv.totalTime = 10;
//Set the delegate for the timer
btv.delegate = self;
``` 
4. Implement the timer’s delegate
``` 
//Corner radius for a timer(0 means rectangle)
-(float) cornerRadius:(VVBorderTimerView *)requestor
{ return 30;
}
//Line width for a timer
-(float) lineWidth:(VVBorderTimerView *)requestor
{ return 10;
}
//When the timer stopped, this method will be called
-(void) timerViewDidFinishedTiming:(VVBorderTimerView *)aTimerView
{ //do something
}
``` 
5. Add it to your viewController’s view and then start the timer using -(void)start
``` 
[self.view addSubview:btv];
[btv start];
``` 

DO NOT forget to release the timer after it is added to the view’s hierarchy if you use non-ARC. You may want to keey a pointer to the timer, so you can remove it from superview when it stops.
You can also find a demo in the github page here. You can watch and fork it if you are intrested in it. Enjoy!

### Lisence
VVBorderTimer is Copyright © 2011 Wei Wang(onevcat), All Rights Reserved, All Wrongs Revenged. Released under the New BSD Licence.
* https://github.com/onevcat/VVBorderTimerView/
BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
Copyright (c) 2011 Wei Wang(onevcat) All Rights Reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBU -TORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
