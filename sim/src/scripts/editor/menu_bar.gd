extends Control

@onready var newButton: MenuButton = $Panel/HBoxContainer/NewButton
@onready var popup: PopupMenu = newButton.get_popup()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup.add_item("设备")
	popup.id_pressed.connect(onMenuPressed)
	
func onMenuPressed(id):
	print(id)
