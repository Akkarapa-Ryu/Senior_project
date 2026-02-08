extends Node3D

@onready var npc_main = get_parent() # อ้างอิงไฟล์หลัก
@onready var nav_agent = $"../NavigationAgent3D"

var player_node: Node3D
var can_follow: bool = false # สถานะเริ่มแรกคือยังไม่เดิน

func _ready() -> void:
	await get_tree().process_frame # รอให้ Group พร้อมใช้งาน
	#self.dialogue_finished.connect(_on_dialogue_finished) # เชื่อมต่อสัญญาณ dialogue_finished เข้ากับฟังก์ชันที่เราจะสร้างขึ้น
	player_node = get_tree().get_first_node_in_group("player") # player คือชื่อ group ของ Player
	if player_node:
		print("หา Player เจอแล้ว: ", player_node.name)
	else:
		print("Error: หา Player ในกลุ่ม 'player' ไม่เจอ!")

# สร้างฟังก์ชันให้ไฟล์แม่เรียกใช้
func start_following():
	npc_main.can_follow = true
	if player_node:
		print("กำลังเริ่มเดินตาม: ", player_node.name)
	else:
		print("ERROR: ไม่มีเป้าหมายให้เดินตาม!")

func _physics_process(delta: float) -> void:
	if npc_main.can_follow and player_node:
		movement_logic(delta)

func movement_logic(delta: float):
	if not npc_main.can_follow or not player_node:
		npc_main.anim_state.travel("idle") # ถ้าไม่ได้เดิน ใช้ท่า idle
		return

	# 1. ใส่แรงโน้มถ่วงเสมอ (ช่วยให้เท้าติดพื้น NavMesh)
	if not npc_main.is_on_floor():
		npc_main.velocity.y -= 20.0 * delta
	else:
		npc_main.velocity.y = 0

	#var dist_to_player = global_position.distance_to(player_node.global_position)
	var dist_to_player = npc_main.global_position.distance_to(player_node.global_position)

	# 2. ระยะหยุด (ปรับ follow_distance เป็น 2.0 เพื่อเว้นที่ให้ Player ขยับ)
	if dist_to_player < npc_main.follow_distance: 
		npc_main.velocity.x = move_toward(npc_main.velocity.x, 0, npc_main.SPEED)
		npc_main.velocity.z = move_toward(npc_main.velocity.z, 0, npc_main.SPEED)
		npc_main.move_and_slide()
		npc_main.anim_state.travel("idle") # เมื่อหยุดเดิน
		return

	# 3. สั่ง Agent คำนวณทาง
	nav_agent.target_position = player_node.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_pos)
		
		# คำนวณความเร็ว
		npc_main.velocity.x = direction.x * npc_main.SPEED
		npc_main.velocity.z = direction.z * npc_main.SPEED
		npc_main.anim_state.travel("walking")
		
		# 4. หันหน้า (หันเฉพาะเมื่อเป้าหมายอยู่ห่างเกิน 0.2 เมตร เพื่อกัน Error)
		if global_position.distance_to(next_path_pos) > 0.2:
			var look_dir = Vector3(direction.x, 0, direction.z)
			if look_dir.length() > 0.01:
				npc_main.look_at(npc_main.global_position + look_dir, Vector3.UP)
		else:
			npc_main.anim_state.travel("idle") # ถึงจุดหมายแล้ว
	
	npc_main.move_and_slide()

# ฟังก์ชันที่จะทำงานเมื่อคุยจบ
func _on_dialogue_finished():
	print("NPC: คุยจบแล้ว เริ่มเดินตามได้!")
	npc_main.can_follow = true
	npc_main.last_target_pos = player_node.global_position
	npc_main.nav_agent.target_position = npc_main.last_target_pos

func stop_following():
	# สั่งให้หยุดเดิน
	set_physics_process(false) # ปิดการทำงานของฟิสิกส์ในคอมโพเนนต์นี้
	# หรือถ้าคุณใช้ NavigationAgent ให้สั่ง velocity เป็นศูนย์
	if get_parent() is CharacterBody3D:
		get_parent().velocity = Vector3.ZERO
	print("MovementComponent: หยุดการเคลื่อนที่แล้ว")
