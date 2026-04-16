extends Control

@onready var log_list: ItemList = $Panel/ItemList

# 配置参数
@export var max_log_count: int = 1000  # 最大保留日志数，防止内存爆炸
@export var auto_scroll: bool = true   # 是否自动滚动到底部

func _ready():
	# ItemList 基础配置
	log_list.allow_reselect = true
	log_list.allow_rmb_select = true
	
	# 可选：固定行高提升性能
	# log_list.fixed_icon_size = Vector2i(0, 24)
	
	# 测试数据
	# for i in range(50):
	# 	add_log("系统初始化中... 步骤 %d" % i, Color.GRAY)
		
	# add_log("✓ 连接成功", Color.GREEN)
	# add_log("✗ 网络超时", Color.RED)
	# add_log("⚠ 内存占用过高", Color.YELLOW)

## 添加日志（核心方法）
func add_log(message: String, color: Color = Color.WHITE, tooltip: String = ""):
	var idx = log_list.add_item(message)
	
	# 设置颜色
	log_list.set_item_custom_fg_color(idx, color)
	
	# 设置提示文本（鼠标悬停显示完整内容）
	if tooltip.is_empty():
		tooltip = message
	log_list.set_item_tooltip(idx, tooltip)
	
	# 性能保护：超出限制时移除旧日志
	if log_list.item_count > max_log_count:
		log_list.remove_item(0)
	
	# 自动滚动到底部（关键）
	if auto_scroll:
		call_deferred("_scroll_to_bottom")

func _scroll_to_bottom():
	# 选中最后一项使其可见（ItemList 专用方法）
	if log_list.item_count > 0:
		log_list.select(log_list.item_count - 1)
		log_list.ensure_current_is_visible()

## 清空日志
func clear_logs():
	log_list.clear()

## 保存日志到文件
func save_logs_to_file(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		for i in range(log_list.item_count):
			file.store_line(log_list.get_item_text(i))
		file.close()
		add_log("日志已保存至: " % path, Color.CYAN)
