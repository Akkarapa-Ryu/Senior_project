extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var settings_menu: Panel = $SetttingsMenu
@onready var exit_menu: Panel = $ExitMenu

func _ready():
	main_buttons.visible = true
	settings_menu.visible = false
	exit_menu.visible = false

func _on_go_2_choose_target_pressed() -> void:
	print("Start pressed")
	#get_tree().change_scene_to_file("res://scences/2_trainning.tscn")
	# มีการใช้ฉากเปลี่ยน scene โดยเรียก func change_scene จาก scence_transation.gd มาใช้งาน
	# โดย func change_scene นี้ ได้ถูกเพิ่มไปเป็นคำสั่งที่ Project > Project Settings > Globals ชื่อว่า "SceneTransition"
	SceneTransition.change_scene("res://scences/2_choose_target.tscn") 

func _on_go_settings_pressed() -> void:
	print("Setting")
	main_buttons.visible = false # ตั้งค่าไม่ให้เห็น MainButtons
	settings_menu.visible = true # ตั้งค่าให้เห็น Setting

func _on_back_settings_pressed() -> void:
	_ready()

func _on_go_exit_pressed() -> void:
	print("Exit")
	main_buttons.visible = false
	exit_menu.visible = true

func  _on_back_exit_pressed() -> void:
	_ready()
