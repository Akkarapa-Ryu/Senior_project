# เมื่อ NPC + อุปกรณ์มาถึงที่ DropPoint แล้วให้ส่งสัญญาณไปหาปุ่มที่ใช้ขยับ ว่าจะขยับไปพร้อมกัน
# เมื่อ NPC เดินมาถึงเตียงให้มี บทสนทนาว่า "ขึ้นไปนอนได้เลยครับ" จากนั้น NPC ขึ้นไปนอน + ล็อกอยู่กับเตียง
# เมื่อครบเวลา player บอกว่าเสร็จแล้ว + ถอดอุปกรณ์เสร็จแล้ว npc เดินออกไปรอนอกห้องเอง
extends StaticBody3D

class_name interact_move_target

signal interacted_move_target()

@export_group("Label")
@export var label_node: Label3D
@export var label_text: String

@export_group("Setting")
@export var promt_message = "Interact_Move_Target"
@export var promt_action = "interact_move"
@export var key_name = "Q"

@export_group("Target")
@export var target_object_1: Node3D # Object ที่ต้องการให้เคลื่อนที่มาใส่ตรงนี้
@export var target_object_2: Node3D

@export_group("Movement Logic")
@export var move_direction: Vector3 = Vector3.ZERO # เลือกทิศทาง (เช่น ขึ้น: 0,1,0 | ลง: 0,-1,0 | ซ้าย: -1,0,0 | ขวา: 1,0,0)
@export var step_distance: float = 0.1 # ระยะทางในการกดแต่ละครั้ง
@export var duration: float = 0.1 # ความเร็วในการเคลื่อนที่ (วินาที)

@export_group("Limits (Optional)")
@export var use_limit: bool = false # ถ้าติ๊กถูก จะจำกัดความสูงไม่ให้เกินค่าที่ตั้งไว้
@export var max_height: float = 5.0
@export var min_height: float = 0.0

@onready var NPC = $"../../NPC"

func _ready() -> void:
	update_label_text()

func update_label_text():
	if label_node:
		label_node.text = label_text

func get_promt():
	return promt_message + "\n" + "[" + key_name + "]"

func interact_move_target(_body):
	emit_signal("interacted_move_target")
	move_target()

func move_target():
	NPC.attach_all_to_bed()
	
	var tween = create_tween().set_parallel(true)
	
	# --- ตรรกะสำหรับ Object 1 ---
	if target_object_1:
		apply_movement(tween, target_object_1, move_direction)

	# --- ตรรกะสำหรับ Object 2 ---
	if target_object_2:
		# เช็คว่าปุ่มนี้เป็นปุ่ม "ซ้าย-ขวา" หรือไม่ (เช็คที่แกน X)
		# ถ้าจะให้ Object 2 ขยับเฉพาะซ้ายขวา ให้กรองทิศทางตรงนี้
		var is_horizontal = abs(move_direction.x) > 0
		
		# ถ้าปุ่มนี้มีทิศทางไปแกน X ให้ขยับ Object 2 ได้
		if is_horizontal:
			apply_movement(tween, target_object_2, move_direction)
		# แต่ถ้าปุ่มนี้เป็น ขึ้น-ลง (แกน Y) และเราอยากให้ Object 2 ขึ้นลงพร้อม Object 1 ด้วย
		elif abs(move_direction.y) > 0:
			apply_movement(tween, target_object_2, move_direction)
		elif abs(move_direction.z) > 0:
			apply_movement(tween, target_object_2, move_direction)

func apply_movement(tween: Tween, obj, dir: Vector3):
	var next_pos = obj.position + (dir.normalized() * step_distance)
	
	if use_limit:
		next_pos.y = clamp(next_pos.y, min_height, max_height)
		
	tween.tween_property(obj, "position", next_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
