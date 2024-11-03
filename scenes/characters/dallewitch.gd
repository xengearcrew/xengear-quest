extends CharacterBody2D

@onready var animations = $AnimationPlayer

func _physics_process(_delta: float) -> void:
	animations.play("dallewitch-walk")
	move_and_slide()
