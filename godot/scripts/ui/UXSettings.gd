extends RefCounted
class_name UXSettings

const PATH := "user://ux_settings.cfg"

static func load_file() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(PATH)
	return config

static func get_value(section: String, key: String, default_value: Variant) -> Variant:
	var config := load_file()
	return config.get_value(section, key, default_value)

static func set_value(section: String, key: String, value: Variant) -> void:
	var config := load_file()
	config.set_value(section, key, value)
	config.save(PATH)

static func is_tutorial_done() -> bool:
	return bool(get_value("onboarding", "tutorial_done", false))

static func set_tutorial_done(done: bool = true) -> void:
	set_value("onboarding", "tutorial_done", done)

static func show_fps() -> bool:
	return bool(get_value("display", "show_fps", true))

static func set_show_fps(enabled: bool) -> void:
	set_value("display", "show_fps", enabled)

static func shop_start_collapsed() -> bool:
	return bool(get_value("hud", "shop_start_collapsed", true))

static func set_shop_start_collapsed(enabled: bool) -> void:
	set_value("hud", "shop_start_collapsed", enabled)

static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

static func set_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	set_value("display", "fullscreen", enabled)

static func apply_saved_display() -> void:
	if bool(get_value("display", "fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
