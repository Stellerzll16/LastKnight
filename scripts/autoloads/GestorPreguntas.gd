extends Node

var preguntas: Dictionary = {}

func _ready() -> void:
	_cargar_preguntas()

func _cargar_preguntas() -> void:
	var archivo = FileAccess.open("res://data/preguntas.json", FileAccess.READ)
	if archivo:
		preguntas = JSON.parse_string(archivo.get_as_text())
	else:
		push_error("No se pudo abrir preguntas.json")

func obtener_pregunta(fase: int) -> Dictionary:
	var categoria = ["matematicas", "programacion"][randi() % 2]
	var clave = str(fase)
	if preguntas.has(categoria) and preguntas[categoria].has(clave):
		var lista: Array = preguntas[categoria][clave]
		return lista[randi() % lista.size()]
	return {}
