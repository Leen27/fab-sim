# ============================================
# FabSim - 半导体工厂仿真系统核心类库
# 版本: 0.1
# ============================================

# ============================================
# 1. 基础数据类 (Value Objects)
# ============================================

class_name Wafer
extends RefCounted

## 晶圆 - 300mm厂的最小管控单位
var wafer_id: String           ## 晶圆唯一ID (如: W20240419001)
var lot_id: String             ## 所属Lot ID
var sequence_in_lot: int       ## 在Lot中的序号 (1-25)
var recipe_id: String          ## 当前工艺配方
var status: WaferStatus        ## 晶圆状态

## 追踪信息
var qtime_start: float         ## Qtime开始时间戳
var operation_history: Array[WaferOperation] = []  ## 操作历史
var chamber_history: Array[String] = []             ## 进过的Chamber列表

## 质量数据
var measurement_data: Dictionary = {}  ## 量测数据 (SPC/EDC)

enum WaferStatus {
	WAITING,           ## 等待
	RESERVED,          ## 已预约
	PROCESSING,        ## 加工中
	COMPLETED,         ## 完成
	ON_HOLD,           ## Hold
	SCRAPPED           ## 报废
}

func _init(id: String, lot: String, seq: int):
	wafer_id = id
	lot_id = lot
	sequence_in_lot = seq
	status = WaferStatus.WAITING
	qtime_start = Time.get_unix_time_from_system()

func record_operation(step: String, equipment: String, chamber: String = ""):
	var op = WaferOperation.new()
	op.step = step
	op.equipment_id = equipment
	op.chamber_id = chamber
	op.timestamp = Time.get_unix_time_from_system()
	operation_history.append(op)
	if chamber != "":
		chamber_history.append(chamber)


class_name WaferOperation
extends RefCounted

## 晶圆操作记录
var step: String               ## 工艺步骤
var equipment_id: String       ## 设备ID
var chamber_id: String         ## Chamber ID
var timestamp: float           ## 时间戳
var result: String             ## 结果 (PASS/FAIL)


class_name Lot
extends RefCounted

## Lot - 生产批次 (通常25片)
var lot_id: String             ## Lot唯一ID
var product_id: String         ## 产品型号
var recipe_id: String          ## 工艺配方ID
var priority: int              ## 优先级 (1-99, 数字越小越优先)
var status: LotStatus          ## Lot状态

## 组成
var wafers: Array[Wafer] = []  ## 包含的晶圆列表
var quantity: int:             ## 当前片数
	get: return wafers.size()

## 时间追踪
var create_time: float         ## 创建时间
var qtime_deadline: float      ## Qtime截止时间

## 当前位置
var current_location: String   ## 当前位置 (Bank/Buffer/Equipment ID)
var current_step: int          ## 当前工艺步骤序号

enum LotStatus {
	WAITING,           ## 等待
	RESERVED,          ## 已预约设备
	QUEUED,            ## 在队列中
	PROCESSING,        ## 加工中
	WAITING_FOR_CARRY, ## 等待搬运
	COMPLETED,         ## 完成所有步骤
	ON_HOLD,           ## Hold状态
	ABORTED            ## 中止
}

func _init(id: String, product: String, recipe: String, count: int = 25):
	lot_id = id
	product_id = product
	recipe_id = recipe
	status = LotStatus.WAITING
	create_time = Time.get_unix_time_from_system()
	
	## 创建晶圆
	for i in range(count):
		var wafer_id = "%s-%02d" % [id, i + 1]
		wafers.append(Wafer.new(wafer_id, id, i + 1))


class_name Recipe
extends RefCounted

## 工艺配方
var recipe_id: String          ## 配方ID
var recipe_name: String        ## 配方名称
var steps: Array[RecipeStep] = []  ## 工艺步骤列表

func _init(id: String, name: String):
	recipe_id = id
	recipe_name = name

func add_step(machine_type: String, process_time: float, params: Dictionary = {}):
	var step = RecipeStep.new()
	step.step_number = steps.size() + 1
	step.machine_type = machine_type
	step.process_time = process_time
	step.parameters = params
	steps.append(step)


class_name RecipeStep
extends RefCounted

## 工艺步骤
var step_number: int           ## 步骤序号
var machine_type: String       ## 所需设备类型
var process_time: float        ## 加工时间(分钟)
var parameters: Dictionary     ## 工艺参数


class_name FOUP
extends RefCounted

## FOUP (Front Opening Unified Pod) - 晶圆传送盒
var foup_id: String            ## FOUP ID
var carrier_id: String         ## 载具ID (与foup_id通常相同)
var capacity: int = 25         ## 容量 (标准25片)
var lots: Array[Lot] = []      ## 包含的Lot列表 (支持Multi-Lot)

## 状态
var status: FOUPStatus
var current_location: String   ## 当前位置ID
var is_empty: bool:
	get: return lots.is_empty()

enum FOUPStatus {
	EMPTY,             ## 空
	OCCUPIED,          ## 占用
	IN_TRANSIT,        ## 搬运中
	AT_EQUIPMENT,      ## 在设备上
	AT_BANK,           ## 在Bank中
	AT_BUFFER          ## 在Buffer中
}

func _init(id: String):
	foup_id = id
	carrier_id = id
	status = FOUPStatus.EMPTY

func load_lot(lot: Lot) -> bool:
	if lots.size() < capacity:
		lots.append(lot)
		status = FOUPStatus.OCCUPIED
		return true
	return false


# ============================================
# 2. 作业控制类 (Control Job / Process Job)
# ============================================

class_name ControlJob
extends RefCounted

## Control Job (CJ) - MES控制设备的单位
## 编码规则: EQPID-YYYYMMDD-XXXX (22位)
var cj_id: String              ## CJ唯一ID
var equipment_id: String       ## 目标设备ID
var status: CJStatus           ## CJ状态

## 包含内容
var lots: Array[Lot] = []      ## 包含的Lot列表 (支持Multi-Lot)
var recipes: Array[String] = [] ## 涉及的Recipe列表 (支持Multi-Recipe)

## 时间
var create_time: float         ## 创建时间 (Reserve时)
var start_time: float          ## 开始时间
var end_time: float            ## 结束时间

## 对应PJ
var process_jobs: Array[ProcessJob] = []  ## 关联的ProcessJob

enum CJStatus {
	RESERVED,          ## 已预约
	QUEUED,            ## 已排队
	PROCESSING,        ## 执行中
	RUNNING_HOLD,      ## Running Hold (异常暂停)
	COMPLETED,         ## 完成
	CANCELLED          ## 取消
}

func _init(eq_id: String, seq: int):
	equipment_id = eq_id
	cj_id = generate_cj_id(eq_id, seq)
	status = CJStatus.RESERVED
	create_time = Time.get_unix_time_from_system()

func generate_cj_id(eq_id: String, seq: int) -> String:
	var date_str = Time.get_date_string_from_system().replace("-", "")
	return "%s-%s-%04d" % [eq_id, date_str, seq]


class_name ProcessJob
extends RefCounted

## Process Job (PJ) - 设备实际执行的作业单位
var pj_id: String              ## PJ ID
var parent_cj: ControlJob      ## 所属的CJ
var equipment_id: String       ## 执行设备

## 执行内容
var current_lot: Lot           ## 当前处理的Lot
var current_recipe: String     ## 当前使用的Recipe
var current_wafer: Wafer       ## 当前处理的Wafer (Wafer Level)

## 状态
var status: PJStatus           ## PJ状态
var start_time: float          ## 开始时间
var end_time: float            ## 结束时间

## 设备内部
var chamber_id: String         ## 使用的Chamber ID

enum PJStatus {
	CREATED,           ## 已创建
	STARTED,           ## 已开始
	WAFER_START,       ## 单片刻开始 (Wafer Level)
	CHAMBER_PROCESS,   ## 进入Chamber (Wafer Level)
	WAFER_END,         ## 单片刻完成 (Wafer Level)
	COMPLETED,         ## 完成
	ABORTED            ## 中止
}

func _init(cj: ControlJob, eq_id: String):
	parent_cj = cj
	equipment_id = eq_id
	pj_id = "%s-PJ%02d" % [cj.cj_id, cj.process_jobs.size() + 1]
	status = PJStatus.CREATED


# ============================================
# 3. 设备与存储类
# ============================================

class_name EquipmentConfig
extends RefCounted

## 设备配置定义 (基于三维分类体系)

## 1. 三维分类
enum CarrierBehavior {
	FIXED_BUFFER,      ## 外置固定缓冲
	INTERNAL_BUFFER    ## 机台内部缓冲
}

enum JobBehavior {
	SINGLE_RECIPE,     ## 单配方
	MULTI_RECIPE,      ## 多配方
	BATCH              ## 批次处理
}

enum MachineBehavior {
	NORMAL,            ## 标准设备
	INLINE,            ## 联机设备
	SORTER,            ## 分拣机
	FURNACE,           ## 炉管
	WET_STATION,       ## 湿法清洗
	N2_OHB,            ## 氮气存储架
	CP,                ## CP测试
	WAT,               ## WAT测试
	AMHS               ## 自动搬运
}

## 基础配置
var equipment_type_id: String
var display_name: String
var category: String           ## LITHOGRAPHY/ETCH/THERMAL等

## 三维分类值
var carrier_behavior: CarrierBehavior
var job_behavior: JobBehavior
var machine_behavior: MachineBehavior

## 仿真参数
var buffer_capacity: int = 2   ## Buffer容量
var process_time_range: Vector2 = Vector2(10, 20)  ## 加工时间范围(分钟)
var setup_time: float = 5.0    ## 准备时间
var recipe_switch_time: float = 10.0  ## 配方切换时间
var parallel_capacity: int = 1 ## 并行加工能力
var batch_size: int = 1        ## 批次大小

## 批次特有参数 (仅Batch设备)
var batching_rules: BatchingRules

## 视觉配置
var visual_config: VisualConfig

## EAP配置
var eap_config: EAPConfig

class BatchingRules:
	var min_batch_size: int = 12      ## 最小凑批数
	var max_wait_time: float = 30.0   ## 最大等待时间(分钟)
	var recipe_compatibility: String = "same_recipe_only"  ## 配方兼容性规则

class VisualConfig:
	var shape: String = "rectangle"   ## 形状
	var width: int = 80               ## 宽度(像素)
	var height: int = 60              ## 高度(像素)
	var color: String = "#FFFFFF"     ## 颜色
	var icon: String = "🔧"            ## 图标
	var label_position: String = "top" ## 标签位置

class EAPConfig:
	var protocol: String = "HSMS"     ## 通信协议
	var message_types: Array[String] = []  ## 支持的SECS消息
	var events: Array[String] = []    ## 上报的事件类型


class_name Equipment
extends Node2D

## 设备基类 - 所有设备的抽象

## 配置
var config: EquipmentConfig
var equipment_id: String

## 状态
var status: EquipmentStatus
var current_cj: ControlJob     ## 当前执行的CJ
var current_pj: ProcessJob     ## 当前执行的PJ

## Buffer (根据carrier_behavior决定)
var buffer: Buffer             ## 设备Buffer

## 统计
var oee_stats: OEEStats        ## OEE统计

enum EquipmentStatus {
	IDLE,              ## 空闲
	SETUP,             ## 准备中
	PROCESSING,        ## 加工中
	MAINTENANCE,       ## 保养中
	DOWN,              ## 故障
	OFFLINE            ## 离线
}

func _init(eq_id: String, eq_config: EquipmentConfig):
	equipment_id = eq_id
	config = eq_config
	status = EquipmentStatus.IDLE
	
	## 根据Buffer类型创建
	if config.carrier_behavior == EquipmentConfig.CarrierBehavior.FIXED_BUFFER:
		buffer = ExternalBuffer.new(eq_id + "_BUF", config.buffer_capacity)
	else:
		buffer = InternalBuffer.new(eq_id + "_IBUF", config.buffer_capacity)
	
	oee_stats = OEEStats.new()

## 虚拟方法 - 子类实现
func can_accept_lot(lot: Lot) -> bool:
	return status == EquipmentStatus.IDLE and buffer.has_space()

func reserve(cj: ControlJob) -> bool:
	## Reserve逻辑
	if can_accept_lot(cj.lots[0]):
		current_cj = cj
		cj.status = ControlJob.CJStatus.RESERVED
		return true
	return false

func track_in(lot: Lot) -> bool:
	## Track In逻辑
	return buffer.add_lot(lot)

func start_processing():
	## 开始加工
	if config.job_behavior == EquipmentConfig.JobBehavior.BATCH:
		_try_start_batch()
	else:
		_start_single_processing()

func _try_start_batch():
	## 批次设备凑批逻辑
	var batching_buffer = buffer as BatchingBuffer
	if batching_buffer.can_form_batch(config.batching_rules.min_batch_size):
		_start_batch_processing(batching_buffer.get_batch())

func _start_single_processing():
	## 单Lot加工
	pass

func _start_batch_processing(batch_lots: Array[Lot]):
	## 批次加工
	pass

func track_out(lot: Lot) -> bool:
	## Track Out逻辑
	return buffer.remove_lot(lot)

func report_wafer_start(wafer: Wafer):
	## 上报Wafer Start (Wafer Level)
	if current_pj:
		current_pj.status = ProcessJob.PJStatus.WAFER_START
		current_pj.current_wafer = wafer

func report_wafer_chamber(wafer: Wafer, chamber: String):
	## 上报Wafer Chamber Process
	if current_pj:
		current_pj.status = ProcessJob.PJStatus.CHAMBER_PROCESS
		current_pj.chamber_id = chamber

func report_wafer_end(wafer: Wafer):
	## 上报Wafer End
	if current_pj:
		current_pj.status = ProcessJob.PJStatus.WAFER_END


class_name Buffer
extends RefCounted

## Buffer基类 (设备缓冲)

var buffer_id: String
var capacity: int
var lots: Array[Lot] = []
var foup_map: Dictionary = {}  ## FOUP -> Lot映射

func _init(id: String, cap: int):
	buffer_id = id
	capacity = cap

func has_space() -> bool:
	return lots.size() < capacity

func add_lot(lot: Lot) -> bool:
	if has_space():
		lots.append(lot)
		return true
	return false

func remove_lot(lot: Lot) -> bool:
	var idx = lots.find(lot)
	if idx >= 0:
		lots.remove_at(idx)
		return true
	return false

func get_first_lot() -> Lot:
	return lots[0] if not lots.is_empty() else null


class_name ExternalBuffer
extends Buffer

## 外置固定缓冲 (FixedBuffer)
## Buffer和设备是分离的节点，FOUP在外部等待

var parent_equipment: Equipment  ## 所属设备

func _init(id: String, cap: int).(id, cap):
	pass


class_name InternalBuffer
extends Buffer

## 机台内部缓冲 (InternalBuffer)
## Buffer是设备的一部分，FOUP进入设备内部

func _init(id: String, cap: int).(id, cap):
	pass


class_name BatchingBuffer
extends InternalBuffer

## 批次缓冲 (用于Furnace/WetStation)
## 支持凑批逻辑

var waiting_lots: Array[Lot] = []   ## 等待凑批的Lot
var recipe_groups: Dictionary = {}  ## 按Recipe分组的Lot

func can_form_batch(min_size: int) -> bool:
	for recipe in recipe_groups:
		if recipe_groups[recipe].size() >= min_size:
			return true
	return false

func get_batch() -> Array[Lot]:
	## 返回可以凑成一批的Lot
	for recipe in recipe_groups:
		var group = recipe_groups[recipe]
		if group.size() >= 1:  ## 实际用min_batch_size
			return group.duplicate()
	return []

func add_lot(lot: Lot) -> bool:
	if super.add_lot(lot):
		if not recipe_groups.has(lot.recipe_id):
			recipe_groups[lot.recipe_id] = []
		recipe_groups[lot.recipe_id].append(lot)
		return true
	return false


class_name Bank
extends Node2D

## Bank (区域存储库) - 区域级的集中存储

var bank_id: String
var display_name: String
var capacity: int = 100          ## 大容量
var zones: Dictionary = {}       ## 存储分区

## 内容
var stored_foups: Array[FOUP] = []
var stored_lots: Array[Lot] = []

## 服务范围
var serving_equipments: Array[String] = []  ## 服务哪些设备

func _init(id: String, name: String, cap: int = 100):
	bank_id = id
	display_name = name
	capacity = cap

func store_foup(foup: FOUP) -> bool:
	if stored_foups.size() < capacity:
		stored_foups.append(foup)
		foup.status = FOUP.FOUPStatus.AT_BANK
		foup.current_location = bank_id
		return true
	return false

func retrieve_foup(foup_id: String) -> FOUP:
	for foup in stored_foups:
		if foup.foup_id == foup_id:
			stored_foups.erase(foup)
			return foup
	return null

func find_lots_by_recipe(recipe_id: String) -> Array[Lot]:
	## 按Recipe查找Lot (用于Batch凑批)
	var result: Array[Lot] = []
	for lot in stored_lots:
		if lot.recipe_id == recipe_id:
			result.append(lot)
	return result


# ============================================
# 4. 设备子类 (具体设备类型)
# ============================================

class_name NormalEquipment
extends Equipment

## 标准单槽设备 (光刻机、刻蚀机等)
## FixedBuffer + SingleRecipe + Normal

func _init(eq_id: String, eq_config: EquipmentConfig).(eq_id, eq_config):
	config.machine_behavior = EquipmentConfig.MachineBehavior.NORMAL
	config.carrier_behavior = EquipmentConfig.CarrierBehavior.FIXED_BUFFER
	config.job_behavior = EquipmentConfig.JobBehavior.SINGLE_RECIPE

func _start_single_processing():
	var lot = buffer.get_first_lot()
	if lot:
		## 创建PJ
		current_pj = ProcessJob.new(current_cj, equipment_id)
		current_pj.current_lot = lot
		current_pj.current_recipe = lot.recipe_id
		current_pj.status = ProcessJob.PJStatus.STARTED


class_name FurnaceEquipment
extends Equipment

## 炉管设备
## InternalBuffer + Batch + Furnace

func _init(eq_id: String, eq_config: EquipmentConfig).(eq_id, eq_config):
	config.machine_behavior = EquipmentConfig.MachineBehavior.FURNACE
	config.carrier_behavior = EquipmentConfig.CarrierBehavior.INTERNAL_BUFFER
	config.job_behavior = EquipmentConfig.JobBehavior.BATCH
	config.batch_size = 25
	config.batching_rules = EquipmentConfig.BatchingRules.new()

func _try_start_batch():
	var internal_buf = buffer as BatchingBuffer
	if internal_buf.can_form_batch(config.batching_rules.min_batch_size):
		var batch = internal_buf.get_batch()
		_start_batch_processing(batch)

func _start_batch_processing(batch_lots: Array[Lot]):
	current_pj = ProcessJob.new(current_cj, equipment_id)
	current_pj.status = ProcessJob.PJStatus.STARTED
	## 批次处理逻辑...


class_name SorterEquipment
extends Equipment

## Sorter分拣机
## FixedBuffer + MultiRecipe + Sorter

var input_ports: int = 2
var output_ports: int = 2

func _init(eq_id: String, eq_config: EquipmentConfig).(eq_id, eq_config):
	config.machine_behavior = EquipmentConfig.MachineBehavior.SORTER
	config.carrier_behavior = EquipmentConfig.CarrierBehavior.FIXED_BUFFER
	config.job_behavior = EquipmentConfig.JobBehavior.MULTI_RECIPE


class_name N2OHBEquipment
extends Equipment

## 氮气存储架 (纯存储设备)
## FixedBuffer + SingleRecipe + N2_OHB

func _init(eq_id: String, eq_config: EquipmentConfig).(eq_id, eq_config):
	config.machine_behavior = EquipmentConfig.MachineBehavior.N2_OHB
	config.carrier_behavior = EquipmentConfig.CarrierBehavior.FIXED_BUFFER
	config.job_behavior = EquipmentConfig.JobBehavior.SINGLE_RECIPE
	status = EquipmentStatus.IDLE  ## 纯存储，始终Idle


# ============================================
# 5. EAP通信类
# ============================================

class_name EAPMessage
extends RefCounted

## EAP通信消息 (SECS/GEM风格)

var message_type: String       ## 如 "S1F1", "S2F41", "S6F11"
var equipment_id: String       ## 目标设备
var data: Dictionary = {}      ## 消息内容
var timestamp: float

func _init(msg_type: String, eq_id: String):
	message_type = msg_type
	equipment_id = eq_id
	timestamp = Time.get_unix_time_from_system()


class_name EAPAdapter
extends RefCounted

## EAP适配器 - 桥接MES和设备

signal message_received(msg: EAPMessage)
signal equipment_event(equipment_id: String, event: String)

var connected_equipments: Dictionary = {}  ## equipment_id -> Equipment

func connect_equipment(equipment: Equipment):
	connected_equipments[equipment.equipment_id] = equipment

func send_message(msg: EAPMessage):
	## 发送消息到设备
	print("[EAP] %s -> %s: %s" % [msg.message_type, msg.equipment_id, msg.data])

func handle_event(equipment_id: String, event: String, data: Dictionary):
	## 处理设备上报事件
	match event:
		"TrackIn":
			emit_signal("equipment_event", equipment_id, "TrackIn")
		"TrackOut":
			emit_signal("equipment_event", equipment_id, "TrackOut")
		"WaferStart":
			emit_signal("equipment_event", equipment_id, "WaferStart")
		"WaferEnd":
			emit_signal("equipment_event", equipment_id, "WaferEnd")


# ============================================
# 6. MES核心类
# ============================================

class_name MESCore
extends Node

## MES核心系统

signal lot_completed(lot_id: String)
signal equipment_status_changed(eq_id: String, status: int)

## 数据存储
var lots: Dictionary = {}          ## lot_id -> Lot
var wafers: Dictionary = {}        ## wafer_id -> Wafer
var recipes: Dictionary = {}       ## recipe_id -> Recipe
var equipments: Dictionary = {}    ## eq_id -> Equipment
var banks: Dictionary = {}         ## bank_id -> Bank

## 作业控制
var active_cjs: Dictionary = {}    ## cj_id -> ControlJob
var cj_sequence: int = 0           ## CJ流水号

## 调度器
var rtd_scheduler: RTDScheduler

## EAP适配器
var eap_adapter: EAPAdapter

func _ready():
	rtd_scheduler = RTDScheduler.new()
	eap_adapter = EAPAdapter.new()
	eap_adapter.equipment_event.connect(_on_equipment_event)

func register_equipment(equipment: Equipment):
	equipments[equipment.equipment_id] = equipment
	eap_adapter.connect_equipment(equipment)

func create_lot(lot_id: String, product: String, recipe: String) -> Lot:
	var lot = Lot.new(lot_id, product, recipe)
	lots[lot_id] = lot
	## 索引所有wafer
	for wafer in lot.wafers:
		wafers[wafer.wafer_id] = wafer
	return lot

func reserve_equipment(equipment_id: String, lot: Lot) -> ControlJob:
	## 创建CJ并预约设备
	var eq = equipments.get(equipment_id)
	if not eq:
		return null
	
	cj_sequence += 1
	var cj = ControlJob.new(equipment_id, cj_sequence)
	cj.lots.append(lot)
	
	if eq.reserve(cj):
		active_cjs[cj.cj_id] = cj
		return cj
	return null

func _on_equipment_event(eq_id: String, event: String):
	## 处理设备事件
	match event:
		"TrackIn":
			pass
		"TrackOut":
			## Lot完成当前步骤，触发RTD找下一站
			var lot = _find_lot_at_equipment(eq_id)
			if lot:
				_find_next_destination(lot)

func _find_next_destination(lot: Lot):
	## RTD决策下一站
	var next_eq = rtd_scheduler.get_next_equipment(lot)
	if next_eq:
		reserve_equipment(next_eq.equipment_id, lot)

func _find_lot_at_equipment(eq_id: String) -> Lot:
	## 查找在设备上的Lot
	for lot_id in lots:
		var lot = lots[lot_id]
		if lot.current_location == eq_id:
			return lot
	return null


class_name RTDScheduler
extends RefCounted

## RTD实时调度器 - 决定Lot下一站去哪

var mes_core: MESCore

func get_next_equipment(lot: Lot) -> Equipment:
	## RTD决策逻辑
	## 1. 获取当前步骤
	## 2. 查找可用设备
	## 3. 选择最优设备 (最短队列、最快完成等)
	
	var next_step = lot.current_step + 1
	var recipe = mes_core.recipes.get(lot.recipe_id)
	if not recipe or next_step > recipe.steps.size():
		return null
	
	var target_step = recipe.steps[next_step - 1]
	var available_eqs = _find_available_equipment(target_step.machine_type)
	
	return _select_best_equipment(available_eqs, lot)

func _find_available_equipment(machine_type: String) -> Array[Equipment]:
	var result: Array[Equipment] = []
	for eq_id in mes_core.equipments:
		var eq = mes_core.equipments[eq_id]
		if eq.config.equipment_type_id == machine_type:
			if eq.status == Equipment.EquipmentStatus.IDLE:
				result.append(eq)
	return result

func _select_best_equipment(eqs: Array[Equipment], lot: Lot) -> Equipment:
	## 选择最优设备 (FIFO策略)
	if eqs.is_empty():
		return null
	return eqs[0]  ## 简单实现：选第一个


# ============================================
# 7. 统计与报告类
# ============================================

class_name OEEStats
extends RefCounted

## OEE统计 (设备综合效率)

var total_time: float = 0.0
var productive_time: float = 0.0
var idle_time: float = 0.0
var down_time: float = 0.0
var setup_time: float = 0.0

var lot_count: int = 0
var wafer_count: int = 0

func calculate_oee() -> float:
	## OEE = 实际生产时间 / 总时间
	if total_time == 0:
		return 0.0
	return productive_time / total_time

func record_processing_time(duration: float):
	productive_time += duration
	total_time += duration
	wafer_count += 1

func record_idle_time(duration: float):
	idle_time += duration
	total_time += duration


class_name FabReport
extends RefCounted

## 工厂报表

static func generate_wip_report(mes: MESCore) -> String:
	var report = "=== WIP Report ===\n"
	for lot_id in mes.lots:
		var lot = mes.lots[lot_id]
		report += "%s: %s @ %s (Step %d)\n" % [
			lot_id, 
			Lot.LotStatus.keys()[lot.status],
			lot.current_location,
			lot.current_step
		]
	return report

static func generate_oee_report(mes: MESCore) -> String:
	var report = "=== OEE Report ===\n"
	for eq_id in mes.equipments:
		var eq = mes.equipments[eq_id]
		var oee = eq.oee_stats.calculate_oee() * 100
		report += "%s: %.1f%%\n" % [eq_id, oee]
	return report