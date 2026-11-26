@tool
class_name CharacterVisuals
extends Node3D

## Builds grounded, articulated placeholder humanoid visuals for
## Dr. Elias Vance (protagonist) and Maya Vance (daughter NPC),
## and drives smooth procedural idle breathing and walk/sprint gait.

enum Archetype { PROTAGONIST_ELIAS, DAUGHTER_MAYA }

@export var archetype: int = Archetype.PROTAGONIST_ELIAS

var _hip_pivot: Node3D
var _torso_pivot: Node3D
var _head_pivot: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D

var _anim_time: float = 0.0
var _gait_blend: float = 0.0
var _base_hip_y: float = 0.88


func _ready() -> void:
	_build_character()


func _make_mat(col: Color, rough: float = 0.82, metal: float = 0.0, emit: Color = Color.BLACK, emit_str: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_str > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_str
	return m


func _add_part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _build_character() -> void:
	var is_child: bool = (archetype == Archetype.DAUGHTER_MAYA)
	var s: float = 0.72 if is_child else 1.0
	_base_hip_y = 0.88 * s

	var skin_mat := _make_mat(Color(0.76, 0.59, 0.48), 0.72)
	var hair_mat := _make_mat(Color(0.16, 0.12, 0.09) if not is_child else Color(0.19, 0.13, 0.09), 0.85)
	var jacket_mat := _make_mat(
		Color(0.62, 0.34, 0.25) if is_child else Color(0.56, 0.59, 0.63), # Rust cardigan vs silver-slate flight jacket
		0.76 if is_child else 0.52,
		0.0 if is_child else 0.18
	)
	var trim_mat := _make_mat(Color(0.24, 0.27, 0.31), 0.65, 0.12)
	var pants_mat := _make_mat(Color(0.18, 0.20, 0.25) if not is_child else Color(0.24, 0.26, 0.34), 0.88)
	var boot_mat := _make_mat(Color(0.16, 0.12, 0.09), 0.78)
	var patch_mat := _make_mat(Color(0.92, 0.68, 0.28), 0.4, 0.2, Color(0.95, 0.72, 0.30), 0.35)

	_hip_pivot = Node3D.new()
	_hip_pivot.name = "HipPivot"
	_hip_pivot.position = Vector3(0.0, _base_hip_y, 0.0)
	add_child(_hip_pivot)

	# Pelvis / waist
	var pelvis_mesh := BoxMesh.new()
	pelvis_mesh.size = Vector3(0.34, 0.16, 0.22) * s
	_add_part(_hip_pivot, pelvis_mesh, Vector3(0.0, 0.0, 0.0), pants_mat)

	# Torso pivot
	_torso_pivot = Node3D.new()
	_torso_pivot.name = "TorsoPivot"
	_torso_pivot.position = Vector3(0.0, 0.08 * s, 0.0)
	_hip_pivot.add_child(_torso_pivot)

	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.40, 0.50, 0.24) * s
	_add_part(_torso_pivot, chest_mesh, Vector3(0.0, 0.25 * s, 0.0), jacket_mat)

	# Collar / scarf detail
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = 0.11 * s
	collar_mesh.bottom_radius = 0.14 * s
	collar_mesh.height = 0.09 * s
	_add_part(_torso_pivot, collar_mesh, Vector3(0.0, 0.51 * s, 0.0), trim_mat)

	if not is_child:
		# Pilot mission patch & chest telemetry harness on Elias
		var patch_mesh := BoxMesh.new()
		patch_mesh.size = Vector3(0.08, 0.08, 0.02)
		_add_part(_torso_pivot, patch_mesh, Vector3(0.11, 0.36, -0.125), patch_mat)
		var pack_mesh := BoxMesh.new()
		pack_mesh.size = Vector3(0.28, 0.34, 0.11)
		_add_part(_torso_pivot, pack_mesh, Vector3(0.0, 0.28, 0.16), trim_mat)
	else:
		# Warm knitted sweater hem & tiny brass compass held at waist
		var compass_mesh := CylinderMesh.new()
		compass_mesh.top_radius = 0.045
		compass_mesh.bottom_radius = 0.045
		compass_mesh.height = 0.022
		_add_part(_torso_pivot, compass_mesh, Vector3(0.12, 0.08, -0.13), patch_mat, Vector3(70, 0, 0))

	# Head pivot
	_head_pivot = Node3D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector3(0.0, 0.56 * s, 0.0)
	_torso_pivot.add_child(_head_pivot)

	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.055 * s
	neck_mesh.bottom_radius = 0.065 * s
	neck_mesh.height = 0.09 * s
	_add_part(_head_pivot, neck_mesh, Vector3(0.0, 0.03 * s, 0.0), skin_mat)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.125 * s
	head_mesh.height = 0.27 * s
	_add_part(_head_pivot, head_mesh, Vector3(0.0, 0.17 * s, 0.0), skin_mat)

	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.132 * s
	hair_mesh.height = 0.22 * s
	_add_part(_head_pivot, hair_mesh, Vector3(0.0, 0.21 * s, 0.02 * s), hair_mat)

	if is_child:
		# Hair braid down back for Maya
		var braid_mesh := CapsuleMesh.new()
		braid_mesh.radius = 0.036
		braid_mesh.height = 0.24
		_add_part(_head_pivot, braid_mesh, Vector3(0.0, 0.05, 0.10), hair_mat, Vector3(14, 0, 0))

	# Arms
	_left_arm = _build_limb(_torso_pivot, Vector3(-0.26 * s, 0.45 * s, 0.0), 0.56 * s, 0.062 * s, jacket_mat, skin_mat)
	_right_arm = _build_limb(_torso_pivot, Vector3(0.26 * s, 0.45 * s, 0.0), 0.56 * s, 0.062 * s, jacket_mat, skin_mat)

	# Legs
	_left_leg = _build_limb(_hip_pivot, Vector3(-0.11 * s, -0.04 * s, 0.0), 0.80 * s, 0.075 * s, pants_mat, boot_mat)
	_right_leg = _build_limb(_hip_pivot, Vector3(0.11 * s, -0.04 * s, 0.0), 0.80 * s, 0.075 * s, pants_mat, boot_mat)


func _build_limb(parent: Node3D, pivot_pos: Vector3, length: float, radius: float, upper_mat: Material, tip_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	parent.add_child(pivot)

	var limb_mesh := CapsuleMesh.new()
	limb_mesh.radius = radius
	limb_mesh.height = length
	_add_part(pivot, limb_mesh, Vector3(0.0, -length * 0.45, 0.0), upper_mat)

	var tip_mesh := BoxMesh.new()
	tip_mesh.size = Vector3(radius * 1.9, radius * 1.6, radius * 2.5)
	_add_part(pivot, tip_mesh, Vector3(0.0, -length * 0.92, -radius * 0.3), tip_mat)
	return pivot


func update_locomotion(delta: float, horizontal_speed: float, max_speed: float) -> void:
	var target_blend: float = clampf(horizontal_speed / maxf(max_speed, 0.1), 0.0, 1.35)
	_gait_blend = lerpf(_gait_blend, target_blend, clampf(delta * 10.0, 0.0, 1.0))

	if _gait_blend > 0.04:
		var freq: float = lerpf(5.8, 9.6, clampf(_gait_blend, 0.0, 1.0))
		_anim_time += delta * freq
		var swing: float = sin(_anim_time) * 0.58 * clampf(_gait_blend, 0.0, 1.1)
		var bob: float = absf(sin(_anim_time)) * 0.045 * clampf(_gait_blend, 0.0, 1.0)

		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
		_left_arm.rotation.x = -swing * 0.72
		_right_arm.rotation.x = swing * 0.72
		_hip_pivot.position.y = _base_hip_y + bob
		_torso_pivot.rotation.x = lerpf(_torso_pivot.rotation.x, 0.07 * _gait_blend, delta * 8.0)
	else:
		_anim_time += delta * 1.7
		var breath: float = sin(_anim_time) * 0.012
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.0, delta * 8.0)
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, 0.0, delta * 8.0)
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.0, delta * 8.0)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, 0.0, delta * 8.0)
		_hip_pivot.position.y = lerpf(_hip_pivot.position.y, _base_hip_y + breath, delta * 6.0)
		_torso_pivot.rotation.x = lerpf(_torso_pivot.rotation.x, 0.0, delta * 6.0)


func look_toward_world_point(world_point: Vector3, delta: float) -> void:
	if _head_pivot == null:
		return
	var local_dir: Vector3 = to_local(world_point)
	var yaw: float = clampf(atan2(-local_dir.x, -local_dir.z), -0.75, 0.75)
	_head_pivot.rotation.y = lerp_angle(_head_pivot.rotation.y, yaw, clampf(delta * 4.0, 0.0, 1.0))
