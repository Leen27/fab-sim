class_name LotTracker
extends RefCounted

signal lot_created(lot_id: String, recipe_id: String)
signal lot_status_changed(lot_id: String, old_status: String, new_status: String)
signal lot_location_changed(lot_id: String, from_location: String, to_location: String)
signal lot_step_completed(lot_id: String, step_id: String, equipment_id: String)
signal lot_completed(lot_id: String, total_time: float)

# Lot 状态
enum LotStatus {
	CREATED,        # 刚创建
	WAITING,        # 等待加工
	PROCESSING,     # 加工中
	HOLDING,        # 暂存/等待搬运
	TRANSPORTING,   # 搬运中
	COMPLETED,      # 已完成
	ABORTED         # 已终止
}

# 批次数据
var lots: Dictionary = {}  # lot_id -> LotData
var next_lot_id: int = 1

# 统计
var total_created: int = 0
var total_completed: int = 0
var total_aborted: int = 0

class LotData:
	var lot_id: String
	var recipe_id: String
	var status: int = LotStatus.CREATED
	var current_step: int = 0
	var location: String = ""  # 当前位置 (设备ID或BankID)
	var create_time: float
	var complete_time: float = 0.0
	var steps: Array = []  # [{step_id, equipment_type, parameters, completed, start_time, end_time}]
	var history: Array = []  # 位置变更历史
	var attributes: Dictionary = {}  # 扩展属性

func create_lot(recipe_id: String, attributes: Dictionary = {}) -> String:
	var lot_id = "LOT%06d" % next_lot_id
	next_lot_id += 1
	
	var lot = LotData.new()
	lot.lot_id = lot_id
	lot.recipe_id = recipe_id
	lot.status = LotStatus.CREATED
	lot.create_time = Time.get_unix_time_from_system()
	lot.attributes = attributes
	
	lots[lot_id] = lot
	total_created += 1
	
	lot_created.emit(lot_id, recipe_id)
	return lot_id

func get_lot(lot_id: String) -> LotData:
	return lots.get(lot_id, null)

func set_lot_status(lot_id: String, new_status: int) -> bool:
	var lot = get_lot(lot_id)
	if lot == null:
		return false
	
	var old_status = lot.status
	if old_status != new_status:
		lot.status = new_status
		lot_status_changed.emit(lot_id, _status_to_string(old_status), _status_to_string(new_status))
		
		if new_status == LotStatus.COMPLETED:
			lot.complete_time = Time.get_unix_time_from_system()
			total_completed += 1
			lot_completed.emit(lot_id, lot.complete_time - lot.create_time)
		elif new_status == LotStatus.ABORTED:
			total_aborted += 1
	
	return true

func set_lot_location(lot_id: String, new_location: String) -> bool:
	var lot = get_lot(lot_id)
	if lot == null:
		return false
	
	var old_location = lot.location
	if old_location != new_location:
		lot.location = new_location
		lot.history.append({
			"from": old_location,
			"to": new_location,
			"time": Time.get_unix_time_from_system()
		})
		lot_location_changed.emit(lot_id, old_location, new_location)
	
	return true

func complete_step(lot_id: String, step_id: String, equipment_id: String, result: String = "PASS") -> bool:
	var lot = get_lot(lot_id)
	if lot == null:
		return false
	
	for step in lot.steps:
		if step.step_id == step_id:
			step.completed = true
			step.end_time = Time.get_unix_time_from_system()
			step.result = result
			lot_step_completed.emit(lot_id, step_id, equipment_id)
			return true
	
	return false

func get_lot_count_by_status(status: int) -> int:
	var count = 0
	for lot in lots.values():
		if lot.status == status:
			count += 1
	return count

func get_active_lots() -> Array:
	var result = []
	for lot in lots.values():
		if lot.status != LotStatus.COMPLETED and lot.status != LotStatus.ABORTED:
			result.append(lot)
	return result

func get_cycle_time() -> float:
	if total_completed == 0:
		return 0.0
	
	var total_time = 0.0
	for lot in lots.values():
		if lot.status == LotStatus.COMPLETED and lot.complete_time > 0:
			total_time += (lot.complete_time - lot.create_time)
	
	return total_time / total_completed

func _status_to_string(status: int) -> String:
	match status:
		LotStatus.CREATED: return "CREATED"
		LotStatus.WAITING: return "WAITING"
		LotStatus.PROCESSING: return "PROCESSING"
		LotStatus.HOLDING: return "HOLDING"
		LotStatus.TRANSPORTING: return "TRANSPORTING"
		LotStatus.COMPLETED: return "COMPLETED"
		LotStatus.ABORTED: return "ABORTED"
		_: return "UNKNOWN"
