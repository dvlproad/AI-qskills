---
name: pod-objc-to-swift-entry
version: 0.0.2
description: |
  将 CocoaPods 项目中 ObjC pod 与 Swift pod 的依赖方向反转（Swift 依赖 ObjC），
  并将 ObjC 文件逐步迁移为 Swift。
  触发场景：
  - 用户说"反转 pod 依赖方向"
  - 用户说"把 ObjC pod 依赖 Swift 改为 Swift pod 依赖 ObjC"
  - 用户说"把 ObjC 的入口改为 Swift"
  - 用户说"总入口从 ObjC 迁移到 Swift"
  - 用户说"把 TSTabBarViewController 转为 Swift"
---

# ObjC → Swift 迁移（反转依赖方向）

将 CocoaPods 项目中 ObjC pod 与 Swift pod 的依赖方向反转，
使 Swift pod 依赖 ObjC pod，从而 Swift 代码可以引用 ObjC 类。

## 适用场景

项目有两个 pod：
- `Foo` (ObjC) — 包含 ObjC 代码，当前被 `Foo-Swift` 依赖（或反过来）
- `Foo-Swift` (Swift) — 包含 Swift 代码

目标：反转依赖方向为 `Foo-Swift` 依赖 `Foo`，使 Swift 可以引用 ObjC 类。

## 完整步骤

### 第 1 步：分析现有依赖

读取两个 podspec，确认当前依赖关系：

```
Foo.podspec:         s.dependency 'Foo-Swift'   ← 当前方向
Foo-Swift.podspec:   无对 Foo 的依赖
```

读取需要迁移的 ObjC 文件，列出所有 import 和引用的类型。

### 第 2 步：反转依赖方向

**Foo.podspec** — 移除对 Foo-Swift 的依赖：
```ruby
# 删除: s.dependency 'Foo-Swift'
```

**Foo-Swift.podspec** — 新增 subspec，依赖 Foo：
```ruby
s.subspec 'VC' do |ss|
  ss.source_files = "Foo-Swift/VC/**/*.{swift}"
  ss.dependency 'Foo'                    # 反向依赖 ObjC pod
  ss.dependency 'CJBaseUIKit-Swift/UIView/as'
  ss.dependency 'CJBaseUtil-Swift/FrameworkCJHelper'
end
```

### 第 3 步：Swift 代码中 import ObjC 模块

反转依赖后，Swift 代码必须显式 import ObjC 模块才能引用其类：

```swift
import UIKit
import Foo                          # ObjC pod 的模块名
import CQDemoKit
import CJBaseUIKit_Swift
```

**模块名规则**：
- Pod 名 `Foo` → 模块名 `Foo`
- Pod 名 `Foo-Swift` → 模块名 `Foo_Swift`（连字符转下划线）
- Pod 名 `CJBaseUIKit-Swift` → 模块名 `CJBaseUIKit_Swift`

### 第 4 步：ObjC → Swift 文件迁移（按需）

反转依赖后，可逐步将 ObjC 文件迁移为 Swift。

#### 4.1 在 Swift pod 下创建同名目录

```bash
mkdir -p Foo-Swift/VC
```

#### 4.2 ObjC → Swift 转换

1. **import 语法差异**：
   - ObjC: `#import <CQDemoKit/CJUIKitBaseHomeViewController.h>`
   - Swift: `import CQDemoKit`

2. **ObjC 类在 Swift 中的引用**：
   - 同一模块内：直接用类名 `TSSingleLineTextViewController.self`
   - 跨 pod 模块：需要 `import 对应模块`（已在第 3 步处理）

3. **Swift 类的可用性检查**：
   ```swift
   if #available(iOS 14.0, *) {
       module.classEntry = TSSUHomeUIViewController.self
   } else {
       module.classEntry = NSClassFromString("TSSUHomeUIViewController")
   }
   ```

4. **动态类查找（保留 ObjC 风格兼容）**：
   ```swift
   if let tsClass = NSClassFromStringCJHelper.swiftClass(
       from: "TSSFUIView", nameSpace: "Foo-Swift"
   ) {
       return (tsClass as! UIView.Type).init()
   }
   ```

#### 4.3 更新 ObjC 中的跨模块引用

原 ObjC 文件引用了被迁移的类：

```objc
// 之前
#import "BaseVCHomeViewController.h"
tabBarModel.classEntry = [BaseVCHomeViewController class];

// 之后 — 删除 import，改用 NSClassFromString（必须带模块名前缀）
tabBarModel.classEntry = NSClassFromString(@"TSDemo_Demo_Swift.BaseVCHomeViewController");
```

原因：ObjC 无法 `#import` Swift 类，必须用运行时动态查找。
Swift 类的 ObjC 运行时名格式为 `模块名.类名`，模块名中连字符转下划线。

#### 4.4 删除旧 ObjC 文件

```bash
rm Foo/VC/BaseVCHomeViewController.h Foo/VC/BaseVCHomeViewController.m
```

### 第 5 步：pod install + 编译验证

```bash
cd TSDemoDemo && pod install
xcodebuild -workspace TSDemoDemo.xcworkspace -scheme TSDemoDemo -sdk iphonesimulator build
```

常见编译错误及修复：

| 错误 | 原因 | 修复 |
|------|------|------|
| `Cannot find 'XXX' in scope` | 缺少 import | 添加 `import Foo`（ObjC 模块名） |
| `NSClassFromStringCJHelper not in scope` | 缺少 CJBaseUtil_Swift | 添加 `import CJBaseUtil_Swift` |
| `'XXX' is only available in iOS 14.0` | 缺少可用性检查 | 用 `#available(iOS 14.0, *)` 包裹 |
| `Cannot find 'XXX' in scope`（ObjC 文件） | ObjC 引用 Swift 类 | 改用 `NSClassFromString(@"模块名.XXX")`，模块名中连字符转下划线 |

## 关键原则

1. **依赖方向**：Swift pod 依赖 ObjC pod（不是反过来），这样 Swift 代码可以引用 ObjC 类
2. **import 显式性**：Swift 必须 `import` ObjC 模块才能使用其类
3. **ObjC 引用 Swift 类**：必须用 `NSClassFromString(@"模块名.类名")`，不能用 `[ClassName class]`
   - Swift 类在 ObjC 运行时的全名是 `模块名.类名`（如 `TSDemo_Demo_Swift.BaseVCHomeViewController`）
   - 模块名中连字符转下划线：`TSDemo_Demo-Swift` → `TSDemo_Demo_Swift`
4. **可用性**：Swift 的 `@available` 注解需要 `#available` 运行时检查
5. **保留注释/头信息**：转换时保留原文件的版权注释
6. **渐进迁移**：反转依赖后可逐步迁移文件，不必一次全部迁移

## 完整示例

参考本 skill 实际执行的项目：
- ObjC pod: `TSDemo_Demo`（含 `TSTabBarViewController.m`）
- Swift pod: `TSDemo_Demo-Swift`（含 `BaseVCHomeViewController.swift`）
- 依赖反转: `TSDemo_Demo-Swift/VC` → `TSDemo_Demo`
