extends CharacterBody2D

var velocidad: float = 90.0
var danio_normal: float = 20.0
var danio_spin: float = 30.0
var danio_salto_aoe: float = 45.0
var danio_salto_swing: float = 25.0
var vida: float = 300.0
var vida_maxima: float = 300.0
var xp_al_morir: float = 80.0
var jugador: Node2D = null

var rango_ataque_normal: float = 55.0
var radio_aoe_salto: float = 100.0
var timer_ataque_normal: float = 0.0
var cadencia_normal: float = 1.5
var timer_spin: float = 0.0
var cooldown_spin: float = 8.0
var timer_salto: float = 0.0
var cooldown_salto: float = 15.0

var empuje: Vector2 = Vector2.ZERO
var timer_congelado: float = 0.0
var quemadura_danio: float = 0.0
var quemadura_timer: float = 0.0
var quemadura_tick: float = 0.0

var velocidad_dash: float = 900.0

enum Estado { NORMAL, ATACANDO_NORMAL, SPIN_PREP, SPINNING, SALTO_PREP, SALTANDO, ATERRIZANDO }
var estado: Estado = Estado.NORMAL
var pos_objetivo_dash: Vector2 = Vector2.ZERO
var _muriendo: bool = false
var _en_hurt: bool = false

@onready var barra_vida = $BarraVida
@onready var sprite = $Sprite

func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("orco_elite")
	var fase = EstadoJuego.get_fase_actual()
	var nivel = EstadoJuego.nivel_jugador
	var escala = 1.0 + (fase - 1) * 0.3 + nivel * 0.05
	danio_normal *= escala
	danio_spin *= escala
	danio_salto_aoe *= escala
	danio_salto_swing *= escala
	vida = 300.0 * escala
	vida_maxima = vida
	xp_al_morir = 80.0 * escala
	sprite.scale = Vector2(3.0, 3.0)
	sprite.play("idle")
	timer_spin = cooldown_spin * 0.5
	timer_salto = cooldown_salto * 0.3

func _physics_process(delta: float) -> void:
	if _muriendo:
		return
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return

	_actualizar_quemadura(delta)

	match estado:
		Estado.NORMAL:
			_estado_normal(delta)
		Estado.SPINNING:
			_estado_spinning(delta)

func _actualizar_quemadura(delta: float) -> void:
	if quemadura_timer <= 0.0:
		return
	quemadura_timer -= delta
	quemadura_tick += delta
	if quemadura_tick >= 0.5:
		quemadura_tick = 0.0
		vida -= quemadura_danio
		barra_vida.actualizar(vida, vida_maxima)
		if vida <= 0:
			_morir()

func _estado_normal(delta: float) -> void:
	var direccion = (jugador.global_position - global_position).normalized()
	sprite.flip_h = direccion.x < 0

	if empuje.length() > 10.0:
		empuje = empuje.lerp(Vector2.ZERO, 0.15)
		velocity = empuje
	elif timer_congelado > 0.0:
		timer_congelado -= delta
		velocity = Vector2.ZERO
		sprite.play("idle")
	else:
		velocity = direccion * velocidad
		if not _en_hurt:
			sprite.play("walk")

	move_and_slide()

	var distancia = global_position.distance_to(jugador.global_position)

	timer_spin += delta
	timer_salto += delta
	timer_ataque_normal += delta

	if timer_salto >= cooldown_salto and distancia < 400.0:
		timer_salto = 0.0
		_iniciar_salto()
	elif timer_spin >= cooldown_spin and distancia < 350.0:
		timer_spin = 0.0
		_iniciar_spin()
	elif timer_ataque_normal >= cadencia_normal and distancia < rango_ataque_normal:
		timer_ataque_normal = 0.0
		_ataque_normal()

func _estado_spinning(delta: float) -> void:
	var direccion = (pos_objetivo_dash - global_position).normalized()
	sprite.flip_h = direccion.x < 0
	velocity = direccion * velocidad_dash
	move_and_slide()

	if global_position.distance_to(jugador.global_position) < 50.0:
		jugador.recibir_danio(danio_spin, global_position)
		jugador.aplicar_knockback(global_position)

	if global_position.distance_to(pos_objetivo_dash) < 30.0:
		velocity = Vector2.ZERO
		estado = Estado.NORMAL

func _ataque_normal() -> void:
	if _en_hurt or estado != Estado.NORMAL:
		return
	estado = Estado.ATACANDO_NORMAL
	sprite.speed_scale = 1.8
	sprite.play("attack01")
	await get_tree().create_timer(0.15).timeout
	if not _muriendo and jugador != null:
		if global_position.distance_to(jugador.global_position) < rango_ataque_normal:
			jugador.recibir_danio(danio_normal, global_position)
	await sprite.animation_finished
	sprite.speed_scale = 1.0
	estado = Estado.NORMAL

func _iniciar_spin() -> void:
	if _en_hurt or estado != Estado.NORMAL:
		return
	estado = Estado.SPIN_PREP
	velocity = Vector2.ZERO
	pos_objetivo_dash = jugador.global_position
	sprite.speed_scale = 1.0
	sprite.play("attack02")
	await get_tree().create_timer(0.4).timeout
	if _muriendo or estado != Estado.SPIN_PREP:
		return
	estado = Estado.SPINNING
	await get_tree().create_timer(2.0).timeout
	if not _muriendo and estado == Estado.SPINNING:
		estado = Estado.NORMAL
		velocity = Vector2.ZERO

func _iniciar_salto() -> void:
	if _en_hurt or estado != Estado.NORMAL:
		return
	estado = Estado.SALTO_PREP
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	sprite.play("attack03")
	await get_tree().create_timer(0.5).timeout
	if _muriendo or estado != Estado.SALTO_PREP:
		estado = Estado.NORMAL
		return

	var destino = jugador.global_position
	estado = Estado.SALTANDO

	# Moverse fisicamente hasta el destino
	var tween = create_tween()
	tween.tween_property(self, "global_position", destino, 0.5)
	await tween.finished

	if _muriendo:
		estado = Estado.NORMAL
		return

	estado = Estado.ATERRIZANDO
	sprite.play("attack03")
	await get_tree().create_timer(0.15).timeout

	if not _muriendo:
		_dano_aoe(global_position)
		await get_tree().create_timer(0.1).timeout
		if jugador != null and global_position.distance_to(jugador.global_position) < rango_ataque_normal * 1.5:
			jugador.recibir_danio(danio_salto_swing, global_position)
			jugador.aplicar_knockback(global_position)

	# Timer fijo en vez de animation_finished para no quedarse pegado
	await get_tree().create_timer(0.4).timeout
	estado = Estado.NORMAL

func _dano_aoe(centro: Vector2) -> void:
	var jugadores = get_tree().get_nodes_in_group("jugador")
	for obj in jugadores:
		if centro.distance_to(obj.global_position) <= radio_aoe_salto:
			obj.recibir_danio(danio_salto_aoe, centro)
			obj.aplicar_knockback(centro)

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
	if estado in [Estado.SPINNING, Estado.SALTANDO, Estado.ATERRIZANDO]:
		return
	_en_hurt = true
	estado = Estado.NORMAL
	sprite.speed_scale = 1.0
	sprite.play("hurt")
	await sprite.animation_finished
	_en_hurt = false

func _morir() -> void:
	if _muriendo:
		return
	_muriendo = true
	estado = Estado.NORMAL
	_en_hurt = false
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	sprite.play("death")
	await sprite.animation_finished
	var jugador_node = get_tree().get_first_node_in_group("jugador")
	if jugador_node:
		jugador_node.agregar_xp(xp_al_morir)
	queue_free()

func congelar(duracion: float) -> void:
	timer_congelado = duracion

func aplicar_quemadura(danio_por_tick: float, duracion: float) -> void:
	quemadura_danio = danio_por_tick
	quemadura_timer = max(quemadura_timer, duracion)
