extends CharacterBody2D

class_name Elly

@onready var animations = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var collideBox = $collideBox
@onready var approachArea = $approachArea

signal expire
signal revive
signal gotoRoom

var gradscale_min_y = null
var gradscale_max_y = null
var gradscale_min_scale = null
var gradscale_max_scale = null
var scaleFactor: float = 1 # current scale factor based on scaleInfo etc
var scaleDir: float = 1 # either 1 if facing right or -1 if facing left
const BASE_SCALE = 2 # scale based on graphics source
const BASE_SPEED = 170.0
const SPRINT_FACTOR = 2
const FLOOR_STICKINESS = 30 # should be from 3 (slippery) to 30 (rubbery floor)
const JUMP_VELOCITY = -400.0
const SPEED_DAMP_FACTOR: float = 0.125
var isEngaging: bool = false
var isAnimating: bool = false
const actions = [
	"attack_1",
	"attack_2",
	"block",
	"die_1",
	"die_2",
	"dodge",
	"duck",
	"get_up",
	"interact",
	"jump",
	"spell_1",
	"spell_2"]
var doorObj: Door = null

# used if you want to scale based on y, unused at the moment
#var minScale: float = 0.8
#var maxScale: float = 1

# to be used later:
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
func getMoveDirFromInput():
	var moveDir = Vector2.ZERO
	if Input.is_action_pressed("walk_up"):
		moveDir.y -= 1
	if Input.is_action_pressed("walk_down"):
		moveDir.y += 1
	if Input.is_action_pressed("walk_left"):
		moveDir.x -= 1
	if Input.is_action_pressed("walk_right"):
		moveDir.x += 1
	return moveDir
	
func processKeyboardAction(action):
	if Input.is_action_just_pressed(action):
		#if key in engagingActions:
			#isEngaging = true
		# deal with actions that dont have animations first:
		if action == "interact":
			if doorObj != null:
				doorObj.open_or_close()
		else:
			# the following actions have animations:
			isAnimating = true
			animations.play("elly_" + str(action))
			await animations.animation_finished
			isAnimating = false
			if action.begins_with("die"):
				expire.emit()
			elif action == "spell_1":
				revive.emit()
		#isEngaging = false
		
func enterArea(gotoRoomIndex, gotoRoomXY):
	gotoRoom.emit(gotoRoomIndex, gotoRoomXY)
	
func enterDoorApproachArea(doorObj):
	print("door area entered")
	self.doorObj = doorObj
	
func exitDoorApproachArea():
	print("door area exited")
	self.doorObj = null
	
func getPlayerApproachArea():
	return approachArea
	
func _physics_process(delta):
	var moveDir = getMoveDirFromInput()
	var moveSpeed = 0
	if (moveDir.x < 0 and scaleDir > 0) or (moveDir.x > 0 and scaleDir < 0):
		scaleDir *= -1
	for action in actions:
		processKeyboardAction(action)
	var speedDamp = 1
	if isEngaging:
		speedDamp = SPEED_DAMP_FACTOR
	if moveDir:
		moveSpeed = BASE_SPEED * scaleFactor
		if Input.is_action_pressed("sprint"):
			moveSpeed = BASE_SPEED * SPRINT_FACTOR * scaleFactor
		velocity = moveDir * moveSpeed * speedDamp
		updateScale()
	else:
		velocity.x = move_toward(velocity.x, 0, FLOOR_STICKINESS)
		velocity.y = move_toward(velocity.y, 0, FLOOR_STICKINESS)
	# Add the gravity here if you want it:
#	if not is_on_floor():
#		velocity.y += gravity * delta
	# Handle Jump.
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY
	if !isAnimating:
		if velocity:
			animations.play("elly_run")
		else:
			animations.play("elly_idle")
	move_and_slide()
	
# from room json, could be float or array if doing "gradiant scaling"
func setScaleInfo(scaleInfo):
	if typeof(scaleInfo) == TYPE_FLOAT:
		gradscale_min_y = null
		gradscale_max_y = null
		gradscale_min_scale = null
		gradscale_max_scale = null
		scaleFactor = scaleInfo
	elif typeof(scaleInfo) == TYPE_ARRAY:
		gradscale_min_y = scaleInfo[0]
		gradscale_max_y = scaleInfo[1]
		gradscale_min_scale = scaleInfo[2]
		gradscale_max_scale = scaleInfo[3]
	updateScale()

# called every time elly moves, updates the scale based on y position
# if scaling is done with "gradiant scaling"
func updateScale():
	if gradscale_min_y:
		# find percentage between min and max scale based on this formula:
		# percentY / 100 = newScale / (maxScale - minScale)
		var posY = get_position().y
		var percY = (posY - gradscale_min_y) / \
			(gradscale_max_y - gradscale_min_y) * 100
		var newScale: float = gradscale_min_scale + percY * \
			(gradscale_max_scale - gradscale_min_scale) / 100
		scaleFactor = newScale
	else:
		# scaleFactor stays the same
		pass
	sprite.scale.x = BASE_SCALE * scaleFactor * scaleDir
	sprite.scale.y = BASE_SCALE * scaleFactor
