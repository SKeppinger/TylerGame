extends Node

@export var start_room: PackedScene
@export var boss_room: PackedScene
@export var room_list: Array[PackedScene]
@export var grid_box_size = 128
@export var grid_size = 30
@export var origin: Vector2
@export var distance_to_boss = 4
@export var base_offshoot_chance = 0.5

var grid = []

func _ready():
	for row in range(grid_size):
		grid.append([])
		for column in range(grid_size):
			grid[row].append(null)
	generate()

# Add room to grid[row][column]. If the room is bigger than 1x1, grid[row][column] will represent the top-rightmost grid space of the room.
func add_room(row, column, room):
	room = room.instantiate()
	if column + room.grid_height > grid_size:
		return false
	if row - room.grid_width < -1:
		return false
	for i in range(room.grid_width):
		for j in range(room.grid_height):
			if grid[row - i][column + j] != null:
				return false
	for i in range(room.grid_width):
		for j in range(room.grid_height):
			if i == 0 and j == 0:
				grid[row][column] = room
			else:
				grid[row - i][column + j] = 1
	return true

# Returns the grid space targeted by the input door, given that top-right of room is at (x,y)
func get_space_from_door(x, y, room, door_number):
	# Door faces right
	if door_number < room.grid_height:
		return Vector2(x + 1, y + door_number)
	# Door faces down
	elif door_number < room.grid_height + room.grid_width:
		return Vector2(x - door_number + room.grid_height, y + room.grid_height)
	# Door faces left
	elif door_number < (room.grid_height * 2) + room.grid_width:
		return Vector2(x - room.grid_width, y - door_number + (2 * room.grid_height) + room.grid_width - 1)
	# Door faces up
	else:
		return Vector2(x + door_number - (room.grid_height * 2) - (room.grid_width * 2) + 1, y - 1)

# Returns the direction the door is facing
func get_dir_from_door(room, door_number):
	# Door faces right
	if door_number < room.grid_height:
		return Vector2.RIGHT
	# Door faces down
	elif door_number < room.grid_height + room.grid_width:
		return Vector2.DOWN
	# Door faces left
	elif door_number < (room.grid_height * 2) + room.grid_width:
		return Vector2.LEFT
	# Door faces up
	else:
		return Vector2.UP

# Returns the relative grid box (top-rightmost is 0, 0)
func get_grid_box_from_door(room, door_number):
	# Door faces right
	if door_number < room.grid_height:
		return Vector2(0, door_number)
	# Door faces down
	elif door_number < room.grid_height + room.grid_width:
		return Vector2(0 - door_number + room.grid_height, 1- room.grid_height)
	# Door faces left
	elif door_number < (room.grid_height * 2) + room.grid_width:
		return Vector2(1 - room.grid_width, 0 - door_number + (2 * room.grid_height) + room.grid_width - 1)
	# Door faces up
	else:
		return Vector2(door_number - (room.grid_height * 2) - (room.grid_width * 2) + 1, 0)

# Generate a level
func generate():
	# Create start room
	var center = (grid_size / 2)
	if grid_size % 2 == 0:
		center -= 1
	if add_room(center, center, start_room):
		print("Start room placed at ", center, " ", center)
		# Follow path to boss room
		var current_x = center
		var current_y = center
		var path_list = []
		# Repeat this process a number of times equal to the room distance to the boss:
		for i in range(distance_to_boss):
			# Collect all the possible rooms and doors to generate
			var current_room = grid[current_x][current_y]
			var possible_rooms = room_list
			var possible_doors = []
			for junction in range(len(current_room.connections)):
				if current_room.connections[junction] == 1:
					var door_space = get_space_from_door(current_x, current_y, current_room, junction)
					if grid[door_space.x][door_space.y] == null:
						possible_doors.append(junction)
			var placed = false
			# Generate a random room and a random door
			var random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
			var random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
			while not placed:
				var target_space = get_space_from_door(current_x, current_y, current_room, random_door)
				var target_direction = get_dir_from_door(current_room, random_door)
				# Ensure the two rooms can connect (i.e. the random room has a door on the opposite side to the random door)
				var random_room_instance = random_room.instantiate()
				for junction in range(len(random_room_instance.connections)):
					if random_room_instance.connections[junction] == 1:
						var door_direction = get_dir_from_door(random_room_instance, junction)
						if door_direction == -1 * target_direction:
							var relative_grid = get_grid_box_from_door(random_room_instance, junction)
							var position = target_space - relative_grid
							# Attempt to place the room
							if add_room(position.x, position.y, random_room):
								print("Path room placed at ", position.x, " ", position.y)
								placed = true
								current_x = position.x
								current_y = position.y
								path_list.append(Vector2(position.x, position.y))
								break
							# If the room was not placed, continue searching through doors
				# If none of the doors were able to connect, choose a different door
				if not placed:
					possible_doors.remove_at(possible_doors.find(random_door))
					# If there are no more doors, choose a different room
					if len(possible_doors) == 0:
						# Add all doors back
						for junction in range(len(current_room.connections)):
							if current_room.connections[junction] == 1:
								possible_doors.append(junction)
						# Choose a different room and door
						possible_rooms.remove_at(possible_rooms.find(random_room))
						# If there are no more rooms, fail
						if len(possible_rooms) == 0:
							print("Failed to generate path to boss room")
							return
						else:
							random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
							random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
					else:
						random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
		
		# Create boss room
		var last_path = grid[current_x][current_y]
		var possible_doors = []
		for junction in range(len(last_path.connections)):
			if last_path.connections[junction] == 1:
				var door_space = get_space_from_door(current_x, current_y, last_path, junction)
				if grid[door_space.x][door_space.y] == null:
					possible_doors.append(junction)
		var random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
		var target_space = get_space_from_door(current_x, current_y, last_path, random_door)
		var target_direction = get_dir_from_door(last_path, random_door)
		var placed = false
		var boss_room_instance = boss_room.instantiate()
		for junction in range(len(boss_room_instance.connections)):
			if boss_room_instance.connections[junction] == 1:
				var door_direction = get_dir_from_door(boss_room_instance, junction)
				if door_direction == -1 * target_direction:
					var relative_grid = get_grid_box_from_door(boss_room_instance, junction)
					var position = target_space - relative_grid
					# Attempt to place the room
					if add_room(position.x, position.y, boss_room):
						print("Boss room placed at ", position.x, " ", position.y)
						placed = true
						break
					# If the room was not placed, continue searching through doors
		# If the boss room was not placed, fail
		if not placed:
			print("Failed to place boss room")
			return

		# Create offshoots
		# Start room
		generate_offshoot(Vector2(center, center), base_offshoot_chance)
		# Path rooms
		for room_pos in path_list:
			generate_offshoot(room_pos, base_offshoot_chance)
		
		# Instantiate all rooms
		for row in range(grid_size):
			for col in range(grid_size):
				if grid[row][col] and grid[row][col] is not int:
					var room = grid[row][col]
					get_tree().root.add_child.call_deferred(room)
					room.global_position.x = (row * grid_box_size) - (center * grid_box_size) + origin.x
					room.global_position.y = (col * grid_box_size) - (center * grid_box_size) + origin.y
	else:
		print("Error creating start room.")

# Generate an offshoot recursively, with a decreasing chance to continue the offshoot
func generate_offshoot(room_position, chance):
	var rng = randf()
	if rng <= chance:
		var origin_room = grid[room_position.x][room_position.y]
		var possible_rooms = room_list
		var possible_doors = []
		for junction in range(len(origin_room.connections)):
			if origin_room.connections[junction] == 1:
				var door_space = get_space_from_door(room_position.x, room_position.y, origin_room, junction)
				if grid[door_space.x][door_space.y] == null:
					possible_doors.append(junction)
		if len(possible_doors) == 0:
			print("Failed to generate offshoot (non-lethal error)")
			return
		var placed = false
		var placed_position
		# Generate a random room and a random door
		var random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
		var random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
		while not placed:
			var target_space = get_space_from_door(room_position.x, room_position.y, origin_room, random_door)
			var target_direction = get_dir_from_door(origin_room, random_door)
			# Ensure the two rooms can connect (i.e. the random room has a door on the opposite side to the random door)
			var random_room_instance = random_room.instantiate()
			for junction in range(len(random_room_instance.connections)):
				if random_room_instance.connections[junction] == 1:
					var door_direction = get_dir_from_door(random_room_instance, junction)
					if door_direction == -1 * target_direction:
						var relative_grid = get_grid_box_from_door(random_room_instance, junction)
						var position = target_space - relative_grid
						# Attempt to place the room
						if add_room(position.x, position.y, random_room):
							print("Offshoot room placed at ", position.x, " ", position.y)
							placed = true
							placed_position = position
							break
						# If the room was not placed, continue searching through doors
			# If none of the doors were able to connect, choose a different door
			if not placed:
				possible_doors.remove_at(possible_doors.find(random_door))
				# If there are no more doors, choose a different room
				if len(possible_doors) == 0:
					# Add all doors back
					for junction in range(len(origin_room.connections)):
						if origin_room.connections[junction] == 1:
							possible_doors.append(junction)
					# Choose a different room and door
					possible_rooms.remove_at(possible_rooms.find(random_room))
					# If there are no more rooms, fail
					if len(possible_rooms) == 0:
						print("Failed to generate offshoot (non-lethal error)")
						return
					else:
						random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
						random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
				else:
					random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
		# If the room was placed, half the offshoot chance and generate again
		generate_offshoot(placed_position, chance / 2.0)
