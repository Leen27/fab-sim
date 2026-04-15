extends Control

@onready var content = $Content

var editor_scene = null
var simulator_scene = null

func _ready():
	print("🔥 FabSim 启动！")
	_load_scenes()

func _load_scenes():
	# 加载编辑器场景
	var editor = load("res://scenes/editor/editor.tscn")
	if editor:
		editor_scene = editor.instantiate()
		content.get_child(0).add_child(editor_scene)
		content.get_child(0).remove_child(content.get_child(0).get_child(0))  # 移除placeholder
	
	# 加载仿真器场景
	var simulator = load("res://scenes/simulator/simulator.tscn")
	if simulator:
		simulator_scene = simulator.instantiate()
		content.get_child(1).add_child(simulator_scene)
		content.get_child(1).remove_child(content.get_child(1).get_child(0))  # 移除placeholder

func _on_tab_changed(tab):
	if tab == 1 and editor_scene:
		# 切换到仿真器时，传递产线数据
		var layout_data = editor_scene.get_layout_data()
		if simulator_scene:
			simulator_scene.set_layout_data(layout_data)