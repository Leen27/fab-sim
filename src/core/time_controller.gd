class_name TimeController
extends RefCounted

signal time_updated(current_time_minutes: float)
signal simulation_started
signal simulation_paused
signal simulation_resumed
signal simulation_stopped

# 时间配置
var time_scale: float = 1.0  # 1x, 10x, 100x
var is_running: bool = false
var is_paused: bool = false

# 时间状态
var current_time: float = 0.0  # 仿真时间（分钟）
var real_elapsed: float = 0.0  # 真实经过时间（秒）
var start_timestamp: int = 0   # 启动时间戳

# 统计
var total_simulated_minutes: float = 0.0

func _init():
	start_timestamp = Time.get_unix_time_from_system()

func start():
	if is_running:
		return
	is_running = true
	is_paused = false
	simulation_started.emit()

func pause():
	if not is_running:
		return
	is_paused = !is_paused
	if is_paused:
		simulation_paused.emit()
	else:
		simulation_resumed.emit()

func stop():
	is_running = false
	is_paused = false
	simulation_stopped.emit()

func reset():
	stop()
	current_time = 0.0
	real_elapsed = 0.0
	total_simulated_minutes = 0.0
	time_updated.emit(0.0)

func update(delta: float):
	if not is_running or is_paused:
		return
	
	# 推进仿真时间
	var sim_delta = delta * time_scale
	current_time += sim_delta / 60.0  # 转换为分钟
	real_elapsed += delta
	total_simulated_minutes += sim_delta / 60.0
	
	time_updated.emit(current_time)

func set_time_scale(scale: float):
	time_scale = max(0.0, scale)

func get_formatted_time() -> String:
	# 格式: HH:MM
	var hours = int(current_time / 60)
	var minutes = int(current_time) % 60
	return "%02d:%02d" % [hours, minutes]

func get_simulation_speed_label() -> String:
	match int(time_scale):
		0: return "暂停"
		1: return "1x"
		10: return "10x"
		100: return "100x"
		_: return "%dx" % int(time_scale)
