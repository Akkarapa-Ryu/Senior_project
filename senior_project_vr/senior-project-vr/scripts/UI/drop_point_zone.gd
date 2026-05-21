extends Node3D

@onready var mesh = $MeshInstance3D
@onready var snap_zone = $XRToolsSnapZone

func _ready():
	mesh.visible = false
	
	# Signal เดิม: เมื่อของเข้ามาใกล้/ออกไป
	snap_zone.body_entered.connect(_on_snap_zone_body_entered)
	snap_zone.body_exited.connect(_on_snap_zone_body_exited)
	
	# Signal ใหม่: เมื่อของ "ถูกวางลงล็อค" หรือ "ถูกหยิบออกไป"
	snap_zone.has_picked_up.connect(_on_has_picked_up)
	snap_zone.has_dropped.connect(_on_has_dropped)

func _on_snap_zone_body_entered(body):
	# แสดง Text เฉพาะตอนที่ SnapZone ยัง "ว่าง" อยู่เท่านั้น
	if body is XRToolsPickable and snap_zone.picked_up_object == null:
		mesh.visible = true

func _on_snap_zone_body_exited(body):
	if body is XRToolsPickable:
		mesh.visible = false

func _on_has_picked_up(_what):
	# เมื่อของวางลงล็อคปุ๊บ ให้ซ่อน Text ทันที
	mesh.visible = false

func _on_has_dropped():
	# เมื่อหยิบของออกจากจุดวาง ถ้ามือเรายังอยู่ในระยะเดิม 
	# อาจจะอยากให้ Text กลับมาขึ้นใหม่ (หรือจะไม่ใส่ก็ได้ครับ)
	# label.visible = true 
	pass
