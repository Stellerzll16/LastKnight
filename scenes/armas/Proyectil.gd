extends Area2D

var velocidad: float = 400.0
var danio: float = 25.0
var direccion: Vector2 = Vector2.ZERO
var golpes_completos: int = 0
var multiplicador_parcial: float = 0.0
var enemigos_golpeados: Array = []
var golpes_dados: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func inicializar(pos: Vector2, dir: Vector2, dmg: float, completos: int = 0, parcial: float = 0.0) -> void:
	global_position = pos
	direccion = dir.normalized()
	danio = dmg
	golpes_completos = completos
	multiplicador_parcial = parcial

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador and global_position.distance_to(jugador.global_position) > 800.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemigos"):
		return
	if body in enemigos_golpeados:
		return
	enemigos_golpeados.append(body)

	if golpes_dados < golpes_completos:
		# Golpes completos: daño total, sigue viajando
		body.recibir_danio(danio)
		golpes_dados += 1
	elif multiplicador_parcial > 0.0:
		# Golpe parcial: daño reducido, se destruye
		body.recibir_danio(danio * multiplicador_parcial)
		queue_free()
	else:
		# Sin penetración: daño normal y se destruye
		body.recibir_danio(danio)
		queue_free()
