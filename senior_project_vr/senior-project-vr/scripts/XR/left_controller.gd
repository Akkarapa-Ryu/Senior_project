# สามารถคุยกับ NPC ได้

extends XRController3D

# กำหนดสีที่ต้องการ Highlight (ตัวอย่าง: สีเหลืองสว่าง)
const HIGHLIGHT_COLOR = Color(0.812, 0.376, 0.494, 1.0)
# ชื่อ Group ที่เราตั้งไว้ในขั้นตอนที่ 1
const BUTTON_GROUP_NAME = "interactable_buttons"

var hovered_object = null
@onready var ray = $RayCast3D
var picked_object = null
var hold_node = null # จุดที่จะให้ของมาวาง (อาจเป็น Node3D เปล่าๆ ที่ปลายมือ)

# 1. ดึง Node ออกมาเป็นตัวแปรแยก (ช่วยให้ Debug ง่ายขึ้นว่าตัวไหนพัง)
@export var exit_node: Node3D
@export var setting_node: Node3D
@export var training_node: Node3D
@export var info_node: Node3D

# 2. นำตัวแปรมาใส่ใน Dictionary (ใช้เครื่องหมาย : แทน =)
@onready var ui_elements = {
	"exit_board": exit_node,
	"setting_board": setting_node,
	"training_menu": training_node,
	"info_1": info_node
}

func _ready() -> void:
	self.button_pressed.connect(btnPressedOnLeftController)
	#self.button_released.connect(btnReleasedOnLeftController)
	
	for key in ui_elements:
		if ui_elements[key] == null:
			print("ERROR: หา Node สำหรับ ", key, " ไม่เจอ! เช็ค Path อีกรอบ")
		else:
			ui_elements[key].visible = false # สั่งซ่อนทุกอันที่เจอ
	
	# สร้างจุดสำหรับยึดของไว้ที่ปลาย Controller
	hold_node = Node3D.new()
	add_child(hold_node)
	hold_node.position = Vector3(0, 0, -0.5) # ห่างจากมือครึ่งเมตร


func _physics_process(_delta: float) -> void:
	var collider = null
	if ray.is_colliding(): # 1. ตรวจสอบว่า Ray ชนอะไรหรือไม่
		collider = ray.get_collider()
		if not collider.is_in_group(BUTTON_GROUP_NAME):
			collider = null
		
	if hovered_object != collider: # 2. ตรวจสอบสถานะการเปลี่ยนแปลง (สำคัญที่สุด)
		hovered_object = collider
		if hovered_object != null: # A. ถ้าเคยชี้อะไรอยู่ ให้คืนค่าสีเดิมของสิ่งนั้นก่อน
			_remove_highlight(hovered_object)
		hovered_object = collider # B. อัปเดตตัวแปรปัจจุบัน
		if hovered_object != null: # C. ถ้าเป้าหมายใหม่มีจริง ให้เปลี่ยนสีเป็น Highlight
			_apply_highlight(hovered_object)


func btnPressedOnLeftController(name: String) -> void:
	print("Controller Pressed: ", name)
	if name == "trigger_click":
		if ray.is_colliding():
			var target = ray.get_collider()
			print("Target: ", target.name)
			if target.has_method("interact_move_target"):
				target.interact_move_target(self)
				return
			elif target.get_parent().has_method("brain"):
				print("Found Button for CT Simulation scanned")
				target.get_parent().brain()
				return
			
			# กรณีที่ 1: ชนปุ่ม UI (ใช้ระบบ Highlight ที่คุณทำไว้)
			if target.is_in_group(BUTTON_GROUP_NAME):
				_handle_interaction(target.name)
			
			# กรณีที่ 2: ชน NPC (คุยได้)
			elif target.has_method("interact_talk"): # เรียก method มาจาก npc.gd
				target.interact_talk()
				print("Talking to:", target.name)
			
			if target and target.has_method("wake_up"):
				if target.current_state == 2: # เลข 2 คือสถานะ SLEEPING
					target.wake_up_smoothly() # สั่งให้ลุกแบบนุ่มนวล
				else:
					target.interact_talk() # ถ้าไม่ได้นอน ก็ให้คุยปกติ
		
	if name == "ax_button":
		if ray.is_colliding():
			var target = ray.get_collider()
			# scolling
			if target.get_parent() is Sprite3D and target.get_parent().has_method("scroll_with_controller"):
				## วิธีที่ 1: ใช้ Analog Stick (แกน Y)
				#var joy_axis = Input.get_axis("ui_up", "ui_down") # หรือชื่อแกนของ VR Controller
				#if abs(joy_axis) > 0.1: # Deadzone กันปุ่มไหล
					#target.get_parent().scroll_with_controller(joy_axis, 25.0)
				
				# วิธีที่ 2: ใช้ปุ่มกด (เช่น ปุ่ม A/B หรือ X/Y)
				#if Input.is_action_pressed("scroll_down"):
				target.get_parent().scroll_with_controller(1.0, 15.0)
				print("Scrolling...")
	elif name == "by_button":
		if ray.is_colliding():
			var target = ray.get_collider()
				#elif Input.is_action_pressed("scroll_up"):
			if target.get_parent() is Sprite3D and target.get_parent().has_method("scroll_with_controller"):
				target.get_parent().scroll_with_controller(-1.0, 15.0)
				print("Scrolling...")
			
	if name == "grip_click":
		print("FORCE TOGGLE DOOR!")
		get_tree().call_group("doors", "toggle_door")
	if name == "ax_button":
		if picked_object == null:
			pick_up_object()
		else:
			drop_object()

# --- ปุ่ม ---
func _handle_interaction(obj_name: String) -> void:
	match obj_name:
		"btn_setting":
			ui_elements["setting_board"].visible = true
		"btn_exit":
			ui_elements.exit_board.visible = true
		"btn_yes":
			get_tree().quit()
		"btn_no":
			ui_elements["exit_board"].visible = false
		"btn_training":
			ui_elements["training_menu"].visible = true
		"Button_Info_1":
			ui_elements["info_1"].visible = true
		"Button_next_1":
			SceneTransition.change_scene("res://scences/scenes_XR/5_training_XR.tscn")
		_:
			print("Hit unknown object: ", obj_name)


#func btnReleasedOnLeftController(name: String) -> void:
	#if name == "trigger_click":
		#pass


# --- open/close Door ---
func _on_button_pressed_door(obj_name: String) -> void:
	if hovered_object == null: return
	
	print("กำลังตรวจสอบการเปิดประตูที่: ", obj_name)
	
	# 1. ลองเช็คที่ตัวมันเอง (StaticBody3D)
	if hovered_object.has_method("toggle_door"):
		hovered_object.toggle_door()
		print("เปิดประตูจากโหนดที่ชนโดยตรง")
	# 2. ถ้าไม่เจอ ลองเช็คที่โหนดแม่ (เช่น Node3D ที่เป็น Parent)
	elif hovered_object.get_parent().has_method("toggle_door"):
		hovered_object.get_parent().toggle_door()
		print("เปิดประตูจากโหนด Parent")
	# 3. ถ้ายังไม่เจออีก ให้ลองเช็คที่ Owner (โหนดสูงสุดของ Scene ประตู)
	elif hovered_object.owner and hovered_object.owner.has_method("toggle_door"):
		hovered_object.owner.toggle_door()
		print("เปิดประตูจากโหนด Owner")
	else:
		print("ERROR: ไม่พบฟังก์ชัน toggle_door ในโหนดที่เกี่ยวข้องเลย!")


# --- เปลี่ยนสีปุ่ม ---
func _apply_highlight(obj: Node3D) -> void:
	# ค้นหา MeshInstance3D ที่อยู่ใน Object นั้น (เผื่อ collider เป็น StaticBody3D)
	var mesh_instance = _find_mesh_instance(obj)
	if not mesh_instance: return

	# ดึง Material ปัจจุบันออกมา
	var current_mat = mesh_instance.get_active_material(0)
	if not current_mat: return
	
	# *** สำคัญ: สร้างสำเนาของ Material เพื่อไม่ให้กระทบปุ่มอื่นที่ใช้ Material เดียวกัน ***
	var highlight_mat = current_mat.duplicate()
	
	# เปลี่ยนสีของ Material สำเนา
	highlight_mat.albedo_color = HIGHLIGHT_COLOR
	# (ทางเลือกเสริม) ทำให้เรืองแสงนิดๆ
	highlight_mat.emission_enabled = true
	highlight_mat.emission = HIGHLIGHT_COLOR
	highlight_mat.emission_energy_multiplier = 0.5
	
	# ใช้ Material Override เพื่อแสดงผลสีใหม่ชั่วคราว
	mesh_instance.set_surface_override_material(0, highlight_mat)

func _remove_highlight(obj: Node3D) -> void:
	var mesh_instance = _find_mesh_instance(obj)
	if not mesh_instance: return
	
	# ยกเลิก Override เพื่อกลับไปใช้ Material ตั้งต้น
	mesh_instance.set_surface_override_material(0, null)

# ฟังก์ชันช่วยค้นหา MeshInstance3D ในลูกหลานของ Object
func _find_mesh_instance(parent: Node3D) -> MeshInstance3D:
	if parent is MeshInstance3D:
		return parent
	
	for child in parent.get_children():
		if child is MeshInstance3D:
			return child
	return null


# --- drag & drop object ---
func _process(_delta):
	if picked_object != null:
		# 1. คำนวณทิศทางจากวัตถุไปที่มือ
		var target_pos = hold_node.global_transform.origin
		var current_pos = picked_object.global_transform.origin
		var direction = target_pos - current_pos
		
		# 2. ตั้งค่าความเร็ว (Linear Velocity) ตามระยะห่าง
		# ยิ่งห่างมาก ยิ่งพุ่งไปหาเร็ว (เลข 20.0 คือความแรงในการดึง)
		picked_object.linear_velocity = direction * 20.0
		
		# 3. คำนวณการหมุน (Angular Velocity) ให้ตรงกับมือ
		var target_basis = hold_node.global_transform.basis
		var current_basis = picked_object.global_transform.basis
		# คำนวณความต่างของมุมแล้วหมุนตาม
		var rotation_diff = (target_basis * current_basis.inverse()).get_euler()
		picked_object.angular_velocity = rotation_diff * 20.0

func pick_up_object():
	if ray.is_colliding():
		var collider = ray.get_collider()
		# เช็คว่าเป็น RigidBody และไม่ได้ถูกหยิบโดยมืออื่นอยู่
		if collider is RigidBody3D and not collider.get_meta("is_being_held", false):
			picked_object = collider
			picked_object.set_meta("is_being_held", true)
			
			picked_object.freeze = false
			picked_object.gravity_scale = 0.0
			# Damp สูงๆ จะช่วยให้ของไม่แกว่งเป็นลูกตุ้มเวลาเราขยับมือเร็วๆ
			picked_object.linear_damp = 15.0 
			picked_object.angular_damp = 15.0

func drop_object():
	if picked_object != null:
		picked_object.set_meta("is_being_held", false)
		picked_object.gravity_scale = 1.0
		picked_object.linear_damp = 0.0
		picked_object.angular_damp = 0.0
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider is Area3D and collider.has_method("_on_body_entered"):
				# สั่งให้ Area3D เช็คการ Snap ทันทีที่ปล่อย
				collider._on_body_entered(picked_object)
		
		picked_object = null
		print("ปล่อยของแล้ว")
