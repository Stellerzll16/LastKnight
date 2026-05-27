extends CanvasLayer

signal pregunta_respondida(correcta: bool)

const TIEMPO_LIMITE = 15.0
var tiempo_restante: float = TIEMPO_LIMITE
var respuesta_correcta: int = 0
var respondido: bool = false

@onready var label_categoria: Label = $Panel/VBoxContainer/LabelCategoria
@onready var label_pregunta: Label = $Panel/VBoxContainer/LabelPregunta
@onready var barra_tiempo: ProgressBar = $Panel/VBoxContainer/BarraTiempo
@onready var botones: Array = []

func _ready() -> void:
	botones = [
		$Panel/VBoxContainer/GridOpciones/BotonA,
		$Panel/VBoxContainer/GridOpciones/BotonB,
		$Panel/VBoxContainer/GridOpciones/BotonC,
		$Panel/VBoxContainer/GridOpciones/BotonD
	]
	$Panel/VBoxContainer/GridOpciones/BotonA.pressed.connect(_on_opcion_presionada.bind(0))
	$Panel/VBoxContainer/GridOpciones/BotonB.pressed.connect(_on_opcion_presionada.bind(1))
	$Panel/VBoxContainer/GridOpciones/BotonC.pressed.connect(_on_opcion_presionada.bind(2))
	$Panel/VBoxContainer/GridOpciones/BotonD.pressed.connect(_on_opcion_presionada.bind(3))
	visible = false

func mostrar_pregunta(datos: Dictionary) -> void:
	visible = true
	respondido = false
	tiempo_restante = TIEMPO_LIMITE
	barra_tiempo.max_value = TIEMPO_LIMITE
	barra_tiempo.value = TIEMPO_LIMITE
	var categoria = datos.get("categoria", "matematicas")
	label_categoria.text = "📚 " + categoria.capitalize()
	label_pregunta.text = datos.get("pregunta", "")
	respuesta_correcta = datos.get("correcta", 0)
	var opciones: Array = datos.get("opciones", ["A", "B", "C", "D"])
	var letras = ["A", "B", "C", "D"]
	for i in range(botones.size()):
		botones[i].text = letras[i] + ") " + opciones[i]
		botones[i].modulate = Color.WHITE
		botones[i].disabled = false
	get_tree().paused = true

func _process(delta: float) -> void:
	if not visible or respondido:
		return
	tiempo_restante -= delta
	barra_tiempo.value = tiempo_restante
	if tiempo_restante <= 0:
		_on_opcion_presionada(-1)

func _on_opcion_presionada(indice: int) -> void:
	if respondido:
		return
	respondido = true
	var correcta = indice == respuesta_correcta
	# Mostrar feedback visual
	for i in range(botones.size()):
		botones[i].disabled = true
		if i == respuesta_correcta:
			botones[i].modulate = Color.GREEN
		elif i == indice:
			botones[i].modulate = Color.RED
	# Esperar 2 segundos y emitir señal
	await get_tree().create_timer(2.0, true, false, true).timeout
	visible = false
	get_tree().paused = false
	pregunta_respondida.emit(correcta)
