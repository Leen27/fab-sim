class_name Bank
extends RefCounted

# Bank 类型
enum BankType {
	INPUT,      # 设备入口缓存
	OUTPUT,     # 设备出口缓存
	CENTRAL     # 中央缓存区
}

# Bank 状态
enum BankStatus {
	EMPTY,          # 空闲
	HOLDING,        # 持有批次，等待派工
	RESERVED,       # MES 已确认派工，等待目标设备就绪
	TRANSFERRING    # 批次正在移出
}

# 信号
signal status_changed(bank_id: String, new_status: int, old_status: int)
signal lot_arrived(bank_id: String, lot_id: String, from_equipment: String)
signal lot_departed(bank_id: String, lot_id: String, to_equipment: String)
signal dispatch_requested(bank_id: String, lot_id: String, candidates: Array)
signal dispatch_confirmed(bank_id: String, lot_id: String, target_equipment: String)

# 配置
var bank_id: String = ""
var bank_name: String = ""
var bank_type: int = BankType.CENTRAL
var associated_equipment: String = ""  # 关联设备（INPUT/OUTPUT类型）
var capacity: int = 5
var dispatch_policy: String = "MES_DIRECT"  # FIFO | PRIORITY | MES_DIRECT

# 状态
var status: int = BankStatus.EMPTY
var lots: Array = []  # 批次队列 [{lot_id, priority, arrive_time, target_equipment}]

# 统计
var total_arrived: int = 0
var total_departed: int = 0
var max_occupancy: int = 0

func _init(p_id: String, p_name: String, p_type: int = BankType.CENTRAL):
	bank_id = p_id
	bank_name = p_name
	bank_type = p_type

# ============ Lot 管理 ============

func add_lot(lot_id: String, from_equipment: String = "", priority: String = "NORMAL") -> bool:
	if lots.size() >= capacity:
		return false  # Bank 已满
	
	var lot_info = {
		"lot_id": lot_id,
		"priority": priority,
		"arrive_time": Time.get_unix_time_from_system(),
		"from_equipment": from_equipment,
		"target_equipment": "",
		"dispatch_confirmed": false
	}
	
	lots.append(lot_info)
	total_arrived += 1
	
	# 更新最大占用
	if lots.size() > max_occupancy:
		max_occupancy = lots.size()
	
	# 更新状态
	if status == BankStatus.EMPTY:
		_set_status(BankStatus.HOLDING)
	
	lot_arrived.emit(bank_id, lot_id, from_equipment)
	
	# 如果是 MES_DIRECT 策略，立即请求派工
	if dispatch_policy == "MES_DIRECT":
		request_dispatch(lot_id)
	
	return true

func remove_lot(lot_id: String) -> bool:
	for i in range(lots.size()):
		if lots[i].lot_id == lot_id:
			lots.remove_at(i)
			total_departed += 1
			
			# 更新状态
			if lots.size() == 0:
				_set_status(BankStatus.EMPTY)
			
			return true
	return false

func get_lot(lot_id: String) -> Dictionary:
	for lot in lots:
		if lot.lot_id == lot_id:
			return lot
	return {}

func get_next_lot() -> Dictionary:
	if lots.size() == 0:
		return {}
	
	# 根据策略选择下一个批次
	match dispatch_policy:
		"FIFO":
			return lots[0]
		"PRIORITY":
			# 按优先级排序，返回最高优先级的
			var sorted = lots.duplicate()
			sorted.sort_custom(func(a, b): return _priority_weight(a.priority) > _priority_weight(b.priority))
			return sorted[0]
		_:
			return lots[0]

func _priority_weight(priority: String) -> int:
	match priority:
		"URGENT": return 3
		"HIGH": return 2
		"NORMAL": return 1
		"LOW": return 0
		_: return 1

# ============ 派工流程 ============

func request_dispatch(lot_id: String) -> bool:
	var lot = get_lot(lot_id)
	if lot.is_empty():
		return false
	
	# 获取候选设备（根据 Bank 类型和下游连接）
	var candidates = _get_candidate_equipment()
	
	dispatch_requested.emit(bank_id, lot_id, candidates)
	return true

func confirm_dispatch(lot_id: String, target_equipment: String) -> bool:
	var lot = get_lot(lot_id)
	if lot.is_empty():
		return false
	
	lot.target_equipment = target_equipment
	lot.dispatch_confirmed = true
	
	_set_status(BankStatus.RESERVED)
	dispatch_confirmed.emit(bank_id, lot_id, target_equipment)
	return true

func start_transfer(lot_id: String, to_equipment: String) -> bool:
	var lot = get_lot(lot_id)
	if lot.is_empty() or not lot.dispatch_confirmed:
		return false
	
	_set_status(BankStatus.TRANSFERRING)
	lot_departed.emit(bank_id, lot_id, to_equipment)
	
	# 移除批次
	remove_lot(lot_id)
	
	return true

func _get_candidate_equipment() -> Array:
	# 根据 Bank 类型确定候选设备
	# 对于 OUTPUT 类型的 Bank，下游设备是固定的连接
	# 对于 CENTRAL 类型的 Bank，需要根据工艺和可用性确定
	# 简化实现：返回空数组，由外部逻辑决定
	return []

# ============ 状态管理 ============

func _set_status(new_status: int):
	var old_status = status
	if old_status != new_status:
		status = new_status
		status_changed.emit(bank_id, new_status, old_status)

func is_full() -> bool:
	return lots.size() >= capacity

func is_empty() -> bool:
	return lots.size() == 0

func get_occupancy() -> int:
	return lots.size()

func get_utilization() -> float:
	return float(lots.size()) / float(capacity)

# ============ 统计信息 ============

func get_stats() -> Dictionary:
	return {
		"bank_id": bank_id,
		"bank_name": bank_name,
		"bank_type": bank_type_to_string(bank_type),
		"status": status_to_string(status),
		"capacity": capacity,
		"occupancy": lots.size(),
		"utilization": get_utilization(),
		"total_arrived": total_arrived,
		"total_departed": total_departed,
		"max_occupancy": max_occupancy,
		"lots": lots.duplicate()
	}

# ============ Static Helpers ============

static func bank_type_to_string(btype: int) -> String:
	match btype:
		BankType.INPUT: return "INPUT"
		BankType.OUTPUT: return "OUTPUT"
		BankType.CENTRAL: return "CENTRAL"
		_: return "UNKNOWN"

static func status_to_string(s: int) -> String:
	match s:
		BankStatus.EMPTY: return "EMPTY"
		BankStatus.HOLDING: return "HOLDING"
		BankStatus.RESERVED: return "RESERVED"
		BankStatus.TRANSFERRING: return "TRANSFERRING"
		_: return "UNKNOWN"
