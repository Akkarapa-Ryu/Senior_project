extends Node3D

@onready var viewport = $SubViewportContainer/SubViewport
@export var yellow_frame: MeshInstance3D

func _ready() -> void:
	yellow_frame.visible = false

# ฟังก์ชันสำหรับจับภาพและบันทึก
func capture_xray_scan(filename: String = "xray_snapshot"):
	yellow_frame.visible = !yellow_frame.visible
	# 1. รอให้ Frame Render เสร็จสมบูรณ์
	await RenderingServer.frame_post_draw
	
	# 2. ดึงข้อมูล Texture จาก SubViewport
	var viewport_texture = viewport.get_texture()
	
	# 3. แปลง Texture เป็น Image object เพื่อการจัดการที่ยืดหยุ่น
	var image_data = viewport_texture.get_image()
	
	# 4. สร้างชื่อไฟล์ที่ไม่ซ้ำ (เช่น เพิ่ม timestamp) หรือใช้ชื่อที่กำหนดมา
	#var final_path = "res://images/{0}_{1}.png".format([filename, Time.get_unix_time_from_system()])
	
	# 5. บันทึกภาพเป็นไฟล์ PNG
	#var save_result = image_data.save_png(final_path)
	
	#if save_result == OK:
		#print("X-ray Scan Captured: ", ProjectSettings.globalize_path(final_path))
	#else:
		#printerr("Error capturing scan: ", save_result)

# ตัวอย่างการเรียกใช้ (เช่น กด Spacebar เพื่อ Scan)
func _input(event):
	if event.is_action_pressed("ui_accept"):
		capture_xray_scan()
