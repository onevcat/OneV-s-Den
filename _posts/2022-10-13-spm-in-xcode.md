---
layout: post
title: "Xcode 中使用 SPM 和 Build Configuration 的一些坑"
date: 2022-10-14 11:00:00.000000000 +09:00
categories: [能工巧匠集, SwiftUI]
tags: [swift, xcode, spm, 编译器]
typora-root-url: ..
---

## TL;DR

当前，在 Xcode 中使用 Swift Package Manager 的包时，SPM 在编译 package 时将参照 Build Configuration 的**名字**，**自动选择**使用 debug 还是 release 来编译，这决定了像是 `DEBUG` 这样的编译 flag 以及最终的二进制产品的架构。在 Xcode 中使用默认的 "Debug" 和 "Release" 之外的自定义的 Build Configuration 时，这个自动选择可能会造成问题。

现在 (2022 年 10 月) 还并没有特别好的方式将 Xcode 中 Build Configuration 映射到 SPM 的编译环境中去。希望未来版本的 Xcode 和 SPM 能有所改善。

{: .alert .alert-info}
关于文中的一些例子，可以[在这里找到源码](https://github.com/onevcat/SPMConfigDemo)。

## Xcode 和 SPM 中的编译条件

### 默认的 DEBUG 编译条件

在 Xcode 中，创建项目时我们会自动得到两个 Build Configuration：Debug 和 Release。

![](/assets/images/2022/xcode-configurations.png)

在 `SWIFT_ACTIVE_COMPILATION_CONDITIONS` 中，Debug Configuration 预定义了 `DEBUG` 条件：

![](/assets/images/2022/xcode-configurations-debug.png)

这允许我们用类似这样的代码来在 Debug 和 Release 时编译不同的内容：

```swift
// In app
#if DEBUG
public let appContainsDebugFlag = true
#else
public let appContainsDebugFlag = false
#endif
```

从 Xcode 11 开始，我们可以直接在 Xcode 里[使用 SPM 来添加框架](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)。在 package 中，我们也可以使用同样的代码方式来进行区分：

```swift
// In package
public struct MyLibrary {
    #if DEBUG
    public static let libContainsDebugFlag = true
    #else
    public static let libContainsDebugFlag = false
    #endif
}
```

为了观察，可以把这些结果放到 UI 上：

```swift
Form {
  Section("DEBUG flag") {
    Text("App: \(appContainsDebugFlag ? "YES" : "NO")")
    Text("Package: \(MyLibrary.libContainsDebugFlag ? "YES" : "NO")")
  }
}.monospaced()
```

使用 Xcode 默认的 Debug Configuration 运行，得到如下结果，一些都很美好：

![](/assets/images/2022/xcode-run-debug.png)

### 自定义编译条件

但是，Package 里的这个 `DEBUG` 条件，**并不是**通过把 Xcode 项目里的 `SWIFT_ACTIVE_COMPILATION_CONDITIONS` 传递到 SPM 来实现的。想要验证这一点，我们可以在 Xcode 中添加一个新的 condition，比如 `CUSTOM`：

![](/assets/images/2022/xcode-custom-flag.png)


类似 `#if DEBUG` 那样，为 `CUSTOM` 也添加一个属性：

```swift
// In package
#if CUSTOM
public static let libContainsCustomFlag = true
#else
public static let libContainsCustomFlag = false
#endif
    
// In app
#if CUSTOM
public let appContainsCustomFlag = true
#else
public let appContainsCustomFlag = false
#endif
```

很不幸，这个 `CUSTOM` 条件在 package 中并不生效：

![](/assets/images/2022/xcode-run-custom-flag.png)

如果对 build log 进行一些确认，可以看到，对于 app target，`DEBUG` 和 `CUSTOM` 都被正确传递给了编译命令。但是在编译 package 时，给入的条件为：

```
SwiftCompile normal arm64 Compiling\ MyLibrary.swift
...
builtin-swiftTaskExecution .. -D SWIFT_PACKAGE -D DEBUG -D Xcode ...
```

在 Xcode 14.0，传入的条件有 `SWIFT_PACKAGE`，`DEBUG` 和 `Xcode`；`CUSTOM` 不在此列。

在本文写作时，SPM 只提供两个 [Build Configuration](https://developer.apple.com/documentation/packagedescription/buildconfiguration)，`.debug` 和 `.release`：

```swift
public struct BuildConfiguration : Encodable {

    /// The debug build configuration.
    public static let debug: PackageDescription.BuildConfiguration

    /// The release build configuration.
    public static let release: PackageDescription.BuildConfiguration
}
```

SPM [本身支持为某个 Configuration 自定义条件](https://developer.apple.com/documentation/packagedescription/swiftsetting/define(_:_:))，对于自己拥有控制权的 package，我们可以通过在 Package.swift 中添加 `swiftSettings` 来传递这个 condition：

```swift-diff
...
targets: [
  .target(
    name: "MyLibrary",
    dependencies: [],
+   swiftSettings: [.define("CUSTOM", .when(configuration: .debug))]
  ),
  ...
```

对于那些直接从 git 仓库添加的外部包，默认情况下其内容是锁定的。如果只是需要暂时传入一个编译 condition 的话，可以通过[将它转换为本地包](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package)，然后进行和上面类似的操作为其添加 `swiftSettings`。如果需要长期的解决方案，可以考虑自己再对需要的外部包进行一次封装：创建一个新的依赖这些外部包的 Swift package，然后在将它们暴露出来的时候添加上合适的 `swiftSettings`。

> 作为包的维护者，如果我们在包里使用了除 `DEBUG` 外的编译条件，最好也相应地在 Package.swift 中进行添加。用户在使用 Xcode 编译你的包时，Xcode 会尊重这些设置。

## 基于 Build Configuration 的判定

当 Xcode 选择使用 `.debug` 去编译 SPM 包时，它按照 Xcode 通用的编译条件，“自动地”传入 `DEBUG`。但是什么时候 Xcode 会去选择使用 `.debug`，什么时候它选择用 `.release` 呢？

答案可能让人大跌眼镜。在 Xcode 环境下，Xcode 会基于 Build Configuration 的名字，来选择 SPM 包的所使用的编译配置。具体来说，暂时发现的规则有：

- 如果名字里包含有 `Debug` 或者 `Development` (不区分大小写)，那么 Xcode 会使用 `.debug` 来编译 SPM 包。比如默认的 `Debug`，以及 `Development`，`Debug_Testing`，`_development_`，`Not_DEBUG`，`hello development` 都在此列。
- 否则，使用 `.release` 进行编译。比如默认的 `Release`，以及像是 `Dev`，`Testing`，`Staging`，`Prod`，`Beta`，`QA`，`CI` 等等，都会使用 `.release` 作为编译配置。

![](/assets/images/2022/xcode-configurations-rename.png)

Xcode 在这里选取了“经验主义”和自以为是的做法，当 SPM 被使用在 Xcode 中时，自定义 Build Configuration 的名字就变成了一个笑话。当你辛辛苦苦为项目配置了一个 `Testing` 的编译配置，打算用来专门跑测试时，你会发现这个配置下编译出来的 Swift package 都经过了优化并被去掉了 testable 支持。想要让 SPM 能按照预想工作，你必须将 Xcode 中的 Build Configuration 命名改回去，比如把它叫做 `Debug_Testing`。

这些规则写在了 Xcode 的编译工具链中，它们并非开源代码，现在也并没有任何文档对这件事进行说明和规定，所以它们是有可能在未来被随意改变的。比较安全的做法，是老老实实就只使用默认的 `Debug` 和 `Release` 两个 Build Configuration。当需要更多环境 (比如用来为不同环境设置不同的 bundle id 或者 app 名字) 时，也许可以选择使用多个 scheme 并为它们配置合适的环境变量来进行区分。

## 编译架构和 Apple Silicon

除了 `DEBUG` flag 之外，Xcode 在为 SPM 包选取编译配置后，还会根据 `.debug` 和 `.release` 为包自动选取需要编译的架构。对于 `.release` 配置，情况比较简单：`ONLY_ACTIVE_ARCH` 被设置为 false，按照当前 Xcode 版本定义的 Standard Architecture 编译多个架构的二进制文件；对于 `.debug` 的话，则会将 `ONLY_ACTIVE_ARCH` 置为 true，根据 mac 设备和目标设备 (模拟器或者真机) 来决定一个编译架构。

### 在模拟器上排除 arm64 导致的问题

在 Apple Silicon 的时代，默认情况下 Xcode 会使用 arm64 架构运行。这时候，自带的 iOS 模拟器也会跑在 arm64 下。如果你在项目里使用了一些老旧的以二进制发布的库，比如 fat binary 做的 framework，或者是不包含模拟器 arm64 的 .a 的文件，那么很可能在 Apple Silicon 的 mac 上，以模拟器为目标进行链接时，看到类似这样的错误：

{: .alert .alert-danger}
building for iOS Simulator, but linking in object file built for iOS, for architecture arm64

这是因为虽然库中包含了 arm64，但是其中标明了它是用在实际设备而非模拟器上的。[网络上常见的办法](https://stackoverflow.com/a/63955114)，会教你在 `EXCLUDED_ARCHS` 里为 simulator 添加 `arm64`，用来把这个架构排除出去。

```
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
```

这是一个治标不治本的“快速疗法”，加入这个设定可以让你编译通过并运行，但是你需要清楚了解到这么做的弊端：因为 arm64 被排除了，所以在 iOS 模拟器上，只有 x86_64 这一个架构选择。这意味着你的整个 app 都会以 x86_64 进行编译，然后跑在 x86_64 的模拟器上。而在 Apple Silicon 的 mac 上，这个模拟器其实是使用 Rosetta 2 跑起来的，这意味着性能的大幅下降。

而更为致命的是，这个方法在和 SPM 一起使用时，会更加麻烦。

因为 Xcode 不会将你设定的 `EXCLUDED_ARCHS` 传递给 SPM，所以在针对模拟器编译时，你会遇到这样的问题：

{: .alert .alert-danger}
Could not find module 'MyLibrary' for target 'x86_64-apple-ios-simulator'; found: arm64-apple-ios-simulator

对于 `.debug`，`ONLY_ACTIVE_ARCH` 为 true，编译目标为 arm64 的 iOS 模拟器，因此 SPM 只会给出 arm64-apple-ios-simulator 版本的编译结果。但是项目本身设定了 `EXCLUDED_ARCHS` arm64，它在链接包时，需要的其实是 x86_64 模拟器版本的包。砰！

> 对于老旧二进制的依赖，最正确的做法是催促维护者赶快适配 xcframework。另一种可行的方案，是 hack 一下二进制，修改 arm64 slice 的目标字段，“欺骗” Xcode 让它认为这个二进制的 arm64 就是为模拟器编译的。这种方法[在这里有详细解释](https://bogo.wtf/arm64-to-sim.html)，作者也发布了[相关的 arm64-to-sim 工具](https://github.com/bogo/arm64-to-sim)，如有需要，可以暂时酌情使用。

### 意外和意外的叠加

理解了 Xcode 中 SPM 选取 Build Configuration 的原理，以及编译架构的关系，我们就可以用“以毒攻毒”的方式“解决”上面的问题。

最简单的方法就是修改 Xcode 中 Build Configuration 的名字，比如把 `Debug` 改成 `Dev`。这样一来，SPM 会选取 `.release` 来编译 Swift 包，此时它会把所有支持的架构都进行编译。在 app target 中即使我们排除了 arm64，链接时因为 x86_64 的 Swift 包的编译结果也存在，因此可以正常找到所需的架构进行链接。

这种用一个“意外”来修正另一个“意外”的做法虽然很愚蠢，但是也还算有效。

带来的最大的副作用有两个：

1. 因为要使用 `.release` 进行包的编译，这不仅会需要编译不必要的架构，也需要进行额外的编译优化，将导致包的编译速度降低。
2. 因为包被 release 优化了，所以 debug 会变得困难：比如在包中设置的断点可能无法工作，`po` 的输出可能出现问题等。

## 小结

想要从根本上解决这些问题，需要 Xcode 中的 SPM 提供一些手段，让我们可以将 Xcode 的 Build Configuration (包括各种编译 flag 的设定) 映射到 SPM 的 Build Configuration 上。社区设想的 [Package Flavors](https://github.com/swift-embedded/swift-package-manager/blob/embedded-5.1/Documentation/Internals/PackageManagerCommunityProposal.md#package-flavors) 可以解决这个问题，但是这个课题需要涉及到 Xcode 的实现，所以需要 Apple 官方进行修改。但不幸的是，现在我们还没有看到 Apple 对此做出公开和积极的响应。

在成熟解决方案问世之前，我们能做的事情是相当有限的，总结一下：

- 尽量不去自定义 Build Configuration 的名字。如果确实需要修改，理解编译配置的名字对 SPM 编译可能产生的影响。
- 如果需要用到二进制库，尽量使用包含所有架构的 xcframework 格式。如果没有提供，可以考虑使用 arm64-to-sim 把为设备编译的 arm64 转换为模拟器的 arm64。
- 常规方式绕不过的话，可以创建自己的 wrapper package，在 Package.swift 中传递需要的编译参数。
- 在 Apple Silicon 上如果实在没办法的话，可以尝试使用 Rosetta 运行 Xcode 作为临时解决方案。
