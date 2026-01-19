extends Node3D

# ลากไฟล์ .dialogue ที่คุณเขียนไว้มาใส่ตรงนี้
@export var dialogue_resource: DialogueResource
@export var dialogue_start_node: String = "start"

func start_conversation():
	# สั่งให้ Dialogue Manager แสดงผล
	# ใน VR เราต้องบอกให้มันไปแสดงที่ SubViewport ของเรา
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start_node)

# ฟังคำสั่งจากการยิงเลเซอร์มาโดน หรือเดินเข้าใกล้
func _on_interactable_area_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		start_conversation()
