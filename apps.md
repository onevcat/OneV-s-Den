---
layout: post
title: 我所使用的工具们
date: 2018-11-16 11:32:54.000000000 +09:00
tags: 能工巧匠集
---

工欲善其事，必先利其器。作为创造者，合手的工具可以以倍速提高效率。对于程序员来说，特别是对于在 macOS 上做开发的程序员来说，我们有非常多的 app 选择。
同时，也有很多朋友会好奇我日常做开发时都使用一些什么样的 app。趁这个机会整理一下自己所偏好使用的一些工具。

[数码荔枝](https://www.lizhi.io/)作为国内有名的软件经销商，为我们争取到了很多中国区特供的优惠价格，文中部分工具也提供了优惠合作的购买链接，您可以先
[拿到优惠券](https://partner.lizhi.io/onevcat/cp)，然后以中国地区的专供价格进行购买，通常会比到官网购买便宜很多。通过这样购买的软件我可以拿到一定的
分成，可能可以 cover 这个站点的运营成本。如果您正好需要购买某个 app 的话，还请不妨考虑这种方式。先谢谢啦！

> 「优惠链接」中写的价格是本文写作时在数码荔枝商店中的售价，并不包含优惠券的折扣。这个价格可能会有变动，还请留意。

## 开发工具

Xcode，JetBrains 全家桶之类的这种大家都需要用的就跳过不说了。下面是几个平时用起来很顺手的和软件开发有关的 macOS app。

### [Code Runner](https://coderunnerapp.com)

![](/assets/images/2018/code-runner.jpg)

[Code Runner](https://coderunnerapp.com) 的作用很类似于 Xcode 的 Playground，它能提供一个快速验证和实验想法的地方，你可以输入各种语言的代码，然后去执行它们，迅速得到结果。我一般用它来验证一些小段的程序，看看结果是否正确。如果没问题的话，再把这些代码复制到实际项目里使用。相比于 Xcode 的 Playground，Code Runner 支持各种杂七杂八的语言 (你可以在官网看到详细的支持列表)，并且为部分语言提供开箱即用的媲美 IDE 的补全和调试支持。

另外，在闲暇时做算法题或者写一些有意思的小东西小脚本的时候，Code Runner 也能帮助我快速开始。值得一提的是，Code Runner 的开发者相当良心，从 version 1 到现在 version 3 的升级，都没有再额外收费。这也是我想把这个 app 放到第一个来介绍的原因。

> VS Code 或者其他一些编辑器也有[插件的方式](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner)提供类似 Code Runner 的功能，但是很多时候需要额外的配置，功能上也相较羸弱一些。我个人更愿意选择一个即开即用，节省时间精力，而且确实很优秀的方案。

> [优惠链接 ($14.99 -> ¥99)](https://partner.lizhi.io/onevcat/coderunner)

---

### [Reveal](https://revealapp.com)

![](/assets/images/2018/reveal.jpg)

自从 Xcode 加入了 View Debugging 以来，很多朋友会问是不是可以替代 [Reveal](https://revealapp.com)。我个人的经验来说，不能。也许简单一些的界面可以用 Xcode 自带的凑合，但是如果遇到 view 比较多的复杂界面，或者需要在更深层的地方 (比如 layer 或者某些特定属性) 中查找问题的话，Reveal 带来的便利性远超 Xcode。

几乎如果你有 iOS UI 开发的需求的话，这个工具会为你节省好多小时，换算下来，是一款性价比极高的可以无脑入手的重要工具。

> [优惠链接 ($59 -> ¥329)](https://partner.lizhi.io/onevcat/reveal)

---

### [Flawless](https://flawlessapp.io)

![](/assets/images/2018/flawless.jpg)

这是一个比较小众的工具，它可以把一张图片注入到 iOS 模拟器里，然后以覆盖层或者左右对比的方式，来检查 UI 的位置尺寸颜色等等一系列属性有没有符合要求。对于有设计师出图和对 UI 还原追求比较极致的同学，是很好的工具，可以帮助你真正做到“一个像素都不差”的精致效果。

我之前有一段时间写了很多 UI 的东西，加上日本这边 QA 和设计师都蛮挑剔的，真是会追着一个像素这种问题和你纠缠。这款 app 也帮我省下不少时间来纠结这类问题。但是最近 UI 相对做的比较少，价值就没有那么突出了。

另外，我记得我买的时候一个 license 是 $15，但是好像在写作本文的时候价格变成了 $49，而且只有一年的更新。这相对来说就比较贵了...有兴趣但是嫌贵的同学也可以观望一下。这款 app 还没有国内的经销商。

---

### [Charles](https://www.charlesproxy.com)

![](/assets/images/2018/charles.png)

[Charles](https://www.charlesproxy.com) 这个应该不用再多介绍了，老牌的 HTTP proxy 和代理抓包工具，功能十分强大。不管用来检测网络请求和响应，还是中途拦截和修改请求，或者是检测 socket 数据，都可以自由应对。现在开发几乎不可能不和网络打交道，而 Charles 则让网络部分的开发和调试过程变得轻松不少。

最近 Charles 也推出了 iOS 版本，可以直接在设备上运行，免去了来回在手机中设置代理的麻烦，也可以让 QA 或者测试的小伙伴直接记录请求。

> [优惠链接 ($50 -> ¥199)](https://partner.lizhi.io/onevcat/charles)

---

### [Fork](https://git-fork.com)

![](/assets/images/2018/fork.jpg)

我自己是喜欢使用 GUI 来操作 git 仓库的。几乎 99% 的日常 git 操作相对并不复杂，使用 GUI 会更直接一些，也更快一些。特别在遇到冲突，或者想要查找 log 历史的时候，GUI 的优势就相当明显了。我以前的偏好是 [Tower](https://www.git-tower.com/mac)，但是最近 Tower 把收费模式从一次买断改为了按年订阅，而且订阅期满后则不能再继续使用。我认为这不是一个工具 app 应该有的收费模式，也很不喜欢它们把一些卖点功能单独放在更高价的订阅等级里的做法，所以我并没有升级到 Tower 的订阅。作为替代，我尝试了很多其他的 Git GUI，最终选择了 [Fork](https://git-fork.com) 作为替代。

除了在拖拽支持上还有一点欠缺以外，它能够很好地满足我对一个优秀 Git GUI 的一切幻想。特别它还内置了解决冲突的界面和对比工具，很好地简化了 merge 的流程。界面和交互上也经过了精心打磨，作为一款个人开发者的作品，能有这样的高度和完成度非常不易。

Fork 现在还在 beta 中，但是软件质量可以说远远超出了 beta 的名字，而且作者也承诺今后不会使用订阅制收费。应该是正式 release 我会第一时间购买的 app。

---

### [Paw](https://paw.cloud)

![](/assets/images/2018/paw.jpg)

在写网络代码的时候，我比较倾向于先动手把网络部分的请求都发一遍，先调通，确认服务器端的请求返回都没问题后，再开始开始着手在 app 里实现相关内容。这时候，一个能帮助保存 API 请求和相关参数的工具就很有用。[Paw](https://paw.cloud) 就是这样的一个工具：记录保存 token，按照不同配置参数来生成网络请求，将请求的内容和返回结果共享给 server 端的小伙伴，甚至最后按照网络请求的配置直接生成代码 (虽然这些代码不太可能直接用在项目了...)。

Paw 给了我一个“一站式”的不用自己动脑筋去实现的 HTTP Client 和 API 管理的方式。如果记录保持完整的话，有时候甚至可以作为 server 的状态和返回的测试来运行，在遇到网络方面的疑难杂症时可以帮助快速定位问题所在。

> [优惠链接 ($49.99 -> ¥249)](https://partner.lizhi.io/onevcat/paw)

---

### [CodeKit](https://codekitapp.com)

![](/assets/images/2018/codekit.jpg)

这是一个前端开发的工具，我主要用它来快速将一些像 Sass 或者 TypeScript 的东西编译成相应的 CSS 和 JavaScript 等。通常在一个项目里，这部分内容都应该由类似 Gulp 或者 Webpack 或者 Babel 之类的工具来做。但是我经常会发现，因为我并不是一个专业的 Web 前端开发，很多时候只是在现有的东西上修修改改。通常写对应的任务和配置，以及从头开始架设开发环境所花的时间，会比实际做事的时间还长。CodeKit 解决了这个问题，它提供了一套不太需要配置的工作流，把前端语言编译，asset 压缩等工作自动化，然后提供了 Hot Reload 的 server 来监视这些变化。

基本上把之前需要自行配置的一系列所谓 modern Web 开发的方式，进行了简化和封装，让不那么正规的项目也可以从正规的工作流中受益的一个工具。

> [优惠链接 ($34 -> ¥209)](https://partner.lizhi.io/onevcat/codekit)

---

### [TablePlus](https://tableplus.io/)

![](/assets/images/2018/tableplus.png)

一个数据库可视化的 GUI 工具，可以方便地对 MySQL，PostgreSQL，Redis 和其他各种数据库进行操作和数据查看。写 SQL 或者各类查询语句是一件挺无趣的事情，使用命令行去对数据库更改之类的工作也很不方便。这个 GUI 在同一个环境下为不同的数据库提供 driver，让我们用更人性化的方式去访问和修改数据库。如果是 server 开发，可能会经常有需要查找和操作数据库的话，这个工具应该能加速不少。

> [购买链接 ($49 -> ¥339)](https://partner.lizhi.io/onevcat/tableplus)

---

## 个人工具

然后是一些个人的管理工具和日常使用的 app。

### [Things](https://culturedcode.com/things/)

![](/assets/images/2018/things.jpg)

最近各种事情变多以后，生活经常会没有条理，往往有那种明明记得应该有什么事儿没做，但是就是想不起来的时候，所以需要一个类似 ToDo List 的管理类 app。Things 严格来说是一个简化版的 GTD 类 app，相比最简单的 ToDo List，它在项目分类和时间节点上做得更好。同时，对比 OmniFocus 这样的“硬派”任务管理类 app，它足够简单容易上手。macOS 版本和 iOS 版本的同步，第三方 app 的支持 (比如从邮件客户端 Spark 发送项目给 Things)，和不俗的交互及颜值，都是我选择这个 app 来作为日程管理的理由。毕竟上面记录了每天都要面对的烦心事儿，要是 app 本身再让人心烦的话，这生活就没法过了...

---

### [Agenda](https://agenda.com)

![](/assets/images/2018/agenda.png)

作为一个和日历绑定的笔记本在使用。Things 主要是记录任务和日程，而 Agenda 主要用来记录更长一些的想法，比如会议上要做的发言，读某篇博客或者某本书的心得体会，这样的东西。对于任何不太合适扔到 Things 的内容，我都会选择放到这里备查。一开始我还担心按照日期和日历来组织笔记会有会很奇怪，但是实际用上以后发现其实也还是可以结合项目来整理，笔记的查找和复习也相当方便。像是会议准备和发言这些内容，更是可以及时归档，保持整洁。

Agenda 一个比较有意思的地方，是它的收费模式。它们采用自称做[「现金奶牛」](https://medium.com/@drewmccormack/a-cash-cow-is-on-the-agenda-138a11995595)的收费方式，每次付费，你可以得到迄今为止的所有附加功能，以及未来一年的更新。即使到期以后，你也可以继续拥有已有特性以及对新系统的支持，直到下一次出现你想要续费购买的新特性时，你才需要另行付费。这种模式相当新颖，也同时激发了用户的购买欲和给了开发者持续努力的动力，很有意思。

这个 app 的 iOS 和 macOS 多端同步也非常好，总体质量不愧于 WWDC 2018 的 Design Award。如果还没有尝试过的同学，不妨一试。

---

### [PDF Expert](https://pdfexpert.com)

![](/assets/images/2018/pdf-expert-sample.png)

Readdle 家的 app 质量都相当有保证，除了这款老牌的 PDF 阅读器，我同时也在使用他们的[邮件 app Spark](https://sparkmailapp.com) 和[日历 app Calendars 5](https://readdle.com/calendars5)。即使以最严厉的眼光来看，他们的这些 app 几乎都挑不出什么毛病。PDF Expert 提供了优良的浏览性能和相当丰富的笔记特性，对于 PDF 效果的还原以及各种辅助阅读的功能都相当完善。我在 macOS 和 iPad 上都使用它来阅读和管理各类技术电子书籍。

> [优惠链接 ($79.99 -> ¥199)](https://partner.lizhi.io/onevcat/tableplus)

---

### [Bartender](https://www.macbartender.com)

macOS 的右上状态栏一直是“兵家必争之地”。有些 app 确实利用状态栏图标做了合适的事情，让使用 app 变得更加方便。但是也难免有一些“毒瘤”要突出自己的存在感，强制性地把自己的图标放上去，还不给用户留出选项。在 app 逐渐变多后，状态栏经常过度膨胀，杂乱无章。Bartender 正是为了解决这个问题而出现的。你可以指定折叠某些不常用的状态栏图标，或者干脆永久隐藏它们。对于 MacBook 笔记本来说，屏幕宽度本来就不像 iMac 那样可供“挥霍”，所以基本在我的笔记本上这也是保持清爽的必备 app 了。

> [优惠链接 ($15 -> ¥89)](https://partner.lizhi.io/onevcat/bartender)

---

## 后记

对于文中没有介绍到的很多工具，可能在数码荔枝也有特价出售，您可以[拿到优惠券](https://partner.lizhi.io/onevcat/cp)，然后去逛一逛网店看看有没有需要。

另外，如果你还有什么值得分享的工具类 app，不论是可以帮助提高开发效率的，还是帮助更好地使用 macOS 的，都欢迎留言提出~也许通过努力，我们也可以为大家争取到国内的分销商特价，以造福国内开发者。