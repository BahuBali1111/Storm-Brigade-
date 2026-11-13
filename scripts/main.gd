extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

var status_label: Label
var score := 0

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
	env.ambient_light_color = Color(0.72, 0.82, 0.95)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.25
	add_child(sun)

	_box("Arena Floor", Vector3(0, -0.5, 0), Vector3(42, 1, 42), Color(0.23, 0.55, 0.42))
	_box("Back Wall", Vector3(0, 2, -20), Vector3(42, 4, 1), Color(0.22, 0.39, 0.72))
	_box("Left Wall", Vector3(-20, 2, 0), Vector3(1, 4, 42), Color(0.95, 0.61, 0.22))
	_box("Right Wall", Vector3(20, 2, 0), Vector3(1, 4, 42), Color(0.95, 0.61, 0.22))
	_box("Blue Cover", Vector3(-6, 1, -5), Vector3(3, 2, 2), Color(0.18, 0.52, 0.88))
	_box("Orange Cover", Vector3(6, 1, -9), Vector3(3, 2, 2), Color(0.95, 0.38, 0.16))
	_box("Center Platform", Vector3(0, 0.25, -12), Vector3(7, 0.5, 2), Color(0.75, 0.77, 0.28))

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
	mat.roughness = 0.85
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
	player.position = Vector3(0, 1.2, 8)
	player.set_script(PLAYER_SCRIPT)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.text = "STORM BRIGADE  |  TRAINING ARENA     TARGETS HIT: 0 / 5"
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
	for i in range(5):
		var target := StaticBody3D.new()
		target.name = "PracticeTarget_%d" % i
		target.position = Vector3(-8 + i * 4, 1.15, -13)
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
