extends PanelContainer
class_name StructureInspectPanel

signal upgrade_chosen(id: int)
signal sell_confirmed
signal closed

const PANEL_SIZE := Vector2(300, 360)
const CONTENT_WIDTH := 264.0
const SCROLL_HEIGHT := 148.0

var _title: Label
var _stats: Label
var _scroll: ScrollContainer
var _upgrade_list: VBoxContainer
var _sell_btn: Button
var _confirming_sell: bool = false
var _sell_refund: int = 0
var _can_sell: bool = true
var _pending_screen_pos: Vector2 = Vector2.ZERO
var _keep_position: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	z_index = 30
	add_theme_stylebox_override("panel", UIHelper.panel_style(18, 14))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_theme_constant_override("separation", 8)

	var header := HBoxContainer.new()
	_title = UIHelper.create_label("Estrutura", 16, GameConstants.COLOR_UI_GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(32, 28)
	UIHelper.apply_button_theme(close_btn, UIHelper.BTN_SECONDARY)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)
	vbox.add_child(header)

	_stats = UIHelper.create_label("", 12, Color(0.78, 0.8, 0.9))
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	vbox.add_child(_stats)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(CONTENT_WIDTH, SCROLL_HEIGHT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_list = VBoxContainer.new()
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_upgrade_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_upgrade_list)
	vbox.add_child(_scroll)

	_sell_btn = UIHelper.danger_button("Vender", Vector2(CONTENT_WIDTH, 36))
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sell_btn.pressed.connect(_on_sell_pressed)
	vbox.add_child(_sell_btn)

	margin.add_child(vbox)
	add_child(margin)

func present(data: Dictionary) -> void:
	_confirming_sell = false
	_keep_position = visible
	_pending_screen_pos = data.get("screen_pos", Vector2.ZERO)
	_title.text = str(data.get("title", "Estrutura"))
	_stats.text = str(data.get("stats", ""))
	_sell_refund = int(data.get("sell_refund", 0))
	_can_sell = bool(data.get("can_sell", true))
	_refresh_sell_button()
	for child in _upgrade_list.get_children():
		_upgrade_list.remove_child(child)
		child.queue_free()
	var upgrades: Array = data.get("upgrades", [])
	for row in upgrades:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var id: int = int(row.get("id", 0))
		var text: String = str(row.get("text", ""))
		var enabled: bool = bool(row.get("enabled", true))
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not enabled
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		UIHelper.apply_button_theme(btn, UIHelper.BTN_PRIMARY if enabled else UIHelper.BTN_DISABLED)
		btn.pressed.connect(func():
			upgrade_chosen.emit(id)
		)
		_upgrade_list.add_child(btn)
	if _scroll:
		_scroll.scroll_vertical = 0
	visible = true
	if not _keep_position:
		_place_on_screen(_pending_screen_pos)
	else:
		size = PANEL_SIZE
	call_deferred("_finish_layout")

func hide_panel() -> void:
	_confirming_sell = false
	visible = false
	closed.emit()

func _finish_layout() -> void:
	if not visible:
		return
	size = PANEL_SIZE
	if not _keep_position:
		_place_on_screen(_pending_screen_pos)
	if _scroll:
		_scroll.scroll_vertical = 0

func _place_on_screen(screen_pos: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := PANEL_SIZE
	var pos := screen_pos + Vector2(16, 16)
	if pos.x + panel_size.x > viewport_size.x:
		pos.x = viewport_size.x - panel_size.x - 12
	if pos.y + panel_size.y > viewport_size.y:
		pos.y = viewport_size.y - panel_size.y - 12
	pos.x = max(8, pos.x)
	pos.y = max(GameConstants.UI_TOP_BAR_HEIGHT + 8, pos.y)
	position = pos
	size = panel_size

func _refresh_sell_button() -> void:
	if not _can_sell:
		_sell_btn.visible = false
		return
	_sell_btn.visible = true
	if _confirming_sell:
		_sell_btn.text = "Confirmar venda (+%d moedas)" % _sell_refund
	else:
		_sell_btn.text = "Vender (+%d moedas)" % _sell_refund

func _on_sell_pressed() -> void:
	if not _confirming_sell:
		_confirming_sell = true
		_refresh_sell_button()
		return
	sell_confirmed.emit()

func _on_close() -> void:
	hide_panel()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := get_global_rect()
		if not local.has_point(event.position):
			hide_panel()
