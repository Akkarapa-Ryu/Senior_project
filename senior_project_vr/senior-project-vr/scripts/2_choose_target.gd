extends Node3D


func _on_go_5_trainning_pressed() -> void:
	print("กำลังเปลี่ยนฉาก...")
	SceneTransition.change_scene("res://scences/5_trainning.tscn")
