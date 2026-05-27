extends Node

@export var escena_enemigo_basico: PackedScene
@export var escena_enemigo_rapido: PackedScene
@export var escena_enemigo_tanque: PackedScene
@export var escena_enemigo_especial: PackedScene
@export var escena_enemigo_orco: PackedScene
@export var escena_enemigo_orco_elite: PackedScene

var tiempo_entre_spawns: float = 2.0
var ventajas_disponibles: Array = []
var debug_forzar_tipo: String = "meteorito"
var timer_spawn: float = 0.0
var timer_autoguardado: float = 0.0
const INTERVALO_AUTOGUARDADO: float = 60.0
var direccion_jugador: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO

var contador_slimes_basicos: int = 0
const SLIMES_PARA_GRANDE: int = 4

var orco_elite_spawneado: bool = false

@onready var pantalla_preguntas = $PantallaPreguntas
@onready var pantalla_poderes = $PantallaSeleccionPoder
@onready var menu_pausa = $MenuPausa

var ventajas = [
	{"nombre": "🏹 Misil Mágico", "descripcion": "Desbloquea ataque a distancia", "tipo": "disparo", "valor": 1},
	{"nombre": "⚔️ Daño+", "descripcion": "+25% daño", "tipo": "danio", "valor": 0.25},
	{"nombre": "💨 Velocidad+", "descripcion": "+20% velocidad", "tipo": "velocidad", "valor": 0.20},
	{"nombre": "🔥 Cadencia+", "descripcion": "-20% tiempo entre ataques", "tipo": "cadencia", "valor": -0.20},
	{"nombre": "❤️ Vida+", "descripcion": "+30 vida máxima", "tipo": "vida", "valor": 30.0},
	{"nombre": "🔱 Penetración+", "descripcion": "", "tipo": "penetracion", "valor": 1},
	{"nombre": "🛡️ Escudo+", "descripcion": "", "tipo": "escudo", "valor": 1},
	{"nombre": "🪄 Señuelo+", "descripcion": "", "tipo": "senuelo", "valor": 1},
	{"nombre": "🔵 Satélite+", "descripcion": "", "tipo": "satelite", "valor": 1},
	{"nombre": "❄️ Hielo+", "descripcion": "", "tipo": "hielo", "valor": 1},
	{"nombre": "🔥 Bola de Fuego+", "descripcion": "", "tipo": "fuego", "valor": 1},
	{"nombre": "☄️ Meteorito+", "descripcion": "", "tipo": "meteorito", "valor": 1},
]

var desventajas = [
	{"nombre": "🐢 Lento", "descripcion": "-20% velocidad", "tipo": "velocidad", "valor": -0.20},
	{"nombre": "💔 Daño-", "descripcion": "-25% daño", "tipo": "danio", "valor": -0.25},
	{"nombre": "🐌 Cadencia-", "descripcion": "+30% tiempo entre ataques", "tipo": "cadencia", "valor": 0.30},
]

func _ready() -> void:
	EventBus.jugador_subio_nivel.connect(_on_jugador_subio_nivel)
	EventBus.jugador_murio.connect(_on_jugador_murio)
	pantalla_preguntas.pregunta_respondida.connect(_on_pregunta_respondida)
	pantalla_poderes.poder_elegido.connect(_on_poder_elegido)

func _on_jugador_murio() -> void:
	ConfiguracionJuego.borrar_partida()

func _process(delta: float) -> void:
	if OS.is_debug_build() and Input.is_action_just_pressed("ui_page_down"):
		EstadoJuego.tiempo_transcurrido += 300.0
	if OS.is_debug_build() and Input.is_action_just_pressed("ui_page_up"):
		EstadoJuego.agregar_xp(EstadoJuego.xp_para_siguiente_nivel)
	if OS.is_debug_build() and Input.is_key_pressed(KEY_0):
		for e in get_tree().get_nodes_in_group("enemigos"):
			if e.has_method("recibir_danio"):
				e.recibir_danio(99999.0)
	_actualizar_direccion_jugador()
	_actualizar_dificultad()
	_verificar_spawn_orco_elite()
	timer_autoguardado += delta
	if timer_autoguardado >= INTERVALO_AUTOGUARDADO:
		timer_autoguardado = 0.0
		ConfiguracionJuego.guardar_partida()
	timer_spawn += delta
	if timer_spawn >= tiempo_entre_spawns:
		timer_spawn = 0.0
		_spawnear_enemigo()

func _verificar_spawn_orco_elite() -> void:
	var tiempo = EstadoJuego.tiempo_transcurrido
	if tiempo < 60.0:
		return
	if escena_enemigo_orco_elite == null:
		return
	# Spawnear si no hay ninguno vivo
	var elites = get_tree().get_nodes_in_group("orco_elite")
	if elites.is_empty():
		_spawnear_en_borde(escena_enemigo_orco_elite)

func _actualizar_dificultad() -> void:
	var fase = EstadoJuego.get_fase_actual()
	match fase:
		1: tiempo_entre_spawns = 1.5
		2: tiempo_entre_spawns = 1.4
		3: tiempo_entre_spawns = 0.9
		4: tiempo_entre_spawns = 0.5

func _elegir_escena_enemigo() -> PackedScene:
	var fase = EstadoJuego.get_fase_actual()
	var tiempo = EstadoJuego.tiempo_transcurrido
	var opciones: Array = []

	if tiempo < 45.0:
		opciones = [escena_enemigo_basico]
	elif tiempo < 90.0:
		opciones = [escena_enemigo_orco]
	else:
		match fase:
			1:
				opciones = [
					escena_enemigo_orco, escena_enemigo_orco,
					escena_enemigo_rapido
				]
			2:
				opciones = [
					escena_enemigo_orco, escena_enemigo_orco,
					escena_enemigo_rapido, escena_enemigo_tanque
				]
			3:
				opciones = [
					escena_enemigo_orco, escena_enemigo_rapido,
					escena_enemigo_tanque, escena_enemigo_especial
				]
			4:
				opciones = [
					escena_enemigo_orco, escena_enemigo_rapido,
					escena_enemigo_tanque, escena_enemigo_especial,
					escena_enemigo_especial
				]

	return opciones[randi() % opciones.size()]

func _spawnear_enemigo() -> void:
	var escena = _elegir_escena_enemigo()
	if escena == null:
		return
	var enemigo = _spawnear_en_borde(escena)
	if enemigo == null:
		return

	if escena == escena_enemigo_basico:
		contador_slimes_basicos += 1
		if contador_slimes_basicos >= SLIMES_PARA_GRANDE:
			contador_slimes_basicos = 0
			if enemigo.has_method("hacer_grande"):
				enemigo.hacer_grande()

func _spawnear_en_borde(escena: PackedScene) -> Node:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return null
	var tamano_pantalla = get_viewport().get_visible_rect().size
	var mitad_w = tamano_pantalla.x / 2.0 + 80.0
	var mitad_h = tamano_pantalla.y / 2.0 + 80.0
	var angulo_base: float
	if direccion_jugador.length() > 0.1 and randf() < 0.7:
		angulo_base = direccion_jugador.angle() + randf_range(-0.6, 0.6)
	else:
		angulo_base = randf() * TAU
	var lado = _angulo_a_lado(angulo_base)
	var pos = Vector2.ZERO
	match lado:
		0: pos = Vector2(randf_range(-mitad_w, mitad_w), -mitad_h)
		1: pos = Vector2(randf_range(-mitad_w, mitad_w), mitad_h)
		2: pos = Vector2(-mitad_w, randf_range(-mitad_h, mitad_h))
		3: pos = Vector2(mitad_w, randf_range(-mitad_h, mitad_h))
	var enemigo = escena.instantiate()
	enemigo.global_position = jugador.global_position + pos
	get_tree().current_scene.add_child(enemigo)
	return enemigo

func _angulo_a_lado(angulo: float) -> int:
	var grados = fmod(rad_to_deg(angulo) + 360.0, 360.0)
	if grados < 45 or grados >= 315: return 3
	elif grados < 135: return 1
	elif grados < 225: return 2
	else: return 0

func _on_jugador_subio_nivel() -> void:
	var fase = EstadoJuego.get_fase_actual()
	var pregunta = GestorPreguntas.obtener_pregunta(fase)
	if pregunta.is_empty():
		return
	pantalla_preguntas.mostrar_pregunta(pregunta)

func _on_pregunta_respondida(correcta: bool) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		ventajas_disponibles = ventajas.filter(func(p):
			if p.tipo == "escudo" and jugador.escudo_nivel >= 6: return false
			if p.tipo == "senuelo" and jugador.senuelo_nivel >= 6: return false
			if p.tipo == "satelite" and jugador.satelite_nivel >= 6: return false
			if p.tipo == "hielo" and jugador.hielo_nivel >= 6: return false
			if p.tipo == "fuego" and jugador.fuego_nivel >= 6: return false
			if p.tipo == "meteorito" and jugador.meteorito_nivel >= 6: return false
			return true
		)
		var siguiente = jugador.penetracion_parcial + 0.25
		var porcentaje: int
		if siguiente >= 1.0:
			porcentaje = 100
		else:
			porcentaje = int(siguiente * 100)
		var num_enemigo = jugador.penetracion_completos + 1
		for poder in ventajas:
			if poder.tipo == "penetracion":
				poder.descripcion = "Daño al %dº enemigo: %d%%" % [num_enemigo, porcentaje]
			elif poder.tipo == "senuelo":
				var nv = jugador.senuelo_nivel
				poder.nombre = "🪄 Señuelo Nv.%d" % (nv + 1)
				if nv == 0: poder.descripcion = "Invoca senuelo cada 40s, dura 5 seg"
				elif nv == 1: poder.descripcion = "Explota al morir"
				elif nv == 2: poder.descripcion = "Se mueve solo"
				elif nv == 3: poder.descripcion = "Dura 15 seg"
				elif nv == 4: poder.descripcion = "Dura 20 seg"
				else: poder.descripcion = "Explosion masiva + 3 minicajas"
				if nv >= 6:
					poder.nombre = "🪄 Señuelo MAX"
					poder.descripcion = "Ya esta al maximo nivel"
			elif poder.tipo == "hielo":
				var nv = jugador.hielo_nivel
				var radios = [80, 110, 140, 175, 210, 250]
				var durs = [1.0, 1.6, 2.2, 2.8, 3.4, 4.0]
				var danios = [10, 16, 22, 28, 34, 40]
				poder.nombre = "❄️ Hielo Nv.%d" % (nv + 1)
				poder.descripcion = "Radio %dpx, %s daño, congela %ss" % [radios[nv], danios[nv], durs[nv]]
				if nv >= 6: poder.descripcion = "Ya esta al maximo"
			elif poder.tipo == "meteorito":
				var nv = jugador.meteorito_nivel
				poder.nombre = "☄️ Meteorito Nv.%d" % (nv + 1)
				if nv == 0: poder.descripcion = "Cae cada 20s, explosion en area"
				elif nv == 1: poder.descripcion = "Fragmentos que queman al explotar"
				elif nv == 2: poder.descripcion = "Fragmentos duran mas tiempo"
				elif nv == 3: poder.descripcion = "Deja crater que quema y ralentiza"
				elif nv == 4: poder.descripcion = "Suelta orbe de curacion 15%%"
				else: poder.descripcion = "Lluvia de meteoritos + charcos"
			elif poder.tipo == "fuego":
				var nv = jugador.fuego_nivel
				var rebotes = [0,0,3,4,5,6]
				var cds = [10,10,10,10,13,13]
				poder.nombre = "🔥 Bola de Fuego Nv.%d" % (nv + 1)
				if nv < 6: poder.descripcion = "%d rebotes, quema 4s, cd %ss" % [rebotes[nv], cds[nv]]
				else: poder.descripcion = "Ya esta al maximo"
			elif poder.tipo == "satelite":
				var nv = jugador.satelite_nivel
				poder.nombre = "🔵 Satélite Nv.%d" % (nv + 1)
				poder.descripcion = "%d orbe(s) girando, 100 daño" % (nv + 1)
			elif poder.tipo == "escudo":
				var nv = jugador.escudo_nivel
				if nv == 0: poder.descripcion = "Absorbe 1 golpe, se regenera"
				elif nv == 1: poder.descripcion = "Sube a 2 golpes + empuje al recibir"
				elif nv == 2: poder.descripcion = "Sube a 3 golpes + daño al romperse"
				elif nv == 3: poder.descripcion = "Recarga: 25s roto / 10s parcial"
				elif nv == 4: poder.descripcion = "Recarga: 20s roto / 5s parcial"
				elif nv == 5: poder.descripcion = "Recarga: 10s roto + mas dano"
				else: poder.descripcion = "Escudo al maximo nivel"
	var pool = ventajas_disponibles if correcta else desventajas
	if OS.is_debug_build() and debug_forzar_tipo != "":
		var forzado = ventajas_disponibles.filter(func(p): return p.tipo == debug_forzar_tipo)
		if not forzado.is_empty():
			var resto = pool.filter(func(p): return p.tipo != debug_forzar_tipo)
			resto.shuffle()
			pool = forzado + resto
	else:
		pool.shuffle()
	var seleccion = pool.slice(0, 3)
	pantalla_poderes.mostrar_poderes(seleccion, correcta)

func _on_poder_elegido(poder: Dictionary) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	EstadoJuego.registrar_poder(poder.tipo, poder.nombre.substr(3))
	match poder.tipo:
		"disparo": jugador.disparo_nivel = 1
		"danio": jugador.danio_ataque *= (1.0 + poder.valor)
		"velocidad": jugador.VELOCIDAD *= (1.0 + poder.valor)
		"cadencia": jugador.cadencia *= (1.0 + poder.valor)
		"vida":
			jugador.vida_maxima += poder.valor
			jugador.vida = min(jugador.vida + poder.valor, jugador.vida_maxima)
		"meteorito":
			if jugador.meteorito_nivel >= 6: return
			jugador.meteorito_nivel += 1
		"fuego":
			if jugador.fuego_nivel >= 6: return
			jugador.fuego_nivel += 1
		"hielo":
			if jugador.hielo_nivel >= 6: return
			jugador.hielo_nivel += 1
		"satelite":
			if jugador.satelite_nivel >= 6: return
			jugador.satelite_nivel += 1
			_agregar_satelite(jugador)
		"senuelo":
			if jugador.senuelo_nivel >= 6: return
			jugador.senuelo_nivel += 1
		"escudo":
			if jugador.escudo_nivel >= 6: return
			jugador.escudo_nivel += 1
			jugador.escudo_golpes_max = min(jugador.escudo_nivel, 3)
			jugador.escudo_golpes_actual = jugador.escudo_golpes_max
			jugador.escudo_roto = false
			jugador.escudo_timer = 0.0
			if jugador.escudo_nivel >= 4:
				var reduccion = (jugador.escudo_nivel - 3) * 5
				jugador.escudo_cooldown_roto = max(10.0, 30.0 - reduccion)
				jugador.escudo_cooldown_parcial = max(5.0, 15.0 - reduccion)
				jugador.escudo_danio_ruptura += 20.0
		"penetracion":
			if jugador.penetracion_completos == 0 and jugador.penetracion_parcial == 0.0:
				jugador.penetracion_completos = 1
				jugador.penetracion_parcial = 0.25
			else:
				jugador.penetracion_parcial += 0.25
				if jugador.penetracion_parcial >= 1.0:
					jugador.penetracion_completos += 1
					jugador.penetracion_parcial = 0.25

func _actualizar_direccion_jugador() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var movimiento = jugador.global_position - posicion_anterior
	if movimiento.length() > 1.0:
		direccion_jugador = movimiento.normalized()
	posicion_anterior = jugador.global_position

func _agregar_satelite(jugador: Node) -> void:
	if jugador.escena_satelite == null:
		return
	var total = jugador.satelite_nivel
	var satelites = get_tree().get_nodes_in_group("satelites")
	for s in satelites:
		s.queue_free()
	for i in total:
		var sat = jugador.escena_satelite.instantiate()
		var angulo_inicial = (TAU / total) * i
		get_tree().current_scene.add_child(sat)
		sat.inicializar(jugador, angulo_inicial)
		sat.add_to_group("satelites")
