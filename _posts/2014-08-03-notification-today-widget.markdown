---
layout: post
title: WWDC 2014 Session笔记 - iOS 通知中心扩展制作入门
date: 2014-08-03 11:50:39.000000000 +09:00
tags: 能工巧匠集
---
本文是我的 [WWDC 2014 笔记](http://onevcat.com/2014/07/developer-should-know-about-ios8/) 中的一篇，涉及的 Session 有

* [Creating Extensions for iOS and OS X, Part 1](http://devstreaming.apple.com/videos/wwdc/2014/205xxqzduadzo14/205/205_hd_creating_extensions_for_ios_and_os_x,_part_1.mov?dl=1)
* [Creating Extensions for iOS and OS X, Part 2](http://devstreaming.apple.com/videos/wwdc/2014/217xxsvxdga3rh5/217/217_hd_creating_extensions_for_ios_and_os_x_part_2.mov?dl=1)

## 总览

扩展 (Extension) 是 iOS 8 和 OSX 10.10 加入的一个非常大的功能点，开发者可以通过系统提供给我们的扩展接入点 (Extension point) 来为系统特定的服务提供某些附加的功能。对于 iOS 来说，可以使用的扩展接入点有以下几个：

* Today 扩展 - 在下拉的通知中心的 "今天" 的面板中添加一个 widget
* 分享扩展 - 点击分享按钮后将网站或者照片通过应用分享
* 动作扩展 - 点击 Action 按钮后通过判断上下文来将内容发送到应用
* 照片编辑扩展 - 在系统的照片应用中提供照片编辑的能力
* 文档提供扩展 - 提供和管理文件内容
* 自定义键盘 - 提供一个可以用在所有应用的替代系统键盘的自定义键盘或输入法

系统为我们提供的接入点虽然还比较有限，但是不少已经是在开发者和 iOS 的用户中呼声很高的了。而通过利用这些接入点提供相应的功能，也可以极大地丰富系统的功能和可用性。本文将先不失一般性地介绍一下各种扩展的共通特性，然后再以一个实际的例子着重介绍下通知中心的 Today 扩展的开发方法，以期为 iOS 8 的扩展的学习提供一个平滑的入口。

Apple 指出，iOS 8 中开发者的中心并不应该发生改变，依然应该是围绕 app。在 app 中提供优秀交互和有用的功能，现在是，将来也会是 iOS 应用开发的核心任务。而扩展在 iOS 中是不能以单独的形式存在的，也就是说我们不能直接在 AppStore 提供一个扩展的下载，扩展一定是随着一个应用一起打包提供的。用户在安装了带有扩展的应用后，将可以在通知中心的今日界面中，或者是系统的设置中来选择开启还是关闭你的扩展。而对于开发者来说，提供扩展的方式是在 app 的项目中加入相应的扩展的 target。因为扩展一般来说是展现在系统级别的 UI 或者是其他应用中的，Apple 特别指出，扩展应该保持轻巧迅速，并且专注功能单一，在不打扰或者中断用户使用当前应用的前提下完成自己的功能点。因为用户是可以自己选择禁用扩展的，所以如果你的扩展表现欠佳的话，很可能会遭到用户弃用，甚至导致他们将你的 app 也一并卸载。

### 扩展的生命周期

扩展的生命周期和包含该扩展的你的容器 app (container app) 本身的生命周期是独立的，准确地说。它们是两个独立的进程，默认情况下互相不应该知道对方的存在。扩展需要对宿主 app (host app，即调用该扩展的 app) 的请求做出响应，当然，通过进行配置和一些手段，我们可以在扩展中访问和共享一些容器 app 的资源，这个我们稍后再说。

因为扩展其实是依赖于调用其的宿主 app 的，因此其生命周期也是由用户在宿主 app 中的行为所决定的。一般来说，用户在宿主 app 中触发了该扩展后，扩展的生命周期就开始了：比如在分享选项中选择了你的扩展，或者向通知中心中添加了你的 widget 等等。而所有的扩展都是由 ViewController 进行定义的，在用户决定使用某个扩展时，其对应的 ViewController 就会被加载，因此你可以像在编写传统 app 的 ViewController 那样获取到诸如 `viewDidLoad` 这样的方法，并进行界面构建及做相应的逻辑。扩展应该保持功能的单一专注，并且迅速处理任务，在执行完成必要的任务，或者是在后台预约完成任务后，一般需要尽快通过回调将控制权交回给宿主 app，至此生命周期结束。

按照 Apple 的说法，扩展可以使用的内存是远远低于 app 可以使用的内存的。在内存吃紧的时候，系统更倾向于优先搞掉扩展，而不会是把宿主 app 杀死。因此在开发扩展的时候，也一定需要注意内存占用的限制。另一点是比如像通知中心扩展，你的扩展可能会和其他开发人员的扩展共存，这样如果扩展阻塞了主线程的话，就会引起整个通知中心失去响应。这种情况下你的扩展和应用也就基本和用户说再见了..

### 扩展和容器应用的交互

扩展和容器应用本身并不共享一个进程，但是作为扩展，其实是主体应用功能的延伸，肯定不可避免地需要使用到应用本身的逻辑甚至界面。在这种情况下，我们可以使用 iOS 8 新引入的自制 framework 的方式来组织需要重用的代码，这样在链接 framework 后 app 和扩展就都能使用相同的代码了。

另一个常见需求就是数据共享，即扩展和应用互相希望访问对方的数据。这可以通过开启 App Groups 和进行相应的配置来开启在两个进程间的数据共享。这包括了使用 ` NSUserDefaults` 进行小数据的共享，或者使用 `NSFileCoordinator` 和 `NSFilePresenter` 甚至是 CoreData 和 SQLite 来进行更大的文件或者是更复杂的数据交互。

另外，一直以来的自定义的 url scheme 也是从扩展向应用反馈数据和交互的渠道之一。

这些常见的手段和策略在接下来的 demo 中都会用到。一张图片能顶千言万语，而一个 demo 能顶千张图片。那么，我们开始吧。

## Timer Demo

Demo 做的应用是一个简单的计时器，即点击开始按钮后开始倒数计时，每秒根据剩余的时间来更新界面上的一个表示时间的 Label，然后在计时到 0 秒时弹出一个 alert，来告诉用户时间到，当然用户也可以使用 Stop 按钮来提前打断计时。其实这个 Demo 就是我的很早之前做的一个[番茄工作法的 app](http://pomo.onevcat.com) 的原型。

为了大家方便跟随这个 demo，我把初始的时候的代码放到 GitHub 的 [start-project](https://github.com/onevcat/TimerExtensionDemo/tree/start-project) 这个 tag 上了。语言当然是要用 Swift，界面因为不是 demo 的重点，所以就非常简单能表明意思就好了。但是虽然简单，却也是利用了[上一篇文章](http://onevcat.com/2014/07/ios-ui-unique/)中所提到的 Size Classes 来完成的不同屏幕的布局，所以至少可以说在思想上是完备的 iOS 8 兼容了 =_=..

初始工程运行起来的界面大概是这样的：

![初始工程](/assets/images/2014/extension-demo-1.JPG)

简单说整个项目只有一个 ViewController，点击开始按钮时我们通过设定希望的计时时间来创建一个 `Timer` 实例，然后调用它的 `start` 方法。这个方法接收两个参数，分别是每次剩余时间更新，以及计时结束（不论是计时时间到的完成还是计时被用户打断）时的回调方法。另外这个方法返回一个 tuple，用来表示是否开始成功以及可能的错误。

剩余时间更新的回调中刷新界面 UI，计时结束的回调里回收了 `Timer` 实例，并且显示了一个 `UIAlertController`。用户通过点击 Stop 按钮可以直接调用 `stop` 方法来打断计时。直接简单，没什么其他的 trick。

我们现在计划为这个 app 做一个 Today 扩展，来在通知中心中显示并更新当前的剩余时间，并且在计时完成后显示一个按钮，点击后可以回到 app 本体，并弹出一个完成的提示。

### 添加扩展 Target

第一步当然是为我们的 app 添加扩展。正如在总览中所提到的，扩展是项目中的一个单独的 target。在 Xcode 6 中， Apple 为我们准备了对应各类不同扩展点的 target 模板，这使得向 app 中添加扩展非常容易。对于我们现在想做的 Today 扩展，只需点选菜单的 File > New > Target...，然后选择 iOS 中的 Application Extension 的 Today Extension 就行了。

![添加 target](/assets/images/2014/extension-tutorial.jpg)

在弹出的菜单中将新的 target 命名为 `SimpleTimerTodayExtenstion`，并且让 Xcode 自动生成新的 Scheme，以方便测试使用。我们的工程中现在会多出一个和新建的 target 同名的文件夹，里面主要包含了一个 .swift 的 ViewController 程序文件，一个叫做 `MainInterface` 的 storyboard 文件和 Info.plist。其中在 plist 里 的 `NSExtension` 中定义了这个 扩展的类型和入口，而配套的 ViewController 和 StoryBoard 就是我们的扩展的具体内容和实现了。

我们的主题程序在编译链接后会生成一个后缀为 `.app` 的包，里面包含主程序的二进制文件和各种资源。而扩展 target 将单独生成一个后缀名为 `.appex` 的文件包。这个文件包将随着主体程序被安装，并由用户选择激活或者添加（对于 Today widget 的话在通知中心 Today 视图中的编辑删增，对于其他的扩展的话，使用系统的设置进行管理）。我们可以看到，现在项目的 Product 中已经新增了一个扩展了。

![扩展的product](/assets/images/2014/extension-tutorial-2.jpg)

如果你有心已经打开了 `MainInterface` 文件的话，可以注意到 Apple 已经为我们准备了一个默认的 Hello World 的 label 了。我们这时候只要运行主程序，扩展就会一并安装了。将 Scheme 设为 Simple Timer 的主程序，`Cmd + R`，然后点击 Home 键将 app 切到后台，拉下通知中心。这时候你应该能在 Toady 视图中找到叫做 `SimpleTimerTodayExtenstion` 的项目，显示了一个 Hello World 的标签。如果没有的话，可以点击下面的编辑按钮看看是不是没有启用，如果在编辑菜单中也没有的话，恭喜你遇到了和 Session 视频里的演讲者同样的 bug，你可能需要删除应用，清理工程，然后再安装试试看。一般来说卸载再安装可以解决现在的 beta 版大部分的无法加载的问题，如果还是遇到问题的话，你还可以尝试重启设备（按照以往几年的 SDK 的情况来看，beta 版里这很正常，正式版中应该就没什么问题了）。

如果一切正常的话，你能看到的通知中心应该类似这样：

![Hello World widget](/assets/images/2014/extension-demo-2.JPG)

这种方式运行的扩展我们无法对其进行调试，因为我们的调试器并没有 attach 到这个扩展的 target 上。有两种方法让我们调试扩展，一种是将 Scheme 设为之前 Xcode 为我们生成的 `SimpleTimerTodayExtenstion`，然后运行时选择从 Today 视图进行运行，如图；另一种是在扩展运行时使用菜单中的 Debug > Attach to Process > By Process Identifier (PID) or name，然后输入你的扩展的名字（在我们的 demo 中是 com.onevcat.SimpleTimer.SimpleTimerTodayExtension）来把调试器挂载到进程上去。

![调试扩展](/assets/images/2014/extension-tutorial-4.jpg)

### 在应用和扩展间共享数据 - App Groups

扩展既然是个 ViewController，那各种连接 `IBOutlet`，使用 `viewDidLoad` 之类的生命周期方法来设置 UI 什么的自然不在话下。我们现在的第一个难点就是，如何获取应用主体在退出时计时器的剩余时间。只要知道了还剩多久以及何时退出，我们就能在通知中心中显示出计时器正确的剩余时间了。

对 iOS 开发者来说，沙盒限制了我们在设备上随意读取和写入。但是对于应用和其对应的扩展来说，Apple 在 iOS 8 中为我们提供了一种可能性，那就是 App Groups。App Groups 为同一个 vender 的应用或者扩展定义了一组域，在这个域中同一个 group 可以共享一些资源。对于我们的例子来说，我们只需要使用同一个 group 下的 `NSUserDefaults` 就能在主体应用不活跃时向其中存储数据，然后在扩展初始化时从同一处进行读取就行了。

首先我们需要开启 App Groups。得益于 Xcode 5 开始引入的 Capabilities，这变得非常简单（至少不再需要去 developer portal 了）。选择主 target `SimpleTimer`，打开它的 Capabilities 选项卡，找到 App Groups 并打开开关，然后添加一个你能记得的 group 名字，比如 `group.simpleTimerSharedDefaults`。接下来你还需要为 `SimpleTimerTodayExtension` 这个 target 进行同样的配置，只不过不再需要新建 group，而是勾选刚才创建的 group 就行。

![启用 App Groups](/assets/images/2014/extension-tutorial-3.jpg)

然后让我们开始写代码吧！首先是在主体程序的 `ViewController.swift` 中添加一个程序失去前台的监听，在 `viewDidLoad` 中加入：

```
NSNotificationCenter.defaultCenter()
    .addObserver(self, selector: "applicationWillResignActive",name: UIApplicationWillResignActiveNotification, object: nil)
```

然后是所调用的 `applicationWillResignActive` 方法：

```
@objc private func applicationWillResignActive() {
    if timer == nil {
        clearDefaults()
    } else {
        if timer.running {
            saveDefaults()
        } else {
            clearDefaults()
        }
    }
}

private func saveDefaults() {
    let userDefault = NSUserDefaults(suiteName: "group.simpleTimerSharedDefaults")
    userDefault.setInteger(Int(timer.leftTime), forKey: "com.onevcat.simpleTimer.lefttime")
    userDefault.setInteger(Int(NSDate().timeIntervalSince1970), forKey: "com.onevcat.simpleTimer.quitdate")

    userDefault.synchronize()
}
    
private func clearDefaults() {
    let userDefault = NSUserDefaults(suiteName: "group.simpleTimerSharedDefaults")
    userDefault.removeObjectForKey("com.onevcat.simpleTimer.lefttime")
    userDefault.removeObjectForKey("com.onevcat.simpleTimer.quitdate")

    userDefault.synchronize()
}
```

这样，在应用切到后台时，如果正在计时，我们就将当前的剩余时间和退出时的日期存到了 `NSUserDefaults` 中。这里注意，可能一般我们在使用 `NSUserDefaults` 时更多地是使用 `standardUserDefaults`，但是这里我们需要这两个数据能够被扩展访问到的话，我们必须使用在 App Groups 中定义的名字来使用 `NSUserDefaults`。

接下来，我们可以到扩展的 `TodayViewController.swift` 中去获取这些数据了。在扩展 ViewController 的 `viewDidLoad` 中，添加以下代码：

```
let userDefaults = NSUserDefaults(suiteName: "group.simpleTimerSharedDefaults")
let leftTimeWhenQuit = userDefaults.integerForKey("com.onevcat.simpleTimer.lefttime")
let quitDate = userDefaults.integerForKey("com.onevcat.simpleTimer.quitdate")
        
let passedTimeFromQuit = NSDate().timeIntervalSinceDate(NSDate(timeIntervalSince1970: NSTimeInterval(quitDate)))
        
let leftTime = leftTimeWhenQuit - Int(passedTimeFromQuit)

lblTImer.text = "\(leftTime)"
```

当然别忘了把 StoryBoard 的那个 label 拖出来：

```
@IBOutlet weak var lblTImer: UILabel!
```

再次运行程序，并开始一个计时，然后按 Home 键切到后台，拉出通知中心，perfect，我们的扩展能够和主程序进行数据交互了：

![读取数据](/assets/images/2014/extension-demo-3.JPG)

### 在应用和扩展间共享代码 - Framework

接下来的任务是在 Today 界面中进行计时，来刷新我们的界面。这部分代码其实我们已经写过（当然..确切来说是我写的，你可能只是看过），没错，就是应用中的 `Timer.swift` 文件。我们只需要在扩展的 ViewController 中用剩余时间创建一个 `Timer` 的实例，然后在更新的 callback 里设置 label 就好了嘛。但是问题是，这部分代码是在应用中的，我们要如何在扩展中也能使用它呢？

一个最直接也是最简单的想法自然是把 `Timer.swift` 加入到扩展 target 的编译文件中去，这样在扩展中自然也就可以使用了。但是 iOS 8 开始 Apple 为我们提供了一个更好的选择，那就是做成 Framework。单个文件可能不会觉得有什么差别，但是随着需要共用的文件数量和种类的增加，将单个文件逐一添加到不同 target 这种管理方法很快就会将事情弄成一团乱麻。你需要考虑每一个新加或者删除的文件影响的范围，以及它们分别需要适用何处，这简直就是人间地狱。提供一个统一漂亮的 framework 会是更多人希望的选择（其实也差不多成为事实标准了）。使用 framework 进行模块化的另一个好处是可以得益于良好的访问控制，以保证你不会接触到不应该使用的东西，然后，Swift 的 namespace 是基于模块的，因此你也不再需要担心命名冲突等等一摊子 objc 时代的烦心事儿。

现在让我们把 `Timer.swift` 放到 framework 里吧。首先我们新建一个 framework 的 target。File > New > Target... 中选择 Framework & Library，选中 Cocoa Touch Framework （配图中的另外几个选项可能在你的 Xcode 中是没有的，请无视它们，这是历史遗留问题），然后确定。按照 Apple 对 framework 的命名规范，也许 `SimpleTimerKit` 会是一个不错的名字。

![建立框架](/assets/images/2014/extension-tutorial-5.jpg)

接下来，我们将 `Timer.swift` 从应用中移动到 framework 中。很简单，首先将其从应用的 target 中移除，然后加入到新建的 `SimpleTimerKit` 的 Compile Sources 中。

![添加 framework 文件](/assets/images/2014/extension-tutorial-6.jpg)

确认在应用中 link 了新的 framwork，并且在 ViewController.swift 中加上 `import SimpleTimerKit` 后试着编译看看...好多错误，基本都是 ViewController 中说找不到 Timer 之类的。这是因为原来的实现是在同一个 module 中的，默认的 `internal` 的访问层级就可以让 ViewController 访问到关于 `Timer` 和相应方法的信息。但是现在它们处于不同的 module 中，所以我们需要对 `Timer.swift` 的访问权限进行一些修改，在需要外部访问的地方加上 `public` 关键字。关于 Swift 中的访问控制，可以参考 Apple 关于 Swift 的这篇[官方博客](https://developer.apple.com/swift/blog/?id=5)，简单说就是 `private` 只允许本文件访问，不写的话默认是 `internal`，允许统一 module 访问，而要提供给别的 module 使用的话，需要声明为 public。修改后的 `Timer.swift` 文件大概是[这个样子](https://github.com/onevcat/TimerExtensionDemo/blob/master/SimpleTimer/SimpleTimer/Timer.swift)的。

修改合适的访问权限后，接下来我们就可以将这个 framework 链接到扩展的 target 了。链接以后编译什么的可以通过，但是会多一个警告：

![警告](/assets/images/2014/extension-tutorial-7.jpg)

这是因为作为插件，需要遵守更严格的沙盒限制，所以有一些 API 是不能使用的。为了避免这个警告，我们需要在 framework 的 target 中声明在我们使用扩展可用的 API。具体在 `SimpleTimerKit` 的 target 的 General 选项卡中，将 Deployment Info 中的 Allow app extension API only 勾选上就可以了。关于在扩展里不能使用的 API，都已经被 Apple 标上了 `NS_EXTENSION_UNAVAILABLE`，在[这里](https://gist.github.com/joeymeyer/0cb033698bfa5a0420f6)有一份简单的列表可供参考，基本来说都是 runtime 的东西以及一些会让用户迷惑或很危险的操作（当然这个标记的方法很可能会不断变动，最终一切请以 Apple 的文档和实际代码为准）。

![开启 Extension Only](/assets/images/2014/extension-tutorial-9.jpg)

接下来，在扩展的 ViewController 中也链接 `SimpleTimerKit` 并加入 `import SimpleTimerKit`，我们就可以在扩展中使用 `Timer` 了。将刚才的直接设置 label 的代码去掉，换成下面的：

```
override func viewDidLoad() {
    //...
    
    if (leftTime > 0) {
        timer = Timer(timeInteral: NSTimeInterval(leftTime))
        timer.start(updateTick: {
                [weak self] leftTick in self!.updateLabel()
            }, stopHandler: nil)
    } else {
        //Do nothing now
    }
}

private func updateLabel() {
    lblTimer.text = timer.leftTimeString
}
```

我们在扩展里也像在 app 内一样，创建 `Timer`，给定回调，坐等界面刷新。运行看看，先进入应用，开始一个计时。然后退出，打开通知中心。通知中心中现在也开始计时了，而且确实是从剩余的时间开始的，一切都很完美：

![通知中心计时](/assets/images/2014/extension-demo-4.JPG)

### 通过扩展启动主体应用

最后一个任务是，我们想要在通知中心计时完毕后，在扩展上呈现一个 "完成啦" 的按钮，并通过点击这个按钮能回到应用，并在应用内弹出结束的 alert。

这其实最关键的在于我们要如何启动主体容器应用，以及向其传递数据。可能很多同学会想到 URL Scheme，没错通过 URL Scheme 我们确实可以启动特定应用并携带数据。但是一个问题是为了通过 URL 启动应用，我们一般需要调用 `UIApplication` 的 openURL 方法。如果细心的刚才看了 `NS_EXTENSION_UNAVAILABLE` 的同学可能会发现这个方法是被禁用的（这也是很 make sense 的一件事情，因为说白了扩展通过 `sharedApplication` 拿到的其实是宿主应用，宿主应用表示凭什么要让你拿到啊！）。为了完成同样的操作，Apple 为扩展提供了一个 `NSExtensionContext` 类来与宿主应用进行交互。用户在宿主应用中启动扩展后，宿主应用提供一个上下文给扩展，里面最主要的是包含了 `inputItems` 这样的待处理的数据。当然对我们现在的需求来说，我们只要用到它的 `openURL(URL:,completionHandler:)` 方法就好了。

另外，我们可能还需要调整一下扩展 widget 的尺寸，以让我们有更多的空间显示按钮，这可以通过设定 `preferredContentSize` 来做到。在 `TodayViewController.swift` 中加入以下方法：

```
private func showOpenAppButton() {
    lblTimer.text = "Finished"
    preferredContentSize = CGSizeMake(0, 100)

    let button = UIButton(frame: CGRectMake(0, 50, 50, 63))
    button.setTitle("Open", forState: UIControlState.Normal)
    button.addTarget(self, action: "buttonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
    
    view.addSubview(button)        
}
```

在设定 `preferredContentSize` 时，指定的宽度都是无效的，系统会自动将其处理为整屏的宽度，所以扔个 0 进去就好了。在这里添加按钮时我偷了个懒，本来应该使用Auto Layout 和添加约束的，但是这并不是我们这个 demo 的重点。另一方面，为了代码清晰明了，就直接上坐标了。

然后添加这个按钮的 action：

```
@objc private func buttonPressed(sender: AnyObject!) {
    extensionContext.openURL(NSURL(string: "simpleTimer://finished"), completionHandler: nil)
}
```

我们将传递的 URL 的 scheme 是 `simpleTimer`，以 host 的 `finished` 作为参数，就可以通知主体应用计时完成了。然后我们需要在计时完成时调用 `showOpenAppButton` 来显示按钮，更新 `viewDidLoad` 中的内容：

```
override func viewDidLoad() {
    //...
    if (leftTime > 0) {
        timer = Timer(timeInteral: NSTimeInterval(leftTime))
        timer.start(updateTick: {
            [weak self] leftTick in self!.updateLabel()
            }, stopHandler: {
                [weak self] finished in self!.showOpenAppButton()
            })
    } else {
        showOpenAppButton()
    }
}
```

最后一步是在主体应用的 target 里设置合适的 URL Scheme：

![设置 url scheme](/assets/images/2014/extension-tutorial-8.jpg)

然后在 `AppDelegate.swift` 中捕获这个打开事件，并检测计时是否完成，然后做出相应：

```
func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
    if url.scheme == "simpleTimer" {
        if url.host == "finished" {
            NSNotificationCenter.defaultCenter()
                .postNotificationName(taskDidFinishedInWidgetNotification, object: nil)
        }
        return true
    }
    
    return false
}
```

在这个例子里，我们发了个通知。而在 ViewController 中我们可以一开始就监听这个通知，然后收到后停止计时并弹出提示就行了。当然我们可能需要一些小的重构，比如添加是手动打断还是计时完成的判断以弹出不一样的对话框等等，这些都很简单再次就不赘述了。

![完成](/assets/images/2014/extension-demo-5.JPG)

至此，我们就完成了一个很基本的通知中心扩展，完整的项目可以在 [GitHub repo 的 master](https://github.com/onevcat/TimerExtensionDemo) 上找到。这个计时器现在在应用中只在前台或者通知中心显示时工作，如果你退出应用后再打开应用，其实这段时间内是没有计时的。因此这个项目之后可能的改进就是在返回应用的时候添加一下计时的判定，来更新计时器的剩余时间，或者是已经完成了的话就直接结束计时。

### 其他

其实在 Xcode 为我们生成的模板文件中，还有这么一段代码也很重要：

```
func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
    // Perform any setup necessary in order to update the view.

    // If an error is encoutered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
    
    completionHandler(NCUpdateResult.NewData)
}
```

对于通知中心扩展，即使你的扩展现在不可见 (也就是用户没有拉开通知中心)，系统也会时不时地调用实现了 `NCWidgetProviding` 的扩展的这个方法，来要求扩展刷新界面。这个机制和 [iOS 7 引入的后台机制](http://onevcat.com/2013/08/ios7-background-multitask/)是很相似的。在这个方法中我们一般可以做一些像 API 请求之类的事情，在获取到了数据并更新了界面，或者是失败后都使用提供的 `completionHandler` 来向系统进行报告。

值得注意的一点是 Xcode (至少现在的 beta 4) 所提供的模板文件的 ViewController 里虽然有这个方法，但是它默认并没有 conform 这个接口，所以要用的话，我们还需要在类声明时加上 `NCWidgetProviding`。

## 总结

这个 Demo 主要涉及了通知中心的 Toady widget 的添加和一般交互。其实扩展是一个相当大块的内容，对于其他像是分享或者是 Action 的扩展，其使用方式又会有所不同。但是核心的概念，生命周期以及与本体应用交互的方法都是相似的。Xcode 在我们创建扩展时就为我们提供了非常好的模版文件，更多的时候我们要做的只不过是在相应的方法内填上我们的逻辑，而对于配置方面基本不太需要操心，这一点还是非常方便的。

就为了扩展这个功能，我已经迫不及待地想用上 iOS 8 了..不论是使用别人开发的扩展还是自己开发方便的扩展，都会让这个世界变得更美好。
