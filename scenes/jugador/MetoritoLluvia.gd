extends Node2D

const CharcoFuego = preload("res://scenes/jugador/CharcoFuego.gd")

var objetivo: Vector2 = Vector2.ZERO
var velocidad: float = 500.0
var jugador_ref: Node = null
var danio: float = 30.0

func _process(delta: float) -> void:
	var dist = global_position.distance_to(objetivo)
	if dist < 10.0:
		_explotar()
		return
	var dir = (objetivo - global_position).normalized()
	global_position += dir * velocidad * delta
	queue_redraw()

func _explotar() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= 60.0:
			e.recibir_danio(danio)
	var charco = CharcoFuego.new()
	charco.global_position = global_position
	charco.radio = 45.0
	charco.duracion = 1.5
	charco.danio_quemadura = 1.5
	get_tree().current_scene.add_child(charco)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(0.8, 0.3, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.6, 0.1, 1.0))
