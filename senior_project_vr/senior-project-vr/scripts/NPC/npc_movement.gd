extends Node3D

@onready var npc_main = get_parent() # อ้างอิงไฟล์หลัก
@onready var nav_agent = $"../NavigationAgent3D"

var player_node: Node3D

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
	if npc_main.can_follow:
		print("กำลังจะเดินตาม")
	
	if npc_main.can_follow and player_node:
		movement_logic(delta)

func movement_logic(delta: float):
	# เช็คความปลอดภัยก่อน
	if not is_instance_valid(player_node) or not npc_main.can_follow:
		npc_main.anim_state.travel("idle")
		return

	# 1. แรงโน้มถ่วง (ใช้จาก npc_main โดยตรง)
	if not npc_main.is_on_floor():
		npc_main.velocity.y -= 20.0 * delta
	else:
		npc_main.velocity.y = 0

	var dist_to_player = npc_main.global_position.distance_to(player_node.global_position)

	# 2. ระยะหยุด (ปรับให้ยืดหยุ่น)
	if dist_to_player < npc_main.follow_distance:
		# ค่อยๆ หยุด
		npc_main.velocity.x = move_toward(npc_main.velocity.x, 0, npc_main.SPEED)
		npc_main.velocity.z = move_toward(npc_main.velocity.z, 0, npc_main.SPEED)
		npc_main.anim_state.travel("idle")
	else:
		# 3. สั่งเดิน
		nav_agent.target_position = player_node.global_position
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = npc_main.global_position.direction_to(next_path_pos)
		
		npc_main.velocity.x = direction.x * npc_main.SPEED
		npc_main.velocity.z = direction.z * npc_main.SPEED
		npc_main.anim_state.travel("walking")
		
		# หันหน้าไปหาทิศที่จะเดิน
		var look_target = Vector3(next_path_pos.x, npc_main.global_position.y, next_path_pos.z)
		if npc_main.global_position.distance_to(look_target) > 0.1:
			npc_main.look_at(look_target, Vector3.UP)

	npc_main.move_and_slide()
	print("target:", player_node.global_position)
	print("next path:", nav_agent.get_next_path_position())

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

# --- NPC ลุกขึ้นจากเตียง ---
func wake_up():
	# ต้องเอา npc ออกจาก bed_marker ก่อน
	print("NPC: กำลังลุกจากเตียง...")
	if npc_main.current_state != NPC.State.SLEEPING: return 
	
	# 1. ย้าย NPC ออกจากการเป็นลูกของเตียงก่อน
	if npc_main.original_parent:
		npc_main.reparent(npc_main.original_parent, true)
	else:
		npc_main.reparent(get_tree().current_scene, true)
	
	# 2. คำนวณจุดยืน (ข้างๆ เตียง)
	var stand_up_pos = npc_main.global_position + (npc_main.global_transform.basis.x * 1.0)
	stand_up_pos.y = npc_main.global_position.y
	print("stand_up_pos.y: ", stand_up_pos.y)
	var tween = create_tween().set_parallel(true) # ให้หมุนและย้ายพร้อมกัน
	tween.tween_property(npc_main, "global_rotation_degrees", Vector3.ZERO, 0.5)
	tween.tween_property(npc_main, "global_position", stand_up_pos, 0.5)
	
	await tween.finished
	
	# 3. คืนค่าสถานะ
	npc_main.current_state = NPC.State.IDLE
	set_physics_process(true)
	npc_main.anim_state.travel("idle")
