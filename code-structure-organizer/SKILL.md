---
name: code-structure-organizer
description: |
  当用户需要整理代码目录结构时触发
  触发场景：
  - 用户输入"帮我理下有关 XXX 的功能"
  - 用户输入"整理 XXX 目录的代码结构"
  - 用户输入"梳理 XXX 的脚本功能"
---

# 代码结构整理

帮助用户整理代码目录结构，梳理脚本功能和调用关系，输出结构化文档。

## 触发条件

当用户需要整理某个代码目录的结构时触发：
- "帮我理下有关 XXX 的功能"
- "整理 XXX 目录的代码结构"
- "梳理 XXX 的脚本功能"

## 执行流程

### 1. 了解目录结构和文件清单

```bash
# 列出目录结构
ls -la <目录路径>

# 递归列出所有文件
find <目录路径> -type f -name "*.sh"
```

**关注点：**
- 目录层级关系（特别是带数字前缀的，如 `10_xxx`, `11_xxx`, `20_xxx`）
- 区分核心脚本和测试脚本
- 找出主入口脚本

### 2. 梳理每个脚本的功能

读取每个核心脚本（排除测试用例），记录：
- 脚本名称
- 功能描述
- 输入参数
- 输出结果

**参数说明格式：**

| 参数 | 说明 |
|------|------|
| `-xxx` | 参数1说明 |
| `-yyy` | 参数2说明 |

### 3. 找出调用关系

使用 grep 查找脚本间的调用关系：

```bash
grep -r "sh.*\.sh\|source.*\.sh" <目录> --include="*.sh"
```

### 4. 组织文档结构

按照**被调用者的层级从高到低**组织子章节：

```
## X. 功能模块名称
├── X.1 目录结构
├── X.2 调用关系
└── X.3 主入口 - 主脚本.sh
      ├── X.3.1 子功能1 - 子脚本1.sh
      │       └── X.3.1.1 底层功能 - 孙脚本.sh
      └── X.3.2 子功能2 - 子脚本2.sh
```

### 5. 添加示例和效果

每个脚本必须包含：
- **测试用例路径**：`test/example_xxx.sh`
- **测试数据路径**：`test/data/xxx.json`
- **运行效果**：实际执行后的输出结果

## 文档模板

### 一、概述
简要说明这个模块的作用。

### 二、目录结构
```
模块名/
├── 主入口.sh              # 主入口功能
├── 功能1.sh               # 功能1说明
├── 功能2.sh               # 功能2说明
└── test/                  # 测试用例
    ├── example_xxx.sh
    └── data/
```

### 三、调用关系

#### 调用关系图

```
主入口.sh    ← 主入口
    ├── 功能1.sh     ← 功能1
    │       └── 底层.sh  ← 底层功能
    └── 功能2.sh     ← 功能2
```

#### 调用关系示例写法

以主入口为例，说明其输出是如何由各子模块组合而成的：

```
主入口脚本.sh 的输出结构
│
├── 子脚本1.sh      ← 生成单条信息
│   ├── 字段1 (子脚本1 内部生成)：示例值
│   ├── 字段2 (子脚本1 内部生成)：示例值
│   └── 嵌套描述
│       ├── 孙脚本1.sh  ← 生成嵌套信息
│       │   └── 输出示例："嵌套内容"
│       └── 输出示例："字段1值\n嵌套内容"
│   │
│   └── 输出示例："字段1值:示例\n字段2值"
│
├── 子脚本2.sh      ← 生成聚合信息
│   ├── 输出示例格式："**分类标题**\n{子脚本1 生成的详情}"
│   └── 输出示例："**=======分类1=======**\n详情1\n**=======分类2=======**\n详情2"
│
└── 最终输出示例（JSON）：
    {
      "key": ["子脚本1生成的值\n子脚本2新增的内容"]
    }
```

**规则：**

1. **用完整脚本名作为标题**：如 `get20_branchMapsInfo_byHisJsonFile.sh 的输出结构`
2. **内部生成的部分加示例**：如 `分支名 (get10 内部生成)：dev_login_err`
3. **每个模块要有输出示例**：分两层
   - `输出示例格式`：说明哪些是当前模块新增的（用 `**` 标注）
   - `输出示例`：具体内容
4. **输出示例用 `""` 包裹**：表示字符串
5. **`\n` 保持原样**：不要渲染成换行，这样才能和最终 JSON 输出对应
6. **添加数据来源说明**：主入口脚本如果需要读取 JSON 文件，必须说明其参数的数据来源

**数据来源说明规则：**

如果主入口脚本需要 `-xxxJsonF` 和 `-xxxKey` 类型的参数（JSON 文件路径和 key），需要在调用关系示例开头添加数据流转关系：

```
数据流转关系：
获取数据的脚本.sh (获取信息)
    │
    │  输出: JSON 数组
    │  示例: [{ "name": "xxx", ... }, { "name": "yyy", ... }]
    │
    ▼
存储到 JSON 文件 (通过其他脚本或手动)
    │
    │  文件示例: output.json
    │  内容: { "dataKey": [{ "name": "xxx", ... }, ...] }
    │
    ▼
主入口脚本.sh (读取并展示)
    │
    ├── -xxxJsonF = output.json      ← 数据源文件
    └── -xxxKey = dataKey             ← 数据在文件中的 key（对应数组）
```

**完整示例参考写法：**

```bash
# 示例中的关键代码
# 1. 获取数据并存储
allDataStrings=$(sh get_data.sh ...)
lastJson='{
    "dataKey": '"${allDataStrings}"'
}'
printf "%s" "$lastJson" > ${output_file}

# 2. 读取并处理
dataJsonFile=${output_file}
dataKey="dataKey"

sh main_entry.sh -xxxJsonF "${dataJsonFile}" -xxxKey "${dataKey}" ...
```

参考示例：[branchMaps_10_resouce_get 下的example_get_allBranchJson_inBranchNames_byJsonDir.sh](https://github.com/dvlpCI/script-qbase/blob/main/branchMaps_10_resouce_get/example/example_get_allBranchJson_inBranchNames_byJsonDir.sh)

**实际示例的示例：**

见：[script-qbase/branch.md](https://github.com/dvlpCI/script-qbase/blob/main/branch.md)

```
get20_branchMapsInfo_byHisJsonFile.sh 的输出结构
│
├── get10_branch_self_detail_info.sh      ← 生成单条分支信息
│   ├── 状态标记 (get10 内部生成)：🖍/🏃coding/❓test_submit/👌🏻test_pass/✅test_prefect
│   ├── 分支名 (get10 内部生成)：dev_login_err
│   ├── 时间线 (get10 内部生成)：[02.09开发中]
│   ├── @人员 (get10 内部生成)：@producter1@test1
│   └── outlines 描述
│       ├── get10_branch_self_detail_info_outline.sh  ← 生成 outlines 列表
│       │   ├── ① ② ③ 编号 (outline 内部生成)：①
│       │   ├── 标题 (outline 内部生成)：功能点一
│       │   ├── 链接 (outline 内部生成)：https://xxx.com/
│       │   └── 耗时
│       │       └── get10_branch_self_detail_info_outline_spend.sh  ← 计算耗时
│       │           └── 输出示例："12"
│       │
│       └── 输出示例："①功能点一[4h]\n②功能点二[12h]"
│   │
│   └── 输出示例："🏃dev_login_err:[02.09开发中]@producter1@test1\n①功能点一[4h]\n②功能点二[12h]"
│
├── get11_category_all_detail_info.sh    ← 分类整理
│   ├── 按 type 分组 (hotfix/feature/optimize/other)
│   ├── 添加分类标题
│   ├── 输出示例格式：
│   │   "=======hotfix=======\n{get10 生成的分支信息}\n=======feature=======\n{get10 生成的分支信息}\n..."
│   └── 输出示例：
│       "=======hotfix=======\n1.❓【34天@test1】dev_login_err:[02.09已提测]@producter1@test1\n①登录失败错误提示\n②登录失败错误提示2\n=======feature=======\n3.✅dev_ui_revision:[02.17已合入预生产]@qian@qian\n①首页UI改版\n..."
│
└── 最终输出示例（JSON）：
    {
      "category": {
        "feature": ["✅dev_ui_revision:[02.17已合入预生产]@qian@qian\n①首页UI改版[8h]"],
        "hotfix": ["🏃dev_login_err:[02.09开发中]@producter1@test1\n①功能点一[4h]\n②功能点二[12h]"],
        "optimize": [...],
        "other": []
      }
    }
```

### 四、功能详解

**每个脚本的内容按以下规则书写**

包含的字段

| 字段         | 说明             |
| ------------ | ---------------- |
| **功能**     | 简要描述         |
| **输出用途** | 输出将被谁使用   |
| **被谁调用** | 调用它的父脚本名 |
| **参数**     | 参数说明表格     |
| **测试用例** | 测试用例         |
| **效果**     | 运行输出         |

**示例**

````
##### 4.1 主入口 - 主脚本.sh

**功能：** 简要描述

**输出用途：** 其输出通常作为 `xxx.sh` 见（[xxx 的 xxx](#xxx)）的数据源，用于xxx。

**参数：**

| 参数   | 说明     |
| ------ | -------- |
| `-xxx` | 参数说明 |
| `-yyy` | 参数说明 |

**测试用例：** `test/example_xxx.sh`

**效果：**

```bash
sh test/example_xxx.sh
[运行输出]
```
````

##### 4.3 测试数据说明

**数据文件** (`test/data/xxx.json`)：
```json
{
  // JSON 结构说明
}
```

### 五、常见问题

#### Q1: [问题描述]
**原因：** [原因]
**解决：** [解决方法]


## 注意事项

1. **区分核心脚本和测试脚本**：核心脚本才有文档价值
2. **运行测试获取真实效果**：不要猜测输出，要实际运行
3. **调用关系要准确**：通过 grep 查找，而不是猜测
4. **子章节按调用链嵌套**：被调用的放底层，调用者放高层
5. **每个脚本都要有效果展示**：让用户能直观看到输出
6. **调用关系示例要清晰**：
   - 内部生成的部分加示例
   - 输出示例用 `""` 包裹
   - `\n` 保持原样
   - 用 `**` 标注新增内容
7. **添加跳转链接**：
   - 当提及某个脚本或章节时，如果有更详细的说明位置，应添加跳转链接
   - **添加锚点**：在被跳转位置的标题前添加 `<a name="锚点名"></a>`
   - **跳转链接格式**：`[显示文本](#锚点名)`，写在描述文字中（不要写在代码块里，代码块里的链接无法点击）
   - **锚点名建议**：使用描述性中文，如 `四、分支信息展示 的 调用关系示例 的数据来源`

**跳转链接示例：**

```markdown
<a name="2.5-主入口详细说明"></a>

### 2.5 主入口 - get_allBranchJson_inBranchNames_byJsonDir.sh

**输出用途：** 其输出通常作为 `get20_branchMapsInfo_byHisJsonFile.sh` 见（[四、分支信息展示 的 调用关系示例 的数据来源](#四、分支信息展示 的 调用关系示例 的数据来源)）的数据源。
```

参考示例：[script-qbase/branch.md](https://github.com/dvlpCI/script-qbase/blob/main/branch.md) 中的 `get20_branchMapsInfo_byHisJsonFile.sh` 数据来源说明

## 版本记录

- 0.0.2 (2026-04-15): 补充调用关系示例的写法规则，调整文档结构
- 0.0.1 (2026-04-15): 初始版本
