---
layout: post
title: MGTwitterEngine中Twitter API 1.1的使用
date: 2013-03-24 00:34:48.000000000 +09:00
tags: 能工巧匠集
---
在iOS5中使用Twitter framework或者在iOS6中使用Social framework来完成Twitter的集成是非常简单和轻松的，但是如果应用要针对iOS5之前的系统版本，那么就不能使用iOS提供的框架了。一个比较常见也是使用最广泛的选择是[MGTwitterEngine](https://github.com/mattgemmell/MGTwitterEngine)，比如[PomodoroDo](http://www.onevcat.com/showcase/pomodoro_do/)选择使用的就是该框架。

但是今天在对PomodoroDo作更新的时候，发现Twitter的分享无法使用了，在查阅Twitter文档说明之后，发现这是Twitter采用了新版API的原因。默认状况下MGTwitterEngine采用的是v1版的API，并且使用XML的版本进行请求，而在1.1中，将[只有JSON方式的API可以使用](https://dev.twitter.com/docs/api/1.1/overview#JSON_support_only)。v1.0版本的API已经于2013年3月5日被完全废弃，因此想要继续使用MGTwitterEngine来适配iOS5之前的Twitter集成需求，就需要将MGTwitterEngine的请求改为JSON方式。MGTwitterEngine也考虑到了这一点，但是因为时间比较古老了，MGTwitterEngine使用了YAJL来作为JSON的Wrapper，因此还需要将YAJL集成进来。下午的时候尝试了一会儿，成功地让MGTwitterEngine用上了1.1的Twitter API，为了以防之后别人或是自己可能遇到同样的问题，将更新的方法在此留底备忘。 

1. 导入YAJL Framework 
	* YAJL的OC实现，从[该地址下载该框架](https://github.com/gabriel/yajl-objc/download)。(2013年3月24日的最新版本为YAJL 0.3.1 for iOS)
	* 解压下载得到的zip，将解压后的YAJLiOS.framework加入项目工程
	* 在Xcode的Build Setting里在Other Linker Flags中添加-ObjC和-all_load标记

2. 加入MGTwitterEngine的JSON相关代码 
	* 从[MGTwitterEngine的页面](https://github.com/mattgemmell/MGTwitterEngine)down下该项目。当然如果有新版或者有别的branch可以用的话更省事儿，但是鉴于MGTwitterEngine现在的活跃度来说估计可能性不大，所以还是乖乖自己更新吧。
    * 解开下载的zip，用Xcode打开MGTwitterEngine.xcodeproj工程文件，将其中Twitter YAJL Parsers组下的所有文件copy到自己的项目中。

3. YAJL头文件集成 
	* 接下来是C和OC接口头文件的导入，从下面下载YAJL库：[https://github.com/thinglabs/yajl-objc](https://github.com/thinglabs/yajl-objc)
	* 在下载得到的文件夹中，寻找并将以下h文件拷贝到自己的工程中： 
		* yajl_common.h
		* yajl_gen.h
		* yajl_parse.h
		* NSObject+YAJL.h
		* YAJL.h
		* YAJLDocument.h
		* YAJLGen.h
		* YAJLParser.h

4. 最后是在MGTwitterEngine设定为使用v1.1 API以及JSON方式请求 

在MGTwitterEngine.m中，将对应代码修改为以下：
	
```objc
#define USE_LIBXML 0
#define TWITTER_DOMAIN @"api.twitter.com/1.1"
```
	
在MGbTwitader.h，启用YAJL 
    
```objc
#define define YAJL_AVAILABLE 1
```

本文参考：


[MGTwitterEngine issues 107](https://github.com/mattgemmell/MGTwitterEngine/issues/107)

[http://damienh.org/2009/06/20/setting-up-mgtwitterengine-with-yajl-106-for-iphone-development/](http://damienh.org/2009/06/20/setting-up-mgtwitterengine-with-yajl-106-for-iphone-development/)
