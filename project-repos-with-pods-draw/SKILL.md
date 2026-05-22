---
name: project-repos-with-pods-draw
description: |
  podspec 规范化。如果是公有库还可以选择是否继续同步更新到项目列表
  触发场景：用户输入"规范化podspec"、"完善pod注释"、"完善公有库"
---

# podspec 规范化

podspec 规范化是公有库和私有库都需要的操作，对于公有库还可以选择是否继续同步更新到项目列表。

## 触发条件

- "规范化podspec" — 规范化 podspec 文件（子库注释 + description）
- "完善pod注释" — 完善 pod 的 subspec 注释
- "完善公有库" — 完善公有库的 pod 注释并更新到项目列表
- "给pod加注释" — 给 podspec 加注释
- 其他表达完善 pod 注释或规范化 podspec 意图的指令

## 执行流程

### 1、获取 repos 信息 `repos_all.json`

询问用户是否获取到了最新的 `repos_all.json` 的信息。

- 是 → 进入下一步

- 否 → 执行【一、获取 repos 信息 `repos_all.json`】，然后提示用户：

  > 恭喜你已更新 repos_all.json。请问是否继续？
  >
  > 1. 不 → ✅ 结束
  >
  > 2. 继续 → 进入下一步
  >


### 2、获取 pod 信息 `pods_all.json`

询问用户是否获取到了最新的 `pods_all.json` 的信息。

- 是 → 进入下一步

- 否 → 执行【二、获取 pod 信息 `pods_all.json`】，然后提示用户：

  > 恭喜你已更新 pods_all.json。请问是否继续？
  >
  > 1. 不 → ✅ 结束
  >
  > 2. 继续：整合 repos_all.json 和 pods_all.json，后续作为 md 或者 html 等的数据源
  >
  >    运行 repos_json_append_pods.sh ，重建 `repos_with_pods.json`。
  >
  > 3. 继续：对我用 repos_all.json 得到的 项目列表.md 文档，增加更新的 pod
  >
  >    运行 repos_md_append_pods.sh ，将 pods_all.json 的更新同步到项目列表 markdown 文档


### 3、整合 repo 和 pod  数据源 `repos_with_pods.json`

询问用户是否获取到了最新的 `repos_with_pods.json` 的信息。

- 是 → 进入下一步
- 否 → ✅ 结束



**用户确认**：展示执行结果。

- `yes` / `y` → 完成，告知用户全部流程结束
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 4. 可选：生成 HTML 版项目列表

询问用户：

> 是否根据 `dvlproad项目列表_PRD.md` 的设计规范，将 `repos_with_pods.json` 渲染为独立 HTML？

- 否 → ✅ 结束
- 是 → 生成 HTML → ✅ 结束

### 5. 可选：生成 Markdown 版项目列表

#### 5.1 SKILL 渲染出只有 `repos_all.json` 的 项目列表.md



#### 5.2. 运行 repos_md_append_pods.sh ，追加 `pods_all.json` 到 项目列表.md

**用户确认**：展示执行日志和结果。

- `yes` / `y` → 继续下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入





## 一、获取 repos 信息 `repos_all.json`



## 二、获取 pod 信息 `pods_all.json`

### 1. 调用 project-pods-action 完成规范化

直接调用 [project-pods-action](../project-pods-action/SKILL.md) 这个SKILL处理，由它完成：
- podspec 规范化
- CocoaPods 同步到本地/远程
- 获取 & 更新 Pod 数据（pods_all.json）

进入 project-pods-action 后按正常流程走即可，完成后回到本 skill 继续。



## 三、整合 repo 和 pod  数据源 `repos_with_pods.json`

### 1、脚本介绍

合并 repos_all.json + pods_all.json → repos_with_pods.json，适合管线二的 JSON 中间数据生成：

```bash
# repos_json_append_pods.sh — 合并 repos_all.json + pods_all.json → repos_with_pods.json
# 每个 repo 节点追加 pods 字段，顶层含 unmatched_pods 列表
# 面向数据：输出 JSON 中间格式，可供后续渲染 md/html 等
sh repos_json_append_pods.sh <repos_all.json> <pods_all.json> [输出.json]
```

### 2、运行 repos_json_append_pods.sh 重建 `repos_with_pods.json`。

```bash
sh scripts/repos_json_append_pods.sh \
  repos_all.json \
  pods_all.json \
  repos_with_pods.json
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

```bash
# repos_md_append_pods.sh — 直接在 md 中按主表追加 Pod 表（面向生成）
sh repos_md_append_pods.sh [--subspec-min-count <N>] [--subspec-force-show PodA,PodB] [--separate-subspecs] <项目列表.md> [pod数据.json]
```

调用 `repos_md_append_pods.sh` 将 pods_all.json 的更新同步到项目列表 markdown 文档。

```bash
sh scripts/repos_md_append_pods.sh \
  --subspec-force-show CJBaseHelper,CJBaseUtil,CJBaseUIKit \
  --separate-subspecs \
  <项目列表.md> \
  <pods_all.json>
```

**输出路径确认**：按以下规则确定路径

1. 先检查 `项目列表/dvlproad项目列表/data/` 是否存在
2. 存在 → 推荐给用户
3. 不存在 → 问用户指定
4. 用户留空 → 放当前目录





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

`repos_all.json` 中每个 repo 的 `url` 用于和 `organize-pod-to-md` 的 `pods_all.json` 做 `git URL` 匹配，决定 Pod 归属。

`[organize-pod-to-md 的 repo_find_pod.py](../organize-pod-to-md/scripts/repo_find_pod.py) 提供 git URL 匹配公共逻辑：

- `build_pod_map(pods)` — 从 `pods_all.json` 构建 `git_url → [pod]` 映射
- `find_pods_for_repo(repo_url, pod_map)` — 按 `(归一化→去协议前缀→含匹配)` 规则返回 `(matched_pods, matched_urls)`

匹配规则：

1. 归一化（去掉 `.git` 后缀、末尾 `/`）
2. 精确匹配
3. 去掉协议前缀（`https://`）后匹配
4. 含匹配（归一化后 url 是 pod git 的子串）

被 `repos_md_append_pods.sh` 和 `repos_json_append_pods.sh` 共用。



## 版本记录

### 0.1.0 (2026-05-12): 新增 Step 6 HTML 生成流程

### 0.0.1 (2026-05-12): 初始版本
