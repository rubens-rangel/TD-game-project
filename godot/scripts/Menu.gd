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
	var btn_load = get_node("Panel/VBoxContainer/BtnLoad")
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
	btn_load.add_theme_stylebox_override("normal", btn_style)
	btn_exit.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.4, 0.6, 0.8, 1.0)
	btn_play.add_theme_stylebox_override("hover", btn_hover_style)
	btn_load.add_theme_stylebox_override("hover", btn_hover_style)
	btn_exit.add_theme_stylebox_override("hover", btn_hover_style)
	
	var btn_pressed_style = btn_style.duplicate()
	btn_pressed_style.bg_color = Color(0.2, 0.4, 0.6, 1.0)
	btn_play.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_load.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_exit.add_theme_stylebox_override("pressed", btn_pressed_style)
	
	get_node("Panel/VBoxContainer/BtnPlay").pressed.connect(_on_play)
	get_node("Panel/VBoxContainer/BtnLoad").pressed.connect(_on_load)
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

func _on_load() -> void:
	_show_load_dialog()

func _on_exit() -> void:
	get_tree().quit()

func _show_load_dialog() -> void:
	const SaveManager = preload("res://scripts/managers/SaveManager.gd")
	
	# Criar diálogo de seleção de slots
	var dialog = Window.new()
	dialog.title = "Carregar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.transient = true
	
	# Container principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	# ScrollContainer para lista de slots
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)
	
	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)
	
	# Obter slots disponíveis
	var available_slots = SaveManager.list_available_slots()
	
	if available_slots.is_empty():
		var no_saves_label = Label.new()
		no_saves_label.text = "Nenhum save encontrado!"
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_list.add_child(no_saves_label)
	else:
		# Criar botão para cada slot
		for slot_info in available_slots:
			var slot_button = Button.new()
			slot_button.custom_minimum_size = Vector2(460, 60)
			slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			var slot_name = slot_info.get("slot_name", "Desconhecido")
			var wave = slot_info.get("wave", 0)
			var coins = slot_info.get("coins", 0)
			var base_hp = slot_info.get("base_hp", 100)
			var save_time = slot_info.get("save_time", "Desconhecido")
			var is_autosave = slot_info.get("is_autosave", false)
			
			# Formatar nome do slot
			var display_name = ""
			if is_autosave:
				display_name = "Auto-save"
			elif slot_name.begins_with("slot"):
				var slot_num = slot_name.substr(4)
				display_name = "Slot %s" % slot_num
			else:
				display_name = slot_name
			
			# Texto do botão
			var button_text = "%s\nWave: %d | Moedas: %d | Vida: %d\n%s" % [display_name, wave, coins, base_hp, save_time]
			slot_button.text = button_text
			
			# Estilizar botão
			var slot_style = StyleBoxFlat.new()
			slot_style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
			slot_style.corner_radius_top_left = 5
			slot_style.corner_radius_top_right = 5
			slot_style.corner_radius_bottom_left = 5
			slot_style.corner_radius_bottom_right = 5
			slot_style.border_width_left = 1
			slot_style.border_width_top = 1
			slot_style.border_width_right = 1
			slot_style.border_width_bottom = 1
			slot_style.border_color = Color(0.4, 0.5, 0.6, 1.0)
			slot_button.add_theme_stylebox_override("normal", slot_style)
			
			var slot_hover_style = slot_style.duplicate()
			slot_hover_style.bg_color = Color(0.35, 0.4, 0.45, 1.0)
			slot_button.add_theme_stylebox_override("hover", slot_hover_style)
			
			# Conectar sinal
			slot_button.pressed.connect(func(): _load_slot(slot_name, dialog))
			
			slot_list.add_child(slot_button)
	
	# Botão cancelar
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(cancel_button)
	
	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)
	
	# Ajustar layout do vbox
	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centralizar janela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()
	
	# Ajustar posição do conteúdo
	await get_tree().process_frame

func _load_slot(slot_name: String, dialog: Window) -> void:
	const SaveManager = preload("res://scripts/managers/SaveManager.gd")
	
	# Criar uma instância temporária do jogo para carregar
	# Na verdade, vamos mudar para a cena do jogo e carregar lá
	# Mas primeiro precisamos passar o slot_name de alguma forma
	# Vamos usar um autoload ou variável global temporária
	
	# Por enquanto, vamos usar uma abordagem simples: salvar o slot em uma variável global
	# ou passar via singleton. Vamos criar um singleton temporário ou usar get_tree().set_meta()
	get_tree().set_meta("load_slot", slot_name)
	
	dialog.queue_free()
	
	# Mudar para a cena do jogo
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
