## 3. GEM 设备仿真 (Mode B 专用)
# 文件: scripts/equipment/gem_equipment.gd

class_name GEMEquipment
extends BaseEquipment

# ============================================
# GEM 状态机
# ============================================

# Communication State (SEMI E30)
var comm_state: String = "DISABLED"  # DISABLED, ENABLED, COMMUNICATING

# Control State (SEMI E30)
var control_state: String = "OFFLINE"  # OFFLINE, ONLINE, LOCAL, REMOTE

# Process State (扩展)
var process_state: String = "IDLE"  # IDLE, SETUP, PROCESSING, PAUSED

# ============================================
# SECS 相关属性
# ============================================

var hsms_connected: bool = false
var device_id: int = 0
var session_id: int = 0

# 状态变量 (Status Variables)
var status_variables: Dictionary = {
    1: {"name": "ControlState", "value": "OFFLINE"},
    2: {"name": "ProcessState", "value": "IDLE"},
    3: {"name": "CurrentRecipe", "value": ""},
    4: {"name": "WaferCount", "value": 0}
}

# 设备常量 (Equipment Constants)
var equipment_constants: Dictionary = {
    1: {"name": "MaxProcessTime", "value": 3600, "min": 0, "max": 7200},
    2: {"name": "MaxBatchSize", "value": capacity, "min": 1, "max": 100}
}

# 收集事件 (Collection Events)
var collection_events: Dictionary = {
    1: "ProcessingStarted",
    2: "ProcessingCompleted",
    3: "AlarmSet",
    4: "AlarmClear",
    5: "ControlStateChanged"
}

# ============================================
# SECS 消息处理器
# ============================================

## S1F1 - Are You Online?
func handle_s1f1(request: SECSMessage) -> SECSMessage:
    """回复在线状态"""
    var response = SECSMessage.new()
    response.stream = 1
    response.function = 2
    response.data = {
        "mdln": equipment_type,
        "softrev": "1.0.0"
    }
    return response

## S1F3 - Selected Equipment Status Request
func handle_s1f3(request: SECSMessage) -> SECSMessage:
    """返回状态变量"""
    var sv_ids = request.data.get("svids", [])
    var response_data = []
    
    for svid in sv_ids:
        if status_variables.has(svid):
            response_data.append({
                "svid": svid,
                "value": status_variables[svid]["value"]
            })
    
    var response = SECSMessage.new()
    response.stream = 1
    response.function = 4
    response.data = response_data
    return response

## S1F13 - Establish Communications Request
func handle_s1f13(request: SECSMessage) -> SECSMessage:
    """建立通信"""
    comm_state = "COMMUNICATING"
    
    var response = SECSMessage.new()
    response.stream = 1
    response.function = 14
    response.data = {
        "commack": 0,  # 0 = Accepted
        "mdln": equipment_type,
        "softrev": "1.0.0"
    }
    return response

## S1F15 - Request Online
func handle_s1f15(request: SECSMessage) -> SECSMessage:
    """请求上线"""
    control_state = "ONLINE"
    _update_sv_control_state()
    
    var response = SECSMessage.new()
    response.stream = 1
    response.function = 16
    response.data = {"oflack": 0}  # 0 = Accepted
    
    # 上报控制状态变化事件
    _send_collection_event(5)
    
    return response

## S1F17 - Request Offline
func handle_s1f17(request: SECSMessage) -> SECSMessage:
    """请求下线"""
    control_state = "OFFLINE"
    _update_sv_control_state()
    
    var response = SECSMessage.new()
    response.stream = 1
    response.function = 18
    response.data = {"oflack": 0}
    
    _send_collection_event(5)
    return response

## S2F13 - Equipment Constant Request
func handle_s2f13(request: SECSMessage) -> SECSMessage:
    """获取设备常量"""
    var ec_ids = request.data.get("ecids", [])
    var response_data = []
    
    for ecid in ec_ids:
        if equipment_constants.has(ecid):
            var ec = equipment_constants[ecid]
            response_data.append({
                "ecid": ecid,
                "ecname": ec["name"],
                "ecmin": ec.get("min", 0),
                "ecmax": ec.get("max", 0),
                "ecdef": ec["value"],
                "ecv": ec["value"]
            })
    
    var response = SECSMessage.new()
    response.stream = 2
    response.function = 14
    response.data = response_data
    return response

## S2F41 - Host Command Send (最重要的消息!)
func handle_s2f41(request: SECSMessage) -> SECSMessage:
    """处理 Host 远程指令"""
    var rcmd = request.data.get("rcmd", "")
    var params = request.data.get("params", [])
    
    var hcack = 0  # 0 = OK
    
    match rcmd:
        "START":
            if not _can_start():
                hcack = 2  # 2 = Cannot perform now
            else:
                var recipe_id = _get_param_value(params, "RecipeID")
                var lot_id = _get_param_value(params, "LotID")
                _gem_start_processing(lot_id, recipe_id)
                
        "STOP":
            _gem_stop_processing()
            
        "PAUSE":
            _gem_pause_processing()
            
        "RESUME":
            _gem_resume_processing()
            
        "ABORT":
            _gem_abort_processing()
            
        _:
            hcack = 1  # 1 = Unknown command
    
    var response = SECSMessage.new()
    response.stream = 2
    response.function = 42
    response.data = {"hcack": hcack}
    return response

## S5F1 - Alarm Report Send (设备主动发送)
func send_s5f1(alarm_code: String, alarm_text: String, is_set: bool) -> void:
    """上报报警"""
    var message = SECSMessage.new()
    message.stream = 5
    message.function = 1
    message.data = {
        "alcd": 1 if is_set else 0,  # 1=Set, 0=Clear
        "alid": alarm_code,
        "altx": alarm_text
    }
    _send_to_host(message)

## S6F11 - Event Report Send (设备主动发送)
func _send_collection_event(ceid: int) -> void:
    """上报收集事件"""
    var event_name = collection_events.get(ceid, "Unknown")
    
    var message = SECSMessage.new()
    message.stream = 6
    message.function = 11
    message.data = {
        "ceid": ceid,
        "ce_name": event_name,
        "equipment_id": equipment_id,
        "timestamp": Time.get_datetime_string_from_system(),
        "reports": _build_event_reports(ceid)
    }
    _send_to_host(message)

# ============================================
# GEM 辅助方法
# ============================================

func _update_sv_control_state():
    """更新状态变量中的控制状态"""
    status_variables[1]["value"] = control_state

func _can_start() -> bool:
    """检查是否可以 START"""
    return control_state == "ONLINE" and process_state == "IDLE"

func _gem_start_processing(lot_id: String, recipe_id: String) -> void:
    """GEM 模式开始加工"""
    process_state = "PROCESSING"
    status_variables[2]["value"] = "PROCESSING"
    status_variables[3]["value"] = recipe_id
    
    # 调用父类的加工逻辑
    on_lot_arrive(lot_id, recipe_id)
    
    # 上报 ProcessingStarted 事件
    _send_collection_event(1)

func _gem_stop_processing() -> void:
    """GEM 模式停止"""
    process_state = "IDLE"
    status_variables[2]["value"] = "IDLE"
    _on_process_interrupted("HOST_STOP")

func _gem_pause_processing() -> void:
    """GEM 模式暂停"""
    process_state = "PAUSED"
    status_variables[2]["value"] = "PAUSED"

func _gem_resume_processing() -> void:
    """GEM 模式恢复"""
    process_state = "PROCESSING"
    status_variables[2]["value"] = "PROCESSING"

func _gem_abort_processing() -> void:
    """GEM 模式中止"""
    process_state = "IDLE"
    status_variables[2]["value"] = "IDLE"
    current_lot_id = ""
    current_recipe_id = ""

func _build_event_reports(ceid: int) -> Array:
    """构建事件报告数据"""
    return [
        {"svid": 1, "value": status_variables[1]["value"]},
        {"svid": 2, "value": status_variables[2]["value"]},
        {"svid": 3, "value": status_variables[3]["value"]}
    ]

func _get_param_value(params: Array, param_name: String) -> String:
    """从参数列表中获取值"""
    for param in params:
        if param.get("name") == param_name:
            return param.get("value", "")
    return ""

func _send_to_host(message: SECSMessage) -> void:
    """发送消息到 Host (MES)"""
    # 由 HSMSManager 实现实际发送
    HSMSManager.send_message(device_id, message)

# ============================================
# 重写父类方法以集成 GEM
# ============================================

## 重写: 加工完成时上报 S6F11
func _on_process_complete():
    super._on_process_complete()
    process_state = "IDLE"
    status_variables[2]["value"] = "IDLE"
    status_variables[3]["value"] = ""
    _send_collection_event(2)

## 重写: 故障注入时上报 S5F1
func inject_fault(fault_type: String, duration: float = -1) -> void:
    super.inject_fault(fault_type, duration)
    var alarm_code = _get_alarm_code_for_fault(fault_type)
    send_s5f1(alarm_code, fault_type, true)

## 重写: 故障清除时上报 S5F1
func clear_fault(alarm_code: String) -> void:
    super.clear_fault(alarm_code)
    send_s5f1(alarm_code, "", false)

# ============================================
# GEM + 特化设备组合工厂
# ============================================

class_name GEMLITHOEquipment
extends GEMEquipment

## 重写: START 时检查掩模版
func _gem_start_processing(lot_id: String, recipe_id: String) -> void:
    # 光刻特有: 检查掩模版
    if reticle_id.is_empty():
        # 发送报警
        send_s5f1("NO_RETICLE", "Reticle not loaded", true)
        return
    
    super._gem_start_processing(lot_id, recipe_id)
