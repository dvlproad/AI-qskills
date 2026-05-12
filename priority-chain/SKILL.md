---
name: priority-chain
description: |
  优先级链 — 多层配置/设置按优先级层叠覆盖的模式。
  触发场景：用户需要处理"低优先修改时自动刷新高优先"、"多层配置覆盖"、"继承式设置"、"权限继承"等场景。
  核心规则：读（显示）时高优先覆盖低优先；写（修改）低优先时清除所有更高优先级。
---

# 优先级链 Priority Chain

## 概念

多层配置源按优先级排列，形成一条"优先级链"。

- **读（读取/显示）**：从最高优先级向最低遍历，返回第一个有值的配置。即 **"越近越高优先，按高优先显示"**。
- **写（修改/设置）**：修改低优先级层时，自动清除所有更高优先级层的同键值，使未显式设置的高优先层回退到刚修改的低优先层。即 **"修改低优先时候要刷新高优先"**。

示例场景：父分类设置了显示级别（低优先），子分类可以独立设置更高级别（高优先）。子分类的独立设置会覆盖父分类的级别生效。但当父分类的级别被修改时，子分类的独立设置被清除，回退到使用父分类的级别。

## 适用场景

- 多层配置覆盖（全局默认 → 分类默认 → 自身设置）
- 权限继承（角色基础权限 → 部门额外权限 → 个人特殊权限）
- 主题定制（全局主题 → 页面主题 → 组件主题）
- 功能开关（平台开关 → 租户开关 → 用户开关）
- UI 显示级别（全局视图模式 → 父分类级别 → 自身级别）

## 场景举例

如 项目列表.html 中有如下样式：

| 类型                                                         | 优先级 | 控制按钮                         |
| ------------------------------------------------------------ | ------ | -------------------------------- |
| 全局顶部悬浮按钮                                             | 0      | 三档分段控制 repo + pod +podspec |
| ## 祖分类（如UI控件：含基础UI、弹窗UI、下拉刷新上拉加载UI等） | --     | 不控制                           |
| ### 父分类1（如基础UI：含CJUIKit、BaseUIKit、BaseVCKit）     | 1      | 三档分段控制 repo + pod +podspec |
| #### 子分类1.1（如 CJUIKit）                                 | 2      | 三档分段控制 repo + pod +podspec |
| #### 子分类1.2（如 BaseUIKit）                               | 2      | 三档分段控制 repo + pod +podspec |
| #### 子分类1.3（如 BaseVCKit）                               | 2      | 三档分段控制 repo + pod +podspec |

要求实现的**设档**行为是：

**1. 低优先级的 全局顶部悬浮按钮 选择任何档，高优先级的都应该刷新调整和其一样的档，不管之前自己设的档是比它高还是低。**

**2. 显示的时候使用高优先级的档，不用管低优先级是设置什么档**

举例说明如下：

初始：低优先级的全局 repo+pod，高优先级的子分类也是和全局一样是 repo+pod

Step1：低优先级的全局换挡到 repo，则低优先级的子分类也要跟着换挡到 repo 档，并显示repo数据

Step2：高优先级的子分类换挡到 repo+pod+podspec，则应该显示 repo+pod+podspec 数据，虽然此时低优先的全局还是repo



## 数据结构

```
Layers: Array<Map<key, value>>
  索引 0  = 最低优先级（最先被覆盖，作用范围最广）
  索引 N  = 最高优先级（最终生效，作用范围最窄）
```

不需要存储"设置了什么优先级"，只需按层存储值。优先级由层索引隐式决定。

## 核心操作

### read(key)

从最高层向最低层遍历，返回第一个有值的层的结果：

```
read(key):
  for layer in [N, N-1, ..., 0]:    // 从高到低
    if layers[layer].has(key):
      return layers[layer][key]
  return null                        // 所有层都没有
```

**效果**：高优先覆盖低优先。设置了就用，没设置就 fallback 到更低层。

### write(layerIndex, key, value)

写入指定层，然后清除所有更高层的同名 key：

```
write(layerIndex, key, value):
  layers[layerIndex][key] = value
  for layer in [layerIndex+1, ..., N]:   // 清除所有更高层
    delete layers[layer][key]
```

**效果**：修改低优先层时，自动刷掉高优先层的覆盖。下次 read 时，该 key 的值会回退到刚修改的层。

### clearAll()

清空所有层，回到完全无配置状态。

## 实现模板

### JavaScript

```javascript
function PriorityChain(layerCount) {
  this.layers = Array.from({length: layerCount}, () => ({}));

  this.read = function(key) {
    for (let i = this.layers.length - 1; i >= 0; i--) {
      if (key in this.layers[i]) return this.layers[i][key];
    }
    return null;
  };

  this.write = function(layerIndex, key, value) {
    this.layers[layerIndex][key] = value;
    for (let i = layerIndex + 1; i < this.layers.length; i++) {
      delete this.layers[i][key];
    }
  };

  this.clearAll = function() {
    this.layers = Array.from({length: this.layers.length}, () => ({}));
  };
}
```

### Python

```python
class PriorityChain:
    def __init__(self, layer_count):
        self.layers = [{} for _ in range(layer_count)]

    def read(self, key):
        for layer in reversed(self.layers):
            if key in layer:
                return layer[key]
        return None

    def write(self, layer_index, key, value):
        self.layers[layer_index][key] = value
        for i in range(layer_index + 1, len(self.layers)):
            self.layers[i].pop(key, None)

    def clear_all(self):
        self.layers = [{} for _ in range(len(self.layers))]
```

### TypeScript

```typescript
class PriorityChain<T> {
  private layers: Map<string, T>[];

  constructor(layerCount: number) {
    this.layers = Array.from({length: layerCount}, () => new Map());
  }

  read(key: string): T | null {
    for (let i = this.layers.length - 1; i >= 0; i--) {
      if (this.layers[i].has(key)) return this.layers[i].get(key)!;
    }
    return null;
  }

  write(layerIndex: number, key: string, value: T): void {
    this.layers[layerIndex].set(key, value);
    for (let i = layerIndex + 1; i < this.layers.length; i++) {
      this.layers[i].delete(key);
    }
  }

  clearAll(): void {
    this.layers = Array.from({length: this.layers.length}, () => new Map());
  }
}
```

## 实例：dvlproad 项目列表

### 层级定义

| 层 | 索引 | 名称 | 存储对象 | 修改触发 |
|----|------|------|---------|---------|
| global | 0 | 全局视图模式 | `viewMode`（单值） | 页面顶部 toolbar 切换 |
| parent | 1 | 父分类级别 | `catDetailLevel[parentType]` | 父分类 seg 控件设置 |
| self | 2 | 自身分类级别 | `catDetailLevel[selfType]` | 自身 seg 控件设置 |

### 数据结构简化为平铺

实际实现时不需要真的用嵌套 layers 数组，层的信息通过**不同的 key 命名约定**或**不同的存储对象**来区分：

```javascript
// 不存 layers 数组，而是用不同的对象表示不同层：
const globalLevel = {
  value: 2  // viewMode 映射后的级别
};
const catDetailLevel = {};  // 同时存储 parent 层和 self 层，但用不同 key 区分
```

读的 fallback 链通过 `??` 运算符实现：

```javascript
// 读：从高到低 fallback
const level = catDetailLevel[selfType] ?? catDetailLevel[parentType] ?? viewModeToLevel(viewMode);
//          ^^^^^^^^^^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^^^^^^^
//          层 2（自）                   层 1（父）                  层 0（全局）
```

写的清除通过 `clearDescendantLevels` 实现：

```javascript
// 写 layer 1（父分类）
function setCatLevel(type, level) {
  catDetailLevel[type] = level;        // 写入 layer 1
  const item = findItemByType(appData.repos, type);
  if (item) clearDescendantLevels(item); // 清除所有 layer 2 的对应 key
  updateCat(type);
}
function clearDescendantLevels(item) {
  if (!item.children) return;
  for (const c of item.children) {
    delete catDetailLevel[c.type];     // 删掉 layer 2
    clearDescendantLevels(c);           // 递归清除更深的后代
  }
}

// 写 layer 0（全局）
function setViewMode(mode) {
  viewMode = mode;
  catDetailLevel = {};                  // 清空所有 layer 1 + 2
  render();
}
```

### 行为追踪

以"基础UI（父分类）→ CJUIKit（子分类）"为例：

| 操作 | layer 0 (global) | layer 1 (基础UI) | layer 2 (CJUIKit) | 显示结果 |
|------|-----------------|-----------------|------------------|---------|
| 初始 | `value=2` | `{}` | `{}` | level = `undefined ?? undefined ?? 2` = **2** |
| CJUIKit → +Subspec | `value=2` | `{}` | `{CJUIKit:3}` | level = `3 ?? undefined ?? 2` = **3** |
| 基础UI → +Pod | `value=2` | `{基础UI:2}` | CJUIKit 被 delete | level = `undefined ?? 2 ?? 2` = **2** |
| CJUIKit → +Subspec | `value=2` | `{基础UI:2}` | `{CJUIKit:3}` | level = `3 ?? 2 ?? 2` = **3** |
| 全局 → 项目 | `value=1` | 全部清空 | 全部清空 | level = `undefined ?? undefined ?? 1` = **1** |

### 关键代码位置

- 读 fallback: `renderSubCategory` 中 `const level = catDetailLevel[item.type] ?? parentLevel ?? viewModeToLevel(viewMode);`
- 写 layer 2 + 清除 layer 1: `setCatLevel` → `clearDescendantLevels`
- 写 layer 0 + 清除全部: `setViewMode` → `catDetailLevel = {}`
- 全局映射: `viewModeToLevel` 将 `'repo'|'pod'|'subspec'` 映射为 `1|2|3`

## 与类似模式的区别

| 模式 | 特点 | 区别 |
|------|------|------|
| 优先级链 | 修改低优先时清除高优先 | 主动刷新，保证回退一致性 |
| 责任链 | 按序传递请求，任一层可中断 | 不涉及配置覆盖和清除 |
| CSS 层叠 | 高优先覆盖低优先，不可变 | 没有"修改低优先刷新高优先"的传播 |
| Git 配置 (system/global/local) | 逐层覆盖，不会自动清除 | 手动指定覆盖层 |
