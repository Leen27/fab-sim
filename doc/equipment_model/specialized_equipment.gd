## 2. 特化设备类型
# 文件: scripts/equipment/specialized/

# ============================================
# 2.1 光刻机 (LITHO)
# 文件: litho_equipment.gd
# ============================================

class_name LITHOEquipment
extends BaseEquipment

# 光刻机特有属性
var reticle_id: String = ""  # 当前掩模版
var alignment_precision: float = 0.99  # 对准精度 0-1
var exposure_time: float = 30.0  # 曝光时间
var lamp_lifetime: float = 100000.0  # 光源寿命

# 支持的 Recipe 白名单
var supported_recipes: Array = ["R_LITHO_01", "R_LITHO_02", "R_LITHO_03"]

# 光刻机特有故障库
var litho_faults: Dictionary = {
    "RETICLE_ERROR": {"mttr": 300, "severity": "HIGH"},
    "ALIGNMENT_FAIL": {"mttr": 600, "severity": "HIGH"},
    "LAMP_DEGRADE": {"mttr": 1800, "severity": "MEDIUM"},
    "VACUUM_PUMP": {"mttr": 1200, "severity": "MEDIUM"},
    "TEMPERATURE_DRIFT": {"mttr": 400, "severity": "LOW"}
}

func _init(config: Dictionary):
    super._init(config)
    equipment_type = "LITHO"
    supported_recipes = config.get("recipes", supported_recipes)

## 重写: 检查 Recipe 兼容性
func can_accept_lot(lot_id: String, recipe_id: String) -> bool:
    # 基础检查
    if not super.can_accept_lot(lot_id, recipe_id):
        return false
    
    # 光刻特有: 检查 Recipe 支持
    if not supported_recipes.has(recipe_id):
        return false
    
    # 光刻特有: 检查掩模版
    if reticle_id.is_empty():
        return false
    
    return true

## 重写: 加工质量计算 (光刻精度更高)
func _calculate_quality() -> float:
    var base = super._calculate_quality()
    # 对准精度影响质量
    return base * alignment_precision

## 重写: 获取图标
func get_icon() -> String:
    return "☀️"  # 光刻机图标

## 光刻特有: 更换掩模版
func change_reticle(new_reticle_id: String) -> bool:
    if is_processing:
        return false
    reticle_id = new_reticle_id
    return true

## 重写: 故障代码生成
func _get_alarm_code_for_fault(fault_type: String) -> String:
    if litho_faults.has(fault_type):
        return "LITHO_%s_%s" % [equipment_id, fault_type]
    return super._get_alarm_code_for_fault(fault_type)


# ============================================
# 2.2 清洗机 (CLEAN)
# 文件: clean_equipment.gd
# ============================================

class_name CLEANEquipment
extends BaseEquipment

# 清洗机特有属性
var liquid_level: float = 100.0  # 清洗液液位 0-100
var chemical_type: String = "HF"  # 化学品类型
var rinse_cycles: int = 3  # 冲洗次数

# 支持的 Recipe
var supported_recipes: Array = ["R_CLEAN_01", "R_CLEAN_02"]

# 清洗机故障库
var clean_faults: Dictionary = {
    "PUMP_FAIL": {"mttr": 600, "severity": "HIGH"},
    "LIQUID_LEAK": {"mttr": 1200, "severity": "HIGH"},
    "Chemical_LOW": {"mttr": 180, "severity": "LOW"},
    "DI_WATER_PRESSURE": {"mttr": 300, "severity": "MEDIUM"}
}

func _init(config: Dictionary):
    super._init(config)
    equipment_type = "CLEAN"
    chemical_type = config.get("chemical", "HF")

## 重写: 加工质量 (化学品纯度影响)
func _calculate_quality() -> float:
    var base = super._calculate_quality()
    # 液位低时质量下降
    var liquid_factor = liquid_level / 100.0
    return base * (0.9 + 0.1 * liquid_factor)

## 重写: 获取图标
func get_icon() -> String:
    return "💧"

## 清洗特有: 补充化学品
func refill_chemical(amount: float) -> void:
    liquid_level = min(100.0, liquid_level + amount)

## 重写: 加工中断处理 (清洗机需要排水)
func _on_process_interrupted(fault_type: String) -> void:
    if fault_type == "PUMP_FAIL":
        # 泵故障时中断清洗，Lot 可能需要返工
        pass


# ============================================
# 2.3 扩散炉 (FURNACE - 批量设备)
# 文件: furnace_equipment.gd
# ============================================

class_name FURNACEEquipment
extends BaseEquipment

# 扩散炉特有属性
var max_batch_size: int = 100  # 最大批量
var current_batch: Array = []  # 当前批次中的 Lot 列表
var temperature: float = 800.0  # 当前温度
var target_temperature: float = 800.0
var ramp_rate: float = 5.0  # 升温速率(度/分钟)

# 支持的 Recipe
var supported_recipes: Array = ["R_DIFF_01", "R_DIFF_02", "R_ANNEAL_01"]

# 扩散炉故障库
var furnace_faults: Dictionary = {
    "HEATER_FAIL": {"mttr": 2400, "severity": "HIGH"},
    "GAS_LEAK": {"mttr": 1800, "severity": "HIGH"},
    "TEMP_OVERSHOOT": {"mttr": 600, "severity": "MEDIUM"},
    "QUARTZ_TUBE": {"mttr": 3600, "severity": "HIGH"}
}

func _init(config: Dictionary):
    super._init(config)
    equipment_type = "FURNACE"
    max_batch_size = config.get("batch_size", 100)
    capacity = max_batch_size  # 批量设备的容量

## 重写: 批量设备接收逻辑
func can_accept_lot(lot_id: String, recipe_id: String) -> bool:
    # 检查 Recipe
    if not supported_recipes.has(recipe_id):
        return false
    
    # 检查温度是否就绪
    if abs(temperature - target_temperature) > 10:
        return false
    
    # 检查批次是否已满
    if current_batch.size() >= max_batch_size:
        return false
    
    # 检查 Recipe 一致性 (同批次必须同 Recipe)
    if not current_batch.is_empty():
        var first_lot_recipe = current_batch[0].get("recipe_id")
        if first_lot_recipe != recipe_id:
            return false
    
    return true

## 批量设备特有: 添加 Lot 到批次
func add_to_batch(lot_id: String, recipe_id: String) -> bool:
    if not can_accept_lot(lot_id, recipe_id):
        return false
    
    current_batch.append({
        "lot_id": lot_id,
        "recipe_id": recipe_id
    })
    
    # 达到最小批次或等待超时后才启动
    if current_batch.size() >= _get_min_batch_size():
        _start_batch_processing()
    
    return true

func _get_min_batch_size() -> int:
    """获取最小批次大小"""
    return int(max_batch_size * 0.5)  # 默认 50%

func _start_batch_processing():
    """启动批量加工"""
    is_processing = true
    current_recipe_id = current_batch[0]["recipe_id"]
    process_progress = 0.0
    process_timer = process_time_base
    
    process_started.emit(equipment_id, "BATCH_%d" % current_batch.size(), current_recipe_id)

## 重写: 加工完成 (批量处理)
func _on_process_complete():
    # 批量完成，所有 Lot 一起完成
    var batch_size = current_batch.size()
    
    for lot_info in current_batch:
        var quality = _calculate_quality()
        process_completed.emit(equipment_id, lot_info["lot_id"], current_recipe_id, quality)
    
    total_processed += batch_size
    current_batch.clear()
    is_processing = false
    process_progress = 0.0

## 重写: 获取图标
func get_icon() -> String:
    return "🔥"

## 重写: 状态描述
func get_status_text() -> String:
    if is_processing:
        return "批量加工 %d lots (%.0f%%)" % [current_batch.size(), process_progress * 100]
    if not current_batch.is_empty():
        return "组批中 %d/%d" % [current_batch.size(), max_batch_size]
    return "空闲"


# ============================================
# 2.4 刻蚀机 (ETCH)
# 文件: etch_equipment.gd
# ============================================

class_name ETCHEquipment
extends BaseEquipment

# 刻蚀机特有属性
var chamber_count: int = 2  # 腔室数量
var chamber_status: Array = []  # 每个腔室的状态
var gas_pressure: float = 10.0  # 气压 (mTorr)

# 支持的 Recipe
var supported_recipes: Array = ["R_ETCH_01", "R_ETCH_02", "R_ETCH_03"]

# 刻蚀机故障库
var etch_faults: Dictionary = {
    "CHAMBER_COATING": {"mttr": 1800, "severity": "MEDIUM"},
    "GAS_FLOW_ERR": {"mttr": 400, "severity": "HIGH"},
    "RF_POWER": {"mttr": 600, "severity": "HIGH"}
}

func _init(config: Dictionary):
    super._init(config)
    equipment_type = "ETCH"
    chamber_count = config.get("chambers", 2)
    # 初始化腔室状态
    for i in range(chamber_count):
        chamber_status.append({"busy": false, "lot_id": ""})

## 重写: 刻蚀机支持多腔室并行
func can_accept_lot(lot_id: String, recipe_id: String) -> bool:
    # 检查是否有空闲腔室
    for chamber in chamber_status:
        if not chamber["busy"]:
            return true
    return false

## 重写: 获取图标
func get_icon() -> String:
    return "⚡"


# ============================================
# 2.5 量测设备 (METROLOGY)
# 文件: metrology_equipment.gd
# ============================================

class_name METROLOGYEquipment
extends BaseEquipment

# 量测特有属性
var measurement_accuracy: float = 0.999  # 测量精度
var calibration_date: String = ""  # 校准日期
var measurement_type: String = "CD"  # CD/Thickness/Defect

# 支持的 Recipe
var supported_recipes: Array = ["R_MEAS_CD", "R_MEAS_THK", "R_MEAS_DEFECT"]

func _init(config: Dictionary):
    super._init(config)
    equipment_type = "METROLOGY"
    measurement_type = config.get("meas_type", "CD")
    process_time_base = config.get("process_time", 120.0)  # 量测通常较快

## 重写: 量测不产生质量问题，只产生量测数据
func _calculate_quality() -> float:
    # 量测设备返回测量精度，不是加工质量
    return measurement_accuracy

## 重写: 获取图标
func get_icon() -> String:
    return "🔍"
