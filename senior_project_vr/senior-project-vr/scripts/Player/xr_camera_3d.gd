extends XRCamera3D

@export var max_height: float = 1.9  # ความสูงสูงสุด (เมตร)
@export var min_height: float = 1.0  # ความสูงต่ำสุด (เมตร)

func _process(_delta):
	# ตรวจสอบตำแหน่ง Y ของกล้อง
	if position.y > max_height:
		position.y = max_height
	elif position.y < min_height:
		position.y = min_height
