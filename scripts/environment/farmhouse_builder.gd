@tool
class_name FarmhouseBuilder
extends Node3D

## Procedurally builds the weathered, explorable Vance Farmhouse:
## - Front porch with smooth walkable ramp, overhang pillars, warm porch lantern
## - Hinged Front Door (South) and Back Door (North toward Outpost 09)
## - Living Room / Kitchen: Clara's Farewell Note & Botanical Archive Photo,
##   Framed Family Porch Photograph on the mantel, sofa, rug, old radio, sunlit windows
## - Maya's Bedroom: Bed, study desk with Farmhouse Sketch, Star Drawing pinned on wall,
##   gently rotating glowing constellation mobile, north window facing the Outpost beacons.

signal player_entered_farmhouse()
signal player_exited_farmhouse()

var _star_mobile: Node3D = null
var _front_door: DoorInteractable = null
var _back_door: DoorInteractable = null


func _ready() -> void:
	_build_structure()
	_build_doors()
	_build_living_room()
	_build_mayas_bedroom()
	_build_interior_trigger()


func _process(delta: float) -> void:
	if _star_mobile != null:
		_star_mobile.rotation.y += delta * 0.42


func _make_mat(col: Color, rough: float = 0.88, metal: float = 0.0, emit: Color = Color.BLACK, emit_str: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_str > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_str
	return m


func _make_textured_mat(tex_path: String, emit_str: float = 0.12) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.65
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		m.albedo_texture = tex
		if emit_str > 0.0:
			m.emission_enabled = true
			m.emission_texture = tex
			m.emission_energy_multiplier = emit_str
	else:
		m.albedo_color = Color(0.85, 0.78, 0.65)
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


func _build_structure() -> void:
	var ext_wood := _make_mat(Color(0.42, 0.34, 0.26), 0.92)
	var int_plaster := _make_mat(Color(0.56, 0.49, 0.40), 0.90)
	var floor_wood := _make_mat(Color(0.32, 0.23, 0.16), 0.84)
	var roof_metal := _make_mat(Color(0.28, 0.22, 0.19), 0.72, 0.35)
	var beam_wood := _make_mat(Color(0.24, 0.17, 0.12), 0.90)

	# Floor deck (main house + front porch): x in [-6.2, 6.2], z in [-5.2, 6.8], top surface at y = 0.30
	_add_solid_box(self, Vector3(12.4, 0.30, 12.0), Vector3(0.0, 0.15, 0.8), floor_wood)

	# Back step deck: x in [-4.0, -1.0], z in [-6.4, -5.2]
	_add_solid_box(self, Vector3(3.0, 0.30, 1.2), Vector3(-2.5, 0.15, -5.8), floor_wood)

	# Smooth sloped walkable front porch ramp (z = 6.8 to 8.2, smoothly bridging y=0.0 -> y=0.30)
	_add_solid_box(self, Vector3(3.4, 0.14, 1.65), Vector3(0.0, 0.12, 7.52), beam_wood, Vector3(11.0, 0.0, 0.0))
	# Smooth sloped back porch ramp (z = -6.4 to -7.8)
	_add_solid_box(self, Vector3(2.8, 0.14, 1.65), Vector3(-2.5, 0.12, -7.12), beam_wood, Vector3(-11.0, 0.0, 0.0))

	# Wall height: y = 0.30 to 3.70 (height = 3.40, center y = 2.00)
	var wall_h: float = 3.40
	var wall_y: float = 2.00
	var wall_t: float = 0.26

	# --- SOUTH EXTERIOR WALL (z = 4.0) with Front Doorway x in [-1.1, 1.1] & 2 windows ---
	# Left of front door: x in [-6.0, -1.1] (width 4.9, center -3.55)
	_add_solid_box(self, Vector3(1.5, wall_h, wall_t), Vector3(-5.25, wall_y, 4.0), ext_wood)
	_add_solid_box(self, Vector3(1.5, wall_h, wall_t), Vector3(-1.85, wall_y, 4.0), ext_wood)
	# Window sill & header at x = -3.55 (window opening width 1.9, y = 1.25..2.65)
	_add_solid_box(self, Vector3(1.9, 0.95, wall_t), Vector3(-3.55, 0.775, 4.0), ext_wood)
	_add_solid_box(self, Vector3(1.9, 1.05, wall_t), Vector3(-3.55, 3.175, 4.0), ext_wood)
	# Front door header (y = 2.75..3.70)
	_add_solid_box(self, Vector3(2.2, 0.95, wall_t), Vector3(0.0, 3.225, 4.0), ext_wood)
	# Right of front door: x in [1.1, 6.0]
	_add_solid_box(self, Vector3(1.5, wall_h, wall_t), Vector3(1.85, wall_y, 4.0), ext_wood)
	_add_solid_box(self, Vector3(1.5, wall_h, wall_t), Vector3(5.25, wall_y, 4.0), ext_wood)
	_add_solid_box(self, Vector3(1.9, 0.95, wall_t), Vector3(3.55, 0.775, 4.0), ext_wood)
	_add_solid_box(self, Vector3(1.9, 1.05, wall_t), Vector3(3.55, 3.175, 4.0), ext_wood)

	# --- NORTH EXTERIOR WALL (z = -5.0) with Back Doorway x in [-3.6, -1.4] & Maya's North Window ---
	_add_solid_box(self, Vector3(2.4, wall_h, wall_t), Vector3(-4.8, wall_y, -5.0), ext_wood)
	_add_solid_box(self, Vector3(2.2, 0.95, wall_t), Vector3(-2.5, 3.225, -5.0), ext_wood) # Back door header
	_add_solid_box(self, Vector3(3.6, wall_h, wall_t), Vector3(0.4, wall_y, -5.0), ext_wood)
	# Maya's north window (x in [2.2, 4.4], y = 1.25..2.65)
	_add_solid_box(self, Vector3(2.2, 0.95, wall_t), Vector3(3.3, 0.775, -5.0), ext_wood)
	_add_solid_box(self, Vector3(2.2, 1.05, wall_t), Vector3(3.3, 3.175, -5.0), ext_wood)
	_add_solid_box(self, Vector3(1.6, wall_h, wall_t), Vector3(5.2, wall_y, -5.0), ext_wood)

	# --- WEST EXTERIOR WALL (x = -6.0, z in [-5.0, 4.0]) ---
	_add_solid_box(self, Vector3(wall_t, wall_h, 3.1), Vector3(-6.0, wall_y, -3.45), ext_wood)
	_add_solid_box(self, Vector3(wall_t, wall_h, 3.1), Vector3(-6.0, wall_y, 2.45), ext_wood)
	# West sunlit window (z in [-1.9, 0.9])
	_add_solid_box(self, Vector3(wall_t, 0.95, 2.8), Vector3(-6.0, 0.775, -0.5), ext_wood)
	_add_solid_box(self, Vector3(wall_t, 1.05, 2.8), Vector3(-6.0, 3.175, -0.5), ext_wood)

	# --- EAST EXTERIOR WALL (x = 6.0, solid wall for Maya's drawings & desk) ---
	_add_solid_box(self, Vector3(wall_t, wall_h, 9.26), Vector3(6.0, wall_y, -0.5), ext_wood)

	# --- INTERIOR PARTITION WALL (x = 0.5) separating Living Room & Maya's Bedroom ---
	# Open archway at z in [-1.1, 1.1]
	_add_solid_box(self, Vector3(0.20, wall_h, 3.9), Vector3(0.5, wall_y, -3.05), int_plaster)
	_add_solid_box(self, Vector3(0.20, wall_h, 2.9), Vector3(0.5, wall_y, 2.55), int_plaster)
	_add_solid_box(self, Vector3(0.20, 0.95, 2.2), Vector3(0.5, 3.225, 0.0), int_plaster)

	# --- CEILING & PITCHED ROOF ---
	_add_solid_box(self, Vector3(12.6, 0.22, 9.6), Vector3(0.0, 3.80, -0.5), int_plaster)
	# Pitched corrugated roof slopes
	_add_solid_box(self, Vector3(7.4, 0.18, 12.6), Vector3(-3.3, 4.95, 0.6), roof_metal, Vector3(0.0, 0.0, 20.0), false)
	_add_solid_box(self, Vector3(7.4, 0.18, 12.6), Vector3(3.3, 4.95, 0.6), roof_metal, Vector3(0.0, 0.0, -20.0), false)
	# Porch roof overhang & support pillars
	_add_solid_box(self, Vector3(12.6, 0.16, 3.2), Vector3(0.0, 3.45, 5.5), roof_metal, Vector3(7.0, 0.0, 0.0), false)
	for px in [-5.8, -2.1, 2.1, 5.8]:
		_add_solid_box(self, Vector3(0.18, 3.05, 0.18), Vector3(px, 1.82, 6.55), beam_wood)

	# Porch handrail sections (leaving center entry open)
	_add_solid_box(self, Vector3(3.6, 0.10, 0.10), Vector3(-3.95, 1.15, 6.55), beam_wood)
	_add_solid_box(self, Vector3(3.6, 0.10, 0.10), Vector3(3.95, 1.15, 6.55), beam_wood)

	# Warm porch lantern light
	var porch_light := OmniLight3D.new()
	porch_light.position = Vector3(1.5, 2.85, 4.65)
	porch_light.light_color = Color(1.0, 0.74, 0.42)
	porch_light.light_energy = 2.1
	porch_light.omni_range = 10.0
	add_child(porch_light)

	# Translucent dusty sunbeam shafts slanting through the West & South windows
	var beam_mat := StandardMaterial3D.new()
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.albedo_color = Color(1.0, 0.82, 0.52, 0.085)
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	for bpos in [Vector3(-4.1, 1.55, -0.5), Vector3(-3.2, 1.45, 2.2), Vector3(3.4, 1.45, 2.2)]:
		var shaft := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(1.55, 2.4, 2.9)
		shaft.mesh = sm
		shaft.position = bpos
		shaft.rotation_degrees = Vector3(14.0, 12.0, -28.0)
		shaft.material_override = beam_mat
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shaft)


func _build_doors() -> void:
	var door_mat := _make_mat(Color(0.28, 0.19, 0.13), 0.82)
	var handle_mat := _make_mat(Color(0.75, 0.62, 0.35), 0.35, 0.85)

	# Front Door pivoted at left jamb (-1.05, 0.30, 4.0)
	var front_pivot := Node3D.new()
	front_pivot.name = "FrontDoorPivot"
	front_pivot.position = Vector3(-1.05, 0.30, 4.0)
	add_child(front_pivot)

	var front_leaf := _add_solid_box(front_pivot, Vector3(2.08, 2.40, 0.10), Vector3(1.04, 1.20, 0.0), door_mat)
	_add_solid_box(front_leaf, Vector3(0.06, 0.22, 0.18), Vector3(0.84, -0.10, 0.0), handle_mat, Vector3.ZERO, false)

	_front_door = DoorInteractable.new()
	_front_door.name = "FrontDoorInteractable"
	_front_door.door_style = DoorInteractable.DoorStyle.HINGED
	_front_door.door_label = "Farmhouse Front Door"
	_front_door.open_angle_deg = 98.0
	_front_door.position = Vector3(0.0, 1.35, 4.0)
	var fcol := CollisionShape3D.new()
	var fsph := SphereShape3D.new()
	fsph.radius = 2.0
	fcol.shape = fsph
	_front_door.add_child(fcol)
	add_child(_front_door)
	_front_door.setup_door_pivot(front_pivot)

	# Back Door (North wall at x = -2.5, z = -5.0) leading directly toward Horizon Outpost 09
	var back_pivot := Node3D.new()
	back_pivot.name = "BackDoorPivot"
	back_pivot.position = Vector3(-3.55, 0.30, -5.0)
	add_child(back_pivot)

	var back_leaf := _add_solid_box(back_pivot, Vector3(2.08, 2.40, 0.10), Vector3(1.04, 1.20, 0.0), door_mat)
	_add_solid_box(back_leaf, Vector3(0.06, 0.22, 0.18), Vector3(0.84, -0.10, 0.0), handle_mat, Vector3.ZERO, false)

	_back_door = DoorInteractable.new()
	_back_door.name = "BackDoorInteractable"
	_back_door.door_style = DoorInteractable.DoorStyle.HINGED
	_back_door.door_label = "Back Porch Door (North)"
	_back_door.open_angle_deg = -98.0
	_back_door.position = Vector3(-2.5, 1.35, -5.0)
	var bcol := CollisionShape3D.new()
	var bsph := SphereShape3D.new()
	bsph.radius = 2.0
	bcol.shape = bsph
	_back_door.add_child(bcol)
	add_child(_back_door)
	_back_door.setup_door_pivot(back_pivot)


func _build_living_room() -> void:
	var table_wood := _make_mat(Color(0.30, 0.21, 0.14), 0.78)
	var cloth_mat := _make_mat(Color(0.42, 0.28, 0.22), 0.94)
	var frame_mat := _make_mat(Color(0.22, 0.15, 0.10), 0.70)
	var rug_mat := _make_mat(Color(0.45, 0.31, 0.21), 0.96)
	var paper_mat := _make_mat(Color(0.90, 0.85, 0.74), 0.85, 0.0, Color(0.92, 0.84, 0.65), 0.2)

	# Warm hanging tungsten ceiling lamp in living room
	var lr_light := OmniLight3D.new()
	lr_light.position = Vector3(-2.9, 3.15, 0.2)
	lr_light.light_color = Color(1.0, 0.80, 0.52)
	lr_light.light_energy = 1.95
	lr_light.omni_range = 10.5
	add_child(lr_light)

	# Woven floor rug
	_add_solid_box(self, Vector3(3.8, 0.03, 2.8), Vector3(-2.8, 0.315, 0.2), rug_mat, Vector3.ZERO, false)

	# Kitchen / Dining Table at (-3.1, 0.30, 0.35)
	_add_solid_box(self, Vector3(2.1, 0.10, 1.25), Vector3(-3.1, 1.08, 0.35), table_wood)
	for lx in [-3.95, -2.25]:
		for lz in [-0.15, 0.85]:
			_add_solid_box(self, Vector3(0.10, 0.75, 0.10), Vector3(lx, 0.675, lz), table_wood)

	# Chairs around table
	_add_solid_box(self, Vector3(0.55, 0.48, 0.55), Vector3(-3.1, 0.54, 1.35), table_wood)
	_add_solid_box(self, Vector3(0.55, 0.48, 0.55), Vector3(-3.1, 0.54, -0.65), table_wood)

	# Clara's Farewell Letter & Botanical Archive Photo resting on the table
	_add_solid_box(self, Vector3(0.36, 0.02, 0.26), Vector3(-2.85, 1.14, 0.35), paper_mat, Vector3(0, 14, 0), false)
	var archive_plane := MeshInstance3D.new()
	var apm := QuadMesh.new()
	apm.size = Vector2(0.42, 0.32)
	archive_plane.mesh = apm
	archive_plane.position = Vector3(-3.35, 1.145, 0.32)
	archive_plane.rotation_degrees = Vector3(-90.0, -8.0, 0.0)
	archive_plane.material_override = _make_textured_mat("res://assets/textures/photo_green_earth.png", 0.18)
	add_child(archive_plane)

	_add_memory_area("clara_letter_and_archive", "Read Clara's Note & Botanical Archive", Vector3(-3.1, 1.25, 0.35))

	# West Mantel Shelf at (-5.55, 0.30, -2.85) with Framed Family Porch Photograph
	_add_solid_box(self, Vector3(0.52, 1.05, 1.85), Vector3(-5.58, 0.825, -2.85), table_wood)
	_add_solid_box(self, Vector3(0.08, 0.56, 0.72), Vector3(-5.56, 1.65, -2.85), frame_mat, Vector3(0, 0, -6), false)

	var porch_photo := MeshInstance3D.new()
	var ppm := QuadMesh.new()
	ppm.size = Vector2(0.64, 0.48)
	porch_photo.mesh = ppm
	porch_photo.position = Vector3(-5.50, 1.65, -2.85)
	porch_photo.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	porch_photo.material_override = _make_textured_mat("res://assets/textures/photo_family_porch.png", 0.22)
	add_child(porch_photo)

	_add_memory_area("family_porch_photo", "Inspect Framed Family Photograph", Vector3(-5.25, 1.45, -2.85))

	# Weathered Sofa along the South-West wall
	_add_solid_box(self, Vector3(2.2, 0.48, 0.95), Vector3(-4.1, 0.54, 3.15), cloth_mat)
	_add_solid_box(self, Vector3(2.2, 0.82, 0.25), Vector3(-4.1, 0.82, 3.55), cloth_mat)


func _build_mayas_bedroom() -> void:
	var bed_wood := _make_mat(Color(0.36, 0.25, 0.18), 0.85)
	var quilt_mat := _make_mat(Color(0.52, 0.33, 0.28), 0.94)
	var pillow_mat := _make_mat(Color(0.84, 0.79, 0.70), 0.92)
	var frame_mat := _make_mat(Color(0.26, 0.20, 0.15), 0.75)

	# Warm desk & bedroom lamp
	var bed_light := OmniLight3D.new()
	bed_light.position = Vector3(3.4, 3.05, -0.5)
	bed_light.light_color = Color(1.0, 0.82, 0.56)
	bed_light.light_energy = 1.9
	bed_light.omni_range = 9.5
	add_child(bed_light)

	# Child's Bed in NE corner (4.4, 0.30, -3.3)
	_add_solid_box(self, Vector3(1.65, 0.44, 2.35), Vector3(4.55, 0.52, -3.35), bed_wood)
	_add_solid_box(self, Vector3(1.52, 0.22, 2.18), Vector3(4.55, 0.80, -3.35), quilt_mat)
	_add_solid_box(self, Vector3(0.92, 0.18, 0.46), Vector3(4.55, 0.96, -4.15), pillow_mat)

	# Study Desk along East wall (4.95, 0.30, 1.4)
	_add_solid_box(self, Vector3(1.20, 0.08, 2.05), Vector3(5.05, 1.05, 1.40), bed_wood)
	_add_solid_box(self, Vector3(1.10, 0.72, 0.10), Vector3(5.05, 0.66, 0.48), bed_wood)
	_add_solid_box(self, Vector3(1.10, 0.72, 0.10), Vector3(5.05, 0.66, 2.32), bed_wood)

	# Maya's Farmhouse Crayon Sketch resting on the desk
	var farm_draw := MeshInstance3D.new()
	var fdm := QuadMesh.new()
	fdm.size = Vector2(0.54, 0.40)
	farm_draw.mesh = fdm
	farm_draw.position = Vector3(4.98, 1.10, 1.72)
	farm_draw.rotation_degrees = Vector3(-90.0, -78.0, 0.0)
	farm_draw.material_override = _make_textured_mat("res://assets/textures/drawing_maya_corn.png", 0.20)
	add_child(farm_draw)

	_add_memory_area("maya_farm_drawing", "Inspect Maya's Sketch ('The Tall Corn')", Vector3(4.65, 1.15, 1.88))

	# Maya's Star Drawing ('Dad's Door to Green') pinned above desk on East wall
	_add_solid_box(self, Vector3(0.06, 0.74, 0.96), Vector3(5.82, 1.85, 1.15), frame_mat, Vector3.ZERO, false)
	var star_draw := MeshInstance3D.new()
	var sdm := QuadMesh.new()
	sdm.size = Vector2(0.88, 0.66)
	star_draw.mesh = sdm
	star_draw.position = Vector3(5.78, 1.85, 1.15)
	star_draw.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	star_draw.material_override = _make_textured_mat("res://assets/textures/drawing_maya_stars.png", 0.25)
	add_child(star_draw)

	_add_memory_area("maya_star_drawing", "Inspect Maya's Drawing ('Dad's Door to Green')", Vector3(5.20, 1.65, 1.05))

	# Gently rotating glowing paper star/planet mobile hanging from bedroom ceiling
	_star_mobile = Node3D.new()
	_star_mobile.name = "ConstellationMobile"
	_star_mobile.position = Vector3(3.15, 3.05, -0.8)
	add_child(_star_mobile)

	var wire_mat := _make_mat(Color(0.55, 0.55, 0.58), 0.4, 0.8)
	var star_gold := _make_mat(Color(1.0, 0.84, 0.42), 0.3, 0.2, Color(1.0, 0.82, 0.38), 1.8)
	var planet_teal := _make_mat(Color(0.42, 0.84, 0.92), 0.3, 0.2, Color(0.38, 0.82, 0.92), 1.6)

	_add_solid_box(_star_mobile, Vector3(1.1, 0.02, 0.02), Vector3.ZERO, wire_mat, Vector3.ZERO, false)
	_add_solid_box(_star_mobile, Vector3(0.02, 0.02, 1.1), Vector3.ZERO, wire_mat, Vector3.ZERO, false)
	for cfg in [
		[Vector3(0.52, -0.25, 0.0), 0.08, star_gold],
		[Vector3(-0.52, -0.35, 0.0), 0.11, planet_teal],
		[Vector3(0.0, -0.22, 0.52), 0.07, star_gold],
		[Vector3(0.0, -0.32, -0.52), 0.09, planet_teal]
	]:
		var orb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = cfg[1]
		sm.height = cfg[1] * 2.0
		orb.mesh = sm
		orb.position = cfg[0]
		orb.material_override = cfg[2]
		_star_mobile.add_child(orb)


func _add_memory_area(mem_id: String, prompt: String, pos: Vector3) -> void:
	var item := MemoryItem.new()
	item.name = "Memory_" + mem_id
	item.memory_id = mem_id
	item.prompt_text = prompt
	item.position = pos
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.65
	col.shape = sph
	item.add_child(col)
	add_child(item)


func _build_interior_trigger() -> void:
	var area := Area3D.new()
	area.name = "InteriorTrigger"
	area.collision_layer = 0
	area.collision_mask = 2 # Player
	area.position = Vector3(0.0, 1.8, -0.4)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(11.4, 3.2, 8.6)
	col.shape = box
	area.add_child(col)
	add_child(area)

	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			player_entered_farmhouse.emit()
	)
	area.body_exited.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			player_exited_farmhouse.emit()
	)
