extends Control

@onready var websocket: WebSocketControlClient = $Control

func _ready() -> void:
		Global.websocket = websocket
