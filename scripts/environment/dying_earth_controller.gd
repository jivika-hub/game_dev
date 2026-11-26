@tool
class_name DyingEarthController
extends Node3D

## Controls the dying Earth 2089 atmosphere:
## - Swirling dust particle cloud following the active camera/player
## - Weathered dirt road, fence posts, spinning farmhouse wind turbine
## - Flashing northern perimeter beacons guiding the player to Horizon Outpost 09
## - Interactive Soil Core #14 field memory along the cornfield path

@onready var sun_light: DirectionalLight3D = $SunLight
@onready var world_env: WorldEnvironment = $WorldEnvironment

var _turbine_blades: Node3D = null
var _dust_particles: GPUParticles3D = null
var _beacon_lights: Array[OmniLight3D] = []
var _beacon_meshes: Array[MeshInstance3D] = []
var _time_acc: float = 0.0


func _ready() -> void:
	_build_dirt_roads_and_fences()
	_build_wind_turbine()
	_build_northern_beacons()
	_build_soil_sensor()
	_build_dust_particles()


func _process(delta: float) -> void:
	_time_acc += delta

	# Rotate rusty wind turbine in gusts
	if _turbine_blades != null:
		var gust: float = 0.85 + 0.45 * sin(_time_acc * 0.65)
		_turbine_blades.rotation.z -= delta * 1.45 * gust

	# Pulse perimeter beacons in sequence toward Horizon Outpost 09
	for i in range(_beacon_lights.size()):
		var phase: float = sin(_time_acc * 3.1 - float(i) * 0.7)
		var lit: float = 1.0 if phase > 0.25 else 0.12
		_beacon_lights[i].light_energy = 2.4 * lit
		var mat := _beacon_meshes[i].material_override as StandardMaterial3D
		if mat != null:
			mat.emission_energy_multiplier = 4.2 * lit

	# Subtle volumetric dust-haze breathing (runtime only so editor scene stays clean)
	if not Engine.is_editor_hint():
		if world_env != null and world_env.environment != null:
			world_env.environment.volumetric_fog_density = 0.014 + 0.004 * sin(_time_acc * 0.32)

		# Keep dust particle emitter centered around the current camera so dust fills every shot
		if _dust_particles != null:
			var cam := get_viewport().get_camera_3d()
			if cam != null:
				_dust_particles.global_position = Vector3(cam.global_position.x, maxf(cam.global_position.y + 1.5, 3.0), cam.global_position.z)


func _make_mat(col: Color, rough: float = 0.9, metal: float = 0.0, emit: Color = Color.BLACK, emit_str: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_str > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_str
	return m


func _build_dirt_roads_and_fences() -> void:
	var road_mat := _make_mat(Color(0.35, 0.26, 0.17), 0.98)
	var wood_mat := _make_mat(Color(0.28, 0.21, 0.15), 0.94)

	# Main compacted dirt road strip slightly above terrain (y = 0.015)
	var road := MeshInstance3D.new()
	road.name = "DirtRoadMain"
	var rmesh := PlaneMesh.new()
	rmesh.size = Vector2(5.2, 118.0)
	road.mesh = rmesh
	road.position = Vector3(0.0, 0.018, 6.0)
	road.material_override = road_mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)

	# Weathered wooden fence posts bordering the southern approach & yard
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.14, 1.25, 0.14)
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.06, 0.09, 5.8)

	for side in [-1.0, 1.0]:
		var x_pos: float = side * 3.45
		for z_step in range(14, 56, 6):
			var post := MeshInstance3D.new()
			post.mesh = post_mesh
			post.position = Vector3(x_pos, 0.60, float(z_step))
			post.rotation.z = side * 0.04 * sin(float(z_step))
			post.material_override = wood_mat
			add_child(post)

			if z_step < 50:
				var rail := MeshInstance3D.new()
				rail.mesh = rail_mesh
				rail.position = Vector3(x_pos, 0.92, float(z_step) + 3.0)
				rail.material_override = wood_mat
				add_child(rail)

	# Distant dry earth ridges on the horizon for silhouettes
	var ridge_mat := _make_mat(Color(0.32, 0.23, 0.15), 0.98)
	var ridge_positions: Array = [
		[Vector3(-90.0, 4.0, -110.0), Vector3(80.0, 11.0, 26.0)],
		[Vector3(95.0, 5.0, -105.0), Vector3(90.0, 14.0, 28.0)],
		[Vector3(-105.0, 3.5, 25.0), Vector3(24.0, 9.0, 110.0)],
		[Vector3(108.0, 4.0, 20.0), Vector3(24.0, 10.0, 120.0)]
	]
	for cfg in ridge_positions:
		var ridge := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = cfg[1]
		ridge.mesh = bm
		ridge.position = cfg[0]
		ridge.material_override = ridge_mat
		add_child(ridge)


func _build_wind_turbine() -> void:
	# Iconic weathered farm windmill beside the farmhouse at (-10.5, 0, -3.5)
	var root := Node3D.new()
	root.name = "FarmWindTurbine"
	root.position = Vector3(-10.5, 0.0, -3.5)
	root.rotation_degrees = Vector3(0.0, 28.0, 0.0)
	add_child(root)

	var rust_mat := _make_mat(Color(0.34, 0.22, 0.16), 0.82, 0.42)
	var blade_mat := _make_mat(Color(0.52, 0.45, 0.36), 0.72, 0.25)

	var mast := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.14
	cm.bottom_radius = 0.42
	cm.height = 11.5
	mast.mesh = cm
	mast.position = Vector3(0.0, 5.75, 0.0)
	mast.material_override = rust_mat
	root.add_child(mast)

	var hub := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.28
	hm.bottom_radius = 0.28
	hm.height = 0.9
	hub.mesh = hm
	hub.position = Vector3(0.0, 11.4, 0.25)
	hub.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	hub.material_override = rust_mat
	root.add_child(hub)

	_turbine_blades = Node3D.new()
	_turbine_blades.name = "TurbineBlades"
	_turbine_blades.position = Vector3(0.0, 11.4, 0.72)
	root.add_child(_turbine_blades)

	for i in range(6):
		var blade_pivot := Node3D.new()
		blade_pivot.rotation.z = float(i) * (TAU / 6.0)
		_turbine_blades.add_child(blade_pivot)

		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.38, 2.35, 0.05)
		blade.mesh = bm
		blade.position = Vector3(0.0, 1.35, 0.0)
		blade.rotation_degrees = Vector3(0.0, 16.0, 0.0)
		blade.material_override = blade_mat
		blade_pivot.add_child(blade)


func _build_northern_beacons() -> void:
	var pole_mat := _make_mat(Color(0.24, 0.26, 0.29), 0.55, 0.65)
	var z_coords: Array[float] = [-16.0, -25.0, -34.0, -43.0]

	for idx in range(z_coords.size()):
		for side in [-1.0, 1.0]:
			var beacon_root := Node3D.new()
			beacon_root.position = Vector3(side * 3.8, 0.0, z_coords[idx])
			add_child(beacon_root)

			var pole := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.06
			pm.bottom_radius = 0.09
			pm.height = 2.6
			pole.mesh = pm
			pole.position = Vector3(0.0, 1.3, 0.0)
			pole.material_override = pole_mat
			beacon_root.add_child(pole)

			var lamp := MeshInstance3D.new()
			var lm := SphereMesh.new()
			lm.radius = 0.14
			lm.height = 0.28
			lamp.mesh = lm
			lamp.position = Vector3(0.0, 2.68, 0.0)
			lamp.material_override = _make_mat(Color(1.0, 0.32, 0.18), 0.2, 0.0, Color(1.0, 0.30, 0.15), 4.0)
			beacon_root.add_child(lamp)
			_beacon_meshes.append(lamp)

			var light := OmniLight3D.new()
			light.position = Vector3(0.0, 2.75, 0.0)
			light.light_color = Color(1.0, 0.36, 0.18)
			light.light_energy = 2.0
			light.omni_range = 7.5
			beacon_root.add_child(light)
			_beacon_lights.append(light)


func _build_soil_sensor() -> void:
	# Field Soil Core #14 along the cornfield path at (2.4, 0, 25.0)
	var root := Node3D.new()
	root.name = "SoilSensor14"
	root.position = Vector3(2.4, 0.0, 25.0)
	add_child(root)

	var metal_mat := _make_mat(Color(0.32, 0.35, 0.38), 0.52, 0.65)
	var amber_mat := _make_mat(Color(0.95, 0.65, 0.22), 0.2, 0.0, Color(0.98, 0.68, 0.22), 2.5)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(0.45, 1.3, 0.45)
	col.shape = cbox
	col.position = Vector3(0.0, 0.65, 0.0)
	body.add_child(col)
	root.add_child(body)

	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.09
	pm.height = 1.25
	post.mesh = pm
	post.position = Vector3(0.0, 0.625, 0.0)
	post.material_override = metal_mat
	root.add_child(post)

	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.38, 0.32, 0.28)
	box.mesh = bm
	box.position = Vector3(0.0, 1.15, 0.0)
	box.material_override = metal_mat
	root.add_child(box)

	var led := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.24, 0.12, 0.03)
	led.mesh = lm
	led.position = Vector3(0.0, 1.18, 0.15)
	led.material_override = amber_mat
	root.add_child(led)

	var mem := MemoryItem.new()
	mem.name = "SoilSensorInteractable"
	mem.memory_id = "soil_sensor_log"
	mem.prompt_text = "Inspect Field Soil Core #14"
	mem.position = Vector3(0.0, 1.0, 0.0)
	var mcol := CollisionShape3D.new()
	var msph := SphereShape3D.new()
	msph.radius = 1.9
	mcol.shape = msph
	mem.add_child(mcol)
	root.add_child(mem)


func _build_dust_particles() -> void:
	_dust_particles = GPUParticles3D.new()
	_dust_particles.name = "AtmosphericDust"
	_dust_particles.amount = 360
	_dust_particles.lifetime = 5.5
	_dust_particles.preprocess = 3.0
	_dust_particles.visibility_aabb = AABB(Vector3(-45, -15, -45), Vector3(90, 35, 90))

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(24.0, 7.0, 24.0)
	pmat.direction = Vector3(1.0, -0.08, 0.25)
	pmat.spread = 22.0
	pmat.initial_velocity_min = 2.4
	pmat.initial_velocity_max = 5.4
	pmat.gravity = Vector3(0.2, -0.05, 0.0)
	pmat.scale_min = 0.06
	pmat.scale_max = 0.20
	pmat.color = Color(0.86, 0.68, 0.46, 0.36)
	_dust_particles.process_material = pmat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.45)
	var dmat := StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dmat.albedo_color = Color(0.92, 0.76, 0.54, 0.42)
	if ResourceLoader.exists("res://assets/textures/dust_particle.png"):
		dmat.albedo_texture = load("res://assets/textures/dust_particle.png")
	quad.material = dmat
	_dust_particles.draw_pass_1 = quad

	add_child(_dust_particles)
