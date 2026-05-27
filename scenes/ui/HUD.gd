extends CanvasLayer

@onready var label_nivel: Label = $VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $VBoxContainer/BarraXP
@onready var label_tiempo: Label = $VBoxContainer/LabelTiempo
@onready var label_fase: Label = $VBoxContainer/LabelFase
@onready var escudo_hud: Control = $EscudoHUD
@onready var arco_escudo = $EscudoHUD/ArcoEscudo
@onready var label_golpes: Label = $EscudoHUD/LabelGolpes
@onready var senuelo_hud: Control = $SenueloHUD
@onready var arco_senuelo = $SenueloHUD/ArcoSenuelo
@onready var label_senuelo: Label = $SenueloHUD/LabelSenuelo
@onready var meteorito_hud: Control = $MetoritoHUD
@onready var arco_meteorito = $MetoritoHUD/ArcoMetorito
@onready var label_meteorito: Label = $MetoritoHUD/LabelMetorito

var nombres_fases = {
	1: "⚔️ Fase 1 — Inicio",
	2: "🔥 Fase 2 — Desarrollo",
	3: "💀 Fase 3 — Intensidad",
	4: "👹 Fase 4 — Finalización"
}

var COLOR_VERDE    = Color(0.2, 1.0, 0.3)
var COLOR_AMARILLO = Color(1.0, 0.85, 0.0)
var COLOR_ROJO     = Color(1.0, 0.2, 0.2)
var COLOR_GRIS     = Color(0.4, 0.4, 0.4)
var COLOR_MAGENTA  = Color(0.8, 0.2, 1.0)
var COLOR_NARANJA  = Color(1.0, 0.5, 0.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(label_nivel) or not is_instance_valid(barra_xp):
		return

	label_nivel.text = "Nivel " + str(EstadoJuego.nivel_jugador)
	barra_xp.max_value = EstadoJuego.xp_para_siguiente_nivel
	barra_xp.value = EstadoJuego.xp_jugador

	var segundos_totales = int(EstadoJuego.tiempo_transcurrido)
	var minutos = segundos_totales / 60
	var segundos = segundos_totales % 60
	label_tiempo.text = "⏱ %02d:%02d" % [minutos, segundos]

	var fase = EstadoJuego.get_fase_actual()
	label_fase.text = nombres_fases[fase]

	_actualizar_escudo_hud()
	_actualizar_senuelo_hud()
	_actualizar_meteorito_hud()

func _actualizar_escudo_hud() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null or jugador.escudo_nivel == 0:
		escudo_hud.visible = false
		return

	escudo_hud.visible = true
	var golpes_max = jugador.escudo_golpes_max
	var golpes_actual = jugador.escudo_golpes_actual
	var timer = jugador.escudo_timer
	var duracion = jugador.escudo_cooldown_roto if jugador.escudo_roto else jugador.escudo_cooldown_parcial

	var color: Color
	if golpes_actual == 0:
		color = COLOR_GRIS
	elif golpes_actual == 1:
		color = COLOR_ROJO
	elif golpes_actual == 2:
		color = COLOR_AMARILLO
	else:
		color = COLOR_VERDE

	var progreso: float
	if golpes_actual >= golpes_max:
		progreso = 1.0
	else:
		progreso = 1.0 - (timer / duracion)

	arco_escudo.actualizar(progreso, color)

	if golpes_actual == 0:
		label_golpes.text = str(int(ceil(timer)))
	elif golpes_actual == golpes_max:
		label_golpes.text = "🛡"
	else:
		label_golpes.text = "🛡%d" % golpes_actual

func _actualizar_senuelo_hud() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null or jugador.senuelo_nivel == 0:
		senuelo_hud.visible = false
		return

	senuelo_hud.visible = true

	if jugador.senuelo_activo:
		arco_senuelo.actualizar(1.0, COLOR_MAGENTA)
		label_senuelo.text = "🪄"
	else:
		var progreso = jugador.senuelo_timer / jugador.senuelo_cooldown
		var segundos_restantes = int(ceil(jugador.senuelo_cooldown - jugador.senuelo_timer))
		var color = COLOR_MAGENTA if progreso >= 1.0 else COLOR_GRIS
		arco_senuelo.actualizar(progreso, color)
		label_senuelo.text = "🪄" if progreso >= 1.0 else str(segundos_restantes)

func _actualizar_meteorito_hud() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null or jugador.meteorito_nivel == 0:
		meteorito_hud.visible = false
		return

	meteorito_hud.visible = true
	var cooldown = 60.0 if jugador.meteorito_nivel >= 6 else (40.0 if jugador.meteorito_nivel >= 2 else 20.0)
	var progreso = jugador.meteorito_timer / cooldown
	var segundos_restantes = int(ceil(cooldown - jugador.meteorito_timer))
	var color = COLOR_NARANJA if progreso >= 1.0 else COLOR_GRIS
	arco_meteorito.actualizar(progreso, color)
	label_meteorito.text = "☄️" if progreso >= 1.0 else str(segundos_restantes)
