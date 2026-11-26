class_name HUDController
extends CanvasLayer

## Minimal cinematic HUD managing letterbox framing, active mission objective,
## 3D waypoint projection, interaction prompt, memory inspection card,
## narrative toasts, and cinematic fade/title transitions.

signal memory_viewer_closed(memory_id: String)

@onready var film_grade: ColorRect = $FilmGrade
@onready var top_bar: ColorRect = $TopLetterbox
@onready var bottom_bar: ColorRect = $BottomLetterbox
@onready var mission_panel: PanelContainer = $MissionPanel
@onready var mission_title_label: Label = $MissionPanel/Margin/VBox/TitleLabel
@onready var mission_obj_label: Label = $MissionPanel/Margin/VBox/ObjectiveLabel
@onready var mission_hint_label: Label = $MissionPanel/Margin/VBox/HintLabel
@onready var memory_count_label: Label = $MissionPanel/Margin/VBox/MemoryCountLabel

@onready var waypoint_root: Control = $WaypointMarker
@onready var waypoint_dist_label: Label = $WaypointMarker/DistLabel
@onready var waypoint_name_label: Label = $WaypointMarker/NameLabel

@onready var prompt_panel: PanelContainer = $InteractPrompt
@onready var prompt_label: Label = $InteractPrompt/Margin/PromptLabel

@onready var memory_modal: ColorRect = $MemoryModal
@onready var mem_title: Label = $MemoryModal/Center/Card/Margin/VBox/Title
@onready var mem_subtitle: Label = $MemoryModal/Center/Card/Margin/VBox/Subtitle
@onready var mem_texture: TextureRect = $MemoryModal/Center/Card/Margin/VBox/ImageFrame/TextureRect
@onready var mem_body: Label = $MemoryModal/Center/Card/Margin/VBox/Body
@onready var mem_reflection: Label = $MemoryModal/Center/Card/Margin/VBox/Reflection
@onready var mem_close_btn: Button = $MemoryModal/Center/Card/Margin/VBox/CloseBtn

@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_label: Label = $ToastPanel/Margin/ToastLabel

@onready var fade_curtain: ColorRect = $FadeCurtain
@onready var title_overlay: Control = $TitleOverlay
@onready var title_main: Label = $TitleOverlay/VBox/MainTitle
@onready var title_sub: Label = $TitleOverlay/VBox/SubTitle

var _active_memory_id: String = ""
var _toast_tween: Tween = null


func _ready() -> void:
	layer = 10
	prompt_panel.visible = false
	memory_modal.visible = false
	toast_panel.visible = false
	toast_panel.modulate.a = 0.0
	waypoint_root.visible = false
	title_overlay.visible = false
	title_overlay.modulate.a = 0.0
	fade_curtain.color = Color(0.0, 0.0, 0.0, 0.0)

	mem_close_btn.pressed.connect(_close_memory_modal)

	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.waypoint_updated.connect(_on_waypoint_updated)
	GameState.mode_changed.connect(_on_mode_changed)
	GameState.memory_inspect_requested.connect(_on_memory_inspect_requested)
	GameState.memory_discovered.connect(_on_memory_discovered)
	GameState.toast_requested.connect(show_toast)

	_refresh_mission_from_manager()
	_update_memory_counter()


func _unhandled_input(event: InputEvent) -> void:
	if memory_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("dialogue_advance") or event.is_action_pressed("pause"):
			_close_memory_modal()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_update_waypoint_projection()


func bind_player(player: PlayerController) -> void:
	if player != null and not player.interact_prompt_changed.is_connected(_on_interact_prompt_changed):
		player.interact_prompt_changed.connect(_on_interact_prompt_changed)


func set_cinematic_bars(enabled: bool, duration: float = 0.75) -> void:
	var target_h: float = 82.0 if enabled else 0.0
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(top_bar, "custom_minimum_size:y", target_h, duration)
	tw.tween_property(top_bar, "offset_bottom", target_h, duration)
	tw.tween_property(bottom_bar, "offset_top", -target_h, duration)


func fade_to_black(duration: float = 1.2) -> Tween:
	var tw := create_tween()
	tw.tween_property(fade_curtain, "color:a", 1.0, duration)
	return tw


func fade_from_black(duration: float = 1.4) -> Tween:
	fade_curtain.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_curtain, "color:a", 0.0, duration)
	return tw


func show_title_card(main_text: String, sub_text: String, hold_seconds: float = 3.2) -> void:
	title_main.text = main_text
	title_sub.text = sub_text
	title_overlay.visible = true
	title_overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title_overlay, "modulate:a", 1.0, 1.0)
	tw.tween_interval(hold_seconds)
	tw.tween_property(title_overlay, "modulate:a", 0.0, 1.1)
	tw.tween_callback(func() -> void: title_overlay.visible = false)


func show_toast(message: String) -> void:
	toast_label.text = message
	toast_panel.visible = true
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func() -> void: toast_panel.visible = false)


func _on_mission_started(_id: String, title: String, objective: String, hint: String) -> void:
	mission_title_label.text = title
	mission_obj_label.text = objective
	mission_hint_label.text = hint
	mission_panel.visible = GameState.current_mode == GameState.Mode.EXPLORING
	_update_memory_counter()


func _refresh_mission_from_manager() -> void:
	if MissionManager.active_mission_id != "":
		mission_title_label.text = MissionManager.active_title
		mission_obj_label.text = MissionManager.active_objective
		mission_hint_label.text = MissionManager.active_hint


func _on_waypoint_updated(_pos: Vector3, label: String, visible_state: bool) -> void:
	waypoint_name_label.text = label
	if not visible_state:
		waypoint_root.visible = false


func _update_waypoint_projection() -> void:
	if not MissionManager.waypoint_visible or GameState.current_mode != GameState.Mode.EXPLORING:
		waypoint_root.visible = false
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		waypoint_root.visible = false
		return

	var target: Vector3 = MissionManager.waypoint_position
	var dist: float = cam.global_position.distance_to(target)
	if dist < 3.0:
		waypoint_root.visible = false
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var behind: bool = cam.is_position_behind(target)
	var screen_pos: Vector2 = cam.unproject_position(target)
	if behind:
		screen_pos.x = vp_size.x - screen_pos.x
		screen_pos.y = vp_size.y - 72.0

	var margin: float = 64.0
	screen_pos.x = clampf(screen_pos.x, margin, vp_size.x - margin)
	screen_pos.y = clampf(screen_pos.y, margin, vp_size.y - margin)

	waypoint_root.visible = true
	waypoint_root.position = screen_pos
	waypoint_dist_label.text = "%dm" % int(round(dist))


func _on_interact_prompt_changed(prompt_text: String, is_visible: bool) -> void:
	if GameState.current_mode != GameState.Mode.EXPLORING:
		prompt_panel.visible = false
		return
	prompt_label.text = "[ E ]  " + prompt_text
	prompt_panel.visible = is_visible


func _on_mode_changed(new_mode: int, _prev_mode: int) -> void:
	var exploring: bool = (new_mode == GameState.Mode.EXPLORING)
	mission_panel.visible = exploring and MissionManager.active_mission_id != ""
	if not exploring:
		prompt_panel.visible = false
	var show_bars: bool = new_mode in [GameState.Mode.CINEMATIC, GameState.Mode.DIALOGUE]
	set_cinematic_bars(show_bars, 0.55)


func _on_memory_discovered(_mem_id: String, _total: int) -> void:
	_update_memory_counter()
	show_toast("Memory recorded in journal.")


func _update_memory_counter() -> void:
	var count: int = GameState.get_family_memory_count()
	memory_count_label.text = "Family Memories Discovered: %d / %d" % [count, GameState.CORE_FAMILY_MEMORY_IDS.size()]
	memory_count_label.visible = (MissionManager.active_mission_id == "explore_farmhouse" or count > 0)


func _on_memory_inspect_requested(memory_id: String) -> void:
	if not StoryData.MEMORIES.has(memory_id):
		return
	_active_memory_id = memory_id
	var data: Dictionary = StoryData.MEMORIES[memory_id]
	mem_title.text = str(data.get("title", "Memory"))
	mem_subtitle.text = str(data.get("subtitle", ""))
	mem_body.text = str(data.get("body", ""))
	mem_reflection.text = str(data.get("reflection", ""))

	var tex_path: String = str(data.get("texture", ""))
	if tex_path != "" and ResourceLoader.exists(tex_path):
		mem_texture.texture = load(tex_path) as Texture2D
		mem_texture.visible = true
	else:
		mem_texture.visible = false

	memory_modal.visible = true
	GameState.set_mode(GameState.Mode.MEMORY_VIEW)


func _close_memory_modal() -> void:
	if not memory_modal.visible:
		return
	var closed_id: String = _active_memory_id
	_active_memory_id = ""
	memory_modal.visible = false
	AudioManager.play_sfx("interact_click", -8.0)
	GameState.set_mode(GameState.Mode.EXPLORING)
	memory_viewer_closed.emit(closed_id)
