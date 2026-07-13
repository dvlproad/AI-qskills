---
name: project-repos-with-pods-draw
version: 0.2.0
description: |
  整理项目（获取并整合 repos_all.json 和 pods_all.json），
  渲染为项目列表的各种格式（markdown / HTML / JSON 数据源）
  或 更新 podspec 到项目列表
---

# 项目列表渲染（repo + pod 数据配图）

获取 repos_all.json（仓库信息）和 pods_all.json（Pod 信息），并将它们整合渲染为项目列表的各种格式。

## 触发条件

- `"整理项目"`
- `"同步或更新 podspec 到项目列表"`

## 执行流程

### 0、判断操作类型

用户触发后，判断是「单条更新 podspec」还是「全量整理项目」：

- 用户提供了 `.podspec` 文件路径（或当前目录下有 `.podspec`）→ **单条更新**，进入 0.1
- 其他 → **全量整理**，跳到 Step 1

#### 单条更新子流程

**0.1、确认 podspec 路径**

- 用户提供了路径 → 使用该路径
- 当前目录有 `.podspec` → 提示用户确认
- 都没有 → 请用户指定路径

**0.2、调用 `project-pods-action` 更新 `pods_all.json`**

调用 [project-pods-action](../project-pods-action/SKILL.md) 的单条更新流程（第五节.3），完成：
- podspec 规范化（`pod ipc spec`）
- 更新 `pods_all.json`（`public-pod-complete2-pods_json.py`）

完成后回到本 skill 继续。

**0.3、重新生成 `repos_with_pods.json`**

确定 `repos_all.json`、`pods_all.json` 的路径（优先 `项目列表/dvlproad项目列表/data/`）。若存在 `skills_all.json` 则一并传入：

```bash
sh scripts/repos_json_append_pods.sh \
  --repos <repos_all.json路径> \
  --pods "<pods_all.json路径>,<skills_all.json路径>" \
  --output <repos_with_pods.json路径>
```

无 `skills_all.json` 时省略即可：

```bash
sh scripts/repos_json_append_pods.sh \
  --repos <repos_all.json路径> \
  --pods <pods_all.json路径> \
  --output <repos_with_pods.json路径>
```

**0.4、提示用户是否继续渲染**

> 已更新 pods_all.json 和 repos_with_pods.json。是否继续？
>
> 1. 不 → ✅ 结束
> 2. 生成 Markdown 版项目列表 → ### 5
> 3. 生成 HTML 版项目列表 → ### 4

---

### 1、获取 repos 信息 `repos_all.json`

Agent 检查 `repos_all.json` 是否存在：

- 检测到 → `检测到 repos_all.json 在 /path/to/file，是否使用？(yes → 使用 / new → 重新获取 / 输入路径)`
- 未检测到 → `未检测到 repos_all.json，请重新获取或输入路径 (new → 重新获取 / 路径)`

- yes → 进入下一步
- new → 执行【一、获取 repos 信息 `repos_all.json`】
- 其他路径 → 尝试使用该路径

获取完毕后提示用户：
> 已更新 repos_all.json。请问是否继续？
>
> 1. 不 → ✅ 结束
>
> 2. 继续 → 进入下一步


### 2、获取数据源（pod + skill）

#### 2.1 获取 pod 信息 `pods_all.json`

Agent 检查 `pods_all.json` 是否存在：

- 检测到 → `检测到 pods_all.json 在 /path/to/file，是否使用？(yes → 使用 / new → 重新获取 / 输入路径)`
- 未检测到 → `未检测到 pods_all.json，请重新获取或输入路径 (new → 重新获取 / 路径)`

- yes → 进入下一步
- new → 执行【二、获取 pod 信息 `pods_all.json`】
- 其他路径 → 尝试使用该路径

#### 2.2 获取 skill 信息 `skills_all.json`

Agent 检查 `skills_all.json` 是否存在：

- 检测到 → `检测到 skills_all.json 在 /path/to/file，是否使用？(yes → 使用 / new → 重新获取 / 输入路径)`
- 未检测到 → `未检测到 skills_all.json，请重新获取或输入路径 (new → 重新获取 / 路径)`

- yes → 进入下一步
- new → 运行 `sh scripts/skills_fetch_to_json.sh`，完成后进入下一步
- 其他路径 → 尝试使用该路径

获取完毕后提示用户：
> 已获取数据源。请问是否继续？
>
> 1. 不 → ✅ 结束
> 2. 继续 → 进入下一步
> 3. 继续 → 进入：追加 Pod 到项目列表.md → 运行 repos_md_append_pods.sh


### 3、整合 repos、pod、skill 数据源 `repos_with_pods.json`

Agent 检查 `repos_with_pods.json` 是否存在：

- 检测到 → `检测到 repos_with_pods.json 在 /path/to/file，是否使用？(yes → 使用 / new → 重新整合 / 输入路径)`
- 未检测到 → `未检测到 repos_with_pods.json，请重新整合或输入路径 (new → 重新整合 / 路径)`

- yes → 进入下一步
- new → 运行 repos_json_append_pods.sh 重建（检测到 skills_all.json 时自动用逗号分隔合并）
- 其他路径 → 尝试使用该路径

**用户确认**：展示整合结果。

- `yes` / `y` → 进入下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入

整合完毕后提示用户：
> 已整合为 repos_with_pods.json。请问下一步做什么？
>
> 1. 不 → ✅ 结束
>
> 2. 生成 HTML 版项目列表 → ### 4
>
> 3. 生成 Markdown 版项目列表 → ### 5

### 4. 可选：生成 HTML 版项目列表

Agent 检查 `dvlproad项目列表.html` 是否存在：

- 检测到 → `检测到 dvlproad项目列表.html 在 /path/to/file，是否打开？(yes → 打开 / new → 重新生成 / 输入路径)`
- 未检测到 → `未检测到 dvlproad项目列表.html 文件，是否生成？(yes → 生成 / no → 跳过)`

- yes → ✅ 打开
- new / yes → 按【五、生成 HTML 版项目列表】渲染，输出路径按【七、输出路径决策】
- no → ✅ 结束

### 5. 可选：生成 Markdown 版项目列表

Agent 检查 `dvlproad项目列表.md` 是否存在：

- 检测到 → `检测到 dvlproad项目列表.md 在 /path/to/file，是否打开？(yes → 打开 / new → 重新生成 / 输入路径)`
- 未检测到 → `未检测到 dvlproad项目列表.md 文件，是否生成？(yes → 生成 / no → 跳过)`

- yes → ✅ 打开
- new / yes → 按【$5.1 $5.2】渲染，输出路径按【七、输出路径决策】
- no → ✅ 结束

#### 5.1 SKILL 渲染出只有 `repos_all.json` 的 项目列表.md



#### 5.2. 运行 repos_md_append_pods.sh ，追加 `pods_all.json` 到 项目列表.md

**用户确认**：展示执行日志和结果。

- `yes` / `y` → 继续下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入





## 一、获取 repos 信息 `repos_all.json`

调用 [project-repos-action](../project-repos-action/SKILL.md) 获取 repos_all.json，完成后回到本 skill 继续。



## 二、获取数据源（`pods_all.json` + `skills_all.json`）

### 1、获取 pod 信息 `pods_all.json`

调用 [project-pods-action](../project-pods-action/SKILL.md) 完成规范化，由它处理：
- podspec 规范化
- CocoaPods 同步到本地/远程
- 获取 & 更新 Pod 数据（pods_all.json）

进入 project-pods-action 后按正常流程走即可，完成后回到本 skill 继续。

### 2、获取 skill 信息 `skills_all.json`

调用 `scripts/skills_fetch_to_json.sh` 扫描 AI-qskills 目录，提取每个 SKILL.md 的 front-matter（name、version、description），输出与 `pods_all.json` 结构一致的 JSON。

```bash
sh scripts/skills_fetch_to_json.sh \
  --skills-dir <AI-qskills路径> \
  --output <skills_all.json路径>
```

输出路径按【七、输出路径决策】确定。通常放在 `项目列表/dvlproad项目列表/data/` 下。

输出结构：

```json
[
  {
    "pod": "normalize-blog-style",
    "version": "0.0.12",
    "git": "https://github.com/dvlproad/AI-qskills",
    "summary": "规范 Hexo 博客的日期显示格式..."
  }
]
```

字段：`pod`（skill 名）、`version`（版本）、`git`（固定 AI-qskills URL）、`summary`（描述）。

### 3、合并到 pod 数据

通过 `--pods` 逗号分隔传入两文件，脚本自动合并：

```bash
sh scripts/repos_json_append_pods.sh \
  --repos repos_all.json \
  --pods "pods_all.json,skills_all.json" \
  --output repos_with_pods.json
```

skill 会作为 Pod 自动匹配到 `AI-qskills` repo 节点下，在渲染时与普通 Pod 一同展示。


## 三、整合 repo、pod、skill 数据源 `repos_with_pods.json`

### 1、脚本介绍

合并 repos_all.json + pods_all.json → repos_with_pods.json，适合管线二的 JSON 中间数据生成。
`--pods` 支持逗号分隔多个文件（如 `"pods.json,skills.json"`），脚本自动合并后处理。

```bash
# repos_json_append_pods.sh — 合并 repos_all.json + pods_all.json → repos_with_pods.json
# 每个 repo 节点追加 pods 字段，顶层含 unmatched_pods 列表
# 面向数据：输出 JSON 中间格式，可供后续渲染 md/html 等
sh repos_json_append_pods.sh \
  --repos repos_all.json \
  --pods pods_all.json \
  --output repos_with_pods.json
```

### 2、运行 repos_json_append_pods.sh 重建 `repos_with_pods.json`。

同时有 pod 和 skill 数据时，逗号分隔传入：

```bash
sh scripts/repos_json_append_pods.sh \
  --repos repos_all.json \
  --pods "pods_all.json,skills_all.json" \
  --output repos_with_pods.json
```

只有 pod 数据时（原流程不变）：

```bash
sh scripts/repos_json_append_pods.sh \
  --repos repos_all.json \
  --pods pods_all.json \
  --output repos_with_pods.json
```



## 四、选择repos.json数据流的处理方向

repos_all.json 生成后，有以下两种方案：

### 管线一：面向生成（直接改 md）：

```
┌─ 管线一 ─────────────────────────────────────────────────────┐
│                                                              │
│                    repos_all.json                            │
│                          │                                   │
│               按 SKILL 渲染（参见 §5：五、SKILL 渲染）           │
│                          ↓                                   │
│                    dvlproad项目列表.md      pods_all.json      │
│                    （初版 · 无Pod）               │            │
│                            \                    /             │
│                             \                  /              │
│                              \                /               │
│                               \              /                │
│                                ↓            ↓                 │
│                          repos_md_append_pods.sh              │
│                          (import repo_find_pod)               │
│                                    │                          │
│                                    ↓                          │
│                           dvlproad项目列表.md                 │
│                           （最终版 · 含Pod表+子库详情）        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 管线二：面向数据（JSON 中间格式）

```
┌─ 管线二 ─────────────────────────────────────────────────────┐
│                                                              │
│              repos_all.json        pods_all.json              │
│                       \                /                     │
│                        \              /                      │
│                         \            /                       │
│                          \          /                        │
│                           ↓        ↓                         │
│                       repos_json_append_pods.sh              │
│                       (import repo_find_pod)                 │
│                                │                             │
│                                ↓                             │
│                          repos_with_pods.json                │
│                                │                             │
│      	     按 repos_with_pods_json_to_md.sh 渲染(待实现)       │
│                                │                             │
│                                ↓                             │
│                         dvlproad项目列表.md                   │
│                        (含Pod表+子库详情+未匹配)                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

两条管线共用 [`repo_find_pod.py` 的匹配逻辑](#匹配逻辑)，数据源相同，输出目标不同。

`repos_with_pods.json` 格式：

```json
{
  "repos": [ /* 同 repos_all.json 结构，每个叶子节点多一个 "pods" 数组 */ ],
  "unmatched_pods": [ /* 未匹配到任何 repo 的 pod */ ]
}
```



## 五、生成 HTML 版项目列表

根据  [dvlproad项目列表_PRD.md](https://dvlproad.github.io/管理相关/项目列表/dvlproad项目列表/dvlproad项目列表_PRD/) 的设计规范，将 `repos_with_pods.json` 渲染为独立 HTML。

> 待实现： repos_with_pods_json_to_html.sh ，将 repos_with_pods.json 渲染为 HTML。

数据加载采用 **数据加载(HTML)规范** 方案（详见《[数据加载(HTML)规范.md](../数据加载(HTML)规范.md)》）。

层级表格（仓库 → Pod → Subspec 展开/收起）采用 **层级数据表格展示规范** 的嵌套可展开表格方案（详见《[层级数据表格展示规范.md](../层级数据表格展示规范.md)》）。

#### 本地正式测试（生成 .js 文件）

如需本地双击即有完整数据，创建 `repos_with_pods.js`：

```bash
DATA_DIR="项目列表/dvlproad项目列表/data"
echo 'window.DATA = ' > "$DATA_DIR/repos_with_pods.js"
cat "$DATA_DIR/repos_with_pods.json" >> "$DATA_DIR/repos_with_pods.js"
```

#### 本地临时测试

无需额外步骤，打开 HTML 后选择 `.json` 文件即可。

#### 文件位置

```
项目列表/
├── dvlproad项目列表.html          ← 渲染器（25 KB，纯逻辑）
├── dvlproad项目列表_PRD.md        ← 设计规范文档
├── dvlproad项目列表.md
└── dvlproad项目列表/
    └── data/
        ├── repos_with_pods.json   ← 数据源（Step 3 生成）
        ├── repos_with_pods.js     ← 可选：file:// 用
        ├── pods_all.json
        └── repos.json
```



## 六、生成 Markdown 版项目列表

> 待实现：repos_with_pods_json_to_md.sh → 将 repos_with_pods.json 渲染为含 Pod 表 + 子库详情 + 未匹配 Pod 的完整 dvlproad项目列表.md。
>
> 遍历 `repos_with_pods.json` 的 `repos` 树，一次遍历完成所有输出：
>
> - 按层级深度输出 heading → intro → repo 表格（格式见 §5）
> - 如果有 `pods` 字段 → 追加 Pod 表（列序：仓库名│开发的Pod│描述│版本│来源│可见│语言）
> - 子库数 ≥ N 或指定 → 追加子库详情
> - 遍历结束 → 追加 `unmatched_pods` 为未匹配 Pod 表

### 1、SKILL 渲染：渲染出只有 `repos_all.json` 的 项目列表.md

手动渲染两条管线中的 md 时，按以下规格输出：

#### 1.1 Repo 表格格式

| 仓库名 | 描述 | 来源 | 组织 | 可见 | 语言 | Stars |
| ------ | ---- | ---- | ---- | ---- | ---- | ----- |

- **描述**放在第二列，方便阅读
- 来源：GitHub / Gitee
- 可见：公有 / 私有

#### 1.2 文档模板

```markdown
---
title: 标题
date: YYYY-MM-DD HH:MM:SS
categories:
- 分类
tags:
- 标签
---

# 标题

> 数据来源: GitHub + Gitee | 更新于 YYYY-MM-DD

---

## 分类名称

### 子分类（可选）

| 仓库名 | 描述 | 来源 | 组织 | 可见 | 语言 | Stars |
|--------|------|------|------|-----------|------|------|
| [仓库名](链接) | 描述内容 | GitHub | dvlproad | 公有 | Objective-C | 0 |
```

### 2、脚本渲染：运行 repos_md_append_pods.sh ，追加 `pods_all.json` 到 项目列表.md

当前 md 中按主表追加 Pod 表，适合管线一的第二阶段：
#### 2.1、脚本介绍

将 Pod 匹配到项目列表，适合管线一的第二阶段

```bash
# repos_md_append_pods.sh — 直接在 md 中按主表追加 Pod 表（面向生成）
sh repos_md_append_pods.sh [--subspec-min-count <N>] [--subspec-force-show PodA,PodB] [--separate-subspecs] <项目列表.md> [pod数据.json]
```

脚本会在每个有 Pod 匹配的 section 下追加 Pod 情况表格，主表完全不改。

参数说明：

- `--subspec-min-count <N>`（可选）— 子库数至少为 N 时展示详情，默认 2
- `--subspec-force-show PodA,PodB`（可选）— 强制展示这些 pod 的子库，默认 CJBaseHelper,CJBaseUtil,CJBaseUIKit
- `--separate-subspecs`（可选）— 每个 pod 独立子库表头

**输出路径确认**：按以下规则确定路径

1. 先检查 `项目列表/dvlproad项目列表/data/` 是否存在
2. 存在 → 推荐给用户
3. 不存在 → 问用户指定
4. 用户留空 → 放当前目录

**匹配逻辑：**

- 按 **git URL** 匹配（去掉 `.git` 后缀比较）
- 同一仓库有多个子 pod 时，汇总到同一 Pod 表
- 无 pod 的 section 不追加任何内容

**加完之后的效果：**

主表不变，每个有 pod 的 section 末尾追加 Pod 情况表：

```markdown
**Pod 情况：**

| 仓库名 | 开发的Pod | 描述 | 版本 | 来源 | 可见 | 语言 |
|--------|-----------|------|------|------|--------|------|
| CJUIKit | CJBaseUIKit | 自定义的基础UI | 0.1.10 | dvlproadSpecs | 私有 | OC |
| CJPopupView | CJPopupView | a pop view | 1.3.0 | CocoaPods | 公有 | OC |
```

- **来源**: `CocoaPods`（公有 trunk）或 `dvlproadSpecs`（私有 specs）
- **可见**: `公有`（CocoaPods）或 `私有`（dvlproadSpecs）
- **语言**: 根据 podspec 的 `swift_version` 字段判断，有为 Swift，否则 OC

#### 2.2、脚本使用

调用 `repos_md_append_pods.sh` 将 pods_all.json 的更新同步到项目列表 markdown 文档。

```bash
sh scripts/repos_md_append_pods.sh \
  --subspec-force-show CJBaseHelper,CJBaseUtil,CJBaseUIKit \
  --subspec-min-count 1 \
  --separate-subspecs \
  <项目列表.md> \
  <pods_all.json>
```

## 七、输出路径决策

输出文件的路径**必须先问用户确认**，Agent 不能默认选中。

决策顺序：

1. Agent 检查 `项目列表/dvlproad项目列表/data/` 目录是否存在
2. **存在** → 推荐给用户："输出到 `data/` 目录下，可以吗？"
3. **不存在** → 问用户："请指定输出路径"
4. 用户留空或不输入 → 放当前工作目录

Agent 话术模板：

> `repos_all.json` 建议放在 `xxx/dvlproad项目列表/data/`（已检测到该目录），可以吗？
> 或者你指定其他路径？留空则放当前目录。

## 八、输出文件

建议都保存到 Hexo 博客目录：

```
/Users/qian/Project/CQBook/dvlproadHexo/source/_posts/管理相关/
```

### dvlproad项目列表.md（可直接查看）

```
/Users/qian/Project/dvlproadHexo/source/_posts/管理相关/项目列表/dvlproad项目列表.md
```



<a id="匹配逻辑"></a>

### 附：`repo_find_pod.py` 的匹配逻辑

`repos_all.json` 中每个 repo 的 `url` 用于和 `project-pods-action` 的 `pods_all.json` 做 `git URL` 匹配，决定 Pod 归属。

`[project-repos-with-pods-draw 的 repo_find_pod.py](./scripts/repo_find_pod.py) 提供 git URL 匹配公共逻辑：

- `build_pod_map(pods)` — 从 `pods_all.json` 构建 `git_url → [pod]` 映射
- `find_pods_for_repo(repo_url, pod_map)` — 按 `(归一化→去协议前缀→含匹配)` 规则返回 `(matched_pods, matched_urls)`

匹配规则：

1. 归一化（去掉 `.git` 后缀、末尾 `/`）
2. 精确匹配
3. 去掉协议前缀（`https://`）后匹配
4. 含匹配（归一化后 url 是 pod git 的子串）

被 `repos_md_append_pods.sh` 和 `repos_json_append_pods.sh` 共用。



## 版本记录

### 0.2.1 (2026-07-11): 新增单条更新 podspec 入口
- 触发条件新增"同步或更新 podspec 到项目列表"
- 新增 Step 0：检测 podspec 文件 → 调用 project-pods-action 更新 pods_all.json → 重新生成 repos_with_pods.json

### 0.2.0 (2026-05-22): 重构标题/触发条件/交互模式，修复结构问题
- 标题改为"项目列表渲染（repo + pod 数据配图）"
- 触发条件以生成/渲染/配图为主，"规范化podspec"降为兼容入口
### 0.1.0 (2026-05-12): 新增 Step 6 HTML 生成流程

### 0.0.1 (2026-05-12): 初始版本
