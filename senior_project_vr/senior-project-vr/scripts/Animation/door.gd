# แก้ปิดประตู

extends Node3D

# Ref: https://www.youtube.com/watch?v=SmPD24zJBTo
@export var open_animation: String
@export var close_animation: String

var is_open = false
var player_near = false
var is_animating = false

@export var animation_player: AnimationPlayer
@onready var open_sound = $OpenSound
@onready var close_sound = $CloseSound

func _on_Area_body_entered(body):
	if body.is_in_group("player_xr") or body.get_parent().is_in_group("player_xr"):
		print("Player is near!")
		player_near = true

func _on_Area_body_exited(body):
	if body.is_in_group("player_xr") or body.get_parent().is_in_group("player_xr"):
		print("Player is near!")
		player_near = false

# จะเอา primary_click จาก controller ไปใส่เพิ่ม เพื่อให้ player_xr กดเปิดปิดประตูได้
func _unhandled_input(_event):
	if player_near and Input.is_action_just_pressed("ui_interact_door") and not is_animating:
		toggle_door()

# สำหรับ XR
func attempt_toggle():
	print("Door: '", name, "' received attempt_toggle. player_near: ", player_near)
	# ถ้าผู้เล่นอยู่ใกล้ และไม่ได้กำลังเล่น Animation อยู่
	if player_near and not is_animating:
	#if not is_animating:
		toggle_door()
	#else:
		#print("Condition failed: player_near=", player_near, " is_animating=", is_animating)

func toggle_door():
	is_animating = true
	if is_open:
		# --- จังหวะปิดประตู ---
		animation_player.play(close_animation)
		print("Open Door")
	else:
		# --- จังหวะเปิดประตู ---
		animation_player.play(open_animation)
		open_sound.play()
		print("Close Door")
	is_open = !is_open

func _on_AnimationPlayer_animation_finished(anim_name):
	is_animating = false
	if anim_name == close_animation:
		close_sound.play()
