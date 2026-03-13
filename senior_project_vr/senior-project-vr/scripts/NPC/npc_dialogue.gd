extends Node3D

signal dialogue_finished

@onready var npc_main = get_parent()
var current_dialogue_line: DialogueLine
var is_processing: bool = false # กันการกดรัวๆ
var current_resource_index: int = 0 # Resource ลำดับที่เท่าไหร่

func interact_talking():
	if is_processing: return
	
	is_processing = true
	
	# ตรวจสอบว่ามี Resource ใน Array ไหม เพื่อป้องกัน Error index out of bounds
	if npc_main.dialogue_resource.size() <= current_resource_index:
		print("Error: ไม่พบไฟล์บทสนทนาที่ Index: ", current_resource_index)
		is_processing = false
		return

	# 1. เริ่มบทสนทนาใหม่ (ระบุ Index ของ Array)
	if not npc_main.is_talking:
		current_dialogue_line = await DialogueManager.get_next_dialogue_line(
			npc_main.dialogue_resource[current_resource_index], # ดึงไฟล์ตาม Index
			npc_main.dialogue_start_node
		)
		if current_dialogue_line:
			npc_main.is_talking = true
			show_current_line()
	
	# 2. ไปบรรทัดถัดไป
	elif current_dialogue_line:
		var next_line = await DialogueManager.get_next_dialogue_line(
			npc_main.dialogue_resource[current_resource_index], # ดึงไฟล์ตาม Index
			current_dialogue_line.next_id
		)
		if next_line:
			current_dialogue_line = next_line
			show_current_line()
		else:
			finish_dialogue()

	is_processing = false


func show_current_line():
	if not current_dialogue_line: return
	
	var speaker = current_dialogue_line.character
	var message = current_dialogue_line.text
	
	hide_all_ui()
	
	# เงื่อนไขเช็คว่าใครพูด (ถ้าชื่อตรงกับไฟล์ Dialogue)
	if speaker == "NPC" or speaker == "":
		update_ui(npc_main.npc_ui, npc_main.npc_label, message)
	else:
		# ถ้าไม่ใช่ NPC ให้ Player_XR เป็นคนพูด
		if npc_main.player_ui:
			update_ui(npc_main.player_ui, npc_main.player_label, message)

func finish_dialogue():
	print("--- คุยจบแล้ว ---")
	npc_main.is_talking = false
	current_dialogue_line = null
	hide_all_ui()
	dialogue_finished.emit()


func hide_all_ui():
	if npc_main.npc_ui: npc_main.npc_ui.visible = false
	if npc_main.player_ui: npc_main.player_ui.visible = false


func update_ui(ui, label, text):
	if ui == null:
		print("Error: UI Node is missing!") # ถ้าขึ้นอันนี้ แสดงว่าลืมลากใส่ Inspector
		return
	
	ui.visible = true
	label.text = text
	print("Showing dialogue on: ", ui.name, " with text: ", text)


# --- ฟังก์ชันใหม่: เรียกใช้เมื่อต้องการเจาะจงไฟล์และจุดเริ่มต้น ---
func start_specific_dialogue(resource_index: int, label_name: String):
	if is_processing: return
	
	# อัปเดต index ปัจจุบัน เพื่อให้เวลากด Interact ต่อ มันยังใช้ไฟล์เดิม
	current_resource_index = resource_index 
	
	is_processing = true
	
	# ตรวจสอบความปลอดภัยของ Array
	if resource_index < npc_main.dialogue_resource.size():
		current_dialogue_line = await DialogueManager.get_next_dialogue_line(
			npc_main.dialogue_resource[resource_index], 
			label_name
		)
		
		if current_dialogue_line:
			npc_main.is_talking = true
			show_current_line()
	else:
		print("Error: Index ", resource_index, " ไม่มีอยู่ใน Array ของ dialogue_resource")
		
	is_processing = false
