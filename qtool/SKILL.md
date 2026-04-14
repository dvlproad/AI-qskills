---
name: qtool
description: 操作 CQCI 工具集（script-branch-json-file），用于分支管理、代码提交、打包上传等
---

# Skill: qtool

当用户输入包含 "qtool" 的指令时触发，用于操作 CQCI 工具集（script-branch-json-file）。

## 触发条件

用户输入以下内容时激活：
- `qtool创建分支` - 创建 Git 分支
- `qtool创建分支信息` - 创建分支JSON文件
- `qtool更新分支信息` - 更新分支JSON文件
- `qtool提交代码` - 规范化Git提交
- `qtool上传` - 上传到蒲公英等平台
- `qtool帮助` - 显示帮助
- 其他包含 "qtool" 的指令

## 执行流程

### 1. 获取配置文件路径
- 优先使用环境变量 `QTOOL_DEAL_PROJECT_PARAMS_FILE_PATH` 的值
- 如环境变量未设置，提示用户输入 tool_params.json 路径

### 2. 解析用户指令
- 根据关键词匹配对应的操作

### 3. 显示命令预览（重要！）
- 显示完整的命令供用户确认
- **不要使用 `<<<` 或管道模拟输入**，这些脚本需要用户交互输入
- 示例：
  ```
  即将执行命令：
  QTOOL_DEAL_PROJECT_PARAMS_FILE_PATH=/path/to/tool_input.json sh /Users/lichaoqian/Project/CQCI/script-branch-json-file/src/branchGit_create.sh
  
  该命令会进入交互式菜单，需要您手动选择和输入。
  是否确认执行？(y/n)
  ```

### 4. 用户确认后执行
- 用户确认 `y` 后才执行命令
- **让用户自己进行交互输入**，不要模拟输入
- 显示执行结果

### 5. 注意事项
- **禁止模拟用户输入**：不要用 `<<<` 或 `-y` 等方式跳过用户交互
- **保持交互**：脚本需要用户选择和输入，这是正常行为，等待用户完成
- 如果需要非交互执行，应该由用户自己在终端操作

## 支持的命令

### 分支管理

| 指令 | 说明 | 命令 |
|------|------|------|
| qtool创建分支 | 创建 Git 分支 | `QTOOL_DEAL_PROJECT_PARAMS_FILE_PATH={PARAMS_FILE} sh {SCRIPT_DIR}/src/branchGit_create.sh` |
| qtool创建分支信息 | 创建分支JSON文件 | `python3 {SCRIPT_DIR}/src/branchJsonFile_create.py -tool_params_file_path {PARAMS_FILE}` |
| qtool更新分支信息 | 更新分支JSON文件 | `python3 {SCRIPT_DIR}/src/branchJsonFile_update.py -tool_params_file_path {PARAMS_FILE}` |

### 代码提交

| 指令 | 说明 | 命令 |
|------|------|------|
| qtool提交代码 | 规范化Git提交 | `qtool cz` |

### 打包上传

| 指令 | 说明 | 命令 |
|------|------|------|
| qtool上传 | 上传到蒲公英等平台 | `sh {SCRIPT_DIR}/upload/upload_to_all_byArgFile.sh -tool_params_file_path {PARAMS_FILE}` |
| qtool签名Apk | 为加固后的apk签名 | `qtool` (进入菜单选择 signApk) |
| qtool上传dSYM | 上传符号表 | `qtool` (进入菜单选择 uploadDSYM) |

### 其他

| 指令 | 说明 | 命令 |
|------|------|------|
| qtool帮助 | 显示帮助 | `qtool -help` |

## 配置说明

### 脚本路径
`{SCRIPT_DIR}` = `/Users/lichaoqian/Project/CQCI/script-branch-json-file`

### 环境变量
```bash
export QTOOL_DEAL_PROJECT_PARAMS_FILE_PATH=/path/to/your/tool_params.json
```

### 参数文件获取方式
- 优先使用环境变量 `QTOOL_DEAL_PROJECT_PARAMS_FILE_PATH` 的值
- 如环境变量未设置，提示用户输入 tool_params.json 路径

### 配置文件格式
参考 `script-branch-json-file/test/tool_input.json`，需包含：
- `project_path.home_path_rel_this_dir` - 项目根目录相对路径
- `branchJsonFile.BRANCH_JSON_FILE_DIR_RELATIVE_PATH` - 分支JSON文件目录
- `personnel_file_path` - 人员配置文件路径

## 执行目录

脚本需要在目标项目的 Git 仓库目录下执行（用于获取当前分支信息）。

## 常用操作速查

```bash
# 创建 Git 分支
qtool创建分支

# 创建分支信息
qtool创建分支信息

# 更新分支信息
qtool更新分支信息

# 提交代码
qtool提交代码  # 或 qtool cz

# 上传应用
qtool上传
```

## 版本记录

### 0.0.1 (2026-04-14): 初始版本
