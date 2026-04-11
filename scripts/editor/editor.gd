extends Control

@onready var machine_buttons = %MachineButtons
@onready var buffer_button = %BufferButton
@onready var machines_container = %Machines
@onready var connections_container = %Connections
@onready var grid_lines = %GridLines

var machine_types = []
var buffer_type = null
var selected_type = null
var machines = []
var next_id = 1
const GRID_SIZE = 20
const MACHINE_SIZE = Vector2(100, 60)
func _ready():
	_load_machine_types()
	_create_machine_buttons()
	_draw_grid()

func _load_machine_types():
	var file = FileAccess.open("res://data/machine_types.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		var data = json.get_data()
		machine_types = data.machine_types
		buffer_type = data.buffer

func _create_machine_buttons():
	for mt in machine_types:
		var btn = Button.new()
		btn.text = mt.icon + " " + mt.name
		btn.tooltip_text = "点击后在画布上放置" + mt.name
		btn.pressed.connect(_on_machine_button_pressed.bind(mt))
		machine_buttons.add_child(btn)
	
	buffer_button.pressed.connect(_on_buffer_button_pressed)

func _on_machine_button_pressed(machine_type):
	selected_type = machine_type
	_add_machine_at(Vector2(200, 200))

func _on_buffer_button_pressed():
	selected_type = buffer_type
	_add_machine_at(Vector2(200, 200))

func _add_machine_at(pos: Vector2):
	var machine = preload("res://scenes/editor/machine_item.tscn").instantiate()
	machine.setup(selected_type, "M" + str(next_id))
	next_id += 1
	
	# 吸附到网格
	pos.x = round(pos.x / GRID_SIZE) * GRID_SIZE
	pos.y = round(pos.y / GRID_SIZE) * GRID_SIZE
	
	machine.position = pos
	machine.machine_moved.connect(_on_machine_moved)
	machine.machine_deleted.connect(_on_machine_deleted)
	machines_container.add_child(machine)
	machines.append(machine)

func _on_machine_moved(machine):
	# 吸附网格
	machine.position.x = round(machine.position.x / GRID_SIZE) * GRID_SIZE
	machine.position.y = round(machine.position.y / GRID_SIZE) * GRID_SIZE

func _on_machine_deleted(machine):
	machines.erase(machine)
	machine.queue_free()

func _draw_grid():
	var viewport_size = Vector2(1400, 800)
	for x in range(0, int(viewport_size.x), GRID_SIZE):
		var line = Line2D.new()
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, viewport_size.y))
		line.default_color = Color(0.15, 0.15, 0.18, 1)
		line.width = 1
		grid_lines.add_child(line)
	
	for y in range(0, int(viewport_size.y), GRID_SIZE):
		var line = Line2D.new()
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(viewport_size.x, y))
		line.default_color = Color(0.15, 0.15, 0.18, 1)
		line.width = 1
		grid_lines.add_child(line)

func get_layout_data():
	var data = {
		"machines": [],
		"buffers": []
	}
	for m in machines:
		var item = {
			"id": m.machine_id,
			"type": m.machine_type.id,
			"name": m.machine_type.name,
			"position": {"x": m.position.x, "y": m.position.y},
			"process_time": m.machine_type.default_time
		}
		if m.machine_type.id == "buffer":
			data.buffers.append(item)
		else:
			data.machines.append(item)
	return data