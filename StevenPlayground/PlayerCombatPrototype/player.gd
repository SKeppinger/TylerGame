extends CharacterBody2D

## PLAYER ATTRIBUTES
@export var movement_speed: float # The player's movement speed
@export var acceleration: float # The player's acceleration
@export var friction: float # The player's friction
@export var max_hp: float # The player's maximum HP

## CONTROL VARIABLES
var current_hp = max_hp # The player's current HP
var attacking = false # Flag for whether the player is attacking

## FUNCTIONS
## Get Move Input
# Receive movement input from the player
func get_move_input():
	var input = Vector2()
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	return input

## Get Combat Input
# Receive combat input from the player
func get_combat_input():
	pass

## Physics Process
# Handle the player movement
func _physics_process(delta):
	# If the player is not attacking, process movement normally
	if not attacking:
		var direction = get_move_input()
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * movement_speed, acceleration)
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
	# Stop movement while attacking
	else:
		velocity = Vector2.ZERO
	
	# Move and slide
	move_and_slide()
