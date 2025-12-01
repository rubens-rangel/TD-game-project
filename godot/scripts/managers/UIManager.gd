extends RefCounted
class_name UIManager

# Gerencia toda a UI do jogo
# Responsável por criar, atualizar e gerenciar elementos de interface

var game: Node2D  # Referência ao Game principal
var hud: Control  # Referência ao HUD
var top_bar: Panel  # Referência ao TopBar

# UI Elements
var tower_shop_panel: Panel
var skills_panel: Panel
var tooltip_label: Label
var game_tooltip: Control
var range_indicator: Line2D
var boss_alert_label: Label
var pause_overlay: Control
var dps_menu_panel: Panel

# UI State
var tower_shop_collapsed: bool = false
var skills_panel_collapsed: bool = false
var dps_menu_visible: bool = false

func _init(game_node: Node2D):
	game = game_node

# Inicializa referências aos elementos UI existentes
func initialize() -> void:
	hud = game.get_node_or_null("CanvasLayer/HUD")
	if hud:
		top_bar = hud.get_node_or_null("TopBar")

# Cria um StyleBoxFlat reutilizável
func create_stylebox(
	bg_color: Color = Color(0.2, 0.2, 0.3),
	border_color: Color = Color(0.4, 0.4, 0.5),
	border_width: int = 1
) -> StyleBoxFlat:
	return UIHelper.create_stylebox(bg_color, border_color, border_width)

# Cria um botão com estilo padrão
func create_button(
	text: String,
	size: Vector2 = Vector2(100, 35),
	bg_color: Color = Color(0.2, 0.4, 0.6),
	border_color: Color = Color(0.3, 0.5, 0.7)
) -> Button:
	return UIHelper.create_button(text, size, bg_color, border_color)

# Cria um label com estilo padrão
func create_label(
	text: String = "",
	font_size: int = 14,
	font_color: Color = GameConstants.COLOR_UI_WHITE
) -> Label:
	return UIHelper.create_label(text, font_size, font_color)

# Atualiza o texto do TopBar
func update_top_bar(wave: int, enemies: int, coins: int, hp: int, fps: int = 0) -> void:
	if not top_bar:
		return
	
	var lbl_left = top_bar.get_node_or_null("LblLeft")
	var lbl_center = top_bar.get_node_or_null("LblCenter")
	var lbl_right = top_bar.get_node_or_null("LblRight")
	
	if lbl_left:
		lbl_left.text = "Onda %d  Inimigos %d  FPS %d" % [wave, enemies, fps]
	if lbl_center:
		lbl_center.text = "Moedas %d" % coins
	if lbl_right:
		lbl_right.text = "Vida %d" % hp

# Ajusta painéis responsivos ao tamanho da tela
func adjust_responsive_panels() -> void:
	if not game:
		return
	
	var viewport = game.get_viewport()
	if not viewport:
		return
	
	var screen_width = viewport.get_visible_rect().size.x
	var screen_height = viewport.get_visible_rect().size.y
	var min_screen_width = 1710.0
	
	# Ajustar loja de torres
	if tower_shop_panel:
		var panel_width_expanded = 380.0
		var panel_width = panel_width_expanded if not tower_shop_collapsed else 80.0
		var panel_height = screen_height - GameConstants.UI_TOP_BAR_HEIGHT
		
		if screen_width < min_screen_width and not tower_shop_collapsed:
			panel_width = min(panel_width, screen_width * 0.25)
		
		var hud_safe_zone = 700.0
		var x_pos = screen_width - panel_width
		
		if tower_shop_collapsed and x_pos < hud_safe_zone:
			x_pos = max(650.0, screen_width - panel_width)
		
		tower_shop_panel.position = Vector2(x_pos, GameConstants.UI_TOP_BAR_HEIGHT)
		tower_shop_panel.size = Vector2(panel_width, panel_height)
	
	# Ajustar painel de skills
	if skills_panel:
		var panel_width_expanded = 390.0
		var panel_width = panel_width_expanded if not skills_panel_collapsed else 80.0
		var panel_height = screen_height - GameConstants.UI_TOP_BAR_HEIGHT
		var tower_panel_width = 80.0
		
		if tower_shop_panel:
			tower_panel_width = tower_shop_panel.size.x
		
		if screen_width < min_screen_width and not skills_panel_collapsed:
			var available_width = screen_width - tower_panel_width - 100
			panel_width = min(panel_width, max(available_width * 0.3, 250.0))
		
		var margin = 5.0
		var hud_safe_zone = 700.0
		var x_pos = screen_width - tower_panel_width - panel_width - margin
		
		if skills_panel_collapsed and x_pos < hud_safe_zone:
			x_pos = max(600.0, screen_width - tower_panel_width - panel_width - margin)
		
		if x_pos < 0:
			x_pos = 0
			if not skills_panel_collapsed:
				panel_width = max(250.0, screen_width - tower_panel_width - margin - 10)
		
		skills_panel.position = Vector2(x_pos, GameConstants.UI_TOP_BAR_HEIGHT)
		skills_panel.size = Vector2(panel_width, panel_height)

# Mostra/esconde tooltip
func show_tooltip(text: String, pos: Vector2) -> void:
	if not game_tooltip:
		return
	
	if text.is_empty():
		game_tooltip.visible = false
		return
	
	game_tooltip.visible = true
	var tooltip_label = game_tooltip.get_node_or_null("Label")
	if tooltip_label:
		tooltip_label.text = text
	game_tooltip.position = pos

func hide_tooltip() -> void:
	if game_tooltip:
		game_tooltip.visible = false
