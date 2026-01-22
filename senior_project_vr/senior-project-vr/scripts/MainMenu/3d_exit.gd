extends StaticBody3D

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# 1. เช็คว่าเป็นเหตุการณ์จากเมาส์
	if event is InputEventMouseButton:
		# 2. เช็คว่าเป็นคลิกซ้าย และเป็นการกดลง (pressed)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("กำลังปิดเกม...")
			get_tree().quit()
