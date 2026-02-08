extends RayCast3D

@onready var promt_label = $"../../Control/Promt"

var promt_action = "button_interact"

# ส่วนนี้มาจาก Gemini ------------------------------
func _process(_delta):
	# 1. เช็คว่าลำแสงส่องไปโดนอะไรไหม
	if is_colliding():
		var target = get_collider() # วัตถุที่โดน
		
		# 2. เช็คว่าวัตถุนั้นมีฟังก์ชัน interact ไหม -> มาจากไฟล์ 3d_button.gd
		if target.has_method("interact_button"):
			# 3. เช็คว่าเรากดปุ่ม "E" (interact) หรือยัง
			if Input.is_action_just_pressed(promt_action):
				target.interact_button() # สั่งให้ปุ่มทำงาน
# ส่วนนี้มาจาก Gemini ------------------------------
	
	# Ref: https://www.youtube.com/watch?v=PAE42x7QkiE
		if target is interact_move_target:
			promt_label.text = target.get_promt()
			
			if Input.is_action_just_pressed(target.promt_action):
				target.interact_move_target(owner)
			else:
				promt_label.text = ""
				
		var brain_node = target as brain # กรณี script อยู่ที่ตัวมันเอง
		if not brain_node and target.get_parent() is brain:
			brain_node = target.get_parent()
		if brain_node:
			# print("เจอสมองแล้ว!")
			if Input.is_action_just_pressed(promt_action):
				# เรียกฟังก์ชันใน Brain.gd (เปลี่ยนชื่อให้ตรงกัน)
				brain_node.scan_model() 
				print("Scan Brain finish")
			
	else:
		promt_label.text = ""
		
