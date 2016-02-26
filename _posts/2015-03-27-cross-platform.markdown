---
layout: post
title: 跨平台开发时代的 (再次) 到来？
date: 2015-03-27 18:56:08.000000000 +09:00
tags: 能工巧匠集
---

![cross-platform](/assets/images/2015/cross-platform.png)

这篇文章主要想谈谈最近又刮起的移动开发跨平台之风，并着重介绍和对比一下像是 [Xamarin](https://xamarin.com)，[NativeScript](https://www.nativescript.org) 和 [React Native](http://facebook.github.io/react-native/) 之类的东西。不会有特别深入的技术讨论，大家可以当作一篇科普类的文章来看。

### 故事的开始

“一次编码，处处运行” 永远是程序员们的理想乡。二十年前 Java 正是举着这面大旗登场，击败了众多竞争对手。但是时至今日，事实已经证明了 Java 笨重的体型和缓慢的发展显然已经很难再抓住这个时代快速跃动的脚步。在新时代的移动大潮下，一个应用想要取胜，完美的使用体验可以说必不可少。使用 native 的方式固然对提升用户体验很有帮助，但是移动的现状是必须针对不同平台 (至少是 iOS 和 Android) 进行开发。这对于开发来说妥妥的是隐患和额外的负担：我们不仅需要在不同的项目间努力用不同的语言实现同样代码的同步，还要承担由此带来的后续维护任务。如果仅只限制在 iOS 和 Android 的话还行，但是如果还要继续向 Windows Phone 等平台拓展的话，所需要付出的代价和[工数](http://en.wikipedia.org/wiki/Man-hour)将几何级增长，这显然是难以接受的。于是，一个其实一直断断续续被提及但是从没有占据过统治地位的概念又一次走进了移动开发者们的视野，那就是跨平台开发。

### 本地 HTML 和 JavaScript

因为每个平台都有浏览器，也都有 WebView 控件，所以我们可以使用 HTML，CSS 和 JavaScript 来将 web 的内容和体验搬到本地。通过这样做我们可以将逻辑和 UI 渲染部分都统一，以减少开发和维护成本。这种方式开发的 app 一般被称为 [Hybrid app](http://blogs.telerik.com/appbuilder/posts/12-06-14/what-is-a-hybrid-mobile-app-)，像 [PhoneGap](http://phonegap.com) 或者 [Cordova](http://cordova.apache.org) 这样的解决方案就是典型的应用。除了使用前端开发的一套技巧来构建页面和交互以外，一般这类框架还会提供一些访问设备的接口，比如相机和 GPS 等。

![hybrid-app](/assets/images/2015/hybrid-app.jpg)

虽然使用全网页的开发策略和环境可以带来代码维护的便利，但是这种方式是有致命弱点的，那就是缓慢的渲染速度和难以驾驭的动画效果。这两者对于用户体验是致命而且难以接受的。随着三年前 Facebook 使用 native 代码重新构建 Facebook 的手机 app 这一[标志性事件](https://www.facebook.com/notes/facebook-engineering/under-the-hood-rebuilding-facebook-for-ios/10151036091753920)的发生，曾经一度占领半壁江山的网页套壳的 app 的发展也日渐式微。特别在现在对于用户体验的追求几近苛刻的现在，呆板的动画效果和生硬的交互体验已经完全无法满足人民群众对高质量 app 的心理预期了。

### 跨平台之心不死的我们该怎么办

想要解决用户体验的问题，基本还是需要回到 native 来进行开发，但是这种行为必然会与平台绑定。世界上总是有聪明人的，并且他们总会利用看起来更加聪明但是实际上却很笨的电脑来做那些很笨的事情 (恰得其所)。其中一件事情就是自动将某个平台的代码转换到另外的平台上去。有一家英国的小公司正在做这样的事情，[MyAppConverter](https://www.myappconverter.com) 想做的事情就是把 iOS 的代码自动转成 Java 的。但是很可惜，如果你尝试过的话，就知道他们的产品暂时还处于无法实用的状态。

在这条路的另一个分叉上有一家公司走得更远，它叫做 [Apportable](http://www.apportable.com)。他们在游戏的转换上已经取得了[很大的成果](https://dashboard.apportable.com/customers)，像是 Kingdom Rush 或者 Mega Run 这样的大作都使用了这家的服务将游戏从 iOS 转换到 Android，并且非常成功。可以毫不夸张地说，Apportable 是除开直接使用像 Unity 或者 Cocos2d-x 以外的另一套诱人的游戏跨平台解决方案。基本上你可以使用 Objective-C 或者 Swift 来在熟悉的平台上开发，而不必去触碰像是 C++ 这样的怪兽 (虽然其实在游戏开发中也不会碰到很难的 C++)。

但是好消息终结于游戏开发了，因为游戏在不同平台上体验不会差别很大，也很少用到不同平台的不同特性，所以处理起来相对容易。当我们想开发一个非游戏的 app 时，事情就要复杂得多。虽然 Apportable [有一个计划](http://www.tengu.com)让 app 转换也能可行，但是估计还需要一段时间我们才能看到它的推出。

### 新的希望

#### Xamarin

其实跨平台开发最大的问题还是针对不同的平台 UI 和体验的不同。如果忽视掉这个最困难的问题，只是共用逻辑部分的代码的话，问题一下子就简单不少。十多年前，当 .NET 刚刚被公布，大家对新时代的开发充满期待的同时，一群喜欢捣鼓的 Hacker 就在盘算要如何将 .NET 和 C# 搬到 Linux 上去。而这就是 [Mono](http://www.mono-project.com) 的起源。Mono 通过在其他平台上实现和 Windows 平台下功能相同的 Common Language Runtime 来运行 .NET 中间代码。现在 Mono 社区已经足够强大，并且不仅仅支持 Linux 平台，对移动设备也同样支持。Mono 背后的支撑企业 [Xamarin](http://xamarin.com) 也顺理成章并适时地推出了一整套的移动跨平台解决方案。

Xamarin 的思路相对简单，那就是使用 C# 来完成所有平台共用的，和平台无关的 app 逻辑部分；然后由于各个平台的 UI 和交互不同，使用预先由 Xamarin 封装好的 C# API 来访问和操控 native 的控件，进行分别针对不同平台的 UI 开发。

![xamarin](/assets/images/2015/xamarin.png)

虽然只有逻辑部分实现了真正的跨平台，而表现层已然需要分别开发，但这确实也是一种在完整照顾用户体验的基础上的好方式 -- 至少开发语言得到了统一。因为 Xamarin 解决方案中的纯 C# 环境和有深厚的 .NET 技术背景做支撑，这个项目现在也受到了微软的支持和重视。

不过存在的致命问题是针对某个特定平台你所能使用的 API 是由 Xamarin 所决定的。也就是说一旦 iOS 或者 Android 平台推出了新的 SDK，加入了新的功能，你必须要等 Xamarin 的工程师先进行封装，然后才能在自己的项目中使用。这种延迟往往可能是致命的，因为现在 AppStore 对于新功能的首页推荐往往只会有新系统上线后的一两周，错过这段时间的话，可能你的 app 就再无翻身之日。而且如果你想使用一些第三方框架的话，将不得不自己动手将它们打包成二进制，并且写 binding 为它们提供 C# 的封装，除非已经有别人帮你[做过](https://github.com/mono/monotouch-bindings)这件事情了。

另外，因为 UI 部分还是各自为战，所以不同的代码库依然存在于项目之中，这对工作量的减少的帮助有限，并且之后的维护中还是存在无法同步和版本差异的隐患。但是总体来说，Xamarin 是一个很不错的解决跨平台开发的思路了。(如果抛开价格因素的话)

#### NativeScript

[NativeScript](https://www.nativescript.org) 是一家名叫 Telerik 的名不见经传保加利亚公司刚刚宣布的项目。虽然 Telerik 并不是很出名，但是却已经在 hybrid app 和跨平台开发这条路上走了很久。

JavaScript 因为广泛的群众基础和易学易用的语言特点，已经大有一统天下的趋势。而现在主流移动平台也都有强劲的处理 JavaScript 的能力 (iOS 7 以后的 JavaScriptCore 以及 Android 自带的 V8 JavaScript Engine)，因为使用 JavaScript 来跨平台水到渠成地成为了一个可选项。

> 在此要吐槽一下，JavaScript 真的是一家公司，一个项目拯救回来的语言。V8 之前谁能想到 JavaScript 能有今日...

NativeScript 的思路就是使用移动平台的 JavaScript 引擎来进行跨平台开发。逻辑部分自然无需多说，关键在于如何使用平台特性，JavaScript 要怎样才能调用 native 的东西呢。NativeScript 给出的答案是通过反射得到所有平台 API，预编译它们，然后将这些 API 注入到 JavaScript 运行环境，接下来在 Javascript 调用后拦截这个调用，并运行 native 代码。

> 在此不打算展开说 NativeScript 详细的原理，如果你对它感兴趣，不妨去看看 Telerik 的员工的写的这篇[博客](http://developer.telerik.com/featured/nativescript-works/)以及发布时的 [Keynote](https://www.youtube.com/watch?v=8hr4E9eodS4)。

![nativescript-architecture](/assets/images/2015/nativescript-architecture.png)

这么做最大的好处是你可以任意使用最新的平台 API 以及各种第三方库。通过对元数据的反射和注入，NativeScript 的 JavaScript 运行环境总能找到它们，触发相应的调用以及最终访问到 iOS 或者 Android 的平台代码。最新版本的平台 SDK 或者第三方库的内容总是可以被获取和使用，而不需要有什么限制。

举个简单的例子，比如创建一个文件，为 iOS 开发的话，可以直接在 JavaScript 里写这样的代码：

```
var fileManager = NSFileManager.defaultManager();
fileManager.createFileAtPathContentsAttributes( path );
```

而对应的 Android 版本也许是：

```
new java.io.File( path );
```

你不需要担心 `NSFileManager` 或者 `java.io` 这类东西的存在，而是可以任意地使用它们！

如果仅只是这样的话，使用上还是非常不便。NativeScript 借助类似 node 的一套包管理系统，用 modules 对这些不同平台的代码进行了统一的封装。比如上面的代码，可以统一使用下面的形式替换：


```
var fs = require( "file-system" );
var file = new fs.File( path );
```

写过 node 的同学肯定对这样的形式很熟悉了，这里的 `file-system` 就是 NativeScript 进行的统一平台的封装。现在的完整的封装列表可以参见这个 [repo](https://github.com/NativeScript/cross-platform-modules)。因为写法很简单，所以开发者如果有需要的话，也可以创建自己的封装，甚至使用 npm 来发布和共享 (当然也有获取别人写的封装)。因为依赖于已有的成熟包管理系统，所以可以认为扩展性是有保证的。

对于 UI 的处理，NativeScript 选择了使用类似 Android 的 XML 的方式进行布局，然后用 CSS 来控制控件的样式。这是一种很有趣的想法，虽然 UI 的布局灵活性上无法与针对不同平台的 native 布局相比，但是其实和传统的 Android 布局已经很接近。举个布局文件的例子就可见一斑：

```
<Page loaded="onPageLoaded">
    <GridLayout rows="auto, *">
        <StackLayout orientation="horizontal" row="0">
            <TextField width="200" text="{{ task }}" hint="Enter a task" id="task" />
            <Button text="Add" tap="add"></Button>
        </StackLayout>

        <ListView items="{{ tasks }}" row="1">
            <ListView.itemTemplate>
                <Label text="{{ name }}" />
            </ListView.itemTemplate>
        </ListView>
    </GridLayout>
</Page>
```

熟悉 Android 或者 Window Phone 开发的读者可能会感到找到了组织。你可能已经注意到，相比于 Android 的布局方式，NativeScript 天生支持 MVVM 和 data binding，这在开发中会十分方便 (但是性能上暂时就未知了)。而像是 `Button` 或者 `ListView` 这样的控件都是由 modules 映射到对应平台的系统标准控件。这些控件的话都是使用 css 来指定样式的，这与传统的网页开发没太大区别。

![nativescript-ui](/assets/images/2015/nativescript-ui.png)

NativeScript 代表的思路是使用大量 web 开发的技巧来进行 app 开发。这是一个很值得期待的方向，相信也会受到很多前端开发者的欢迎 -- 因为工具链和语言都非常熟悉。但是这个方向依然面临的最大挑战还是 UI，现在看来开发者是被限制在预先定义好的 UI 控件中的，而不能像传统 Hybrid app 那样使用 HTML5 的元素。这使得如何能开发出高度自定义的 UI 和交互成为问题。另一个可能存在的问题是最终 app 的尺寸。因为我们需要将整个元数据注入到运行环境中，也存在很多在不同语言中的编译，所以不可避免地会造成较大的 app 尺寸。最后一个挑战是对于像 app 这样的工程，没有类型检查和编译器的帮助，开发起来难度会比较大。另外在调试的时候也可能会有传统 app 开发中不曾遇到的问题。

总体来看，NativeScript 是很有希望的一个方案。如果它能实现自己的愿景，那必将是跨平台这块大蛋糕的有力竞争者。当然，现在 NativeScript 还太年轻，也还有[很多问题](https://www.nativescript.org/roadmap)。不妨多给这个项目一点时间，看看正式版本上线后的表现。

#### React Native

Facebook 几个月前[公布](https://code.facebook.com/videos/786462671439502/react-js-conf-2015-keynote-introducing-react-native-/)了 React Native，而今天这个项目终于在万众期待下[发布](http://facebook.github.io/react-native/)了。

React Native 在一定程度上和 NativeScript 的概念类似：都是使用 JavaScript 和 native UI 来实现 app (所以说 JavaScript 真是有一桶浆糊的趋势..如果你现在还不会写几句 JavaScript 的话，建议尽早学一学)。但是它们的出发点略有不同，React Native 在首页上就写明了，使用这个库可以：

> learn once, write anywhere

而并不是 "run anywhere"。所以说 React Native 想要达成的目标其实并不是一个跨平台 app 开发方案，而是让你能够使用相似的方法和同样的语言来在不同平台进行开发的工具。另外，React Native 的主要工作是构建响应式的 View，其长处在于根据应用所处的状态来决定 View 的表现状态。而对于其他一些系统平台的 API 来说，就显得比较无力。而正是由于这些要素，使得 React Native 确实不是一个跨平台的好选择。

那为什么我们还要在这篇以 “跨平台” 为主题的文章里谈及 React Native 呢？

因为虽然 Facebook 不是以跨平台为出发点，但是却不可能阻止工程师想要这么来使用它。从原理上来说，React Native 继承了 React.js 的虚拟 DOM 的思想，只不过这次变成了虚拟 View。事实上这个框架提供了一组 native 实现的 view (在 iOS 平台上是 `RCT` 开头的一系列类)。我们在写 JavaScript (更准确地说，对于 React Native，我们写的是带有 XML 的 JavaScript：[JSX](http://facebook.github.io/react/docs/jsx-in-depth.html)) 时，通过将虚拟 View 添加并绑定到注册的模块中，在 native 侧用 JavaScript 运行环境 (对于 iOS 来说也就是 JavaScriptCore) 执行编译并注入好的 JavaScript 代码，获取其对 UI 的调用，将其截取并桥接到 native 代码中进行对应部件的渲染。而在布局方面，依然是通过 CSS 来实现的。

这里整个过程和思路与 NativeScript 有相似之处，但是在与 native 桥接的时候采取的策略完全相反。React Native 是将 native 侧作为渲染的后端，去提供统一的 JavaScript 侧所需要的 View 的实体。NativeScript 基本算反其道行之，是在 JavaScript 里写分开的中间层来分别对应不同平台。

对于非 View 的处理，对于 iOS，React Native 提供了 `RCTBridgeModule` 协议，我们可以通过在 native 侧实现这个协议来提供 JavaScript 中的访问可能。另外，回调和事件发送等也可以通过相应的 native 代码来完成。

总结来说，如果想要把 React Native 作为一个跨平台方案来看的话 (实际上也并不应当如此)，那么单靠 JavaScript 一侧是难以完成的，因为一款有意义的 app 不太可能完全不借助平台 API 的力量。但是毕竟这个项目背后是 Facebook，如果 Facebook 想要通过自己的影响力自立一派的话，必定会通过不断改进和工具链的完善，将 app 开发的风向引导至自己旗下。对于原来就使用 React.js 的开发者来说，这个框架降低了他们进入 app 开发的门槛。但是对于已经在做 native app 开发的人来说，是否值得和需要投入精力进行学习，还需要观察 Facebook 接下来动作。

不过现在 React Native 的正式发布才过去了不到 24 小时，我想我们有的是时间来思考和检阅这样一个框架。

### 总结

当然还有一些其他方案，比如 [Titanium](http://www.appcelerator.com/titanium/) 等。现在使用跨平台方案开发 app 的案例并不算很多，但是无论在项目管理还是维护上，跨平台始终是一种诱惑。它们都解决了一些 Hybrid app 的遗留问题，但是它们又都有一些非 native app 的普遍面临的阴影。谁能找到一个好的方式来解决像是自定义 UI，API 扩展性以及 app 尺寸这样的问题，谁就将能在这个市场中取得领先或者胜利，从而引导之后的开发潮流。

但是谁又知道最后谁能取胜呢？也有可能大家在跨平台的道路上再一次全体失败。伺机而动也许是现在开发者们很好的选择，不过我的建议是提前[学点儿 JavaScript](http://www.codecademy.com/en/tracks/javascript) 总是不会出错的。
