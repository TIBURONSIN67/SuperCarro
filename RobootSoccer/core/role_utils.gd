class_name RoleUtils

# 🔍 Método privado: Devuelve los datos del rol si existen y son un Dictionary. Si no, devuelve uno vacío.
static func _get_role_data(peer_id: int) -> Dictionary:
	if not Global.roles.has(peer_id):
		return {}
	var role_data = Global.roles[peer_id]
	if role_data is Dictionary:
		return role_data
	return {}  # Si no es diccionario, devolvemos vacío

# ✅ Verifica si el ID del peer existe en Global.roles.
static func exists(peer_id: int) -> bool:
	return Global.roles.has(peer_id)

# 🎮 Verifica si el peer es un control (su rol es "control").
static func is_control(peer_id: int) -> bool:
	var role = _get_role_data(peer_id)
	return role.get("role", "") == "control"

# 🚗 Verifica si el peer es un carro (su rol es "carro").
static func is_car(peer_id: int) -> bool:
	var role = _get_role_data(peer_id)
	return role.get("role", "") == "carro"

# ⏳ Verifica si el peer está autorizado y tiene tiempo para controlar.
static func is_authorized(peer_id: int) -> bool:
	var role = _get_role_data(peer_id)
	return role.get("authorized", false)

# 🔗 Verifica si el peer está actualmente controlando el carro con el ID especificado.
static func controls_car(peer_id: int, car_id: int) -> bool:
	var role = _get_role_data(peer_id)
	return role.get("controlling_car_id", -1) == car_id

# 👁️ Verifica si el carro está siendo controlado actualmente por algún control.
static func is_being_controlled(car_id: int) -> bool:
	var role = _get_role_data(car_id)
	return role.get("controlled_by_id", -1) != -1

# 📥 Devuelve el ID del control que está controlando el carro, o -1 si no hay ninguno.
static func get_controlled_by(car_id: int) -> int:
	var role = _get_role_data(car_id)
	return role.get("controlled_by_id", -1)
