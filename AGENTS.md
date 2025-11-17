# AGENTS.md

This file provides guidance to AI agent (like codex or Claude Code) when working with code in this repository.

## 项目概述

这是 OneV's Den（王巍/onevcat 的博客），一个基于 Jekyll 的技术博客，主要专注于 iOS 和 Swift 开发。博客使用 Chirpy 主题，文章主要使用中文撰写。

## 常用开发命令

### 本地运行博客
```bash
bash tools/run.sh
# 带实时更新（需要 fswatch）
bash tools/run.sh -r
```

### 构建站点
```bash
bash tools/build.sh
# 构建到指定目录
bash tools/build.sh -d /path/to/destination
```

### 运行测试
```bash
bash tools/test.sh
```

### 创建新文章
在 `_posts/` 目录下创建新的 markdown 文件，命名规则：
```
YYYY-MM-DD-文章标题.md
```

## 架构概览

### 目录结构
- `_posts/`: 博客文章（Markdown 格式，YYYY-MM-DD-title.md）
- `_layouts/`: Jekyll 布局模板（post、page、home 等）
- `_includes/`: 可复用组件（header、footer、sidebar 等）
- `_plugins/`: 自定义 Jekyll 插件
  - `swift-diff.rb`: Swift diff 语法高亮
  - `raw-content.rb`: 原始内容处理
- `assets/`: CSS、JS、图片资源
  - `css/`: SCSS 文件（编译为 CSS）
  - `js/`: JavaScript 文件（有压缩版本）
  - `images/`: 文章图片（按年份组织）
- `tabs/`: 主导航页面（关于、归档、分类、标签）
- `tools/`: 开发和部署脚本

### 文章元数据
文章使用 YAML front matter，常用字段：
```yaml
---
layout: post
title: "文章标题"
date: YYYY-MM-DD HH:MM:SS +0800
categories: [能工巧匠集] # 或 [一得之愚集], [南箕北斗集]
tags: [标签1, 标签2]
typora-root-url: ..
---
```

### 分类系统
- **能工巧匠集**: 技术类文章，关于开发的工艺和技巧
- **一得之愚集**: 生活感悟和时事评论
- **南箕北斗集**: 吐槽和牢骚，增加世界熵的内容

### 关键配置
- 主配置文件：`_config.yml`
- 站点 URL：https://onevcat.com
- 时区：Asia/Tokyo
- 评论系统：Utterances（基于 GitHub）
- 主题模式：双主题（明/暗）

### 构建流程
构建脚本（`tools/build.sh`）执行步骤：
1. 创建临时容器目录
2. 运行页面创建脚本
3. 使用生产环境构建 Jekyll 站点
4. 复制 markdown 源文件到输出目录供参考
5. 如果在 git 仓库中，提交更改

### 自定义功能
- Swift 语法高亮（支持 diff）
- Utterances 评论系统
- 双主题模式（明/暗）
- 全站中文本地化
- 按年月组织的文章归档

### 开发提示
- 使用 `tools/run.sh -r` 进行实时更新开发
- 图片放置在 `assets/images/YYYY/` 目录
- 使用 Rouge 进行语法高亮
- `_plugins/` 中的自定义插件扩展了功能
- 默认构建输出到 `_site/` 目录

## 写作助手

当你被要求完成 blog 文章写作时，遵循以下原则：

- 先随机挑选几篇已有的文章进行阅读，理解作者 (onevcat) 的写作风格和语气习惯
- 尽量模仿文章作者的行文风格，尽量减少文章的 AI 生成痕迹
- 使用中文进行写作，写作和用词要符合作者人设（科技从业人员，iOS 开发，清华毕业高级知识分子，为人温和，诙谐有趣）
- 对于每个章节，按照提示进行扩写；控制长度，不要让读者感到阅读疲劳
- 除非特别指定，否则采取相对中立的立场进行叙述
- 对于涉及的技术细节，力求准确，如果有不确定的部分，进行网络搜索和事实比对