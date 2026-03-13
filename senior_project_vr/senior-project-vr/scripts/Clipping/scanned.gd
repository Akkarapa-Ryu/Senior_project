# เปลี่ยนชื่อไฟล์เป็น "scan model"
# เอาโมเดลจาก node อื่นมาใส่แทนแล้วเอาตั้งค่ากล้องให้อยู่ที่เครื่อง CT แทน
extends Node3D

class_name ScanModel

@export_group("UI Controls")
@export var btn_sim: StaticBody3D
@export var btn_scan: StaticBody3D

@export_group("Model Settings")
@export var model: Node3D
@export var total_slices: int = 48
@export var slice_delay: float = 0.1 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)
@export var skeletal: MeshInstance3D

@export_group("Viewport & Grids")
@export var viewport_y: SubViewport # z-axis ของโมเดล เนื่องจากโมเดลมันมีการหมุนเปลี่ยนมุม
@export var viewport_x: SubViewport
@export var grid_y: GridContainer
@export var grid_x: GridContainer

#@export_group("Frame")
@onready var frame_yellow = $Sprite3D/CaptureSystem_y/CaptureViewport_y/CaptureCamera_y/Frame_yellow


var materials = []
var is_scanning = false

func _ready() -> void:
	# ค้นหา Material แบบละเอียด (ลึกแค่ไหนก็เจอ)
	if model:
		_find_materials_recursive(model)
	print("พบ Material ทั้งหมด: ", materials.size(), " ชิ้น")
	
	frame_yellow.visible = false
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


# ฟังก์ชันตรวจจับการคลิกด้วยเมาส์ (สำหรับ Debug บน PC)
#func _on_btn_sim_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#scan_model() # เปลี่ยนตามโจทย์: btn_sim -> scan_model
#
#func _on_btn_scan_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#if not is_scanning:
			#capture_model() # เปลี่ยนตามโจทย์: btn_scan -> capture_model

func capture_model():
	frame_yellow.visible = !frame_yellow.visible
	print("เริ่มทำการถ่ายรูป...")
	# ใส่ Logic สำหรับหมุนเครื่องหรือเปิดไฟที่นี่

func scan_model():
	if materials.is_empty() or is_scanning:
		return
	
	is_scanning = true
	print("เริ่มทำการสแกน...simulation")
	
	# หาขอบเขตของโมเดล (AABB) เพื่อความแม่นยำในการเลื่อน Slice
	var combined_aabb = _get_model_aabb(model)

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
	
	# --- ส่งสัญญาณว่า "สแกนเสร็จแล้ว" ไปที่ npc_movement.gd ---
	if model:
		await get_tree().create_timer(5.0).timeout
		model.start_post_scan_sequence()


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
