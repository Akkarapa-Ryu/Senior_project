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

@export var total_slices: int = 32
@export var slice_delay: float = 0.05 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)

# เนื่องจากเปลี่ยนเป็น Local Space ค่าเหล่านี้ควรสัมพันธ์กับขนาด Mesh จริงๆ
# เช่น ถ้า Mesh สูง 2 เมตร ค่าควรเป็น 1.0 ถึง -1.0
@export var start_y: float = 1.0 
@export var end_y: float = -1.0

func brain():
	print("รับสัญญาณการคลิก: กำลังเริ่มสแกน...")
	emit_signal("brain_button_clicked") # บอกคนอื่น (ถ้ามี) ว่าเริ่มสแกนแล้ว
	scan_model() # เรียกฟังก์ชันสแกนที่คุณเขียนไว้


func scan_model():
	print("เริ่มการสแกนหาขอบอัตโนมัติ...")
	#print("เริ่มการสแกน...")
	emit_signal("brain_button_clicked")
	
	# --- ส่วนที่เพิ่มเข้ามา: คำนวณขอบโมเดล ---
	var aabb = model.get_aabb() # ดึงค่า "กล่องขอบเขต" ของโมเดล
	var scale_y = model.scale.y # ดึงค่า Scale มาคำนวณด้วยในกรณีที่คุณย่อ/ขยายโมเดล
	
	# หาค่าสูงสุดและต่ำสุดในพิกัด Local (เพื่อให้สอดคล้องกับ Shader)
	var mesh_top = (aabb.position.y + aabb.size.y) * scale_y
	var mesh_bottom = aabb.position.y * scale_y
	
	# กำหนดค่าเริ่มต้นและสิ้นสุดตามขอบจริงของโมเดล
	start_y = mesh_top
	end_y = mesh_bottom
	# ---------------------------------------

	# ล้างภาพเก่า
	for n in grid_y.get_children(): n.queue_free()
	for n in grid_x.get_children(): n.queue_free()

	var step = (start_y - end_y) / float(total_slices - 1)

	for i in range(total_slices):
		var current_h = start_y - (step * i)
		model.get_active_material(0).set_shader_parameter("slice_height", current_h)

		await RenderingServer.frame_post_draw
		
		# ใส่ Delay เพื่อให้เห็นความเร็วที่ช้าลง (ตามที่คุณต้องการ)
		await get_tree().create_timer(0.05).timeout 

		var img_y = viewport_y.get_texture().get_image()
		var img_x = viewport_x.get_texture().get_image()
		
		if img_y != null and !img_y.is_empty():
			var tex = ImageTexture.create_from_image(img_y)
			var rect = TextureRect.new()
			rect.texture = tex
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.custom_minimum_size = Vector2(150, 150)
			grid_y.add_child(rect)
		
		if img_x != null and !img_x.is_empty():
			var tex = ImageTexture.create_from_image(img_x)
			var rect = TextureRect.new()
			rect.texture = tex
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.custom_minimum_size = Vector2(150, 150)
			grid_x.add_child(rect)
