extends CanvasLayer

signal poder_elegido(poder: Dictionary)

var poderes_disponibles: Array = []

@onready var label_titulo: Label = $Panel/VBoxContainer/LabelTitulo
@onready var cartas: Array = []

func _ready() -> void:
	cartas = [
		$Panel/VBoxContainer/HBoxContainer/Carta1,
		$Panel/VBoxContainer/HBoxContainer/Carta2,
		$Panel/VBoxContainer/HBoxContainer/Carta3
	]
	cartas[0].pressed.connect(_on_carta_presionada.bind(0))
	cartas[1].pressed.connect(_on_carta_presionada.bind(1))
	cartas[2].pressed.connect(_on_carta_presionada.bind(2))
	visible = false

func mostrar_poderes(poderes: Array, es_ventaja: bool) -> void:
	visible = true
	poderes_disponibles = poderes
	get_tree().paused = true
	label_titulo.text = "⚔️ Elige tu mejora" if es_ventaja else "💀 Elige tu penalización"
	for i in range(cartas.size()):
		var poder = poderes[i]
		cartas[i].text = poder.nombre + "\n" + poder.descripcion

func _on_carta_presionada(indice: int) -> void:
	visible = false
	get_tree().paused = false
	poder_elegido.emit(poderes_disponibles[indice])
