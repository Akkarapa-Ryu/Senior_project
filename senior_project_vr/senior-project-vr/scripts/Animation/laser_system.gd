extends Node3D

@onready var ray_cast: RayCast3D = $Laser
@onready var fan_mesh: MeshInstance3D = $FanMesh
@onready var hit_line: Decal = $HitLine

func _process(_delta: float) -> void:
	if ray_cast.is_colliding():
		var hit_point = ray_cast.get_collision_point()
		var hit_normal = ray_cast.get_collision_normal()
		
		# 1. วาง Decal บนพื้นผิว NPC
		hit_line.global_position = hit_point
		hit_line.visible = true
		
		# หมุน Decal ให้ขนานกับพื้นผิว
		# หมุน Decal ให้ขนานกับพื้นผิว
		if hit_normal.is_equal_approx(Vector3.UP):
			hit_line.look_at(hit_point + Vector3.RIGHT, hit_normal)
		else:
			hit_line.look_at(hit_point + hit_normal, Vector3.UP)
			
		# 2. ปรับแผ่นแสง (FanMesh) ให้ยาวไปถึงจุดที่ชน
		var distance = global_position.distance_to(hit_point)
		if fan_mesh.mesh is BoxMesh:
			# ยืดขนาดแกน Z ของ Mesh
			fan_mesh.mesh.size.z = distance
			# เลื่อนตำแหน่งให้โคนอยู่ที่เครื่องยิงพอดี
			fan_mesh.position.z = -distance / 2.0
	else:
		hit_line.visible = false
		# ถ้าไม่ชนอะไร ให้ยืดไปสุดระยะ Target ของ Raycast
		var max_dist = ray_cast.target_position.length()
		if fan_mesh.mesh is BoxMesh:
			fan_mesh.mesh.size.z = max_dist
			fan_mesh.position.z = -max_dist / 2.0
