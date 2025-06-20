extends Node

var tiempo_restante: float = 0 
var autorizados := {}
var joy_id_autorizado := -1  
var out:= ""
var peers:Dictionary[int, WebSocketPeer] = {}
var websocket:WebSocketControlClient
var roles: Dictionary[int, String] = {}  
