extends Window
class_name SettingsDialog

signal settings_changed
signal music_volume_changed(value: float)

var _music_slider: HSlider
var _fullscreen_check: CheckButton
var _fps_check: CheckButton
var _shop_check: CheckButton
var _initial_volume: float = -7.0

func _init(current_volume: float = -7.0) -> void:
	_initial_volume = current_volume
	title = "Opções"
	size = Vector2i(460, 420)
	min_size = Vector2i(400, 360)
	transient = true
	unresizable = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_requested.connect(queue_free)

func _ready() -> void:
	UIHelper.apply_window_theme(self)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIHelper.window_fill_style())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var title_lbl := UIHelper.create_label("Opções", 20, GameConstants.COLOR_UI_GOLD)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var vol_lbl := UIHelper.create_label("Volume da música", 14, Color(0.8, 0.82, 0.92))
	vbox.add_child(vol_lbl)
	_music_slider = HSlider.new()
	_music_slider.min_value = -60.0
	_music_slider.max_value = 0.0
	_music_slider.step = 1.0
	_music_slider.value = _initial_volume
	_music_slider.custom_minimum_size = Vector2(0, 28)
	_music_slider.value_changed.connect(func(v: float):
		music_volume_changed.emit(v)
	)
	vbox.add_child(_music_slider)

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Tela cheia (F11)"
	_fullscreen_check.button_pressed = UXSettings.is_fullscreen()
	_fullscreen_check.toggled.connect(func(on: bool):
		UXSettings.set_fullscreen(on)
		settings_changed.emit()
	)
	vbox.add_child(_fullscreen_check)

	_fps_check = CheckButton.new()
	_fps_check.text = "Mostrar FPS"
	_fps_check.button_pressed = UXSettings.show_fps()
	_fps_check.toggled.connect(func(on: bool):
		UXSettings.set_show_fps(on)
		settings_changed.emit()
	)
	vbox.add_child(_fps_check)

	_shop_check = CheckButton.new()
	_shop_check.text = "Iniciar com a loja recolhida"
	_shop_check.button_pressed = UXSettings.shop_start_collapsed()
	_shop_check.toggled.connect(func(on: bool):
		UXSettings.set_shop_start_collapsed(on)
		settings_changed.emit()
	)
	vbox.add_child(_shop_check)

	var hint := UIHelper.create_label("A loja e as skills começam recolhidas para o mapa ficar visível.", 12, Color(0.65, 0.68, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	var close_btn := UIHelper.secondary_button("Fechar", Vector2(140, 40))
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(queue_free)
	vbox.add_child(close_btn)

	margin.add_child(vbox)
	panel.add_child(margin)
	add_child(panel)
	popup_centered()
