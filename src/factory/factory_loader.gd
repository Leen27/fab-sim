class_name FactoryLoader
extends RefCounted

signal factory_loaded(factory_data: Dictionary)
signal load_error(error_message: String)

# 加载的工厂数据
var factory_config: Dictionary = {}
var equipment_list: Array = []
var bank_list: Array = []
var area_list: Array = []

func load_factory(config_path: String) -> bool:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		var error = "无法打开工厂配置文件: " + config_path
		push_error(error)
		load_error.emit(error)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		var error = "JSON 解析错误: " + json.get_error_message()
		push_error(error)
		load_error.emit(error)
		return false
	
	_parse_factory(json.data)
	factory_loaded.emit(factory_config)
	return true

func _parse_factory(data: Dictionary):
	factory_config = data
	
	# 解析区域
	if data.has("areas"):
		for area_data in data.areas:
			area_list.append({
				"area_id": area_data.get("area_id", ""),
				"area_name": area_data.get("area_name", ""),
				"description": area_data.get("description", "")
			})
	
	# 解析设备
	if data.has("equipment"):
		for eq_data in data.equipment:
			equipment_list.append({
				"equipment_id": eq_data.get("equipment_id", ""),
				"equipment_type": eq_data.get("equipment_type", ""),
				"equipment_name": eq_data.get("equipment_name", ""),
				"area_id": eq_data.get("area_id", ""),
				"work_area_id": eq_data.get("work_area_id", ""),
				"input_bank": eq_data.get("input_bank", ""),
				"output_bank": eq_data.get("output_bank", ""),
				"upstream": eq_data.get("upstream", []),
				"downstream": eq_data.get("downstream", [])
			})
	
	# 解析 Bank
	if data.has("banks"):
		for bank_data in data.banks:
			bank_list.append({
				"bank_id": bank_data.get("bank_id", ""),
				"bank_name": bank_data.get("bank_name", ""),
				"bank_type": bank_data.get("bank_type", "CENTRAL"),
				"associated_equipment": bank_data.get("associated_equipment", ""),
				"capacity": bank_data.get("capacity", 5),
				"dispatch_policy": bank_data.get("dispatch_policy", "MES_DIRECT")
			})

func get_equipment_by_id(equipment_id: String) -> Dictionary:
	for eq in equipment_list:
		if eq.equipment_id == equipment_id:
			return eq
	return {}

func get_bank_by_id(bank_id: String) -> Dictionary:
	for bank in bank_list:
		if bank.bank_id == bank_id:
			return bank
	return {}

func get_banks_by_type(bank_type: String) -> Array:
	var result = []
	for bank in bank_list:
		if bank.bank_type == bank_type:
			result.append(bank)
	return result

func get_equipment_by_type(equipment_type: String) -> Array:
	var result = []
	for eq in equipment_list:
		if eq.equipment_type == equipment_type:
			result.append(eq)
	return result

func get_input_banks_for_equipment(equipment_id: String) -> Array:
	var eq = get_equipment_by_id(equipment_id)
	if eq.is_empty():
		return []
	
	var result = []
	if eq.input_bank != "":
		var bank = get_bank_by_id(eq.input_bank)
		if not bank.is_empty():
			result.append(bank)
	
	# 添加上游设备的输出 bank
	for upstream_id in eq.upstream:
		var upstream_eq = get_equipment_by_id(upstream_id)
		if not upstream_eq.is_empty() and upstream_eq.output_bank != "":
			var bank = get_bank_by_id(upstream_eq.output_bank)
			if not bank.is_empty():
				result.append(bank)
	
	return result
