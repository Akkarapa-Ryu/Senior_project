extends Node3D

# ตั้งค่าตำแหน่งที่จะเซฟไฟล์ (เปลี่ยนได้ตามต้องการ)
#@export_global_dir var save_directory: String = "user://scans"
@export var mesh_path: NodePath # ลาก MeshInstance3D มาใส่ใน Inspector
@export var scan_duration: float = 5.0 # ปรับความช้าได้จากหน้าจอ Inspector (หน่วยเป็นวินาที)
@export var start_height: float = 1.0
@export var end_height: float = -1.0

@onready var viewport = $SubViewportContainer/SubViewport
var material : ShaderMaterial
#@export var yellow_frame: MeshInstance3D

func _ready():
	# ตรวจสอบและดึง Material จาก Mesh
	var mesh_node = get_node_or_null(mesh_path)
	if mesh_node and mesh_node is MeshInstance3D:
		material = mesh_node.get_active_material(0)
	#yellow_frame.visible = false
	
	# สร้างโฟลเดอร์สำหรับเซฟถ้ายังไม่มี
	#if not DirAccess.dir_exists_absolute(save_directory):
		#DirAccess.make_dir_recursive_absolute(save_directory)

func _process(delta):
	if material:
		# ทำให้จุดเข้มขยับขึ้นลงเบาๆ หรือเปลี่ยนขนาดตามเวลา
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
		material.set_shader_parameter("spot_size", 0.2 + (pulse * 0.1))

# --- ฟังก์ชันการทำงานหลัก ---

func animate_and_capture():
	if not material:
		push_error("ไม่พบ Material บนโมเดล กรุณาตรวจสอบ NodePath")
		return

	# 1. สร้าง Tween เพื่อเลื่อนจุดตัด (Slicing) จากบนลงล่าง
	var tween = create_tween()
	# สมมติโมเดลสูงระหว่าง 1.0 ถึง -1.0 (ปรับค่าตามขนาดโมเดลของคุณ)
	tween.tween_property(material, "shader_parameter/slice_height", end_height, scan_duration).from(start_height)
	
	# 2. เมื่อเลื่อนเลเยอร์การตัดเสร็จแล้ว ให้ทำการถ่ายภาพ
	tween.finished.connect(func():
		# รอให้เฟรมวาดเสร็จก่อน 1 เฟรม
		await get_tree().process_frame
		capture_xray_scan("mri_result")
	)

func capture_xray_scan(filename: String):
	# รอให้ Rendering Server วาดเสร็จสิ้น
	await RenderingServer.frame_post_draw
	
	# ดึงภาพจาก Viewport
	var image_data = viewport.get_texture().get_image()
	
	# ตั้งชื่อไฟล์พร้อมเวลาเพื่อไม่ให้ซ้ำกัน
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	#var final_path = save_directory + "/" + filename + "_" + timestamp + ".png"
	
	# บันทึกไฟล์
	#var save_result = image_data.save_png(final_path)
	
	#if save_result == OK:
		#print("สแกนและบันทึกสำเร็จที่: ", ProjectSettings.globalize_path(final_path))
	#else:
		#printerr("เกิดข้อผิดพลาดในการบันทึก: ", save_result)

# --- ปุ่มกดทดสอบ ---

func _input(event):
	# กด Spacebar (หรือปุ่ม Accept) เพื่อเริ่มกระบวนการ
	if event.is_action_pressed("ui_accept"):
		animate_and_capture()
