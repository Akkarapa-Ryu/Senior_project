@tool # ทำให้เห็นการเปลี่ยนแปลงในหน้า Editor ทันที
extends StaticBody3D

# ส่วนนี้มาจาก Gemini ------------------------------
@export_file("*.tscn") var target_scene_path: String # สร้างช่องใน Inspector ให้ลากไฟล์ฉากมาใส่ได้เลย
@export var custom_mesh: Mesh: # ช่องสำหรับเลือก Mesh ใน Inspector
	set(value):
		custom_mesh = value
		update_appearance()

@export var custom_scale: Vector3 = Vector3(1, 1, 1): # ช่องสำหรับปรับขนาดใน Inspector
	set(value):
		custom_scale = value
		update_appearance()
		
#signal button_clicked # ส่งสัญญาณออกไปเมื่อถูกกด
# ส่วนนี้มาจาก Gemini ------------------------------

@export var info_node: Node3D

func _ready() -> void:
	if info_node != null:
		info_node.visible = false
	else:
		print("Path Null")



# ส่วนนี้มาจาก Gemini ------------------------------
func update_appearance():
	# ตรวจสอบว่า Node ลูกถูกสร้างขึ้นมาจริงๆ หรือยัง (ป้องกัน Crash ตอนรันเกม)
	if not is_inside_tree(): 
		await ready # รอให้ Node พร้อมก่อนค่อยทำงาน
	
	var mesh_node = get_node_or_null("MeshInstance3D")
	var col_node = get_node_or_null("CollisionShape3D")
	
	if mesh_node and custom_mesh:
		mesh_node.mesh = custom_mesh
		mesh_node.scale = custom_scale
		
		# อัปเดต Collision
		if col_node:
			var new_shape = custom_mesh.create_trimesh_shape()
			col_node.set_deferred("shape", new_shape)
			col_node.scale = custom_scale

func interact():
	if Engine.is_editor_hint(): # ป้องกันไม่ให้ปุ่มทำงานตอนเราแก้ใน Editor
		return
		
	print("ปุ่มถูกกด!")
	# เล่น Animation ถ้ามี
	#if has_node("AnimationPlayer"):
		#$AnimationPlayer.play("press_anim")
	
	# ส่ง Signal ออกไปเพื่อให้ระบบอื่นทำงาน (เช่น เปิดประตู)
	#emit_signal("button_clicked")
# ส่วนนี้มาจาก Gemini ------------------------------

	if target_scene_path != "":
		print("วาร์ปไปฉาก: ", target_scene_path)
		SceneTransition.change_scene(target_scene_path)
	#elif info_node:
		#info_1.visible = true
	else:
		print("ยังไม่ได้ใส่ไฟล์ฉากใน Inspector นะ!")


	print("ปุ่มถูกกด เพื่อเปิด")
	if info_node:
		if info_node.visible == false:
			info_node.visible = true
		else:
			info_node.visible = false
	
