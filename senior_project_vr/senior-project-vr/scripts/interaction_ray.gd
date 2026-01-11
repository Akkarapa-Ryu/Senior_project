extends RayCast3D

# ส่วนนี้มาจาก Gemini ------------------------------
func _process(_delta):
	# 1. เช็คว่าลำแสงส่องไปโดนอะไรไหม
	if is_colliding():
		var target = get_collider() # วัตถุที่โดน
		
		# 2. เช็คว่าวัตถุนั้นมีฟังก์ชัน interact ไหม -> มาจากไฟล์ 3d_button.gd
		if target.has_method("interact"):
			# 3. เช็คว่าเรากดปุ่ม "E" (interact) หรือยัง
			if Input.is_action_just_pressed("interact"):
				target.interact() # สั่งให้ปุ่มทำงาน
# ส่วนนี้มาจาก Gemini ------------------------------
				#target.interact_info()
		#elif target.has_method("uninteract_info"):
			##print("func uninteract")
			#if Input.is_action_just_pressed("interact"):
				#target.uninteract_info()
