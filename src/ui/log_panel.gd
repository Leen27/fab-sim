class_name LogPanel
extends PanelContainer

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var log_container: VBoxContainer = $ScrollContainer/VBoxContainer

# 配置
var max_logs: int = 1000  # 最大保留日志条数
var auto_scroll: bool = true  # 是否自动滚动到底部

# 颜色配置
var colors = {
	"INFO": Color.WHITE,
	"DEBUG": Color.GRAY,
	"WARNING": Color.YELLOW,
	"ERROR": Color.RED,
	"SUCCESS": Color.GREEN,
	"EVENT": Color.CYAN,
	"MES": Color.ORANGE,
	"EAP": Color.PURPLE
}

func _ready():
	# 确保滚动容器可以自动滚动
	scroll_container.follow_focus = true

# 添加普通日志
func log_info(message: String):
	_add_log(message, "INFO")

func log_debug(message: String):
	_add_log(message, "DEBUG")

func log_warning(message: String):
	_add_log(message, "WARNING")

func log_error(message: String):
	_add_log(message, "ERROR")

func log_success(message: String):
	_add_log(message, "SUCCESS")

# 添加事件日志
func log_event(event_type: String, data: Dictionary):
	var message = "[%s] %s" % [event_type, _dict_to_string(data)]
	_add_log(message, "EVENT")

# 添加 MES 通信日志
func log_mes(direction: String, endpoint: String, data: Variant = null):
	var arrow = "→" if direction == "OUT" else "←"
	var message = "[MES] %s %s" % [arrow, endpoint]
	if data != null:
		message += " | %s" % _data_to_string(data)
	_add_log(message, "MES")

# 添加 EAP 日志
func log_eap(stream_function: String, equipment_id: String, data: Dictionary = {}):
	var message = "[EAP:%s] EQ:%s" % [stream_function, equipment_id]
	if not data.is_empty():
		message += " | %s" % _dict_to_string(data)
	_add_log(message, "EAP")

# 核心添加日志方法
func _add_log(message: String, level: String = "INFO"):
	var timestamp = _get_timestamp()
	var color = colors.get(level, Color.WHITE)
	
	# 创建日志标签
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true  # Godot 4 特性：自动适应内容高度
	label.scroll_active = false  # 禁用内部滚动，让 ScrollContainer 处理
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 设置 BBCode 格式
	var bbcode = "[color=#%s][b]%s[/b] [%s][/color] %s" % [
		color.to_html(),
		timestamp,
		level,
		message
	]
	label.text = bbcode
	
	# 设置最小宽度，确保文本换行正确
	label.custom_minimum_size.x = log_container.size.x - 20
	
	# 添加到容器
	log_container.add_child(label)
	
	# 限制日志数量
	if log_container.get_child_count() > max_logs:
		var oldest = log_container.get_child(0)
		log_container.remove_child(oldest)
		oldest.queue_free()
	
	# 自动滚动到底部
	if auto_scroll:
		_scroll_to_bottom()

# 滚动到底部
func _scroll_to_bottom():
	# 在下一帧滚动，确保布局更新完成
	await get_tree().process_frame
	var scrollbar = scroll_container.get_v_scroll_bar()
	if scrollbar:
		scroll_container.scroll_vertical = scrollbar.max_value

# 清空日志
func clear_logs():
	for child in log_container.get_children():
		log_container.remove_child(child)
		child.queue_free()

# 获取时间戳
func _get_timestamp() -> String:
	var time = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

# 字典转字符串
func _dict_to_string(data: Dictionary) -> String:
	var parts = []
	for key in data.keys():
		var value = data[key]
		if value is String:
			parts.append("%s=%s" % [key, value])
		else:
			parts.append("%s=%s" % [key, str(value)])
	return ", ".join(parts)

# 数据转字符串
func _data_to_string(data: Variant) -> String:
	if data is Dictionary:
		return _dict_to_string(data)
	elif data is String:
		return data
	else:
		return str(data)

# 设置是否自动滚动
func set_auto_scroll(enabled: bool):
	auto_scroll = enabled

# 滚动到顶部
func scroll_to_top():
	scroll_container.scroll_vertical = 0

# 滚动到底部（手动）
func scroll_to_bottom():
	_scroll_to_bottom()

# 保存日志到文件
func save_to_file(filepath: String):
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		for child in log_container.get_children():
			if child is RichTextLabel:
				# 移除 BBCode 标签保存纯文本
				var text = child.text
				text = text.replace("[color=#" + colors["INFO"].to_html() + "]", "")
				text = text.replace("[/color]", "")
				text = text.replace("[b]", "")
				text = text.replace("[/b]", "")
				file.store_line(text)
		file.close()
		log_success("日志已保存到: " + filepath)
