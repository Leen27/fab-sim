# FabSim Pro - 分层设备模型设计
# Godot 4.x GDScript 实现

## 1. 基础设备类 (BaseEquipment)
# 文件: scripts/equipment/base_equipment.gd

class_name BaseEquipment
extends RefCounted

# ============================================
# 信号定义
# ============================================
signal state_changed(equipment_id, old_state, new_state)
signal process_started(equipment_id, lot_id, recipe_id)
signal process_completed(equipment_id, lot_id, recipe_id, quality)
signal alarm_triggered(equipment_id, alarm_code, alarm_text)
signal alarm_cleared(equipment_id, alarm_code)

# ============================================
# 基础属性 (引擎层关心的数学参数)
# ============================================
var equipment_id: String
var equipment_name: String
var equipment_type: String  # "LITHO", "CLEAN", "FURNACE" 等

# 能力参数
var capacity: int = 1  # 加工容量 (1=单片, >1=批量)
var process_time_base: float = 600.0  # 基础加工时间(秒)
var process_time_variance: float = 0.05  # 时间波动 5%

# 可靠性参数 (MTBF/MTTR)
var mtbf: float = 3600.0  # 平均故障间隔(秒)
var mttr: float = 900.0   # 平均修复时间(秒)
var current_health: float = 100.0  # 设备健康度 0-100

# 状态变量 (离散事件仿真核心)
var is_available: bool = true
var is_processing: bool = false
var current_lot_id: String = ""
var current_recipe_id: String = ""
var process_progress: float = 0.0  # 0.0 - 1.0
var process_timer: float = 0.0

# 统计信息
var total_processed: int = 0
var total_downtime: float = 0.0
var utilization_history: Array = []

# ============================================
# 初始化
# ============================================
func _init(config: Dictionary):
    equipment_id = config.get("id", "EQP_UNKNOWN")
    equipment_name = config.get("name", "Unknown Equipment")
    equipment_type = config.get("type", "GENERIC")
    capacity = config.get("capacity", 1)
    process_time_base = config.get("process_time", 600.0)
    process_time_variance = config.get("variance", 0.05)
    mtbf = config.get("mtbf", 3600.0)
    mttr = config.get("mttr", 900.0)

# ============================================
# 离散事件仿真核心方法
# ============================================

## 处理 Lot 到达事件
func on_lot_arrive(lot_id: String, recipe_id: String) -> bool:
    """
    离散事件: Lot 到达设备
    返回: 是否成功接收
    """
    if not can_accept_lot(lot_id, recipe_id):
        return false
    
    current_lot_id = lot_id
    current_recipe_id = recipe_id
    is_processing = true
    process_progress = 0.0
    
    # 计算实际加工时间 (考虑随机波动)
    var variance = randf_range(-process_time_variance, process_time_variance)
    process_timer = process_time_base * (1.0 + variance)
    
    process_started.emit(equipment_id, lot_id, recipe_id)
    return true

## 仿真时间推进 (每帧调用)
func update(delta: float) -> void:
    """
    离散事件仿真更新
    delta: 仿真时间步长(秒)
    """
    if not is_processing or not is_available:
        return
    
    # 推进加工进度
    process_progress += delta / process_timer
    
    # 加工完成
    if process_progress >= 1.0:
        _on_process_complete()

## 加工完成处理
func _on_process_complete():
    is_processing = false
    process_progress = 1.0
    total_processed += 1
    
    var quality = _calculate_quality()
    process_completed.emit(equipment_id, current_lot_id, current_recipe_id, quality)
    
    # 清理当前 Lot
    var completed_lot = current_lot_id
    current_lot_id = ""
    current_recipe_id = ""
    process_progress = 0.0

## 计算加工质量 (可被特化类重写)
func _calculate_quality() -> float:
    """
    返回 0.0-1.0 的质量分数
    基础实现: 健康度越高，质量越好
    """
    var base_quality = 0.95
    var health_factor = current_health / 100.0
    return base_quality * health_factor + randf_range(-0.02, 0.02)

## 检查是否可以接收 Lot
func can_accept_lot(lot_id: String, recipe_id: String) -> bool:
    """
    检查设备是否可接受此 Lot
    基础检查: 是否空闲 + 是否可用
    特化类可添加更多检查 (Recipe 兼容性等)
    """
    return (not is_processing) and is_available

# ============================================
# 故障管理
# ============================================

var active_alarms: Dictionary = {}  # alarm_code -> alarm_data

func inject_fault(fault_type: String, duration: float = -1) -> void:
    """
    注入故障
    duration: -1 表示使用 MTTR，否则使用指定时间
    """
    var alarm_code = _get_alarm_code_for_fault(fault_type)
    var alarm_data = {
        "code": alarm_code,
        "type": fault_type,
        "start_time": SimulationEngine.current_time,
        "duration": duration if duration > 0 else mttr
    }
    
    active_alarms[alarm_code] = alarm_data
    is_available = false
    
    # 如果正在加工，中断
    if is_processing:
        _on_process_interrupted(fault_type)
    
    alarm_triggered.emit(equipment_id, alarm_code, fault_type)

func clear_fault(alarm_code: String) -> void:
    """清除故障"""
    if active_alarms.has(alarm_code):
        active_alarms.erase(alarm_code)
        
        # 所有故障清除后恢复可用
        if active_alarms.is_empty():
            is_available = true
        
        alarm_cleared.emit(equipment_id, alarm_code)

func _get_alarm_code_for_fault(fault_type: String) -> String:
    """生成报警代码 - 可被特化类重写"""
    return "%s_%s_%d" % [equipment_id, fault_type, Time.get_ticks_msec()]

func _on_process_interrupted(fault_type: String) -> void:
    """加工中断处理 - 可被特化类重写"""
    pass

# ============================================
# 统计数据
# ============================================

func get_utilization(simulation_time: float) -> float:
    """计算设备利用率"""
    if simulation_time <= 0:
        return 0.0
    var busy_time = total_processed * process_time_base
    return busy_time / simulation_time

func get_stats() -> Dictionary:
    """获取设备统计信息"""
    return {
        "equipment_id": equipment_id,
        "equipment_type": equipment_type,
        "total_processed": total_processed,
        "current_health": current_health,
        "is_available": is_available,
        "is_processing": is_processing,
        "active_alarms": active_alarms.size()
    }

# ============================================
# 可视化支持
# ============================================

## 获取设备状态颜色
func get_status_color() -> Color:
    if not active_alarms.is_empty():
        return Color.RED  # 报警
    if not is_available:
        return Color.GRAY  # 离线/维护
    if is_processing:
        return Color.YELLOW  # 加工中
    return Color.GREEN  # 空闲

## 获取设备图标
func get_icon() -> String:
    """返回设备图标 - 必须被特化类重写"""
    return "⬜"  # 默认方块

## 获取状态描述
func get_status_text() -> String:
    if not active_alarms.is_empty():
        return "报警: %s" % active_alarms.keys()[0]
    if not is_available:
        return "离线"
    if is_processing:
        return "加工 %s (%.0f%%)" % [current_lot_id, process_progress * 100]
    return "空闲"
