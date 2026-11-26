@tool
class_name CornfieldGenerator
extends Node3D

## Procedurally generates an endless-feeling dying Earth cornfield using
## MultiMeshInstance3D (single draw call) with custom wind-sway vertex shader,
## automatically carving clean clearings for roads, the farmhouse, and Outpost 09.

@export var field_half_extent_x: float = 95.0
@export var field_min_z: float = -105.0
@export var field_max_z: float = 75.0
@export var stalk_count: int = 3200
@export var seed_value: int = 2089

var _multimesh_instance: MultiMeshInstance3D


func _ready() -> void:
	_build_cornfield()


func _is_in_clearing(x: float, z: float) -> bool:
	# Main north-south dirt access road
	if absf(x) < 4.2 and z > -52.0 and z < 66.0:
		return true
	# Farmhouse yard clearing
	if x > -14.5 and x < 14.5 and z > -13.0 and z < 13.5:
		return true
	# Research Facility & Launch Pad compound
	if x > -26.0 and x < 26.0 and z > -106.0 and z < -45.5:
		return true
	return false


func _build_stalk_mesh() -> ArrayMesh:
	# Build a lightweight crossed-leaf + central stalk ArrayMesh (~28 triangles)
	# so 3,200 stalks render effortlessly at 60+ FPS with rich silhouette.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Central tapered stalk (two crossed vertical quads, height 2.5m, centered vertically at 1.25)
	var h: float = 2.55
	var w_bot: float = 0.055
	var w_top: float = 0.025
	for angle_deg in [0.0, 90.0]:
		var rad: float = deg_to_rad(angle_deg)
		var dx: float = cos(rad)
		var dz: float = sin(rad)
		var p0 := Vector3(-dx * w_bot, 0.0, -dz * w_bot)
		var p1 := Vector3(dx * w_bot, 0.0, dz * w_bot)
		var p2 := Vector3(dx * w_top, h, dz * w_top)
		var p3 := Vector3(-dx * w_top, h, -dz * w_top)
		_add_quad(st, p0, p1, p2, p3)

	# Four drooping corn leaves at staggered heights & angles
	var leaf_configs: Array = [
		[0.75, 25.0, 0.65, 0.14],
		[1.15, 145.0, 0.72, 0.14],
		[1.55, 235.0, 0.68, 0.13],
		[1.92, 325.0, 0.56, 0.11]
	]
	for cfg in leaf_configs:
		var ly: float = cfg[0]
		var ang: float = deg_to_rad(cfg[1])
		var length: float = cfg[2]
		var half_w: float = cfg[3] * 0.5
		var fwd := Vector3(cos(ang), 0.0, sin(ang))
		var side := Vector3(-sin(ang), 0.0, cos(ang))

		var b0 := Vector3(0.0, ly, 0.0) - side * half_w
		var b1 := Vector3(0.0, ly, 0.0) + side * half_w
		var m0 := fwd * (length * 0.55) + Vector3(0.0, ly + 0.16, 0.0) - side * (half_w * 0.85)
		var m1 := fwd * (length * 0.55) + Vector3(0.0, ly + 0.16, 0.0) + side * (half_w * 0.85)
		var tip := fwd * length + Vector3(0.0, ly - 0.14, 0.0)

		_add_quad(st, b0, b1, m1, m0)
		st.add_vertex(m0)
		st.add_vertex(m1)
		st.add_vertex(tip)

	st.generate_normals()
	return st.commit()


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _build_cornfield() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var transforms: Array[Transform3D] = []
	var attempts: int = 0
	var max_attempts: int = stalk_count * 3

	while transforms.size() < stalk_count and attempts < max_attempts:
		attempts += 1
		# Concentrate more densely near the playable corridor, fading smoothly to horizon
		var x: float
		var z: float
		if attempts % 3 != 0:
			x = rng.randf_range(-42.0, 42.0)
			z = rng.randf_range(-72.0, 58.0)
		else:
			x = rng.randf_range(-field_half_extent_x, field_half_extent_x)
			z = rng.randf_range(field_min_z, field_max_z)

		# Snap loosely into agricultural crop rows along X for authentic farmland feel
		x = snappedf(x, 1.15) + rng.randf_range(-0.24, 0.24)
		z += rng.randf_range(-0.22, 0.22)

		if _is_in_clearing(x, z):
			continue

		var scale_y: float = rng.randf_range(0.82, 1.24)
		var scale_xz: float = rng.randf_range(0.88, 1.20)
		var rot_y: float = rng.randf_range(0.0, TAU)
		var tilt_x: float = rng.randf_range(-0.08, 0.08)
		var tilt_z: float = rng.randf_range(-0.08, 0.08)

		var basis := Basis.from_euler(Vector3(tilt_x, rot_y, tilt_z)).scaled(Vector3(scale_xz, scale_y, scale_xz))
		transforms.append(Transform3D(basis, Vector3(x, -0.04, z)))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _build_stalk_mesh()
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "CornMultiMesh"
	_multimesh_instance.multimesh = mm
	_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var shader_path: String = "res://assets/shaders/corn_wind.gdshader"
	if ResourceLoader.exists(shader_path):
		var smat := ShaderMaterial.new()
		smat.shader = load(shader_path)
		smat.set_shader_parameter("base_color", Vector3(0.42, 0.36, 0.19))
		smat.set_shader_parameter("tip_color", Vector3(0.66, 0.52, 0.27))
		smat.set_shader_parameter("wind_speed", 1.55)
		smat.set_shader_parameter("wind_strength", 0.26)
		_multimesh_instance.material_override = smat
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.54, 0.44, 0.23)
		fallback.roughness = 0.9
		fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
		_multimesh_instance.material_override = fallback

	add_child(_multimesh_instance)
