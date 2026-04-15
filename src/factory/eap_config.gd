class_name EapConfig
extends RefCounted

# 状态变量定义
class StatusVariable:
	var svid: int
	var sv_name: String
	var equipment_type: String  # "ALL" 或具体类型
	var data_type: String       # "U1", "U2", "U4", "I1", "I2", "I4", "A", "Boolean"
	var units: String
	var description: String
	var default_value: Variant

# 数据变量定义
class DataVariable:
	var dvid: int
	var dv_name: String
	var description: String

# 收集事件定义
class CollectionEvent:
	var ceid: int
	var ce_name: String
	var description: String
	var enabled_by_default: bool = false
	var reports: Array = []  # 关联的报告 RPTID 列表

# 报告定义
class Report:
	var rptid: int
	var rpt_name: String
	var svids: Array = []  # 包含的 SVID 列表

# 报警定义
class Alarm:
	var alid: int
	var alarm_name: String
	var alarm_text: String
	var alarm_set_ceid: int
	var alarm_clear_ceid: int

# 配方定义
class Recipe:
	var ppid: String
	var equipment_type: String
	var parameters: Dictionary

# 配置数据
var status_variables: Array = []
var data_variables: Array = []
var collection_events: Array = []
var reports: Array = []
var alarms: Array = []
var recipes: Array = []

func load_from_json(json_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("无法打开 EAP 配置文件: " + json_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("JSON 解析错误: " + json.get_error_message())
		return false
	
	_parse_config(json.data)
	return true

func _parse_config(data: Dictionary):
	# 解析状态变量
	if data.has("status_variables"):
		for sv_data in data.status_variables:
			var sv = StatusVariable.new()
			sv.svid = sv_data.get("svid", 0)
			sv.sv_name = sv_data.get("sv_name", "")
			sv.equipment_type = sv_data.get("equipment_type", "ALL")
			sv.data_type = sv_data.get("data_type", "A")
			sv.units = sv_data.get("units", "")
			sv.description = sv_data.get("description", "")
			sv.default_value = sv_data.get("default_value", null)
			status_variables.append(sv)
	
	# 解析收集事件
	if data.has("collection_events"):
		for ce_data in data.collection_events:
			var ce = CollectionEvent.new()
			ce.ceid = ce_data.get("ceid", 0)
			ce.ce_name = ce_data.get("ce_name", "")
			ce.description = ce_data.get("description", "")
			ce.enabled_by_default = ce_data.get("enabled_by_default", false)
			ce.reports = ce_data.get("reports", [])
			collection_events.append(ce)
	
	# 解析报告
	if data.has("reports"):
		for rpt_data in data.reports:
			var rpt = Report.new()
			rpt.rptid = rpt_data.get("rptid", 0)
			rpt.rpt_name = rpt_data.get("rpt_name", "")
			rpt.svids = rpt_data.get("svids", [])
			reports.append(rpt)
	
	# 解析报警
	if data.has("alarms"):
		for al_data in data.alarms:
			var al = Alarm.new()
			al.alid = al_data.get("alid", 0)
			al.alarm_name = al_data.get("alarm_name", "")
			al.alarm_text = al_data.get("alarm_text", "")
			al.alarm_set_ceid = al_data.get("alarm_set_ceid", 0)
			al.alarm_clear_ceid = al_data.get("alarm_clear_ceid", 0)
			alarms.append(al)

func get_sv_by_id(svid: int) -> StatusVariable:
	for sv in status_variables:
		if sv.svid == svid:
			return sv
	return null

func get_ce_by_id(ceid: int) -> CollectionEvent:
	for ce in collection_events:
		if ce.ceid == ceid:
			return ce
	return null

func get_report_by_id(rptid: int) -> Report:
	for rpt in reports:
		if rpt.rptid == rptid:
			return rpt
	return null

func get_ce_by_name(ce_name: String) -> CollectionEvent:
	for ce in collection_events:
		if ce.ce_name == ce_name:
			return ce
	return null
