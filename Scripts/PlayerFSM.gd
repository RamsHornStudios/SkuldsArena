extends "res://Scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("flap")
	add_state("glide")
	add_state("skid")
	call_deferred("set_state", states.idle)

func _input(event):
	if [states.idle, states.run, states.glide, states.flap, states.skid].has(state):
		if event.is_action_pressed("flap"):
			parent.animation_sprite.play("Flap")
			parent.velocity.y = parent.velocity.y + parent.flap_acceleration
			parent.is_jumping = true
			
func _input_delay_timer():
		var timer = Timer.new()
		timer.set_one_shot(true)
		timer.set_wait_time(0.2)
		timer.connect("timeout", self, "_on_timeout_complete")
		add_child(timer)
		timer.start()

func _on_timeout_complete():
	parent.ignore_input = false

func _state_logic(delta):
	parent._handle_move_input()
	parent._apply_gravity(delta)
	parent._apply_movement()
	
func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_grounded:
				if Input.is_action_pressed("flap"):
					return states.flap
			elif parent.velocity.x != 0:
				return states.run
			if Input.is_action_just_released("move_left") || Input.is_action_just_released("move_right"):
				parent.ignore_input = false
			_input_delay_timer()

		states.run:
			if !parent.is_grounded:
				if Input.is_action_pressed("flap"):
					return states.flap
				elif parent.velocity.y > 0:
					return states.glide
			elif parent.velocity.x == 0:
				return states.idle
			elif parent.last_input != parent.momentum_direction:
				if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
					return states.skid

		states.flap:
			if parent.is_grounded:
				return states.idle
			elif !Input.is_action_pressed("flap"):
				return states.glide
		states.glide:
			if parent.is_grounded:
				return states.idle
			elif Input.is_action_pressed("flap"):
				return states.flap
		states.skid:
			if !parent.is_grounded:
				if Input.is_action_pressed("flap"):
					return states.flap
				elif parent.velocity.y > 0:
					return states.glide
			elif abs(parent.velocity.x) < 10:
				parent.velocity.x = 0
				return states.idle
			if parent.last_input == parent.momentum_direction:
				return states.run
				
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.animation_sprite.play("Idle")
			if old_state == states.skid:
				parent.ignore_input = true
		states.run:
			parent.animation_sprite.play("Walking")
			parent.get_node("Body").scale.x = parent.momentum_direction
		states.flap:
			parent.animation_sprite.play("Flap")
			parent.ignore_input = false
		states.glide:
			parent.animation_sprite.play("Glide")
			parent.get_node("Body/Shield").hide()
		states.skid:
			parent.animation_sprite.play("Skid")
			parent.get_node("Body").scale.x = parent.momentum_direction

func _exit_state(old_state, new_state):
	match old_state:
		states.glide:
			parent.get_node("Body/Shield").show()
