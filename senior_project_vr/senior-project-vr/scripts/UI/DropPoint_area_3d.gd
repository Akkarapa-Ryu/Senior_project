extends Area3D
# ส่วนนี้มาจาก Gemini ------------------------------
@onready var snap_pos = $"../SnapPosition" # อ้างอิงจุดที่เราจะให้ของไปวาง

# Ref: https://forum.godotengine.org/t/how-to-change-meshinstance3d-to-another/77159
# 3d model ที่ต้องการเปลี่ยนรูปร่าง
var thermoplastic_mask_short_use_model = load("res://3d model/Equipment/Thermoplastic Mask Short Type_use.obj")
@export var model: MeshInstance3D
#@onready var model = $"../thermoplastic_mask_short/MeshInstance3D"

func _ready():
	# เชื่อมต่อสัญญาณ (Signal) เมื่อมีวัตถุเข้ามาในเขต
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	# เช็คว่าสิ่งที่เข้ามาคือ RigidBody3D (ของที่เราถือ) หรือไม่
	if body is RigidBody3D:
		# ถ้าผู้เล่น "ไม่ได้ถือของชิ้นนี้อยู่" (คือปล่อยมือแล้วในเขตนี้)
		# หรือคุณอาจจะเช็คผ่าน Global Signal หรือตัวแปรกลางก็ได้
		var being_held = body.get_meta("is_being_held", false)
		if not being_held:
			call_deferred("snap_object", body) # รอให้ฟิสิกส์คำนวณเสร็จเรียบร้อยก่อน แล้วค่อยมารันฟังก์ชัน "snap_object" ทั้งก้อนในเฟรมถัดไป
		print("ของเข้ามาในเขตวางแล้ว")
		if body.name == "thermoplastic_mask_short":
			model.mesh = thermoplastic_mask_short_use_model
			

func snap_object(obj):
	# 1. ปิดฟิสิกส์เพื่อไม่ให้มันร่วงหรือขยับ
	obj.freeze = true
	
	# 2. ย้ายตำแหน่งไปที่ SnapPosition เป๊ะๆ
	obj.global_position = snap_pos.global_position
	obj.global_rotation = snap_pos.global_rotation
	
	# 3. (Optional) ปิดการชนเพื่อไม่ให้ตัวละครเดินชนแล้วกล่องดีด
	#obj.get_node("CollisionShape3D").disabled = true
	
	if obj.has_method("on_snapped"):
		obj.on_snapped()

	print("วางวัตถุลงจุดสำเร็จ!")

# ทริค: ในสคริปต์ Player ตอนฟังก์ชัน drop_object() 
# ให้เช็คว่า ray ส่องไปเจอ Area3D นี้ไหม ถ้าเจอให้ย้ายไปที่ snap_pos.global_position
# ส่วนนี้มาจาก Gemini ------------------------------
