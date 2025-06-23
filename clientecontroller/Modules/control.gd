extends Node2D
class_name WebSocketControlClient

@export var mostrar_mensaje: MostrarMensaje = null

var websocket := WebSocketPeer.new()
@export var host: String = "ws://192.168.238.146:9080"
var registrado := false

var carros_disponibles: Array
signal carros_actualizados(carros: Array[int])

var reconnection_attempts := 0
var reconnect_delay := 1.0  # segundos
var reconnect_timer := 0.0

func _ready():
	_connect_to_server()
	set_process(true) # Ensure _process is active to poll websocket

func _process(delta):
	websocket.poll()
	
	match websocket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			_handle_state_connecting()
		WebSocketPeer.STATE_OPEN:
			_handle_state_open(delta)
		WebSocketPeer.STATE_CLOSING:
			_handle_state_closing()
		WebSocketPeer.STATE_CLOSED:
			_handle_state_closed(delta)

## Intenta conectar el cliente WebSocket al servidor.
func _connect_to_server():
	var err := websocket.connect_to_url(host)
	if err != OK:
		push_error("❌ No se pudo conectar a %s: %s" % [host, err])
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ No se pudo conectar a %s: %s" % [host, err])
	else:
		print("🔄 Intentando conectar a %s..." % host)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("🔄 Intentando conectar a %s..." % host)

## Maneja el estado CONNECTING del WebSocket.
func _handle_state_connecting():
	pass # No hay lógica específica necesaria mientras se está conectando.

## Maneja el estado OPEN del WebSocket.
func _handle_state_open(delta: float):
	_reset_reconnection_timers()
	_register_as_control_if_needed()
	_process_incoming_messages()

## Resetea los contadores y el retardo de reconexión.
func _reset_reconnection_timers():
	reconnection_attempts = 0
	reconnect_delay = 1.0
	reconnect_timer = 0.0

## Envía el mensaje de registro como "control" si aún no se ha hecho.
func _register_as_control_if_needed():
	if not registrado:
		print("📡 Conexión exitosa ")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("📡 Conectado al servidor")
		var register_msg := {
			"type": "register",
			"role": "control"
		}
		websocket.send_text(JSON.stringify(register_msg))
		registrado = true
		print("📡 Registrado como CONTROL")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("📡 Registrado como CONTROL")
		
		_request_available_cars()

## Solicita la lista de carros disponibles al servidor.
func _request_available_cars():
	var request := {
		"type": "get_available_cars"
	}
	websocket.send_text(JSON.stringify(request))
	print("📤 Solicitada lista de carros disponibles")
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("📤 Solicitada lista de carros disponibles")

## Procesa todos los paquetes entrantes del WebSocket.
func _process_incoming_messages():
	while websocket.get_available_packet_count() > 0:
		var msg := websocket.get_packet().get_string_from_utf8()
		print("📥 Mensaje recibido del servidor:", msg)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("📥 Mensaje recibido: " + msg)

		var parsed = JSON.parse_string(msg)
		if typeof(parsed) == TYPE_DICTIONARY:
			_process_json_message(parsed)
		else:
			print("⚠️ Mensaje recibido no es JSON válido: %s" % msg)

## Maneja el estado CLOSING del WebSocket.
func _handle_state_closing():
	print("🔌 Cerrando conexión...")
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("🔌 Cerrando conexión...")

## Maneja el estado CLOSED del WebSocket y la lógica de reconexión.
func _handle_state_closed(delta: float):
	registrado = false
	reconnect_timer += delta
	
	if reconnect_timer >= reconnect_delay:
		reconnection_attempts += 1
		reconnect_delay = min(10.0, reconnect_delay * 2) # aumenta exponencialmente hasta 10s
		reconnect_timer = 0.0

		print("🔁 Reintentando conexión (intento #%d)..." % reconnection_attempts)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("🔁 Reintentando conexión (intento #%d)..." % reconnection_attempts)
		
		_connect_to_server()

## Envía un comando (diccionario JSON) al servidor.
## @param data: El diccionario de datos a enviar.
func send_command(data: Dictionary):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.send_text(JSON.stringify(data))
		print("📤 Comando enviado:", data)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("📤 Comando enviado: " + JSON.stringify(data))
	else:
		print("❌ No se pudo enviar el comando: WebSocket no está abierto.")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ WebSocket no abierto para enviar comando.")



func _process_json_message(data: Dictionary):
	if not data.has("type"):
		print("⚠️ Mensaje JSON sin 'type':", data)
		return

	match data["type"]:
		"available_cars":
			var cars = []
			for car in data["carros"]:
				cars.append(car)
			emit_signal("carros_actualizados",cars)
		"control_response":
			if data.has("status") and data["status"] == "ok":
				Global.autorizado = true
				if data.has("car_id"):
					Global.carro_controlado_id = int(data["car_id"])
				print("✅ Autorizado para controlar el carro:", Global.carro_controlado_id)
			else:
				Global.autorizado = false
				Global.carro_controlado_id = -1
				var mensaje = data.get("message", "No autorizado")
				print("❌ No autorizado:", mensaje)

		"authorized":
			if data.has("time_assigned"):
				Global.con_tiempo = true
				var tiempo_asignado = data["time_assigned"]
				print("⏳ Tiempo asignado:", tiempo_asignado, "segundos")
			else:
				Global.con_tiempo = false

		"deauthorized":
			if data.get("reason", "") == "time_expired":
				Global.con_tiempo = false
			Global.autorizado = false
			Global.carro_controlado_id = -1
			print("⏱️ Se desautorizó el control por:", data.get("reason", "desconocido"))

		_:
			print("ℹ️ Mensaje JSON de tipo desconocido:", data["type"])


## Maneja el mensaje "available_cars" recibido del servidor.
## @param data: El diccionario que contiene la clave "carros".
func _handle_available_cars_message(data: Dictionary):
	if data.has("carros") and typeof(data["carros"]) == TYPE_ARRAY:
		carros_disponibles = data["carros"]
		print("🚗 Carros disponibles:", carros_disponibles)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("🚗 Carros disponibles actualizados")
		emit_signal("carros_actualizados", carros_disponibles)
	else:
		print("⚠️ Mensaje 'available_cars' mal formado:", data)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⚠️ Mensaje 'available_cars' mal formado.")

## Envía una solicitud al servidor para tomar el control de un carro específico.
## @param car_id: El ID del carro que se desea controlar.
func request_car_control(car_id: int):
	var request_msg := {
		"type": "request_control",
		"car_id": car_id
	}
	send_command(request_msg)
	print("📤 Solicitando control del carro %d" % car_id)
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("📤 Solicitando control del carro %d" % car_id)
