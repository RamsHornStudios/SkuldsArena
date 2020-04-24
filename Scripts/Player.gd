extends KinematicBody2D

const UP = Vector2(0, -1)
const SLOPE_STOP_THRESHOLD = 64.0

var velocity = Vector2()
var max_speed = 6 * Globals.UNIT_SIZE
var gravity
#var max_jump_velocity
#var min_jump_velocity
var is_grounded
var is_jumping = false
var input_direction
var last_input
var momentum_direction
var acceleration = 12
var flap_acceleration = -3.5 * Globals.UNIT_SIZE
var ignore_input = false

var max_jump_height = 1.25 * Globals.UNIT_SIZE
var min_jump_height = 0.25 * Globals.UNIT_SIZE
var jump_duration = 0.5

onready var screen_size = get_viewport_rect().size
onready var animation_sprite = get_node("Body/AnimatedSprite")

func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
#	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
#	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	

func _apply_gravity(delta):
	# Apply gravity.
	velocity.y += gravity * delta
	
func _apply_movement():
	# Set is_jumping to false if player is jumping and moving downward.
	if is_jumping && velocity.y >= 0:
		is_jumping = false
	
	var snap = Vector2.DOWN * 32 if !is_jumping else Vector2.ZERO
	
	if input_direction == 0 && abs(velocity.x) < SLOPE_STOP_THRESHOLD:
		velocity.x = 0
		
	var stop_on_slope = true if get_floor_velocity().x == 0 else false
	
	velocity = move_and_slide_with_snap(velocity, snap, UP, stop_on_slope)
	position.x = wrapf(position.x, 0, screen_size.x)
	
	is_grounded = is_on_floor()
	
	animation_sprite.frames.set_animation_speed("Walking", abs(velocity.x)/14 + 2)
	
	if velocity.x != 0:
#		print("moment ", momentum_direction)
		if velocity.x > 0:
			momentum_direction = 1
		elif velocity.x < 0:
			momentum_direction = -1

func _handle_move_input():
	var input_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	# velocity.x = lerp(velocity.x, max_speed * input_direction, 0.2)
#	print("input_dir ", input_direction
	print ("ignore input ", ignore_input)
	if !ignore_input:
		if input_direction != 0:
			last_input = input_direction
	#		print("last input ", last_input)
			if !is_grounded:
				$Body.scale.x = input_direction
			if abs(velocity.x) > max_speed:
				velocity.x = clamp(velocity.x, -max_speed, max_speed)
			else:
				velocity.x = velocity.x + acceleration * input_direction