---
layout: post
title: iOS内购实现及测试Check List
date: 2013-11-18 01:01:16.000000000 +09:00
tags: 能工巧匠集
---

![image](/assets/images/2013/cannot-connect-its.png)

免费+应用内购买的模式已经被证明了是最有效的盈利模式，所以实现内购功能可能是很多开发者必做的工作和必备的技能了。但是鉴于内购这块坑不算少，另外因为sandbox测试所需要特定的配置也很多，所以对于经验不太多的开发者来说很容易就遇到各种问题，并且测试时出错Apple给出的也只有“Can not connect iTunes Store”或者"Invalid Product IDs"之类毫无价值的错误提示，并没有详细的错误说明，因此调试起来往往没有方向。有老前辈在[这里](http://troybrant.net/blog/2010/01/invalid-product-ids/)整理过一个相对完整的check list了，但是因为年代已经稍微久远，所以内容上和现在的情况已经有一些出入。趁着在最近两个项目里做内购这块遇到的新问题，顺便在此基础上总结整理了一份比较新的中文Check list，希望能帮到后来人。

如果您在实现和测试iOS应用内购的时候遇到问题，可以逐一对照下面所列出的条目，并逐一进行检查。相信可以排除大部分的错误。如果您遇到的问题不在这个列表范围内，欢迎在评论中指出，我会进行更新。

* 您是否在iOS Dev Center中打开了对应应用AppID的`In-App Purchases`功能？登陆iOS Dev Center的Certificates, Identifiers & Profiles下，在Identifiers中找到正在开发的App，In-App Purchase一项应当显示Enabled（如果使用Xcode5，可以直接在Xcode的Capabilities页面中打开In-App Purchases）。
* 您是否在iTunes Connect中注册了您的IAP项目，并将其设为Cleared for Sale？
* 您的plist中的`Bundle identifier`的内容是否和您的AppID一致？
* 您是否正确填写了Version（CFBundleVersion）和Build（CFBuildNumber）两个数字？两者缺一不可。
* 您用代码向Apple申请售卖物品列表时是否使用了完整的在iTC注册的Product ID？（使用在IAP管理中内购项目的Product ID一栏中的字符串）
* 您是否在打开IAP以后重新生成过包含IAP许可的provisioning profile？
* 你是否重新导入了新的包含IAP的provisioning profile？建议在Organizer中先删掉原来设备上的老的provisioning profile。
* 您是否在用包含IAP的provisioning profile在部署测试程序？在Xcode5中，建议使用General中的Team选项来自动管理。
* 您是否是在模拟器中测试IAP？虽然理论上说模拟器在某些情况下可以测试IAP，但是条件很多也不让人安心，因此您确实需要一台真机来做IAP测试。
* 您是在企业版发布中测试IAP么？因为企业版没有iTC进行内购项目管理，也无法发布AppStore应用，所以您在企业版的build中不能使用IAP。
* 您是否将设备上原来的app删除了，并重新进行了安装？记得在安装前做一下Clean和Clean Build Folder。
* 您是否在运行应用前将设备上实际的Apple ID登出了？建议在设置->iTunes Store和App Stroe中将使用中的Apple ID登出，以未登录状态进入应用进行测试。
* 你是否使用的是Test User？如果你还没有创建Test User，你需要到iTC中创建。
* 您使用的测试账号是否是美国区账号？虽然不是一定需要，但是鉴于其他地区的测试账号经常抽风，加上美国区账号一直很稳定，因此强烈建议使用美国区账号。正常情况下IAP不需要进行信用卡绑定和其他信息填写，如果你遇到了这种情况，可以试试删除这个测试账号再新建一个其他地区的。
* 您是否有新建账户进行测试？可能的话，可以使用新建测试账户试试看，因为某些特定情况下测试账户会被Apple锁定。
* 您的应用是否是被拒状态（Rejected）或自己拒绝（Developer Rejected）了？被拒绝状态的应用的话对应还未通过的内购项目也会一起被拒，因此您需要重新将IAP项目设为Cleared for Sale。
* 您的应用是否处于等待开发者发布（Pending Developer Release）状态？等待发布状态的IAP是无法测试的。
* 您的内购项目是否是最近才新建的，或者进行了更改？内购项目需要一段时间才能反应到所有服务器上，这个过程一般是一两小时，也可能再长一些达到若干小时。
* 您在iTC中Contracts, Tax, and Banking Information项目中是否有还没有设置或者过期了的项目？不完整的财务信息无法进行内购测试。
* 您是在越狱设备上进行内购测试么？越狱设备不能用于正常内购，您需要重装或者寻找一台没有越狱的设备。
* 您是否能正常连接到Apple的服务器，你可以访问[Apple开发者论坛关于IAP的板块](https://devforums.apple.com/community/ios/connected/purchase)，如果苹果服务器正down掉，那里应该有热烈的讨论。

---

如果您正在寻找一份手把手教你实现IAP的教程的话，这篇文章不是您的菜。关于IAP的实现和步骤，可以参考下面的教程：

* 苹果的[官方IAP指南](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Introduction.html)和相应的[Technical Note](https://developer.apple.com/library/mac/technotes/tn2259/_index.html)
* Ray Wenderlich的[iOS6 IAP教程](http://www.raywenderlich.com/23266/in-app-purchases-in-ios-6-tutorial-consumables-and-receipt-validation)
* 一篇图文并茂的[中文教程](http://blog.csdn.net/xiaominghimi/article/details/6937097)
* 直接使用大神们封好的Store有关的库，比如[mattt/CargoBay](https://github.com/mattt/CargoBay)，[robotmedia/RMStore](https://github.com/robotmedia/RMStore)或者[MugunthKumar/MKStoreKit](https://github.com/MugunthKumar/MKStoreKit)。推荐前两个，因为MKStoreKit有一些恼人的小bug。
