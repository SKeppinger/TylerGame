extends Area2D
class_name Door

@export var left_room: Room # The left (or bottom) room
@export var right_room: Room # The right (or top) room
@export var partner: Door # The corresponding door
@export var grid_size: int # How big the grid boxes are
@export var orientation = Vector2.RIGHT # Which way the door is facing
@export var offset = 64 # How far from the center of the door to teleport the player

# Transport the player when they enter
func _on_body_entered(body):
	if body.is_in_group("player"):
		match orientation:
			Vector2.RIGHT:
				body.global_position = partner.global_position + Vector2(offset, 0)
			Vector2.LEFT:
				body.global_position = partner.global_position - Vector2(offset, 0)
			Vector2.DOWN:
				body.global_position = partner.global_position + Vector2(0, offset)
			Vector2.UP:
				body.global_position = partner.global_position - Vector2(0, offset)
