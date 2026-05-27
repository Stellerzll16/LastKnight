extends CanvasLayer

signal continuar_juego

enum Pantalla { PRINCIPAL, ESTADISTICAS, AJUSTES }
var pantalla_actual: Pantalla = Pantalla.PRINCIPAL

const ESCENA_AJUSTES := preload("res://scenes/ui/PantallaAjustes.tscn")

@onready var panel_principal = $PanelPrincipal
@onready var panel_estadisticas = $PanelEstadisticas
@onready var label_stats = $PanelEstadisticas/ScrollContainer/VBox/LabelStats

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			cerrar()
		else:
			abrir()

func abrir() -> void:
	visible = true
	_mostrar_panel(Pantalla.PRINCIPAL)
	get_tree().paused = true
	ConfiguracionJuego.guardar_partida()

func cerrar() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("continuar_juego")

func _mostrar_panel(p: Pantalla) -> void:
	pantalla_actual = p
	panel_principal.visible = p == Pantalla.PRINCIPAL
	panel_estadisticas.visible = p == Pantalla.ESTADISTICAS

func _on_btn_ajustes() -> void:
	panel_principal.visible = false
	var ajustes = ESCENA_AJUSTES.instantiate()
	ajustes.tree_exited.connect(func(): panel_principal.visible = true)
	add_child(ajustes)

func _on_btn_continuar() -> void:
	cerrar()

func _on_btn_estadisticas() -> void:
	_actualizar_estadisticas()
	_mostrar_panel(Pantalla.ESTADISTICAS)

func _on_btn_volver_principal() -> void:
	_mostrar_panel(Pantalla.PRINCIPAL)

func _on_btn_menu_principal() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MenuPrincipal.tscn")

func _on_btn_salir_juego() -> void:
	get_tree().quit()

func _actualizar_estadisticas() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var cadencia_ps = 1.0 / jugador.cadencia
	var texto = ""

	texto += "═══ ESTADÍSTICAS DEL JUGADOR ═══\n\n"
	texto += "❤️  Vida:             %d / %d\n" % [jugador.vida, jugador.vida_maxima]
	texto += "⚔️  Daño:             %.1f\n" % jugador.danio_ataque
	texto += "💨  Velocidad:        %.0f\n" % jugador.VELOCIDAD
	texto += "🔥  Cadencia:         %.2f seg entre ataques\n" % jugador.cadencia
	texto += "🎯  Ataques/segundo:  %.1f\n" % cadencia_ps

	if jugador.penetracion_completos > 0 or jugador.penetracion_parcial > 0.0:
		var pct = int(jugador.penetracion_parcial * 100)
		if pct == 0:
			texto += "🔱  Penetración:      %d enemigos al 100%%\n" % jugador.penetracion_completos
		else:
			texto += "🔱  Penetración:      %d al 100%% + %d%% al siguiente\n" % [jugador.penetracion_completos, pct]

	texto += "\n═══ PODERES ACTIVOS ═══\n\n"

	var tiene_poderes = false

	if jugador.penetracion_completos > 0 or jugador.penetracion_parcial > 0.0:
		tiene_poderes = true
		var ciclos_extra = max(0, jugador.penetracion_completos - 1)
		var veces = ciclos_extra * 4 + int(round(jugador.penetracion_parcial / 0.25))
		texto += "  • 🔱 Penetración  Nv. %d\n" % veces

	if jugador.escudo_nivel > 0:
		tiene_poderes = true
		var max_escudo = " (MAX)" if jugador.escudo_nivel >= 6 else ""
		texto += "  • 🛡️ Escudo  Nv. %d%s\n" % [jugador.escudo_nivel, max_escudo]

	if jugador.senuelo_nivel > 0:
		tiene_poderes = true
		var max_senuelo = " (MAX)" if jugador.senuelo_nivel >= 6 else ""
		texto += "  • 🪄 Señuelo  Nv. %d%s\n" % [jugador.senuelo_nivel, max_senuelo]

	if jugador.satelite_nivel > 0:
		tiene_poderes = true
		var max_sat = " (MAX)" if jugador.satelite_nivel >= 6 else ""
		texto += "  • 🔵 Satélite  Nv. %d%s\n" % [jugador.satelite_nivel, max_sat]

	if jugador.hielo_nivel > 0:
		tiene_poderes = true
		var max_hie = " (MAX)" if jugador.hielo_nivel >= 6 else ""
		texto += "  • ❄️ Hielo  Nv. %d%s\n" % [jugador.hielo_nivel, max_hie]

	if not tiene_poderes:
		texto += "  (ninguno aún)\n"

	label_stats.text = texto
