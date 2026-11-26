class_name Interactable
extends Area3D

## Base reusable Interactable node.
## Placed on Layer 3 (Interactables) for clean detection by the Player's InteractionDetector.

signal interacted(actor: Node3D)
signal focus_changed(is_focused: bool)

@export var prompt_text: String = "Examine"
@export var interaction_enabled: bool = true
@export var one_shot: bool = false
@export var interact_sfx: String = "interact_click"

var _has_triggered: bool = false
var _is_focused: bool = false
var _highlight_ring: MeshInstance3D = null


func _ready() -> void:
	collision_layer = 4 # Layer 3: Interactables
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactables")
	_create_subtle_indicator()


func _create_subtle_indicator() -> void:
	# Small restrained glowing beacon dot when focused
	_highlight_ring = MeshInstance3D.new()
	_highlight_ring.name = "FocusBeacon"
	var sphere := SphereMesh.new()
	sphere.radius = 0.055
	sphere.height = 0.11
	_highlight_ring.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.80, 0.42, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.98, 0.78, 0.36)
	mat.emission_energy_multiplier = 2.4
	mat.roughness = 0.2
	_highlight_ring.material_override = mat
	_highlight_ring.position = Vector3(0.0, 0.35, 0.0)
	_highlight_ring.visible = false
	add_child(_highlight_ring)


func can_interact() -> bool:
	if not interaction_enabled:
		return false
	if one_shot and _has_triggered:
		return false
	return true


func get_prompt() -> String:
	return prompt_text


func set_focused(focused: bool) -> void:
	if _is_focused == focused:
		return
	_is_focused = focused
	if _highlight_ring != null:
		_highlight_ring.visible = focused and can_interact()
	focus_changed.emit(focused)


func interact(actor: Node3D) -> void:
	if not can_interact():
		return
	_has_triggered = true
	if interact_sfx != "":
		AudioManager.play_sfx(interact_sfx, -6.0)
	_on_interact(actor)
	interacted.emit(actor)
	if one_shot and _highlight_ring != null:
		_highlight_ring.visible = false


func _on_interact(_actor: Node3D) -> void:
	pass
