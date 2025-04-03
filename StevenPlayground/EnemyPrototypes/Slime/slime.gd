extends ContactEnemy
class_name Slime

## ATTRIBUTES
@export var hop_range = 100.0 # How far the slime hops when approaching
@export var hop_start_time = 0.25 # How long it takes for the slime to start the hop
@export var hop_time = 0.25 # How many seconds it takes for the slime to perform the hop
@export var hop_cooldown = 1.0 # How long after a hop before the slime can hop again
@export var jump_range = 300.0 # How close the slime must be to initiate a jump at the player (and how far it jumps)
@export var jump_start_time = 0.75 # How long it takes for the slime to start the jump
@export var jump_time = 0.5 # How many seconds it takes for the slime to perform the jump
@export var jump_cooldown = 1.5 # How long after a jump before the slime can jump again
@export var recovery_time = 0.5 # How long the slime knocks itself back from its target
@export var self_knockback = 200.0 # How fast the slime knocks itself back from its target

## INSTANCE VARIABLES
var jump_direction # Tracks the direction the player was in when the slime initiated the jump
var hopping = false # Flag for whether the slime is hopping
var hop_start_timer = 0.0 # Timer for how long the slime has been starting the hop
var hop_timer = 0.0 # Timer for how long the slime has been hopping
var hop_cooldown_timer = hop_cooldown # Timer for the hop cooldown
var jumping = false # Flag for whether the slime is jumping
var jump_start_timer = 0.0 # Timer for how long the slime has been starting the jump
var jump_timer = 0.0 # Timer for how long the slime has been jumping
var jump_cooldown_timer = jump_cooldown # Timer for the jump cooldown
var recovery_timer = 0.0 # Timer for how long the slime has been recovering
var contact_point # Tracks the point where the slime contacted another body

## FUNCTIONS
## Idle Action
# Hop in a random direction

## Approach
# Hop toward the player
func approach(delta):
	# Check if the slime should switch to attack state
	if not hopping and global_position.distance_to(target_node.global_position) <= jump_range:
		state = ENEMY_STATE.Attacking
		# Reset hop cooldown
		hop_cooldown_timer = 0.0
		# Do not continue
		return
	# Hop
	if not hopping and hop_cooldown_timer >= hop_cooldown:
		hop_cooldown_timer = 0.0
		jump_direction = global_position.direction_to(target_node.global_position)
		hopping = true
	# Update hop timer (or hop start timer)
	elif hopping:
		if hop_start_timer < hop_start_time:
			velocity = Vector2.ZERO
			hop_start_timer += delta
		if hop_start_timer >= hop_start_time:
			hop_timer += delta
			velocity = jump_direction * (hop_range / hop_time)
			if hop_timer >= hop_time:
				velocity = Vector2.ZERO
				hop_timer = 0.0
				hopping = false
	# Update hop cooldown timer
	else:
		hop_cooldown_timer += delta

## Attack
# Jump toward the player
func attack(delta):
	# Check if the slime should return to aggro state
	if not jumping and global_position.distance_to(target_node.global_position) > jump_range:
		state = ENEMY_STATE.Aggro
		# Reset jump cooldown
		jump_cooldown_timer = jump_cooldown
		# Do not continue
		return
	# Jump
	if not jumping and jump_cooldown_timer >= jump_cooldown:
		jump_cooldown_timer = 0.0
		jump_direction = global_position.direction_to(target_node.global_position)
		jumping = true
	# Update jump timer (or jump start timer)
	elif jumping:
		if jump_start_timer < jump_start_time:
			velocity = Vector2.ZERO
			jump_start_timer += delta
		if jump_start_timer >= jump_start_time:
			velocity = jump_direction * (jump_range / jump_time)
			jump_timer += delta
			if jump_timer >= jump_time:
				velocity = Vector2.ZERO
				jump_timer = 0.0
				jump_start_timer = 0.0
				jumping = false
	# Update jump cooldown timer
	else:
		jump_cooldown_timer += delta

## Contact Action
# Interrupt all jumps and hops, apply self-knockback
func contact_action(delta):
	# If this is the first call (i.e. contact just happened)
	if recovery_timer == 0.0:
		# Reset values
		reset()
		# Set contact point
		contact_point = contacted_body.global_position
	# Apply self-knockback
	velocity = -1 * global_position.direction_to(contact_point) * self_knockback
	recovery_timer += delta
	if recovery_timer >= recovery_time:
		velocity = Vector2.ZERO
		recovery_timer = 0.0
		state = ENEMY_STATE.Aggro
		contacted = false

## Hurt Action
# Interrupt all jumps and hops
func hurt_action():
	reset()

## Reset
# Process an interruption (contact)
func reset():
	# Reset values
	jumping = false
	hopping = false
	hop_start_timer = 0.0
	hop_timer = 0.0
	hop_cooldown_timer = 0.0
	jump_start_timer = 0.0
	jump_timer = 0.0
	jump_cooldown_timer = jump_cooldown
