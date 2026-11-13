extends CharacterBody3D

const SPEED := 7.0
const JUMP_VELOCITY := 5.0
const LOOK_SENSITIVITY := 0.0025
const FIRE_RANGE := 80.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D
var pitch := 0.0
var fire_cooldown := 0.0

func _ready() -> void:
	_add_collision()
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.position = Vector3(0, 0.55, 0)
	camera.current = true
	add_child(camera)
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _add_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fire()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			_rotate_view(event.relative * 1.4)
	elif event is InputEventScreenTouch and event.pressed:
		var screen_size := get_viewport().get_visible_rect().size
		if event.position.x > screen_size.x * 0.72 and event.position.y > screen_size.y * 0.55:
			_fire()

func _rotate_view(delta: Vector2) -> void:
	rotate_y(-delta.x * LOOK_SENSITIVITY)
	pitch = clampf(pitch - delta.y * LOOK_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
	if is_instance_valid(camera):
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _fire() -> void:
	if fire_cooldown > 0.0 or not is_instance_valid(camera):
		return
	fire_cooldown = 0.22
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z * FIRE_RANGE)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.has("collider"):
		var hit := result["collider"] as Node
		if hit.name.begins_with("PracticeTarget_"):
			get_parent().register_hit(hit)
