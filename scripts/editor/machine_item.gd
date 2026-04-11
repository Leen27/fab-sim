extends Node2D

@onready var background = $Background
@onready var label = $Label
@onready var id_label = $IdLabel
@onready var area = $Area2D
@onready var delete_button = $DeleteButton

signal machine_moved(machine)
signal machine_deleted(machine)

var machine_type = null
var machine_id = ""
var is_dragging = false
var drag_offset = Vector2.ZERO

func setup(type_data, id: String):
	machine_type = type_data
	machine_id = id
	
	# 设置颜色
	background.color = Color(type_data.color)
	
	# 设置文字
	label.text = type_data.name
	id_label.text = id

func _ready():
	area.input_event.connect(_on_input_event)
	delete_button.pressed.connect(_on_delete_pressed)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				delete_button.visible = true
				z_index = 10
			else:
				is_dragging = false
				z_index = 0
				machine_moved.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_on_delete_pressed()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func _on_delete_pressed():
	machine_deleted.emit(self)