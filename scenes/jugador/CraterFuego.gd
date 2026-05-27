extends Node2D

var radio: float = 130.0
var duracion: float = 10.0
var timer: float = 0.0
var danio_quemadura: float = 8.0
var ralentizar: bool = false
var tick_timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	tick_timer += delta
	if tick_timer >= 0.5:
		tick_timer = 0.0
		_aplicar_efecto()
	queue_redraw()
	if timer >= duracion:
		queue_free()

func _aplicar_efecto() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio:
			if e.has_method("aplicar_quemadura"):
				e.aplicar_quemadura(danio_quemadura, 1.0)
			if ralentizar and e.has_method("ralentizar"):
				e.ralentizar(0.6)

func _draw() -> void:
	var alpha = (1.0 - timer / duracion) * 0.45
	draw_circle(Vector2.ZERO, radio, Color(0.9, 0.2, 0.0, alpha))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(1.0, 0.5, 0.0, alpha * 1.5), 4.0, true)
