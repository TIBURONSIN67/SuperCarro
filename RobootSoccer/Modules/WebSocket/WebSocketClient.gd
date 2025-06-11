extends Node
class_name WebSocketClient

var socket := WebSocketPeer.new()
const SERVER_URL := "ws://192.168.36.100:81"  # Cambia esta IP si es necesario

var is_connected := false
var reconnect_timer := 0.0
const RECONNECT_INTERVAL := 5.0

func _process(delta):
	socket.poll()
	handle_state()

	if is_connected:
		handle_messages()
	else:
		reconnect_timer += delta
		if reconnect_timer >= RECONNECT_INTERVAL:
			reconnect_timer = 0.0
			print("🔄 Intentando reconectar WebSocket...")
			connect_to_server()

func connect_to_server(url: String = SERVER_URL):
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED and socket.get_ready_state() != WebSocketPeer.STATE_CLOSING:
		print("⚠️ Ya hay una conexión en uso. Estado:", socket.get_ready_state())
		return

	var err := socket.connect_to_url(url)
	if err != OK:
		print("❌ Error al conectar WebSocket:", err)
	else:
		print("🔄 Intentando conectar a:", url)

func handle_messages():
	while socket.get_available_packet_count() > 0:
		var data := socket.get_packet().get_string_from_utf8()
		print("📨 Mensaje recibido:", data)
		_on_message_received(data)

func handle_state():
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not is_connected:
				print("✅ ¡Conectado al servidor WebSocket!")
				is_connected = true
				_on_connected()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			if is_connected:
				print("🔌 Conexión cerrada. Código:", socket.get_close_code(), "Razón:", socket.get_close_reason())
			is_connected = false
			_on_disconnected()

func send_json(data: Dictionary):
	if is_connected:
		var json_string = JSON.stringify(data)
		socket.send_text(json_string)
		print("📤 Enviado JSON:", json_string)
	else:
		print("⚠️ No se puede enviar, WebSocket no está conectado.")

func _on_connected():
	print("📡 Cliente WebSocket conectado.")
	

func _on_message_received(message: String):
	pass  # Aquí puedes procesar mensajes recibidos si quieres

func _on_disconnected():
	pass  # Aquí puedes agregar lógica al desconectarse
