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
		return Vector2(x + door_number - (room.grid_height * 2) - (room.grid_width * 2) + 1, y + 1)

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

func generate():
	# Create start room
	var center = (grid_size / 2)
	if grid_size % 2 == 0:
		center -= 1
	if add_room(center, center, start_room):
		# Follow path to boss room
		var current_x = center
		var current_y = center
		# Repeat this process a number of times equal to the room distance to the boss:
		for i in range(distance_to_boss):
			# Collect all the possible rooms and doors to generate
			var current_room = grid[current_x][current_y]
			var possible_rooms = room_list
			var possible_doors = []
			for junction in range(len(current_room.connections)):
				if current_room.connections[junction] == 1:
					possible_doors.append(junction)
			var placed = false
			while not placed:
				# Generate a random room and a random door
				var random_room = room_list[randi_range(0, len(room_list) - 1)]
				var random_door = possible_doors[randi_range(0, len(possible_doors) - 1)]
				var target_space = get_space_from_door(current_x, current_y, current_room, random_door)
				var target_direction = get_dir_from_door(current_room, random_door)
				# Ensure the two rooms can connect (i.e. the random room has a door on the opposite side to the random door)
				for junction in range(len(random_room.connections)):
					if random_room.connections[junction] == 1:
						var door_direction = get_dir_from_door(random_room, junction)
						if door_direction == -1 * target_direction:
							pass
		# Create boss room
		# Create offshoots
	else:
		print("Error creating start room.")

func generate_offshoot(room, chance):
	pass
