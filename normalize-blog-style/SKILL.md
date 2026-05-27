---
name: normalize-blog-style
version: 0.0.18
description: |
   规范 Hexo 博客的日期显示格式、分类排序、内容处理（去重标题/清理[toc]/引用样式/独立HTML/全站搜索）+ 视觉美化（scrollReveal fadeIn 动画、fairyDustCursor 星光鼠标、clickLove 爱心点击、canvas-particles 粒子背景）+ rating 评分排序（front-matter 方式）
    触发场景：换主题时检查风格一致性；加特效时参考视觉美化方案
---

# 博客风格与视觉美化

定义博客的视觉风格与美化规范，换主题时逐项检查新主题是否支持，缺失则按参考代码补充；需要添加特效时参考视觉美化方案。

## 触发条件

- "换主题" — 切换 Hexo 主题时，检查并修复风格一致性
- "博客风格" — 查看当前博客风格的规范项
- "规范博客" — 按规范整理博客主题风格
- "博客效果" / "博客美化" / "博客特效" — 添加视觉美化特效
- "鼠标特效" — 添加鼠标光标特效
- "滚动动画" — 添加页面滚动元素动画

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

Step 5: 检查 Read More 链接样式
          │
          ├── 已配置 + 样式明显 → 跳过
          └── 缺失或样式太淡 → 按 Step 4.5 参考代码实现

Step 6: 确认新主题/配置生效

Step 7: 处理独立 HTML 文件（同目录的资产文件）
          │
          └── 检查 _posts/ 下和 .md 同级的 .html → 移入资产目录

Step 8: 配置本地全站搜索（hexo-generator-searchdb）
          │
          ├── 不需要 → 跳过
          └── 需要 → 安装插件 + 添加 JS + 添加样式

Step 9: 检查引用块（blockquote）样式
          │
          ├── 已经是左竖线标准引用 → 跳过
          └── 还是居中/大字号名言样式 → 按参考代码修改

Step 10: [可选] 检查代码块配色
          │
          ├── 配色协调 → 跳过
          └── 突兀 → 按参考代码调整 highlight.styl 变量

Step 11: 检查重复标题 + [toc] 文字
          │
          ├── article.ejs 已有处理逻辑 → 跳过
          └── 没有 → 按参考代码在输出前处理

Step 12: 检查 Asset 图片路径
          │
          ├── 无此模式 → 跳过
          └── 有此模式 → 按参考代码修正

Step 13: 检查 ![]() 空格文件名修复
          │
          ├── 无此模式 → 跳过
          └── 有空格文件名的图片 → 管线已自动处理，无需额外操作

Step 14: 验证图片路径是否正确
          │
          └── `hexo s` → 打开指定页面确认图片显示正常
```

## 一、首页与侧边栏优化

### Step 1: 日期显示格式

**预期行为：**
- 有 `updated` 字段时：`发表于 2026-05-19 · 更新于 2026-05-20`
- 无 `updated` 字段时：只显示日期

**前置条件：** 根 `_config.yml` 必须设置 `updated_option: empty`，否则 Hexo 会默认用文件 mtime 自动填充 `updated`，导致"无 updated"的情况不会出现，所有文章都会显示"更新于"。

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
- 首页文章按「新鲜 → 新鲜日 → top → rating → 日期」五层排序
- `freshness` 控制最新 N 篇置顶
- `freshness_days` 控制 N 天内的文章置顶
- `top` 字段控制 top 评分文章排序
- `rating_threshold` 控制 rating 评分文章筛选（`rating >= 阈值` 进入评分层）

**检查方法：** 查看主题的 `_config.yml` 中是否有 `freshness` / `freshness_days` 配置。
首页模板中是否有对应的排序逻辑。

**不支持时实现：** 按「首页文章排序」章节的规则和伪代码实现。

**验证：** 发布一篇测试文章并设置不同的 freshness / freshness_days / top 值，确认首页顺序符合预期即可。

#### 1. 排序层级

按以下优先级排列，一篇文章只出现在满足条件的最高层级：

| 序   | 含义       | 层级               | 条件                                                       | 层内排序                |
| ---- | ---------- | ------------------ | ---------------------------------------------------------- | ----------------------- |
| 1    | **新鲜**   | **freshness**      | 全局最新 N 篇（`freshness: N`）                            | 按 date/updated 较新者倒序 |
| 2    | **新鲜日** | **freshness_days** | N 天内的文章（`freshness_days: N`），排除已出现在 fresh 的 | 按 date/updated 较新者倒序 |
| 3    | **top**    | **top**            | `top` 值 > 0 的文章，排除已出现在前两层的                  | 按 top 降序 → date 倒序    |
| 4    | **rating** | **rating**         | `rating` >= `rating_threshold`，排除已出现在前三层         | 按 rating 降序 → date 倒序 |
| 5    | **日期**   | **rest**           | 其余所有                                                   | 按 date 倒序               |

#### 2. 评分机制

**top 评分：** 在 front matter 中添加 `top: N` 字段（1-100），N 越大评分越高。无 `top` 字段等同于 `top: 0`。

**rating 评分：** 在 front matter 中添加 `rating: N` 字段（0-100），通过 `rating_threshold` 配置筛选阈值。无 `rating` 字段等同于 `rating: 0`，不进入 rating 层。

#### 3. 配置

在主题 `_config.yml` 中定义：

```yaml
# 首页新鲜期（优先级: freshness > freshness_days > top > rating > date）
freshness: 2               # 0 = 不启用，正整数 = 最新 N 篇
freshness_days: 3          # 0 = 不启用，正整数 = N 天内的文章
rating_threshold: 70       # 0 = 不启用，正整数 = rating >= 此值的文章进入评分排序层
```

在博客根 `_config.yml` 中设置全局排序和 `updated` 行为：

```yaml
index_generator:
  order_by: -top,-rating,-date

# 只有手动设了 updated 的文章才有该值，不被文件 mtime 自动填充
updated_option: empty
```

### Step 4.5: 首页 Read More 链接样式

**预期行为：**
- 文字为 `阅读全文 →`（中文 + 箭头，直观可点击）
- 颜色为蓝色链接，显著但不突兀
- hover 时变蓝底白字

**检查方法：**
1. 主题 `_config.yml` 中是否有 `excerpt_link` 配置项
2. CSS 中是否有 `.article-more-link a` 样式定义（通常在 `source/css/_partial/article.styl` 或等效文件）

**不支持时实现：**
1. 在主题 `_config.yml` 中添加：
   ```yaml
   excerpt_link: 阅读全文 →
   ```
2. 在主题 CSS 文件中添加样式：
   ```stylus
   .article-more-link a
     display: inline-block
     line-height: 1em
     padding: 6px 15px
     border-radius: 15px
     background: color-background
     color: color-link
     text-decoration: none
     &:hover
       background: color-link
       color: #fff
       text-decoration: none
   ```

**验证：** 找一篇有 `<!-- more -->` 截断的文章，确认首页底部显示蓝色「阅读全文 →」链接，hover 变蓝底白字。

### Step 4.6: 自定义 Index Generator（分页排序）

**作用：** 覆盖默认的分页排序逻辑，确保只有 `rating >= rating_threshold` 的文章获得分页排序提升。

**为什么需要：** 默认 `hexo-generator-index` 按 `order_by` 排序时，即使 rating=5 的文章也会排在 rating=0 前面。用自定义生成器后：
- `rating >= 70`（阈值）→ 获得排序提升，排在同页靠前
- `rating < 70` → 等同于无评分，只按日期排序

**原理：** `effectiveSortRating(p) = rating >= threshold ? rating : 0`，低于阈值的评分在排序时被归一化为 0。

---

## 二、配置与迁移

### Step 5: 配置迁移

**注意：** Step 4.5（Read More 链接样式）的 `excerpt_link` 配置和 CSS 样式也需一并迁移。

将以下配置从 `themes/landscape/_config.yml` 和根 `_config.yml` 复制到新主题的 `_config.yml`：

```yaml
# 根 _config.yml：不自动填充 updated
updated_option: empty

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

## 三、功能扩展

### Step 7: 独立 HTML 文件处理

**目的：** 让 `.html` 文件能被 Hexo 正确输出，并通过 URL 访问到。

**背景：** `_posts/` 下与 `.md` 同级的 `.html` 文件，因 `post_asset_folder: true`
机制被纳入 PostAsset 处理。但 Hexo 对此类文件的 slug 计算错误（带前导 `/`），
导致文件不输出到 `public/`，无法通过 URL 访问。

**触发条件：** `_posts/` 下存在和 `.md` 文章同级的独立 `.html` 页面。

**处理方法：**

1. 将 `.html` 移入 `.md` 的资产目录（同名文件夹）中
2. 更新 `.html` 内的相对路径（图片/fetch 等改为相对于新位置）
3. 无需加 `skip_render` 配置（HTML 作为 asset 被直接复制）
4. 不影响本地双击打开

#### 数据生成器脚本

如果 HTML 页面需要动态数据（如目录解析、项目列表），可以将生成器脚本也放在资产目录下：

```
source/_posts/
├── 文章.md                              ← post
└── 文章/                                ← post assets
    ├── 页面.html                        ← 三阶段加载页面
    ├── 生成器.sh                        ← 扫描/生成脚本（js/sh 等均可）
    └── data/
        └── data.json                    ← 脚本输出
```

- 脚本放在资产目录，需在 `_config.yml` 加 `skip_render`：
  ```yaml
  skip_render:
    - '_posts/文章/**/*.{json,js,css,html}'
  ```
- 数据输出到 `data/` 子目录
- HTML 内 fetch 用相对路径 `./data/xxx.json`
- 执行一条命令重建：`node source/_posts/文章/生成器.js` 或 `bash source/_posts/文章/生成器.sh`

**实例参考：** `总目录.md` → `总目录.html` + `parse-catalog.js` + `data/catalog.json`

#### 首页展示 HTML 内容

部分文章（如 `dvlproad项目列表`）有独立的 `.html` 版本，比 markdown 渲染效果更好。
首页默认显示 markdown excerpt，可通过以下方案用 HTML 替代。

**方案 A（iframe 嵌入 + 遮罩）：** 在首页文章卡片中嵌入 iframe 展示 `.html`，iframe 上方覆盖半透明遮罩防止误以为内容完整，点击遮罩或蓝色按钮跳转到独立页面。

**① 创建 filter 脚本：** `scripts/asset-html.js`

```javascript
hexo.extend.filter.register('after_post_render', function(post) {
  var fs = require('fs');
  var path = require('path');
  var basename = (post.slug || '').replace(/.*\//, '');
  if (!basename) return post;

  var htmlFile = path.join(hexo.source_dir, '_posts', post.slug, basename + '.html');
  if (fs.existsSync(htmlFile)) {
    post.index_html_url = basename + '.html';
  }

  return post;
});
```

**② 修改链接：** 将所有指向 `post.path` 的链接改为当 `index && post.index_html_url` 时指向 `.html`。涉及以下模板：

- **②-a 标题链接** — `layout/_partial/post/title.ejs`
  ```ejs
  <% if (index && post.index_html_url){ %>
    <h1 itemprop="name">
      <a class="<%= class_name %>" href="<%- url_for(post.path + post.index_html_url) %>"><%= post.title %></a>
    </h1>
  <% } else if (index){ %>
    <h1 itemprop="name">
      <a class="<%= class_name %>" href="<%- url_for(post.path) %>"><%= post.title %></a>
    </h1>
  <% } else { %>
  ```

- **②-b 日期链接（"发表于"）** — `layout/_partial/post/date.ejs`
  两处 `<a href="<%- url_for(post.path) %>">`（`post.updated` 分支和 `else` 分支）都要加判断：
  ```ejs
  <% if (index && post.index_html_url){ %>
    <a href="<%- url_for(post.path + post.index_html_url) %>">
  <% } else { %>
    <a href="<%- url_for(post.path) %>">
  <% } %>
  ```

- **②-c 搜索结果 URL** — `scripts/asset-html.js` 追加 `after_generate` filter
  修正 `search.xml` 中的 URL，将 `post.path` 替换为 `post.path + post.index_html_url`：
  ```javascript
  hexo.extend.filter.register('after_generate', function() {
    var searchPath = this.config.search ? this.config.search.path : null;
    if (!searchPath) return;
  
    var routeData = this.route.routes[searchPath];
    if (!routeData) return;
  
    var data = routeData.data;
    if (typeof data !== 'string') return;
  
    var root = this.config.root || '/';
    var Post = this.model('Post');
  
    Post.find({ published: true }).forEach(function(post) {
      if (!post.index_html_url) return;
      var oldUrl = encodeURI(root + post.path);
      var newUrl = encodeURI(root + post.path + post.index_html_url);
      if (data.indexOf(oldUrl) !== -1) {
        data = data.split(oldUrl).join(newUrl);
      }
    });
    routeData.data = data;
  });
  ```

- **②-d 总目录.html 链接** — `source/_posts/总目录/总目录.html` + `parse-catalog.js`
  `总目录.html` 中的 3 处 `escapeHtml(item.url)` 在构建链接时使用 `escapeHtml(item.htmlUrl || item.url)`，
  `parse-catalog.js` 负责在扫描 `.md` 时检测配对 `.html` 文件并设置 `post.htmlUrl`：
  ```javascript
  // 检查是否有 paired HTML 资源文件
  var pBasename = path.basename(relPath, '.md');
  var pHtmlDir = path.join(path.dirname(fullPath), pBasename);
  var pHtmlFile = path.join(pHtmlDir, pBasename + '.html');
  if (fs.existsSync(pHtmlFile)) {
    post.htmlUrl = url + '/' + pBasename + '.html';
  }
  ```

**③ 首页内容改用 iframe + 遮罩展示：** `layout/_partial/article.ejs`

```ejs
<% if (index && post.index_html_url){ %>
  <div class="article-html-wrap">
    <iframe src="<%- url_for(post.path + post.index_html_url) %>" style="width:100%;height:70vh;border:none;overflow:auto;"></iframe>
    <a class="article-html-overlay" href="<%- url_for(post.path + post.index_html_url) %>">
      <span class="article-html-overlay-btn">
        👆 点击查看完整独立页面
      </span>
    </a>
  </div>
<% } else if (post.excerpt && index){ %>
```

**④ 添加 CSS 样式：** `source/css/_partial/article.styl`

```stylus
// ── HTML 独立页面预览遮罩 ──
.article-html-wrap
  position: relative

.article-html-overlay
  position: absolute
  top: 0
  left: 0
  right: 0
  bottom: 0
  background: rgba(255,255,255,0.6)
  backdrop-filter: blur(2px)
  display: flex
  align-items: center
  justify-content: center
  cursor: pointer
  text-decoration: none
  transition: background 0.2s, backdrop-filter 0.2s

  &:hover
    background: rgba(255,255,255,0.3)
    backdrop-filter: blur(0px)

.article-html-overlay-btn
  display: inline-block
  padding: 12px 28px
  background: #1a73e8
  color: #fff
  border-radius: 6px
  font-size: 1rem
  font-weight: 500
  line-height: 1.4
  box-shadow: 0 2px 12px rgba(0,0,0,0.15)
  transition: transform 0.2s, box-shadow 0.2s
  user-select: none

  .article-html-overlay:hover &
    transform: scale(1.05)
    box-shadow: 0 4px 20px rgba(0,0,0,0.2)
```

**效果：** 有 `.html` 文件时，首页展示 iframe + 半透明遮罩（内容虚化不可交互）+ 居中蓝色按钮；用户必须点击按钮或遮罩才能跳转到独立页面，不会误以为 iframe 内容就是全部。没有 `.html` 时照常走 `fixMarkdownImages` → `stripH1` 管线。

### Step 8: 本地全站搜索

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

## 四、文章样式优化

### Step 9: 引用块（blockquote）样式

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

### Step 10: [可选] 代码块配色

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

## 五、文章内容处理管线

### Step 11: 重复标题自动去除 + [toc] 文字清理

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

### Step 12: 检查 Asset 图片路径

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

### Step 13: `![]()` 空格文件名修复

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

### Step 14: 验证图片路径是否正确

`hexo s` 后打开以下页面，检查 Step 12（Asset 图片路径）和 Step 13（`![]()` 空格文件名修复）是否生效：

- [首页](http://localhost:4000)

- `<img src="FOLDER/">` 和 `![](FOLDER/)` 的图片 ：[科学上网_ClashX](http://localhost:4000/常识类/技术常识/科学上网_ClashX)

- `![](FOLDER/)`中图片名有空格的图片显示情况：[5框架设计模式-⑦组件化](http://localhost:4000/Architecture架构/架构相关/3组件化/5框架设计模式-⑦组件化)

即检查内容为：其它包含 `![]()` 或 `<img src="FOLDER/">` 模式图片的页面

---

## 六、视觉特效

### Step 15: [可选] 视觉美化特效

**说明：** 此步骤为**可选**。按需添加以下效果，互不冲突，可单独选一或全部添加。

```
├── 不需要 → 跳过
└── 需要 → 按需选择以下效果添加
    ├── A. fairyDustCursor — 星光粉尘鼠标跟随
    ├── B. clickLove.js — 鼠标点击弹出彩色爱心
    ├── C. scrollReveal.js — 滚动淡入/滑入动画（轻量推荐）
    └── D. canvas-particles — 蓝色粒子背景（两侧边距飘移）
```

**检查方法：** 首页下滑，观察文章卡片/图片/标题是否带入场动画；移动鼠标看是否有星光轨迹；点击页面看是否有爱心弹出。

**加载位置（以 landscape 主题为例）：**

所有特效脚本统一在主题的 `layout/_partial/after-footer.ejs` 中添加（或其他主题的 `layout/_partial/footer.ejs` / `layout.njk` 底部）。确保在 `</body>` 前加载。

---

#### A. fairyDustCursor — 星光粉尘鼠标跟随

**用途：** 鼠标移动时，在光标位置产生彩色星光/魔法粉尘的拖尾效果。

**接入方式（ESM，推荐）：** 在 `after-footer.ejs` 中添加：

```html
<script type="module">
  import { fairyDustCursor } from "https://unpkg.com/cursor-effects@latest/dist/esm.js";
  new fairyDustCursor();
</script>
<style>
  /* 防止被页内元素（卡片内容、侧边栏等）压住 */
  canvas { z-index: 999999 !important; }
</style>
```

**自定义颜色和符号：**

```html
<script type="module">
  import { fairyDustCursor } from "https://unpkg.com/cursor-effects@latest/dist/esm.js";
  new fairyDustCursor({
    colors: ["#ff0000", "#ffaa00", "#ffff00"],
    fairySymbol: "✨"
  });
</script>
<style>
  canvas { z-index: 999999 !important; }
</style>
```

**z-index 说明：** fairyDustCursor 生成的 canvas 默认被页面元素（article-entry、sidebar 等）遮盖导致不可见，需强制提至顶层。`canvas` 通配选择器即可（页面一般无其他 canvas，无冲突）。如有其他 canvas 需要用更精确选择器 `canvas[style*="pointer-events"] { z-index: 999999 !important; }`。

**效果：** 鼠标移动时，光标后跟随飘落的彩色星光颗粒，适合科技/创意类博客首页。

**注意：** 移动端无 hover 概念不会触发，不影响触屏用户。

---

#### B. clickLove.js — 鼠标点击爱心

**用途：** 鼠标点击页面任意位置时，从点击处弹出彩色浮动爱心。

**接入方式：** 在 `after-footer.ejs` 中添加：

```html
<script type="text/javascript">
!function(e,t,a){function n(){c(".heart{width: 10px;height: 10px;position: fixed;background: #f00;transform: rotate(45deg);-webkit-transform: rotate(45deg);-moz-transform: rotate(45deg);}.heart:after,.heart:before{content: '';width: inherit;height: inherit;background: inherit;border-radius: 50%;-webkit-border-radius: 50%;-moz-border-radius: 50%;position: fixed;}.heart:after{top: -5px;}.heart:before{left: -5px;}"),o(),r()}function r(){for(var e=0;e<d.length;e++)d[e].alpha<=0?(t.body.removeChild(d[e].el),d.splice(e,1)):(d[e].y--,d[e].scale+=.004,d[e].alpha-=.013,d[e].el.style.cssText="left:"+d[e].x+"px;top:"+d[e].y+"px;opacity:"+d[e].alpha+";transform:scale("+d[e].scale+","+d[e].scale+") rotate(45deg);background:"+d[e].color+";z-index:99999");requestAnimationFrame(r)}function o(){var t="function"==typeof e.onclick&&e.onclick;e.onclick=function(e){t&&t(),i(e)}}function i(e){var a=t.createElement("div");a.className="heart",d.push({el:a,x:e.clientX-5,y:e.clientY-5,scale:1,alpha:1,color:s()}),t.body.appendChild(a)}function c(e){var a=t.createElement("style");a.type="text/css";try{a.appendChild(t.createTextNode(e))}catch(t){a.styleSheet.cssText=e}t.getElementsByTagName("head")[0].appendChild(a)}function s(){return"rgb("+~~(255*Math.random())+","+~~(255*Math.random())+","+~~(255*Math.random())+")"}var d=[];e.requestAnimationFrame=function(){return e.requestAnimationFrame||e.webkitRequestAnimationFrame||e.mozRequestAnimationFrame||e.oRequestAnimationFrame||e.msRequestAnimationFrame||function(e){setTimeout(e,1e3/60)}}(),n()}(window,document);
</script>
```

**效果：** 每次鼠标点击产生一个随机颜色的爱心，逐渐上浮 + 缩小 + 淡出消失，叠加多个爱心时呈自然粒子扩散效果。

**注意：** 移动端 tap 事件同样触发，不影响交互。

---

#### C. scrollReveal.js — 滚动动画（轻量方案）

**用途：** 页面滚动时，元素以淡入/滑入方式出场，提升浏览节奏感。

**接入方式：** 在 `after-footer.ejs` 中引入 CDN 并初始化：

```html
<script src="https://unpkg.com/scrollreveal"></script>
<script>
  ScrollReveal({ distance: '40px', duration: 800, easing: 'ease-out' });
  ScrollReveal().reveal('.article',             { delay: 200, interval: 100, origin: 'bottom' });
  ScrollReveal().reveal('.article-entry h2',    { origin: 'left' });
  ScrollReveal().reveal('.article-entry img',   { origin: 'bottom', scale: 0.95 });
</script>
```

**选择器说明（按 landscape 主题）：**

| 选择器 | 效果 | 说明 |
|--------|------|------|
| `.article` | 底部滑入 + staggered | 首页文章卡片，每张间隔 100ms |
| `.article-entry h2` | 左侧滑入 | 文章内二级标题 |
| `.article-entry img` | 底部淡入 + 轻微缩放 | 文章内图片 |

**初始化参数：** `distance` 移动距离、`duration` 动画时长 ms、`easing` 缓动函数。

**注意：** 仅对首页和文章页生效，不影响侧边栏和 footer。对纯内容页面（无大段滚动）无性能影响。

---

#### D. canvas-particles — 蓝色粒子背景（两侧边距飘移）

**用途：** 页面背景层以 180 个蓝色粒子（#258fb8）在两侧边距和侧边栏空隙中缓缓飘移，鼠标快速掠过时粒子按速度比例逃离，产生动态交互感。

**接入方式：**

1. **创建 `themes/landscape/source/js/canvas-particles.js`**，内容见下方参考代码
2. **在 `after-footer.ejs` 中添加加载行**（位于视觉美化特效区前）：
   ```html
   <!-- ====== 粒子背景 ====== -->
   <%- js('js/canvas-particles') %>
   ```
3. **修正 fairyDustCursor 的 CSS 选择器**，避免 z-index 冲突：
   ```css
   /* 旧：canvas { z-index: 999999 !important; } */
   canvas:not(#canvas-particles) { z-index: 999999 !important; }
   ```

**参数说明：**

| 参数 | 值 | 说明 |
|------|:---:|------|
| COUNT | 180 | 粒子总数 |
| SPEED | 0.10 | 基础漂移速度 |
| CONNECT_DIST | 150px | 连线最大距离 |
| 颜色 | #258fb8 | 博客链接色，蓝绿系 |
| 阻尼 | 0.995 | 每帧速度衰减，逃离后约 5 秒回落 |
| mouseSpeed 阈值 | 0.5 | 鼠标移动速度超过此值触发逃离 |
| 逃离范围 | 100px | 粒子在此半径内受鼠标影响 |

**遮挡规则：**

- 粒子落在 `#main` 或 `.widget-wrap` 的 bounding rect 内时跳过绘制
- 粒子在左右两侧边距和侧边栏组件之间的空隙可见
- `updateBlockedRects` 在 resize 和 scroll 时通过 `requestAnimationFrame` 节流重算
- 连接线只在两个粒子都可绘制时画（双方 `isBlocked` 均为 false）

**z-index 层级：**

| 元素 | z-index | 说明 |
|------|:-------:|------|
| canvas#canvas-particles | 2 | 粒子层，固定在内容之上 |
| #wrap | 1 | 内容容器（需设 `background: #fff` 遮挡底部粒子） |
| fairyDustCursor canvas | 999999 | 最顶层，用 `:not(#canvas-particles)` 排除粒子 canvas |

**注意：** 移动端无 hover 概念不会触发鼠标逃离，粒子仅做基础漂移。

**参考代码：** `themes/landscape/source/js/canvas-particles.js`

```javascript
(function() {
  var canvas = document.createElement('canvas');
  canvas.id = 'canvas-particles';
  canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:2;pointer-events:none;';
  document.body.insertBefore(canvas, document.body.firstChild);

  var ctx = canvas.getContext('2d');
  var width, height;
  var particles = [];
  var COUNT = 180;
  var CONNECT_DIST = 150;
  var SPEED = 0.10;
  var mouseX = null, mouseY = null;
  var lastMX = null, lastMY = null, mouseSpeed = 0;
  var blockedRects = [];
  var rectUpdatePending = false;

  function updateBlockedRects() {
    blockedRects = [];
    var main = document.querySelector('#main');
    if (main) blockedRects.push(main.getBoundingClientRect());
    var widgets = document.querySelectorAll('.widget-wrap');
    for (var i = 0; i < widgets.length; i++) {
      blockedRects.push(widgets[i].getBoundingClientRect());
    }
    rectUpdatePending = false;
  }

  function scheduleRectUpdate() {
    if (!rectUpdatePending) {
      rectUpdatePending = true;
      requestAnimationFrame(updateBlockedRects);
    }
  }

  function isBlocked(x, y) {
    for (var i = 0; i < blockedRects.length; i++) {
      var r = blockedRects[i];
      if (x >= r.left && x <= r.right && y >= r.top && y <= r.bottom) return true;
    }
    return false;
  }

  function resize() {
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = width;
    canvas.height = height;
    scheduleRectUpdate();
  }

  resize();
  updateBlockedRects();

  for (var i = 0; i < COUNT; i++) {
    particles.push({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * SPEED,
      vy: (Math.random() - 0.5) * SPEED,
      s: 2 + Math.random() * 2.5
    });
  }

  function animate() {
    if (mouseX === null) mouseSpeed = 0;
    else mouseSpeed *= 0.5;
    ctx.clearRect(0, 0, width, height);

    for (var i = 0; i < COUNT; i++) {
      var p = particles[i];

      if (p.x < 0 || p.x > width) { p.vx = -p.vx; p.x = Math.min(Math.max(p.x, 0), width); }
      if (p.y < 0 || p.y > height) { p.vy = -p.vy; p.y = Math.min(Math.max(p.y, 0), height); }

      if (mouseX !== null && mouseY !== null && mouseSpeed >= 0.5) {
        var dx = p.x - mouseX, dy = p.y - mouseY;
        var dist = Math.sqrt(dx * dx + dy * dy);
        var avoid = 100;
        if (dist < avoid) {
          var angle = Math.atan2(dy, dx);
          var force = (avoid - dist) / avoid * 0.8 * Math.min(mouseSpeed, 2);
          p.vx += Math.cos(angle) * force * 0.08;
          p.vy += Math.sin(angle) * force * 0.08;
          var maxSpeed = 2.0;
          p.vx = Math.min(Math.max(p.vx, -maxSpeed), maxSpeed);
          p.vy = Math.min(Math.max(p.vy, -maxSpeed), maxSpeed);
        }
      }

      p.vx *= 0.995;
      p.vy *= 0.995;
      p.x += p.vx;
      p.y += p.vy;

      if (isBlocked(p.x, p.y)) continue;

      for (var j = i + 1; j < COUNT; j++) {
        var q = particles[j];
        if (isBlocked(q.x, q.y)) continue;
        var dx = p.x - q.x, dy = p.y - q.y;
        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < CONNECT_DIST) {
          var a = (1 - dist / CONNECT_DIST) * 0.4;
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(q.x, q.y);
          ctx.strokeStyle = 'rgba(37,143,184,' + a + ')';
          ctx.lineWidth = 1;
          ctx.stroke();
        }
      }

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.s, 0, Math.PI * 2);
      var grad = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.s);
      grad.addColorStop(0, 'rgba(37,143,184,0.75)');
      grad.addColorStop(1, 'rgba(20,100,140,0.4)');
      ctx.fillStyle = grad;
      ctx.shadowBlur = 10;
      ctx.shadowColor = 'rgba(37,143,184,0.45)';
      ctx.fill();
      ctx.shadowBlur = 0;
    }

    requestAnimationFrame(animate);
  }

  animate();
  window.addEventListener('resize', resize);
  window.addEventListener('scroll', scheduleRectUpdate);
  window.addEventListener('mousemove', function(e) {
    if (lastMX !== null) {
      mouseSpeed = Math.sqrt(Math.pow(e.clientX - lastMX, 2) + Math.pow(e.clientY - lastMY, 2));
    }
    lastMX = e.clientX;
    lastMY = e.clientY;
    mouseX = e.clientX;
    mouseY = e.clientY;
  });
  window.addEventListener('mouseleave', function() {
    mouseX = null;
    mouseY = null;
    lastMX = null;
    lastMY = null;
    mouseSpeed = 0;
  });
})();
```

---

## 参考代码

### date.ejs — 中文日期显示 + 独立 HTML 链接

在主题的 `layout/_partial/post/date.ejs`：

```ejs
<% if (post.updated){ %>
  <span class="<%= class_name %>">
    <% if (index && post.index_html_url){ %>
      <a href="<%- url_for(post.path + post.index_html_url) %>">
    <% } else { %>
      <a href="<%- url_for(post.path) %>">
    <% } %>
      <time datetime="<%= date_xml(post.date) %>" itemprop="datePublished">发表于 <%= date(post.date, date_format) %></time>
    </a>
    <span class="article-updated"> · 更新于 <%= date(post.updated, date_format) %></span>
  </span>
<% } else { %>
  <% if (index && post.index_html_url){ %>
    <a href="<%- url_for(post.path + post.index_html_url) %>" class="<%= class_name %>">
  <% } else { %>
    <a href="<%- url_for(post.path) %>" class="<%= class_name %>">
  <% } %>
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

  function effectiveTime(p) { return p.updated || p.date; }

  // Sort by effectiveTime descending for freshness calculations
  var byDate = [].concat(posts).sort(function(a, b) { return effectiveTime(b) - effectiveTime(a); });

  // Layer 1: freshness (top N by effectiveTime)
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
      if (layerFresh.indexOf(byDate[i]) === -1 && effectiveTime(byDate[i]) >= cutoff) {
        layerFdays.push(byDate[i]);
      }
    }
    layerFdays.sort(function(a, b) { return effectiveTime(b) - effectiveTime(a); });
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

  // Layer 4: rating >= threshold from remaining
  var layerRating = [];
  var ratingThreshold = theme.rating_threshold || 0;
  if (ratingThreshold > 0) {
    var newRest = [];
    for (var i = 0; i < rest.length; i++) {
      if (rest[i].rating >= ratingThreshold) {
        layerRating.push(rest[i]);
      } else {
        newRest.push(rest[i]);
      }
    }
    layerRating.sort(function(a, b) { return (b.rating - a.rating) || (effectiveTime(b) - effectiveTime(a)); });
    rest = newRest;
  }

  // Layer 5: rest
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
  renderLayer(layerRating);
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

### index-generator-sort.js — 自定义分页排序生成器

在博客根目录的 `scripts/index-generator-sort.js`（覆盖默认 `hexo-generator-index`，按 `top → effectiveSortRating → date` 排序）：

```javascript
'use strict';

var pagination = require('hexo-pagination');

hexo.extend.generator.register('index', function(locals) {
  var config = this.config;
  var ratingThreshold = (this.theme && this.theme.config && this.theme.config.rating_threshold) || 70;
  function effectiveSortRating(p) {
    return (p.rating != null && p.rating >= ratingThreshold) ? p.rating : 0;
  }

  var posts = locals.posts;
  posts.data = posts.data.sort(function(a, b) {
    var sa = effectiveSortRating(a);
    var sb = effectiveSortRating(b);

    if (a.top && b.top) {
      if (a.top === b.top) return b.date - a.date;
      return b.top - a.top;
    }
    if (a.top && !b.top) return -1;
    if (!a.top && b.top) return 1;

    if (sa > 0 && sb > 0) {
      if (sa === sb) return b.date - a.date;
      return sb - sa;
    }
    if (sa > 0 && sb === 0) return -1;
    if (sa === 0 && sb > 0) return 1;

    return b.date - a.date;
  });

  var paginationDir = config.pagination_dir || 'page';
  return pagination('', posts, {
    perPage: config.index_generator.per_page,
    layout: ['index', 'archive'],
    format: paginationDir + '/%d/',
    data: { __index: true }
  });
});
```

**工作原理：** Hexo 的 `scripts/` 目录在插件之后加载，`generator.register('index', fn)` 会覆盖 `hexo-generator-index` 注册的同名生成器。`posts.data = posts.data.sort(fn)` 直接修改 Warehouse Query 的内部数据数组。

**注意：** 自定义生成器不读 `_config.yml` 的 `index_generator.order_by` 配置（完全由代码内比较器决定）。

---

### after-footer.ejs — 视觉特效统一加载（四个效果同区添加）

在主题的 `layout/_partial/after-footer.ejs` 末尾（`</body>` 前）添加：

```html
<!-- ====== 粒子背景 ====== -->
<%- js('js/canvas-particles') %>

<!-- ====== 视觉美化特效 ====== -->

<!-- A. fairyDustCursor — 星光粉尘鼠标跟随（ESM） -->
<script type="module">
  import { fairyDustCursor } from "https://unpkg.com/cursor-effects@latest/dist/esm.js";
  new fairyDustCursor();
</script>
<style>
  canvas:not(#canvas-particles) { z-index: 999999 !important; }
</style>

<!-- B. clickLove.js — 鼠标点击爱心 -->
<script type="text/javascript">
!function(e,t,a){function n(){c(".heart{width: 10px;height: 10px;position: fixed;background: #f00;transform: rotate(45deg);-webkit-transform: rotate(45deg);-moz-transform: rotate(45deg);}.heart:after,.heart:before{content: '';width: inherit;height: inherit;background: inherit;border-radius: 50%;-webkit-border-radius: 50%;-moz-border-radius: 50%;position: fixed;}.heart:after{top: -5px;}.heart:before{left: -5px;}"),o(),r()}function r(){for(var e=0;e<d.length;e++)d[e].alpha<=0?(t.body.removeChild(d[e].el),d.splice(e,1)):(d[e].y--,d[e].scale+=.004,d[e].alpha-=.013,d[e].el.style.cssText="left:"+d[e].x+"px;top:"+d[e].y+"px;opacity:"+d[e].alpha+";transform:scale("+d[e].scale+","+d[e].scale+") rotate(45deg);background:"+d[e].color+";z-index:99999");requestAnimationFrame(r)}function o(){var t="function"==typeof e.onclick&&e.onclick;e.onclick=function(e){t&&t(),i(e)}}function i(e){var a=t.createElement("div");a.className="heart",d.push({el:a,x:e.clientX-5,y:e.clientY-5,scale:1,alpha:1,color:s()}),t.body.appendChild(a)}function c(e){var a=t.createElement("style");a.type="text/css";try{a.appendChild(t.createTextNode(e))}catch(t){a.styleSheet.cssText=e}t.getElementsByTagName("head")[0].appendChild(a)}function s(){return"rgb("+~~(255*Math.random())+","+~~(255*Math.random())+","+~~(255*Math.random())+")"}var d=[];e.requestAnimationFrame=function(){return e.requestAnimationFrame||e.webkitRequestAnimationFrame||e.mozRequestAnimationFrame||e.oRequestAnimationFrame||e.msRequestAnimationFrame||function(e){setTimeout(e,1e3/60)}}(),n()}(window,document);
</script>

<!-- C. scrollReveal.js — 滚动淡入/滑入动画 -->
<script src="https://unpkg.com/scrollreveal"></script>
<script>
  ScrollReveal({ distance: '40px', duration: 800, easing: 'ease-out' });
  ScrollReveal().reveal('.article',             { delay: 200, interval: 100, origin: 'bottom' });
  ScrollReveal().reveal('.article-entry h2',    { origin: 'left' });
  ScrollReveal().reveal('.article-entry img',   { origin: 'bottom', scale: 0.95 });
</script>
```

**按需注释：** 不需要的效果直接注释或删除对应块即可。

---

## 版本记录

**0.0.18 (2026-05-28): Step 4.6 新增自定义 Index Generator（`scripts/index-generator-sort.js`）用于阈值过滤；`order_by` 示例改为 `-top,-rating,-date`；基于 front-matter 方式**

**0.0.14 (2026-05-27): Step 4 新增 rating 评分排序层（`rating_threshold: 70`），五层排序：freshness → freshness_days → top → rating → rest；同步更新 archive.ejs 参考代码**

**0.0.13 (2026-05-27): Step 15 新增 D. canvas-particles 蓝色粒子背景选项；修正 fairyDustCursor CSS 选择器为 `canvas:not(#canvas-particles)` 避免 z-index 冲突**

**0.0.12 (2026-05-23): Step 6 新增「数据生成器脚本」子节，补充 JS skip_render + data/ 目录规范**

**0.0.11 (2026-05-21): 标题改为「博客风格与视觉美化」；新增 Step 14 视觉美化特效（scrollReveal.js / fairyDustCursor / clickLove.js）；新增触发词

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
