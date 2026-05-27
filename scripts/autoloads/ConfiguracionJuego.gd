extends Node

const RUTA_CONFIG   := "user://config.cfg"
const RUTA_PARTIDA  := "user://partida.cfg"

var vol_master : float = 1.0
var vol_musica : float = 1.0
var vol_efectos: float = 1.0

const BUS_MASTER  := 0
const BUS_MUSICA  := 1
const BUS_EFECTOS := 2

func _ready() -> void:
	cargar_config()

func set_vol_master(valor: float) -> void:
	vol_master = clamp(valor, 0.0, 1.0)
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(vol_master))
	AudioServer.set_bus_mute(BUS_MASTER, vol_master == 0.0)
	guardar_config()

func set_vol_musica(valor: float) -> void:
	vol_musica = clamp(valor, 0.0, 1.0)
	AudioServer.set_bus_volume_db(BUS_MUSICA, linear_to_db(vol_musica))
	AudioServer.set_bus_mute(BUS_MUSICA, vol_musica == 0.0)
	guardar_config()

func set_vol_efectos(valor: float) -> void:
	vol_efectos = clamp(valor, 0.0, 1.0)
	AudioServer.set_bus_volume_db(BUS_EFECTOS, linear_to_db(vol_efectos))
	AudioServer.set_bus_mute(BUS_EFECTOS, vol_efectos == 0.0)
	guardar_config()

func guardar_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master",  vol_master)
	cfg.set_value("audio", "musica",  vol_musica)
	cfg.set_value("audio", "efectos", vol_efectos)
	cfg.save(RUTA_CONFIG)

func cargar_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_CONFIG) != OK:
		return
	vol_master  = cfg.get_value("audio", "master",  1.0)
	vol_musica  = cfg.get_value("audio", "musica",  1.0)
	vol_efectos = cfg.get_value("audio", "efectos", 1.0)
	set_vol_master(vol_master)
	set_vol_musica(vol_musica)
	set_vol_efectos(vol_efectos)

func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_PARTIDA)

func guardar_partida() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partida", "vida_jugador",            EstadoJuego.vida_jugador)
	cfg.set_value("partida", "vida_maxima",             EstadoJuego.vida_maxima)
	cfg.set_value("partida", "xp_jugador",              EstadoJuego.xp_jugador)
	cfg.set_value("partida", "nivel_jugador",           EstadoJuego.nivel_jugador)
	cfg.set_value("partida", "xp_para_siguiente_nivel", EstadoJuego.xp_para_siguiente_nivel)
	cfg.set_value("partida", "tiempo_transcurrido",     EstadoJuego.tiempo_transcurrido)
	cfg.set_value("partida", "enemigos_eliminados",     EstadoJuego.enemigos_eliminados)
	cfg.set_value("partida", "poderes_activos",         EstadoJuego.poderes_activos)
	cfg.set_value("partida", "registro_poderes",        EstadoJuego.registro_poderes)
	cfg.save(RUTA_PARTIDA)

func cargar_partida() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_PARTIDA) != OK:
		return
	EstadoJuego.vida_jugador            = cfg.get_value("partida", "vida_jugador",            100.0)
	EstadoJuego.vida_maxima             = cfg.get_value("partida", "vida_maxima",             100.0)
	EstadoJuego.xp_jugador              = cfg.get_value("partida", "xp_jugador",              0.0)
	EstadoJuego.nivel_jugador           = cfg.get_value("partida", "nivel_jugador",           1)
	EstadoJuego.xp_para_siguiente_nivel = cfg.get_value("partida", "xp_para_siguiente_nivel", 50.0)
	EstadoJuego.tiempo_transcurrido     = cfg.get_value("partida", "tiempo_transcurrido",     0.0)
	EstadoJuego.enemigos_eliminados     = cfg.get_value("partida", "enemigos_eliminados",     0)
	EstadoJuego.poderes_activos         = cfg.get_value("partida", "poderes_activos",         [])
	EstadoJuego.registro_poderes        = cfg.get_value("partida", "registro_poderes",        {})

func borrar_partida() -> void:
	if FileAccess.file_exists(RUTA_PARTIDA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_PARTIDA))
