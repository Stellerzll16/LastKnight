extends Node2D

var radio: float = 28.0
var grosor: float = 3.0
var visible_escudo: bool = false
var color_actual: Color = Color(0.2, 1.0, 0.3)

var COLOR_VERDE    = Color(0.2, 1.0, 0.3, 0.85)
var COLOR_AMARILLO = Color(1.0, 0.85, 0.0, 0.85)
var COLOR_ROJO     = Color(1.0, 0.2, 0.2, 0.85)
var COLOR_GRIS     = Color(0.4, 0.4, 0.4, 0.5)

func _draw() -> void:
	if not visible_escudo:
		return
	draw_arc(Vector2.ZERO, radio, 0, TAU, 64, color_actual, grosor, true)

func actualizar(golpes_actual: int, golpes_max: int, timer: float, duracion: float, roto: bool) -> void:
	visible_escudo = golpes_max > 0

	if golpes_actual == 0:
		color_actual = COLOR_GRIS
	elif golpes_actual == 1:
		color_actual = COLOR_ROJO
	elif golpes_actual == 2:
		color_actual = COLOR_AMARILLO
	else:
		color_actual = COLOR_VERDE

	queue_redraw()
