Technology ──► Product Group ──► Product ──► Main Flow ──► Sub Flow ──► Step ──► Logical Recipe ──► Recipe ──► EQP ──► Chamber / Port

【技术】       【产品组】         【产品】      【主流程】      【子流程】      【工序】      【逻辑配方】         【物理配方】    【设备】     【腔体/端口】


🎯 层级关系说明


| 层级                 | 含义                    | 继承关系                       |
| ------------------ | --------------------- | -------------------------- |
| **Technology**     | 工艺技术（如28nm、14nm、7nm）  | 顶层分类                       |
| **Product Group**  | 产品组（如DRAM、NAND、Logic） | 属于一个Technology             |
| **Product**        | 具体产品型号                | 属于一个Product Group          |
| **Main Flow**      | 主流程                   | Product可指定一个Main Flow      |
| **Sub Flow**       | 子流程                   | Main Flow由多个Sub Flow组成     |
| **Step**           | 工序（单个加工步骤）            | Sub Flow由多个Step组成          |
| **Logical Recipe** | 逻辑配方（条件化Recipe）       | Step依据条件最终指定               |
| **Recipe**         | 物理配方（具体工艺参数）          | Logical Recipe可由多个Recipe达成 |
| **EQP**            | 设备类型                  | Recipe可由多个EQP达成            |
| **Chamber**        | 工艺腔体                  | EQP包含多个Chamber             |
| **Port**           | 设备端口                  | EQP包含多个Port                |

🔄 覆盖机制（Overwrite）
图中橙色框表示上层配置可以被下层覆盖：

| 覆盖类型                         | 位置                  | 说明                 |
| ---------------------------- | ------------------- | ------------------ |
| **Qtime Overwrite**          | Main Flow层          | 在Main Flow层覆盖Qtime |
| **DC Item / Spec Overwrite** | Main Flow/Sub Flow层 | 数据采集项/规格覆盖         |
| **EQP / Recipe Overwrite**   | Logical Recipe层     | 设备/配方覆盖            |

💡 关键设计：Logical Recipe Rule Decide

Step ──► [Logical Recipe Rule Decide] ──► Logical Recipe
              │
              ├── 按 Technology 选
              ├── 按 Product Group 选
              └── 按 Product 选

作用：同一个Step，根据产品类型动态决定使用哪个Logical Recipe！

🏭 实例说明

Technology: 28nm Logic
    │
    ▼
Product Group: Mobile SoC
    │
    ▼
Product: Smartphone Chip A
    │
    ▼
Main Flow: Standard_28nm_Flow
    │
    ▼
Sub Flow: Litho_Module
    │
    ▼
Step: Photo_Exposure
    │
    ▼
Logical Recipe Rule Decide:
    ├─ 如果是Product A → Logical Recipe: Photo_A
    └─ 如果是Product B → Logical Recipe: Photo_B
    │
    ▼
Logical Recipe: Photo_A
    │
    ▼
Recipe: EXP_28NM_001, EXP_28NM_002 (多个可选)
    │
    ▼
EQP: Litho_Machine_A, Litho_Machine_B (多个可选)
    │
    ▼
Chamber: Chamber_1, Chamber_2, Chamber_3, Chamber_4

```
# FabSim需要实现的多层级配置

class Technology:
    var tech_id: String
    var product_groups: Array[ProductGroup]

class ProductGroup:
    var group_id: String
    var technology: Technology
    var products: Array[Product]

class Product:
    var product_id: String
    var product_group: ProductGroup
    var main_flow: MainFlow  # 关联主流程

class MainFlow:
    var flow_id: String
    var sub_flows: Array[SubFlow]
    var qtime_overwrites: Dictionary  # Qtime覆盖

class SubFlow:
    var sub_flow_id: String
    var steps: Array[Step]
    var dc_overwrites: Dictionary  # DC覆盖

class Step:
    var step_id: String
    var logical_recipe_rule: LogicalRecipeRule  # 条件决策

class LogicalRecipeRule:
    # 根据条件返回Logical Recipe
    func decide(product: Product) -> LogicalRecipe:
        pass

class LogicalRecipe:
    var logical_recipe_id: String
    var recipes: Array[Recipe]  # 多个可选Recipe
    var eqp_overwrites: Dictionary

class Recipe:
    var recipe_id: String
    var eqps: Array[EQP]  # 多个可选设备

class EQP:
    var eqp_id: String
    var chambers: Array[Chamber]
    var ports: Array[Port]
```