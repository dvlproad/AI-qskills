---
name: blog-catalog-update
version: 0.1.0
description: |
  更新博客总目录 — 扫描文件系统、合并评分、重新生成总目录.md
  触发场景：
  - 用户说"更新总目录"
  - 用户说"整理博客目录"
---

# 博客总目录更新

更新 Hexo 博客的总目录系统，包括扫描文章、合并评分、重新生成目录文件。

## 触发条件

- `"更新总目录"` — 全量更新总目录
- `"整理博客目录"` — 全量更新总目录

## 执行流程

### Step 1: 确定路径

检查当前工作目录，确定博客路径：

- 检测到 `source/_posts/总目录/` → 使用该路径
- 未检测到 → 询问用户博客路径

默认路径：
```
/Users/qian/Project/dvlproadHexo/source/_posts/
```

### Step 2: 扫描文件系统 → catalog.json

运行 `parse-catalog.js` 扫描 `source/_posts/` 下所有 Markdown 文件，读取 `总目录.md` 的链接顺序，生成 `catalog.json`。

```bash
node scripts/parse-catalog.js \
  --posts-dir <source/_posts路径> \
  --output <catalog.json输出路径>
```

示例：
```bash
node scripts/parse-catalog.js \
  --posts-dir /Users/qian/Project/dvlproadHexo/source/_posts \
  --output /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog.json
```

### Step 3: 合并评分数据（可选）

检测 `总目录/data/` 下是否存在 `rating_*.json` 文件：

- **存在** → 运行 `catalog_merge_ratings.sh` 合并评分
- **不存在** → 跳过此步

```bash
sh scripts/catalog_merge_ratings.sh \
  --catalog <catalog.json路径> \
  --output <catalog_with_ratings.json路径> \
  --json <rating文件1> <rating文件2> ...
```

示例：
```bash
sh scripts/catalog_merge_ratings.sh \
  --catalog /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog.json \
  --output /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog_with_ratings.json \
  --json /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/rating_iOS.json \
         /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/rating_Flutter.json
```

### Step 4: 备份 总目录.md

```bash
cp "$POSTS_DIR/总目录.md" "$POSTS_DIR/总目录.md.bak"
```

### Step 5: 重新生成 总目录.md

运行 `json-to-md.js` 重新生成 `总目录.md`。

- 有评分时 → 用 `catalog_with_ratings.json` 作为输入（评分分值会显示在 markdown 中）
- 无评分时 → 用 `catalog.json`

**注意：** 此步骤会完全覆盖 `总目录.md`。

```bash
# 有评分
node scripts/json-to-md.js \
  --input <catalog_with_ratings.json路径> \
  --output <总目录.md路径>

# 无评分
node scripts/json-to-md.js \
  --input <catalog.json路径> \
  --output <总目录.md路径>
```

示例：
```bash
node scripts/json-to-md.js \
  --input /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog_with_ratings.json \
  --output /Users/qian/Project/dvlproadHexo/source/_posts/总目录.md
```

### Step 6: 完成

输出更新结果：
- 扫描到的文章数
- 生成的分类数
- 合并的评分文件数（如有）

---

## 完整命令示例

```bash
# 博客路径
POSTS_DIR="/Users/qian/Project/dvlproadHexo/source/_posts"
CATALOG_DIR="$POSTS_DIR/总目录"
DATA_DIR="$CATALOG_DIR/data"

# Step 1: 扫描文件系统
node scripts/parse-catalog.js \
  --posts-dir "$POSTS_DIR" \
  --output "$DATA_DIR/catalog.json"

# Step 2: 合并评分（如有 rating_*.json）
RATING_FILES=("$DATA_DIR"/rating_*.json)
CATALOG_INPUT="$DATA_DIR/catalog.json"
if [ ${#RATING_FILES[@]} -gt 0 ] && [ -f "${RATING_FILES[0]}" ]; then
  sh scripts/catalog_merge_ratings.sh \
    --catalog "$DATA_DIR/catalog.json" \
    --output "$DATA_DIR/catalog_with_ratings.json" \
    --json "${RATING_FILES[@]}"
  CATALOG_INPUT="$DATA_DIR/catalog_with_ratings.json"
fi

# Step 3: 备份总目录.md
cp "$POSTS_DIR/总目录.md" "$POSTS_DIR/总目录.md.bak"

# Step 4: 重新生成总目录.md
node scripts/json-to-md.js \
  --input "$CATALOG_INPUT" \
  --output "$POSTS_DIR/总目录.md"
```

---

## 脚本说明

### parse-catalog.js

扫描 `source/_posts/` 下所有 `.md` 文件，读取 `总目录.md` 中的链接顺序，生成结构化的 `catalog.json`。

**参数：**
- `--posts-dir` — `source/_posts` 目录路径（必需）
- `--output` — `catalog.json` 输出路径（必需）
- `--catalog-md` — `总目录.md` 路径（可选，默认为 `posts-dir/总目录.md`）

**输出：**
```json
{
  "catalog": [
    {
      "type": "分类名",
      "children": [
        { "title": "文章标题", "url": "分类/文章名", "secNum": "1", "date": "..." }
      ]
    }
  ]
}
```

### json-to-md.js

将 `catalog.json` 渲染为 `总目录.md`，支持自动编号、虚拟分组、hideFromWeb 标记等。

**参数：**
- `--input` — `catalog.json` 输入路径（必需）
- `--output` — `总目录.md` 输出路径（必需，或使用 `--stdout`）
- `--stdout` — 输出到控制台而不是文件
- `--remove-secNum-at-first true` — 清空所有 secNum 后全走自动编号（用于验证）

**特殊处理：显示名映射**

目录名与显示名不一致时，在 `json-to-md.js` 的 `DISPLAY_NAME` 中添加映射：

```js
const DISPLAY_NAME = {
  '工具实用': '实用工具',
  '工具开发': '开发工具',
  '工具编程': '编程工具',
};
```

> 来源：`AI-qskills/命名规范.md` 第256行，「目录名（存储）」与「分类名（阅读）」分离。

### catalog_merge_ratings.sh

将 `rating_*.json` 合并到 `catalog.json`，输出 `catalog_with_ratings.json`。

**参数：**
- `--catalog` — `catalog.json` 输入路径（必需）
- `--output` — `catalog_with_ratings.json` 输出路径（必需）
- `--json` — 评分文件路径（可多个，空格分隔）

**依赖：** jq

---

## 数据流

```
source/_posts/*.md  ─┐
                     ├─→  parse-catalog.js  ─→  catalog.json
总目录.md  ──────────┘                              │
                                                    ↓
                                            catalog_merge_ratings.sh (可选)
                                                    │
                                                    ↓
                                            catalog_with_ratings.json
                                                    │
                                                    ↓
                                              json-to-md.js
                                                    │
                                                    ↓
                                              总目录.md (覆盖)
```

---

## 注意事项

- **直接执行**：此 skill 不需要反复确认，直接执行全流程
- **评分合并可选**：如果没有 `rating_*.json` 文件，跳过 Step 3
- **输出路径**：脚本会自动创建输出目录
- **备份提醒**：`总目录.md` 会被完全覆盖，如有手动编辑需提前备份
- **依赖**：`catalog_merge_ratings.sh` 需要 `jq`，其他脚本无外部依赖

---

## 版本记录

### 0.1.1 (2026-07-28): 修复 + 工作流优化
- 修复 `catalog_merge_ratings.sh` 对无 title 文章的 jq 报错（`Cannot index object with null`）
- `parse-catalog.js` 自动为缺 title 的文章添加默认 title（`⚠️ 缺少title: xxx`）
- `json-to-md.js` 新增 `DISPLAY_NAME` 映射（工具实用→实用工具、工具开发→开发工具、工具编程→编程工具）
- Step 4 新增备份步骤，Step 5 优先使用 `catalog_with_ratings.json`

### 0.1.0 (2026-07-28): 初始版本
- 支持全量更新总目录
- 参数化脚本调用
- 支持评分数据合并
