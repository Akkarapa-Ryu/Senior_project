extends Area3D

# --- [ Export Variables ] ---
@export_group("Settings")
@export var snap_pos: Marker3D
@export var bed_marker: Marker3D
@export var accepted_group: String = ""
@export var max_slots: int = 3

# --- [ Internal Variables ] ---
var bodies_waiting_to_snap: Array[Node3D] = []
var placed_items: Array[Node3D] = [] # เปลี่ยนจาก item_name เพื่อความสื่อความหมาย

# --- [ Lifecycle Methods ] ---

func _ready() -> void:
	# เชื่อมต่อสัญญาณพื้นฐาน
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# วนเช็ควัตถุในเขตที่ผู้เล่นปล่อยมือแล้ว
	for body in bodies_waiting_to_snap:
		if is_instance_valid(body) and not body.is_picked_up():
			# นำออกจากคิวรอก่อนเพื่อป้องกันการเรียกซ้ำ
			bodies_waiting_to_snap.erase(body)
			# สั่ง Snap โดยใช้ call_deferred เพื่อความปลอดภัยเรื่อง Physics State
			call_deferred("snap_object", body)

# --- [ Signal Callbacks ] ---

func _on_body_entered(body: Node3D) -> void:
	if accepted_group != "" and not body.is_in_group(accepted_group):
		return
		
	if body.has_method("is_picked_up"):
		if body not in bodies_waiting_to_snap:
			bodies_waiting_to_snap.append(body)
			print("ตรวจพบวัตถุ: ", body.name)

func _on_body_exited(body: Node3D) -> void:
	if body in bodies_waiting_to_snap:
		bodies_waiting_to_snap.erase(body)
		print("วัตถุออกจากเขต: ", body.name)

func _on_item_picked_up(obj: Node3D) -> void:
	if is_instance_valid(obj):
		# 1. คืนค่าฟิสิกส์
		if obj is RigidBody3D:
			obj.freeze = false
			obj.sleeping = false
			obj.linear_velocity = Vector3.ZERO
			obj.angular_velocity = Vector3.ZERO
		
		# 2. ย้ายออกจาก Parent เดิม (เตียง) กลับไปที่ Scene Root
		if obj.get_parent() == bed_marker:
			obj.reparent(get_tree().current_scene, true)
			
		print(obj.name, " ถูกหยิบออกจากจุดวาง")
		
		# 3. เคลียร์ข้อมูลออกจากระบบของจุดวาง
		release_object(obj)
		
		# 4. ตัดการเชื่อมต่อสัญญาณ
		if obj.is_connected("picked_up", _on_item_picked_up):
			obj.picked_up.disconnect(_on_item_picked_up)

# --- [ Core Logic ] ---

func snap_object(obj: Node3D) -> void:
	# 1. ตรวจสอบเงื่อนไขว่าเต็มหรือยัง
	if placed_items.size() >= max_slots:
		_show_full_warning()
		return

	# 2. ตั้งค่า Physics และการติดตาม (Signals)
	if obj.has_signal("picked_up"):
		if not obj.is_connected("picked_up", _on_item_picked_up):
			obj.picked_up.connect(_on_item_picked_up)
	
	if obj is RigidBody3D:
		obj.freeze = true

	# 3. ย้ายตำแหน่งและเปลี่ยน Parent
	if bed_marker and snap_pos:
		obj.reparent(bed_marker, true)
		
		# คำนวณตำแหน่งวางซ้อน (Offset)
		var offset_y = Vector3(0, placed_items.size() * 0.01, 0)
		obj.global_position = snap_pos.global_position + offset_y
		obj.global_rotation = snap_pos.global_rotation

	# 4. จัดการรูปลักษณ์ (กรณีเป็นหน้ากาก)
	_update_mask_visuals(obj)
	
	# 5. บันทึกข้อมูล
	placed_items.append(obj)
	
	if obj.has_method("on_snapped"):
		obj.on_snapped()

	print("วาง ", obj.name, " สำเร็จ (ชิ้นที่ ", placed_items.size(), ")")

func release_object(obj: Node3D) -> void:
	if obj in placed_items:
		placed_items.erase(obj)

# --- [ Helper Functions ] ---

# ฟังก์ชันจัดการการสลับ Mesh ของหน้ากาก
func _update_mask_visuals(obj: Node3D) -> void:
	var is_mask = obj.is_in_group("mask") or obj.name.begins_with("thermoplastic_mask_short")
	if not is_mask:
		return

	# รายชื่อ Node ที่ต้องซ่อน/แสดง
	var nodes_to_hide = ["MeshNormal", "XRToolsHighlightVisible_Normal"]
	var nodes_to_show = ["MeshUsed", "XRToolsHighlightVisible_Used", "Zone"]

	for n in nodes_to_hide:
		var node = obj.get_node_or_null(n)
		if node: node.hide()

	for n in nodes_to_show:
		var node = obj.get_node_or_null(n)
		if node: node.show()

	# จัดการลูกข้างใน Highlight (ถ้ามี)
	var hl_used = obj.get_node_or_null("XRToolsHighlightVisible_Used")
	if hl_used:
		for child in hl_used.get_children():
			if child is MeshInstance3D or child is Label3D:
				child.show()
				
	print("ปรับปรุง Visuals สำหรับ: ", obj.name)

# ฟังก์ชันแสดงคำเตือนเมื่อจุดวางเต็ม
func _show_full_warning() -> void:
	if bed_marker and bed_marker.get_parent().get("npc_label"):
		var label = bed_marker.get_parent().npc_label
		var original_text = label.text
		label.text = "จุดนี้เต็มแล้ว วางเพิ่มไม่ได้!"
		
		await get_tree().create_timer(2.0).timeout
		label.text = original_text
	print("Warning: Snap zone is full.")
