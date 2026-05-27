extends Control

@onready var boton_continuar = $TextureRect/BotonContinuar
@onready var tablero = $TextureRect
@onready var personaje = $Personaje

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	EstadoJuego.reiniciar()
	boton_continuar.visible = ConfiguracionJuego.hay_partida_guardada()
	_animar_tablero()
	tablero.pivot_offset = Vector2(tablero.size.x / 2.0, 0.0)
	personaje.play("idle")
	_fade_personaje()

func _animar_tablero() -> void:
	await get_tree().process_frame
	tablero.pivot_offset = Vector2(tablero.size.x / 2.0, 0.0)
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(tablero, "rotation_degrees", 3.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tablero, "rotation_degrees", -3.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _fade_personaje() -> void:
	var tween = create_tween()
	tween.set_loops()
	# Inicio: aparece
	tween.tween_property(personaje, "modulate:a", 0.0, 0.0)  # empieza invisible
	tween.tween_property(personaje, "modulate:a", 1.0, 0.5)  # fade in
	# Espera hasta los 5.2s
	tween.tween_interval(4.7)
	# Mitad: desaparece y reaparece
	tween.tween_property(personaje, "modulate:a", 0.0, 0.7)  # fade out
	tween.tween_property(personaje, "modulate:a", 1.0, 0.5)  # fade in
	# Espera hasta el final y se oscurece
	tween.tween_interval(4.2)
	tween.tween_property(personaje, "modulate:a", 0.0, 0.4)  # fade out final
	# Total: 0.5 + 4.7 + 0.7 + 0.5 + 3.9 + 0.7 = 11.0
	
func _on_boton_jugar_pressed() -> void:
	ConfiguracionJuego.borrar_partida()
	EstadoJuego.reiniciar()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_boton_continuar_pressed() -> void:
	ConfiguracionJuego.cargar_partida()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
