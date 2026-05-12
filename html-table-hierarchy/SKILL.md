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
