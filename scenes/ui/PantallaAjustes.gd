extends Control

@onready var slider_master  : HSlider = $Panel/VBox/FilaMaster/SliderMaster
@onready var slider_musica  : HSlider = $Panel/VBox/FilaMusica/SliderMusica
@onready var slider_efectos : HSlider = $Panel/VBox/FilaEfectos/SliderEfectos

@onready var label_master  : Label = $Panel/VBox/FilaMaster/LabelValorMaster
@onready var label_musica  : Label = $Panel/VBox/FilaMusica/LabelValorMusica
@onready var label_efectos : Label = $Panel/VBox/FilaEfectos/LabelValorEfectos

func _ready() -> void:
	# Cargar valores actuales
	slider_master.value  = ConfiguracionJuego.vol_master
	slider_musica.value  = ConfiguracionJuego.vol_musica
	slider_efectos.value = ConfiguracionJuego.vol_efectos
	_actualizar_labels()

	# Conectar señales
	slider_master.value_changed.connect(_on_master_changed)
	slider_musica.value_changed.connect(_on_musica_changed)
	slider_efectos.value_changed.connect(_on_efectos_changed)

func _on_master_changed(valor: float) -> void:
	ConfiguracionJuego.set_vol_master(valor)
	label_master.text = str(int(valor * 100)) + "%"

func _on_musica_changed(valor: float) -> void:
	ConfiguracionJuego.set_vol_musica(valor)
	label_musica.text = str(int(valor * 100)) + "%"

func _on_efectos_changed(valor: float) -> void:
	ConfiguracionJuego.set_vol_efectos(valor)
	label_efectos.text = str(int(valor * 100)) + "%"

func _actualizar_labels() -> void:
	label_master.text  = str(int(slider_master.value  * 100)) + "%"
	label_musica.text  = str(int(slider_musica.value  * 100)) + "%"
	label_efectos.text = str(int(slider_efectos.value * 100)) + "%"

func _on_boton_cerrar_pressed() -> void:
	queue_free()
