---
layout: post
title: "sim-use - 给 agent 装上眼睛和手，让 mobile 开发跟上 AI 时代"
date: 2026-07-03 23:50:00.000000000 +09:00
categories: [能工巧匠集]
tags: [AI,Agent,iOS,Android,自动化,开源,工具,vibe coding]
typora-root-url: ..
---

最近在公司捣鼓了一个工具，叫 [`sim-use`](https://github.com/lycorp-jp/sim-use)：一个跨平台 CLI，让 agent 能在 iOS 和 Android 上高效且准确地"看见画面、点按元素、验证结果"。前段时间它正式开源了，日文版的介绍文章也发在了[公司的 Tech Blog](https://techblog.lycorp.co.jp/ja/20260701b) 上。不过说来有趣，那篇文章的初稿其实是用中文写的，后来才翻译成日文发表；现在再把它从日文"翻译"回中文、发在自己的博客上，多少有点出口转内销的行为艺术。趁着记忆还新鲜，用母语把里面的技术细节好好聊一遍。

如果你最近半年用 agent 写代码，大概经历过这个循环：

```
写 prompt → agent 出活 → 自己跑 app
  → 验证 / 截图 / 找 agent 抱怨
  → agent 改 → 再跑 → 再截图 …
```

"写代码"这部分工作，在很大程度上已经被 agent 承担并接手了，但是**"验证"**正确性对 UI app 来说尤为困难。agent 已经能在几分钟内吐出一大段像模像样的 Swift 或 Kotlin，但写完最多跑跑单元测试，然后就停在那儿了——它等你来运行、来看、来告诉它哪不对，它再根据反馈进行修改。这是相当低效的开发方式。

这篇文章讲的就是我们针对这个问题做的 `sim-use`。我会先讲讲这件事为什么值得做，然后用五个技术决定，聊聊它内部那些可能有点意思、但不那么显然的设计和细节。

## 背景：agent 时代写代码和验证产品的分歧

业内有个粗略的说法：**未来五年产出的代码量，会超过过去所有年份的总和**。你信不信这个数字无所谓，方向是明确的——agent 正在迅速吃掉软件开发的"产出"这一端。

但"产出"只是开发循环的一半。代码必须经过验证才能变成产品。传统的验证方式——工程师手动点一点、CI 上跑功能测试、发版前靠 QA 团队测试——本来就已经是研发流程里最贵、最慢的一环。当上游的代码生成被加速十倍，下游的验证瓶颈就会被放大十倍。

更麻烦的是，**在 mobile app 这里，因为成熟工具链的缺乏，加上移动平台本身比 Web 封闭，这个问题被放得更大。**

### 前端 agent 的"作弊"优势

做 Web 的同学会感觉，agent 在前端的闭环验证做得还不错。原因很朴素：

- agent 能毫不费力地直接拿到 **DOM**：结构化、可遍历、自带语义的一棵树。
- 浏览器有成熟的自动化工具：Playwright、Puppeteer 这些，selector 很稳。
- 控制台日志、网络请求——所有信号都是文本可读的。

DOM 本身就是一份 agent 的"天然语料"。`<button id="login">` 这种东西不需要视觉理解——它就是结构化数据。agent 写完代码可以自己跑、自己点、自己看，闭环很短。

### Mobile 的"黑盒"苦衷

换到 mobile，问题立刻就不一样了：

- iOS 和 Android 都是相对封闭的环境，没有一个"DOM 等价物"对外暴露。
- 现在市面上能看到的两类方案，都还不能让人满意：
  - **靠截图 + 多模态模型**：贵、慢，对长尾控件识别能力有限，点坐标需要靠截图计算容易漂移，不稳定，而且多模态的调用成本爆炸。
  - **dump UI tree 给 agent 看**：UIAutomator / AccessibilityService / iOS 的 AX API，原始输出动不动几十甚至上百 KB JSON，使用不当 token 消耗惊人，还**经常拿不到 UI 元素**（这点后面细说）。

结果就是：agent 看不清楚界面，就没法自己验证；没法自己验证，就得把开发者拉回那个"写 prompt、等出活、人肉跑 app"的低效循环里。

**"让 agent 高效、准确、可靠、快速地拥有对 app 的视觉和操作能力"，这件事基本决定了它能在多大程度上接管验证，也决定了真实开发中速度的上限。** 我们认为，这是接下来的软件开发时代里最值得着手解决的事情之一。一旦这个闭环跑起来，agent 开发才算真正走上正轨。

这就是 `sim-use` 想要解决的问题。

## sim-use 是什么

**`sim-use` 是一个跨平台 CLI，让 agent 可以像人一样操作 iOS 模拟器和 Android 模拟器/真机。**

它做四件事：

1. **看**：把 app 当前屏幕翻译成一种紧凑、对 agent 友好的文本格式（我们叫它 `outline`）。
2. **点**：通过 outline 里 `@N`、`#id` 这种简短 selector，让 agent（和人）都能轻松选中元素并触发交互。
3. **打字 / 手势 / 截图 / 录屏 / 多指操作 / 键盘事件**……提供一整套命令，覆盖所有操作和证据留存，为 agent 审计和接入其他系统留好接口。
4. **跨平台**：iOS 和 Android 用同一套命令、同一种 selector、同一种 JSON 输出格式，同样的验证在多端可以复用。

它的产品形态是一个 Swift 写的 macOS CLI（带一个 daemon 做加速），两端各自这样驱动：iOS 侧通过 Facebook 的 idb（FBSimulatorControl）连接模拟器，UI 观测经 CoreSimulator 的 `AccessibilityPlatformTranslation` 取 accessibility tree，输入则通过注入 HID 事件完成；Android 侧则是一个在设备上跑 `AccessibilityService` 的 bridge APK，通过 `adb forward` 暴露 HTTP API。

用起来大概是这样：

```bash
sim-use ui --device <iOS-UDID-or-Android-emulator>
```

```
# 输出
App: LINE Dev  402x874

[Top  y<120]
  @6  Button  "Keep memo"  #keepButton
  @7  Button  "Notifications"  #notificationButton
  …

[Content  y=120..754]
  @10  Button  "Sato's profile"
  @12  Image  "Profile image"  #profileView
  …

[Bottom  y>=754]
  @39  RadioButton  "Home"  #homeTab  selected
  @40  RadioButton  "Chats, 22 new items"  #chatTab
  @41  RadioButton  "Shopping"  #commerceTab
  @42  RadioButton  "News"  #newsTab
  @43  RadioButton  "MINI"  #miniTab
```

一个屏幕往往可以被压缩在几百 token 里，agent 瞬间可以看完。通过文本看到 UI 之后，它执行操作：

```bash
sim-use tap "@10"
sim-use type "hello world"
sim-use swipe --from-x 200 --from-y 800 --to-x 200 --to-y 400
sim-use record-video --output ./demo.mp4
```

最后，再次使用 `ui` 命令获取新的屏幕状态，进行断言和接下来的操作，直到达成目的或者拿到需要的验证证据。

这篇文章不打算浅显地介绍 `sim-use` 怎么用，而是想深入聊聊几个我们认为值得讲的技术决定和细节。

## 技术内幕（一）：Outline —— 给 agent 准备的"方言"

agent 第一件需要的事是"看见画面"。最直觉的做法是把 accessibility tree 整棵 dump 成 JSON 喂给它——结构清楚、内容完整，解析方便。我们也是这么做的，直到第一次在 LINE 的新闻页上试了一下，结果得到了一个 **24 KB、pretty 打印 1600 多行**的 JSON。

24 KB 在普通工程里不算什么，但对 agent 是个灾难。一个验证循环里 `sim-use ui` 会被调几十次，每次的输出被混进上下文。两三步之后，上下文就被 UI 树撑爆，上下文中的噪音让 agent 开始忘掉之前的对话。聪明的 agent 在遇到几次这种情况后也许会通过 `head` 或者写一个脚本来对数据进行整形，但是也依赖特定的上下文结构（比如预先定义好 skill）或者 agent 的自我纠错。为 agent 提供舒适的工作环境，是让它高效处理问题的关键。

所以我们在 CLI 层做了一个紧凑的文本 DSL 输出，叫 `outline`。同一个 LINE 新闻页面，dump 出来 **1.2 KB、不到 30 行**，token 消耗压到原来的 1/20。一个示意片段：

```
[Top y<120]
  @1 Button "Back" (24,60 88x44)
  @2 StaticText "News" (152,68 96x28)
[Content y=120..H-120]
  @3 #1 Cell "Top story headline …" (0,120 393x180)
  @4 #2 Cell "Second story …" (0,308 393x180)
  …
[Bottom y≥H-120]
  @9 Button "Tab Home" (0,790 98x44)
```

![](/assets/images/2026/sim-use-outline-compression.png)

*图 1：同一个 LINE 新闻页面，JSON 是 24 KB / 1600 行，outline 是 1.2 KB / 28 行 —— token 消耗压到 1/20。*

### 不只是压缩 —— Outline 的设计原则

Outline 不只是压缩。它固然有"让 JSON 变小"的目的，但更重要的是**为了让 agent 读起来更顺畅**。这个定位带来了几条具体的设计选择，每一条都是踩过坑之后留下的。

最朴素的一条是**字节级稳定**。坐标全部 `Int(rounded())` 取整，元素按 `(center-y, x)` 确定性排序，同一画面两次 dump 出来一定字节一致。这意味着 agent 可以对两次 dump 做直接的文本 diff——"点之前"和"点之后"差了什么，一眼就能看出来，要处理的数据量也小得多，对推理速度很关键。

第二条是 selector 设计。你可能已经注意到了，在 `ui` 输出中，我们提供三种简写：`@N` 是当前快照里的第 N 个元素；`#N` 是"页面主列表的第 N 个 cell"，对应列表式 UI；`#<id>` 直接引用 accessibility tree 自带的稳定 ID，能跨 dump 复用。这个 DSL 的初衷是让 agent 少打字——`sim-use tap "@5"` 比 `sim-use tap --label "Login Button" --container "MainView"` 直白多了。但出乎意料的是，不仅是 agent，**人也很喜欢用**——手工调试一个失败的 case 时，盯着输出敲 `tap @10` 比构造一长串 selector 快得多。而在人与人、人与 agent 交流时，这套 outline 也极大简化了描述问题的难度。

第三条是**克制**。Outline 严格只写 accessibility tree 已经声明的东西，不发明语义——一片按钮就是"Button × 5"，不会被擅自命名为"NavBar"或"CategoryTabs"。这条纪律来自一个判断：agent 看到"位置在最底部、横向排列、role 都是 RadioButton"，自己会推断这是 tab bar；但如果工具替它命名，一旦猜错（比如把一组 RadioButton 标成 SegmentedControl 但实际行为不同），agent 就会跟着错。这也是固定工具和 LLM 智能之间需要拿捏的平衡：与其让工具去猜，不如让 agent 自己推断和理解屏幕的意图。

唯一的例外是输出顶上那三段 `[Top y<120]` / `[Content]` / `[Bottom y≥H-120]` 的分带。它们是仅有的"语义提示"，但放进去是因为这三段在 mobile UI 上足够稳定——status bar、内容区、tab bar——属于几乎不可能出错的低成本提示。

最后一条是**跨平台不强行对齐**。iOS 上元素按 `(center-y, x)` 排序——一行按钮即使高度不同，居中对齐是常态，中线排序最稳；但 Android 的 `AccessibilityNodeInfo.bounds` 会把容器 padding 也算进去，中线排序反而会把父节点排到子节点中间。所以 Android 那边改成 `(top-y, x)`。一个小细节，但能让 outline 的排布更贴近 UI 在屏幕上的真实顺序。跨平台不是"把一边的设计硬搬到另一边"，而是要留出给平台特性分歧的空间。

### 不只是看，还要能指 —— 列表探测

`#N` 这种 selector 看起来简单，背后藏着一个不平凡的问题：**怎么在运行时识别出页面的"主列表"？**

最直白的做法是让用户指定容器——"这是聊天列表""这是新闻流"。但那就违背了"agent 不需要知道结构"的前提。所以我们做了一个启发式的自动探测：扫一遍页面，找出所有"看起来像列表"的元素簇，按可信度排名，最高的就是 `#N` 默认指向的那一组。

探测分两路并行。一路看高度——找一群高度一致的兄弟节点（好友列表、表格 cell 是典型形态）；另一路看间距——找一群"行间距大致一致"的节点（新闻 feed，聊天列表这种 cell 高度不一致但节奏一致的布局）。然后用一个朴素的乘法打分：`cellCount × consistency × roleBonus × widthBonus`，不需要训练，不需要权重学习，得分最高的那一簇胜出。多列表共存时（比如 LINE 的转发选择页同时有"好友列表"和"群组列表"），第二高的列表也会被识别出来，给到 `#N@2` 这个 selector。

![](/assets/images/2026/sim-use-list-selector.jpg)

*图 2：LINE 转发选择页同时存在好友列表和群组列表 —— 得分最高的好友列表拿到 `#N`，群组列表自动落到 `#N@2`。完整的动态演示可以看下面的视频。*

<video controls style="width: 100%; max-width: 620px; height: auto;" playsinline>
  <source src="/assets/images/2026/sim-use-list-selector.mp4" type="video/mp4">
  您的浏览器不支持 HTML5 视频。
</video>

对 agent 来说，这意味着"点击聊天列表里的第三行"这样的自然语言，现在可以直接对应 `tap #3`，不需要中间任何视觉识别、推理和计算。验证脚本也不再绑死在硬编码的坐标（会随设备漂移）或某个特定的 label 上（会随多语言漂移）——它适配的是"页面运行时呈现出来的主列表"，而不管这个列表今天有 5 个 cell 还是 20 个 cell、也不关心 cell 的具体 label 是什么。E2E 测试在这种 selector 下要稳定得多。

## 技术内幕（二）：让看不见的元素"现身"—— Quadtree 探针

iOS 自动化里有个让人头疼的现象，部分节点的内容在 `AccessibilityPlatformTranslation` 框架下无法获取，比如 **UITabBar 报回来的 `accessibilityChildren` 是空的**：明明屏幕底部有四个 tab 按钮，遍历 accessibility tree 那个 `AXGroup` 下面却什么都没有。WebView 也是类似，iOS 26 的"Liquid Glass"设计、各种自定义浮层、用 SwiftUI 拼出来的非标控件也经常出这个问题。

更诡异的是，这并不是 API 完全坏掉了。同一个元素，`accessibilityChildren` 遍历不到，但 `objectAtPoint:` 点得到——你给 iOS 一个坐标，它能告诉你这里有什么；但你让它列出某个容器有哪些子元素，它就装作不知道。这是一个长期顽疾，业界默默忍了很多年。

我们想要的是一个完整的 accessibility tree，所以问题就变成了：**怎么用 hit-test 把那些遍历不到的元素"钓"出来？**

最朴素的想法是密集打点：把容器整块 frame 当成画布，按一个小间距（比如 10pt）撒满探测点，每个点 hit-test 一次，命中的元素全收回来然后去重。逻辑上没毛病，但代价受不了——每次 `objectAtPoint:` 都是一次 XPC 跨进程通信，从 sim-use 进程到模拟器进程再回来，单次成本好几毫秒。一块 400×800 的画布按 10pt 撒，就是 3200 次 hit-test，几十秒起步——这个响应速度完全没法用。

`ui` 是整个 loop 里最重要的一环，**"怎么点得聪明"**就成了这个工具的核心。我们用的解法是一棵**自适应的四叉树**。

四叉树（quadtree）是计算几何里的老方法——核心思路是把一块二维区域自顶向下递归切成四份，到某个条件满足就停。游戏里用它做碰撞剪枝，地图渲染里用它组织瓦片。我们这里用的是它的一个变种，专门为"漏元素回收"做了适配：先把容器 frame 撒一层 160×80 的粗格子，每个格子中心做一次 `objectAtPoint:`；命中的元素记下来、它的 bounding rect 标记成"已覆盖"；没命中的格子说明要么是真空白、要么跨过了几个小元素之间的缝隙，把它切成四份继续探。这个细分有截断：单个粗格子最多被切 16 次（Phase 1）或 6 次（Phase 2），最小尺寸不低于 `--min-cell-size`（默认 14pt）——免得在真空白上死磕。

这里有一个容易想错的细节：seed cell 命中一个小元素之后，cell 剩下的部分会被切成最多 4 条矩形（hit 上下两条加左右两条），再 push 回探测队列继续走。换句话说，hit 锁住的不是整个 seed cell，只是 hit 自己的 bounding rect —— 周围那些可能漏掉的兄弟元素仍然有机会被探到。这一步在代码里叫 "opportunistic remainder subdivide"。

整体形态就是一棵粗到细的树：元素密集的地方树深，空白处树浅。accessibility tree 已经枚举出来的东西被直接当作"已知"跳过；只有可能有漏元素的区域才会被深入探测。换句话说，**把昂贵的 XPC hit-test 用在刀刃上，而不是均匀撒在整张画布上**。

![](/assets/images/2026/sim-use-quadtree-probe.png)

*图 3：UITabBar 的 `accessibilityChildren` 是空的，但 quadtree 探针通过粗 seed 网格、命中即标已覆盖（命中元素之外的剩余条带会重新入队继续探）、nil 即四分细分，最终把 4 个 tab 按钮全部探出来。*

实践中漏元素分两种情况，分别走两个 phase。**Phase 1 是空容器复原**：父节点 children 是空的但视觉上显然不空（UITabBar 的典型症状），整块 frame 直接喂给四叉树。**Phase 2 是盲区扫描**：父节点有 children 但只覆盖了一部分——比如 nav bar 报回了左上角的 back button，右上角的 menu button 不见了。我们把容器 frame 减去所有已知元素覆盖的部分，剩下的"盲矩形"（≥ 60×60 且 ≥ 10000 pt² 才算）再走一遍四叉树。Phase 2 用了一个取巧的几何技巧——**水平条带切割 + 矩形减法**——比通用的多边形减法好写得多，而对 mobile UI 这种"元素几乎都是矩形且大致水平排列"的输入分布也非常合适。

把这个抽象算法做成"跑得动"，靠的是几个朴素的工程优化。最关键的一条是**种子用矩形不用正方形**：mobile UI 的元素几乎都是横向多于纵向——nav link、文章标题、列表行、文字标签都是横长条的。早期我们简单地用了正方形 seed，效率很低；把初始 seed 改成 160×80 之后，同样的功能覆盖率下 LINE News 的探针次数和 wall time 下降了 20%，seed cell 从 45 降到 27，相比同面积的方形 seed，在保证相同可探测率的前提下，一次典型复杂页面的总耗时能缩短 30% 左右。

另一条是 **XPC 调用前的覆盖剪枝**——既然 XPC 是最贵的一段，那 accessibility tree 已经知道的格子就不应该再问一次。我们维护一个 `CoveredSet`，如果某个 seed cell 的中心点已经落在已知元素范围内（带 2pt 松动），直接跳过。还有一个看似无关紧要但实际影响很大的参数：`--min-cell-size`。我们把它从 20 降到 14，让 status bar 上的 SSID 图标、tab bar 上的小 badge、设置页右边那些小箭头都能被识别出来。代价是中位数延迟从 ~470ms 涨到 ~520ms（+11%, ~50ms），但 agent 经常要点这些小图标，这 50ms 是值的。

最后一个细节是去重。早期 `sim-use ui` 偶尔会在"chat detail 顶部 nav"这种位置返回重复的合成元素。原因是 UIKit 会把同一个容器藏在多个兄弟 `AXGroup` 里，每个 `AXGroup` 各自探针下去都会命中同一组真实元素。最早的去重逻辑只在单次探针调用范围里有效，需要把它提升到 traversal 全局——一个 `SeenIdentitySet` 贯穿整个 walk，每命中一个元素就记录身份，再撞上就跳过。最终落到代码上只有 8 行，但该改哪 8 行，只能靠实际跑、反复试才能弄清楚。

## 技术内幕（三）：让 200ms 消失 —— Daemon 架构

`sim-use` 是一个 CLI。CLI 用起来直观，但有一个不显眼的代价：**每次调用都是一个新进程，所有"重"的初始化都得重做一遍**。

对 iOS 来说，这个"重"是 simulator 框架的初始化加上 accessibility 子系统的初始化，两段加起来稳定占掉 ~200ms。对 Android 来说，是 `BridgeClient` 启动、auth token 缓存、`adb forward` 端口准备，一整套加起来 ~150ms。单看不显眼，但 agent 在一个验证循环里会调几十次 `sim-use`，冷启动开销迅速变成主导成本。

我们的解法是**为每个设备起一个常驻进程**：在 host 上跑一个 Unix-domain socket 的 daemon 服务，客户端跑命令时直接走 socket。第一次调用 fork-exec 出 daemon、等 socket 起来（5s 超时），之后所有命令都走 hot path——所有重初始化只付一次代价。空闲 600s 自动退出，不留垃圾。

效果是 iOS 每次 `sim-use ui` 节省 ~200ms（基本就是冷启动那部分被一次性付掉），Android 则把每次调用从 ~150ms 压到 ~10ms。Android 侧的改善幅度这么大，是因为 `BridgeClient` 那一套初始化本来就比普通的 adb 命令重得多——把它常驻起来收益最大。

而这也有维护上的代价，比如 **daemon 带来的几个正确性问题**。

第一个问题是**二进制升级，daemon 还在跑旧逻辑**。用户刚 `brew upgrade` 了一个新版本，下一次调用却命中了仍在跑旧代码的 daemon，行为对不上、bug 复现不出来、人开始怀疑人生。我们的解法是每次客户端调用前先发一个 `_ping`，对比 daemon 报的 `simUseVersion` 和当前 binary 的版本，不一致就 shutdown，让 `invoke` 重新 spawn。Ping 本身 ~0.4ms，对 ~280ms 的 `sim-use ui` 几乎免费。

第二个问题是**模拟器在 daemon 不知情的情况下被关了**。`xcrun simctl shutdown`、用户直接 quit Simulator.app——daemon 还握着 `FBSimulator` handle 不放，下一次 verb 就 crash。我们让 daemon 自己检测 simulator 状态，发现宕了就主动退出、返回一个 `staleSimulator` 错误。这里有个不那么显眼的细节：iOS 在不同状态下吐出来的底层错误字符串不一样（关机、未启动、启动中各有各的说法），我们把这些都识别并包装成统一的可恢复错误，让 agent 拿到错误时有足够信息知道下一步该做什么——比如自动尝试重启模拟器，而不是把一串原始 NSError 描述扔回给用户。

第三个问题是 **stdin 输入跟 daemon 的"stdin 是 /dev/null"冲突**。`sim-use ios type --stdin` 这种命令需要从用户终端读输入，但 daemon 的 stdin 早就指向 /dev/null 了，没法读。修法不复杂——在命令上声明 `daemonBypass`，让这类命令直接走 in-process 路径、绕过 daemon。但这是 daemon 带来的一类新麻烦：**不是所有命令都适合走 daemon**，有些必须留一条逃生通道。

Daemon 要处理的问题和前面几节都不太一样。Outline 和 Quadtree 解决的都是"怎么让 agent 看得清"，更靠近产品决策；Daemon 则是纯粹的性能问题，但它也展示了一种很常见的工程节奏——加速容易，**让加速之后的系统在所有边界条件下都还正确**，才是费功夫的部分。

## 技术内幕（四）：一套命令，两个世界 —— 跨平台设计

`sim-use` 一开始只支持 iOS Simulator。等到这套设计在 iOS 上跑稳了，我们才开始添加 Android 后端。iOS 走 FBSimulatorControl、Android 走 bridge APK + `adb forward`，两边底层完全不同，但对于 LINE 来说，iOS 和 Android 工程师协力开发是日常状态，因此一开始的目标就是创建一个**让两边的命令面看起来一样的工具**，这样，agent 就不需要为不同平台学两套 API，很多面向最终 app 开发的实践能够共享和沉淀。

最关键的设计决定其实很简单：**让命令本身判断设备类型，用户和 agent 默认都不需要 `--platform` 这种参数**。自主识别设备是最容易的：`PlatformRouter` 用三条规则判设备编号——iOS Simulator 是 `8-4-4-4-12` 的标准 UUID 格式，Android 模拟器是 `emulator-` 开头，Android 真机则是一段 ASCII serial（4-32 字符、且必须包含数字）。

前两条很自然，第三条"必须包含数字"是防御性的。`--device foo` 这种笔误如果走 Android 路径，会等 `adb -s foo` 超时 5 秒才报错；走 iOS 路径反而能立刻报出更清楚的错误。这种"错误能多快被人发现"的考量，是我们写规则时经常会做的小决定——agent 跟人不一样，它处理一次模糊错误的代价远高于人：一次失败的工具调用可能直接触发一次完整的 LLM 推理、几千 token 的上下文消耗。让错误尽早、尽具体地暴露出来，是 agent CLI 设计里一条很值得贯彻的原则。

Android 后端跟 iOS 命令面 1:1 对齐之后，我们做了一件不太常见的事：**主动从顶层命令面里删掉了 5 个 iOS-only 的命令**——`key`、`key-combo`、`key-sequence`、`stream-video`、`batch`。它们仍然存在，但只能通过 `sim-use ios <verb>` 调用，不会再出现在顶层 `--help` 里。老命令保留兼容性，但 exit `64`（`EX_USAGE`）并附上一行迁移提示。

理由很简单：`sim-use --help` 列出来的，应该都是真的两个平台都能用的东西。用户读到 `tap`、`type`、`swipe`，应该可以放心写跨平台脚本，不需要担心"噢这个其实只有 iOS 有"。

这是一个有点儿反直觉的决定。多数项目会把"向后兼容"当成第一价值，让命令面慢慢膨胀——加东西容易，删东西难。这在传统面向人类用户开发和运维的语境下，是正确的。但是时代已经变化，在当前的软件开发业态设计工具时，agent friendly 越来越重要。**对一个给 agent 用的工具来说，"命令面诚实"比"命令面稳定"更重要**。Agent 不会带着对历史命名的怀念去使用工具——它只会被那些"看起来应该能做、实际却做不到"的命令坑到。每一个那样的命令都是一次额外的错误处理、一次额外的 fallback prompt、一次本可以避免的 token 消耗。

## 技术内幕（五）：让手指变多 —— 多指触控的技术验证

我们想给 `sim-use` 加上"两指捏合"这个命令。看起来不算大的需求——pinch、rotate、two-finger long-press——但开发过程是我最难忘的一段。原因很简单：它没什么严肃工程的味道，更像是"逆向 + 实验 + 一行的顿悟"。

事情的起点是 [facebook/idb#514](https://github.com/facebook/idb/issues/514) 这个 issue：2020 年开的，标题大意是"idb 什么时候能支持两指手势"。我们开始动手之前它已经躺了**六年**。并不是没人想做——Meta 自家也试过，他们走的是"5 参数调用 + 手动 patch 报文字节"的路线，能用，但脆：任何一次 SimulatorKit 的二进制变动都可能让那段 hardcoded 偏移失效。我们想找一个更稳的入口。

转机来自 `SimulatorKit.framework` 里一个叫 `IndigoHIDMessageForMouseNSEvent` 的私有符号。idb 上游用的是它 5 参数的调用形式，单指够用。但如果用 9 参数的形式调用同一个符号：

```
IndigoHIDMessageForMouseNSEvent(p0, p1, target, eventType, direction,
                                1.0, 1.0, widthPoints, heightPoints)
```

它会生成一个**结构完全不同的包**——一个真正的 two-payload Indigo packet，两个 finger slot 的 state bits 都被正确初始化。5 参数版本不是不能多指，而是它根本不去初始化第二个 finger slot，iOS 那边只会看到一个手指。但一旦切到 9 参数版本，SimulatorKit 自己就会产生正确的包结构，不需要任何硬编码字节偏移；同一份 patch 在 iOS 18.6 和 iOS 26.2 上都直接跑通。

但有意思的部分，是这个原语接到顶层命令之后才开始的。在技术验证阶段，我们以为最难的是"让 iOS 认两个手指"，结果发现真正难的是"让 iOS 认对手势"。

第一个意外是 iOS 不数事件。我们以为得在 Down 和 Up 之间塞很多 Move 才会被识别成连续手势，结果 `steps=1`——一次 Down、一次 Move、一次 Up——iOS 照样把它当成完整的拖动。手势识别器认的是 **finger identifier 的连续性**，不是事件数量。这件事直接简化了顶层 API：我们不需要为不同手势构造不同复杂度的事件流，一个原语足够。

第二个意外更有意思：把 start 和 end 设成同一个点，**不是 no-op，而是一次双指 tap**。Maps 真的会接着这一下缩小一级。这意味着 pinch、rotate、two-finger tap、two-finger long-press 这四个命令，本质上是同一个 multi-touch 原语在不同 `duration` 和 endpoint 几何下的特例。我们最终在 CLI 里也是这样组织的——一个底层原语，几个 preset。

第三个意外把我们卡了两天。直线插值的 rotate 转到 90° 时，两指中点距离会收缩到 71%；转到 180° 时直接收缩到 0。`UIRotationGestureRecognizer` 看到中点距离持续变化，会把它误识别为一个混入的 pinch 手势。所以要进行正确 **rotate** 的话，手势必须沿圆弧插值——几何上一个看起来无所谓的简化（直线 vs 弧线），到了识别器面前就是是非题。

到这里技术验证基本结束，pinch 和 rotate 在 iOS 18 / iOS 26 上都能稳定 zoom in/out 和旋转。但在把它接入产品的过程里，我们又被识别器教育了两次。

第一次是 rotate 的速度。默认 270°/0.5s 跑出来 iOS 跟到 ~360°（`UIRotationGestureRecognizer` 自带惯性），Android 反过来跟到 ~210°（`dispatchGesture` 受帧率限制）。两边都不准，但巧的是它们的"舒服速度"基本重合：~180°/s。我们最后把 rotate 的默认 duration 改成根据旋转角度自适应的数值，让角速度恒定在这个区间，两边识别器都跟得干净。

第二次是 `--radius`。默认值 80 在 iOS Simulator 上是 20% 屏宽，跑得好好的；切到 1080+ px 的 Android emulator 上就变成 7% 屏宽，**低于一般设备的 rotate 阈值，静默失败**——没有任何错误信息，只是看上去没反应。修起来就一行：`max(80, min(w, h) * 0.15)`。但它是那种你不在两台不同设备上分别跑过、就很难注意到的 bug——单平台开发者完全有可能交付一个在另一个平台上"看起来工作但其实没动"的工具。

和前几个细节又有不同：Outline DSL 是为 agent 服务的产品决策，Quadtree 探针是绕过 API 限制的工程兜底，Daemon 是性能问题——它们都是"被规划出来的"。Multi-touch 这些收尾工作没法被规划，只能贴着一线的实际使用一点点磨出来。

## 结语：为什么我们要把它开源

`sim-use` 不是一个新点子，但我们相信它对于推进和解决 agent 在 mobile 开发 loop 的验证环节这件事上，会带来帮助。Cameron Cooke 的 [AXe](https://github.com/cameroncooke/axe) 是它的起点，业界也有 Appium、idb、Maestro 等等。我们站在前人的肩上做了几件具体的事：

- **第一目标是"让 agent 高效消化 UI"，而不是"让脚本能跑"**。Outline DSL 是这件事的直接结果。
- **承认 iOS / Android 的 accessibility API 都不完整**，并用具体的几何 / hit-test 算法把缺口补上。
- **跨平台不是"把一边的设计复制到另一边"**，而是用一套统一的命令面 + 平台特定的实现 + "surface honesty"的纪律来保证 agent 真的能写出跨平台的脚本。
- **足够轻量，容易上手**：一个 7MB 的 binary，加一段几百行的 SKILL.md，就能补上 agent 开发的最后一块拼图，把人从"人肉跑 app"的循环里解放出来，去想更值得想的事。

`sim-use` 已经[在 GitHub 上开源](https://github.com/lycorp-jp/sim-use)。希望这篇能让你对它内部的设计取舍有一些直观的认识。如果你也在做 mobile + AI 这件事，欢迎来提 issue 和 PR。

Agent 写代码的速度，本质上被它能多快验证自己写的代码所限制。在 mobile 这件事上，这个限制至少在今天还是真实存在的。

我们希望 `sim-use` 能让这个限制变小一点。
