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

Step 9: 检查重复标题
          │
          ├── article.ejs 已有 H1 去重逻辑 → 跳过
          └── 没有 → 按参考代码在输出前添加去重

Step 10: 检查 [toc] 文字
          │
          ├── 页面不显示 [toc] → 跳过
          └── 显示 [toc] 字样 → 按参考代码在输出前清理
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

### Step 9: 重复标题自动去除

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

### Step 10: [toc] 文字清理

**预期行为：** 页面上不显示 `[toc]` 字样。

**背景：** `[toc]` 是 Typora 等本地编辑器的目录语法。Hexo 默认的 markdown 渲染器（`marked`）不认识此语法，将其渲染为 `<p>[toc]</p>`，在博客页面上显示为裸露文字。

**检查方法：** 找一篇使用了 `[toc]` 语法的文章，确认页面上不显示 `[toc]` 字样。

**不支持时实现：** 将 `[toc]` 清理加到 Step 9 的 `stripH1` 函数中：

```ejs
function stripH1(text, title) {
  var m = text.match(h1Regex);
  if (m) {
    var inner = m[1].replace(/<[^>]*>/g, '').trim();
    if (inner === title.trim()) text = text.replace(h1Regex, '');
  }
  return text.replace(/<p>\[toc\]<\/p>/gi, '');
}
```

完整 `stripH1` + `[toc]` 合一（`article.ejs` 中的完整改动）：

```ejs
    <div class="article-entry" itemprop="articleBody">
      <%
      var h1Regex = /<h1[^>]*>([\s\S]*?)<\/h1>/;
      function stripH1(text, title) {
        var m = text.match(h1Regex);
        if (m) {
          // 去掉 h1 内部的 anchor 等标签后再比较，防止 headerlink 干扰
          var inner = m[1].replace(/<[^>]*>/g, '').trim();
          if (inner === title.trim()) text = text.replace(h1Regex, '');
        }
        // 清理 [toc]
        return text.replace(/<p>\[toc\]<\/p>/gi, '');
      }
      %>
      <% if (post.excerpt && index){ %>
        <%- stripH1(post.excerpt, post.title) %>
        ...
      <% } else { %>
        <%- stripH1(post.content, post.title) %>
      <% } %>
    </div>
```

**注意：** `stripH1` 在 `if/else` 之前定义一次，两个分支共用。`post.excerpt`（首页截断有 `<!-- more -->` 的文章）和 `post.content`（文章页 + 无截断首页）统一处理。

---

## 版本记录

### 0.0.5 (2026-05-20): 新增 Step 9 重复标题自动去除 + Step 10 [toc] 文字清理

### 0.0.4 (2026-05-20): 新增 Step 8 引用块（blockquote）样式规范化

### 0.0.3 (2026-05-20): 新增 Step 7 本地全站搜索 + 三种搜索方式对比

### 0.0.2 (2026-05-20): 新增 Step 6 独立 HTML 文件处理规范

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

### 首页文章排序

#### 排序层级

按以下优先级排列，一篇文章只出现在满足条件的最高层级：

| 层级 | 条件 | 层内排序 |
|------|------|---------|
| 1. **fresh** | 全局最新 N 篇（`freshness: N`） | 按 date 倒序 |
| 2. **fresh_days** | N 天内的文章（`freshness_days: N`），排除已出现在 fresh 的 | 按 date 倒序 |
| 3. **top** | `top` 值 > 0 的文章，排除已出现在前两层的 | 按 top 降序 → date 倒序 |
| 4. **rest** | 其余所有 | 按 date 倒序 |

#### 配置

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

#### 评分机制

在 front matter 中添加 `top: N` 字段（1-100），N 越大评分越高。无 `top` 字段等同于 `top: 0`。

#### 实现参考（伪代码）

换主题时，按以下逻辑在主题的首页模板中实现：

```
posts = page.posts
by_date = posts sorted by date descending

// 分配层级
fresh_layer   = by_date[0..freshness-1]
freshday_layer = posts in [today - freshness_days, today] 且不在 fresh_layer
remaining      = posts 中排除 fresh_layer + freshday_layer 的（保持原序）
top_layer      = remaining 中 top > 0 的连续段
rest_layer     = remaining 中剩余

// 渲染
render fresh_layer（按 date 降序）
render freshday_layer（按 date 降序）
render top_layer（按 top 降序 → date 降序）
render rest_layer（按 date 降序）
```

---

## 版本记录

### 0.0.2 (2026-05-20): 新增 Step 6 独立 HTML 文件处理规范

### 0.0.1 (2026-05-19): 初始版本
