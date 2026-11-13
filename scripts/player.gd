extends CharacterBody3D

const SPEED := 7.0
const JUMP_VELOCITY := 5.0
const LOOK_SENSITIVITY := 0.003
const FIRE_RANGE := 100.0
const JOYSTICK_RADIUS := 82.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D
var pitch := 0.0
var fire_cooldown := 0.0
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false
var fire_requested := false
var joystick_base: Control
var joystick_knob: Control

func _ready() -> void:
	_add_collision()
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.position = Vector3(0, 0.55, 0)
	camera.current = true
	add_child(camera)
	_build_mobile_controls()
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

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControls"
	add_child(layer)

	joystick_base = ColorRect.new()
	joystick_base.color = Color(0.08, 0.1, 0.13, 0.34)
	joystick_base.size = Vector2(150, 150)
	joystick_base.position = Vector2(28, -178)
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joystick_base)

	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.8, 0.86, 0.95, 0.55)
	joystick_knob.size = Vector2(58, 58)
	joystick_knob.position = Vector2(46, 46)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

	var fire_button := _make_button(layer, "FIRE", Vector2(-132, -170), Vector2(108, 70))
	fire_button.pressed.connect(func(): fire_requested = true)
	var jump_button := _make_button(layer, "JUMP", Vector2(-132, -88), Vector2(108, 62))
	jump_button.pressed.connect(func(): jump_requested = true)

func _make_button(parent: Control, label: String, offset: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = label
	button.size = size
	button.position = offset
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.add_theme_font_size_override("font_size", 18)
	button.modulate = Color(1, 1, 1, 0.82)
	parent.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fire()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventScreenTouch:
		if event.pressed:
			var w := get_viewport().get_visible_rect().size.x
			if event.position.x < w * 0.42 and move_touch_id == -1:
				move_touch_id = event.index
				move_origin = event.position
				_update_joystick(Vector2.ZERO)
			elif look_touch_id == -1:
				look_touch_id = event.index
		else:
			if event.index == move_touch_id:
				move_touch_id = -1
				move_vector = Vector2.ZERO
				_update_joystick(Vector2.ZERO)
			if event.index == look_touch_id:
				look_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch_id:
			var delta: Vector2 = event.position - move_origin
			move_vector = (delta / JOYSTICK_RADIUS).limit_length(1.0)
			_update_joystick(move_vector)
		elif event.index == look_touch_id:
			_rotate_view(event.relative * 1.2)

func _update_joystick(value: Vector2) -> void:
	if is_instance_valid(joystick_knob):
		joystick_knob.position = Vector2(46, 46) + value * 42.0

func _rotate_view(delta: Vector2) -> void:
	rotate_y(-delta.x * LOOK_SENSITIVITY)
	pitch = clampf(pitch - delta.y * LOOK_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
	if is_instance_valid(camera):
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif jump_requested or Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	jump_requested = false
	if fire_requested:
		_fire()
		fire_requested = false

	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := move_vector if move_vector.length() > 0.05 else keyboard
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
