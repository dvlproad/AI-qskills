---
name: record-to-script-repo
description: |
  将脚本分类入库 — 判断脚本归属仓库和子目录，放入正确位置
  触发场景：被 record-router 路由至此
---

# Record to Script Repo — 脚本入库分类

将独立脚本放入正确的仓库和子目录，同时更新对应的菜单配置文件（`qbase.json` / `qtool.json`）。

## 触发条件

- 被 record-router 路由"脚本入库"任务时

## 引用规范

当涉及以下约定时，优先参考对应规范：

- 分类归属规则：暂无
- 命名约定：暂无
- 流程对比：暂无

## 知识库 — 脚本仓库

### 仓库一览

| 仓库 | CLI | 路径 |
|------|-----|------|
| script-qbase | `qbase` | `~/Project/Github/script-qbase/` |
| script-branch-json-file | `qtool` | `~/Project/Github/script-branch-json-file/` |

### script-qbase — 脚本基础库（通用/基础工具）

用途：通用的、不依赖特定项目的脚本工具。

```yaml
子目录:
  foundation/:       字符串处理、JSON 转数组、拼音转换等基础函数
  json_check/:       JSON 文件检查
  json_formatter/:   JSON 格式化
  log/:              打印日志
  date/:             日期计算
  path_util/:        路径拼接、路径转换
  value_create/:     值的创建（如输入获取、app 版本号更新）
  value_update_in_file/:   文件中值的更新（sed、json 更新）
  value_update_in_code/:   代码中值的更新
  value_get_in_json_file/:  JSON 文件中值的获取
  env_variables/:    环境变量操作
  menu/:             菜单脚本
  notification/:     企业微信通知
  package/:          Homebrew 包管理
  upload_app/:       上传到蒲公英、TestFlight 等
  branch/:           分支相关
  branch_quickcmd/:  分支快捷命令
  branchMaps_10_resouce_get/:    分支映射资源获取
  branchMaps_11_resouce_check/:  分支映射检查
  branchMaps_20_info/:           分支映射信息整理
  get_file_text/:    从文件中提取文本
  git_content/:      Git 内容操作
  channel_file/:     多渠道配置文件
  excel_data_compare/: Excel 数据比较
  pythonModuleSrc/:  Python 模块源码
  markdown/:         Markdown 相关
  init/:             初始化
  base/:             基础模块
```

### script-branch-json-file — 项目工具脚本（CI/打包/特定流程）

用途：与具体项目流程相关的工具脚本。

```yaml
子目录:
  branch/:       分支检查（打包分支名、必合分支）
  commit/:       提交相关
  rebase/:       Rebase 相关
  pack/:         打包
  package-size/: 包大小
  sign/:         签名
  upload/:       上传
  upload_arg_get/: 上传参数获取
  dsym/:         dSYM 符号表
  test/:         测试
  jenkins/:      Jenkins CI
  monitor/:      监控
  project_tool/: 项目工具
  common/:       通用工具
  gui/:          GUI 界面
  src/:          源码
  base/:         基础模块
  init/:         初始化
  branch_quickcmd/: 分支快捷命令
  channel_file/:    多渠道配置文件
  example/:         示例
```

## 执行流程

### 1. 判断归属仓库

根据脚本功能判断归属：

| 脚本特征 → | script-qbase | script-branch-json-file |
|------------|-------------|----------------------|
| 字符串/JSON/日期处理 | ✅ | |
| 环境变量操作 | ✅ | |
| 文件值读写修改 | ✅ | |
| 通知发送 | ✅ | |
| 上传到分发平台 | ✅ | |
| 分支检查/合规 | | ✅ |
| CI/打包/签名 | | ✅ |
| Jenkins 相关 | | ✅ |
| 包大小分析 | | ✅ |
| 符号表/dSYM | | ✅ |
| 通用/不确定 | 询问用户 | |

如果不确定，询问用户。

### 2. 选择子目录

在目标仓库中找到最匹配的子目录。如果不确定，列出来让用户选。

### 3. 复制脚本到目标位置

```bash
cp /path/to/script.sh ~/Project/Github/script-qbase/foundation/
```

### 4. 更新菜单配置（如需要）

如果脚本需要通过 `qbase -quick` 或 `qtool -quick` 调用，需更新对应的 JSON：

- script-qbase → 更新 `qbase.json` 的 `support_script_path` 或 `quickCmd` 数组
- script-branch-json-file → 更新 `qtool.json` 的对应数组

配置项格式：

```json
{
    "type": "foundation",
    "des": "字符串处理(截取)",
    "values": [
        {
            "des": "功能描述",
            "key": "脚本关键字",
            "rel_path": "./foundation/脚本名.sh",
            "example": "使用示例"
        }
    ]
}
```

### 5. 确认

让用户确认文件和配置是否正确。

## 版本记录

### 0.0.2 (2026-05-19): 新增引用规范区（暂无可引用的特定规范）

### 0.0.1 (2026-05-18): 初始版本
