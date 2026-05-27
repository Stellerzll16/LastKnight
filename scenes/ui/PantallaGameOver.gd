extends CanvasLayer

@onready var label_tiempo = $Panel/VBoxContainer/Stats
@onready var boton_menu = $Panel/VBoxContainer/VolverAlMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	boton_menu.pressed.connect(_on_boton_menu)

func mostrar() -> void:
	var minutos = int(EstadoJuego.tiempo_transcurrido) / 60
	var segundos = int(EstadoJuego.tiempo_transcurrido) % 60
	label_tiempo.text = "Tiempo sobrevivido: %02d:%02d\nEnemigos eliminados: %d" % [minutos, segundos, EstadoJuego.enemigos_eliminados]
	get_tree().paused = true
	visible = true

func _on_boton_menu() -> void:
	get_tree().paused = false
	EstadoJuego.reiniciar()
	get_tree().change_scene_to_file("res://scenes/ui/MenuPrincipal.tscn")
