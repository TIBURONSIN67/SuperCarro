extends Control

class_name Controller
@export var car_button_texture:Texture2D
@export var joistick: VirtualJoystick = null
var id_text = ""
@onready var websocket: WebSocketControlClient = $"../Control"
@export var mostrar_mensaje:MostrarMensaje = null

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

func _ready():
	websocket.carros_actualizados.connect(_on_data_received)
		

func _physics_process(delta):

	forward = 0.0
	turn = 0.0
	moving = false

	var usando_joystick_virtual = joistick and joistick.output.length() > 0.1

	# 🔹 Entrada por joystick virtual
	if usando_joystick_virtual:
		forward = joistick.output.y
		turn = joistick.output.x
		moving = true

	# 🔹 Entrada por joystick físico
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

	if (Input.is_action_just_released("move_down") or
		Input.is_action_just_released("move_left") or 
		Input.is_action_just_released("move_right") or 
		Input.is_action_just_released("move_up")):
		moving = false
		_on_send_pressed({"left": 0, "right": 0})
		last_left = 0
		last_right = 0
		return
		
	# 🔁 Calcular motores
	if forward != 0:
		left = (base_speed * forward - turn_speed * turn) * velocity
		right = (base_speed * forward + turn_speed * turn) * velocity
	elif turn != 0:
		left = (-turn_speed * turn) * velocity
		right = (turn_speed * turn) * velocity
	else:
		left = 0
		right = 0

	left = round_decimals(clamp(left, -255, 255), 2)
	right = round_decimals(clamp(right, -255, 255), 2)

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


func round_decimals(value: float, digits: int = 2) -> float:
	var factor = pow(10.0, digits)
	return round(value * factor) / factor


# ✅ Enviar movimiento con target incluido
func _on_send_pressed(direction: Dictionary):
	if id_text.is_empty():
		mostrar_mensaje.mostrar_mensaje("seleciona un dispositvo")
		return
	if Global.websocket and Global.websocket.is_connected:
		direction["target"] = id_text
		Global.websocket.send_command(direction)
	else:
		mostrar_mensaje.mostrar_mensaje("⚠️ WebSocket no conectado")
		print("⚠️ WebSocket no conectado")


	
@onready var control_2: Control = $Control2

func clear_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _on_data_received(data: Array):
	clear_children(control_2)
	
	for carro in data:
		var button := TouchScreenButton.new()
		button.texture_normal = car_button_texture
		button.scale = Vector2(1.5, 1.5)
		button.pressed.connect(func(): _on_car_button_pressed(carro))
		control_2.add_child(button)



func _on_car_button_pressed(carro_id: String):
	id_text = carro_id
	mostrar_mensaje.mostrar_mensaje("dispositivo seleccionado")
	clear_children(control_2)
	
