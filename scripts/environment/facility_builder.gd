@tool
class_name FacilityBuilder
extends Node3D

## Builds Horizon Outpost 09 (Research Facility & Launch Complex) and
## the single-occupant deep-space vessel Aethelgard IV.
## Also provides animated launch gantry clamps, ignition plume, and cinematic cameras.

signal player_entered_facility()
signal player_exited_facility()
signal launch_requested()

var anomaly_console: AnomalyConsole = null
var launch_terminal: LaunchTerminal = null

var _gyro_outer: Node3D = null
var _gyro_mid: Node3D = null
var _gyro_inner: Node3D = null
var _terminal_status_light: OmniLight3D = null
var _terminal_status_mesh: MeshInstance3D = null

var _ship_root: Node3D = null
var _clamp_arm_upper: Node3D = null
var _clamp_arm_lower: Node3D = null
var _plume_mesh: MeshInstance3D = null
var _engine_light: OmniLight3D = null
var _exhaust_particles: GPUParticles3D = null
var _cryo_particles: GPUParticles3D = null

var _cam_wide: Camera3D = null
var _cam_engine: Camera3D = null
var _cam_sky: Camera3D = null

var _anomaly_locked: bool = false
var _launching: bool = false
var _launch_time: float = 0.0
var _ship_base_pos: Vector3 = Vector3(0.0, 0.55, -22.0)


func _ready() -> void:
	_build_apron_and_bunker()
	_build_airlock_door()
	_build_interior_equipment()
	_build_launch_complex_and_ship()
	_build_launch_cameras()
	_build_interior_trigger()
	if not Engine.is_editor_hint():
		GameState.flag_changed.connect(_on_flag_changed)
	_sync_anomaly_visuals()


func _process(delta: float) -> void:
	var spin_mult: float = 2.6 if _anomaly_locked else 1.0
	if _gyro_outer != null:
		_gyro_outer.rotation.y += delta * 0.55 * spin_mult
		_gyro_outer.rotation.x += delta * 0.22 * spin_mult
	if _gyro_mid != null:
		_gyro_mid.rotation.z -= delta * 0.85 * spin_mult
	if _gyro_inner != null:
		_gyro_inner.rotation.x += delta * 1.25 * spin_mult

	if _launching and _ship_root != null:
		_launch_time += delta
		# Engine rumble vibration before liftoff (0..2.2s), then accelerating vertical climb
		if _launch_time < 2.2:
			var vib: float = (_launch_time / 2.2) * 0.08
			_ship_root.position = _ship_base_pos + Vector3(randf_range(-vib, vib), 0.0, randf_range(-vib, vib))
		else:
			var climb_t: float = _launch_time - 2.2
			var altitude: float = 0.55 + 2.4 * climb_t * climb_t + 0.35 * climb_t * climb_t * climb_t
			var vib: float = maxf(0.02, 0.12 - climb_t * 0.015)
			_ship_root.position = Vector3(
				_ship_base_pos.x + randf_range(-vib, vib),
				altitude,
				_ship_base_pos.z + randf_range(-vib, vib)
			)
		if _plume_mesh != null and _plume_mesh.visible:
			var flicker: float = randf_range(0.92, 1.18)
			_plume_mesh.scale = Vector3(flicker, randf_range(0.95, 1.35), flicker)
		if _engine_light != null and _engine_light.visible:
			_engine_light.light_energy = randf_range(16.0, 26.0)
		if _cam_sky != null and _cam_sky.current:
			_cam_sky.look_at(_ship_root.global_position + Vector3(0.0, 8.0, 0.0), Vector3.UP)


func get_anomaly_console_world_pos() -> Vector3:
	return to_global(Vector3(0.0, 1.5, 4.4))


func get_launch_terminal_world_pos() -> Vector3:
	return to_global(Vector3(0.0, 1.5, -2.5))


func get_airlock_world_pos() -> Vector3:
	return to_global(Vector3(0.0, 1.5, 12.2))


func _on_flag_changed(flag_name: String, _value: Variant) -> void:
	if flag_name == "anomaly_decoded":
		_sync_anomaly_visuals()


func _sync_anomaly_visuals() -> void:
	_anomaly_locked = false if Engine.is_editor_hint() else bool(GameState.get_flag("anomaly_decoded", false))
	if _terminal_status_light != null:
		_terminal_status_light.light_color = Color(0.28, 0.96, 0.88) if _anomaly_locked else Color(0.95, 0.30, 0.18)
	if _terminal_status_mesh != null:
		var mat := _terminal_status_mesh.material_override as StandardMaterial3D
		if mat != null:
			var c: Color = Color(0.28, 0.96, 0.88) if _anomaly_locked else Color(0.95, 0.30, 0.18)
			mat.albedo_color = c
			mat.emission = c


func activate_launch_camera(index: int) -> void:
	match index:
		0:
			if _cam_wide != null:
				_cam_wide.make_current()
		1:
			if _cam_engine != null:
				_cam_engine.make_current()
		2:
			if _cam_sky != null:
				_cam_sky.make_current()


func retract_gantry_clamps() -> void:
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if _clamp_arm_upper != null:
		tw.tween_property(_clamp_arm_upper, "rotation_degrees:z", 58.0, 2.2)
	if _clamp_arm_lower != null:
		tw.tween_property(_clamp_arm_lower, "rotation_degrees:z", 52.0, 2.0)


func ignite_and_launch() -> void:
	_launching = true
	_launch_time = 0.0
	if _plume_mesh != null:
		_plume_mesh.visible = true
	if _engine_light != null:
		_engine_light.visible = true
	if _exhaust_particles != null:
		_exhaust_particles.emitting = true
	if _cryo_particles != null:
		_cryo_particles.emitting = false


func _make_mat(col: Color, rough: float = 0.72, metal: float = 0.25, emit: Color = Color.BLACK, emit_str: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_str > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_str
	return m


func _add_solid_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, with_collision: bool = true) -> Node3D:
	var container: Node3D
	if with_collision:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		sb.add_child(col)
		container = sb
	else:
		container = Node3D.new()

	container.position = pos
	container.rotation_degrees = rot_deg

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	container.add_child(mi)

	parent.add_child(container)
	return container


func _build_apron_and_bunker() -> void:
	var concrete := _make_mat(Color(0.34, 0.35, 0.36), 0.90, 0.05)
	var hull_steel := _make_mat(Color(0.22, 0.25, 0.29), 0.56, 0.62)
	var deck_metal := _make_mat(Color(0.18, 0.21, 0.25), 0.48, 0.68)
	var trim_amber := _make_mat(Color(0.86, 0.54, 0.16), 0.45, 0.35)
	var cyan_strip := _make_mat(Color(0.28, 0.88, 0.96), 0.2, 0.0, Color(0.28, 0.88, 0.96), 3.0)

	# Concrete compound apron (slightly above terrain at y = 0.02)
	_add_solid_box(self, Vector3(44.0, 0.06, 52.0), Vector3(0.0, 0.01, -9.0), concrete, Vector3.ZERO, false)

	# Bunker Deck floor: x in [-11, 11], z in [-4, 12], top surface y = 0.30
	_add_solid_box(self, Vector3(22.0, 0.30, 16.0), Vector3(0.0, 0.15, 4.0), deck_metal)

	# Smooth entrance ramp at South airlock (z = 12.0 to 13.8)
	_add_solid_box(self, Vector3(4.2, 0.14, 1.9), Vector3(0.0, 0.12, 12.88), concrete, Vector3(10.0, 0.0, 0.0))

	var wall_h: float = 4.6
	var wall_y: float = 2.60
	var wall_t: float = 0.42

	# South Wall (z = 12.0) with Airlock doorway x in [-1.45, 1.45], height 2.8m
	_add_solid_box(self, Vector3(9.55, wall_h, wall_t), Vector3(-6.225, wall_y, 12.0), hull_steel)
	_add_solid_box(self, Vector3(9.55, wall_h, wall_t), Vector3(6.225, wall_y, 12.0), hull_steel)
	_add_solid_box(self, Vector3(2.9, 1.8, wall_t), Vector3(0.0, 4.0, 12.0), hull_steel)
	# Glowing Outpost 09 exterior accent strip above entrance
	_add_solid_box(self, Vector3(6.8, 0.18, 0.16), Vector3(0.0, 3.65, 12.28), cyan_strip, Vector3.ZERO, false)
	_add_solid_box(self, Vector3(12.0, 0.25, 0.22), Vector3(0.0, 4.65, 12.25), trim_amber, Vector3.ZERO, false)

	# West & East bunker walls
	_add_solid_box(self, Vector3(wall_t, wall_h, 16.4), Vector3(-11.0, wall_y, 4.0), hull_steel)
	_add_solid_box(self, Vector3(wall_t, wall_h, 16.4), Vector3(11.0, wall_y, 4.0), hull_steel)

	# North Observation Wall (z = -4.0) with Panoramic Reinforced Viewport (x in [-7.5, 7.5], y = 1.35..4.15)
	_add_solid_box(self, Vector3(3.5, wall_h, wall_t), Vector3(-9.25, wall_y, -4.0), hull_steel)
	_add_solid_box(self, Vector3(3.5, wall_h, wall_t), Vector3(9.25, wall_y, -4.0), hull_steel)
	_add_solid_box(self, Vector3(15.0, 1.05, wall_t), Vector3(0.0, 0.825, -4.0), hull_steel)
	_add_solid_box(self, Vector3(15.0, 0.75, wall_t), Vector3(0.0, 4.525, -4.0), hull_steel)

	# Translucent glass pane (with solid collider so player doesn't walk through viewport)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.55, 0.80, 0.92, 0.14)
	glass_mat.roughness = 0.08
	glass_mat.metallic = 0.2
	_add_solid_box(self, Vector3(15.0, 2.8, 0.08), Vector3(0.0, 2.75, -4.0), glass_mat)

	# Ceiling slab + industrial roof ribs
	_add_solid_box(self, Vector3(22.6, 0.35, 16.6), Vector3(0.0, 5.05, 4.0), hull_steel)

	# Exterior communications mast rising from the bunker roof so Outpost 09 is visible from the cornfield!
	_add_solid_box(self, Vector3(0.45, 14.0, 0.45), Vector3(8.5, 12.0, 9.5), hull_steel, Vector3.ZERO, false)
	var spire_beacon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.38
	sm.height = 0.76
	spire_beacon.mesh = sm
	spire_beacon.position = Vector3(8.5, 19.2, 9.5)
	spire_beacon.material_override = _make_mat(Color(1.0, 0.26, 0.14), 0.2, 0.0, Color(1.0, 0.26, 0.14), 6.0)
	add_child(spire_beacon)


func _build_airlock_door() -> void:
	var door_mat := _make_mat(Color(0.28, 0.33, 0.38), 0.42, 0.75)
	var stripe_mat := _make_mat(Color(0.92, 0.62, 0.18), 0.35, 0.4)

	var door_pivot := Node3D.new()
	door_pivot.name = "AirlockDoorPivot"
	door_pivot.position = Vector3(0.0, 0.30, 12.0)
	add_child(door_pivot)

	var leaf := _add_solid_box(door_pivot, Vector3(2.85, 2.78, 0.22), Vector3(0.0, 1.39, 0.0), door_mat)
	_add_solid_box(leaf, Vector3(2.4, 0.16, 0.26), Vector3(0.0, 0.25, 0.0), stripe_mat, Vector3.ZERO, false)

	var door_int := DoorInteractable.new()
	door_int.name = "AirlockDoorInteractable"
	door_int.door_style = DoorInteractable.DoorStyle.SLIDING
	door_int.door_label = "Outpost 09 Airlock"
	door_int.slide_offset = Vector3(2.75, 0.0, 0.0)
	door_int.open_duration = 0.95
	door_int.position = Vector3(0.0, 1.5, 12.0)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.5
	col.shape = sph
	door_int.add_child(col)
	add_child(door_int)
	door_int.setup_door_pivot(door_pivot)


func _build_interior_equipment() -> void:
	var console_mat := _make_mat(Color(0.18, 0.22, 0.27), 0.42, 0.65)
	var brass_mat := _make_mat(Color(0.84, 0.66, 0.32), 0.28, 0.88)
	var cyan_glow := _make_mat(Color(0.30, 0.88, 0.98), 0.2, 0.0, Color(0.28, 0.86, 0.98), 2.8)

	# Cool sci-fi interior lighting contrasting Earth's warm dusty exterior
	for lpos in [Vector3(-5.5, 4.3, 4.5), Vector3(5.5, 4.3, 4.5), Vector3(0.0, 4.2, -1.5)]:
		var light := OmniLight3D.new()
		light.position = lpos
		light.light_color = Color(0.76, 0.90, 1.0)
		light.light_energy = 2.3
		light.omni_range = 14.0
		add_child(light)

	# --- CENTRAL GRAVITATIONAL INTERFEROMETER TELEMETRY ARRAY (0, 0.3, 3.0) ---
	_add_solid_box(self, Vector3(4.2, 0.95, 2.2), Vector3(0.0, 0.775, 3.0), console_mat)

	# Holographic signal screen displaying our generated facility_signal_screen.png
	var screen := MeshInstance3D.new()
	var sqm := QuadMesh.new()
	sqm.size = Vector2(3.6, 1.8)
	screen.mesh = sqm
	screen.position = Vector3(0.0, 2.35, 2.35)
	var smat := StandardMaterial3D.new()
	smat.roughness = 0.25
	if ResourceLoader.exists("res://assets/textures/facility_signal_screen.png"):
		var tex := load("res://assets/textures/facility_signal_screen.png") as Texture2D
		smat.albedo_texture = tex
		smat.emission_enabled = true
		smat.emission_texture = tex
		smat.emission_energy_multiplier = 1.65
	else:
		smat.albedo_color = Color(0.2, 0.85, 0.95)
	screen.material_override = smat
	add_child(screen)

	# Floating spinning Gravitational Interferometer Gyroscope above console
	var gyro_anchor := Node3D.new()
	gyro_anchor.position = Vector3(0.0, 2.55, 3.35)
	add_child(gyro_anchor)

	_gyro_outer = _make_ring(gyro_anchor, 0.62, 0.035, brass_mat)
	_gyro_mid = _make_ring(_gyro_outer, 0.45, 0.03, cyan_glow)
	_gyro_inner = _make_ring(_gyro_mid, 0.28, 0.025, brass_mat)

	var core_orb := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.11
	cm.height = 0.22
	core_orb.mesh = cm
	core_orb.material_override = cyan_glow
	gyro_anchor.add_child(core_orb)

	# AnomalyConsole interactable
	anomaly_console = AnomalyConsole.new()
	anomaly_console.name = "AnomalyConsole"
	anomaly_console.position = Vector3(0.0, 1.35, 4.35)
	var acol := CollisionShape3D.new()
	var asph := SphereShape3D.new()
	asph.radius = 2.15
	acol.shape = asph
	anomaly_console.add_child(acol)
	add_child(anomaly_console)

	# --- LAUNCH CONTROL TERMINAL AT NORTH VIEWPORT (0, 0.3, -2.5) ---
	_add_solid_box(self, Vector3(2.4, 1.05, 0.95), Vector3(0.0, 0.825, -2.65), console_mat)
	_terminal_status_mesh = MeshInstance3D.new()
	var tbm := BoxMesh.new()
	tbm.size = Vector3(1.6, 0.18, 0.35)
	_terminal_status_mesh.mesh = tbm
	_terminal_status_mesh.position = Vector3(0.0, 1.42, -2.65)
	_terminal_status_mesh.material_override = _make_mat(Color(0.95, 0.30, 0.18), 0.2, 0.0, Color(0.95, 0.30, 0.18), 3.0)
	add_child(_terminal_status_mesh)

	_terminal_status_light = OmniLight3D.new()
	_terminal_status_light.position = Vector3(0.0, 1.9, -2.5)
	_terminal_status_light.light_energy = 1.8
	_terminal_status_light.omni_range = 5.5
	add_child(_terminal_status_light)

	launch_terminal = LaunchTerminal.new()
	launch_terminal.name = "LaunchTerminal"
	launch_terminal.position = Vector3(0.0, 1.35, -2.1)
	var lcol := CollisionShape3D.new()
	var lsph := SphereShape3D.new()
	lsph.radius = 2.15
	lcol.shape = lsph
	launch_terminal.add_child(lcol)
	add_child(launch_terminal)
	launch_terminal.launch_requested.connect(func() -> void: launch_requested.emit())

	# --- SIDE SERVER RACKS & FLIGHT MANIFEST MEMORY ---
	for sz in [1.0, 4.2, 7.4]:
		_add_solid_box(self, Vector3(1.1, 2.9, 1.8), Vector3(-9.4, 1.75, sz), console_mat)
		_add_solid_box(self, Vector3(1.1, 2.9, 1.8), Vector3(9.4, 1.75, sz), console_mat)

	# Flight manifest terminal on left side
	_add_solid_box(self, Vector3(1.1, 1.1, 1.5), Vector3(-6.8, 0.85, 6.2), console_mat)
	_add_solid_box(self, Vector3(0.08, 0.55, 0.9), Vector3(-6.22, 1.55, 6.2), cyan_glow, Vector3.ZERO, false)
	var manifest := MemoryItem.new()
	manifest.name = "Memory_outpost_manifest"
	manifest.memory_id = "outpost_manifest"
	manifest.prompt_text = "Read Outpost 09 Flight Manifest"
	manifest.position = Vector3(-6.1, 1.35, 6.2)
	var mcol := CollisionShape3D.new()
	var msph := SphereShape3D.new()
	msph.radius = 1.95
	mcol.shape = msph
	manifest.add_child(mcol)
	add_child(manifest)


func _make_ring(parent: Node3D, radius: float, tube: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.05, radius - tube)
	torus.outer_radius = radius
	mi.mesh = torus
	mi.material_override = mat
	pivot.add_child(mi)
	return pivot


func _build_launch_complex_and_ship() -> void:
	var pad_mat := _make_mat(Color(0.24, 0.25, 0.27), 0.88, 0.15)
	var steel_red := _make_mat(Color(0.46, 0.21, 0.16), 0.62, 0.58)
	var ceramic_white := _make_mat(Color(0.84, 0.83, 0.80), 0.36, 0.14)
	var heatshield_dark := _make_mat(Color(0.14, 0.15, 0.18), 0.55, 0.45)
	var canopy_gold := _make_mat(Color(0.95, 0.72, 0.30), 0.18, 0.75, Color(0.95, 0.68, 0.25), 0.85)
	var engine_metal := _make_mat(Color(0.28, 0.30, 0.34), 0.35, 0.85)

	# Concrete launch pad base at (0, 0, -22)
	_add_solid_box(self, Vector3(18.0, 0.55, 18.0), Vector3(0.0, 0.275, -22.0), pad_mat)

	# Launch Gantry Tower at (-6.0, 0.55, -22.0)
	var gantry := Node3D.new()
	gantry.name = "LaunchGantry"
	gantry.position = Vector3(-6.0, 0.55, -22.0)
	add_child(gantry)

	for gx in [-1.0, 1.0]:
		for gz in [-1.0, 1.0]:
			_add_solid_box(gantry, Vector3(0.32, 22.0, 0.32), Vector3(gx, 11.0, gz), steel_red, Vector3.ZERO, false)
	for gy in [4.0, 8.5, 13.0, 17.5, 21.5]:
		_add_solid_box(gantry, Vector3(2.3, 0.25, 2.3), Vector3(0.0, gy, 0.0), steel_red, Vector3.ZERO, false)

	# Retractable umbilical clamp arms
	_clamp_arm_upper = Node3D.new()
	_clamp_arm_upper.position = Vector3(1.1, 15.0, 0.0)
	gantry.add_child(_clamp_arm_upper)
	_add_solid_box(_clamp_arm_upper, Vector3(4.2, 0.45, 0.65), Vector3(2.1, 0.0, 0.0), steel_red, Vector3.ZERO, false)

	_clamp_arm_lower = Node3D.new()
	_clamp_arm_lower.position = Vector3(1.1, 8.5, 0.0)
	gantry.add_child(_clamp_arm_lower)
	_add_solid_box(_clamp_arm_lower, Vector3(3.8, 0.45, 0.65), Vector3(1.9, 0.0, 0.0), steel_red, Vector3.ZERO, false)

	# Four pad floodlights illuminating Aethelgard IV dramatically
	for fx in [-10.0, 10.0]:
		for fz in [-12.0, -32.0]:
			_add_solid_box(self, Vector3(0.3, 9.0, 0.3), Vector3(fx, 4.5, fz), pad_mat, Vector3.ZERO, false)
			var fl := OmniLight3D.new()
			fl.position = Vector3(fx * 0.82, 9.5, fz + (2.5 if fz < -22.0 else -2.5))
			fl.light_color = Color(1.0, 0.88, 0.70)
			fl.light_energy = 4.2
			fl.omni_range = 30.0
			add_child(fl)

	# --- SPACECRAFT: AETHELGARD IV ---
	_ship_root = Node3D.new()
	_ship_root.name = "AethelgardIV"
	_ship_root.position = _ship_base_pos
	add_child(_ship_root)

	# Main core stage fuselage
	var core := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.65
	cm.bottom_radius = 2.05
	cm.height = 13.5
	core.mesh = cm
	core.position = Vector3(0.0, 8.2, 0.0)
	core.material_override = ceramic_white
	_ship_root.add_child(core)

	# Forward tapered crew module / nose fairing
	var nose := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.25
	nm.bottom_radius = 1.65
	nm.height = 6.2
	nose.mesh = nm
	nose.position = Vector3(0.0, 18.0, 0.0)
	nose.material_override = ceramic_white
	_ship_root.add_child(nose)

	# Dark thermal heat-shield dorsal stripe & forward cockpit window
	_add_solid_box(_ship_root, Vector3(1.4, 12.0, 0.45), Vector3(0.0, 8.4, 1.82), heatshield_dark, Vector3.ZERO, false)
	_add_solid_box(_ship_root, Vector3(1.15, 0.85, 0.45), Vector3(0.0, 15.8, 1.48), canopy_gold, Vector3(-16.0, 0.0, 0.0), false)

	# Three radial aerodynamic fins & landing legs
	for i in range(3):
		var ang: float = float(i) * (TAU / 3.0)
		var fin_pivot := Node3D.new()
		fin_pivot.rotation.y = ang
		_ship_root.add_child(fin_pivot)
		_add_solid_box(fin_pivot, Vector3(0.28, 6.2, 2.2), Vector3(0.0, 4.4, 2.35), heatshield_dark, Vector3(-14.0, 0.0, 0.0), false)
		# Engine bell cluster
		var bell := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.48
		bm.bottom_radius = 0.82
		bm.height = 1.45
		bell.mesh = bm
		bell.position = Vector3(0.0, 0.72, 1.02)
		bell.material_override = engine_metal
		fin_pivot.add_child(bell)

	# Venting pre-launch cryo-vapor particles
	_cryo_particles = GPUParticles3D.new()
	_cryo_particles.position = Vector3(0.0, 1.2, 0.0)
	_cryo_particles.amount = 90
	_cryo_particles.lifetime = 3.2
	var cpm := ParticleProcessMaterial.new()
	cpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	cpm.emission_ring_radius = 2.4
	cpm.emission_ring_height = 0.4
	cpm.direction = Vector3(1.0, 0.15, 0.2)
	cpm.spread = 45.0
	cpm.initial_velocity_min = 1.2
	cpm.initial_velocity_max = 3.2
	cpm.gravity = Vector3(0.0, 0.4, 0.0)
	cpm.scale_min = 0.5
	cpm.scale_max = 1.6
	cpm.color = Color(0.88, 0.93, 0.98, 0.25)
	_cryo_particles.process_material = cpm
	var cquad := QuadMesh.new()
	cquad.size = Vector2(1.4, 1.4)
	var cqmat := StandardMaterial3D.new()
	cqmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cqmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cqmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	cqmat.albedo_color = Color(0.88, 0.92, 0.98, 0.22)
	if ResourceLoader.exists("res://assets/textures/dust_particle.png"):
		cqmat.albedo_texture = load("res://assets/textures/dust_particle.png")
	cquad.material = cqmat
	_cryo_particles.draw_pass_1 = cquad
	_ship_root.add_child(_cryo_particles)

	# Engine ignition plasma flame cone (hidden until ignition)
	_plume_mesh = MeshInstance3D.new()
	var plm := CylinderMesh.new()
	plm.top_radius = 1.75
	plm.bottom_radius = 0.15
	plm.height = 14.0
	_plume_mesh.mesh = plm
	_plume_mesh.position = Vector3(0.0, -7.0, 0.0)
	_plume_mesh.material_override = _make_mat(Color(1.0, 0.78, 0.35), 0.1, 0.0, Color(1.0, 0.68, 0.24), 8.5)
	_plume_mesh.visible = false
	_ship_root.add_child(_plume_mesh)

	_engine_light = OmniLight3D.new()
	_engine_light.position = Vector3(0.0, -2.2, 0.0)
	_engine_light.light_color = Color(1.0, 0.72, 0.34)
	_engine_light.light_energy = 20.0
	_engine_light.omni_range = 65.0
	_engine_light.visible = false
	_ship_root.add_child(_engine_light)

	# Roaring launch exhaust plume particles
	_exhaust_particles = GPUParticles3D.new()
	_exhaust_particles.position = Vector3(0.0, -0.5, 0.0)
	_exhaust_particles.amount = 260
	_exhaust_particles.lifetime = 2.4
	_exhaust_particles.emitting = false
	_exhaust_particles.visibility_aabb = AABB(Vector3(-35, -80, -35), Vector3(70, 120, 70))
	var epm := ParticleProcessMaterial.new()
	epm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	epm.emission_sphere_radius = 1.6
	epm.direction = Vector3(0.0, -1.0, 0.0)
	epm.spread = 28.0
	epm.initial_velocity_min = 14.0
	epm.initial_velocity_max = 26.0
	epm.gravity = Vector3(2.0, -1.5, 0.0)
	epm.scale_min = 1.4
	epm.scale_max = 4.2
	epm.color = Color(1.0, 0.66, 0.30, 0.62)
	_exhaust_particles.process_material = epm
	var equad := QuadMesh.new()
	equad.size = Vector2(2.2, 2.2)
	var eqmat := StandardMaterial3D.new()
	eqmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eqmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eqmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	eqmat.albedo_color = Color(1.0, 0.76, 0.45, 0.55)
	if ResourceLoader.exists("res://assets/textures/dust_particle.png"):
		eqmat.albedo_texture = load("res://assets/textures/dust_particle.png")
	equad.material = eqmat
	_exhaust_particles.draw_pass_1 = equad
	_ship_root.add_child(_exhaust_particles)


func _build_launch_cameras() -> void:
	# Shot 1: Dramatic low-angle wide hero shot of Aethelgard IV and gantry
	_cam_wide = Camera3D.new()
	_cam_wide.name = "LaunchCamWide"
	_cam_wide.fov = 52.0
	_cam_wide.position = Vector3(16.5, 4.2, -7.5)
	add_child(_cam_wide)
	_cam_wide.look_at(to_global(Vector3(0.0, 11.5, -22.0)), Vector3.UP)

	# Shot 2: Close pad-level engine ignition shot
	_cam_engine = Camera3D.new()
	_cam_engine.name = "LaunchCamEngine"
	_cam_engine.fov = 58.0
	_cam_engine.position = Vector3(-9.5, 2.2, -13.0)
	add_child(_cam_engine)
	_cam_engine.look_at(to_global(Vector3(0.0, 4.5, -22.0)), Vector3.UP)

	# Shot 3: Tracking sky shot watching Aethelgard IV punch into the dusty clouds
	_cam_sky = Camera3D.new()
	_cam_sky.name = "LaunchCamSky"
	_cam_sky.fov = 50.0
	_cam_sky.position = Vector3(24.0, 5.5, 6.0)
	add_child(_cam_sky)
	_cam_sky.look_at(to_global(Vector3(0.0, 14.0, -22.0)), Vector3.UP)


func _build_interior_trigger() -> void:
	var area := Area3D.new()
	area.name = "FacilityInteriorTrigger"
	area.collision_layer = 0
	area.collision_mask = 2 # Player
	area.position = Vector3(0.0, 2.2, 4.0)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(21.2, 4.2, 15.2)
	col.shape = box
	area.add_child(col)
	add_child(area)

	area.body_entered.connect(func(body: Node3D) -> void:
		if body is PlayerController:
			(body as PlayerController).is_on_metal_surface = true
			player_entered_facility.emit()
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body is PlayerController:
			(body as PlayerController).is_on_metal_surface = false
			player_exited_facility.emit()
	)
