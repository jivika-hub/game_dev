@tool
class_name ParadoxMarketSequence
extends Node3D

## Orchestrates Acts 8 & 9 of Chapter I:
## - Orbital flight of Aethelgard IV toward the gravitational fold
## - First encounter with the abstract, formless Cosmic Entity ('The Threshold')
## - Philosophical dialogue with player choices
## - Unfurling of the Interdimensional Rift & flying into THE PARADOX MARKET
## - Chapter I completion summary & persistent completion save.

@onready var main_camera: Camera3D = $SequenceCamera
@onready var hud: HUDController = $HUD
@onready var dialogue_ui: DialogueUI = $DialogueBox
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var finale_layer: CanvasLayer = $FinaleOverlay
@onready var finale_summary: Label = $FinaleOverlay/Bg/Center/Card/Margin/VBox/SummaryLabel
@onready var menu_btn: Button = $FinaleOverlay/Bg/Center/Card/Margin/VBox/BtnRow/MenuBtn
@onready var replay_btn: Button = $FinaleOverlay/Bg/Center/Card/Margin/VBox/BtnRow/ReplayBtn

var _ship_root: Node3D = null
var _entity_root: Node3D = null
var _entity_core: MeshInstance3D = null
var _entity_rings: Array[Node3D] = []
var _entity_shards: Array[Node3D] = []
var _portal_mesh: MeshInstance3D = null
var _portal_mat: ShaderMaterial = null
var _market_root: Node3D = null

var _time_acc: float = 0.0
var _phase: int = 0 # 0: approach, 1: entity dialogue, 2: rift opening, 3: entering market, 4: ended
var _phase_t: float = 0.0
var _rift_openness: float = 0.0


func _ready() -> void:
	_build_starfield()
	_build_orbital_ship()
	_build_cosmic_entity()
	_build_interdimensional_rift()
	_build_paradox_market_vista()

	if Engine.is_editor_hint():
		if _market_root != null:
			_market_root.visible = true
		return

	GameState.current_scene_path = "res://scenes/environment/ParadoxMarketArrival.tscn"
	GameState.pending_load_from_save = false
	finale_layer.visible = false

	menu_btn.pressed.connect(_on_return_menu)
	replay_btn.pressed.connect(_on_replay)

	main_camera.make_current()
	_run_sequence()


func _process(delta: float) -> void:
	_time_acc += delta
	_phase_t += delta

	# Animate formless Cosmic Entity: counter-rotating rings & breathing chaotic shard cloud
	if _entity_core != null:
		_entity_core.rotation.y += delta * 0.25
		_entity_core.rotation.x += delta * 0.14
		var pulse: float = 1.0 + 0.08 * sin(_time_acc * 1.4)
		_entity_core.scale = Vector3.ONE * pulse

	for i in range(_entity_rings.size()):
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		_entity_rings[i].rotation.x += delta * (0.28 + 0.12 * i) * dir
		_entity_rings[i].rotation.y += delta * (0.42 - 0.08 * i) * -dir

	for i in range(_entity_shards.size()):
		var shard: Node3D = _entity_shards[i]
		var ang: float = _time_acc * (0.22 + float(i % 5) * 0.07) + float(i) * 0.45
		var rad: float = 7.5 + float(i % 4) * 2.4 + sin(_time_acc * 0.9 + float(i)) * 1.1
		if _phase >= 2:
			rad += _rift_openness * 10.0 # Entity parts outward as the Paradox Market rift opens!
		var elev: float = sin(ang * 1.3 + float(i)) * 5.2
		shard.position = Vector3(cos(ang) * rad, elev, sin(ang) * rad)
		shard.rotation += Vector3(delta * 0.6, delta * 0.9, delta * 0.4)

	# Gentle drift of the floating Paradox Market spires
	if _market_root != null:
		_market_root.rotation.z = sin(_time_acc * 0.18) * 0.03

	# Update ship & camera choreography per phase (runtime only)
	if Engine.is_editor_hint():
		return
	match _phase:
		0: # Approach cosmic anomaly
			var t: float = clampf(_phase_t / 5.5, 0.0, 1.0)
			var ease_t: float = t * t * (3.0 - 2.0 * t)
			_ship_root.position = Vector3(0.0, -1.5, 36.0).lerp(Vector3(0.0, -1.0, 18.0), ease_t)
			main_camera.global_position = Vector3(11.0, 3.5, 44.0).lerp(Vector3(8.5, 2.2, 27.5), ease_t)
			main_camera.look_at(Vector3(0.0, 0.5, -14.0), Vector3.UP)
		1: # Orbit gently during Entity encounter dialogue
			_ship_root.position = Vector3(0.0, -1.0 + sin(_time_acc * 0.7) * 0.25, 18.0)
			var cam_x: float = 8.5 + sin(_time_acc * 0.25) * 3.5
			var cam_y: float = 2.2 + cos(_time_acc * 0.2) * 1.2
			main_camera.global_position = Vector3(cam_x, cam_y, 27.5)
			main_camera.look_at(Vector3(0.0, 0.5, -14.0), Vector3.UP)
		2: # Rift expands, revealing the Paradox Market beyond
			_rift_openness = clampf(_phase_t / 4.2, 0.0, 1.0)
			if _portal_mat != null:
				_portal_mat.set_shader_parameter("openness", _rift_openness)
			if _portal_mesh != null:
				var s: float = lerpf(0.05, 1.0, _rift_openness)
				_portal_mesh.scale = Vector3(s, s, 1.0)
			if _entity_core != null:
				_entity_core.scale = Vector3.ONE * maxf(0.05, 1.0 - _rift_openness * 0.85)
			if _market_root != null:
				_market_root.visible = _rift_openness > 0.15
			main_camera.global_position = main_camera.global_position.lerp(Vector3(4.5, 1.8, 25.0), clampf(delta * 1.4, 0.0, 1.0))
			main_camera.look_at(Vector3(0.0, 1.0, -45.0), Vector3.UP)
		3: # Aethelgard IV flies across the threshold into the Paradox Market!
			var t: float = clampf(_phase_t / 7.5, 0.0, 1.0)
			var ease_t: float = t * t * (3.0 - 2.0 * t)
			_ship_root.position = Vector3(0.0, -1.0, 18.0).lerp(Vector3(0.0, 0.5, -62.0), ease_t)
			var cam_pos := Vector3(4.5, 1.8, 25.0).lerp(Vector3(6.0, 5.5, -48.0), ease_t)
			main_camera.global_position = cam_pos
			main_camera.look_at(_ship_root.global_position + Vector3(0.0, 1.5, -24.0), Vector3.UP)


func _run_sequence() -> void:
	GameState.chapter_stage = "cosmic_entity"
	GameState.set_mode(GameState.Mode.CINEMATIC)
	MissionManager.start_mission("orbital_crossing")

	AudioManager.play_music("cosmic_entity", -7.0, 2.5)
	hud.fade_from_black(2.2)
	hud.show_title_card("NODE 09-K", "0.4 AU BEYOND SATURN — GRAVITATIONAL ANOMALY", 3.4)

	# Phase 0: Approach
	_phase = 0
	_phase_t = 0.0
	await get_tree().create_timer(5.6).timeout
	if not is_inside_tree():
		return

	# Phase 1: Dialogue with the abstract, formless Cosmic Entity
	_phase = 1
	_phase_t = 0.0
	DialogueManager.start_dialogue("cosmic_entity_encounter", GameState.Mode.CINEMATIC)
	await DialogueManager.dialogue_finished
	if not is_inside_tree():
		return

	# Phase 2: Opening the Interdimensional Paradox Market Rift
	_phase = 2
	_phase_t = 0.0
	MissionManager.start_mission("enter_market")
	AudioManager.play_sfx("puzzle_lock", -3.0, 0.72)
	AudioManager.play_music("market_ambient", -6.5, 2.8)
	await get_tree().create_timer(4.4).timeout
	if not is_inside_tree():
		return

	# Phase 3: Cross threshold into the Paradox Market
	_phase = 3
	_phase_t = 0.0
	GameState.chapter_stage = "paradox_market_arrival"
	GameState.set_flag("chapter1_completed", true)
	GameState.save_progress(null)
	hud.show_title_card("THE PARADOX MARKET", "WHERE WORLDS ARE WEIGHED AND TOMORROWS ARE TRADED", 4.2)

	await get_tree().create_timer(7.6).timeout
	if not is_inside_tree():
		return

	# Phase 4: Finale screen
	_phase = 4
	_show_finale_overlay()


func _show_finale_overlay() -> void:
	GameState.set_mode(GameState.Mode.ENDED)
	var mem_count: int = GameState.discovered_memories.size()
	var maya_note: String = "You told Maya the honest math of the unknown." if bool(GameState.get_flag("maya_response_honest", false)) else "You promised Maya you would return with a blue sky."
	var entity_note: String = "You offered your own remaining years to buy humanity a dawn." if bool(GameState.get_flag("entity_stance_sacrifice", false)) else "You staked humanity's memory and science as currency."

	finale_summary.text = (
		"Dr. Elias Vance has crossed the fold into the Paradox Market.\n\n"
		+ "• %s\n" % maya_note
		+ "• %s\n" % entity_note
		+ "• Memories Discovered: %d / 6\n" % mem_count
		+ "• Chapter I Playtime: %s\n\n" % GameState.format_elapsed_time()
		+ "Thank you for playing THE PARADOX MARKET — Chapter I Prototype."
	)
	finale_layer.visible = true


func _on_return_menu() -> void:
	AudioManager.play_sfx("interact_click", -8.0)
	AudioManager.stop_music(0.8)
	GameState.set_mode(GameState.Mode.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")


func _on_replay() -> void:
	AudioManager.play_sfx("ui_chime", -6.0)
	AudioManager.stop_music(0.8)
	GameState.reset_new_game()
	get_tree().change_scene_to_file("res://scenes/main/Chapter1World.tscn")


func _make_mat(col: Color, rough: float = 0.5, metal: float = 0.3, emit: Color = Color.BLACK, emit_str: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_str > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_str
	return m


func _build_starfield() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4096
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	mm.mesh = sm
	mm.instance_count = 1400

	for i in range(1400):
		var dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var dist: float = rng.randf_range(120.0, 290.0)
		var sc: float = rng.randf_range(0.45, 2.2)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * sc), dir * dist))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _make_mat(Color.WHITE, 0.2, 0.0, Color(0.92, 0.94, 1.0), 2.5)
	add_child(mmi)


func _build_orbital_ship() -> void:
	_ship_root = Node3D.new()
	_ship_root.name = "AethelgardOrbital"
	_ship_root.position = Vector3(0.0, -1.5, 36.0)
	add_child(_ship_root)

	var ceramic := _make_mat(Color(0.86, 0.85, 0.82), 0.34, 0.22)
	var dark := _make_mat(Color(0.14, 0.16, 0.20), 0.5, 0.5)
	var canopy := _make_mat(Color(0.96, 0.76, 0.34), 0.2, 0.6, Color(0.96, 0.72, 0.30), 1.6)
	var ion := _make_mat(Color(0.35, 0.86, 1.0), 0.1, 0.0, Color(0.35, 0.88, 1.0), 6.0)

	# Horizontal orientation pointing toward -Z (the Cosmic Entity & Paradox Market)
	var hull := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.72
	hm.bottom_radius = 1.05
	hm.height = 6.2
	hull.mesh = hm
	hull.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	hull.material_override = ceramic
	_ship_root.add_child(hull)

	var nose := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.12
	nm.bottom_radius = 0.72
	nm.height = 2.8
	nose.mesh = nm
	nose.position = Vector3(0.0, 0.0, -4.5)
	nose.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	nose.material_override = ceramic
	_ship_root.add_child(nose)

	var cockpit := MeshInstance3D.new()
	var cpm := BoxMesh.new()
	cpm.size = Vector3(0.62, 0.36, 1.2)
	cockpit.mesh = cpm
	cockpit.position = Vector3(0.0, 0.66, -2.5)
	cockpit.material_override = canopy
	_ship_root.add_child(cockpit)

	# Wing fins
	for sx in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(2.2, 0.14, 2.4)
		wing.mesh = wm
		wing.position = Vector3(sx * 1.45, -0.1, 1.2)
		wing.material_override = dark
		_ship_root.add_child(wing)

	# Soft blue ion drive glow at rear (+Z)
	var drive := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.58
	dm.height = 1.16
	drive.mesh = dm
	drive.position = Vector3(0.0, 0.0, 3.3)
	drive.material_override = ion
	_ship_root.add_child(drive)

	var ship_light := OmniLight3D.new()
	ship_light.position = Vector3(0.0, 1.4, -2.5)
	ship_light.light_color = Color(0.85, 0.92, 1.0)
	ship_light.light_energy = 2.2
	ship_light.omni_range = 16.0
	_ship_root.add_child(ship_light)


func _build_cosmic_entity() -> void:
	_entity_root = Node3D.new()
	_entity_root.name = "TheThresholdEntity"
	_entity_root.position = Vector3(0.0, 0.5, -16.0)
	add_child(_entity_root)

	# Formless distorting central presence using custom cosmic_entity.gdshader
	_entity_core = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 4.2
	sphere.height = 8.4
	sphere.radial_segments = 48
	sphere.rings = 32
	_entity_core.mesh = sphere

	var shader_path: String = "res://assets/shaders/cosmic_entity.gdshader"
	if ResourceLoader.exists(shader_path):
		var smat := ShaderMaterial.new()
		smat.shader = load(shader_path)
		_entity_core.material_override = smat
	else:
		_entity_core.material_override = _make_mat(Color(0.05, 0.06, 0.12), 0.15, 0.85, Color(0.75, 0.65, 1.0), 2.0)
	_entity_root.add_child(_entity_core)

	# Three nested gravitational lensing rings
	var gold_ring := _make_mat(Color(0.98, 0.78, 0.36), 0.2, 0.8, Color(0.98, 0.76, 0.34), 3.4)
	var cyan_ring := _make_mat(Color(0.32, 0.86, 0.98), 0.2, 0.8, Color(0.32, 0.86, 0.98), 3.2)

	for cfg in [[6.8, 0.12, gold_ring], [9.4, 0.10, cyan_ring], [12.2, 0.09, gold_ring]]:
		var r_pivot := Node3D.new()
		_entity_root.add_child(r_pivot)
		var rmi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = cfg[0] - cfg[1]
		torus.outer_radius = cfg[0]
		torus.rings = 48
		rmi.mesh = torus
		rmi.material_override = cfg[2]
		r_pivot.add_child(rmi)
		_entity_rings.append(r_pivot)

	# 32 orbiting obsidian/luminous non-Euclidean shards
	var shard_mat := _make_mat(Color(0.09, 0.10, 0.16), 0.2, 0.9, Color(0.55, 0.76, 1.0), 0.9)
	for i in range(32):
		var s_node := Node3D.new()
		var mi := MeshInstance3D.new()
		var bm := PrismMesh.new()
		bm.size = Vector3(0.75, 1.65, 0.55) * (0.6 + float(i % 4) * 0.25)
		mi.mesh = bm
		mi.material_override = shard_mat
		s_node.add_child(mi)
		_entity_root.add_child(s_node)
		_entity_shards.append(s_node)

	var ent_light := OmniLight3D.new()
	ent_light.light_color = Color(0.84, 0.76, 1.0)
	ent_light.light_energy = 7.5
	ent_light.omni_range = 65.0
	_entity_root.add_child(ent_light)


func _build_interdimensional_rift() -> void:
	_portal_mesh = MeshInstance3D.new()
	_portal_mesh.name = "ParadoxMarketRift"
	var qm := QuadMesh.new()
	qm.size = Vector2(44.0, 44.0)
	_portal_mesh.mesh = qm
	_portal_mesh.position = Vector3(0.0, 0.5, -24.0)
	_portal_mesh.scale = Vector3(0.05, 0.05, 1.0)

	var shader_path: String = "res://assets/shaders/portal_rift.gdshader"
	if ResourceLoader.exists(shader_path):
		_portal_mat = ShaderMaterial.new()
		_portal_mat.shader = load(shader_path)
		_portal_mat.set_shader_parameter("openness", 0.0)
		_portal_mesh.material_override = _portal_mat
	add_child(_portal_mesh)


func _build_paradox_market_vista() -> void:
	# Breathtaking interdimensional bazaar architecture revealed beyond the rift (z = -40 to -125)
	_market_root = Node3D.new()
	_market_root.name = "ParadoxMarketVista"
	_market_root.position = Vector3(0.0, 0.0, -78.0)
	_market_root.visible = false
	add_child(_market_root)

	var basalt := _make_mat(Color(0.11, 0.13, 0.19), 0.45, 0.65)
	var amber_lantern := _make_mat(Color(1.0, 0.78, 0.34), 0.2, 0.0, Color(1.0, 0.74, 0.28), 5.5)
	var teal_spire := _make_mat(Color(0.28, 0.88, 0.94), 0.2, 0.3, Color(0.28, 0.86, 0.96), 3.2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 9001

	# Grand floating avenue of upright AND inverted interdimensional bazaar monoliths & glowing lantern stalls
	for i in range(28):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var z_off: float = 34.0 - float(i) * 3.2
		var x_off: float = side * rng.randf_range(12.0, 30.0)
		var inverted: float = -1.0 if i % 3 == 0 else 1.0
		var y_off: float = inverted * rng.randf_range(5.0, 15.0)

		var tower := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var h: float = rng.randf_range(10.0, 26.0)
		bm.size = Vector3(rng.randf_range(3.0, 6.0), h, rng.randf_range(3.0, 6.0))
		tower.mesh = bm
		tower.position = Vector3(x_off, y_off, z_off)
		tower.material_override = basalt
		_market_root.add_child(tower)

		# Warm market stall lantern orb tethered beside each monolith
		var lantern := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = rng.randf_range(0.55, 1.15)
		lm.height = lm.radius * 2.0
		lantern.mesh = lm
		lantern.position = Vector3(x_off - side * 3.6, y_off - inverted * 2.5, z_off)
		lantern.material_override = amber_lantern if i % 2 == 0 else teal_spire
		_market_root.add_child(lantern)

	# Colossal suspended archway rings framing the central Paradox Market boulevard
	for az in [18.0, -4.0, -26.0]:
		var arch := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 15.5
		tm.outer_radius = 16.4
		tm.rings = 48
		arch.mesh = tm
		arch.position = Vector3(0.0, 0.5, az)
		arch.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		arch.material_override = amber_lantern if az > 0.0 else teal_spire
		_market_root.add_child(arch)

	var m_light_a := OmniLight3D.new()
	m_light_a.position = Vector3(0.0, 6.0, 10.0)
	m_light_a.light_color = Color(1.0, 0.78, 0.42)
	m_light_a.light_energy = 10.0
	m_light_a.omni_range = 85.0
	_market_root.add_child(m_light_a)

	var m_light_b := OmniLight3D.new()
	m_light_b.position = Vector3(0.0, -4.0, -24.0)
	m_light_b.light_color = Color(0.32, 0.86, 0.96)
	m_light_b.light_energy = 10.0
	m_light_b.omni_range = 90.0
	_market_root.add_child(m_light_b)
