# qtool GUI 安装包 — 需求、方案与构建

## 1. 背景

### 1.1. qtool 是什么

qtool 是一个命令行工具集，功能包括：
- **分支管理**：分支的检查（打包使用的分支名、必须包含的分支、相对上次缺失的分支）
- **环境变量配置**：交互式菜单设置项目配置、环境变量表
- **打包上传**：上传到 pgyer、COS、TestFlight 等平台

当前交互方式：**终端菜单**（`qtool` 回车后显示选项列表，数字选择后执行）。

### 1.2. 当前分发方式（Homebrew）

用户通过 Homebrew tap 安装：
```bash
brew tap dvlpci/qtool
brew install qtool
```

依赖 `qbase` 基础库（也通过 Homebrew 安装）。

### 1.3. 为什么需要 GUI

| 问题 | 说明 |
|------|------|
| 终端门槛高 | 非开发者或不熟悉命令行的同事难以使用 |
| 安装链长 | 需先装 Homebrew → 装 qbase → 装 qtool |
| 体验原始 | 终端菜单无图形反馈、无进度条、无可视化选择 |

### 1.4. 用户场景

- 测试/QA 同事：选择项目和分支后打包上传
- 开发同学：快速切换项目配置、检查分支
- 日常使用：环境变量管理、菜单式操作

---

## 2. 核心需求

### 2.1. 功能性

- ✅ **覆盖现有 qtool 所有功能**：分支检查、环境变量配置、打包上传等
- ✅ **后端复用现有 shell 脚本**：不改一行 `.sh`，GUI 层只做调用和展示
- ✅ **菜单树动态渲染**：从 `qtool_menu_public.json` 读菜单结构，加新 entry 自动更新

### 2.2. 分发与安装

- ✅ **.app 形式**：双击打开即用
- ✅ **零 Homebrew 依赖或首次引导**：用户不需要提前安装 Homebrew、qbase、qtool
- ✅ **macOS 原生**（跨平台暂不需要）

### 2.3. 非需求（明确不做）

- ❌ 不重写现有 shell 脚本逻辑
- ❌ 不需要复杂的动画或设计系统
- ❌ 不需要跨平台（仅 macOS）
- ❌ 不需要云端同步或用户系统
- ❌ 不嵌入 PTY/伪终端（避免 CPU 开销，见 §6.3）

---

## 3. 架构决策

### 3.1. 最终方案（方案 C2 → 方案 A）

**方案 C2：混合模式 — 首次引导 + wrapper 自动执行**

| 方案 | 描述 | 结论 |
|------|------|------|
| A：全打包进 .app | 所有脚本拷入 `.app/Contents/Resources/` | ❌ 脚本明文可被右键"显示包内容"看到 |
| B：纯 GUI 依赖 Homebrew | .app 只负责展示菜单 + 启动 Terminal，用户自行 `brew install qtool` | ❌ GUI 沦为"启动器说明书"，用户要点两次 |
| **C2/A：wrapper 自动执行 + Homebrew** | **.app 放 30 行 wrapper 脚本，业务脚本仍在 Homebrew；点击菜单项 → 弹 Terminal 自动执行 action** | ✅ 最佳平衡 |

**理由**：
1. 脚本放 Homebrew 比放 .app "隐蔽"（/opt/homebrew/Cellar/ 不是桌面可见文件）
2. Wrapper 仅 30 行，不暴露业务代码
3. GUI 点一次就执行，终端只看结果
4. 有子菜单的 action 继承 Terminal 的 stdin/stdout，交互正常

### 3.2. 实现语言

**Swift 原生** ← 已确认

理由：
- 单文件编译，双击即用，无需运行时
- 包体 ~200KB（不捆绑脚本时），较小
- 原生 macOS 窗口控件
- `Process()` + `NSWorkspace` 调脚本和 Terminal

### 3.3. 零修改原则

> **GUI 不修改现有 `.sh` 文件一行代码。**
> wrapper 脚本（`qtool_run_action.sh`）用 `awk` 在运行时剥离 `showMenu` 和 `exit` 两行，不修改源文件。
> 所有业务逻辑仍在 Homebrew 安装的 `qtool_menu.sh` 中。

### 3.4. 路径检测逻辑

```swift
// 查找 qtool_menu_public.json 的优先级：
1. 二进制所在目录（开发模式：gui/）
2. 二进制所在目录的父目录（开发模式：repo 根）
3. brew --prefix qtool/lib/（生产模式：Homebrew lib 目录）
```

```swift
// 查找 qtool_run_action.sh 的优先级：
1. basePath/gui/name（开发模式）
2. basePath/name
3. basePath/../Resources/name（.app 包内 Resources）
4. binDir/../Resources/name（二进制同包 Resources 兜底）
```

---

## 4. 工程结构

### 4.1. 仓库文件

```
script-branch-json-file/
├── gui/
│   ├── main.swift              # SwiftUI 源码（git 跟踪）
│   ├── qtool_run_action.sh     # wrapper 脚本（git 跟踪）
│   ├── build.sh                # 一键构建脚本（git 跟踪）
│   ├── .gitignore              # 排除 Qtool + Qtool.app
│   ├── Qtool                   # 编译产物（忽略）
│   └── Qtool.app               # 打包产物（忽略）
├── qtool_menu_public.json      # 菜单结构（GUI 读取）
├── qtool_menu.sh               # 所有 action 函数定义（不被修改）
├── src/                        # Python 子脚本
├── dsym/                       # 符号表上传
├── rebase/                     # rebase 检查
└── ...
```

### 4.2. 打包后 .app 结构

```
Qtool.app/Contents/
├── MacOS/
│   └── Qtool                  # Swift 编译的二进制
├── Resources/
│   └── qtool_run_action.sh    # wrapper 脚本（仅 30 行）
└── Info.plist
```

注意：**不含任何业务脚本**，所有脚本在 Homebrew Cellar 中。

### 4.3. 一键构建

```bash
sh gui/build.sh
```

脚本功能：编译 `main.swift` → 生成 `gui/Qtool` binary → 组装 `gui/Qtool.app`（含 Info.plist 和 wrapper）。

### 4.4. 使用方式

**发给别人只需要 `Qtool.app`**，对方需已通过 Homebrew 安装 qtool：
```bash
brew install qbase/qbase/qtool
```

使用：
- 双击 `Qtool.app` 打开图形菜单
- 点击任意菜单项 → 自动弹出 Terminal 执行对应 action
- 执行完后 Terminal 显示结果，按 `Cmd+W` 关闭窗口
- 再次点击同一项可重新执行

### 4.5. 文件说明

| 文件 | 用途 |
|------|------|
| `gui/main.swift` | SwiftUI 源码，编译入口 |
| `gui/qtool_run_action.sh` | wrapper 脚本（30 行），剥离菜单、执行 action |
| `gui/build.sh` | 一键构建脚本：编译 binary → 组装 .app |
| `gui/.gitignore` | 排除 `Qtool` 和 `Qtool.app` |
| `gui/Qtool` | 编译产物（binary），忽略 |
| `gui/Qtool.app` | 可分发的 .app 包，忽略 |

---

## 5. wrapper 方案详情

### 5.1. 流程

```
用户点击菜单项
  → SwiftUI selectionBinding setter
    → openInTerminal()
      → 创建临时 .command 文件
        → NSWorkspace.shared.open() 在 Terminal.app 中执行
          → wrapper qtool_run_action.sh <basePath> <actionName>
            → awk 剥离 qtool_menu.sh 的 showMenu + exit 行（478-482）
            → source 剥离后的版本（定义所有函数）
            → eval "$actionName" 执行选中的 action
            → 执行完毕 → 显示结果 → exit 0
              → Shell 退出 → "Process completed"
              → 用户手动 Cmd+W 关窗
```

### 5.2. Wrapper 剥离逻辑

`qtool_menu.sh` 末尾（第 478-482 行）：
```bash
showMenu "..."    # 交互菜单
exit 0            # 退出
```

用 `awk 'NR<=477'` 去掉这两行，保留所有函数定义。

### 5.3. 交互式子菜单支持

Terminal.app 提供完整 PTY，子进程/孙进程继承 stdin/stdout。Action 中：
- 调用 `read -p` → 用户输入 → 正常工作
- 调用 `python3 xxx.py`（内嵌 `input()`）→ 正常工作
- 调用子脚本的子脚本 → 正常工作

---

## 6. 原型演进记录

| 版本 | 方案 | 结果 |
|------|------|------|
| 原型 1 | AppKit NSWindow + NSTableView | 能跑但丑 |
| 原型 2 | SwiftUI 读 `qtool.json` | 菜单不符，与终端体验不一致 |
| 原型 3 | SwiftUI 读 `qtool_menu_public.json` | 菜单正确，但 action 无法执行 |
| 原型 4 | PTY 内嵌终端 | 20+ 残留进程 CPU 风扇狂转 ❌ |
| 原型 5 | Terminal-launcher（按钮触发） | 需用户点两次 |
| **当前** | **wrapper 自动执行** | ✅ 一次点击直接执行 |

### 6.1. PTY 原型教训

PTY 实现导致每次点击产生 3-4 个 `qtool_menu.sh` 进程，累计 20+，每个 ~5-6% CPU → 风扇满载。如果用 PTY，必须确保 `pkill -f "qtool_menu.sh"` 清理。

### 6.2. Terminal 自动关窗不可行

macOS Terminal 安全性限制：**无法通过 AppleScript 在没有确认框的情况下关闭有运行进程的窗口**。

尝试过的方法均不可靠：
- `shellExitAction = 0/1` — 不生效
- `exec osascript close front window` — 弹出确认框
- `nohup` 延迟关窗 — 弹出确认框
- 外部 AppleScript 设定 — 不生效

结论：用户手动 `Cmd+W` 关窗，不做自动关闭。

### 6.3. AppleScript 引号陷阱

`osascript` 中：
- `&&` 在 AppleScript 字符串内 **不被解释为 shell 运算符**（与常见直觉相反）
- 单引号 `'...'` 在 AppleScript 中不表示字符串字面量（AppleScript 用 `"..."` 表示字符串）
- 正确做法：用 `.command` 文件 + `NSWorkspace.shared.open()` 绕过 AppleScript

### 6.4. Swift 版本

编译器：swiftc (swiftlang-6.3.2.1.108)
当前无 Package.swift，单文件编译。

---

## 7. 待办

### 7.1. 首次引导

检测 `which qtool` → 没有则弹窗显示安装命令：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install qbase/qbase/qtool
```

### 7.2. Code Signing

- ❌ 不签名：首次打开需右键 → 打开
- ✅ 签名 $99/年 Apple Developer：无警告

### 7.3. 分发

- GitHub Releases

### 7.4. 更新机制

- 手动下载替换 / 应用内检查更新

---

## 8. 版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1.0 | 2026-05-18 | wrapper 方案定型，Desktop .app 测试通过 |
| 0.1.1 | 2026-05-18 | 修复同一项重复点击、文档更新、代码提交 |

## 9. 相关仓库

- qtool：`https://github.com/dvlpCI/script-branch-json-file`
- qbase：`https://github.com/dvlpCI/script-qbase`
- Homebrew tap：`https://github.com/dvlpCI/homebrew-qtool`
