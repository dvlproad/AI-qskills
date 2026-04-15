---
name: test-branch-info
description: |
  测试分支信息的获取
  触发场景：用户输入"测试分支信息的获取"
---

# 测试分支信息的获取

用于测试分支信息获取功能，需要创建测试分支并验证获取逻辑。

## 执行流程

```mermaid
graph TD
    A[开始] --> B{确认测试项目}
    B -->|正确| C[确定主分支]
    B -->|不正确| D[输入项目路径]
    D --> C

    C --> E[拉取主分支到远程最新]
    E --> F{遍历分支<br/>test/branchInfo1/2/3}

    F -->|test/branchInfo1| G1[检查分支是否存在]
    F -->|test/branchInfo2| G2[检查分支是否存在]
    F -->|test/branchInfo3| G3[检查分支是否存在]

    G1 --> H1{分支是否存在?}
    G2 --> H2{分支是否存在?}
    G3 --> H3{分支是否存在?}

    H1 -->|是| I1[rebase 到主分支]
    H1 -->|否| J1[基于主分支创建分支]
    H2 -->|是| I2[rebase 到主分支]
    H2 -->|否| J2[基于主分支创建分支]
    H3 -->|是| I3[rebase 到主分支]
    H3 -->|否| J3[基于主分支创建分支]

    I1 --> K1{分支信息是否存在?}
    J1 --> K1
    I2 --> K2{分支信息是否存在?}
    J2 --> K2
    I3 --> K3{分支信息是否存在?}
    J3 --> K3

    K1 -->|是| L1[跳过创建]
    K1 -->|否| M1{检查 QTOOL 环境变量?}
    K2 -->|是| L2[跳过创建]
    K2 -->|否| M2{检查 QTOOL 环境变量?}
    K3 -->|是| L3[跳过创建]
    K3 -->|否| M3{检查 QTOOL 环境变量?}

    M1 -->|是| N1[使用 qtool 创建分支信息]
    M1 -->|否| O1[直接创建在项目example目录]
    M2 -->|是| N2[使用 qtool 创建分支信息]
    M2 -->|否| O2[直接创建在项目example目录]
    M3 -->|是| N3[使用 qtool 创建分支信息]
    M3 -->|否| O3[直接创建在项目example目录]

    O1 --> P1[修改 README.md<br/>插入 2-5 个中文字]
    N1 --> P1
    O2 --> P2[跳过 README 修改]
    N2 --> P2
    O3 --> P3[跳过 README 修改]
    N3 --> P3

    P1 --> Q1[提交修改]
    P2 --> Q2[提交修改]
    P3 --> Q3[提交修改]

    Q1 --> R{还有分支未处理?}
    Q2 --> R
    Q3 --> R
    R -->|是| F
    R -->|否| S{检查 dev_in_pgyer 分支}

    S -->|存在| T1[删除 dev_in_pgyer 分支]
    S -->|不存在| T2[跳过删除]

    T1 --> U[基于主分支创建 dev_in_pgyer]
    T2 --> U

    U --> V[合并 test/branchInfo1/2/3<br/>的所有提交到 dev_in_pgyer]
    V --> W[推送]

    W --> X[完成]

    style A fill:#e1f5fe
    style X fill:#c8e6c9
    style I1 fill:#fff3e0
    style J1 fill:#fff3e0
    style I2 fill:#fff3e0
    style J2 fill:#fff3e0
    style I3 fill:#fff3e0
    style J3 fill:#fff3e0
    style T1 fill:#ffcdd2
    style T2 fill:#c8e6c9
    style N1 fill:#fce4ec
    style N2 fill:#fce4ec
    style N3 fill:#fce4ec
    style O1 fill:#fce4ec
    style O2 fill:#fce4ec
    style O3 fill:#fce4ec
    style P1 fill:#fce4ec
    style V fill:#e8f5e9
    style W fill:#e8f5e9
```

## 分支信息 JSON 结构

直接创建时，在项目根目录 `example` 目录下创建分支信息 JSON 文件，结构要完整。

### 5.1 分支 JSON 结构

```json
{
  "name": "feature/user_login",
  "type": "feature",
  "create_time": "2024.03.01",
  "submit_test_time": "2024.03.10",
  "pass_test_time": "2024.03.15",
  "merger_pre_time": "2024.03.18",
  "tester": {
    "name": "zhangsan"
  },
  "answer": {
    "name": "lisi"
  },
  "outlines": [
    {
      "title": "登录模块开发",
      "weekSpend": [16, 24, 16, 8]
    }
  ]
}
```

### 5.2 字段说明

| 字段                   | 类型   | 必填         | 说明                                |
| ---------------------- | ------ | ------------ | ----------------------------------- |
| `name`                 | string | 是           | 分支名                              |
| `type`                 | string | 是           | 类型：hotfix/feature/optimize/other |
| `create_time`          | string | 是           | 创建时间（格式：YYYY.MM.DD）        |
| `submit_test_time`     | string | 测试阶段必填 | 提测时间                            |
| `pass_test_time`       | string | 预生产前必填 | 测试通过时间                        |
| `merger_pre_time`      | string | 发布前必填   | 合入预生产时间                      |
| `tester`               | object | 提测时必填   | 测试人员信息                        |
| `tester.name`          | string | 是           | 测试人员姓名                        |
| `answer`               | object | 否           | 答疑者信息                          |
| `outlines`             | array  | 否           | 工作事项列表                        |
| `outlines[].title`     | string | 是           | 事项标题                            |
| `outlines[].weekSpend` | array  | 周报必填     | 各周耗时（小时）                    |

## 示例对话

```
用户：测试分支信息的获取
助手：确认一下，您是在 /Users/lichaoqian/Project/AI/AI-qskills 项目下测试吗？
用户：不是，我在 CQCI 项目下测试
助手：请输入要测试的项目路径
用户：/Users/lichaoqian/Project/CQCI/script-qbase
助手：好的，现在开始创建测试分支...
（执行创建流程）
完成！已创建 test/branchInfo1、test/branchInfo2、test/branchInfo3 三个分支，并合并到 dev_in_pgyer 分支，可用于测试分支信息获取功能。
```
