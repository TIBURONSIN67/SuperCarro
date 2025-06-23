extends Control

@export var websocket: WebSocketControlClient = null

func _ready() -> void:
		Global.websocket = websocket
