extends Node

@export var grid_width: int
@export var grid_height: int
## Starting from the right side of the top-rightmost grid space in the room and moving clockwise, place a 1 if there can be a door, 
## and a 0 if not.
## For example, the connections array for a 1x1 room will have 4 entries: right, down, left, up.
## The connections array for a 2x2 room will have 8 entries: 
## toprightright, bottomrightright, bottomrightdown, bottomleftdown, bottomleftleft, topleftleft, topleftup, toprightup
## For a 1x2 room:
## topright, bottomright, bottomdown, bottomleft, topleft, topup
## I hope this makes sense.
@export var connections: Array[int]
