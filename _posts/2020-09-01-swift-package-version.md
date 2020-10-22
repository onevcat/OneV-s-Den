---
layout: post
title: "Package.swift toolchain 版本的选择"
date: 2020-09-05 12:00:00.000000000 +09:00
categories: [能工巧匠集, Swift]
tags: [swift, spm, 工具链, 最佳实践, wwdc]
---

WWDC 2020 上 Swift Package Manager (SPM) 开始支持 [Resource bundle](https://developer.apple.com/videos/play/wwdc2020/10169/) 和 [Binary Framework](https://developer.apple.com/videos/play/wwdc2020/10147/)。对于 Package 的维护者来说，如果有需求，当然是应该尽快适配这些内容。首先要做的，就是将 Package.swift 中的 Swift Toolchain 版本改到最新的 5.3：只有最新的 tool chain 才具备这些功能。

```
// swift-tools-version:5.3
```

但是，如果之前你就支持了 SPM 的话，直接在 Package.swift 文件上进行修改，会破坏旧版本的兼容性。比如 5.3 的 toolchain 是集成在 Xcode 12 中的，如果这样改动以后，现有的使用 Xcode 11 的用户由于 toolchain 版本过低，就无法再 build 这个 package，造成问题。

> package at 'xxx' is using Swift tools version 5.3.0 but the installed version is 5.2.0

你不能假设用户永远都使用最新的版本，不顾兼容性的更新也会带来严重的后果。那要如何让一个 package 支持多个版本的 toolchain 呢？

### Package.swift 文件后缀

你可能已经看到过，有的项目中 (比如 [PromiseKit](https://github.com/mxcl/PromiseKit)) 会有多个 Package.swift 的声明：它们带有不同的后缀，比如 `Package.swift`，`Package@swift-4.2.swift` 或者 `Package@swift-5.3.swift`。SPM 在选取声明文件时，会按照当前 toolchain 版本从新到旧，去选取最近的一个兼容版本的文件。举个几个例子，上面三个文件存在的情况下：

- 如果安装了带有 5.3 的 Xcode 12，则选取使用 `Package@swift-5.3.swift`；
- 如果运行环境是 5.1 的 Xcode 11，则跳过 `Package@swift-5.3.swift` (由于不符合最低版本)。同时，由于不存在 `Package@swift-5.1.swift` 这一恰好兼容的版本，SPM 会向下寻找最近的一个兼容版本，即 转而使用 `Package@swift-4.2.swift`。
- 如果 toolchain 版本甚至低于 4.2，那么所有带有后缀的声明文件都会被跳过，而去使用 `Package.swift`。

### swift-tools-version

在选取了合适的 Package.swift 文件后，第一行的 `swift-tools-version` 注释将会最终决定实际使用的 toolchain 版本。虽然没有强制要求这个注释指定的版本号必须和 `Package@swift-x.y.swift` 文件名中的版本号一致，但是选取不同的数字显然会引起不必要的误解。

## 那我该怎么做呢

因此，在添加 SPM 新版本支持的时候，正确的做法是：

1. 创建 package 时，在 `Package.swift` 的首行中，声明你的 package 所能支持的最低的 toolchain 版本。
2. 保持现有的所有 `Package.swift` 和 `Package@swift-a.b.swift` 不变：这可以让旧版本的 toolchain 继续使用已有的 package 描述。
3. 为新版本 `x.y` 添加 `Package@swift-x.y.swift` 文件，并在文件中首行将 toolchain 版本设置为同样的版本，即 `// swift-tools-version:x.y`。然后为新版编写合适的 package 声明。

你可以通过切换 Xcode 中的 Command Line Tools 设定，并使用下面的命令来检查当前设定下所被选用的 toolchain version。

```
$ swift package tools-version
```

确保每个组合都按照预想工作，就这么简单。
