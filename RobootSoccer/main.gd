extends CanvasLayer

@onready var autorisar: Button = $VBoxContainer/Autorisar
@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
@onready var timer: Timer = $Timer

@export var tiempo_minutos: float = 2.0 # Tiempo por defecto en minutos
@export var contenedor_autorizacion: NodePath # Nodo que contiene los campos de autorización
@export var contenedor_controles: NodePath # Nodo con los controles del juego

func _ready():
	var ips = IP.get_local_addresses()
	var found = false
	
	if ips.size() > 0:
		print("IPs locales disponibles (filtradas 192.168.x.x):")
		for ip in ips:
			if ip.begins_with("192.168."):
				print("  - ", ip)
				found = true
	
	if not found:
		print("No se encontraron IPs locales en el rango 192.168.x.x.")

	autorisar.pressed.connect(_on_autorizar_pressed)
	timer.timeout.connect(_on_timer_timeout)

func _on_autorizar_pressed():
	if not line_edit.text.is_valid_int():
		print("⚠️ Ingresa un número válido como ID de mando.")
		return

	var joy_id := int(line_edit.text)

	if not Input.get_connected_joypads().has(joy_id):
		print("❌ El mando con ID %d no está conectado." % joy_id)
		return

	var tiempo_segundos := tiempo_minutos * 60.0

	Global.autorizados[joy_id] = true
	Global.joy_id_autorizado = joy_id

	timer.wait_time = tiempo_segundos
	timer.one_shot = true
	timer.start()

	print("✅ Mando ID %d autorizado por %.2f minutos." % [joy_id, tiempo_minutos])

	# Mostrar/Ocultar controles
	if contenedor_autorizacion:
		get_node(contenedor_autorizacion).visible = false
	if contenedor_controles:
		get_node(contenedor_controles).visible = true

func _on_timer_timeout():
	var joy_id := Global.joy_id_autorizado
	if joy_id != -1 and Global.autorizados.has(joy_id):
		Global.autorizados.erase(joy_id)
		print("⏱️ Mando ID %d desautorizado tras %.2f minutos." % [joy_id, tiempo_minutos])
		Global.joy_id_autorizado = -1

		# Restaurar controles
		if contenedor_autorizacion:
			get_node(contenedor_autorizacion).visible = true
		if contenedor_controles:
			get_node(contenedor_controles).visible = false
