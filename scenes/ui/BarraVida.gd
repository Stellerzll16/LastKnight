extends Node2D

@onready var barra: ProgressBar = $ProgressBar

func actualizar(vida_actual: float, vida_maxima: float) -> void:
	print("BarraVida.actualizar llamado, barra=", barra)
	barra.max_value = vida_maxima
	barra.value = vida_actual
	visible = vida_actual < vida_maxima
