extends RefCounted
class_name UIHelper

# Helper class para criar elementos UI reutilizáveis
# Reduz código duplicado e facilita manutenção

# Cria um StyleBoxFlat com configurações padrão
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
	return style

# Cria um botão com estilo padrão
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
	return btn

# Cria um label com estilo padrão
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

# Aplica estilo de botão desabilitado
static func apply_disabled_button_style(button: Button) -> void:
	var style = create_stylebox(
		Color(0.3, 0.3, 0.3),
		Color(0.5, 0.5, 0.5)
	)
	button.add_theme_stylebox_override("disabled", style)

# Aplica estilo de botão hover
static func apply_hover_button_style(button: Button, hover_color: Color = Color(0.3, 0.5, 0.7)) -> void:
	var style = create_stylebox(
		hover_color,
		Color(0.4, 0.6, 0.8)
	)
	button.add_theme_stylebox_override("hover", style)

