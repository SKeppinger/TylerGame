extends CharacterBody2D

## PLAYER ATTRIBUTES
@export var movement_speed: float # The player's movement speed
@export var acceleration: float # The player's acceleration
@export var friction: float # The player's friction
@export var max_hp: float # The player's maximum HP
@export var knockback_resist: float # How much the player reduces knockback distance (multiplicative)
@export var invuln_time: float # How long the player remains invulnerable due to recently being hurt
@export var equipped_weapon: Weapon # The player's currently equipped weapon

## CONTROL VARIABLES
@onready var current_hp = max_hp # The player's current HP
var attacking = false # Flag for whether the player is attacking
var hurting = false # Flag for whether the player is invulnerable due to recently being hurt
var dying = false # Flag for whether the player is dying
var hurt_timer = 0.0 # A timer to track how long the player should be hurting
var attack_timer = 0.0 # Timer for the player's attack
var attack_cooldown_timer = 0.0 # Timer for the player's attack cooldown
var target # Tracks the location of the mouse for attacks (all attackers must have target variable)

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
		print("Player attacked")
		target = get_global_mouse_position()
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
	if not hurting and not dying:
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
		
		# Check for attacks
		get_combat_input()
	
	# Move and slide
	move_and_slide()

## Hurt
# Called when a damaging object (like an attack or projectile) collides with the player.
func hurt(damage):
	# If not invulnerable
	if not hurting and not dying:
		# Process damage
		current_hp -= damage
		# If HP is <= 0, the player is dying
		if current_hp <= 0:
			print("Player died!")
			current_hp = 0
			dying = true
		# Otherwise, the player is hurting
		else:
			hurting = true

## Knockback
# Called when the player is hurt by an attack that knocks it back
func knockback(speed, origin):
	if not hurting and not dying:
		var direction = (global_position - origin).normalized()
		var distance = speed * invuln_time
		distance -= distance * knockback_resist
		velocity = direction * (distance / invuln_time)

## Process
# Handle timers and other internal control
func _process(delta):
	# Process player death
	if dying:
		pass #TODO: Account for animations, game over screen, etc
	# Process player hurt
	elif hurting:
		hurt_timer += delta
		if hurt_timer >= invuln_time:
			hurt_timer = 0.0
			hurting = false
	
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
