extends RefCounted
class_name ResourceManager

signal loading_progress_updated(progress: float)

var textures: Dictionary = {}
var loading_progress: float = 0.0

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
	
	# Carregar texturas de inimigos
	textures["enemy_zombie"] = load_texture("res://assets/images/enemy_zombie.png", true)
	_update_progress(0.15)
	
	textures["enemy_humanoid"] = load_texture("res://assets/images/enemy_humanoid.png", true)
	_update_progress(0.25)
	
	textures["enemy_robot"] = load_texture("res://assets/images/enemy_robot.png", true)
	_update_progress(0.30)
	
	textures["enemy_alien"] = load_texture("res://assets/images/enemy_alien.png", true)
	_update_progress(0.35)
	
	# Carregar texturas de estruturas
	textures["tent"] = load_texture("res://assets/images/tent.png", true)
	_update_progress(0.45)
	
	textures["grass"] = load_texture("res://assets/images/grass.png")
	textures["path"] = load_texture("res://assets/images/path.png")
	textures["wall"] = load_texture("res://assets/images/wall.png")
	_update_progress(0.55)
	
	# Carregar texturas de torres
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
	textures["coin"] = load_texture("res://assets/images/coin.png", true)
	textures["talism"] = load_texture("res://assets/images/talism.png", true)  # Processar fundo transparente
	textures["house"] = load_texture("res://assets/images/house.png", true)
	textures["castle"] = load_texture("res://assets/images/castle.png", true)
	textures["game_over"] = load_texture("res://assets/images/GameOver.png", false)
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
		threshold = 0.85  # Mesmo threshold padrão para talismã
	
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


