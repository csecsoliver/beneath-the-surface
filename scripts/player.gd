extends CharacterBody2D


const SPEED = 10.0
const MAX_SPEED = 200.0 # sideways. double of terminal velocity
const JUMP_VELOCITY = -150.0
const GRAVITY = 300.0

func _physics_process(delta: float) -> void:
	
	if abs(velocity.y) < 20:
		%PlayerSprite.animation = "idle"
		
	
	# handle gravity with low terminal velocity
	if not is_on_floor() and velocity.y < MAX_SPEED*0.5:
		velocity.y += GRAVITY * delta
		
	# handle movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction and abs(velocity.x) < MAX_SPEED:
		velocity.x += SPEED * direction
	else:
		# friction sideways
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if direction:
		%PlayerSprite.animation = "swim"
	
	if Input.is_action_pressed("move_down") and velocity.y < MAX_SPEED: # increase descent speed over terminal velocity
		velocity.y += SPEED
	elif velocity.y > MAX_SPEED*0.5: # slow down descent to terminal velocity
		velocity.y = move_toward(velocity.y, MAX_SPEED*0.5, SPEED)
	if Input.is_action_pressed("move_down"):
		%PlayerSprite.animation = "down"
	# Handle jump.
	if Input.is_action_just_pressed("move_up"):
		velocity.y = JUMP_VELOCITY
		# make it go faster if jumping
		if direction and abs(velocity.x) < MAX_SPEED * 3:
			velocity.x += SPEED*5 * direction
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		if abs(normal.x) > 0.5:
			if normal.x > 0 and Input.is_action_just_pressed("move_kick"):
				velocity.x += MAX_SPEED*2
			elif Input.is_action_just_pressed("move_kick"):
				velocity.x -= MAX_SPEED*2
	
	if velocity.y > 20:
		%PlayerSprite.animation = "down"
	if velocity.y < -20:
		%PlayerSprite.animation = "up"
	if direction > 0:
		%PlayerSprite.flip_h = true
	elif direction < 0:
		%PlayerSprite.flip_h = false
	
	
	
	move_and_slide()
	
	
	
