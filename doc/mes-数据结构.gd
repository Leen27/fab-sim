# ============================================
# MES系统核心类定义 (含方法)
# 版本: 0.1
# ============================================

# ============================================
# 1. 枚举类型定义
# ============================================

enum WaferStatus {
	WAITING,           # 等待
	RESERVED,          # 已预约
	PROCESSING,        # 加工中
	COMPLETED,         # 完成
	ON_HOLD,           # Hold
	SCRAPPED           # 报废
}

enum LotStatus {
	WAITING,           # 等待
	RESERVED,          # 已预约设备
	QUEUED,            # 在队列中
	PROCESSING,        # 加工中
	WAITING_FOR_CARRY, # 等待搬运
	COMPLETED,         # 完成所有步骤
	ON_HOLD,           # Hold状态
	ABORTED            # 中止
}

enum FOUPStatus {
	EMPTY,             # 空
	OCCUPIED,          # 占用
	IN_TRANSIT,        # 搬运中
	AT_EQUIPMENT,      # 在设备上
	AT_BANK,           # 在Bank中
	AT_BUFFER          # 在Buffer中
}

enum CJStatus {
	RESERVED,          # 已预约
	QUEUED,            # 已排队
	PROCESSING,        # 执行中
	RUNNING_HOLD,      # Running Hold
	COMPLETED,         # 完成
	CANCELLED          # 取消
}

enum PJStatus {
	CREATED,           # 已创建
	STARTED,           # 已开始
	WAFER_START,       # 单片刻开始
	CHAMBER_PROCESS,   # 进入Chamber
	WAFER_END,         # 单片刻完成
	COMPLETED,         # 完成
	ABORTED            # 中止
}

enum EquipmentStatus {
	IDLE,              # 空闲
	SETUP,             # 准备中
	PROCESSING,        # 加工中
	MAINTENANCE,       # 保养中
	DOWN,              # 故障
	OFFLINE            # 离线
}

enum CarrierBehavior {
	FIXED_BUFFER,      # 外置固定缓冲
	INTERNAL_BUFFER    # 机台内部缓冲
}

enum JobBehavior {
	SINGLE_RECIPE,     # 单配方
	MULTI_RECIPE,      # 多配方
	BATCH              # 批次处理
}

enum MachineBehavior {
	NORMAL,            # 标准设备
	INLINE,            # 联机设备
	SORTER,            # 分拣机
	FURNACE,           # 炉管
	WET_STATION,       # 湿法清洗
	N2_OHB,            # 氮气存储架
	CP,                # CP测试
	WAT,               # WAT测试
	AMHS               # 自动搬运
}

enum TransferStatus {
	PENDING,           # 待执行
	EXECUTING,         # 执行中
	COMPLETED,         # 完成
	FAILED             # 失败
}

# ============================================
# 2. 基础数据类
# ============================================

class Wafer:
	var wafer_id: String           # 晶圆唯一ID
	var lot_id: String             # 所属Lot ID
	var sequence_in_lot: int       # 在Lot中的序号(1-25)
	var recipe_id: String          # 当前工艺配方ID
	var status: WaferStatus        # 晶圆状态
	
	# 追踪信息
	var qtime_start: float         # Qtime开始时间戳
	var operation_history: Array[WaferOperation]  # 操作历史
	var chamber_history: Array[String]            # 进过的Chamber列表
	
	# 质量数据
	var measurement_data: Dictionary  # 量测数据(SPC/EDC)
	var defect_data: Dictionary       # 缺陷数据
	
	# 初始化
	func _init(id: String, lot: String, seq: int):
		pass
	
	# 记录一次操作历史
	# step: 工艺步骤, equipment: 设备ID, chamber: Chamber ID
	func record_operation(step: String, equipment: String, chamber: String = ""):
		pass
	
	# 记录进入Chamber
	# chamber_id: Chamber标识
	func record_chamber_visit(chamber_id: String):
		pass
	
	# 更新Qtime开始时间
	func start_qtime():
		pass
	
	# 检查Qtime是否超时
	# 返回: 是否超时
	func is_qtime_exceeded(limit_minutes: float) -> bool:
		return false
	
	# 更新状态
	# new_status: 新状态
	func update_status(new_status: WaferStatus):
		pass
	
	# 添加量测数据
	# param_name: 参数名, value: 参数值
	func add_measurement(param_name: String, value: float):
		pass

class WaferOperation:
	var operation_id: String       # 操作ID
	var step: String               # 工艺步骤
	var equipment_id: String       # 设备ID
	var chamber_id: String         # Chamber ID
	var timestamp: float           # 时间戳
	var result: String             # 结果(PASS/FAIL)
	
	# 初始化
	func _init():
		pass

class Lot:
	var lot_id: String             # Lot唯一ID
	var product_id: String         # 产品型号
	var recipe_id: String          # 工艺配方ID
	var priority: int              # 优先级(1-99)
	var status: LotStatus          # Lot状态
	var quantity: int              # 当前片数
	
	# 组成
	var wafers: Array[Wafer]       # 包含的晶圆列表
	
	# 时间追踪
	var create_time: float         # 创建时间
	var qtime_deadline: float      # Qtime截止时间
	
	# 当前位置
	var current_location: String   # 当前位置(Bank/Buffer/Equipment ID)
	var current_step: int          # 当前工艺步骤序号
	
	# 初始化，创建指定数量的晶圆
	# id: Lot ID, product: 产品型号, recipe: 配方ID, count: 晶圆数量(默认25)
	func _init(id: String, product: String, recipe: String, count: int = 25):
		pass
	
	# 获取下一个工艺步骤
	# 返回: 下一步骤序号
	func get_next_step() -> int:
		return 0
	
	# 更新Lot状态
	# new_status: 新状态
	func update_status(new_status: LotStatus):
		pass
	
	# 更新当前位置
	# location: 新位置ID, step: 当前步骤
	func update_location(location: String, step: int = -1):
		pass
	
	# 获取所有晶圆ID列表
	# 返回: 晶圆ID数组
	func get_wafer_ids() -> Array[String]:
		return []
	
	# 检查是否所有晶圆都完成
	# 返回: 是否全部完成
	func is_all_wafers_completed() -> bool:
		return false

class Recipe:
	var recipe_id: String          # 配方ID
	var recipe_name: String        # 配方名称
	var product_type: String       # 产品类型
	var steps: Array[RecipeStep]   # 工艺步骤列表
	var version: String            # 版本号
	
	# 初始化
	func _init(id: String, name: String):
		pass
	
	# 添加工艺步骤
	# machine_type: 设备类型, process_time: 加工时间, params: 工艺参数
	func add_step(machine_type: String, process_time: float, params: Dictionary = {}):
		pass
	
	# 获取指定步骤
	# step_number: 步骤序号, 返回: RecipeStep对象
	func get_step(step_number: int) -> RecipeStep:
		return null
	
	# 获取总步骤数
	# 返回: 步骤总数
	func get_total_steps() -> int:
		return 0
	
	# 获取某步骤的设备类型
	# step_number: 步骤序号, 返回: 设备类型字符串
	func get_machine_type_for_step(step_number: int) -> String:
		return ""

class RecipeStep:
	var step_number: int           # 步骤序号
	var step_name: String          # 步骤名称
	var machine_type: String       # 所需设备类型
	var process_time: float        # 标准加工时间(分钟)
	var parameters: Dictionary     # 工艺参数
	var qtime_limit: float         # Qtime限制(分钟)

class FOUP:
	var foup_id: String            # FOUP ID
	var carrier_id: String         # 载具ID
	var capacity: int              # 容量(标准25片)
	var status: FOUPStatus         # FOUP状态
	
	# 内容
	var lots: Array[Lot]           # 包含的Lot列表(Multi-Lot支持)
	var is_empty: bool             # 是否为空
	
	# 位置
	var current_location: String   # 当前位置ID
	var current_location_type: String  # BANK/BUFFER/EQUIPMENT/AMHS
	
	# 初始化
	func _init(id: String):
		pass
	
	# 加载Lot到FOUP
	# lot: 要加载的Lot, 返回: 是否成功
	func load_lot(lot: Lot) -> bool:
		return false
	
	# 从FOUP卸载Lot
	# lot_id: Lot ID, 返回: 卸载的Lot对象
	func unload_lot(lot_id: String) -> Lot:
		return null
	
	# 获取FOUP中的总晶圆数
	# 返回: 晶圆总数
	func get_total_wafer_count() -> int:
		return 0
	
	# 更新位置和状态
	# location: 新位置, location_type: 位置类型, new_status: 新状态
	func update_location(location: String, location_type: String, new_status: FOUPStatus):
		pass
	
	# 清空FOUP
	func clear():
		pass

# ============================================
# 3. 作业控制类
# ============================================

class ControlJob:
	var cj_id: String              # CJ唯一ID(EQPID-YYYYMMDD-XXXX)
	var equipment_id: String       # 目标设备ID
	var status: CJStatus           # CJ状态
	
	# 包含内容(Multi-Lot/Multi-Recipe)
	var lots: Array[Lot]           # 包含的Lot列表
	var recipes: Array[String]     # 涉及的Recipe列表
	
	# 时间
	var create_time: float         # 创建时间(Reserve时)
	var start_time: float          # 开始时间
	var end_time: float            # 结束时间
	
	# 对应PJ
	var process_jobs: Array[ProcessJob]  # 关联的ProcessJob
	
	# 初始化，自动生成CJ ID
	# eq_id: 设备ID, seq: 流水号
	func _init(eq_id: String, seq: int):
		pass
	
	# 生成CJ ID
	# eq_id: 设备ID, seq: 流水号, 返回: CJ ID字符串
	func generate_cj_id(eq_id: String, seq: int) -> String:
		return ""
	
	# 添加Lot到CJ
	# lot: 要添加的Lot, 返回: 是否成功
	func add_lot(lot: Lot) -> bool:
		return false
	
	# 添加Recipe到CJ
	# recipe_id: 配方ID
	func add_recipe(recipe_id: String):
		pass
	
	# 更新CJ状态
	# new_status: 新状态
	func update_status(new_status: CJStatus):
		pass
	
	# 创建Process Job
	# 返回: 创建的PJ对象
	func create_process_job() -> ProcessJob:
		return null
	
	# 检查是否包含指定Lot
	# lot_id: Lot ID, 返回: 是否包含
	func contains_lot(lot_id: String) -> bool:
		return false

class ProcessJob:
	var pj_id: String              # PJ ID
	var parent_cj: ControlJob      # 所属的CJ
	var equipment_id: String       # 执行设备ID
	
	# 执行内容
	var current_lot: Lot           # 当前处理的Lot
	var current_recipe: String     # 当前使用的Recipe
	var current_wafer: Wafer       # 当前处理的Wafer(Wafer Level)
	
	# 状态
	var status: PJStatus           # PJ状态
	var start_time: float          # 开始时间
	var end_time: float            # 结束时间
	
	# 设备内部
	var chamber_id: String         # 使用的Chamber ID
	
	# 初始化
	# cj: 父CJ, eq_id: 设备ID
	func _init(cj: ControlJob, eq_id: String):
		pass
	
	# 更新PJ状态
	# new_status: 新状态
	func update_status(new_status: PJStatus):
		pass
	
	# 设置当前处理的晶圆(Wafer Level)
	# wafer: 晶圆对象
	func set_current_wafer(wafer: Wafer):
		pass
	
	# 记录进入Chamber
	# chamber_id: Chamber ID
	func record_chamber_entry(chamber_id: String):
		pass

# ============================================
# 4. 设备类
# ============================================

class Equipment:
	var equipment_id: String       # 设备唯一ID
	var equipment_type: String     # 设备类型ID
	var display_name: String       # 显示名称
	var category: String           # 设备大类(LITHO/ETCH/THERMAL等)
	
	# 三维分类
	var carrier_behavior: CarrierBehavior   # 载具行为
	var job_behavior: JobBehavior           # Job建立行为
	var machine_behavior: MachineBehavior   # 机台特定行为
	
	# 状态
	var status: EquipmentStatus    # 设备状态
	var current_cj: ControlJob     # 当前执行的CJ
	var current_pj: ProcessJob     # 当前执行的PJ
	
	# 缓冲
	var buffer: Buffer             # 设备Buffer
	
	# 能力
	var parallel_capacity: int     # 并行加工能力
	var batch_size: int            # 批次大小
	
	# EAP连接
	var eap_session_id: String     # EAP会话ID
	
	# 初始化
	# eq_id: 设备ID, eq_config: 设备配置
	func _init(eq_id: String, eq_config: EquipmentConfig):
		pass
	
	# 检查是否可以接受指定Lot
	# lot: Lot对象, 返回: 是否可接受
	func can_accept_lot(lot: Lot) -> bool:
		return false
	
	# Reserve设备(CJ预约)
	# cj: ControlJob对象, 返回: 是否成功
	func reserve(cj: ControlJob) -> bool:
		return false
	
	# Track In(Lot投入设备)
	# lot: Lot对象, 返回: 是否成功
	func track_in(lot: Lot) -> bool:
		return false
	
	# Track Out(Lot从设备产出)
	# lot: Lot对象, 返回: 是否成功
	func track_out(lot: Lot) -> bool:
		return false
	
	# 开始加工
	func start_processing():
		pass
	
	# 完成加工
	func complete_processing():
		pass
	
	# 更新设备状态
	# new_status: 新状态
	func update_status(new_status: EquipmentStatus):
		pass
	
	# 上报Wafer Start(Wafer Level)
	# wafer: 晶圆对象
	func report_wafer_start(wafer: Wafer):
		pass
	
	# 上报Wafer Chamber Process(Wafer Level)
	# wafer: 晶圆对象, chamber: Chamber ID
	func report_wafer_chamber(wafer: Wafer, chamber: String):
		pass
	
	# 上报Wafer End(Wafer Level)
	# wafer: 晶圆对象
	func report_wafer_end(wafer: Wafer):
		pass
	
	# 获取OEE统计数据
	# 返回: OEEData对象
	func get_oee_data() -> OEEData:
		return null
	
	# 检查Buffer是否有空间
	# 返回: 是否有空间
	func has_buffer_space() -> bool:
		return false

class Buffer:
	var buffer_id: String          # Buffer ID
	var capacity: int              # 容量
	var lots: Array[Lot]           # 当前存储的Lot列表
	var parent_equipment: String   # 所属设备ID(外置Buffer)
	
	# 初始化
	# id: Buffer ID, cap: 容量
	func _init(id: String, cap: int):
		pass
	
	# 检查是否有空间
	# 返回: 是否有空间
	func has_space() -> bool:
		return false
	
	# 添加Lot到Buffer
	# lot: Lot对象, 返回: 是否成功
	func add_lot(lot: Lot) -> bool:
		return false
	
	# 从Buffer移除Lot
	# lot: Lot对象, 返回: 是否成功
	func remove_lot(lot: Lot) -> bool:
		return false
	
	# 获取第一个Lot(FIFO)
	# 返回: Lot对象
	func get_first_lot() -> Lot:
		return null
	
	# 获取所有Lot
	# 返回: Lot数组
	func get_all_lots() -> Array[Lot]:
		return []
	
	# 清空Buffer
	func clear():
		pass
	
	# 获取当前Lot数量
	# 返回: Lot数量
	func get_count() -> int:
		return 0

class BatchingBuffer:
	extends Buffer
	var waiting_lots: Array[Lot]   # 等待凑批的Lot
	var recipe_groups: Dictionary  # 按Recipe分组的Lot
	var min_batch_size: int        # 最小凑批数
	
	# 检查是否可以凑成一批
	# min_size: 最小批次数, 返回: 是否可以凑批
	func can_form_batch(min_size: int) -> bool:
		return false
	
	# 获取可以凑成一批的Lot列表
	# 返回: Lot数组
	func get_batch() -> Array[Lot]:
		return []
	
	# 按Recipe分组Lot
	func group_by_recipe():
		pass
	
	# 获取指定Recipe的Lot数量
	# recipe_id: 配方ID, 返回: 数量
	func get_recipe_count(recipe_id: String) -> int:
		return 0

class Bank:
	var bank_id: String            # Bank唯一ID
	var display_name: String       # 显示名称
	var capacity: int              # 总容量
	var zones: Dictionary          # 存储分区(按Recipe/优先级)
	
	# 内容
	var stored_foups: Array[FOUP]  # 存储的FOUP列表
	var stored_lots: Array[Lot]    # 存储的Lot列表
	
	# 服务范围
	var serving_equipments: Array[String]  # 服务哪些设备
	var serving_area: String       # 服务区域
	
	# 初始化
	# id: Bank ID, name: 名称, cap: 容量
	func _init(id: String, name: String, cap: int = 100):
		pass
	
	# 存储FOUP
	# foup: FOUP对象, 返回: 是否成功
	func store_foup(foup: FOUP) -> bool:
		return false
	
	# 检索FOUP
	# foup_id: FOUP ID, 返回: FOUP对象
	func retrieve_foup(foup_id: String) -> FOUP:
		return null
	
	# 按Recipe查找Lot(用于Batch凑批)
	# recipe_id: 配方ID, 返回: Lot数组
	func find_lots_by_recipe(recipe_id: String) -> Array[Lot]:
		return []
	
	# 按优先级查找Lot
	# priority: 优先级, 返回: Lot数组
	func find_lots_by_priority(priority: int) -> Array[Lot]:
		return []
	
	# 获取指定位置的FOUP
	# zone_id: 分区ID, position: 位置, 返回: FOUP对象
	func get_foup_at_position(zone_id: String, position: int) -> FOUP:
		return null
	
	# 检查是否有空间
	# 返回: 是否有空间
	func has_space() -> bool:
		return false
	
	# 获取当前存储数量
	# 返回: FOUP数量
	func get_stored_count() -> int:
		return 0
	
	# 获取指定Zone的FOUP列表
	# zone_id: 分区ID, 返回: FOUP数组
	func get_zone_foups(zone_id: String) -> Array[FOUP]:
		return []
	
	# 添加服务设备
	# equipment_id: 设备ID
	func add_serving_equipment(equipment_id: String):
		pass

# ============================================
# 5. 搬运类(AMHS)
# ============================================

class TransferJob:
	var transfer_id: String        # 搬运任务ID
	var status: TransferStatus     # 搬运状态
	
	# 搬运对象
	var foup_id: String            # 搬运的FOUP ID
	var lot_ids: Array[String]     # 包含的Lot ID列表
	
	# 路径
	var from_location: String      # 起点
	var from_location_type: String # BANK/BUFFER/EQUIPMENT
	var to_location: String        # 终点
	var to_location_type: String   # BANK/BUFFER/EQUIPMENT
	
	# 执行
	var oht_id: String             # 执行的天车ID
	var start_time: float          # 开始时间
	var complete_time: float       # 完成时间
	
	# 初始化
	# foup: FOUP对象, from_loc: 起点, to_loc: 终点
	func _init(foup: FOUP, from_loc: String, to_loc: String):
		pass
	
	# 开始执行
	# oht_id: 天车ID
	func start(oht_id: String):
		pass
	
	# 完成搬运
	func complete():
		pass
	
	# 搬运失败
	# reason: 失败原因
	func fail(reason: String):
		pass
	
	# 更新状态
	# new_status: 新状态
	func update_status(new_status: TransferStatus):
		pass
	
	# 获取搬运时长
	# 返回: 搬运时长(分钟)
	func get_duration() -> float:
		return 0.0

class OHT:
	var oht_id: String             # 天车ID
	var status: String             # IDLE/BUSY/MAINTENANCE
	var current_position: String   # 当前位置
	var current_job: TransferJob   # 当前执行的任务
	
	# 初始化
	# id: 天车ID
	func _init(id: String):
		pass
	
	# 分配搬运任务
	# job: TransferJob对象, 返回: 是否接受
	func assign_job(job: TransferJob) -> bool:
		return false
	
	# 完成任务
	func complete_job():
		pass
	
	# 更新位置
	# position: 新位置
	func update_position(position: String):
		pass
	
	# 更新状态
	# new_status: 新状态
	func update_status(new_status: String):
		pass
	
	# 检查是否可用
	# 返回: 是否可用
	func is_available() -> bool:
		return false

# ============================================
# 6. EAP通信类
# ============================================

class EAPMessage:
	var message_type: String       # SECS消息类型(S1F1/S2F41/S6F11等)
	var equipment_id: String       # 目标设备ID
	var stream_function: String    # Stream.Function
	var data: Dictionary           # 消息内容
	var timestamp: float           # 时间戳
	
	# 初始化
	# msg_type: 消息类型, eq_id: 设备ID
	func _init(msg_type: String, eq_id: String):
		pass
	
	# 添加数据字段
	# key: 字段名, value: 字段值
	func add_data(key: String, value):
		pass
	
	# 获取数据字段
	# key: 字段名, 返回: 字段值
	func get_data(key: String):
		return null
	
	# 序列化为SECS格式
	# 返回: SECS格式字符串
	func to_secs_format() -> String:
		return ""
	
	# 从SECS格式解析
	# secs_data: SECS数据字符串
	func from_secs_format(secs_data: String):
		pass
	
	# 构建S1F1(建立通信)
	# eq_id: 设备ID, 返回: EAPMessage对象
	static func build_s1f1(eq_id: String) -> EAPMessage:
		return null
	
	# 构建S2F41(主机发送命令)
	# eq_id: 设备ID, command: 命令名, 返回: EAPMessage对象
	static func build_s2f41(eq_id: String, command: String) -> EAPMessage:
		return null
	
	# 构建S6F11(事件报告)
	# eq_id: 设备ID, event_name: 事件名, 返回: EAPMessage对象
	static func build_s6f11(eq_id: String, event_name: String) -> EAPMessage:
		return null

class EquipmentEvent:
	var event_id: String           # 事件ID
	var equipment_id: String       # 设备ID
	var event_name: String         # 事件名称(TrackIn/TrackOut/WaferStart等)
	var cj_id: String              # 关联的CJ ID
	var pj_id: String              # 关联的PJ ID
	var timestamp: float           # 时间戳
	var data: Dictionary           # 事件数据
	
	# 初始化
	func _init():
		pass
	
	# 添加事件数据
	# key: 字段名, value: 字段值
	func add_data(key: String, value):
		pass
	
	# 获取事件数据
	# key: 字段名, 返回: 字段值
	func get_data(key: String):
		return null

# ============================================
# 7. 调度类
# ============================================

class RTDDecision:
	var decision_id: String        # 决策ID
	var lot_id: String             # 决策的Lot
	var current_step: int          # 当前步骤
	var next_equipment: String     # 选定的下一台设备
	var decision_reason: String    # 决策原因(最短队列/最快完成等)
	var timestamp: float           # 决策时间
	
	# 初始化
	# lot: Lot对象, step: 当前步骤
	func _init(lot: Lot, step: int):
		pass
	
	# 执行决策，选择最优设备
	# available_equipments: 可用设备列表, rules: 调度规则
	func execute_decision(available_equipments: Array[Equipment], rules: Array[DispatchRule]):
		pass
	
	# 记录决策原因
	# reason: 原因描述
	func record_reason(reason: String):
		pass

class DispatchRule:
	var rule_id: String            # 规则ID
	var rule_name: String          # 规则名称
	var rule_type: String          # FIFO/SPT/CR/OAS等
	var priority: int              # 优先级
	var conditions: Dictionary     # 适用条件
	var parameters: Dictionary     # 规则参数
	
	# 初始化
	# id: 规则ID, name: 规则名, type: 规则类型
	func _init(id: String, name: String, type: String):
		pass
	
	# 应用规则选择设备
	# candidates: 候选设备列表, lot: Lot对象, 返回: 选中的设备
	func apply(candidates: Array[Equipment], lot: Lot) -> Equipment:
		return null
	
	# 检查是否适用于指定Lot
	# lot: Lot对象, 返回: 是否适用
	func is_applicable(lot: Lot) -> bool:
		return false
	
	# 设置规则参数
	# params: 参数字典
	func set_parameters(params: Dictionary):
		pass

# ============================================
# 8. 统计类
# ============================================

class OEEData:
	var equipment_id: String       # 设备ID
	var date: String               # 日期
	
	# 时间分解
	var total_time: float          # 总时间(分钟)
	var productive_time: float     # 生产时间
	var idle_time: float           # 空闲时间
	var down_time: float           # 故障时间
	var setup_time: float          # 换线时间
	
	# 产出
	var lot_count: int             # 加工Lot数
	var wafer_count: int           # 加工晶圆数
	
	# 计算值
	var oee: float                 # OEE值
	var availability: float        # 可用率
	var performance: float         # 性能率
	var quality: float             # 良率
	
	# 初始化
	# eq_id: 设备ID, report_date: 日期
	func _init(eq_id: String, report_date: String):
		pass
	
	# 记录生产时间
	# duration: 时长(分钟)
	func record_productive_time(duration: float):
		pass
	
	# 记录空闲时间
	# duration: 时长(分钟)
	func record_idle_time(duration: float):
		pass
	
	# 记录故障时间
	# duration: 时长(分钟)
	func record_down_time(duration: float):
		pass
	
	# 记录换线时间
	# duration: 时长(分钟)
	func record_setup_time(duration: float):
		pass
	
	# 计算OEE
	# 返回: OEE值(0-1)
	func calculate_oee() -> float:
		return 0.0
	
	# 计算可用率
	# 返回: 可用率(0-1)
	func calculate_availability() -> float:
		return 0.0
	
	# 计算性能率
	# 返回: 性能率(0-1)
	func calculate_performance() -> float:
		return 0.0
	
	# 生成OEE报告
	# 返回: 报告字符串
	func generate_report() -> String:
		return ""

class WIPData:
	var timestamp: float           # 时间戳
	var total_wip: int             # 总WIP数
	var step_wip: Dictionary       # 各步骤WIP分布
	var area_wip: Dictionary       # 各区域WIP分布
	var equipment_wip: Dictionary  # 各设备WIP分布
	
	# 初始化
	func _init():
		pass
	
	# 添加步骤WIP
	# step: 步骤名, count: 数量
	func add_step_wip(step: String, count: int):
		pass
	
	# 添加区域WIP
	# area: 区域名, count: 数量
	func add_area_wip(area: String, count: int):
		pass
	
	# 添加设备WIP
	# equipment: 设备ID, count: 数量
	func add_equipment_wip(equipment: String, count: int):
		pass
	
	# 计算总WIP
	func calculate_total():
		pass
	
	# 生成WIP报告
	# 返回: 报告字符串
	func generate_report() -> String:
		return ""

# ============================================
# 9. MES核心类
# ============================================

class MESContext:
	# 数据存储
	var lots: Dictionary           # lot_id -> Lot
	var wafers: Dictionary         # wafer_id -> Wafer
	var recipes: Dictionary        # recipe_id -> Recipe
	var equipments: Dictionary     # eq_id -> Equipment
	var banks: Dictionary          # bank_id -> Bank
	var foups: Dictionary          # foup_id -> FOUP
	
	# 作业控制
	var active_cjs: Dictionary     # cj_id -> ControlJob
	var active_pjs: Dictionary     # pj_id -> ProcessJob
	var transfer_jobs: Dictionary  # transfer_id -> TransferJob
	
	# 历史记录
	var cj_history: Array[ControlJob]    # CJ历史
	var operation_history: Array[WaferOperation]  # 操作历史
	
	# 初始化
	func _init():
		pass
	
	# 创建Lot
	# lot_id: Lot ID, product: 产品型号, recipe: 配方ID, count: 晶圆数量
	func create_lot(lot_id: String, product: String, recipe: String, count: int = 25) -> Lot:
		return null
	
	# 注册设备
	# equipment: 设备对象
	func register_equipment(equipment: Equipment):
		pass
	
	# 注册Bank
	# bank: Bank对象
	func register_bank(bank: Bank):
		pass
	
	# 预约设备(创建CJ)
	# equipment_id: 设备ID, lot: Lot对象, 返回: CJ对象
	func reserve_equipment(equipment_id: String, lot: Lot) -> ControlJob:
		return null
	
	# Track In(Lot投入设备)
	# cj_id: CJ ID, lot: Lot对象, 返回: 是否成功
	func track_in(cj_id: String, lot: Lot) -> bool:
		return false
	
	# Track Out(Lot从设备产出)
	# cj_id: CJ ID, lot: Lot对象, 返回: 是否成功
	func track_out(cj_id: String, lot: Lot) -> bool:
		return false
	
	# Wafer Start(Wafer Level)
	# cj_id: CJ ID, wafer: 晶圆对象
	func wafer_start(cj_id: String, wafer: Wafer):
		pass
	
	# Wafer Chamber Process(Wafer Level)
	# cj_id: CJ ID, wafer: 晶圆对象, chamber: Chamber ID
	func wafer_chamber_process(cj_id: String, wafer: Wafer, chamber: String):
		pass
	
	# Wafer End(Wafer Level)
	# cj_id: CJ ID, wafer: 晶圆对象
	func wafer_end(cj_id: String, wafer: Wafer):
		pass
	
	# 创建搬运任务
	# foup: FOUP对象, from_loc: 起点, to_loc: 终点, 返回: TransferJob对象
	func create_transfer_job(foup: FOUP, from_loc: String, to_loc: String) -> TransferJob:
		return null
	
	# 获取Lot
	# lot_id: Lot ID, 返回: Lot对象
	func get_lot(lot_id: String) -> Lot:
		return null
	
	# 获取设备
	# eq_id: 设备ID, 返回: 设备对象
	func get_equipment(eq_id: String) -> Equipment:
		return null
	
	# 获取CJ
	# cj_id: CJ ID, 返回: CJ对象
	func get_cj(cj_id: String) -> ControlJob:
		return null
	
	# 查询WIP
	# query: 查询条件, 返回: WIPData对象
	func query_wip(query: WIPQuery) -> WIPData:
		return null
	
	# 生成OEE报告
	# equipment_id: 设备ID(空表示全部), date: 日期, 返回: OEEData数组
	func generate_oee_report(equipment_id: String = "", date: String = "") -> Array[OEEData]:
		return []
	
	# 保存历史记录
	func save_history():
		pass
	
	# 加载历史记录
	func load_history():
		pass

class MESConfig:
	var fab_id: String             # 工厂ID
	var fab_name: String           # 工厂名称
	
	# 系统配置
	var wafer_level_control: bool  # 是否开启Wafer级管控
	var rtd_enabled: bool          # 是否开启RTD调度
	var amhs_enabled: bool         # 是否启用AMHS
	
	# 参数配置
	var default_qtime: float       # 默认Qtime(分钟)
	var max_cj_wait_time: float    # CJ最大等待时间
	
	# 初始化
	func _init():
		pass
	
	# 从文件加载配置
	# filepath: 配置文件路径
	func load_from_file(filepath: String):
		pass
	
	# 保存配置到文件
	# filepath: 配置文件路径
	func save_to_file(filepath: String):
		pass
	
	# 设置Wafer级管控开关
	# enabled: 是否启用
	func set_wafer_level_control(enabled: bool):
		pass
	
	# 设置RTD开关
	# enabled: 是否启用
	func set_rtd_enabled(enabled: bool):
		pass
	
	# 获取配置项
	# key: 配置项名, 返回: 配置值
	func get_config(key: String):
		return null
	
	# 设置配置项
	# key: 配置项名, value: 配置值
	func set_config(key: String, value):
		pass

# ============================================
# 10. 查询/请求类
# ============================================

class LotQuery:
	var lot_id: String             # Lot ID(精确查询)
	var product_id: String         # 产品型号
	var status: LotStatus          # 状态
	var current_location: String   # 当前位置
	var recipe_id: String          # 配方ID
	var priority_range: Vector2    # 优先级范围
	
	# 初始化
	func _init():
		pass
	
	# 设置Lot ID精确查询
	# id: Lot ID
	func by_lot_id(id: String):
		pass
	
	# 设置产品型号查询
	# product: 产品型号
	func by_product(product: String):
		pass
	
	# 设置状态查询
	# s: 状态
	func by_status(s: LotStatus):
		pass
	
	# 设置位置查询
	# location: 位置ID
	func by_location(location: String):
		pass
	
	# 设置配方查询
	# recipe: 配方ID
	func by_recipe(recipe: String):
		pass
	
	# 设置优先级范围
	# min_p: 最小优先级, max_p: 最大优先级
	func by_priority_range(min_p: int, max_p: int):
		pass
	
	# 构建查询条件字典
	# 返回: 查询条件字典
	func build() -> Dictionary:
		return {}

class EquipmentQuery:
	var equipment_id: String       # 设备ID
	var equipment_type: String     # 设备类型
	var status: EquipmentStatus    # 状态
	var area: String               # 区域
	
	# 初始化
	func _init():
		pass
	
	# 设置设备ID
	# id: 设备ID
	func by_id(id: String):
		pass
	
	# 设置设备类型
	# type: 设备类型
	func by_type(type: String):
		pass
	
	# 设置状态
	# s: 状态
	func by_status(s: EquipmentStatus):
		pass
	
	# 设置区域
	# a: 区域
	func by_area(a: String):
		pass
	
	# 构建查询条件
	# 返回: 查询条件字典
	func build() -> Dictionary:
		return {}

class WIPQuery:
	var area: String               # 区域
	var step: String               # 工艺步骤
	var product: String            # 产品型号
	var time_range: Vector2        # 时间范围
	
	# 初始化
	func _init():
		pass
	
	# 设置区域
	# a: 区域
	func by_area(a: String):
		pass
	
	# 设置工艺步骤
	# s: 步骤
	func by_step(s: String):
		pass
	
	# 设置产品
	# p: 产品型号
	func by_product(p: String):
		pass
	
	# 设置时间范围
	# start: 开始时间, end: 结束时间
	func by_time_range(start: float, end: float):
		pass
	
	# 构建查询条件
	# 返回: 查询条件字典
	func build() -> Dictionary:
		return {}