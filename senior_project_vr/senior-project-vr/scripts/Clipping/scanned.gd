# เปลี่ยนชื่อไฟล์เป็น "scan model"
# เอาโมเดลจาก node อื่นมาใส่แทนแล้วเอาตั้งค่ากล้องให้อยู่ที่เครื่อง CT แทน
extends Node3D

class_name ScanModel

@export_group("UI Controls")
@export var btn_sim: StaticBody3D
@export var btn_scan: StaticBody3D

@export_group("Model Settings")
@export var model: Node3D
@export var total_slices: int = 64
@export var slice_delay: float = 0.01 # ยิ่งมากยิ่งช้า (หน่วยเป็นวินาที)

@export_group("Viewport & Grids")
@export var viewport_y: SubViewport # z-axis ของโมเดล เนื่องจากโมเดลมันมีการหมุนเปลี่ยนมุม
@export var viewport_x: SubViewport
@export var grid_y: GridContainer
@export var grid_x: GridContainer

var materials = []
var is_scanning = false

func _ready() -> void:
	# ค้นหา Material แบบละเอียด (ลึกแค่ไหนก็เจอ)
	if model:
		_find_materials_recursive(model)
	print("พบ Material ทั้งหมด: ", materials.size(), " ชิ้น")
	
	if btn_sim:
		btn_sim.input_event.connect(_on_btn_sim_input_event)
	if btn_scan:
		btn_scan.input_event.connect(_on_btn_scan_input_event)

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


func brain():
	scan_model() # เรียกฟังก์ชันสแกนที่คุณเขียนไว้

# ฟังก์ชันตรวจจับการคลิกที่ปุ่ม btn_sim
func _on_btn_sim_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		start_simulation()

# ฟังก์ชันตรวจจับการคลิกที่ปุ่ม btn_scan
func _on_btn_scan_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_scanning:
			scan_model()

func start_simulation():
	print("เริ่มระบบจำลองเครื่อง CT...")
	# ใส่ Logic สำหรับหมุนเครื่องหรือเปิดไฟที่นี่

func scan_model():
	if materials.is_empty() or is_scanning:
		return
	
	is_scanning = true
	print("เริ่มทำการสแกน...")
	
	# หาขอบเขตของโมเดล (AABB) เพื่อความแม่นยำในการเลื่อน Slice
	var combined_aabb = _get_model_aabb(model)

	# ล้างข้อมูลเก่าใน Grid
	for n in grid_x.get_children(): n.queue_free()
	for n in grid_y.get_children(): n.queue_free()

	# เปิดโหมด Slicing
	for mat in materials:
		mat.set_shader_parameter("is_slicing", true)

	# --- สแกนแกน X (Side View) ---
	await _run_scan_loop(Vector3(1, 0, 0), combined_aabb.position.x, combined_aabb.end.x, viewport_x, grid_x)

	# --- สแกนแกน Z (Front View) ---
	await _run_scan_loop(Vector3(0, 0, 1), combined_aabb.position.z, combined_aabb.end.z, viewport_y, grid_y)

	# ปิดโหมด Slicing
	for mat in materials:
		mat.set_shader_parameter("is_slicing", false)
	
	is_scanning = false
	print("การสแกนเสร็จสมบูรณ์")


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
		var mesh_aabb = child.get_transformed_aabb() # ใช้ค่า Global เพื่อความแม่นยำ
		if first:
			full_aabb = mesh_aabb
			first = false
		else:
			full_aabb = full_aabb.merge(mesh_aabb)
	return full_aabb

# ฟังก์ชัน Loop การสแกนแบบแม่นยำ
func _run_scan_loop(normal: Vector3, start: float, end: float, vp: SubViewport, grid: GridContainer):
	for i in range(total_slices):
		var dist = lerp(start, end, float(i) / float(total_slices - 1))
		
		for mat in materials:
			mat.set_shader_parameter("slice_normal", normal)
			mat.set_shader_parameter("slice_dist", dist)
		
		# บังคับ Update Viewport และรอ GPU เรนเดอร์
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame 
		await RenderingServer.frame_post_draw 
		
		_capture_to_grid(vp, grid)
		
		if slice_delay > 0:
			await get_tree().create_timer(slice_delay).timeout
