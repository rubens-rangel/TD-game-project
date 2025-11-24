extends RefCounted
class_name UIManager

const GameConstants = preload("res://scripts/Constants.gd")

var top_bar: Control
var upgrade_overlay: Control
var game_over_overlay: Control
var loading_screen: Control

var tower_menu: PopupMenu
var barracks_menu: PopupMenu
var sniper_menu: PopupMenu
var aoe_menu: PopupMenu
var buy_menu: PopupMenu

var tower_selected_index: int = -1
var barracks_selected_index: int = -1
var sniper_selected_index: int = -1
var aoe_selected_index: int = -1

var choosing_upgrade: bool = false
var benefit_applied: bool = false
var upgrade_options: Array = []

signal buy_item_requested(item_type: String)
signal upgrade_selected(option_index: int)
signal resume_after_upgrade()
signal game_over_menu()
signal game_over_restart()

func _init(canvas_layer: CanvasLayer):
	_setup_ui(canvas_layer)

func _setup_ui(canvas_layer: CanvasLayer) -> void:
	top_bar = canvas_layer.get_node_or_null("HUD/TopBar")
	upgrade_overlay = canvas_layer.get_node_or_null("UpgradeOverlay")
	game_over_overlay = canvas_layer.get_node_or_null("GameOverOverlay")
	
	if upgrade_overlay:
		upgrade_overlay.visible = false
		var btn1 = upgrade_overlay.get_node_or_null("Panel/Btn1")
		var btn2 = upgrade_overlay.get_node_or_null("Panel/Btn2")
		var btn3 = upgrade_overlay.get_node_or_null("Panel/Btn3")
		var btn_resume = upgrade_overlay.get_node_or_null("Panel/BtnResume")
		
		if btn1:
			btn1.pressed.connect(func(): upgrade_selected.emit(0))
		if btn2:
			btn2.pressed.connect(func(): upgrade_selected.emit(1))
		if btn3:
			btn3.pressed.connect(func(): upgrade_selected.emit(2))
		if btn_resume:
			btn_resume.pressed.connect(func(): resume_after_upgrade.emit())
	
	if game_over_overlay:
		game_over_overlay.visible = false
		var btn_menu = game_over_overlay.get_node_or_null("Panel/BtnMenu")
		var btn_restart = game_over_overlay.get_node_or_null("Panel/BtnRestart")
		
		if btn_menu:
			btn_menu.pressed.connect(func(): game_over_menu.emit())
		if btn_restart:
			btn_restart.pressed.connect(func(): game_over_restart.emit())
	
	_setup_buy_menu()
	_setup_tower_menus(canvas_layer)

func _setup_buy_menu() -> void:
	if not top_bar:
		return
	
	var menu_btn = top_bar.get_node_or_null("BuyMenuButton")
	if not menu_btn:
		menu_btn = MenuButton.new()
		menu_btn.name = "BuyMenuButton"
		top_bar.add_child(menu_btn)
		menu_btn.position = Vector2(810, 8)
		menu_btn.size = Vector2(180, 28)
		menu_btn.text = "Comprar"
	
	buy_menu = menu_btn.get_popup()
	buy_menu.clear()
	buy_menu.add_item("Torre (%d)" % GameConstants.TOWER_COST, 1)
	buy_menu.add_item("Quartel (%d)" % GameConstants.BARRACKS_COST, 2)
	buy_menu.add_item("Mina (%d)" % GameConstants.MINE_COST, 3)
	buy_menu.add_item("Slow Tower (%d)" % GameConstants.SLOW_TOWER_COST, 4)
	buy_menu.add_item("AOE Tower (%d)" % GameConstants.AOE_TOWER_COST, 5)
	buy_menu.add_item("Sniper Tower (%d)" % GameConstants.SNIPER_TOWER_COST, 6)
	buy_menu.add_item("Boost Tower (%d)" % GameConstants.BOOST_TOWER_COST, 7)
	buy_menu.add_item("Muralha (%d)" % GameConstants.WALL_COST, 8)
	buy_menu.add_item("Cura (%d)" % GameConstants.HEALING_STATION_COST, 9)
	buy_menu.id_pressed.connect(_on_buy_menu_pressed)

func _setup_tower_menus(canvas_layer: CanvasLayer) -> void:
	# Tower menu
	var menu_container = Control.new()
	menu_container.name = "TowerMenuContainer"
	menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_menu = PopupMenu.new()
	tower_menu.name = "TowerMenu"
	tower_menu.hide_on_checkable_item_selection = true
	tower_menu.add_item("Alcance +60", 1)
	tower_menu.add_item("Cadencias +", 2)
	tower_menu.add_item("+4 Direcoes", 3)
	tower_menu.add_item("Dano +0.5", 4)
	tower_menu.add_item("Congelamento", 5)
	tower_menu.add_item("Fogo", 6)
	menu_container.add_child(tower_menu)
	canvas_layer.add_child(menu_container)
	
	# Barracks menu
	var barracks_container = Control.new()
	barracks_container.name = "BarracksMenuContainer"
	barracks_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	barracks_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barracks_menu = PopupMenu.new()
	barracks_menu.name = "BarracksMenu"
	barracks_menu.hide_on_checkable_item_selection = true
	barracks_menu.add_item("Dano +0.2", 1)
	barracks_menu.add_item("Tempo Hold +1s", 2)
	barracks_menu.add_item("Spawn Rate -0.5s", 3)
	barracks_menu.add_item("Velocidade Projétil +20", 4)
	barracks_container.add_child(barracks_menu)
	canvas_layer.add_child(barracks_container)
	
	# Sniper menu
	var sniper_container = Control.new()
	sniper_container.name = "SniperMenuContainer"
	sniper_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sniper_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_menu = PopupMenu.new()
	sniper_menu.name = "SniperMenu"
	sniper_menu.hide_on_checkable_item_selection = true
	sniper_menu.add_item("Dano +2", 1)
	sniper_menu.add_item("Taxa de Tiro +", 2)
	sniper_container.add_child(sniper_menu)
	canvas_layer.add_child(sniper_container)
	
	# AOE menu
	var aoe_container = Control.new()
	aoe_container.name = "AOEMenuContainer"
	aoe_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	aoe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aoe_menu = PopupMenu.new()
	aoe_menu.name = "AOEMenu"
	aoe_menu.hide_on_checkable_item_selection = true
	aoe_menu.add_item("Dano +1", 1)
	aoe_menu.add_item("Taxa de Tiro +", 2)
	aoe_menu.add_item("Área +20", 3)
	aoe_container.add_child(aoe_menu)
	canvas_layer.add_child(aoe_container)

func _on_buy_menu_pressed(id: int) -> void:
	var item_types = {
		1: "tower",
		2: "barracks",
		3: "mine",
		4: "slow_tower",
		5: "aoe_tower",
		6: "sniper_tower",
		7: "boost_tower",
		8: "wall",
		9: "healing_station"
	}
	
	if item_types.has(id):
		buy_item_requested.emit(item_types[id])

func update_top_bar(wave: int, enemy_count: int, coins: int, hp: int, is_boss_wave: bool = false) -> void:
	if not top_bar:
		return
	
	var wave_text = "Wave %d (CHEFE!)" % wave if is_boss_wave else "Wave %d" % wave
	
	var lbl_left = top_bar.get_node_or_null("LblLeft")
	var lbl_center = top_bar.get_node_or_null("LblCenter")
	var lbl_right = top_bar.get_node_or_null("LblRight")
	
	if lbl_left:
		lbl_left.text = "%s  Inimigos %d" % [wave_text, enemy_count]
	if lbl_center:
		lbl_center.text = "Moedas %d" % coins
	if lbl_right:
		lbl_right.text = "Vida %d" % hp

func update_buy_menu(coins: int, counts: Dictionary, limits: Dictionary) -> void:
	if not buy_menu:
		return
	
	var items = [
		{"name": "Torre", "cost": GameConstants.TOWER_COST, "count": counts.get("tower", 0), "limit": limits.get("tower", 0)},
		{"name": "Quartel", "cost": GameConstants.BARRACKS_COST, "count": counts.get("barracks", 0), "limit": limits.get("barracks", 0)},
		{"name": "Mina", "cost": GameConstants.MINE_COST, "count": counts.get("mine", 0), "limit": limits.get("mine", 0)},
		{"name": "Slow Tower", "cost": GameConstants.SLOW_TOWER_COST, "count": counts.get("slow_tower", 0), "limit": limits.get("slow_tower", 0)},
		{"name": "AOE Tower", "cost": GameConstants.AOE_TOWER_COST, "count": counts.get("aoe_tower", 0), "limit": limits.get("aoe_tower", 0)},
		{"name": "Sniper Tower", "cost": GameConstants.SNIPER_TOWER_COST, "count": counts.get("sniper_tower", 0), "limit": limits.get("sniper_tower", 0)},
		{"name": "Boost Tower", "cost": GameConstants.BOOST_TOWER_COST, "count": counts.get("boost_tower", 0), "limit": limits.get("boost_tower", 0)},
		{"name": "Muralha", "cost": GameConstants.WALL_COST, "count": counts.get("wall", 0), "limit": limits.get("wall", 0)},
		{"name": "Cura", "cost": GameConstants.HEALING_STATION_COST, "count": counts.get("healing_station", 0), "limit": limits.get("healing_station", 0)}
	]
	
	for i in range(min(items.size(), buy_menu.get_item_count())):
		var item = items[i]
		var text = "%s (%d) [%d/%d]" % [item.name, item.cost, item.count, item.limit]
		buy_menu.set_item_text(i, text)
		buy_menu.set_item_disabled(i, coins < item.cost or item.count >= item.limit)

func show_upgrade_overlay(options: Array) -> void:
	choosing_upgrade = true
	benefit_applied = false
	upgrade_options = options
	
	if upgrade_overlay:
		upgrade_overlay.visible = true
		_update_upgrade_labels()

func hide_upgrade_overlay() -> void:
	choosing_upgrade = false
	if upgrade_overlay:
		upgrade_overlay.visible = false

func show_game_over(wave: int) -> void:
	if game_over_overlay:
		game_over_overlay.visible = true
		var lbl_wave = game_over_overlay.get_node_or_null("Panel/LblWave")
		if lbl_wave:
			lbl_wave.text = "Wave %d" % wave

func hide_game_over() -> void:
	if game_over_overlay:
		game_over_overlay.visible = false

func create_loading_screen(canvas_layer: CanvasLayer) -> void:
	loading_screen = Control.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	loading_screen.add_child(bg)
	
	var center_container = VBoxContainer.new()
	center_container.name = "CenterContainer"
	center_container.set_anchors_preset(Control.PRESET_CENTER)
	center_container.add_theme_constant_override("separation", 20)
	loading_screen.add_child(center_container)
	
	var loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Carregando..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	center_container.add_child(loading_label)
	
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "0%"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	center_container.add_child(progress_label)
	
	var progress_bar_bg = ColorRect.new()
	progress_bar_bg.name = "ProgressBarBG"
	progress_bar_bg.custom_minimum_size = Vector2(400, 20)
	progress_bar_bg.color = Color(0.2, 0.2, 0.3, 1.0)
	center_container.add_child(progress_bar_bg)
	
	var progress_bar = ColorRect.new()
	progress_bar.name = "ProgressBar"
	progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_right = 0.0
	progress_bar.offset_right = 0.0
	progress_bar.color = Color(1.0, 0.9, 0.2, 1.0)
	progress_bar_bg.add_child(progress_bar)
	
	canvas_layer.add_child(loading_screen)
	loading_screen.z_index = 1000

func update_loading_progress(progress: float) -> void:
	if not loading_screen:
		return
	
	var progress_label = loading_screen.get_node_or_null("CenterContainer/ProgressLabel")
	var progress_bar = loading_screen.get_node_or_null("CenterContainer/ProgressBarBG/ProgressBar")
	
	if progress_label:
		progress_label.text = "%d%%" % int(progress * 100)
	
	if progress_bar:
		progress_bar.anchor_right = progress
		progress_bar.offset_right = 0

func hide_loading_screen() -> void:
	if loading_screen:
		loading_screen.queue_free()
		loading_screen = null

func _update_upgrade_labels() -> void:
	if not upgrade_overlay:
		return
	
	var btn1 = upgrade_overlay.get_node_or_null("Panel/Btn1")
	var btn2 = upgrade_overlay.get_node_or_null("Panel/Btn2")
	var btn3 = upgrade_overlay.get_node_or_null("Panel/Btn3")
	
	if btn1 and upgrade_options.size() >= 1:
		btn1.text = upgrade_options[0].get("label", "")
	if btn2 and upgrade_options.size() >= 2:
		btn2.text = upgrade_options[1].get("label", "")
	if btn3 and upgrade_options.size() >= 3:
		btn3.text = upgrade_options[2].get("label", "")


