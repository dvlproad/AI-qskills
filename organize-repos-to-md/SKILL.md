---
name: organize-repos-to-md
description: 整理 GitHub 和 Gitee 仓库列表为分类 JSON，也可直接生成 Markdown 文档
---

# organize-repos-to-md

当用户想要整理自己的 GitHub 和 Gitee 仓库列表，并生成分类文档时触发。

## 触发条件

- `整理仓库` - 整理 GitHub 和 Gitee 仓库
- `整理项目列表` - 整理项目列表
- `整理仓库列表` - 整理仓库列表
- `get repos` - 获取仓库列表
- 其他表达整理仓库意图的指令

## 执行流程

### 1、获取 Github 的所有 repos 

### 2、获取 Gitee 的所有 repos 

### 3、按分类体系归类repo → 输出 repos_all.json

从 GitHub/Gitee API 获取到的原始 JSON 数据（参见"一、获取 Github 的所有 repos"和"二、获取 Gitee 的所有 repos"），按"推荐分类体系"归类后输出 `repos_all.json`。

#### 3.1、repos_all.json 格式（含分类）

```json
[
    {
        "type": "UI控件",
        "children": [
            {
                "type": "基础UI",
                "children": [
                    {
                        "type": "CJUIKit",
                        "intro": "CJUIKit 是每个APP都肯定能用到的基础UI控件，该系列包含多个版本和关联项目",
                        "values": [
                            {
                                "repo_name": "CJUIKit",
                                "url": "https://github.com/dvlproad/CJUIKit",
                                "description": "每个APP都肯定能用到的基础UI控件",
                                "source": "GitHub",
                                "org": "dvlproad",
                                "visibility": "公有",
                                "language": "Objective-C",
                                "stars": 0
                            }
                        ]
                    }
                ]
            }
        ]
    }
]
```

字段说明：

| 字段          | 说明                          |
| ------------- | ----------------------------- |
| `type`        | 分类名，对应 markdown heading |
| `intro`       | 可选，分类下的引言文字        |
| `values`      | repo 数组                     |
| `children`    | 递归嵌套子分类                |
| `repo_name`   | 仓库显示名                    |
| `url`         | 仓库链接                      |
| `description` | 仓库描述                      |
| `source`      | GitHub / Gitee                |
| `org`         | 所属组织                      |
| `visibility`  | 公有 / 私有                   |
| `language`    | 编程语言                      |
| `stars`       | star 数                       |

#### 3.2、Github 中的某个 repo（原始 API 数据）

以 `001-UIKit-CQDemo-iOS` 为例：

```json
	{
    "id": 252917475,
    "name": "001-UIKit-CQDemo-iOS",
    "private": false,
    "html_url": "https://github.com/dvlproad/001-UIKit-CQDemo-iOS",
    "description": "a template demo",
    "org": "dvlproad"
  }
```

#### 3.3、Gitee 中的某个 repo（原始 API 数据）

以 `UIKit-EffectBaseUI-iOS` 为例，它的仓库名是 `name` 部分，链接是 `html_url`

```json
	{
    "id": 14196705,
    "path": "UIKit-EffectBaseUI-iOS",
    "name": "001-UIKit-EffectBaseUI-iOS",
    "description": "含效果的baseUI：数字滚动、跑马灯等",
    "private": true,
    "public": false,
    "html_url": "https://gitee.com/dvlproad/UIKit-EffectBaseUI-iOS.git"
  }
```

### 4、选择repos.json数据流的处理方向

repos_all.json 有了，接下来往哪走？详见 → 四、选择repos.json数据流的处理方向

## 一、获取 Github 的所有 repos

**详见 [github_repos_all.sh](./scripts/github_repos_all.sh) **

### 1. 获取 GitHub Token

- 优先使用环境变量 `GITHUB_TOKEN` 的值
- 如果没有，尝试使用 `gh auth token`
- 如果都没有，请求用户从 https://github.com/settings/tokens 获取 Token

```bash
# 查看本地 Token
gh auth token
```

### 2. 获取所有组织

获取Github用户dvlproad的所有组织

```shell
GITHUB_TOKEN=ghp_xxx
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/orgs" | \
  jq -r '.[] | "\(.login) | \(.description // "-")"'
```

### 3. GitHub 仓库

```bash
# 获取用户自己的仓库（公开）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=100&sort=updated" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'

# 获取用户自己的仓库（所有，包括私有）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=100&sort=updated&affiliation=owner" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'

# 获取组织仓库（需要是组织成员）
for org in org1 org2 org3; do
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$org/repos?per_page=100" | \
    jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'
done
```

## 二、获取 Gitee 的所有 repos 的方法

**详见 [gitee_repos_all.sh](./scripts/gitee_repos_all.sh) **

### 1. 获取 Gitee OAuth Token

Gitee 需要通过 OAuth 获取 Token：

#### 1.1 获取 Client ID 和 Client Secret

用户需要在 https://gitee.com/oauth/applications 创建一个 OAuth 应用：

- 应用名称：任意（如 opencode）
- 应用主页：任意（如 `https://example.com`）
- Redirect URI：`https://example.com/callback`
- 权限：需要 `projects` 和 `groups`

#### 1.2 生成授权链接

```bash
CLIENT_ID="你的Client_ID"
REDIRECT_URI="https://example.com/callback"
echo "请访问以下链接授权："
echo "https://gitee.com/oauth/authorize?client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&response_type=code&scope=projects+groups"
```

#### 1.3 获取 Access Token

用户授权后会跳转到 `https://example.com/callback?code=xxx`，提取 `code=` 后面的值：

```bash
curl -X POST "https://gitee.com/oauth/token" \
  -d "grant_type=authorization_code" \
  -d "code=刚才获取的code" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "redirect_uri=$REDIRECT_URI"
```

返回格式：

```json
{"access_token":"xxx","token_type":"bearer","expires_in":86400,"refresh_token":"xxx","scope":"user_info projects groups","created_at":xxx}
```

### 2. 获取所有组织

获取Gitee用户dvlproad的所有组织

```shell
curl -s https://gitee.com/api/v5/users/dvlproad/orgs | jq '.'
```

### 3. 获取仓库列表

```bash
# 获取用户自己的仓库
curl -s -H "Authorization: token $GITEE_TOKEN" \
  "https://gitee.com/api/v5/users/用户名/repos?per_page=100" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.description // "-")"'

# 获取组织仓库
for org in org1 org2 org3; do
  curl -s -H "Authorization: token $GITEE_TOKEN" \
    "https://gitee.com/api/v5/orgs/$org/repos?per_page=100" | \
    jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.description // "-")"'
done
```

## 三. 按分类体系归类repo → 输出 repos_all.json

### 1. 分类原则

#### 1.1 核心原则

1. **按用途分类**：按仓库的实际用途分类，而非按语言或平台分类
2. **唯一位置**：每个仓库只出现在一个最合适的位置，不要重复
3. **同级分类**：同一层级的分类应该是平行的概念

#### 1.2 子分类细分

同类仓库可再细分子分类：

- **基础/常见/其他**：如 App模块
- **视频/图片/图表/摄像头**：如 媒体相关

### 2. 推荐分类体系

```
AI
Book
模板Demo
初始化项目
学习/验证Demo
  设计模式
  数据算法
  项目优化
  卡顿收集
  响应式编程
  其他学习（线程、模块化）
UI控件
  基础UI
    CJUIKit
    BaseUIKit
    BaseVCKit
  弹窗UI（Popup、Overlay）
    Popup
    Overlay
  下拉刷新、上拉加载、空白页
  Image、TextInput
  List、Search
    列表相关
    图片添加删除列表
    搜索
  Picker控件
  Banner控件
  Segmented
  Guide
  Line
  CommonUI
  其他UI控件
网络请求
数据存储
路由
开发工具
  环境切换
  JS测试
特效
  手势
  动画效果 Animation、Effect
媒体相关
  图片
  视频
  摄像头
  图表
视图元素
数据万象
调试监视
埋点曝光
国际化
单元/自动化测试
App功能
  登录
  分享
  桌面组件、扫一扫、地图等
App模块
  基础
  常见
  Collect
  其他
App项目
  TotalDemo
  Demo
  Widget
  Card
  Car
推送通知
后台任务
组件仓库
跨平台框架
逆向破解
工具脚本 (CI/CD)
  基础
    其他
  打包相关
    分支信息
    打包
  commit信息
  安装包优化
  集成 ChatGPT 到 Discord
Web项目
API项目
其他文档仓库
组织汇总
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

## 五、SKILL 渲染

手动渲染两条管线中的 md 时，按以下规格输出：

### 5.1 Repo 表格格式

| 仓库名 | 描述 | 来源 | 组织 | 可见 | 语言 | Stars |
| ------ | ---- | ---- | ---- | ---- | ---- | ----- |

- **描述**放在第二列，方便阅读
- 来源：GitHub / Gitee
- 可见：公有 / 私有

### 5.2 文档模板

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

## 六、脚本渲染

### 6.1 repos_md_append_pods.sh（已有）

当前 md 中按主表追加 Pod 表，适合管线一的第二阶段：

```bash
# repos_md_append_pods.sh — 直接在 md 中按主表追加 Pod 表（面向生成）
sh repos_md_append_pods.sh [--subspec-min-count <N>] [--subspec-force-show PodA,PodB] [--separate-subspecs] <项目列表.md> [pod数据.json]
```

### 6.2 repos_json_append_pods.sh（已有）

合并 repos_all.json + pods_all.json → repos_with_pods.json，适合管线二的 JSON 中间数据生成：

```bash
# repos_json_append_pods.sh — 合并 repos_all.json + pods_all.json → repos_with_pods.json
# 每个 repo 节点追加 pods 字段，顶层含 unmatched_pods 列表
# 面向数据：输出 JSON 中间格式，可供后续渲染 md/html 等
sh repos_json_append_pods.sh <repos_all.json> <pods_all.json> [输出.json]
```

### 6.3 repos_with_pods_json_to_md.sh（待实现）

将 repos_with_pods.json 渲染为含 Pod 表 + 子库详情 + 未匹配 Pod 的完整 dvlproad项目列表.md。

遍历 `repos_with_pods.json` 的 `repos` 树，一次遍历完成所有输出：

- 按层级深度输出 heading → intro → repo 表格（格式见 §5）
- 如果有 `pods` 字段 → 追加 Pod 表（列序：仓库名│开发的Pod│描述│版本│来源│可见│语言）
- 子库数 ≥ N 或指定 → 追加子库详情
- 遍历结束 → 追加 `unmatched_pods` 为未匹配 Pod 表

### 6.4 repos_with_pods_json_to_html.sh（待实现）

将 repos_with_pods.json 渲染为 HTML。

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

### repos_all.json（供 organize-pod-to-md 消费）

```
/Users/qian/Project/dvlproadHexo/source/_posts/管理相关/项目列表/data/repos_all.json
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



## 注意事项

1. **GitHub Token 权限** - Token 需要有 `repo` 权限才能访问私有仓库
2. **Gitee Token 过期** - Gitee Token 默认 24 小时过期，需要刷新
3. **组织成员** - 需要是组织成员才能访问组织仓库
4. **Stars 为空** - Gitee API 不返回 stars，可留空

## 版本记录

### 0.0.4 (2026-05-11): 提取匹配公共库，新增 JSON 中间格式
- `repo_find_pod.py` — 从 `repos_md_append_pods.sh` 提取匹配逻辑为公共库
- `repos_json_append_pods.sh` — 新增 JSON 中间格式输出（面向数据），每个 repo 节点追加 `pods` 字段
- `repos_md_append_pods.sh` — 精简，改用 import `repo_find_pod`

### 0.0.3 (2026-05-10): 改为 JSON 输出
- 产出物从纯 Markdown 改为 JSON（`repos_all.json`），也可直接生成 Markdown
- 新增与 organize-pod-to-md 联动说明

### 0.0.2 (2026-04-26): 补充分类原则
- 添加分类原则：按用途分类、每个仓库只出现一次
- 添加推荐分类体系
- 调整表格列顺序：描述放在第二列

### 0.0.1 (2026-04-25): 初始版本
- 获取 GitHub 和 Gitee 仓库列表
- 按用途分类整理
- 生成 Markdown 文档