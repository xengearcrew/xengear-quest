extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var animations = $AnimationPlayer
@onready var collideBox = $collideBox
@onready var collisionMap = $"../../tilemaps/collisionMapLayer"
@onready var path_tilemap = $"../../tilemaps/path"
@onready var elly = $"../elly"

@export var speed = 150
@export var vision_len_cells = 80

var astar_grid: AStarGrid2D
var dest_pos
var cur_start_cell = null
var isAnimating: bool = false
var enemyIsWithinPlayerOwnedArea = false
var isAlive = true

func _ready():
	elly.expire.connect(elly_expires)
	elly.revive.connect(elly_revives)
	var playerApproachArea = elly.getPlayerApproachArea()
	# connect elly's action area signals with functions in this script
	playerApproachArea.characterOwnedAreaEntered.connect(onPlayerOwnedAreaEntered)
	playerApproachArea.characterOwnedAreaExited.connect(onPlayerOwnedAreaExited)
	initAStarGrid()

# code for a single game frame for the enemy
func _physics_process(delta):
	if !isAlive:
		return
	if dest_pos != null:
		var curPos = position + collideBox.position
		var moveDir = dest_pos - curPos
		velocity = moveDir.normalized() * speed
		move_and_slide()
		updateFacingDirection(moveDir)
	else:
		velocity = Vector2.ZERO
	if !isAnimating:
		var anim = "seraphita_idle";
		if velocity:
			anim = "seraphita_run"
		animations.play(anim)
	
	var playerIsWithinSight = checkIfPlayerIsWithinSight()
	if playerIsWithinSight && !enemyIsWithinPlayerOwnedArea:
		update_astar_grid_using_collision_map()
		find_path()
	elif !playerIsWithinSight:
		stopPursuing()

# if the enemy is facing one way but his moveDir faces the opposite way, switch the way they're facing
#
# note:
# this particular enemy's sprite sheet has her facing left, usually sprite sheets have them face right,
# and when they are facing right, this "facing" check would instead be this 
# (notice the sprite.scale.x < and >):
# if (moveDir.x < 0 and sprite.scale.x > 0) or (moveDir.x > 0 and sprite.scale.x < 0):
func updateFacingDirection(moveDir):
	if (moveDir.x < 0 and sprite.scale.x < 0) or (moveDir.x > 0 and sprite.scale.x > 0):
		sprite.scale.x *= -1;
		collideBox.scale.x *= -1;

# check if elly's TILED position is within the rectangle of tiles with size
# defined by vision_len_cells
func checkIfPlayerIsWithinSight() -> bool:
	var curPos = position + collideBox.position
	var pos_cell = collisionMap.local_to_map(curPos)
	var ellyPos = elly.position + elly.collideBox.position
	var player_pos_cell = collisionMap.local_to_map(ellyPos)
	var vision_left = pos_cell.x - vision_len_cells
	var vision_top = pos_cell.y - vision_len_cells
	var visionRect = Rect2i(vision_left, vision_top, vision_len_cells * 2, vision_len_cells * 2)
	return visionRect.has_point(player_pos_cell)

# this enemy has reached elly's approach area
func onPlayerOwnedAreaEntered():
	stopPursuing()
	enemyIsWithinPlayerOwnedArea = true

# this enemy was in elly's approach area but has now left
func onPlayerOwnedAreaExited():
	enemyIsWithinPlayerOwnedArea = false

func initAStarGrid() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.set_cell_size(collisionMap.tile_set.tile_size)
	var curPos = position + collideBox.position
	var pos_cell = collisionMap.local_to_map(curPos)
	var vision_left = pos_cell.x - vision_len_cells
	var vision_top = pos_cell.y - vision_len_cells
	astar_grid.set_region(Rect2i(vision_left, vision_top, vision_len_cells * 2, vision_len_cells * 2))
	astar_grid.update()
	
var wallCoordsHaveBeenOutputted = true
# mark all the walls within the astar_grid (the size of which is defined by how far the enemy
# can see, IE the value of vision_len_cells) based on their being a marked tile in collisionMap
func update_astar_grid_using_collision_map() -> void:
	var curPos = position + collideBox.position
	var pos_cell = collisionMap.local_to_map(curPos)
	var vision_left = pos_cell.x - vision_len_cells
	var vision_top = pos_cell.y - vision_len_cells
	astar_grid.set_region(Rect2i(vision_left, vision_top, vision_len_cells * 2, vision_len_cells * 2))
	astar_grid.update()
	var debugStr = "w,h: [" + str(astar_grid.size.x) + "," + str(astar_grid.size.y) + "], walls: "
	for i in range(vision_left, vision_left + astar_grid.size.x):
		for j in range(vision_top, vision_top + astar_grid.size.y):
			var collision_map_tile = Vector2i(i, j)
			if collisionMap.get_cell_source_id(collision_map_tile) >= 0:
				astar_grid.set_point_solid(Vector2i(i, j), true)
				debugStr = debugStr + str(Vector2i(i, j)) + " "
	if !wallCoordsHaveBeenOutputted:
		print(debugStr)
		wallCoordsHaveBeenOutputted = true

# set the dest_pos to the next cell in the enemy's current astar path towards its target,
# set the 'path' tilemap layer so it's drawn in-game for debugging purposes
# if elly's sprite or pivot isn't centered, you can add a Vector2 to her position, ex:
# collisionMap.local_to_map(elly.position + Vector2(40,-20))
var pathCoordsHaveBeenOutputtedCtr = 0
var pathCoordsHaveBeenOutputtedMax = 0
func find_path() -> void:
	var curPos = position + collideBox.position
	var ellyPos = elly.position + elly.collideBox.position
	var start_cell = collisionMap.local_to_map(curPos)
	var elly_cell = collisionMap.local_to_map(ellyPos)
	if (cur_start_cell == null or cur_start_cell != start_cell):
		cur_start_cell = start_cell
		if start_cell == elly_cell or !astar_grid.is_in_boundsv(start_cell) or !astar_grid.is_in_boundsv(elly_cell):
			# either the enemy has no where to go, or its start or end cells are outside the grid
			stopPursuing()
			return
		var astar_path = astar_grid.get_id_path(start_cell, elly_cell)
		var debugStr = "ids: "
		path_tilemap.clear()
		for path_point in astar_path:
			# mark all the cells in the astar path
			path_tilemap.set_cell(path_point, 0, Vector2i(2, 0))
			debugStr = debugStr + str(path_point) + " "
		if astar_path.size() > 1:
			# we only care about the first point in the path bc the path is constantly updating
			var tileSize = collisionMap.tile_set.tile_size;
			var dir = astar_path[1] - astar_path[0]
			dest_pos = collisionMap.map_to_local(start_cell + dir)
		else:
			stopPursuing()
		if astar_path and pathCoordsHaveBeenOutputtedCtr < pathCoordsHaveBeenOutputtedMax:
			print(debugStr)
			pathCoordsHaveBeenOutputtedCtr += 1
	
func stopPursuing():
	path_tilemap.clear()
	dest_pos = null
	cur_start_cell = null
	
func elly_expires():
	if isAlive:
		isAnimating = true
		animations.play("seraphita_collapse")
		await animations.animation_finished
		isAnimating = false
		animations.play("seraphita_staydown")
		isAlive = false
		
func elly_revives():
	if !isAlive:
		isAnimating = true
		animations.play("seraphita_revive")
		await animations.animation_finished
		isAnimating = false
		animations.play("seraphita_idle")
		isAlive = true
