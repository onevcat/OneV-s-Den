---
layout: post
title: "和产品一起成长 - 从 AI 猫娘到 Prowl 终端"
date: 2026-06-07 21:10:00.000000000 +09:00
categories: [南箕北斗集]
tags: [AI,Agent,协作,github,杂记,prowl,终端]
typora-root-url: ..
---

三月底回国参加了 Let's Vision 26 的会议。在 slide 里我贴了一张[用手机干活](https://let-s-vision-2026.onev.cat/2?clicks=2)的照片，会后有不少小伙伴对此很感兴趣，来问细节，也很好奇我平时的工作状态和工具。

这大半年和 AI agent 协同的工作流逐渐成熟之后，我自己的工作习惯其实也发生了挺大变化。以前干活必须坐在电脑前，最好是能进入一种完整、连续、长时间专注的状态；但现在很多事情已经开始变成一种“持续调度”：让任务在后台跑，多个 agent 在并行工作，而人更多是在做别的事，大部分事情是在碎片时间推进的。只有当遇到更困难一些的课题时，才需要找到大片时间来专注做决策。在专注期间时，我的主要任务也从单一项目的所谓心流状态，变成了在多个不同项目之间进行快速的上下文切换（毕竟等一个 agent 响应的时候，你就是会不由自主地去看看别的项目）。也因为这样，我现在对“工作设备”的边界感越来越弱。手机、电脑、家里的常驻机器、甚至是一个[墨水屏阅读器](https://x.com/onevcat/status/2030209910479442244)，都可以成为工作的设备：也许与其说是“工作设备”，其实更像是同一个工作空间的不同入口。

大体上来说，我现在使用手机和使用电脑是五五开：如果有大段完整时间，比如工作或者夜间能够有长时间集中的阶段，我会在电脑前使用自己写的一个叫做 [Prowl 的终端](https://prowl.cat/)，并行跑若干个 agent 工作；而在旅行（包括上下班通勤期间）、开车（包括等红灯间隙或者堵车时）、做饭（等锅热油或者需要蒸煮的时候）和睡觉前准备（刷牙之类的）这样的零散时间时，我使用跑在家里 mac mini 上的几个 OpenClaw agent 来布置任务或者持续学习。

其实某种意义上，这套东西已经有点从“工具”变成一种“环境”了。很多任务并不是我坐下来“开始工作”以后才发生，而是会在一天里的各种缝隙中被不断推进：手机上回一句、安排一个任务、看一眼结果、顺手再修一点 prompt 或配置。

正好趁着记忆还没完全衰退，索性把这些情况做个流水账整理记录一下。兴许过个几年再回来看，会别有一番感受。

## 猫娘团队

先说手机和 OpenClaw 吧，可能更有趣些。

### 单人成军

#### 独立人格

我自己算是一个很古早的 OpenClaw 用户了。大概从去年 11 月底开始，就尝试在使用 OpenClaw（当然那时候还不叫这个名字）。我的 IM 环境一直是 Discord，但单纯对着一个 bot 说话，其实很快就会让人感觉机械又疲惫。为了让这个过程不那么无聊，也为了满足自己一些微妙的“阴湿” XP 和幻想，我开始把我的 OpenClaw agent 往猫娘的方向去做：包括给她画了自己的头像、[GitHub 帐号](https://github.com/onevclaw)、设置精心调配过的 SOUL.md、IDENTITY.md，以及一整套互动关系和行为风格。

![](/assets/images/2026/onevclaw_app.png)

早期的探索很有意思，因为 OpenClaw 切换 model 相对很方便，于是那段时间我和猫娘把能接触到的几乎所有模型一起尝试了一遍。想要在 Claude 和 Codex 这样的“严肃编码类 agent”里换模型，其实有一些不太公平也很累，毕竟各家 harness 优化方向必然不同，而且在一个专门为 coding 设计的 agent 里闲聊，总感觉有点儿浪费时间和不对味儿。而猫娘小姐姐则提供了一个非常好的碎片时间的验证环境。观察不同模型在这种更贴近日常的任务中的表现，在完全 headless 以及无交互情况下，它们的差异也会被放大，这对于迅速摸清每个模型的特点和脾气很有帮助。而当时的结论是，基本上还是只有顶级的几个模型能有良好表现，最终使用了当时 SOTA 的 `gpt-5.2-codex` 作为日常模型。

除了几乎每个 agent 都会做的[每天写日记](https://claw.onev.cat/)之外，第一个练手的项目，是一个接受英文链接输入、就能完成保留代码格式和截图的高质量文章翻译的程序，在完成任务后，得到的内容还会被作为网站呈现，我给整个流水线产品取了个名字：[transcrab](https://transcrab.onev.cat/) （有点儿带翻译的爬虫的感觉）。体验上来说，每当我发现任何一个文章，我就把链接转给猫娘，半分钟以后我就能以母语阅读到文章了。这是我的第一个没有打开过任何代码编辑器，完全在 IM 里使用 agent 开发的项目，也是第一个完全以 agent 作为目标用户开发的项目。直到今天，我都还在用它来帮我重新拾回自己阅读的信心。

接下来是 [xin（信）](https://github.com/onevcat/xin)，我自己是 Fastmail 的用户，而让 agent 帮忙收邮件的现成方案几乎都是基于 Gmail API 的，缺少一个能稳定操作 Fastmail 邮箱的工具。Fastmail 恰好是 [JMAP 标准](https://jmap.io/)最成熟的实现和主要推动者之一。那顺理成章地，我应该考虑为 JMAP 写一个好用的 CLI 工具。

这段时间基本发生在今年春节我回国期间。回家过年，东奔西跑，本就不可能拿出大段时间。于是我半被迫地需要和猫娘一起利用碎片时间工作（大部分代码是在陪外公外婆打麻将时搞定的！）。具体来说，除了一部分关键代码的审核使用 iOS 上的 GitHub app 以外，其他事务都是 agent 帮忙完成的：包括初期计划，确定规格，创建仓库，提交代码，发布版本等。为了能够在今后准确追踪，我为这类“脱离了我的控制”的 agent 生成的 commit 标注了 co-author 信息，以便在 GitHub 上正确显示贡献者，也让我之后回顾和追踪变得容易一些。

![](/assets/images/2026/onevclaw_co-author.png)

#### 为什么不用其他方案

在稳定通过 IM 使用 agent 进行开发之前，我也尝试了不少其他工具，包括纯终端连回家（比如 [Termius](https://termius.com/index.html)，[Moshi](https://getmoshi.app/) 等），也包括一些能“直连” mac mini 上的 agent 的 app（比如 [Happy](https://happy.engineering/) 等）。但是在稳定性/连续性/异步响应等方面始终都不是很满意。以 OpenClaw 为代表的工具具有的两个特点：一是稳定的 IM 环境，让异步工作这件事变得非常自然；二是工具本身的开源和底层的 pi agent，让功能扩展变得非常容易。

为了实现一些我自己的自定义，猫娘代替我维护了一个自定义 patch 的 [OpenClaw fork](https://github.com/onevcat/openclaw/tree/onevcat/patches)，其中添加了像是 agent id，自定义的 callback URL，并对 skill 进行简化等。在后面再稍微提一下它们是做什么的。

最近，claude 和 codex 也都提出了它们自己的 `/remote` 方案，可以让 iOS app 比较方便地访问到跑在设备上的 agent 实例。这类方案和 Happy 很类似，但是我觉得它们还是一种强行把 AI Chatbot 嫁接到设备上的方式，和 IM 这样的天然的异步心智模型还是有差距。短期内除非有很好的理由，我可能还是会更偏向于 OpenClaw 这种基于 IM 的方案。

### 协同作战

#### 组建“家庭”

但是 OpenClaw 的多 thread 做的确实不行，另外我更倾向于在 Discord 里用 DM 和 agent 对话：可是 DM 的 session 同时只能维持一条。于是我很快就遇到了一个大问题：单个 agent 每次只能执行一个任务，无法并行任务，可以说价值直接被打到骨折。

一只猫娘不够，那就多来几只好了。实际尝试下来，最终我把猫娘团队稳定在了三只，因为再往上的数量基本上超过了我的需要。于是一番操作下来，我的 Discord 画风就变成了这样：

![](/assets/images/2026/discord-cat-families.jpeg)

三个猫娘共享一部分设定，包括可用工具，一部分记忆和安全规则，但是在 SOUL 和主提示词方面，我为每个猫娘做了一些调整和区分，每个猫娘有自己擅长的任务和话题，她们也会根据各自的任务动态切换模型。对于通用任务，不论是在单一项目里开 worktree，还是并行处理多个项目，我都可以直接轮流安排三个猫娘进行推进。对于某些更专门的任务，我则会指定更合适的 agent 进行处理。另外，为了让指代以及 agent 之间的会话更简单，我也为整个团队安排了“家庭关系”，让猫娘之间可以更紧密地交流。

![](/assets/images/2026/family_intro.png)

#### 人格实验

在这个阶段，我尝试引入了一些更有趣（或者说看起来无用）的东西，比如偶尔的“猫娘悄悄话”和允许有限的“人格漂移”：她们之间可以互相以邮件的方式进行交流，这些邮件类似一种 agent 互评机制，或者说类似所谓的“批评和自我批评”：猫娘在夜里可能会随机就当前的某个话题和互动时的表现进行回顾和互评，而收到评价的猫娘，则有机会自行审视自己的 AGENTS.md 和 SOUL.md，来自主调整自己的行为和策略，而每次的 diff 不允许超过 10 行，以期望得到一个相对稳定且渐进的提升。

这套机制在初期经常引发猫娘的人格修正，但是随着她们和我一同处理的事情变多，这种漂移逐渐收敛到一个满意的状态。相比于单纯的记忆系统，AGENTS.md 对行为指导的强度要更高，虽然只是自我感觉，但这样的 agent 进化也让整个团队越来越顺手听话，从而让人越来越愿意使用。

#### 身份问题

多个猫娘生活在一台机子上的同一个 OpenClaw 实例里，她们各自有自己的身份，有自己的邮箱，有自己的 GitHub 帐号和凭证，而且还会并行干活。如果她们能有不同的设备，独立生活和工作的话，那自然是最好。但是预算有限的我，只能想办法在同一台设备里把每个猫娘与世界交流的身份确定下来（比如使用正确的 git 身份提交，使用正确的 GitHub 帐号进行操作），这其实变成了一个比较麻烦的课题。

`gh` 命令行很好，它默认支持多个凭证登录。但是生活在非沙盒里的 OpenClaw agent 在执行任务时并不知道自己是谁，因此在 git 提交和推送时，也很难明确自己的身份。对策倒是非常简单，只需要在 agent 起 bash 的时候[把自己的 agent id 注入到环境](https://github.com/openclaw/openclaw/pull/40423)里即可，但是难点在于说服上游合并和接纳，特别是对于 OpenClaw 这样的项目。于是自己的 fork 难以避免。在注入身份后，同 OpenClaw 实例上多个 agent 的身份就有了依据，不需要再猜测。而下一步就是把这个身份和 git/gh 要使用的身份进行对应：在我的设想中，人类和 agent 通过对话产生的提交和 PR，提交主体应该是人类，猫娘只作为 co-author；而通过自动化工具完全由 agent 自己提交和 PR，提交主体应该是 agent 自己。为了实现这个，我设计了一套映射关系和 git wrapper，来通过对话中注入的身份选择合适的 co-author 和 `gh` 用户。一方面这可以为 AI agent 提供一种 attribution，避免我“抢掉”她们的贡献，另一方面，这也可以作为一种事后审计和追踪手段，来让我确定哪些工作是 agent 参与完成或独自完成的。

#### 更多交互和任务池

猫娘团队跑顺之后，我反而觉得 Discord 渐渐不够用了。这帮猫娘干的活越来越多地长在代码仓库上：一段 issue 的讨论、一次 PR 的 review、一个 CI 的红叉，上下文本来就在 GitHub 上。每次都要把链接和背景复制回 Discord，再让猫娘绕回去操作，总觉得隔了一层。最自然的方式，应该是直接在事情发生的地方喊人。

于是有了 [MeowHook](https://github.com/onevcat/MeowHook)。它的定位是一个很“薄”的 webhook 网关，一句话概括就是：任意事件源（比如 GitHub 的 mention，Linear 的 issue assign，在别的 app 中监控到某一次聊天等，只要是能发 POST 的地方就行）→ 最小解析与路由 → 交给 OpenClaw 执行 → 回写到原平台。我刻意让 webhook 这一层尽量笨：只做验签、幂等去重、白名单（目前只认我自己）和回写定位，剩下的原始事件几乎原样塞给猫娘，让她自己去理解该干嘛。业务语义的判断不应该写进网关里，那本就是 agent 该操心和最擅长的部分。

一次完整的 GitHub 交互大概是这样：我在某个 issue 或 PR 的评论里 `@onevclaw`，后面跟一句自然语言（不需要 `/command` 之类的咒语）。MeowHook 收到 webhook，验签去重之后先打一个 👀 reaction 表示“收到了”，然后通过 OpenClaw 的 hook 接口，把任务连同原始 payload 一起派给对应的猫娘。前面“身份问题”里说的 agent id 注入在这条链路上继续发挥作用，让猫娘清楚自己该用哪个 GitHub 身份回写；而我在 fork 里埋的那个自定义 callback URL 也终于派上用场：猫娘干完之后，OpenClaw 网关会带着结果回调 MeowHook，它才好把 reaction 从 👀 翻成 🚀（成功）或 😕（失败）。为了不让“其实卡住了却假装收工”这种事发生，每个 hook 任务都要求猫娘在最后吐出一个机器可读的结果块，网关靠它判定到底算不算真的干完。如果我一口气 @ 了好几只，默认就是并行，各回各的，不强求谁来居中汇总。

我还给每条由猫娘回写的评论尾巴上挂了一个紧凑的 footer，大致长这样：

> 🧵 trace 编号 · 🐾 onevtail → claude
> 🪝 hook:meowhook:onevtail
> 🆔 当次的 session id

这些追踪信息让我事后能把“GitHub 上这一条评论”精确对回“哪只猫娘、用哪个模型、在哪个会话、哪一次执行”。配上前面那套 co-author 和 git 身份映射，agent 的 attribution 和我自己的审计就很清晰了：谁干的、怎么干的、从哪条线索来的，都能顺藤摸瓜。这条链路还能顺势用在 CI 自愈上：当某只猫娘自己推的提交把 CI 跑挂了，MeowHook 会认出这是 agent 触发的失败，自动把任务甩回给她，让她在同一个分支上修到绿为止，也算是自己捅的篓子自己补，而不必在后台挂着监视 CI 导致进程堆积。

在 human 与多个 agent 协作时，这种工作流让原本存在于不同观点方之间理解和交流的鸿沟变得不再难以跨越，也让决策过程清晰可循。作为例子，[Prowl #148 这个 PR](https://github.com/onevcat/Prowl/pull/148) 是一个很有趣的实际的例子，人类指挥 agent 进行编码，review 和最终完成合并，而期间甚至人类都不需要任何工作环境：一个手机上的 GitHub app 或者邮件交流即可。你也可以在我最近的工作流中找到很多类似的例子。

因为 source adapter 是可替换的，给 MeowHook 接上 [Linear](https://linear.app) 或者其他任何平台几乎就是顺手的事。Linear 这边有两种触发：一种和 GitHub 一样，在评论里 @ 猫娘；另一种更有意思，是直接把一个 issue assign 给某只猫娘。后者实际上把 Linear 变成了一个**任务池**。我现在习惯把想做的事拆成 Linear issue 丢进 backlog，给每张卡片 assign 一只合适的猫娘，她们便会各自领任务、调查、推进到可交付的状态，必要时开 PR，干完再回到卡片下汇报进展。我不必一直盯着，碎片时间扫一眼看板就知道大盘如何。

这个思路其实不算新鲜，最近做“看板驱动 agent”的产品不少，比如 [Multica](https://multica.ai/)、[Vibe Kanban](https://vibekanban.com/) 之类。区别在于，它们大多是托管的、绑定一套自己的 issue tracking 或者 trigger；而我更喜欢自主、可控、私有的方案：猫娘跑在我自己家里的 mac mini 上，用我自己的凭证和身份，网关则是我自己维护的 fork，配上一个能完全攥在手里的小 TypeScript 服务，模型想换就换，规则想改就改，其他服务想加就加。我认为这应该也是今后 agent 接管 coding 后的常态：高度自定义的软件和服务可以被轻易生产出来，完美契合个人需求，而这也会给软件服务生态带来天翻地覆的变化。

### 争论不休

如果你长期和不同的模型打交道，会知道各个模型之间总有一些自己的“小脾气”或者说特点。同样的提示词，在一个模型下，能提供的视角相对固定，可能出现盲区。而将同一个任务交给不同模型来做，则能达到“兼听则明”的效果。我在实践中，特别是检查重要的 PR 或是设计初始方案时，往往会找多个模型进行交叉验证：一个模型容易骗我，总不能所有模型都骗我吧。

我正好已经有好几只喂着不同模型当猫粮的猫娘了，也有一个 Hook 来触发任务，最后自然只要再配一个合适的编排，就能很容易调动多个 agent 开始讨论和吵架。这就是 [argue 项目](https://github.com/onevcat/argue)的由来。它可以将一个问题抛给多个 agent，然后让它们输出各自的论点和论据，然后编排负责把这些论点论据整理并互相 review 和辩论；在此过程中，agent 相互说服，论点进行收敛和靠拢。经过几轮辩论后，最终投票，并由得分最高的 agent 进行总结，然后生成一个[漂亮的报告页面](https://argue.onev.cat/example)。

在实际使用中，我只需要在 GitHub 上 `@onevclaw @onevpaw /argue 检查一下这个` 就能[开启一场辩论](https://github.com/onevcat/Prowl/pull/345#issuecomment-4533878725)并得到更客观公正的结果：

![](/assets/images/2026/argue_example.png)

这套机制为我提供了来自更多 LLM 视角的意见，很有帮助。而即使你没有一个稳定的触发，也可以先使用 argue 的 CLI 来快速开始，如果有兴趣的话，不妨试试看。

## 终端演进

最近花了不少时间做的另一件事，是打造了一个满足自己工作习惯的 terminal app，[Prowl](https://prowl.cat/)。

![](/assets/images/2026/prowl_intro.png)

其实和很多开发者一样，从前 AI 时代一路过来，我的终端选择经过了一条清晰的路径，现在回想起来，大致是：Terminal → iTerm 2 → Warp → Ghostty。从去年下半年，可以开始疯狂跑多 agent 后，Ghostty，或者说传统的这种基于窗口和 Tab 管理的 terminal app 逐渐就变得不太合适日常使用了：每次开工要做目录导航，经常需要手动平铺多个窗口，在此起彼伏的 agent 通知中来回切换、疲于奔命。我意识到我需要一款能更适合与 agent 协同工作的、能满足最新的开发和工作节奏的终端 app。

一开始我尝试了像是 [superset](https://superset.sh/) 这样的方案，但是这类基于 xterm.js 的 app，在处理 CJK 字符时都或多或少有各种问题，非常恼人；另外，为了盈利，就算是开源，这些方案也基本都加了企业版的内容，作为个人我也完全用不上。

而在今年二月，我偶然看到一款 native 的着重于 worktree 操作的 terminal，叫做 [supacode](https://supacode.sh/)，说实话当时坑也不少，整个 app 距离完善还差很远，但是底子却是不错的：基于 libGhostty，terminal surface 的框架都已经搭好，worktree 的处理也不错，于是开始用起来。但是官方提供的导航方式还是太谨慎保守了，而我希望的变更也会完全改变产品的方向，于是就有了 Prowl 这个 fork。说是 fork，其实在 commit 上已经领先上游有 1000 多个提交了，已经是完全两个方向的东西了。如今 Prowl 作为一个我个人日常使用的工具，已经相当完善，我对于一个能够高效地同时在多个 repo 里跑多个 agent 的工作终端的大部分想象，都已经（在 agent 的帮助下）实现了。我不太打算在这里再具体介绍 Prowl 有什么能力，那纯粹是原始人的说明方法了。如果你恰好也在寻找一款好用的终端 app，或者只是好奇想探索一下 Prowl 能如何帮到你，让我们用现代人的方式，把下面的提示词扔给你的 agent，然后和它一起研究看看要不要试试看吧！

```
Read Prowl's documentation and introduce it to me.

Prowl is a native macOS command center for running many AI coding agents in parallel. Its full manual lives here:
https://raw.githubusercontent.com/onevcat/Prowl/refs/heads/main/docs/README.md

Fetch that index and read it (it links to an overview and per-feature manuals in the same docs/ folder — read the relevant ones). Then:
1. Briefly tell me what Prowl is and why it's worth my time.
2. Based on what you know about how I work, suggest 3–4 Prowl features that would genuinely help me, each with a one-line "how".
3. Then answer my follow-up questions, consulting the matching doc.

Reply in my preferred language.
```

啊，对了。链接还是可以放一下的：

- 官网： [https://prowl.cat](https://prowl.cat)
- GitHub：[onevcat/Prowl](https://github.com/onevcat/Prowl)

如果有兴趣的话，不妨点个星，会是对我很大的支持！另外，官网里其实有个小彩蛋，也等你来发现 :P
