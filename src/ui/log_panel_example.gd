# 日志面板使用示例

extends Control

@onready var log_panel: LogPanel = $LogPanel

func _ready():
	# 添加不同类型的日志
	log_panel.log_info("系统启动完成")
	log_panel.log_debug("调试信息：初始化参数")
	log_panel.log_warning("警告：Bank 容量接近上限")
	log_panel.log_error("错误：设备连接超时")
	log_panel.log_success("操作成功：配方已下载")
	
	# 添加事件日志
	log_panel.log_event("BANK_LOT_ARRIVE", {
		"bank_id": "BK_D1_IN",
		"lot_id": "LOT2024001",
		"timestamp": "08:30:00"
	})
	
	# 添加 MES 通信日志
	log_panel.log_mes("OUT", "/api/v1/equipment/status", {"status": "RUNNING"})
	log_panel.log_mes("IN", "/api/v1/equipment/command", {"rcmd": "START"})
	
	# 添加 EAP 日志
	log_panel.log_eap("S6F11", "EQ001", {"ceid": 1012, "lot_id": "LOT001"})

# 在仿真引擎中使用
func on_equipment_status_changed(equipment_id: String, status: String):
	log_panel.log_info("设备 %s 状态变为 %s" % [equipment_id, status])

func on_bank_lot_arrived(bank_id: String, lot_id: String):
	log_panel.log_event("BANK_LOT_ARRIVE", {
		"bank_id": bank_id,
		"lot_id": lot_id
	})

func on_mes_message_sent(endpoint: String, data: Dictionary):
	log_panel.log_mes("OUT", endpoint, data)

func on_mes_message_received(endpoint: String, data: Dictionary):
	log_panel.log_mes("IN", endpoint, data)
