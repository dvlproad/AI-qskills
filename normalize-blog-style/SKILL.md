---
name: normalize-blog-style
description: |
  规范 Hexo 博客的日期显示格式、分类排序、内容处理（去重标题/清理[toc]/引用样式/独立HTML/全站搜索）
  触发场景：换主题时检查风格一致性
---

# 博客风格规范

定义博客的视觉风格规范，换主题时逐项检查新主题是否支持，缺失则按参考代码补充。

## 触发条件

- "换主题" — 切换 Hexo 主题时，检查并修复风格一致性
- "博客风格" — 查看当前博客风格的规范项
- "规范博客" — 按规范整理博客主题风格

## 执行流程

换主题时按以下顺序检查：

```
Step 1: 检查日期显示格式
          │
          ├── 已支持 → 跳过
          └── 不支持 → 按参考代码实现

Step 2: 检查分类排序
          │
          ├── 已支持 → 跳过
          └── 不支持 → 按参考代码实现

Step 3: 检查分类隐藏
          │
          ├── 已支持 → 跳过
          └── 不支持 → 按参考代码实现

Step 4: 配置首页排序规则
          │
          ├── 不需要 → 确保 freshness / freshness_days 值为 0
          └── 需要 → 按排序规则章节配置

Step 5: 确认新主题/配置生效

Step 6: 处理独立 HTML 文件（同目录的资产文件）
          │
          └── 检查 _posts/ 下和 .md 同级的 .html → 移入资产目录

Step 7: 配置本地全站搜索（hexo-generator-searchdb）
          │
          ├── 不需要 → 跳过
          └── 需要 → 安装插件 + 添加 JS + 添加样式

Step 8: 检查引用块（blockquote）样式
          │
          ├── 已经是左竖线标准引用 → 跳过
          └── 还是居中/大字号名言样式 → 按参考代码修改

Step 9: [可选] 检查代码块配色
          │
          ├── 配色协调 → 跳过
          └── 突兀 → 按参考代码调整 highlight.styl 变量

Step 10: 检查重复标题 + [toc] 文字
          │
          ├── article.ejs 已有处理逻辑 → 跳过
          └── 没有 → 按参考代码在输出前处理

Step 11: 检查 Asset 图片路径
          │
          ├── 无此模式 → 跳过
          └── 有此模式 → 按参考代码修正

Step 12: 检查 ![]() 空格文件名修复
          │
          ├── 无此模式 → 跳过
          └── 有空格文件名的图片 → 管线已自动处理，无需额外操作
```

### Step 1: 日期显示格式

**预期行为：**
- 有 `updated` 字段时：`发表于 2026-05-19 · 更新于 2026-05-20`
- 无 `updated` 字段时：只显示日期

**检查方法：** 查看主题目录下 `layout/_partial/post/` 中是否有 `date.ejs` 或等效文件。

**不支持时实现：** 将参考代码写入 `<新主题>/layout/_partial/post/date.ejs`。

### Step 2: 分类排序

**预期行为：**
- 顶级分类按 `category_order` 配置顺序显示
- 未在配置中的分类按字母序排在末尾
- 子分类按中文章节数字排序（`第十章` → `12`）

**检查方法：** 查看主题目录下 `layout/_widget/` 中分类组件是否支持自定义排序。

**不支持时实现：** 将参考代码写入 `<新主题>/layout/_widget/category.ejs`。

### Step 3: 分类隐藏

**预期行为：**
- `category_exclude` 中配置的分类（如 随笔、面试）不出现在侧边栏

**检查方法：** 查看主题是否支持分类过滤配置。

**不支持时实现：** category.ejs 参考代码已包含此功能，与 Step 2 同一文件。

### Step 4: 首页排序

**预期行为：**
- 首页文章按「新鲜 → 新鲜日 → 评分 → 日期」四层排序
- `freshness` 控制最新 N 篇置顶
- `freshness_days` 控制 N 天内的文章置顶
- `top` 字段控制评分文章排序

**检查方法：** 查看主题的 `_config.yml` 中是否有 `freshness` / `freshness_days` 配置。
首页模板中是否有对应的排序逻辑。

**不支持时实现：** 按「首页文章排序」章节的规则和伪代码实现。

**验证：** 发布一篇测试文章并设置不同的 freshness / freshness_days / top 值，确认首页顺序符合预期即可。

#### 1. 排序层级

按以下优先级排列，一篇文章只出现在满足条件的最高层级：

| 序   | 含义       | 层级               | 条件                                                       | 层内排序                |
| ---- | ---------- | ------------------ | ---------------------------------------------------------- | ----------------------- |
| 1    | **新鲜**   | **freshness**      | 全局最新 N 篇（`freshness: N`）                            | 按 date 倒序            |
| 2    | **新鲜日** | **freshness_days** | N 天内的文章（`freshness_days: N`），排除已出现在 fresh 的 | 按 date 倒序            |
| 3    | **评分**   | **top**            | `top` 值 > 0 的文章，排除已出现在前两层的                  | 按 top 降序 → date 倒序 |
| 4    | **日期**   | **rest**           | 其余所有                                                   | 按 date 倒序            |

#### 2. 评分机制

在 front matter 中添加 `top: N` 字段（1-100），N 越大评分越高。无 `top` 字段等同于 `top: 0`。

#### 3. 配置

在主题 `_config.yml` 中定义：

```yaml
# 首页新鲜期（优先级: freshness > freshness_days > top > date）
freshness: 0          # 0 = 不启用，正整数 = 最新 N 篇
freshness_days: 0     # 0 = 不启用，正整数 = N 天内的文章
```

在博客根 `_config.yml` 中设置全局排序：

```yaml
index_generator:
  order_by: -top,-date
```

### Step 5: 配置迁移

### Step 6: 独立 HTML 文件处理

**目的：** 让 `.html` 文件能被 Hexo 正确输出，并通过 URL 访问到。

**背景：** `_posts/` 下与 `.md` 同级的 `.html` 文件，因 `post_asset_folder: true`
机制被纳入 PostAsset 处理。但 Hexo 对此类文件的 slug 计算错误（带前导 `/`），
导致文件不输出到 `public/`，无法通过 URL 访问。

**触发条件：** `_posts/` 下存在和 `.md` 文章同级的独立 `.html` 页面。

**处理方法：**

1. 将 `.html` 移入 `.md` 的资产目录（同名文件夹）中
2. 更新 `.html` 内的相对路径（图片/fetch 等改为相对于新位置）
3. 无需加 `skip_render` 配置
4. 不影响本地双击打开

将以下配置从 `themes/landscape/_config.yml` 复制到新主题的 `_config.yml`：

```yaml
# 顶级分类排序
category_order:
  - Architecture
  - 安全与破解
  - AI
  - ...（完整列表）

# 隐藏分类
category_exclude:
  - 随笔
  - 面试
```

### Step 7: 本地全站搜索

**目的：** 让博客支持全站搜索，不依赖第三方服务。

#### 三种搜索对比

| 类型 | 搜什么 | 如何工作 | 是否需要配置 |
|------|--------|----------|:-----------:|
| Ctrl+F | 当前页面文字 | 浏览器原生功能，按 Ctrl+F 搜索当前已打开的页面 | ❌ 不需要 |
| 搜索表单（search_form） | Google 站内搜索 | 填关键字后跳转 Google，搜 site:你的域名 关键字 | ✅ 主题自带，无需额外配置 |
| 本地全站搜索（hexo-generator-searchdb） | 全站文章标题+正文 | 安装插件生成 search.xml，JS 在本地解析并实时匹配展示 | ✅ 需装插件 + 加 JS + 加样式 |

**检查方法：**
- `npm list hexo-generator-searchdb` 确认已安装
- `_config.yml` 中有 search 配置（path / field / content）
- 主题包含搜索 JS + overlay 样式

**不支持时实现：**
1. `npm install hexo-generator-searchdb --save`
2. `_config.yml` 添加：
   ```yaml
   search:
     path: search.xml
     field: all
     content: true
   ```
3. 在主题 `source/js/` 下创建 `search-local.js`（拦截搜索按钮，加载 search.xml，实时匹配展示结果）
4. 在布局文件中引用 search-local.js（如 landscape 的 `after-footer.ejs`、next 的 `layout.njk`）
5. 在主题 `source/css/` 中添加 overlay 样式（遮罩层、面板、搜索框、结果列表）

**参考代码：** 见 landscape 主题的 `search-local.js` 和 `style.styl` 中的搜索样式。

### Step 8: 引用块（blockquote）样式

**预期行为：**
- 标准引用样式：左侧竖线、正常字号、左对齐
- 非主题默认的名言居中样式（大字号 + 居中）

**检查方法：** 查看 `source/css/_partial/article.styl` 或其他 CSS 文件中的 `blockquote` 样式定义。

**主题默认样式（需修改）：**
```stylus
blockquote
    font-family: font-serif
    font-size: 1.4em
    margin: line-height 20px
    text-align: center
    /* 无 padding, 无 border-left */
```

**修改后样式：**
```stylus
blockquote
    font-family: font-serif
    margin: line-height 20px
    padding: 0 15px
    border-left: 3px solid color-border
    /* 移除 font-size: 1.4em 和 text-align: center */
```

**注意：** 如果主题的 blockquote 是单独样式文件，在对应文件修改；如果混在 `article.styl` 中，找到 `.article-entry blockquote` 嵌套块修改。

### Step 9: [可选] 代码块配色

**说明：** 此步骤为**可选**。每个主题的代码块配色可能已经配合自身风格，你不一定需要修改。只有当你觉得当前配色不协调时才按需调整。

**检查方法：** 找一篇包含代码块的文章，观察代码块背景色是否与页面整体风格协调。

- 白底简洁主题 + 深色代码块 → 可能突兀，建议调整
- 主题自带配色已经协调 → 跳过

**调整方法：** 修改主题 `source/css/_partial/highlight.styl` 中的颜色变量。以 landscape 主题为例，默认是深色 Tomorrow 主题，可切换为浅色 GitHub 风格：

```stylus
// 变量定义（文件顶部）
highlight-background = #f6f8fa      // 代码块背景：浅灰
highlight-current-line = #eaecef    // 当前行背景
highlight-selection = #c8e1ff       // 选中色
highlight-foreground = #24292f      // 默认文字：近黑
highlight-comment = #6e7781         // 注释：中灰
highlight-red = #cf222e             // 标签、变量
highlight-orange = #953800          // 数字、内置对象
highlight-yellow = #8250df          // 类名
highlight-green = #0550ae           // 字符串（蓝色）
highlight-aqua = #0550ae            // CSS 十六进制色
highlight-blue = #6f42c1            // 函数名（紫色）
highlight-purple = #cf222e          // 关键字（红色）
```

如果需要其他配色，参考 [highlight.js 主题](https://highlightjs.org/static/demo/) 挑选。

---

### Step 10: 重复标题自动去除 + [toc] 文字清理

**预期行为：** 文章标题仅由 `title.ejs` 渲染一次，markdown 正文中的 `# 标题` 不再重复显示。

**背景：** 有些文章在 front-matter 设置了 `title`，正文又以 `# 标题` 开头，导致页面上出现两个相同的标题（一个来自 `title.ejs` 的 `<h1 class="article-title">`，一个来自 markdown 渲染后的 `<h1>`）。

**检查方法：** 找一篇正文以 `# 标题` 开头的文章，确认页面上没有两个相同的标题。

**不支持时实现：** 在主题的 `layout/_partial/article.ejs` 中，定义 `stripH1` 函数，在 `post.excerpt`（首页截断）和 `post.content`（全文）输出前统一处理：

```ejs
<%
var h1Regex = /<h1[^>]*>([\s\S]*?)<\/h1>/;
function stripH1(text, title) {
  var m = text.match(h1Regex);
  if (m) {
    // 去掉 h1 内部的 anchor 等标签后再比较，防止 headerlink 干扰
    var inner = m[1].replace(/<[^>]*>/g, '').trim();
    if (inner === title.trim()) text = text.replace(h1Regex, '');
  }
  return text;
}
%>
<% if (post.excerpt && index){ %>
  <%- stripH1(post.excerpt, post.title) %>
  <% if (theme.excerpt_link){ %>
    <p class="article-more-link">
      <a href="<%- url_for(post.path) %>#more"><%= theme.excerpt_link %></a>
    </p>
  <% } %>
<% } else { %>
  <%- stripH1(post.content, post.title) %>
<% } %>
```

**原理：** `post.content`（或 `post.excerpt`）是 markdown 渲染后的完整 HTML。用正则匹配第一个 `<h1>`，取其内部文本（去掉 `<a class="headerlink">` 等标签）与 `post.title` 比较，匹配则移除该 `<h1>` 块。

**注意：** 只输出前做处理，不修改 `.md` 源文件。对没有 `<h1>` 的文章无影响。`stripH1` 函数同时处理 `post.excerpt`（首页截断）和 `post.content`（文章页、无截断的首页），保证重复标题无处可逃。

#### [toc] 文字清理

`[toc]` 是 Typora 等本地编辑器的目录语法，Hexo 不认识，渲染为 `<p>[toc]</p>`。

在 `stripH1` 中加一行即可清理：

```js
text = text.replace(/<p>\[toc\]<\/p>/gi, '');
```

---

### Step 11: 检查 Asset 图片路径

**文件结构示意：**

```
source/_posts/
└── 常识类/
    └── 技术常识/
        ├── 科学上网_ClashX.md             ← 文章
        └── 科学上网_ClashX/               ← post_asset_folder（同名文件夹）
            ├── ClashVerge_3using_1.png  			← 图片
            └── ClashVerge_3using_2env.png   	← 图片
```

**目的**：想让md在本地 Typora中显示正常，又想让 Hexo 正常。

**背景**：默认情况下：md中路径的不同写法对 Typora 和 Hexo 的显示情况对照表

| 模式名 | 模式特征 | 类型 | Typora | Hexo |
|------|------|------|:----------:|:----------:|
| model_img_folder | `<img src="FOLDER/">` | `<img src="技术常识/ClashVerge_3using_1.png">` | ✅ | ❌ |
| model_img_folder | `<img src="FOLDER/">` | `<img src="image-20250729180443948.png">` | ❌ | ✅ |
| model_mark_folder | `![](FOLDER/)` | `![](科学上网_ClashX/clashx_2setting_2.png)` | ✅ | ❌ |
| model_mark_folder | `![](FOLDER/)` | `![](clashx_2setting_2.png)` | ❌ | ✅ |

**图片路径模式分类**

在 `stripH1` 中用 `getImageModel(src, folderName)` 统一判断：

| 模式 | 条件 | 处理 |
|------|------|:----:|
| `model_http` | `src` 以 `http://` 或 `https://` 开头 | 跳过 |
| `model_warning_current1` | `src` 中无 `/`（无文件夹前缀） | 跳过 |
| `model_warning_current2` | `src` 以 `./` 开头 | 跳过 |
| `model_warning_parent` | `src` 以 `../` 开头 | 跳过 |
| `model_img_folder` | `<img src="FOLDER/xxx">`，FOLDER = asset 文件夹名 | 补 `post.slug` |
| `model_mark_folder` | `![](FOLDER/xxx)` 渲染为 `<img src="/FOLDER/xxx">`，FOLDER = asset 文件夹名 | 去前导 `/` 后补 `post.slug` |
| `mode_other` | FOLDER ≠ asset 文件夹名 | 跳过 |

**判断函数：**

```js
function getImageModel(src, folderName) {
  if (src.match(/^https?:\/\//)) return 'model_http';
  if (src.indexOf('/') < 0)       return 'model_warning_current1';
  if (src.match(/^\.\//))         return 'model_warning_current2';
  if (src.match(/^\.\.\//))       return 'model_warning_parent';

  var raw = src;
  var isMarkFolder = false;
  if (raw.charAt(0) === '/') {
    isMarkFolder = true;
    raw = raw.substring(1);
  }

  var folder = raw.split('/')[0];
  if (decodeURIComponent(folder) === folderName || folder === folderName) {
    return isMarkFolder ? 'model_mark_folder' : 'model_img_folder';
  }
  return 'mode_other';
}
```

**替换处理（在 `stripH1` 中）：**

```js
var folderName = (post.slug || '').replace(/.*\//, '');
if (folderName) {
  text = text.replace(
    /(<img[^>]+src=")([^"]+)/g,
    function(m0, prefix, src) {
      var imageMode = getImageModel(src, folderName);
      if (imageMode === 'model_img_folder' || imageMode === 'model_mark_folder') {
        var raw = src;
        if (raw.charAt(0) === '/') raw = raw.substring(1);
        var folder = raw.split('/')[0];
        var rest = raw.slice(folder.length + 1);
        return prefix + '/' + post.slug + '/' + rest;
      }
      return m0;
    }
  );
}
```

**变换过程（以 `科学上网_ClashX` 为例）：**

```
原始: <img src="科学上网_ClashX/ClashVerge_3using_1.png">
                    └─ getImageModel → 'model_img_folder'

     step 1: 删掉 folderName/
     <img src="ClashVerge_3using_1.png">

     step 2: 补上 post.slug/
     <img src="/常识类/技术常识/科学上网_ClashX/ClashVerge_3using_1.png">
```

```
原始: ![](科学上网_ClashX/clashx_2setting_2.png)
      → 渲染为 <img src="/科学上网_ClashX/clashx_2setting_2.png">
                                         └─ getImageModel → 'model_mark_folder'

     step 1: 去掉前导 /
     <img src="科学上网_ClashX/clashx_2setting_2.png">

     step 2: 删掉 folderName/，补上 slug/
     <img src="/常识类/技术常识/科学上网_ClashX/clashx_2setting_2.png">
```

**注意事项**

- `model_mark_folder` 的前导 `/` 来自 marked 对 `![]()` 的默认渲染，`getImageModel` 中用 `isMarkFolder` 标记区分，但不做 `/？` 跳脱匹配，防止 `model_img_folder` 的路径被二次处理
- URL 编码的文件夹名（如 `%E7%A7%91%E5%AD%A6/`）会先 `decodeURIComponent` 再比较
- `model_warning_current1`（无文件夹前缀）的图片由 Hexo 的 `post_asset_folder` 自行处理，`stripH1` 不干涉

---

### Step 12: `![]()` 空格文件名修复

**问题：** markdown 的 `![]()` 语法中，如果文件名包含空格（如 `Manager 跳转.png`），渲染器无法正确解析 URL，将 `![]()` 输出为原始文本，图片不显示。

**背景：** `post.content` 中的 `![]()` 已由 Hexo 初步处理，URL 中的 `/` 被编码为 `&#x2F;`。需要先解码再编码空格，才能让 `getImageModel` 正确识别。

**修复：** 在 `article.ejs` 的 `stripH1` 前增加预处理函数：

```ejs
function fixMarkdownImages(text) {
  return text.replace(/!\[([^\]]*)\]\(([^)]*)\)/g, function(m, alt, url) {
    var clean = url.replace(/&#x2F;/g, '/').replace(/&#47;/g, '/');
    return '<img src="' + clean.replace(/ /g, '%20') + '" alt="' + alt + '">';
  });
}
```

**调用位置：**
```ejs
<%- stripH1(fixMarkdownImages(post.excerpt), post.title) %>
<%- stripH1(fixMarkdownImages(post.content), post.title) %>
```

**完整管线：**

```
post.content
  → fixMarkdownImages   (&#x2F; → /，空格 → %20，![]() → <img>)
  → stripH1             (H1 去重 + [toc] 清理)
    → getImageModel     (model_warning_current1 → model_img_folder → 重写绝对路径)
  → 输出 HTML
```

**注意：** 只修改渲染管线，不修改 `.md` 源文件。

---

## 参考代码

### date.ejs — 中文日期显示

在主题的 `layout/_partial/post/date.ejs`：

```ejs
<% if (post.updated){ %>
  <span class="<%= class_name %>">
    <a href="<%- url_for(post.path) %>">
      <time datetime="<%= date_xml(post.date) %>" itemprop="datePublished">发表于 <%= date(post.date, date_format) %></time>
    </a>
    <span class="article-updated"> · 更新于 <%= date(post.updated, date_format) %></span>
  </span>
<% } else { %>
  <a href="<%- url_for(post.path) %>" class="<%= class_name %>">
    <time datetime="<%= date_xml(post.date) %>" itemprop="datePublished"><%= date(post.date, date_format) %></time>
  </a>
<% } %>
```

### category.ejs — 排序 + 隐藏 + 子分类章节排序

在主题的 `layout/_widget/category.ejs`：

```ejs
<% if (site.categories.length){ %>
  <%
  function chapterSortKey(name) {
    var m = name.match(/^第([一二三四五六七八九十百]+)章/);
    if (!m) return 'ZZZ' + name;
    var d = {一:1,二:2,三:3,四:4,五:5,六:6,七:7,八:8,九:9,十:10,百:100};
    var n = 0;
    for (var i = 0; i < m[1].length; i++) {
      n += d[m[1][i]] || 0;
    }
    return String(n).padStart(4, '0');
  }
  %>
  <div class="widget-wrap">
    <h3 class="widget-title"><%= __('categories') %></h3>
    <div class="widget">
      <ul class="category-list">
        <%
        var topCats = site.categories.toArray().filter(function(c) { return !c.parent; });
        var exclude = theme.category_exclude || [];
        topCats = topCats.filter(function(c) { return exclude.indexOf(c.name) === -1; });
        var order = theme.category_order || [];
        topCats.sort(function(a, b) {
          var ia = order.indexOf(a.name);
          var ib = order.indexOf(b.name);
          if (ia !== -1 && ib !== -1) return ia - ib;
          if (ia !== -1) return -1;
          if (ib !== -1) return 1;
          return a.name.localeCompare(b.name);
        });
        for (var ci = 0; ci < topCats.length; ci++) {
          var cat = topCats[ci];
        %>
          <li class="category-list-item">
            <a class="category-list-link" href="<%- url_for(cat.path) %>"><%= cat.name %></a>
            <% if (theme.show_count){ %>
              <span class="category-list-count"><%= cat.length %></span>
            <% } %>
            <%
            var children = site.categories.find({parent: cat._id}).sort({name: 1}).toArray();
            children.sort(function(a, b) {
              return chapterSortKey(a.name).localeCompare(chapterSortKey(b.name));
            });
            if (children.length > 0) {
            %>
              <ul class="category-list-child">
              <% for (var chi = 0; chi < children.length; chi++) { %>
                <li class="category-list-item">
                  <a class="category-list-link" href="<%- url_for(children[chi].path) %>"><%= children[chi].name %></a>
                  <% if (theme.show_count){ %>
                    <span class="category-list-count"><%= children[chi].length %></span>
                  <% } %>
                </li>
              <% } %>
              </ul>
            <% } %>
          </li>
        <% } %>
      </ul>
    </div>
  </div>
<% } %>
```

### _config.yml — 分类配置

在主题的 `_config.yml` 中添加：

```yaml
# 顶级分类排序（按此顺序显示，未列出的按字母序排在末尾）
category_order:
  - Architecture
  - 安全与破解
  - AI
  - 管理相关
  - 行业相关
  - 混编
  - 数据结构
  - 算法与数学
  - Database
  - iOS
  - Android
  - Flutter
  - ReactNative
  - React
  - H5-APP
  - HTML
  - Weex
  - 上架相关
  - Script
  - 阿里云
  - 实用工具
  - 代码管理
  - 电脑使用
  - 常识类
  - 编程工具
  - 开发工具
  - 科学工具
  - 专利
  - 面试
  - 随笔
  - developer
  - 自动化

# 隐藏分类（侧边栏不展示）
category_exclude:
  - 随笔
  - 面试
```

### archive.ejs — 首页文章排序

在主题的 `layout/_partial/archive.ejs`：

```ejs
<% if (pagination == 2){ %>
  <%
  var freshN = theme.freshness || 0;
  var freshDays = theme.freshness_days || 0;
  var posts = page.posts.toArray();

  // Sort by date descending for freshness calculations
  var byDate = [].concat(posts).sort(function(a, b) { return b.date - a.date; });

  // Layer 1: freshness (top N by date)
  var layerFresh = [];
  if (freshN > 0) {
    layerFresh = byDate.slice(0, Math.min(freshN, byDate.length));
  }

  // Layer 2: freshness_days (within N days, exclude layerFresh)
  var layerFdays = [];
  if (freshDays > 0) {
    var now = new Date();
    var cutoff = new Date(now.getTime() - freshDays * 86400000);
    for (var i = 0; i < byDate.length; i++) {
      if (layerFresh.indexOf(byDate[i]) === -1 && byDate[i].date >= cutoff) {
        layerFdays.push(byDate[i]);
      }
    }
    layerFdays.sort(function(a, b) { return b.date - a.date; });
  }

  // Remaining (from original -top,-date order, exclude assigned)
  var rest = [];
  for (var i = 0; i < posts.length; i++) {
    if (layerFresh.indexOf(posts[i]) === -1 && layerFdays.indexOf(posts[i]) === -1) {
      rest.push(posts[i]);
    }
  }

  // Layer 3: top > 0 from remaining
  var layerTop = [];
  while (rest.length > 0 && rest[0].top > 0) {
    layerTop.push(rest.shift());
  }

  // Layer 4: rest
  var layerRest = rest;

  // Render layers in order
  function renderLayer(layer) {
    for (var j = 0; j < layer.length; j++) {
  %>
      <%- partial('article', {post: layer[j], index: true}) %>
  <%
    }
  }
  renderLayer(layerFresh);
  renderLayer(layerFdays);
  renderLayer(layerTop);
  renderLayer(layerRest);
  %>
<% } else { %>
  <% var last; %>
  <% page.posts.each(function(post, i){ %>
    <% var year = post.date.year(); %>
    <% if (last != year){ %>
      <% if (last != null){ %>
        </div></section>
      <% } %>
      <% last = year; %>
      <section class="archives-wrap">
        <div class="archive-year-wrap">
          <a href="<%- url_for(config.archive_dir + '/' + year) %>" class="archive-year"><%= year %></a>
        </div>
        <div class="archives">
    <% } %>
    <%- partial('archive-post', {post: post, even: i % 2 == 0}) %>
  <% }) %>
  <% if (page.posts.length){ %>
    </div></section>
  <% } %>
<% } %>
<% if (page.total > 1){ %>
  <nav id="page-nav">
    <% var prev_text = "&laquo; " + __('prev');var next_text = __('next') + " &raquo;"%>
    <%- paginator({
      prev_text: prev_text,
      next_text: next_text
    }) %>
  </nav>
<% } %>
```

---

## 版本记录

**0.0.10 (2026-05-21): 新增 Step 12 ![]() 空格文件名修复（fixMarkdownImages）+ Step 9/11 重编号**

**0.0.9 (2026-05-20): Step 10 重构为 getImageModel 分类 + 标准化模式命名**

**0.0.8 (2026-05-20): 补充 `![]()` vs `<img>` 处理边界，去掉 `/?` 防止双倍路径**

**0.0.7 (2026-05-20): Step 10 重写为 Asset 图片路径修正，[toc] 合并到 Step 9**

**0.0.6 (2026-05-20): 新增 Step 11 [可选] 代码块配色**

**0.0.5 (2026-05-20): 新增 Step 9 重复标题自动去除 + Step 10 [toc] 文字清理**

**0.0.4 (2026-05-20): 新增 Step 8 引用块（blockquote）样式规范化**

**0.0.3 (2026-05-20): 新增 Step 7 本地全站搜索 + 三种搜索方式对比**

**0.0.2 (2026-05-20): 新增 Step 6 独立 HTML 文件处理规范**

**0.0.2 (2026-05-20): 新增 Step 6 独立 HTML 文件处理规范**

**0.0.1 (2026-05-19): 初始版本**
