## The Contact Enemy deals damage upon contact
## When creating Contact Enemies, you can override the approach() and attack() functions to determine 
## how they get to the player. Also, make sure to adjust the ContactArea if you adjust the enemy's shape.
extends Enemy
class_name ContactEnemy

## ATTRIBUTES
@export var idle_speed = 50.0 # The enemy's idle speed
@export var contact_damage = 1.0 # The enemy's contact damage
@export var contact_knockback = 0.0 # How fast contact knocks enemies back
@export var passive_contact_damage = false # Flag for whether the enemy deals contact damage when not attacking

## INSTANCE VARIABLES
var contacted = false # Flag that tracks whether the enemy is performing its contact action
var contacted_body # Tracks which body the enemy just contacted

## FUNCTIONS
## Idle Action
#TODO: Give the contact enemy some sort of idle behavior
func idle_action(_delta):
	velocity = Vector2.ZERO

## Process
# Perform contact action, or normal process
func _process(delta):
	if contacted:
		contact_action(delta)
	else:
		super._process(delta)

## Contact Action [Abstract]
# Perform some action upon contacting (and damaging) another entity
# When overriding this function, ensure to give it a condition to return to the aggro state and set contacted=false.
func contact_action(_delta):
	state = ENEMY_STATE.Aggro
	contacted = false

## On Contact Body Entered
# Hurt the contacted body, then perform an abstract contact action
func _on_contact_area_body_entered(body):
	if passive_contact_damage or state == ENEMY_STATE.Attacking:
		if (body.is_in_group("player") and target_node.is_in_group("player")) or (body.is_in_group("enemy") and target_node.is_in_group("enemy")):
			body.knockback(contact_knockback, global_position)
			body.hurt(contact_damage)
			contacted = true
			contacted_body = body
