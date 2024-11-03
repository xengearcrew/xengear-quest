extends Area2D

class_name ActionArea

enum areaTypeEnum {PLAYER_OWNED_AREA, ROOM_ENTER_AREA, DOOR_APPROACH}

@export var areaType: areaTypeEnum
@export var gotoRoomIndex: int
@export var gotoRoomXY: Vector2
@export var doorObj: Door

signal characterOwnedAreaEntered
signal characterOwnedAreaExited
signal areaEntered
signal doorApproachEntered
signal doorApproachExited

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_entered(area):
	if areaType == areaTypeEnum.PLAYER_OWNED_AREA:
		characterOwnedAreaEntered.emit()
	elif areaType == areaTypeEnum.ROOM_ENTER_AREA:
		areaEntered.emit(gotoRoomIndex, gotoRoomXY)
	elif areaType == areaTypeEnum.DOOR_APPROACH:
		doorApproachEntered.emit(doorObj)
		
func _on_area_exited(area):
	if areaType == areaTypeEnum.PLAYER_OWNED_AREA:
		characterOwnedAreaExited.emit()
	elif areaType == areaTypeEnum.DOOR_APPROACH:
		doorApproachExited.emit()
