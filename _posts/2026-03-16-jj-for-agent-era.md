---
layout: post
title: "用好你的 jj - 重新思考 Agent 时代的版本控制"
date: 2026-03-16 12:00:00.000000000 +09:00
categories: [一得之愚集]
tags: [AI,大模型,jj,版本控制,vibe coding,Agent]
typora-root-url: ..
---

在过去大半年深度使用 AI agent 辅助开发的过程中，我逐渐意识到一件事：**"怎么组织 agent 的产出"这件事，比想象中重要得多。**

这话听起来可能有点奇怪。大家关注的焦点往往是模型能力、prompt 技巧、上下文管理……但当你真的和 agent 一起高强度地迭代了一段时间之后，会发现有一层更基础的东西在暗中影响效率：版本控制。更准确地说，是你用什么样的心智模型来管理本地的代码变更。

我现在的结论是：Git 作为远端协作和代码托管的标准依然不可撼动，但在本地工作流这一端，[jj (Jujutsu)](https://github.com/jj-vcs/jj) 明显更适合今天这种人与 agent 交替工作的开发方式。这篇文章就是来安利这件事的。

## Git 在 Agent 时代的摩擦

Git 是一个伟大的工具，这一点没有任何争议。但它的很多设计假设，是建立在二十年前"人类手工编程"这个时代背景上的——一个人坐在编辑器前，想清楚要改什么，改完后检查一遍，然后 `add`、`commit`、`push`。这套流程为人类的线性思考量身定做，staging area 给你"最后再看一眼"的机会，branch 帮你隔离不同的工作流，stash 让你临时把手头的东西放一放。

这些机制的本质，是为人类争取"喘一口气"的时间。

但 agent 不需要喘气。

当 agent 介入开发后，staging area、detached HEAD、rebase in progress、stash 栈——这些隐性状态全都变成了摩擦源。Agent 不理解、不需要理解、也不应该理解"我现在处于什么 Git 状态"。然而为了让 agent 正确地操作 Git，你不得不把这些状态信息作为额外的上下文传递给它，这本身就是无意义的消耗。

这里有一个关键观察：**agent 的产出模式是"先大量生成，再整理历史"，而 Git 的模型更偏向"边想边提交"。** 这两者之间存在根本性的不匹配。

想想你有多少次在心流中打断自己，对 agent 说"提交一下""先 stash 一下""切到那个分支"。每一次这样的指令都是一次心流中断——你从"思考产品和代码"切换到了"思考 Git 状态管理"。在 agent 深度介入开发之前，这种切换的代价还可以接受；但当你和 agent 的协作节奏变得更快、更密集之后，每一次中断的成本都会被放大。

## jj 和 Change：一个更简单的心智模型

### jj 的定位

[jj (Jujutsu)](https://github.com/jj-vcs/jj) 是一个可以和 Git 无缝共存的版本控制工具。本地用 jj 管理变更，远端依然通过 `jj git push/fetch` 和标准 Git 交互——对 GitHub 和你的同事来说，看到的就是普通的 git commit 和 branch，没有任何区别。

这意味着你可以随时尝试，也可以随时无缝退回 Git，没有迁移成本，没有锁定效应。

安装也就一行的事：

```bash
brew install jj
cd your-repo
jj git init --colocate
```

### 用一个例子理解 Change

jj 的核心概念是 **change**。与其列一堆定义，不如直接上手看看。

假设你在一个现有 repo 里刚启用了 jj，跑一下 `jj log`：

```
@  kxryzmsp  (empty) (no description set)
○  master
```

`@` 表示你当前所在的 change，`kxryzmsp` 是它的 **Change ID**——一个跨 rebase 不变的唯一标识。你不需要记 branch name 或 commit hash，这个短 ID 就是你在 jj 世界里的坐标。一般来说，你甚至可以只用前两个或者前三个字母来代表它。

现在开始写代码。改了几个文件后，再跑 `jj log`：

```
@  kxryzmsp  (no description set)
│  modified: src/auth.rs, src/main.rs
○  master
```

注意：**你什么都没做，改动已经属于当前 change 了。** 没有 `git add`，没有 staging area，不存在"改了但还没 add"这种中间态。在 jj 里，你的 working copy 本身就是一个 change，文件一改，它就跟着变。

这段工作做完了，给它一个描述：

```bash
jj describe -m "feat: add auth module"
```

这就像写 commit message，但有一个重要区别：**随时可以改**。甚至可以对任意 change 改（`jj describe -r <change-id> -m "..."`），不需要 `rebase -i` 来修改历史消息。

开始下一项工作：

```bash
jj new
```

```
@  wqnyzlkr  (empty) (no description set)
○  kxryzmsp  feat: add auth module
○  master
```

`jj new` 做的事情很简单：把当前 change 定格，创建一个新的空 change 作为你的新工作台。相当于 Git 的 `commit` + 开始新工作，但不需要 `add` 这个步骤。（顺便一提，为了照顾 `git` 习惯，`jj commit` 也存在：`jj commit -m "..."` 就是 `describe` + `new` 的 alias。）

几个 change 下来，你的 `jj log` 可能长这样：

```
@  tpqrstuv  (empty) (no description set)
○  wqnyzlkr  feat: add token refresh
○  kxryzmsp  feat: add auth module
○  master
```

到这里，你其实已经理解了 jj 80% 的日常。接下来几个操作也很直观。

#### 分叉：`jj new <change-id>`

从某个 change 开始新工作，不影响原来的链：

```bash
jj new kx
```

```
○  wqnyzlkr  feat: add token refresh
│
│ @  mnopqrst  (empty) (no description set)
├─╯
○  kxryzmsp  feat: add auth module
○  master
```

#### 回到旧 change 继续修改：`jj edit`

```bash
jj edit kx
```

直接跳回那个 `kxryzmsp` change 继续改代码。改完后，后续所有 change 自动 rebase，没有 detached HEAD，也不需要手动操作。

值得一提的是：对于已经推送到远端的 immutable change，`jj edit` 会直接报错（`Error: Commit <hash> is immutable`），防止你意外改写已发布的历史。jj 在工具层面帮你守住了这个安全边界，你不需要自己记住"这个能不能改"。

#### Merge：给 `jj new` 传多个 parent

```bash
jj new wqnyzlkr mnopqrst
# 当然，只要不重复，你也可以写 
# jj new wq mn
```

```
@  uvwxyzab  (empty) (no description set)
├─╮
○ │  wqnyzlkr  feat: add token refresh
│ ○  mnopqrst  fix: hotfix for auth
├─╯
○  kxryzmsp  feat: add auth module
○  master
```

#### Rebase

把 `mnopqrst` 移到 `wqnyzlkr` 后面：

```bash
jj rebase -s mnopqrst -d wqnyzlkr
```

```
@  mnopqrst  fix: hotfix for auth
○  wqnyzlkr  feat: add token refresh
○  kxryzmsp  feat: add auth module
○  master
```

原本分叉的两条线变成了一条直线，就这么简单。

#### 和远端 Git 交互

jj 通过 **bookmark** 和 Git 世界桥接。`jj git fetch` 时，远端的 Git branch（比如 `master`）会自动映射为 jj 的 bookmark——所以你在 `jj log` 里看到的 `master` 就是远端的 `master` branch。

拉取并 rebase 到最新：

```bash
jj git fetch
jj rebase -d master
```

相当于 Git 的 `git pull --rebase`，但拆成了两个明确的步骤：先拿数据，再决定怎么整合。

推送时反过来，给你的 change 贴一个 bookmark（映射成 Git branch）：

```bash
jj bookmark create my-feature -r wqnyzlkr
jj git push
```

Bookmark 只在和远端交互时才需要，本地工作几乎不用想 branch 这个概念。

---

这些就是 jj 的全部日常了。没有 staging area，没有 detached HEAD，没有 stash 栈。光是这些，已经能让日常的本地工作变得更清爽。但 jj 真正让我觉得"这东西必须推荐"的地方，是它在 agent 工作流下展现出的契合度。

## 实战场景：当 jj 遇上 Agent 工作流

接下来是我最想聊的部分。每个场景我都会同时列出 Git 时代的做法——包括你可能会对 agent 说的提示词——和 jj 下的做法。对比之下，差异会非常直观。

### 场景 1：最简单的日常——开始下一项工作

**Git 时代**

```
你：看看现在的改动情况，把这些变更提交并推送，
    然后新建一个分支，开始下一项工作：实现用户头像上传功能
```

工作结束后：

```
你：检查一下改动，没问题的话提交并推送
```

每一项工作的开始和结束，你都需要显式地指挥 agent 完成"检查 → add → commit → push"这套仪式，开始新工作前还得记得创建分支。这些指令和你要做的事情本身毫无关系，但可能你不得不每天说上好几次。

**jj**

```
你：开始下一项工作：实现用户头像上传功能
```

jj 永远是“干净”的，Agent 直接无脑 `jj new` 就可以开始干活。甚至可以 `jj describe -m "feat: avatar upload"` 后在这个 change 上直接工作。不需要 add，不需要显式 commit。当你需要推送时，再贴 bookmark 并 push。

版本控制从"每次都要交代的仪式"变成了"背景里自然发生的事"。

### 场景 2：做到一半，临时切去处理别的事

**Git 时代**

```
你：先 stash 一下，切到 master，拉最新代码，新建一个分支来修这个 bug
```

Agent 需要执行 `git stash → git checkout master → git pull → git checkout -b hotfix → ...修完... → git checkout - → git stash pop`。这个链条中间任何一步出错（比如 stash 冲突），agent 都可能卡住或做出错误判断。

**jj**

```
你：先去修一下那个 bug
```

Agent 只需要 `jj new master`，在新 change 里修 bug，修完后 `jj edit` 回到之前的 change 继续。没有 stash，没有分支切换，没有状态要恢复。

### 场景 3：完成工作后，拆分变更内容

这大概是日常里最常见的整理场景了：agent 完成了一项（甚至多项）工作，产出了一大坨改动，现在你需要把它们拆成逻辑清晰的提交历史。

**Git 时代**

```
你：检查我们的变更，按照修改的逻辑进行合理拆分，
    并多次提交，保持 commit 合理可追溯
```

说实话，这对 agent 来说很难。它需要理解整个 diff、规划拆分策略，然后 `git reset HEAD~1`，再 `git add -p` 交互式地选择 hunk——或者手动 `git add` 特定文件然后 commit，反复多次。整个过程非常脆弱：agent 很可能在 add 的时候遗漏文件，少了几行，或者把不相关的改动混进同一个 commit。

**jj**

```
你：按模块拆分当前 change：功能实现、测试、文档各一个
```

Agent 执行 `jj split`，选择文件或 hunk 归到第一个 change，剩下的自动成为第二个。再 `jj split` 一次就拆成三个。全程没有"暂存区"这个概念，也永远不会丢东西，不存在"reset 后忘了 add 某个文件"的风险。拆分错了就回去 edit，后面的 changes 自动 rebase。

### 场景 4：先规划骨架，再让 agent 分段实现

这是我个人认为 jj 在 agent 工作流下最强力的场景。

**Git 时代**

几乎没有对应的自然操作。你最多能在一个外部文档里列出步骤，然后让 agent 一个个做完再 commit。但如果中间某步需要回头改前面的实现，整个提交历史就得用 `rebase -i` 来整理——光是解释清楚怎么 interactive rebase，就够消耗一轮上下文了。

**jj**

先创建一串 change 骨架，每个都是空的，只有描述（`jj` 的提交格式和 `git` 一致：首行作为标题，后续空行后作为描述，所以你也完全可以在 `-m` 后面写小作文甚至 prompt）：

```bash
jj commit -m "refactor: extract auth module"
jj commit -m "feat: add token refresh logic"
jj commit -m "test: update auth tests"
jj commit -m "docs: update API documentation"
```

然后对 agent 说：

```
你：参考各 change 的描述，从 kxry 开始，顺次处理每个 change 的实现
```

Agent `jj edit` 到第一个 change，写代码；写完后 `jj edit` 到下一个。每个 change 填充后，后续 change 自动 rebase，不需要任何手动操作。

一个邪修用法是 agent 甚至可以直接根据描述来验收当前步骤的实现是否达标，比如把测试方法和验收标准都写在 `-m` 里，或者把你的 spec 转换成一堆骨架 change。Agent 在确认达标后，才允许继续下一个——这能形成天然的自驱动闭环。而在 Git 里，这种"步骤 + 验收标准"通常需要额外维护一份外部文档，agent 还得来回对照，再配合一点 [Ralph Loop](https://github.com/snarktank/ralph) 才能实现，这远不如 change 描述这样内嵌在版本历史中来得自然。

### 场景 5：多 agent 并行开发

多 agent 并行在当下的开发工作流中越来越常见，Git 的 `git worktree` 已经是很多团队的标配了。jj 通过 workspace 提供了对等的能力：

```bash
jj workspace add ../agent-1
jj workspace add ../agent-2
jj workspace add ../agent-3
```

每个 workspace 有独立的磁盘目录，但共享底层 store。多个 agent 同时从同一个 base 分叉工作：

```
       → b1 (agent 1)
base   → b2 (agent 2)
       → b3 (agent 3)

```

做完后 `jj new b1 b2 b3` 合并。和 `git worktree` 相比，jj workspace 不需要提前建 branch，也不需要一个个合并弄出一堆 merge，配合 change 模型使用起来更自然一些，但核心能力是对等的。选择 jj 不会在并行多 worktree 场景下丢失任何能力。

### 场景 6：Agent 搞砸了，需要快速回退

这件事几乎一定会发生，而且会频繁发生。

**Git 时代**

```
你：撤回刚才的修改。
你：什么？操作丢了？你上下文里还有么？（大汗...）
```

Agent 需要判断当前的状态：是用 `git reset --hard`？`git checkout .`？`git revert`？还是得 `git reflog` 找到之前的状态再 `reset`？每种选择有不同的副作用，选错了可能丢失工作成果，导致一天白干

**jj**

```
你：撤回刚才的操作
```

Agent 执行 `jj undo`。一个命令，撤回的是最后一个操作，不管这个操作具体是什么。如果需要回退到更早的状态，`jj op log` 查看操作级历史，`jj op restore <id>` 也可以恢复到任意历史节点。什么都不会真正丢失。

### 小结

回看这些场景，jj 的优势不仅仅是"命令更少"或者"步骤更简单"。更关键的变化在于：**你给 agent 的提示词可以更专注于业务意图，而不是版本控制的状态管理。**

当你不再需要说"先 stash""切到那个分支""interactive rebase 一下"的时候，你和 agent 之间的沟通带宽就真正被释放出来了。你在想产品逻辑和代码设计，而不是在想 Git 的状态机。

> 在 AI 时代，更重要的能力不是"一次生成完美的提交历史"，而是"低成本地把已有结果整理成合理的历史"。jj 的整个设计，恰好就是为这件事服务的。

## 最小可用命令速查

如果你看到这里已经有点心动了，下面这张表就是你需要的全部。十个命令，覆盖 jj 的日常使用：

| 操作 | jj | Git 等效 |
|------|------|----------|
| 查看状态和历史 | `jj log` | `git log --oneline --graph` + `git status` |
| 给当前改动写描述 | `jj describe -m "..."` | `git commit -m "..."`（但 jj 可随时改） |
| 开始下一段工作 | `jj new` | `git commit` + 继续编辑 |
| 切到某个 change 继续编辑 | `jj edit <change>` | `git checkout <hash>`（但不会 detach） |
| 拆分一个 change | `jj split` | `git reset HEAD~1` + 反复 `git add -p` + `git commit` |
| 撤回上一步操作 | `jj undo` | `git reflog` + `git reset` |
| 拉取远端 | `jj git fetch` | `git fetch` |
| Rebase 到最新 master | `jj rebase -d master` | `git rebase master` |
| 标记要推送的 change | `jj bookmark create feat -r @` | `git branch feat` |
| 推送 | `jj git push` | `git push` |

会这些就够了。剩下的，边用边学。

## 让 Agent 直接用上 jj

一般来说直接让你的 agent 使用 jj 就好，它的生态和 agent 对它的认识，基本可以做到无缝切换，你只需要在 AGENTS.md 或者 CLAUDE.md 提上一句“这个 repo 在本地使用 `jj` 管理”，然后按照 `jj` 的方式组织提示词并工作就好

但如果你想要给你的 agent 喂一个更加精确一些的操作指南的话，我也配套制作了一个 jj 的 agent skill，让它可以更好地理解和使用 jj 来管理版本控制——当然包括本文提到的所有场景。大部分情况下，应该是够用了。

TODO: 附 skill 的链接和简要说明

## 写在最后

Git 在过去二十年里定义了现代软件开发的协作方式，不论是由于惯性还是由于生态的积累，在未来很长一段时间内，我想这个地位是不会改变的。但"协作"和"本地工作"却是两件事。Git 在协作端依然是无可争议的标准；而在本地端——你如何组织变更、如何整理历史、如何和 agent 配合——也许已经到了值得重新思考的时候。

jj 给出的答案很朴素：去掉那些为人类心理安全感设计的中间状态，让版本控制的心智模型回归到最简单的形态。当 agent 越来越深入地参与日常开发，这种低成本的重写、拆分、回退和并行的能力，只会越来越重要。

> Git 仍然是你和世界协作的语言；但 jj 可能是你和 agent 一起思考的更好方式。
