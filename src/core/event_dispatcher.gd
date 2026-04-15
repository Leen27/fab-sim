class_name EventDispatcher
extends Node

# 事件信号
signal equipment_event(equipment_id: String, event_type: String, data: Dictionary)
signal bank_event(bank_id: String, event_type: String, data: Dictionary)
signal lot_event(lot_id: String, event_type: String, data: Dictionary)
signal eap_event(equipment_id: String, stream_function: String, data: Dictionary)
signal mes_event(event_type: String, data: Dictionary)

# 事件队列（用于调试和回放）
var event_queue: Array = []
var max_queue_size: int = 1000

# 事件过滤
var enabled_events: Dictionary = {
	"EQUIPMENT": true,
	"BANK": true,
	"LOT": true,
	"EAP": true,
	"MES": true
}

func dispatch_equipment_event(equipment_id: String, event_type: String, data: Dictionary = {}):
	if not enabled_events.get("EQUIPMENT", true):
		return
	
	var event = {
		"category": "EQUIPMENT",
		"timestamp": Time.get_unix_time_from_system(),
		"equipment_id": equipment_id,
		"event_type": event_type,
		"data": data
	}
	
	_add_to_queue(event)
	equipment_event.emit(equipment_id, event_type, data)

func dispatch_bank_event(bank_id: String, event_type: String, data: Dictionary = {}):
	if not enabled_events.get("BANK", true):
		return
	
	var event = {
		"category": "BANK",
		"timestamp": Time.get_unix_time_from_system(),
		"bank_id": bank_id,
		"event_type": event_type,
		"data": data
	}
	
	_add_to_queue(event)
	bank_event.emit(bank_id, event_type, data)

func dispatch_lot_event(lot_id: String, event_type: String, data: Dictionary = {}):
	if not enabled_events.get("LOT", true):
		return
	
	var event = {
		"category": "LOT",
		"timestamp": Time.get_unix_time_from_system(),
		"lot_id": lot_id,
		"event_type": event_type,
		"data": data
	}
	
	_add_to_queue(event)
	lot_event.emit(lot_id, event_type, data)

func dispatch_eap_event(equipment_id: String, stream_function: String, data: Dictionary = {}):
	if not enabled_events.get("EAP", true):
		return
	
	var event = {
		"category": "EAP",
		"timestamp": Time.get_unix_time_from_system(),
		"equipment_id": equipment_id,
		"stream_function": stream_function,
		"data": data
	}
	
	_add_to_queue(event)
	eap_event.emit(equipment_id, stream_function, data)

func dispatch_mes_event(event_type: String, data: Dictionary = {}):
	if not enabled_events.get("MES", true):
		return
	
	var event = {
		"category": "MES",
		"timestamp": Time.get_unix_time_from_system(),
		"event_type": event_type,
		"data": data
	}
	
	_add_to_queue(event)
	mes_event.emit(event_type, data)

func _add_to_queue(event: Dictionary):
	event_queue.append(event)
	
	# 限制队列大小
	if event_queue.size() > max_queue_size:
		event_queue.remove_at(0)

func get_recent_events(count: int = 100) -> Array:
	var start_idx = max(0, event_queue.size() - count)
	return event_queue.slice(start_idx)

func get_events_by_category(category: String) -> Array:
	return event_queue.filter(func(e): return e.category == category)

func get_events_by_equipment(equipment_id: String) -> Array:
	return event_queue.filter(func(e): return e.get("equipment_id") == equipment_id)

func get_events_by_lot(lot_id: String) -> Array:
	return event_queue.filter(func(e): return e.get("lot_id") == lot_id)

func clear_queue():
	event_queue.clear()

func set_event_enabled(category: String, enabled: bool):
	enabled_events[category] = enabled

func export_events_to_json(filepath: String) -> bool:
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		return false
	
	var data = {
		"export_time": Time.get_datetime_string_from_system(true),
		"event_count": event_queue.size(),
		"events": event_queue
	}
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
