---
layout: post
title: 如何打造一个让人愉快的框架
date: 2016-01-19 15:32:24.000000000 +09:00
tags: 能工巧匠集
---

> 这是我在今年 1 月 10 日 [@Swift 开发者大会](http://atswift.io) 上演讲的文字稿。相关的视频还在制作中，没有到现场的朋友可以通过这个文字稿了解到这个 session 的内容。

<script async class="speakerdeck-embed" data-id="809c2dfa8e5f46cf98e92898079c943a" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

<br\>

虽然我的工作是程序员，但是最近半年其实我的主要干的事儿是养了一个小孩。
所以这半年来可以说没有积累到什么技术，反而是积累了不少养小孩的心得。
当知道了有这么次会议可以分享这半年来的心得的时候，我毫不犹豫地选定了主题。那就是

> 如何打造一个让人愉快的**小孩**  

但考虑到这是一次开发者会议...当我把这个想法和题目提交给大会的时候，被残酷地拒绝了。考虑到我们是一次开发者大会，所以我需要找一些更合适的主题。其实如果你对自己的代码有感情的话，我们开发和维护的项目或者框架就如同自己的孩子一般这也是我所能找到的两者的共同点。所以，我将原来拟定的主题换了两个字：

> 如何打造一个让人愉快的**框架**

在正式开始前，我想先给大家分享一个故事。我们那儿的 iOS 开发小组里有一个叫做武田君的人，他的代码写得不错，做事也非常严谨，可以说是楷模般的员工。但是他有一个致命的弱点 -- 喜欢自己发明轮子。他出于本能地抗拒在代码中使用第三方框架，所以接到开发任务以后他一般都要花比其他小伙伴更多的时间才能完成。

武田君其实在各个方面都有建树...比如

- 网络请求
- 模型解析
- 导航效果
- 视图动画
...

不过虽然造了很多轮子，但是代码的重用比较糟糕，耦合严重。在新项目中使用的话，只能复制粘贴，然后针对项目修修补补。因为承担的任务总是没有办法完成，他一直是项目deadline的决定者，在日本这种社会，压力可想而知。就在我这次回国之前，武田君来向我借了一本我本科时候最喜欢的书。就是这本：

![](/assets/images/2016/book-cover.jpg)

我有时候就想，到底是什么让一个开发者面临如此大的精神压力，我们有什么办法来缓解这种压力。在我们有限的开发生涯中，应该如何有效利用时间来做一些更有价值的事情。

显然，我们不可能一天建成罗马，也不可能一个人建成罗马。我们需要一些方法把自己和别人写的代码组织起来，高效地利用，并以此为基础构建软件。这就涉及到使用和维护框架。如何利用框架迅速构建应用，以及在开发和发布一个框架的时候应该注意一些什么，这是我今天想讲的主题。当然，为了让大家安心和专注于今天的内容，而不是挂念武田君的命运，特此声明：

> 以上故事纯属虚构，如有雷同实属巧合

## 使用框架

在了解如何制作框架之前，先让我们看看如何使用框架。可以说，如果你想成为一个框架的提供者，首先你必须是一个优秀的使用者。

在 iOS 开发的早期，使用框架其实并不是一件让人愉悦的事情。可能有几年经验的开发者都有这样的体会，那就是：

> 忘不了 那些年，被手动引用和 `.a` 文件所支配的恐惧

其实恐惧源于未知，回想一下，当我们刚接触软件开发的时候，懵懵懂懂地引用了一个静态库，然后面对一排排编译器报错时候手足无措的绝望。但是当我们了解了静态库的话，我们就能克服这种恐惧了。

### 什么是静态库 (Static Library)

所谓静态库，或者说 .a 文件，就是一系列从源码编译的目标文件的集合。它是你的源码的实现所对应的二进制。配合上公共的 .h 文件，我们可以获取到 .a 中暴露的方法或者成员等。在最后编译 app 的时候.a 将被链接到最终的可执行文件中，之后每次都随着app的可执行二进制文件一同加载，你不能控制加载的方式和时机，所以称为静态库。

在 iOS 8 之前，iOS 只支持以静态库的方式来使用第三方的代码。

### 什么是动态框架 (Dynamic Framework)

与静态相对应的当然是动态。我们每天使用的 iOS 系统的框架是以 .framework 结尾的，它们就是动态框架。

Framework 其实是一个 bundle，或者说是一个特殊的文件夹。系统的 framework 是存在于系统内部，而不会打包进 app 中。app 的启动的时候会检查所需要的动态框架是否已经加载。像 UIKit 之类的常用系统框架一般已经在内存中，就不需要再次加载，这可以保证 app 启动速度。相比静态库，framework 是自包含的，你不需要关心头文件位置等，使用起来很方便。

### Universal Framework

iOS 8 之前也有一些第三方库提供 .framework 文件，但是它们实质上都是静态库，只不过通过一些方法进行了包装，相比传统的 .a 要好用一些。像是原来的 Dropbox 和 Facebook 等都使用这种方法来提供 SDK。不过因为已经脱离时代，所以在此略过不说。有兴趣和需要的朋友可以参看一下[这里](https://github.com/kstenerud/iOS-Universal-Framework)和[这里](https://github.com/jverkoey/iOS-Framework)。

### Library v.s. Framework

对比静态库和动态框架，后者是有不少优势的。

首先，静态库不能包含像 xib 文件，图片这样的资源文件，其他开发者必须将它们复制到 app 的 main bundle 中才能使用，维护和更新非常困难；而 framework 则可以将资源文件包含在自己的 bundle 中。
其次，静态库必须打包到二进制文件中，这在以前的 iOS 开发中不是很大的问题。但是随着 iOS 扩展（比如通知中心扩展或者 Action 扩展）开发的出现，你现在可能需要将同一个 .a 包含在 app 本体以及扩展的二进制文件中，这是不必要的重复。

最后，静态库只能随应用 binary 一起加载，而动态框架加载到内存后就不需要再次加载，二次启动速度加快。另外，使用时也可以控制加载时机。

动态框架有非常多的优点，但是遗憾的是以前 Apple 不允许第三方框架使用动态方式，而只有系统框架可以通过动态方式加载。

很多时候我们都想问，Apple，凭什么？

好吧，这种事也不是一次两次了...不过好消息是：。

### Cocoa Touch Framework

Apple 从 iOS 8 开始允许开发者有条件地创建和使用动态框架，这种框架叫做 Cocoa Touch Framework。

虽然同样是动态框架，但是和系统 framework 不同，app 中的使用的 Cocoa Touch Framework 在打包和提交 app 时会被放到 app bundle 中，运行在沙盒里，而不是系统中。也就是说，不同的 app 就算使用了同样的 framework，但还是会有多份的框架被分别签名，打包和加载。

Cocoa Touch Framework 的推出主要是为了解决两个问题：首先是应对刚才提到的从 iOS 8 开始的扩展开发。其次是因为 Swift，在 Swift 开源之前，它是不支持编译为静态库的。虽然在开源后有编译为静态库的可能性，但是因为 Binary Interface 未确定，现在也还无法实用。这些问题会在 Swift 3 中将被解决，但这至少要等到今年下半年了。

现在，Swift runtime 不在系统中，而是打包在各个 app 里的。所以如果要使用 Swift 静态框架，由于 ABI 不兼容，所以我们将不得不在静态包中再包含一次 runtime，可能导致同一个 app 包中包括多个版本的运行时，暂时是不可取的。

### 包和依赖管理

在使用框架的时候，用一些包管理和依赖管理工具可以简化使用流程。其中现在使用最广泛的应该是 [CocoaPods](http://cocoapods.org](http://cocoapods.org)。

CocoaPods 是一个已经有五年历史的 ruby 程序，可以帮助获取和管理依赖框架。

CocoaPods 的主要原理是框架的提供者通过编写合适的 PodSpec 文件来提供框架的基本信息，包括仓库地址，需要编译的文件，依赖等
用户使用 Podfile 文件指定想要使用的框架，CocoaPods 会创建一个新的工程来管理这些框架和它们的依赖，并把所有这些框架编译到成一个静态的 libPod.a。然后新建一个 workspace 包含你原来的项目和这个新的框架项目，最后在原来的项目中使用这个 libPods.a

这是一种“侵入式”的集成方式，它会修改你的项目配置和结构。

本来 CocoaPods 已经准备在前年发布 1.0 版本，但是 Swift 和动态框架的横空出世打乱了这个计划。因为必须提供对这两者的支持。不过最近 1.0.0 的 beta 已经公布，相信这个历时五年的项目将在最近很快迎来正式发布。

从 0.36.0 开始，可以通过在 Podfile 中添加 `use_frameworks!` 来编译 CocoaTouch Framework，也就是动态框架。

因为现在 Swift 的代码只能被编译为动态框架，所以如果你使用的依赖中包含 Swift 代码，又想使用 CocoaPods 来管理的话，必须选择开启这个选项。

`use_frameworks!` 会把项目的依赖全部改为 framework。也就是说这是一个 none or all 的更改。你无法指定某几个框架编译为动态，某几个编译为静态。我们可以这么理解：假设 Pod A 是动态框架，Pod B 是静态，Pod A 依赖 Pod B。要是 app 也依赖 Pod B：那么要么 Pod A 在 link 的时候找不到 Pod B 的符号，要么 A 和 app 都包含 B，都是无解的情况。

使用 CocoaPods 很简单，用 Podfile 来描述你需要使用和依赖哪些框架，然后执行 pod install 就可以了。下面是一个典型的 Podfile 的结构。

```ruby
# Podfile
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
  pod 'AFNetworking', '~> 2.6'
  pod 'ORStackView', '~> 3.0'
  pod 'SwiftyJSON', '~> 2.3'
end
```

```bash
$ pod install
```

[Carthage](https://github.com/Carthage/Carthage) 是另外的一个选择，它是在 Cocoa Touch Framework 和 Swift 发布后出现的专门针对 Framework 进行的包管理工具。

Carthage 相比 CocoaPods，采用的是完全不同的一条道路。Carthage 只支持动态框架，它仅负责将项目 clone 到本地并将对应的 Cocoa Framework target 进行构建。之后你需要自行将构建好的 framework 添加到项目中。和 CocoaPods 需要提交和维护框架信息不同，Carthage 是去中心化的
它直接从 git 仓库获取项目，而不需要依靠 podspec 类似的文件来管理。

使用上来说，Carthage 和 CocoaPods 类似之处在于也通过一个文件 `Cartfile` 来指定依赖关系。

```ruby
# Cartfile
github "ReactiveCocoa/ReactiveCocoa"
github "onevcat/Kingfisher" ~> 1.8
github "https://enterprise.local/hello/repo.git"
```

```bash
$ carthage update
```

在使用 Framework 的时候，我们需要将用到的框架 Embedded Binary 的方式链接到希望的 App target 中。

随着上个月 Swift 开源，有了新的可能的选项，那就是 [Swift Package Manager](https://swift.org/package-manager/)。这可能是未来的包管理方式，但是现在暂时不支持 iOS 和 tvOS （也就是说 UIKit 并不支持）。

Package Manager 实际上做的事情和 Carthage 相似，不过是通过 `llbuild` （low level build system）的跨平台编译工具将 Swift 编译为 .a 静态库。

这个项目很新，从去年 11 月才开始。不过因为是 Apple 官方支持，所以今后很可能会集成到 Xcode 工具链中，成为项目的标配，非常值得期待。但是现在暂时还无法用于应用开发。

## 创建框架

作为框架的用户你可能知道这些就能够很好地使用各个框架了。但是如果你想要创建一个框架的话，还远远不够。接下来我们说一说如何创建一个框架。

Xcode 为我们准备了 framework target 的模板，直接创建这个 target，就可以开始编写框架了。

添加源文件，编写代码，编译，完成，就是这么简单。

app 开发所得到产品直接面向最终用户；而框架开发得到的是一个中间产品，它面向的是其他开发者。对于一款 app，我们更注重使用各种手段来保证用户体验，最终目的是解决用户使用的问题。而框架的侧重点与 app 稍有不同，像是集成上的便利程度，使用上是否方便，升级的兼容等都需要考虑。虽然框架的开发和 app 的开发有不少不同，但是也有不少共通的规则和需要遵循的思维方式。

### API 设计

#### 最小化原则

基于框架开发的特点，相较于 app 开发，需要更着重地考虑 API 的设计。你标记为 public 的内容将是框架使用者能看到的内容。提供什么样的 API 在很大程度上决定了其他的开发者会如何使用你的框架。

在 API 设计的时候，从原则上来说，我们一开始可以提供尽可能少的接口来完成必要的任务，这有助于在框架初期控制框架的复杂程度。
之后随着逐步的开发和框架使用场景的扩展，我们可以添加公共接口或者将原来的 internal 或者 private 接口标记为 public 供外界使用。

```swift
// Do this
public func mustMethod() { ... }
func onlyUsedInFramework() { ... }
private func onlyUsedInFile() { ... }
```

```swift
// Don't do this
public func mustMethod() { ... }
public func onlyUsedInFramework() { ... }
public func onlyUsedInFile() { ... }
```

#### 命名考虑

在决定了 public 接口以后，我们很快就会迎来编程界的最难的问题之一，命名。

在 Objective-C 时代 Cocoa 开发的类型或者方法名称就以一个长字著称，Swift 时代保留了这个光荣传统。Swift 程序的命名应该尽量表意清晰，不用奇怪的缩写。在 Cocoa 的世界里，精确比简短更有吸引力。

几个例子，相比于简单的 `remove`，`removeAt` 更能表达出从一个集合类型中移除元素的方式。而 `remove` 可能导致误解，是移除特定的 int 还是从某个 index 移除？

```swift
// Do this
public mutating func removeAt(position: Index) -> Element
```

```swift
// Don't do this
public mutating func remove(i: Int) -> Element            
// <- index or element?
```

同样，`recursivelyFetch` 表达了递归地获取，而 `fetch` 很可能被理解为仅获取当前输入。

```swift
// Do this
public func recursivelyFetch(urls: [(String, Range<Version>)]) throws -> [T]
```

```swift
// Don't do this
public func fetch(urls: [(String, Range<Version>)]) throws -> [T] // <- how?
```

另外需要注意方法名应该是动词或者动词短语开头，而属性名应该是名词。当遇到冲突时，（比如这里的 displayName，既可以是名字也可以是动词）应该特别注意属性和方法的上下文造成的理解不同。更好的方式是避免名动皆可的词语，比如把 displayName 换为 screenName，就不会产生歧义了。

```swift
public var displayName: String
public var screenName: String // <- Better
```

```swift
// Don't do this
public func displayName() -> String 
// <- noun or verb? Why returning `String`?
```

在命名 API 时一个有用的诀窍是为你的 API 写文档。如果你用一句话无法将一个方法的内容表述清楚的话，这往往就意味着 API 的名字有改进的余地。好的 API 设计可以让有经验的开发者猜得八九不离十，看文档更多地只是为了确认细节。一个 API 如果能做到不需要看文档就能被使用，那么它肯定是成功的。

关于 API 的命名，Apple 官方给出了一个很详细的[指南](https://swift.org/documentation/api-design-guidelines/) (Swift API Design Guidelines)，相信每个开发者的必读内容。遵守这个准则，和其他开发者一道，用约定俗称的方式来进行编程和交流，这对提高框架质量非常，非常，非常重要（重要的事情要说三遍，如果你在我的演讲中只能记住一页的话，我希望是这一页。如果你还没有看过这个指南，建议去看一看，只需要花十分钟时间。）

#### 优先测试，测试驱动开发

你应该是你自己写的框架的第一个用户，最简单的使用你自己的框架的方式就是编写测试。据我所知，在 app 开发中，很多时候单元测试被忽视了。但是在框架开发中，这是很重要的一个环节。可能没有人会敢使用没有测试的框架。除了保证功能正确以外，通过测试，你可以发现框架中设计不合理的地方，并在第一时间进行改善。

为框架编写测试的方式和为 app 测试类似，
Swift 2 开始可以使用 @testable 来把框架引入到测试 module。这样的话可以调用 internal 方法。

不过对于框架来说，理论上只测试 public 就够了。但是我个人推荐使用 testable，来对一些重要的 internal 的方法也进行测试。这可以提高开发和交付时的信心。

```swift
// In Test Target
import XCTest
@testable import YourFramework
class FrameworkTypeTests: XCTestCase {
   // ...
}
```

---

### 开发时的选择

#### 命名冲突

在 Objective-C 中的 static library 里一个常见问题是同样的符号在链接时会导致冲突。

Swift 中我们可以通过 module 来提供类似命名空间隔离，从而避免符号冲突。但是在对系统已有的类添加 extension 的时候还是需要特别注意命名的问题。

```swift
   // F1.framework
   extension UIImage {
       public method() { print("F1") }
   }

   // F2.framework
   extension UIImage {
       public method() { print("F2") }
   }
```


比如在框架 F1 和 F2 中我们都对 UIImage 定义了 method 方法，分别就输出自己来自哪个框架。

如果我们需要在同一个文件里的话引入的话：

```swift
// app
import F1
import F2
UIImage().method()
// Ambiguous use of 'method()'
```

在 app 中的一个文件里同时 import F1 和 F2，就会产生编译错误，因为 F1 和 F2 都为同一个类型 UIImage 定义了 method，编译器无法确定使用哪个方法。

当然因为有 import 控制，在使用的时候注意一下源文件的划分，避免同时 import F1 和 F2，似乎就能解决这个问题。

```swift
// app
import F1
UIImage().method()
// 输出 F2 （结果不确定）
```


确实，只 import F1 的话，编译错误没有了，但是运行的时候有可能看到虽然 import 的是 F1，但是实际上调用到的是 F2 中的方法。

这是因为虽然有命名空间隔离，但 NSObject 的 extension 实际上还是依赖于 Objective-C runtime 的，这两个框架都在 app 启动时候被加载，运行时究竟调用了哪个方法是和加载顺序相关的，并不确定。

这种问题可以实际遇到的话，会非常难调试。

所以我们开发框架时的选择，对于已存在类型的 `extension`，**必须添加前缀**，
这和以前我们写 Objective-C 的 Category 的时候的原则是一样的。

上面的例子里，在开发的时候，不应该写这样的代码，而应该加上合适的前缀，以减少冲突的可能性。

```swift
// Do this
// F1.framework
extension UIImage {
  public f1_method() { print("F1") }
}

// F2.framework
extension UIImage {
  public f2_method() { print("F2") }
}
```

#### 资源 bundle

刚才提到过，framework 的一大优势是可以在自己的 bundle 中包含资源文件。在使用时，不需要关心框架的用户的环境，直接访问自己的类型的 bundle 就可以获取框架内的资源。

```swift
let bundle =
    NSBundle(forClass: ClassInFramework.self)
let path =
    bundle.pathForResource("resource", ofType: "png")
```


## 发布框架

最后说说发布和维护一个框架。辛苦制作的框架的最终目的其实就是让别人使用，一个没有人用的框架可以说是没有价值的。

如果你想让更多的人知道你的框架，那抛开各种爱国感情和个人喜好，可以说 iOS 或者 Swift 开发者的发布目的地只有一个，那就是 GitHub。

当然在像是开源中国或者 CSDN 这样的代码托管服务上发布也是很好的选择，但是不可否认的现状是只有在 GitHub 上你才能很方便地和全世界其他地方的开发者分享和交流你的代码。

### 选择依赖工具

关于发布，另外一个重要的问题，一般你需要选择支持一个或多个依赖管理工具。

#### CocoaPods

刚才也提到，CocoaPods 用 podspec 文件来描述项目信息，使用 CocoaPods 提供的命令行工具
可以创建一个 podspec 模板，我们要做的就是按照项目的情况编辑这个文件。
比如这里列出了一个podspec的基本结构，可以看到包含了很多项目信息。关于更详细的用法，可以参看 CocoaPods 的[文档](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)。

```bash
pod spec create MyFramework
```

```swift
Pod::Spec.new do |s|
  s.name         = "MyFramework"
  s.version      = "1.0.2"
  s.summary      = "My first framework"
  s.description  = <<-DESC
                    It's my first framework.
                   DESC
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/onevcat/myframework.git", 
                     :tag => s.version }

  s.source_files  = "Class/*.{h,swift}"
  s.public_header_files = ["MyFramework/MyFramework.h"]
end
```

提交到 CocoaPods 也很简单，使用它们的命令行工具来检查 podspec 语法和项目是否正常编译，最后推送 podspec 到 CocoaPods 的主仓库就可以了。

```bash
# 打 tag
git tag 1.0.2 && git push origin --tags

# podspec 文法检查
pod spec lint MyFramework.podspec

# 提交到 CocoaPods 中心仓库
pod trunk push MyFramework.podspec
```

#### Carthage

另一个应该考虑尽量支持的是 Carthage，因为它的用户数量也不可小觑。
支持 Carthage 比 CocoaPods 要简单很多，你需要做的只是保证你的框架 target 能正确编译，然后在 Manage Scheme 里把这个 target 标记为 Shared 就行了。

#### Swift Package Manager

Swift Package Manager 暂时还不能用于 iOS 项目的依赖管理，但是对于那些并不依赖 iOS 平台的框架来说，现在就可以开始支持 Swift Package Manager 了。

Swift Package Manager 按照文件夹组织来确定模块，你需要把你的代码放到项目根目录下的 Sources 文件夹里。

然后在根目录下创建 Package.swift 文件来定义 package 信息。这就是一个普通的 swift 源码文件，你需要做的是在里面定义一个 package 成员，为它指定名字和依赖关系等等。Package Manager 命令将根据这个文件和文件夹的层次来构建你的框架。

```swift
// Package.swift
import PackageDescription  
let package = Package(
    name: "MyKit",
    dependencies: [
        .Package(url: "https://github.com/onevcat/anotherPacakge.git",
                 majorVersion: 1)
    ]
)
```

### 版本管理

在发布时另外一个需要特别注意的是版本。在 Podfile 或者 Cartfile 中指定依赖版本的时候我们可以看到类似这样的小飘箭头的符号，这代表版本兼容。比如兼容 2.6.1 表示高于 2.6.1 的 2.6.x 版本都可以使用，而 2.7 或以上不行；同理，如果兼容 2.6 的话，2.6，2.7，2.8 等等这些版本都是兼容的，而 3.0 不行。当然也可以使用 >= 或者是 = 这些符号。

```ruby
# Podfile
pod 'AFNetworking', '~> 2.6.1'
# 2.6.x 兼容 (2.6.1, 2.6.2, 2.6.9 等，不包含 2.7)

# Podfile
pod 'AFNetworking', '~> 2.6'
# 2.x 兼容 (2.6.1, 2.7, 2.8 等，不包含 3.0)

# Cartfile
github "Mantle/Mantle" >= 1.1
# 大于等于 1.1 (1.1，1.1.4, 1.3, 2.1 等)
```

#### Semantic Versioning 和版本兼容

那什么叫版本兼容呢？我们看到的这套版本管理的方法叫做 [Semantic Versioning](http://semver.org)。它一般通过三个数字来定义版本。

> `x(major).y(minor).z(patch)`

- major - 公共 API 改动或者删减
- minor - 新添加了公共 API
- patch - bug 修正等
- `0.x.y` 只遵守最后一条

major 的更改表示用户必须修改自己的代码才能继续使用框架；minor 表示框架添加了新的 API，但是现有用户不需要修改代码可以保持原有行为不变；而 patch 则代表 API 没有改变，仅只是内部修正。

在这个约定下，同样的 major 版本号就意味着用户不需要修改现有代码就能继续使用这个框架，所以这是使用最广的一个依赖方式，在这个兼容保证下，用户可以自由升级 minor 版本号。

但是有一个例外，那就是还没有正式到达 1.0.0 版本号的框架。
这种框架代表还在早期开发，没有正式发布，API 还在调整中，开发者只需要遵守 patch 的规则，也就是说 0.1.1 和 0.1.2 只有小的修正。但是 0.2 和 0.1 是可以完全不兼容。如果你正在使用一个未正式发布的框架的时候，需要小心这一点。

框架的版本应该和 git 的 tag 对应，这可以和大多数版本管理工具兼容
一般来说用户会默认你的框架时遵循 Semantic Versioning 和兼容规则。

我们在设置版本的时候可能会注意到 Info.plist 中的 Version 和 Build 这两个值。虽然 CocoaPods 或者 Carthage 这样的包管理系统并不是使用 Info.plist 里的内容来确定依赖关系，但是我们最好还是保持这里的版本号和 git tag 的一致性。

当我们编译框架项目的时候，会在头文件或者 module map 里看到这样的定义。
框架的用户想要在运行时知道所使用的框架的版本号的话，使用这些属性会十分方便。这在做框架版本迁移的时候可能会有用。所以作为开发者，也应该维护这两个值来帮助我们确定框架版本。

```c
// MyFramework.h
//! Project version string for MyFramework.
FOUNDATION_EXPORT const unsigned char MyFrameworkVersionString[]; // 1.8.3
//! Project version number for MyFramework.
FOUNDATION_EXPORT double MyFrameworkVersionNumber; // 347

// Exported module map
//! Project version number for MyFramework.
public var MyFrameworkVersionNumber: Double
// 并没有导出 MyFrameworkVersionString
```

### 持续集成

在框架开发中，一个优秀的持续集成环境是至关重要的。CI 可以保证潜在的贡献者在有保障的情况下对代码进行修改，减小了框架的维护压力。大部分 CI 环境对于开源项目都是免费的，得益于此，我们可以利用这个星球上最优秀的 CI 来确保我们的代码正常工作。

就 iOS 或者 OSX 开发来说，Travis CI, CircleCI, Coveralls，Codecov 等都是很好的选择。

开发总是有趣的，但是发布一般都很无聊。因为发布流程每次都一样，非常机械。无非就是跑测试，打 tag，上传代码，写 release log，更新 podspec 等等。虽然简单，但是费时费力，容易出错。对于这种情景，自动化流程显然是最好的选择。而相比于自己写发布脚本，在 Cocoa 社区我们有更好的工具，那就是 [fastlane](https://fastlane.tools)。

fastlane 是一系列 Cocoa 开发的工具的集合，包括跑测试，打包 app，自动截图，管理 iTunes Connect 等等。

不单单是 app 开发，在框架开发中，我们也可以利用到 fastlane 里很多很方便的命令。

使用 fastlane 做持续发布很简单，建立自己的合适的 Fastfile 文件，然后把你想做什么写进去就好了。比如这里是一个简单的 Fastfile 的例子：

```ruby
# Fastfile
desc "Release new version"
lane :release do |options|
  target_version = options[:version]
  raise "The version is missed." if target_version.nil?
  ensure_git_branch                                             # 确认 master 分支
  ensure_git_status_clean                                       # 确认没有未提交的文件
  scan                                                          # 运行测试

  sync_build_number_to_git                                      # 将 build 号设为 git commit 数
  increment_version_number(version_number: target_version)      # 设置版本号

  version_bump_podspec(path: "Kingfisher.podspec",
             version_number: target_version)                    # 更新 podspec
  git_commit_all(message: "Bump version to #{target_version}")  # 提交版本号修改
  add_git_tag tag: target_version                               # 设置 tag
  push_to_git_remote                                            # 推送到 git 仓库
  pod_push                                                      # 提交到 CocoaPods
end

$ fastlane release version:1.8.4
```

AFNetworking 在 3.0 版本开始加入了 fastlane 做自动集成和发布，可以说把开源项目的 CI 做到了极致。在这里强烈推荐大家有空可以看一看[这个项目](https://github.com/AFNetworking/fastlane)，除了使用 fastlane 简化流程以外，这个项目里还介绍了一些发布框架时的最佳实践。

我们能不能创造出像 AFNetworking 这样优秀的框架呢？一个优秀的框架包含哪些要求？

### 创建一个优秀的框架

一个优秀的框架必定包含这些特性：详尽的文档说明，可以指导后来开发者或者协作者迅速上手的注释，

完善的测试保证功能正确以及不发生退化，简短易读可维护的代码，可以让使用者了解版本变化的更新日志，对于issue的解答等等。

我们知道在科技界或者说 IT 界会有很多喜欢跑分的朋友。其实跑分这个事情可以辩证来看，它有其有意义的一面。跑分高的不一定优秀，但是优秀的跑分一般一定都会高。

不止在硬件类的产品，其实在框架开发中我们其实也可以做类似的跑分来检验我们的框架质量如何。

那就是 [CocoaPods Quality](https://cocoapods.org/pods/Kingfisher/quality)，它是一个给开源框架打分的索引类的项目，会按照项目的受欢迎程度和完整度，并基于我们上面说的这些标准来对项目质量进行评判。

对于框架使用者来说，这可以成为一个选择框架时的[重要参考](https://guides.cocoapods.org/making/quality-indexes)，分数越高基本可以确定可能遇到的坑会越少。

而对于框架的开发者来说，努力提高这个分数的同时，代码和框架质量肯定也得到了提高，这是一个自我完善的良好途径。在遇到功能类似的框架，我们也可以说“不服？跑个分”

### 可能的问题

最后想和大家探讨一下在框架开发中几个比较常见和需要特别注意的问题。

首先是兼容性的保证这里的兼容性不是 API 的兼容性，而是逻辑上的兼容性。
最可能出现问题的地方就是在不同版本中对数据持久化部分的处理是否兼容，
包括数据库和Key-archiving。比如在新版本中添加了一个属性，如何从老版本中进行迁移如果处理不当，很可能就造成严重错误甚至 crash。

另一个问题是重复的依赖。Swift 运行时还没有包含在设备中，如果对于框架，将 `EMBEDDED_CONTENT_CONTAINS_SWIFT` 设为 `YES` 的话，Swift 运行库将会被复制到框架中，这不是我们想见到的。在框架开发中这个 flag 一定是 NO，我们应该在 app 的 target 中进行设置。另外，可能你的框架会依赖其他框架，不要在项目中通过 copy file 把依赖的框架 copy 到框架 target 中，而是应该通过 Podfile 和 Cartfile 来解决依赖问题。

在决定框架依赖的时候，可能遇到的最大的问题就是不同框架的依赖可能[无法兼容](https://github.com/apple/swift-package-manager/blob/master/Documentation/DependencyHells.md)。

比如说一个 app 同时依赖了框架 A 和框架 B，而这两个框架又都依赖另一个框架 C。如果 A 中指定了兼容 1.1.2 而 B 中指定的是精确的 1.6.1 的话，app 的依赖关系就无法兼容了。

在框架开发中，如果我们依赖了别的框架，就必须考虑和其他框架及应用的兼容。
为了避免这种依赖无法满足的情况，我们最好尽量选择最宽松的依赖关系。

一般情况下我们没有必要限定依赖的版本，如果被依赖的框架遵守我们上面提到的版本管理的规则的话，我们并没有必要去选择固定某一个版本，而应该尽可能放宽依赖限制以避免无法兼容。

如果在使用框架中遇到这样的情况的话，去向依赖版本较旧的框架的维护者提 issue 或者发 pull request 会是好选择。

有一些开发者表示在转向使用 Framework 以后遇到首次应用加载速度变长的问题 ([参考 1](https://github.com/artsy/eigen/issues/586)，[参考 2](rdar://22948371](http://openradar.appspot.com/radar?id=4867644041723904))。

社区讨论和探索结果表明可能是 Dynamic linker 在验证证书的时候的问题。
这个时间和 app 中 dynamic framework 的数量为 n^2 时间复杂度。不过现在大家发现这可能是 Apple 在证书管理上的一个 bug，应该是只发生在开发阶段。可能现在比较安全的做法是控制使用的框架数量在合理范围之内，就我们公司的产品来说，并没有在生产环境遇到这个问题。如果你在 app 开发中遇到类似情况，这算是一个小提醒。

最后，因为现在 Swift 现在 Binary Interface 还没有稳定，不论是框架还是应用项目中所有的 Swift 代码都必须用同样版本的编译器进行编译。就是说，每当 Swift 版本升级，原来 build 过的 framework 需要重新构建否则无法通过编译。对框架开发者来说，保持使用最新 release 版本的编译器来发布框架就不会有大的问题。

在 Swift 3.0 以后语言的二进制接口将会稳定，届时 Swift 也将被集成到 iOS 系统中。也就是说到今年下半年的话这个问题就将不再存在。

## 从今天开始开发框架

做一个小的总结。现在这个时机对于中国的 Cocoa 开发者来说是非常好的时代，GitHub 中国用户很多，国内 iOS 开发圈子大家的分享精神和新东西的传播速度也非常快。可以说，我们中国开发者正在离这个世界的中心舞台越来越近，只要出现好东西的话，应该很快就能得到国内开发者的关注，继而登上 GitHub Trending 页面被世界所知。不要说五年，可能在两年之前，这都是难以想象的。

> Write the code, change the world.

Swift 是随着这句口号诞生的，而现在开发者改变这个世界的力度可以说是前所未有的。

对于国内的开发者来说，我们真的应该希望少一些像 MingGeJS 这样的东西，而多一些能帮助这个世界的项目，以认真的态度多写一些有意义的代码，回馈开源社区，这于人于己都是一件好事。

希望中国的开发者能够在 Swift 这个新时代创造出更多世界级的框架，让这些框架能帮助全球的开发者一起构建更优秀的软件。
