extends CanvasLayer
class_name ToastOverlay

const MAX_VISIBLE := 3
const TOAST_WIDTH := 420.0

var notification_manager: NotificationManager
var _container: VBoxContainer
var _toast_nodes: Array = []

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_container = VBoxContainer.new()
	_container.name = "ToastList"
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_theme_constant_override("separation", 8)
	_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_container.offset_top = 64
	_container.offset_bottom = 220
	_container.offset_left = 0
	_container.offset_right = 0
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_container)

func setup(manager: NotificationManager) -> void:
	notification_manager = manager

func _process(delta: float) -> void:
	if notification_manager == null:
		return
	notification_manager.update_notifications(delta)
	_sync_toasts()

func _sync_toasts() -> void:
	var notes: Array = notification_manager.get_notifications()
	var visible_count: int = mini(notes.size(), MAX_VISIBLE)
	while _toast_nodes.size() < visible_count:
		var panel := _make_toast_panel()
		_container.add_child(panel)
		_toast_nodes.append(panel)
	while _toast_nodes.size() > visible_count:
		var extra: Control = _toast_nodes.pop_back()
		extra.queue_free()
	for i in range(visible_count):
		var note: Dictionary = notes[notes.size() - visible_count + i]
		var panel: PanelContainer = _toast_nodes[i]
		var label: Label = panel.get_node("Margin/Label")
		label.text = str(note.get("text", ""))
		var color: Color = note.get("color", Color.WHITE)
		color.a = float(note.get("alpha", 1.0))
		label.add_theme_color_override("font_color", color)
		panel.modulate = Color(1, 1, 1, float(note.get("alpha", 1.0)))

func _make_toast_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(TOAST_WIDTH, 36)
	var style := UIHelper.toast_style()
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	margin.add_child(label)
	panel.add_child(margin)
	return panel
