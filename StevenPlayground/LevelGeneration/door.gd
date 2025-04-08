extends Area2D
class_name Door

@export var left_room: Room # The left (or bottom) room
@export var right_room: Room # The right (or top) room
@export var grid_size: int # How big the grid boxes are
@export var orientation = Vector2.RIGHT # Which way the door is facing

# Transport the player when they enter
# TODO: THIS IS NOT VERY PRECISE, IMPROVE IT LATER
func _on_body_entered(body):
	if body.is_in_group("player"):
		match orientation:
			Vector2.RIGHT:
				if body.global_position.x > global_position.x:
					body.global_position.x = left_room.global_position.x + (grid_size * left_room.grid_width / 3.0)
				else:
					body.global_position.x = right_room.global_position.x - (grid_size * right_room.grid_width / 3.0)
			Vector2.LEFT:
				if body.global_position.x > global_position.x:
					body.global_position.x = left_room.global_position.x + (grid_size * left_room.grid_width / 3.0)
				else:
					body.global_position.x = right_room.global_position.x - (grid_size * right_room.grid_width / 3.0)
			Vector2.DOWN:
				if body.global_position.y < global_position.y:
					body.global_position.y = left_room.global_position.y - (grid_size * left_room.grid_height / 3.0)
				else:
					body.global_position.y = right_room.global_position.y + (grid_size * right_room.grid_height / 3.0)
			Vector2.UP:
				if body.global_position.y < global_position.y:
					body.global_position.y = left_room.global_position.y - (grid_size * left_room.grid_height / 3.0)
				else:
					body.global_position.y = right_room.global_position.y + (grid_size * right_room.grid_height / 3.0)
