extends Control

const ButtonHoverHelper = preload("res://scripts/helpers/ButtonHoverHelper.gd")
const ToastOverlayScript = preload("res://scripts/ui/ToastOverlay.gd")
const SettingsDialogScript = preload("res://scripts/ui/SettingsDialog.gd")
const TutorialOverlayScript = preload("res://scripts/ui/TutorialOverlay.gd")
const NotificationManager = preload("res://scripts/managers/NotificationManager.gd")

func _cfg() -> Node:
	return get_node_or_null("/root/GameConfig")

var music_muted: bool = false
var music_volume: float = -7.0
var music_volume_slider: HSlider = null
var music_mute_button: Button = null
var notification_manager: NotificationManager
var progression_hub: Window

func _try_load(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return load(path)
	var max_side := 1024
	var w: int = image.get_width()
	var h: int = image.get_height()
	if w > max_side or h > max_side:
		var scale: float = float(max_side) / float(maxi(w, h))
		image.resize(maxi(1, int(w * scale)), maxi(1, int(h * scale)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func _try_load_music(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _ready() -> void:

	var panel = get_node("Panel")
	panel.add_theme_stylebox_override("panel", UIHelper.panel_style())
	panel.clip_contents = true

	var vbox = get_node("Panel/VBoxContainer")
	vbox.add_theme_constant_override("separation", 14)

	var btn_play = get_node("Panel/VBoxContainer/BtnPlay")
	var btn_load = get_node("Panel/VBoxContainer/BtnLoad")
	var btn_exit = get_node("Panel/VBoxContainer/BtnExit")

	var title = Label.new()
	title.text = "DEFESA DO LABIRINTO"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.move_child(title, 0)

	var subtitle = Label.new()
	subtitle.text = "Tower Defense · Sobreviva às ondas"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.6, 0.78))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	vbox.move_child(subtitle, 1)

	var stats_panel = PanelContainer.new()
	var stats_style = UIHelper.card_style()
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 16)
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
	const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
	var ach_mgr = AchievementManager.get_instance()
	var cur_mgr = SpecialCurrencyManager.new()
	var cur_info = cur_mgr.get_currency_info()
	var pts_lbl = Label.new()
	pts_lbl.text = "🏆 %d pts" % ach_mgr.total_points
	pts_lbl.add_theme_font_size_override("font_size", 13)
	pts_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	stats_hbox.add_child(pts_lbl)
	var dia_lbl = Label.new()
	dia_lbl.text = "💎 %d" % cur_info.diamonds
	dia_lbl.add_theme_font_size_override("font_size", 13)
	dia_lbl.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0))
	stats_hbox.add_child(dia_lbl)
	stats_panel.add_child(stats_hbox)
	vbox.add_child(stats_panel)
	vbox.move_child(stats_panel, 2)

	btn_play.custom_minimum_size = Vector2(320, 50)
	btn_load.custom_minimum_size = Vector2(320, 46)
	btn_exit.custom_minimum_size = Vector2(320, 42)
	btn_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	UIHelper.apply_button_theme(btn_play, UIHelper.BTN_PRIMARY)
	UIHelper.apply_button_theme(btn_load, UIHelper.BTN_PRIMARY)
	UIHelper.apply_button_theme(btn_exit, UIHelper.BTN_DANGER)
	btn_play.add_theme_font_size_override("font_size", 18)
	btn_load.add_theme_font_size_override("font_size", 18)
	btn_exit.add_theme_font_size_override("font_size", 18)

	btn_play.text = "  ▶  Jogar"
	btn_play.pressed.connect(_on_play)
	btn_load.pressed.connect(_on_load)
	btn_exit.pressed.connect(_on_exit)

	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	var btn_progression_prestige = Button.new()
	btn_progression_prestige.text = "  📈  Progressão & Prestígio"
	btn_progression_prestige.custom_minimum_size = Vector2(240, 44)
	btn_progression_prestige.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_progression_prestige.pressed.connect(_on_progression_prestige)
	vbox.add_child(btn_progression_prestige)
	UIHelper.apply_button_theme(btn_progression_prestige, UIHelper.BTN_SECONDARY)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var btn_quests = Button.new()
	btn_quests.text = "  Missões"
	btn_quests.custom_minimum_size = Vector2(240, 44)
	btn_quests.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_quests.pressed.connect(_on_quests)
	vbox.add_child(btn_quests)
	UIHelper.apply_button_theme(btn_quests, UIHelper.BTN_SECONDARY)

	var btn_howto = Button.new()
	btn_howto.text = "  Como jogar"
	btn_howto.custom_minimum_size = Vector2(240, 44)
	btn_howto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_howto.pressed.connect(_on_how_to_play)
	vbox.add_child(btn_howto)
	UIHelper.apply_button_theme(btn_howto, UIHelper.BTN_SECONDARY)

	var btn_options = Button.new()
	btn_options.text = "  Opções"
	btn_options.custom_minimum_size = Vector2(240, 44)
	btn_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_options.pressed.connect(_on_options)
	vbox.add_child(btn_options)
	UIHelper.apply_button_theme(btn_options, UIHelper.BTN_SECONDARY)

	vbox.move_child(btn_exit, vbox.get_child_count() - 1)


	var bg_image = get_node_or_null("BGImage")
	var bg = get_node_or_null("BG")
	var overlay = get_node_or_null("ColorOverlay")

	if bg_image:
		var image_path = "res://assets/images/menu_background.png"
		var bg_texture = _try_load(image_path)
		if bg_texture != null:

			print("Menu: Imagem de fundo carregada com sucesso!")
			bg_image.texture = bg_texture
			bg_image.visible = true

			if bg:
				bg.visible = false

			if overlay:
				overlay.color = Color(0.04, 0.05, 0.12, 0.45)
		else:

			print("Menu: Imagem de fundo não encontrada em: ", image_path)
			if bg:
				bg.visible = true
			if bg_image:
				bg_image.visible = false
			if overlay:
				overlay.color = Color(0.1, 0.1, 0.15, 0.6)


	_create_music_controls()


	var music_player = get_node_or_null("MusicPlayer")
	if music_player:
		var music = _try_load_music("res://assets/music/menu_music.ogg")
		if music == null:

			music = _try_load_music("res://assets/music/menu_music.mp3")
		if music != null:

			if music is AudioStreamOggVorbis:
				music.loop = true
			elif music is AudioStreamMP3:
				music.loop = true
			music_player.stream = music

			var config = ConfigFile.new()
			var config_path = "user://audio_settings.cfg"
			if config.load(config_path) == OK:
				music_volume = config.get_value("audio", "music_volume", -7.0)
				music_muted = config.get_value("audio", "music_muted", false)
			else:

				music_volume = -7.0
				music_muted = false


			if music_muted:
				music_player.volume_db = -80.0
			else:
				music_player.volume_db = music_volume


			if music_volume_slider:
				music_volume_slider.value = music_volume
			if music_mute_button:
				music_mute_button.text = "🔇" if music_muted else "🔊"

			music_player.play()
			print("Menu: Música de fundo iniciada")
		else:
			print("Menu: Música de fundo não encontrada")

	notification_manager = NotificationManager.new()
	var toast := ToastOverlayScript.new()
	toast.name = "ToastOverlay"
	add_child(toast)
	toast.setup(notification_manager)

func _on_how_to_play() -> void:
	if has_node("TutorialOverlay"):
		return
	var overlay := TutorialOverlayScript.new()
	overlay.name = "TutorialOverlay"
	add_child(overlay)

func _on_options() -> void:
	var dlg := SettingsDialogScript.new(music_volume)
	dlg.music_volume_changed.connect(func(v: float):
		music_volume = v
		music_muted = false
		var music_player = get_node_or_null("MusicPlayer")
		if music_player:
			music_player.volume_db = music_volume
		if music_volume_slider:
			music_volume_slider.value = music_volume
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", music_volume)
		config.set_value("audio", "music_muted", music_muted)
		config.save("user://audio_settings.cfg")
	)
	add_child(dlg)

func _on_play() -> void:
	_show_play_mode_dialog()

func _show_play_mode_dialog() -> void:
	if get_node_or_null("UiModalOverlay"):
		return
	var body := UIHelper.present_modal(self, Vector2(640, 260))
	var overlay: Control = body.get_meta("modal_root")

	var header := HBoxContainer.new()
	var title := UIHelper.create_label("Como deseja jogar?", 22, UIHelper.TITLE_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var close_btn := UIHelper.secondary_button("✕", Vector2(36, 36))
	close_btn.pressed.connect(func(): overlay.queue_free())
	header.add_child(close_btn)
	body.add_child(header)

	var subtitle := UIHelper.create_label("Escolha um modo para começar", 14, Color(0.65, 0.68, 0.78))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(subtitle)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn_normal := UIHelper.primary_button("JOGAR NORMAL", Vector2(280, 88))
	btn_normal.add_theme_font_size_override("font_size", 18)
	btn_normal.pressed.connect(func():
		overlay.queue_free()
		var c = _cfg()
		if c:
			c.start_normal_mode()
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
	hbox.add_child(btn_normal)

	var btn_custom := UIHelper.secondary_button("JOGAR PERSONALIZADO", Vector2(280, 88))
	btn_custom.add_theme_font_size_override("font_size", 18)
	btn_custom.pressed.connect(func():
		overlay.queue_free()
		const CustomGameConfig = preload("res://scripts/CustomGameConfig.gd")
		var config_win = CustomGameConfig.new()
		get_tree().root.add_child(config_win)
		config_win.popup_centered()
	)
	hbox.add_child(btn_custom)
	body.add_child(hbox)

	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			overlay.queue_free()
	)

func _on_load() -> void:
	_show_load_dialog()

func _on_exit() -> void:
	get_tree().quit()

func _show_load_dialog() -> void:
	const SaveManager = preload("res://scripts/managers/SaveManager.gd")


	var dialog = Window.new()
	dialog.title = "Carregar Jogo"
	dialog.size = Vector2(520, 450)
	dialog.min_size = Vector2(500, 400)
	dialog.always_on_top = true
	dialog.transient = true
	UIHelper.apply_window_theme(dialog)


	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)


	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)

	var slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 5)
	scroll.add_child(slot_list)
	vbox.add_child(scroll)


	var available_slots = SaveManager.list_available_slots()

	if available_slots.is_empty():
		var no_saves_label = Label.new()
		no_saves_label.text = "Nenhum save encontrado!"
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_list.add_child(no_saves_label)
	else:

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


			var display_name = ""
			if is_autosave:
				display_name = "Auto-save"
			elif slot_name.begins_with("slot"):
				var slot_num = slot_name.substr(4)
				display_name = "Slot %s" % slot_num
			else:
				display_name = slot_name


			var button_text = "%s\nWave: %d | Moedas: %d | Vida: %d\n%s" % [display_name, wave, coins, base_hp, save_time]
			slot_button.text = button_text


			UIHelper.apply_button_theme(slot_button, UIHelper.BTN_SECONDARY)
			slot_button.add_theme_font_size_override("font_size", 13)


			slot_button.pressed.connect(func(): _load_slot(slot_name, dialog))

			slot_list.add_child(slot_button)


	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(480, 40)
	cancel_button.pressed.connect(func(): dialog.queue_free())
	UIHelper.apply_button_theme(cancel_button, UIHelper.BTN_SECONDARY)
	vbox.add_child(cancel_button)

	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)


	await get_tree().process_frame
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)


	var screen_size = DisplayServer.screen_get_size()
	var window_size = dialog.size
	dialog.position = (screen_size - window_size) / 2
	dialog.show()


	await get_tree().process_frame

func _load_slot(slot_name: String, dialog: Window) -> void:
	var c = _cfg()
	if c:
		c.start_normal_mode()
	const SaveManager = preload("res://scripts/managers/SaveManager.gd")








	get_tree().set_meta("load_slot", slot_name)

	dialog.queue_free()


	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_achievements() -> void:
	_show_achievements_dialog()

func _on_perks() -> void:
	_show_perks_dialog()

func _on_quests() -> void:
	_show_quests_dialog()

func _on_prestige() -> void:
	_show_prestige_dialog()

func _on_progression_prestige() -> void:
	_show_progression_prestige_menu()

func _show_progression_prestige_menu() -> void:
	var dialog = Window.new()
	dialog.title = "Progressão & Prestígio"
	dialog.size = Vector2i(480, 420)
	dialog.min_size = Vector2i(420, 360)
	dialog.transient = true
	dialog.unresizable = true
	UIHelper.apply_window_theme(dialog)
	dialog.close_requested.connect(func():
		progression_hub = null
		dialog.queue_free()
	)
	progression_hub = dialog

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIHelper.window_fill_style())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)

	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(400, 280)

	var tab_prog_scroll = ScrollContainer.new()
	tab_prog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_prog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var tab_progression = VBoxContainer.new()
	tab_progression.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_progression.add_theme_constant_override("separation", 12)
	var prog_label = Label.new()
	prog_label.text = "Desbloqueie bônus com pontos de conquistas"
	prog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prog_label.add_theme_font_size_override("font_size", 13)
	prog_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	tab_progression.add_child(prog_label)

	var btn_achievements = Button.new()
	btn_achievements.text = "  🏆  Conquistas"
	btn_achievements.custom_minimum_size = Vector2(0, 48)
	btn_achievements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_achievements.pressed.connect(func():
		dialog.hide()
		_show_achievements_dialog(dialog)
	)
	_style_secondary_button(btn_achievements)
	tab_progression.add_child(btn_achievements)

	var btn_perks = Button.new()
	btn_perks.text = "  ⭐  Melhorias Persistentes"
	btn_perks.custom_minimum_size = Vector2(0, 48)
	btn_perks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_perks.pressed.connect(func():
		dialog.hide()
		_show_perks_dialog(dialog)
	)
	_style_secondary_button(btn_perks)
	tab_progression.add_child(btn_perks)
	tab_prog_scroll.add_child(tab_progression)
	tabs.add_child(tab_prog_scroll)
	tabs.set_tab_title(0, "📈 Progressão")

	var tab_prest_scroll = ScrollContainer.new()
	tab_prest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_prest_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var tab_prestige = VBoxContainer.new()
	tab_prestige.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_prestige.add_theme_constant_override("separation", 12)
	const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
	var currency_manager = SpecialCurrencyManager.new()
	var currency_info = currency_manager.get_currency_info()
	var diamonds_label = Label.new()
	diamonds_label.text = "💎 Diamantes: %d" % currency_info.diamonds
	diamonds_label.add_theme_font_size_override("font_size", 20)
	diamonds_label.add_theme_color_override("font_color", Color(0.5, 0.78, 1.0))
	tab_prestige.add_child(diamonds_label)

	var prest_label = Label.new()
	prest_label.text = "Bônus permanentes comprados com diamantes (concedidos em marcos do jogo)."
	prest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prest_label.add_theme_font_size_override("font_size", 13)
	prest_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	tab_prestige.add_child(prest_label)

	var btn_prestige = Button.new()
	btn_prestige.text = "  💎  Abrir Loja de Prestígio"
	btn_prestige.custom_minimum_size = Vector2(0, 48)
	btn_prestige.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_prestige.pressed.connect(func():
		dialog.hide()
		_show_prestige_dialog(dialog)
	)
	_style_secondary_button(btn_prestige)
	tab_prestige.add_child(btn_prestige)
	tab_prest_scroll.add_child(tab_prestige)
	tabs.add_child(tab_prest_scroll)
	tabs.set_tab_title(1, "💎 Prestígio")

	vbox.add_child(tabs)

	var btn_close = Button.new()
	btn_close.text = "Fechar"
	btn_close.custom_minimum_size = Vector2(120, 36)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_close.pressed.connect(dialog.queue_free)
	_style_secondary_button(btn_close)
	vbox.add_child(btn_close)

	margin.add_child(vbox)
	panel.add_child(margin)
	dialog.add_child(panel)
	add_child(dialog)
	dialog.popup_centered()

func _style_secondary_button(btn: Button) -> void:
	UIHelper.apply_button_theme(btn, UIHelper.BTN_SECONDARY)
	btn.add_theme_font_size_override("font_size", 16)

func _restore_parent_dialog(dialog: Window, return_to: Window) -> void:
	if is_instance_valid(dialog):
		dialog.queue_free()
	if return_to and is_instance_valid(return_to):
		return_to.show()
		return_to.popup_centered()

func _show_prestige_dialog(return_to: Window = null) -> void:
	const PrestigeShop = preload("res://scripts/managers/PrestigeShop.gd")
	const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
	const GameConstants = preload("res://scripts/Constants.gd")

	var prestige_shop = PrestigeShop.new()
	var currency_manager = SpecialCurrencyManager.new()
	var currency_info = currency_manager.get_currency_info()
	var upgrades_info = prestige_shop.get_all_upgrades_info()

	var dialog = Window.new()
	dialog.title = "Loja de Prestígio"
	dialog.size = Vector2i(760, 660)
	dialog.min_size = Vector2i(640, 520)
	dialog.transient = true
	dialog.unresizable = false
	UIHelper.apply_window_theme(dialog)
	dialog.close_requested.connect(dialog.queue_free)

	var root_panel = PanelContainer.new()
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_panel.add_theme_stylebox_override("panel", UIHelper.window_fill_style())

	var main = MarginContainer.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("margin_left", 20)
	main.add_theme_constant_override("margin_top", 16)
	main.add_theme_constant_override("margin_right", 20)
	main.add_theme_constant_override("margin_bottom", 16)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)

	# Cabeçalho: saldo + explicação
	var header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", UIHelper.card_style())

	var header_v = VBoxContainer.new()
	header_v.add_theme_constant_override("separation", 6)
	var saldo = Label.new()
	saldo.text = "💎 Seus diamantes: %d" % currency_info.diamonds
	saldo.add_theme_font_size_override("font_size", 22)
	saldo.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	header_v.add_child(saldo)
	var hint = Label.new()
	hint.text = "Gaste diamantes para desbloquear bônus permanentes. Clique em Comprar em cada item."
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_v.add_child(hint)
	header.add_child(header_v)
	vbox.add_child(header)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 400)

	var sections_vbox = VBoxContainer.new()
	sections_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections_vbox.add_theme_constant_override("separation", 16)

	# ---- Seção: Bônus permanentes ----
	var bonus_array = []
	bonus_array.append({"name": "Multiplicador de Recompensas", "description": "+10% recompensa de moedas por nível.", "cost": GameConstants.PRESTIGE_COST_REWARD_MULTIPLIER, "type": "reward_multiplier", "level": upgrades_info.diamond_upgrades.reward_multiplier, "max_level": -1})
	bonus_array.append({"name": "HP da Base", "description": "+20 HP máximo da base por nível.", "cost": GameConstants.PRESTIGE_COST_BASE_HP_BOOST, "type": "base_hp_boost", "level": upgrades_info.diamond_upgrades.get("base_hp_boost", 0), "max_level": -1})
	bonus_array.append({"name": "Dano do Herói", "description": "+15% dano do herói por nível.", "cost": GameConstants.PRESTIGE_COST_HERO_DAMAGE_BOOST, "type": "hero_damage_boost", "level": upgrades_info.diamond_upgrades.get("hero_damage_boost", 0), "max_level": -1})
	bonus_array.append({"name": "Drop de Moedas", "description": "+3% chance de inimigos droparem moedas por nível.", "cost": GameConstants.PRESTIGE_COST_COIN_DROP_BOOST, "type": "coin_drop_boost", "level": upgrades_info.diamond_upgrades.get("coin_drop_boost", 0), "max_level": -1})
	bonus_array.append({"name": "Moedas Iniciais", "description": "+50 moedas no início da partida por nível.", "cost": GameConstants.PRESTIGE_COST_STARTING_COINS_BOOST, "type": "starting_coins_boost", "level": upgrades_info.diamond_upgrades.get("starting_coins_boost", 0), "max_level": -1})

	sections_vbox.add_child(_make_section_header("Bônus permanentes"))
	var bonus_list = VBoxContainer.new()
	bonus_list.add_theme_constant_override("separation", 10)
	for d in bonus_array:
		var p = _create_prestige_upgrade_panel(d.name, d.description, d.cost, currency_info.diamonds, d.type, d.level, d.max_level, prestige_shop, currency_manager, dialog)
		if d.max_level == 1 and d.level > 0:
			p.modulate = Color(0.55, 0.55, 0.55)
		bonus_list.add_child(p)
	sections_vbox.add_child(bonus_list)

	# ---- Seção: Variantes de torres ----
	var tower_array = []
	tower_array.append({"name": "Flechas Corrosivas", "description": "Torres básicas aplicam dano contínuo (corrosivo).", "cost": GameConstants.PRESTIGE_COST_TOWER_ARROW_CORROSIVE, "type": "tower_arrow_corrosive", "level": 1 if upgrades_info.diamond_upgrades.get("tower_arrow_corrosive", false) else 0, "max_level": 1})
	tower_array.append({"name": "Gelo Profundo", "description": "Slow Towers reduzem mais a velocidade dos inimigos.", "cost": GameConstants.PRESTIGE_COST_SLOW_TOWER_FROST, "type": "slow_tower_frost", "level": 1 if upgrades_info.diamond_upgrades.get("slow_tower_frost", false) else 0, "max_level": 1})
	tower_array.append({"name": "Explosão Incendiária", "description": "Torre AOE causa mais dano na área.", "cost": GameConstants.PRESTIGE_COST_AOE_TOWER_INFERNO, "type": "aoe_tower_inferno", "level": 1 if upgrades_info.diamond_upgrades.get("aoe_tower_inferno", false) else 0, "max_level": 1})
	tower_array.append({"name": "Disparo Perfurante", "description": "Sniper perfura mais inimigos e causa mais dano.", "cost": GameConstants.PRESTIGE_COST_SNIPER_TOWER_PIERCE, "type": "sniper_tower_pierce", "level": 1 if upgrades_info.diamond_upgrades.get("sniper_tower_pierce", false) else 0, "max_level": 1})
	tower_array.append({"name": "Corrente Estendida", "description": "Shock Towers encadeiam em mais alvos.", "cost": GameConstants.PRESTIGE_COST_SHOCK_TOWER_CHAIN, "type": "shock_tower_chain", "level": 1 if upgrades_info.diamond_upgrades.get("shock_tower_chain", false) else 0, "max_level": 1})
	tower_array.append({"name": "Aura Suprema", "description": "Boost Towers amplificam mais as torres próximas.", "cost": GameConstants.PRESTIGE_COST_BOOST_TOWER_AURA, "type": "boost_tower_aura", "level": 1 if upgrades_info.diamond_upgrades.get("boost_tower_aura", false) else 0, "max_level": 1})

	sections_vbox.add_child(_make_section_header("Variantes de torres"))
	var tower_list = VBoxContainer.new()
	tower_list.add_theme_constant_override("separation", 10)
	for d in tower_array:
		var p = _create_prestige_upgrade_panel(d.name, d.description, d.cost, currency_info.diamonds, d.type, d.level, d.max_level, prestige_shop, currency_manager, dialog)
		if d.max_level == 1 and d.level > 0:
			p.modulate = Color(0.55, 0.55, 0.55)
		tower_list.add_child(p)
	sections_vbox.add_child(tower_list)

	scroll.add_child(sections_vbox)
	vbox.add_child(scroll)

	var close_btn = Button.new()
	close_btn.text = "Voltar" if return_to else "Fechar"
	close_btn.custom_minimum_size = Vector2(140, 42)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func(): _restore_parent_dialog(dialog, return_to))
	_style_secondary_button(close_btn)
	vbox.add_child(close_btn)

	root_panel.add_child(main)
	dialog.add_child(root_panel)
	dialog.set_meta("return_to", return_to)
	dialog.close_requested.connect(func(): _restore_parent_dialog(dialog, return_to))
	add_child(dialog)
	dialog.popup_centered()

func _purchase_prestige_upgrade(upgrade_type: String, prestige_shop: PrestigeShop, currency_manager: SpecialCurrencyManager) -> bool:
	match upgrade_type:
		"reward_multiplier":
			return prestige_shop.purchase_reward_multiplier(currency_manager)
		"base_hp_boost":
			return prestige_shop.purchase_base_hp_boost(currency_manager)
		"hero_damage_boost":
			return prestige_shop.purchase_hero_damage_boost(currency_manager)
		"coin_drop_boost":
			return prestige_shop.purchase_coin_drop_boost(currency_manager)
		"starting_coins_boost":
			return prestige_shop.purchase_starting_coins_boost(currency_manager)
		"tower_arrow_corrosive":
			return prestige_shop.purchase_tower_arrow_corrosive(currency_manager)
		"slow_tower_frost":
			return prestige_shop.purchase_slow_tower_frost(currency_manager)
		"aoe_tower_inferno":
			return prestige_shop.purchase_aoe_tower_inferno(currency_manager)
		"sniper_tower_pierce":
			return prestige_shop.purchase_sniper_tower_pierce(currency_manager)
		"shock_tower_chain":
			return prestige_shop.purchase_shock_tower_chain(currency_manager)
		"boost_tower_aura":
			return prestige_shop.purchase_boost_tower_aura(currency_manager)
	return false

func _make_section_header(title: String) -> Control:
	var h = Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	return h

func _create_prestige_upgrade_panel(name: String, description: String, cost: int, available_diamonds: int, upgrade_type: String, current_level: int, max_level: int, prestige_shop: PrestigeShop, currency_manager: SpecialCurrencyManager, dialog: Window) -> Panel:
	"""Cria painel legível para uma melhoria de prestígio."""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 92)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_maxed = max_level > 0 and current_level >= max_level
	var is_unique_bought = max_level == 1 and current_level > 0
	var can_afford = available_diamonds >= cost

	var panel_style: StyleBoxFlat
	if is_maxed or is_unique_bought:
		panel_style = UIHelper.card_style(Color(0.4, 0.45, 0.5, 1.0), Color(0.18, 0.18, 0.2, 1.0))
	elif can_afford:
		panel_style = UIHelper.card_style(Color(0.25, 0.55, 0.75, 1.0), Color(0.14, 0.22, 0.32, 1.0))
	else:
		panel_style = UIHelper.card_style()
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	# Custo à esquerda
	var cost_box = VBoxContainer.new()
	cost_box.custom_minimum_size = Vector2(72, 0)
	cost_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var cost_lbl = Label.new()
	cost_lbl.text = "💎 %d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_box.add_child(cost_lbl)
	var status_lbl = Label.new()
	if is_maxed or is_unique_bought:
		status_lbl.text = "✓ Ativo"
		status_lbl.add_theme_color_override("font_color", Color(0.45, 0.9, 0.5))
	elif can_afford:
		status_lbl.text = "Disponível"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.55))
	else:
		status_lbl.text = "Faltam %d" % (cost - available_diamonds)
		status_lbl.add_theme_color_override("font_color", Color(0.95, 0.5, 0.45))
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_box.add_child(status_lbl)
	hbox.add_child(cost_box)

	# Nome + descrição (expandível)
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 4)
	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	text_vbox.add_child(name_lbl)
	var desc_lbl = Label.new()
	desc_lbl.text = description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.92))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(desc_lbl)
	if max_level != 1:
		var lvl = Label.new()
		if max_level > 0:
			lvl.text = "Nível %d / %d" % [current_level, max_level]
		else:
			lvl.text = "Nível %d" % current_level
		lvl.add_theme_font_size_override("font_size", 12)
		lvl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.95))
		text_vbox.add_child(lvl)
	hbox.add_child(text_vbox)

	if not is_maxed and not is_unique_bought:
		var buy_btn = Button.new()
		buy_btn.text = "Desbloquear" if max_level == 1 else "Comprar"
		buy_btn.custom_minimum_size = Vector2(108, 38)
		buy_btn.disabled = not can_afford
		var menu_self = self
		buy_btn.pressed.connect(func():
			if not can_afford:
				if notification_manager:
					notification_manager.show_warning("Diamantes insuficientes")
				return
			if _purchase_prestige_upgrade(upgrade_type, prestige_shop, currency_manager):
				if notification_manager:
					notification_manager.show_success("Melhoria desbloqueada")
				var ret = dialog.get_meta("return_to", null)
				dialog.queue_free()
				menu_self.call_deferred("_show_prestige_dialog", ret)
		)
		_style_secondary_button(buy_btn)
		hbox.add_child(buy_btn)

	margin.add_child(hbox)
	panel.add_child(margin)
	return panel

func _show_quests_dialog() -> void:
	"""Mostra diálogo de quests"""
	const QuestManager = preload("res://scripts/managers/QuestManager.gd")

	var quest_manager = QuestManager.new()
	quest_manager.check_and_refresh_quests()


	var dialog = Window.new()
	dialog.title = "Quests"
	dialog.size = Vector2(800, 600)
	dialog.min_size = Vector2(700, 500)
	dialog.always_on_top = true
	dialog.transient = true
	UIHelper.apply_window_theme(dialog)


	dialog.close_requested.connect(func(): dialog.queue_free())


	var main_container = MarginContainer.new()
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)


	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 480)

	var all_quests = quest_manager.get_all_active_quests()


	var daily_scroll = ScrollContainer.new()
	daily_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var daily_list = VBoxContainer.new()
	daily_list.add_theme_constant_override("separation", 8)
	for quest in all_quests.daily:
		var quest_panel = _create_quest_panel(quest, quest_manager, dialog)
		daily_list.add_child(quest_panel)
	daily_scroll.add_child(daily_list)
	tab_container.add_child(daily_scroll)
	tab_container.set_tab_title(0, "📅 Diárias")


	var weekly_scroll = ScrollContainer.new()
	weekly_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var weekly_list = VBoxContainer.new()
	weekly_list.add_theme_constant_override("separation", 8)
	for quest in all_quests.weekly:
		var quest_panel = _create_quest_panel(quest, quest_manager, dialog)
		weekly_list.add_child(quest_panel)
	weekly_scroll.add_child(weekly_list)
	tab_container.add_child(weekly_scroll)
	tab_container.set_tab_title(1, "📆 Semanais")


	var monthly_scroll = ScrollContainer.new()
	monthly_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var monthly_list = VBoxContainer.new()
	monthly_list.add_theme_constant_override("separation", 8)
	for quest in all_quests.monthly:
		var quest_panel = _create_quest_panel(quest, quest_manager, dialog)
		monthly_list.add_child(quest_panel)
	monthly_scroll.add_child(monthly_list)
	tab_container.add_child(monthly_scroll)
	tab_container.set_tab_title(2, "🗓️ Mensais")

	vbox.add_child(tab_container)


	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(150, 45)
	close_button.pressed.connect(func(): dialog.queue_free())
	UIHelper.apply_button_theme(close_button, UIHelper.BTN_SECONDARY)
	button_container.add_child(close_button)
	vbox.add_child(button_container)

	main_container.add_child(vbox)
	dialog.add_child(main_container)
	add_child(dialog)
	await get_tree().process_frame
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.popup_centered()

func _create_quest_panel(quest: Dictionary, quest_manager: QuestManager, dialog: Window) -> Panel:
	"""Cria painel para uma quest"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)


	var panel_style: StyleBoxFlat
	if quest.status == QuestManager.QuestStatus.COMPLETED:
		panel_style = UIHelper.card_style(Color(0.3, 0.6, 0.3, 1.0), Color(0.16, 0.28, 0.18, 0.95))
	elif quest.status == QuestManager.QuestStatus.CLAIMED:
		panel_style = UIHelper.card_style(Color(0.4, 0.4, 0.45, 1.0), Color(0.16, 0.16, 0.18, 0.95))
	else:
		panel_style = UIHelper.card_style()
	panel.add_theme_stylebox_override("panel", panel_style)


	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)


	var icon_label = Label.new()
	icon_label.text = quest.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(icon_label)


	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = quest.name
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)


	var progress_label = Label.new()
	var progress_text = "%d / %d" % [quest.current, quest.target]
	progress_label.text = progress_text
	progress_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(progress_label)


	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = quest.target
	progress_bar.value = quest.current
	progress_bar.custom_minimum_size = Vector2(0, 8)
	UIHelper.apply_progress_bar_style(progress_bar, Color(0.25, 0.65, 0.85))
	info_vbox.add_child(progress_bar)

	hbox.add_child(info_vbox)


	if quest.status == QuestManager.QuestStatus.COMPLETED:
		var claim_button = Button.new()
		var pts = quest.get("reward_points", 0)
		var reward_text = "⭐ %d pts" % pts
		if quest.get("reward_diamonds", 0) > 0:
			reward_text += "\n💎 %d" % quest.reward_diamonds
		claim_button.text = "Reivindicar\n" + reward_text
		claim_button.custom_minimum_size = Vector2(120, 60)
		UIHelper.apply_success_button(claim_button)

		var menu_self = self
		claim_button.pressed.connect(func():
			var result = quest_manager.claim_quest(quest.id)
			if result.success:
				var reward_pts = result.get("reward_points", 0)
				if reward_pts > 0:
					const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")
					AchievementManager.get_instance().add_points(reward_pts)
				if result.reward_diamonds > 0:
					const SpecialCurrencyManager = preload("res://scripts/managers/SpecialCurrencyManager.gd")
					var currency_manager_claim = SpecialCurrencyManager.new()
					currency_manager_claim.add_diamonds(result.reward_diamonds, "quest")
				dialog.queue_free()
				menu_self.call_deferred("_show_quests_dialog")
				if notification_manager:
					notification_manager.show_success("Recompensa reivindicada")
		)
		hbox.add_child(claim_button)

	panel.add_child(hbox)


	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.set_offsets_preset(Control.PRESET_FULL_RECT, 5)

	return panel

func _show_achievements_dialog(return_to: Window = null) -> void:
	const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")

	var achievement_manager = AchievementManager.get_instance()
	var stats = achievement_manager.get_stats()


	var dialog = Window.new()
	dialog.title = "Conquistas - %d/%d Desbloqueadas" % [stats.unlocked, stats.total]
	dialog.size = Vector2(900, 700)
	dialog.min_size = Vector2(800, 600)
	dialog.always_on_top = true
	dialog.transient = true
	UIHelper.apply_window_theme(dialog)


	var main_container = MarginContainer.new()
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)


	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(0, 80)


	var stats_style = UIHelper.card_style()
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)


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


	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = stats.completion_percentage
	progress_bar.custom_minimum_size = Vector2(0, 25)
	progress_bar.show_percentage = true
	UIHelper.apply_progress_bar_style(progress_bar, Color(0.95, 0.75, 0.2))
	stats_vbox.add_child(progress_bar)

	stats_margin.add_child(stats_vbox)
	stats_panel.add_child(stats_margin)
	vbox.add_child(stats_panel)


	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 480)
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL


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


	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.custom_minimum_size = Vector2(0, 50)

	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(150, 45)


	UIHelper.apply_button_theme(close_button, UIHelper.BTN_SECONDARY)

	close_button.text = "Voltar" if return_to else "Fechar"
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(func(): _restore_parent_dialog(dialog, return_to))

	button_container.add_child(close_button)
	vbox.add_child(button_container)

	main_container.add_child(vbox)
	dialog.add_child(main_container)
	dialog.close_requested.connect(func(): _restore_parent_dialog(dialog, return_to))
	add_child(dialog)
	await get_tree().process_frame
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.popup_centered()

func _create_achievement_panel(achievement: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)


	var panel_style: StyleBoxFlat
	if achievement.unlocked:
		panel_style = UIHelper.card_style(Color(0.3, 0.6, 0.3, 1.0), Color(0.16, 0.28, 0.18, 0.95))
	else:
		panel_style = UIHelper.card_style()
	panel.add_theme_stylebox_override("panel", panel_style)


	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)


	var icon_label = Label.new()
	icon_label.text = achievement.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(50, 0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)


	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = achievement.name
	if achievement.unlocked:
		name_label.modulate = Color(0.8, 1.0, 0.8)
	else:
		name_label.modulate = Color(0.6, 0.6, 0.6)
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)


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


	await get_tree().process_frame
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.set_offsets_preset(Control.PRESET_FULL_RECT, 5)

	return panel

func _show_perks_dialog(return_to: Window = null) -> void:
	const PerkManager = preload("res://scripts/managers/PerkManager.gd")
	const AchievementManager = preload("res://scripts/managers/AchievementManager.gd")

	var perk_manager = PerkManager.get_instance()
	var achievement_manager = AchievementManager.get_instance()


	var dialog = Window.new()
	dialog.title = "Melhorias Persistentes"
	dialog.size = Vector2i(900, 650)
	dialog.min_size = Vector2i(800, 550)
	dialog.always_on_top = true
	dialog.transient = true
	UIHelper.apply_window_theme(dialog)


	var main_container = MarginContainer.new()
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)


	var points_panel = Panel.new()
	points_panel.custom_minimum_size = Vector2(0, 75)


	var points_style = UIHelper.card_style()
	points_panel.add_theme_stylebox_override("panel", points_style)

	var points_vbox = VBoxContainer.new()
	points_vbox.add_theme_constant_override("separation", 5)

	var points_container = HBoxContainer.new()
	points_container.add_theme_constant_override("separation", 10)


	var coin_icon = Label.new()
	coin_icon.text = "💰"
	coin_icon.add_theme_font_size_override("font_size", 28)
	coin_icon.custom_minimum_size = Vector2(50, 0)
	coin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_container.add_child(coin_icon)


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


	var points_desc = Label.new()
	points_desc.text = "Use pontos de conquistas para desbloquear melhorias permanentes"
	points_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	points_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_desc.add_theme_font_size_override("font_size", 11)
	points_desc.modulate = Color(0.7, 0.7, 0.7)
	points_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	points_vbox.add_child(points_desc)

	points_panel.add_child(points_vbox)


	await get_tree().process_frame
	points_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	points_vbox.set_offsets_preset(Control.PRESET_FULL_RECT)

	vbox.add_child(points_panel)


	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 480)
	tab_container.add_theme_constant_override("h_separation", 10)


	var categories = [
		{"name": "Início", "category": PerkManager.Category.STARTING, "icon": "🚀"},
		{"name": "Economia", "category": PerkManager.Category.ECONOMY, "icon": "💰"},
		{"name": "Combate", "category": PerkManager.Category.COMBAT, "icon": "⚔️"},
		{"name": "Defesa", "category": PerkManager.Category.DEFENSE, "icon": "🛡️"},
		{"name": "Progressão", "category": PerkManager.Category.PROGRESSION, "icon": "📈"}
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


	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END


	var reset_button = Button.new()
	reset_button.text = "Resetar Melhorias"
	reset_button.custom_minimum_size = Vector2(150, 45)
	reset_button.tooltip_text = "Resetar todas as melhorias persistentes (perks)"


	UIHelper.apply_button_theme(reset_button, UIHelper.BTN_DANGER)

	reset_button.add_theme_font_size_override("font_size", 14)
	reset_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	reset_button.pressed.connect(func(): _show_reset_perks_confirmation(dialog, perk_manager, achievement_manager, return_to))

	button_container.add_child(reset_button)


	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(150, 45)


	UIHelper.apply_button_theme(close_button, UIHelper.BTN_SECONDARY)

	close_button.text = "Voltar" if return_to else "Fechar"
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(func(): _restore_parent_dialog(dialog, return_to))

	button_container.add_child(close_button)
	vbox.add_child(button_container)

	main_container.add_child(vbox)
	dialog.add_child(main_container)
	dialog.close_requested.connect(func(): _restore_parent_dialog(dialog, return_to))
	add_child(dialog)
	await get_tree().process_frame
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.popup_centered()

func _create_perk_panel(perk: Dictionary, perk_manager: PerkManager, achievement_manager: AchievementManager, dialog: Window) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)


	var panel_style: StyleBoxFlat
	if perk.level > 0:
		panel_style = UIHelper.card_style(Color(0.4, 0.6, 0.8, 1.0), Color(0.14, 0.22, 0.32, 0.95))
	else:
		panel_style = UIHelper.card_style()
	panel.add_theme_stylebox_override("panel", panel_style)


	var main_margin = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 12)
	main_margin.add_theme_constant_override("margin_top", 10)
	main_margin.add_theme_constant_override("margin_right", 12)
	main_margin.add_theme_constant_override("margin_bottom", 10)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)


	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL


	var icon_container = Panel.new()
	icon_container.custom_minimum_size = Vector2(55, 55)
	icon_container.add_theme_stylebox_override("panel", UIHelper.card_style())

	var icon_label = Label.new()
	icon_label.text = perk.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_container.add_child(icon_label)
	top_hbox.add_child(icon_container)


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


	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(150, 50)
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_END

	buy_button.set_meta("perk_cost", perk.cost)
	buy_button.set_meta("perk_id", perk.id)

	if perk.is_max_level:
		buy_button.text = "✓ Máximo"
		buy_button.disabled = true
		UIHelper.apply_success_button(buy_button)
		buy_button.disabled = true
	elif achievement_manager.total_points < perk.cost:
		buy_button.text = "💰 %d" % perk.cost
		buy_button.disabled = true
		UIHelper.apply_button_theme(buy_button, UIHelper.BTN_DISABLED)
	else:
		buy_button.text = "Comprar\n💰 %d" % perk.cost
		UIHelper.apply_button_theme(buy_button, UIHelper.BTN_PRIMARY)

		buy_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	buy_button.add_theme_font_size_override("font_size", 12)
	buy_button.pressed.connect(func():
		if perk_manager.purchase_perk(perk.id, achievement_manager):

			var points_label = _find_points_label_recursive(dialog)
			if points_label:
				points_label.text = "Pontos Disponíveis: %d" % achievement_manager.total_points


			_update_all_perk_buttons(dialog, achievement_manager)


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

	var tab_container = dialog.get_node_or_null("*/MarginContainer/VBoxContainer/TabContainer")
	if not tab_container:
		return


	for tab_idx in range(tab_container.get_tab_count()):
		var scroll = tab_container.get_child(tab_idx) as ScrollContainer
		if not scroll:
			continue

		var perk_list = scroll.get_child(0) as VBoxContainer
		if not perk_list:
			continue


		for child in perk_list.get_children():
			if child is Panel:
				var panel = child as Panel
				var buy_button = _find_buy_button_recursive(panel)
				if buy_button and not buy_button.text.contains("Máximo"):

					var cost = buy_button.get_meta("perk_cost", -1)
					if cost < 0:

						var button_text = buy_button.text
						var cost_match = button_text.get_slice("💰", 1).strip_edges()
						if cost_match.is_valid_int():
							cost = int(cost_match)

					if cost > 0:
						if achievement_manager.total_points < cost:

							buy_button.disabled = true
							buy_button.text = "💰 %d" % cost
							UIHelper.apply_button_theme(buy_button, UIHelper.BTN_DISABLED)
						else:

							buy_button.disabled = false
							buy_button.text = "Comprar\n💰 %d" % cost
							UIHelper.apply_button_theme(buy_button, UIHelper.BTN_PRIMARY)

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

func _show_reset_perks_confirmation(dialog: Window, perk_manager, achievement_manager, return_to: Window = null) -> void:

	var confirm_window = Window.new()
	confirm_window.title = "Resetar Melhorias Persistentes"
	confirm_window.size = Vector2i(450, 250)
	confirm_window.min_size = Vector2i(400, 200)
	confirm_window.always_on_top = true
	confirm_window.transient = true
	confirm_window.popup_window = true
	UIHelper.apply_window_theme(confirm_window)


	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	confirm_window.add_child(main_vbox)


	var label = Label.new()
	label.text = "Tem certeza que deseja resetar TODAS as melhorias persistentes (perks)?\n\nEsta ação não pode ser desfeita!\n\nTodas as melhorias serão removidas e os pontos gastos serão devolvidos para redistribuição."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(label)


	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_END


	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(100, 35)
	cancel_btn.pressed.connect(func():
		confirm_window.queue_free()
	)
	UIHelper.apply_button_theme(cancel_btn, UIHelper.BTN_SECONDARY)
	button_container.add_child(cancel_btn)


	var confirm_btn = Button.new()
	confirm_btn.text = "Sim, Resetar"
	confirm_btn.custom_minimum_size = Vector2(120, 35)


	UIHelper.apply_button_theme(confirm_btn, UIHelper.BTN_DANGER)

	confirm_btn.pressed.connect(func():

		var points_refunded = perk_manager.reset_all_perks(achievement_manager)
		print("Perks resetados com sucesso! Pontos devolvidos: ", points_refunded)


		confirm_window.queue_free()



		dialog.queue_free()
		await get_tree().process_frame
		_show_perks_dialog(return_to)
	)
	button_container.add_child(confirm_btn)

	main_vbox.add_child(button_container)


	get_tree().root.add_child(confirm_window)


	var screen_size = DisplayServer.screen_get_size()
	var window_size = confirm_window.size
	confirm_window.position = (screen_size - window_size) / 2


	confirm_window.show()

func _create_music_controls() -> void:
	"""Cria os controles de música (mute e slider) no canto inferior direito"""

	var music_container = HBoxContainer.new()
	music_container.name = "MusicControls"
	music_container.add_theme_constant_override("separation", 10)


	music_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	music_container.offset_left = -200
	music_container.offset_top = -50
	music_container.offset_right = -10
	music_container.offset_bottom = -10


	music_mute_button = Button.new()
	music_mute_button.name = "BtnMuteMusic"
	music_mute_button.custom_minimum_size = Vector2(40, 30)
	music_mute_button.text = "🔊"
	music_mute_button.tooltip_text = "Mutar/Desmutar música"


	UIHelper.apply_button_theme(music_mute_button, UIHelper.BTN_SECONDARY)

	music_mute_button.add_theme_font_size_override("font_size", 16)
	music_mute_button.pressed.connect(_on_mute_music)
	music_container.add_child(music_mute_button)


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


	_save_audio_settings()

func _on_music_volume_changed(value: float) -> void:
	"""Atualiza o volume da música quando o slider é movido"""
	music_volume = value
	var music_player = get_node_or_null("MusicPlayer")
	if music_player and not music_muted:
		music_player.volume_db = music_volume


	_save_audio_settings()

func _save_audio_settings() -> void:
	"""Salva as configurações de áudio em arquivo"""
	var config = ConfigFile.new()
	var config_path = "user://audio_settings.cfg"


	config.load(config_path)


	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "music_muted", music_muted)


	config.save(config_path)

func _save_quest_rewards(emeralds: int, diamonds: int) -> void:
	"""Salva recompensas de moedas especiais de quests para serem aplicadas no Game"""
	if emeralds <= 0 and diamonds <= 0:
		return

	var config = ConfigFile.new()
	var config_path = "user://pending_quest_rewards.cfg"


	var pending_emeralds = 0
	var pending_diamonds = 0
	if config.load(config_path) == OK:
		pending_emeralds = config.get_value("rewards", "emeralds", 0)
		pending_diamonds = config.get_value("rewards", "diamonds", 0)


	pending_emeralds += emeralds
	pending_diamonds += diamonds


	config.set_value("rewards", "emeralds", pending_emeralds)
	config.set_value("rewards", "diamonds", pending_diamonds)
	config.save(config_path)
