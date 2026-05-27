extends Node

var vida_jugador: float = 100.0
var vida_maxima: float = 100.0
var xp_jugador: float = 0.0
var nivel_jugador: int = 1
var xp_para_siguiente_nivel: float = 150.0
var tiempo_transcurrido: float = 0.0
var enemigos_eliminados: int = 0
var poderes_activos: Array = []
var registro_poderes: Dictionary = {}

func registrar_poder(tipo: String, nombre: String) -> void:
	if tipo in registro_poderes:
		registro_poderes[tipo]["nivel"] += 1
	else:
		registro_poderes[tipo] = {"nombre": nombre, "nivel": 1}

func reiniciar() -> void:
	vida_jugador = 100.0
	vida_maxima = 100.0
	xp_jugador = 0.0
	nivel_jugador = 1
	xp_para_siguiente_nivel = 50.0
	tiempo_transcurrido = 0.0
	enemigos_eliminados = 0
	poderes_activos = []
	registro_poderes = {}

func agregar_xp(cantidad: float) -> void:
	xp_jugador += cantidad
	if xp_jugador >= xp_para_siguiente_nivel:
		xp_jugador -= xp_para_siguiente_nivel
		nivel_jugador += 1
		xp_para_siguiente_nivel *= 1.6 + (nivel_jugador * 0.08)
		EventBus.jugador_subio_nivel.emit()

func recibir_danio(cantidad: float) -> void:
	vida_jugador = max(0.0, vida_jugador - cantidad)
	if vida_jugador <= 0.0:
		EventBus.jugador_murio.emit()

func get_fase_actual() -> int:
	if tiempo_transcurrido < 300.0:
		return 1
	elif tiempo_transcurrido < 900.0:
		return 2
	elif tiempo_transcurrido < 1500.0:
		return 3
	else:
		return 4

func _process(delta: float) -> void:
	if not get_tree().paused:
		tiempo_transcurrido += delta
