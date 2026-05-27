extends CharacterBody2D

const MiniSenuelo = preload("res://scenes/jugador/MiniSenuelo.gd")

var nivel: int = 1
var duracion: float = 5.0
var timer_vida: float = 0.0
var timer_ataque: float = 0.0
var velocidad_deambular: float = 0.0
var timer_cambio_direccion: float = 0.0
var direccion_actual: Vector2 = Vector2.ZERO
var danio_explosion: float = 40.0
var vida: float = 80.0
var vida_maxima: float = 80.0
var jugador_ref: Node = null
var modo_explosion: bool = false

@onready var barra_vida = $BarraVida

func _ready() -> void:
	add_to_group("senuelo")

func inicializar(jugador: Node, nv: int) -> void:
	nivel = nv
	jugador_ref = jugador
	vida = jugador.vida_maxima
	vida_maxima = jugador.vida_maxima

	match nivel:
		1: duracion = 5.0
		2: duracion = 5.0
		3: duracion = 5.0
		4: duracion = 15.0
		5: duracion = 20.0
		6: duracion = 20.0

	if nivel >= 3:
		velocidad_deambular = 80.0

	match nivel:
		2: danio_explosion = 30.0
		3: danio_explosion = 40.0
		4: danio_explosion = 50.0
		5: danio_explosion = 60.0
		6: danio_explosion = 200.0

	if nivel < 3:
		call_deferred("_ocultar_barra")

func _ocultar_barra() -> void:
	if is_instance_valid(barra_vida):
		barra_vida.visible = false

func _physics_process(delta: float) -> void:
	timer_vida += delta
	if timer_vida >= duracion:
		_morir()
		return

	if nivel >= 3:
		_mover_inteligente(delta)
		move_and_slide()

	timer_ataque += delta
	var cadencia_actual = jugador_ref.cadencia if jugador_ref else 0.5
	if timer_ataque >= cadencia_actual:
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
		jugador_ref.danio_ataque,
		jugador_ref.penetracion_completos,
		jugador_ref.penetracion_parcial
	)

func recibir_danio(cantidad: float) -> void:
	if nivel < 3:
		return
	vida -= cantidad
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		_morir()

func _morir() -> void:
	if nivel >= 2:
		_explotar()
	if nivel == 6:
		_spawnear_minicajas()
	queue_free()

func _explotar() -> void:
	var radio = 120.0 if nivel < 6 else 220.0
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio:
			e.recibir_danio(danio_explosion)
			var dir = (e.global_position - global_position).normalized()
			if e.has_method("recibir_empuje"):
				e.recibir_empuje(dir * 400.0)

func _spawnear_minicajas() -> void:
	var offsets = [
		Vector2(0, -45),
		Vector2(-40, 30),
		Vector2(40, 30)
	]
	for i in 3:
		var mini = MiniSenuelo.new()
		mini.global_position = global_position + offsets[i]
		mini.jugador_ref = jugador_ref
		get_tree().current_scene.add_child(mini)

func _mover_inteligente(delta: float) -> void:
	if jugador_ref == null:
		return

	var tiempo_restante = duracion - timer_vida
	var viewport = get_viewport().get_visible_rect().size
	var rango_elastico = min(viewport.x, viewport.y) * 0.5

	if tiempo_restante <= 2.0 and nivel >= 2:
		if not modo_explosion:
			modo_explosion = true
		var objetivo = _encontrar_conglomerado()
		if objetivo != Vector2.ZERO:
			var dir = (objetivo - global_position).normalized()
			velocity = dir * velocidad_deambular * 3.0
		return

	var centro_masa = _calcular_centro_masa(200.0)
	timer_cambio_direccion -= delta
	if timer_cambio_direccion <= 0.0:
		direccion_actual = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		timer_cambio_direccion = randf_range(1.5, 3.0)

	var dir_base: Vector2
	if centro_masa != Vector2.ZERO:
		var dir_escape = (global_position - centro_masa).normalized()
		dir_base = (dir_escape * 0.7 + direccion_actual * 0.3).normalized()
	else:
		dir_base = direccion_actual

	var dist_jugador = global_position.distance_to(jugador_ref.global_position)
	var dir_final: Vector2
	if dist_jugador > rango_elastico:
		var peso_jugador = clamp((dist_jugador - rango_elastico) / rango_elastico, 0.0, 0.8)
		var dir_jugador = (jugador_ref.global_position - global_position).normalized()
		dir_final = (dir_base * (1.0 - peso_jugador) + dir_jugador * peso_jugador).normalized()
	else:
		dir_final = dir_base

	velocity = dir_final * velocidad_deambular

func _calcular_centro_masa(radio: float) -> Vector2:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var suma = Vector2.ZERO
	var conteo = 0
	for e in enemigos:
		if global_position.distance_to(e.global_position) <= radio:
			suma += e.global_position
			conteo += 1
	if conteo == 0:
		return Vector2.ZERO
	return suma / conteo

func _encontrar_conglomerado() -> Vector2:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	if enemigos.is_empty():
		return Vector2.ZERO
	var mejor_pos = Vector2.ZERO
	var mejor_conteo = 0
	for e in enemigos:
		var conteo = 0
		for e2 in enemigos:
			if e.global_position.distance_to(e2.global_position) <= 150.0:
				conteo += 1
		if conteo > mejor_conteo:
			mejor_conteo = conteo
			mejor_pos = e.global_position
	return mejor_pos
