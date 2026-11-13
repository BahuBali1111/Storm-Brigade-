extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

var status_label: Label
var score := 0

const STONE := Color(0.62, 0.49, 0.34)
const DARK_STONE := Color(0.39, 0.34, 0.29)
const SAND := Color(0.77, 0.65, 0.43)
const GRASS := Color(0.28, 0.48, 0.29)

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	_spawn_targets()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.84, 0.96)
	env.ambient_light_energy = 0.85
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.35
	add_child(sun)

	# Large playable island: 140 x 140 metres.
	_box("Main battlefield", Vector3(0, -0.6, 0), Vector3(140, 1.2, 140), GRASS)
	_box("Sandy central road", Vector3(0, 0.015, 8), Vector3(13, 0.04, 116), SAND)
	_box("North road", Vector3(0, 0.02, -35), Vector3(100, 0.05, 12), SAND)

	# Outer battlefield boundary walls and corner watch posts.
	_box("North boundary", Vector3(0, 3, -69), Vector3(140, 6, 2), DARK_STONE)
	_box("South boundary", Vector3(0, 3, 69), Vector3(140, 6, 2), DARK_STONE)
	_box("West boundary", Vector3(-69, 3, 0), Vector3(2, 6, 140), DARK_STONE)
	_box("East boundary", Vector3(69, 3, 0), Vector3(2, 6, 140), DARK_STONE)
	_watch_tower(Vector3(-57, 0, -56), 11)
	_watch_tower(Vector3(57, 0, -56), 11)
	_watch_tower(Vector3(-57, 0, 56), 11)
	_watch_tower(Vector3(57, 0, 56), 11)

	# Main ruined fort in the northern half of the map.
	_build_main_fort()
	# Broken walls, columns and rubble create lanes and cover.
	_build_ruins()
	# A small ruined village on the east flank.
	_build_ruined_village()

func _build_main_fort() -> void:
	# Fort courtyard floor and thick perimeter walls, with a wide front gate.
	_box("Fort courtyard", Vector3(0, 0.12, -39), Vector3(62, 0.25, 42), Color(0.55, 0.46, 0.35))
	_box("Fort north wall", Vector3(0, 5, -60), Vector3(64, 10, 3), STONE)
	_box("Fort west wall", Vector3(-31, 4, -39), Vector3(3, 8, 42), STONE)
	_box("Fort east wall", Vector3(31, 4, -39), Vector3(3, 8, 42), STONE)
	# Front wall is split to leave a broad entrance.
	_box("Gate left wall", Vector3(-22, 4, -18), Vector3(20, 8, 3), STONE)
	_box("Gate right wall", Vector3(22, 4, -18), Vector3(20, 8, 3), STONE)
	_box("Gate top lintel", Vector3(0, 8, -18), Vector3(24, 2, 4), DARK_STONE)
	_box("Gate inner arch top", Vector3(0, 6.8, -20.2), Vector3(13, 1.2, 1), Color(0.76, 0.62, 0.43))

	_watch_tower(Vector3(-31, 0, -59), 15)
	_watch_tower(Vector3(31, 0, -59), 15)
	_watch_tower(Vector3(-31, 0, -19), 12)
	_watch_tower(Vector3(31, 0, -19), 12)

	# Inner keep and a damaged tower-like structure.
	_box("Fort keep lower", Vector3(0, 3, -47), Vector3(18, 6, 14), DARK_STONE)
	_box("Fort keep upper", Vector3(0, 8, -47), Vector3(13, 4, 11), STONE)
	_box("Keep roof", Vector3(0, 10.5, -47), Vector3(15, 1, 13), Color(0.43, 0.31, 0.24))
	_box("Keep doorway", Vector3(0, 1.6, -39.7), Vector3(3, 3.2, 0.5), Color(0.15, 0.12, 0.1))
	# Broken battlements along the keep roof.
	for i in range(5):
		_box("Keep battlement %d" % i, Vector3(-6 + i * 3, 11.5, -53), Vector3(1.8, 1.4, 1.5), STONE)

	# Courtyard cover and old stone pillars.
	_box("Courtyard broken barricade", Vector3(-13, 1.1, -31), Vector3(12, 2.2, 2), DARK_STONE)
	_box("Courtyard cover", Vector3(15, 1, -45), Vector3(9, 2, 2), STONE)
	for x in [-22, -12, 12, 22]:
		_pillar("Courtyard pillar", Vector3(x, 0, -27), 5, STONE)

func _build_ruins() -> void:
	# West ruined chapel and collapsed walls.
	_box("West ruin floor", Vector3(-43, 0.1, -5), Vector3(25, 0.2, 24), SAND)
	_box("West ruin wall A", Vector3(-54, 3, -5), Vector3(2, 6, 22), STONE)
	_box("West ruin wall B", Vector3(-43, 2.2, -16), Vector3(22, 4.4, 2), STONE)
	_box("West broken wall", Vector3(-34, 1.5, -7), Vector3(2, 3, 12), DARK_STONE)
	_pillar("Chapel column 1", Vector3(-49, 0, 5), 7, STONE)
	_pillar("Chapel column 2", Vector3(-39, 0, 5), 4, STONE)
	_box("Collapsed chapel beam", Vector3(-44, 7, 5), Vector3(14, 1.3, 2), DARK_STONE)

	# East-side broken ramparts and a ruined gatehouse.
	_box("East rampart A", Vector3(43, 2.5, 5), Vector3(2, 5, 28), STONE)
	_box("East rampart B", Vector3(53, 2, 18), Vector3(22, 4, 2), DARK_STONE)
	_box("East gatehouse left", Vector3(37, 4, -12), Vector3(3, 8, 13), STONE)
	_box("East gatehouse right", Vector3(55, 4, -12), Vector3(3, 8, 13), STONE)
	_box("East gatehouse top", Vector3(46, 8, -12), Vector3(21, 2, 14), DARK_STONE)
	_pillar("East broken pillar", Vector3(36, 0, 22), 5, STONE)

	# Southern ruins and scattered cover.
	_box("South ruin wall 1", Vector3(-25, 2, 34), Vector3(24, 4, 2), STONE)
	_box("South ruin wall 2", Vector3(25, 2.5, 42), Vector3(2, 5, 23), STONE)
	_box("South broken wall", Vector3(5, 1.4, 52), Vector3(17, 2.8, 2), DARK_STONE)
	_pillar("South fallen column", Vector3(-38, 0, 38), 3.5, STONE)
	_box("Stone rubble cover", Vector3(38, 0.8, 34), Vector3(8, 1.6, 5), DARK_STONE)

func _build_ruined_village() -> void:
	# Original low-poly abandoned village buildings with open doorways.
	_build_house(Vector3(44, 0, -39), Color(0.76, 0.56, 0.34), 10, 8)
	_build_house(Vector3(48, 0, -25), Color(0.63, 0.48, 0.35), 8, 7)
	_build_house(Vector3(-45, 0, -37), Color(0.72, 0.58, 0.4), 9, 8)
	_box("Village well", Vector3(43, 0.6, -8), Vector3(4, 1.2, 4), DARK_STONE)

func _build_house(pos: Vector3, tint: Color, width: float, depth: float) -> void:
	_box("Ruined house floor", pos + Vector3(0, 0.12, 0), Vector3(width, 0.25, depth), SAND)
	_box("House back wall", pos + Vector3(0, 2.2, -depth / 2.0), Vector3(width, 4.4, 0.8), tint)
	_box("House left wall", pos + Vector3(-width / 2.0, 2, 0), Vector3(0.8, 4, depth), tint)
	_box("House right broken wall", pos + Vector3(width / 2.0, 1.3, 1), Vector3(0.8, 2.6, depth * 0.55), tint)
	_box("House roof remains", pos + Vector3(-1, 4.5, -1), Vector3(width * 0.55, 0.8, depth), DARK_STONE)

func _watch_tower(pos: Vector3, height: float) -> void:
	_box("Fort watch tower base", pos + Vector3(0, height / 2.0, 0), Vector3(9, height, 9), STONE)
	_box("Tower top platform", pos + Vector3(0, height + 0.5, 0), Vector3(11, 1, 11), DARK_STONE)
	for x in [-4, 0, 4]:
		_box("Tower merlon", pos + Vector3(x, height + 1.5, -4), Vector3(1.5, 2, 1.5), STONE)
	_box("Tower damaged opening", pos + Vector3(0, height * 0.55, 4.56), Vector3(2.4, 3.2, 0.15), Color(0.18, 0.15, 0.12))

func _pillar(label: String, pos: Vector3, height: float, tint: Color) -> void:
	_box(label, pos + Vector3(0, height / 2.0, 0), Vector3(1.8, height, 1.8), tint)
	_box(label + " capital", pos + Vector3(0, height, 0), Vector3(2.5, 0.7, 2.5), DARK_STONE)

func _box(label: String, pos: Vector3, size: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.92
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.2, 58)
	player.set_script(PLAYER_SCRIPT)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.text = "STORM BRIGADE  |  RUINED FORT     TARGETS HIT: 0 / 5"
	status_label.position = Vector2(24, 20)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(status_label)

	var hint := Label.new()
	hint.text = "WASD: MOVE   MOUSE: LOOK   CLICK: FIRE   SPACE: JUMP"
	hint.position = Vector2(24, 54)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(hint)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -20)
	crosshair.add_theme_font_size_override("font_size", 34)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(crosshair)

func _spawn_targets() -> void:
	var positions := [
		Vector3(-12, 1.2, -29),
		Vector3(-5, 1.2, -34),
		Vector3(5, 1.2, -34),
		Vector3(13, 1.2, -29),
		Vector3(0, 1.2, -52)
	]
	for i in range(positions.size()):
		var target := StaticBody3D.new()
		target.name = "PracticeTarget_%d" % i
		target.position = positions[i]
		add_child(target)
		var mesh_instance := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.8
		mesh.height = 1.6
		mesh_instance.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.95, 0.25, 0.22), Color(0.98, 0.72, 0.16), Color(0.22, 0.72, 0.95)][i % 3]
		mesh_instance.material_override = mat
		target.add_child(mesh_instance)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.85
		collision.shape = shape
		target.add_child(collision)

func register_hit(target: Node) -> void:
	if not is_instance_valid(target):
		return
	target.queue_free()
	score += 1
	if is_instance_valid(status_label):
		status_label.text = "STORM BRIGADE  |  TARGETS HIT: %d / 5" % score
