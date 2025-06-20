extends Node
class_name WebSocketServerNode

@export var mostrar_mensaje: MostrarMensaje = null

@export var port: int = 9080
var server := TCPServer.new()

var last_pong_time := {}
@export var ping_interval := 5.0
@export var ping_timeout := 10.0

@onready var ping_timer: Timer = $PingTimer
@onready var timeout_timer: Timer = $TimeoutTimer

func _ready():
	ping_timer.timeout.connect(_on_PingTimer_timeout)
	timeout_timer.timeout.connect(_on_TimeoutTimer_timeout)
	
	var err = server.listen(port)
	if err != OK:
		push_error("❌ No se pudo iniciar el servidor TCP: %s" % err)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ No se pudo iniciar servidor TCP: %s" % err)
		set_process(false)
		return
	print("🟢 TCP escuchando en el puerto %d" % port)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("🟢 TCP escuchando en el puerto %d" % port)
	set_process(true)

func _process(delta):
	if server.is_connection_available():
		var stream = server.take_connection()
		_accept_ws(stream)

	for peer_id in Global.peers.keys():
		var peer_ws: WebSocketPeer = Global.peers[peer_id]
		peer_ws.poll()

		if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			while peer_ws.get_available_packet_count() > 0:
				var pkt = peer_ws.get_packet()
				var msg = pkt.get_string_from_utf8()
				print("📥 Recibido de Peer %d: %s" % [peer_id, msg])

				if msg == "pong":
					last_pong_time[peer_id] = Time.get_unix_time_from_system()
					print("📡 Pong recibido de Peer %d" % peer_id)
					continue

				var data = JSON.parse_string(msg)
				if typeof(data) != TYPE_DICTIONARY:
					print("⚠️ Mensaje no válido (no es JSON): %s" % msg)
					continue

				if data.has("type") and data["type"] == "register" and data.has("role"):
					Global.roles[peer_id] = {
						"role": data["role"],
						"authorized": false
					}
					print("📝 Peer %d registrado como %s" % [peer_id, data["role"]])
					if mostrar_mensaje:
						mostrar_mensaje.mostrar_mensaje("📝 Peer %d registrado como %s" % [peer_id, data["role"]])

					if data["role"] == "carro":
						var hay_otros_carros := false
						for id in Global.roles.keys():
							if id != peer_id and Global.roles[id]["role"] == "carro":
								hay_otros_carros = true
								break
						if not hay_otros_carros:
							ping_timer.start(ping_interval)
							timeout_timer.start(ping_timeout)
							print("▶️ Primer carro conectado: timers iniciados")
							if mostrar_mensaje:
								mostrar_mensaje.mostrar_mensaje("▶️ Primer carro conectado: timers iniciados")
							enviar_lista_carros()
					continue

				if data.has("type") and data["type"] == "get_available_cars":
					if Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "control":
						var carros_disponibles := []
						for id in Global.roles.keys():
							if Global.roles[id]["role"] == "carro":
								carros_disponibles.append(id)
						var carros_str := []
						for id in carros_disponibles:
							carros_str.append(str(id))
						var response := {
							"type": "available_cars",
							"carros": carros_str
						}
						if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
							peer_ws.send_text(JSON.stringify(response))
							print("📤 Enviado (a pedido) lista de carros al control %d: %s" % [peer_id, JSON.stringify(response)])
					continue

				if Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "control":
					if data.has("left") and data.has("right"):
						if data.has("target"):
							var target_id = int(data["target"])
							send_json_to_role("carro", data, peer_id, target_id)
							print("🎯 Reenviado desde control %d al carro %d: %s" % [peer_id, target_id, JSON.stringify(data)])
						else:
							print("⚠️ Control %d envió comando sin target" % peer_id)
						continue

				peer_ws.send_text(msg)

		elif peer_ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			print("🔌 Peer %d desconectado" % peer_id)
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("🔌 Peer %d desconectado" % peer_id)
			peer_ws.close()
			Global.peers.erase(peer_id)
			Global.roles.erase(peer_id)
			last_pong_time.erase(peer_id)

func _on_PingTimer_timeout():
	print("⏰ PingTimer triggered")
	var now = Time.get_unix_time_from_system()
	for peer_id in Global.peers.keys():
		if not Global.roles.has(peer_id): continue
		if Global.roles[peer_id]["role"] != "carro": continue

		var peer_ws = Global.peers[peer_id]
		if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer_ws.send_text("ping")
			print("📤 Ping enviado a Carro %d" % peer_id)
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("📤 Ping enviado a Carro %d" % peer_id)

func _on_TimeoutTimer_timeout():
	print("⏰ TimeoutTimer triggered")
	var now = Time.get_unix_time_from_system()
	var to_remove := []

	for peer_id in Global.peers.keys():
		if not Global.roles.has(peer_id): continue
		if Global.roles[peer_id]["role"] != "carro": continue

		if now - last_pong_time.get(peer_id, 0) > ping_timeout:
			to_remove.append(peer_id)

	for peer_id in to_remove:
		print("❌ Carro %d desconectado por timeout (no respondió pong)" % peer_id)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ Carro %d desconectado por timeout" % peer_id)
		var peer_ws = Global.peers[peer_id]
		peer_ws.close()
		Global.peers.erase(peer_id)
		Global.roles.erase(peer_id)
		last_pong_time.erase(peer_id)
		print("🔌 Carro %d desconectado" % peer_id)

	var quedan_carros := false
	for peer in Global.roles.values():
		if peer["role"] == "carro":
			quedan_carros = true
			break

	if not quedan_carros:
		ping_timer.stop()
		timeout_timer.stop()
		print("⏸ Sin carros conectados: timers detenidos")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⏸ Sin carros conectados: timers detenidos")
		enviar_lista_carros()

func _accept_ws(stream: StreamPeerTCP):
	var new_ws := WebSocketPeer.new()
	var err := new_ws.accept_stream(stream)
	if err != OK:
		push_warning("❗ Falló handshake WebSocket: %s" % err)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❗ Falló handshake WebSocket: %s" % err)
		return
	var peer_id := new_ws.get_instance_id()
	Global.peers[peer_id] = new_ws
	print("✅ Peer conectado: %d" % peer_id)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("✅ Peer conectado: %d" % peer_id)

func send_json_to_role(role: String, data: Dictionary, control_id:int, target_peer_id: int = -1):
	if data.has("left") and data.has("right"):
		data.erase("target")

	var json_str := JSON.stringify(data)

	if target_peer_id != -1:
		if Global.roles.has(target_peer_id):
			if not Global.roles[control_id]["authorized"]:
				print("peer control no autorizado")
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("peer control no autorizado")
				return
			if Global.peers.has(target_peer_id):
				var target_ws = Global.peers[target_peer_id]
				if target_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
					target_ws.send_text(json_str)
					print("📤 Enviado a cliente %d (rol: %s): %s" % [target_peer_id, role, json_str])
		else:
			print("❌ Peer %d no tiene el rol '%s' o no existe" % [target_peer_id, role])
		return

func enviar_lista_carros():
	for id in Global.roles.keys():
		if Global.roles[id]["role"] == "control":
			if Global.peers.has(id):
				var peer_ws = Global.peers[id]
				if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
					var carros_disponibles := []
					for cid in Global.roles.keys():
						if Global.roles[cid]["role"] == "carro":
							carros_disponibles.append(str(cid))
					var response := {
						"type": "available_cars",
						"carros": carros_disponibles
					}
					peer_ws.send_text(JSON.stringify(response))
					print("🔄 Lista de carros enviada al control %d: %s" % [id, JSON.stringify(response)])
					if mostrar_mensaje:
						mostrar_mensaje.mostrar_mensaje("🔄 Lista de carros enviada al control %d" % id)
