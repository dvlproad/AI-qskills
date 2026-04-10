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
qbase -quick 脚本关键字 [参数...]
```

而不是：
- `sh xxx.sh 参数`
- `sh ${path}/qbase.sh -quick 脚本关键字 参数`

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

添加后即可以通过 `sh ${path}/qbase.sh -quick 脚本关键字 [具名参数/参数...]` 调用脚本。

### 步骤2：重新编译 qbase（使用 shc）

运行 `${path}/qbase重新生成.sh`（内部使用 `shc` 将 shell 脚本转换为二进制文件）。

生成后即可通过 `${path}/qbase -quick 脚本关键字 [具名参数/参数...]` 调用脚本。

### 步骤3：提交代码并发布

**脚本仓库操作**：
1. 提交代码：将修改后的脚本代码提交到仓库（如 script-qbase）
2. 打标签：创建版本标签（如 0.0.1）并推送到远程

**准备 rb 更新所需信息**：
3. 获取 tar.gz：通过 `https://github.com/dvlpCI/script-qbase/archive/{tag}.tar.gz` 获取压缩包
4. 计算 sha256：`shasum -a 256 {tag}.tar.gz` 获取文件校验和

**更新 homebrew 仓库**：
5. 更新 rb 文件：在 homebrew 对应仓库中更新 .rb 文件的 url 和 sha256
6. 提交 rb 文件：将更新后的 rb 文件提交到 homebrew 仓库

### 步骤4：下载更新和使用

用户更新：
```bash
brew update
brew upgrade qbase
```

使用：
```bash
qbase -quick 脚本关键字 [具名参数/参数...]
```





## 完整 Homebrew Tap 创建流程

### 1. 脚本仓库（script-qbase）

1.1. 创建脚本仓库（如 `https://github.com/dvlpCI/script-qbase.git`）

1.2. 在仓库中添加脚本文件（如 `helloworld.sh`），编写脚本代码

1.3. 编译为二进制：
   ```bash
   shc -r -f helloworld.sh
   ```
   - 将生成的 `helloworld.sh.x` 重命名为 `helloworld`

1.4. 提交代码并打标签（如 `0.0.1`）

1.5. 获取 tar.gz 链接：`https://github.com/dvlpCI/script-qbase/archive/0.0.1.tar.gz`

1.6. 计算 sha256：
   ```bash
   shasum -a 256 0.0.1.tar.gz
   ```

### 2. Homebrew 仓库（homebrew-qbase）

2.1. 创建 homebrew tap 仓库（如 `https://github.com/dvlpCI/homebrew-qbase.git`）

2.2. 添加 `.rb` 文件，配置 url 和 sha256：
   ```ruby
   class Qbase < Formula
     url "https://github.com/dvlpCI/script-qbase/archive/0.0.1.tar.gz"
     sha256 "xxxxxx"
     ...
   end
   ```

2.3. 提交 rb 文件

### 3. 使用

```bash
brew tap dvlpCI/qbase
brew install qbase
```





## 示例

将 `package_remote_version.sh` 整合到 qbase：

1. **qbase.json 添加配置**：
```json
{
    "key": "check_remote_version",
    "des": "检查/更新 Homebrew 包的远程版本",
    "rel_path": "./package/package_remote_version.sh",
    "example": "qbase -quick check_remote_version -a check -p qbase"
}
```

2. **重新编译 qbase**：运行 `${path}/qbase重新生成.sh`

3. **提交代码并发布**：打标签、更新 rb 文件

4. **下载更新和使用**：
```bash
brew update
brew upgrade qbase
qbase -quick check_remote_version -a check -p qbase
```