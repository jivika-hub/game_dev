class_name DoorInteractable
extends Interactable

## Smooth hinged (farmhouse wood) or sliding (sci-fi airlock) door.

enum DoorStyle { HINGED, SLIDING }

signal door_state_changed(is_open: bool)

@export var door_style: int = DoorStyle.HINGED
@export var door_label: String = "Door"
@export var open_angle_deg: float = 95.0
@export var slide_offset: Vector3 = Vector3(2.2, 0.0, 0.0)
@export var open_duration: float = 0.75

var is_open: bool = false
var _door_pivot: Node3D = null
var _closed_pos: Vector3 = Vector3.ZERO
var _closed_rot_y: float = 0.0
var _tween: Tween = null


func setup_door_pivot(pivot: Node3D) -> void:
	_door_pivot = pivot
	_closed_pos = pivot.position
	_closed_rot_y = pivot.rotation.y
	_refresh_prompt()


func _ready() -> void:
	super._ready()
	_refresh_prompt()


func _refresh_prompt() -> void:
	prompt_text = ("Close " if is_open else "Open ") + door_label


func _on_interact(_actor: Node3D) -> void:
	set_open(not is_open)


func set_open(open_state: bool) -> void:
	is_open = open_state
	_refresh_prompt()
	door_state_changed.emit(is_open)

	if _door_pivot == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_IN_OUT)

	if door_style == DoorStyle.HINGED:
		var target_y: float = _closed_rot_y + (deg_to_rad(open_angle_deg) if is_open else 0.0)
		_tween.tween_property(_door_pivot, "rotation:y", target_y, open_duration)
	else:
		var target_pos: Vector3 = _closed_pos + (slide_offset if is_open else Vector3.ZERO)
		_tween.tween_property(_door_pivot, "position", target_pos, open_duration)
