# AGENTS.md — fab-sim 项目指南

> 本文件面向 AI 编程助手。阅读前请勿对项目做任何假设；以下信息均基于仓库中的实际文件与提交历史整理而成。

---

## 1. 项目概述

**fab-sim**（半导体工厂仿真系统 v0.1）是一个用于验证和演示 MES（制造执行系统）的仿真平台。它通过模拟半导体前道产线的设备运行、WIP 流转和 EAP 行为，帮助在真实产线部署前验证 MES 逻辑。

- **核心定位**：MES 的效果验证与演示平台，不是物理/化学过程仿真。
- **仿真范围**：设备状态机、Bank（缓存区）流转、工艺时间模拟、EAP SECS/GEM 行为模拟（通过 REST API 映射）。
- **不在范围内**：真实的 SECS/GEM 协议栈、AGV/天车物理搬运、设备内部机械运动、真实的工艺参数计算。

**项目当前状态**：骨架阶段。仓库中有非常详细的设计文档，但源码实现大多为空壳或极简 stub。最近一次大规模重构（`5a69f33` 之后）把原先带有完整 Lot 流转 + FIFO 调度的 MVP 实现移除，换成了新的目录结构 stubs。

---

## 2. 技术栈与运行环境

| 层级 | 技术 | 说明 |
|------|------|------|
| 引擎 | **Godot 4.6** | 2D 项目，使用 GL Compatibility 渲染后端 |
| 脚本 | **GDScript** | 全部逻辑用 GDScript 编写 |
| 通信 | **HTTP REST API** | 与 MES 之间仅使用 HTTP（无 WebSocket） |
| 配置 | **JSON** | 工厂模型、EAP 配置、工艺配方均计划使用 JSON |
| 版本控制 | Git | 远程仓库 `git@github.com:Leen27/fab-sim.git` |

### 运行要求
- 安装 **Godot Engine 4.x**（推荐 4.6 及以上）。
- 打开项目根目录下的 `sim/project.godot` 即可启动编辑器或运行场景。
- **没有** `package.json`、`Cargo.toml`、`pyproject.toml` 之类的包管理配置；`server/` 目录目前为空。

---

## 3. 目录结构

```
fab-sim/
├── server/                     # 预留服务端目录（当前为空）
├── sim/                        # Godot 仿真项目
│   ├── project.godot           # Godot 项目配置
│   ├── icon.svg                # 项目图标
│   ├── src/
│   │   ├── eap/
│   │   │   ├── eap_config.gd           # EAP 配置加载（目前仅有一行注释 stub）
│   │   │   └── eap_simulator.gd        # EAP 仿真器核心（目前仅有一行注释 stub）
│   │   ├── factory/            # 工厂模型目录（当前为空）
│   │   ├── scenes/
│   │   │   ├── main.gd         # 主场景脚本（仅实现了 _ready 与空 initialize）
│   │   │   └── main.tscn       # 主场景文件（Node2D + ColorRect + Camera2D + Log）
│   │   └── scripts/
│   │       └── log.gd          # 日志面板控件（功能较完整）
│   └── .godot/                 # Godot 编辑器缓存（已在 .gitignore 中）
├── ReadMe.md                   # v0.1 系统设计文档（非常详细，中文）
├── siview-interface.md         # SiView 风格 MES 接口规范（详细，中文）
├── .gitignore                  # Godot 标准忽略配置
└── AGENTS.md                   # 本文件
```

### 关键源码文件现状
- `sim/src/scenes/main.gd`：入口脚本。当前仅配置了 `factory_config`、`recipe_config`、`eap_config` 等路径，`_ready()` 里打印了一条日志，没有实际加载逻辑。
- `sim/src/scripts/log.gd`：相对完整的日志 UI 组件。支持添加带颜色的日志、自动滚动、性能保护（最大保留条数）、保存到文件。
- `sim/src/eap/*.gd`：几乎为空，仅含中文注释占位。
- `sim/src/factory/`：没有任何文件。

### 设计文档
仓库根目录有两份重量级中文文档，定义了系统的**目标形态**：
1. **`ReadMe.md`**（~2000 行）：系统定位、核心功能（Bank 机制、EAP 仿真、AMHS 简化仿真）、数据模型、仿真引擎设计、可视化设计、REST API 规范、开发计划。
2. **`siview-interface.md`**（~1300 行）：SiView 风格的 SECS/GEM → REST API 映射规范，包含 S1F3/S1F4、S2F41/S2F42、S6F11/S6F12、S7F3/S7F4 等消息的 JSON 格式定义。

> **注意**：这两份文档描述的是“应当做成什么样”，不是“现在已经实现成什么样”。当前源码距离文档中的完整设计还有大量工作要做。

---

## 4. 构建与运行

### 在 Godot 编辑器中运行
1. 打开 Godot Project Manager。
2. 导入 `sim/project.godot`。
3. 直接按 F5 运行主场景 `res://src/scenes/main.tscn`。

### 命令行运行（如已安装 godot CLI）
```bash
cd sim
godot --path . --scene src/scenes/main.tscn
```

### 导出发布
- 目前无 CI/CD 配置。
- 如需导出，使用 Godot 内置的导出模板（Export → 选择平台）。

---

## 5. 代码风格与开发约定

### 命名规范（从现有代码与 Godot 惯例推断）
- **文件/目录**：小写 + 下划线（`eap_simulator.gd`、`main.tscn`）。
- **GDScript 变量/函数**： snake_case（`log_panel`, `add_log`, `_scroll_to_bottom`）。
- **类名/节点名**：PascalCase（`Node2D`, `ColorRect`, `ItemList`）。
- **常量**：全大写下划线分隔（Godot 惯例）。
- **信号**：PascalCase（Godot 惯例）。

### 注释与文档
- 项目中主要使用**中文**进行注释和文档编写。
- 新增代码建议保持中文注释，以与现有文档风格一致。

### 场景组织
- 场景文件（`.tscn`）与对应脚本（`.gd`）放在同一目录或相邻目录。
- 使用 `@onready var` 进行节点引用缓存。
- UI 逻辑与业务逻辑当前混在一起（`main.gd` 中既有场景引用也有配置字典），后续如需扩展，建议按设计文档分层：
  - `core/` — 仿真引擎（时间控制器、设备状态机、Bank 调度器）
  - `mes/` — MES 接口层（HTTP 客户端/服务端）
  - `factory/` — 工厂模型（Equipment、Bank、Recipe）
  - `ui/` — 可视化与交互

### 逻辑与视觉分离（设计文档中的强制原则）
> 如果 MES 不需要它来完成派工决策，它就不应该出现在 MES 接口中。
- 所有与 MES 交互的数据（设备 ID、类型、Area、Bank 关联、状态）必须是**纯逻辑数据**，不包含屏幕坐标、颜色、图标路径。
- 视觉配置计划放在独立的 `visual.json` 中，不影响 MES 接口。

---

## 6. 测试策略

**当前状态：没有自动化测试。**

根据 `ReadMe.md` 中的开发计划，未来计划包含以下验证手段：
- `tests/mes_mock_server.py` — MES 模拟服务（用于联调）。
- `tests/eap_test_client.py` — EAP 测试客户端。
- 手动场景验证：正常派工、设备异常、优先级调度、工艺参数传递、WIP 追溯、良率统计、EAP 事件上报等。

在添加测试时，建议：
1. 由于这是 Godot 项目，优先使用 Godot 内置的 **GUT (Godot Unit Test)** 或轻量的场景断言脚本。
2. 对于 HTTP 接口逻辑，可用 Python 编写 mock MES 和集成测试脚本，放在 `tests/` 目录。

---

## 7. 关键接口与配置（设计态）

以下信息来自 `ReadMe.md` 和 `siview-interface.md`，供开发时参考：

### 仿真系统 ↔ MES 通信方式
- **仅使用 HTTP**，不使用 WebSocket。
- 仿真系统作为 HTTP Client 主动 POST 到 MES 回调地址。
- 仿真系统也作为 HTTP Server 接收 MES 下发的指令。

### 仿真系统服务端端点（MES 可调用）
| 方法 | 端点 | 用途 |
|------|------|------|
| POST | `/api/v1/equipment/command` | 设备控制指令 |
| POST | `/api/v1/bank/dispatch` | Bank 派工 |
| POST | `/api/v1/eap/command` | EAP 远程指令 (S2F41) |
| GET | `/api/v1/equipment/{id}/status` | 查询设备状态 |
| GET | `/api/v1/bank/{id}/status` | 查询 Bank 状态 |
| GET | `/api/v1/events/pending` | 获取待处理事件 |

### MES 回调端点（仿真系统调用）
| 方法 | 端点 | 用途 |
|------|------|------|
| POST | `/api/v1/mes/equipment/status` | 设备状态上报 |
| POST | `/api/v1/mes/bank/event` | Bank 事件上报 |
| POST | `/api/v1/mes/eap/event` | EAP 事件上报 (S6F11) |
| POST | `/api/v1/mes/lot/complete` | 批次完成上报 |

### 计划中的配置文件
- `config/factory.json` — 工厂布局与 Bank 定义
- `config/recipe.json` — 工艺流程
- `config/eap_config.json` — EAP 变量、事件、指令定义
- `config/mes.json` — MES 连接地址与认证

> 注意：`config/` 目录目前并不存在，相关路径在 `main.gd` 中只是硬编码的字符串字典。

---

## 8. 安全注意事项

- 本项目当前没有任何身份验证、TLS 或加密实现。
- `mes.json` 设计文档中提到了 `${MES_TOKEN}` 环境变量占位，但目前没有实际加载逻辑。
- 如果后续添加真实的 MES 连接，请务必：
  1. 将 token、密码等敏感信息放入环境变量或 Godot 的导出变量（Export Vars），不要硬编码在 Git 中。
  2. 不要提交 `config/mes.json` 的副本到仓库（应在 `.gitignore` 中忽略 `config/mes.json` 或提供 `mes.example.json`）。

---

## 9. 对 AI 助手的特别提示

1. **不要过度假设实现已存在**：很多看起来很详细的类/模块/接口目前只是文档里的文字，源码中还没有对应文件。
2. **修改前优先查看 `ReadMe.md` 和 `siview-interface.md`**：这两份文档是该项目的“规格书”，新增功能应与其保持一致。
3. **保持中文注释和文档**：项目的主要交流语言是中文。
4. **Godot 4 的 `.uid` 文件**：当新建 `.gd` 脚本或 `.tscn` 场景时，Godot 会自动生成 `.uid` 文件，提交时建议一并包含。
5. **Emoji 谨慎使用**：早期提交 `d802874` 专门修复了场景文件中 Emoji 导致 Godot 解析错误的问题。在 `.tscn`、`.gd` 和配置文件中避免使用 Emoji，UI 中如需显示可用 Unicode 字符或 Godot Label 的富文本替代方案。
