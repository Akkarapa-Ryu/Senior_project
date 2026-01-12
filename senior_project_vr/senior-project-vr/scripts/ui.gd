extends CanvasLayer


func _on_back_main_menu_pressed():
	print("Back to MainMenu")
	SceneTransition.change_scene("res://main_menu.tscn") 

func _on_back_choose_target_pressed():
	print("Back to MainMenu")
	SceneTransition.change_scene("res://scences/2_choose_target.tscn") 
	
