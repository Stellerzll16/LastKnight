extends Node2D

var vida: float = 20.0
var timer_ataque: float = 0.0
var timer_vida: float = 0.0
var duracion: float = 5.0
var jugador_ref: Node = null

func _ready() -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(10, 10)
	rect.position = Vector2(-5, -5)
	rect.color = Color(1.0, 0.9, 0.2)
	add_child(rect)

func _process(delta: float) -> void:
	timer_vida += delta
	if timer_vida >= duracion:
		queue_free()
		return
	if jugador_ref == null:
		return
	timer_ataque += delta
	if timer_ataque >= jugador_ref.cadencia * 1.5:
		_atacar()
		timer_ataque = 0.0

func _atacar() -> void:
	if jugador_ref == null or jugador_ref.escena_proyectil == null:
		return
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	if enemigos.is_empty():
		return
	var mas_cercano = null
	var dist_min = INF
	for e in enemigos:
		var d = global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			mas_cercano = e
	if mas_cercano == null:
		return
	var dir = (mas_cercano.global_position - global_position).normalized()
	var proyectil = jugador_ref.escena_proyectil.instantiate()
	get_tree().current_scene.add_child(proyectil)
	proyectil.inicializar(
		global_position,
		dir,
		jugador_ref.danio_ataque * 0.3,
		jugador_ref.penetracion_completos,
		jugador_ref.penetracion_parcial
	)

func recibir_danio(cantidad: float) -> void:
	vida -= cantidad
	if vida <= 0:
		queue_free()
