## I'll make this description more formal later, but for now I'm going to just write out my plan.
## My idea is to have the weapon "spawn" an attack shape wherever it is meant to appear (originating
## from the attacker in the case of a melee/ranged attack, or something like a fireball could be spawned
## at some point away from the attacker). Then, this script will also give the attack shape its behavior
## (should it flicker like a melee attack? fly like a projectile? maybe it creates a lingering damaging
## area?). All of that functionality should be localized to this script.

## Theoretically, then, we can create any weapon we want by filling out this script's attribute parameters 
## and creating the AttackShape node (you can find the default one in this folder). Additionally, I'm going 
## to do my best to program defensively for possible abilities that may alter weapon stats. Stuff like damage 
## is pretty straightforward, but say we want an ability to caused ranged projectiles to pierce more than one 
## target? I might choose (will choose) to have an integer "pierces" to which that hypothetical ability can 
## externally give a +1 (or however many).

## HOW TO MAKE A WEAPON USING THIS SCRIPT:
## Duplicate weapon.tscn and attack_shape.tscn into your directory
## Rename both if you wish
## Set the exported attributes of the weapon to your desired values
## Give the attack shape a collision shape; create it as though the attacker is facing to the right
## Set the weapon's attack shape to your new attack shape
extends Node2D
class_name Weapon

## WEAPON ENUMS
enum WEAPON_TYPE {Melee, Ranged, Magic} # The type of the weapon (for grouping purposes only)
enum ORIGIN_TYPE {Attacker, Point} # Whether the attack originates from the attacker or a point
enum BEHAVIOR {Flicker, Projectile, Linger, Custom} # How the attack should behave once it is spawned
enum TARGETS {Enemies, Player, Both} # Who the attack hurts

## BASIC WEAPON ATTRIBUTES
@export var weapon_type: WEAPON_TYPE # Indicator for the weapon type
@export var origin_type: ORIGIN_TYPE # Indicator for the origin type
@export var behavior: BEHAVIOR # Indicator for the behavior
@export var targets: TARGETS # Indicator for the targets
@export var attack_damage: float # How much damage the attack deals
@export var attack_time: float # How long it takes to perform the attack
@export var cooldown: float # How long before the attack can be used again
@export var knockback: float # How fast the attack knocks enemies back from the origin
@export var attack_shape: PackedScene # The shape of the attack

## SPECIFIC WEAPON ATTRIBUTES
@export var projectile_pierces: int # How many targets the projectile can pierce before being destroyed
@export var projectile_speed: float # How fast the projectile travels
@export var linger_time: float # How long the attack lingers
@export var linger_ticks: int # How many times the attack deals damage
@export var point_range: float # How far the mouse/point attack can be spawned from the attacker
@export var enemy_attacker_range: float # How close an enemy must be to use an attacker-origin (non-projectile) attack (accessed by Equipped Enemy)

## FUNCTIONS
## Attack
# Execute the weapon's attack (attacker will pass in "self" when calling this function)
func attack(attacker):
	# Instantiate the attack shape
	var atk = attack_shape.instantiate()
	# Set its instance variables
	atk.attacker = attacker
	atk.damage = attack_damage
	atk.knockback = knockback
	atk.behavior = behavior
	atk.targets = targets
	atk.pierces = projectile_pierces
	atk.projectile_speed = projectile_speed
	atk.linger_time = linger_time
	atk.linger_ticks = linger_ticks
	# Spawn the attack
	get_tree().root.add_child(atk)
	# Based on the weapon's origin, set the attack's position
	match origin_type:
		ORIGIN_TYPE.Attacker:
			atk.global_position = attacker.global_position
		ORIGIN_TYPE.Point:
			if attacker.position.distance_to(attacker.target) <= point_range:
				atk.global_position = attacker.target
			else:
				atk.global_position = attacker.global_position + (attacker.global_position.direction_to(attacker.target) * point_range)
	# Rotate the attack toward the target
	atk.look_at(attacker.target)
