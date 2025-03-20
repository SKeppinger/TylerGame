extends CharacterBody2D

## PLAYER ATTRIBUTES
@export var movement_speed: float # The player's movement speed
@export var acceleration: float # The player's acceleration
@export var friction: float # The player's friction
@export var max_hp: float # The player's maximum HP
@export var equipped_weapon: Weapon # The player's currently equipped weapon

## CONTROL VARIABLES
var current_hp = max_hp # The player's current HP
var attacking = false # Flag for whether the player is attacking
var attack_timer = 0.0 # Timer for the player's attack
var attack_cooldown_timer = 0.0 # Timer for the player's attack cooldown

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
	# If the player inputs a valid attack (i.e. it is off cooldown), then attack
	if Input.is_action_just_pressed("attack") and not attacking and attack_cooldown_timer <= 0:
		attack()

## Attack
# Called when the player begins their attack (the attack is actually executed in physics_process)
func attack():
	attacking = true
	attack_timer = equipped_weapon.attack_time
	attack_cooldown_timer = equipped_weapon.cooldown

## Physics Process
# Handle the physical player actions (like movement and attacks)
func _physics_process(_delta):
	# If the player is not attacking, process movement normally
	if not attacking:
		var direction = get_move_input()
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * movement_speed, acceleration)
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
	# Stop movement while attacking (and fulfill the attack)
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			equipped_weapon.attack(self) # Pass in the attacker (i.e. self)
			attacking = false
	
	# Move and slide
	move_and_slide()

## Process
# Handle timers and other internal control
func _process(delta):
	# Attack timer
	if attack_timer > 0:
		attack_timer -= delta
	if attack_timer < 0:
		attack_timer = 0

	# Attack cooldown timer
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if attack_cooldown_timer < 0:
		attack_cooldown_timer = 0
