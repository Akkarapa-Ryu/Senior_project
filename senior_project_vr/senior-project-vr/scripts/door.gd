extends Node3D

# Ref: https://www.youtube.com/watch?v=SmPD24zJBTo
@export var open_animation: String
@export var close_animation: String

var is_open = false
var player_near = false
var is_animating = false

@onready var animation_player = $DoorAnimation
@onready var open_sound = $OpenSound
@onready var close_sound = $CloseSound

func _on_Area_body_entered(body):
	if body.name == "Player":
		player_near = true

func _on_Area_body_exited(body):
	if body.name == "Player":
		player_near = false

func _unhandled_input(event):
	if player_near and Input.is_action_just_pressed("ui_interact_door") and not is_animating:
		toggle_door()

func toggle_door():
	is_animating = true
	if is_open:
		animation_player.play(close_animation)
	else:
		animation_player.play(open_animation)
		open_sound.play()
	is_open = !is_open

func _on_AnimationPlayer_animation_finished(anim_name):
	is_animating = false
	if anim_name == close_animation:
		close_sound.play()
