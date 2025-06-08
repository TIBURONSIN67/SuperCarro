extends Node

var tiempo_restante: float = 0 
var autorizados := {}
var joy_id_autorizado := -1  
@onready var websocket := WebSocketClient.new()

func _ready() -> void:
	add_child(websocket)
	websocket.connect_to_server("ws://192.168.43.20")
	
