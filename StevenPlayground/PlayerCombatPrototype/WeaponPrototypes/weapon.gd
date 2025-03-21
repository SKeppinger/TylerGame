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
extends Node2D
class_name Weapon

## WEAPON ENUMS
enum WEAPON_TYPE {Melee, Ranged, Magic} # The type of the weapon (for grouping purposes only)
enum ORIGIN_TYPE {Attacker, Mouse, Point} # Whether the attack originates from the attacker, the mouse (player), or a point (enemy)
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
@export var knockback: float # How much the attack knocks enemies back from the origin
@export var attack_shape: Area2D # The shape of the attack

## SPECIFIC WEAPON ATTRIBUTES
@export var projectile_pierces: int # How many targets the projectile can pierce before being destroyed
@export var linger_time: float # How long the attack lingers
@export var point_range: float # How far the mouse/point attack can be spawned from the attacker

## FUNCTIONS
## Attack
# Execute the weapon's attack (attacker will pass in "self" when calling this function)
func attack(attacker):
	pass
