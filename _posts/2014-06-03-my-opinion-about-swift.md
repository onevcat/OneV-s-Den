---
layout: post
title: 关于 Swift 的一点初步看法
date: 2014-06-03 12:05:44.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [wwdc, swift, 开发者体验, 编程语言]
image: /assets/images/2014/swift.png
---

虽然四点半就起床去排队等入场，结果还是只能坐在了蛮后面的位置看着大屏幕参加了今年的 Keynote。其实今年 OS X 和 iOS 的更新亮点都不少，但是显然风头和光芒都让横空出世的 Swift 给抢走了。这部分内容因为不是 NDA，所以可以提前说一说。

Swift 是 Apple 自创的一门专门为 Cocoa 和 CocoaTouch 设计的语言，意在用来替代 objc。早上发布的时候有很多朋友说其实他们已经写了很久的 Swift，而且还给了一个[网站](http://swift-lang.org)，在这里首先需要说明的是，这个网站的 *Swift parallel scripting language* 和 Apple 的 [Swift](https://developer.apple.com/swift/) 并不是一个东西，两者可以说毫无关系。Apple 还在自己的 Swift 介绍页面后面很友好地放上了 Swift parallel scripting language 的网站链接，以提示那些真的想搜另一个 Swift 却被 SEO 误导过来的可怜的孩子。

我个人来说，在把玩了 Swift 几个小时之后，深深地喜欢上了这门新的语言。这篇文章以一个初学者（其实现在大家都是初学者）的角度来对 Swift 做一个简单的介绍，因为现在大家其实是在同一个起跑线上，所以理解上可能会有很多不精确的地方，出错了也请大家轻喷指正！

## 什么是 Swift

很多人在看到 Swift 第一眼的感觉是，这丫是个脚本语言啊。因为在很多语法特性上 Swift 确实和一些脚本非常相似。但是首先需要明确的是，至少在 Apple 开发中，Swift 不是以一种脚本语言来运行的，所有的 Swift 代码都将被 LLVM 编译为 native code，以极高的效率运行。按照官方今天给出的 benchmark 数据，运行时比 Python 快 3.9 倍，比 objc 快 1.4 倍左右。我相信官方数据肯定是有些水分，但是即使这样，Swift 也给人带来很多遐想和期待。Swift 和原来的 objc 一样，是类型安全的语言，变量和方法都有明确的返回，并且变量在使用前需要进行初始化。而在语法方面，Swift 迁移到了业界公认的非常先进的语法体系，其中包含了闭包，多返回，泛型和大量的函数式编程的理念，函数也终于成为一等公民可以作为变量保存了（虽然具体实现和用法上来看和 js 那种传统意义的好像不太一样）。初步看下来语法上借鉴了很多 Ruby 的人性化的设计，但是借助于 Apple 自己手中 强大的 LLVM，性能上必须要甩开 Ruby 不止一两个量级。

另一方面，Swift 的代码又是可以 Interactive 来“解释”执行的。新的 Xcode 中加入了所谓的 Playground 来对开发者输入的 Swift 代码进行交互式的相应，开发者也可是使用 swift 的命令行工具来交互式地执行 swift 语句。细心的朋友可能注意到了，我在这里把“解释”两个字打上了双引号。这是因为即使在命令行中， Swift 其实也不是被解释执行的，而是在每个指令后进对从开始以来的 swift 代码行了一遍编译，然后执行的。这样的做法下依然可以让人“感到”是在做交互解释执行，这门语言的编译速度和优化水平，可见一斑。同时 Playground 还顺便记录了每条语句的执行时候的各种情况，叫做一组 timeline。可以使用 timeline 对代码的执行逐步检查，省去了断点 debug 的时间，也非常方便。

至于更详细的比如 Swift 的语法之类的，可以参见 Apple 在 iBooks 放出的 [The Swift Programming Language](https://itunes.apple.com/us/book/the-swift-programming-language/id881256329?mt=11)，或者你是开发者的话，也可以看看 pre-release 的[参考文档](https://developer.apple.com/library/ios/welcome_to_swift)

## Cool，我可以现在就使用 Swift 么？

Swift 作为 Apple 钦定的 objc 的继承者，作为 iOS/Mac 开发者的话，是觉得必须和值得学习和使用的。现在 Swift 可以和原来的 objc 或者 c 系的代码混用（注意，不同于 objc 和 c++ 或者 c 在同一个 .mm 文件中的混编，swift 文件不能和 objc 代码写在同一个文件中，你需要将两种代码分开）。编译出来的二进制文件是可以运行在 iOS 7 和 iOS 8 的设备上的（iOS 6 及之前的是不支持的）。虽然我没有尝试过，但是使用新的 clang 对 swift 进行编译的 app 二进制包，只要你的 target 是 iOS 7 及以上的话，应该现在就可以往 App Store 进行提交。

一个很好的消息是 Xcode 6 中应该是所有的文档都有 objc 和 swift 两种语言版本了，所以在文档支持上应该不是问题。而按照 Apple 开发者社区的一贯的跟进速度，有理由相信在不久的将来，Apple 很可能会果断 drop 掉 objc 的支持，而全面转向 swift。所以，关于标题里的这个问题的答案，我个人的建议是，尽快学习，尽快开始使用。如果你有一定的脚本语言的基础（Ruby 最好，Python 或者 JS 什么的也很不错），又比较了解 Cocoa 框架的思想的话，转型到新的语言应该完全不是问题。你会发现以前很多 objc 实现起来很郁闷的事情，在新语言下都易如反掌。我毫不忌讳地说，在 Apple 无数工程师和语言设计天才的努力下，Swift 吸收了众多语言的精华，应该是现在这个世界上最新（这不是废话么），也是最先进的一门编程语言（之一）了。而我认为，也正是 Apple 对这门语言有这样的自信，才会在这么一个可以说公司还在全盛的时候，不守陈规、如此大胆地进行语言的更换。因为 Apple 必定比你我都精于算计，切换语言带来的利益必须远大于弊端，才会值得冒如此大的风险。在这个意义上来说，今天的发布会就是程序开发业界的一枚重磅炸弹，也必将写入史册，而你我其实真的身在其中，变成了这段历史的见证者。

## 如何开始？

很简单，虽然历年的 WWDC 都在 NDA 的控制之下使得我们无法讨论过多的内容，但是这次的 Swift 破天荒地是在 NDA 之外的内容。Apple 已经放出了足够多的资源让我们开始学习。首先是官方的 Swift 的[介绍页面](https://developer.apple.com/swift/)，你可以了解一些 Swift 的基本特性和细节。然后就是从 iBooks 下载 [Swift 的书籍](https://itunes.apple.com/us/book/the-swift-programming-language/id881256329?mt=11)。你可以不必通读全书，而只需要快速浏览一下 35 页之前的 Tour 部分的内容，就可以开始将其运用到开发中了。因为不受 NDA 限制，所以 StackOverflow 的 [swift 标签](http://stackoverflow.com/questions/tagged/swift-language)和 [Google 上](https://www.google.com/#q=swift)应该会马上充斥满相关的问题和内容。及时跟进，相信和其他开发者一同从零开始学习和进步，你会很快上手并熟练使用 Swift 进行开发。

（因为真的，太好用了。你很难想象我在写一个漂亮的闭包或者嵌套函数或者多返回时，那种内心的激动和喜悦...）

## 总结

这次的 WWDC 可以说是 Apple 之前几年布局的一个汇总和爆发。从一开始的 Mac 整合电话和短信，以及无处不在的 Handoff，到后面的通知中心 widget 和系统 framework 的 extension，以及更甚的 Family Share 等等，可以说 Apple 通过自己对产业链的控制和生态圈的完善，让 iDevice 或者 Mac 的用户粘度得到了前所未有的加强。对一个人来说，可能一台苹果设备之后他会很容易购买第二台第三台；对于一家人来说，可能一个成员拥有苹果设备之后，其他人也会被宣传和便捷带动。这是一手妙招，也是 Apple 最近几年一直在做的趋势。

罗马其实不是一天建成的，在开发语言方面，Apple 其实也精心打造了很多年。在语言而言，之前完全没有这方面经验的苹果，毅然决然地选择离开 GCC 阵营，另起炉灶自己弄 Clang 和 LLVM 的布局，而终于在几年来对 objc 小修小补之后来了一次革命性的爆发。在日进万金的大好时候，抛弃一个成熟开发社区，而转向一种新的编程语言，做出这种决策，只能说这家公司的魄力让人折服和钦佩。另一方面，Apple 这么做的另一个理由应该是吸引更多的开发者加入到 Apple 开发阵营，因为相对于 objc 的语法和学习曲线，Swift 显然要容易很多，对于其他阵营的开发者，这也会是一个很好的入场机会。正应了这次 WWDC 的宣传语，Apple 已经为我们提供了更好的工具，我们有什么理由不继续我们的征途，实现我们的梦想呢？

**Write the code. Change the world.**
