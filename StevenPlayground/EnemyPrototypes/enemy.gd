## To create an enemy using this template, duplicate the "enemy.tscn" scene and disconnect this script from the duplicate.
## Then, write a new script that extends the Enemy class and override the functions labeled [ABSTRACT] to program the enemy's 
## behavior, and attach it. Then, change the enemy's attributes by modifying the exported variables in the inspector.
## You will also have to edit the collision shape of the new enemy by editing the nodes directly. By default, the collision 
## shape is a 64x64 square. Make sure to rename the new enemy as well.
extends CharacterBody2D
class_name Enemy

#TODO: Conditions! Changes to enemy behavior based on in-game circumstances
# (i.e. if they are summoned by the player, they should attack other enemies)
# (or other more simple conditions, like slowed or poisoned)

## STATE
enum ENEMY_STATE {Idle, Aggro, Attacking, Custom}

## ENEMY ATTRIBUTES (and default values)
@export var max_hp = 10.0 # The enemy's maximum HP
@export var knockback_resist = 0.0 # How much the enemy reduces knockback distance (multiplicative)
@export var do_hurt_on_death = false # A flag for whether the enemy should perform its hurt action if the damage kills it
@export var aggro_range = 1000.0 # How close the enemy must be to its target to enter the aggro state from the idle state
@export var invuln_time = 0.5 # How long (in seconds) the enemy is invulnerable and inactive after being hurt (hurt actions still happen)

## CONTROL VARIABLES
@onready var current_hp = max_hp # The enemy's current HP
@onready var target_node = get_tree().get_first_node_in_group("player") # The enemy's current target node
var spacing_range = 24.0
var spacing_speed = 32.0
var state = ENEMY_STATE.Idle # The enemy's current state
var hurt_timer = 0.0 # A timer to track how long the enemy should be hurting
var hurting = false # A flag for whether the enemy is invulnerable due to recently being hurt
var dying = false # A flag for whether the enemy is dying
var dead = false # A flag used in the death_action() function to determine when to actually queue_free the enemy

## FUNCTIONS
## Process
# Called every frame
func _process(delta):
	# Process enemy death
	if dying:
		die(delta)
	# Process enemy hurt
	elif hurting:
		hurt_timer += delta
		if hurt_timer >= invuln_time:
			hurt_timer = 0.0
			hurting = false
	# Process default state-based behavior
	else:
		match state:
			ENEMY_STATE.Idle:
				idle(delta)
			ENEMY_STATE.Aggro:
				aggro(delta)
			ENEMY_STATE.Attacking:
				attacking(delta)
			ENEMY_STATE.Custom:
				custom(delta)

## Physics Process
## IMPORTANT: Set velocity in behavior functions, this function will just move the enemy
## ALWAYS set velocity in behavior functions, especially if you want the enemy not to move (as in, set it to zero)
## Note that the default enemy will not move unless knocked back (all behavior functions set velocity to zero)
# Called every physics frame
func _physics_process(_delta):
	move_and_slide()

## Avoid Hazards
# Stop enemies from walking into hazards
#func avoid_hazards(delta):
	## Get the destination
	#var destination = global_position + (velocity.normalized() * 48) #TODO: 48 is a magic number, should be 1.5x the size of the enemy
	##print("position: ", global_position.x, " ", global_position.y)
	##print("dest: ", destination.x, " ", destination.y)
	## Check if destination collides with attacks that harm enemies
	#var space_state = get_world_2d().direct_space_state
	#var parameters = PhysicsPointQueryParameters2D.new()
	#parameters.position = destination
	#parameters.collide_with_areas = true
	#parameters.collide_with_bodies = false
	##parameters.collision_mask = 3
	#var results = space_state.intersect_point(parameters)
	#var hazard_ahead = false
	#for area in results:
		#var attack = area.collider
		#if attack is AttackShape and (attack.targets == Weapon.TARGETS.Enemies or attack.targets == Weapon.TARGETS.Both):
			#hazard_ahead = true
			#break
	## If there is a hazard, avoid it
	##TODO: Smarter pathfinding instead of refusing to move
	#if hazard_ahead:
		#velocity = Vector2.ZERO

## Idle
# The enemy's idle behavior
func idle(delta):
	idle_action(delta)
	if global_position.distance_to(target_node.global_position) <= aggro_range:
		state = ENEMY_STATE.Aggro

## Idle Action [Abstract]
# What the enemy does while idle
func idle_action(_delta):
	velocity = Vector2.ZERO

## Aggro
# The enemy's aggro behavior
func aggro(delta):
	approach(delta)
	# Don't get too close to the exact position of another enemy (to stop enemies from fully overlapping)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != self and global_position.distance_to(enemy.global_position) <= spacing_range:
			var direction = (global_position - enemy.global_position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2(randf_range(0, 1), randf_range(0, 1))
			velocity += direction * spacing_speed
	#avoid_hazards(delta)

## Approach [Abstract]
## When overriding this function, make sure to specify a condition to transition to the attacking or custom state
# How the enemy determines when to attack the player or perform some other combat action
func approach(_delta):
	velocity = Vector2.ZERO

## Attacking
# The enemy's attacking behavior
func attacking(delta):
	attack(delta)

## Attack [Abstract]
## When overriding this function, make sure to specify a condition to transition out of the attacking state
# The enemy's attack
func attack(_delta):
	velocity = Vector2.ZERO

### Custom [Abstract]
# A function for further customization of enemy behavior
func custom(_delta):
	velocity = Vector2.ZERO

## Hurt
# Called when a damaging object (like an attack or projectile) collides with the enemy.
func hurt(damage):
	# If not invulnerable
	if not hurting and not dying:
		# Reset to idle state
		state = ENEMY_STATE.Idle
		# Process damage
		current_hp -= damage
		# If HP is <= 0, the enemy is dying
		if current_hp <= 0:
			current_hp = 0
			dying = true
		# Otherwise, the enemy is hurting
		else:
			hurting = true
		# Perform hurt action
		if not dying or do_hurt_on_death:
			hurt_action()

## Knockback
# Called when the enemy is hurt by an attack that knocks it back
func knockback(speed, origin):
	if not hurting and not dying:
		var direction = (global_position - origin).normalized()
		var distance = speed * invuln_time
		distance -= distance * knockback_resist
		velocity = direction * (distance / invuln_time)

## Hurt Action [ABSTRACT]
## If you want the enemy to move while hurting, ADD to velocity in hurt action.
## Add instead of setting so as not to interfere with knockback effects.
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
	if dying and hp > 0:
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
