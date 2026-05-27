extends Node2D

const CraterFuego = preload("res://scenes/jugador/CraterFuego.gd")
const FragmentoMeteorito = preload("res://scenes/jugador/FragmentoMeteorito.gd")
const OrbesCuracion = preload("res://scenes/jugador/OrbeCuracion.gd")
const MetoritoLluvia = preload("res://scenes/jugador/MetoritoLluvia.gd")

var nivel: int = 1
var danio: float = 80.0
var radio_explosion: float = 100.0
var jugador_ref: Node = null
var cayendo: bool = true
var velocidad_caida: float = 600.0
var objetivo: Vector2 = Vector2.ZERO
var altura_inicial: float = -500.0
var timer_visual: float = 0.0

func inicializar(jugador: Node, nv: int, pos_objetivo: Vector2) -> void:
	jugador_ref = jugador
	nivel = nv
	objetivo = pos_objetivo
	global_position = Vector2(pos_objetivo.x, pos_objetivo.y + altura_inicial)

	match nv:
		1: danio = 80.0;  radio_explosion = 100.0
		2: danio = 95.0;  radio_explosion = 110.0
		3: danio = 110.0; radio_explosion = 120.0
		4: danio = 125.0; radio_explosion = 130.0
		5: danio = 140.0; radio_explosion = 140.0
		6: danio = 180.0; radio_explosion = 180.0

func _process(delta: float) -> void:
	if cayendo:
		global_position.y += velocidad_caida * delta
		if global_position.y >= objetivo.y:
			global_position = objetivo
			cayendo = false
			_explotar()
	queue_redraw()

func _explotar() -> void:
	# Daño en área
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio_explosion:
			e.recibir_danio(danio)

	# Fragmentos lvl2+
	if nivel >= 2:
		_lanzar_fragmentos()

	# Crater lvl4+
	if nivel >= 4:
		var crater = CraterFuego.new()
		crater.global_position = global_position
		crater.radio = 130.0
		crater.duracion = 10.0
		crater.danio_quemadura = 8.0
		crater.ralentizar = true
		get_tree().current_scene.add_child(crater)

	# Orbe curacion lvl5+
	if nivel >= 5:
		var orbe = OrbesCuracion.new()
		orbe.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		orbe.jugador_ref = jugador_ref
		orbe.curacion_pct = 0.15
		get_tree().current_scene.add_child(orbe)

	# Lluvia lvl6
	if nivel >= 6:
		_lanzar_lluvia()

	queue_free()

func _lanzar_fragmentos() -> void:
	for i in 6:
		var frag = FragmentoMeteorito.new()
		var angulo = (TAU / 6.0) * i
		var dir = Vector2(cos(angulo), sin(angulo))
		frag.global_position = global_position
		frag.direccion = dir
		frag.nivel = nivel
		get_tree().current_scene.add_child(frag)

func _lanzar_lluvia() -> void:
	for i in 5:
		var mini = MetoritoLluvia.new()
		var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
		mini.objetivo = global_position + offset
		mini.global_position = Vector2(mini.objetivo.x, mini.objetivo.y - 400.0)
		mini.jugador_ref = jugador_ref
		get_tree().current_scene.add_child(mini)

func _draw() -> void:
	if cayendo:
		var radio = 18.0 if nivel < 6 else 28.0
		draw_circle(Vector2.ZERO, radio, Color(0.8, 0.3, 0.0, 0.95))
		draw_circle(Vector2.ZERO, radio * 0.5, Color(1.0, 0.7, 0.2, 1.0))
