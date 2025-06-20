extends Node

var tiempo_restante: float = 0 
var autorizados := {}
var joy_id_autorizado := -1  
var out:= ""
var peers:Dictionary[int, WebSocketPeer] = {}
var websocket:WebSocketServerNode = null
var roles: Dictionary[int, Dictionary] = {}  
