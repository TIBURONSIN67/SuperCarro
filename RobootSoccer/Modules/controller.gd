extends Control

var last_left = 0
var last_right = 0
var left = 0
var right = 0
var base_speed = 255
var turn_speed = 255
var velocity := 1  # 🔹 Control global de velocidad (entre 0.0 y 1.0)
var moving = false

@export var joistick:VirtualJoystick = null

var joy_id = 0


var forward = 0.0
var turn = 0.0
func _physics_process(delta):
	forward = 0.0
	turn = 0.0

	# 🔒 Verificar si el mando actual está autorizado
	# ✅ Autorizar si el joystick virtual está activo
	var usando_joystick_virtual = joistick and joistick.output.length() > 0.1

	if not Global.autorizados.has(joy_id) and not usando_joystick_virtual:
		# Si no está autorizado y no es un joystick virtual, no mover nada
		if moving:
			_on_send_pressed({"left": 0, "right": 0})
			last_left = 0
			last_right = 0
			moving = false
		return  # 🔒 Evitar todo lo demás


	moving = false
	
	# 🔹 Entrada por joystick virtual (tiene prioridad)
	if joistick and joistick.output.length() > 0.1:
		forward = joistick.output.y  # Invertido
		turn = joistick.output.x
		moving = true

	# 🔹 Si no hay joystick virtual, usar joystick físico
	elif Input.get_connected_joypads().has(joy_id):
		forward = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_Y)
		turn = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_X)
		if abs(forward) > 0.1 or abs(turn) > 0.1:
			moving = true

	# 🔹 Entrada por teclado
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

	# Combinar movimiento
	if forward != 0:
		left = (base_speed * forward - turn_speed * turn) * velocity
		right = (base_speed * forward + turn_speed * turn) * velocity
	elif turn != 0:
		left = (-turn_speed * turn) * velocity
		right = (turn_speed * turn) * velocity
	else:
		left = 0
		right = 0

	left = clamp(left, -255, 255)
	right = clamp(right, -255, 255)

	if moving:
		if left != last_left or right != last_right:
			_on_send_pressed({"left": left, "right": right})
			last_left = left
			last_right = right
	else:
		if last_left != 0 or last_right != 0:
			_on_send_pressed({"left": 0, "right": 0})
			last_left = 0
			last_right = 0

func _on_send_pressed(direction: Dictionary):
	if Global.websocket.is_connected:
		Global.websocket.send_json(direction)
		print("📤 Enviado:", direction)
	else:
		print("⚠️ No conectado")
