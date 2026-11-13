extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const STONE := Color(0.48, 0.43, 0.36)
const LIGHT_STONE := Color(0.68, 0.59, 0.45)
const DARK_STONE := Color(0.25, 0.24, 0.22)
const SAND := Color(0.66, 0.52, 0.34)
const GRASS := Color(0.22, 0.37, 0.20)
const ROOF := Color(0.30, 0.19, 0.14)
const WATER := Color(0.10, 0.34, 0.43)

var status_label: Label
var score := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 817263
	_build_environment()
	_build_terrain()
	_build_roads_and_river()
	_build_capital_fort()
	_build_hill_fort(Vector3(-112, 0, -105), 0.72)
	_build_hill_fort(Vector3(122, 0, 80), 0.58)
	_build_ruined_citadel(Vector3(-126, 0, 105))
	_build_villages()
	_build_battlefield_cover()
	_build_forest()
	_build_player()
	_build_hud()
	_spawn_targets()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.82, 0.91)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

func _height_at(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var fade := clampf((d - 82.0) / 105.0, 0.0, 1.0)
	return fade * (2.2 * sin(x * 0.025) * cos(z * 0.021) + 1.4 * sin((x + z) * 0.043))

func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var divisions := 76
	var extent := 230.0
	for z in range(divisions):
		for x in range(divisions):
			var x0 := -extent + float(x) * extent * 2.0 / divisions
			var x1 := -extent + float(x + 1) * extent * 2.0 / divisions
			var z0 := -extent + float(z) * extent * 2.0 / divisions
			var z1 := -extent + float(z + 1) * extent * 2.0 / divisions
			var a := Vector3(x0, _height_at(x0, z0), z0)
			var b := Vector3(x1, _height_at(x1, z0), z0)
			var c := Vector3(x1, _height_at(x1, z1), z1)
			var d := Vector3(x0, _height_at(x0, z1), z1)
			var col := GRASS.lerp(Color(0.42, 0.34, 0.22), clampf((_height_at((x0+x1)*0.5,(z0+z1)*0.5)+1.0)/8.0,0.0,0.5))
			st.set_color(col); st.add_vertex(a)
			st.set_color(col); st.add_vertex(c)
			st.set_color(col); st.add_vertex(b)
			st.set_color(col); st.add_vertex(a)
			st.set_color(col); st.add_vertex(d)
			st.set_color(col); st.add_vertex(c)
	st.generate_normals()
	var mesh := st.commit()
	var terrain := StaticBody3D.new()
	terrain.name = "Huge rolling battlefield terrain"
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	visual.material_override = mat
	terrain.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	terrain.add_child(collision)
	add_child(terrain)

func _build_roads_and_river() -> void:
	# Wide dusty roads join every stronghold and village.
	_box("Main north south road", Vector3(0, 0.06, 0), Vector3(12, 0.12, 350), SAND)
	_box("Cross battlefield road", Vector3(0, 0.07, 8), Vector3(330, 0.14, 10), SAND)
	_box("West road to hill fort", Vector3(-72, 0.08, -58), Vector3(105, 0.16, 8), SAND)
	_box("East road to fort", Vector3(78, 0.08, 54), Vector3(115, 0.16, 8), SAND)
	# River and stone bridges on the east side.
	_box("Blue river", Vector3(165, -0.05, 0), Vector3(19, 0.12, 390), WATER)
	_box("River west bank", Vector3(153, 0.15, 0), Vector3(3, 0.4, 390), DARK_STONE)
	_box("River east bank", Vector3(177, 0.15, 0), Vector3(3, 0.4, 390), DARK_STONE)
	_build_bridge(Vector3(165, 0.65, -82))
	_build_bridge(Vector3(165, 0.65, 82))
	# Small paths into the main gate.
	_box("Fort approach", Vector3(0, 0.12, 92), Vector3(18, 0.2, 62), SAND)

func _build_bridge(pos: Vector3) -> void:
	_box("Ancient bridge deck", pos, Vector3(30, 1.2, 12), LIGHT_STONE)
	for x in [-12, -4, 4, 12]:
		_box("Bridge side parapet", pos + Vector3(x, 1.2, -5.4), Vector3(2, 1.3, 1), STONE)
		_box("Bridge side parapet", pos + Vector3(x, 1.2, 5.4), Vector3(2, 1.3, 1), STONE)
	for x in [-9, 9]:
		_pillar("Bridge support pier", pos + Vector3(x, -2, 0), 5, DARK_STONE)

func _build_capital_fort() -> void:
	# Large central fortress: broad outer curtain, four round towers, inner keep.
	_box("Capital courtyard", Vector3(0, 0.18, -78), Vector3(112, 0.35, 76), Color(0.43,0.37,0.29))
	_box("Capital north curtain", Vector3(0, 9, -117), Vector3(116, 18, 5), STONE)
	_box("Capital west curtain", Vector3(-56, 8, -78), Vector3(5, 16, 82), STONE)
	_box("Capital east curtain", Vector3(56, 8, -78), Vector3(5, 16, 82), STONE)
	_box("Capital south left curtain", Vector3(-42, 8, -39), Vector3(32, 16, 5), STONE)
	_box("Capital south right curtain", Vector3(42, 8, -39), Vector3(32, 16, 5), STONE)
	_box("Grand gate lintel", Vector3(0, 16, -39), Vector3(54, 4, 7), DARK_STONE)
	for p in [Vector3(-56,0,-117),Vector3(56,0,-117),Vector3(-56,0,-39),Vector3(56,0,-39)]:
		_round_tower(p, 25, 10)
	# Walkable-looking wall walk and crenellations.
	for x in range(-52, 53, 6):
		_box("Capital battlement", Vector3(x, 18.2, -117), Vector3(3.0, 3.0, 2.5), LIGHT_STONE)
	for z in range(-110, -44, 7):
		_box("West wall merlon", Vector3(-56, 17.5, z), Vector3(2.5, 3, 3), LIGHT_STONE)
		_box("East wall merlon", Vector3(56, 17.5, z), Vector3(2.5, 3, 3), LIGHT_STONE)
	# Keep: several tiers, corner turrets, roof, arches and banners.
	_box("Royal keep base", Vector3(0, 7, -86), Vector3(42, 14, 34), DARK_STONE)
	_box("Royal keep upper hall", Vector3(0, 17, -86), Vector3(34, 8, 28), LIGHT_STONE)
	_box("Royal keep roof", Vector3(0, 21.5, -86), Vector3(38, 1.5, 32), ROOF)
	for p in [Vector3(-18,0,-101),Vector3(18,0,-101),Vector3(-18,0,-71),Vector3(18,0,-71)]:
		_round_tower(p, 29, 4.5)
	_box("Keep grand doorway", Vector3(0, 3, -68.6), Vector3(7, 6, 0.6), DARK_STONE)
	_box("Keep arch crown", Vector3(0, 6.5, -68.2), Vector3(12, 1.2, 1.2), LIGHT_STONE)
	# Courtyard buildings, stable, barracks, well and statues.
	_build_hall(Vector3(-34,0,-67), Vector3(18,9,20), Color(0.58,0.48,0.36))
	_build_hall(Vector3(34,0,-67), Vector3(18,8,20), Color(0.55,0.43,0.31))
	_cylinder("Courtyard well", Vector3(0,1,-53), 3.5, 2, DARK_STONE)
	for x in [-42,42]:
		_pillar("Courtyard statue plinth", Vector3(x,0,-92), 5, LIGHT_STONE)
	# Inner yard cover and old siege engines.
	_box("Stone barricade", Vector3(-24,2,-94), Vector3(18,4,3), STONE)
	_box("Stone barricade", Vector3(25,2,-94), Vector3(16,4,3), STONE)
	_build_torch(Vector3(-48,0,-48))
	_build_torch(Vector3(48,0,-48))

func _round_tower(pos: Vector3, height: float, radius: float) -> void:
	_cylinder("Round fortress tower", pos + Vector3(0,height/2,0), radius, height, LIGHT_STONE)
	_cylinder("Tower lower stone ring", pos + Vector3(0,3,0), radius+0.8, 1.4, DARK_STONE)
	_cylinder("Tower crown ring", pos + Vector3(0,height-1,0), radius+1.2, 2, DARK_STONE)
	_cylinder("Tower roof cap", pos + Vector3(0,height+1.3,0), radius*0.82, 1.2, ROOF)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		var p := pos + Vector3(cos(a)*(radius+0.2), height+2.1, sin(a)*(radius+0.2))
		_box("Tower crenellation", p, Vector3(2,2.5,2), LIGHT_STONE)
	# Tall dark arrow windows on the visible sides.
	_box("Tower arrow slit", pos + Vector3(0,height*0.58,radius+0.06), Vector3(0.8,3,0.18), DARK_STONE)

func _build_hill_fort(center: Vector3, scale: float) -> void:
	var w := 54.0 * scale
	var h := 13.0 * scale
	# Raised rocky mound and smaller fortress on the hill.
	_cylinder("Hill fort rocky mound", center + Vector3(0,3,0), w, 6, Color(0.32,0.34,0.27))
	_box("Hill fort yard", center + Vector3(0,6,-2), Vector3(w*1.55,0.6,w*1.25), SAND)
	_box("Hill fort rear wall", center + Vector3(0,h/2+6,-w*0.55), Vector3(w*1.5,h,w*0.13), STONE)
	_box("Hill fort left wall", center + Vector3(-w*0.75,h/2+6,0), Vector3(w*0.13,h,w), STONE)
	_box("Hill fort right wall", center + Vector3(w*0.75,h/2+6,0), Vector3(w*0.13,h,w), STONE)
	_box("Hill fort gate left", center + Vector3(-w*0.28,h/2+6,w*0.55), Vector3(w*0.42,h,w*0.13), LIGHT_STONE)
	_box("Hill fort gate right", center + Vector3(w*0.28,h/2+6,w*0.55), Vector3(w*0.42,h,w*0.13), LIGHT_STONE)
	_box("Hill fort gate top", center + Vector3(0,h+6,w*0.55), Vector3(w*0.28,2,w*0.16), DARK_STONE)
	_round_tower(center + Vector3(-w*0.75,6,-w*0.55),h+3,w*0.16)
	_round_tower(center + Vector3(w*0.75,6,-w*0.55),h+3,w*0.16)
	_round_tower(center + Vector3(-w*0.75,6,w*0.45),h,w*0.15)
	_round_tower(center + Vector3(w*0.75,6,w*0.45),h,w*0.15)
	_box("Hill fort keep", center + Vector3(0,11,-8), Vector3(w*0.58,18,w*0.5), DARK_STONE)
	_box("Hill fort keep roof", center + Vector3(0,20,-8), Vector3(w*0.65,2,w*0.56), ROOF)
	for x in [-w*0.45,0,w*0.45]:
		_box("Hill fort merlon", center + Vector3(x,h+8,-w*0.55), Vector3(3,3,2), LIGHT_STONE)

func _build_ruined_citadel(center: Vector3) -> void:
	# A collapsed ancient fortress with broken towers and exposed interior.
	_box("Ruined citadel floor", center + Vector3(0,0.2,0), Vector3(76,0.4,62), SAND)
	_box("Citadel rear wall", center + Vector3(0,5,-30), Vector3(76,10,4), STONE)
	_box("Citadel west broken wall", center + Vector3(-36,3,0), Vector3(4,6,60), STONE)
	_box("Citadel east broken wall", center + Vector3(36,4,0), Vector3(4,8,60), STONE)
	_box("Collapsed front wall left", center + Vector3(-24,2,29), Vector3(28,4,4), DARK_STONE)
	_box("Collapsed front wall right", center + Vector3(27,1.5,29), Vector3(22,3,4), STONE)
	_round_tower(center + Vector3(-36,0,-30),17,7)
	_round_tower(center + Vector3(36,0,-30),13,6)
	_round_tower(center + Vector3(-36,0,30),8,6)
	# Broken central palace with missing roof and fallen columns.
	_box("Citadel palace back", center + Vector3(0,5,-15), Vector3(30,10,3), LIGHT_STONE)
	_box("Citadel palace left", center + Vector3(-14,4,-4), Vector3(3,8,22), LIGHT_STONE)
	_box("Citadel palace right broken", center + Vector3(14,2.5,-8), Vector3(3,5,14), STONE)
	for x in [-10,-3,5,11]:
		_pillar("Ancient broken column", center + Vector3(x,0,1), rng.randf_range(3,8), LIGHT_STONE)
	_box("Fallen stone beam", center + Vector3(2,1.4,10), Vector3(20,2,3), DARK_STONE)
	_box("Rubble pile", center + Vector3(-22,1.2,15), Vector3(12,2.4,9), DARK_STONE)
	_box("Rubble pile", center + Vector3(23,1.0,-4), Vector3(10,2,8), STONE)

func _build_hall(pos: Vector3, size: Vector3, tint: Color) -> void:
	_box("Fort hall floor", pos + Vector3(0,0.2,0), Vector3(size.x,0.4,size.z), SAND)
	_box("Hall rear wall", pos + Vector3(0,size.y/2,-size.z/2), Vector3(size.x,size.y,size.z*0.12), tint)
	_box("Hall side wall", pos + Vector3(-size.x/2,size.y/2,0), Vector3(size.x*0.12,size.y,size.z), tint)
	_box("Hall other side", pos + Vector3(size.x/2,size.y/2,0), Vector3(size.x*0.12,size.y,size.z), tint)
	_box("Hall roof", pos + Vector3(0,size.y,0), Vector3(size.x*1.08,1.2,size.z*1.08), ROOF)
	_box("Hall doorway shadow", pos + Vector3(0,2,size.z/2+0.1), Vector3(4,4,0.2), DARK_STONE)

func _build_villages() -> void:
	for p in [Vector3(88,0,-12),Vector3(104,0,8),Vector3(92,0,28),Vector3(-82,0,12),Vector3(-96,0,32),Vector3(30,0,145),Vector3(-25,0,158)]:
		_build_house(p, rng.randf_range(7,11), rng.randf_range(6,9))
	_box("Village market square", Vector3(95,0.1,12), Vector3(30,0.2,24), SAND)
	_cylinder("Village well", Vector3(95,1,12), 2.5,2,DARK_STONE)

func _build_house(pos: Vector3, width: float, depth: float) -> void:
	var tint: Color = [Color(0.62,0.43,0.29), Color(0.72,0.58,0.39), Color(0.49,0.42,0.33)][rng.randi_range(0, 2)]
	_box("Village mud house rear", pos+Vector3(0,2,-depth/2), Vector3(width,4,0.8), tint)
	_box("Village mud house left", pos+Vector3(-width/2,2,0), Vector3(0.8,4,depth), tint)
	_box("Village mud house right", pos+Vector3(width/2,1.5,1), Vector3(0.8,3,depth*0.6), tint)
	_box("Village house roof", pos+Vector3(0,4.2,-0.5), Vector3(width*1.1,0.8,depth*1.1), ROOF)
	_box("Village doorway", pos+Vector3(0,1.2,depth/2+0.05), Vector3(2.2,2.4,0.2), DARK_STONE)

func _build_battlefield_cover() -> void:
	for i in range(26):
		var x := rng.randf_range(-145,145)
		var z := rng.randf_range(-180,180)
		if Vector2(x,z).length() < 75 or absf(x-165) < 25:
			continue
		var size := rng.randf_range(2.5,7.0)
		_box("Scattered battlefield boulder", Vector3(x,_height_at(x,z)+size*0.35,z), Vector3(size,size*0.7,size*1.2), DARK_STONE)
	for i in range(18):
		var x := rng.randf_range(-150,145)
		var z := rng.randf_range(-180,180)
		if Vector2(x,z).length() < 72:
			continue
		_box("Broken defensive wall", Vector3(x,_height_at(x,z)+1.4,z), Vector3(rng.randf_range(5,13),2.8,1.8), STONE)

func _build_forest() -> void:
	for i in range(100):
		var x := rng.randf_range(-205,205)
		var z := rng.randf_range(-205,205)
		if Vector2(x,z).length() < 82 or (x > 135 and x < 190):
			continue
		if absf(x) < 12 or absf(z) < 12:
			continue
		_tree(Vector3(x,_height_at(x,z),z),rng.randf_range(0.75,1.35))

func _tree(pos: Vector3, scale: float) -> void:
	_cylinder("Tree trunk",pos+Vector3(0,2.2*scale,0),0.65*scale,4.4*scale,Color(0.28,0.18,0.11))
	_cone("Tree crown lower",pos+Vector3(0,5.2*scale,0),3.3*scale,5.5*scale,Color(0.12,0.28,0.14))
	_cone("Tree crown upper",pos+Vector3(0,7.4*scale,0),2.5*scale,4.5*scale,Color(0.17,0.36,0.18))

func _build_torch(pos: Vector3) -> void:
	_box("Torch iron post",pos+Vector3(0,2,0),Vector3(0.45,4,0.45),DARK_STONE)
	var lamp := OmniLight3D.new()
	lamp.position = pos+Vector3(0,4.5,0)
	lamp.light_color = Color(1.0,0.55,0.2)
	lamp.light_energy = 1.4
	lamp.omni_range = 13
	add_child(lamp)
	_sphere("Torch flame",pos+Vector3(0,4.7,0),0.6,Color(1.0,0.38,0.08))

func _pillar(label: String, pos: Vector3, height: float, tint: Color) -> void:
	_cylinder(label,pos+Vector3(0,height/2,0),1.5,height,tint)
	_cylinder(label+" capital",pos+Vector3(0,height,0),2.1,0.7,DARK_STONE)

func _box(label: String, pos: Vector3, size: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.95
	visual.material_override = mat
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _cylinder(label: String, pos: Vector3, radius: float, height: float, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius*0.94
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.96
	visual.material_override = mat
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)

func _cone(label: String, pos: Vector3, radius: float, height: float, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 1.0
	visual.material_override = mat
	body.add_child(visual)

func _sphere(label: String, pos: Vector3, radius: float, tint: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.position = pos
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	visual.material_override = mat
	add_child(visual)

func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.5, 14)
	player.set_script(PLAYER_SCRIPT)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.text = "STORM BRIGADE  |  THE LOST KINGDOM     TARGETS: 0 / 5"
	status_label.position = Vector2(24,20)
	status_label.add_theme_font_size_override("font_size",22)
	status_label.add_theme_color_override("font_color",Color.WHITE)
	layer.add_child(status_label)
	var hint := Label.new()
	hint.text = "MOVE: JOYSTICK / WASD     LOOK: DRAG / MOUSE     FIRE     JUMP"
	hint.position = Vector2(24,54)
	hint.add_theme_font_size_override("font_size",16)
	hint.add_theme_color_override("font_color",Color.WHITE)
	layer.add_child(hint)
	var cross := Label.new()
	cross.text = "+"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-12,-20)
	cross.add_theme_font_size_override("font_size",34)
	cross.add_theme_color_override("font_color",Color.WHITE)
	layer.add_child(cross)

func _spawn_targets() -> void:
	var positions := [Vector3(-18,1.5,-47),Vector3(-7,1.5,-53),Vector3(7,1.5,-53),Vector3(18,1.5,-47),Vector3(0,1.5,-90)]
	for i in range(positions.size()):
		var target := StaticBody3D.new()
		target.name = "PracticeTarget_%d" % i
		target.position = positions[i]
		add_child(target)
		var visual := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		visual.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.92,0.2,0.16),Color(0.95,0.68,0.12),Color(0.15,0.68,0.92)][i%3]
		visual.material_override = mat
		target.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 1.05
		collision.shape = shape
		target.add_child(collision)

func register_hit(target: Node) -> void:
	if not is_instance_valid(target):
		return
	target.queue_free()
	score += 1
	if is_instance_valid(status_label):
		status_label.text = "STORM BRIGADE  |  TARGETS HIT: %d / 5" % score
