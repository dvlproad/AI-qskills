---
name: script-specification
description: |
  当用户输入"创建脚本"时触发，帮助用户创建符合统一要求的脚本
  触发场景：用户输入"创建脚本"
---

# 脚本开发规范

帮助用户创建符合统一要求的脚本



## 触发条件

用户输入"创建脚本"时触发


## 脚本结构顺序

脚本内容应按以下顺序编写：

1. shebang + 头部注释
2. 显示帮助信息 `show_help() `
3. 定义常量（颜色、命令等）

4. 获取脚本目录（如果需要）
5. 日志函数
6. 耗时操作提示
7. 主区域划分结构

## 脚本结构说明

### 划分说明

- 使用 `# --------------------- xxx ---------------------` 分隔不同功能区域
  - 日志函数（终端）之前的部分不需要
- 使用 `# ---------- xxx ----------` 细分 main 中的子区域

### 1、shebang + 头部注释

每个脚本必须包含以下头部信息：

```bash
#!/bin/bash

###
# @Author: dvlproad dvlproad@163.com
# @Date: YYYY-MM-DD HH:MM:SS
# @LastEditors: dvlproad
# @LastEditTime: YYYY-MM-DD HH:MM:SS
# @FilePath: <相对路径>
# @Description: <脚本功能描述>
# @Note: 简要说明或参考链接
###
```

示例：

| 类型  | 含义               | 值示例                                                       |
| ----- | ------------------ | ------------------------------------------------------------ |
| @Note | 简要说明或参考链接 | 检查更新原理见 [https://dvlproad.github.io/代码管理/库管理/homebrew](https://dvlproad.github.io/%E4%BB%A3%E7%A0%81%E7%AE%A1%E7%90%86/%E5%BA%93%E7%AE%A1%E7%90%86/homebrew) |

### 2、显示帮助信息 `show_help() `

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

### 3、定义常量（颜色、命令等）

- 颜色常量（用于在日志消息中高亮内容）

  ```bash
  NC="\033[0m"     # No Color 关闭颜色
  RED="\033[31m"   # 红色
  GREEN="\033[32m" # 绿色
  YELLOW="\033[33m" # 黄色
  BLUE="\033[34m"  # 蓝色
  PURPLE="\033[0;35m" # 紫色
  CYAN="\033[0;36m"  # 青色
  ```

- 命令常量

  | 场景             | 定义                  |
  | ---------------- | --------------------- |
  | 需要执行 json 时 | `JQ_EXEC=$(which jq)` |

### 4、获取脚本目录（如果需要）

获取脚本自身目录和项目根目录，用于调用同项目下的其他脚本：

```bash
# 获取脚本自身目录（$0 所在的目录）
CurrentDIR_Script_Absolute="$(cd "$(dirname "$0")" && pwd)"

# 获取项目根目录（脚本所在目录，即项目目录）
project_homedir_abspath="${CurrentDIR_Script_Absolute}"

# 如需获取上级目录，根据脚本所在层级使用一个或多个 %/* 来获取项目根目录
# 目的：避免路径中出现 ".."，防止某些场景下路径处理异常
# project_homedir_abspath="${CurrentDIR_Script_Absolute%/*}"        # 去除最后一级（如 script-qbase/package/ -> script-qbase）
# project_homedir_abspath="${CurrentDIR_Script_Absolute%/*/*}"     # 去除最后两级
```

**变量说明**：

| 变量                               | 说明             | 适用场景                                                     |
| ---------------------------------- | ---------------- | ------------------------------------------------------------ |
| `CurrentDIR_Script_Absolute`       | 脚本自身所在目录 | 当被执行的脚本和目标脚本同级时                               |
| `project_homedir_abspath`          | 项目根目录       | 当需要调用子目录下的脚本时（如 `package/xxx.sh`）            |
| `${CurrentDIR_Script_Absolute%/*}` | 上级目录         | 需要通过 %/* 获取上级目录时（脚本在子目录中，可多次使用获取项目根目录） |

**`%/*` 的作用**：

- 去除路径的最后一级目录
- 避免路径中出现 `..`（如 `../../`），导致某些场景下路径处理异常（如某些脚本或工具对包含 `..` 的路径兼容性差）

**使用场景**：当脚本需要调用同项目下的其他脚本时（如调用 `package/package_remote_version.sh`），先获取自身目录，再拼接目标脚本路径：

```bash
# 示例：调用项目下的 package_remote_version.sh
package_remote_version_script="${project_homedir_abspath}/package/package_remote_version.sh"
if [ ! -f "${package_remote_version_script}" ]; then
    echo "${RED}Error: 未找到 ${package_remote_version_script}${NC}"
    exit 1
fi
sh "${package_remote_version_script}" "$@"
```

*特殊，如果是qbase等这种后面会被放到bin下的，则不能使用上述方法。**

应该用 https://github.com/dvlpCI/script-qbase/blob/main/qbase.sh 里的如下代码：

```bash
# qbase.sh
...
qbase_homedir_abspath=$(getHomeDir_abspath_byVersion "${qbaseScript_allVersion_homedir}" "${qbase_latest_version}" "bin")
```

### 5、日志函数

#### 5.1 基础日志函数（必需）

```bash
# --------------------- 日志函数（终端） ---------------------
# 说明1：log_key()是公开的关键步骤
#	说明2：qian_log()是隐私的关键步骤，一般含底层命令

# 日志相关的初始变量
VERBOSE=false

# 日志函数（私有）
_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 终端输出（ERROR/WARN/KEY 级别有默认颜色，INFO 无默认颜色。消息内部可再用其他颜色高亮特定内容）
    case "$level" in
        ERROR)
            printf "${RED}[%s] [%s] %s${NC}\n" "$timestamp" "$level" "$message" >&2
            ;;
        WARN)
            printf "${YELLOW}[%s] [%s] %s${NC}\n" "$timestamp" "$level" "$message" >&2
            ;;
        KEY)
            printf "${GREEN}[%s] [%s] %s${NC}\n" "$timestamp" "$level" "$message" >&2
            ;;
        INFO)
            # INFO 只在 verbose 模式下显示
            if [ "$VERBOSE" = true ]; then
                printf "[%s] [%s] %s\n" "$timestamp" "$level" "$message" >&2
            fi
            ;;
    esac
}

log_error() { _log "ERROR" "$1"; }
log_warn() { _log "WARN" "$1"; }
log_info() { _log "INFO" "$1"; }
log_key() { _log "KEY" "$1"; }

# qian_log 函数
DEFINE_QIAN=false
function qian_log() {
    # 只有定义 --qian 的时候才打印这个log
    if [ "$DEFINE_QIAN" = true ]; then
        echo "$1" >&2   # 使用 echo 信息里的颜色才能正常显示出来
        # printf "%s\n" "$1" >&2
    fi
}
```

python 中

```python
# --------------------- 日志函数（终端） ---------------------
# 说明1：qian_log_func()是隐私的关键步骤，放在方法入口，代表进到某个方法，方便从日志中查看到哪了
#	说明2：qian_log()是隐私的关键步骤，一般含底层命令


#### ------ qian_log_func() ------ ####
import inspect
# 声明全局变量
DEFINE_QIAN = None
def qian_log_func(msg):
    """只有定义 --qian 的时候才打印这个log(带函数名)"""
    global DEFINE_QIAN
    if DEFINE_QIAN:  # 只有当用户传了 --qian 相关参数时才打印
        func_name = inspect.currentframe().f_back.f_code.co_name
        print(f"{PURPLE}>>>>>>>>>>>>【{func_name}】{msg} {NC}", file=sys.stderr)
```





#### 5.2 日志文件功能（可选）

如果需要日志文件功能，需要两处修改：

**第一处**：在变量定义处添加 `LOG_FILE=""`

**第二处**：在 `_log()` 中加入文件写入逻辑

```bash
# 日志相关的初始变量
VERBOSE=false
LOG_FILE=""

# 日志函数（私有）
_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 写入日志文件（所有级别，不带颜色）← 新增
    if [ -n "$LOG_FILE" ]; then
        printf "[%s] [%s] %s\n" "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi
    
    # 终端输出（同基础版）
    ...
}
```

**说明**：

- LOG_FILE 为可选功能，通过 `-l` / `--log-file` 参数指定
- 所有日志级别都会写入文件（不带颜色）

### 6、耗时操作提示

```bash
# --------------------- 耗时操作计时函数 ---------------------
# 耗时操作的相关初始变量
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
```

### 7、服务主区域的基础函数

#### 1.help



#### 2. 具名参数值的解析和获取函数

```bash
# --------------------- 具名参数值的解析和获取函数 ---------------------
# 获取具名参数的值（不允许以 - 开头）
# 用法：get_named_arg_value "$1" "$2" "参数名"
# 返回值：0=成功，1=参数缺失，2=参数为空，3=参数以-开头
# 输出：成功时输出参数值，失败时输出具体原因（不含 Error: 前缀）
get_named_arg_value() {
    local opt="$1"
    local val="$2"
    local arg_name="${3:-参数值}"
    
    # 条件1：没有第2个参数
    if [ $# -lt 2 ]; then
        printf "%s 缺少 %s" "$opt" "$arg_name"
        return 1
    fi
    
    # 条件2：第2个参数为空字符串
    if [ -z "$val" ]; then
        printf "%s 的 %s 为空字符串" "$opt" "$arg_name"
        return 2
    fi
    
    # 条件3：第2个参数以 - 开头（是选项）
    if [[ "$val" =~ ^- ]]; then
        printf "%s 的 %s 不能以 '-' 开头: %s" "$opt" "$arg_name" "$val"
        return 3
    fi
    
    # 正常情况：输出值，返回0
    printf "%s" "$val"
    return 0
}

# 获取具名参数的值（允许以 - 开头）
# 用法：get_named_arg_dashValue "$1" "$2" "参数名"
# 返回值：0=成功，1=参数缺失，2=参数为空
# 输出：成功时输出参数值，失败时输出具体原因（不含 Error: 前缀）
get_named_arg_dashValue() {
    local opt="$1"
    local val="$2"
    local arg_name="${3:-参数值}"
    
    # 条件1：没有第2个参数
    if [ $# -lt 2 ]; then
        printf "%s 缺少 %s" "$opt" "$arg_name"
        return 1
    fi
    
    # 条件2：第2个参数为空字符串
    if [ -z "$val" ]; then
        printf "%s 的 %s 为空字符串" "$opt" "$arg_name"
        return 2
    fi
    
    # 正常情况：输出值，返回0
    printf "%s" "$val"
    return 0
}

# 定义错误处理函数
handle_named_arg_error() {
    local option="$1"
    echo "${RED}Error: 您为参数${YELLOW} ${option} ${RED}指定了值，但该值不符合要求或为空，请检查是否在 ${option} 后提供了正确的值${NC}"
    exit 1
}
```

调用示例：

```bash
while [ "$#" -gt 0 ]; do
    case "$1" in
        -rebaseBranch|--rebase-branch)
            REBASE_BRANCH=$(get_named_arg_value "$1" "$2") || handle_named_arg_error "$1"
            shift 2;;
        -addValue|--add-value)
            ADD_VALUE=$(get_named_arg_dashValue "$1" "$2") || handle_named_arg_error "$1"
            shift 2;;
        -onlyName|--only-name)
            VALUE=$(get_named_arg_value "$1" "$2")
            if [ $? -eq 0 ] && [ "$VALUE" = "true" ]; then
                ONLY_NAME="true"
                shift 2
            else
                ONLY_NAME="false"
                shift
            fi
            ;; # ;; 必须放在分支的最后一条命令后面。前面有 if/else/for 所以需另起一行
    esac
done
```

**规则**

若干该脚本不需要使用 `get_named_dashArg_value` 则不用添加

### 8、主区域划分结构

#### 主区域划分结构

```bash
# --------------------- main 相关 ---------------------
# ---------- 1、初始化变量 ----------
PACKAGE_NAME=""

# ---------- 2、核心命令 ----------
do_update() { ... }

# ---------- 3.1、具名参数的解析、判断等 ----------
# 解析具名参数
while [[ $# -gt 0 ]]; do
    case $1 in
        ...
    esac
done

# 检查必需参数
...
# 检查可选参数
...
# 输出参数
...

# ---------- 3.2、业务逻辑 ----------
...

# ---------- 3.3、返回值 ----------
...
```

#### 通配符了解

```shell
#!/bin/bash

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --)
                echo "匹配 [--] : 选项结束标志"
                shift
                echo "  剩余参数都是位置参数: $@"
                break
                ;;
            -*)
                echo "匹配 [-*] : 选项参数 $1"
                shift
                ;;
            *)
                echo "匹配 [*] : 普通参数 $1"
                shift
                ;;
        esac
    done
}

# 测试
echo "=== 测试1 ==="
parse_args --verbose --file test.txt

echo -e "\n=== 测试2 ==="
parse_args --verbose -- --help test.txt

echo -e "\n=== 测试3 ==="
parse_args -v -f config.txt

echo -e "\n=== 测试4 ==="
parse_args --help --version
```

#### 1. 参数解析部分

1. 获取第几个参数，如获取 `firstArg=$1`，作为逻辑判断是走`-quick`还是`-path`

2. 过滤掉前几个参数

3. 循环判断剩余参数里是否包含指定参数，例如 `contains_verbose_in_allArgs`

4. 循环获取要传递给下个脚本的参数 `COMMON_FLAG_ARGS`，只允许传递不影响脚本逻辑的公共参数，不然传了后发现有些脚本只接收指定的参数会造成反而无法正常运行

5. 循环获取过滤掉指定参数的剩余参数，如过滤掉 `--version`，其他参数继续传给下个脚本，如传给 `-quick`

6. ？检查参数是否存在两个连续的`--`开头长参

   > 1. 如果当前参数以 - 或 -- 开头，且需要值（具名参数），则 shift 2
   > 2. 如果当前参数不以 - 或 -- 开头（位置参数），则 shift 1
   > 3. 如果当前参数是 -quick 或 -path 这类需要值的选项，则要获取下一个参数作为值

参考： [qtool.sh](https://github.com/dvlpCI/script-branch-json-file/blob/main/qtool.sh) 中的参数解析

附：py的参数解析参考

[qbase 的 dealScript_by_scriptConfig.py](https://github.com/dvlpCI/script-qbase/blob/main/pythonModuleSrc/dealScript_by_scriptConfig.py) 的参数解析 更完整

[qtool 的 dealScriptByCustomChoose.py](https://github.com/dvlpCI/script-branch-json-file/blob/main/src/dealScriptByCustomChoose.py) 的参数解析





```bash
# 使用数组保存参数，避免空格问题
# shift 1		#如果需要可以先通过 shift 过滤掉前几个参数
allArgsArray=("$@")


COMMON_FLAG_ARGS=() # 存储要传递给下个脚本的参数，只允许传递不影响脚本逻辑的公共参数，不然传了后发现有些脚本只接收指定的参数会造成反而无法正常运行

# 初始化标志
contains_help_in_allArgs=false
contains_verbose_in_allArgs=false
# 遍历数组
for arg in "${allArgsArray[@]}"; do
    # echo "正在处理参数: $arg"  # 打印每个参数
    
    case "$arg" in
        -qbase-local-path|--qbase-local-path)
            # 用户明确传递了此参数，必须提供有效值
            QBASE_CMD=$(get_named_arg_value "$1" "$2" "qbase路径") || handle_named_arg_error "$1"
            COMMON_FLAG_ARGS+=("$1" "$2")
            shift 2;;
        # 标志参数（不需要值的开关）
        --no-use-brew-path)
            isTestingScript=true    # qtool 里的其他脚本路径是否使用本地来拼接，而不是 brew 里的路径
            COMMON_FLAG_ARGS+=("$1")
            shift 1
            ;;
        --help|-help|-h|help)
            contains_help_in_allArgs=true
            COMMON_FLAG_ARGS+=("$arg")
            ;;
        --verbose|-verbose|-v)
            contains_verbose_in_allArgs=true
            COMMON_FLAG_ARGS+=("$arg")
            ;;
        --qian|-qian|-lichaoqian|-chaoqian)
            DEFINE_QIAN=true
            COMMON_FLAG_ARGS+=("$arg")
            ;;
        *)
            # echo "  -> 未匹配的普通参数: $arg"
            ;;
    esac
done
# 输出解析结果（调试用）
qian_log "========== 参数解析结果（$0） =========="
qian_log "QBASE_CMD: $QBASE_CMD"
qian_log "DEFINE_QIAN: $DEFINE_QIAN"
qian_log "CONTAINS_VERBOSE: $CONTAINS_VERBOSE"
qian_log "CONTAINS_HELP: $CONTAINS_HELP"
qian_log "公共参数（${#COMMON_FLAG_ARGS[@]}个）: ${COMMON_FLAG_ARGS[*]}"
qian_log "=================================="

# 剩余未解析到的参数（已解析的已被shift等）
POSITIONAL_ARGS=("$@")
```

附：如果是python

```python
import argparse
import sys

def print_custom_help():
    print(f"print_custom_help()")
    
def parse_arguments():
    # 先手动检查 help
    if '-h' in sys.argv or '--help' in sys.argv:
        print_custom_help()
        sys.exit(0)
    
    # 禁用自动 help，避免冲突
    parser = argparse.ArgumentParser(description='你的程序描述', add_help=False)
    
    parser.add_argument('--verbose', '-v', 
                       action='store_true',
                       help='显示详细信息')
    
    parser.add_argument('--qian', 
                       action='store_true',
                       help='开启打印调试log模式')
    
    parser.add_argument('--test', 
                       action='store_true',
                       help='开启本地测试模式')
    
    args = parser.parse_args()
    return args

# 声明全局变量
DEFINE_QIAN = None
def qian_log(msg):
    """只有定义 --qian 的时候才打印这个log"""
    global DEFINE_QIAN
    if DEFINE_QIAN:  # 只有当用户传了 --qian 相关参数时才打印
        print(msg, file=sys.stderr)

# 解析参数（所有参数都是可选的）
args = parse_arguments()
contains_verbose_in_allArgs = args.verbose  # 用户没传 --verbose 时是 False
DEFINE_QIAN = args.qian  # 用户没传 --qian 时是 False
'''
# 测试输出
if contains_verbose_in_allArgs:
    print("Verbose mode enabled")
'''
```







## 一、脚本要求(基础/公共)

### 1、日志要求

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

### 2、输出代码的要求

#### 2.1、命令输出（printf vs echo）

- **输出规则**：

  - 用 `printf "%s\n"` 而非 `echo`（更安全，可避免特殊字符问题）
  - 静态固定提示文本可用 `echo`
  - 禁止使用 `echo -e`

- **场景说明**：

  - **场景1：日志函数** → 用 `printf`，避免路径等含特殊字符的值输出异常

    ```bash
      log_error() { printf "%s\n" "$message" >&2; }
    ```

  - **场景2：变量输出：终端显示变量内容** → 用 `printf "%s"`，变量中的 `\n` 才能原样显示，而不是被显示成换行，导致看不到`\n`这个内容，丢失了这个信息

  - **场景3：变量输出：传递给 jq 的变量** → 用 `printf "%s"`，避免对含反斜杠 `\`的字段值（如文件路径 `"C:\Users\test"`），echo 会改变反斜杠，从而影响整个jsonString没法原样传递，而是被处理，导致传给 jq 后，jq 解析失败。

    ```bash
    # 推荐(printf 保持原样)
    printf "%s" "$jsonString" | jq "."  # 正常
    # 避免使用 echo(echo 会改变反斜杠)
    echo "$jsonString" | jq "."    # 可能解析失败
    ```

  - **场景4：固定提示文本** → 用 `echo`（确认是静态文字，如 "开始执行..."）

#### 2.2、日志输出（>&2 重定向）

日志输出使用 `>&2` 重定向，确保脚本返回值保持干净，不被日志污染：

```bash
# 推荐
printf "日志信息\n" >&2

# 日志函数
function debug_log() {
    printf "$1\n" >&2
}
```

**说明**：用 `>&2` 后，日志只显示在终端，不会传递给管道或被其他脚本获取。

**了解常识**：
不管是用 `echo` 还是 `printf` 输出脚本内容给其他脚本调用或管道使用，这些输出都会被传递下去，导致返回值不够干净。但**加上用 `>&2` 重定向后，这些信息就只会显示在终端，不会传递下去，这样脚本的返回值（JSON 等）就可以保持干净，不会被日志信息污染。

#### 2.3、输出信息（错误提示等）

当脚本执行失败时，应给出清晰的错误提示，帮助用户排查问题：

- **jq 执行失败的错误提示**：

```bash
iCatalogMap=$(printf "%s" "$categoryData" | jq -r ".[${i}]")
if [ $? != 0 ] || [ -z "${iCatalogMap}" ]; then
    echo "❌${RED}Error1:执行命令jq出错了，常见错误：您的内容文件中，有斜杠，但使用jq时候却没使用printf \"%s\"，而是使用echo。解决方法：【若允许修改源内容时，方法①去掉斜杠，方法②一个斜杠应该用四个斜杠标识】；【默认不允许修改源内容时，解决方法：使用printf \"%s\"】。请检查源内容>>>>>>>${NC}\n ${iCatalogMap} ${RED}\n<<<<<<<<<<<<<请检查以上内容。${NC} "
    exit 1
fi
```

### 3、contain代码的要求

#### 1、数组是常量(固定)，简单

如只判断是不是 --help|-help|-h|help 中的一个

```bash
# 判断第一个参数是不是 help 参数
shouldShowHelp=false
case "${firstArg}" in
    --help|-help|-h|help)
        shouldShowHelp=true
        exit 0  # 这行会退出脚本！
        ;;
esac
```

延伸：判断剩余参数中是不是有参数属于 help 数组

```bash
allArgsOrigin="$@"
# 是不是包含 help 参数
contains_help_in_allArgs=false
for arg in $allArgsOrigin; do
    case $arg in
        --help|-help|-h|help)
            contains_help_in_allArgs=true
            break
            ;;
    esac
done

# 是不是包含 verbose 参数
contains_verbose_in_allArgs=false
for arg in $allArgsOrigin; do
    case $arg in
        --verbose|-verbose|-v)
            contains_verbose_in_allArgs=true
            break
            ;;
    esac
done
```

#### 2、数组是变量(不确定)，通用

```bash
# 数组从外部获取，灵活可变
helpCmdStrings=$(cat config.json | jq -r '.help_params[]')

contains_help=false
for arg in $allArgsExceptFirstArg; do
    for help_arg in "${helpCmdStrings[@]}"; do  # 遍历数组，支持任意多个参数
        if [ "$arg" = "$help_arg" ]; then
            contains_help=true
            break 2
        fi
    done
done
```

应用实例：[dvlpCI/script-qbase 中的 qbase.sh](https://github.com/dvlpCI/script-qbase/blob/main/qbase.sh)



### 3、耗时操作提示

对于耗时操作（如网络请求、文件下载、编译等），应在执行过程中持续显示省略号，让用户感知操作正在进行中：

```bash
# 使用方式：
start_timer "提示信息"; <执行命令>; stop_timer

# 示例：
start_timer "正在获取版本"
REMOTE_VERSION=$(curl -s "$FORMULA_URL")
stop_timer
```

效果：`正在获取版本....` 每秒增加一个点

### 4、执行脚本前打印命令

在执行其他脚本之前，应先打印将要执行的完整命令，方便用户了解当前执行的操作：

```bash
# 示例：执行其他脚本前打印命令
printf "${YELLOW}正在执行命令(获取分支名)：《${BLUE} sh %s -rebaseBranch \"%s\" -addValue \"%s\" -onlyName \"%s\" ${YELLOW}》${NC}\n" \
    "${scriptPath}" "${REBASE_BRANCH}" "${add_value}" "${ONLY_NAME}"
result=$(sh "${scriptPath}" -rebaseBranch "${REBASE_BRANCH}" -addValue "${add_value}" -onlyName "${ONLY_NAME}")
```

**说明**：
- 使用 `${YELLOW}` 显示命令的整体开始/结束
- 使用 `${BLUE}` 高亮脚本路径和参数值
- 打印完成后，再执行实际的 `sh` 命令

### 5、特殊字符处理

示例：打印测试命令时候，遇到 requestBranchNames 换行了

```bash
    echo "${YELLOW}正在执行测试名(获取所有json):《${BLUE} sh \"$qbase_get_allBranchJson_inBranchNames_byJsonDir_scriptPath\" -requestBranchNames \"${requestBranchNames//$'\n'/ }\" -access-token \"${access_token}\" -oneOfDirUrl \"${ONE_OF_DIRECTORY_URL}\" -dirUrlBranchName \"${DIRECTORY_URL_BranchName}\" ${YELLOW}》${NC}"
```

参考：[dvlpCI/script-qbase 中 value_update_in_code 里的 example_update_text_variable.sh](https://github.com/dvlpCI/script-qbase/blob/main/value_update_in_code/example/example_update_text_variable.sh)

```bash
function updateText_test3() {
    
    WillUpdateText=$(
cat << 'EOF'
origin/main
origin/dev_in_pgyer
origin/feature/network_time
origin/test/test1
origin/test3
EOF
)
		HopeText_KongGe="origin/main origin/dev_in_pgyer origin/feature/network_time origin/test/test1 origin/test3"
		HopeText_N="origin/main\norigin/dev_in_pgyer\norigin/feature/network_time\norigin/test/test1\norigin/test3"
		
    echo "原始值:"
    echo "$WillUpdateText"
    
    echo "想要得到"

    echo "-------------3.1.①直接使用原始命令，直接输出(替换所有)"
    echo ">>>>>>>>>>>>>3.1.1"
    echo ${WillUpdateText//\\n/\\\\n}   		# ✅	\n	HopeText_KongN
    echo ">>>>>>>>>>>>>3.1.2"
    echo "${WillUpdateText//\\n/\\\\n}" 		# ❌ 换行了
    echo ">>>>>>>>>>>>>3.1.3"
    echo ${WillUpdateText//$'\n'/\\\\n} 		# ✅ \n	HopeText_KongN
    echo ${WillUpdateText//$'\n'/ }     		# ✅ 空格 HopeText_KongGe
    echo ">>>>>>>>>>>>>3.1.4"
    echo "${WillUpdateText//$'\n'/\\\\n}"   # ✅ \n 	HopeText_KongN
    echo "${WillUpdateText//$'\n'/ }"       # ✅ 空格 HopeText_KongGe
}
updateText_test3

```

### 6、返回值的代码要求(py)

背景：想要让方法里的错误信息，放到方法后的  if 才打印。但只要方法里有print肯定先打印，才打印方法后的。所以原则是方法里不 print

#### shell

```shell
getPath() {
    local type = $1
    if [ ! -f "$1" ]; then
        # 输出写法一：使用如下输出
        echo "😭文件不存在: $1"
        # 输出写法二：使用如下输出
        echo "$1"

        return 1
    fi

    echo "$1"
}
path=$(getPath "/some/file")
if [ $? != 0 ]; then
    printf "❌Error:目录不存在，请检查:%s\n" "${path}" >&2
    exit 1
fi


则失败时，输出写法一
❌Error:目录不存在，请检查:😭文件不存在: /some/file

输出写法2：
❌Error:目录不存在，请检查:/some/file
```



#### python

```python
		branch_json_file_dir_abspath = joinFullPath_checkExsit(base_dir_path, result_value)
    # print(f"branch_json_file_dir_abspath:{RED}{branch_json_file_dir_abspath} {NC}")
    if branch_json_file_dir_abspath == None:
        print(f"{RED}获取路径失败。获取{BLUE} {base_dir_path} {RED}相对路径{BLUE} {result_value} {RED}失败。请修改您在文件{BLUE} {json_file_path} {RED}中的 {hasFoundKeyPath.split('.')} {RED}字段值{NC}")
        return None
```

方法修正后的示例：

```python
def joinFullPath_checkExsit(host_dir, rel_path, createIfNoExsit=False):
    # 处理路径
    if host_dir.endswith("/"):
        host_dir = host_dir[:-1]
    if rel_path.startswith("/"):
        rel_path = rel_path[1:]
    full_path = os.path.join(host_dir, rel_path)
    full_abspath = os.path.abspath(full_path)
    
    if os.path.exists(full_abspath):
        return full_abspath, None  # 返回 (路径, 错误信息)
    else:
        if createIfNoExsit == True:
            try:
                os.makedirs(full_abspath, exist_ok=True)
                return full_abspath, None
            except Exception as e:
                return None, f"创建目录失败: {full_abspath}, 错误: {e}"
        else:
            return None, f"路径不存在: {full_abspath}"

# 调用方
dir_path, error_msg = joinFullPath_checkExsit(host_dir, rel_path, createIfNoExsit=False)
if error_msg:
    print(f"--------------------3 {error_msg}")
    print(f"--------------------4 {error_msg}")
else:
    print(f"路径有效: {dir_path}")
```





## 二、脚本要求(业务)

### 1、参数要求

- 必须使用具名参数（如 `-p`、`--package`）
- 支持短参数和长参数两种形式
- 参数解析使用 `while` + `case` 语句

### 2、执行要求

- 缺失必需参数时必须立即报错并退出
- 报错信息要明确告知缺少哪个参数
- 报错信息要提示使用 `--help` 查看帮助
- 遇到未知参数时也要报错退出

### 3、用户确认交互

当脚本需要用户确认某些操作（如确认更新、确认删除等）时，应：

- 使用 `while true` + `case` 循环，确保输入有效。输入无效时提示重新输入，直到输入有效。
- **无效应先判断空字符串**：先判断 `-z "${option}"`（输入为空），再判断其他有效条件
- 无效输入时提示重新输入，避免误操作跳过确认
- 输入有效后 `break` 退出循环

#### 输入场景

要根据不同输入场景，显示命令

- 正常输入：
  - 接受有效输入：`yes/y`（确认）、`no/n`（取消）
  - 接收退出输入：文案为 `（退出quit/q）`或`(退出请输入Q|q)`，在末尾
- 若是**请确认是否正确**的输入，则文案为 `[继续y/退出n]`，在末尾

#### 示例

```bash
if [ "${option}" == "q" ] || [ "${option}" == "Q" ]; then
    exit 2
elif [ -z "${option}" ]; then
    echo "输入不能为空，请重新输入。"
elif [ "${option}" -le "${count}" ]; then
    ...
```

**变量加双引号的原因**：避免空字符串导致 `[: -le: unary operator expected` 报错。

### 4、结果要求

- 能将脚本的执行结果固定的以json的格式输出给其他脚本使用

- JSON 必须包含 status 字段

- JSON 输出使用`heredocs`

  所谓heredocs，算是一种多行输入的方法，即在”<<”后定一个标识符，接着我们可以输入多行内容，直到再次遇到标识符为止。

  ```bash
  cat << EOF
  {
    "status": "$STATUS",
    "package": "$PACKAGE_NAME",
    "local_version": "${LOCAL_VERSION_ESCAPED:-null}",
    "remote_version": "$REMOTE_VERSION_ESCAPED",
    "has_update": $HAS_UPDATE,
    "tap_repo": "$TAP_REPO_ESCAPED"
  }
  EOF
  ```

  

## 一些文献

### 初次实践的示例文件

参考 [dvlpCI/script-qbase  中 package 里的 package_remote_version.sh](https://github.com/dvlpCI/script-qbase/blob/main/package/package_remote_version.sh)



## 版本记录

- 0.0.5 (2026-04-15): 新增执行脚本前打印命令的要求
- 0.0.4 (2026-04-14): 完善用户确认交互的退出机制
- 0.0.1 (2026-04-11): 初始版本

