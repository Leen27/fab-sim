class_name EapMessageHandler
extends RefCounted

signal eap_response_ready(equipment_id: String, response: Dictionary)
signal eap_command_received(equipment_id: String, rcmd: String, parameters: Array)
signal ppid_requested(equipment_id: String, ppid: String)
signal ppid_received(equipment_id: String, ppid: String, ppbody: Array)

var eap_simulator: EapSimulator = null
var mes_client: MesHttpClient = null

func _init(p_eap_sim: EapSimulator, p_mes_client: MesHttpClient):
	eap_simulator = p_eap_sim
	mes_client = p_mes_client

# 处理从 MES 收到的 EAP 消息
func handle_incoming_message(message: Dictionary) -> Dictionary:
	var stream_function = message.get("stream_function", "")
	var equipment_id = message.get("equipment_id", "")
	
	match stream_function:
		"S1F1":
			return _handle_s1f1(equipment_id)
		
		"S1F3":
			var svids = message.get("svids", [])
			return _handle_s1f3(equipment_id, svids)
		
		"S1F11":
			var svids = message.get("svids", [])
			return _handle_s1f11(equipment_id, svids)
		
		"S1F13":
			return _handle_s1f13(equipment_id)
		
		"S2F13":
			var ecids = message.get("ecids", [])
			return _handle_s2f13(equipment_id, ecids)
		
		"S2F33":
			return _handle_s2f33(equipment_id, message)
		
		"S2F35":
			return _handle_s2f35(equipment_id, message)
		
		"S2F37":
			var ceid = message.get("ceid", 0)
			var enable = message.get("enable", false)
			return _handle_s2f37(equipment_id, ceid, enable)
		
		"S2F41":
			var rcmd = message.get("rcmd", "")
			var parameters = message.get("parameters", [])
			return _handle_s2f41(equipment_id, rcmd, parameters)
		
		"S7F3":
			var ppid = message.get("ppid", "")
			var ppbody = message.get("ppbody", [])
			return _handle_s7f3(equipment_id, ppid, ppbody)
		
		"S7F5":
			var ppid = message.get("ppid", "")
			return _handle_s7f5(equipment_id, ppid)
		
		"S7F17":
			var ppids = message.get("ppids", [])
			return _handle_s7f17(equipment_id, ppids)
		
		_:
			return {"error": "Unsupported stream function: " + stream_function}

func _handle_s1f1(equipment_id: String) -> Dictionary:
	return eap_simulator.handle_s1f1(equipment_id)

func _handle_s1f3(equipment_id: String, svids: Array) -> Dictionary:
	return eap_simulator.handle_s1f3(equipment_id, svids)

func _handle_s1f11(equipment_id: String, svids: Array) -> Dictionary:
	return eap_simulator.handle_s1f11(equipment_id, svids)

func _handle_s1f13(equipment_id: String) -> Dictionary:
	# S1F13 - Establish Communications Request
	return {
		"stream_function": "S1F14",
		"equipment_id": equipment_id,
		"commack": 0,
		"commack_name": "OK",
		"mdln": "FabSim",
		"softrev": "0.1.0"
	}

func _handle_s2f13(equipment_id: String, ecids: Array) -> Dictionary:
	return eap_simulator.handle_s2f13(equipment_id, ecids)

func _handle_s2f33(equipment_id: String, data: Dictionary) -> Dictionary:
	var result = eap_simulator.handle_s2f33(equipment_id, data)
	return {
		"stream_function": "S2F34",
		"equipment_id": equipment_id,
		"drack": result.get("drack", 0)
	}

func _handle_s2f35(equipment_id: String, data: Dictionary) -> Dictionary:
	var result = eap_simulator.handle_s2f35(equipment_id, data)
	return {
		"stream_function": "S2F36",
		"equipment_id": equipment_id,
		"lrack": result.get("lrack", 0)
	}

func _handle_s2f37(equipment_id: String, ceid: int, enable: bool) -> Dictionary:
	var result = eap_simulator.handle_s2f37(equipment_id, ceid, enable)
	return {
		"stream_function": "S2F38",
		"equipment_id": equipment_id,
		"erack": result.get("erack", 0)
	}

func _handle_s2f41(equipment_id: String, rcmd: String, parameters: Array) -> Dictionary:
	# 先调用 EAP 仿真器处理
	var result = eap_simulator.handle_s2f41(equipment_id, rcmd, parameters)
	
	# 发出信号通知外部处理
	if result.get("hcack", 0) == 0:
		eap_command_received.emit(equipment_id, rcmd, parameters)
	
	return {
		"stream_function": "S2F42",
		"equipment_id": equipment_id,
		"hcack": result.get("hcack", 0),
		"hcack_name": result.get("hcack_name", "OK")
	}

func _handle_s7f3(equipment_id: String, ppid: String, ppbody: Array) -> Dictionary:
	var result = eap_simulator.handle_s7f3(equipment_id, ppid, ppbody)
	
	if result.get("ppgnt", 0) == 0:
		ppid_received.emit(equipment_id, ppid, ppbody)
	
	return {
		"stream_function": "S7F4",
		"equipment_id": equipment_id,
		"ppgnt": result.get("ppgnt", 0)
	}

func _handle_s7f5(equipment_id: String, ppid: String) -> Dictionary:
	ppid_requested.emit(equipment_id, ppid)
	return eap_simulator.handle_s7f5(equipment_id, ppid)

func _handle_s7f17(equipment_id: String, ppids: Array) -> Dictionary:
	var result = eap_simulator.handle_s7f17(equipment_id, ppids)
	return {
		"stream_function": "S7F18",
		"equipment_id": equipment_id,
		"ackc7": result.get("ackc7", 0)
	}

# 上报收集事件
func report_collection_event(equipment_id: String, ceid: int, reports: Array = []) -> bool:
	if mes_client and mes_client.enabled:
		# 查找 CE 名称
		var ce_name = ""
		if eap_simulator.config:
			var ce = eap_simulator.config.get_ce_by_id(ceid)
			if ce:
				ce_name = ce.ce_name
		
		return mes_client.report_eap_event(equipment_id, ceid, ce_name, reports)
	return false

# 更新状态变量并触发事件
func update_status_variable(equipment_id: String, svid: int, value: Variant):
	if eap_simulator:
		eap_simulator.update_status_variable(equipment_id, svid, value)
