extends CharacterBody3D

const SPEED = 3.0
const SPRINT_MULTIPLIER = 1.5
const JUMP_VELOCITY = 7.0
const NORMAL_FOV = 70.0
const SPRINT_FOV = 85.0
const ZOOM_SPEED = 10.0

# Bob variables
const BOB_FREQ = 3.0
const BOB_AMP = 0.08
var t_bob =0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20
@onready var neck := $Neck
@onready var camera := $Neck/Camera
var flashlight_on:bool = true

func _ready():
	PlayerAutoload.player = self

func _input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		neck.rotate_y(-event.relative.x * 0.01)
		camera.rotate_x(-event.relative.y * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event.is_action_pressed("flashlight"):
		flashlight_on = !flashlight_on
		$Neck/Camera/Flashlight/SpotLight3D.visible = flashlight_on
		$Sounds/Flashlight.play_sfx()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$Sounds/Jump.play_sfx()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Determine if the player is sprinting.
	var is_moving = input_dir != Vector2.ZERO
	var is_sprinting = Input.is_action_pressed("sprint") and is_moving

	var current_speed = SPEED * (SPRINT_MULTIPLIER if is_sprinting else 1.0)

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	#Head bob
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	move_and_slide()
	if direction != Vector3() and is_on_floor() and !is_sprinting:
		if $Sounds/Timer.time_left <= 0:
			$Sounds/Walk.pitch_scale = randf_range(1.2,1)
			$Sounds/Walk.play_sfx()
			$Sounds/Timer.start(0.7)
	elif direction != Vector3() and is_on_floor() and is_sprinting:
		if $Sounds/Timer.time_left <= 0:
			$Sounds/Walk.pitch_scale = randf_range(1.2,1)
			$Sounds/Walk.play_sfx()
			$Sounds/Timer.start(0.4)

	# Handle camera zoom when sprinting
	if is_sprinting:
		camera.fov = lerp(camera.fov, SPRINT_FOV, ZOOM_SPEED * delta)
	else:
		camera.fov = lerp(camera.fov, NORMAL_FOV, ZOOM_SPEED * delta)
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


