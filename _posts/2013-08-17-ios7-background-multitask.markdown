---
layout: post
title: WWDC 2013 Session笔记 - iOS7中的多任务
date: 2013-08-17 00:56:02.000000000 +09:00
tags: 能工巧匠集
---

![iOS7的后台多任务特性](/assets/images/2013/ios7-multitasking.jpg)

这是我的WWDC2013系列笔记中的一篇，完整的笔记列表请参看[这篇总览](http://onevcat.com/2013/06/developer-should-know-about-ios7/)。本文仅作为个人记录使用，也欢迎在[许可协议](http://creativecommons.org/licenses/by-nc/3.0/deed.zh)范围内转载或使用，但是还烦请保留原文链接，谢谢您的理解合作。如果您觉得本站对您能有帮助，您可以使用[RSS](http://onevcat.com/atom.xml)或[邮件](http://eepurl.com/wNSkj)方式订阅本站，这样您将能在第一时间获取本站信息。

本文涉及到的WWDC2013 Session有

* Session 204 What's New with Multitasking
* Session 705 What’s New in Foundation Networking

## iOS7以前的Multitasking

iOS的多任务是在iOS4的时候被引入的，在此之前iOS的app都是按下Home键就被干掉了。iOS4虽然引入了后台和多任务，但是实际上是伪多任务，一般的app后台并不能执行自己的代码，只有少数几类服务在通过注册后可以真正在后台运行，并且在提交到AppStore的时候也会被严格审核是否有越权行为，这种限制主要是出于对于设备的续航和安全两方面进行的考虑。之后经过iOS5和6的逐渐发展，后台能运行的服务的种类虽然出现了增加，但是iOS后台的本质并没有变化。在iOS7之前，系统所接受的应用多任务可以大致分为几种：

* 后台完成某些花费时间的特定任务
* 后台播放音乐等
* 位置服务
* IP电话（VoIP）
* Newsstand

在WWDC 2013的keynote上，iOS7的后台多任务改进被专门拿出来向开发者进行了介绍，到底iOS7里多任务方面有什么新的特性可以利用，如何使用呢？简单来说，iOS7在后台特性方面有很大改进，不仅改变了以往的一些后台任务处理方式，还加入了全新的后台模式，本文将针对iOS7中新的后台特性进行一些学习和记录。大体来说，iOS7后台的变化在于以下四点：

* 改变了后台任务的运行方式
* 增加了后台获取（Background Fetch）
* 增加了推送唤醒（静默推送，Silent Remote Notifications）
* 增加了后台传输（￼Background Transfer Service）

<!--more-->

## iOS7的多任务

### 后台任务

首先看看后台任务的变化，先说这方面的改变，而不是直接介绍新的API，是因为这个改变很典型地代表了iOS7在后台任务管理和能耗控制上的大体思路。从上古时期开始（其实也就4.0），UIApplication提供了`-beginBackgroundTaskWithExpirationHandler:`方法来使app在被切到后台后仍然能保持运行一段时间，app可以用这个方法来确保一些很重很慢的工作可以在急不可耐的用户将你的应用扔到后台后还能完成，比如编码视频，上传下载某些重要文件或者是完成某些数据库操作等，虽然时间不长，但在大多数情况下勉强够用。如果你之前没有使用过这个API的话，它使用起来大概是长这个样子的：

```objc
- (void) doUpdate

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [self beginBackgroundUpdateTask];

        NSURLResponse * response = nil;
        NSError  * error = nil;
        NSData * responseData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];

        // Do something with the result

        [self endBackgroundUpdateTask];
    });
}

- (void) beginBackgroundUpdateTask
{
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void) endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundUpdateTask];
    self.backgroundUpdateTask = UIBackgroundTaskInvalid;
}	
```

在`beginBackgroundTaskWithExpirationHandler:`里写一个超时处理（系统只给app分配了一定时间来进行后台任务，超时之前会调用这个block），然后进行开始进行后台任务处理，在任务结束或者过期的时候call一下`endBackgroundTask:`使之与begin方法配对（否则你的app在后台任务超时的时候会被杀掉）。同时，你可以使用UIApplication实例的backgroundTimeRemaining属性来获取剩余的后台执行时间。

具体的执行时间来说，在iOS6和之前的系统中，系统在用户退出应用后，如果应用正在执行后台任务的话，系统会保持活跃状态直到后台任务完成或者是超时以后，才会进入真正的低功耗休眠状态。

![iOS6之前的后台任务处理](/assets/images/2013/ios-multitask-ios6.png)

而在iOS7中，后台任务的处理方式发生了改变。系统将在用户锁屏后尽快让设备进入休眠状态，以节省电力，这时后台任务是被暂停的。之后在设备在特定时间进行系统应用的操作被唤醒（比如检查邮件或者接到来电等）时，之前暂停的后台任务将一起进行。就是说，系统不会专门为第三方的应用保持设备处于活动状态。如下图示

![iOS7的后台任务处理](/assets/images/2013/ios-multitask-ios7.png)

这个变化在不减少应用的后台任务时间长度的情况下，给设备带来了更多的休眠时间，从而延长了续航。对于开发者来说，这个改变更多的是系统层级的变化，对于非网络传输的任务来说，保持原来的用法即可，新系统将会按照新的唤醒方式进行处理；而对于原来在后台做网络传输的应用来说，苹果建议在iOS7中使用`NSURLSession`，创建后台的session并进行网络传输，这样可以很容易地利用更好的后台传输API，而不必受限于原来的时长，关于这个具体的我们一会儿再说。

### 后台获取（Background Fetch）

现在的应用无法在后台获取信息，比如社交类应用，用户一定需要在打开应用之后才能进行网络连接，获取新的消息条目，然后才能将新内容呈现给用户。说实话这个体验并不是很好，用户在打开应用后必定会有一段时间的等待，每次皆是如此。iOS7中新加入的后台获取就是用来解决这个不足的：后台获取干的事情就是在用户打开应用之前就使app有机会执行代码来获取数据，刷新UI。这样在用户打开应用的时候，最新的内容将已然呈现在用户眼前，而省去了所有的加载过程。想想看，没有加载的网络体验的世界，会是怎样一种感觉。这已经不是smooth，而是真的amazing了。

那具体应该怎么做呢？一步一步来：

#### 启用后台获取

首先是修改应用的Info.plist，在`UIBackgroundModes`中加入fetch，即可告诉系统应用需要后台获取的权限。另外一种更简单的方式，得益于Xcode5的Capabilities特性（参见可以参见我之前的一篇[WWDC2013笔记 Xcode5和ObjC新特性](http://onevcat.com/2013/06/new-in-xcode5-and-objc/)），现在甚至都不需要去手动修改Info.plist来进行添加了，打开Capabilities页面下的Background Modes选项，并勾选Background fetch选项即可（如下图）。

![在Capabilities中开启Background Modes](/assets/images/2013/ios7-multitask-background-fetch.png)

笔者写这篇文章的时候iOS7还没有上市，也没有相关的审核资料，所以不知道如果只是在这里打开了fetch选项，但却没有实现的话，应用会不会无法通过审核。但是依照苹果一贯的做法来看，如果声明了需要某项后台权限，但是结果却没有相关实现的话，被拒掉的可能性还是比较大的。因此大家尽量不要拿上线产品进行实验，而应当是在demo项目里研究明白以后再到上线产品中进行实装。

#### 设定获取间隔

对应用的UIApplication实例设置获取间隔，一般在应用启动的时候调用以下代码即可：

```objc
[[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
```

如果不对最小后台获取间隔进行设定的话，系统将使用默认值`UIApplicationBackgroundFetchIntervalNever`，也就是永远不进行后台获取。当然，`-setMinimumBackgroundFetchInterval:`方法接受的是NSTimeInterval，因此你也可以手动指定一个以秒为单位的最小获取间隔。需要注意的是，我们都已经知道iOS是一个非常霸道为我独尊的系统，因此自然也不可能让一介区区第三方应用来控制系统行为。这里所指定的时间间隔只是代表了“在上一次获取或者关闭应用之后，在这一段时间内一定不会去做后台获取”，而真正具体到什么时候会进行后台获取，那~~~完全是要看系统娘的心情的~~~我们是无从得知的。系统将根据你的设定，选择比如接收邮件的时候顺便为你的应用获取一下，或者也有可能专门为你的应用唤醒一下设备。作为开发者，我们应该做的是为用户的电池考虑，尽可能地选择合适自己应用的后台获取间隔。设置为UIApplicationBackgroundFetchIntervalMinimum的话，系统会尽可能多尽可能快地为你的应用进行后台获取，但是比如对于一个天气应用，可能对实时的数据并不会那么关心，就完全不必设置为UIApplicationBackgroundFetchIntervalMinimum，也许1小时会是一个更好的选择。新的Mac OSX 10.9上已经出现了功耗监测，用于让用户确定什么应用是能耗大户，有理由相信同样的东西也可能出现在iOS上。如果不想让用户因为你的应用是耗电大户而怒删的话，从现在开始注意一下应用的能耗还是蛮有必要的（做绿色环保低碳的iOS app，从今天开始～）。

#### 实现后台获取代码并通知系统

在完成了前两步后，只需要在AppDelegate里实现`-application:performFetchWithCompletionHandler:`就行了。系统将会在执行fetch的时候调用这个方法，然后开发者需要做的是在这个方法里完成获取的工作，然后刷新UI，并通知系统获取结束，以便系统尽快回到休眠状态。获取数据这是应用相关的内容，在此不做赘述，应用在前台能完成的工作在这里都能做，唯一的限制是系统不会给你很长时间来做fetch，一般会小于一分钟，而且fetch在绝大多数情况下将和别的应用共用网络连接。这些时间对于fetch一些简单数据来说是足够的了，比如微博的新条目（大图除外），接下来一小时的天气情况等。如果涉及到较大文件的传输的话，用后台获取的API就不合适了，而应该使用另一个新的文件传输的API，我们稍后再说。类似前面提到的后台任务完成时必须通知系统一样，在在获取完成后，也必须通知系统获取完成，方法是调用`-application:performFetchWithCompletionHandler:`的handler。这个CompletionHandler接收一个`UIBackgroundFetchResult`作为参数，可供选择的结果有`UIBackgroundFetchResultNewData`,`UIBackgroundFetchResultNoData`,`UIBackgroundFetchResultFailed`三种，分别表示获取到了新数据（此时系统将对现在的UI状态截图并更新App Switcher中你的应用的截屏），没有新数据，以及获取失败。写一个简单的例子吧：

```objc
//File: YourAppDelegate.m
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    UINavigationController *navigationController = (UINavigationController*)self.window.rootViewController;
    
    id fetchViewController = navigationController.topViewController;
    if ([fetchViewController respondsToSelector:@selector(fetchDataResult:)]) {
        [fetchViewController fetchDataResult:^(NSError *error, NSArray *results){
            if (!error) {
        	    if (results.count != 0) {
        		    //Update UI with results.
        		    //Tell system all done.
        		    completionHandler(UIBackgroundFetchResultNewData);
        	    } else {
        			completionHandler(UIBackgroundFetchResultNoData);
        	    }
            } else {
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }];
    } else {
        completionHandler(UIBackgroundFetchResultFailed);
    }
}
```

当然，实际情况中会比这要复杂得多，用户当前的ViewController是否合适做获取，获取后的数据如何处理都需要考虑。另外要说明的是上面的代码在获取成功后直接在appDelegate里更新UI，这只是为了能在同一处进行说明，但却是不正确的结构。比较好的做法是将获取和更新UI的业务逻辑都放到fetchViewController里，然后向其发送获取消息的时候将completionHandler作为参数传入，并在fetchViewController里完成获取结束的报告。

另一个比较神奇的地方是系统将追踪用户的使用习惯，并根据对每个应用的使用时刻给一个合理的fetch时间。比如系统将记录你在每天早上9点上班的电车上，中午12点半吃饭时，以及22点睡觉前会刷一下微博，只要这个习惯持续个三四天，系统便会将应用的后台获取时刻调节为9点，12点和22点前一点。这样在每次你打开应用都直接有最新内容的同时，也节省了电量和流量。

#### 后台获取的调试

既然是系统决定的fetch，那我们要如何测试写的代码呢？难道是将应用退到后台，然后安心等待系统进行后台获取么？当然不是...Xcode5为我们提供了两种方法来测试后台获取的代码。一种是从后台获取中启动应用，另一种是当应用在后台时模拟一次后台推送。

对于前者，我们可以新建一个Scheme来专门调试从后台启动。点击Xcode5的Product->Scheme->Edit Scheme(或者直接使用快捷键`⌘<`)。在编辑Scheme的窗口中点Duplicate Scheme按钮复制一个当前方案，然后在新Scheme的option中将Background Fetch打上勾。从这个Scheme来运行应用的时候，应用将不会直接启动切入前台，而是调用后台获取部分代码并更新UI，这样再点击图标进入应用时，你应该可以看到最新的数据和更新好的UI了。

![更改Scheme的选项为从后台获取事件中启动](/assets/images/2013/ios7-back-fetch-scheme.png)

另一种是当应用在后台时，模拟一次后台获取。这个比较简单，在app调试运行时，点击Xcode5的Debug菜单中的Simulate Background Fetch，即可模拟完成一次获取调用。

### 推送唤醒（Remote Notifications）

远程推送（￼￼Remote Push Notifications）可以说是增加用户留存率的不二法则，在iOS6和之前，推送的类型是很单一的，无非就是显示标题内容，指定声音等。用户通过解锁进入你的应用后，appDelegate中通过推送打开应用的回调将被调用，然后你再获取数据，进行显示。这和没有后台获取时的打开应用后再获取数据刷新的问题是一样的。在iOS7中这个行为发生了一些改变，我们有机会使设备在接收到远端推送后让系统唤醒设备和我们的后台应用，并先执行一段代码来准备数据和UI，然后再提示用户有推送。这时用户如果解锁设备进入应用后将不会再有任何加载过程，新的内容将直接得到呈现。

实装的方法和刚才的后台获取比较类似，还是一步步来：

#### 启用推送唤醒

和上面的后台获取类似，更改Info.plist，在`UIBackgroundModes`下加入`remote-notification`即可开启，当然同样的更简单直接的办法是使用Capabilities。

#### 更改推送的payload

在iOS7中，如果想要使用推送来唤醒应用运行代码的话，需要在payload中加入`content-available`，并设置为1。

```javascript
aps {
     content-available: 1
     alert: {...}
   }
```
￼￼
#### 实现推送唤醒代码并通知系统
最后在appDelegate中实现`￼-application:didReceiveRemoteNotification:fetchCompletionHandle:`。这部分内容和上面的后台获取部分完全一样，在此不再重复。
#### 一些限制和应用的例子
因为一旦推送成功，用户的设备将被唤醒，因此这类推送不可能不受到限制。Apple将限制此类推送的频率，当频率超过一定限制后，带有content-available标志的推送将会被阻塞，以保证用户设备不被频繁唤醒。按照Apple的说法，这个频率在一小时内个位数次的推送的话不会有太大问题。

Apple给出了几个典型的应用情景，比如一个电视节目类的应用，当用户标记某些剧目为喜爱时，当这些剧有更新时，可以给用户发送静默的唤醒推送通知，客户端在接到通知后检查更新并开始后台下载（注意后台下载的部分绝对不应该在推送回调中做，而是应该使用新的后台传输服务，后面详细介绍）。下载完成后发送一个本地推送告知用户新的内容已经准备完毕。这样在用户注意到推送并打开应用的时候，所有必要的内容已经下载完毕，UI也将切换至用户喜爱的剧目，用户只需要点击播放即可开始真正使用应用，这绝对是无比顺畅和优秀的体验。另一种应用情景是文件同步类，比如用户标记了一些文件为需要随时同步，这样用户在其他设备或网页服务上更改了这些文件时，可以发送静默推送然后使用后台传输来保持这些文件随时是最新。

如果您是一路看下来的话，不难发现其实后台获取和静默推送在很多方面是很类似的，特别是实现和处理的方式，但是它们适用的情景是完全不同的。后台获取更多地使用在泛数据模式下，也即用户对特定数据并不是很关心，数据应该被更新的时间也不是很确定，典型的有社交类应用和天气类应用；而静默推送或者是推送唤醒更多地应该是用户感兴趣的内容发生更新时被使用，比如消息类应用和内容型服务等。根据不同的应用情景，选择合适的后台策略（或者混合使用两者），以带给用户绝佳体验，这是Apple所期望iOS7开发者做到的。

### 后台传输（￼Background Transfer Service）

iOS6和之前，iOS应用在大块数据的下载这一块限制是比较多的：只有应用在前台时能保持下载（用户按Home键切到后台或者是等到设备自动休眠都可能中止下载），在后台只有很短的最多十分钟时间可以保持网络连接。如果想要完成一个较大数据的下载，用户将不得不打开你的app并且基本无所事事。很多这种时候，用户会想要是在下载的时候能切到别的应用刷刷微博或者玩玩游戏，然后再切回来的就已经下载完成了的话，该有多好。iOS7中，这可以实现了。iOS7引入了后台传输的相关方式，用来保证应用退出后数据下载或者上传能继续进行。这种传输是由iOS系统进行管理的，没有时间限制，也不要求应用运行在前台。

想要实现后台传输，就必须使用iOS7的新的网络连接的类，NSURLSession。这是iOS7中引入用以替代陈旧的NSURLConnection的类，著名的AFNetworking甚至不惜从底层开始完全重写以适配iOS7和NSURLSession（参见[这里](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-2.0-Migration-Guide)），NSURLSession的重要性可见一斑。在这里我主要只介绍NSURLSession在后台传输中的一些使用，关于这个类的其他用法和对原有NSURLConnection的加强，只做稍微带过而不展开，有兴趣深入挖掘和使用的童鞋可以参看Apple的文档（或者更简单的方式是使用AFNetworking来处理网络相关内容，而不是直接和CFNetwork框架打交道）。

#### 步骤和例子

后台传输的的实现也十分简单，简单说分为三个步骤：创建后台传输用的NSURLSession对象；向这个对象中加入对应的传输的NSURLSessionTask，并开始传输；在实现appDelegate里实现`-application:handleEventsForBackgroundURLSession:completionHandler:`方法，以刷新UI及通知系统传输结束。接下来结合代码来看一看实际的用法吧～

首先我们需要一个用于后台下载的session：

```objc
- (NSURLSession *)backgroundSession
{
    //Use dispatch_once_t to create only one background session. If you want more than one session, do with different identifier
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.yourcompany.appId.BackgroundSession"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    return session;
}
```
这里创建并配置了NSURLSession，将其指定为后台session并设定delegate。

接下来向其中加入对应的传输用的NSURLSessionTask，并启动下载。

```objc
//@property (nonatomic) NSURLSession *session;
//@property (nonatomic) NSURLSessionDownloadTask *downloadTask;

- (NSURLSession *)backgroundSession
{
    //...
}

- (void) beginDownload
{
    NSURL *downloadURL = [NSURL URLWithString:DownloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.session = [self backgroundSession];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    [self.downloadTask resume];
}
```

最后一步是在appDelegate中实现`-application:handleEventsForBackgroundURLSession:completionHandler:`

```objc
//AppDelegate.m
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    //Check if all transfers are done, and update UI
    //Then tell system background transfer over, so it can take new snapshot to show in App Switcher
    completionHandler();
    
    //You can also pop up a local notification to remind the user
    //...
}
```

NSURLSession和对应的NSURLSessionTask有以下重要的delegate方法可以使用：

```objc
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(NSError *)error;
```

一旦后台传输的状态发生变化（包括正常结束和失败）的时候，应用将被唤醒并运行appDelegate中的回调，接下来NSURLSessionTask的委托方法将在后台被调用。虽然上面的例子中直接在appDelegate中call了completionHandler，但是实际上更好的选择是在appDelegate中暂时持有completionHandler，然后在NSURLSessionTask的delegate方法中检查是否确实完成了传输并更新UI后，再调用completionHandler。另外，你的应用到现在为止只是在后台运行，想要提醒用户传输完成的话，也许你还需要在这个时候发送一个本地推送（记住在这个时候你的应用是可以执行代码的，虽然是在后台），这样用户可以注意到你的应用的变化并回到应用，并开始已经准备好数据和界面。

#### 一些限制

首先，后台传输只会通过wifi来进行，用户大概也不会开心蜂窝数据的流量被后台流量用掉。后台下载的时间与以前的关闭应用后X分钟的模式不一样，而是为了节省电力变为离散式的下载，并与其他后台任务并发（比如接收邮件等）。另外还需要注意的是，对于下载后的内容不要忘记写到应用的目录下（一般来说这种可以重复获得的内容应该放到cache目录下），否则如果由于应用完全退出的情况导致没有保存到可再次访问的路径的话，那可就白做工了。

后台传输非常适合用于文件，照片或者追加游戏内容关卡等的下载，如果配合后台获取或者静默推送的话，相信可以完全很多很有趣，并且以前被限制而无法实现的功能。
