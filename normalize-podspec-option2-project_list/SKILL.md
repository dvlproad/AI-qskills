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

每个步骤都需要用户确认后才能继续。流程分叉如下：

```
Step 0: 确认库信息（公有/私有）
         │
         ▼
Step 1: podspec_normalize.sh（公有/私有都做）
         │
         ├── 私有库 → 结束（后续由 pods_fetch_to_md.sh 批量提取）
         │
         └── 公有库 + yes → Step 2-5（同步到项目列表）
```

### 0. 确认用户要完善的库

询问用户以下信息：

- **本地项目目录**（如 `/Users/qian/Project/Github/CJRadio`）
  - 目录下必须存在 `.podspec` 文件
  - 确认后用于 Step 1 的 `podspec_normalize.sh --project-dir`
- **公有/私有** — 判断该 pod 是公有（CocoaPods trunk）还是私有
  - 公有库：后续可选择同步到项目列表
  - 私有库：规范化完成后即结束（后续由 `pods_fetch_to_md.sh` 从私有 spec repo 批量提取）
- **Pod 名称**（仅公有库需要，用于 Step 2 寻找 trunk 仓库路径）

用户确认路径和类型无误后进入 Step 1。

### 1. 运行 podspec_normalize.sh

在当前会话中使用以下命令：

```bash
sh ../pod-action/scripts/podspec_normalize.sh \
  --project-dir <用户提供的项目目录>
```

**用户确认**：展示 podspec 的变更内容（新增的注释、更新的 description），然后根据库类型分叉：

**私有库**：
- `yes` / `y` → 结束（规范化完成，后续由 `pods_fetch_to_md.sh` 批量提取到项目列表）
- `no` / `n` → 结束
- `quit` / `q` → 退出
- 其他 → 提示重新输入

**公有库**：
- `yes` / `y` → 继续同步到项目列表（进入 Step 2-5）
- `no` / `n` → 结束（规范化完成，不同步到项目列表）
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 2. 询问是否同步到 CocoaPods trunk（仅公有库）

> **背景说明**：`pods_fetch_to_md.sh` 是从 `~/.cocoapods/repos/` 下的 trunk 仓库中读取 pod 数据，
> **不是**从 GitHub 上的单个项目目录读取。如果你只改了本地的 podspec 但 trunk 仓库还是旧版，
> 后续运行 `pods_fetch_to_md.sh` 时旧数据会重新写回 `pods_all.json`，本地修改就白做了。

询问用户是否将本地修改后的 podspec 通过覆盖方式临时更新到 CocoaPods trunk（即不发布，直接替换本地缓存）：

注意：只有你确认podsepc完全没问题，即没有新增未发布的子pod，只是修改注释的情况下，才建议选择**是**。其他一律建议否，即不覆盖 trunk 仓库。

- **是** → 
  
  1. 找到 trunk 中该 pod 最高版本路径（如 ~/.cocoapods/repos/trunk/Specs/.../CJRadio/1.4.0/CJRadio.podspec.json）

  2. 展示路径，二次询问用户是否真的要进行覆盖。
  
  3. 如果选择真的要覆盖：则
  
     3.1 将本地的 `.podspec` 通过 `pod ipc spec` 转为 `.podspec.json`
  
     3.2 用 `.podspec.json` 内容覆盖 trunk 仓库中的 .podspec.json 文件
  
     3.3 覆盖完成后，提示用户后续运行 `pods_fetch_to_md.sh` 时，得到的 `pods_all.json`，就会是和本地一样的了。
  
  4. 如果选择不是的覆盖：则走本地模式：用 Step 3 从本地 podspec 读取数据更新 `pods_all.json`。
  
- **否** → 走本地模式：用 Step 3 从本地 podspec 读取数据更新 `pods_all.json`。

**用户确认**：
- `yes` / `y` → 继续下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 3. 运行 public-pod-complete2-pods_json.py

从本地 podspec 文件解析数据，合并到 `pods_all.json`。

```bash
python3 ../pod-action/scripts/public-pod-complete2-pods_json.py \
  <本地 podspec 路径> \
  <pods_all.json路径>
```

**用户确认**：展示 pods_all.json 中该 pod 条目的变化（新增或更新的字段）。
- `yes` / `y` → 继续下一步
- `quit` / `q` → 退出
- 其他 → 提示重新输入

### 4. 运行 repos_md_append_pods.sh

将 pods_all.json 的更新同步到项目列表 markdown 文档。

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

### 5. 运行 repos_json_append_pods.sh

重建 `repos_with_pods.json`。

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

### 6. 可选：生成 HTML 版项目列表

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
        ├── repos_with_pods.json   ← 数据源（Step 5 生成）
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
