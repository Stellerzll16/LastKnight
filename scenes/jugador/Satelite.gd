extends Node2D

var radio: float = 120.0
var velocidad_angular: float = 2.5
var angulo: float = 0.0
var danio: float = 100.0
var jugador_ref: Node = null
var enemigos_golpeados: Array = []
var timer_reset: float = 0.0

func inicializar(jugador: Node, angulo_inicial: float) -> void:
	jugador_ref = jugador
	angulo = angulo_inicial

func _physics_process(delta: float) -> void:
	if jugador_ref == null:
		return

	angulo += velocidad_angular * delta
	var offset = Vector2(cos(angulo), sin(angulo)) * radio
	global_position = jugador_ref.global_position + offset

	# Reset enemigos golpeados cada 0.5s para poder volver a golpear
	timer_reset += delta
	if timer_reset >= 0.5:
		timer_reset = 0.0
		enemigos_golpeados.clear()

	# Detectar enemigos cercanos
	var enemigos = jugador_ref.get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e in enemigos_golpeados:
			continue
		if global_position.distance_to(e.global_position) < 14.0:
			e.recibir_danio(danio)
			enemigos_golpeados.append(e)
