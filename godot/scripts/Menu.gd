extends Control

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _try_load_music(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _ready() -> void:
	get_node("Panel/BtnPlay").pressed.connect(_on_play)
	get_node("Panel/BtnExit").pressed.connect(_on_exit)
	
	# Tentar carregar imagem de fundo, se existir
	var bg_image = get_node_or_null("BGImage")
	var bg = get_node_or_null("BG")
	var overlay = get_node_or_null("ColorOverlay")
	
	if bg_image:
		var image_path = "res://assets/images/menu_background.png"
		var bg_texture = _try_load(image_path)
		if bg_texture != null:
			# Imagem encontrada - usar ela como fundo
			print("Menu: Imagem de fundo carregada com sucesso!")
			bg_image.texture = bg_texture
			bg_image.visible = true
			# Esconder o ColorRect de fundo
			if bg:
				bg.visible = false
			# Ajustar overlay para ser mais sutil quando há imagem
			if overlay:
				overlay.color = Color(0.05, 0.05, 0.1, 0.4)
		else:
			# Imagem não encontrada - usar cor sólida
			print("Menu: Imagem de fundo não encontrada em: ", image_path)
			if bg:
				bg.visible = true
			if bg_image:
				bg_image.visible = false
			if overlay:
				overlay.color = Color(0.1, 0.1, 0.15, 0.6)
	
	# Carregar e tocar música de fundo
	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		var music = _try_load_music("res://assets/music/menu_music.ogg")
		if music == null:
			# Tentar formato alternativo
			music = _try_load_music("res://assets/music/menu_music.mp3")
		if music != null:
			# Configurar loop se for AudioStreamOggVorbis ou AudioStreamMP3
			if music is AudioStreamOggVorbis:
				music.loop = true
			elif music is AudioStreamMP3:
				music.loop = true
			music_player.stream = music
			music_player.play()
			print("Menu: Música de fundo iniciada")
		else:
			print("Menu: Música de fundo não encontrada")

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_exit() -> void:
	get_tree().quit()






