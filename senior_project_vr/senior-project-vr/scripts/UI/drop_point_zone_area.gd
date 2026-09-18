extends Node3D

# ลาก Area3D และ MeshInstance3D มาใส่ใน Inspector
@export var detection_area: Area3D
@export var preview_mesh: MeshInstance3D

# กำหนดชื่อ Group ที่ต้องการ (แก้ชื่อ "MedicalTools" เป็นชื่อกลุ่มที่คุณตั้งไว้)
@export var target_group_name: String = ""

func _ready():
	if not detection_area or not preview_mesh:
		push_warning("⚠️ กรุณาลาก Node ใส่ใน Inspector ให้ครบด้วยครับ")
		return

	preview_mesh.visible = false
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# เช็ก 2 เงื่อนไข: 1. เป็นวัตถุหยิบได้ 2. อยู่ใน Group ที่เราต้องการ
	if body is XRToolsPickable and body.is_in_group(target_group_name):
		preview_mesh.visible = true

func _on_body_exited(body):
	# เช็กเงื่อนไขเดียวกันเพื่อให้แน่ใจว่าปิด Mesh เฉพาะตอนวัตถุกลุ่มนั้นออกไป
	if body is XRToolsPickable and body.is_in_group(target_group_name):
		preview_mesh.visible = false
