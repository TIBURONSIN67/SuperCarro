extends Node

var tiempo_restante: float = 0
var autorizados := {} # This might become redundant if you use 'roles[peer_id]["authorized"]'
var joy_id_autorizado := -1 # This might become redundant if you use per-car control
var out:= ""
var peers: Dictionary[int, WebSocketPeer] = {}
var websocket: WebSocketServerNode = null

var roles: Dictionary[int, Dictionary] = {}
# Ejemplo de cómo se vería 'roles' después de algunas conexiones/autorizaciones:
# {
#   1001: { "role": "control", "authorized": true, "controlling_car_id": 2001 },
#   1002: { "role": "control", "authorized": false, "controlling_car_id": -1 },
#   2001: { "role": "carro", "authorized": true, "controlled_by_id": 1001 },
#   2002: { "role": "carro", "authorized": false, "controlled_by_id": -1 }
# }
