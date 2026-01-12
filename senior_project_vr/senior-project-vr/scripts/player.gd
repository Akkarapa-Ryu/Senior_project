extends CharacterBody3D

# ส่วนนี้มาจาก Gemini ------------------------------
# การขยับของ player
const SPEED = 10.0
const JUMP_VELOCITY = 6.5
const MOUSE_SENSITIVITY = 0.002 # ความเร็วในการหันเมาส์

@onready var camera = $Camera3D

#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity = 20.0
var camera_look_input = Vector2.ZERO


# การหยิบจับสิ่งของของ player
var picked_object = null # เก็บตัวแปรว่าตอนนี้ถืออะไรอยู่ไหม
@onready var ray = $Camera3D/InteractionRay
@onready var hold_pos = $Camera3D/HoldPosition


func _ready():
	# ล็อคเมาส์ไว้กลางจอเพื่อให้เล่นเกมง่ายขึ้น
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	# ถ้ามีการขยับเมาส์
	# 1. ปลดล็อคเมาส์/ล็อคเมาส์ ด้วยปุ่ม ESC
	if event.is_action_pressed("ui_cancel"): # ui_cancel คือปุ่ม ESC โดยมาตรฐาน
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 2. การหันกล้อง (จะทำงานเมื่อเมาส์ถูกล็อคอยู่เท่านั้น)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	# แก้ไขบรรทัดนี้: เปลี่ยนจาก event เป็น Input
	if Input.is_action_just_pressed("rigid_picking_arm"): # rigid_picking_arm เป็ฯการเพิ่มเข้าไปใหม่ที่ Project > Project Settings > Input Map
		if picked_object == null:
			pick_up_object()
		else:
			drop_object()


func pick_up_object():
	print("พยายามหยิบของ...") # เช็คว่ากดปุ่มติดไหม
	if ray.is_colliding():
		var collider = ray.get_collider()
		print("เลเซอร์ชนกับ: ", collider.name) # เช็คว่าเลเซอร์เห็นอะไร
		# เช็คว่าเป็นวัตถุที่เราต้องการให้หยิบได้ไหม (RigidBody3D)
		if collider is RigidBody3D:
			print("เจอ RigidBody แล้ว! กำลังหยิบ...")
			picked_object = collider
			# ปิดฟิสิกส์ชั่วคราวเพื่อไม่ให้มันตกขณะถือ
			picked_object.freeze = true
		else:
			print("สิ่งที่ชนไม่ใช่ RigidBody3D")
	else:
		print("เลเซอร์ไม่ชนอะไรเลย") # ถ้าขึ้นอันนี้ แสดงว่าเลเซอร์สั้นไปหรือตั้ง Mask ผิด

func drop_object():
	if picked_object != null:
		# เช็คก่อนว่าเราส่องโดน DropPoint หรือเปล่า?
		if ray.is_colliding() and ray.get_collider() is Area3D:
			# ถ้าส่องโดนพื้นที่วาง ให้เราปล่อยเฉยๆ แล้วปล่อยให้ Area3D จัดการต่อ
			picked_object.freeze = false
			picked_object = null
		else:
			# ถ้าวางบนพื้นทั่วไป ให้ทำตามเดิม
			picked_object.get_node("CollisionShape3D").disabled = false
			picked_object.freeze = false
			picked_object.linear_velocity = Vector3.ZERO
			picked_object = null
# ส่วนนี้มาจาก Gemini ------------------------------


func _physics_process(delta: float):
	# Add the gravity. เพิ่มแรงโน้มถ่วง
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump. จัดการการกระโดด
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# ส่วนนี้มาจาก Gemini ------------------------------
	# ถ้าถือของอยู่ ให้ของย้ายตำแหน่งตาม HoldPosition
	if picked_object:
		picked_object.global_transform.origin = hold_pos.global_transform.origin
	# ส่วนนี้มาจาก Gemini ------------------------------
