class_name Chapter1Director
extends Node3D

## Orchestrates Chapter I Earth progression:
## 1. Cinematic Dying Earth opening flyover & narration
## 2. Cornfield exploration -> Vance Farmhouse -> Maya & Family Memories
## 3. Horizon Outpost 09 -> Gravitational Anomaly Puzzle
## 4. Multi-shot Cinematic Spacecraft Launch -> Transition to ParadoxMarketArrival.tscn

@onready var environment_node: DyingEarthController = $DyingEarthEnvironment
@onready var farmhouse: FarmhouseBuilder = $Farmhouse
@onready var facility: FacilityBuilder = $ResearchFacility
@onready var player: PlayerController = $Player
@onready var opening_camera: Camera3D = $OpeningCamera
@onready var hud: HUDController = $HUD
@onready var dialogue_ui: DialogueUI = $DialogueBox
@onready var signal_puzzle: SignalPuzzleUI = $SignalPuzzleUI
@onready var pause_menu: PauseMenu = $PauseMenu

var _opening_orbit_active: bool = false
var _opening_time: float = 0.0


func _ready() -> void:
	GameState.current_scene_path = "res://scenes/main/Chapter1World.tscn"
	hud.bind_player(player)

	# Connect world signals
	farmhouse.player_entered_farmhouse.connect(_on_entered_farmhouse)
	farmhouse.player_exited_farmhouse.connect(_on_exited_farmhouse)

	var maya := farmhouse.get_node_or_null("DaughterNPC") as DaughterNPC
	if maya != null:
		maya.conversation_completed.connect(_on_maya_conversation_completed)

	facility.player_entered_facility.connect(_on_entered_facility)
	facility.player_exited_facility.connect(_on_exited_facility)
	facility.launch_requested.connect(_on_launch_requested)

	signal_puzzle.puzzle_solved.connect(_on_puzzle_solved)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

	# Start Earth soundscape
	AudioManager.play_ambient("wind_dust", -10.5, 1.5)
	AudioManager.play_music("earth_theme", -10.0, 2.0)

	if GameState.pending_load_from_save:
		_restore_from_save()
	else:
		_start_opening_cinematic()


func _process(delta: float) -> void:
	if _opening_orbit_active and opening_camera != null:
		_opening_time += delta
		var t: float = clampf(_opening_time / 7.2, 0.0, 1.0)
		var ease_t: float = t * t * (3.0 - 2.0 * t)
		# Sweep high above the endless cornfield toward the farmhouse & distant Outpost spire
		var start_pos := Vector3(-16.0, 8.5, 58.0)
		var end_pos := Vector3(2.8, 3.6, 46.5)
		opening_camera.global_position = start_pos.lerp(end_pos, ease_t)
		var look_target := Vector3(0.0, 2.2, 4.0).lerp(Vector3(0.0, 2.0, -10.0), ease_t)
		opening_camera.look_at(look_target, Vector3.UP)


func _start_opening_cinematic() -> void:
	GameState.chapter_stage = "opening"
	GameState.set_mode(GameState.Mode.CINEMATIC)
	player.global_position = Vector3(0.0, 0.08, 42.0)
	player.set_camera_yaw(0.0) # Facing North (-Z) toward Farmhouse

	opening_camera.global_position = Vector3(-16.0, 8.5, 58.0)
	opening_camera.make_current()
	_opening_orbit_active = true
	_opening_time = 0.0

	hud.fade_from_black(2.0)
	hud.show_title_card("THE PARADOX MARKET", "2089  —  CHAPTER I: THE LAST HARVEST", 3.6)

	await get_tree().create_timer(6.8).timeout
	if not is_inside_tree():
		return
	_opening_orbit_active = false
	player.activate_player_camera()
	DialogueManager.start_dialogue("opening_monologue", GameState.Mode.EXPLORING)


func _restore_from_save() -> void:
	GameState.pending_load_from_save = false
	if GameState.has_saved_player_transform:
		player.global_position = GameState.saved_player_position
		player.set_camera_yaw(GameState.saved_player_yaw)
	else:
		player.global_position = Vector3(0.0, 0.08, 42.0)
		player.set_camera_yaw(0.0)

	player.activate_player_camera()
	GameState.set_mode(GameState.Mode.EXPLORING)
	hud.fade_from_black(1.0)
	_sync_mission_for_current_flags()
	GameState.notify("Loaded saved story progress.")


func _sync_mission_for_current_flags() -> void:
	if bool(GameState.get_flag("anomaly_decoded", false)):
		MissionManager.start_mission("initiate_launch", facility.get_launch_terminal_world_pos(), "LAUNCH TERMINAL", true)
	elif bool(GameState.get_flag("entered_facility", false)):
		MissionManager.start_mission("investigate_anomaly", facility.get_anomaly_console_world_pos(), "TELEMETRY ARRAY", true)
	elif bool(GameState.get_flag("talked_to_maya", false)):
		MissionManager.start_mission("go_to_facility", facility.get_airlock_world_pos(), "HORIZON OUTPOST 09", true)
	elif bool(GameState.get_flag("entered_farmhouse", false)):
		MissionManager.start_mission("explore_farmhouse", Vector3(2.8, 1.7, -0.5), "MAYA", true)
	else:
		MissionManager.start_mission("walk_to_farmhouse", Vector3(0.0, 2.0, 5.5), "VANCE FARMHOUSE", true)


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "opening_monologue":
		GameState.chapter_stage = "cornfield"
		MissionManager.start_mission("walk_to_farmhouse", Vector3(0.0, 2.0, 5.5), "VANCE FARMHOUSE", true)
		GameState.save_progress(player)


func _on_entered_farmhouse() -> void:
	AudioManager.set_ambient_volume(-19.0, 0.9)
	if not bool(GameState.get_flag("entered_farmhouse", false)):
		GameState.set_flag("entered_farmhouse", true)
		GameState.chapter_stage = "farmhouse"
		if not bool(GameState.get_flag("talked_to_maya", false)):
			MissionManager.start_mission("explore_farmhouse", Vector3(2.8, 1.7, -0.5), "MAYA", true)
		GameState.save_progress(player)


func _on_exited_farmhouse() -> void:
	AudioManager.set_ambient_volume(-10.5, 0.9)


func _on_maya_conversation_completed() -> void:
	GameState.chapter_stage = "to_facility"
	MissionManager.start_mission("go_to_facility", facility.get_airlock_world_pos(), "HORIZON OUTPOST 09", true)
	GameState.save_progress(player)


func _on_entered_facility() -> void:
	AudioManager.set_ambient_volume(-28.0, 0.9)
	if not bool(GameState.get_flag("entered_facility", false)):
		GameState.set_flag("entered_facility", true)
		GameState.chapter_stage = "facility"
		if not bool(GameState.get_flag("anomaly_decoded", false)):
			MissionManager.start_mission("investigate_anomaly", facility.get_anomaly_console_world_pos(), "TELEMETRY ARRAY", true)
			DialogueManager.start_dialogue("facility_arrival", GameState.Mode.EXPLORING)
		GameState.save_progress(player)


func _on_exited_facility() -> void:
	AudioManager.set_ambient_volume(-10.5, 0.9)


func _on_puzzle_solved() -> void:
	GameState.chapter_stage = "ready_for_launch"
	MissionManager.start_mission("initiate_launch", facility.get_launch_terminal_world_pos(), "LAUNCH TERMINAL", true)
	DialogueManager.start_dialogue("puzzle_solved", GameState.Mode.EXPLORING)
	GameState.save_progress(player)


func _on_launch_requested() -> void:
	_run_launch_cinematic()


func _run_launch_cinematic() -> void:
	GameState.chapter_stage = "launch_sequence"
	GameState.set_mode(GameState.Mode.CINEMATIC)
	MissionManager.clear_waypoint()
	AudioManager.stop_music(1.2)
	AudioManager.stop_ambient(1.2)

	# Fade briefly into hero launch camera
	var fade_in_cut := hud.fade_to_black(0.65)
	await fade_in_cut.finished
	if not is_inside_tree():
		return

	# Shot 1: Wide hero shot of Aethelgard IV + retracting gantry clamps
	facility.activate_launch_camera(0)
	hud.fade_from_black(0.8)
	facility.retract_gantry_clamps()
	AudioManager.play_sfx("launch_rumble", -2.5)

	# Play Elias's final radio transmission to Maya & Clara
	DialogueManager.start_dialogue("launch_transmission", GameState.Mode.CINEMATIC)
	await DialogueManager.dialogue_finished
	if not is_inside_tree():
		return

	# Shot 2: Close pad-level engine ignition!
	facility.activate_launch_camera(1)
	facility.ignite_and_launch()
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree():
		return

	# Shot 3: Wide sky tracking shot as Aethelgard IV pierces the dusty sky
	facility.activate_launch_camera(2)
	hud.show_title_card("ASCENT", "LEAVING EARTH — ORBITAL VECTOR LOCKED", 2.8)
	await get_tree().create_timer(4.4).timeout
	if not is_inside_tree():
		return

	var fade_out := hud.fade_to_black(1.6)
	await fade_out.finished
	if not is_inside_tree():
		return

	# Save chapter progression and enter deep space for the Cosmic Entity & Paradox Market
	GameState.chapter_stage = "orbital_crossing"
	GameState.current_scene_path = "res://scenes/environment/ParadoxMarketArrival.tscn"
	GameState.save_progress(null)
	get_tree().change_scene_to_file("res://scenes/environment/ParadoxMarketArrival.tscn")
