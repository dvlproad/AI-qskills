---
name: script-to-qbase
description: |
  将独立脚本整合到 qbase 库中，统一使用 qbase -quick 调用
  触发场景：用户输入"将脚本整合/添加到qbase"
---

# 将脚本整合到 qbase 库

帮助用户将独立脚本整合到 qbase 库中，统一调用方式。



## 触发条件

用户输入"将脚本整合/添加到qbase"时触发



## 核心目标

将所有脚本调用方式统一为：
```bash
qbase -quick 脚本关键字 [具名参数/参数...]
```

而不是：
- `sh xxx.sh 具名参数/参数`
- `sh ${path}/qbase.sh -quick 脚本关键字 具名参数/参数`

## 好处

### 1. 关键字（key）的好处
- **与文件名解耦**：脚本关键字是 `qbase.json` 中的 `key`，与脚本文件名无关。**即使脚本文件名变更，只要 `key` 不变，调用就不受影响**
- **统一调用方式**：从 `sh xxx.sh` 改为 `sh ${path}/qbase.sh -quick 脚本关键字`，规范化管理

### 2. qbase 加密二进制文件统一调用的好处
- **初步统一入口**：所有脚本都通过 `${path}/qbase`调用，便于管理和维护
- **初简化调用**：从 `sh ${path}/qbase.sh -quick 脚本关键字` 简化为 `${path}/qbase -quick 脚本关键字`

### 3. qbase Homebrew 包的好处
- **最终统一入口**：所有脚本都通过 `qbase`调用，便于管理和维护
- **极简化调用**：从 `${path}/qbase -quick 脚本关键字` 简化为 `qbase -quick 脚本关键字`




## 整合步骤

### 步骤1：在 qbase.json 中添加配置

在 `support_script_path` 数组中添加：

```json
{
    "type": "package",  // 选择合适的类型
    "des": "脚本分类描述",
    "values": [
        {
            "key": "脚本关键字",
            "des": "脚本功能描述",
            "rel_path": "./package/xxx.sh",
            "example": "qbase -quick 脚本关键字 -参数 值"
        }
    ]
}
```

**效果**：添加后即可以通过 `sh ${path}/qbase.sh -quick 脚本关键字 [具名参数/参数...]` 调用脚本。

示例：将 `package_remote_version.sh` 整合到 qbase

> **qbase.json 添加配置**：
>
> ```json
> {
>     "key": "package_remote_version",
>     "des": "检查/更新 Homebrew 包的远程版本",
>     "rel_path": "./package/package_remote_version.sh",
>     "example": "qbase -quick package_remote_version -p qbase -v -l ./check.log"
> }
> ```
>

### 步骤2：重新编译 qbase（使用 shc）

运行 `${path}/qbase重新生成.sh`（内部使用 `shc` 将 shell 脚本转换为二进制文件）。

**效果**：生成后即可通过 `${path}/qbase -quick 脚本关键字 [具名参数/参数...]` 调用脚本。

**注意**：此步骤需要 AI 执行，AI 会运行：
```bash
cd ${path} && sh qbase重新生成.sh
```

### 步骤3：提交代码并发布

此步骤由 AI 自动执行：

**1. 提交修改后的 `qbase.json` 和 二进制文件 `qbase` 到脚本仓库**：

```bash
# 只提交步骤一(qbase.json)和步骤二(qbase二进制)生成的文件
git add qbase.json qbase
git commit -m "【Update】添加脚本配置并升级 qbase 二进制"

# 推送到远程
git push
```

**2. 创建版本标签并推送到远程**：

标签需由用户输入，不能自己指定。

```bash
# 创建标签（版本号由用户提供）
git tag -a {版本号} -m "版本 {版本号}"

# 推送标签
git push origin {版本号}
```

**3. 准备 rb 更新所需信息（tar.gz 的 url 和 sha256）**：

```bash
# 下载 tar.gz 并计算 sha256
curl -sL https://github.com/dvlpCI/script-qbase/archive/{tag}.tar.gz -o /tmp/script-qbase-{tag}.tar.gz
shasum -a 256 /tmp/script-qbase-{tag}.tar.gz
```

**4. 更新 homebrew 仓库**：
- 更新 qbase.rb 中的 version 和 sha256
- 将更新的 qbase.rb 提交并推送

### 步骤4：安装、更新和使用

完成后提示用户：

```bash
# 步骤1. 刷新 Tap 索引（检测新版本）
# 方法一：刷新所有 tap
brew update
# 方法二：只刷新 qbase tap（更快）
cd "$(brew --repository)/Library/Taps/dvlpci/homebrew-qbase" && git pull

# 步骤2. 升级 qbase
brew upgrade qbase

# 步骤3. 验证安装
qbase -quick 脚本关键字 --help
```

《安装和更新命令的**更多介绍》**见：[https://dvlproad.github.io/代码管理/库管理/homebrew](https://dvlproad.github.io/%E4%BB%A3%E7%A0%81%E7%AE%A1%E7%90%86/%E5%BA%93%E7%AE%A1%E7%90%86/homebrew) 中 【安装和更新命令的**更多介绍】**



#### 4.1、安装

```bash
# 先添加 qbase.rb 所在的 Tap 包(dvlpCI/qbase)
brew tap dvlpCI/qbase

# 添加 Tap 后，可以简化命令（省略 dvlpCI/qbase/ 前缀）
brew install qbase
或
brew install dvlpCI/qbase/qbase
```

#### 4.2、更新

```bash
# 步骤1. 刷新索引（知道有哪些新版本）
# 方法一：通过 brew update,刷新所有 tap 的索引
brew update
# 方法二：不通过 brew update,只更新这一个 tap 而不更新其他。这样比 brew update（更新所有 tap）快很多。
cd "$(brew --repository)/Library/Taps/dvlpci/homebrew-qbase" && git pull

# 步骤2. 升级指定包（按刷新后的最新版本升级）
brew upgrade qbase
```

#### 4.3、使用

```bash
qbase -quick 脚本关键字 [具名参数/参数...]
```

示例：

> ```bash
> qbase -quick check_remote_version -a check -p qbase -v
> ```
>



## 附录

<a name="以 qhelloworld 为例的完整 Homebrew Tap 创建流程"></a>

## 附录一、以 qhelloworld 为例的完整 Homebrew Tap 创建流程

### 1. 脚本仓库(script-qbase)

1.1. 创建脚本仓库（如 `https://github.com/dvlpCI/script-qbase.git`）

1.2. 在仓库中添加脚本文件（如 `qhelloworld.sh`），编写脚本代码

1.3. 编译为加密的二进制文件：

   ```bash
shc -r -f ${path}/qhelloworld.sh
   ```

   - 将生成的二进制可执行文件 `qhelloworld.sh.x` 重命名为 `qhelloworld`(以便后续能够使用qhelloworld，而不是还要输qhelloworld.sh或者qhelloworld.sh.x)"

[https://dvlproad.github.io/Script/Shell/Shell高级加密可执行](https://dvlproad.github.io/Script/Shell/Shell%E9%AB%98%E7%BA%A7%E5%8A%A0%E5%AF%86%E5%8F%AF%E6%89%A7%E8%A1%8C/)

1.4. 提交代码并打标签tag到远程（如 `qhelloworld-0.0.1`），发布后 GitHub 会自动生成 tar.gz 包

1.5. 获取刚才打的tag的 tar.gz 的 url 地址，并下载。

 tar.gz 链接：如刚才打的tag是 `qhelloworld-0.0.1`，则链接为（**推荐**）

https://github.com/dvlpCI/script-qbase/archive/qhelloworld-0.0.1.tar.gz 

你可以直接在浏览器里输入后按回车来下载该文件"

你也可以通过一下方式，获取到链接为（不推荐）：

https://github.com/dvlpCI/script-qbase/archive/refs/tags/qhelloworld-0.0.1.tar.gz

<img src="resources/tag_tar_gz.png" alt="tag下的tar_gz包" style="zoom: 33%;" />

1.6. 计算该包的 sha256：

   ```bash
shasum -a 256 ${path}/script-qbase-qhelloworld-0.0.1.tar.gz
   ```

### 2. Homebrew 仓库(homebrew-qbase)

2.1. 创建 homebrew tap 仓库，用于存放各种 `.rb` 文件，仓库必须已 `homebrew-` 开头，后缀名一般用你最后想要被使用比较好。

不过这里 qhelloworld 只是我们测试的一个例子，所以就不特意为其创建 tap 仓库，就暂时放在 qbase 的 tap 仓库里就好。即： `https://github.com/dvlpCI/homebrew-qbase.git`

2.2. 在上述创建的git下添加 `qhelloword.rb` 文件，配置刚才的 `url` 及通过该url对应的的.tar.gz的 `sha256`：

   ```ruby
class Qhelloworld < Formula
  url "https://github.com/dvlpCI/script-qbase/archive/qhelloworld-0.0.1.tar.gz"
  sha256 "xxxxxx"
  ...
end
   ```

**Homebrew 对 rb 文件的要求**：

- 文件名: qbase.rb （小写）

- 类名: Qbase （首字母大写，但第二个字母小写）

2.3. 提交 rb 文件

### 3. 安装、更新和使用

#### 3.1、安装、更新

见：[https://dvlproad.github.io/代码管理/库管理/homebrew](https://dvlproad.github.io/%E4%BB%A3%E7%A0%81%E7%AE%A1%E7%90%86/%E5%BA%93%E7%AE%A1%E7%90%86/homebrew) 中 【安装和更新命令的**更多介绍】**里的 【homebrew-xxx 下多 .rb 包的安装和更新】  

#### 3.2、使用

在终端输入 `qhelloworld` 即可。


## 版本记录

- 0.0.1 (2026-04-11): 初始版本
- 0.0.4 (2026-04-13): 修复AI执行skill中断问题，让AI可以按skill自动执行完整个流程

## End