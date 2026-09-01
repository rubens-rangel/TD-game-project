extends RefCounted
class_name WeatherManager

const GameConstants = preload("res://scripts/Constants.gd")

enum WeatherType {
	NONE,
	FOG,
	NIGHT,
	RAIN,
	HEAT,
	STORM,
	WIND,
	SNOW
}

var current_weather: WeatherType = WeatherType.NONE
var weather_start_wave: int = 0
var weather_duration: int = GameConstants.WEATHER_DURATION_WAVES

func _init():
	pass

func update_weather(current_wave: int) -> bool:
	"""Atualiza o clima baseado na wave atual. Retorna true se o clima mudou"""
	var old_weather = current_weather


	if current_weather != WeatherType.NONE:
		if current_wave >= weather_start_wave + weather_duration:

			current_weather = WeatherType.NONE
			weather_start_wave = 0

			return true


	if current_weather == WeatherType.NONE:
		if current_wave % GameConstants.WEATHER_CHANGE_INTERVAL == 0 and current_wave > 0:

			current_weather = _get_random_weather()
			weather_start_wave = current_wave
			return true


	return false

func _get_random_weather() -> WeatherType:
	"""Retorna um tipo de clima aleatório"""
	var available_weathers = [
		WeatherType.FOG,
		WeatherType.NIGHT,
		WeatherType.RAIN,
		WeatherType.HEAT,
		WeatherType.STORM,
		WeatherType.WIND,
		WeatherType.SNOW
	]
	return available_weathers[randi() % available_weathers.size()]

func get_weather_name() -> String:
	"""Retorna o nome do clima atual"""
	match current_weather:
		WeatherType.NONE:
			return ""
		WeatherType.FOG:
			return "🌫️ NÉVOA"
		WeatherType.NIGHT:
			return "🌙 NOITE"
		WeatherType.RAIN:
			return "🌧️ CHUVA"
		WeatherType.HEAT:
			return "☀️ CALOR"
		WeatherType.STORM:
			return "⛈️ TEMPESTADE"
		WeatherType.WIND:
			return "💨 VENTO"
		WeatherType.SNOW:
			return "❄️ NEVE"
		_:
			return ""

func get_weather_description() -> String:
	"""Retorna a descrição dos efeitos do clima"""
	match current_weather:
		WeatherType.NONE:
			return ""
		WeatherType.FOG:
			return "Alcance das torres -20%"
		WeatherType.NIGHT:
			return "Alcance -30% • Inimigos +10% velocidade"
		WeatherType.RAIN:
			return "Dano das torres -15% • Alcance -10%"
		WeatherType.HEAT:
			return "Inimigos +25% velocidade • +15% HP"
		WeatherType.STORM:
			return "Dano -20% • Alcance -15% • Inimigos +10% velocidade"
		WeatherType.WIND:
			return "Precisão das torres reduzida"
		WeatherType.SNOW:
			return "Velocidade de todos -15%"
		_:
			return ""

func get_tower_damage_multiplier() -> float:
	"""Retorna multiplicador de dano das torres baseado no clima"""
	match current_weather:
		WeatherType.RAIN:
			return 1.0 - GameConstants.WEATHER_RAIN_TOWER_DAMAGE_REDUCTION
		WeatherType.STORM:
			return 0.80
		_:
			return 1.0

func get_tower_range_multiplier() -> float:
	"""Retorna multiplicador de alcance das torres baseado no clima"""
	match current_weather:
		WeatherType.FOG:
			return 1.0 - GameConstants.WEATHER_FOG_VISIBILITY_REDUCTION
		WeatherType.NIGHT:
			return 1.0 - GameConstants.WEATHER_NIGHT_VISIBILITY_REDUCTION
		WeatherType.RAIN:
			return 1.0 - GameConstants.WEATHER_RAIN_TOWER_RANGE_REDUCTION
		WeatherType.STORM:
			return 0.85
		_:
			return 1.0

func get_enemy_speed_multiplier() -> float:
	"""Retorna multiplicador de velocidade dos inimigos baseado no clima"""
	match current_weather:
		WeatherType.HEAT:
			return GameConstants.WEATHER_HEAT_ENEMY_SPEED_BOOST
		WeatherType.NIGHT:
			return GameConstants.WEATHER_NIGHT_ENEMY_SPEED_BOOST
		WeatherType.STORM:
			return 1.10
		WeatherType.SNOW:
			return 0.85
		_:
			return 1.0

func get_enemy_hp_multiplier() -> float:
	"""Retorna multiplicador de HP dos inimigos baseado no clima"""
	match current_weather:
		WeatherType.HEAT:
			return GameConstants.WEATHER_HEAT_ENEMY_HP_BOOST
		_:
			return 1.0

func get_tower_accuracy_multiplier() -> float:
	"""Retorna multiplicador de precisão das torres (para vento)"""
	match current_weather:
		WeatherType.WIND:
			return 0.85
		WeatherType.STORM:
			return 0.90
		_:
			return 1.0

func is_night() -> bool:
	"""Retorna true se é noite"""
	return current_weather == WeatherType.NIGHT

func is_rainy() -> bool:
	"""Retorna true se está chovendo"""
	return current_weather == WeatherType.RAIN or current_weather == WeatherType.STORM

func is_foggy() -> bool:
	return current_weather == WeatherType.FOG

func has_visibility_reduction() -> bool:
	"""Retorna true se o clima reduz visibilidade"""
	return current_weather == WeatherType.FOG or current_weather == WeatherType.NIGHT

func is_snowy() -> bool:
	"""Retorna true se está nevando"""
	return current_weather == WeatherType.SNOW

func is_windy() -> bool:
	"""Retorna true se está ventando"""
	return current_weather == WeatherType.WIND or current_weather == WeatherType.STORM
