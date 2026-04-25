---
name: organize-repos-to-md
description: 整理 GitHub 和 Gitee 仓库列表为分类文档，保存为 Markdown 文件
---

# organize-repos-to-md

当用户想要整理自己的 GitHub 和 Gitee 仓库列表，并生成分类文档时触发。

## 触发条件

- `整理仓库` - 整理 GitHub 和 Gitee 仓库
- `整理项目列表` - 整理项目列表
- `整理仓库列表` - 整理仓库列表
- `get repos` - 获取仓库列表
- 其他表达整理仓库意图的指令

## 执行流程

### 1. 获取 GitHub Token

- 优先使用环境变量 `GITHUB_TOKEN` 的值
- 如果没有，尝试使用 `gh auth token`
- 如果都没有，请求用户从 https://github.com/settings/tokens 获取 Token

```bash
# 查看本地 Token
gh auth token
```

### 2. 获取 Gitee OAuth Token

Gitee 需要通过 OAuth 获取 Token：

#### 2.1 获取 Client ID 和 Client Secret

用户需要在 https://gitee.com/oauth/applications 创建一个 OAuth 应用：

- 应用名称：任意（如 opencode）
- 应用主页：任意（如 `https://example.com`）
- Redirect URI：`https://example.com/callback`
- 权限：需要 `projects` 和 `groups`

#### 2.2 生成授权链接

```bash
CLIENT_ID="你的Client_ID"
REDIRECT_URI="https://example.com/callback"
echo "请访问以下链接授权："
echo "https://gitee.com/oauth/authorize?client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&response_type=code&scope=projects+groups"
```

#### 2.3 获取 Access Token

用户授权后会跳转到 `https://example.com/callback?code=xxx`，提取 `code=` 后面的值：

```bash
curl -X POST "https://gitee.com/oauth/token" \
  -d "grant_type=authorization_code" \
  -d "code=刚才获取的code" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "redirect_uri=$REDIRECT_URI"
```

返回格式：
```json
{"access_token":"xxx","token_type":"bearer","expires_in":86400,"refresh_token":"xxx","scope":"user_info projects groups","created_at":xxx}
```

### 3. 获取仓库列表

#### 3.1 GitHub 仓库

```bash
# 获取用户自己的仓库（公开）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=100&sort=updated" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'

# 获取用户自己的仓库（所有，包括私有）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=100&sort=updated&affiliation=owner" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'

# 获取组织仓库（需要是组织成员）
for org in org1 org2 org3; do
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$org/repos?per_page=100" | \
    jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.stargazers_count) | \(.description // "-")"'
done
```

#### 3.2 Gitee 仓库

```bash
# 获取用户自己的仓库
curl -s -H "Authorization: token $GITEE_TOKEN" \
  "https://gitee.com/api/v5/users/用户名/repos?per_page=100" | \
  jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.description // "-")"'

# 获取组织仓库
for org in org1 org2 org3; do
  curl -s -H "Authorization: token $GITEE_TOKEN" \
    "https://gitee.com/api/v5/orgs/$org/repos?per_page=100" | \
    jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | \(.description // "-")"'
done
```

### 4. 组织仓库列表

#### 4.1 常见组织

**GitHub:**
- `dvlproad` - 主用户
- `dvlpCI` - CI脚本
- `dvlpCrack` - 逆向
- `dvlpFork` - Fork仓库
- `luckincoffee-app` - 瑞幸项目

**Gitee:**
- `dvlproad` - 主用户
- `dvlpAppModule` - App模块
- `dvlpFeatureModule` - 功能模块
- `dvlpCI` - CI脚本
- `dvlpBridgeModule` - 桥接模块
- `dvlpApi` - API
- `dvlpPublic` - 公共
- `dvlpMedia` - 媒体
- `dvlpPrivateForever` - 私有永久
- `dvlpteam` - 团队
- `aliroad` - 阿里

### 5. 分类原则

#### 5.1 核心原则

1. **按用途分类**：按仓库的实际用途分类，而非按语言或平台分类
2. **唯一位置**：每个仓库只出现在一个最合适的位置，不要重复
3. **同级分类**：同一层级的分类应该是平行的概念

#### 5.2 子分类细分

同类仓库可再细分子分类：

- **基础/常见/其他**：如 App模块
- **视频/图片/图表/摄像头**：如 媒体相关

### 6. 推荐分类体系

```
模板Demo
初始化项目
UI控件
  - 基础UI (CJUIKit系列)
  - 弹窗UI
  - 列表UI
  - Banner控件
  - 手势
网络请求
数据存储
API
媒体相关
  - 视频
  - 图片
  - 图表
  - 摄像头
动画效果
调试监视
埋点曝光
设计模式
App功能
  - 登录
  - 分享
  - 其他
App模块
  - 基础
  - 常见
  - 其他
推送通知
后台任务
响应式编程
数据算法
Web相关
开发工具
  - 环境切换
工具脚本 (CI/CD)
Homebrew
逆向破解
项目架构
组件库
SDK
跨平台框架
其他
```

### 7. Markdown 格式

#### 7.1 表格列顺序

| 仓库名 | 描述 | 来源 | 组织 | 可见 | 语言 | Stars |
|--------|------|------|------|-----------|------|------|

- **描述**放在第二列，方便阅读
- 来源：GitHub / Gitee
- 可见：公有 / 私有

#### 7.2 文档模板

```markdown
---
title: 标题
date: YYYY-MM-DD HH:MM:SS
categories:
- 分类
tags:
- 标签
---

# 标题

> 数据来源: GitHub + Gitee | 更新于 YYYY-MM-DD

---

## 分类名称

### 子分类（可选）

| 仓库名 | 描述 | 来源 | 组织 | 可见 | 语言 | Stars |
|--------|------|------|------|-----------|------|------|
| [仓库名](链接) | 描述内容 | GitHub | dvlproad | 公有 | Objective-C | 0 |
```

## 输出文件

建议保存到 Hexo 博客目录：
```
/Users/lichaoqian/Project/CQBook/dvlproadHexo/source/_posts/管理相关/
```

## 注意事项

1. **GitHub Token 权限** - Token 需要有 `repo` 权限才能访问私有仓库
2. **Gitee Token 过期** - Gitee Token 默认 24 小时过期，需要刷新
3. **组织成员** - 需要是组织成员才能访问组织仓库
4. **Stars 为空** - Gitee API 不返回 stars，可留空

## 版本记录

### 0.0.2 (2026-04-26): 补充分类原则
- 添加分类原则：按用途分类、每个仓库只出现一次
- 添加推荐分类体系
- 调整表格列顺序：描述放在第二列

### 0.0.1 (2026-04-25): 初始版本
- 获取 GitHub 和 Gitee 仓库列表
- 按用途分类整理
- 生成 Markdown 文档