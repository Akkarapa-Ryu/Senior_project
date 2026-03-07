extends Area3D
# ส่วนนี้มาจาก Gemini ------------------------------
var bodies_waiting_to_snap = []
@export var snap_pos: Marker3D

# Ref: https://forum.godotengine.org/t/how-to-change-meshinstance3d-to-another/77159
# 3d model ที่ต้องการเปลี่ยนรูปร่าง
var thermoplastic_mask_short_use_model = load("res://3d model/Equipment/Thermoplastic Mask Short Type_use.obj")
@export var model: MeshInstance3D
@export var attached_objects: Array[Node3D]
@export var bed_marker: Marker3D

var item_name = []
@export var max_slots = 3 # กำหนดว่าวางทับกันได้สูงสุดกี่ชิ้น

func _ready():
	# เชื่อมต่อสัญญาณ (Signal) เมื่อมีวัตถุเข้ามาในเขต
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	print("ตรวจพบวัตถุ: ", body.name) # ถ้าอันนี้ไม่ขึ้น แสดงว่าเป็นที่ Collision Layer/Mask
	if body.has_method("is_picked_up"):
		if not bodies_waiting_to_snap.has(body):
			bodies_waiting_to_snap.append(body)
			print("รอนับถอยหลังการปล่อยมือ: ", body.name)

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
		print("จุดนี้เต็มแล้ว! วางเพิ่มไม่ได้")
		return
	
	# ถ้ามัน Snap แล้ว อย่าให้มันมาอยู่ในคิวรออีก
	if bodies_waiting_to_snap.has(obj):
		bodies_waiting_to_snap.erase(obj)
	
	# ปิดฟิสิกส์เพื่อไม่ให้มันร่วงหรือขยับ
	#obj.freeze = true
	# --- เพิ่มส่วนนี้: เชื่อมต่อสัญญาณตอนโดนหยิบ ---
	if obj.has_signal("picked_up"):
		# ป้องกันการเชื่อมต่อซ้ำ (กัน Error)
		if not obj.is_connected("picked_up", _on_item_picked_up):
			obj.picked_up.connect(_on_item_picked_up.bind(obj))
	
	# ย้ายตำแหน่งไปที่ SnapPosition เป๊ะๆ
	var offset_y = Vector3(0, item_name.size() * 0.01, 0) # ขยับขึ้นข้างบนนิดหน่อยตามจำนวนชิ้น
	obj.global_position = snap_pos.global_position + offset_y
	obj.global_rotation = snap_pos.global_rotation
	
	# จัดการเรื่อง Mesh (ถ้าเป็นหน้ากากชิ้นที่กำหนด)
	if obj.is_in_group("mask") or obj.name.begins_with("thermoplastic_mask_short"):
		if model:
			model.mesh = thermoplastic_mask_short_use_model
			
	attach_all_to_bed()
	
	# add item name
	item_name.append(obj)
	
	if obj.has_method("on_snapped"):
		obj.on_snapped()

	print("วางสำเร็จ! (ชิ้นที่ ", item_name.size(), "/", max_slots, ")")
# ส่วนนี้มาจาก Gemini ------------------------------

# --- remove object from area ---
func release_object(obj):
	if obj in item_name:
		item_name.erase(obj)
		#obj.freese = false
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
		obj.freeze = false # คืนแรงโน้มถ่วงทันที!
		
		# ถ้าตอน Snap คุณสั่ง reparent ไปที่เตียง 
		# ตอนหยิบควรย้ายมันกลับมาที่ Scene หลัก (หรือ Parent ของ Area นี้)
		# เพื่อให้มันไม่ขยับตามเตียงเวลาโดนถือ
		if obj.get_parent() != get_parent():
			obj.reparent(get_parent(), true)
			
		print(obj.name, " ถูกหยิบออกจากจุด Snap: คืนแรงโน้มถ่วงแล้ว")
		
		# อย่าลืมลบออกจากรายชื่อใน Zone ด้วย
		release_object(obj)
