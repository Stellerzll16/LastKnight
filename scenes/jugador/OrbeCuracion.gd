extends Node2D

var jugador_ref: Node = null
var curacion_pct: float = 0.15
var radio_recogida: float = 40.0
var duracion: float = 15.0
var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= duracion:
		queue_free()
		return
	if jugador_ref and global_position.distance_to(jugador_ref.global_position) <= radio_recogida:
		var curacion = jugador_ref.vida_maxima * curacion_pct
		jugador_ref.vida = min(jugador_ref.vida + curacion, jugador_ref.vida_maxima)
		jugador_ref.barra_vida.actualizar(jugador_ref.vida, jugador_ref.vida_maxima)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha = 1.0 - (timer / duracion)
	draw_circle(Vector2.ZERO, 10.0, Color(0.2, 1.0, 0.4, alpha))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 1.0, alpha))
