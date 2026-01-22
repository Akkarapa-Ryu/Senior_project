extends Node3D

# ส่วนนี้มาจาก Gemini ------------------------------
signal dialogue_finished # สัญญาณแจ้งเตือนเมื่อคุยจบ (เอาไว้ให้สคริปต์อื่นมาฟังได้ เช่น ให้ประตูเปิด)

@onready var npc_main = get_parent() # อ้างอิงไฟล์หลัก
var current_dialogue_line: DialogueLine # เก็บข้อมูลบรรทัดปัจจุบัน


func interact_talking():
	# 1. ถ้ายังไม่มีการคุย ให้ดึงบรรทัดแรกมา
	if not npc_main.is_talking:
		if current_dialogue_line == null:
			current_dialogue_line = await DialogueManager.get_next_dialogue_line(npc_main.dialogue_resource, npc_main.dialogue_start_node)
			if current_dialogue_line:
				npc_main.is_talking = true
				show_current_line()
			return
	
	# 2. ถ้ามีบรรทัดให้แสดง ถ้ากำลังคุยอยู่
	if npc_main.is_talking and current_dialogue_line:
		var next_line = await DialogueManager.get_next_dialogue_line(npc_main.dialogue_resource, current_dialogue_line.next_id)
		if next_line:
			current_dialogue_line = next_line
			show_current_line()
		else:
			finish_dialogue()


func show_current_line():
		var speaker = current_dialogue_line.character # ชื่อตัวละครที่เราพิมพ์ในไฟล์ (เช่น NPC:)
		var message = current_dialogue_line.text # ข้อความบทพูด
		
		if speaker == "NPC":
			update_ui(npc_main.npc_ui, npc_main.npc_label, message)
			if npc_main.player_ui: npc_main.player_ui.visible = false
		else:
			if npc_main.player_ui:
				update_ui(npc_main.player_ui, npc_main.player_label, message)
			npc_main.npc_ui.visible = false


func finish_dialogue(): # ฟังก์ชันปิดการสนทนา
	print("--- คุยครบทุกประโยคแล้ว ---")
	npc_main.is_talking = false
	current_dialogue_line = null
	npc_main.npc_ui.visible = false
	if npc_main.player_ui: npc_main.player_ui.visible = false
	dialogue_finished.emit() # ส่งสัญญาณออกไป


func update_ui(ui, label, text):
	ui.visible = true
	label.text = text


# ส่วนนี้มาจาก Gemini ------------------------------
