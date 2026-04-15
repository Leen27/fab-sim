class_name MesHttpServer
extends Node

signal command_received(equipment_id: String, command: String, parameters: Dictionary)
signal eap_command_received(equipment_id: String, rcmd: String, parameters: Array)
signal dispatch_received(bank_id: String, lot_id: String, target_equipment: String)

# HTTP 服务器
var server: TCPServer
var port: int = 8080
var running: bool = false

# 客户端连接池
var clients: Array = []

# 请求路由
var routes: Dictionary = {}

func _ready():
	_setup_routes()

func _setup_routes():
	# EAP 消息接口
	routes["POST /api/v1/eap/message"] = _handle_eap_message
	routes["POST /api/v1/equipment/{id}/command"] = _handle_equipment_command
	routes["POST /api/v1/bank/{id}/dispatch"] = _handle_bank_dispatch
	
	# 查询接口
	routes["GET /api/v1/equipment"] = _handle_get_equipment_list
	routes["GET /api/v1/equipment/{id}/status"] = _handle_get_equipment_status
	routes["GET /api/v1/banks"] = _handle_get_banks
	routes["GET /api/v1/bank/{id}/status"] = _handle_get_bank_status
	routes["GET /api/v1/events/pending"] = _handle_get_pending_events

func start_server(p_port: int = 8080) -> bool:
	port = p_port
	server = TCPServer.new()
	
	var err = server.listen(port)
	if err != OK:
		push_error("HTTP 服务器启动失败: ", err)
		return false
	
	running = true
	print("✅ MES HTTP 服务器已启动，端口: ", port)
	return true

func stop_server():
	if server:
		server.stop()
		running = false
		print("🛑 MES HTTP 服务器已停止")

func _process(delta):
	if not running or server == null:
		return
	
	# 接受新连接
	if server.is_connection_available():
		var conn = server.take_connection()
		if conn:
			clients.append({"connection": conn, "buffer": ""})
			print("🟢 新客户端连接: ", conn.get_connected_host())
	
	# 处理客户端请求
	_process_clients()

func _process_clients():
	for client in clients:
		var conn: StreamPeerTCP = client.connection
		
		if conn.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue
		
		# 读取数据
		var bytes_available = conn.get_available_bytes()
		if bytes_available > 0:
			var data = conn.get_data(bytes_available)
			if data[0] == OK:
				client.buffer += data[1].get_string_from_utf8()
				
				# 检查是否收到完整 HTTP 请求
				if client.buffer.find("\r\n\r\n") >= 0:
					_handle_http_request(conn, client.buffer)
					client.buffer = ""

func _handle_http_request(conn: StreamPeerTCP, request_text: String):
	# 解析 HTTP 请求
	var lines = request_text.split("\r\n")
	if lines.size() < 1:
		_send_error(conn, 400, "Bad Request")
		return
	
	# 解析请求行
	var request_line = lines[0].split(" ")
	if request_line.size() < 2:
		_send_error(conn, 400, "Bad Request")
		return
	
	var method = request_line[0]
	var path = request_line[1]
	
	# 查找路由
	var handler = _find_route(method, path)
	
	if handler:
		# 解析请求体
		var body = ""
		var body_start = request_text.find("\r\n\r\n")
		if body_start >= 0:
			body = request_text.substr(body_start + 4)
		
		# 调用处理器
		handler.call(conn, path, body)
	else:
		_send_error(conn, 404, "Not Found")

func _find_route(method: String, path: String) -> Callable:
	var full_path = method + " " + path
	
	# 精确匹配
	if routes.has(full_path):
		return routes[full_path]
	
	# 模式匹配（支持 {id} 参数）
	for route in routes.keys():
		if _match_route(route, full_path):
			return routes[route]
	
	return Callable()

func _match_route(route: String, request: String) -> bool:
	var route_parts = route.split(" ")
	var request_parts = request.split(" ")
	
	if route_parts.size() != 2 or request_parts.size() != 2:
		return false
	
	if route_parts[0] != request_parts[0]:  # 方法不匹配
		return false
	
	var route_path = route_parts[1]
	var request_path = request_parts[1]
	
	# 简单通配匹配（实际应该更完善）
	if route_path.contains("{id}"):
		var prefix = route_path.split("{id}")[0]
		return request_path.begins_with(prefix)
	
	return false

# ============ 路由处理器 ============

func _handle_eap_message(conn: StreamPeerTCP, path: String, body: String):
	var json = JSON.new()
	var err = json.parse(body)
	
	if err != OK:
		_send_error(conn, 400, "Invalid JSON")
		return
	
	var data = json.data
	var stream_function = data.get("stream_function", "")
	var equipment_id = data.get("equipment_id", "")
	
	match stream_function:
		"S2F41":  # Host Command
			var rcmd = data.get("rcmd", "")
			var parameters = data.get("parameters", [])
			eap_command_received.emit(equipment_id, rcmd, parameters)
			_send_json(conn, 200, {"hcack": 0, "hcack_name": "OK"})
		
		"S7F3":  # PPID Download
			var ppid = data.get("ppid", "")
			# TODO: 处理配方下载
			_send_json(conn, 200, {"ackc7": 0, "ackc7_name": "OK"})
		
		"S1F3":  # Status Variable Request
			# TODO: 返回状态变量
			_send_json(conn, 200, {"sv_count": 0, "status_variables": []})
		
		_:
			_send_json(conn, 200, {"message": "Received", "sf": stream_function})

func _handle_equipment_command(conn: StreamPeerTCP, path: String, body: String):
	var json = JSON.new()
	var err = json.parse(body)
	
	if err != OK:
		_send_error(conn, 400, "Invalid JSON")
		return
	
	var data = json.data
	var equipment_id = _extract_id_from_path(path)
	var command = data.get("command", "")
	var parameters = data.get("parameters", {})
	
	command_received.emit(equipment_id, command, parameters)
	_send_json(conn, 200, {"status": "ACCEPTED", "command_id": _generate_command_id()})

func _handle_bank_dispatch(conn: StreamPeerTCP, path: String, body: String):
	var json = JSON.new()
	var err = json.parse(body)
	
	if err != OK:
		_send_error(conn, 400, "Invalid JSON")
		return
	
	var data = json.data
	var bank_id = _extract_id_from_path(path)
	var lot_id = data.get("lot_id", "")
	var target_equipment = data.get("target_equipment", "")
	
	dispatch_received.emit(bank_id, lot_id, target_equipment)
	_send_json(conn, 200, {"status": "CONFIRMED", "dispatch_id": _generate_dispatch_id()})

func _handle_get_equipment_list(conn: StreamPeerTCP, path: String, body: String):
	# TODO: 从工厂模型获取设备列表
	_send_json(conn, 200, {"count": 0, "equipment": []})

func _handle_get_equipment_status(conn: StreamPeerTCP, path: String, body: String):
	var equipment_id = _extract_id_from_path(path)
	# TODO: 返回设备状态
	_send_json(conn, 200, {"equipment_id": equipment_id, "status": "IDLE"})

func _handle_get_banks(conn: StreamPeerTCP, path: String, body: String):
	# TODO: 返回 Bank 列表
	_send_json(conn, 200, {"count": 0, "banks": []})

func _handle_get_bank_status(conn: StreamPeerTCP, path: String, body: String):
	var bank_id = _extract_id_from_path(path)
	# TODO: 返回 Bank 状态
	_send_json(conn, 200, {"bank_id": bank_id, "status": "EMPTY"})

func _handle_get_pending_events(conn: StreamPeerTCP, path: String, body: String):
	# TODO: 返回待处理事件
	_send_json(conn, 200, {"events": []})

# ============ 辅助方法 ============

func _send_json(conn: StreamPeerTCP, status_code: int, data: Dictionary):
	var body = JSON.stringify(data)
	var response = "HTTP/1.1 %d OK\r\n" % status_code
	response += "Content-Type: application/json\r\n"
	response += "Content-Length: %d\r\n" % body.length
	response += "\r\n"
	response += body
	
	conn.put_data(response.to_utf8_buffer())
	conn.disconnect_from_host()

func _send_error(conn: StreamPeerTCP, status_code: int, message: String):
	_send_json(conn, status_code, {"error": message, "code": status_code})

func _extract_id_from_path(path: String) -> String:
	# 从路径 /api/v1/equipment/EQ001/status 中提取 EQ001
	var parts = path.split("/")
	if parts.size() >= 4:
		return parts[4]
	return ""

func _generate_command_id() -> String:
	return "CMD%d" % Time.get_unix_time_from_system()

func _generate_dispatch_id() -> String:
	return "DIS%d" % Time.get_unix_time_from_system()
