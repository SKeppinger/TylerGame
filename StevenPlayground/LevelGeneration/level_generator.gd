extends Node

@export var player: PackedScene # Player scene
@export var start_room: PackedScene # The level's start room
@export var boss_room: PackedScene # The level's boss room
@export var door: PackedScene # The door scene (assumed to be facing right)
@export var room_list: Array[PackedScene] # A list of other rooms that can populate the level
@export var grid_box_size = 128 # The size (side length) of one grid box, in pixels
@export var grid_size = 30 # The size (side length) of the entire grid, in boxes
@export var grid_offset = 0 # The amount of empty space between grid spaces
@export var origin: Vector2 # The actual position in the level scene around which to center the grid box
@export var distance_to_boss = 4 # How many rooms between the start room and boss room
@export var minimum_rooms = 8 # Minimum number of rooms in dungeon (provided it is possible)
@export var base_offshoot_chance = 0.8 # The base chance to create an offshoot from a given room
@export var extra_door_chance = 0.5 # The chance to add an optional door to a room

var grid = []
var room_count = 0
var door_positions = []
var boss_room_position

func _ready():
	for row in range(grid_size):
		grid.append([])
		for column in range(grid_size):
			grid[row].append(null)
	# Keep attempting to generate until a correct level is generated
	while generate() == -1:
		grid = []
		room_count = 0
		door_positions = []
		for row in range(grid_size):
			grid.append([])
			for column in range(grid_size):
				grid[row].append(null)
		for node in get_tree().get_nodes_in_group("door"):
			node.queue_free()
	# Spawn the player
	if player:
		var player_instance = player.instantiate()
		get_tree().root.add_child.call_deferred(player_instance)
		player_instance.global_position = origin

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
				grid[row - i][column + j] = Vector2(row, column)
	room_count += 1
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

# Add a door to a room
func add_door(room_position, door_number):
	var door_instance = door.instantiate()
	get_tree().root.add_child.call_deferred(door_instance)
	var room = grid[room_position.x][room_position.y]
	var to_room = null
	var target_space = get_space_from_door(room_position.x, room_position.y, room, door_number)
	if target_space and grid[target_space.x][target_space.y] is Vector2:
		var location = grid[target_space.x][target_space.y]
		to_room = grid[location.x][location.y]
	else:
		to_room = grid[target_space.x][target_space.y]
	var door_position = room_position + get_grid_box_from_door(room, door_number)
	var center = (grid_size / 2)
	if grid_size % 2 == 0:
		center -= 1
	door_instance.global_position.x = (door_position.x * grid_box_size) - (center * grid_box_size) + origin.x + ((door_position.x - center) * grid_offset)
	door_instance.global_position.y = (door_position.y * grid_box_size) - (center * grid_box_size) + origin.y + ((door_position.y - center) * grid_offset)
	var door_direction = get_dir_from_door(room, door_number)
	door_instance.orientation = door_direction
	door_instance.grid_size = grid_box_size
	match door_direction:
		Vector2.RIGHT:
			door_instance.global_position.x += grid_box_size / 2
			door_instance.left_room = room
			door_instance.right_room = to_room
		Vector2.DOWN:
			door_instance.rotation_degrees = 90
			door_instance.global_position.y += grid_box_size / 2
			door_instance.left_room = to_room
			door_instance.right_room = room
		Vector2.LEFT:
			door_instance.global_position.x -= grid_box_size / 2
			door_instance.left_room = to_room
			door_instance.right_room = room
		Vector2.UP:
			door_instance.rotation_degrees = 90
			door_instance.global_position.y -= grid_box_size / 2
			door_instance.left_room = room
			door_instance.right_room = to_room
	door_positions.append(door_instance.global_position)
	#TODO: This is temporary so I can see the doors
	#door_instance.z_index = 1
	#TODO: THIS IS TEMPORARY SO I DONT SEE THE DOORS LMAO
	door_instance.set_visible(false)
	return door_instance

# Add optional doors
func add_optional_doors():
	for row in range(grid_size):
		for col in range(grid_size):
			if grid[row][col] and grid[row][col] is not Vector2:
				# Don't add extra doors to boss room
				if Vector2(row, col) == boss_room_position:
					continue
				var room = grid[row][col]
				for junction in range(len(room.connections)):
					if room.connections[junction] == 1 and !door_exists(Vector2(row, col), junction):
						var target_space = get_space_from_door(row, col, room, junction)
						var to_direction = get_dir_from_door(room, junction)
						if grid[target_space.x][target_space.y] != null:
							var target_room = null
							var target_room_pos = target_space
							if grid[target_space.x][target_space.y] is Vector2:
								target_room_pos = grid[target_space.x][target_space.y]
								target_room = grid[target_room_pos.x][target_room_pos.y]
							else:
								target_room = grid[target_space.x][target_space.y]
							# Don't add extra doors to boss room
							if target_room_pos == boss_room_position:
								continue
							# Check if target room has a potential door in that space
							var can_traverse = false
							for door_num in range(len(target_room.connections)):
								if target_room.connections[door_num] == 1:
									if target_room_pos + get_grid_box_from_door(target_room, door_num) == target_space:
										if get_dir_from_door(target_room, door_num) == -1 * to_direction:
											# Chance to add door
											var rng = randf()
											if rng <= extra_door_chance:
												var door1 = add_door(Vector2(row, col), junction)
												var door2 = add_door(target_room_pos, door_num)
												door1.partner = door2
												door2.partner = door1
												print("Optional door added!")

# Check if a door exists in a certain position
func door_exists(room_position, door_number):
	var room = grid[room_position.x][room_position.y]
	var grid_box = room_position + get_grid_box_from_door(room, door_number)
	var door_direction = get_dir_from_door(room, door_number)
	var center = (grid_size / 2)
	if grid_size % 2 == 0:
		center -= 1
	var door_position = Vector2.ZERO
	door_position.x = (grid_box.x * grid_box_size) - (center * grid_box_size) + origin.x
	door_position.y = (grid_box.y * grid_box_size) - (center * grid_box_size) + origin.y
	match door_direction:
		Vector2.RIGHT:
			door_position.x += grid_box_size / 2
		Vector2.DOWN:
			door_position.y += grid_box_size / 2
		Vector2.LEFT:
			door_position.x -= grid_box_size / 2
		Vector2.UP:
			door_position.y -= grid_box_size / 2
	var door_check = false
	for position in door_positions:
		if position == door_position:
			door_check = true
	return door_check

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
			if len(possible_doors) == 0:
				print("Path to boss room failed")
				return -1
			var placed = false
			# Generate a random room and a random door
			var random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
			# Don't put a dead end on the path
			while random_room.instantiate().dead_end:
				random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
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
								# Add doors
								var door1 = add_door(position, junction)
								var door2 = add_door(Vector2(current_x, current_y), random_door)
								door1.partner = door2
								door2.partner = door1
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
							return -1
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
		if len(possible_doors) == 0:
			print("Failed to place boss room")
			return -1
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
						boss_room_position = position
						placed = true
						# Add doors
						var door1 = add_door(position, junction)
						var door2 = add_door(Vector2(current_x, current_y), random_door)
						door1.partner = door2
						door2.partner = door1
						break
					# If the room was not placed, continue searching through doors
		# If the boss room was not placed, fail
		if not placed:
			print("Failed to place boss room")
			return -1

		# Create offshoots
		# Start room
		generate_offshoot(Vector2(center, center), base_offshoot_chance)
		# Path rooms
		for room_pos in path_list:
			generate_offshoot(room_pos, base_offshoot_chance)
		
		# Instantiate all rooms
		for row in range(grid_size):
			for col in range(grid_size):
				if grid[row][col] and grid[row][col] is not Vector2:
					var room = grid[row][col]
					get_tree().root.add_child.call_deferred(room)
					room.global_position.x = (row * grid_box_size) - (center * grid_box_size) + origin.x + ((row - center) * grid_offset)
					room.global_position.y = (col * grid_box_size) - (center * grid_box_size) + origin.y + ((col - center) * grid_offset)
		
		# Add optional doors
		add_optional_doors()
	else:
		print("Error creating start room.")
		return -1
	return 0

# Generate an offshoot recursively, with a decreasing chance to continue the offshoot
func generate_offshoot(room_position, chance):
	var rng = randf()
	if rng <= chance or (chance == base_offshoot_chance and room_count < minimum_rooms):
		var origin_room = grid[room_position.x][room_position.y]
		var possible_rooms = room_list
		var possible_doors = []
		for junction in range(len(origin_room.connections)):
			if origin_room.connections[junction] == 1:
				var door_space = get_space_from_door(room_position.x, room_position.y, origin_room, junction)
				if grid[door_space.x][door_space.y] == null:
					possible_doors.append(junction)
		if len(possible_doors) == 0 or len(possible_rooms) == 0:
			print("Failed to generate offshoot (non-lethal error)")
			return
		var placed = false
		var placed_position
		# Generate a random room and a random door
		var random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
		print(random_room.instantiate().dead_end)
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
							print("Offshoot room placed at ", position.x, " ", position.y, " from ", room_position.x, " ", room_position.y)
							placed = true
							placed_position = position
							# Add doors
							var door1 = add_door(position, junction)
							var door2 = add_door(room_position, random_door)
							door1.partner = door2
							door2.partner = door1
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
							var door_space = get_space_from_door(room_position.x, room_position.y, origin_room, junction)
							if grid[door_space.x][door_space.y] == null:
								possible_doors.append(junction)
					# Choose a different room and door
					possible_rooms.remove_at(possible_rooms.find(random_room))
					# If there are no more rooms, fail
					if len(possible_rooms) == 0:
						print("Failed to generate offshoot (non-lethal error)")
						return
					else:
						random_room = possible_rooms[randi_range(0, len(possible_rooms) - 1)]
						print(random_room.instantiate().dead_end)
						random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
				else:
					random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
		# If the room was placed, half the offshoot chance and generate again
		generate_offshoot(placed_position, chance / 2.0)
