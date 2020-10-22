---
layout: post
title: "一些关于 App Clips 的笔记"
date: 2020-06-23 12:00:00.000000000 +09:00
categories: [能工巧匠集, WWDC]
tags: [app clips, wwdc, 用户体验]
---

App clips 是今天 WWDC 上 iOS 14 的一个重要“卖点”，它提供了一种“即时使用”的方式，让用户可以在特定时间、特定场景，在不下载完整 app 的前提下，体验到你的 app 的核心功能。

装好 Xcode 12 以后第一时间体验了一下如何为 app 添加 app clip。它的创建和使用都很简单，也没有什么新的 API，所以要为 app 开发一个 clip 的话，难点更多地在于配置、代码的复用以及尺寸优化等。在阅读文档和实际体验的同时，顺便整理了一些要点，作为备忘。

### App clips 的一些基本事实和添加步骤

在写作本文时 (2020.06.23)，通过文档和实践能获知的关于 app clips 的几点情况：

- 一个 app 能且只能拥有一个 app clip。
- 通过在一个 app project 中添加 app clip target 就能很简单地创建一个 app clip 了。

    ![](/assets/images/2020/app_clip_target_add.png)

- App clip 的**结构和普通的 app 毫无二致**。你可以使用绝大多数的框架，包括 SwiftUI 和 UIKit ([不能使用的](https://developer.apple.com/documentation/app_clips/developing_a_great_app_clip#3625585)都是一些冷门框架和隐私相关的框架，比如 CallKit 和 HomeKit 等 )。所以 app clip 的开发非常简单，你可以使用所有你已经熟知的技术：创建 `UIViewController`，组织 `UIView`，用 `URLSession` 发送请求等等。和小程序这种 H5 技术不同，app clip 就是一个 native 的几乎“什么都能做”的“简化版”的 app。
- App clip 所包含的功能必须是 main app 的子集。App clip 的 bundle ID 必须是 main app 的 bundle ID 后缀加上 `.Clip` (在 Xcode 中创建 app clip target 时会自动帮你搞定)。
- 域名和 server 配置方面，和支持 Universal Link 以及 Web Credentials 的时候要做的事情非常相似：你需要为 app clip 的 target 添加 Associated Domain，格式为 `appclips:yourdomain.com`；然后在 server 的 App Site Association (通常是在网站 `.well-known` 下的 `apple-app-site-association` 文件) 中添加这个域名对应的 `appclips` 条目：

```javascript
{
  "appclips": {
    "apps": ["ABCED12345.com.example.MyApp.Clip"]
  }
} 
```

- 默认最简单的情况下，app clip **通过 Safari App Banner 或者 iMessage app 中的符合 domain 要求的 URL 下载和启动**。这种启动方式叫做 Default App Clip Experience。

- 一个能够启动 app clip 的 App Banner 形式如下：

```xml
<meta 
  name="apple-itunes-app" 
  content="app-id=myAppStoreID, app-clip-bundle-id=appClipBundleID
>
```

- 你的 app clip 在被真正调用前，系统会显示一个 app clip card。对于 Default App Clip Experience，你可以在 App Store Connect 中为这种启动方式提供固定的图片，标题文本和按钮文本。（现在版本的  App Store Connect 中似乎还没有设置的地方，应该是 iOS 14 正式发布后会添加）。

    ![](/assets/images/2020/app_clip_parts.png)

- App clip card 显示时，你的 app clip 就已经开始下载了。App clip 的**体积必须在 10MB 以内**。这样，大概率在用户选择打开你的 app clip 之前，就能下载完成，以提供良好体验。
- 用户点击 banner 或者 iMessage 链接，且继续点击打开按钮后，app clip 的 user activity 关联的生命周期函数将被调用，根据你所使用的技术不同，它将是 [`onContinueUserActivity(_:perform:)`](https://developer.apple.com/documentation/swiftui/view/oncontinueuseractivity(_:perform:)) (SwiftUI)，[`scene(_:willContinueUserActivityWithType:)`](https://developer.apple.com/documentation/uikit/uiscenedelegate/3238060-scene) (Scene-Based app) 或者 [`application(_:continue:restorationHandler:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application) (App Delegate app) 之一。获取到唤醒 app clip 的 `NSUserActivity` 后，就可以通过 `webpageURL` 获取到调用的链接了(Banner 所在页面的链接，或 iMessage 中点击的链接)。
- 根据唤醒 app clip 的 URL，用 UIKit 或 SwiftUI 完成对应的 UI 构建和展示。因为 App Clip 需要是 main app 的子集，因此一般来说这些 URL (以及对应的 `NSUserActivity`) 也需要能被 main app 处理。当 main app 已经被安装时，唤醒的会是 main app。
- 对于更复杂的唤醒情况，可以根据 URL 的不同、甚至是地点的不同，来提供不一样的 app clip card。这部分内容也是通过 App Store Connect 进行配置的。这类启动方式被称为 Advanced App Clip Experiences。
- 在开发时，可以通过设置 `_XCAppClipURL` 这个环境变量，并运行 app clip target 来“模拟”通过特定 URL 点击后的情况。当 Associated Domain 设置正确后，在 Xcode 中运行 app clip，就可以拿到包含这个环境值的 `NSUserActivity`。这样在 Beta 期间的本地开发就不需要依赖外部 server 环境了。

    ![](/assets/images/2020/app_clip_url_env.png)
    
- 关于代码和资源的组织。很大机率 main app 和 app clip 是需要共用代码的，可以无脑地选择将源码放到 main app 和 app clip 两个 target 中，也可以选择打成 framework 或者 local Swift Package。不管如何，这部分共用的 binary 都会同时存在于 main app bundle 和 app clip bundle 中。图片等素材资源也类似。简单说，app clip 其实就是一个完整但尺寸有所限制、并且和某个域名绑定，因此不需要用户认证 Apple ID 就可以下载的 app。
- 部分 app clip 是“用完就走”的，但是也有部分 app clip 是为了导流到 main app。可以通过 `SKOverlay` 或 `SKStoreProductViewController` 来显示一个指向 main app 的推广窗：

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
  // 处理 userActivity ...
  
  if let scene = scene as? UIWindowScene {
    let overlay = SKOverlay(configuration: SKOverlay.AppClipConfiguration(position: .bottom))
    overlay.present(in: scene)
  }
}
```

![](/assets/images/2020/app_clip_skoverlay.png)

- 如果在 app clip 中有用户注册/登录和支付需求的话，Apple 推荐使用 Sign in with Apple 和 Apple Pay 来简化流程。虽然在 app clip 中，所有的 UI 操作和导航关系都是支持的 (手势，modal present，navigation push 等等)，但 app clip 应该尽量避免 tab 或者很长的表单这类复杂交互，让用户能直奔主题。

### 一些初步的思考和展望

所以今后，一个有追求的 iOS app 将会有两个 .app 的 bundle：一个完整的原始版本，一个快速搞定核心功能的 lite 版本。不过悲剧的是，国内的 iOS 生态面临崩溃，微信小程序的地位不可撼动，所以 app clip 能在多大程度上吸引开发者是存有疑问的：因为很难说服一个跨 iOS 和 Android 平台的成熟服务将 app clip 作为核心部分进行开发，而 iPhone 的市场占有率又决定了这样的开发能够覆盖的用户十分有限。

不过好处在于，很大程度上，为现有的 app 提供一个 app clip 需要花费的精力并不会很多：在确定了方向和提供的核心功能后，大量的 main app 中的既有代码和素材都可以重复使用。App clip 和小程序定位也完全不同。前者并没有改变以 app 为中心、以提高体验和快捷使用为基本点的方针：它更像一种为 main app 做 promotion 的手段，让 main app 多一些被曝光和试用的机会。对于线下获取用户来说，也许会有一定效果。从体验上来说，可以肯定的是，基于 native 和成熟开发框架 (此处专指 UIKit，暂不包含 SwiftUI) 的 app clip 一定是胜过小程序很多的。但是，究竟有多少注重体验的高端用户，愿意为其买单，我个人只能抱有谨慎乐观的态度。





