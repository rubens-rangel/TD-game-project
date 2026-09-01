extends RefCounted
class_name UIHelper

const BTN_PRIMARY := "primary"
const BTN_SECONDARY := "secondary"
const BTN_DANGER := "danger"
const BTN_DISABLED := "disabled"

const PANEL_BG := Color(0.09, 0.1, 0.16, 0.97)
const PANEL_BORDER := Color(0.42, 0.48, 0.72, 1.0)
const PRIMARY_BG := Color(0.18, 0.28, 0.5, 1.0)
const PRIMARY_HOVER := Color(0.25, 0.38, 0.65, 1.0)
const SECONDARY_BG := Color(0.22, 0.2, 0.35, 1.0)
const SECONDARY_HOVER := Color(0.3, 0.26, 0.45, 1.0)
const DANGER_BG := Color(0.48, 0.18, 0.2, 1.0)
const DANGER_HOVER := Color(0.62, 0.24, 0.26, 1.0)
const SUCCESS_BG := Color(0.2, 0.44, 0.3, 1.0)
const SUCCESS_HOVER := Color(0.26, 0.54, 0.36, 1.0)
const CARD_BG := Color(0.13, 0.14, 0.21, 0.94)
const CARD_BORDER := Color(0.38, 0.42, 0.58, 0.95)
const HUD_BAR_BG := Color(0.07, 0.08, 0.13, 0.96)
const TITLE_GOLD := Color(0.98, 0.92, 0.65, 1.0)
const CORNER_PANEL := 14
const CORNER_CARD := 10
const CORNER_BUTTON := 10
const BORDER_PANEL := 2
const BORDER_CARD := 1

static func create_stylebox(
	bg_color: Color = Color(0.2, 0.2, 0.3),
	border_color: Color = Color(0.4, 0.4, 0.5),
	border_width: int = 1
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.set_corner_radius_all(CORNER_BUTTON)
	return style

static func panel_style(_corner: int = CORNER_PANEL, _shadow: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(CORNER_PANEL)
	style.set_border_width_all(BORDER_PANEL)
	style.border_color = PANEL_BORDER
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	style.set_content_margin_all(8)
	return style

static func toast_style() -> StyleBoxFlat:
	var style := card_style()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.94)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

static func window_fill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(12)
	return style

static func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(CORNER_BUTTON)
	style.set_border_width_all(BORDER_CARD)
	style.border_color = border
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func hud_bar_style(is_bottom: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HUD_BAR_BG
	style.border_color = Color(0.38, 0.42, 0.62, 0.9)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	if is_bottom:
		style.bg_color = Color(0.07, 0.08, 0.13, 0.55)
		style.border_color = Color(0.38, 0.42, 0.62, 0.55)
		style.shadow_color = Color(0, 0, 0, 0.22)
		style.border_width_top = 1
		style.set_corner_radius_all(CORNER_CARD)
		style.shadow_offset = Vector2(0, -2)
	else:
		style.border_width_bottom = 1
		style.shadow_offset = Vector2(0, 3)
	return style

static func side_panel_style(collapsed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.15, 0.97)
	style.border_color = PANEL_BORDER
	style.border_width_left = 2
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	if collapsed:
		style.corner_radius_top_left = CORNER_CARD
		style.corner_radius_bottom_left = CORNER_CARD
	return style

static func card_style(border: Color = CARD_BORDER, bg: Color = CARD_BG) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(BORDER_CARD)
	style.set_corner_radius_all(CORNER_CARD)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func hero_card_style() -> StyleBoxFlat:
	var style := card_style(Color(0.78, 0.62, 0.28, 1.0))
	style.bg_color = Color(0.16, 0.14, 0.22, 0.96)
	style.set_border_width_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func apply_accent_button(button: Button, bg: Color, hover: Color = Color()) -> void:
	if hover == Color():
		hover = bg.lightened(0.12)
	var border := bg.lightened(0.2)
	button.add_theme_stylebox_override("normal", _button_style(bg, border))
	button.add_theme_stylebox_override("hover", _button_style(hover, border.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.18), border))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.28, 0.28, 0.32, 1.0), Color(0.4, 0.4, 0.45, 1.0)))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 13)
	ButtonHoverHelper.setup_button_hover(button)

static func apply_success_button(button: Button) -> void:
	apply_accent_button(button, SUCCESS_BG, SUCCESS_HOVER)

static func padded_margin(left: int = 12, top: int = 10, right: int = 12, bottom: int = 10) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

static func apply_button_theme(button: Button, kind: String = BTN_PRIMARY) -> void:
	var bg := PRIMARY_BG
	var hover := PRIMARY_HOVER
	var border := Color(0.3, 0.45, 0.75, 1.0)
	match kind:
		BTN_SECONDARY:
			bg = SECONDARY_BG
			hover = SECONDARY_HOVER
			border = Color(0.45, 0.4, 0.65, 1.0)
		BTN_DANGER:
			bg = DANGER_BG
			hover = DANGER_HOVER
			border = Color(0.75, 0.35, 0.38, 1.0)
		BTN_DISABLED:
			bg = Color(0.28, 0.28, 0.32, 1.0)
			hover = bg
			border = Color(0.4, 0.4, 0.45, 1.0)
	button.add_theme_stylebox_override("normal", _button_style(bg, border))
	button.add_theme_stylebox_override("hover", _button_style(hover, border.lightened(0.15)))
	button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.2), border))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.28, 0.28, 0.32, 1.0), Color(0.4, 0.4, 0.45, 1.0)))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	if kind != BTN_DISABLED:
		ButtonHoverHelper.setup_button_hover(button)

static func primary_button(text: String, size: Vector2 = Vector2(160, 42)) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	apply_button_theme(btn, BTN_PRIMARY)
	return btn

static func secondary_button(text: String, size: Vector2 = Vector2(160, 42)) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	apply_button_theme(btn, BTN_SECONDARY)
	return btn

static func danger_button(text: String, size: Vector2 = Vector2(160, 42)) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	apply_button_theme(btn, BTN_DANGER)
	return btn

static func create_button(
	text: String,
	size: Vector2 = Vector2(100, 35),
	bg_color: Color = Color(0.2, 0.4, 0.6),
	border_color: Color = Color(0.3, 0.5, 0.7)
) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	var style = create_stylebox(bg_color, border_color)
	btn.add_theme_stylebox_override("normal", style)
	apply_hover_button_style(btn, bg_color.lightened(0.15))
	ButtonHoverHelper.setup_button_hover(btn)
	return btn

static func create_label(
	text: String = "",
	font_size: int = 14,
	font_color: Color = GameConstants.COLOR_UI_WHITE
) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	return label

static func apply_disabled_button_style(button: Button) -> void:
	var style = create_stylebox(
		Color(0.3, 0.3, 0.3),
		Color(0.5, 0.5, 0.5)
	)
	button.add_theme_stylebox_override("disabled", style)

static func apply_hover_button_style(button: Button, hover_color: Color = Color(0.3, 0.5, 0.7)) -> void:
	var style = create_stylebox(
		hover_color,
		Color(0.4, 0.6, 0.8)
	)
	button.add_theme_stylebox_override("hover", style)

static func apply_progress_bar_style(progress_bar: ProgressBar, fill_color: Color = Color(0.25, 0.7, 0.35)) -> void:
	"""Aplica estilo escuro de fundo e fill colorido à ProgressBar."""
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.18, 0.2, 0.25, 0.95)
	bg.border_color = Color(0.35, 0.38, 0.45)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.border_color = fill_color.darkened(0.2)
	fill.set_border_width_all(0)
	fill.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("fill", fill)

static func apply_window_theme(win: Window) -> void:
	if win == null:
		return
	var chrome := panel_style()
	chrome.content_margin_left = 10
	chrome.content_margin_right = 10
	chrome.content_margin_bottom = 10
	chrome.content_margin_top = 36
	win.add_theme_stylebox_override("embedded_border", chrome)
	var unfocused := chrome.duplicate()
	unfocused.border_color = PANEL_BORDER.darkened(0.15)
	win.add_theme_stylebox_override("embedded_unfocused_border", unfocused)
	win.add_theme_color_override("title_color", TITLE_GOLD)
	win.add_theme_font_size_override("title_font_size", 15)
	win.add_theme_constant_override("title_height", 32)
	win.transient = true

static func dialog_window(title: String, size: Vector2i = Vector2i(520, 420)) -> Window:
	var dialog := Window.new()
	dialog.title = title
	dialog.size = size
	dialog.min_size = Vector2i(max(320, size.x - 80), max(240, size.y - 80))
	dialog.unresizable = true
	dialog.close_requested.connect(dialog.queue_free)
	apply_window_theme(dialog)
	return dialog

static func popup_in_viewport(dialog: Window, host: Node) -> void:
	if dialog.get_parent() == null:
		var root := host.get_tree().root if host else null
		if root:
			root.add_child(dialog)
		else:
			host.add_child(dialog)
	dialog.popup_centered()

static func present_modal(host: Node, min_size: Vector2 = Vector2(560, 240)) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.name = "UiModalOverlay"
	overlay.color = Color(0.02, 0.03, 0.06, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 80
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	panel.add_child(margin)
	center.add_child(panel)
	overlay.add_child(center)
	host.add_child(overlay)
	vbox.set_meta("modal_root", overlay)
	return vbox

static func close_modal(from: Node) -> void:
	if from == null:
		return
	var root = from.get_meta("modal_root", null)
	if root is Node:
		root.queue_free()
	elif from.get_parent():
		from.get_parent().queue_free()
