extends Control
class_name Controller

# 📦 Export variables
@export var car_button_texture: Texture2D
@export var joistick: VirtualJoystick = null
@export var websocket: WebSocketControlClient = null
@export var mostrar_mensaje: MostrarMensaje = null

# ⚙️ Variables internas
var id_text: String = ""
var last_left := 0.0
var last_right := 0.0
var left := 0.0
var right := 0.0
var base_speed := 255
var turn_speed := 255
var velocity := 1.0
var moving := false
var joy_id := 0

var forward := 0.0
var turn := 0.0

@onready var control_2: Control = $Control2

# ✅ READY
func _ready():
	websocket.carros_actualizados.connect(carros_actualizados)

# 🚀 Bucle principal de física
func _physics_process(delta):
	reset_movement_state()
	handle_inputs()
	update_motor_values()
	check_and_send_motor_commands()

# 🔄 Reinicia estado de movimiento
func reset_movement_state():
	forward = 0.0
	turn = 0.0
	moving = false

# 🎮 Manejo de entradas (teclado, joystick físico o virtual)
func handle_inputs():
	var using_virtual_joystick := joistick and joistick.output.length() > 0.1

	if using_virtual_joystick:
		forward = joistick.output.y
		turn = joistick.output.x
		moving = true
	elif Input.get_connected_joypads().has(joy_id):
		forward = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_Y)
		turn = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_X)
		if abs(forward) > 0.1 or abs(turn) > 0.1:
			moving = true

	if Input.is_action_pressed("move_up"):
		forward -= 1
		moving = true
	elif Input.is_action_pressed("move_down"):
		forward += 1
		moving = true
	if Input.is_action_pressed("move_left"):
		turn -= 1
		moving = true
	elif Input.is_action_pressed("move_right"):
		turn += 1
		moving = true

	if is_releasing_movement():
		send_motor_command(0, 0)
		return

# 🔁 Verifica si se soltó alguna tecla de movimiento
func is_releasing_movement() -> bool:
	return (Input.is_action_just_released("move_down")
		or Input.is_action_just_released("move_left")
		or Input.is_action_just_released("move_right")
		or Input.is_action_just_released("move_up"))

# ⚙️ Calcula los valores del motor
func update_motor_values():
	if forward != 0:
		left = (base_speed * forward - turn_speed * turn) * velocity
		right = (base_speed * forward + turn_speed * turn) * velocity
	elif turn != 0:
		left = -turn_speed * turn * velocity
		right = turn_speed * turn * velocity
	else:
		left = 0
		right = 0

	left = round_decimals(clamp(left, -255, 255), 2)
	right = round_decimals(clamp(right, -255, 255), 2)

# 📤 Envía valores del motor si cambiaron
func check_and_send_motor_commands():
	if moving:
		if left != last_left or right != last_right:
			send_motor_command(left, right)
	else:
		if last_left != 0 or last_right != 0:
			send_motor_command(0, 0)

# 🔁 Redondea decimales
func round_decimals(value: float, digits: int = 2) -> float:
	var factor = pow(10.0, digits)
	return round(value * factor) / factor

# 📡 Enviar comandos al WebSocket
func send_motor_command(left_val: float, right_val: float):
	if id_text.is_empty():
		show_message("⚠️ Selecciona un dispositivo")
		return

	if Global.websocket and Global.websocket.is_connected:
		var direction := {
			"type": "direction",
			"target": id_text,
			"left": left_val,
			"right": right_val
		}
		Global.websocket.send_command(direction)
		last_left = left_val
		last_right = right_val
	else:
		show_message("⚠️ WebSocket no conectado")
		print("❌ WebSocket no conectado")

# 🧹 Limpia los botones de control
func clear_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

# 🚗 Crea botones para cada carro
func carros_actualizados(cars: Array):
	clear_children(control_2)

	for carro in cars:
		if carro == str(Global.carro_controlado_id):
			continue
		var button := TouchScreenButton.new()
		button.texture_normal = car_button_texture
		button.scale = Vector2(1.5, 1.5)
		button.pressed.connect(func(): on_car_selected(carro))
		control_2.add_child(button)

# ✔️ Selección de carro
func on_car_selected(carro_id: String):
	if not Global.con_tiempo:
		show_message("❌ No tienes tiempo disponible. Compra más.")
		print("❌ Tiempo agotado.")
		return

	id_text = carro_id
	websocket.request_car_control(carro_id.to_int())
	show_message("✅ Dispositivo seleccionado")
	print("📲 Dispositivo seleccionado:", carro_id)

	if Global.autorizado:
		clear_children(control_2)

# 🪧 Mostrar mensajes en la interfaz
func show_message(msg: String):
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje(msg)
