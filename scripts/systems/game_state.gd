extends Node

## Central GameState autoload managing gameplay modes, story flags,
## discovered family memories, playtime tracking, and JSON save/load persistence.

enum Mode {
	MAIN_MENU,
	CINEMATIC,
	EXPLORING,
	DIALOGUE,
	MEMORY_VIEW,
	PUZZLE,
	PAUSED,
	ENDED
}

signal mode_changed(new_mode: int, previous_mode: int)
signal flag_changed(flag_name: String, value: Variant)
signal memory_discovered(memory_id: String, total_count: int)
signal memory_inspect_requested(memory_id: String)
signal puzzle_requested()
signal toast_requested(message: String)
signal save_completed(success: bool, message: String)

const SAVE_PATH: String = "user://paradox_market_save.json"
const CORE_FAMILY_MEMORY_IDS: Array[String] = [
	"family_porch_photo",
	"clara_letter_and_archive",
	"maya_star_drawing",
	"maya_farm_drawing"
]

var current_mode: int = Mode.MAIN_MENU
var _pre_pause_mode: int = Mode.EXPLORING

var chapter_stage: String = "opening"
var current_scene_path: String = "res://scenes/main/Chapter1World.tscn"
var flags: Dictionary = {}
var discovered_memories: Array[String] = []
var elapsed_seconds: float = 0.0

var pending_load_from_save: bool = false
var saved_player_position: Vector3 = Vector3.ZERO
var saved_player_yaw: float = 0.0
var has_saved_player_transform: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()


func _process(delta: float) -> void:
	if current_mode in [Mode.EXPLORING, Mode.CINEMATIC, Mode.DIALOGUE, Mode.MEMORY_VIEW, Mode.PUZZLE]:
		elapsed_seconds += delta


func _ensure_input_actions() -> void:
	var bindings: Dictionary = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"pause": [KEY_ESCAPE],
		"dialogue_advance": [KEY_SPACE, KEY_ENTER]
	}
	for action_name in bindings.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if InputMap.action_get_events(action_name).is_empty():
			for keycode in bindings[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action_name, ev)


func set_mode(new_mode: int) -> void:
	if new_mode == current_mode:
		_sync_mouse_mode()
		return
	var prev: int = current_mode
	current_mode = new_mode
	if new_mode == Mode.PAUSED:
		_pre_pause_mode = prev
		get_tree().paused = true
	else:
		get_tree().paused = false
	_sync_mouse_mode()
	mode_changed.emit(new_mode, prev)


func resume_from_pause() -> void:
	if current_mode == Mode.PAUSED:
		set_mode(_pre_pause_mode)


func _sync_mouse_mode() -> void:
	if current_mode == Mode.EXPLORING:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func is_player_control_active() -> bool:
	return current_mode == Mode.EXPLORING


func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)


func discover_memory(memory_id: String) -> bool:
	var newly_discovered: bool = false
	if not discovered_memories.has(memory_id):
		discovered_memories.append(memory_id)
		newly_discovered = true
		memory_discovered.emit(memory_id, discovered_memories.size())
	memory_inspect_requested.emit(memory_id)
	return newly_discovered


func get_family_memory_count() -> int:
	var count: int = 0
	for mem_id in CORE_FAMILY_MEMORY_IDS:
		if discovered_memories.has(mem_id):
			count += 1
	return count


func request_puzzle() -> void:
	puzzle_requested.emit()


func notify(message: String) -> void:
	toast_requested.emit(message)


func reset_new_game() -> void:
	chapter_stage = "opening"
	current_scene_path = "res://scenes/main/Chapter1World.tscn"
	flags.clear()
	discovered_memories.clear()
	elapsed_seconds = 0.0
	pending_load_from_save = false
	has_saved_player_transform = false
	saved_player_position = Vector3.ZERO
	saved_player_yaw = 0.0
	DialogueManager.cancel_dialogue()
	MissionManager.reset_missions()


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_progress(player_node: Node3D = null) -> bool:
	if player_node != null and is_instance_valid(player_node):
		saved_player_position = player_node.global_position
		saved_player_yaw = player_node.rotation.y
		has_saved_player_transform = true

	var payload: Dictionary = {
		"version": 1,
		"chapter_stage": chapter_stage,
		"scene_path": current_scene_path,
		"flags": flags,
		"discovered_memories": discovered_memories,
		"elapsed_seconds": elapsed_seconds,
		"mission_state": MissionManager.serialize(),
		"has_player_transform": has_saved_player_transform,
		"player_pos": [saved_player_position.x, saved_player_position.y, saved_player_position.z],
		"player_yaw": saved_player_yaw
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "Unable to write save file.")
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit(true, "Story progress saved.")
	notify("Progress saved.")
	return true


func load_progress() -> bool:
	if not has_save_file():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed

	chapter_stage = str(data.get("chapter_stage", "cornfield"))
	current_scene_path = str(data.get("scene_path", "res://scenes/main/Chapter1World.tscn"))
	flags = data.get("flags", {}).duplicate(true)

	discovered_memories.clear()
	var loaded_mems: Variant = data.get("discovered_memories", [])
	if typeof(loaded_mems) == TYPE_ARRAY:
		for item in loaded_mems:
			discovered_memories.append(str(item))

	elapsed_seconds = float(data.get("elapsed_seconds", 0.0))
	has_saved_player_transform = bool(data.get("has_player_transform", false))
	var pos_arr: Variant = data.get("player_pos", [0.0, 0.0, 0.0])
	if typeof(pos_arr) == TYPE_ARRAY and pos_arr.size() == 3:
		saved_player_position = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	saved_player_yaw = float(data.get("player_yaw", 0.0))

	var mission_data: Variant = data.get("mission_state", {})
	if typeof(mission_data) == TYPE_DICTIONARY:
		MissionManager.deserialize(mission_data)

	pending_load_from_save = true
	return true


func format_elapsed_time() -> String:
	var total: int = int(elapsed_seconds)
	var mins: int = total / 60
	var secs: int = total % 60
	return "%02d:%02d" % [mins, secs]
