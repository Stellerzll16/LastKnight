extends CharacterBody2D

var velocidad: float = 60.0
var danio: float = 10.0
var vida: float = 60.0
var vida_maxima: float = 60.0
var xp_al_morir: float = 10.0
var jugador: Node2D = null
var timer_danio: float = 0.0
var cadencia_danio: float = 1.0
var rango_ataque: float = 32.0
var knockback_ataque: float = 0.0
var delay_impacto: float = 0.18

var empuje: Vector2 = Vector2.ZERO
var timer_congelado: float = 0.0
var timer_ralentizado: float = 0.0
var factor_ralentizado: float = 0.3
var quemadura_danio: float = 0.0
var quemadura_timer: float = 0.0
var quemadura_tick: float = 0.0

# Animacion
var _muriendo: bool = false
var _atacando: bool = false
var _en_hurt: bool = false
var _ataque_cancelado: bool = false

# Slime grande
var es_grande: bool = false
var animacion_ataque: String = "attack"

@onready var barra_vida = $BarraVida
@onready var sprite = $Sprite

func _ready() -> void:
	add_to_group("enemigos")
	var fase = EstadoJuego.get_fase_actual()
	var nivel = EstadoJuego.nivel_jugador
	var escala = 1.0 + (fase - 1) * 0.35 + nivel * 0.06
	velocidad = 60.0 * escala
	danio = 10.0 * escala
	vida = 60.0 * escala
	vida_maxima = vida
	xp_al_morir = 10.0 * escala
	sprite.play("idle")

func hacer_grande() -> void:
	es_grande = true
	animacion_ataque = "attack02"
	vida *= 1.5
	vida_maxima = vida
	danio *= 1.8
	xp_al_morir *= 2.0
	rango_ataque = 100.0
	knockback_ataque = 600.0
	delay_impacto = 0.45
	scale = Vector2(1.6, 1.6)

func _physics_process(delta: float) -> void:
	if _muriendo:
		return
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return

	var objetivo = _obtener_objetivo()
	var direccion = (objetivo.global_position - global_position).normalized()

	sprite.flip_h = direccion.x < 0

	if quemadura_timer > 0.0:
		quemadura_timer -= delta
		quemadura_tick += delta
		if quemadura_tick >= 0.5:
			quemadura_tick = 0.0
			vida -= quemadura_danio
			barra_vida.actualizar(vida, vida_maxima)
			if vida <= 0:
				_morir()
				return

	if timer_congelado > 0.0:
		timer_congelado -= delta
		velocity = Vector2.ZERO
		_play_base("idle")
	elif timer_ralentizado > 0.0:
		timer_ralentizado -= delta
		if empuje.length() > 10.0:
			empuje = empuje.lerp(Vector2.ZERO, 0.15)
			velocity = empuje
		else:
			velocity = direccion * velocidad * factor_ralentizado
		_play_base("walk")
	elif empuje.length() > 10.0:
		empuje = empuje.lerp(Vector2.ZERO, 0.15)
		velocity = empuje
		_play_base("walk")
	else:
		empuje = Vector2.ZERO
		if _atacando:
			velocity = Vector2.ZERO
		else:
			velocity = direccion * velocidad
		_play_base("walk")

	move_and_slide()

	var senuelo = get_tree().get_first_node_in_group("senuelo")
	if senuelo != null:
		var dist_senuelo = global_position.distance_to(senuelo.global_position)
		if dist_senuelo < 32.0:
			senuelo.recibir_danio(danio)

	timer_danio += delta
	if timer_danio >= cadencia_danio:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia < rango_ataque and not _atacando:
			timer_danio = 0.0
			_atacar()

func _play_base(anim: String) -> void:
	if _en_hurt or _atacando:
		return
	sprite.play(anim)

func _atacar() -> void:
	if _atacando or _en_hurt:
		return
	_atacando = true
	_ataque_cancelado = false
	sprite.speed_scale = 2.0
	sprite.play(animacion_ataque)

	await get_tree().create_timer(delay_impacto).timeout

	if not _muriendo and not _ataque_cancelado and jugador != null:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia < rango_ataque:
			jugador.recibir_danio(danio, global_position)
			if knockback_ataque > 0.0:
				jugador.aplicar_knockback(global_position)

	await sprite.animation_finished
	sprite.speed_scale = 1.0
	_atacando = false
	_ataque_cancelado = false

func recibir_empuje(fuerza: Vector2) -> void:
	empuje = fuerza

func recibir_danio(cantidad: float) -> void:
	if _muriendo:
		return
	vida -= cantidad
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		_morir()
		return
	_en_hurt = true
	_atacando = false
	_ataque_cancelado = true
	sprite.speed_scale = 1.0
	sprite.play("hurt")
	await sprite.animation_finished
	_en_hurt = false

func _morir() -> void:
	if _muriendo:
		return
	_muriendo = true
	_en_hurt = false
	_atacando = false
	_ataque_cancelado = true
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	sprite.play("death")
	await sprite.animation_finished
	var jugador_node = get_tree().get_first_node_in_group("jugador")
	if jugador_node:
		jugador_node.agregar_xp(xp_al_morir)
	EstadoJuego.enemigos_eliminados += 1
	queue_free()

func _obtener_objetivo() -> Node:
	var senuelo = get_tree().get_first_node_in_group("senuelo")
	if senuelo != null:
		return senuelo
	return jugador

func congelar(duracion: float) -> void:
	timer_congelado = duracion

func ralentizar(factor: float) -> void:
	if timer_congelado <= 0.0:
		timer_ralentizado = 0.5
		factor_ralentizado = factor

func aplicar_quemadura(danio_por_tick: float, duracion: float) -> void:
	quemadura_danio = danio_por_tick
	quemadura_timer = max(quemadura_timer, duracion)
