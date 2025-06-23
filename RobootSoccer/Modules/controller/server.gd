# Archivo: ServerControl.gd
extends Control
class_name ServerControl

## Referencia a un nodo para mostrar mensajes en la interfaz de usuario.
## Debe ser un nodo que implemente un método 'mostrar_mensaje(mensaje: String, duracion: float = 0.0)'.
@export var mostrar_mensaje: MostrarMensaje = null

## Contenedor VBox para organizar los controles de autorización de clientes.
@onready var contenedor: VBoxContainer = $Contenedor

## Un temporizador temporal (usado para la autorización, aunque la lógica principal ahora usa un diccionario de tiempos).
@onready var temp_timer: Timer = $Timer

@export var websocket_server:WebSocketServerNode = null

## Almacena los IDs de los clientes "control" que estaban conectados en el fotograma anterior.
## Se utiliza para detectar cambios y actualizar la UI.
var ids_controles_anteriores: Array = []

## Tamaño de fuente base para los elementos de la UI.
var font_size: int = 30

## Ancho mínimo para los botones en la UI.
var button_min_width: int = 250

## Ancho mínimo para los campos de entrada de texto en la UI.
var input_min_width: int = 200

## Diccionario para almacenar el tiempo de expiración (unix time) de la autorización por cliente.
## Formato: { peer_id: { "fin": timestamp_unix } }
var temporizadores: Dictionary = {}

func _ready() -> void:
	#SEÑAL QUE SE EMITE DEL WEBSOCKETT CUANDO UN CONTROL HACE UNA SOLICITUD DE OPTERNER EL CARRO 
	websocket_server.request_control.connect(_request_control)

## Se ejecuta cada fotograma.
## Responsabilidades:
## - Detectar cambios en la lista de controles conectados y actualizar la UI.
## - Actualizar la cuenta regresiva de tiempo restante para los controles autorizados.
## - Desautorizar clientes cuyo tiempo haya expirado.
func _process(_delta: float) -> void:
	# 1. Obtener la lista actual de IDs de los clientes "control" conectados.
	var ids_actuales: Array = []
	for peer_id in Global.roles.keys():
		if Global.roles[peer_id].has("role") and Global.roles[peer_id]["role"] == "control":
			ids_actuales.append(peer_id)

	# 2. Actualizar la interfaz si la lista de controles ha cambiado.
	if ids_actuales != ids_controles_anteriores:
		mostrar_botones_disponibles()
		ids_controles_anteriores = ids_actuales.duplicate() # Actualiza la lista para la próxima comparación.

	# 3. Actualizar la cuenta regresiva visible para los controles autorizados.
	for child in contenedor.get_children(): # Itera sobre los HBoxContainers
		for grandchild in child.get_children(): # Itera sobre los elementos dentro de cada HBox
			# Busca las etiquetas de tiempo.
			if grandchild is Label and grandchild.name.begins_with("TiempoLabel_"):
				var pid: int = int(grandchild.name.split("_")[1]) # Extrae el peer_id del nombre de la etiqueta.
				var restante := _obtener_tiempo_restante(pid)
				grandchild.text = restante # Actualiza el texto de la etiqueta.

				# Si el tiempo restante es "0s", significa que el tiempo ha expirado, desautoriza al cliente.
				if restante == "⏳ 0s":
					_desautorizar_cliente(pid)

## Elimina todos los hijos de un nodo dado. Útil para limpiar la UI antes de reconstruirla.
## @param node: El nodo del cual se eliminarán todos los hijos.
func clear_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free() # Libera el nodo de la memoria.

## Reconstruye y muestra los botones y entradas de autorización para los clientes "control" disponibles.
func mostrar_botones_disponibles():
	clear_children(contenedor) # Limpia los controles existentes.

	for peer_id in Global.roles.keys():
		# Solo procesa clientes con el rol "control".
		if  RoleUtils.is_control(peer_id):
			var hbox := HBoxContainer.new() # Crea un contenedor horizontal para cada cliente.
			hbox.add_theme_constant_override("separation", 20) # Más espacio entre elementos.
			var autorizado: bool = Global.roles[peer_id].get("authorized", false) # Verifica el estado de autorización.

			# Etiqueta para mostrar el ID del peer.
			var label_id := Label.new()
			label_id.text = "ID: %d" % peer_id
			label_id.custom_minimum_size = Vector2(100, 0) # Ancho mínimo.
			label_id.add_theme_font_size_override("font_size", font_size)
			hbox.add_child(label_id)

			if autorizado:
				# Si el cliente está autorizado, muestra el tiempo restante y un botón "Desautorizar".
				var tiempo_label := Label.new()
				tiempo_label.name = "TiempoLabel_%d" % peer_id # Nombre único para identificar el label.
				tiempo_label.text = _obtener_tiempo_restante(peer_id)
				tiempo_label.add_theme_font_size_override("font_size", font_size)
				hbox.add_child(tiempo_label)

				var boton_des := Button.new()
				boton_des.text = "Desautorizar"
				boton_des.custom_minimum_size = Vector2(button_min_width, 0)
				boton_des.add_theme_font_size_override("font_size", font_size)
				# Conecta el botón a la función _desautorizar_cliente con el ID del peer.
				boton_des.pressed.connect(_desautorizar_cliente.bind(peer_id))
				hbox.add_child(boton_des)
			else:
				# Si el cliente NO está autorizado, muestra una entrada de texto y un botón "Autorizar".
				var line_edit := LineEdit.new()
				line_edit.placeholder_text = "Tiempo (ej: 5m, 30s, 1h)" # Placeholder para la entrada.
				line_edit.custom_minimum_size = Vector2(input_min_width, 0)
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Expande horizontalmente.
				line_edit.add_theme_font_size_override("font_size", font_size)

				var button := Button.new()
				button.text = "Autorizar"
				button.custom_minimum_size = Vector2(button_min_width, 0)
				button.add_theme_font_size_override("font_size", font_size)
				# Conecta el botón a la función _on_boton_control_seleccionado con el ID del peer y la entrada de texto.
				button.pressed.connect(_on_boton_control_seleccionado.bind(peer_id, line_edit))

				hbox.add_child(line_edit)
				hbox.add_child(button)

			contenedor.add_child(hbox) # Añade el HBox completo al VBox principal.

func _on_boton_control_seleccionado(peer_id: int, line_edit: LineEdit):
	var texto: String = line_edit.text.strip_edges().to_lower()
	var tiempo_en_segundos: int = _convertir_a_segundos(texto)

	if tiempo_en_segundos <= 0:
		print("⛔ Ingrese un tiempo válido (ej: 5m, 30s, 1h)")
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⛔ Ingrese un tiempo válido (ej: 5m, 30s, 1h)")
		return

	# Mensaje de confirmación en consola y UI.
	print("🎯 Cliente %d autorizado por %d segundos." % [peer_id, tiempo_en_segundos])
	if mostrar_mensaje:
		mostrar_mensaje.mostrar_mensaje("✅ Cliente %d autorizado por %d segundos." % [peer_id, tiempo_en_segundos], 5.0)

	# Marca el rol como autorizado.
	Global.roles[peer_id]["authorized"] = true

	# Calcula el tiempo de finalización de la autorización.
	var tiempo_fin: int = int(Time.get_unix_time_from_system() + tiempo_en_segundos)
	temporizadores[peer_id] = { "fin": tiempo_fin } # Guarda el tiempo de fin para este peer.

	# Manejo del temporizador: evita duplicados
	if temp_timer.timeout.is_connected(_on_autorizacion_terminada):
		temp_timer.timeout.disconnect(_on_autorizacion_terminada)

	# Conecta la señal con el peer_id vinculado (bind)
	temp_timer.timeout.connect(_on_autorizacion_terminada.bind(peer_id))
	temp_timer.wait_time = float(tiempo_en_segundos)
	temp_timer.one_shot = true
	temp_timer.start()

	# Enviar mensaje al cliente para informarle que fue autorizado y cuánto tiempo tiene.
	websocket_server.send_json_to_peer(peer_id, {
		"type":"authorized",
		"reason": "time_assigned",
		"status": "ok",
		"message": "Autorizado por %d segundos." % tiempo_en_segundos,
		"time_assigned": tiempo_en_segundos,
		"authorized": true
	})

	# Actualiza la UI para reflejar el nuevo estado
	mostrar_botones_disponibles()


## Convierte una cadena de texto de tiempo (ej: "5m", "30s", "1h") a segundos.
## @param texto: La cadena de tiempo a convertir.
## @return: El tiempo en segundos, o 0 si el formato es inválido.
func _convertir_a_segundos(texto: String) -> int:
	if texto.ends_with("h"):
		return int(texto.trim_suffix("h")) * 3600
	elif texto.ends_with("m"):
		return int(texto.trim_suffix("m")) * 60
	elif texto.ends_with("s"):
		return int(texto.trim_suffix("s"))
	else:
		# Si no tiene sufijo, intenta parsear como minutos directamente.
		if texto.is_valid_int():
			return int(texto) * 60
		return 0 # Si no es un entero válido ni tiene sufijo.

func _request_control(peer_id:int, car_id):
	##si pasa todas las pruevas autorizarlo 
	websocket_server._autorizar_cliente(peer_id,car_id)
	

## Obtiene la cadena de texto que representa el tiempo restante para un peer.
## @param peer_id: El ID del peer.
## @return: Una cadena como "⏳ 120s" o "⏳ -" si no hay temporizador.
func _obtener_tiempo_restante(peer_id: int) -> String:
	if temporizadores.has(peer_id):
		var restante: int = temporizadores[peer_id]["fin"] - Time.get_unix_time_from_system()
		return "⏳ %ds" % max(restante, 0) # Asegura que el tiempo no sea negativo.
	return "⏳ -" # Si no hay temporizador para este peer.

## Función llamada cuando la autorización de un cliente termina (ej: por timeout del temp_timer).
## @param peer_id: El ID del cliente cuya autorización ha terminado.
func _on_autorizacion_terminada(peer_id: int):
	_desautorizar_cliente(peer_id)

func _desautorizar_cliente(peer_id: int):
	
	if RoleUtils.exists(peer_id):
		temporizadores.erase(peer_id) # Elimina el temporizador de este cliente.
		websocket_server._desautorizar_cliente(peer_id)

		mostrar_botones_disponibles() # Refresca la UI.
		print("⏱️ Tiempo terminado. Cliente %d desautorizado." % peer_id)
		if mostrar_mensaje:
			mostrar_mensaje.mostrar_mensaje("⏱️ Cliente %d desautorizado." % peer_id)
