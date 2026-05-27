extends Node2D

var direccion: Vector2 = Vector2.ZERO
var velocidad: float = 180.0
var distancia_max: float = 140.0
var distancia_recorrida: float = 0.0
var nivel: int = 2
var danio: float = 20.0
var duracion: float = 8.0
var timer: float = 0.0
var tick_quemadura: float = 0.0
var enemigos_quemados: Array = []

func _process(delta: float) -> void:
	timer += delta
	if timer >= duracion:
		queue_free()
		return

	if distancia_recorrida < distancia_max:
		var mov = direccion * velocidad * delta
		global_position += mov
		distancia_recorrida += mov.length()

	# Quemar enemigos cercanos cada 0.5s
	tick_quemadura += delta
	if tick_quemadura >= 0.5:
		tick_quemadura = 0.0
		_quemar_cercanos()

	queue_redraw()

func _quemar_cercanos() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) < 16.0:
			e.recibir_danio(danio)
			if e.has_method("aplicar_quemadura"):
				var duracion_quema = 6.0 if nivel >= 3 else 3.0
				e.aplicar_quemadura(4.0, duracion_quema)

func _draw() -> void:
	var alpha = 1.0 - (timer / duracion)
	draw_circle(Vector2.ZERO, 6.0, Color(0.9, 0.4, 0.0, alpha))
