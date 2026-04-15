extends Control

# 引用 UI 节点
@onready var log_panel: LogPanel = $VBoxContainer/MainContent/LogPanel
@onready var start_button: Button = $VBoxContainer/ToolBar/StartButton
@onready var pause_button: Button = $VBoxContainer/ToolBar/PauseButton
@nready var stop_button: Button = $VBoxContainer/ToolBar/StopButton
@onready var create_lot_button: Button = $VBoxContainer/ToolBar/CreateLotButton
@onready var time_scale_spin: SpinBox = $VBoxContainer/ToolBar/TimeScaleSpin
@onready var status_label: Label = $VBoxContainer/StatusBar/StatusLabel

# 配置
var config: Dictionary = {
	"factory_config": "res://config/factory.json",
	"recipe_config": "res://config/recipe.json",
	"eap_config": "res://config/eap_config.json",
	"mes_endpoint": "http://localhost:8080",
	"server_port": 8081
}

func _ready():
	print("🔥 FabSim v0.1 启动！")
	
	# 设置日志面板引用
	FabSimEngine.log_panel = log_panel
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	create_lot_button.pressed.connect(_on_create_lot_pressed)
	time_scale_spin.value_changed.connect(_on_time_scale_changed)
	
	# 连接引擎信号
	FabSimEngine.simulation_started.connect(_on_simulation_started)
	FabSimEngine.simulation_paused.connect(_on_simulation_paused)
	FabSimEngine.simulation_resumed.connect(_on_simulation_resumed)
	FabSimEngine.simulation_stopped.connect(_on_simulation_stopped)
	FabSimEngine.tick.connect(_on_tick)
	
	# 初始化引擎
	_initialize_engine()

func _initialize_engine():
	log_panel.log_info("正在初始化 FabSim 引擎...")
	
	if FabSimEngine.initialize(config):
		log_panel.log_success("引擎初始化完成！")
		_update_status("就绪")
	else:
		log_panel.log_error("引擎初始化失败！")
		_update_status("初始化失败")

func _on_start_pressed():
	FabSimEngine.start_simulation()

func _on_pause_pressed():
	FabSimEngine.pause_simulation()

func _on_stop_pressed():
	FabSimEngine.stop_simulation()

func _on_create_lot_pressed():
	var lot_id = FabSimEngine.create_lot()
	log_panel.log_success("创建新批次: %s" % lot_id)

func _on_time_scale_changed(value: float):
	FabSimEngine.set_time_scale(value)
	log_panel.log_info("时间倍率: %.0fx" % value)

func _on_simulation_started():
	_update_status("运行中")
	start_button.disabled = true
	pause_button.disabled = false
	stop_button.disabled = false

func _on_simulation_paused():
	_update_status("已暂停")
	pause_button.text = "继续"

func _on_simulation_resumed():
	_update_status("运行中")
	pause_button.text = "暂停"

func _on_simulation_stopped():
	_update_status("已停止")
	start_button.disabled = false
	pause_button.disabled = true
	stop_button.disabled = true
	pause_button.text = "暂停"

func _on_tick(_delta: float):
	_update_status_display()

func _update_status(status: String):
	status_label.text = "状态: %s | 时间: %s" % [status, FabSimEngine.time_controller.get_formatted_time()]

func _update_status_display():
	var stats = FabSimEngine.get_simulation_stats()
	status_label.text = "状态: %s | 时间: %s | 批次: %d/%d | WIP: %d" % [
		"运行中" if stats.is_running else "已停止",
		stats.current_time,
		stats.total_lots_completed,
		stats.total_lots_created,
		stats.wip
	]

# 快捷测试：按空格创建批次
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			_on_create_lot_pressed()
