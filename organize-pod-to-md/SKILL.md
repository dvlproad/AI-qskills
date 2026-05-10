---
name: organize-pod-to-md
description: 整理 CocoaPods 列表为 Markdown 文档，并匹配到项目列表 md 中
---

# organize-pod-to-md

当用户想要查看自己的 CocoaPods Pod 列表，或查看哪些仓库发布了对应的 Pod 时触发。

## 触发条件

- `整理pod` - 整理 CocoaPods Pod 列表
- `导出pod列表` - 导出为 Markdown 文档
- `列出所有pod` - 列出所有发布的 Pod
- `查看pod地址` - 查看所有 Pod 的 git 地址
- `匹配pod到仓库` - 将 Pod 匹配到仓库项目列表中
- 其他表达整理 CocoaPods 意图的指令

## 执行流程

### 1. 获取所有 Pod 数据

```bash
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos <repo1,repo2,...> [--json path] [--md path]
```

必传参数：
- `--repos` — 逗号分隔的 CocoaPods repo 目录名（trunk/cocoapods → 公有，其他 → 私有）

至少指定一个输出参数：
- `--json path` — 输出 JSON 路径（相对于当前工作目录）
- `--md path` — 输出 Markdown 路径（相对于当前工作目录）

例如：

```bash
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos trunk --json pods.json                 # 输出到当前目录
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos trunk --json ../output/pods.json       # 相对路径
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos trunk --json /tmp/pods.json            # 绝对路径（目录必须存在）
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos trunk,dvlproad --json data.json --md pods.md  # 同时输出 JSON 和 MD
```

生成文件：
- `pods.json` — 给脚本用的结构化数据
- `pods.md` — 给人看的表格

### 2. 将 Pod 匹配到项目列表

```bash
sh organize-pod-to-md/scripts/pod_match2_repos.sh [--subspec-min-count <N>] [--subspec-force-show PodA,PodB] [--separate-subspecs] <项目列表.md路径>
```

例如：

```bash
sh organize-pod-to-md/scripts/pod_match2_repos.sh --subspec-min-count 1 --separate-subspecs /path/to/dvlproad项目列表.md
```

参数说明：
- `--subspec-min-count <N>`（可选）— 子库数至少为 N 时展示详情，默认 2
- `--subspec-force-show PodA,PodB`（可选）— 强制展示这些 pod 的子库，默认 CJBaseHelper,CJBaseUtil,CJBaseUIKit
- `--separate-subspecs`（可选）— 每个 pod 独立子库表头

脚本会在每个有 Pod 匹配的 section 下追加 Pod 情况表格，主表完全不改。

### 匹配逻辑

- 按 **git URL** 匹配（去掉 `.git` 后缀比较）
- 同一仓库有多个子 pod 时，汇总到同一 Pod 表
- 无 pod 的 section 不追加任何内容

## 表格格式

### pods_all.md

```markdown
| Pod | Version | Git URL | Source | Visibility | Language |
```

### 项目列表中的 Pod 情况表

主表不变，每个有 pod 的 section 末尾追加：

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

## 脚本说明

### pods_fetch_to_md.sh

| 功能 | 说明 |
|------|------|
| 脚本路径 | `organize-pod-to-md/scripts/pods_fetch_to_md.sh` |
| 公有数据源 | `pod trunk me` + 本地 trunk/cocoapods repo 缓存 |
| 私有数据源 | 扫描 `gitee-dvlproad-dvlproadspecs` 的全部 `.podspec`（Ruby 格式，Python 正则解析） |
| 输出 | `--json` → JSON / `--md` → Markdown（至少指定一个） |
| 去重规则 | 同一 pod 在公有和私有都存在 → 标记为 CocoaPods / 公有 |
| 性能 | 公有约 60 个 pod，私有约 128 个 pod，合计约 2-3 分钟 |

### pod_match2_repos.sh

| 功能 | 说明 |
|------|------|
| 脚本路径 | `organize-pod-to-md/scripts/pod_match2_repos.sh` |
| 输入 1 | `pods_all.json`（pod 数据） |
| 输入 2 | 项目列表 md 文件（如 dvlproad项目列表.md） |
| 匹配方式 | 按 git URL 归一化后匹配 |
| 输出 | 在原始 md 中每个有 pod 的 section 后追加 Pod 情况表格（7 列） |

## 注意事项

1. **需要 CocoaPods 环境** — `pods_fetch_to_md.sh` 依赖 `pod` 命令
2. **需要 trunk 登录** — 必须 `pod trunk me` 能正常返回 pod 列表
3. **私有 repo 需要已 clone** — `gitee-dvlproad-dvlproadspecs` 必须在 `~/.cocoapods/repos/` 中存在
4. **避免网络超时** — `pod trunk me` 可能需要代理，可设置 `https_proxy=http://127.0.0.1:7897`
5. **匹配数据源** — 必须先运行 `pods_fetch_to_md.sh` 生成 JSON，再运行 `pod_match2_repos.sh`

## 版本记录

### 0.0.2 (2026-05-10): 新增私有 Pod 扫描、来源/可见/语言列
- `pods_fetch_to_md.sh`: 新增扫描 `dvlproadSpecs` 私有 repo 的 `.podspec` 文件
- JSON/MD 新增 `source`、`visibility`、`language` 三个字段
- Pod 情况表从 4 列扩展到 7 列
- 语言根据 `swift_version` 字段自动判断（Swift/OC）
- 公有/私有去重：优先公有

### 0.0.1 (2026-05-09): 初始版本
- `pods_fetch_to_md.sh`: 获取所有 pod 数据，输出 md + json
- `pod_match2_repos.sh`: 将 pod 按 git URL 匹配到项目列表，在每个有 pod 的 section 后追加 Pod 情况表格，主表不改
