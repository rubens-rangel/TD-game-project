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
	# Configurar bordas arredondadas no Panel
	var panel = get_node("Panel")
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.5, 1.0)
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Centralizar conteúdo do VBoxContainer e adicionar padding
	var vbox = get_node("Panel/VBoxContainer")
	vbox.add_theme_constant_override("separation", 15)
	
	# Adicionar padding ao painel através do style_box
	style_box.content_margin_left = 20
	style_box.content_margin_top = 20
	style_box.content_margin_right = 20
	style_box.content_margin_bottom = 20
	# Reaplicar o style_box após adicionar padding
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Estilizar os botões
	var btn_play = get_node("Panel/VBoxContainer/BtnPlay")
	var btn_exit = get_node("Panel/VBoxContainer/BtnExit")
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.5, 0.7, 1.0)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_left = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.5, 0.7, 0.9, 1.0)
	
	btn_play.add_theme_stylebox_override("normal", btn_style)
	btn_exit.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.4, 0.6, 0.8, 1.0)
	btn_play.add_theme_stylebox_override("hover", btn_hover_style)
	btn_exit.add_theme_stylebox_override("hover", btn_hover_style)
	
	var btn_pressed_style = btn_style.duplicate()
	btn_pressed_style.bg_color = Color(0.2, 0.4, 0.6, 1.0)
	btn_play.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_exit.add_theme_stylebox_override("pressed", btn_pressed_style)
	
	get_node("Panel/VBoxContainer/BtnPlay").pressed.connect(_on_play)
	get_node("Panel/VBoxContainer/BtnExit").pressed.connect(_on_exit)
	
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






