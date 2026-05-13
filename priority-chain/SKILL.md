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

## 常见 UI 模式：Segmented Control

优先级链最自然的 UI 表达是**多档分段控件**（segmented control）。

### 映射关系

N 个段位代表 N 级详细程度，每个段位对应一个层索引。选中段位决定当前读取到哪一层：

- seg 段位 0（最简）→ layer 0 级别
- seg 段位 1 → layer 1 级别
- seg 段位 N-1（最详）→ layer N-1 级别

### 填充规则

选中段位 k 时，所有 ≤ k 的段位都亮起，表示"第 k 级包含所有低级别的内容"。即视觉上累进填充：

```
选中 k=0: [██░░░]
选中 k=1: [████░]
选中 k=2: [█████]
```

### 数据流

```
点击 seg[k] → write(layer, key, k) → clearAbove(layer, key) → 重渲染
```

### 适用特征

- 各档位是**累进**的（第 2 档包含第 1 档，第 3 档包含前两者）
- 档位从简到详排列
- 同时只有一档可选中（互斥）
- 每个层级不一定有配置项，fallback 到低优先级取默认值

### 实例

三层叠配置，点击 L0 控件时触发 clearAll，清除所有高优先级的同名键。

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

## 与类似模式的区别

| 模式 | 特点 | 区别 |
|------|------|------|
| 优先级链 | 修改低优先时清除高优先 | 主动刷新，保证回退一致性 |
| 责任链 | 按序传递请求，任一层可中断 | 不涉及配置覆盖和清除 |
| CSS 层叠 | 高优先覆盖低优先，不可变 | 没有"修改低优先刷新高优先"的传播 |
| Git 配置 (system/global/local) | 逐层覆盖，不会自动清除 | 手动指定覆盖层 |
