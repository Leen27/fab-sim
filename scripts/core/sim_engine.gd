class_name SimEngine
extends RefCounted

signal time_updated(current_time_minutes)
signal wip_updated(wip_count)
signal lot_completed(lot_id, total_time)
signal machine_status_changed(machine_id, status)

# 仿真配置
var layout_data = null
var recipe_data = null

# 仿真状态
var current_time: float = 0.0  # 仿真时间（分钟）
var time_scale: float = 1.0    # 时间加速倍数
var is_running: bool = false
var is_paused: bool = false

# 产线配置
var machines = {}      # 设备字典
var buffers = {}       # 缓冲字典
var connections = []   # 连接关系

# 仿真实体
var lots = []          # 所有Lot
var completed_lots = 0 # 已完成计数
var next_lot_id = 1    # Lot编号生成器

# 设备状态
var machine_states = {}  # 设备实时状态

# 统计
var total_wip: int = 0
var max_wip: int = 0

func setup(p_layout_data, p_recipe_data):
	layout_data = p_layout_data
	recipe_data = p_recipe_data
	_parse_layout()
	_init_machine_states()

func _parse_layout():
	machines.clear()
	buffers.clear()
	connections.clear()
	
	if layout_data:
		if layout_data.has("machines"):
			for m in layout_data.machines:
				machines[m.id] = {
					"id": m.id,
					"type": m.type,
					"name": m.name,
					"process_time": m.process_time,
					"position": Vector2(m.x, m.y)
				}
		
		if layout_data.has("buffers"):
			for b in layout_data.buffers:
				buffers[b.id] = {
					"id": b.id,
					"name": b.name,
					"capacity": b.capacity,
					"position": Vector2(b.x, b.y),
					"queue": []  # 缓冲队列
				}
		
		if layout_data.has("connections"):
			connections = layout_data.connections

func _init_machine_states():
	machine_states.clear()
	
	for id in machines.keys():
		machine_states[id] = {
			"status": "空闲",      # 空闲/加工中
			"current_lot": null,   # 正在加工的Lot
			"queue": [],           # 等待队列
			"busy_until": 0.0,     # 忙到什么时候
			"total_processed": 0   # 累计加工数
		}
		machine_status_changed.emit(id, "空闲")

func start():
	if is_running:
		return
	is_running = true
	is_paused = false
	
	# 生成初始Lot
	_generate_lots(5)

func pause():
	is_paused = !is_paused

func stop():
	is_running = false
	is_paused = false

func reset():
	is_running = false
	is_paused = false
	current_time = 0.0
	next_lot_id = 1
	completed_lots = 0
	total_wip = 0
	max_wip = 0
	
	# 清空所有Lot
	lots.clear()
	
	# 重置设备状态
	_init_machine_states()
	
	# 清空缓冲队列
	for id in buffers.keys():
		buffers[id].queue.clear()
	
	time_updated.emit(0)
	wip_updated.emit(0)

func set_time_scale(scale: float):
	time_scale = scale

func update(delta: float):
	if not is_running or is_paused:
		return
	
	# 推进仿真时间
	var sim_delta = delta * time_scale
	current_time += sim_delta
	
	# 1. 检查完成的设备，释放Lot
	_check_completed_machines()
	
	# 2. 移动Lot从缓冲到下一台设备
	_move_lots_from_buffers()
	
	# 3. 分配空闲设备给等待的Lot
	_dispatch_lots()
	
	# 4. 更新统计
	_update_stats()
	
	# 5. 发射信号更新UI
	time_updated.emit(current_time)
	wip_updated.emit(total_wip)

func _generate_lots(count: int):
	for i in range(count):
		var lot = {
			"id": "L%04d" % next_lot_id,
			"enter_time": current_time,
			"current_step": 0,      # 当前工艺步骤
			"status": "等待",       # 等待/加工中/运输中/完成
			"location": null,       # 当前位置（设备ID或缓冲ID）
			"target_machine": null  # 目标设备
		}
		next_lot_id += 1
		lots.append(lot)
		
		# 放入第一台设备的队列
		var first_machine_id = machines.keys()[0]
		machine_states[first_machine_id].queue.append(lot)
		lot.location = first_machine_id
		lot.status = "等待"

func _check_completed_machines():
	# 检查哪些设备完成了加工
	for id in machines.keys():
		var state = machine_states[id]
		
		if state.status == "加工中" and current_time >= state.busy_until:
			# 设备完成加工
			var lot = state.current_lot
			state.current_lot = null
			state.status = "空闲"
			state.total_processed += 1
			machine_status_changed.emit(id, "空闲")
			
			# Lot完成这一步
			if lot != null:
				lot.current_step += 1
				
				# 检查是否完成所有步骤
				if lot.current_step >= 6:  # 6个步骤完成
					lot.status = "完成"
					lot.location = null
					completed_lots += 1
					var total_time = current_time - lot.enter_time
					lot_completed.emit(lot.id, total_time)
				else:
					# 放入对应的缓冲
					var buffer_id = _get_buffer_after_machine(id)
					if buffer_id != null:
						buffers[buffer_id].queue.append(lot)
						lot.location = buffer_id
						lot.status = "等待"

func _get_buffer_after_machine(machine_id: String) -> String:
	# 根据连接关系找到设备后的缓冲
	for conn in connections:
		if conn.from == machine_id and buffers.has(conn.to):
			return conn.to
	return ""

func _get_machine_after_buffer(buffer_id: String) -> String:
	# 根据连接关系找到缓冲后的设备
	for conn in connections:
		if conn.from == buffer_id and machines.has(conn.to):
			return conn.to
	return ""

func _move_lots_from_buffers():
	# 从缓冲移动Lot到下一台设备
	for buffer_id in buffers.keys():
		var buffer = buffers[buffer_id]
		var next_machine_id = _get_machine_after_buffer(buffer_id)
		
		if next_machine_id == "":
			continue
		
		var machine_state = machine_states[next_machine_id]
		
		# 将缓冲中的Lot移到设备的等待队列
		while buffer.queue.size() > 0:
			var lot = buffer.queue[0]
			machine_state.queue.append(lot)
			lot.location = next_machine_id
			lot.status = "等待"
			buffer.queue.remove_at(0)

func _dispatch_lots():
	# FIFO调度：空闲设备处理队列中的第一个Lot
	for id in machines.keys():
		var state = machine_states[id]
		
		if state.status == "空闲" and state.queue.size() > 0:
			# 取出第一个Lot开始加工
			var lot = state.queue[0]
			state.queue.remove_at(0)
			
			state.current_lot = lot
			state.status = "加工中"
			state.busy_until = current_time + machines[id].process_time
			lot.status = "加工中"
			lot.target_machine = id
			
			machine_status_changed.emit(id, "加工中")

func _update_stats():
	# 计算当前WIP
	total_wip = 0
	for lot in lots:
		if lot.status != "完成":
			total_wip += 1
	
	if total_wip > max_wip:
		max_wip = total_wip

# 获取设备队列长度
func get_machine_queue_count(machine_id: String) -> int:
	if machine_states.has(machine_id):
		return machine_states[machine_id].queue.size()
	return 0

# 获取缓冲队列长度
func get_buffer_count(buffer_id: String) -> int:
	if buffers.has(buffer_id):
		return buffers[buffer_id].queue.size()
	return 0

# 获取设备状态
func get_machine_status(machine_id: String) -> String:
	if machine_states.has(machine_id):
		return machine_states[machine_id].status
	return "未知"

# 获取吞吐量（每小时完成数）
func get_throughput() -> float:
	if current_time > 0:
		return (completed_lots / current_time) * 60.0
	return 0.0

# 获取平均周期时间
func get_average_cycle_time() -> float:
	if completed_lots > 0:
		# 简化的CT计算
		return current_time / completed_lots
	return 0.0

# 动态添加新Lot（模拟新订单到达）
func add_new_lot():
	var lot = {
		"id": "L%04d" % next_lot_id,
		"enter_time": current_time,
		"current_step": 0,
		"status": "等待",
		"location": null,
		"target_machine": null
	}
	next_lot_id += 1
	lots.append(lot)
	
	var first_machine_id = machines.keys()[0]
	machine_states[first_machine_id].queue.append(lot)
	lot.location = first_machine_id