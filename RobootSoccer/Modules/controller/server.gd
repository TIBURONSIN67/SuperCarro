extends Control
class_name ServerControl

@export var mostrar_mensaje:MostrarMensaje = null

@onready var contenedor: VBoxContainer = $Contenedor
@onready var temp_timer: Timer = $Timer

var ids_controles_anteriores: Array = []
var font_size: int = 30
var button_min_width: int = 250
var input_min_width: int = 200

# Diccionario para almacenar el tiempo de expiración por cliente
var temporizadores: Dictionary = {}

func _process(delta: float) -> void:
	var ids_actuales: Array = []

	# Obtener lista actual de controles conectados
	for peer_id in Global.roles.keys():
		if Global.roles[peer_id].has("role") and Global.roles[peer_id]["role"] == "control":
			ids_actuales.append(peer_id)

	# Actualizar lista si hubo cambios
	if ids_actuales != ids_controles_anteriores:
		mostrar_botones_disponibles()
		ids_controles_anteriores = ids_actuales.duplicate()

	# Actualizar cuenta regresiva visible
	for child in contenedor.get_children():
		for grandchild in child.get_children():
			if grandchild is Label and grandchild.name.begins_with("TiempoLabel_"):
				var pid: int = int(grandchild.name.split("_")[1])
				var restante := _obtener_tiempo_restante(pid)
				grandchild.text = restante

				if restante == "⏳ 0s":
					_desautorizar_cliente(pid)

func clear_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func mostrar_botones_disponibles():
	clear_children(contenedor)

	for peer_id in Global.roles.keys():
		if Global.roles[peer_id].has("role") and Global.roles[peer_id]["role"] == "control":
			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 20)  # 👈 más espacio entre elementos
			var autorizado: bool = Global.roles[peer_id].get("authorized", false)

			var label_id := Label.new()
			label_id.text = "ID: %d" % peer_id
			label_id.custom_minimum_size = Vector2(100, 0)
			label_id.add_theme_font_size_override("font_size", font_size)
			hbox.add_child(label_id)

			if autorizado:
				var tiempo_label := Label.new()
				tiempo_label.name = "TiempoLabel_%d" % peer_id
				tiempo_label.text = _obtener_tiempo_restante(peer_id)
				tiempo_label.add_theme_font_size_override("font_size", font_size)
				hbox.add_child(tiempo_label)

				var boton_des := Button.new()
				boton_des.text = "Desautorizar"
				boton_des.custom_minimum_size = Vector2(button_min_width, 0)
				boton_des.add_theme_font_size_override("font_size", font_size)
				boton_des.pressed.connect(_desautorizar_cliente.bind(peer_id))
				hbox.add_child(boton_des)
			else:
				var line_edit := LineEdit.new()
				line_edit.placeholder_text = "Tiempo"
				line_edit.custom_minimum_size = Vector2(input_min_width, 0)
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line_edit.add_theme_font_size_override("font_size", font_size)

				var button := Button.new()
				button.text = "Autorizar"
				button.custom_minimum_size = Vector2(button_min_width, 0)
				button.add_theme_font_size_override("font_size", font_size)
				button.pressed.connect(_on_boton_control_seleccionado.bind(peer_id, line_edit))

				hbox.add_child(line_edit)
				hbox.add_child(button)

			contenedor.add_child(hbox)

func _on_boton_control_seleccionado(peer_id: int, line_edit: LineEdit):
	var texto: String = line_edit.text.strip_edges().to_lower()
	var tiempo_en_segundos: int = _convertir_a_segundos(texto)

	if tiempo_en_segundos <= 0:
		print("⛔ Ingrese un tiempo válido (ej: 5m, 30s, 1h)")
		mostrar_mensaje.mostrar_mensaje("⛔ Ingrese un tiempo válido (ej: 5m, 30s, 1h)")
		return

	mostrar_mensaje.mostrar_mensaje("✅ Cliente %d autorizado por %d segundos." % [peer_id, tiempo_en_segundos], 5.0)
	print("🎯 Cliente %d autorizado por %d segundos." % [peer_id, tiempo_en_segundos])

	Global.joy_id_autorizado = peer_id
	Global.roles[peer_id]["authorized"] = true

	var tiempo_fin: int = Time.get_unix_time_from_system() + tiempo_en_segundos
	temporizadores[peer_id] = { "fin": tiempo_fin }

	# Temporizador global opcional (por seguridad)
	temp_timer.wait_time = float(tiempo_en_segundos)
	temp_timer.one_shot = true
	temp_timer.start()

	if temp_timer.timeout.is_connected(_on_autorizacion_terminada):
		temp_timer.timeout.disconnect(_on_autorizacion_terminada)

	temp_timer.timeout.connect(_on_autorizacion_terminada.bind(peer_id))

	mostrar_botones_disponibles()

func _convertir_a_segundos(texto: String) -> int:
	if texto.ends_with("h"):
		return int(texto.trim_suffix("h")) * 3600
	elif texto.ends_with("m"):
		return int(texto.trim_suffix("m")) * 60
	elif texto.ends_with("s"):
		return int(texto.trim_suffix("s"))
	else:
		return int(texto)

func _obtener_tiempo_restante(peer_id: int) -> String:
	if temporizadores.has(peer_id):
		var restante: int = temporizadores[peer_id]["fin"] - Time.get_unix_time_from_system()
		return "⏳ %ds" % max(restante, 0)
	return "⏳ -"

func _on_autorizacion_terminada(peer_id: int):
	_desautorizar_cliente(peer_id)

func _desautorizar_cliente(peer_id: int):
	if Global.roles.has(peer_id):
		Global.roles[peer_id]["authorized"] = false
		temporizadores.erase(peer_id)
		print("⏱️ Tiempo terminado. Cliente %d desautorizado." % peer_id)
		mostrar_mensaje.mostrar_mensaje("⏱️ Cliente %d desautorizado." % peer_id)
		mostrar_botones_disponibles()
