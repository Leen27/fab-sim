class_name EquipmentFSM
extends RefCounted

# GEM Control State (SEMI E30)
enum ControlState {
	OFFLINE = 0,    # 离线
	ONLINE = 1,     # 在线未确定模式
	LOCAL = 4,      # 本地控制
	REMOTE = 5      # 远程控制 (MES可操作)
}

# GEM Process State
enum ProcessState {
	IDLE = 0,       # 空闲
	SETUP = 1,      # 准备中
	PROCESSING = 2, # 加工中
	COMPLETE = 3,   # 完成
	PAUSED = 4,     # 暂停
	ABORTED = 5     # 已终止
}

# Equipment Status
enum EquipmentStatus {
	UP = 0,         # 正常
	DOWN = 1,       # 故障
	MAINTENANCE = 2 # 维护中
}

# 状态信号
signal control_state_changed(equipment_id: String, new_state: int, old_state: int)
signal process_state_changed(equipment_id: String, new_state: int, old_state: int)
signal equipment_status_changed(equipment_id: String, new_status: int, old_status: int)
signal lot_arrived(equipment_id: String, lot_id: String)
signal lot_departed(equipment_id: String, lot_id: String)
signal processing_started(equipment_id: String, lot_id: String, ppid: String)
signal processing_completed(equipment_id: String, lot_id: String, result: String)
signal alarm_set(equipment_id: String, alarm_id: int, alarm_text: String)
signal alarm_cleared(equipment_id: String, alarm_id: int)

# 设备配置
var equipment_id: String = ""
var equipment_type: String = ""
var equipment_name: String = ""
var area_id: String = ""
var work_area_id: String = ""
var input_bank: String = ""
var output_bank: String = ""
var upstream: Array = []
var downstream: Array = []

# 状态
var control_state: int = ControlState.OFFLINE
var process_state: int = ProcessState.IDLE
var equipment_status: int = EquipmentStatus.UP

# 当前批次信息
var current_lot_id: String = ""
var current_ppid: String = ""
var process_start_time: float = 0.0
var process_end_time: float = 0.0

# 队列
var input_queue: Array = []  # 等待加工的批次

# 告警
var active_alarms: Dictionary = {}
var alarm_history: Array = []

# 统计
var total_processed: int = 0

func _init(p_id: String, p_type: String, p_name: String):
	equipment_id = p_id
	equipment_type = p_type
	equipment_name = p_name

# ============ Control State 转换 ============

func go_online() -> bool:
	if control_state == ControlState.OFFLINE:
		_set_control_state(ControlState.ONLINE)
		return true
	return false

func go_local() -> bool:
	if control_state in [ControlState.ONLINE, ControlState.REMOTE]:
		_set_control_state(ControlState.LOCAL)
		return true
	return false

func go_remote() -> bool:
	if control_state in [ControlState.ONLINE, ControlState.LOCAL]:
		_set_control_state(ControlState.REMOTE)
		return true
	return false

func go_offline() -> bool:
	_set_control_state(ControlState.OFFLINE)
	return true

func _set_control_state(new_state: int):
	var old_state = control_state
	if old_state != new_state:
		control_state = new_state
		control_state_changed.emit(equipment_id, new_state, old_state)

# ============ Process State 转换 ============

func can_start() -> bool:
	return process_state == ProcessState.IDLE and \
		   control_state == ControlState.REMOTE and \
		   equipment_status == EquipmentStatus.UP and \
		   input_queue.size() > 0

func start_processing(lot_id: String, ppid: String) -> bool:
	if not can_start():
		return false
	
	current_lot_id = lot_id
	current_ppid = ppid
	process_start_time = Time.get_unix_time_from_system()
	process_end_time = 0.0
	
	_set_process_state(ProcessState.PROCESSING)
	processing_started.emit(equipment_id, lot_id, ppid)
	total_processed += 1
	
	return true

func pause_processing() -> bool:
	if process_state == ProcessState.PROCESSING:
		_set_process_state(ProcessState.PAUSED)
		return true
	return false

func resume_processing() -> bool:
	if process_state == ProcessState.PAUSED:
		_set_process_state(ProcessState.PROCESSING)
		return true
	return false

func stop_processing() -> bool:
	if process_state == ProcessState.PROCESSING:
		process_end_time = Time.get_unix_time_from_system()
		_set_process_state(ProcessState.IDLE)
		lot_departed.emit(equipment_id, current_lot_id)
		current_lot_id = ""
		current_ppid = ""
		return true
	return false

func abort_processing() -> bool:
	if process_state in [ProcessState.PROCESSING, ProcessState.PAUSED]:
		process_end_time = Time.get_unix_time_from_system()
		_set_process_state(ProcessState.ABORTED)
		processing_completed.emit(equipment_id, current_lot_id, "ABORTED")
		return true
	return false

func complete_processing(result: String = "PASS") -> bool:
	if process_state == ProcessState.PROCESSING:
		process_end_time = Time.get_unix_time_from_system()
		_set_process_state(ProcessState.COMPLETE)
		processing_completed.emit(equipment_id, current_lot_id, result)
		return true
	return false

func finish_completion() -> bool:
	if process_state == ProcessState.COMPLETE:
		lot_departed.emit(equipment_id, current_lot_id)
		current_lot_id = ""
		current_ppid = ""
		_set_process_state(ProcessState.IDLE)
		return true
	return false

func _set_process_state(new_state: int):
	var old_state = process_state
	if old_state != new_state:
		process_state = new_state
		process_state_changed.emit(equipment_id, new_state, old_state)

# ============ Queue Management ============

func add_lot_to_queue(lot_id: String) -> bool:
	input_queue.append(lot_id)
	lot_arrived.emit(equipment_id, lot_id)
	return true

func remove_lot_from_queue(lot_id: String) -> bool:
	var idx = input_queue.find(lot_id)
	if idx >= 0:
		input_queue.remove_at(idx)
		return true
	return false

func get_next_lot() -> String:
	if input_queue.size() > 0:
		return input_queue[0]
	return ""

func pop_next_lot() -> String:
	if input_queue.size() > 0:
		return input_queue.pop_at(0)
	return ""

# ============ Alarm Management ============

func set_alarm(alarm_id: int, alarm_text: String, alarm_level: String = "WARNING"):
	if not active_alarms.has(alarm_id):
		active_alarms[alarm_id] = {
			"text": alarm_text,
			"level": alarm_level,
			"set_time": Time.get_unix_time_from_system()
		}
		alarm_set.emit(equipment_id, alarm_id, alarm_text)
		alarm_history.append({
			"alarm_id": alarm_id,
			"text": alarm_text,
			"level": alarm_level,
			"action": "SET",
			"time": Time.get_unix_time_from_system()
		})

func clear_alarm(alarm_id: int):
	if active_alarms.has(alarm_id):
		active_alarms.erase(alarm_id)
		alarm_cleared.emit(equipment_id, alarm_id)
		alarm_history.append({
			"alarm_id": alarm_id,
			"action": "CLEAR",
			"time": Time.get_unix_time_from_system()
		})

func get_alarm_count() -> int:
	return active_alarms.size()

# ============ Status Variables (SV) ============

func get_status_variable(svid: int) -> Variant:
	match svid:
		1: return control_state_to_string(control_state)
		2: return process_state_to_string(process_state)
		3: return current_lot_id
		4: return current_ppid
		5: return process_start_time
		6: return process_end_time if process_end_time > 0 else 0
		7: return equipment_status_to_string(equipment_status)
		8: return get_alarm_count()
		_: return null

func get_all_status() -> Dictionary:
	return {
		"equipment_id": equipment_id,
		"equipment_type": equipment_type,
		"control_state": control_state_to_string(control_state),
		"process_state": process_state_to_string(process_state),
		"equipment_status": equipment_status_to_string(equipment_status),
		"current_lot_id": current_lot_id,
		"current_ppid": current_ppid,
		"process_start_time": process_start_time,
		"queue_count": input_queue.size(),
		"alarm_count": get_alarm_count(),
		"total_processed": total_processed
	}

# ============ Static Helpers ============

static func control_state_to_string(state: int) -> String:
	match state:
		ControlState.OFFLINE: return "OFFLINE"
		ControlState.ONLINE: return "ONLINE"
		ControlState.LOCAL: return "LOCAL"
		ControlState.REMOTE: return "REMOTE"
		_: return "UNKNOWN"

static func process_state_to_string(state: int) -> String:
	match state:
		ProcessState.IDLE: return "IDLE"
		ProcessState.SETUP: return "SETUP"
		ProcessState.PROCESSING: return "PROCESSING"
		ProcessState.COMPLETE: return "COMPLETE"
		ProcessState.PAUSED: return "PAUSED"
		ProcessState.ABORTED: return "ABORTED"
		_: return "UNKNOWN"

static func equipment_status_to_string(status: int) -> String:
	match status:
		EquipmentStatus.UP: return "UP"
		EquipmentStatus.DOWN: return "DOWN"
		EquipmentStatus.MAINTENANCE: return "MAINTENANCE"
		_: return "UNKNOWN"
