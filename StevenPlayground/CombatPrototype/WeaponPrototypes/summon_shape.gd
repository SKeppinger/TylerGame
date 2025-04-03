## A special kind of attack shape that summons creatures in the area
## IMPORTANT: SHAPE MUST BE A CIRCLE
## If you want to summon at a specific point, make it a very small circle :)
extends AttackShape
class_name SummonShape

## ATTRIBUTES
@export var summoned_creature: PackedScene # The creature to summon
@export var summon_count = 1 # How many creatures to summon
@export var center_repel = 0.3 # The minimum distance from the center to summon a creature (percentage of radius)

## FUNCTIONS
func custom(_delta):
	var summoned_creatures = 0
	var shape = $Shape.shape
	while summoned_creatures < summon_count:
		# Randomly determine the summon position
		var direction_x = randf_range(0, 1)
		var direction_y = randf_range(0, 1)
		var direction = Vector2(direction_x, direction_y)
		var distance = randf_range(center_repel * shape.radius, shape.radius)
		# Summon the creature
		var creature = summoned_creature.instantiate()
		get_tree().root.add_child(creature)
		creature.global_position = global_position + (direction * distance)
		summoned_creatures += 1
	queue_free()
