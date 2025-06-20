extends Node2D
class_name WebSocketControlClient

@export var mostrar_mensaje: MostrarMensaje = null

var websocket := WebSocketPeer.new()
@export var host: String = "ws://192.168.93.146:9080"
var registrado := false

var carros_disponibles: Array
signal carros_actualizados(carros: Array[int])

func _ready():
	var err := websocket.connect_to_url(host)
	if err != OK:
		push_error("❌ No se pudo conectar a %s: %s" % [host, err])
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("❌ No se pudo conectar a %s: %s" % [host, err])
	else:
		print("🔄 Intentando conectar a %s..." % host)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("🔄 Intentando conectar a %s..." % host)
		set_process(true)

var reconnection_attempts := 0
var reconnect_delay := 1.0  # segundos
var reconnect_timer := 0.0

func _process(delta):
	websocket.poll()

	match websocket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_OPEN:
			# Resetear reconexión al conectarse con éxito
			reconnection_attempts = 0
			reconnect_delay = 1.0
			reconnect_timer = 0.0

			if not registrado:
				print("📡📡 Conexion exitosa ")
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
				# Solicitar lista de carros inmediatamente después del registro
				var request := {
					"type": "get_available_cars"
				}
				websocket.send_text(JSON.stringify(request))
				print("📤 Solicitada lista de carros disponibles")
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("📤 Solicitada lista de carros disponibles")

			while websocket.get_available_packet_count() > 0:
				var msg := websocket.get_packet().get_string_from_utf8()
				print("📥 Mensaje recibido del servidor:", msg)
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("📥 Mensaje recibido: " + msg)

				var parsed = JSON.parse_string(msg)
				if typeof(parsed) == TYPE_DICTIONARY:
					_process_json_message(parsed)

		WebSocketPeer.STATE_CLOSING:
			print("🔌 Cerrando conexión...")
			if mostrar_mensaje:
				mostrar_mensaje.mostrar_mensaje("🔌 Cerrando conexión...")

		WebSocketPeer.STATE_CLOSED:
			registrado = false
			reconnect_timer += delta
			if reconnect_timer >= reconnect_delay:
				reconnection_attempts += 1
				reconnect_delay = min(10.0, reconnect_delay * 2)  # aumenta exponencialmente hasta 10s
				reconnect_timer = 0.0

				print("🔁 Reintentando conexión (intento #%d)..." % reconnection_attempts)
				if mostrar_mensaje:
					mostrar_mensaje.mostrar_mensaje("🔁 Reintentando conexión (intento #%d)..." % reconnection_attempts)
				var err := websocket.connect_to_url(host)
				if err != OK:
					push_error("❌ Fallo al reconectar: %s" % err)
					if mostrar_mensaje:
						mostrar_mensaje.mostrar_mensaje("❌ Fallo al reconectar: %s" % err)
				else:
					print("🔄 Intentando reconectar a %s..." % host)
					if mostrar_mensaje:
						mostrar_mensaje.mostrar_mensaje("🔄 Intentando reconectar a %s..." % host)

func send_command(data: Dictionary):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.send_text(JSON.stringify(data))
		print("📤 Comando enviado:", data)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("📤 Comando enviado: " + JSON.stringify(data))

func _process_json_message(data: Dictionary):
	print(data)
	if data["type"] == "available_cars" and data.has("carros"):
		carros_disponibles = data["carros"]
		print("🚗 Carros disponibles:", carros_disponibles)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("🚗 Carros disponibles actualizados")
		emit_signal("carros_actualizados", carros_disponibles)
