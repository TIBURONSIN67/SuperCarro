extends Control
class_name MostrarMensaje

@onready var mensaje_label: Label = $MensajeLabel

var cola_mensajes := []
var mostrando := false

func mostrar_mensaje(texto: String, duracion: float = 2.0) -> void:
	cola_mensajes.append({"texto": texto, "duracion": duracion})
	if not mostrando:
		_procesar_siguiente_mensaje()

func _procesar_siguiente_mensaje() -> void:
	if cola_mensajes.size() == 0:
		mostrando = false
		mensaje_label.visible = false
		return
	mostrando = true
	var msg = cola_mensajes.pop_front()
	mensaje_label.text = msg["texto"]
	mensaje_label.visible = true
	mensaje_label.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_property(mensaje_label, "modulate:a", 0.0, msg["duracion"])\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN)
	await tween.finished
	_procesar_siguiente_mensaje()
