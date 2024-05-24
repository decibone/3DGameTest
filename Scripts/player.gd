extends CharacterBody3D

const SPEED = 3.0
const SPRINT_MULTIPLIER = 1.5
const JUMP_VELOCITY = 7.0
const NORMAL_FOV = 70.0
const SPRINT_FOV = 85.0
const ZOOM_SPEED = 10.0

const BOB_FREQ = 3.0
const BOB_AMP = 0.08
var t_bob = 0.0

var gravity = 20
@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera
var flashlight_on: bool = false

const FALL_THRESHOLD = -50.0 # Threshold below which the player is considered to have fallen off the map

func _ready():
	PlayerAutoload.player = self
	$Neck/Camera/Flashlight/SpotLight3D.visible = false

func _input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		neck.rotate_y(-event.relative.x * 0.01)
		camera.rotate_x(-event.relative.y * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
	elif event.is_action_pressed("quit"):
		get_tree().quit()
	elif event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("flashlight"):
		flashlight_on = !flashlight_on
		$Neck/Camera/Flashlight/SpotLight3D.visible = flashlight_on
		$Sounds/Flashlight.play_sfx()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$Sounds/Jump.play_sfx()

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_moving = input_dir != Vector2.ZERO
	var is_sprinting = Input.is_action_pressed("sprint") and is_moving
	var current_speed = SPEED * (SPRINT_MULTIPLIER if is_sprinting else 1.0)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	move_and_slide()

	if direction != Vector3.ZERO and is_on_floor():
		var timer_interval = 0.4 if is_sprinting else 0.7
		if $Sounds/Timer.time_left <= 0:
			$Sounds/Walk.pitch_scale = randf_range(1.2, 1.0)
			$Sounds/Walk.play_sfx()
			$Sounds/Timer.start(timer_interval)

	camera.fov = lerp(camera.fov, SPRINT_FOV if is_sprinting else NORMAL_FOV, ZOOM_SPEED * delta)

	_check_fall_off_map()

func _headbob(time) -> Vector3:
	return Vector3(cos(time * BOB_FREQ / 2) * BOB_AMP, sin(time * BOB_FREQ) * BOB_AMP, 0.0)

func _check_fall_off_map():
	if global_transform.origin.y < FALL_THRESHOLD:
		_restart_scene()

func _restart_scene():
	var current_scene = get_tree().current_scene
	get_tree().reload_current_scene()
