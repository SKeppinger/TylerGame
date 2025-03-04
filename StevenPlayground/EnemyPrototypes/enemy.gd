## To create an enemy using this template, duplicate the "enemy.tscn" scene and disconnect this script from the duplicate.
## Then, write a new script that extends the Enemy class and override the functions labeled [ABSTRACT] to program the enemy's 
## behavior, and attach it. Then, change the enemy's attributes by modifying the exported variables in the inspector.
## You will also have to edit the collision shape and hurtbox of the new enemy by editing the nodes directly. By default,
## the hurtbox is a 20x20 square and the collision shape is a 19x19 square. Make sure to rename the new enemy as well.
extends CharacterBody2D
class_name Enemy

## ENEMY ATTRIBUTES
@export var max_hp: float # The enemy's maximum HP
@export var do_hurt_on_death: bool # A flag for whether the enemy should perform its hurt action if the damage kills it

## CONTROL VARIABLES
var current_hp = max_hp # The enemy's current HP
var dying = false # A flag for whether the enemy is dying
var dead = false # A flag used in the death_action() function to determine when to actually queue_free the enemy

## FUNCTIONS
## Process
# Called every frame
func _process(delta):
	# Process enemy death
	if dying:
		die(delta)
	## TODO: else, state-based behavior

## Hurt
# Called when a damaging object (like an attack or projectile) collides with the enemy.
func hurt(damage):
	# Process damage
	current_hp -= damage
	# Perform hurt action
	if current_hp > 0 or do_hurt_on_death:
		hurt_action()
	# If HP is <= 0, the enemy is dying
	if current_hp <= 0:
		current_hp = 0
		dying = true

## Hurt Action [ABSTRACT]
# Called every time the enemy is hurt
func hurt_action():
	pass

## Heal
# Can be used to heal the enemy by the given amount (up to its maximum HP)
func heal(hp):
	# Add HP to the enemy's current total
	current_hp += hp
	# But only up to its maximum HP
	if current_hp > max_hp:
		current_hp = max_hp
	# If the enemy healed at all, set the "dying" flag to false
	if hp > 0:
		dying = false

## Die
# Called every frame while the "dying" flag is true
func die(delta):
	# Perform death action
	death_action(delta)
	# Delete the enemy node if done with action
	if dead:
		queue_free()

## Death Action [ABSTRACT]
## When overriding this function, make sure to specify a condition for when to set dead = true, to ensure the enemy actually
## ends up getting removed from the scene. (If you want to resurrect the enemy, use the heal() function).
# Called every frame while the "dying" flag is true
func death_action(_delta):
	dead = true

## SIGNALS
## Hurtbox Signal
# If a body that is damaging to the enemy enters the hurtbox, call the hurt() function
func _on_hurtbox_body_entered(body):
	## TODO: I'll make a class for enemy damagers to avoid having to manually add a "damage" variable to every one we make.
	## For now, though, I'll just use this group.
	if body.is_in_group("damages_enemies"):
		hurt(body.damage)
		## TODO: For now, we can just kill the damager, but eventually we might want the aforementioned class to have an
		## "on_hit" function to determine what happens to it when it hits an enemy.
		body.queue_free()
