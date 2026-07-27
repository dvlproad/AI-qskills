---
name: normalize-ios-project
version: 0.5.1
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
   - 处理 AppDelegate 引用：通过 `CQDemoProtocol` pod 中的 `CQTSDemoAppDelegateProtocol` 协议，主工程 AppDelegate 遵循该协议，pod 通过 `(id<CQTSDemoAppDelegateProtocol>)[UIApplication sharedApplication].delegate` 获取

4. **处理 app 专属文件**
   - 确认不挪入 pod 的文件：`AppAssets.xcassets`（属 app target）、app 工具类（如 `YunUncaughtExceptionHandler`、`CJAppVersionUtil` → 留在 app target）

5. **更新 Xcode 引用**
   - App target：删除源文件引用（`PBXSourceBuildPhase`）
   - 可选：删除 Xcode 中对应 group（`PBXGroup`）

6. **编译验证** + `pod install`（如果 CocoaPods 缓存过期）

**无需修复时**：跳过，进入下一项检查。

---

### 检查 2：二次封装组件提取

**检查目的**：TSDemo_xxx 中的部分文件可能是基于主库（如 CJBaseUIKit）的二次封装组件（Wrapper），不是纯 demo。这些应提取到独立的中层 pod（如 `CQBaseUIKit`），形成 `TSDemo_xxx → CQBaseUIKit → CJBaseUIKit` 三层依赖。

**检查对象**：TSDemo_xxx 中非 demo 的二次封装文件

**判断方法**：文件如果符合以下特征，属于二次封装组件：
- 直接 `#import` CJBaseUIKit 的 category/类（如 `UIColor+CJHex.h`、`UIButton+CJMoreProperty.h`、`CJTextField.h`）
- 提供可复用的工厂类或控件封装（如 `TSButtonFactory`、`CQBlockTextField`、`CQCommentsPopView`）
- 不是"演示如何使用 CJBaseUIKit"的 VC，而是"封装了 CJBaseUIKit 功能"的工具

**规范的修复步骤**：

1. **创建新 pod**：`CQBaseUIKit.podspec`，`s.source_files = "CQBaseUIKit/**/*.{h,m}"`
2. **识别待移动模块**：从 TSDemo_xxx 中找出所有二次封装组件
   - 常见模块：`TSButtonFactory/`、`DemoTextFieldFactory/`、`TSSliderFactory/`、`CJDemoDatePickerView/`、`CJDemoDateTextField/`、`TextField/CQBlockTextField`、`TextField/Helper/`、`DemoLabel/`、`CQCommentsPopView/`
3. **移动文件**：`mv TSDemo_BaseUIKit/Foo/ CQBaseUIKit/Foo/`
4. **更新 podspec 依赖**
   - `CQBaseUIKit.podspec`：`s.dependency 'CJBaseUIKit'`（及辅助依赖如 `CJDataVientianeSDK`）
   - `TSDemo_xxx.podspec`：添加 `s.dependency 'CQBaseUIKit'`
5. **更新 import 路径**：TSDemo_xxx 和 app target 中所有引用移动模块的文件，`#import "Foo.h"` → `#import <CQBaseUIKit/Foo.h>`
6. **更新 Podfile**：app target 添加 `pod 'CQBaseUIKit', :path => '../'`
7. **pod install + 编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 3：同类型库合并 TSDemo

**检查目的**：同类库（如 CJBaseUtil + CJBaseHelper 都是工具/帮助类）的 demo 无需独立成多个 TSDemo，合并到一个即可（如 `TSDemo_BaseUtilHelper`）。

**原则**：
- 按库的性质分组，而非按库名一对一建 TSDemo
- 示例：`CJBaseUtil` + `CJBaseHelper` → `TSDemo_BaseUtilHelper`
- 同样，如果需要 `CQBaseUtil` 二次封装 pod，同理合并

---

### 检查 4：Home VC 引用 Swift 类的归属

**检查目的**：ObjC TSDemo 中的 Home VC 如果引用了 Swift 类（如 `TSEasyAnimationViewController`），该 Home VC 应转换为 Swift 并移入 `TSDemo_xxx-Swift`，而非留在 ObjC pod 中。

**检查方法**：在 ObjC TSDemo 的 Home VC 中搜索 `classEntry = [TSEasy... class]` 或其他 Swift 类引用。

**规范**：
- Home VC 引用 Swift 类 → 转为 Swift，移入 `TSDemo_xxx-Swift`
- ObjC 入口（如 `TSAnmaionMainViewController`）引用该 Home VC → 改用 `NSClassFromString(@"模块名.类名")`

**修复步骤**：

1. **转换 Home VC 为 Swift**
   - 在 `TSDemo_xxx-Swift/` 下创建同名 `.swift` 文件
   - 标记 `@objc class` 以保持 ObjC 运行时可见
   - 引用 ObjC 类时使用 `NSClassFromString("TSDemo_xxx.类名")`

2. **删除旧 ObjC 文件**
   - 删除 `TSDemo_xxx/` 下的 `.h` 和 `.m`

3. **更新 ObjC 入口引用**
   - 移除 `#import "XxxHomeViewController.h"`
   - `classEntry = [XxxHomeViewController class]` → `classEntry = NSClassFromString(@"TSDemo_xxx_Swift.XxxHomeViewController")`

4. **pod install + 编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 4：ObjC/Swift pod 依赖方向

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

### 检查 5：Podfile 构建方式（use_frameworks! vs use_modular_headers!）

**检查目的**：ObjC/Swift 混编项目需要正确选择构建方式，否则 Swift 生成的头文件无法被 ObjC 引用。

**规范**：
- `use_frameworks!`：每个 pod 编译为独立 framework，Swift 自动生成的头文件（`Module-Swift.h`）可通过 `#import <Module/Module-Swift.h>` 访问
- `use_modular_headers!`：每个 pod 编译为 static library + module map，Swift 生成的头文件不在磁盘上，ObjC 只能通过 `@import Module;` 访问（需要 `CLANG_ENABLE_MODULES = YES`）
- 如果 ObjC 代码需要 `#import <Module/Module-Swift.h>`，必须用 `use_frameworks!`

**检查方法**：查看 Podfile 顶部的构建方式声明。

**不规范时的修复步骤**：

1. **切换构建方式**
   ```ruby
   # 修改前
   use_modular_headers!
   # 修改后
   use_frameworks!
   ```

2. **pod install**（会重新生成 Pods 项目）

3. **编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 6：UIWindow+RootSetting 统一入口

**检查目的**：AppDelegate 中设置 rootViewController 的逻辑应集中管理，便于不同 pod/配置切换入口。

**规范**：创建 `UIWindow+RootSetting` category，提供 `- (void)settingRoot` 方法统一设置 rootVC。AppDelegate 只需调用 `[self.window settingRoot]`。

**创建步骤**：

1. **创建 UIWindow+RootSetting.h/.m**（放在主 target 或 Demo pod 中）
   ```objc
   // UIWindow+RootSetting.m
   #import "UIWindow+RootSetting.h"
   #import <Module_Swift/Module_Swift-Swift.h>
   
   @implementation UIWindow (RootSetting)
   - (void)settingRoot {
       [self setBackgroundColor:[UIColor whiteColor]];
       UIViewController *rootViewController = [[SwiftVCClass alloc] init];
       self.rootViewController = rootViewController;
       [self makeKeyAndVisible];
   }
   @end
   ```

2. **AppDelegate 精简**
   ```objc
   - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
       self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
       [self.window settingRoot];
       return YES;
   }
   ```

3. **更新 Xcode 项目引用**（PBXBuildFile、PBXFileReference、PBXGroup、PBXSourcesBuildPhase）

4. **编译验证**

**注意**：
- `UIWindow+RootSetting` 如果引用 Swift 类，不能放在 ObjC pod 中（会形成循环依赖），应放在主 target 或 Swift pod 的依赖方
- ObjC 类引用 Swift 类：`NSClassFromString(@"Module_Swift.SwiftClassName")`（模块名中连字符转下划线）
- Swift 类引用 ObjC 类：直接 `import ObjCModule` 后使用类名

**无需修复时**：跳过，进入下一项检查。

---

### 检查 6.5：Tab 图片完整性

**检查目的**：MainViewController 中 tabBarModels 设置了 title 和 classEntry，但可能遗漏了 normalImage，导致 tab 无图标。

**检查方法**：在 TSPopupMainViewController（或其他 MainViewController）中搜索 `CQDMTabBarModel`，检查每个 model 是否都设置了 `normalImage`。

**规范**：每个 tabBarModel 必须设置 `normalImage`（图标资源来自 `CQDemoResource` 的 `icons8-*` 系列）。

**不规范时的修复步骤**：

1. **确认依赖**：podspec 中需添加 `s.dependency "CQDemoResource/Images"`，对应头文件 `#import <CQDemoResource/UIImage+CQDemoResource.h>`
2. **添加 import**：在 MainViewController.m 中添加 `#import <CQDemoResource/UIImage+CQDemoResource.h>`
3. **import 顺序规范**：`<>` 引用按以下顺序排列：
   - 第三方库（如 Masonry）
   - CQDemoKit
   - CQDemoResource
   - CQDemoProtocol
   - 主库（如 CJPopupAction）
   - TSDemo_（Demo pod）
4. **补充 normalImage**
   ```objc
   // ObjC
   tabBarModel.normalImage = [UIImage cqresource_imageNamed:@"icons8-menu"];
   ```
   ```swift
   // Swift
   model.normalImage = UIImage.cqresource_imageNamed("icons8-menu")
   ```

5. **可用图标参考**（CQDemoResource/Images 中的 `icons8-*` 系列）：
   - `icons8-menu` — 菜单
   - `icons8-folder` — 文件夹
   - `icons8-settings` — 设置
   - `icons8-calendar` — 日历
   - `icons8-home` — 首页

6. **编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 7：XIB 加载 Bundle 修正

**检查目的**：Demo 文件移到 pod 后，xib 资源从 mainBundle 移到了 pod 的 framework bundle，`[NSBundle mainBundle]` 加载会崩溃。

**检查方法**：在 TSDemo_xxx 中搜索 `loadNibNamed:` 或 `mainBundle`。

**规范**：pod 中加载 xib 必须使用 `[NSBundle bundleForClass:[self class]]`，不能用 `[NSBundle mainBundle]`。

**不规范时的修复步骤**：

1. **全局替换**
   ```objc
   // 修改前
   [[NSBundle mainBundle] loadNibNamed:@"XxxView" owner:nil options:nil]
   // 修改后
   [[NSBundle bundleForClass:[self class]] loadNibNamed:@"XxxView" owner:nil options:nil]
   ```

2. **同理修复 xibBundle 赋值**
   ```objc
   // 修改前
   module.xibBundle = [NSBundle mainBundle];
   // 修改后
   module.xibBundle = [NSBundle bundleForClass:[self class]];
   ```

3. **编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 8：Main.storyboard 清理

**检查目的**：Demo 文件移到 pod 后，旧的 storyboard 场景（如 ViewController）已废弃，残留的 `initialViewController` 和 segue 连线会影响启动流程。

**检查方法**：查看 Info.plist 中 `UIMainStoryboardFile` 是否仍指向 Main.storyboard，以及 storyboard 中是否有已废弃的 ViewController 场景。

**规范**：
- 如果 AppDelegate 已通过 `UIWindow+RootSetting` 设置 rootVC，Info.plist 应移除 `UIMainStoryboardFile`
- Main.storyboard 保留但清空废弃的 ViewController 场景和连线（保留空骨架即可）

**修复步骤**：

1. **Info.plist 移除 Main storyboard 引用**
   ```xml
   <!-- 删除以下两行 -->
   <key>UIMainStoryboardFile</key>
   <string>Main</string>
   ```

2. **清空 storyboard 废弃场景**
   - 移除 ViewController scene 及其 segue 连线
   - 保留空的 storyboard 骨架（NavigationController 等可保留）

3. **更新 Xcode 项目引用**（如果需要调整 PBXFileReference 路径）

4. **编译验证**

**无需修复时**：跳过，进入下一项检查。

---

### 检查 9：NSClassFromString 命名修正

**检查目的**：`use_frameworks!` 下 ObjC 类不带模块前缀，Swift 类才带模块前缀。误用会导致 `NSClassFromString` 返回 nil。

**检查方法**：搜索 `NSClassFromString` 调用，检查类名前缀是否正确。

**规范**：
| 类型 | 正确格式 | 错误格式 |
|------|---------|---------|
| ObjC 类 | `NSClassFromString(@"ClassName")` | `NSClassFromString(@"Module.ClassName")` |
| Swift 类 | `NSClassFromString(@"Module.ClassName")` | `NSClassFromString(@"ClassName")` |

**不规范时的修复步骤**：

1. **ObjC 类**：移除模块前缀
   ```objc
   // 修改前
   NSClassFromString(@"TSDemo_Popup.ViewController")
   // 修改后
   NSClassFromString(@"ViewController")
   ```

2. **Swift 类**：确认模块名正确（连字符转下划线）
   ```objc
   // 模块名 TSDemo_Popup-Swift → TSDemo_Popup_Swift
   NSClassFromString(@"TSDemo_Popup_Swift.TSPopupMainViewController")
   ```

3. **编译验证**

**无需修复时**：跳过，进入下一项检查。

---

## 常见编译错误及修复

| 错误 | 原因 | 修复 |
|------|------|------|
| `Cannot find 'XXX' in scope` | 缺少 import | 添加 `import Foo`（ObjC 模块名） |
| `NSClassFromStringCJHelper not in scope` | 缺少 CJBaseUtil_Swift | 添加 `import CJBaseUtil_Swift` |
| `'XXX' is only available in iOS 14.0` | 缺少可用性检查 | 用 `#available(iOS 14.0, *)` 包裹 |
| `Cannot find 'XXX' in scope`（ObjC 文件） | ObjC 引用 Swift 类 | 改用 `NSClassFromString(@"模块名.XXX")` |
| `'Module-Swift.h' file not found` | use_modular_headers! 下无法 import Swift 头文件 | 切换为 `use_frameworks!` |
| 启动后页面为空 | `NSClassFromString` 返回 nil（ObjC 类误加模块前缀） | 移除前缀：`NSClassFromString(@"ClassName")` |
| xib 加载崩溃 | pod 中 xib 不在 mainBundle | 改用 `[NSBundle bundleForClass:[self class]]` |
| storyboard 启动冲突 | Info.plist 仍有 `UIMainStoryboardFile`，与 UIWindow+RootSetting 冲突 | 移除 `UIMainStoryboardFile` 键值 |
| Tab 无图标 | tabBarModel 未设置 `normalImage` | 补充 `normalImage = [UIImage cqresource_imageNamed:@"icons8-xxx"]` |

---

## 实战案例：CJPopupAction 规范化

**项目**：CJPopupAction（弹窗动画库）

**规范化前状态**：
- 所有 Demo 文件（ViewController、4 个 Demo VC、2 个 View + xib）混在 app target
- 无 Swift 入口，无 Demo pod
- Podfile 使用 `use_modular_headers!`

**执行步骤**：

1. **动画系统重构**（前提：先拆分 Core/Product/ExpandAnimation/SlideAnimation）
2. **创建 TSDemo_Popup pod**：移入所有 ObjC Demo 文件
3. **创建 TSDemo_Popup-Swift pod**：`TSPopupMainViewController`（TabBar 入口，引用 ObjC 的 ViewController）
4. **Podfile 切换为 `use_frameworks!`**：支持 `#import <TSDemo_Popup_Swift/TSDemo_Popup_Swift-Swift.h>`
5. **创建 UIWindow+RootSetting**：放在主 target，精简 AppDelegate
6. **清空 Main.storyboard**：移除废弃 ViewController 场景，Info.plist 移除 `UIMainStoryboardFile`
7. **修正 XIB 加载 Bundle**：`NSBundle mainBundle` → `[NSBundle bundleForClass:]`
8. **修正 NSClassFromString**：ObjC 类移除模块前缀

**最终依赖关系**：
```
CJPopupActionDemo (app target)
├── TSDemo_Popup (ObjC Demo pod)
│   ├── CJPopupAction
│   ├── Masonry
│   └── CQDemoKit
└── TSDemo_Popup-Swift (Swift 入口 pod)
    ├── TSDemo_Popup
    └── CQDemoResource
```

## 关键原则

1. **渐进迁移**：反转依赖后可逐步迁移文件，不必一次全部完成
2. **ObjC 运行时名**：Swift 类的 ObjC 全名是 `模块名.类名`，连字符转下划线；ObjC 类无模块前缀
3. **可用性**：Swift 的 `@available` 注解需要 `#available` 运行时检查
4. **资源 Bundle**：pod 中的 xib/storyboard 等资源在 framework bundle 中，必须用 `[NSBundle bundleForClass:]` 加载
5. **循环依赖**：ObjC pod 引用 Swift 类不能通过 import，需用 `NSClassFromString`；Swift pod 可直接 import ObjC 模块
6. **use_frameworks!**：ObjC/Swift 混编且需要 `#import <Module/Module-Swift.h>` 时，必须用 `use_frameworks!`
7. **UIWindow+RootSetting**：AppDelegate 中 rootVC 设置逻辑应集中管理，便于切换入口
