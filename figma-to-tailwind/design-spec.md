# 长鑫项目 - Host Core UI 设计规范

## 📋 设计概览

**项目**: 长鑫项目  
**节点**: Title Bar (顶部导航栏)  
**设计风格**: 现代简洁、B端后台系统  
**尺寸**: 1708×48px (自适应宽度)

---

## 🎨 颜色系统 (Design Tokens)

### 主色调
| 名称 | 色值 | 用途 |
|------|------|------|
| Primary Blue | `#055CB9` | 主按钮、链接文字、图标 |
| Light Blue BG | `#E6F0FF` | 标签背景、下拉选择器背景 |
| Accent Green | `#01C59D` | 搜索图标背景 |
| Error Red | `#FC465C` | 通知徽标、错误提示 |

### 中性色
| 名称 | 色值 | 用途 |
|------|------|------|
| Text Primary | `#1A1A1A` | 主要文字 |
| Text Secondary | `#71718A` | 次要文字、下拉箭头 |
| Text Muted | `rgba(0,0,0,0.2)` | Placeholder文字 |
| Border Light | `rgba(0,0,0,0.05)` | 分割线、边框 |
| Background | `#FFFFFF` | 页面背景 |
| Search BG | `#DDE8EB` | 搜索框背景 |

---

## 🔤 字体规范

### 字体栈
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```

### 字号层级
| 级别 | 大小 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| Body | 14px | 400 (Regular) | 100% | 正文、标签文字 |
| Small | 12px | 400 (Regular) | 100% | 辅助文字、用户名 |
| Medium | 14px | 500 (Medium) | 100% | 按钮文字、Group标签 |

---

## 📐 间距系统

### 内边距
| 组件 | 数值 |
|------|------|
| Header 水平内边距 | 16px |
| 搜索框内边距 | 8px 8px 8px 8px |
| Group 标签内边距 | 10px 24px |
| 添加 Group 按钮 | 10px 8px 10px 10px |
| 语言选择器 | 2px 4px |

### 间距 (Gap)
| 区域 | 数值 |
|------|------|
| 图标与文字间距 | 8px |
| Group 标签之间 | 8px |
| 右侧控件之间 | 12px |
| 右侧区域整体间距 | 18px |

---

## 🧩 组件规范

### 1. 搜索框 (Search)
- **尺寸**: 160×28px
- **背景**: `#DDE8EB`
- **圆角**: 16px (rounded-2xl)
- **图标**: 20×20px 绿色圆形背景 `#01C59D`
- **Placeholder**: "Search"，颜色 `rgba(0,0,0,0.2)`

### 2. Group 标签
- **尺寸**: 100×30px
- **背景**: `#E6F0FF`
- **文字颜色**: `#055CB9`
- **圆角**: 16px (rounded-2xl)
- **内边距**: 10px 24px
- **字号**: 14px / Medium

### 3. 添加 Group 按钮
- **高度**: 30px
- **背景**: `#E6F0FF`
- **圆角**: 16px
- **图标**: Plus 图标 20×20px `#055CB9`
- **内边距**: 10px 8px 10px 10px

### 4. 通知铃铛图标
- **容器尺寸**: 24×24px
- **圆角**: 12px (圆形按钮)
- **图标尺寸**: 20×20px
- **样式**: Duotone (双色)
- **徽标**: 8×8px 红色圆点 `#FC465C`，位于右上角

### 5. 消息图标
- **容器尺寸**: 24×24px
- **圆角**: 12px
- **图标尺寸**: 20×20px
- **样式**: 聊天气泡 + 三个点

### 6. 语言选择器
- **背景**: `#E6F0FF`
- **圆角**: 4px
- **内边距**: 2px 4px
- **地球图标**: 24×24px
- **文字**: "English" 12px / Regular
- **下拉箭头**: 8×4px，50%透明度

### 7. 用户信息
- **容器**: 圆形头像 + 用户名
- **头像尺寸**: 24×24px
- **头像圆角**: 12px (圆形)
- **用户名**: "admin" 12px / Medium
- **间距**: 图标与文字 8px

---

## 🎯 布局结构

```
┌─────────────────────────────────────────────────────────────────┐
│  [搜索框                    ]    [Group 1] [Group 2] [+ Group]   │
│  160px                         100px     100px    auto          │
│                                                                 │
│                    [铃铛][消息][English][👤 admin]              │
└─────────────────────────────────────────────────────────────────┘
```

### Flexbox 布局
- **Header**: `flex justify-between items-center`
- **左侧**: 搜索框固定宽度
- **中间**: Group 标签区域
- **右侧**: 控件组 `flex items-center gap-3`

---

## ⚡ 交互状态

### 悬停状态 (Hover)
| 组件 | 效果 |
|------|------|
| 添加 Group 按钮 | 背景色加深 `#D6E8FF` |
| 图标按钮 | 背景 `rgba(0,0,0,0.05)` |
| 语言选择器 | 背景色加深 |

### 圆角规范
| 组件 | 圆角值 |
|------|--------|
| 搜索框 | 16px (rounded-2xl) |
| Group 标签/按钮 | 16px (rounded-2xl) |
| 图标按钮 | 12px (rounded-xl) |
| 徽标 | 4px |
| 语言选择器 | 4px |

---

## 📱 响应式考虑

- Header 使用自适应宽度
- 搜索框固定 160px 宽度
- Group 标签固定 100px 宽度
- 右侧控件保持固定间距

---

## 🔧 代码实现提示

### Tailwind CSS 类参考
```html
<!-- 搜索框 -->
<div class="w-40 h-7 px-2 py-1 bg-[#DDE8EB] rounded-2xl flex items-center gap-2">
  <div class="w-5 h-5 rounded-full bg-[#01C59D] flex items-center justify-center">
    <!-- 搜索图标 -->
  </div>
  <span class="text-sm text-black/20">Search</span>
</div>

<!-- Group 标签 -->
<div class="h-[30px] px-6 bg-[#E6F0FF] rounded-2xl flex items-center justify-center">
  <span class="text-sm font-medium text-[#055CB9]">Group 1</span>
</div>

<!-- 通知铃铛 -->
<div class="relative w-6 h-6 rounded-xl hover:bg-gray-100 flex items-center justify-center">
  <!-- 铃铛图标 -->
  <span class="absolute -top-0.5 -right-0.5 w-2 h-2 bg-[#FC465C] rounded-full"></span>
</div>
```

---

## 📁 文件信息

- **Figma 文件**: 长鑫项目
- **节点 ID**: 525:7601
- **最后更新**: 2024
- **设计工具**: Figma
