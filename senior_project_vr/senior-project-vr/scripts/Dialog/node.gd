extends Node

# ลากไฟล์ main.dialogue จาก FileSystem มาวางในช่องนี้ที่ Inspector
@export var dialogue_resource: DialogueResource 

func _input(event):
	# กด Spacebar เพื่อเริ่มคุย (เอาไว้เทส)
	if event.is_action_pressed("ui_accept"):
		# คำสั่งนี้จะสร้าง Balloon ขึ้นมาบนหน้าจอให้อัตโนมัติ
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")
