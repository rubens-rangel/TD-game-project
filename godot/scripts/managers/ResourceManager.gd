extends RefCounted
class_name ResourceManager

signal loading_progress_updated(progress: float)

var textures: Dictionary = {}
var loading_progress: float = 0.0

# Cache de StyleBoxes (pré-criados para melhor performance)
var style_boxes: Dictionary = {}

# Cache de Colors (pré-definidos para evitar criação repetida)
var colors: Dictionary = {}

# Cache de AudioStreams (pré-carregados)
var audio_streams: Dictionary = {}

func load_texture(path: String, process: bool = false) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture = load(path)
		if process and texture != null:
			texture = _process_white_to_transparent(texture, path)
		return texture
	return null

func load_all_textures() -> void:
	loading_progress = 0.0
	loading_progress_updated.emit(0.0)
	
	textures["enemy_zombie"] = load_texture("res://assets/images/enemies/enemy_zombie.png", true)
	_update_progress(0.10)
	
	textures["enemy_zombie_gordo"] = load_texture("res://assets/images/enemies/enemy_zombie_gordo.png", true)
	_update_progress(0.12)
	
	textures["enemy_zombie_corredor"] = load_texture("res://assets/images/enemies/enemy_zombie_corredor.png", true)
	_update_progress(0.15)
	
	textures["enemy_boss"] = load_texture("res://assets/images/enemies/enemy_boss.png", true)
	_update_progress(0.18)
	
	textures["enemy_humanoid"] = load_texture("res://assets/images/enemies/enemy_humanoid.png", true)
	_update_progress(0.25)
	
	textures["enemy_robot"] = load_texture("res://assets/images/enemies/enemy_robot.png", true)
	_update_progress(0.30)
	
	textures["enemy_alien"] = load_texture("res://assets/images/enemies/enemy_alien.png", true)
	_update_progress(0.35)
	
	textures["tent"] = load_texture("res://assets/images/tent.png", true)
	_update_progress(0.45)
	
	textures["grass"] = load_texture("res://assets/images/grass.png")
	textures["path"] = load_texture("res://assets/images/path.png")
	textures["wall"] = load_texture("res://assets/images/wall.png")
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
	_update_progress(0.9)
	
	textures["barracks"] = load_texture("res://assets/images/barracks.png", true)
	textures["mine"] = load_texture("res://assets/images/mine.png", true)
	textures["wall_structure"] = load_texture("res://assets/images/wall_structure.png", true)
	textures["healing_station"] = load_texture("res://assets/images/healing_station.png", true)
	textures["market"] = load_texture("res://assets/images/market.png", true)
	textures["coin"] = load_texture("res://assets/images/coin.png", true)
	textures["talism"] = load_texture("res://assets/images/talism.png", true)
	textures["house"] = load_texture("res://assets/images/house.png", true)
	textures["castle"] = load_texture("res://assets/images/castle.png", true)
	textures["Caste2"] = load_texture("res://assets/images/Caste2.png", true)
	textures["game_over"] = load_texture("res://assets/images/GameOver.png", false)
	_update_progress(0.95)
	
	# Pré-carregar sons
	_preload_audio_streams()
	_update_progress(0.97)
	
	# Pré-criar StyleBoxes comuns
	_preload_style_boxes()
	_update_progress(0.99)
	
	# Pré-definir cores comuns
	_preload_colors()
	_update_progress(1.0)

func _update_progress(progress: float) -> void:
	loading_progress = progress
	loading_progress_updated.emit(progress)

func get_texture(name: String) -> Texture2D:
	return textures.get(name, null)

func _process_white_to_transparent(texture: Texture2D, image_path: String) -> Texture2D:
	var image: Image = null
	
	if texture.has_method("get_image"):
		image = texture.get_image()
	
	if image == null:
		if ResourceLoader.exists(image_path):
			image = Image.new()
			var error = image.load(image_path)
			if error != OK:
				return texture
	
	if image == null:
		return texture
	
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	
	var threshold = 0.85
	if "slow_tower" in image_path:
		threshold = 0.82
	elif "tower.png" in image_path:
		threshold = 0.78
	elif "talism" in image_path:
		threshold = 0.85
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			var is_white = pixel.r >= threshold and pixel.g >= threshold and pixel.b >= threshold
			var is_transparent = pixel.a < 0.1
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			var is_bright = brightness >= threshold
			
			if is_white or is_transparent or is_bright:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))
	
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture

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
		# Só adicionar se a chave ainda não existe (evitar sobrescrever)
		if not audio_streams.has(key) and ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				audio_streams[key] = stream

func _preload_style_boxes() -> void:
	"""Pré-cria StyleBoxes comuns para evitar criação repetida"""
	# TopBar style
	var top_bar_style = StyleBoxFlat.new()
	top_bar_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	top_bar_style.border_color = Color(0.3, 0.3, 0.4)
	top_bar_style.border_width_bottom = 2
	style_boxes["top_bar"] = top_bar_style
	
	# BottomBar style
	var bottom_bar_style = StyleBoxFlat.new()
	bottom_bar_style.bg_color = Color(0.1, 0.1, 0.15, 0.6)
	bottom_bar_style.border_color = Color(0.3, 0.3, 0.4, 0.6)
	bottom_bar_style.border_width_top = 2
	style_boxes["bottom_bar"] = bottom_bar_style
	
	# Button normal style
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
	
	# Button hover style
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
	
	# Admin button style
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
	
	# Cores de UI
	colors["ui_text"] = Color(1.0, 1.0, 1.0)
	colors["ui_text_gold"] = Color(1.0, 0.9, 0.3)
	colors["ui_text_red"] = Color(1.0, 0.3, 0.3)
	colors["ui_text_blue"] = Color(0.8, 0.8, 1.0)
	colors["ui_text_green"] = Color(0.6, 1.0, 0.6)
	colors["ui_text_purple"] = Color(0.8, 0.2, 0.8)
	
	# Cores de preview
	colors["preview_valid"] = Color(0.7, 0.9, 0.7, 0.7)
	colors["preview_invalid"] = Color(0.9, 0.3, 0.3, 0.7)
	colors["preview_border_valid"] = Color(0.5, 0.8, 0.5)
	colors["preview_border_invalid"] = Color(0.8, 0.2, 0.2)
	
	# Cores de efeitos
	colors["damage_number"] = Color(1.0, 0.3, 0.3)
	colors["heal_number"] = Color(0.2, 0.8, 0.3)
	colors["coin_number"] = Color(1.0, 0.9, 0.3)

func get_style_box(name: String) -> StyleBoxFlat:
	"""Retorna um StyleBox pré-criado (cria cópia para evitar modificações)"""
	if style_boxes.has(name):
		var original = style_boxes[name] as StyleBoxFlat
		var copy = StyleBoxFlat.new()
		copy.bg_color = original.bg_color
		copy.border_color = original.border_color
		copy.border_width_left = original.border_width_left
		copy.border_width_top = original.border_width_top
		copy.border_width_right = original.border_width_right
		copy.border_width_bottom = original.border_width_bottom
		copy.corner_radius_top_left = original.corner_radius_top_left
		copy.corner_radius_top_right = original.corner_radius_top_right
		copy.corner_radius_bottom_left = original.corner_radius_bottom_left
		copy.corner_radius_bottom_right = original.corner_radius_bottom_right
		return copy
	return null

func get_color(name: String) -> Color:
	"""Retorna uma cor pré-definida"""
	return colors.get(name, Color.WHITE)

func get_audio_stream(name: String) -> AudioStream:
	"""Retorna um AudioStream pré-carregado"""
	return audio_streams.get(name, null)


