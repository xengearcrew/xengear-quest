extends Node

# represents one "Room" in the game, with its own camera settings
class_name Room

var curRoomIndex: int
var jsonData

# called with Room.new()
func _init(roomIndex):
	# for now this file has all the rooms in the game, but we may want more room files
	var roomJSONPath = "res://rooms/rooms001.json"
	self.curRoomIndex = roomIndex
	var jsonString = FileAccess.get_file_as_string(roomJSONPath)
	var json = JSON.new()
	var error = json.parse(jsonString)
	if error == OK:
		jsonData = json.data
		# json is expected to be an array
		if typeof(jsonData) == TYPE_ARRAY:
			print("room name: ", jsonData[curRoomIndex].get("name"))
		else:
			jsonData = null
			printerr("Unexpected data, expected array in ", roomJSONPath)
	else:
		jsonData = null
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())

# make only the current room's bg visible, update cam params to show the room within its boundaries
func showRoomBackground(bgNodes, camera):
	if jsonData == null: return false
	var roomCtr: int = 0
	for room in jsonData:
		var backgroundJO = room.get("background")
		if backgroundJO:
			var bgNode = bgNodes.get_node(backgroundJO)
			if roomCtr == curRoomIndex:
				bgNode.visible = true
			else:
				bgNode.visible = false
		roomCtr += 1
	var camLimits = jsonData[curRoomIndex].get("cam_limits", null) # expects array of left, right, top, bottom
	if camLimits:
		camera.limit_left = camLimits[0]
		camera.limit_right = camLimits[1]
		camera.limit_top = camLimits[2]
		camera.limit_bottom = camLimits[3]
		
func getRoomScaleInfo():
	if jsonData != null: 
		var room = jsonData[curRoomIndex]
		var room_scale = room.get("room_scale_info")
		if room_scale:
			return room_scale
	return 1
