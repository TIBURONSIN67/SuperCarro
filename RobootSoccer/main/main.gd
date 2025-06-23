extends CanvasLayer
class_name AuthLayer

@export var tiempo_minutos: float = 2.0
@export var websocket: WebSocketServerNode

func _ready():
	var my_ip = get_my_ip()
	print("🌐 Mi IP es: ", my_ip)
	Global.websocket = websocket

func get_my_ip() -> String:
	var ips = IP.get_local_addresses()
	for ip in ips:
		if ip.begins_with("192.") or ip.begins_with("10."):
			return ip
	return "127.0.0.1"
