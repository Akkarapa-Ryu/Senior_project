extends Node3D

@export var model: Node3D
@onready var viewport_y = $CaptureSystem_y/CaptureViewport_y
@onready var viewport_x = $CaptureSystem_x/CaptureViewport_x
@onready var grid_y = $UI/Control/ScrollContainer_y/ResultGrid_y
@onready var grid_x = $UI/Control/ScrollContainer_x/ResultGrid_x

@export var total_slices: int = 32
@export var slice_delay: float = 0.05 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)

# เนื่องจากเปลี่ยนเป็น Local Space ค่าเหล่านี้ควรสัมพันธ์กับขนาด Mesh จริงๆ
# เช่น ถ้า Mesh สูง 2 เมตร ค่าควรเป็น 1.0 ถึง -1.0
@export var start_y: float = 1.0 
@export var end_y: float = -1.0

func _on_scan_button_pressed():
	scan_model()

func scan_model():
	print("เริ่มการสแกนหาขอบอัตโนมัติ...")
	
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
