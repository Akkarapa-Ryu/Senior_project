extends StaticBody3D


func _on_interactable_area_button_button_pressed(button: Variant) -> void:
	print("Full Path: ", button.get_path()) # จะเห็นเลยว่ามันไล่จากไหนไปไหน
	print("Parent Name: ", button.get_parent().name)
