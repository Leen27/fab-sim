class_name BankMessageHandler
extends RefCounted

signal dispatch_requested(bank_id: String, lot_id: String, candidates: Array)
signal dispatch_confirmed(bank_id: String, lot_id: String, target_equipment: String)
signal transport_started(transport_id: String, lot_id: String, from_bank: String, to_equipment: String)
signal transport_completed(transport_id: String, lot_id: String, result: String)

var banks: Dictionary = {}  # bank_id -> Bank
var mes_client: MesHttpClient = null

func _init(p_mes_client: MesHttpClient):
	mes_client = p_mes_client

func register_bank(bank: Bank):
	banks[bank.bank_id] = bank
	
	# 连接信号
	bank.status_changed.connect(_on_bank_status_changed)
	bank.lot_arrived.connect(_on_lot_arrived)
	bank.lot_departed.connect(_on_lot_departed)
	bank.dispatch_requested.connect(_on_dispatch_requested)
	bank.dispatch_confirmed.connect(_on_dispatch_confirmed)

func _on_bank_status_changed(bank_id: String, new_status: int, old_status: int):
	var bank = banks.get(bank_id)
	if bank == null:
		return
	
	# 状态变化时上报 MES
	if mes_client and mes_client.enabled:
		var event_type = "BANK_STATUS_CHANGED"
		var data = {
			"old_status": Bank.status_to_string(old_status),
			"new_status": Bank.status_to_string(new_status),
			"occupancy": bank.get_occupancy()
		}
		mes_client.report_bank_event(event_type, bank_id, "", data)

func _on_lot_arrived(bank_id: String, lot_id: String, from_equipment: String):
	var bank = banks.get(bank_id)
	if bank == null:
		return
	
	# 上报 MES
	if mes_client and mes_client.enabled:
		var event_type = "BANK_LOT_ARRIVE"
		var data = {
			"from_equipment": from_equipment,
			"bank_type": Bank.bank_type_to_string(bank.bank_type)
		}
		mes_client.report_bank_event(event_type, bank_id, lot_id, data)
	
	# 根据策略处理
	match bank.dispatch_policy:
		"FIFO":
			# FIFO 模式：自动触发派工请求
			_request_dispatch(bank_id, lot_id)
		
		"MES_DIRECT":
			# MES 直接派工：等待 MES 指令
			_request_dispatch(bank_id, lot_id)

func _on_lot_departed(bank_id: String, lot_id: String, to_equipment: String):
	var bank = banks.get(bank_id)
	if bank == null:
		return
	
	# 上报 MES
	if mes_client and mes_client.enabled:
		var event_type = "BANK_LOT_DEPART"
		var data = {
			"to_equipment": to_equipment
		}
		mes_client.report_bank_event(event_type, bank_id, lot_id, data)

func _on_dispatch_requested(bank_id: String, lot_id: String, candidates: Array):
	dispatch_requested.emit(bank_id, lot_id, candidates)

func _on_dispatch_confirmed(bank_id: String, lot_id: String, target_equipment: String):
	dispatch_confirmed.emit(bank_id, lot_id, target_equipment)

# 处理 MES 派工指令
func handle_dispatch_command(bank_id: String, lot_id: String, target_equipment: String) -> bool:
	var bank = banks.get(bank_id)
	if bank == null:
		push_error("Bank not found: " + bank_id)
		return false
	
	# 确认派工
	if not bank.confirm_dispatch(lot_id, target_equipment):
		return false
	
	return true

# 处理 MES 取消派工
func handle_cancel_dispatch(bank_id: String, lot_id: String) -> bool:
	var bank = banks.get(bank_id)
	if bank == null:
		return false
	
	var lot = bank.get_lot(lot_id)
	if lot.is_empty():
		return false
	
	lot.dispatch_confirmed = false
	lot.target_equipment = ""
	
	# 更新 Bank 状态
	if bank.lots.size() > 0:
		bank._set_status(Bank.BankStatus.HOLDING)
	else:
		bank._set_status(Bank.BankStatus.EMPTY)
	
	return true

# 开始搬运
func start_transport(bank_id: String, lot_id: String, to_equipment: String) -> String:
	var bank = banks.get(bank_id)
	if bank == null:
		return ""
	
	var transport_id = "TR%d" % Time.get_unix_time_from_system()
	
	if bank.start_transfer(lot_id, to_equipment):
		transport_started.emit(transport_id, lot_id, bank_id, to_equipment)
		return transport_id
	
	return ""

# 完成搬运
func complete_transport(transport_id: String, lot_id: String, result: String = "SUCCESS"):
	transport_completed.emit(transport_id, lot_id, result)
	
	# 上报 MES
	if mes_client and mes_client.enabled:
		mes_client.report_transport_complete(transport_id, lot_id, "", "", 0.0)

# 添加批次到 Bank（从设备流出）
func add_lot_from_equipment(bank_id: String, lot_id: String, from_equipment: String) -> bool:
	var bank = banks.get(bank_id)
	if bank == null:
		return false
	
	return bank.add_lot(lot_id, from_equipment)

# 移除批次从 Bank（进入设备）
func remove_lot_to_equipment(bank_id: String, lot_id: String) -> Dictionary:
	var bank = banks.get(bank_id)
	if bank == null:
		return {}
	
	var lot = bank.get_lot(lot_id)
	if lot.is_empty():
		return {}
	
	if bank.remove_lot(lot_id):
		return lot
	
	return {}

# 获取 Bank 状态
func get_bank_status(bank_id: String) -> Dictionary:
	var bank = banks.get(bank_id)
	if bank:
		return bank.get_stats()
	return {}

# 获取所有 Bank 状态
func get_all_bank_status() -> Array:
	var result = []
	for bank in banks.values():
		result.append(bank.get_stats())
	return result

# 私有方法：请求派工
func _request_dispatch(bank_id: String, lot_id: String):
	var bank = banks.get(bank_id)
	if bank == null:
		return
	
	bank.request_dispatch(lot_id)
