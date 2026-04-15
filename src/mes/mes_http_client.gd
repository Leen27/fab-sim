class_name MesHttpClient
extends Node

signal message_sent(endpoint: String, data: Dictionary)
signal message_received(endpoint: String, data: Dictionary)
signal send_error(endpoint: String, error: String)

# MES 配置
var mes_endpoint: String = "http://localhost:8080"
var auth_token: String = ""
var enabled: bool = false

# HTTP 客户端
var http_request: HTTPRequest

# 事件队列（用于轮询模式）
var pending_events: Array = []

# 统计
var total_sent: int = 0
var total_received: int = 0
var total_errors: int = 0

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func setup(endpoint: String, token: String = ""):
	mes_endpoint = endpoint.rstrip("/")
	auth_token = token
	enabled = true

# ============ 上报方法 ============

# 上报设备状态
func report_equipment_status(equipment_id: String, status: Dictionary) -> bool:
	var data = {
		"message_type": "EQUIPMENT_STATUS",
		"timestamp": _get_timestamp(),
		"equipment_id": equipment_id,
		"status": status
	}
	return _post("/api/v1/mes/equipment/status", data)

# 上报 Bank 事件
func report_bank_event(event_type: String, bank_id: String, lot_id: String, data: Dictionary = {}) -> bool:
	var payload = {
		"message_type": event_type,
		"timestamp": _get_timestamp(),
		"bank_id": bank_id,
		"lot_id": lot_id
	}
	payload.merge(data)
	return _post("/api/v1/mes/bank/event", payload)

# 上报 EAP 事件 (S6F11)
func report_eap_event(equipment_id: String, ceid: int, ce_name: String, reports: Array) -> bool:
	var data = {
		"stream_function": "S6F11",
		"equipment_id": equipment_id,
		"ceid": ceid,
		"ce_name": ce_name,
		"reports": reports,
		"timestamp": _get_timestamp()
	}
	return _post("/api/v1/mes/eap/event", data)

# 上报批次完成
func report_lot_complete(lot_id: String, equipment_id: String, result: String, parameters: Dictionary = {}) -> bool:
	var data = {
		"message_type": "LOT_COMPLETE",
		"timestamp": _get_timestamp(),
		"lot_id": lot_id,
		"equipment_id": equipment_id,
		"result": result,
		"parameters": parameters
	}
	return _post("/api/v1/mes/lot/complete", data)

# 上报搬运请求
func request_transport(lot_id: String, from_location: String, to_location: String, priority: String = "NORMAL") -> bool:
	var data = {
		"message_type": "TRANSPORT_REQUEST",
		"transport_id": _generate_transport_id(),
		"lot_id": lot_id,
		"from_location": {"type": "BANK", "id": from_location},
		"to_location": {"type": "BANK", "id": to_location},
		"priority": priority,
		"timestamp": _get_timestamp()
	}
	return _post("/api/v1/mes/transport/request", data)

# 上报搬运完成
func report_transport_complete(transport_id: String, lot_id: String, from_location: String, to_location: String, duration_sec: float) -> bool:
	var data = {
		"message_type": "TRANSPORT_COMPLETE",
		"transport_id": transport_id,
		"lot_id": lot_id,
		"from_location": from_location,
		"to_location": to_location,
		"status": "SUCCESS",
		"actual_duration_sec": duration_sec,
		"timestamp": _get_timestamp()
	}
	return _post("/api/v1/mes/transport/complete", data)

# ============ HTTP 基础方法 ============

func _post(endpoint: String, data: Dictionary) -> bool:
	if not enabled:
		pending_events.append({"endpoint": endpoint, "data": data})
		return false
	
	var url = mes_endpoint + endpoint
	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if err != OK:
		total_errors += 1
		send_error.emit(endpoint, "Request failed: %d" % err)
		return false
	
	total_sent += 1
	message_sent.emit(endpoint, data)
	return true

func _get(endpoint: String) -> bool:
	if not enabled:
		return false
	
	var url = mes_endpoint + endpoint
	var headers = []
	
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	
	var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if err != OK:
		total_errors += 1
		send_error.emit(endpoint, "Request failed: %d" % err)
		return false
	
	return true

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		total_errors += 1
		return
	
	total_received += 1
	
	var body_text = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(body_text)
	
	if err == OK:
		message_received.emit("", json.data)

# ============ 轮询模式 ============

# 获取待处理事件（从队列中）
func get_pending_events() -> Array:
	var events = pending_events.duplicate()
	pending_events.clear()
	return events

# ============ 辅助方法 ============

func _get_timestamp() -> String:
	return Time.get_datetime_string_from_system()

func _generate_transport_id() -> String:
	return "TR%d" % Time.get_unix_time_from_system()

func get_stats() -> Dictionary:
	return {
		"total_sent": total_sent,
		"total_received": total_received,
		"total_errors": total_errors,
		"pending_events": pending_events.size(),
		"enabled": enabled
	}
