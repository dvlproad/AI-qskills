---
name: opencode-sessions-manager
description: |
  交互式 opencode 会话选择器 - 分页浏览恢复历史会话
  触发场景：
  - 用户输入"配置opencode会话管理"
  - 用户说"帮我设置 opencode 的会话恢复功能"
  - 用户在新机器上要配置会话选择器
---

# Opencode 会话选择器

交互式会话选择器：打开终端输入 `opencode_list` 即可分页浏览历史会话并选择恢复。不覆盖原生命令，`opencode` 行为不受影响。

## 触发条件

用户需要配置 opencode 会话自动记录和恢复功能时触发：
- "配置opencode会话管理"
- "帮我设置 opencode 的会话恢复功能"
- 新机器上需要配置 opencode 会话管理

## 安装步骤

### 1. 复制脚本文件

脚本位于 [`scripts/oc.sh`](scripts/oc.sh)，复制到 `~/.config/opencode/`：

```bash
mkdir -p ~/.config/opencode
cp scripts/oc.sh ~/.config/opencode/source_opencode.sh
```

> **平台说明**：macOS（Intel/M 芯片）和统信 UOS 均适用。如使用 bash，将 `~/.zshrc` 替换为 `~/.bashrc`。

### 2. 添加到 shell 配置

根据使用的 shell，在对应配置文件的末尾追加：

| Shell | 配置文件 |
|-------|----------|
| zsh（macOS / UOS 默认） | `~/.zshrc` |
| bash | `~/.bashrc` |

```zsh
source ~/.config/opencode/source_opencode.sh
```

### 3. 生效

```bash
source ~/.zshrc    # zsh
# source ~/.bashrc  # bash（如使用 bash）
```

## 使用说明

| 命令 | 效果 |
|------|------|
| `opencode_list` | 弹会话列表（显示项目名、标题、首条/倒二/末条用户输入），最新会话在最底部，1 号位离输入框最近 |
| `opencode web` | 原样透传 |
| `opencode -s ses_xxx` | 原样透传 |
| `opencode --help` | 原样透传 |

## 依赖

- **sqlite3**：macOS 自带；统信 UOS 需 `sudo apt install sqlite3`

## 卸载步骤

1. 删除脚本文件：`rm ~/.config/opencode/source_opencode.sh`
2. 从 `.zshrc`（或 `.bashrc`）中移除 `source ~/.config/opencode/source_opencode.sh` 行
3. 重新加载：`source ~/.zshrc`（或 `source ~/.bashrc`）

## 版本记录

### 0.0.1 (2026-05-18): 初始版本
