class_name Recipe
extends RefCounted

# 工艺步骤
class ProcessStep:
	var step_id: String
	var step_name: String
	var step_order: int
	var equipment_type: String       # 所需设备类型
	var required_equipment: String   # 指定设备ID（可选）
	var process_time: float          # 加工时间（分钟）
	var parameters: Dictionary       # 工艺参数
	var next_steps: Array            # 后续步骤（分支工艺用）
	var inspection_required: bool    # 是否需要检测
	
	func _init(p_step_id: String, p_equipment_type: String, p_time: float):
		step_id = p_step_id
		equipment_type = p_equipment_type
		process_time = p_time

# 配方数据
var recipe_id: String = ""
var recipe_name: String = ""
var description: String = ""
var version: String = "1.0"
var steps: Array = []  # ProcessStep 列表

func load_from_json(json_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("无法打开配方文件: " + json_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("JSON 解析错误: " + json.get_error_message())
		return false
	
	_parse_recipe(json.data)
	return true

func _parse_recipe(data: Dictionary):
	recipe_id = data.get("recipe_id", "")
	recipe_name = data.get("recipe_name", "")
	description = data.get("description", "")
	version = data.get("version", "1.0")
	
	steps.clear()
	if data.has("steps"):
		for step_data in data.steps:
			var step = ProcessStep.new(
				step_data.get("step_id", ""),
				step_data.get("equipment_type", ""),
				step_data.get("process_time", 0.0)
			)
			step.step_name = step_data.get("step_name", "")
			step.step_order = step_data.get("step_order", 0)
			step.required_equipment = step_data.get("required_equipment", "")
			step.parameters = step_data.get("parameters", {})
			step.next_steps = step_data.get("next_steps", [])
			step.inspection_required = step_data.get("inspection_required", false)
			steps.append(step)
		
		# 按顺序排序
		steps.sort_custom(func(a, b): return a.step_order < b.step_order)

func get_step_by_id(step_id: String) -> ProcessStep:
	for step in steps:
		if step.step_id == step_id:
			return step
	return null

func get_step_by_order(order: int) -> ProcessStep:
	for step in steps:
		if step.step_order == order:
			return step
	return null

func get_first_step() -> ProcessStep:
	if steps.size() > 0:
		return steps[0]
	return null

func get_next_step(current_step_id: String, result: String = "PASS") -> ProcessStep:
	var current = get_step_by_id(current_step_id)
	if current == null:
		return null
	
	# 检查是否有分支
	if current.next_steps.size() > 0:
		for next in current.next_steps:
			if next.get("condition", "") == result:
				return get_step_by_id(next.step_id)
	
	# 返回顺序下一个
	return get_step_by_order(current.step_order + 1)

func get_total_process_time() -> float:
	var total = 0.0
	for step in steps:
		total += step.process_time
	return total

func get_equipment_types_needed() -> Array:
	var types = []
	for step in steps:
		if not types.has(step.equipment_type):
			types.append(step.equipment_type)
	return types

func get_step_count() -> int:
	return steps.size()

func to_dict() -> Dictionary:
	var step_list = []
	for step in steps:
		step_list.append({
			"step_id": step.step_id,
			"step_name": step.step_name,
			"step_order": step.step_order,
			"equipment_type": step.equipment_type,
			"process_time": step.process_time,
			"parameters": step.parameters
		})
	
	return {
		"recipe_id": recipe_id,
		"recipe_name": recipe_name,
		"description": description,
		"version": version,
		"step_count": steps.size(),
		"total_process_time": get_total_process_time(),
		"steps": step_list
	}
