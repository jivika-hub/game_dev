extends Node

## Story-controlled DialogueManager autoload.
## Drives sequential lines and optional emotional choices via signals.

signal dialogue_started(dialogue_id: String)
signal line_presented(speaker: String, role: String, text: String, choices: Array)
signal dialogue_finished(dialogue_id: String)

var is_active: bool = false
var current_dialogue_id: String = ""

var _queue: Array = []
var _current_line: Dictionary = {}
var _return_mode: int = GameState.Mode.EXPLORING


func start_dialogue(dialogue_id: String, custom_return_mode: int = -1) -> void:
	var lines: Array = StoryData.get_dialogue(dialogue_id)
	if lines.is_empty():
		return
	start_custom_dialogue(dialogue_id, lines, custom_return_mode)


func start_custom_dialogue(dialogue_id: String, lines: Array, custom_return_mode: int = -1) -> void:
	if lines.is_empty():
		return
	current_dialogue_id = dialogue_id
	_queue = lines.duplicate(true)
	if custom_return_mode >= 0:
		_return_mode = custom_return_mode
	else:
		_return_mode = GameState.current_mode
		if _return_mode == GameState.Mode.DIALOGUE or _return_mode == GameState.Mode.PAUSED:
			_return_mode = GameState.Mode.EXPLORING

	is_active = true
	GameState.set_mode(GameState.Mode.DIALOGUE)
	dialogue_started.emit(current_dialogue_id)
	_present_next()


func advance() -> void:
	if not is_active:
		return
	var choices: Array = _current_line.get("choices", [])
	if not choices.is_empty():
		# Wait for the player to select a choice
		return
	_present_next()


func select_choice(choice_index: int) -> void:
	if not is_active:
		return
	var choices: Array = _current_line.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	var chosen: Dictionary = choices[choice_index]
	var flag_name: String = str(chosen.get("flag", ""))
	if flag_name != "":
		GameState.set_flag(flag_name, true)

	var reply_lines: Array = chosen.get("reply", [])
	if not reply_lines.is_empty():
		# Prepend reply lines ahead of remaining queue
		var merged: Array = reply_lines.duplicate(true)
		merged.append_array(_queue)
		_queue = merged

	_current_line = {}
	_present_next()


func _present_next() -> void:
	if _queue.is_empty():
		_finish_dialogue()
		return
	_current_line = _queue.pop_front()
	var speaker: String = str(_current_line.get("speaker", ""))
	var role: String = str(_current_line.get("role", "protagonist"))
	var text: String = str(_current_line.get("text", ""))
	var choices: Array = _current_line.get("choices", [])
	line_presented.emit(speaker, role, text, choices)


func _finish_dialogue() -> void:
	var finished_id: String = current_dialogue_id
	is_active = false
	current_dialogue_id = ""
	_current_line = {}
	_queue.clear()
	GameState.set_mode(_return_mode)
	dialogue_finished.emit(finished_id)


func cancel_dialogue() -> void:
	if not is_active:
		return
	is_active = false
	current_dialogue_id = ""
	_current_line = {}
	_queue.clear()
	dialogue_finished.emit("")
