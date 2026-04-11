extends Control

@onready var start_btn = $ControlPanel/HBoxContainer/StartBtn
@onready var pause_btn = $ControlPanel/HBoxContainer/PauseBtn
@onready var reset_btn = $ControlPanel/HBoxContainer/ResetBtn
@onready var speed_1x = $ControlPanel/HBoxContainer/Speed1x
@onready var speed_10x = $ControlPanel/HBoxContainer/Speed10x
@onready var speed_100x = $ControlPanel/HBoxContainer/Speed100x
@onready var time_label = $ControlPanel/HBoxContainer/TimeLabel
@onready var wip_label = $ControlPanel/HBoxContainer/WipLabel
@onready var throughput_label = $ControlPanel/HBoxContainer/ThroughputLabel
@onready var machines_node = $Canvas/Machines
@onready var buffers_node = $Canvas/Buffers
@onready var connections_node = $Canvas/Connections
@onready var status_label = $InfoPanel/VBoxContainer/StatusLabel
@onready var completed_label = $InfoPanel/VBoxContainer/CompletedLabel
@onready var ct_label = $InfoPanel/VBoxContainer/CTLabel

var sim_engine: SimEngine = null
var machine_displays = {}
var buffer_displays = {}

func _ready():
	_setup_buttons()
	_load_data_and_init()

func _setup_buttons():
	start_btn.pressed.connect(_on_start)
	pause_btn.pressed.connect(_on_pause)
	reset_btn.pressed.connect(_on_reset)
	
	speed_1x.pressed.connect(_set_speed.bind(1.0, speed_1x))
	speed_10x.pressed.connect(_set_speed.bind(10.0, speed_10x))
	speed_100x.pressed.connect(_set_speed.bind(100.0, speed_100x))

func _load_data_and_init():
	# 加载产线布局
	var layout_file = FileAccess.open("res://data/default_layout.json", FileAccess.READ)
	if not layout_file:
		push_error("无法加载产线布局文件")
		return
	
	var layout_json = JSON.new()
	layout_json.parse(layout_file.get_as_text())
	var layout_data = layout_json.get_data()
	
	# 加载配方
	var recipe_file = FileAccess.open("res://data/recipes.json", FileAccess.READ)
	var recipe_data = null
	if recipe_file:
		var recipe_json = JSON.new()
		recipe_json.parse(recipe_file.get_as_text())
		recipe_data = recipe_json.get_data()
	
	# 创建仿真引擎
	sim_engine = SimEngine.new()
	sim_engine.setup(layout_data, recipe_data)
	sim_engine.time_updated.connect(_on_time_updated)
	sim_engine.wip_updated.connect(_on_wip_updated)
	sim_engine.lot_completed.connect(_on_lot_completed)
	sim_engine.machine_status_changed.connect(_on_machine_status_changed)
	
	# 渲染产线
	_render_layout(layout_data)

func _render_layout(data):
	# 清除旧显示
	for child in machines_node.get_children():
		child.queue_free()
	for child in buffers_node.get_children():
		child.queue_free()
	for child in connections_node.get_children():
		child.queue_free()
	
	machine_displays.clear()
	buffer_displays.clear()
	
	# 渲染连接线
	if data.has("connections"):
		for conn in data.connections:
			_render_connection(conn)
	
	# 渲染缓冲
	if data.has("buffers"):
		for buf in data.buffers:
			_render_buffer(buf)
	
	# 渲染设备
	if data.has("machines"):
		for m in data.machines:
			_render_machine(m)

func _render_machine(m_data):
	var node = Control.new()
	node.position = Vector2(m_data.x, m_data.y)
	node.size = Vector2(120, 70)
	node.name = m_data.id
	
	# 背景
	var bg = ColorRect.new()
	bg.size = Vector2(120, 70)
	bg.color = _get_machine_color(m_data.type)
	bg.name = "BG"
	
	# 高光边框
	var top_line = ColorRect.new()
	top_line.size = Vector2(120, 2)
	top_line.color = Color(1, 1, 1, 0.4)
	
	var bottom_line = ColorRect.new()
	bottom_line.position = Vector2(0, 68)
	bottom_line.size = Vector2(120, 2)
	bottom_line.color = Color(0, 0, 0, 0.3)
	
	# 设备名
	var name_label = Label.new()
	name_label.text = m_data.name
	name_label.position = Vector2(0, 15)
	name_label.size = Vector2(120, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_override_font_sizes/font_size = 14
	name_label.theme_override_colors/font_color = Color(0, 0, 0)
	
	# 状态
	var status_label = Label.new()
	status_label.text = "空闲"
	status_label.position = Vector2(0, 40)
	status_label.size = Vector2(120, 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.theme_override_font_sizes/font_size = 12
	status_label.name = "StatusLabel"
	
	# 队列数量角标
	var badge = ColorRect.new()
	badge.position = Vector2(100, -5)
	badge.size = Vector2(24, 24)
	badge.color = Color(0.9, 0.2, 0.2)
	badge.name = "Badge"
	badge.visible = false
	
	var badge_label = Label.new()
	badge_label.position = Vector2(100, -3)
	badge_label.size = Vector2(24, 20)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.theme_override_font_sizes/font_size = 12
	badge_label.theme_override_colors/font_color = Color(1, 1, 1)
	badge_label.name = "BadgeLabel"
	badge_label.visible = false
	
	node.add_child(bg)
	node.add_child(top_line)
	node.add_child(bottom_line)
	node.add_child(name_label)
	node.add_child(status_label)
	node.add_child(badge)
	node.add_child(badge_label)
	
	machines_node.add_child(node)
	machine_displays[m_data.id] = node

func _render_buffer(b_data):
	var node = Control.new()
	node.position = Vector2(b_data.x, b_data.y)
	node.size = Vector2(80, 50)
	node.name = b_data.id
	
	# 背景
	var bg = ColorRect.new()
	bg.size = Vector2(80, 50)
	bg.color = Color(0.58, 0.44, 0.86)  # 紫色
	
	# 名称
	var name_label = Label.new()
	name_label.text = "缓冲"
	name_label.position = Vector2(0, 8)
	name_label.size = Vector2(80, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_override_font_sizes/font_size = 12
	name_label.theme_override_colors/font_color = Color(1, 1, 1)
	
	# 数量
	var count_label = Label.new()
	count_label.text = "0"
	count_label.position = Vector2(0, 26)
	count_label.size = Vector2(80, 22)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.theme_override_font_sizes/font_size = 16
	count_label.theme_override_colors/font_color = Color(1, 0.9, 0)
	count_label.name = "CountLabel"
	
	node.add_child(bg)
	node.add_child(name_label)
	node.add_child(count_label)
	
	buffers_node.add_child(node)
	buffer_displays[b_data.id] = node

func _render_connection(conn_data):
	# 简单起见，这里先不画连线，用位置关系暗示
	pass

func _get_machine_color(type: String) -> Color:
	match type:
		"clean": return Color(1, 0.84, 0)       # 金黄
		"deposition": return Color(0.2, 0.8, 0.2)   # 绿色
		"lithography": return Color(0.12, 0.56, 1)  # 蓝色
		"etching": return Color(0.86, 0.08, 0.24)   # 红色
		"heat": return Color(1, 0.55, 0)        # 橙色
		"inspect": return Color(0.83, 0.83, 0.83)   # 灰色
		_: return Color(0.5, 0.5, 0.5)

func _on_start():
	if sim_engine:
		sim_engine.start()
		status_label.text = "状态: 运行中"

func _on_pause():
	if sim_engine:
		sim_engine.pause()
		status_label.text = "状态: 暂停" if sim_engine.is_paused else "状态: 运行中"

func _on_reset():
	if sim_engine:
		sim_engine.reset()
		_update_all_displays()
		status_label.text = "状态: 停止"
		completed_label.text = "已完成: 0"
		ct_label.text = "平均CT: --"

func _set_speed(speed: float, btn: Button):
	if sim_engine:
		sim_engine.set_time_scale(speed)
	
	# 更新按钮状态
	speed_1x.button_pressed = (speed == 1.0)
	speed_10x.button_pressed = (speed == 10.0)
	speed_100x.button_pressed = (speed == 100.0)

func _on_time_updated(time_minutes: float):
	var hours = int(time_minutes) / 60
	var mins = int(time_minutes) % 60
	time_label.text = "⏱️ %02d:%02d" % [hours, mins]
	
	# 更新吞吐量
	if sim_engine:
		var tph = sim_engine.get_throughput()
		throughput_label.text = "⚡ %.1f/h" % tph

func _on_wip_updated(wip_count: int):
	wip_label.text = "📦 WIP: %d" % wip_count
	_update_all_displays()

func _on_lot_completed(lot_id: String, total_time: float):
	completed_label.text = "已完成: %d" % sim_engine.completed_lots
	ct_label.text = "平均CT: %.0fmin" % sim_engine.get_average_cycle_time()

func _on_machine_status_changed(machine_id: String, status: String):
	if machine_displays.has(machine_id):
		var display = machine_displays[machine_id]
		var status_label_node = display.get_node("StatusLabel")
		if status_label_node:
			status_label_node.text = status
			status_label_node.theme_override_colors/font_color = Color(0, 0.5, 0) if status == "加工中" else Color(0.4, 0.4, 0.4)

func _update_all_displays():
	if not sim_engine:
		return
	
	# 更新设备显示
	for id in machine_displays.keys():
		var display = machine_displays[id]
		var queue_count = sim_engine.get_machine_queue_count(id)
		
		var badge = display.get_node("Badge")
		var badge_label = display.get_node("BadgeLabel")
		
		if queue_count > 0:
			badge.visible = true
			badge_label.visible = true
			badge_label.text = str(queue_count)
		else:
			badge.visible = false
			badge_label.visible = false
	
	# 更新缓冲显示
	for id in buffer_displays.keys():
		var display = buffer_displays[id]
		var count = sim_engine.get_buffer_count(id)
		var count_label = display.get_node("CountLabel")
		if count_label:
			count_label.text = str(count)

func _process(delta):
	if sim_engine and sim_engine.is_running:
		sim_engine.update(delta)
		_update_all_displays()