---
name: script-create
description: |
  当用户输入"创建脚本"时触发，帮助用户创建符合统一要求的脚本
  触发场景：用户输入"创建脚本"
---

# 创建脚本

帮助用户创建符合统一要求的脚本



## 触发条件

用户输入"创建脚本"时触发



## 脚本要求

### 1、脚本标注格式

每个脚本必须包含以下头部信息：

```bash
###
# @Author: dvlproad dvlproad@163.com
# @Date: YYYY-MM-DD HH:MM:SS
# @LastEditors: dvlproad
# @LastEditTime: YYYY-MM-DD HH:MM:SS
# @FilePath: <相对路径>
# @Description: <脚本功能描述>
###
```

### 2. 帮助信息要求

帮助信息必须包含以下内容：

- **用法说明**：脚本的基本使用格式

- **必需参数**：列出所有必需参数及其说明

- **可选参数**：列出所有可选参数及其说明

- **核心命令**：告诉用户如果不使用此脚本，可以直接在终端执行哪些命令来达到相同效果

  - 格式："如果你不想使用此脚本，可以直接在终端执行以下命令来手动检查版本："

  - 列出具体的命令示例（如 curl、grep 等）

  - 核心命令示例

    ```markdown
    核心命令:
        如果你不想使用此脚本，可以直接在终端执行以下命令来手动检查版本：
        
        1. 优先从 version 字段获取版本号：
           curl -s https://raw.githubusercontent.com/<tap_repo>/main/<package>.rb | grep -E '^[[:space:]]*version' | head -1 | sed -E 's/.*"(.*)".*/\1/'
        
        2. 如果 version 字段不存在，则从 url 字段提取版本号：
           curl -s https://raw.githubusercontent.com/<tap_repo>/main/<package>.rb | grep 'url' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
    ```

- **输出格式**：说明 JSON 输出的字段含义

- **退出码**：说明不同退出码的含义

- **日志说明**：说明日志级别和显示规则

- **示例**：提供至少 3 个使用示例

### 3、参数要求

- 必须使用具名参数（如 `-p`、`--package`）
- 支持短参数和长参数两种形式
- 参数解析使用 `while` + `case` 语句

### 4、执行要求

- 缺失必需参数时必须立即报错并退出
- 报错信息要明确告知缺少哪个参数
- 报错信息要提示使用 `--help` 查看帮助
- 遇到未知参数时也要报错退出

### 5、结果要求

- 能将脚本的执行结果固定的以json的格式输出给其他脚本使用
- JSON 必须包含 status 字段

### 6、日志要求

- 日志信息有终端显示和日志文件两种方式，日志等级有INFO/WARN/ERROR/KEY四种

- **在终端显示时候**
  - INFO信息：有"verbose" "-v" "--verbose"的时候才显示，无默认颜色
  - WARN信息：黄色，总显示
  - ERROR信息：红色，总显示，消息内部可再用其他颜色（如${BLUE}）高亮特定内容
  - KEY信息：关键信息（如操作开始、最终结果），绿色，总显示
  - 示例：
    ```bash
    log_error "从 ${BLUE}${CONTENTS_JSON_FILE_PATH}${NC} 中获取 ${BLUE}.${CONTENTS_JSON_KEY}${NC} 失败"
    ```

- **日志文件**：
  - 为可选的具名参数 `-l` `-log-file`
  - 所有等级信息都显示
  
- **定义**：
  
  每个脚本都要定义颜色常量（用于在日志消息中高亮内容）
  
  ```bash
  NC="\033[0m"     # No Color 关闭颜色
  RED="\033[31m"   # 红色
  GREEN="\033[32m" # 绿色
  YELLOW="\033[33m" # 黄色
  BLUE="\033[34m"  # 蓝色
  PURPLE="\033[0;35m" # 紫色
  CYAN="\033[0;36m"  # 青色
  ```
  
  如果需要执行json的，则定义
  
  ```bash
  JQ_EXEC=$(which jq)
  ```

### 7、代码要求

- 尽量不在 `log` 开头的方法（如 `log_info`、`log_error`、`log_warn`）之外的其他地方使用 `echo` 或 `printf` ，除非是需要颜色，如

  ```bash
  echo "${RED}缺少 -contentJsonKey 参数，要contents来源于文件的哪个key不能为空.${NC}\n"
  ```

- **禁止使用 echo -e**

### 8、耗时操作提示

对于耗时操作（如网络请求、文件下载、编译等），应在执行过程中持续显示省略号，让用户感知操作正在进行中：

```bash
# 初始化变量时添加
TIMER_PID=""

# Ctrl+C 中断处理
trap 'cleanup_timer; exit 130' INT

# 定义耗时操作计时函数
start_timer() {
    TIMER_MSG="${1:-执行中}"
    printf "  %s" "$TIMER_MSG" >&2
    (
        while true; do
            printf "." >&2
            sleep 1
        done
    ) &
    TIMER_PID=$!
}

stop_timer() {
    if [ -n "$TIMER_PID" ]; then
        kill $TIMER_PID 2>/dev/null
        wait $TIMER_PID 2>/dev/null
    fi
    printf " 完成\n" >&2
}

cleanup_timer() {
    if [ -n "$TIMER_PID" ]; then
        kill $TIMER_PID 2>/dev/null
        wait $TIMER_PID 2>/dev/null
    fi
}

# 使用方式
start_timer "正在获取版本"
REMOTE_VERSION=$(curl -s "$FORMULA_URL")
stop_timer
```

效果：`正在获取版本....` 每秒增加一个点