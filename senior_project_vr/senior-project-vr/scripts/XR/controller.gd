extends XRController3D

const BUTTON_GROUP_NAME = "interactable_buttons"

# อ้างอิงโหนด Area ที่เราสร้างไว้ที่มือเพื่อใช้ตรวจจับปุ่ม/NPC
@export var interacting_area: Area3D
var current_target: Node3D = null # เก็บวัตถุที่มือแตะอยู่ในปัจจุบัน
var original_materials := {} # ตัวแปรเก็บ material เดิม

@export var exit_node: Node3D
@export var setting_node: Node3D
@export var training_node: Node3D
@export var info_node: Node3D
@export var laser_node: Node3D

@onready var ui_elements = {
	"exit_board": exit_node,
	"setting_board": setting_node,
	"training_menu": training_node,
	"info_1": info_node,
}

func _ready() -> void:
	# เชื่อมต่อสัญญาณการกดปุ่ม (ใช้สำหรับ Trigger กดปุ่ม UI หรือ คุยกับ NPC)
	self.button_pressed.connect(_on_button_pressed)

	# ปิด UI เริ่มต้น
	for key in ui_elements:
		if ui_elements[key]:
			ui_elements[key].visible = false
	
	#laser_node.visible = false

func _physics_process(_delta: float) -> void:
	_update_interaction()
	
func _update_interaction() -> void:
	# --- ระบบ Highlight เมื่อมือไปแตะโดนวัตถุ ---
	var overlapping_bodies = interacting_area.get_overlapping_bodies()
	var new_target = null
	
	# ค้นหาวัตถุที่โต้ตอบได้ตัวแรกที่เจอ
	for body in overlapping_bodies:
		if _is_interactable(body):
			new_target = body
			break
			
	# ตรวจสอบการเปลี่ยน Target (สำหรับทำ Highlight)
	if new_target != current_target:
		
		# 🔴 ปิดของเก่า (ต้องเช็คก่อน)
		if current_target:
			_set_highlight_off(current_target)
		
		current_target = new_target
		
		# 🟢 เปิดของใหม่
		if current_target:
			_set_highlight_on(current_target)
	

func _is_interactable(node: Node) -> bool:
	if not node: return false
	return (
		node.is_in_group(BUTTON_GROUP_NAME) or 
		node.has_method("interact_talk") or 
		node.has_method("attempt_toggle") or # <--- เพิ่มบรรทัดนี้
		(node.get_parent() and node.get_parent().has_method("attempt_toggle")) or # <--- และบรรทัดนี้
		node.has_method("interact_move_target") or 
		(node.get_parent() and node.get_parent().has_method("scan_model"))
	)

func _set_highlight_on(node: Node3D) -> void:
	var mesh = _find_mesh_instance(node)
	if not mesh:
		return

	if not original_materials.has(mesh):
		original_materials[mesh] = mesh.get_active_material(0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.4, 0.4)
	
	mesh.set_surface_override_material(0, mat)

func _set_highlight_off(node: Node3D) -> void:
	var mesh = _find_mesh_instance(node)
	if not mesh:
		return

	if original_materials.has(mesh):
		mesh.set_surface_override_material(0, original_materials[mesh])
		original_materials.erase(mesh)

func _on_button_pressed(button_name: String) -> void:
	print("Button Pressed: ", button_name)
	
	if not current_target: 
		return

	# --- 1. จัดการปุ่ม Trigger (UI / Talk / Move) ---
	if button_name == "trigger_click":
		_handle_trigger_interaction(current_target)

	# --- 2. จัดการปุ่ม AX (ประตู หรือ Scrolling) ---
	elif button_name == "ax_button":
		# เช็กเรื่องประตูก่อน
		var found_door = false
		var check_node = current_target
		
		while check_node != null:
			if check_node.has_method("attempt_toggle"):
				check_node.attempt_toggle()
				found_door = true
				break
			check_node = check_node.get_parent()
		
		# ถ้าไม่ใช่ประตู ให้ไปเช็กเรื่องการ Scroll (ถ้ามี)
		if not found_door:
			_handle_scrolling(button_name, current_target)

	# --- 3. จัดการปุ่ม BY (Scrolling) ---
	elif button_name == "by_button":
		_handle_scrolling(button_name, current_target)
	


func _handle_trigger_interaction(target: Node3D) -> void:
	# 1. จัดการ UI
	if target.is_in_group(BUTTON_GROUP_NAME):
		_handle_ui_logic(target.name)
	
	# 2. จัดการ NPC / Special Objects
	if target.has_method("interact_talk"):
		target.interact_talk()
	
	if "current_state" in target and target.has_method("wake_up"):
		target.wake_up()
		
	if target.has_method("interact_move_target"):
		target.interact_move_target(self)
	if target.get_parent() and target.get_parent().has_method("interact_move_target"):
		target.get_parent().interact_move_target(self)
		
	if target.get_parent().has_method("scan_model") or target.get_parent().has_method("scout_model"):
		if target.name == "btn_sim":
			print("VR: Calling scan_model via btn_sim")
			target.get_parent().scan_model()
		elif target.name == "btn_scan":
			print("VR: Calling scan_model via btn_scan")
			target.get_parent().scout_model()

func _handle_scrolling(button_name: String, target: Node3D) -> void:
	var sprite = target.get_parent()
	if sprite is Sprite3D and sprite.has_method("scroll_with_controller"):
		var scroll_val = 1.0 if button_name == "ax_button" else -1.0
		sprite.scroll_with_controller(scroll_val, 15.0)

func _handle_ui_logic(obj_name: String) -> void:
	match obj_name:
		"btn_setting":  ui_elements["setting_board"].visible = !ui_elements["setting_board"].visible
		"btn_exit":     ui_elements["exit_board"].visible = !ui_elements["exit_board"].visible
		"btn_yes":      get_tree().quit()
		"btn_no":       ui_elements["exit_board"].visible = !ui_elements["exit_board"].visible
		"btn_training": ui_elements["training_menu"].visible = !ui_elements["training_menu"].visible
		"Button_Info_1": ui_elements["info_1"].visible = !ui_elements["info_1"].visible
		"Button_next_1":
			if has_node("/root/SceneTransition"):
				get_node("/root/SceneTransition").change_scene("res://scences/scenes_XR/5_training_XR.tscn")
		"Open_Close_Laser": laser_node.visible = !laser_node.visible


func _find_mesh_instance(parent: Node) -> MeshInstance3D:
	if parent is MeshInstance3D: return parent
	for child in parent.get_children():
		if child is MeshInstance3D: return child
	return null
