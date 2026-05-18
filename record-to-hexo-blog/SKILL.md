---
name: record-to-hexo-blog
description: |
  将内容写入 hexo 博客 — 根据内容匹配合适分类，按规范创建博客文章
  触发场景：被 record-router 路由至此
---

# Record to Hexo Blog — 博客写入规范

将知识/经验/踩坑记录写入 hexo 博客，按规范匹配合适的分类和文件名。

## 触发条件

- 被 record-router 路由"写博客"任务时

## 知识库 — 博客结构

### 根目录

```
~/Project/dvlproadHexo/source/_posts/
```

### 分类体系（来自 总目录.md）

每次写文章前，先参考 `总目录.md` 确定归属分类。主要分类：

| 顶级分类 | 示例子分类 |
|---------|-----------|
| Architecture架构 | 架构相关、框架相关、基础规范、监控相关 |
| 实用工具 | Terminal、Hexo、GitBook、Jenkins、Nginx |
| Script | Shell、Ruby、JavaScript、Python |
| AI | ChatGPT、AIGC、AI Agent、AI Tool |
| iOS部分 | 开发规范、Swift、性能相关、第三方库 |
| Flutter部分 | 入门、集成、交互、详解、进阶 |
| ... | （详见 总目录.md） |

### 文章命名规范

博客文章命名遵循[《命名规范.md》](../命名规范.md)（第三章：博客文章命名规则），包括：
- 文件路径格式 `分类目录/文章名.md`
- 文章名 `域前缀-序号文章名`
- hexo frontmatter 格式
- 图片资源（`post_asset_folder: true`）

同级序号按已有文件递增。

## 执行流程

### 1. 确定分类

读取 `总目录.md`，根据内容匹配合适的分类。不确定时询问用户。

### 2. 确定文件名和路径

按分类下的现有文件序号递增。例如 AI Agent 下已有 ①、②、③，则下一篇为 `AI-④xxx.md`。

### 3. 撰写内容

参照现有文章风格：
- 简洁，附代码/命令
- 记录核心知识和关键要点
- 提及对应的 Skill 路径（如有）
- 不写无意义的废话

### 4. 更新 总目录.md

在对应分类的列表末尾新增条目：

```markdown
  - [第N节：文章标题](分类/文章名)
```

### 5. 确认

让用户确认文章内容和位置，确认后再结束。

## 版本记录

### 0.0.1 (2026-05-18): 初始版本
