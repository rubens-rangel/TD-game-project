extends Control

func _ready() -> void:
	get_node("Panel/BtnPlay").pressed.connect(_on_play)
	get_node("Panel/BtnExit").pressed.connect(_on_exit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_exit() -> void:
	get_tree().quit()






