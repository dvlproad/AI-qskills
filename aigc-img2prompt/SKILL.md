---
name: aigc-img2prompt
version: 0.0.1
description: 反推图片，将其转换成结构化 JSON，作为生成提示词。覆盖产品外观、构图、灯光、镜头角度、材质、颜色、阴影与反射、空间关系、整体视觉风格等维度。
---

# aigc-img2prompt

分析图片，生成结构化 JSON 提示词。支持反推分析 + 基于 JSON 的图片生成。

## 触发条件

当用户说以下内容时触发：
- "反推这张图片"
- 其他表达分析图片为结构化数据的意图

## 执行流程

### 1. 确认图片

- 确认用户已提供图片（文件路径或 URL）
- 如未提供，要求用户提供图片

### 2. 逐维度分析

按以下顺序逐一分析图片的每个维度：

#### 2.1 图片类型

判断是电商产品图、生活场景图、人像、风景、概念图、渲染图等。

#### 2.2 整体场景

- environment：环境描述（如：温馨室内桌面场景/户外庭院/专业摄影棚/书房/厨房等）
- style：风格标签（如：北欧极简/工业风/侘寂风/赛博朋克/复古/未来感/自然清新等，用2-4个词）
- mood：情绪感受（如：温暖、安静、治愈、专业、高级、神秘、活力、冷峻等，用2-4个词）
- visual_focus：视觉焦点（描述画面最吸引注意力的元素）
- depth：景深效果（如：浅景深/中等景深/全景深）
- background：背景类型、颜色、纹理、光照效果

#### 2.3 主体产品/对象

按层级拆解产品结构：
- category：产品类别（如：桌面触控台灯/蓝牙音箱/咖啡杯/电动牙刷等）
- position：画面位置（中央/偏左/偏右/对角线等）
- orientation：朝向（垂直/水平/倾斜/侧向）
- visual_weight：视觉占比估计（如：占据画面约60%注意力）
- components：组件分解（每个组件含 name/shape/material/texture/color/lighting/reflection）

#### 2.4 辅助对象

列表形式描述画面中其他对象：
- name / position / shape / material / color / texture
- 与主体的关系（relationship_to_main_product）

#### 2.5 灯光设置

- primary_light：主光源（source如"台灯自身/窗外自然光/顶部射灯"，color_temperature暖/冷/中性，intensity强/中/弱，effect描述）
- secondary_light：辅助光（source/softness/purpose）
- shadow_characteristics：阴影特征（type硬阴影/柔和阴影/无明显阴影，direction方向，contrast高/中/低）
- reflection_characteristics：反射特征（按材质分类，如金属高光/木材哑光/玻璃镜面反射等）

#### 2.6 构图

- camera_angle：镜头角度（height平视/俯视/仰视 + 相对主体高度，perspective透视关系，lens_style广角/标准/长焦，distortion低/中/高）
- framing：构图布局（layout中心构图/三分法/对角线/对称/引导线等，balance画面平衡感，negative_space留白多少）
- depth_layers：景深层次（foreground前景物体列表，midground中景物体列表，background背景元素列表）

#### 2.7 材质表面

按材质类型描述：
- wood/metal/fabric/ceramic/glass/plastic 等
- 每个材质含 finish 和 texture_visibility

#### 2.8 色彩

- dominant_colors：主色调（如：暖白/米色/浅木色，按面积降序列出2-3个）
- accent_colors：点缀/强调色（如：青蓝色/绿色/红色，用于视觉焦点或按钮等小面积元素）
- overall_tone：整体色调倾向（如：低饱和暖色调/高饱和冷色调/中性灰调）

#### 2.9 视觉风格

- rendering_style：渲染/拍摄风格（如：超写实商业摄影/胶片感/3D渲染/自然光写实/插画风）
- commercial_intent：商业意图（如：突出产品质感/营造生活方式氛围/展示功能交互/强调性价比）
- editing_style：后期处理风格（如：高光柔化/低对比/干净修图/胶片颗粒/高饱和）
- brand_feeling：品牌感受（如：高端家居/智能科技/自然环保/年轻时尚/专业工具）

### 3. 生成 JSON

- 使用层级结构组织 JSON
- **不要虚构不可见信息**（如看不到材质细节则不写）
- 仅返回合法 JSON，没有任何前后缀说明文字
- 必须包裹在 ```json ``` 代码块中

### 4. 基于 JSON 生成（可选）

如用户提供"更新后的 JSON"，执行：
1. 对比原图 JSON 与更新后 JSON，识别变化点
2. 保持原图的：构图、灯光、风格氛围
3. 根据更新后 JSON 生成新图片的提示词
4. 输出可直接用于 AI 绘图工具的提示词文本

## 核心原则

### 只写所见

| 原则 | 说明 |
|------|------|
| 可见即写 | 只描述图片中实际可见的信息 |
| 不可见不写 | 例如看不到材质细节就不写 `texture` 字段 |
| 不确定需说明 | 用 `"uncertain": true` 标记不确定的判断 |

### 层级结构

JSON 必须使用层级嵌套，而非扁平结构。最大深度不超过 4 层。

### 维度覆盖

以下维度必须至少覆盖 6 个：
1. 产品外观
2. 构图
3. 灯光
4. 镜头角度
5. 材质
6. 颜色
7. 阴影与反射
8. 空间关系
9. 整体视觉风格

## JSON 结构模板

```json
{
  "image_type": "图片类型（如：电商产品图/生活场景图/静物摄影/室内设计图等）",
  "overall_scene": {
    "environment": "环境描述（如：温馨室内桌面场景/户外庭院/工作室等）",
    "style": "风格标签（如：北欧极简/工业风/复古/未来感等，用2-4个词）",
    "mood": "情绪感受（如：温暖、安静、治愈、专业、高级等，用2-4个词）",
    "visual_focus": "视觉焦点是什么（描述主体产品和交互动作）",
    "depth": "景深特征（如：浅景深/中等景深/全景深）",
    "background": {
      "type": "背景类型（纯色墙面/自然风景/虚化光斑/生活空间等）",
      "color": "背景主色",
      "texture": "纹理描述",
      "lighting_effect": "背景上的光效"
    }
  },
  "main_product": {
    "category": "产品类别",
    "position": "画面位置（中央/偏左/偏右等）",
    "orientation": "朝向（垂直/水平/倾斜）",
    "visual_weight": "视觉占比估计（如：占据约60%注意力）",
    "components": [
      {
        "name": "部件名称（如：灯罩/底座/支撑杆）",
        "shape": "形状",
        "material": "材质",
        "texture": "纹理",
        "color": "颜色",
        "lighting": {
          "state": "光照状态（如：点亮/未点亮/背光等）",
          "brightness": "亮度（高亮/中等/暗）",
          "glow": "光晕特征"
        },
        "reflection": "反射特征"
      }
    ]
  },
  "supporting_objects": [
    {
      "name": "物体名称",
      "position": "位置（前景/中景/背景 + 左右方向）",
      "material": "材质",
      "color": "颜色",
      "relationship_to_main_product": "与主体的关系（如：衬托/功能连接/氛围补充）"
    }
  ],
  "lighting_setup": {
    "primary_light": {
      "source": "主光源来源（如：台灯自身/窗外自然光/顶部射灯）",
      "color_temperature": "色温（暖/冷/中性/混合）",
      "intensity": "强度（强/中/弱）",
      "effect": "产生的效果（如：形成中心高亮与背景渐变）"
    },
    "secondary_light": {
      "source": "辅助光源",
      "softness": "柔和度",
      "purpose": "作用（如：降低阴影对比度/补亮暗部）"
    },
    "shadow_characteristics": {
      "type": "阴影类型（硬阴影/柔和阴影/无明显阴影）",
      "direction": "方向",
      "contrast": "对比度（高/中/低）"
    },
    "reflection_characteristics": "整体反射特征描述（如：金属高光/木材哑光/桌面漫反射）"
  },
  "composition": {
    "camera_angle": {
      "height": "拍摄高度（平视/俯视/仰视 + 相对主体的高度描述）",
      "perspective": "透视关系（如：正面轻微俯视）",
      "lens_style": "焦段感（广角/标准/长焦）",
      "distortion": "畸变程度（低/中/高）"
    },
    "framing": {
      "layout": "构图方式（中心构图/三分法/对角线/对称等）",
      "balance": "画面平衡感",
      "negative_space": "留白处理"
    },
    "depth_layers": {
      "foreground": ["前景物体列表"],
      "midground": ["中景物体列表"],
      "background": ["背景元素列表"]
    }
  },
  "surface_and_materials": {
    "wood": {
      "finish": "表面处理（哑光/亮光/未处理）",
      "texture_visibility": "纹理可见度（明显/细微/不可见）"
    },
    "metal": {
      "finish": "表面处理（抛光/拉丝/哑光）",
      "reflection": "反射特征（镜面高光/柔和高光/无）"
    },
    "fabric": {
      "finish": "表面处理（半透光/不透光/磨砂）",
      "texture": "纹理描述"
    },
    "ceramic": {
      "finish": "表面处理（光泽/哑光/釉面）",
      "texture": "纹理描述"
    },
    "glass": {
      "finish": "表面处理（透明/磨砂/镜面）",
      "reflection": "反射特征"
    },
    "plastic": {
      "finish": "表面处理",
      "texture": "纹理描述"
    }
  },
  "color_palette": {
    "dominant_colors": ["主色1", "主色2", "主色3"],
    "accent_colors": ["点缀色1", "点缀色2"],
    "overall_tone": "整体色调倾向（如：低饱和暖色调/高饱和冷色调/中性灰调）"
  },
  "visual_style": {
    "rendering_style": "渲染/拍摄风格（如：超写实商业摄影/胶片感/3D渲染/自然光写实）",
    "commercial_intent": "商业意图（如：突出产品质感/营造生活方式氛围/展示功能交互）",
    "editing_style": "后期处理风格（如：高光柔化/低对比/干净修图/胶片颗粒）",
    "brand_feeling": "品牌感受（如：高端家居/智能科技/自然环保/年轻时尚）"
  }
}
```

## 版本记录

### 0.0.1 (2026-06-08): 初始版本
