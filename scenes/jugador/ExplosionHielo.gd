extends Node2D

var radio: float = 80.0
var danio: float = 10.0
var duracion_congela: float = 1.0
var duracion_zona: float = 2.0
var timer_zona: float = 0.0
var fase: String = "explosion"

var radios     = [80.0,  110.0, 140.0, 175.0, 210.0, 250.0]
var danios     = [10.0,  16.0,  22.0,  28.0,  34.0,  40.0]
var duraciones = [1.0,   1.6,   2.2,   2.8,   3.4,   4.0]

var timer_visual: float = 0.15
var enemigos_ya_congelados: Array = []
var velocidad_reducida: float = 0.3

func inicializar(jugador: Node, nivel: int) -> void:
	global_position = jugador.global_position
	var idx = clamp(nivel - 1, 0, 5)
	radio = radios[idx]
	danio = danios[idx]
	duracion_congela = duraciones[idx]
	_aplicar_explosion()

func _aplicar_explosion() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio:
			e.recibir_danio(danio)
			if e.has_method("congelar"):
				e.congelar(duracion_congela)
				enemigos_ya_congelados.append(e)

func _process(delta: float) -> void:
	if fase == "explosion":
		timer_visual -= delta
		if timer_visual <= 0.0:
			fase = "zona"
			timer_zona = duracion_zona
		queue_redraw()
	elif fase == "zona":
		timer_zona -= delta
		_aplicar_ralentizacion()
		queue_redraw()
		if timer_zona <= 0.0:
			queue_free()

func _aplicar_ralentizacion() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e in enemigos_ya_congelados:
			continue
		if global_position.distance_to(e.global_position) <= radio:
			if e.has_method("ralentizar"):
				e.ralentizar(velocidad_reducida)

func _draw() -> void:
	if fase == "explosion":
		var alpha = timer_visual / 0.15
		draw_circle(Vector2.ZERO, radio, Color(0.5, 0.9, 1.0, alpha * 0.4))
		draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(0.5, 0.9, 1.0, alpha), 3.0, true)
	elif fase == "zona":
		var alpha = (timer_zona / duracion_zona) * 0.3
		draw_circle(Vector2.ZERO, radio, Color(0.5, 0.9, 1.0, alpha))
		draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(0.5, 0.9, 1.0, 0.5), 2.0, true)
