# เปลี่ยนชื่อไฟล์เป็น "scan model"
# เอาโมเดลจาก node อื่นมาใส่แทนแล้วเอาตั้งค่ากล้องให้อยู่ที่เครื่อง CT แทน
extends Node3D

class_name ScanModel

@export_group("UI Controls")
@export var btn_sim: StaticBody3D
@export var btn_scan: StaticBody3D

@export_group("Model Settings")
@export var npc_model: Node3D
@export var total_slices: int = 48
@export var slice_delay: float = 0.1 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)
@export var skeletal: MeshInstance3D
@export var bed_model: MeshInstance3D

@export_group("Viewport & Grids")
@export var viewport_y: SubViewport # z-axis ของโมเดล เนื่องจากโมเดลมันมีการหมุนเปลี่ยนมุม
@export var viewport_x: SubViewport
@export var grid_y: GridContainer
@export var grid_x: GridContainer
@export var capture_viewport_x: SubViewport
@export var capture_viewport_y: SubViewport

#@export_group("Frame")
@onready var decal_x = $Sprite3D/CaptureSystem_y/CaptureViewport_y/CaptureCamera_y/Decal_X
@onready var decal_y = $Sprite3D/CaptureSystem_y/CaptureViewport_y/CaptureCamera_y/Decal_Y
@onready var decal_z = $Sprite3D/CaptureSystem_x/CaptureViewport_x/CaptureCamera_x/Decal_Z


var materials = []
var is_scanning = false
var original_bed_pos: Vector3 # ตัวแปรเก็บตำแหน่งเริ่มต้นของเตียง

func _ready() -> void:
	# ค้นหา Material แบบละเอียด (ลึกแค่ไหนก็เจอ)
	if npc_model:
		_find_materials_recursive(npc_model)
	print("พบ Material ทั้งหมด: ", materials.size(), " ชิ้น")
	
	decal_x.visible = false
	decal_y.visible = false
	decal_z.visible = false
	skeletal.visible = true

# ฟังก์ชันช่วยหา Material ในลูกหลานทุกชั้น
func _find_materials_recursive(node: Node):
	if node is MeshInstance3D:
		# ต้องเข้าถึงข้อมูล mesh ก่อนถึงจะนับ Surface ได้
		if node.mesh:
			for i in node.mesh.get_surface_count():
				# การดึง Material จากตัว MeshInstance (เผื่อมีการทำ Material Override)
				var mat = node.get_active_material(i)
				if mat is ShaderMaterial:
					materials.append(mat)
					print("พบ Shader ที่: ", node.name, " (Surface ", i, ")")
	
	# วนลูปหาในลูกต่อ (Recursive)
	for child in node.get_children():
		_find_materials_recursive(child)

# --- Scout ---
func scout_model():
	# 0. เตรียมการและ Reset
	print("เริ่มกระบวนการถ่ายรูป X และ Y...")
	original_bed_pos = bed_model.position # เก็บค่าตำแหน่งเดิมไว้
	print("original_bed_pos: ", )
	
	# --- ขั้นตอนที่ 1: ถ่ายแนว X ---
	print("1. กำลังเลื่อนเตียงเข้าตำแหน่ง (X)...")
	decal_x.show() # เปิด Decal X
	decal_z.show()
	await move_bed(Vector3(original_bed_pos.x, original_bed_pos.y, -0.3))
	
	print("2. บันทึกภาพ CaptureCamera_x...")
	# สั่งให้ Viewport อัปเดตแค่เฟรมเดียว (เหมือนการกดชัตเตอร์)
	capture_viewport_x.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame # รอ 1 เฟรมเพื่อให้ GPU วาดภาพเสร็จ
	
	# --- ขั้นตอนที่ 2: เลื่อนเตียงออก ---
	print("3. เลื่อนเตียงกลับจุดเริ่มต้น...")
	decal_x.hide()
	decal_z.hide()
	await move_bed(original_bed_pos)
	await get_tree().create_timer(0.5).timeout # พักหายใจครู่หนึ่ง
	
	# --- ขั้นตอนที่ 3: ถ่ายแนว Y ---
	print("4. กำลังเลื่อนเตียงเข้าตำแหน่ง (Y)...")
	decal_y.show()
	decal_x.show() # เปิด Decal Y
	await move_bed(Vector3(original_bed_pos.x, original_bed_pos.y, -0.3))
	
	print("5. บันทึกภาพ CaptureCamera_y...")
	capture_viewport_y.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	# --- ขั้นตอนสุดท้าย: เลื่อนกลับและเสร็จสิ้น ---
	print("6. เสร็จสิ้นกระบวนการ เลื่อนเตียงกลับ...")
	decal_y.hide()
	decal_x .hide()
	await move_bed(original_bed_pos)
	print("ถ่ายรูปเรียบร้อยทั้งสองแกน!")

# ฟังก์ชันเสริมสำหรับเลื่อนเตียงและรอให้เสร็จ (Helper Function)
func move_bed(target_pos: Vector3) -> Signal:
	var tween = create_tween()
	tween.tween_property(bed_model, "position", target_pos, 1.5).set_trans(Tween.TRANS_SINE)
	return tween.finished # ส่งคืน Signal เพื่อให้ใช้ await ได้
# --- Scout ---


#--- Simulation ---
func scan_model():
	if materials.is_empty() or is_scanning:
		return
	
	capture_viewport_x.render_target_update_mode = SubViewport.UPDATE_DISABLED
	capture_viewport_y.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await move_bed(Vector3(original_bed_pos.x, original_bed_pos.y, -0.3))
	is_scanning = true
	print("เริ่มทำการสแกน...simulation")
	
	# หาขอบเขตของโมเดล (AABB) เพื่อความแม่นยำในการเลื่อน Slice
	var combined_aabb = _get_model_aabb(npc_model)

	# ล้างข้อมูลเก่าใน Grid
	for n in grid_x.get_children(): n.queue_free()
	for n in grid_y.get_children(): n.queue_free()

	skeletal.visible = false
	# เปิดโหมด Slicing
	for mat in materials:
		mat.set_shader_parameter("is_slicing", true)

	# --- สแกนแกน X (Side View) ---
	print("_run_scan_loop: X")
	await _run_scan_loop(Vector3(-1, 0, 0), combined_aabb.position.x, combined_aabb.end.x, viewport_x, grid_x)
	
	# --- wait a minite for start ---
	#await get_tree().create_timer(5).timeout
	print("รอ 3 วินาที")
	for n in range(3):
		print("wait : ", n + 1)
		await get_tree().create_timer(1.0).timeout
	
	# --- สแกนแกน Z (Front View) ---
	print("_run_scan_loop: Z")
	await _run_scan_loop(Vector3(0, 0, 1), combined_aabb.position.z, combined_aabb.end.z, viewport_y, grid_y)
	
	# ปิดโหมด Slicing
	for mat in materials:
		mat.set_shader_parameter("is_slicing", false)
	skeletal.visible = true
	
	is_scanning = false
	print("การสแกนเสร็จสมบูรณ์")
	await move_bed(original_bed_pos)
	
	# --- ส่งสัญญาณว่า "สแกนเสร็จแล้ว" ไปที่ npc_movement.gd ---
	#if npc_model:
		#await get_tree().create_timer(5.0).timeout
		#npc_model.start_post_scan_sequence()


# ฟังก์ชันคำนวณหาขนาดโมเดลรวม
func _get_model_aabb(parent: Node3D) -> AABB:
	var full_aabb = AABB()
	var first = true
	# ใช้การหาลูกแบบ Recursive เพื่อหา Mesh ทั้งหมด
	for child in parent.find_children("*", "MeshInstance3D", true):
		var mesh_aabb = child.global_transform * child.get_aabb() # ใช้ค่า Global เพื่อความแม่นยำ
		if first:
			full_aabb = mesh_aabb
			first = false
		else:
			full_aabb = full_aabb.merge(mesh_aabb)
	return full_aabb


# ฟังก์ชันที่เาอไว้วนทำ slicing ของในแต่ละแกนของโมเดล
func _run_scan_loop(normal: Vector3, start: float, end: float, vp: SubViewport, grid: GridContainer):
	# เริ่มต้นค่าใน Shader
	for mat in materials:
		mat.set_shader_parameter("is_slicing", true)
		mat.set_shader_parameter("slice_normal", normal)

	for i in range(total_slices):
		var current_step = lerp(start, end, float(i) / float(total_slices - 1))
		
		for mat in materials:
			mat.set_shader_parameter("slice_dist", current_step)
		
		# 1. รอให้ Shader อัปเดตตำแหน่ง (สำคัญมากสำหรับการทำแบบช้าๆ)
		await get_tree().process_frame
		
		# 2. สั่งให้ Viewport วาดภาพเพียงครั้งเดียวในเฟรมนี้
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		# 3. รอให้การวาดภาพเสร็จสมบูรณ์ (Post Draw) ก่อนจะจับภาพลง Grid
		await RenderingServer.frame_post_draw 
		
		# 4. บันทึกภาพแผ่น Slice ที่บางและคมลงใน Grid
		_capture_to_grid(vp, grid)
		
		# 5. หน่วงเวลาเพื่อให้คนดู (User ใน VR) เห็นกระบวนการสแกนแบบค่อยเป็นค่อยไป
		if slice_delay > 0:
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
# --- Simulation ---
