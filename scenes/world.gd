extends Node2D

const Room = preload("res://rooms/room.gd")

@onready var bg_nodes = $background_nodes
@onready var elly = $foreground_items/elly
@onready var camera = $foreground_items/elly/Camera2D
@onready var actionAreas = $action_areas
@onready var door = $foreground_items/door01

var curRoomIndex: int

# Called when the node enters the scene tree for the first time.
func _ready():
	# connect all the Area2D nodes' "areaEntered" signals in the world so something happens when 
	# when elly goes into them
	for actionArea in actionAreas.get_children():
		if actionArea.areaType == ActionArea.areaTypeEnum.ROOM_ENTER_AREA:
			actionArea.areaEntered.connect(elly.enterArea)
		elif actionArea.areaType == ActionArea.areaTypeEnum.DOOR_APPROACH:
			actionArea.doorApproachEntered.connect(elly.enterDoorApproachArea)
			actionArea.doorApproachExited.connect(elly.exitDoorApproachArea)
	elly.gotoRoom.connect(enterRoom)
	
	#enterRoom(0, Vector2(550.0, 320.0))
	enterRoom(1, Vector2(1500.0, 380.0)) # for testing room 1
	#enterRoom(2, Vector2(1700.0, -700.0)) # for testing room 1, may want to not have seraphita alive for this test

# changes which room we're seeing
func enterRoom(gotoRoomIndex, gotoRoomXY):
	curRoomIndex = gotoRoomIndex
	elly.set_position(gotoRoomXY)
	var room = Room.new(curRoomIndex)
	room.showRoomBackground(bg_nodes, camera)
	elly.setScaleInfo(room.getRoomScaleInfo())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
