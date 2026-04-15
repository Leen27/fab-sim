class_name FabSimEngine
extends Node

# 信号
signal simulation_started
signal simulation_paused
signal simulation_resumed
signal simulation_stopped
signal tick(delta_time: float)

# 核心模块
var time_controller: TimeController
var lot_tracker: LotTracker
var event_dispatcher: EventDispatcher

# 工厂模型
var factory_loader: FactoryLoader
var recipe: Recipe
var eap_config: EapConfig

# 设备与 Bank
var equipment_fsm: Dictionary = {}  # equipment_id -> EquipmentFSM
var banks: Dictionary = {}  # bank_id -> Bank

# MES 接口
var mes_http_server: MesHttpServer
var mes_http_client: MesHttpClient
var eap_handler: EapMessageHandler
var bank_handler: BankMessageHandler

# EAP 仿真
var eap_simulator: EapSimulator

# UI 引用
var log_panel: LogPanel

# 配置
var config: Dictionary = {}
var is_initialized: bool = false

func _ready():
	# 初始化核心模块
	time_controller = TimeController.new()
	lot_tracker = LotTracker.new()
	event_dispatcher = EventDispatcher.new()
	
	add_child(event_dispatcher)

func initialize(p_config: Dictionary) -> bool:
	config = p_config
	
	log_panel?.log_info("FabSim 初始化中...")
	
	# 1. 加载配置
	if not _load_configurations():
		return false
	
	# 2. 初始化工厂模型
	if not _init_factory_model():
		return false
	
	# 3. 初始化 EAP 仿真
	if not _init_eap_simulation():
		return false
	
	# 4. 初始化 MES 接口
	if not _init_mes_interface():
		return false
	
	# 5. 连接信号
	_connect_signals()
	
	is_initialized = true
	log_panel?.log_success("FabSim 初始化完成！")
	return true

func _load_configurations() -> bool:
	# 加载工厂配置
	factory_loader = FactoryLoader.new()
	var factory_path = config.get("factory_config", "res://config/factory.json")
	if not factory_loader.load_factory(factory_path):
		log_panel?.log_error("工厂配置加载失败")
		return false
	log_panel?.log_info("工厂配置加载成功")
	
	# 加载配方
	recipe = Recipe.new()
	var recipe_path = config.get("recipe_config", "res://config/recipe.json")
	if not recipe.load_from_json(recipe_path):
		log_panel?.log_warning("配方配置加载失败，使用默认配置")
	else:
		log_panel?.log_info("配方配置加载成功")
	
	# 加载 EAP 配置
	eap_config = EapConfig.new()
	var eap_path = config.get("eap_config", "res://config/eap_config.json")
	if not eap_config.load_from_json(eap_path):
		log_panel?.log_warning("EAP 配置加载失败，使用默认配置")
	else:
		log_panel?.log_info("EAP 配置加载成功")
	
	return true

func _init_factory_model() -> bool:
	# 创建设备 FSM
	for eq_data in factory_loader.equipment_list:
		var fsm = EquipmentFSM.new(
			eq_data.equipment_id,
			eq_data.equipment_type,
			eq_data.equipment_name
		)
		fsm.area_id = eq_data.area_id
		fsm.work_area_id = eq_data.work_area_id
		fsm.input_bank = eq_data.input_bank
		fsm.output_bank = eq_data.output_bank
		fsm.upstream = eq_data.upstream
		fsm.downstream = eq_data.downstream
		
		equipment_fsm[eq_data.equipment_id] = fsm
		
		# 连接信号
		fsm.control_state_changed.connect(_on_control_state_changed)
		fsm.process_state_changed.connect(_on_process_state_changed)
		fsm.processing_started.connect(_on_processing_started)
		fsm.processing_completed.connect(_on_processing_completed)
	
	log_panel?.log_info("创建了 %d 台设备" % equipment_fsm.size())
	
	# 创建 Banks
	for bank_data in factory_loader.bank_list:
		var bank_type = Bank.BankType.CENTRAL
		match bank_data.bank_type:
			"INPUT": bank_type = Bank.BankType.INPUT
			"OUTPUT": bank_type = Bank.BankType.OUTPUT
		
		var bank = Bank.new(bank_data.bank_id, bank_data.bank_name, bank_type)
		bank.capacity = bank_data.capacity
		bank.dispatch_policy = bank_data.dispatch_policy
		bank.associated_equipment = bank_data.associated_equipment
		
		banks[bank_data.bank_id] = bank
	
	log_panel?.log_info("创建了 %d 个 Bank" % banks.size())
	
	return true

func _init_eap_simulation() -> bool:
	eap_simulator = EapSimulator.new(eap_config)
	
	# 注册所有设备到 EAP 仿真器
	for eq_id in equipment_fsm.keys():
		var fsm = equipment_fsm[eq_id]
		eap_simulator.register_equipment(eq_id, fsm.equipment_type)
	
	return true

func _init_mes_interface() -> bool:
	# 创建 HTTP 客户端
	mes_http_client = MesHttpClient.new()
	add_child(mes_http_client)
	
	var mes_endpoint = config.get("mes_endpoint", "http://localhost:8080")
	var auth_token = config.get("auth_token", "")
	mes_http_client.setup(mes_endpoint, auth_token)
	
	# 创建消息处理器
	eap_handler = EapMessageHandler.new(eap_simulator, mes_http_client)
	bank_handler = BankMessageHandler.new(mes_http_client)
	
	# 注册所有 Bank
	for bank in banks.values():
		bank_handler.register_bank(bank)
	
	# 连接 EAP 处理器信号
	eap_handler.eap_command_received.connect(_on_eap_command)
	
	# 连接 Bank 处理器信号
	bank_handler.dispatch_requested.connect(_on_dispatch_requested)
	bank_handler.dispatch_confirmed.connect(_on_dispatch_confirmed)
	
	# 创建 HTTP 服务器
	mes_http_server = MesHttpServer.new()
	add_child(mes_http_server)
	
	var server_port = config.get("server_port", 8081)
	if not mes_http_server.start_server(server_port):
		log_panel?.log_error("MES HTTP 服务器启动失败")
		return false
	
	log_panel?.log_info("MES HTTP 服务器启动在端口 %d" % server_port)
	
	# 连接服务器信号
	mes_http_server.eap_command_received.connect(_on_server_eap_command)
	mes_http_server.command_received.connect(_on_server_equipment_command)
	mes_http_server.dispatch_received.connect(_on_server_dispatch_command)
	
	return true

func _connect_signals():
	time_controller.time_updated.connect(_on_time_updated)
	time_controller.simulation_started.connect(func(): simulation_started.emit())
	time_controller.simulation_paused.connect(func(): simulation_paused.emit())
	time_controller.simulation_resumed.connect(func(): simulation_resumed.emit())
	time_controller.simulation_stopped.connect(func(): simulation_stopped.emit())

func _process(delta: float):
	if not is_initialized:
		return
	
	# 更新时间控制器
	time_controller.update(delta)
	
	# 处理 EAP 待发送事件
	_process_eap_events()

func _process_eap_events():
	if mes_http_client == null or not mes_http_client.enabled:
		return
	
	for eq_id in equipment_fsm.keys():
		var events = eap_simulator.get_pending_events(eq_id)
		for event in events:
			eap_handler.report_collection_event(eq_id, event.ceid, event.reports)

# ============ 公共接口 ============

func start_simulation():
	time_controller.start()
	
	# 让所有设备上线并进入 REMOTE 模式
	for fsm in equipment_fsm.values():
		fsm.go_online()
		fsm.go_remote()

func pause_simulation():
	time_controller.pause()

func stop_simulation():
	time_controller.stop()

func reset_simulation():
	time_controller.reset()
	lot_tracker = LotTracker.new()  # 重置批次跟踪
	
	# 重置所有设备
	for fsm in equipment_fsm.values():
		fsm.go_offline()

func create_lot(recipe_id: String = "") -> String:
	if recipe_id == "":
		recipe_id = recipe.recipe_id
	
	var lot_id = lot_tracker.create_lot(recipe_id)
	
	# 将批次放入第一个 Bank
	var first_bank = banks.values()[0] if banks.size() > 0 else null
	if first_bank:
		first_bank.add_lot(lot_id, "SYSTEM")
		lot_tracker.set_lot_location(lot_id, first_bank.bank_id)
	
	return lot_id

func set_time_scale(scale: float):
	time_controller.set_time_scale(scale)

# ============ 信号处理 ============

func _on_time_updated(current_time: float):
	tick.emit(time_controller.time_scale / 60.0)  # 转换为分钟

func _on_control_state_changed(equipment_id: String, new_state: int, old_state: int):
	var fsm = equipment_fsm[equipment_id]
	log_panel?.log_info("设备 %s 控制状态: %s -> %s" % [
		equipment_id,
		EquipmentFSM.control_state_to_string(old_state),
		EquipmentFSM.control_state_to_string(new_state)
	])
	
	# 更新 EAP 状态变量
	var svid = 1 if new_state == EquipmentFSM.ControlState.REMOTE else 0
	eap_simulator.update_status_variable(equipment_id, 1, svid)

func _on_process_state_changed(equipment_id: String, new_state: int, old_state: int):
	var fsm = equipment_fsm[equipment_id]
	log_panel?.log_info("设备 %s 工艺状态: %s -> %s" % [
		equipment_id,
		EquipmentFSM.process_state_to_string(old_state),
		EquipmentFSM.process_state_to_string(new_state)
	])

func _on_processing_started(equipment_id: String, lot_id: String, ppid: String):
	lot_tracker.set_lot_status(lot_id, LotTracker.LotStatus.PROCESSING)
	lot_tracker.set_lot_location(lot_id, equipment_id)
	
	log_panel?.log_event("PROCESSING_STARTED", {
		"equipment_id": equipment_id,
		"lot_id": lot_id,
		"ppid": ppid
	})

func _on_processing_completed(equipment_id: String, lot_id: String, result: String):
	var fsm = equipment_fsm[equipment_id]
	
	# 将批次移到输出 Bank
	if fsm.output_bank != "":
		var bank = banks.get(fsm.output_bank)
		if bank:
			bank.add_lot(lot_id, equipment_id)
			lot_tracker.set_lot_location(lot_id, fsm.output_bank)
			lot_tracker.set_lot_status(lot_id, LotTracker.LotStatus.HOLDING)
	
	log_panel?.log_event("PROCESSING_COMPLETED", {
		"equipment_id": equipment_id,
		"lot_id": lot_id,
		"result": result
	})

func _on_eap_command(equipment_id: String, rcmd: String, parameters: Array):
	log_panel?.log_eap("S2F41", equipment_id, {"rcmd": rcmd})
	
	var fsm = equipment_fsm.get(equipment_id)
	if fsm == null:
		return
	
	match rcmd:
		"START":
			var lot_id = fsm.get_next_lot()
			if lot_id != "":
				var ppid = "STD_RECIPE"  # 应从参数获取
				fsm.start_processing(lot_id, ppid)
		
		"STOP":
			fsm.stop_processing()
		
		"PAUSE":
			fsm.pause_processing()
		
		"RESUME":
			fsm.resume_processing()
		
		"ABORT":
			fsm.abort_processing()

func _on_dispatch_requested(bank_id: String, lot_id: String, candidates: Array):
	log_panel?.log_info("Bank %s 请求派工: %s" % [bank_id, lot_id])

func _on_dispatch_confirmed(bank_id: String, lot_id: String, target_equipment: String):
	log_panel?.log_info("派工确认: %s -> %s" % [lot_id, target_equipment])

func _on_server_eap_command(equipment_id: String, rcmd: String, parameters: Array):
	# 从 HTTP 服务器收到的 EAP 命令
	var response = eap_handler.handle_incoming_message({
		"stream_function": "S2F41",
		"equipment_id": equipment_id,
		"rcmd": rcmd,
		"parameters": parameters
	})
	log_panel?.log_mes("IN", "/eap/command", response)

func _on_server_equipment_command(equipment_id: String, command: String, parameters: Dictionary):
	log_panel?.log_mes("IN", "/equipment/command", {
		"equipment_id": equipment_id,
		"command": command
	})

func _on_server_dispatch_command(bank_id: String, lot_id: String, target_equipment: String):
	bank_handler.handle_dispatch_command(bank_id, lot_id, target_equipment)

# ============ 查询接口 ============

func get_equipment_status(equipment_id: String) -> Dictionary:
	var fsm = equipment_fsm.get(equipment_id)
	if fsm:
		return fsm.get_all_status()
	return {}

func get_all_equipment_status() -> Array:
	var result = []
	for fsm in equipment_fsm.values():
		result.append(fsm.get_all_status())
	return result

func get_bank_status(bank_id: String) -> Dictionary:
	return bank_handler.get_bank_status(bank_id)

func get_all_bank_status() -> Array:
	return bank_handler.get_all_bank_status()

func get_simulation_stats() -> Dictionary:
	return {
		"current_time": time_controller.get_formatted_time(),
		"time_scale": time_controller.time_scale,
		"is_running": time_controller.is_running,
		"total_lots_created": lot_tracker.total_created,
		"total_lots_completed": lot_tracker.total_completed,
		"cycle_time": lot_tracker.get_cycle_time(),
		"wip": lot_tracker.get_active_lots().size()
	}
