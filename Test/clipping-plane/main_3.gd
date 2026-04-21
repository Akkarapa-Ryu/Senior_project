# เปลี่ยนชื่อไฟล์เป็น "scan model"
# เอาโมเดลจาก node อื่นมาใส่แทนแล้วเอาตั้งค่ากล้องให้อยู่ที่เครื่อง CT แทน
extends Node3D

class_name brain

signal brain_button_clicked

@export var model: MeshInstance3D
@export var viewport_y: SubViewport
@export var viewport_x: SubViewport
@export var grid_y: GridContainer
@export var grid_x: GridContainer

@export var total_slices: int = 64
@export var slice_delay: float = 0.05 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)

var materials = []

# เนื่องจากเปลี่ยนเป็น Local Space ค่าเหล่านี้ควรสัมพันธ์กับขนาด Mesh จริงๆ
# เช่น ถ้า Mesh สูง 2 เมตร ค่าควรเป็น 1.0 ถึง -1.0
@export var start_y: float = 1.0 
@export var end_y: float = -1.0

func brain():
	print("รับสัญญาณการคลิก: กำลังเริ่มสแกน...")
	emit_signal("brain_button_clicked") # บอกคนอื่น (ถ้ามี) ว่าเริ่มสแกนแล้ว
	scan_model() # เรียกฟังก์ชันสแกนที่คุณเขียนไว้

func _ready() -> void:
	# วนหา Material ทั้งหมดในลูกทุกตัว (ทั้ง Human และ Brain)
	for child in model.find_children("*", "MeshInstance3D"):
		for i in range(child.get_surface_count()):
			var mat = child.get_active_material(i)
			if mat is ShaderMaterial:
				materials.append(mat)

func scan_model():
	print("เริ่มการสแกนหาขอบอัตโนมัติ...")
	#print("เริ่มการสแกน...")
	emit_signal("brain_button_clicked")
	
	## --- ส่วนที่เพิ่มเข้ามา: คำนวณขอบโมเดล ---
	#var aabb = model.get_aabb() # ดึงค่า "กล่องขอบเขต" ของโมเดล
	#var scale_y = model.scale.y # ดึงค่า Scale มาคำนวณด้วยในกรณีที่คุณย่อ/ขยายโมเดล
	#
	## หาค่าสูงสุดและต่ำสุดในพิกัด Local (เพื่อให้สอดคล้องกับ Shader)
	#var mesh_top = (aabb.position.y + aabb.size.y) * scale_y
	#var mesh_bottom = aabb.position.y * scale_y
	#
	## กำหนดค่าเริ่มต้นและสิ้นสุดตามขอบจริงของโมเดล
	#start_y = mesh_top
	#end_y = mesh_bottom
	## ---------------------------------------
#
	## ล้างภาพเก่า
	#for n in grid_y.get_children(): n.queue_free()
	#for n in grid_x.get_children(): n.queue_free()
#
	##var step = (start_y - end_y) / float(total_slices - 1)

	# 1. ล้างข้อมูลเก่า
	for n in grid_y.get_children(): n.queue_free()
	for n in grid_x.get_children(): n.queue_free()

	# --- ส่วนที่ 1: สแกนแนว Y (บนลงล่าง) ---
	var cam_y = viewport_y.get_camera_3d()
	var dist_y = cam_y.global_position.distance_to(model.global_position)
	var range_y = 0.3 # ลองปรับค่านี้ถ้าภาพยังไม่ถึงเนื้อสมอง
	
	for i in range(total_slices):
		var t = lerp(dist_y - range_y, dist_y + range_y, float(i) / float(total_slices - 1))
		update_all_materials(t)
		await RenderingServer.frame_post_draw
		_capture_to_grid(viewport_y, grid_y)
		await get_tree().create_timer(slice_delay).timeout

	# --- ส่วนที่ 2: สแกนแนว X (ซ้ายไปขวา) ---
	var cam_x = viewport_x.get_camera_3d()
	var dist_x = cam_x.global_position.distance_to(model.global_position)
	var range_x = 0.25 
	
	for i in range(total_slices):
		var t = lerp(dist_x - range_x, dist_x + range_x, float(i) / float(total_slices - 1))
		update_all_materials(t)
		await RenderingServer.frame_post_draw
		_capture_to_grid(viewport_x, grid_x)
		await get_tree().create_timer(slice_delay).timeout

# ฟังก์ชันช่วยเก็บภาพ (ช่วยให้โค้ดสะอาดขึ้น)
func _capture_to_grid(vp, grid):
	var img = vp.get_texture().get_image()
	if img and !img.is_empty():
		var tex = ImageTexture.create_from_image(img)
		var rect = TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(150, 150)
		grid.add_child(rect)

# ฟังก์ชันช่วย Update ทุกชิ้นส่วน (Human + Brain)
func update_all_materials(threshold_value):
	# ใส่ Material ของ Human
	model.get_active_material(0).set_shader_parameter("slice_threshold", threshold_value)
	# ใส่ Material ของ Brain (อ้างอิงตาม Node Name ในภาพของคุณ)
	var brain_mesh = get_node("Idle/Skeleton3D/Nervous_Cerebrum_Multicolor") # ปรับ Path ให้ตรง
	if brain_mesh:
		brain_mesh.get_active_material(0).set_shader_parameter("slice_threshold", threshold_value)
