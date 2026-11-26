class_name PauseMenu
extends CanvasLayer

## Escape-key Pause Menu with persistent Save/Load, Controls summary,
## and Return to Main Menu.

@onready var overlay: ColorRect = $Overlay
@onready var resume_btn: Button = $Overlay/Center/Panel/Margin/VBox/ResumeBtn
@onready var save_btn: Button = $Overlay/Center/Panel/Margin/VBox/SaveBtn
@onready var load_btn: Button = $Overlay/Center/Panel/Margin/VBox/LoadBtn
@onready var menu_btn: Button = $Overlay/Center/Panel/Margin/VBox/MenuBtn
@onready var status_label: Label = $Overlay/Center/Panel/Margin/VBox/StatusLabel


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	status_label.text = ""

	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	menu_btn.pressed.connect(_on_main_menu)
	GameState.mode_changed.connect(_on_mode_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if GameState.current_mode == GameState.Mode.PAUSED:
		_on_resume()
		get_viewport().set_input_as_handled()
	elif GameState.current_mode in [GameState.Mode.EXPLORING, GameState.Mode.DIALOGUE, GameState.Mode.CINEMATIC]:
		GameState.set_mode(GameState.Mode.PAUSED)
		get_viewport().set_input_as_handled()


func _on_mode_changed(new_mode: int, _prev_mode: int) -> void:
	var paused: bool = (new_mode == GameState.Mode.PAUSED)
	overlay.visible = paused
	if paused:
		status_label.text = ""
		load_btn.disabled = not GameState.has_save_file()


func _on_resume() -> void:
	AudioManager.play_sfx("interact_click", -8.0)
	GameState.resume_from_pause()


func _on_save() -> void:
	var player: Node3D = null
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0] as Node3D
	var ok: bool = GameState.save_progress(player)
	status_label.text = "Story progress saved." if ok else "Failed to write save file."
	load_btn.disabled = not GameState.has_save_file()
	AudioManager.play_sfx("ui_chime", -8.0)


func _on_load() -> void:
	if not GameState.load_progress():
		status_label.text = "No save file found."
		return
	AudioManager.play_sfx("ui_chime", -8.0)
	DialogueManager.cancel_dialogue()
	get_tree().paused = false
	GameState.set_mode(GameState.Mode.CINEMATIC)
	get_tree().change_scene_to_file(GameState.current_scene_path)


func _on_main_menu() -> void:
	AudioManager.play_sfx("interact_click", -8.0)
	DialogueManager.cancel_dialogue()
	get_tree().paused = false
	AudioManager.stop_ambient(0.5)
	AudioManager.stop_music(0.5)
	GameState.set_mode(GameState.Mode.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
