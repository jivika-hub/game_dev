class_name DialogueUI
extends CanvasLayer

## Cinematic story-controlled dialogue UI driven purely by DialogueManager signals.

@onready var root_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/Margin/VBox/Header/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var choices_box: VBoxContainer = $DialoguePanel/Margin/VBox/ChoicesContainer
@onready var continue_label: Label = $DialoguePanel/Margin/VBox/ContinueHint

const ROLE_COLORS: Dictionary = {
	"protagonist": Color(0.95, 0.84, 0.58),
	"daughter": Color(0.95, 0.70, 0.54),
	"system": Color(0.45, 0.88, 0.98),
	"entity": Color(0.84, 0.72, 1.0)
}

var _full_text: String = ""
var _shown_chars: float = 0.0
var _is_typing: bool = false
var _pending_choices: Array = []
var _chars_per_sec: float = 55.0


func _ready() -> void:
	layer = 20
	root_panel.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_presented.connect(_on_line_presented)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)


func _process(delta: float) -> void:
	if not root_panel.visible or not _is_typing:
		return
	_shown_chars += delta * _chars_per_sec
	var count: int = mini(int(_shown_chars), _full_text.length())
	text_label.visible_characters = count
	if count >= _full_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not root_panel.visible or not DialogueManager.is_active:
		return
	if GameState.current_mode == GameState.Mode.PAUSED:
		return

	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var kc: int = (event as InputEventKey).physical_keycode
		if not _is_typing and not _pending_choices.is_empty():
			if kc == KEY_1 and _pending_choices.size() >= 1:
				_choose(0)
				get_viewport().set_input_as_handled()
				return
			elif kc == KEY_2 and _pending_choices.size() >= 2:
				_choose(1)
				get_viewport().set_input_as_handled()
				return

	var advance_pressed: bool = (
		event.is_action_pressed("dialogue_advance")
		or event.is_action_pressed("interact")
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	)
	if advance_pressed:
		if _is_typing:
			_finish_typing()
			get_viewport().set_input_as_handled()
		elif _pending_choices.is_empty():
			AudioManager.play_sfx("interact_click", -10.0)
			DialogueManager.advance()
			get_viewport().set_input_as_handled()


func _on_dialogue_started(_dialogue_id: String) -> void:
	root_panel.visible = true


func _on_line_presented(speaker: String, role: String, text: String, choices: Array) -> void:
	speaker_label.text = speaker
	speaker_label.add_theme_color_override("font_color", ROLE_COLORS.get(role, Color(0.95, 0.90, 0.78)))

	_full_text = text
	_shown_chars = 0.0
	_is_typing = true
	_pending_choices = choices.duplicate(true)

	text_label.text = _full_text
	text_label.visible_characters = 0

	_clear_choices()
	continue_label.visible = false
	AudioManager.play_sfx("ui_chime", -14.0, 0.95 if role == "entity" else 1.08)


func _finish_typing() -> void:
	_is_typing = false
	text_label.visible_characters = -1
	if _pending_choices.is_empty():
		continue_label.visible = true
	else:
		continue_label.visible = false
		_populate_choices()


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()
	choices_box.visible = false


func _populate_choices() -> void:
	_clear_choices()
	choices_box.visible = true
	for i in range(_pending_choices.size()):
		var choice: Dictionary = _pending_choices[i]
		var btn := Button.new()
		btn.text = "[%d]  %s" % [i + 1, str(choice.get("label", "Respond"))]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		var idx: int = i
		btn.pressed.connect(func() -> void: _choose(idx))
		choices_box.add_child(btn)


func _choose(index: int) -> void:
	_pending_choices.clear()
	_clear_choices()
	AudioManager.play_sfx("interact_click", -8.0)
	DialogueManager.select_choice(index)


func _on_dialogue_finished(_dialogue_id: String) -> void:
	_is_typing = false
	_pending_choices.clear()
	_clear_choices()
	root_panel.visible = false
