---
layout: post
title: "用好你的 jj - 重新思考 Agent 时代的版本控制"
date: 2026-03-16 23:30:00.000000000 +09:00
categories: [一得之愚集]
tags: [AI,大模型,jj,版本控制,vibe coding,Agent]
typora-root-url: ..
---

![](/assets/images/2026/use-jj.jpg)

过去大半年我一直在高强度地用 AI agent 写代码，用着用着发现一个问题：**"怎么组织 agent 吐出来的东西"这件事，比我原来想的重要太多了。**

这话听着可能有点奇怪。大家关心的一般都是模型能力、prompt 怎么写、上下文够不够长……但真的和 agent 密集配合过一阵子之后，你会发现有个更底层的东西一直在拖后腿：版本控制。说得再具体一点，就是你拿什么样的心智模型来管理本地的代码变更。

我现在的结论是：Git 作为远端协作和代码托管的标准还是没什么好说的，但在本地工作流这头，[jj (Jujutsu)](https://github.com/jj-vcs/jj) 明显更适合现在这种人和 agent 来回切着干活的开发方式。这篇文章就是来安利这个的。

## Git 在 Agent 时代的摩擦

Git 是个伟大的工具，这一点没啥好争的。但它的很多设计假设，是建立在二十年前"人类手工编程"的时代背景上——一个人坐在编辑器前面，想清楚要改什么，改完检查一遍，然后 `add`、`commit`、`push`。这套流程是给人类的线性思维量身做的：staging area 给你一个"最后再看一眼"的机会，branch 帮你隔离不同的工作流，stash 让你临时把手头的东西放一放。

说白了，这些机制就是给人类留一口喘气的时间。

但 agent 不需要喘气。

agent 一介入开发，staging area、detached HEAD、rebase in progress、stash 栈——这些隐性状态全都变成了绊脚石。Agent 不理解这些状态，也没必要理解。但你为了让 agent 正确操作 Git，又不得不把这些状态信息当成额外上下文喂给它，白白浪费 token。

这里有个要紧的观察：**agent 的干活方式是"先哗哗地生成一堆，回头再整理历史"，而 Git 的模型偏向"边想边提交"。** 这两件事天然就是拧着的。

想想你有多少次在心流里把自己打断，跟 agent 说"提交一下""先 stash 一下""切到那个分支"。每一次都是一次脱轨——你从"想产品想代码"切到了"想 Git 状态管理"。以前没有 agent 的时候，这点开销还能忍；但你和 agent 配合的节奏越快、频率越密，每次打断的代价就越高。

## jj 和 Change：一个更简单的心智模型

### jj 的定位

[jj (Jujutsu)](https://github.com/jj-vcs/jj) 是一个可以和 Git 无缝共存的版本控制工具。本地用 jj 管理变更，远端依然通过 `jj git push/fetch` 和标准 Git 交互——对 GitHub 和你的同事来说，看到的就是普通的 git commit 和 branch，没有任何区别。

也就是说你可以随时试试看，不喜欢也可以随时退回 Git，没有迁移成本，不存在被锁定的问题。

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

这些就是 jj 的全部日常了。没有 staging area，没有 detached HEAD，没有 stash 栈。光是这些，日常在本地干活就已经清爽不少了。但 jj 真正让我觉得"这东西必须推荐给别人"的地方，是它和 agent 工作流之间的那种天然的契合感。

## 实战场景：当 jj 遇上 Agent 工作流

接下来是我最想聊的部分。每个场景我都会列出 Git 时代的做法——包括你可能会对 agent 说的话——和 jj 下的做法。一对比就很清楚了。

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

每项工作的开头和结尾，你都得指挥 agent 走一遍"检查 → add → commit → push"的仪式，开始新工作前还得记着建分支。这些指令跟你真正想做的事情一点关系都没有，但一天可能得说上好几遍。

**jj**

```
你：开始下一项工作：实现用户头像上传功能
```

jj 永远是"干净"的，Agent 直接无脑 `jj new` 就可以开始干活。甚至可以 `jj describe -m "feat: avatar upload"` 后在这个 change 上直接工作。不需要 add，不需要显式 commit。当你需要推送时，再贴 bookmark 并 push。

版本控制从"每次都要交代的仪式"变成了"背景里自然发生的事"。

### 场景 2：做到一半，临时切去处理别的事

**Git 时代**

```
你：先 stash 一下，切到 master，拉最新代码，新建一个分支来修这个 bug
```

Agent 需要执行 `git stash → git checkout master → git pull → git checkout -b hotfix → ...修完... → git checkout - → git stash pop`。这个链条中间任何一步出了岔子（比如 stash 冲突），agent 都可能卡住或者搞出更多问题来。

**jj**

```
你：先去修一下那个 bug
```

Agent 只需要 `jj new master`，在新 change 里修 bug，修完后 `jj edit` 回到之前的 change 继续。没有 stash，没有分支切换，没有什么状态要恢复。

### 场景 3：完成工作后，拆分变更内容

这大概是日常里最常见的整理场景了：agent 完成了一项（甚至多项）工作，产出了一大坨改动，现在你需要把它们拆成逻辑清晰的提交历史。

**Git 时代**

```
你：检查我们的变更，按照修改的逻辑进行合理拆分，
    并多次提交，保持 commit 合理可追溯
```

说实话，这对 agent 来说挺难的。它需要理解整个 diff、想好怎么拆，然后 `git reset HEAD~1`，再 `git add -p` 交互式地选 hunk——或者手动 `git add` 特定文件然后 commit，来回好几次。这个过程非常脆弱：agent 很容易 add 的时候漏掉文件，少选几行，或者把不相关的改动混进同一个 commit。

**jj**

```
你：按模块拆分当前 change：功能实现、测试、文档各一个
```

Agent 执行 `jj split`，选择文件或 hunk 归到第一个 change，剩下的自动成为第二个。再 `jj split` 一次就拆成三个。全程没有"暂存区"这个概念，也永远不会丢东西，不存在"reset 后忘了 add 某个文件"的风险。拆分错了就回去 edit，后面的 changes 自动 rebase。

### 场景 4：先规划骨架，再让 agent 分段实现

我个人觉得这是 jj 在 agent 工作流里最厉害的用法。

**Git 时代**

基本没有什么对应的自然操作。你顶多在一个外部文档里列出步骤，然后让 agent 一个个做完再 commit。但如果中间某步需要回头改前面的实现，整个提交历史就得用 `rebase -i` 来整理——光是跟 agent 解释清楚怎么 interactive rebase，就够烧一轮上下文了。

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

Agent `jj edit` 到第一个 change，写代码；写完后 `jj edit` 到下一个。每个 change 填充完后，后续 change 自动 rebase，不需要任何手动操作。

还有个比较野的玩法：agent 甚至可以拿描述本身当验收标准——你把测试方法和通过条件都写在 `-m` 里，或者把你的 spec 拆成一堆骨架 change。Agent 跑完一个步骤，自己对照描述确认达标了，才往下走——这就自然形成了一个自驱动的循环。在 Git 里搞这种事情，你得额外维护一份文档，agent 来回对照，可能还得配合 [Ralph Loop](https://github.com/snarktank/ralph) 之类的东西才行，远没有直接把标准写进 change 描述来得顺手。

### 场景 5：多 agent 并行开发

多 agent 并行在现在的开发里越来越常见了，Git 那边 `git worktree` 已经是很多团队的标配。jj 通过 workspace 提供了对等的能力：

```bash
jj workspace add ../agent-1
jj workspace add ../agent-2
jj workspace add ../agent-3
```

每个 workspace 有独立的磁盘目录，但共享底层 store。多个 agent 同时从同一个 base 分叉干活：

```
       → b1 (agent 1)
base   → b2 (agent 2)
       → b3 (agent 3)

```

做完后 `jj new b1 b2 b3` 合并。和 `git worktree` 比的话，jj workspace 不需要提前建 branch，也不需要一个个合并搞出一堆 merge commit，配合 change 模型用起来更顺手一些，不过核心能力是对等的。选 jj 不会在多 worktree 并行的场景下丢掉什么能力。

### 场景 6：Agent 搞砸了，需要快速回退

这件事几乎一定会发生，而且会经常发生。

**Git 时代**

```
你：撤回刚才的修改。
你：什么？操作丢了？你上下文里还有么？（大汗...）
```

Agent 得先判断现在是啥情况：该用 `git reset --hard`？`git checkout .`？`git revert`？还是得翻 `git reflog` 找到之前的状态再 `reset`？每种选择的副作用都不一样，选错了可能把工作成果弄丢，一天白干。

**jj**

```
你：撤回刚才的操作
```

Agent 执行 `jj undo`。一个命令，撤回最后一个操作，不管那个操作具体是什么。如果需要回退到更早的状态，`jj op log` 查看操作级别的历史，`jj op restore <id>` 恢复到任意节点。什么都不会真正丢。

### 小结

回头看这些场景，jj 的好处不光是"少打几个命令"或者"步骤简单一些"。更要紧的是：**你跟 agent 说话的时候可以只说业务上的事，不用操心版本控制的状态。**

当你不再需要说"先 stash""切到那个分支""interactive rebase 一下"的时候，你和 agent 之间的沟通带宽才算真正被释放出来了。你脑子里想的是产品逻辑和代码设计，而不是 Git 的状态机怎么转。

> 在 AI 时代，更重要的能力不是"一次生成完美的提交历史"，而是"低成本地把已有结果整理成合理的历史"。jj 的设计，恰好就是在做这件事。

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

一般来说直接让你的 agent 使用 jj 就好，它的生态和 agent 对它的认识，基本可以做到无缝切换，你只需要在 AGENTS.md 或者 CLAUDE.md 提上一句"这个 repo 在本地使用 `jj` 管理"，然后按照 `jj` 的方式组织提示词并工作就好

但如果你想要给你的 agent 喂一个更精确的操作指南的话，我也配套制作了一个 jj 的 agent skill：[onevcat-jj](https://github.com/onevcat/skills/tree/master/skills/onevcat-jj)，让它可以更好地理解和使用 jj 来管理版本控制——包括本文提到的所有场景。

如果你的 agent 工具支持 [skills.sh](https://skills.sh/) 生态，一行命令就能安装：

```bash
npx skills add onevcat/skills --skill onevcat-jj
```

如果你装了 [OMA (Oh My Agents)](https://oh-my-agents.app/)，点一下就能装：

<a class="btn" href="oma://github.com/onevcat/skills/tree/master/skills/onevcat-jj">用 OMA 安装 onevcat-jj</a>

或者，你也可以直接把下面这段话丢给你的 agent，让它自己搞定：

```
读取 https://github.com/onevcat/skills/tree/master/skills/onevcat-jj 的
SKILL.md 内容，将它作为一个 skill 安装到本地。询问我希望安装到用户全局
还是当前项目，然后把文件放到对应的 skills 目录。
```

## 写在最后

Git 在过去二十年里定义了现代软件开发的协作方式，不管是惯性使然还是生态积累，我想这个地位在很长一段时间内都不会变。但"协作"和"本地工作"是两码事。Git 在协作这头还是没得说的标准；而在本地这头——你怎么组织变更、怎么整理历史、怎么和 agent 配合——也许确实到了该重新想想的时候了。

jj 给出的答案挺朴素的：把那些为人类心理安全感设计的中间状态砍掉，让版本控制的心智模型回到最简单的样子。当 agent 越来越深地参与到日常开发里，这种低成本地重写、拆分、回退和并行的能力，只会越来越重要。

> Git 仍然是你和世界协作的语言；但 jj 可能是你和 agent 一起思考的更好方式。
