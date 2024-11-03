extends CharacterBody2D

class_name Door

@onready var animations = $AnimationPlayer
var isOpen: bool = false
var childDoor: Door = null
var parentDoor: Door = null

func _ready():
	var children = get_children()
	for child in children:
		if is_instance_of(child, Door):
			childDoor = child
			break
	var parent = get_parent()
	if is_instance_of(parent, Door):
		parentDoor = parent
		
	# how to figure out whether your parent or any of your kids is a Door
	#for child in children:
		#print('child: ', str(child), ', is instance of Door: ', str(is_instance_of(child, Door)))
	#var parent = get_parent()
	#print('parent: ', str(parent), ', is instance of Door: ', str(is_instance_of(parent, Door)))
	
func open_or_close():
	open_or_close_me()
	if childDoor:
		childDoor.open_or_close_me()
	elif parentDoor:
		parentDoor.open_or_close_me()
		
func open_or_close_me():
	if isOpen:
		close_door()
	else:
		open_door()

func open_door():
	animations.play("door_open")
	isOpen = true
	
func close_door():
	animations.play("door_close")
	isOpen = false
