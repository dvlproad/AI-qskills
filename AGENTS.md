# AI-qskills — Agent 使用指南

## 仓库用途

这是一个 OpenCode 技能合集。每个目录就是一个技能，入口文件是 `SKILL.md`。

## 目录结构

- `.opencode/` — 插件打包相关（`INSTALL.md`、`package.json`，用 `@opencode-ai/plugin`）
- `organize-pod-to-md/scripts/` — 最复杂的脚本，分两步：
   1. `pods_fetch_to_md.sh` — 扫描 CocoaPods trunk + 私有 dvlproadSpecs → JSON/MD（通过 `--json`/`--md` 指定）
   2. `repos_append_pods.sh` — 把 pod 数据匹配到项目列表的 markdown 表格中

## 重要规则

- **所有实现决策和踩坑记录都放在 `README.md` 里**（`CLAUDE.md` 的要求）。如果 Agent 发现了 bug 或踩了坑，必须更新 README.md。
- **技能优化走 `skill-qian-optimize/SKILL.md`**，触发词："完善我的skill"。

## organize-pod-to-md 脚本注意事项

- `pods_fetch_to_md.sh` 需要代理（`https_proxy=http://127.0.0.1:7897`）才能访问 CocoaPods trunk API 和 Gitee API。
- `repos_append_pods.sh` 是用 heredoc 内嵌 Python3 的脚本，不依赖外部 Python 包，只用 `json`/`re`/`sys`。
- 表格分隔线正则：`r'^\|\s*-{3,}'` — 必须同时兼容 `|----`（无空格）和 `| ----`（有空格）两种格式。
- Pod 表是增量合并的：已有行顺序保留，新 pod 追加末尾，已移除的 pod 自动删除。
- 预处理器会先清除旧 Pod 表（识别 `Pod 情况：` 标记 + `| 仓库名 | 开发的Pod |` 表头），同时清除旧的 `## 未匹配的 Pod` 章节和旧的 `📋 子库详情` 表。
- 表头列名是 `可见性`（不是 `可见`）。
- Emoji 标记：`**📦 Pod 情况：**`
- 未匹配的 pod 追加到文件末尾，格式为 `## 未匹配的 Pod` 表格，列序同 `pod_all.md`。
- `pod_all.md` 列序：`Pod | Summary | Version | Git URL | Source | Visibility | Language`

## 常用命令

```bash
# 完整 pod 工作流（需要代理）
export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897
sh organize-pod-to-md/scripts/pods_fetch_to_md.sh --repos trunk,cocoapods,gitee-dvlproad-dvlproadspecs --json pods_all.json --md pods_all.md
sh organize-repos-to-md/scripts/repos_append_pods.sh --subspec-min-count <N> [--subspec-force-show PodA,PodB] [--separate-subspecs] <项目列表.md> <pod_json.json>
```

## 这个仓库没有的东西

- 没有构建系统、没有测试、没有 linter — 纯 bash/python/文档仓库
- 没有包管理器（只有插件包装层有 npm 依赖）
- 目标文件（`dvlproad项目列表.md`）在另一个仓库：`/Users/qian/Project/dvlproadHexo/`
