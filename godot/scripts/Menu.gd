extends Control

var music_muted: bool = false
var music_volume: float = -7.0  # Volume padrão 20% mais baixo (-7.0 dB)
var music_volume_slider: HSlider = null
var music_mute_button: Button = null

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
	
	# Garantir que todos os botões tenham o mesmo tamanho
	btn_play.custom_minimum_size = Vector2(200, 40)
	btn_load.custom_minimum_size = Vector2(200, 40)
	btn_exit.custom_minimum_size = Vector2(200, 40)
	btn_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Estilo azul marinho
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.2, 0.4, 1.0)  # Azul marinho
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_left = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.2, 0.3, 0.5, 1.0)
	
	btn_play.add_theme_stylebox_override("normal", btn_style)
	btn_load.add_theme_stylebox_override("normal", btn_style)
	btn_exit.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.15, 0.3, 0.5, 1.0)  # Azul marinho mais claro no hover
	btn_play.add_theme_stylebox_override("hover", btn_hover_style)
	btn_load.add_theme_stylebox_override("hover", btn_hover_style)
	btn_exit.add_theme_stylebox_override("hover", btn_hover_style)
	
	var btn_pressed_style = btn_style.duplicate()
	btn_pressed_style.bg_color = Color(0.05, 0.15, 0.3, 1.0)  # Azul marinho mais escuro no pressed
	btn_play.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_load.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_exit.add_theme_stylebox_override("pressed", btn_pressed_style)
	
	# Conectar sinais
	btn_play.pressed.connect(_on_play)
	btn_load.pressed.connect(_on_load)
	btn_exit.pressed.connect(_on_exit)
	
	# Adicionar botão de Achievements
	var btn_achievements = Button.new()
	btn_achievements.text = "Conquistas"
	btn_achievements.custom_minimum_size = Vector2(200, 40)
	btn_achievements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_achievements.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_achievements.pressed.connect(_on_achievements)
	vbox.add_child(btn_achievements)
	
	# Adicionar botão de Perks
	var btn_perks = Button.new()
	btn_perks.text = "Melhorias"
	btn_perks.custom_minimum_size = Vector2(200, 40)
	btn_perks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_perks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_perks.pressed.connect(_on_perks)
	vbox.add_child(btn_perks)
	
	# Aplicar estilo aos novos botões
	btn_achievements.add_theme_stylebox_override("normal", btn_style)
	btn_perks.add_theme_stylebox_override("normal", btn_style)
	btn_achievements.add_theme_stylebox_override("hover", btn_hover_style)
	btn_perks.add_theme_stylebox_override("hover", btn_hover_style)
	btn_achievements.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn_perks.add_theme_stylebox_override("pressed", btn_pressed_style)
	
	# Mover o botão de sair para o final
	vbox.move_child(btn_exit, vbox.get_child_count() - 1)
	
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
	
	# Criar controles de música no canto inferior direito
	_create_music_controls()
	
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
			# Carregar configurações de volume e aplicar
			var config = ConfigFile.new()
			var config_path = "user://audio_settings.cfg"
			if config.load(config_path) == OK:
				music_volume = config.get_value("audio", "music_volume", -7.0)
				music_muted = config.get_value("audio", "music_muted", false)
			else:
				# Volume padrão 20% mais baixo
				music_volume = -7.0
				music_muted = false
			
			# Aplicar volume e mute
			if music_muted:
				music_player.volume_db = -80.0
			else:
				music_player.volume_db = music_volume
			
			# Atualizar UI dos controles
			if music_volume_slider:
				music_volume_slider.value = music_volume
			if music_mute_button:
				music_mute_button.text = "🔇" if music_muted else "🔊"
			
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

func _on_achievements() -> void:
	_show_achievements_dialog()

func _on_perks() -> void:
	_show_perks_dialog()

func _show_achievements_dialog() -> void:
	const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
	
	var achievement_manager = AchievementManager.get_instance()
	var stats = achievement_manager.get_stats()
	
	# Criar janela de achievements
	var dialog = Window.new()
	dialog.title = "Conquistas - %d/%d Desbloqueadas" % [stats.unlocked, stats.total]
	dialog.size = Vector2(900, 700)
	dialog.min_size = Vector2(800, 600)
	dialog.always_on_top = true
	dialog.transient = true
	
	# Conectar signal de fechar (botão X)
	dialog.close_requested.connect(func(): dialog.queue_free())
	
	# Container principal com padding
	var main_container = MarginContainer.new()
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	
	# Barra de estatísticas no topo - melhorada
	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(0, 80)
	
	# Estilo do painel de stats
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.15, 0.2, 0.3, 0.9)
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_style.border_width_left = 2
	stats_style.border_width_top = 2
	stats_style.border_width_right = 2
	stats_style.border_width_bottom = 2
	stats_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	
	# Padding interno
	var stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 15)
	stats_margin.add_theme_constant_override("margin_top", 12)
	stats_margin.add_theme_constant_override("margin_right", 15)
	stats_margin.add_theme_constant_override("margin_bottom", 12)
	
	var stats_label = Label.new()
	stats_label.text = "Pontos Totais: %d  |  Progresso: %.1f%%" % [stats.total_points, stats.completion_percentage]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.modulate = Color(1.0, 0.9, 0.3)
	stats_vbox.add_child(stats_label)
	
	# Barra de progresso visual
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = stats.completion_percentage
	progress_bar.custom_minimum_size = Vector2(0, 25)
	progress_bar.show_percentage = true
	stats_vbox.add_child(progress_bar)
	
	stats_margin.add_child(stats_vbox)
	stats_panel.add_child(stats_margin)
	vbox.add_child(stats_panel)
	
	# Tabs para categorias - altura ajustada
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 480)
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Categorias
	var categories = [
		{"name": "Combate", "category": AchievementManager.Category.COMBAT, "icon": "⚔️"},
		{"name": "Economia", "category": AchievementManager.Category.ECONOMY, "icon": "💰"},
		{"name": "Defesa", "category": AchievementManager.Category.DEFENSE, "icon": "🏰"},
		{"name": "Progressão", "category": AchievementManager.Category.PROGRESSION, "icon": "📈"},
		{"name": "Especiais", "category": AchievementManager.Category.SPECIAL, "icon": "⭐"}
	]
	
	for cat_info in categories:
		var scroll = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		
		var achievement_list = VBoxContainer.new()
		achievement_list.add_theme_constant_override("separation", 8)
		achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var achievements = achievement_manager.get_achievements_by_category(cat_info.category)
		
		if achievements.is_empty():
			var empty_container = CenterContainer.new()
			var empty_label = Label.new()
			empty_label.text = "Nenhuma conquista nesta categoria"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_size_override("font_size", 14)
			empty_label.modulate = Color(0.6, 0.6, 0.6)
			empty_container.add_child(empty_label)
			achievement_list.add_child(empty_container)
		else:
			for achievement in achievements:
				var achievement_panel = await _create_achievement_panel(achievement)
				achievement_list.add_child(achievement_panel)
		
		scroll.add_child(achievement_list)
		tab_container.add_child(scroll)
		tab_container.set_tab_title(tab_container.get_tab_count() - 1, cat_info.icon + " " + cat_info.name)
	
	vbox.add_child(tab_container)
	
	# Botão fechar - melhorado e sem espaço extra
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.custom_minimum_size = Vector2(0, 50)
	
	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(150, 45)
	
	# Estilo do botão fechar
	var close_btn_style = StyleBoxFlat.new()
	close_btn_style.bg_color = Color(0.4, 0.4, 0.5, 1.0)
	close_btn_style.corner_radius_top_left = 5
	close_btn_style.corner_radius_top_right = 5
	close_btn_style.corner_radius_bottom_left = 5
	close_btn_style.corner_radius_bottom_right = 5
	close_btn_style.border_width_left = 2
	close_btn_style.border_width_top = 2
	close_btn_style.border_width_right = 2
	close_btn_style.border_width_bottom = 2
	close_btn_style.border_color = Color(0.5, 0.5, 0.6, 1.0)
	close_button.add_theme_stylebox_override("normal", close_btn_style)
	
	var close_hover_style = close_btn_style.duplicate()
	close_hover_style.bg_color = Color(0.5, 0.5, 0.6, 1.0)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	
	var close_pressed_style = close_btn_style.duplicate()
	close_pressed_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	close_button.add_theme_stylebox_override("pressed", close_pressed_style)
	
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(func(): dialog.queue_free())
	
	button_container.add_child(close_button)
	vbox.add_child(button_container)
	
	main_container.add_child(vbox)
	dialog.add_child(main_container)
	get_tree().root.add_child(dialog)
	
	# Ajustar layout
	await get_tree().process_frame
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centralizar janela na tela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _create_achievement_panel(achievement: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	# Estilo do painel
	var panel_style = StyleBoxFlat.new()
	if achievement.unlocked:
		panel_style.bg_color = Color(0.2, 0.4, 0.2, 0.8)  # Verde para desbloqueado
		panel_style.border_color = Color(0.3, 0.6, 0.3, 1.0)
	else:
		panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Cinza para bloqueado
		panel_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Container horizontal
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	# Ícone
	var icon_label = Label.new()
	icon_label.text = achievement.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(50, 0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# Informações
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = achievement.name
	if achievement.unlocked:
		name_label.modulate = Color(0.8, 1.0, 0.8)  # Verde claro
	else:
		name_label.modulate = Color(0.6, 0.6, 0.6)  # Cinza
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)
	
	# Barra de progresso
	var progress_container = HBoxContainer.new()
	var progress_label = Label.new()
	if achievement.unlocked:
		progress_label.text = "✓ Desbloqueado!"
		progress_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		var progress_pct = (float(achievement.progress) / float(achievement.max_progress)) * 100.0
		progress_label.text = "%d / %d (%.0f%%)" % [achievement.progress, achievement.max_progress, progress_pct]
		progress_label.modulate = Color(1.0, 1.0, 0.5)
	progress_label.add_theme_font_size_override("font_size", 10)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_container.add_child(progress_label)
	
	var reward_label = Label.new()
	reward_label.text = "+%d pontos" % achievement.reward_points
	reward_label.add_theme_font_size_override("font_size", 10)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_container.add_child(reward_label)
	info_vbox.add_child(progress_container)
	
	hbox.add_child(info_vbox)
	panel.add_child(hbox)
	
	# Ajustar layout
	await get_tree().process_frame
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.set_offsets_preset(Control.PRESET_FULL_RECT, 5)
	
	return panel

func _show_perks_dialog() -> void:
	const PerkManager = preload("res://scripts/managers/PerkManager.gd")
	const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
	
	var perk_manager = PerkManager.get_instance()
	var achievement_manager = AchievementManager.get_instance()
	
	# Criar janela de perks
	var dialog = Window.new()
	dialog.title = "Melhorias Persistentes"
	dialog.size = Vector2(900, 650)
	dialog.min_size = Vector2(800, 550)
	dialog.always_on_top = true
	dialog.transient = true
	
	# Conectar signal de fechar (botão X)
	dialog.close_requested.connect(func(): dialog.queue_free())
	
	# Container principal com padding
	var main_container = MarginContainer.new()
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	# Barra de pontos disponíveis - melhorada
	var points_panel = Panel.new()
	points_panel.custom_minimum_size = Vector2(0, 75)
	
	# Estilo do painel de pontos
	var points_style = StyleBoxFlat.new()
	points_style.bg_color = Color(0.15, 0.2, 0.3, 0.9)
	points_style.corner_radius_top_left = 8
	points_style.corner_radius_top_right = 8
	points_style.corner_radius_bottom_left = 8
	points_style.corner_radius_bottom_right = 8
	points_style.border_width_left = 2
	points_style.border_width_top = 2
	points_style.border_width_right = 2
	points_style.border_width_bottom = 2
	points_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
	points_style.content_margin_left = 12
	points_style.content_margin_top = 10
	points_style.content_margin_right = 12
	points_style.content_margin_bottom = 10
	points_panel.add_theme_stylebox_override("panel", points_style)
	
	var points_vbox = VBoxContainer.new()
	points_vbox.add_theme_constant_override("separation", 5)
	
	var points_container = HBoxContainer.new()
	points_container.add_theme_constant_override("separation", 10)
	
	# Ícone de moedas
	var coin_icon = Label.new()
	coin_icon.text = "💰"
	coin_icon.add_theme_font_size_override("font_size", 28)
	coin_icon.custom_minimum_size = Vector2(50, 0)
	coin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_container.add_child(coin_icon)
	
	# Label de pontos
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Pontos Disponíveis: %d" % achievement_manager.total_points
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.modulate = Color(1.0, 0.9, 0.3)
	points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_container.add_child(points_label)
	
	points_vbox.add_child(points_container)
	
	# Descrição - em linha separada para evitar quebra vertical
	var points_desc = Label.new()
	points_desc.text = "Use pontos de conquistas para desbloquear melhorias permanentes"
	points_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_desc.add_theme_font_size_override("font_size", 11)
	points_desc.modulate = Color(0.7, 0.7, 0.7)
	points_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	points_vbox.add_child(points_desc)
	
	points_panel.add_child(points_vbox)
	
	# Ajustar layout do VBoxContainer
	await get_tree().process_frame
	points_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	points_vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	vbox.add_child(points_panel)
	
	# Tabs para categorias
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 480)
	tab_container.add_theme_constant_override("h_separation", 10)
	
	# Categorias
	var categories = [
		{"name": "Início", "category": PerkManager.Category.STARTING, "icon": "🚀"},
		{"name": "Economia", "category": PerkManager.Category.ECONOMY, "icon": "💰"},
		{"name": "Combate", "category": PerkManager.Category.COMBAT, "icon": "⚔️"},
		{"name": "Defesa", "category": PerkManager.Category.DEFENSE, "icon": "🛡️"}
	]
	
	for cat_info in categories:
		var scroll = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		
		var perk_list = VBoxContainer.new()
		perk_list.add_theme_constant_override("separation", 8)
		perk_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var perks = perk_manager.get_perks_by_category(cat_info.category)
		
		if perks.is_empty():
			var empty_container = CenterContainer.new()
			empty_container.custom_minimum_size = Vector2(0, 200)
			var empty_label = Label.new()
			empty_label.text = "Nenhuma melhoria nesta categoria"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_size_override("font_size", 14)
			empty_label.modulate = Color(0.6, 0.6, 0.6)
			empty_container.add_child(empty_label)
			perk_list.add_child(empty_container)
		else:
			for perk in perks:
				var perk_panel = await _create_perk_panel(perk, perk_manager, achievement_manager, dialog)
				perk_list.add_child(perk_panel)
		
		scroll.add_child(perk_list)
		tab_container.add_child(scroll)
		tab_container.set_tab_title(tab_container.get_tab_count() - 1, cat_info.icon + " " + cat_info.name)
	
	vbox.add_child(tab_container)
	
	# Botões de ação - melhorado
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END
	
	# Botão de resetar perks
	var reset_button = Button.new()
	reset_button.text = "Resetar Melhorias"
	reset_button.custom_minimum_size = Vector2(150, 45)
	reset_button.tooltip_text = "Resetar todas as melhorias persistentes (perks)"
	
	# Estilo padrão do botão (padronizado com fechar)
	var reset_btn_style = StyleBoxFlat.new()
	reset_btn_style.bg_color = Color(0.4, 0.2, 0.2, 1.0)  # Vermelho para ação destrutiva
	reset_btn_style.corner_radius_top_left = 5
	reset_btn_style.corner_radius_top_right = 5
	reset_btn_style.corner_radius_bottom_left = 5
	reset_btn_style.corner_radius_bottom_right = 5
	reset_btn_style.border_width_left = 2
	reset_btn_style.border_width_top = 2
	reset_btn_style.border_width_right = 2
	reset_btn_style.border_width_bottom = 2
	reset_btn_style.border_color = Color(0.6, 0.3, 0.3, 1.0)
	reset_button.add_theme_stylebox_override("normal", reset_btn_style)
	
	var reset_hover_style = reset_btn_style.duplicate()
	reset_hover_style.bg_color = Color(0.5, 0.3, 0.3, 1.0)
	reset_button.add_theme_stylebox_override("hover", reset_hover_style)
	
	var reset_pressed_style = reset_btn_style.duplicate()
	reset_pressed_style.bg_color = Color(0.3, 0.15, 0.15, 1.0)
	reset_button.add_theme_stylebox_override("pressed", reset_pressed_style)
	
	reset_button.add_theme_font_size_override("font_size", 14)
	reset_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	reset_button.pressed.connect(func(): _show_reset_perks_confirmation(dialog, perk_manager, achievement_manager))
	
	button_container.add_child(reset_button)
	
	# Botão fechar - melhorado
	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(150, 45)
	
	# Estilo do botão fechar
	var close_btn_style = StyleBoxFlat.new()
	close_btn_style.bg_color = Color(0.4, 0.4, 0.5, 1.0)
	close_btn_style.corner_radius_top_left = 5
	close_btn_style.corner_radius_top_right = 5
	close_btn_style.corner_radius_bottom_left = 5
	close_btn_style.corner_radius_bottom_right = 5
	close_btn_style.border_width_left = 2
	close_btn_style.border_width_top = 2
	close_btn_style.border_width_right = 2
	close_btn_style.border_width_bottom = 2
	close_btn_style.border_color = Color(0.5, 0.5, 0.6, 1.0)
	close_button.add_theme_stylebox_override("normal", close_btn_style)
	
	var close_hover_style = close_btn_style.duplicate()
	close_hover_style.bg_color = Color(0.5, 0.5, 0.6, 1.0)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	
	var close_pressed_style = close_btn_style.duplicate()
	close_pressed_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	close_button.add_theme_stylebox_override("pressed", close_pressed_style)
	
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(func(): dialog.queue_free())
	
	button_container.add_child(close_button)
	vbox.add_child(button_container)
	
	main_container.add_child(vbox)
	dialog.add_child(main_container)
	get_tree().root.add_child(dialog)
	
	# Ajustar layout
	await get_tree().process_frame
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centralizar janela na tela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()

func _create_perk_panel(perk: Dictionary, perk_manager: PerkManager, achievement_manager: AchievementManager, dialog: Window) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)
	
	# Estilo do painel - melhorado
	var panel_style = StyleBoxFlat.new()
	if perk.level > 0:
		panel_style.bg_color = Color(0.15, 0.25, 0.35, 0.9)  # Azul mais escuro para comprado
		panel_style.border_color = Color(0.4, 0.6, 0.8, 1.0)
	else:
		panel_style.bg_color = Color(0.18, 0.18, 0.22, 0.9)  # Cinza escuro para não comprado
		panel_style.border_color = Color(0.35, 0.35, 0.4, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Container principal com padding
	var main_margin = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 12)
	main_margin.add_theme_constant_override("margin_top", 10)
	main_margin.add_theme_constant_override("margin_right", 12)
	main_margin.add_theme_constant_override("margin_bottom", 10)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Linha superior: ícone, nome e nível
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Ícone - maior e mais destacado
	var icon_container = Panel.new()
	icon_container.custom_minimum_size = Vector2(55, 55)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6
	icon_container.add_theme_stylebox_override("panel", icon_style)
	
	var icon_label = Label.new()
	icon_label.text = perk.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_container.add_child(icon_label)
	top_hbox.add_child(icon_container)
	
	# Nome e nível
	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = perk.name
	if perk.level > 0:
		name_label.modulate = Color(0.8, 0.9, 1.0)
	else:
		name_label.modulate = Color(0.6, 0.6, 0.6)
	name_label.add_theme_font_size_override("font_size", 14)
	name_vbox.add_child(name_label)
	
	var level_label = Label.new()
	if perk.is_max_level:
		level_label.text = "Nível Máximo (%d/%d)" % [perk.level, perk.max_level]
		level_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		level_label.text = "Nível %d/%d" % [perk.level, perk.max_level]
		level_label.modulate = Color(1.0, 1.0, 0.5)
	level_label.add_theme_font_size_override("font_size", 11)
	name_vbox.add_child(level_label)
	
	top_hbox.add_child(name_vbox)
	
	# Botão de compra - melhorado e alinhado
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(150, 50)
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	# Armazenar o custo como metadata para facilitar atualização
	buy_button.set_meta("perk_cost", perk.cost)
	buy_button.set_meta("perk_id", perk.id)
	
	if perk.is_max_level:
		buy_button.text = "✓ Máximo"
		buy_button.disabled = true
		var max_style = StyleBoxFlat.new()
		max_style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
		max_style.corner_radius_top_left = 6
		max_style.corner_radius_top_right = 6
		max_style.corner_radius_bottom_left = 6
		max_style.corner_radius_bottom_right = 6
		max_style.border_color = Color(0.3, 0.7, 0.3, 1.0)
		max_style.border_width_left = 2
		max_style.border_width_top = 2
		max_style.border_width_right = 2
		max_style.border_width_bottom = 2
		buy_button.add_theme_stylebox_override("normal", max_style)
		buy_button.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	elif achievement_manager.total_points < perk.cost:
		buy_button.text = "💰 %d" % perk.cost
		buy_button.disabled = true
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		disabled_style.corner_radius_top_left = 6
		disabled_style.corner_radius_top_right = 6
		disabled_style.corner_radius_bottom_left = 6
		disabled_style.corner_radius_bottom_right = 6
		disabled_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
		disabled_style.border_width_left = 2
		disabled_style.border_width_top = 2
		disabled_style.border_width_right = 2
		disabled_style.border_width_bottom = 2
		buy_button.add_theme_stylebox_override("normal", disabled_style)
		buy_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		buy_button.text = "Comprar\n💰 %d" % perk.cost
		var buy_style = StyleBoxFlat.new()
		buy_style.bg_color = Color(0.2, 0.5, 0.8, 1.0)
		buy_style.corner_radius_top_left = 6
		buy_style.corner_radius_top_right = 6
		buy_style.corner_radius_bottom_left = 6
		buy_style.corner_radius_bottom_right = 6
		buy_style.border_color = Color(0.3, 0.6, 0.9, 1.0)
		buy_style.border_width_left = 2
		buy_style.border_width_top = 2
		buy_style.border_width_right = 2
		buy_style.border_width_bottom = 2
		buy_button.add_theme_stylebox_override("normal", buy_style)
		
		var buy_hover_style = buy_style.duplicate()
		buy_hover_style.bg_color = Color(0.3, 0.6, 0.9, 1.0)
		buy_button.add_theme_stylebox_override("hover", buy_hover_style)
		
		var buy_pressed_style = buy_style.duplicate()
		buy_pressed_style.bg_color = Color(0.15, 0.4, 0.7, 1.0)
		buy_button.add_theme_stylebox_override("pressed", buy_pressed_style)
		
		buy_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	buy_button.add_theme_font_size_override("font_size", 12)
	buy_button.pressed.connect(func():
		if perk_manager.purchase_perk(perk.id, achievement_manager):
			# Atualizar pontos na UI imediatamente - encontrar o label corretamente
			var points_label = _find_points_label_recursive(dialog)
			if points_label:
				points_label.text = "Pontos Disponíveis: %d" % achievement_manager.total_points
			
			# Atualizar todos os botões de compra para refletir o novo valor de pontos
			_update_all_perk_buttons(dialog, achievement_manager)
			
			# Recriar painel do perk comprado
			var parent = panel.get_parent()
			var index = parent.get_children().find(panel)
			panel.queue_free()
			await get_tree().process_frame
			var updated_perk = perk_manager.get_perk_info(perk.id)
			var new_panel = await _create_perk_panel(updated_perk, perk_manager, achievement_manager, dialog)
			parent.add_child(new_panel)
			parent.move_child(new_panel, index)
	)
	top_hbox.add_child(buy_button)
	
	main_vbox.add_child(top_hbox)
	
	# Descrição - melhorada
	var desc_label = Label.new()
	desc_label.text = perk.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if perk.level > 0:
		desc_label.modulate = Color(0.85, 0.9, 1.0)
	else:
		desc_label.modulate = Color(0.7, 0.7, 0.75)
	main_vbox.add_child(desc_label)
	
	main_margin.add_child(main_vbox)
	panel.add_child(main_margin)
	
	# Ajustar layout
	await get_tree().process_frame
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	return panel

func _find_points_label_recursive(node: Node) -> Label:
	"""Encontra o label de pontos recursivamente"""
	if node is Label and node.name == "PointsLabel":
		return node as Label
	for child in node.get_children():
		var found = _find_points_label_recursive(child)
		if found:
			return found
	return null

func _update_all_perk_buttons(dialog: Window, achievement_manager: AchievementManager) -> void:
	"""Atualiza todos os botões de compra de perks para refletir o novo valor de pontos disponíveis"""
	# Encontrar todos os ScrollContainers (um por categoria)
	var tab_container = dialog.get_node_or_null("*/MarginContainer/VBoxContainer/TabContainer")
	if not tab_container:
		return
	
	# Iterar sobre todas as abas
	for tab_idx in range(tab_container.get_tab_count()):
		var scroll = tab_container.get_child(tab_idx) as ScrollContainer
		if not scroll:
			continue
		
		var perk_list = scroll.get_child(0) as VBoxContainer
		if not perk_list:
			continue
		
		# Atualizar cada botão de compra
		for child in perk_list.get_children():
			if child is Panel:
				var panel = child as Panel
				var buy_button = _find_buy_button_recursive(panel)
				if buy_button and not buy_button.text.contains("Máximo"):
					# Obter custo do metadata ou do texto
					var cost = buy_button.get_meta("perk_cost", -1)
					if cost < 0:
						# Tentar extrair do texto como fallback
						var button_text = buy_button.text
						var cost_match = button_text.get_slice("💰", 1).strip_edges()
						if cost_match.is_valid_int():
							cost = int(cost_match)
					
					if cost > 0:
						if achievement_manager.total_points < cost:
							# Desabilitar botão e atualizar texto
							buy_button.disabled = true
							buy_button.text = "💰 %d" % cost
							var disabled_style = StyleBoxFlat.new()
							disabled_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
							disabled_style.corner_radius_top_left = 6
							disabled_style.corner_radius_top_right = 6
							disabled_style.corner_radius_bottom_left = 6
							disabled_style.corner_radius_bottom_right = 6
							disabled_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
							disabled_style.border_width_left = 2
							disabled_style.border_width_top = 2
							disabled_style.border_width_right = 2
							disabled_style.border_width_bottom = 2
							buy_button.add_theme_stylebox_override("normal", disabled_style)
							buy_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
						else:
							# Habilitar botão se tinha sido desabilitado antes
							buy_button.disabled = false
							buy_button.text = "Comprar\n💰 %d" % cost
							var buy_style = StyleBoxFlat.new()
							buy_style.bg_color = Color(0.2, 0.5, 0.8, 1.0)
							buy_style.corner_radius_top_left = 6
							buy_style.corner_radius_top_right = 6
							buy_style.corner_radius_bottom_left = 6
							buy_style.corner_radius_bottom_right = 6
							buy_style.border_color = Color(0.3, 0.6, 0.9, 1.0)
							buy_style.border_width_left = 2
							buy_style.border_width_top = 2
							buy_style.border_width_right = 2
							buy_style.border_width_bottom = 2
							buy_button.add_theme_stylebox_override("normal", buy_style)
							
							var buy_hover_style = buy_style.duplicate()
							buy_hover_style.bg_color = Color(0.3, 0.6, 0.9, 1.0)
							buy_button.add_theme_stylebox_override("hover", buy_hover_style)
							
							var buy_pressed_style = buy_style.duplicate()
							buy_pressed_style.bg_color = Color(0.15, 0.4, 0.7, 1.0)
							buy_button.add_theme_stylebox_override("pressed", buy_pressed_style)
							
							buy_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _find_buy_button_recursive(node: Node) -> Button:
	"""Encontra o botão de compra recursivamente"""
	if node is Button:
		var btn = node as Button
		if btn.text.contains("Comprar") or btn.text.contains("💰"):
			return btn
	for child in node.get_children():
		var found = _find_buy_button_recursive(child)
		if found:
			return found
	return null

func _show_reset_perks_confirmation(dialog: Window, perk_manager, achievement_manager) -> void:
	# Criar diálogo de confirmação como Window para garantir que apareça acima
	var confirm_window = Window.new()
	confirm_window.title = "Resetar Melhorias Persistentes"
	confirm_window.size = Vector2i(450, 250)
	confirm_window.min_size = Vector2i(400, 200)
	confirm_window.always_on_top = true
	confirm_window.transient = true
	confirm_window.popup_window = true  # Modal-like behavior
	
	# Container principal
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	confirm_window.add_child(main_vbox)
	
	# Texto de confirmação
	var label = Label.new()
	label.text = "Tem certeza que deseja resetar TODAS as melhorias persistentes (perks)?\n\nEsta ação não pode ser desfeita!\n\nTodas as melhorias serão removidas e os pontos gastos serão devolvidos para redistribuição."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(label)
	
	# Container de botões
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END
	
	# Botão Cancelar
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(100, 35)
	cancel_btn.pressed.connect(func():
		confirm_window.queue_free()
	)
	button_container.add_child(cancel_btn)
	
	# Botão Confirmar
	var confirm_btn = Button.new()
	confirm_btn.text = "Sim, Resetar"
	confirm_btn.custom_minimum_size = Vector2(120, 35)
	
	# Estilizar botão de confirmação (vermelho)
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.5, 0.2, 0.2, 1.0)
	confirm_style.corner_radius_top_left = 5
	confirm_style.corner_radius_top_right = 5
	confirm_style.corner_radius_bottom_left = 5
	confirm_style.corner_radius_bottom_right = 5
	confirm_style.border_width_left = 2
	confirm_style.border_width_top = 2
	confirm_style.border_width_right = 2
	confirm_style.border_width_bottom = 2
	confirm_style.border_color = Color(0.7, 0.3, 0.3, 1.0)
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	
	confirm_btn.pressed.connect(func():
		# Resetar perks e devolver pontos
		var points_refunded = perk_manager.reset_all_perks(achievement_manager)
		print("Perks resetados com sucesso! Pontos devolvidos: ", points_refunded)
		
		# Fechar o diálogo de confirmação
		confirm_window.queue_free()
		
		# Atualizar a janela de perks recriando os painéis
		# Primeiro, vamos fechar o diálogo atual e reabrir
		dialog.queue_free()
		await get_tree().process_frame
		_show_perks_dialog()
	)
	button_container.add_child(confirm_btn)
	
	main_vbox.add_child(button_container)
	
	# Adicionar à raiz da árvore para aparecer acima de tudo
	get_tree().root.add_child(confirm_window)
	
	# Centralizar na tela
	var screen_size = DisplayServer.screen_get_size()
	var window_size = confirm_window.size
	confirm_window.position = (screen_size - window_size) / 2
	
	# Mostrar janela
	confirm_window.show()

func _create_music_controls() -> void:
	"""Cria os controles de música (mute e slider) no canto inferior direito"""
	# Container para os controles de música
	var music_container = HBoxContainer.new()
	music_container.name = "MusicControls"
	music_container.add_theme_constant_override("separation", 10)
	
	# Posicionar no canto inferior direito
	music_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	music_container.offset_left = -200
	music_container.offset_top = -50
	music_container.offset_right = -10
	music_container.offset_bottom = -10
	
	# Botão de mute
	music_mute_button = Button.new()
	music_mute_button.name = "BtnMuteMusic"
	music_mute_button.custom_minimum_size = Vector2(40, 30)
	music_mute_button.text = "🔊"
	music_mute_button.tooltip_text = "Mutar/Desmutar música"
	
	# Estilo do botão
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.3, 0.4, 0.8)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_left = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.5, 0.5, 0.6, 1.0)
	music_mute_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.4, 0.4, 0.5, 0.9)
	music_mute_button.add_theme_stylebox_override("hover", btn_hover_style)
	
	var btn_pressed_style = btn_style.duplicate()
	btn_pressed_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	music_mute_button.add_theme_stylebox_override("pressed", btn_pressed_style)
	
	music_mute_button.add_theme_font_size_override("font_size", 16)
	music_mute_button.pressed.connect(_on_mute_music)
	music_container.add_child(music_mute_button)
	
	# Slider de volume
	music_volume_slider = HSlider.new()
	music_volume_slider.name = "MusicVolumeSlider"
	music_volume_slider.custom_minimum_size = Vector2(150, 30)
	music_volume_slider.min_value = -40.0
	music_volume_slider.max_value = 0.0
	music_volume_slider.step = 1.0
	music_volume_slider.value = music_volume
	music_volume_slider.tooltip_text = "Volume da música"
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	music_container.add_child(music_volume_slider)
	
	add_child(music_container)

func _on_mute_music() -> void:
	"""Alterna o estado de mute da música"""
	music_muted = not music_muted
	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		if music_muted:
			music_player.volume_db = -80.0
			music_mute_button.text = "🔇"
		else:
			music_player.volume_db = music_volume
			music_mute_button.text = "🔊"
	
	# Salvar configuração
	_save_audio_settings()

func _on_music_volume_changed(value: float) -> void:
	"""Atualiza o volume da música quando o slider é movido"""
	music_volume = value
	var music_player = get_node_or_null("MusicPlayer")
	if music_player and not music_muted:
		music_player.volume_db = music_volume
	
	# Salvar configuração
	_save_audio_settings()

func _save_audio_settings() -> void:
	"""Salva as configurações de áudio em arquivo"""
	var config = ConfigFile.new()
	var config_path = "user://audio_settings.cfg"
	
	# Carregar configurações existentes se houver
	config.load(config_path)
	
	# Salvar configurações de música
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "music_muted", music_muted)
	
	# Salvar arquivo
	config.save(config_path)
