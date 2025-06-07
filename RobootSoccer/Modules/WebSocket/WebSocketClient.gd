extends Node

class_name WebSocketClient

var socket := WebSocketPeer.new()
const SERVER_URL := "ws://192.168.4.1:81"

var is_connected := false

func _process(_delta):
	socket.poll()
	handle_state()  # siempre chequear el estado

	if is_connected:
		handle_messages()

# 📡 Conectar al servidor
func connect_to_server(url: String = SERVER_URL):
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED and socket.get_ready_state() != WebSocketPeer.STATE_CLOSING:
		print("⚠️ Ya hay una conexión en uso. Estado:", socket.get_ready_state())
		return

	var err := socket.connect_to_url(url)
	if err != OK:
		print("❌ Error al conectar WebSocket:", err)
		set_process(false)
	else:
		print("🔄 Intentando conectar a:", url)
		set_process(true)


# 📨 Manejar recepción de mensajes
func handle_messages():
	while socket.get_available_packet_count() > 0:
		var data := socket.get_packet().get_string_from_utf8()
		print("📨 Mensaje recibido:", data)
		_on_message_received(data)

# 🔄 Verificar y manejar el estado de conexión
func handle_state():
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not is_connected:
				print("✅ Conectado al servidor WebSocket.")
				is_connected = true
				_on_connected()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			print("🔌 Conexión cerrada. Código:", socket.get_close_code(), "Razón:", socket.get_close_reason())
			is_connected = false
			_on_disconnected()
			set_process(false)

#
func send_json(data: Dictionary):
	if is_connected:
		var json_string = JSON.stringify(data)
		socket.send_text(json_string)
		print("📤 Enviado JSON:", json_string)
	else:
		print("⚠️ No se puede enviar, WebSocket no está conectado.")


# 🎯 Callbacks (puedes sobrescribirlos si extiendes la clase)
func _on_connected():
	send_json({"right":0,"left":0})  # Enviar un mensaje al conectar (personalizable)

func _on_message_received(message: String):
	# Puedes personalizar esta función en tus scripts
	pass

func _on_disconnected():
	# Puedes personalizar esta función en tus scripts
	pass
