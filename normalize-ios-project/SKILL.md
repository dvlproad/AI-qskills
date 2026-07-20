---
name: normalize-ios-project
version: 0.2.0
description: |
  规范化 iOS 项目的文件归属和 ObjC/Swift 混编结构，检查并修复 Demo 文件归属、Swift pod 依赖方向等问题。
  触发场景：
  - 用户说"规范化 iOS 项目"
  - 用户说"检查 ObjC Swift 混编是否规范"
  - 用户说"反转 pod 依赖方向"
  - 用户说"把 Demo 文件移到 pod"
  - 用户说"把 ObjC pod 依赖 Swift 改为 Swift pod 依赖 ObjC"
  - 用户说"把 ObjC 的入口改为 Swift"
  - 用户说"总入口从 ObjC 迁移到 Swift"
---

# iOS 项目规范化

检查 iOS 项目的 ObjC/Swift 混编结构，发现问题时自动修复。

## 检查流程

依次执行以下检查，发现问题则修复，无问题则跳过：

### 检查 1：Demo 文件归属

**检查目的**：Demo 文件应先从 app target 剥离到独立 Demo pod（如 `TSDemo_BaseUIKit`），后续才做依赖方向分析和 Swift 拆分。

**检查对象**：app target 中引用主库（如 `CJBaseUIKit`）大量头文件的 Demo 文件（如 `DemosView/`）

**规范**：Demo 文件应放在独立的 Demo pod（如 `TSDemo_BaseUIKit`）中，而非直接混在 app target。

**检查方法**：
- 项目中有独立的 Demo pod（如 `TSDemo_BaseUIKit.podspec`）
- app target 仍有大量直接引用 `CJBaseUIKit` 等主库头文件的 Demo 文件夹（如 `DemosView/`）

**不规范时的修复步骤**：

1. **确定边界**
   - 识别目标移动范围（如 `DemosView/` 全部文件）
   - 检查跨文件夹引用 — 同一个模块内部的 Demo 文件一起移动

2. **识别共用辅助文件**
   - 找出 Demo 文件引用的 `CommonUI/`、`CommonUtil/` 等共享组件
   - 这些辅助文件也需要随 Demo 一起移到 pod

3. **处理依赖**
   - 更新 podspec：添加所有必要的 `s.dependency`
   - 处理 PCH：用 `prefix_header_contents` 替代 `#import "xxx.h"` 等相对引用
   - 处理 AppDelegate 引用：创建协议（`@protocol`），主工程 AppDelegate 遵循该协议

4. **处理 app 专属文件**
   - 确认不挪入 pod 的文件：`AppAssets.xcassets`（属 app target）、app 工具类（如 `YunUncaughtExceptionHandler`、`CJAppVersionUtil` → 留在 app target）

5. **更新 Xcode 引用**
   - App target：删除源文件引用（`PBXSourceBuildPhase`）
   - 可选：删除 Xcode 中对应 group（`PBXGroup`）

6. **编译验证** + `pod install`（如果 CocoaPods 缓存过期）

**无需修复时**：跳过，进入下一项检查。

---

### 检查 2：TSDemo_xxx-Swift 检查（预留）

检查 `TSDemo_xxx` 是否需要拆分 `TSDemo_xxx-Swift`，处理 Swift 与 ObjC 混编问题。

---

### 检查 3：ObjC/Swift pod 依赖方向

**检查对象**：项目中同名的 ObjC pod 和 Swift pod（如 `Foo` 和 `Foo-Swift`）

**规范**：Swift pod 应依赖 ObjC pod（不是反过来），这样 Swift 代码可以引用 ObjC 类。

**检查方法**：读取两个 podspec，确认依赖方向：
```
✅ 规范：Foo-Swift.podspec → dependency 'Foo'
❌ 不规范：Foo.podspec → dependency 'Foo-Swift'
```

**不规范时的修复步骤**：

1. **反转依赖方向**
   - `Foo.podspec`：移除 `s.dependency 'Foo-Swift'`
   - `Foo-Swift.podspec`：新增 subspec，添加 `ss.dependency 'Foo'`

2. **Swift 代码中 import ObjC 模块**
   ```swift
   import Foo  # ObjC pod 的模块名
   ```

3. **ObjC 引用 Swift 类**：改用 `NSClassFromString(@"模块名.类名")`
   - 模块名中连字符转下划线：`Foo-Swift` → `Foo_Swift`

4. **pod install + 编译验证**

**无需修复时**：跳过，进入下一项检查。

---

## 常见编译错误及修复

| 错误 | 原因 | 修复 |
|------|------|------|
| `Cannot find 'XXX' in scope` | 缺少 import | 添加 `import Foo`（ObjC 模块名） |
| `NSClassFromStringCJHelper not in scope` | 缺少 CJBaseUtil_Swift | 添加 `import CJBaseUtil_Swift` |
| `'XXX' is only available in iOS 14.0` | 缺少可用性检查 | 用 `#available(iOS 14.0, *)` 包裹 |
| `Cannot find 'XXX' in scope`（ObjC 文件） | ObjC 引用 Swift 类 | 改用 `NSClassFromString(@"模块名.XXX")` |

## 关键原则

1. **渐进迁移**：反转依赖后可逐步迁移文件，不必一次全部完成
2. **ObjC 运行时名**：Swift 类的 ObjC 全名是 `模块名.类名`，连字符转下划线
3. **可用性**：Swift 的 `@available` 注解需要 `#available` 运行时检查
