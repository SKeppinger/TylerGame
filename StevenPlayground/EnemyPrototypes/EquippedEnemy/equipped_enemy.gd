## The Equipped Enemy uses a Weapon to attack, like the player would
extends Enemy
class_name EquippedEnemy

## ATTRIBUTES
@export var idle_speed = 50.0 # The enemy's idle speed
@export var chase_speed = 200.0 # The enemy's chase speed
@export var equipped_weapon: Weapon # The enemy's equipped weapon

## INSTANCE VARIABLES
@onready var target = target_node.global_position # Weapons require targets to be positions, not nodes
var attack_range = 0.0 # The enemy's attack range
var attack_timer = 0.0 # Timer for the attack
var attack_cooldown_timer = 0.0 # Timer for the attack cooldown

## FUNCTIONS
## READY
# Procedurally determine the enemy's attack range based on its equipped weapon
func _ready():
	match equipped_weapon.origin_type:
		Weapon.ORIGIN_TYPE.Attacker:
			match equipped_weapon.behavior:
				Weapon.BEHAVIOR.Projectile:
					# Set the attack range equal to some function of the projectile speed
					#TODO: Find a balanced function
					attack_range = equipped_weapon.projectile_speed # Will fire when the projectile will take 1 sec to reach target
				_: # Anything other than projectile:
					attack_range = equipped_weapon.enemy_attacker_range
		Weapon.ORIGIN_TYPE.Point:
			attack_range = equipped_weapon.point_range * 0.75 # Use 75% here so the enemy doesn't constantly attack at its maximum range

## IDLE ACTION
#TODO: Give the equipped enemy some sort of idle behavior
func idle_action(_delta):
	# Reset all timers when placed into idle state
	attack_timer = 0.0
	attack_cooldown_timer = 0.0
	velocity = Vector2.ZERO

## APPROACH
# The equipped enemy approaches its target until within attack range
func approach(delta):
	# Track the attack cooldown
	if attack_cooldown_timer > 0:
		velocity = Vector2.ZERO # Don't move if on attack cooldown
		attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0:
		# Update the target position
		target = target_node.global_position
		if global_position.distance_to(target) <= attack_range:
			state = ENEMY_STATE.Attacking
		else:
			var direction = global_position.direction_to(target)
			velocity = chase_speed * direction

## ATTACK
# Use the weapon to attack
func attack(delta):
	velocity = Vector2.ZERO
	attack_timer += delta
	if attack_timer >= equipped_weapon.attack_time:
		attack_timer = 0.0
		# Always make sure the attack target is correct
		if equipped_weapon.targets != Weapon.TARGETS.Both:
			if target_node.is_in_group("player"):
				equipped_weapon.targets = Weapon.TARGETS.Player
			elif target_node.is_in_group("enemy"):
				equipped_weapon.targets = Weapon.TARGETS.Enemies
		# Attack
		equipped_weapon.attack(self) # Pass in the attacker (i.e. self)
		attack_cooldown_timer = equipped_weapon.cooldown
		# Return to aggro state
		state = ENEMY_STATE.Aggro
