# 公共部分抽取方案

由于 HTML 无法像 JS 那样通过 `<script src="">` 引用公共部分，有以下几种方案：

---

## 方案一：构建时替换（推荐）

创建构建脚本，在构建时将公共部分替换进业务页面。

**目录结构**：
```
project/
├── src/
│   ├── common/
│   │   ├── head.html      # 公共 head
│   │   ├── api-key.html   # API Key 设置区
│   │   ├── result.html    # 结果展示区
│   │   └── common.js
│   └── pages/
│       ├── crush.html     # 业务页面（只有业务部分）
│       └── emoji.html
└── build.js               # 构建脚本
```

**使用方式**：运行 `node build.js` 生成最终 HTML

---

## 方案二：运行时加载

使用 fetch 在运行时加载公共部分：

```javascript
// 加载公共 HTML
async function loadCommonPart(id, file) {
    const res = await fetch(`./common/${file}`);
    document.getElementById(id).innerHTML = await res.text();
}
```

---

## 方案三：iframe 嵌套

创建公共框架页，业务页作为内容嵌入：

```html
<!-- framework.html -->
<iframe id="content" src="业务页.html" style="border:none;width:100%;height:100%"></iframe>
```

---

## 方案四：直接复制模板

1. 以 `base.html` 为模板
2. 替换 `<!--{占位符}-->` 为实际内容
3. 得到最终 HTML

**base.html 模板变量**：

| 变量 | 说明 |
|------|------|
| `<!--{title}-->` | 页面标题 |
| `<!--{header_title}-->` | 页面大标题 |
| `<!--{header_subtitle}-->` | 副标题 |
| `<!--{input_section}-->` | 业务输入区 HTML |
| `<!--{replies_container_class}-->` | 结果容器 class |
| `<!--{token_usage_class}-->` | Token 显示区 class |
| `<!--{empty_icon}-->` | 空状态图标 |
| `<!--{empty_text}-->` | 空状态文字 |
| `<!--{empty_hint}-->` | 空状态提示 |
| `<!--{business_script}-->` | 业务 JS 代码 |

---

## 当前实现

当前采用**方案四（直接复制模板）**：

1. 参考 `resources/base.html` 作为公共部分模板
2. 业务页面包含完整的 HTML（便于独立运行和修改）
3. 公共 JS 函数在 `common.js` 中

如需更规范的管理，可自行实现构建脚本。
