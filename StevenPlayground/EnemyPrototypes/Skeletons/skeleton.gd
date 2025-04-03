extends EquippedEnemy
class_name Skeleton

## ATTRIBUTES
@export var bone_pile_duration = 2.0 # How many seconds a bone pile lasts before the skeleton finally dies
@export var reconstruct_range = 100.0 # How close the bone pile must be for the skeleton to reconstruct
@export var reconstruct_time = 1.5 # How many seconds it takes for the skeleton to reconstruct
@export var reconstruct_hp_multiplier = 0.75 # Percentage of maximum HP skeleton recovers when reconstructing

## INSTANCE VARIABLES
var is_bone_pile = false # Flag for whether the dying skeleton is currently acting as a bone pile
var reconstructing = false # Flag for whether the skeleton is reconstructing
var pile_timer = 0.0 # Tracks how long the bone pile has been active
var reconstruct_timer = 0.0 # Tracks how long the reconstruction has been happening

## FUNCTIONS
## Death Action
# Skeletons will leave behind bone piles when they die; if another skeleton dies near the bone pile,
# the two of them reconstruct back into the skeleton that died second
func death_action(delta):
	velocity = Vector2.ZERO
	# If not reconstructing and not a bone pile:
	if not reconstructing and not is_bone_pile:
		# Check for a nearby bone pile
		var bone_source = null
		for pile in get_tree().get_nodes_in_group("bone_pile"):
			if global_position.distance_to(pile.global_position) <= reconstruct_range:
				bone_source = pile
				break
		# If there is no nearby bone pile, become a bone pile
		if not bone_source:
			is_bone_pile = true
			add_to_group("bone_pile")
			remove_from_group("enemy")
		# Otherwise, destroy the nearby pile and start reconstructing
		else:
			bone_source.queue_free()
			reconstructing = true
	# Process reconstruction
	elif reconstructing:
		reconstruct_timer += delta
		if reconstruct_timer >= reconstruct_time:
			reconstruct_timer = 0.0
			reconstructing = false
			heal(max_hp * reconstruct_hp_multiplier)
	# Determine if the pile should disintegrate
	else:
		pile_timer += delta
		if pile_timer >= bone_pile_duration:
			dead = true
