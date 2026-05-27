extends Control

var progreso: float = 1.0
var color_arco: Color = Color(0.2, 1.0, 0.3)
var color_fondo: Color = Color(0.15, 0.15, 0.15, 0.6)
var grosor: float = 8.0

func _draw() -> void:
	var centro = size / 2
	var radio = min(size.x, size.y) / 2 - grosor

	# Fondo gris del arco
	draw_arc(centro, radio, -PI/2, -PI/2 + TAU, 64, color_fondo, grosor, true)

	# Arco de progreso
	if progreso > 0.0:
		var angulo_fin = -PI/2 + TAU * progreso
		draw_arc(centro, radio, -PI/2, angulo_fin, 64, color_arco, grosor, true)

func actualizar(p: float, c: Color) -> void:
	progreso = clamp(p, 0.0, 1.0)
	color_arco = c
	queue_redraw()
