extends Node3D

@onready var model = $ScannedModel
@onready var viewport = $CaptureSystem/CaptureViewport
@onready var grid = $UI/Control/ScrollContainer/ResultGrid

@export var total_slices: int = 24
@export var start_y: float = 1
@export var end_y: float = -1

func _on_scan_button_pressed():
	print("ปุ่มถูกกดแล้ว!") # ดูว่าปุ่มเชื่อมติดไหม
	scan_model()

func scan_model():
	print("เริ่มการสแกน...")
	grid.get_children().make_read_only() # ลบภาพเก่า (ถ้ามี)
	for n in grid.get_children(): n.queue_free()

	var step = (start_y - end_y) / float(total_slices - 1)

	for i in range(total_slices):
		# 1. ขยับรอยตัด
		var current_h = start_y - (step * i)
		model.get_active_material(0).set_shader_parameter("slice_height", current_h)

		# 2. รอให้ GPU วาดภาพเสร็จ (ลองเพิ่มเป็น 2 เฟรมเพื่อความชัวร์)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw

		# 3. ดึงภาพออกมา
		var img = viewport.get_texture().get_image()
		
		# --- จุดเช็ก Error ---
		if img == null or img.is_empty():
			print("Error: ภาพที่ชั้น ", i, " ถ่ายไม่ติด (ภาพว่างเปล่า)")
			continue
		
		# 4. สร้างแผ่นภาพใน UI
		var tex = ImageTexture.create_from_image(img)
		var rect = TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(150, 150) # ต้องตั้งขนาด ไม่เช่นนั้นภาพจะเล็กจนมองไม่เห็น
		
		grid.add_child(rect)
		print("ถ่ายภาพชั้นที่ ", i, " สำเร็จ!")
