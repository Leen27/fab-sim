class_name EapSimulator
extends Node

# EAP 信号
signal eap_message_received(equipment_id: String, stream_function: String, data: Dictionary)
signal eap_message_sent(equipment_id: String, stream_function: String, data: Dictionary)
signal collection_event_triggered(equipment_id: String, ceid: int, reports: Array)

# 配置
var config: EapConfig = null

# 设备 EAP 状态
var equipment_eap: Dictionary = {}  # equipment_id -> EapState

class EapState:
	var equipment_id: String
	var communication_state: bool = false  # 是否建立通信
	var control_state: int = 1  # 1=ONLINE, 4=LOCAL, 5=REMOTE
	var process_state: int = 0  # 0=IDLE, 2=PROCESSING
	
	# 状态变量 (SVID -> Value)
	var status_variables: Dictionary = {}
	
	# 事件使能状态 (CEID -> bool)
	var event_enabled: Dictionary = {}
	
	# 已触发的 CEID
	var pending_ceids: Array = []

func _init(p_config: EapConfig):
	config = p_config

func register_equipment(equipment_id: String, equipment_type: String):
	var state = EapState.new()
	state.equipment_id = equipment_id
	
	# 初始化状态变量
	if config:
		for sv in config.status_variables:
			if sv.equipment_type == equipment_type or sv.equipment_type == "ALL":
				state.status_variables[sv.svid] = sv.default_value
		
		# 初始化事件使能（默认全部禁用，等待 S2F37）
		for evt in config.collection_events:
			state.event_enabled[evt.ceid] = false
	
	equipment_eap[equipment_id] = state

# ============ SECS-II 消息处理 ============

# S1F1 - Are You There? (握手)
func handle_s1f1(equipment_id: String) -> Dictionary:
	var state = equipment_eap.get(equipment_id)
	if state:
		state.communication_state = true
	
	return {
		"stream_function": "S1F2",
		"equipment_id": equipment_id,
		"mdln": "FabSim",
		"softrev": "0.1.0"
	}

# S1F3 - Status Variable Request
func handle_s1f3(equipment_id: String, svids: Array) -> Dictionary:
	var state = equipment_eap.get(equipment_id)
	if state == null:
		return {"error": "Equipment not found"}
	
	var sv_list = []
	for svid in svids:
		var value = state.status_variables.get(svid, null)
		var sv_def = _find_sv_definition(svid)
		sv_list.append({
			"svid": svid,
			"sv_name": sv_def.sv_name if sv_def else "UNKNOWN",
			"value": value
		})
	
	return {
		"stream_function": "S1F4",
		"equipment_id": equipment_id,
		"sv_count": sv_list.size(),
		"status_variables": sv_list
	}

# S1F11 - Status Variable Namelist Request
func handle_s1f11(equipment_id: String, svids: Array) -> Dictionary:
	var sv_list = []
	for svid in svids:
		var sv_def = _find_sv_definition(svid)
		if sv_def:
			sv_list.append({
				"svid": svid,
				"sv_name": sv_def.sv_name,
				"units": sv_def.units,
				"description": sv_def.description
			})
	
	return {
		"stream_function": "S1F12",
		"sv_count": sv_list.size(),
		"status_variables": sv_list
	}

# S2F13 - Equipment Constant Request
func handle_s2f13(equipment_id: String, ecids: Array) -> Dictionary:
	return {
		"stream_function": "S2F14",
		"equipment_id": equipment_id,
		"ec_count": 0,
		"equipment_constants": []
	}

# S2F33 - Define Report
func handle_s2f33(equipment_id: String, data: Dictionary) -> Dictionary:
	# TODO: 实现报告定义
	return {"drack": 0}  # 0 = OK

# S2F35 - Link Event
func handle_s2f35(equipment_id: String, data: Dictionary) -> Dictionary:
	# TODO: 实现事件链接
	return {"lrack": 0}  # 0 = OK

# S2F37 - Enable/Disable Event
func handle_s2f37(equipment_id: String, ceid: int, enable: bool) -> Dictionary:
	var state = equipment_eap.get(equipment_id)
	if state:
		state.event_enabled[ceid] = enable
	
	return {"erack": 0}  # 0 = OK

# S2F41 - Host Command
func handle_s2f41(equipment_id: String, rcmd: String, parameters: Array) -> Dictionary:
	var hcack = 0  # 0 = OK, 1 = Invalid command, 2 = Cannot do now
	var cmd_error = []
	
	match rcmd:
		"PP-SELECT":
			# 选择配方
			pass
		"START":
			# 开始加工
			pass
		"STOP":
			# 停止加工
			pass
		"PAUSE":
			# 暂停
			pass
		"RESUME":
			# 恢复
			pass
		"ABORT":
			# 终止
			pass
		_:
			hcack = 1  # Invalid command
	
	return {
		"stream_function": "S2F42",
		"equipment_id": equipment_id,
		"hcack": hcack,
		"hcack_name": _hcack_to_string(hcack),
		"command_errors": cmd_error
	}

# S7F3 - Process Program Send (PPID Download)
func handle_s7f3(equipment_id: String, ppid: String, ppbody: Array) -> Dictionary:
	# TODO: 存储配方
	return {"ppgnt": 0}  # 0 = OK

# S7F5 - Process Program Request (PPID Upload)
func handle_s7f5(equipment_id: String, ppid: String) -> Dictionary:
	# TODO: 返回配方内容
	return {
		"stream_function": "S7F6",
		"ppid": ppid,
		"ppbody": []
	}

# S7F17 - Delete Process Program
func handle_s7f17(equipment_id: String, ppids: Array) -> Dictionary:
	return {"ackc7": 0}

# ============ 事件触发 ============

func trigger_collection_event(equipment_id: String, ceid: int, reports: Array = []) -> bool:
	var state = equipment_eap.get(equipment_id)
	if state == null:
		return false
	
	# 检查事件是否使能
	if not state.event_enabled.get(ceid, false):
		return false
	
	# 添加到待发送队列
	state.pending_ceids.append({
		"ceid": ceid,
		"reports": reports,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	collection_event_triggered.emit(equipment_id, ceid, reports)
	return true

func get_pending_events(equipment_id: String) -> Array:
	var state = equipment_eap.get(equipment_id)
	if state:
		var events = state.pending_ceids.duplicate()
		state.pending_ceids.clear()
		return events
	return []

# ============ 辅助方法 ============

func _find_sv_definition(svid: int) -> EapConfig.StatusVariable:
	if config == null:
		return null
	for sv in config.status_variables:
		if sv.svid == svid:
			return sv
	return null

func _hcack_to_string(hcack: int) -> String:
	match hcack:
		0: return "OK"
		1: return "Invalid Command"
		2: return "Cannot Do Now"
		3: return "Parameter Error"
		4: return "Initiated"
		5: return "Rejected"
		6: return "Invalid Object"
		_: return "Unknown"

func update_status_variable(equipment_id: String, svid: int, value: Variant):
	var state = equipment_eap.get(equipment_id)
	if state:
		state.status_variables[svid] = value
