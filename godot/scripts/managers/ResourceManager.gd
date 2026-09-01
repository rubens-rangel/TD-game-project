extends RefCounted
class_name ResourceManager

signal loading_progress_updated(progress: float)

const MAX_SPRITE_SIZE := 256
const MAX_TILE_SIZE := 64
const MAX_ICON_SIZE := 128
const MAX_BG_SIZE := 1024
const MAX_UI_SIZE := 512

var textures: Dictionary = {}
var loading_progress: float = 0.0

var style_boxes: Dictionary = {}

var colors: Dictionary = {}

var audio_streams: Dictionary = {}

func load_texture(path: String, process: bool = false, max_size: int = MAX_SPRITE_SIZE) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		var fallback = load(path)
		if fallback is Texture2D:
			return fallback as Texture2D
		return null
	if process:
		_make_white_transparent(image, path)
	_fit_image(image, max_size)
	return ImageTexture.create_from_image(image)

func load_all_textures() -> void:
	loading_progress = 0.0
	loading_progress_updated.emit(0.0)

	textures["enemy_zombie"] = load_texture("res://assets/images/enemies/enemy_zombie.png", true)
	_update_progress(0.10)

	textures["enemy_zombie_gordo"] = load_texture("res://assets/images/enemies/enemy_zombie_gordo.png", true)
	_update_progress(0.12)

	textures["enemy_zombie_corredor"] = load_texture("res://assets/images/enemies/enemy_zombie_corredor.png", true)
	_update_progress(0.15)

	textures["enemy_boss_zombie"] = load_texture("res://assets/images/enemies/enemy_boss_zombie.png", true)
	textures["enemy_boss_alien"] = load_texture("res://assets/images/enemies/enemy_boss_alien.png", true)
	textures["boss_aura"] = load_texture("res://assets/images/boss_aura.png", true, MAX_ICON_SIZE)
	_update_progress(0.18)

	textures["enemy_humanoid"] = load_texture("res://assets/images/enemies/enemy_humanoid.png", true)
	_update_progress(0.25)

	textures["enemy_robot"] = load_texture("res://assets/images/enemies/enemy_robot.png", true)
	_update_progress(0.30)

	textures["enemy_alien"] = load_texture("res://assets/images/enemies/enemy_alien.png", true)
	_update_progress(0.35)

	textures["alien_voador"] = load_texture("res://assets/images/alien_voador.png", true)
	_update_progress(0.38)

	textures["mecanoide_bipede1"] = load_texture("res://assets/images/enemies/mecanoide_bipede1.png", true)
	textures["mecanoide_lagartas1"] = load_texture("res://assets/images/enemies/mecanoide_lagartas1.png", true)
	textures["mecanoide_drone1"] = load_texture("res://assets/images/enemies/mecanoide_drone1.png", true)
	textures["mecanoide_regenerado1"] = load_texture("res://assets/images/enemies/mecanoide_regenerado1.png", true)
	textures["mecanoide_boss1"] = load_texture("res://assets/images/enemies/mecanoide_boss1.png", true)
	_update_progress(0.42)

	textures["tent"] = load_texture("res://assets/images/tent.png", true)
	_update_progress(0.45)

	textures["grass"] = load_texture("res://assets/images/grass.png", false, MAX_TILE_SIZE)
	textures["path"] = load_texture("res://assets/images/path.png", false, MAX_TILE_SIZE)
	textures["wall"] = load_texture("res://assets/images/wall.png", false, MAX_TILE_SIZE)
	_update_progress(0.55)

	textures["tower"] = load_texture("res://assets/images/tower.png", true)
	_update_progress(0.65)

	textures["slow_tower"] = load_texture("res://assets/images/slow_tower.png", true)
	_update_progress(0.70)

	textures["aoe_tower"] = load_texture("res://assets/images/aoe_tower.png", true)
	_update_progress(0.75)

	textures["sniper_tower"] = load_texture("res://assets/images/sniper_tower.png", true)
	_update_progress(0.80)

	textures["boost_tower"] = load_texture("res://assets/images/boost_tower.png", true)
	_update_progress(0.85)

	textures["shock_tower"] = load_texture("res://assets/images/shock_tower.jpg", true)
	textures["anti_air_tower"] = load_texture("res://assets/images/antiaereo.png", true)
	_update_progress(0.9)

	textures["barracks"] = load_texture("res://assets/images/barracks.png", true)
	textures["mine"] = load_texture("res://assets/images/mine.png", true)
	textures["wall_structure"] = load_texture("res://assets/images/wall_structure.png", true)
	textures["healing_station"] = load_texture("res://assets/images/healing_station.png", true)
	textures["market"] = load_texture("res://assets/images/market.png", true)
	textures["coin"] = load_texture("res://assets/images/coin.png", true, MAX_ICON_SIZE)
	textures["talism"] = load_texture("res://assets/images/talism.png", true, MAX_ICON_SIZE)
	textures["house"] = load_texture("res://assets/images/house.png", true)
	textures["castle"] = load_texture("res://assets/images/castle.png", true)
	textures["Caste2"] = load_texture("res://assets/images/Caste2.png", true)
	textures["game_over"] = load_texture("res://assets/images/GameOver.png", false, MAX_UI_SIZE)
	_update_progress(0.95)


	_preload_audio_streams()
	_update_progress(0.97)


	_preload_style_boxes()
	_update_progress(0.99)


	_preload_colors()
	_update_progress(1.0)

func _update_progress(progress: float) -> void:
	loading_progress = progress
	loading_progress_updated.emit(progress)

func get_texture(name: String) -> Texture2D:
	return textures.get(name, null)

func _fit_image(image: Image, max_size: int) -> void:
	if max_size <= 0:
		return
	var w: int = image.get_width()
	var h: int = image.get_height()
	if w <= max_size and h <= max_size:
		return
	var scale: float = float(max_size) / float(maxi(w, h))
	image.resize(maxi(1, int(w * scale)), maxi(1, int(h * scale)), Image.INTERPOLATE_LANCZOS)

func _make_white_transparent(image: Image, image_path: String) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var threshold := 0.85
	if "slow_tower" in image_path:
		threshold = 0.82
	elif "tower.png" in image_path:
		threshold = 0.78
	var threshold_b: int = int(threshold * 255.0)
	var data := image.get_data()
	var changed := false
	for i in range(0, data.size(), 4):
		var a: int = data[i + 3]
		if a < 26:
			if a != 0:
				data[i + 3] = 0
				changed = true
			continue
		var r: int = data[i]
		var g: int = data[i + 1]
		var b: int = data[i + 2]
		if r >= threshold_b and g >= threshold_b and b >= threshold_b:
			data[i + 3] = 0
			changed = true
			continue
		if (r + g + b) >= threshold_b * 3:
			data[i + 3] = 0
			changed = true
	if changed:
		image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)

func _preload_audio_streams() -> void:
	"""Pré-carrega streams de áudio comuns"""
	var audio_paths = [
		["res://assets/sounds/coin_collect.ogg", "coin_collect"],
		["res://assets/sounds/coin_collect.mp3", "coin_collect"],
		["res://assets/sounds/coin_collect.wav", "coin_collect"],
		["res://assets/music/game_music.ogg", "game_music"],
		["res://assets/music/game_music.mp3", "game_music"],
		["res://assets/music/menu_music.ogg", "menu_music"],
		["res://assets/music/menu_music.mp3", "menu_music"],
		["res://assets/sounds/aproaching.wav", "boss_warning"],
		["res://assets/sounds/approaching.wav", "boss_warning"]
	]

	for path_data in audio_paths:
		var path = path_data[0]
		var key = path_data[1]

		if not audio_streams.has(key) and ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				audio_streams[key] = stream

func _preload_style_boxes() -> void:
	"""Pré-cria StyleBoxes comuns para evitar criação repetida"""

	style_boxes["top_bar"] = UIHelper.hud_bar_style(false)
	style_boxes["bottom_bar"] = UIHelper.hud_bar_style(true)


	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.4, 0.6, 0.9)
	btn_normal.border_color = Color(0.4, 0.6, 0.8, 1.0)
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left = 5
	btn_normal.corner_radius_top_right = 5
	btn_normal.corner_radius_bottom_left = 5
	btn_normal.corner_radius_bottom_right = 5
	style_boxes["button_normal"] = btn_normal


	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.5, 0.7, 0.95)
	btn_hover.border_color = Color(0.5, 0.7, 0.9, 1.0)
	btn_hover.border_width_left = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_bottom = 2
	btn_hover.corner_radius_top_left = 5
	btn_hover.corner_radius_top_right = 5
	btn_hover.corner_radius_bottom_left = 5
	btn_hover.corner_radius_bottom_right = 5
	style_boxes["button_hover"] = btn_hover


	var admin_btn_normal = StyleBoxFlat.new()
	admin_btn_normal.bg_color = Color(0.4, 0.2, 0.6)
	admin_btn_normal.border_color = Color(0.6, 0.3, 0.8)
	admin_btn_normal.border_width_left = 1
	admin_btn_normal.border_width_top = 1
	admin_btn_normal.border_width_right = 1
	admin_btn_normal.border_width_bottom = 1
	style_boxes["admin_button_normal"] = admin_btn_normal

	var admin_btn_hover = StyleBoxFlat.new()
	admin_btn_hover.bg_color = Color(0.5, 0.3, 0.7)
	admin_btn_hover.border_color = Color(0.7, 0.4, 0.9)
	admin_btn_hover.border_width_left = 1
	admin_btn_hover.border_width_top = 1
	admin_btn_hover.border_width_right = 1
	admin_btn_hover.border_width_bottom = 1
	style_boxes["admin_button_hover"] = admin_btn_hover

func _preload_colors() -> void:
	"""Pré-define cores comuns para evitar criação repetida"""
	colors["white"] = Color(1.0, 1.0, 1.0)
	colors["black"] = Color(0.0, 0.0, 0.0)
	colors["red"] = Color(1.0, 0.0, 0.0)
	colors["green"] = Color(0.0, 1.0, 0.0)
	colors["blue"] = Color(0.0, 0.0, 1.0)
	colors["yellow"] = Color(1.0, 1.0, 0.0)
	colors["cyan"] = Color(0.0, 1.0, 1.0)
	colors["magenta"] = Color(1.0, 0.0, 1.0)


	colors["ui_text"] = Color(1.0, 1.0, 1.0)
	colors["ui_text_gold"] = Color(1.0, 0.9, 0.3)
	colors["ui_text_red"] = Color(1.0, 0.3, 0.3)
	colors["ui_text_blue"] = Color(0.8, 0.8, 1.0)
	colors["ui_text_green"] = Color(0.6, 1.0, 0.6)
	colors["ui_text_purple"] = Color(0.8, 0.2, 0.8)


	colors["preview_valid"] = Color(0.7, 0.9, 0.7, 0.7)
	colors["preview_invalid"] = Color(0.9, 0.3, 0.3, 0.7)
	colors["preview_border_valid"] = Color(0.5, 0.8, 0.5)
	colors["preview_border_invalid"] = Color(0.8, 0.2, 0.2)


	colors["damage_number"] = Color(1.0, 0.3, 0.3)
	colors["heal_number"] = Color(0.2, 0.8, 0.3)
	colors["coin_number"] = Color(1.0, 0.9, 0.3)

func get_style_box(name: String) -> StyleBoxFlat:
	return style_boxes.get(name, null) as StyleBoxFlat

func get_color(name: String) -> Color:
	"""Retorna uma cor pré-definida"""
	return colors.get(name, Color.WHITE)

func get_audio_stream(name: String) -> AudioStream:
	"""Retorna um AudioStream pré-carregado"""
	return audio_streams.get(name, null)

