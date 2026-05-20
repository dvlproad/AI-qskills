---
name: html-table-hierarchy
description: |
  N 级层级数据表格展示方案 — Level 1 → Level 2 → Level 3 嵌套可展开表格。
  包括列序设计（名称后紧跟展开列）、toggle 位置（数字+符号）、整行可点展开、层级缩进、动画等。
  触发场景：用户提到"嵌套表格"、"可展开表格"、"层级数据展示"、"树形表格"、"多级展开"
---

# HTML 层级数据表格展示方案

## 适用场景

需要在 HTML 表格中展示多级嵌套数据，支持展开/收起，且要求：

- 视觉层级清晰（逐级缩进）
- 名称列和展开控制相邻
- 无子项时不显示展开图标
- 整行可点击展开

本方案以 **dvlproad 项目列表**（仓库 → Pod → Subspec）为示例数据，但所有设计规则和代码模板均通用。

## 设计前提：响应式约束

层级表格列数多（5–7+ 列），窄屏时必然溢出。套用本方案前必须同时规划响应式策略，否则大屏 OK、小屏体验崩塌。

**四点约束：**

1. **布局用 `rem` 而非 `px`** — 通过 `--font-base` + `@media` 断点实现全局缩放。改一处根字体，所有 `rem` 间距/字体联动
2. **`table-layout: fixed`** — 强制表不超过容器宽度，列宽按比例分配。这是防溢出的唯一 CSS 方案，其他方式（`max-width`、`overflow`）都不可靠
3. **长内容列预设截断** — 如描述列需预设：大屏换行全显示，小屏 `ellipsis` 截断 + `title` 悬浮查看
4. **侧栏与主内容联动** — 窄屏时侧栏逐级缩窄或隐藏，主内容边距同步

> 详细实现见本章末尾「响应式适配」一节。

## 设计规则

### 1. 列序 — 名称列后紧跟展开列

展开控制紧挨名称，用户看到名称后最快判断是否有子项可展开：

```
L1 表: 名称 | L2展开列 | 数据列 | 数据列 | ...
L2 表: 名称 | L3展开列 | 数据列 | 数据列 | ...
```

具体列数按项目实际字段定，但展开列始终位于第二列。

### 2. 符号位置 — 数字在前，符号在后

```
2 ▼    ✓    ("有 2 个子项，可展开")
▼ 2    ✗    (符号在前，先看到展开才看到数量)
9 ▶    ✓
```

### 3. 展开控制 — 整行可点（除链接外）

- **L1 表**：名称列通常是链接（跳转），其他列加 `toggle-cell` + `onclick`
- **L2 表**：`<tr onclick>` 整行可点，展开列加 `toggle-cell` 标识

CSS：
```css
.toggle-cell { cursor: pointer; }
.toggle-cell:hover { background: #e2e8f0; }
```

### 4. 无子项 — 不显示符号，只显示 `-`

有子项 → `2 ▼`（可展开）
无子项 → `-`（不可展开）

### 5. 层级缩进 — 逐级嵌套

```
L1 名
  └─ L2 表（展开后通过 colspan 跨列，内嵌子表）
       └─ L3 表（padding-left: 32px）
```

L3 及以上层级在渲染时包裹一层 `<div style="padding-left:32px">`：

```javascript
function renderLevel3Table(items, prefix) {
  let html = '<div style="padding-left:32px"><table>...';
  // ...
  html += '</table></div>';
  return html;
}
```

### 6. 动画 — 入场 + 展开/收起

CSS：
```css
@keyframes row-fade-in {
  from { opacity: 0; transform: translateY(4px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes fade-in-down {
  from { opacity: 0; transform: translateY(-3px); }
  to   { opacity: 1; transform: translateY(0); }
}
.l1-row { animation: row-fade-in .3s ease both; }
.l2-row { animation: row-fade-in .3s ease both; }
.l2-expand-row.animating   { animation: fade-in-down .2s ease; }
.l3-expand-row.animating   { animation: fade-in-down .2s ease; }
```

入场错开（stagger）：
```javascript
// L1 行：30ms 间隔
html += `<tr class="l1-row" style="animation-delay:${idx * 30}ms">`;

// L2 行：20ms 间隔
html += `<tr class="l2-row" style="animation-delay:${pidx * 20}ms">`;
```

展开时强制重播动画：
```javascript
function toggleRow(id, iconId) {
  const el = document.getElementById(id);
  const icon = document.getElementById(iconId);
  if (!el) return;
  el.classList.remove('animating');
  if (el.classList.contains('hidden')) {
    el.classList.remove('hidden');
    void el.offsetHeight;          // 强制重排，触发动画重播
    el.classList.add('animating');
    if (icon) icon.textContent = '▼';
  } else {
    el.classList.add('hidden');
    if (icon) icon.textContent = '▶';
  }
}
```

### 7. Typography 层级 — 字体权重递减

视觉重量随层级递减，让用户快速聚焦一级内容：

```
L1 (Repo)     font-weight: 500    ← 最重，主层级
L2 (Pod)      font-weight: 400    ← 中等
L3+ (Subspec) font-weight: 300    ← 默认 td，缩进协助区分
```

CSS：
```css
.l1-row td { font-weight: 500; }
.l2-row td { font-weight: 400; }
/* L3+ 无特殊规则，继承 td { font-weight: 300 } */
```

设计理由：
- 层数越深权重越轻，符合阅读直觉
- 二级（L2）与一级（L1）差 100，足够肉眼区分
- L3+ 用 300（最轻），层级靠缩进，不需要额外权重

### 8. 层级颜色系统 — 表头 + Hover

表头统一带色（标识层级），行级 hover 时高亮。色相随层级变化：**紫 → 蓝 → 青绿**

```
              表头             Hover
L1 (Repo)     rgba(83,58,253,0.30)  rgba(83,58,253,0.50)  品牌紫
L2 (Pod)      rgba(6,95,212,0.25)   rgba(6,95,212,0.35)   蓝色
L3 (Subspec)  rgba(13,148,136,0.10) rgba(13,148,136,0.22) 青绿
```

CSS：
```css
/* 表头颜色 */
.l1-table thead { background: rgba(83,58,253, 0.30); }
.l2-table th { background: rgba(6,95,212, 0.25); }
.l2-table thead { background: transparent; }   /* 避免 #f8fafc 底色调和 */
.l3-expand-row th { background: rgba(13,148,136, 0.10); }
.l3-expand-row table thead { background: transparent; }  /* 同上 */

/* L3 行基线（始终显示） */
.l3-expand-row table tbody td {
  background: rgba(13,148,136, 0.10);
}

/* L3 行基线（始终显示） */
.l3-expand-row table tbody td {
  background: rgba(13,148,136, 0.10);
}

/* Hover 高亮 */
.l1-row:hover td { background: rgba(83,58,253, 0.50); }
.l2-row:hover td { background: rgba(6,95,212, 0.35); }
.l3-expand-row table tbody tr:hover td {
  background: rgba(13,148,136, 0.22);
}
```

设计理由：
- 用色相区分比单纯透明度变化更直观
- 紫→蓝→青绿，冷色系同色温顺滑过渡，每级色相不同但调性统一
- 表头带色不随 hover 变化，稳定标识层级身份
- L1/L2 行 hover 才亮，L3 因行密集始终亮基线色辅助阅读

### 9. 分类级 Pod / Subspec 三档分段控制（局部刷新）

子分类头部使用**三档分段控件**代替独立开关，三个档位对应三种详细程度：**repo** → **+Pod** → **+Subspec**。档位颜色跟随层级色系（紫 → 蓝 → 青绿）。点击后**只重建该子分类的 DOM**，不影响其他分类。

级别通过 `catDetailLevel` 对象存储，子分类继承父分类级别（`Math.min(selfLevel, parentLevel)`），确保子项不会比父项显示更细。

**优先级规则**：分类级 seg 控件 > 全局 toolbar。如果一个分类显式设置了 seg 档位，则全局 toolbar 的 viewMode 被**忽略**（该分类按 seg 档位渲染）。未设置 seg 的分类则回退到全局 viewMode 作为默认值。

```javascript
// 全局 viewMode → 级别映射
function viewModeToLevel(mode) {
  return mode === 'repo' ? 1 : mode === 'pod' ? 2 : 3;
}
// 使用：未设 seg 的分类回退到全局默认
const level = catDetailLevel[item.type] ?? viewModeToLevel(viewMode);
```

CSS：
```css
.level-seg {
  display: inline-flex; overflow: hidden;
  border-radius: 4px; border: 1px solid var(--border);
}
.level-seg .seg {
  font-size: 11px; padding: 2px 8px; cursor: pointer;
  user-select: none; transition: all .1s;
  border-right: 1px solid var(--border);
  background: transparent; color: var(--text-secondary); line-height: 1.8;
}
.level-seg .seg:last-child { border-right: none; }
.level-seg .seg:hover { background: var(--hover-bg); }
.level-seg .seg.f1 { background: rgba(83,58,253,0.12); color: var(--accent); font-weight: 500; }
.level-seg .seg.f2 { background: rgba(6,95,212,0.12); color: #1a56db; font-weight: 500; }
.level-seg .seg.f3 { background: rgba(13,148,136,0.12); color: #0d5e56; font-weight: 500; }
```

注意：`.intro`（注释行）需要换行到标题下方，避免 seg 被挤到第二行：
```css
.subcategory-header { flex-wrap: wrap; }
.subcategory-header .intro { flex: 0 0 100%; order: 10; margin-top: 2px; }
```

JS 状态和更新：
```javascript
let catDetailLevel = {};

function setCatLevel(type, level) {
  catDetailLevel[type] = level;
  updateCat(type);
}

function updateCat(type) {
  const item = findItemByType(appData.repos, type);
  if (!item) return;
  const q = document.getElementById('search').value.trim().toLowerCase();
  const html = renderSubCategory(item, q, 0);
  const el = document.getElementById('cat-' + encodeURIComponent(type));
  if (el && html) el.outerHTML = html;
}

function findItemByType(items, type) {
  for (const item of items) {
    if (item.type === type) return item;
    if (item.children) {
      const found = findItemByType(item.children, type);
      if (found) return found;
    }
  }
  return null;
}
```

渲染时，在 `renderCategory`（顶级分类）和 `renderSubCategory`（子分类）的 header 尾部添加分段控件，所有含有 pods 的分类都会渲染（不限深度）：

```javascript
// 在 renderCategory / renderSubCategory 中
const level = catDetailLevel[item.type] ?? viewModeToLevel(viewMode);
// ...
const hasPods = filtered.some(r => r.pods && r.pods.length > 0);
if (hasPods) {
  const labels = ['repo', '+Pod', '+Subspec'];
  let segHtml = '<span class="level-seg">';
  for (let i = 0; i < 3; i++) {
    const filled = level >= i + 1;
    segHtml += `<span class="seg${filled ? ' f' + (i + 1) : ''}"
      onclick="setCatLevel('${escapeHtml(item.type)}', ${i + 1})">${labels[i]}</span>`;
  }
  segHtml += '</span>';
  html += segHtml;
}
```

级别传递链：`renderCategory`（读取 `catDetailLevel`）→ `renderRepoTable(q, hidePod, hideSubspec)` → `renderPodCompactTable(q, hideSubspec)`。Pod 控制在 `renderRepoTable` 中生效（`showPods = hasPods && viewMode !== 'repo' && !hidePod`），Subspec 控制在 `renderPodCompactTable` 中生效。

子分类通过 `parentLevel` 参数继承父级级别（未显式设置 seg 时）：
```javascript
// 父分类设置 seg，子分类继承（或独立设置）
function renderSubCategory(item, q, depth = 0, parentLevel) {
  // fallback 链：自身 seg > 父级 seg > 全局 toolbar
  const level = catDetailLevel[item.type] ?? parentLevel ?? viewModeToLevel(viewMode);
  // ...
  // 传递给子级
  for (const c of item.children) {
    renderSubCategory(c, q, depth + 1, level);
  }
}
```

三档效果：
| 档位 | catDetailLevel | hidePod | hideSubspec | 显示内容 |
|------|---------------|---------|-------------|---------|
| repo | 1 | true | true | 仅仓库列表 |
| +Pod | 2 (跟随全局) | false | true | 仓库 + Pod |
| +Subspec | 3 | false | false | 全部 |

设计理由：
- 三档分段比两个独立开关更紧凑，占据更少空间
- 档位间互斥，避免「隐藏 Pod 但显示 Subspec」的非法状态
- 颜色跟随层级色系（紫→蓝→青绿），档位越深颜色越深
- **优先级链**：此处实现的是抽象 `priority-chain` skill 的具体实例，模型为 `自身 > 父级 > 全局` 三层。显示时高优先覆盖低优先；修改低优先时自动清除高优先。详见 [`priority-chain`](../priority-chain/SKILL.md)
- 该 Segmented Control UI 模式是通用 priority-chain 的具象化表达，各档位对应优先级层索引，填充规则遵循累进亮起原则
- 局部 DOM 替换避免全量重渲染

## 代码模板

以下模板使用通用命名，替换注释标记 `/*...*/` 处的字段名和列名即可适配任意项目。

### CSS 片段

```css
.toggle-icon {
  display: inline-block;
  width: 18px;
  text-align: center;
  font-size: 10px;
  color: var(--text-secondary);
  user-select: none;
}
.toggle-cell { cursor: pointer; }
.toggle-cell:hover { background: #e2e8f0; }

.l2-row { cursor: pointer; }
.l2-row:hover { background: #e2e8f0; }

.l1-row { animation: row-fade-in .3s ease both; }
.l2-row { animation: row-fade-in .3s ease both; }

.l2-expand-row.animating   { animation: fade-in-down .2s ease; }
.l3-expand-row.animating   { animation: fade-in-down .2s ease; }
```

### L1 表渲染

```javascript
function renderL1Table(items) {
  let html = '<table><thead><tr><th>/* 名称 */</th><th>/* L2展开列标题 */</th><th>/* 其他列... */</th></tr></thead><tbody>';
  for (const item of items) {
    const l2Id = 'l2-' + Math.random().toString(36).slice(2, 7);
    const hasL2 = item.children && item.children.length > 0;   /* children = L2 子项数组 */
    const showL2 = hasL2 && viewMode !== 'l1-only';
    html += `<tr class="l1-row" style="animation-delay:${idx * 30}ms">`;
    html += `<td>${renderLink(item)}</td>`;   /* 名称列 = 链接（跳转不展开） */
    html += `<td${showL2 ? ' class="toggle-cell" onclick="toggleL2(\'' + l2Id + '\')"' : ''}>${showL2 ? item.children.length + ' <span class="toggle-icon" id="icon-' + l2Id + '">▼</span>' : '-'}</td>`;
    /* 后续数据列按需渲染，L2 可展开时加 toggle-cell + onclick */
    html += `<td class="${showL2 ? 'toggle-cell' : ''}"${showL2 ? ` onclick="toggleL2('${l2Id}')"` : ''}>${escapeHtml(item.field1 || '-')}</td>`;
    html += `<td${showL2 ? ' class="toggle-cell"' : ''}${showL2 ? ` onclick="toggleL2('${l2Id}')"` : ''}>${escapeHtml(item.field2 || '-')}</td>`;
    html += `</tr>`;
    if (showL2) {
      html += `<tr class="l2-expand-row" id="${l2Id}"><td colspan="/* 总列数 */" style="padding:0;">`;
      html += renderL2Table(item.children);
      html += `</td></tr>`;
    }
  }
  html += '</tbody></table>';
  return html;
}
```

### L2 表渲染

```javascript
function renderL2Table(items) {
  let html = '<table><thead><tr><th>/* 名称 */</th><th>/* L3展开列标题 */</th><th>/* 其他列... */</th></tr></thead><tbody>';
  for (const item of items) {
    const l3Id = 'l3-' + Math.random().toString(36).slice(2, 7);
    const hasL3 = item.grandchildren && item.grandchildren.length > 0;   /* grandchildren = L3 子项数组 */
    html += `<tr class="l2-row" style="animation-delay:${pidx * 20}ms"${hasL3 ? ` onclick="toggleL3('${l3Id}')"` : ''}>`;
    html += `<td>${escapeHtml(item.name)}</td>`;
    html += `<td${hasL3 ? ' class="toggle-cell"' : ''}>${hasL3 ? item.grandchildren.length + ' <span class="toggle-icon" id="icon-' + l3Id + '">▶</span>' : '-'}</td>`;
    /* 后续数据列按需渲染 */
    html += `<td class="desc">${escapeHtml(item.summary || '-')}</td>`;
    html += `<td>${escapeHtml(item.version || '-')}</td>`;
    html += `</tr>`;
    if (hasL3) {
      html += `<tr class="l3-expand-row hidden" id="${l3Id}"><td colspan="/* 总列数 */" style="padding:0;">`;
      html += renderL3Table(item.grandchildren, item.name);
      html += `</td></tr>`;
    }
  }
  html += '</tbody></table>';
  return html;
}
```

### L3 及以上表渲染（缩进）

```javascript
function renderL3Table(items, prefix) {
  let html = '<div style="padding-left:32px"><table><thead><tr><th>名称</th><th>Summary</th></tr></thead><tbody>';
  for (const item of items) {
    const name = prefix ? prefix + '/' + item.name : item.name;
    html += `<tr><td>${escapeHtml(name)}</td><td>${escapeHtml(item.summary || '')}</td></tr>`;
    if (item.grandchildren && item.grandchildren.length > 0) {
      html += renderL3Rows(item.grandchildren, name);
    }
  }
  html += '</tbody></table></div>';
  return html;
}
```

### 展开/收起控制

```javascript
function toggleL2(id) {
  toggleRow(id, 'icon-' + id);
}
function toggleL3(id) {
  toggleRow(id, 'icon-' + id);
}
function toggleRow(id, iconId) {
  const el = document.getElementById(id);
  const icon = document.getElementById(iconId);
  if (!el) return;
  el.classList.remove('animating');
  if (el.classList.contains('hidden')) {
    el.classList.remove('hidden');
    void el.offsetHeight;
    el.classList.add('animating');
    if (icon) icon.textContent = '▼';
  } else {
    el.classList.add('hidden');
    if (icon) icon.textContent = '▶';
  }
}
```

## 项目映射示例

以下展示 dvlproad 项目列表如何套用上述通用模板：

| 通用 | dvlproad 项目列表 |
|------|------------------|
| L1 = 仓库 (Repo) | 数据字段：`repo_name`, `description`, `source`, `visibility`, `language`, `stars` |
| L2 = Pod | 数据字段：`pod`, `summary`, `version`, `source`, `visibility`, `language` |
| L3 = Subspec | 数据字段：`name`, `summary` |
| `item.children` | `repo.pods` |
| `item.grandchildren` | `pod.subspecs` |
| L1 表列序 | `仓库名 \| Pod \| 描述 \| 来源 \| 可见 \| 语言 \| Stars` |
| L2 表列序 | `Pod \| 子库 \| 描述 \| 版本 \| 来源 \| 可见 \| 语言` |
| L3 表列序 | `Subspec \| Summary` |
| L1 总列数 | 7 |
| L2 总列数 | 7 |
| 整行可点 | L1 除仓库名外、L2 整行 |
| L3 缩进 | `padding-left: 32px` |

## 常见问题

### Q: 为什么展开列紧跟名称列？
用户看到名称后，最自然的下一步是查看详情或展开子项。展开列放在第二列，视觉路径最短。

### Q: 为什么数字在前、符号在后？
先看到数量（"有 2 个子项"），再看到符号（"可以展开"）。阅读顺序更自然。

### Q: 为什么不用占位符保持对齐？
无子项的行直接显示 `-`，不显示不可见图标。因为不可见的占位符会让用户困惑（"那里是不是有个 Bug？"）。

### Q: 为什么整行可点？
点击目标区域更大，操作更顺畅。只有链接例外（名称是链接时点链接跳转，不展开）。

### Q: colspan 怎么确定？
总列数由当前表的表头列数决定。展开行用 `<td colspan="N">`，N 为表头列数。

## 优先级链实例：dvlproad 分类 seg 控件

此处是通用 [`priority-chain`](../priority-chain/SKILL.md) skill 在 dvlproad 项目列表中的具体实现。三层叠配置：**全局 toolbar（层 0）→父分类 seg（层 1）→自身 seg（层 2）**。

### 层级定义

| 层 | 索引 | 名称 | 存储对象 | 修改触发 |
|----|------|------|---------|---------|
| global | 0 | 全局视图模式 | `viewMode`（单值） | 页面顶部 toolbar 切换 |
| parent | 1 | 父分类级别 | `catDetailLevel[parentType]` | 父分类 seg 控件设置 |
| self | 2 | 自身分类级别 | `catDetailLevel[selfType]` | 自身 seg 控件设置 |

### 数据结构

不用嵌套 layers 数组，层通过不同存储对象区分：

```javascript
const globalLevel = { value: 2 };  // viewMode 映射后的级别
const catDetailLevel = {};         // 同时存 parent 和 self 层
```

读 fallback 通过 `??` 实现：

```javascript
const level = catDetailLevel[selfType] ?? catDetailLevel[parentType] ?? viewModeToLevel(viewMode);
//          高优先          ↑              中等优先       ↑              低优先        ↑
```

写清除通过 `clearDescendantLevels` 实现：

```javascript
// 写 layer 1（父分类）
function setCatLevel(type, level) {
  catDetailLevel[type] = level;
  const item = findItemByType(appData.repos, type);
  if (item) clearDescendantLevels(item);
  updateCat(type);
}
function clearDescendantLevels(item) {
  if (!item.children) return;
  for (const c of item.children) {
    delete catDetailLevel[c.type];
    clearDescendantLevels(c);
  }
}

// 写 layer 0（全局）
function setViewMode(mode) {
  viewMode = mode;
  catDetailLevel = {};
  render();
}
```

### 行为追踪

以"基础UI（父分类）→ CJUIKit（子分类）"为例：

| 操作 | layer 0 (global) | layer 1 (基础UI) | layer 2 (CJUIKit) | 显示结果 |
|------|-----------------|-----------------|------------------|---------|
| 初始 | `value=2` | `{}` | `{}` | level = `undefined ?? undefined ?? 2` = **2** |
| CJUIKit → +Subspec | `value=2` | `{}` | `{CJUIKit:3}` | level = `3 ?? undefined ?? 2` = **3** |
| 基础UI → +Pod | `value=2` | `{基础UI:2}` | CJUIKit 被 delete | level = `undefined ?? 2 ?? 2` = **2** |
| CJUIKit → +Subspec | `value=2` | `{基础UI:2}` | `{CJUIKit:3}` | level = `3 ?? 2 ?? 2` = **3** |
| 全局 → repo | `value=1` | 全部清空 | 全部清空 | level = `undefined ?? undefined ?? 1` = **1** |

> **联动 N层规则**：以上 priority chain 跟踪的是档位级别的读写清除。在此之上，手动展开/收起状态遵循 N层嵌套规则的加减档规则：减档时被减掉层级的展开状态全部丢弃，加档回本层时恢复默认。完整规范见 priority-chain 中的 [N层嵌套表格层级展开规则说明（完整版）](../priority-chain/SKILL.md#n层嵌套表格层级展开规则说明完整版)。

### 10. Seg 级别不锁定手动交互

**核心规则**：渲染始终生成所有下级 DOM，seg 级别只控制初始 `hidden`，不阻断手动点击展开。适用于每一级。

**通用代码模式**：

```javascript
const hasChildren = data.children && data.children.length > 0;
const childHidden = segLevel < childMinLevel;  // seg 不够就默认隐藏

// 展开列：有下级就显示数字+图标，图标初始方向由 childHidden 决定
html += `<td class="toggle-cell" onclick="toggleChild('${id}')">${hasChildren ? data.children.length + ' <span class="toggle-icon" id="icon-' + id + '">' + (childHidden ? '▶' : '▼') + '</span>' : '-'}</td>`;

// 下级行：始终渲染，seg 控制 hidden 类
if (hasChildren) {
  html += `<tr class="${childHidden ? 'hidden' : ''}" id="${id}">${renderTable(data.children)}</tr>`;
}
```

#### Repo → Pod

| 场景 | Pod 列显示 | Pod 行 DOM | 可点击展开 |
|------|-----------|-----------|-----------|
| 有 pod，seg ≥ +Pod | `3 ▼` | 存在，`hidden` 为 false | ✅ |
| 有 pod，seg = repo | `3 ▶` | 存在，`hidden` 为 true | ✅ |
| 无 pod | `-` | 无 | — |

```javascript
const hasPods = r.pods && r.pods.length > 0;
const showPods = hasPods && !hidePod;          // seg 是否 >= +Pod
const podInitIcon = hidePod ? '▶' : '▼';       // seg = repo 时初始折叠

// Pod 列：有 pod 就显示数字 + 图标，非链接列全部可点击
html += `<td${hasPods ? ' class="repo-toggle-cell" onclick="toggleRepoPod(\'' + id + '\')"' : ''}>${hasPods ? r.pods.length + ' <span class="toggle-icon" id="repo-icon-' + id + '">' + podInitIcon + '</span>' : '-'}</td>`;
// 其他列：可点击条件用 hasPods（非 showPods）
html += `<td class="desc${hasPods ? ' repo-toggle-cell' : ''}"${hasPods ? ` onclick="toggleRepoPod('${id}')"` : ''}>...</td>`;

// Pod 行：始终渲染，seg 控制 hidden 类
if (hasPods) {
  html += `<tr class="repo-pod-row${showPods ? '' : ' hidden'}" id="${id}">...`;
}
```

#### Pod → Subspec

| 场景 | Subspec 行 DOM | 可点击展开 |
|------|---------------|-----------|
| 有 subspec，seg ≥ +Subspec | 存在，`hidden` 为 false | ✅ |
| 有 subspec，seg = +Pod | 存在，`hidden` 为 true | ✅ |
| 无 subspec | 无 | — |

```javascript
if (hasSub) {
  const subspecHidden = hideSubspec;  // seg < +Subspec
  html += `<tr class="pod-subspec-row${subspecHidden ? ' hidden' : ''}" id="${podId}">...`;
}
// 不能写成 if (hasSub && showSubspec)
```

**注意**：手动展开状态不跨档位保留，加/减档时重置。完整规范见 priority-chain 中的 N层嵌套表格层级展开规则说明。

### 关键代码位置

- 读 fallback: `renderSubCategory` 中 `const level = catDetailLevel[item.type] ?? parentLevel ?? viewModeToLevel(viewMode);`
- 写 layer 2 + 清除 layer 1: `setCatLevel` → `clearDescendantLevels`
- 写 layer 0 + 清除全部: `setViewMode` → `catDetailLevel = {}`
- 全局映射: `viewModeToLevel` 将 `'repo'|'pod'|'subspec'` 映射为 `1|2|3`

## 12. 响应式适配

### 12.1 整页断点缩放

通过 `--font-base` + `rem` 在多断点联动缩放布局和字体：

**CSS：**
```css
:root { --font-base: 16px; }
body { font-size: var(--font-base); }
/* 所有字体、间距、边距用 rem 而非 px */

@media (max-width: 1200px) {
  :root { --font-base: 15px; }
  .sidebar { width: 240px; }
  .main { margin-left: 240px; }
}
@media (max-width: 1000px) {
  :root { --font-base: 14px; }
  .sidebar { width: 200px; }
  .main { margin-left: 200px; }
}
@media (max-width: 800px) {
  :root { --font-base: 13px; }
  .sidebar { width: 160px; }
  .main { margin-left: 160px; }
}
@media (max-width: 600px) {
  :root { --font-base: 12px; }
  .sidebar { display: none; }      /* 移动端隐藏侧栏 */
  .main { margin-left: 0; }
}
@media (max-width: 480px) {
  th, td { padding: 0.4rem 0.533rem; }  /* 更紧凑 */
  .toolbar input { min-width: 120px; }
}
```

侧栏与主内容边距同步（`margin-left = sidebar width`），保证右侧内容始终可见。

### 12.2 `table-layout: fixed` 防溢出

```css
table { width: 100%; table-layout: fixed; }
th, td { word-break: break-word; }
```

配合同步列宽比例，让重要列获得更多宽度：
```css
.table-main th:nth-child(1) { width: 22%; }    /* 名称 */
.table-main th:nth-child(2) { width: 10%; }    /* 展开列 */
.table-main th:nth-child(3) { width: 32%; }    /* 描述 */
.table-main th:nth-child(7) { width: 10%; }    /* 次要列 */
/* 其余列自动均分剩余空间 */
```

`table-layout: fixed` 后，浏览器按固定分配列宽，内容超出由 `word-break: break-word` 换行处理。表的实际宽度 = 容器宽度，不再受内容撑大。

### 12.3 描述列截断

大屏显示全文，小屏截断 + `title` 悬浮查看：

```css
.desc { white-space: normal; word-break: break-word; }

@media (max-width: 800px) {
  .desc { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
}
```

JS 渲染时加 `title` 属性：
```javascript
html += `<td class="desc" title="${escapeHtml(text)}">${escapeHtml(text)}</td>`;
```

### 12.4 CSS 代码模板中的备注

如果从本章的**代码模板**部分拷贝 CSS，需注意：模板里用的是 `px`（如 `width: 18px; font-size: 10px`），套用本方案时应改为 `rem`：
```css
/* px → rem（假设 16px 基准） */
.toggle-icon {
  width: 1.2rem;     /* 18px → 1.2rem */
  font-size: 0.667rem; /* 10px → 0.667rem */
}
```

## 13. 完整实现示例

**`dvlproad项目列表.html`** 是本 skill 的完整实现，位于：
```
source/_posts/管理相关/项目列表/dvlproad项目列表/dvlproad项目列表.html
```

该文件覆盖了本 skill 的全部设计规则：

| 规则 | 实现位置/方式 |
|------|--------------|
| 列序（名称后紧跟展开列） | 仓库名列第 1 列，Pod 展开图标列第 2 列 |
| toggle 位置（数字+符号） | 有 Pod 的行显示 `2 ▼`，有 Subspec 的 Pod 行显示 `3 ▶` |
| 整行可点展开 | `.repo-row` 整行 `onclick="toggleRepoPod(id)"` |
| 层级缩进 | Pod 行 `padding-left: 2rem`，Subspec 行 `padding-left: 4rem` |
| CSS 动画 | `.repo-pod-row { transition: all 0.2s ease; }` |
| 优先级链 | `viewMode`(layer 0) × `catDetailLevel`(layer 2) — `clearDescendantLevels` 递归清除 |
| 响应式适配 | `--font-base` + 5 断点 + `table-layout: fixed` + 描述列截断 |

**使用方法：** 替换 `data/` 目录下的 JSON 数据源，调整列定义和 `render()` 中的表头，即可适配任意 N 级层级结构。
```
