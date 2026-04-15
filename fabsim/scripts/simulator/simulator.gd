extends Control

@onready var time_label = %TimeLabel
@onready var wip_label = %WipLabel
@onready var throughput_label = %ThroughputLabel
@onready var machines_container = %Machines
@onready var lots_container = %Lots
@onready var status_label = %Status

var sim_engine = null
var layout_data = null
var is_running = false

func _ready():
	_setup_buttons()

func _setup_buttons():
	$VBoxContainer/ControlPanel/StartButton.pressed.connect(_on_start)
	$VBoxContainer/ControlPanel/PauseButton.pressed.connect(_on_pause)
	$VBoxContainer/ControlPanel/ResetButton.pressed.connect(_on_reset)
	
	$VBoxContainer/ControlPanel/SpeedButton1.pressed.connect(_set_speed.bind(1))
	$VBoxContainer/ControlPanel/SpeedButton10.pressed.connect(_set_speed.bind(10))
	$VBoxContainer/ControlPanel/SpeedButton100.pressed.connect(_set_speed.bind(100))

func set_layout_data(data):
	layout_data = data
	_render_layout()
	_setup_simulation()

func _render_layout():
	# 清除旧显示
	for child in machines_container.get_children():
		child.queue_free()
	
	if not layout_data:
		return
	
	# 渲染设备
	for m in layout_data.machines:
		var display = _create_machine_display(m)
		machines_container.add_child(display)
	
	# 渲染缓冲
	for b in layout_data.buffers:
		var display = _create_machine_display(b)
		machines_container.add_child(display)

func _create_machine_display(data):
	var node = Node2D.new()
	node.position = Vector2(data.position.x, data.position.y)
	node.name = data.id
	
	var bg = ColorRect.new()
	bg.size = Vector2(100, 60)
	
	# 根据类型设置颜色
	var color = Color.GRAY
	match data.type:
		"clean": color = Color("#FFD700")
		"deposition": color = Color("#32CD32")
		"lithography": color = Color("#1E90FF")
		"etching": color = Color("#DC143C")
		"heat": color = Color("#FF8C00")
		"inspect": color = Color("#D3D3D3")
		"buffer": color = Color("#9370DB")
	bg.color = color
	
	var label = Label.new()
	label.text = data.name
	label.position = Vector2(5, 5)
	label.size = Vector2(90, 25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var status = Label.new()
	status.text = "空闲"
	status.position = Vector2(5, 35)
	status.size = Vector2(90, 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.name = "StatusLabel"
	
	var wip_count = Label.new()
	wip_count.text = "0"
	wip_count.position = Vector2(80, 5)
	wip_count.size = Vector2(20, 20)
	wip_count.name = "WipCount"
	
	node.add_child(bg)
	node.add_child(label)
	node.add_child(status)
	node.add_child(wip_count)
	
	return node

func _setup_simulation():
	sim_engine = preload("res://scripts/core/sim_engine.gd").new()
	sim_engine.setup(layout_data)
	sim_engine.time_updated.connect(_on_time_updated)
	sim_engine.wip_updated.connect(_on_wip_updated)

func _on_start():
	if sim_engine:
		sim_engine.start()
		is_running = true
		status_label.text = "状态: 运行中"

func _on_pause():
	if sim_engine:
		sim_engine.pause()
		is_running = false
		status_label.text = "状态: 暂停"

func _on_reset():
	if sim_engine:
		sim_engine.reset()
		is_running = false
		_update_display()
		status_label.text = "状态: 重置"

func _set_speed(speed):
	if sim_engine:
		sim_engine.set_time_scale(speed)

func _on_time_updated(time_minutes):
	var hours = int(time_minutes) / 60
	var mins = int(time_minutes) % 60
	time_label.text = "⏱️ 时间: %02d:%02d" % [hours, mins]

func _on_wip_updated(wip_count):
	wip_label.text = "📦 WIP: %d" % wip_count

func _update_display():
	if sim_engine:
		_on_time_updated(sim_engine.current_time)
		_on_wip_updated(sim_engine.get_wip_count())

func _process(delta):
	if is_running and sim_engine:
		sim_engine.update(delta)
		_update_machine_status()

func _update_machine_status():
	if not sim_engine:
		return
	
	for machine_id in sim_engine.machine_states.keys():
		var state = sim_engine.machine_states[machine_id]
		var node = machines_container.get_node_or_null(machine_id)
		if node:
			var status_label_node = node.get_node_or_null("StatusLabel")
			if status_label_node:
				status_label_node.text = state.status
			
			var wip_label_node = node.get_node_or_null("WipCount")
			if wip_label_node:
				wip_label_node.text = str(state.wip_count)