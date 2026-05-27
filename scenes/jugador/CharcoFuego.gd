extends Node2D

var radio: float = 70.0
var duracion: float = 5.0
var timer: float = 0.0
var danio_quemadura: float = 2.0
var tick_timer: float = 0.0
var tick_intervalo: float = 0.5

func _process(delta: float) -> void:
	timer += delta
	tick_timer += delta

	if tick_timer >= tick_intervalo:
		tick_timer = 0.0
		_quemar_enemigos()

	queue_redraw()

	if timer >= duracion:
		queue_free()

func _quemar_enemigos() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio:
			if e.has_method("aplicar_quemadura"):
				e.aplicar_quemadura(danio_quemadura, 1.0)

func _draw() -> void:
	var alpha = 1.0 - (timer / duracion)
	draw_circle(Vector2.ZERO, radio, Color(1.0, 0.3, 0.0, alpha * 0.35))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(1.0, 0.5, 0.0, alpha * 0.7), 3.0, true)
