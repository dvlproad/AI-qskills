---
name: html-data-loading
description: |
  HTML 三阶段数据加载方案 — fetch JSON → 动态 JS → 文件选择器降级。
  解决单页面 HTML 在 file:// 和 HTTP 双协议下的数据加载问题。
  触发场景：用户提到"数据加载方案"、"html数据加载"、"三阶段加载"、"本地测试数据"、"file:// 数据加载"、"双协议数据"
---

# HTML 三阶段数据加载方案

## 适用场景

单页面 HTML 需要加载外部 JSON 数据，但目标用户可能在：
- **HTTP 环境**（如 Hexo 博客）— 可以直接 `fetch()`
- **file:// 本地双击**（本地测试）— `fetch()` 因 CORS 失败

## 加载策略

```text
打开页面 → Phase 0: startApp(DEFAULT_DATA)
                       │ 用户立刻看到界面，无需等待
                       ▼
Phase 1: fetch(data.json)  ─── HTTP 成功 → ✅ 完整渲染
                       │
                       └── HTTP 失败
                       │
                       ▼
Phase 2: 动态 <script> 加载 data.js  ─── 成功 → ✅ 完整渲染
                       │
                       └── JS 失败
                       │
                       ▼
Phase 3: 显示提示（含创建 JS 的指令）+ 文件选择器
         用户手动选择 .json → FileReader → ✅ 完整渲染
```

## 代码模板

### 1. 数据定义

```javascript
// 内嵌默认数据（约 2 KB，放在 <script> 中，在 init() 之前定义）
const DEFAULT_DATA = { "repos": [...], "unmatched_pods": [...] };
```

### 2. 辅助函数

```javascript
function loadJsAsync(src) {
  return new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = src;
    s.onload = () => resolve(window.DATA || null);
    s.onerror = reject;
    document.head.appendChild(s);
  });
}

function clearSidebar() {
  const sb = document.getElementById('sidebar');
  sb.innerHTML = '<div class="sidebar-title">📂 项目分类</div>';
}
```

### 3. startApp — 数据就绪后的唯一入口

```javascript
function startApp(data) {
  appData = data;
  clearSidebar();
  buildSidebar(data.repos);
  render();                // 渲染主内容
}
```

要求 `startApp()` 支持重复调用：
- 第一次：Phase 0 加载默认数据
- 后续：Phase 1/2/3 成功后替换为正式数据

### 4. 三阶段加载

```javascript
async function init() {
  startApp(DEFAULT_DATA);             // Phase 0: 立即展示

  // Phase 1: fetch JSON (HTTP)
  try {
    const resp = await fetch('./data/repos_with_pods.json');
    if (!resp.ok) throw new Error();
    startApp(await resp.json());
    return;
  } catch {}

  // Phase 2: 动态 JS (file://)
  try {
    const jsData = await loadJsAsync('./data/repos_with_pods.js');
    if (jsData) { startApp(jsData); return; }
  } catch {}

  // Phase 3: 提示 + 文件选择器
  document.getElementById('data-warning').style.display = '';
  document.getElementById('file-picker').style.display = '';
}
```

### 5. 文件选择器

```javascript
function loadLocalFile(input) {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    try {
      const data = JSON.parse(e.target.result);
      document.getElementById('data-warning').style.display = 'none';
      document.getElementById('file-picker').style.display = 'none';
      startApp(data);
    } catch {
      alert('JSON 格式错误');
    }
  };
  reader.readAsText(file);
}
```

## 文件结构

```
项目根目录/
├── index.html                ← 渲染器（25 KB）
├── data/
│   ├── repos_with_pods.json  ← 数据源（Phase 1 fetch）
│   ├── repos_with_pods.js    ← 可选（Phase 2，file:// 用）
│   └── ...
```

## 各环境设置

### HTTP（Hexo / 服务器）
- 无需额外设置，`fetch()` 自动工作
- 更新 `.json` 后刷新即生效

### 本地正式测试（双击 HTML）
创建 `.js` 文件供 Phase 2 使用：

```bash
echo 'window.DATA = ' > data/repos_with_pods.js
cat data/repos_with_pods.json >> data/repos_with_pods.js
```

HTML 中 `startApp()` 会根据 `window.DATA` 变量读取数据。

### 本地临时测试
- 无需额外文件
- 打开 HTML → 看到默认数据界面 → 选择 `.json` 文件 → 渲染完整数据

## HTML 提示横幅模板

```html
<div id="data-warning" class="data-warning">
  <p><strong>⚠️ 数据文件加载失败</strong></p>
  <p><strong>如需本地双击即有完整数据（正式测试）：</strong><br>
  创建 <code>data/repos_with_pods.js</code> 文件：</p>
  <pre>echo 'window.DATA = ' > data/repos_with_pods.js
cat data/repos_with_pods.json >> data/repos_with_pods.js</pre>
  <p><strong>如需临时查看（临时测试）：</strong>请在下方选择文件</p>
</div>
<div id="file-picker" class="file-picker">
  <span>选择 <code>repos_with_pods.json</code>：</span>
  <input type="file" accept=".json" onchange="loadLocalFile(this)">
</div>
```

```css
.data-warning { background: #fff8e1; border: 1px solid #ffe082; padding: 8px 16px; border-radius: 6px; margin-bottom: 8px; font-size: 13px; color: #795548; display: none; line-height: 1.7; }
.data-warning p { margin: 4px 0; }
.data-warning pre { background: #f0f0f0; padding: 6px 10px; border-radius: 4px; font-size: 12px; overflow-x: auto; margin: 4px 0 8px; }
.data-warning code { background: #f0f0f0; padding: 1px 4px; border-radius: 3px; }
```

## 常见问题

### Q: 为什么不用 `<script src>` 静态加载 JS？
静态 `<script>` 标记会阻塞渲染，且无法判断加载成功与否。动态 `loadJsAsync()` 可以：
- 控制加载时机（先展示默认数据）
- Promise 化，方便接入 try/catch 流程
- 通过 `window.DATA` 判断数据是否就绪

### Q: 默认数据（DEFAULT_DATA）应该放多少？
约 2-5 KB，包含 1-2 个分类、2-3 个仓库、1 个带 Pod 的仓库即可。目标是展示 UI 效果，不是完整数据。

### Q: `startApp()` 为什么需要支持重复调用？
因为从 Phase 0（默认数据）切换到 Phase 1/2（正式数据）时，需要重新构建 sidebar 和渲染内容。需要：
- `clearSidebar()` 重置 sidebar
- `buildSidebar()` 用新数据重建
- `render()` 全量重绘
