# AI-qskills
自定义的 Skill 工具集合

| Skill                                        | 描述                      | 触发场景        | 产出示例          |
| -------------------------------------------- | ------------------------- | --------------- | ----------------- |
| [skill-qian-optimize](./skill-qian-optimize) | 优化skill，可生成结构文档 | "完善我的skill" | 所有的skill的创建 |

**所有 Skill 的完善遵从 [skill-qian-optimize 的 SKILL.md](./skill-qian-optimize/SKILL.md)**



## Skill 分类详解

---

### 📝 脚本相关

**关系**: 流程链

```mermaid
graph LR
    A[📝 script-specification<br/>创建脚本] --> B[📦 script-to-homebrew<br/>发布] --> C[🔧 script-qtool<br/>使用] --> D[🧪 script-test-branch-info<br/>测试]
```

| Skill | 描述 | 触发场景 | 产出示例 |
|-------|------|----------|----------|
| [script-specification](./script-specification) | 帮助创建符合统一要求的脚本 | "创建脚本" | |
| [script-to-homebrew](./script-to-homebrew) | 将脚本整合到 qbase 库 | "整合到qbase" | 发布qbase |
| [script-qtool](./script-qtool) | 操作 CQCI 工具集 | 包含 "script-qtool" 的指令 | |
| [script-test-branch-info](./script-test-branch-info) | 测试分支信息 | "测试分支信息" | |

---

### 📁 内容整理

```mermaid
graph LR
    A[📁 organize-code-to-md<br/>整理代码] --> B[qbase/branch.md<br/>产出]
    C[🧪 organize-md-to-md<br/>生成文档] -.-> A
```

| Skill | 描述 | 触发场景 | 产出示例 |
|-------|------|----------|----------|
| [organize-code-to-md](./organize-code-to-md) | 整理代码目录结构 | "帮我理下有关 XXX" | [qbase/branch.md](https://github.com/dvlproad/qbase/blob/main/branch.md) |
| [organize-md-to-md](./organize-md-to-md) | 整理文档关系/生成图谱 | "整理文档关系" | |

---

### 💬 创意娱乐

```mermaid
graph LR
    A[💬 life-reply-crush<br/>回复] <--> B[🎮 life-emoji-idiom<br/>猜成语]
```

| Skill                                  | 描述                           | 触发场景     | 产出示例          |
| -------------------------------------- | ------------------------------ | ------------ | ----------------- |
| [life-reply-crush](./life-reply-crush) | 生成幽默撩人、有情绪张力的回复 | `crush: xxx` | crush: 今天忙啥呢 |
| [life-emoji-idiom](./life-emoji-idiom) | 根据emoji符号猜成语            | "猜成语"     | 🙄🐯🧧🏮              |





---

## 在 ChatGPT 等中使用

提示词如下：

**开头：复制文档标题之后内容**

**过渡**：

| Skill                        | 过渡                                               |
| ---------------------------- | -------------------------------------------------- |
| [crush-reply](./crush-reply) | 以后我输入 "crush: xxx" 的格式，你就直接生成回复。 |
| [emoji-idiom](./emoji-idiom) | 以后我说"猜成语"或发送emoji图片，你就帮我猜成语。 |

**结尾：明白请回复"明白"**



---

## 安装到 OpenCode

### 方式一：Plugin 方式（推荐）

参考：https://github.com/obra/superpowers

告诉 OpenCode：
```
Fetch and follow instructions from https://raw.githubusercontent.com/dvlproad/AI-qskills/refs/heads/main/.opencode/INSTALL.md
```

或者在 `opencode.json` 中添加：

```json
{
  "plugin": ["ai-qskills@git+https://github.com/dvlproad/AI-qskills.git"]
}
```

### 方式二：手动软链接（简单）

```bash
注意：原文件不能使用相对路径

# 克隆仓库后链接整个 AI-qskills 目录（使用绝对路径）
ln -s "/Users/用户名/Project/AI/AI-qskills" ~/.config/opencode/skills/ai-qskills

# 或者链接单个 skill
ln -s "/Users/用户名/Project/AI/AI-qskills/crush-reply" ~/.config/opencode/skills/crush-reply
```





---

## 开发新 Skill

1. 在 `AI-qskills/` 目录下创建新的 skill 文件夹
2. 文件夹内必须包含 `SKILL.md` 文件，格式如下：

```yaml
---
name: skill-name
description: |
  技能描述，说明什么时候触发这个技能
---

# 技能内容
```

3. 更新 `.opencode/plugins/ai-qskills.js` 中的 `skillsDir` 配置，确保新 skill 被加载
4. 更新 `.opencode/INSTALL.md` 中的 Available Skills 部分
5. 在本 README.md 的 Skills 表格中添加新 skill



## 版本记录

更多版本记录想看每个 SKILL 内部的版本记录

### 0.0.5 (2026-04-13)
- 新增 [skill-qian-optimize](./skill-qian-optimize) skill：优化和完善用户创建的 skill
- 修复 [script-to-homebrew](./script-to-homebrew) skill：修复AI执行skill中断问题，让AI可以按skill自动执行完整个流程

### 0.0.4 (2026-04-11)
- 新增 [script-specification](./script-specification) skill：帮助用户创建符合统一要求的脚本
- 新增 [script-to-homebrew](./script-to-homebrew) skill：将独立脚本整合到 qbase 库中

### 0.0.2 (2026-04-1)

- 新增 [crush-reply](./crush-reply) skill：生成幽默撩人、有情绪张力的回复，让对方笑、脸红、想继续聊
- 新增 [emoji-idiom](./emoji-idiom) skill：根据emoji符号猜成语，支持谐音法、象形法、组合法

