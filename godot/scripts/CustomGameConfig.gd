extends Window
## Janela de configuração do modo de jogo personalizado.
## Opções organizadas por seção: Economia, Herói, Torres, Ondas.

signal start_game_requested

func _cfg() -> Node:
	return get_node("/root/GameConfig")

# key, label, min, max, step, integer, section
const FIELDS: Array = [
	# Economia
	{"key": "HERO_START_COINS", "label": "Moedas iniciais", "min": 0, "max": 10000, "step": 10, "integer": true, "section": "Economia"},
	{"key": "COIN_DROP_CHANCE", "label": "Chance de drop de moeda (%)", "min": 0.0, "max": 100.0, "step": 1.0, "integer": false, "section": "Economia"},
	{"key": "COIN_MIN_VALUE", "label": "Moedas mín. por drop", "min": 1, "max": 100, "step": 1, "integer": true, "section": "Economia"},
	{"key": "COIN_MAX_VALUE", "label": "Moedas máx. por drop", "min": 1, "max": 500, "step": 1, "integer": true, "section": "Economia"},
	{"key": "REWARD_SCALE", "label": "Escala de recompensa por wave", "min": 1.0, "max": 2.0, "step": 0.01, "integer": false, "section": "Economia"},
	{"key": "WAVE_COMPLETION_BONUS_BASE", "label": "Bônus base ao completar wave", "min": 0, "max": 500, "step": 5, "integer": true, "section": "Economia"},
	{"key": "UPGRADE_COST_MULTIPLIER", "label": "Multiplicador custo de upgrade", "min": 1.0, "max": 2.0, "step": 0.05, "integer": false, "section": "Economia"},
	# Herói e base
	{"key": "HERO_BASE_HP", "label": "Vida da base", "min": 1, "max": 1000, "step": 10, "integer": true, "section": "Herói e base"},
	{"key": "HERO_BASE_DAMAGE", "label": "Dano base do herói", "min": 0.1, "max": 5.0, "step": 0.1, "integer": false, "section": "Herói e base"},
	{"key": "HERO_BASE_FIRE_RATE", "label": "Cadência base do herói", "min": 0.1, "max": 5.0, "step": 0.1, "integer": false, "section": "Herói e base"},
	# Torres e limites
	{"key": "TOWER_COST", "label": "Custo base da torre", "min": 1, "max": 500, "step": 1, "integer": true, "section": "Torres e limites"},
	{"key": "MAX_TOWERS", "label": "Máximo de torres", "min": 1, "max": 20, "step": 1, "integer": true, "section": "Torres e limites"},
	{"key": "MAX_MINES", "label": "Máximo de minas", "min": 0, "max": 30, "step": 1, "integer": true, "section": "Torres e limites"},
	# Ondas
	{"key": "INTERMISSION", "label": "Tempo entre waves (segundos)", "min": 1.0, "max": 60.0, "step": 1.0, "integer": false, "section": "Ondas"},
]

var _controls: Dictionary = {}

func _ready() -> void:
	title = "Modo personalizado — Regras do jogo"
	size = Vector2i(520, 580)
	min_size = Vector2i(480, 420)
	UIHelper.apply_window_theme(self)

	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIHelper.window_fill_style())

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)

	# Título
	var title_label = Label.new()
	title_label.text = "Ajuste as regras do jogo abaixo. Todas as opções usam os valores padrão se não alterar."
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.custom_minimum_size.x = 460
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	root.add_child(title_label)

	# Área rolável com seções
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var sections_vbox = VBoxContainer.new()
	sections_vbox.add_theme_constant_override("separation", 18)

	var current_section := ""
	var section_container: VBoxContainer = null

	for field in FIELDS:
		var key: String = field.key
		var section: String = field.get("section", "Outros")
		if section != current_section:
			current_section = section
			# Título da seção
			var section_label = Label.new()
			section_label.text = section
			section_label.add_theme_font_size_override("font_size", 15)
			section_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
			sections_vbox.add_child(section_label)

			# Painel da seção
			var section_panel = PanelContainer.new()
			section_panel.add_theme_stylebox_override("panel", UIHelper.card_style())
			section_container = VBoxContainer.new()
			section_container.add_theme_constant_override("separation", 10)
			section_panel.add_child(section_container)
			sections_vbox.add_child(section_panel)

		# Linha: label + SpinBox
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var lbl = Label.new()
		lbl.text = field.label
		lbl.custom_minimum_size.x = 260
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))
		row.add_child(lbl)
		var spin = SpinBox.new()
		spin.custom_minimum_size.x = 120
		spin.min_value = field.min
		spin.max_value = field.max
		spin.step = field.step
		spin.allow_greater = false
		spin.allow_lesser = false
		var val = _cfg().get_default(key)
		if field.integer:
			spin.value = int(val)
		else:
			if key == "COIN_DROP_CHANCE":
				spin.value = float(val) * 100.0
			else:
				spin.value = float(val)
		_controls[key] = {"spin": spin, "integer": field.integer, "key": key}
		row.add_child(spin)
		section_container.add_child(row)

	scroll.add_child(sections_vbox)
	root.add_child(scroll)

	# Botões
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn_defaults = UIHelper.secondary_button("Restaurar padrões", Vector2(0, 40))
	btn_defaults.pressed.connect(_on_restore_defaults)
	btn_row.add_child(btn_defaults)

	var btn_cancel = UIHelper.secondary_button("Cancelar", Vector2(0, 40))
	btn_cancel.pressed.connect(_on_cancel)
	btn_row.add_child(btn_cancel)

	var btn_start = UIHelper.primary_button("Iniciar jogo", Vector2(0, 40))
	btn_start.pressed.connect(_on_start_game)
	btn_row.add_child(btn_start)

	root.add_child(btn_row)
	margin.add_child(root)
	panel.add_child(margin)
	add_child(panel)

	close_requested.connect(_on_close_requested)

func _on_restore_defaults() -> void:
	for field in FIELDS:
		var key: String = field.key
		var val = _cfg().get_default(key)
		var data = _controls[key]
		var spin: SpinBox = data.spin
		if field.integer:
			spin.value = int(val)
		else:
			if key == "COIN_DROP_CHANCE":
				spin.value = float(val) * 100.0
			else:
				spin.value = float(val)

func _on_start_game() -> void:
	_cfg().start_custom_mode()
	for key in _controls:
		var data = _controls[key]
		var spin: SpinBox = data.spin
		if data.integer:
			_cfg().set_override(key, int(spin.value))
		else:
			var v = spin.value
			if key == "COIN_DROP_CHANCE":
				v = v / 100.0
			_cfg().set_override(key, v)
	start_game_requested.emit()
	hide()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_close_requested() -> void:
	hide()
	queue_free()

func _on_cancel() -> void:
	_on_close_requested()
