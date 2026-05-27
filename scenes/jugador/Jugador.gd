extends CharacterBody2D

var VELOCIDAD = 200.0
var vida: float = 100.0
var vida_maxima: float = 100.0
var danio_ataque: float = 25.0
var cadencia: float = 0.5
var timer_ataque: float = 0.0
var penetracion_completos: int = 0
var penetracion_parcial: float = 0.0

# Espada
var rango_espada: float = 70.0
var espada_knockback: float = 400.0

# Disparo (poder desbloqueable)
var disparo_nivel: int = 0

# Meteorito
var meteorito_nivel: int = 0
var meteorito_timer: float = 0.0

# Fuego
var fuego_nivel: int = 0
var fuego_timer: float = 0.0
var fuego_cooldown: float = 10.0

# Hielo
var hielo_nivel: int = 0
var hielo_timer: float = 0.0
var hielo_cooldown: float = 7.0

# Satelite
var satelite_nivel: int = 0
@export var escena_satelite: PackedScene

# Senuelo
var senuelo_nivel: int = 0
var senuelo_timer: float = 0.0
var senuelo_cooldown: float = 40.0
var senuelo_activo: bool = false
var senuelo_invulnerable: float = 0.0
@export var escena_senuelo: PackedScene

# Escudo
var escudo_nivel: int = 0
var escudo_golpes_max: int = 0
var escudo_golpes_actual: int = 0
var escudo_timer: float = 0.0
var escudo_roto: bool = false
var escudo_cooldown_roto: float = 30.0
var escudo_cooldown_parcial: float = 15.0
var escudo_radio_empuje: float = 150.0
var escudo_danio_ruptura: float = 60.0
var knockback_velocidad: Vector2 = Vector2.ZERO
var knockback_fuerza: float = 800.0

# Animacion
var _en_ataque: bool = false
var _en_hurt: bool = false

@export var escena_proyectil: PackedScene
@onready var barra_vida = $BarraVida
@onready var escudo_visual = $EscudoVisual
@onready var sprite = $Sprite
@onready var sonido_espada = $SonidoEspada
@onready var sonido_pasos = $SonidoPasos
@onready var sonido_danio = $SonidoDanio
@onready var sonido_muerte = $SonidoMuerte

func _ready() -> void:
	add_to_group("jugador")
	sprite.animation_finished.connect(_on_animacion_terminada)

func _on_animacion_terminada() -> void:
	if sprite.animation in ["attack", "hurt"]:
		_en_ataque = false
		_en_hurt = false

func _physics_process(delta: float) -> void:
	_mover(delta)
	_atacar(delta)
	_actualizar_escudo(delta)
	_actualizar_senuelo(delta)
	_actualizar_hielo(delta)
	_actualizar_fuego(delta)
	_actualizar_meteorito(delta)
	if OS.is_debug_build() and Input.is_action_just_pressed("click_derecho"):
		_lanzar_meteorito()

func _mover(delta: float) -> void:
	var direccion = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direccion.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direccion.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direccion.y -= 1
	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()
	if knockback_velocidad.length() > 1.0:
		knockback_velocidad *= 0.85
		var factor = clamp(1.0 - (knockback_velocidad.length() / 900.0), 0.3, 1.0)
		velocity = knockback_velocidad + (direccion * VELOCIDAD * factor)
	else:
		knockback_velocidad = Vector2.ZERO
		velocity = direccion * VELOCIDAD
	move_and_slide()

	var mouse_pos = get_global_mouse_position()
	sprite.flip_h = mouse_pos.x < global_position.x

	if not _en_ataque and not _en_hurt:
		if velocity.length() > 10.0:
			sprite.play("walk")
			if not sonido_pasos.playing:
				sonido_pasos.play()
		else:
			sprite.play("idle")
			sonido_pasos.stop()

func _atacar(delta: float) -> void:
	timer_ataque += delta
	if timer_ataque < cadencia:
		return
	if _en_ataque:
		return
	if _en_hurt:
		return
	if not Input.is_action_just_pressed("click_izquierdo"):
		return
	timer_ataque = 0.0

	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var mas_cercano = null
	var dist_min = INF
	for e in enemigos:
		var d = global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			mas_cercano = e

	if mas_cercano != null and dist_min <= rango_espada:
		_espadazo()
	elif disparo_nivel >= 1 and mas_cercano != null and escena_proyectil != null:
		var pos_mouse = get_global_mouse_position()
		var direccion = (pos_mouse - global_position).normalized()
		var proyectil = escena_proyectil.instantiate()
		get_tree().current_scene.add_child(proyectil)
		proyectil.inicializar(global_position, direccion, danio_ataque, penetracion_completos, penetracion_parcial)
	else:
		_espadazo()

func _espadazo() -> void:
	_en_ataque = true
	sprite.play("attack")

	var pos_mouse = get_global_mouse_position()
	var dir_mouse = (pos_mouse - global_position).normalized()

	await get_tree().create_timer(0.15).timeout

	sonido_espada.play()
	_mostrar_arco_espada(dir_mouse)

	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		var dist = global_position.distance_to(e.global_position)
		if dist <= rango_espada:
			var dir_enemigo = (e.global_position - global_position).normalized()
			var angulo = rad_to_deg(dir_mouse.angle_to(dir_enemigo))
			if abs(angulo) <= 60.0:
				e.recibir_danio(danio_ataque)
				if e.has_method("recibir_empuje"):
					e.recibir_empuje((e.global_position - global_position).normalized() * espada_knockback)

# Variables para el arco visual de la espada
var _arco_timer: float = 0.0
var _arco_duracion: float = 0.15
var _arco_activo: bool = false
var _arco_direccion: Vector2 = Vector2.RIGHT

func _mostrar_arco_espada(direccion: Vector2) -> void:
	_arco_direccion = direccion
	_arco_timer = 0.0
	_arco_activo = true
	queue_redraw()

func _process(delta: float) -> void:
	if _arco_activo:
		_arco_timer += delta
		queue_redraw()
		if _arco_timer >= _arco_duracion:
			_arco_activo = false
			queue_redraw()

func aplicar_knockback(origen: Vector2) -> void:
	knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza

func recibir_danio(cantidad: float, origen: Vector2 = Vector2.ZERO) -> void:
	if senuelo_invulnerable > 0.0:
		return
	if escudo_absorber_golpe():
		return
	vida -= cantidad
	if origen != Vector2.ZERO:
		knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza

	_en_hurt = true
	_en_ataque = false
	sonido_pasos.stop()
	sonido_danio.play()
	sprite.play("hurt")

	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		sonido_muerte.play()
		sprite.play("death")
		await sprite.animation_finished
		EventBus.jugador_murio.emit()
		queue_free()

func agregar_xp(cantidad: float) -> void:
	EstadoJuego.agregar_xp(cantidad)

func _actualizar_escudo(delta: float) -> void:
	if escudo_nivel == 0:
		return
	if escudo_golpes_actual < escudo_golpes_max:
		escudo_timer -= delta
		if escudo_timer <= 0.0:
			escudo_golpes_actual = escudo_golpes_max
			escudo_roto = false
	var duracion = escudo_cooldown_roto if escudo_roto else escudo_cooldown_parcial
	escudo_visual.actualizar(escudo_golpes_actual, escudo_golpes_max, escudo_timer, duracion, escudo_roto)

func escudo_absorber_golpe() -> bool:
	if escudo_nivel == 0 or escudo_golpes_actual <= 0:
		return false

	escudo_golpes_actual -= 1

	if escudo_nivel >= 2:
		_escudo_empujar_enemigos(false)

	if escudo_golpes_actual <= 0:
		escudo_roto = true
		escudo_timer = escudo_cooldown_roto
		if escudo_nivel >= 3:
			_escudo_empujar_enemigos(true)
	else:
		escudo_timer = escudo_cooldown_parcial

	return true

func _escudo_empujar_enemigos(ruptura: bool) -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for enemigo in enemigos:
		var distancia = global_position.distance_to(enemigo.global_position)
		if distancia <= escudo_radio_empuje:
			var direccion = (enemigo.global_position - global_position).normalized()
			if ruptura:
				enemigo.recibir_danio(escudo_danio_ruptura)
			if enemigo.has_method("recibir_empuje"):
				enemigo.recibir_empuje(direccion * 500.0)

func _actualizar_senuelo(delta: float) -> void:
	if senuelo_nivel == 0:
		return
	if senuelo_invulnerable > 0.0:
		senuelo_invulnerable -= delta
		modulate.a = 0.4
	else:
		modulate.a = 1.0
	if senuelo_activo:
		return
	senuelo_timer += delta
	if senuelo_timer >= senuelo_cooldown:
		senuelo_timer = 0.0
		_invocar_senuelo()

func _invocar_senuelo() -> void:
	if escena_senuelo == null:
		return
	senuelo_activo = true
	var s = escena_senuelo.instantiate()
	s.global_position = global_position
	s.inicializar(self, senuelo_nivel)
	get_tree().current_scene.add_child(s)
	s.tree_exited.connect(_on_senuelo_muerto)

	var dir = velocity.normalized() if velocity.length() > 10.0 else Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	knockback_velocidad = dir * 900.0
	senuelo_invulnerable = 0.5

func _on_senuelo_muerto() -> void:
	senuelo_activo = false

func _actualizar_hielo(delta: float) -> void:
	if hielo_nivel == 0:
		return
	hielo_timer += delta
	if hielo_timer >= hielo_cooldown:
		hielo_timer = 0.0
		_lanzar_explosion_hielo()

func _lanzar_explosion_hielo() -> void:
	var explosion = preload("res://scenes/jugador/ExplosionHielo.gd").new()
	get_tree().current_scene.add_child(explosion)
	explosion.inicializar(self, hielo_nivel)

func _actualizar_fuego(delta: float) -> void:
	if fuego_nivel == 0:
		return
	fuego_timer += delta
	var cooldown = 13.0 if fuego_nivel >= 5 else 10.0
	if fuego_timer >= cooldown:
		fuego_timer = 0.0
		_lanzar_bola_fuego()

func _lanzar_bola_fuego() -> void:
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
	var bala = preload("res://scenes/jugador/BalaFuego.gd").new()
	get_tree().current_scene.add_child(bala)
	bala.inicializar(self, fuego_nivel, mas_cercano)

func _actualizar_meteorito(delta: float) -> void:
	if meteorito_nivel == 0:
		return
	var cooldown = 60.0 if meteorito_nivel >= 6 else (40.0 if meteorito_nivel >= 2 else 20.0)
	meteorito_timer += delta
	if meteorito_timer >= cooldown:
		meteorito_timer = 0.0
		_lanzar_meteorito()

func _lanzar_meteorito() -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	if enemigos.is_empty():
		return
	var mejor_pos = global_position
	var mejor_conteo = 0
	for e in enemigos:
		var conteo = 0
		for e2 in enemigos:
			if e.global_position.distance_to(e2.global_position) <= 100.0:
				conteo += 1
		if conteo > mejor_conteo:
			mejor_conteo = conteo
			mejor_pos = e.global_position
	var meteorito = preload("res://scenes/jugador/Meteorito.gd").new()
	get_tree().current_scene.add_child(meteorito)
	meteorito.inicializar(self, meteorito_nivel, mejor_pos)
