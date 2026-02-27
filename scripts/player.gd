extends CharacterBody2D


const SPEED = 10.0
const MAX_SPEED = 200.0
const JUMP_VELOCITY = -150.0
const GRAVITY = 300.0

func _physics_process(delta: float) -> void:
	# handle gravity with low terminal velocity
	if not is_on_floor() and velocity.y < MAX_SPEED*0.5:
		velocity.y += GRAVITY * delta
		
	# handle movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction and abs(velocity.x) < MAX_SPEED:
		velocity.x += SPEED * direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
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
				velocity.x += MAX_SPEED*2
				
	
	move_and_slide()
	
	
	
