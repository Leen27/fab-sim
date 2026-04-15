class_name MessageFormats
extends RefCounted

# ============ HTTP 消息格式 ============

# 设备状态上报 (仿真系统 -> MES)
static func create_equipment_status_report(equipment_id: String, status: Dictionary) -> Dictionary:
	return {
		"message_type": "EQUIPMENT_STATUS_REPORT",
		"timestamp": _get_iso_timestamp(),
		"equipment": {
			"equipment_id": equipment_id,
			"control_state": status.get("control_state", "OFFLINE"),
			"process_state": status.get("process_state", "IDLE"),
			"equipment_status": status.get("equipment_status", "UP"),
			"current_lot_id": status.get("current_lot_id", ""),
			"current_ppid": status.get("current_ppid", ""),
			"alarm_count": status.get("alarm_count", 0)
		}
	}

# Bank 事件上报
static func create_bank_event(event_type: String, bank_id: String, lot_id: String, additional_data: Dictionary = {}) -> Dictionary:
	var data = {
		"message_type": event_type,
		"timestamp": _get_iso_timestamp(),
		"bank_id": bank_id,
		"lot_id": lot_id
	}
	data.merge(additional_data)
	return data

# 批次完成上报
static func create_lot_complete_report(lot_id: String, equipment_id: String, result: String, cycle_time: float, parameters: Dictionary = {}) -> Dictionary:
	return {
		"message_type": "LOT_PROCESSING_COMPLETE",
		"timestamp": _get_iso_timestamp(),
		"lot": {
			"lot_id": lot_id,
			"result": result,
			"cycle_time_minutes": cycle_time
		},
		"equipment_id": equipment_id,
		"parameters": parameters
	}

# 搬运请求
static func create_transport_request(transport_id: String, lot_id: String, from_location: Dictionary, to_location: Dictionary, priority: String = "NORMAL") -> Dictionary:
	return {
		"message_type": "TRANSPORT_REQUEST",
		"timestamp": _get_iso_timestamp(),
		"transport_id": transport_id,
		"lot_id": lot_id,
		"from_location": from_location,
		"to_location": to_location,
		"priority": priority
	}

# 搬运完成
static func create_transport_complete(transport_id: String, lot_id: String, from_location: String, to_location: String, duration_sec: float) -> Dictionary:
	return {
		"message_type": "TRANSPORT_COMPLETE",
		"timestamp": _get_iso_timestamp(),
		"transport_id": transport_id,
		"lot_id": lot_id,
		"from_location": from_location,
		"to_location": to_location,
		"status": "SUCCESS",
		"actual_duration_sec": duration_sec
	}

# ============ EAP/SECS 消息格式 ============

# S1F3 - 状态变量请求
static func create_s1f3(equipment_id: String, svids: Array) -> Dictionary:
	return {
		"stream_function": "S1F3",
		"equipment_id": equipment_id,
		"svids": svids
	}

# S1F4 - 状态变量响应
static func create_s1f4(equipment_id: String, status_variables: Array) -> Dictionary:
	return {
		"stream_function": "S1F4",
		"equipment_id": equipment_id,
		"sv_count": status_variables.size(),
		"status_variables": status_variables
	}

# S2F41 - Host Command
static func create_s2f41(equipment_id: String, rcmd: String, parameters: Array = []) -> Dictionary:
	return {
		"stream_function": "S2F41",
		"equipment_id": equipment_id,
		"rcmd": rcmd,
		"parameters": parameters
	}

# S2F42 - Host Command Acknowledge
static func create_s2f42(equipment_id: String, hcack: int, command_errors: Array = []) -> Dictionary:
	var hcack_names = {0: "OK", 1: "Invalid Command", 2: "Cannot Do Now", 3: "Parameter Error"}
	return {
		"stream_function": "S2F42",
		"equipment_id": equipment_id,
		"hcack": hcack,
		"hcack_name": hcack_names.get(hcack, "Unknown"),
		"command_errors": command_errors
	}

# S6F11 - Event Report Send
static func create_s6f11(equipment_id: String, ceid: int, ce_name: String, reports: Array) -> Dictionary:
	return {
		"stream_function": "S6F11",
		"equipment_id": equipment_id,
		"ceid": ceid,
		"ce_name": ce_name,
		"reports": reports,
		"timestamp": _get_iso_timestamp()
	}

# S7F3 - Process Program Send
static func create_s7f3(equipment_id: String, ppid: String, ppbody: Array) -> Dictionary:
	return {
		"stream_function": "S7F3",
		"equipment_id": equipment_id,
		"ppid": ppid,
		"ppbody": ppbody
	}

# ============ MES 命令格式 ============

# MES -> 仿真系统：设备控制指令
static func create_mes_equipment_command(equipment_id: String, command: String, parameters: Dictionary = {}) -> Dictionary:
	return {
		"command_id": _generate_id("CMD"),
		"equipment_id": equipment_id,
		"command": command,
		"parameters": parameters,
		"timestamp": _get_iso_timestamp()
	}

# MES -> 仿真系统：Bank 派工指令
static func create_mes_dispatch_command(bank_id: String, lot_id: String, target_equipment: String, priority: String = "NORMAL") -> Dictionary:
	return {
		"dispatch_id": _generate_id("DIS"),
		"bank_id": bank_id,
		"lot_id": lot_id,
		"target_equipment": target_equipment,
		"priority": priority,
		"timestamp": _get_iso_timestamp()
	}

# ============ 辅助方法 ============

static func _get_iso_timestamp() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"

static func _generate_id(prefix: String) -> String:
	return "%s%d" % [prefix, Time.get_unix_time_from_system()]

# 验证消息格式
static func validate_message(data: Dictionary, required_fields: Array) -> bool:
	for field in required_fields:
		if not data.has(field):
			return false
	return true
