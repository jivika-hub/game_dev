class_name PlayerController
extends CharacterBody3D

## Third-person character controller for Dr. Elias Vance.
## Uses CharacterBody3D, SpringArm3D, and Camera3D with smooth camera interpolation,
## collision handling, sprinting, footsteps, and context-sensitive interaction detection.

signal interact_prompt_changed(prompt_text: String, visible: bool)

@export var walk_speed: float = 4.2
@export var sprint_speed: float = 6.9
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0
@export var mouse_sensitivity: float = 0.0024
@export var camera_smoothness: float = 14.0
@export var base_fov: float = 62.0
@export var sprint_fov: float = 67.5

@onready var visual_root: CharacterVisuals = $VisualRoot
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_pitch: Node3D = $CameraPivot/CameraPitch
@onready var spring_arm: SpringArm3D = $CameraPivot/CameraPitch/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/CameraPitch/SpringArm3D/Camera3D
@onready var interaction_detector: Area3D = $InteractionDetector

var is_on_metal_surface: bool = false

var _target_yaw: float = 0.0
var _target_pitch: float = -0.18
var _gravity: float = 18.0
var _footstep_timer: float = 0.0
var _nearby_interactables: Array[Interactable] = []
var _focused_interactable: Interactable = null


func _ready() -> void:
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * 1.8
	_target_yaw = camera_pivot.rotation.y
	_target_pitch = clampf(camera_pitch.rotation.x, deg_to_rad(-48.0), deg_to_rad(32.0))

	interaction_detector.area_entered.connect(_on_interactable_entered)
	interaction_detector.area_exited.connect(_on_interactable_exited)
	GameState.mode_changed.connect(_on_game_mode_changed)


func set_camera_yaw(yaw_rad: float) -> void:
	_target_yaw = yaw_rad
	camera_pivot.rotation.y = yaw_rad
	visual_root.rotation.y = yaw_rad


func activate_player_camera() -> void:
	if camera != null:
		camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_player_control_active():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_target_yaw -= mm.relative.x * mouse_sensitivity
		_target_pitch = clampf(
			_target_pitch - mm.relative.y * mouse_sensitivity,
			deg_to_rad(-48.0),
			deg_to_rad(32.0)
		)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		if _focused_interactable != null and _focused_interactable.can_interact():
			_focused_interactable.interact(self)
			_update_focused_interactable()


func _physics_process(delta: float) -> void:
	# Smooth camera pivot interpolation
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, _target_yaw, clampf(delta * camera_smoothness, 0.0, 1.0))
	camera_pitch.rotation.x = lerpf(camera_pitch.rotation.x, _target_pitch, clampf(delta * camera_smoothness, 0.0, 1.0))

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var input_vec: Vector2 = Vector2.ZERO
	var sprinting: bool = false
	if GameState.is_player_control_active():
		input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		sprinting = Input.is_action_pressed("sprint") and input_vec.length() > 0.1

	var forward: Vector3 = -camera_pivot.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = camera_pivot.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = (right * input_vec.x - forward * input_vec.y)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var target_speed: float = sprint_speed if sprinting else walk_speed
	var desired_horiz: Vector3 = move_dir * target_speed
	var rate: float = acceleration if move_dir.length() > 0.05 else deceleration

	velocity.x = lerpf(velocity.x, desired_horiz.x, clampf(delta * rate, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, desired_horiz.z, clampf(delta * rate, 0.0, 1.0))

	move_and_slide()

	var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
	var horiz_speed: float = horiz_vel.length()

	if horiz_speed > 0.25 and GameState.is_player_control_active():
		var target_model_yaw: float = atan2(-horiz_vel.x, -horiz_vel.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_model_yaw, clampf(delta * 10.5, 0.0, 1.0))

	visual_root.update_locomotion(delta, horiz_speed, walk_speed)

	# Subtle FOV breathing when sprinting
	var desired_fov: float = sprint_fov if (sprinting and horiz_speed > walk_speed * 0.9) else base_fov
	camera.fov = lerpf(camera.fov, desired_fov, clampf(delta * 6.0, 0.0, 1.0))

	# Footstep cadence
	if is_on_floor() and horiz_speed > 0.8 and GameState.is_player_control_active():
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			AudioManager.play_footstep(is_on_metal_surface)
			_footstep_timer = 0.34 if sprinting else 0.50
	else:
		_footstep_timer = 0.14

	if GameState.is_player_control_active():
		_update_focused_interactable()


func _on_game_mode_changed(new_mode: int, _prev_mode: int) -> void:
	if new_mode != GameState.Mode.EXPLORING:
		_clear_focus()


func _on_interactable_entered(area: Area3D) -> void:
	if area is Interactable and not _nearby_interactables.has(area):
		_nearby_interactables.append(area)
		_update_focused_interactable()


func _on_interactable_exited(area: Area3D) -> void:
	if area is Interactable:
		_nearby_interactables.erase(area)
		if area == _focused_interactable:
			_clear_focus()
		_update_focused_interactable()


func _clear_focus() -> void:
	if _focused_interactable != null and is_instance_valid(_focused_interactable):
		_focused_interactable.set_focused(false)
	_focused_interactable = null
	interact_prompt_changed.emit("", false)


func _update_focused_interactable() -> void:
	# Prune freed nodes
	var valid: Array[Interactable] = []
	for item in _nearby_interactables:
		if is_instance_valid(item):
			valid.append(item)
	_nearby_interactables = valid

	var best: Interactable = null
	var best_score: float = -INF
	var cam_fwd: Vector3 = -camera.global_transform.basis.z
	cam_fwd.y = 0.0
	if cam_fwd.length() > 0.01:
		cam_fwd = cam_fwd.normalized()

	for item in _nearby_interactables:
		if not item.can_interact():
			continue
		var to_item: Vector3 = item.global_position - global_position
		var dist: float = to_item.length()
		var dir_flat := Vector3(to_item.x, 0.0, to_item.z).normalized()
		var alignment: float = cam_fwd.dot(dir_flat) if dir_flat.length() > 0.01 else 1.0
		var score: float = alignment * 2.2 - dist * 0.55
		if score > best_score:
			best_score = score
			best = item

	if best != _focused_interactable:
		if _focused_interactable != null and is_instance_valid(_focused_interactable):
			_focused_interactable.set_focused(false)
		_focused_interactable = best
		if _focused_interactable != null:
			_focused_interactable.set_focused(true)
			interact_prompt_changed.emit(_focused_interactable.get_prompt(), true)
		else:
			interact_prompt_changed.emit("", false)
	elif _focused_interactable != null:
		interact_prompt_changed.emit(_focused_interactable.get_prompt(), true)
