---
name: normalize-podspec-option2-project_list
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

### 1. 调用 pod-action 完成规范化

直接调用 [pod-action](../pod-action/SKILL.md) 处理，由它完成：
- podspec 规范化
- CocoaPods 同步到本地/远程
- 获取 & 更新 Pod 数据（pods_all.json）

进入 pod-action 后按正常流程走即可，完成后回到本 skill 继续。

### 2. 运行 repos_md_append_pods.sh ，同步到 项目列表.md

调用 `repos_md_append_pods.sh` 将 pods_all.json 的更新同步到项目列表 markdown 文档。

```bash
sh organize-repos-to-md/scripts/repos_md_append_pods.sh \
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

**用户确认**：展示执行日志和结果。
- `yes` / `y` → 继续下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 3. 运行 repos_json_append_pods.sh 重建 `repos_with_pods.json`。

```bash
sh organize-repos-to-md/scripts/repos_json_append_pods.sh \
  repos_all.json \
  pods_all.json \
  repos_with_pods.json
```

**用户确认**：展示执行结果。
- `yes` / `y` → 完成，告知用户全部流程结束
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 4. 可选：生成 HTML 版项目列表

根据 `dvlproad项目列表_PRD.md` 的设计规范，将 `repos_with_pods.json` 渲染为独立 HTML。

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

## 参考脚本

| 脚本 | 位置 | 用途 |
|------|------|------|
| `podspec_normalize.sh` | 本 skill 的 `scripts/` 下 | 给 podspec 的 subspec 加注释、更新 description |
| `public-pod-complete2-pods_json.py` | 本 skill 的 `scripts/` 下 | 从本地 podspec 解析数据并合并到 pods_all.json |
| `repos_md_append_pods.sh` | `organize-repos-to-md/scripts/` | 同步 pods_all.json → 项目列表 markdown |
| `repos_json_append_pods.sh` | `organize-repos-to-md/scripts/` | 重建 repos_with_pods.json |

## 版本记录

### 0.1.0 (2026-05-12): 新增 Step 6 HTML 生成流程

### 0.0.1 (2026-05-12): 初始版本
