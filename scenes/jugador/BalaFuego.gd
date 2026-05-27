extends Node2D

const CharcoFuego = preload("res://scenes/jugador/CharcoFuego.gd")

var velocidad: float = 300.0
var direccion: Vector2 = Vector2.ZERO
var objetivo: Node = null
var danio: float = 15.0
var danio_quemadura: float = 3.0
var duracion_quemadura: float = 4.0
var rebotes_max: int = 0
var rebotes_dados: int = 0
var nivel: int = 1
var jugador_ref: Node = null
var enemigos_golpeados: Array = []
var viajando: bool = true
var timer_visual: float = 0.0

func inicializar(jugador: Node, nv: int, objetivo_inicial: Node) -> void:
	jugador_ref = jugador
	nivel = nv
	objetivo = objetivo_inicial
	global_position = jugador.global_position

	match nv:
		1: danio = 15.0;  danio_quemadura = 3.0;  rebotes_max = 0
		2: danio = 22.0;  danio_quemadura = 5.0;  rebotes_max = 0
		3: danio = 30.0;  danio_quemadura = 7.0;  rebotes_max = 3
		4: danio = 38.0;  danio_quemadura = 10.0; rebotes_max = 4
		5: danio = 46.0;  danio_quemadura = 13.0; rebotes_max = 5
		6: danio = 55.0;  danio_quemadura = 16.0; rebotes_max = 6

	if objetivo:
		direccion = (objetivo.global_position - global_position).normalized()

func _process(delta: float) -> void:
	if not viajando or objetivo == null:
		return

	# Mover hacia objetivo
	var dist = global_position.distance_to(objetivo.global_position)
	if dist < 15.0:
		_golpear_objetivo()
	else:
		direccion = (objetivo.global_position - global_position).normalized()
		global_position += direccion * velocidad * delta

	queue_redraw()

func _golpear_objetivo() -> void:
	if not is_instance_valid(objetivo):
		_terminar()
		return

	objetivo.recibir_danio(danio)
	if objetivo.has_method("aplicar_quemadura"):
		objetivo.aplicar_quemadura(danio_quemadura, duracion_quemadura)
	enemigos_golpeados.append(objetivo)

	if rebotes_dados < rebotes_max:
		var siguiente = _buscar_siguiente()
		if siguiente != null:
			objetivo = siguiente
			rebotes_dados += 1
			direccion = (objetivo.global_position - global_position).normalized()
		else:
			_terminar()
	else:
		_terminar()

func _buscar_siguiente() -> Node:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var mejor = null
	var dist_min = INF
	for e in enemigos:
		if e == objetivo:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < 250.0 and d < dist_min:
			dist_min = d
			mejor = e
	# Si no hay otro enemigo cerca, rebotar al ultimo golpeado
	if mejor == null and enemigos_golpeados.size() >= 2:
		mejor = enemigos_golpeados[enemigos_golpeados.size() - 2]
		if not is_instance_valid(mejor):
			mejor = null
	return mejor

func _terminar() -> void:
	viajando = false
	if nivel >= 6:
		_crear_charco()
	queue_free()

func _crear_charco() -> void:
	var charco = CharcoFuego.new()
	charco.global_position = global_position
	charco.danio_quemadura = danio_quemadura * 0.5
	get_tree().current_scene.add_child(charco)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.4, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.9, 0.0, 1.0))
