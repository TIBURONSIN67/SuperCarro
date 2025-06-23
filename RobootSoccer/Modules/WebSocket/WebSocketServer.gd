# Archivo: WebSocketServerNode.gd
extends Node
class_name WebSocketServerNode

## Referencia a un nodo para mostrar mensajes en la interfaz de usuario.
## Debe ser un nodo que implemente un método 'mostrar_mensaje(mensaje: String, duracion: float = 0.0)'.
@export var mostrar_mensaje: MostrarMensaje = null

## Puerto en el que el servidor TCP/WebSocket escuchará las conexiones.
@export var port: int = 9080

## Instancia del servidor TCP que acepta las conexiones entrantes.
var server := TCPServer.new()

## Diccionario para almacenar el último tiempo en que se recibió un 'pong' de cada peer.
## Se usa para detectar desconexiones por inactividad.
var last_pong_time := {}

## Intervalo en segundos para enviar mensajes 'ping' a los clientes conectados.
@export var ping_interval := 5.0

## Tiempo en segundos que se espera por una respuesta 'pong' antes de considerar un cliente desconectado.
@export var ping_timeout := 10.0

## Nodo Timer para enviar pings periódicamente. Configurado en el editor o en _ready().
@onready var ping_timer: Timer = $PingTimer

## Nodo Timer para verificar timeouts de pings. Configurado en el editor o en _ready().
@onready var timeout_timer: Timer = $TimeoutTimer

## Señal cuando piden controlar un carro
signal request_control(peer_id:int, car_id)

## Se ejecuta una vez cuando el nodo y sus hijos están listos.
func _ready():
	# Conecta las señales de timeout de los temporizadores a sus respectivas funciones.
	ping_timer.timeout.connect(_on_PingTimer_timeout)
	timeout_timer.timeout.connect(_on_TimeoutTimer_timeout)
	
	# Intenta iniciar el servidor TCP en el puerto especificado.
	var err = server.listen(port)
	if err != OK:
		# Si falla al iniciar, muestra un error y deshabilita el procesamiento del script.
		push_error("❌ No se pudo iniciar el servidor TCP: %s" % err)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ No se pudo iniciar servidor TCP: %s" % err)
		set_process(false) # Detiene el _process si el servidor no inicia.
		return
	
	# Si el servidor inicia correctamente, imprime un mensaje de éxito.
	print("🟢 TCP escuchando en el puerto %d" % port)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("🟢 TCP escuchando en el puerto %d" % port)
	set_process(true) # Habilita el _process.

## Se ejecuta cada fotograma. Maneja la aceptación de nuevas conexiones y el procesamiento de mensajes de los peers existentes.
func _process(_delta):
	# 1. Aceptar nuevas conexiones TCP y convertirlas a WebSocket.
	_handle_new_connections()

	# 2. Procesar mensajes de los peers (clientes) WebSocket existentes.
	_poll_and_process_peers()

## Maneja la aceptación de nuevas conexiones TCP y las convierte en WebSocket.
func _handle_new_connections():
	if server.is_connection_available():
		var stream = server.take_connection()
		_accept_ws(stream)

## Itera sobre los peers conectados, los sondea y procesa sus mensajes.
func _poll_and_process_peers():
	# Recorre una copia de las claves para evitar errores si los peers se eliminan durante la iteración.
	for peer_id in Global.peers.keys().duplicate():
		if not Global.peers.has(peer_id): # El peer podría haberse desconectado durante el bucle.
			continue

		var peer_ws: WebSocketPeer = Global.peers[peer_id]
		peer_ws.poll() # Actualiza el estado del peer y procesa los paquetes.

		if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_process_peer_messages(peer_id, peer_ws)
		elif peer_ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			_handle_peer_disconnection(peer_id, peer_ws)


## Maneja la recepción de un mensaje "pong".
## @param peer_id: El ID del peer que envió el pong.
func _handle_pong_message(peer_id: int):
	last_pong_time[peer_id] = Time.get_unix_time_from_system()

## Maneja un mensaje de tipo "register".
## @param peer_id: El ID del peer que se está registrando.
## @param data: Los datos del mensaje JSON.
func _handle_register_message(peer_id: int, data: Dictionary):
	if data.has("role"):
		match data["role"]:
			"control":
				Global.roles[peer_id] = {
					"role": "control",
					"authorized": false,
					"controlling_car_id": -1
				}
				print("📝 Peer %d registrado como control" % peer_id)
				_desautorizar_cliente(peer_id)
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("📝 Peer %d registrado como control" % peer_id)

			"carro":
				Global.roles[peer_id] = {
					"role": "carro",
					"controlled_by_id": -1
				}
				print("📝 Peer %d registrado como carro" % peer_id)
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("📝 Peer %d registrado como carro" % peer_id)
				
				_check_and_start_ping_timers()
				enviar_lista_carros() # Notifica a los controles sobre el nuevo carro

			_:
				print("⚠️ Peer %d tiene un rol desconocido: %s" % [peer_id, data["role"]])
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("⚠️ Rol desconocido: %s" % data["role"])

## Comprueba si hay carros conectados y, si es el primero, inicia los temporizadores de ping/timeout.
func _check_and_start_ping_timers():
	var hay_carros_conectados := false
	for id in Global.roles.keys():
		if Global.roles[id]["role"] == "carro":
			hay_carros_conectados = true
			break
	
	if hay_carros_conectados and not ping_timer.is_stopped(): # Si ya hay carros y los timers ya están corriendo
		return # No es el primer carro o los timers ya están activos, no hacer nada.

	if hay_carros_conectados and ping_timer.is_stopped(): # Si es el primer carro, o los timers se detuvieron y ahora hay uno
		ping_timer.start(ping_interval)
		timeout_timer.start(ping_timeout)
		print("▶️ Primer carro conectado / Carro reconnectado: timers iniciados")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("▶️ Primer carro conectado / Carro reconnectado: timers iniciados")
	elif not hay_carros_conectados and not ping_timer.is_stopped(): # Si no quedan carros pero los timers siguen, detenerlos
		ping_timer.stop()
		timeout_timer.stop()
		print("⏸ Sin carros conectados: timers detenidos")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⏸ Sin carros conectados: timers detenidos")

## Maneja una solicitud de tipo "get_available_cars".
## @param peer_id: El ID del peer que solicitó la lista.
## @param peer_ws: La instancia de WebSocketPeer.
func _handle_get_available_cars_message(peer_id: int, peer_ws: WebSocketPeer):
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

## Maneja un mensaje que no es de tipo "pong", "register" o "get_available_cars".
## Actualmente, reenvía comandos de control o simplemente hace un eco del mensaje.
## @param peer_id: El ID del peer que envió el mensaje.
## @param peer_ws: La instancia de WebSocketPeer.
## @param data: Los datos del mensaje JSON (puede ser un diccionario vacío si no era JSON válido).
## @param original_msg: El mensaje original en formato String.
func _handle_generic_message(peer_id: int, peer_ws: WebSocketPeer, data: Dictionary, original_msg: String):
	if Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "control":
		# Comandos de control (movimiento del carro).
		if data.has("left") and data.has("right"):
			if data.has("target"):
				var target_id = int(data["target"])
				send_json_to_role("carro", data, peer_id, target_id)
				print("🎯 Reenviado desde control %d al carro %d: %s" % [peer_id, target_id, JSON.stringify(data)])
			else:
				print("⚠️ Control %d envió comando sin target" % peer_id)
			return
	
	# Si no fue un comando de control específico, simplemente reenvía el mensaje original (eco).
	peer_ws.send_text(original_msg)

## Maneja la desconexión de un peer.
## @param peer_id: El ID del peer desconectado.
## @param peer_ws: La instancia de WebSocketPeer (que ya está en estado CLOSED).
func _handle_peer_disconnection(peer_id: int, peer_ws: WebSocketPeer):
	print("🔌 Peer %d desconectado" % peer_id)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("🔌 Peer %d desconectado" % peer_id)
	
	peer_ws.close() # Asegura que la conexión está cerrada.
	Global.peers.erase(peer_id)
	
	# Solo elimina de Global.roles y last_pong_time si el peer existía allí.
	if Global.roles.has(peer_id):
		var disconnected_role = Global.roles[peer_id]["role"]
		Global.roles.erase(peer_id)
		last_pong_time.erase(peer_id)

		# Si el peer desconectado era un carro, verifica y actualiza el estado de los temporizadores.
		if disconnected_role == "carro":
			_check_and_start_ping_timers() # Esto detendrá los timers si no quedan carros.
		
		enviar_lista_carros() # Notifica a los controles sobre la desconexión.


## Función llamada cuando el PingTimer se agota. Envía pings a todos los carros conectados.
func _on_PingTimer_timeout():
	print("⏰ PingTimer triggered")
	for peer_id in Global.peers.keys():
		if Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "carro":
			var peer_ws = Global.peers[peer_id]
			if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
				peer_ws.send_text("ping")
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("📤 Ping enviado a Carro %d" % peer_id)

## Función llamada cuando el TimeoutTimer se agota. Desconecta los carros que no respondieron al ping.
func _on_TimeoutTimer_timeout():
	print("⏰ TimeoutTimer triggered")
	var now = Time.get_unix_time_from_system()
	var to_remove := [] # Lista de peers a desconectar.

	for peer_id in Global.peers.keys():
		if Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "carro":
			if now - last_pong_time.get(peer_id, 0) > ping_timeout:
				to_remove.append(peer_id)

	for peer_id in to_remove:
		print("❌ Carro %d desconectado por timeout (no respondió pong)" % peer_id)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ Carro %d desconectado por timeout" % peer_id)
		
		# Llama a la función de manejo de desconexión para limpiar el peer.
		_handle_peer_disconnection(peer_id, Global.peers.get(peer_id)) # Pasar el peer_ws si aún existe

	# Después de procesar las desconexiones, verifica si aún quedan carros y detiene/inicia los timers.
	_check_and_start_ping_timers()


## Acepta una conexión TCP entrante y la convierte en una conexión WebSocket.
## @param stream: El StreamPeerTCP de la conexión entrante.

var next_peer_id := 0

func _accept_ws(stream: StreamPeerTCP):
	var new_ws := WebSocketPeer.new()
	var err := new_ws.accept_stream(stream) # Intenta el handshake de WebSocket.
	if err != OK:
		push_warning("❗ Falló handshake WebSocket: %s" % err)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❗ Falló handshake WebSocket: %s" % err)
		return
	
	var peer_id := next_peer_id
	next_peer_id += 1
	Global.peers[peer_id] = new_ws
	last_pong_time[peer_id] = Time.get_unix_time_from_system() # Inicializa el tiempo del último pong.
	
	print("✅ Peer conectado: %d" % peer_id)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("✅ Peer conectado: %d" % peer_id)


## Envía una lista actualizada de los carros conectados a todos los clientes con rol "control".
func enviar_lista_carros():
	var carros_disponibles_ids := []
	for id in Global.roles.keys():
		if RoleUtils.is_car(id):
			if not RoleUtils.is_being_controlled(id):
				carros_disponibles_ids.append(str(id)) # Convertir ID a string para JSON.
			
	var response := {
		"type": "available_cars",
		"carros": carros_disponibles_ids
	}
	var json_response_str := JSON.stringify(response)

	for id in Global.roles.keys():
		if Global.roles[id]["role"] == "control":
			if Global.peers.has(id):
				var peer_ws = Global.peers[id]
				if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
					peer_ws.send_text(json_response_str)
					print("🔄 Lista de carros enviada al control %d: %s" % [id, json_response_str])
					if mostrar_mensaje:
						mostrar_mensaje.mostrar_mensaje("🔄 Lista de carros enviada al control %d" % id)


func _process_peer_messages(peer_id: int, peer_ws: WebSocketPeer):
	while peer_ws.get_available_packet_count() > 0:
		var pkt = peer_ws.get_packet()
		var msg = pkt.get_string_from_utf8()
		print("📥 Recibido de Peer %d: %s" % [peer_id, msg])

		if msg == "pong":
			_handle_pong_message(peer_id)
			continue

		var data = JSON.parse_string(msg)
		if typeof(data) != TYPE_DICTIONARY:
			print("⚠️ Mensaje no válido (no es JSON): %s" % msg)
			continue

		if data.has("type"):
			match data["type"]:
				"direction":
					_handle_direction_message(peer_id, data)
				"register":
					_handle_register_message(peer_id, data)
				"get_available_cars":
					_handle_get_available_cars_message(peer_id, peer_ws)
				"request_control":
					if not data.has("car_id"):
						print("⚠️ Solicitud de control de %d mal formada (falta 'car_id' o tipo incorrecto)." % peer_id)
						send_json_to_peer(peer_id, {"type": "control_response", "status": "error", "message": "Solicitud de control mal formada."})
						return
						
					var car_id:int = data["car_id"]
					emit_signal("request_control",peer_id,car_id)
				_:
					_handle_generic_message(peer_id, peer_ws, data, msg)
		else:
			_handle_generic_message(peer_id, peer_ws, data, msg)


## Maneja un mensaje de dirección recibido desde un cliente (peer_id).
## @param peer_id ID del cliente que envía el comando.
## @param data Diccionario con las claves: "target", "left", "right"
func _handle_direction_message(peer_id: int, data: Dictionary) -> void:
	# 🔎 Validación de campos básicos
	if not data.has("target") or not data.has("left") or not data.has("right"):
		print("⚠️ _handle_direction_message: Datos incompletos del cliente %d: %s" % [peer_id, str(data)])
		return

	var target_id: int = int(data["target"])
	var left_dir: float = data["left"]
	var right_dir: float = data["right"]

	# 🔐 Verificar que el peer sea un control válido
	if not RoleUtils.is_control(peer_id):
		print("❌ _handle_direction_message: El peer %d no es un control válido o no está registrado." % peer_id)
		return

	# 🔐 Verificar que el target sea un carro válido
	if not RoleUtils.is_car(target_id):
		print("❌ _handle_direction_message: Target %d no es un carro válido." % target_id)
		return

	# 🔒 Verificar que el control esté autorizado
	if not RoleUtils.is_authorized(peer_id):
		print("⛔ _handle_direction_message: Peer %d no tiene tiempo o no está autorizado." % peer_id)
		send_json_to_peer(peer_id, {
			"type": "movement_response",
			"status": "error",
			"message": "No tienes autorización para enviar movimientos."
		})
		return

	# 🔒 Verificar que el peer esté autorizado para ese carro específico
	if not RoleUtils.controls_car(peer_id,target_id):
		print("🚫 _handle_direction_message: Peer %d no tiene permiso para controlar el carro %d." % [peer_id, target_id])
		send_json_to_peer(peer_id, {
			"type": "movement_response",
			"status": "error",
			"message": "No estás autorizado para controlar este carro."
		})
		return

	# 🧾 Construir y enviar el comando de movimiento
	var movement_data := {
		"type": "motor_command",
		"left": left_dir,
		"right": right_dir
	}

	send_json_to_peer(target_id, movement_data)
	print("✅ Movimiento enviado desde peer %d a carro %d -> L: %.2f | R: %.2f" % [peer_id, target_id, left_dir, right_dir])

## Envía un mensaje JSON a un peer específico.
## @param peer_id: El ID del peer al que se enviará el mensaje.
## @param data: El diccionario de datos a enviar, que se convertirá a JSON.
func send_json_to_peer(peer_id: int, data: Dictionary):
	if Global.peers.has(peer_id):
		var peer_ws = Global.peers[peer_id]
		if peer_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			var json_str = JSON.stringify(data)
			peer_ws.send_text(json_str)
			print("📤 Enviado a Peer %d: %s" % [peer_id, json_str])
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("📤 Enviado a Peer %d: %s" % [peer_id, json_str])
		else:
			print("❌ No se pudo enviar mensaje a Peer %d: no está en estado OPEN." % peer_id)
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("❌ Peer %d no está listo para recibir." % peer_id)
	else:
		print("❌ No se pudo enviar mensaje a Peer %d: Peer no encontrado (desconectado?)." % peer_id)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ Peer %d no encontrado." % peer_id)

func send_json_to_role(role: String, data: Dictionary, control_id: int, target_peer_id: int):
	var data_to_send = data.duplicate()
	if data_to_send.has("target"):
		data_to_send.erase("target")

	# 2. Validar la existencia y estado del peer objetivo.
	if Global.roles.has(target_peer_id) and Global.roles[target_peer_id]["role"] == role:
		if Global.peers.has(target_peer_id):
			var target_ws = Global.peers[target_peer_id]
			if target_ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
				var json_str_to_car = JSON.stringify(data_to_send)
				target_ws.send_text(json_str_to_car)
				print("📤 Enviado a cliente %d (rol: %s): %s" % [target_peer_id, role, json_str_to_car])
			else:
				print("❌ Peer %d (rol: %s) no está en estado OPEN." % [target_peer_id, role])
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("❌ Carro %d no está listo." % target_peer_id)
				send_json_to_peer(control_id, {"type": "command_response", "status": "error", "message": "Carro no disponible."})
		else:
			print("❌ Peer %d (rol: %s) no encontrado en Global.peers (ya desconectado?)." % [target_peer_id, role])
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("❌ Carro %d no conectado." % target_peer_id)
			send_json_to_peer(control_id, {"type": "command_response", "status": "error", "message": "Carro no encontrado."})
	else:
		print("❌ Peer %d no tiene el rol '%s' o no existe en Global.roles." % [target_peer_id, role])
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ Carro %d no registrado/rol incorrecto." % target_peer_id)
		send_json_to_peer(control_id, {"type": "command_response", "status": "error", "message": "Carro inválido o rol incorrecto."})

## Autoriza a un cliente "control" a controlar un carro específico.

func _autorizar_cliente(control_peer_id: int, car_id: int):
	
	if RoleUtils.exists(control_peer_id) and RoleUtils.exists(car_id):

		if not (RoleUtils.is_car(car_id)):
			print("❌ _autorizar_cliente: Carro %d no es rol 'carro' al intentar autorizar control %d." % [car_id, control_peer_id])
			Global.roles[control_peer_id]["controlling_car_id"] = -1
			return

		# Ahora sí: ya sabemos que el carro existe y es válido.
		#verificamos si el carro esta libre o esta siendo controlado ya 
		if RoleUtils.is_being_controlled(car_id):
			print("❌ _autorizar_cliente: Carro %d ya está siendo controlado por %d. No se puede autorizar al control %d." % [car_id, Global.roles[car_id]["controlled_by_id"], control_peer_id])
			# Enviar respuesta al cliente indicando que el carro ya está en uso
			send_json_to_peer(control_peer_id, {
				"type": "control_response",
				"status": "error",
				"message": "El carro ya está siendo controlado por otro usuario."
			})
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("❌ Carro %d ya controlado." % car_id)
			return

		# Autorización válida
		if not RoleUtils.is_authorized(control_peer_id):
			print("⏳ El peer %d está sin tiempo o no está autorizado." % control_peer_id)
			send_json_to_peer(control_peer_id, {
				"type": "control_response",
				"status": "error",
				"message": "No tienes tiempo restante para controlar un carro."
			})
			return

		Global.roles[car_id]["controlled_by_id"] = control_peer_id
		Global.roles[control_peer_id]["controlling_car_id"] = car_id
		
		# Enviar confirmación directa al cliente autorizado
		send_json_to_peer(control_peer_id, {
			"type": "control_response",
			"status": "ok",
			"message": "Autorizado para controlar el carro.",
			"car_id": car_id,
			"authorized": true
		})
		print("👍 Cliente control %d AUTORIZADO para carro %d. Estado actualizado en Global.roles." % [control_peer_id, car_id])
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("👍 Control %d autorizado para carro %d." % [control_peer_id, car_id])
		enviar_lista_carros()

	else:
		print("⚠️ _autorizar_cliente: No se puede autorizar al cliente %d: no es un rol de control o no existe." % control_peer_id)

## Desautoriza un cliente específico con el rol de 'control', eliminando su autorización y su temporizador.
## Si el control estaba manejando un carro, el carro también se libera de ese control.
## Actualiza la estructura de Global.roles para el control desautorizado y el carro afectado.
## @param peer_id: El ID del cliente (se asume que es un control) a desautorizar.
func _desautorizar_cliente(peer_id: int):
	# Verifica si el ID de peer existe en el diccionario global de roles y si su rol es "control".
	if not RoleUtils.exists(peer_id):
		print("no existe el peer ",peer_id)
	if RoleUtils.is_control(peer_id):
		
		# Obtiene el ID del carro que este control estaba manejando, si lo hay.
		var controlled_car_id = Global.roles[peer_id]["controlling_car_id"]
		
		# Imprime un mensaje en la consola sobre la desautorización del control.
		print("⏱️ Cliente control %d desautorizado." % peer_id)
		# Si hay un nodo para mostrar mensajes en la interfaz de usuario, muestra el mensaje allí.
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⏱️ Cliente control %d desautorizado." % peer_id)
		
		# Prepara y envía un mensaje al cliente control para informarle que ha sido desautorizado.
		var deauth_message := {
			"type": "deauthorized",
			"reason": "time_expired", # La razón de la desautorización (ej. tiempo expirado, revocado por admin).
			"car_id": controlled_car_id # Incluye el ID del carro que dejó de controlar.
		}
		# Marca el rol como autorizado.
		Global.roles[peer_id]["authorized"] = false
		send_json_to_peer(peer_id, deauth_message)
		
		# Si el control estaba controlando un carro válido, actualiza el estado de ese carro
		# y del control
		if controlled_car_id != -1 and RoleUtils.is_car(controlled_car_id):
			var car_message = {
				"left":0,
				"right":0
			}
			send_json_to_peer(controlled_car_id,car_message)
			Global.roles[controlled_car_id]["controlled_by_id"] = -1
			Global.roles[peer_id]["controlling_car_id"] = -1
			
		# Notifica a todos los clientes "control" sobre la lista actualizada de carros,
		# ya que la disponibilidad podría haber cambiado si un carro fue liberado.
		enviar_lista_carros()
	elif Global.roles.has(peer_id) and Global.roles[peer_id]["role"] == "carro":
		# Si el ID de peer se encuentra, pero es un carro, se ignora la desautorización y se imprime un mensaje.
		print("ℹ️ Intento de desautorizar cliente %d, pero es un 'carro'. Esta función solo desautoriza 'controles'." % peer_id)
	else:
		# Si el ID de peer no se encuentra en los roles globales, imprime una advertencia.
		print("⚠️ Intento de desautorizar cliente %d que no existe en Global.roles." % peer_id)
