extends Area3D
# ส่วนนี้มาจาก Gemini ------------------------------
var bodies_waiting_to_snap = []
@export var snap_pos: Marker3D
@export var accepted_group: String = "" # ใส่ชื่อกลุ่ม เช่น "mask" หรือ "pillow"

# Ref: https://forum.godotengine.org/t/how-to-change-meshinstance3d-to-another/77159
# 3d model ที่ต้องการเปลี่ยนรูปร่าง
#var thermoplastic_mask_short_use_model = load("res://3d model/Equipment/Thermoplastic Mask Short Type_use.obj")
#@export var model: MeshInstance3D
@export var attached_objects: Array[Node3D]
@export var bed_marker: Marker3D

var item_name = []
@export var max_slots = 3 # กำหนดว่าวางทับกันได้สูงสุดกี่ชิ้น

func _ready():
	# เชื่อมต่อสัญญาณ (Signal) เมื่อมีวัตถุเข้ามาในเขต
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	# เช็คว่าวัตถุอยู่ในกลุ่มที่ต้องการไหม (ถ้าไม่ได้ตั้งค่าไว้ก็รับหมด)
	if accepted_group != "" and not body.is_in_group(accepted_group):
		return
		
	print("ตรวจพบวัตถุที่ถูกต้อง: ", body.name)
	if body.has_method("is_picked_up"):
		if not bodies_waiting_to_snap.has(body):
			bodies_waiting_to_snap.append(body)

func _on_body_exited(body):
	# ถ้าหยิบออกไปนอกเขตก่อนปล่อยมือ ให้ลบชื่อทิ้ง
	if bodies_waiting_to_snap.has(body):
		bodies_waiting_to_snap.erase(body)
		print("เอาออกจากคิวรอ: ", body.name)

func _process(_delta):
	# วนเช็ครายชื่อวัตถุที่แช่อยู่ใน Zone
	for body in bodies_waiting_to_snap:
		if is_instance_valid(body) and not body.is_picked_up():
			# ถ้าปล่อยมือแล้ว (is_picked_up == false)
			print("ปล่อยมือแล้ว! เริ่มกระบวนการ Snap...")
			
			# เอาออกจากคิวก่อน เพื่อไม่ให้มันสั่ง snap ซ้ำรัวๆ
			bodies_waiting_to_snap.erase(body)
			
			# สั่ง Snap
			call_deferred("snap_object", body)


# --- add object into area ---
func snap_object(obj):
	if item_name.size() >= max_slots:
		if bed_marker and bed_marker.get_parent().get("npc_label"):
			var label = bed_marker.get_parent().npc_label
			var original_text = label.text
			label.text = "จุดนี้เต็มแล้ว วางเพิ่มไม่ได้!"
			
			# รอ 2 วินาทีแล้วคืนค่าเดิม หรือซ่อนไป
			await get_tree().create_timer(2.0).timeout
			label.text = original_text
		print("จุดนี้เต็มแล้ว!")
		return
	
	if bodies_waiting_to_snap.has(obj):
		bodies_waiting_to_snap.erase(obj)

	# 1. เชื่อมต่อสัญญาณการหยิบ (ใช้ .bind เหมือนเดิมแต่เราแก้ฟังก์ชันรับแล้ว)
	if obj.has_signal("picked_up"):
		if not obj.is_connected("picked_up", _on_item_picked_up):
			obj.picked_up.connect(_on_item_picked_up)
	
	# 2. ปิดฟิสิกส์ให้หยุดนิ่ง
	if obj is RigidBody3D:
		obj.freeze = true
	
	# 4. เปลี่ยน Parent ไปที่เตียง เพื่อให้เคลื่อนที่ไปพร้อมกับเตียง/NPC
	if bed_marker:
		obj.reparent(bed_marker, true)
		
		# 3. ย้ายตำแหน่ง (ใช้ global_transform เพื่อความแม่นยำ)
		var offset_y = Vector3(0, item_name.size() * 0.01, 0)
		obj.global_position = snap_pos.global_position + offset_y
		obj.global_rotation = snap_pos.global_rotation

	# 5. เปลี่ยน Mesh (กรณีหน้ากาก)
	if obj.is_in_group("mask") or obj.name.begins_with("thermoplastic_mask_short"):
		# หา Node ลูกที่อยู่ในตัวหน้ากาก
		var m_normal = obj.get_node_or_null("MeshNormal")
		var m_used = obj.get_node_or_null("MeshUsed")
		# ดึง Node Highlight (ปรับชื่อให้ตรงตามภาพ _N และ _U)
		var hl_normal = obj.get_node_or_null("XRToolsHighlightVisible_Normal")
		var hl_used = obj.get_node_or_null("XRToolsHighlightVisible_Used")
		
		# ตรวจสอบว่า Node หลักๆ อยู่ครบไหมก่อนทำงาน
		if m_normal and m_used and hl_normal and hl_used:
			m_normal.hide() # ใช้ .hide() แทน .visible = false ได้ครับ
			m_used.show()
			
			hl_normal.hide()
			hl_used.show()
			
			# สำหรับลูกของ Highlight ถ้ามั่นใจว่าโครงสร้างเป๊ะ สั่งผ่านตัวแม่ได้เลย
			# หรือจะเจาะจงไปที่ MeshHighlight_used ก็ได้
			var m_h_used = hl_used.get_node_or_null("MeshHighlight_used")
			var m_h_normal = hl_normal.get_node_or_null("MeshHighlight_normal")
			var label_used = hl_used.get_node_or_null("Label3D_used")
			var label_normal = hl_used.get_node_or_null("Label3D_normal")
			var zone = obj.get_node_or_null("Zone")
			if m_h_used:
				m_h_normal.hide()
				label_normal.hide()
				m_h_used.show()
				label_used.show()
				zone.show()
			
		print("สลับเป็นหน้ากากทรงใช้งานแล้ว: ", obj.name)
	
	item_name.append(obj)
	if obj.has_method("on_snapped"):
		obj.on_snapped()

	print("วาง ", obj.name, " สำเร็จ!")
# ส่วนนี้มาจาก Gemini ------------------------------

# --- remove object from area ---
func release_object(obj):
	if obj in item_name:
		item_name.erase(obj)
		#obj.freeze = false
		print("หยิบของออกแล้ว เหลือที่ว่างเพิ่ม!")


func attach_all_to_bed():
	for obj in attached_objects:
		if is_instance_valid(obj) and obj != self: # ตรวจสอบว่า obj ไม่ใช่ตัวเองก่อนสั่ง
			if is_instance_valid(obj): # เช็คว่าวัตถุยังอยู่ในเกมไหม (ไม่ถูกลบไปก่อน)
				# 1. หยุดฟิสิกส์ (ถ้ามี)
				#if obj is RigidBody3D:
					#obj.freeze = true

				# 2. เปลี่ยนพ่อแม่มาเป็นเตียง
				obj.reparent(bed_marker, true)
				
				# 3. (Optional) จัดตำแหน่งของแต่ละชิ้น
				# ถ้าไม่อยากให้ของทับกันที่จุดเดียว อาจจะไม่ต้องเซต position = 0
				print("ยึด ", obj.name, " ติดกับเตียงเรียบร้อย")


func _on_item_picked_up(obj):
	if is_instance_valid(obj):
		# 1. ปลด Freeze และปลุกฟิสิกส์
		if obj is RigidBody3D:
			obj.freeze = false
			obj.sleeping = false # บังคับให้ตื่นมาคำนวณแรงโน้มถ่วง
			# แถม: ปรับแรงให้เป็นศูนย์ป้องกันมันพุ่งกระเด็นตอนหลุด
			obj.linear_velocity = Vector3.ZERO
			obj.angular_velocity = Vector3.ZERO
		
		# 2. สำคัญมาก: ย้ายออกจากเตียง (bed_marker) มาที่โลกภายนอก
		# ในโค้ดเดิมคุณสั่ง reparent กลับไปที่ bed_marker ทำให้มันลอยค้าง
		if obj.get_parent() == bed_marker:
			# ย้ายไปที่ root ของ scene ปัจจุบันเพื่อให้มันเป็นอิสระ
			obj.reparent(get_tree().current_scene, true)
			
		print(obj.name, " ถูกปลดจากเตียงแล้ว!")
		
		# 3. ลบรายชื่อออกจาก Array ของจุดวาง
		release_object(obj)
		
		# 4. ตัดการเชื่อมต่อสัญญาณ เพื่อไม่ให้มันเรียกฟังก์ชันนี้ซ้ำตอนเราไปวางที่อื่น
		if obj.is_connected("picked_up", _on_item_picked_up):
			obj.picked_up.disconnect(_on_item_picked_up)
