class_name MainMenuController
extends Node3D

## Live 3D atmospheric Main Menu for THE PARADOX MARKET.
## Features a slow camera pan over the dusty 2089 cornfield with New Game & Continue Save.

@onready var menu_camera: Camera3D = $MenuCamera
@onready var new_game_btn: Button = $MenuUI/Margin/VBox/Buttons/NewGameBtn
@onready var continue_btn: Button = $MenuUI/Margin/VBox/Buttons/ContinueBtn
@onready var quit_btn: Button = $MenuUI/Margin/VBox/Buttons/QuitBtn
@onready var save_hint_label: Label = $MenuUI/Margin/VBox/SaveHintLabel

var _time_acc: float = 0.0


func _ready() -> void:
	GameState.set_mode(GameState.Mode.MAIN_MENU)
	menu_camera.make_current()

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)

	var has_save: bool = GameState.has_save_file()
	continue_btn.disabled = not has_save
	save_hint_label.text = "Saved story progress detected." if has_save else "No saved progress yet — start Chapter I."

	AudioManager.play_ambient("wind_dust", -11.0, 1.5)
	AudioManager.play_music("earth_theme", -10.5, 2.2)


func _process(delta: float) -> void:
	_time_acc += delta
	# Gentle sweeping cinematic camera across the dying cornfields toward the farmhouse & horizon
	var x: float = sin(_time_acc * 0.14) * 14.0
	var z: float = 34.0 + cos(_time_acc * 0.11) * 5.0
	menu_camera.global_position = Vector3(x, 4.4 + sin(_time_acc * 0.25) * 0.35, z)
	menu_camera.look_at(Vector3(0.0, 2.4, -10.0), Vector3.UP)


func _on_new_game() -> void:
	AudioManager.play_sfx("ui_chime", -6.0)
	GameState.reset_new_game()
	get_tree().change_scene_to_file("res://scenes/main/Chapter1World.tscn")


func _on_continue() -> void:
	if not GameState.load_progress():
		return
	AudioManager.play_sfx("ui_chime", -6.0)
	get_tree().change_scene_to_file(GameState.current_scene_path)


func _on_quit() -> void:
	AudioManager.play_sfx("interact_click", -8.0)
	get_tree().quit()
