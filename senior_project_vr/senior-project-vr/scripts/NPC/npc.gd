extends CharacterBody3D
class_name NPC # class_name ทำให้เราเรียก enum จากไฟล์อื่นได้

# --- Animation ---
enum State { IDLE, FOLLOWING, SLEEPING, TALKING }
var current_state = State.TALKING
@onready var anim_tree = $Idle_skeletal/AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

# --- ส่วนบทสนทนา ---
@export_group("Dialogu UI")
@export var player_ui: Sprite3D
@export var player_label: Label
@onready var npc_label = $Sprite3D/SubViewport/CenterContainer/PanelContainer/MarginContainer/Label
@onready var npc_ui = $Sprite3D

@export_group("Dialogue Logic")
@export var dialogue_resource: Array[DialogueResource]
@export var dialogue_start_node: String = "start" # ชื่อ Label ในไฟล์ เช่น ~ start

var current_step = -1
var original_parent: Node


# --- ส่วนการเคลื่อนที่ ---
@export_group("Movement Settings")
#@export var destination_node: Node3D  # ลากจุดมาร์ค (Marker3D) มาใส่ที่นี่
@export var follow_distance : float = 1
@export var resume_distance : float = 0.5
const ARRIVE_DISTANCE: float = 1.0 # ระยะที่ถือว่า "ถึงจุดมาร์คแล้ว"
const SPEED: float = 2
const ACCEL: float = 10.0
var player_node: Node3D
var has_reached_marker: bool = false
var last_target_pos: Vector3 = Vector3.ZERO


# --- NPC นอนงลบนเตียง ---
@export var player: Node3D
@export var bed_marker: Marker3D
@onready var nav_agent = $NavigationAgent3D
const ARRIVE_DISTANCE_bed: float = 1 # ระยะที่ถือว่า "ถึงจุดมาร์คแล้ว"
#@onready var anim_player = $AnimatableBody3D

# --- obj ที่จะขัยไปด้วยเมื่อวางที่เตียง ---
@export var attached_objects: Array[Node3D]

# --- สถานะ (State) ---
var is_talking: bool = false # เช็คว่ากำลังคุยอยู่ไหม
var can_follow: bool = false # ตอนเริ่มเกมจะยังไม่เดิน

@onready var dialogue_comp = $DialogueComponent
@onready var movement_comp = $MovementComponent


func _ready():
	# เมื่อคุยจบ (สัญญาณจาก Dialogue) ให้เริ่มเดิน (สั่งงานที่ Movement)
	dialogue_comp.dialogue_finished.connect(_on_talk_done)
	anim_state.travel("idle")

func _on_talk_done():
	print("Main: คุยจบแล้ว สั่ง Movement ให้เริ่มเดิน")
	movement_comp.start_following()
	current_state = State.FOLLOWING

# ฟังก์ชันนี้ไว้รับการกด Interact จาก Player
func interact_talk():
	anim_state.travel("idle") # ให้ยืนนิ่งๆ เวลาคุย
	dialogue_comp.interact_talking()


func _physics_process(_delta):
	# ถ้าสถานะคือ 1 (เดินตาม) ให้คอยเช็คว่าถึงเตียงหรือยัง
	match current_state:
		State.FOLLOWING:
			check_if_arrived_at_bed()
		State.SLEEPING:
			anim_state.travel("sleeping")
		State.TALKING, State.IDLE:
			anim_state.travel("idle")

func check_if_arrived_at_bed():
	if bed_marker == null: return
	
	# แก้เป็นแบบนี้: ดึงค่า x และ z ออกมาทีละตัว
	var npc_pos_2d = Vector2(global_position.x, global_position.z)
	var bed_pos_2d = Vector2(bed_marker.global_position.x, bed_marker.global_position.z)
	var dist_to_bed = npc_pos_2d.distance_to(bed_pos_2d)
	
	if dist_to_bed <= ARRIVE_DISTANCE_bed:
		current_state = State.SLEEPING
		call_deferred("snap_to_bed")
	
	#print(dist_to_bed)

func snap_to_bed():
	if current_state != State.SLEEPING: return
	
	print("NPC: กำลังนอน...")
	# ปิดการเดินแน่นอน
	can_follow = false 
	if movement_comp:
		movement_comp.stop_following()

	# ย้ายไปเป็นลูกของเตียง (ทำครั้งเดียวพอ)
	reparent(bed_marker, true)
	
	# ใช้ Tween เพื่อให้การ "นอน" ดูสมูท ไม่วาร์ป
	var tween = create_tween()
	tween.tween_property(self, "transform", Transform3D.IDENTITY, 0.5) # วางตำแหน่ง/หมุนให้ตรงกับ Marker
	
	attach_all_to_bed()
	if npc_ui: npc_ui.hide()
	anim_state.travel("sleeping")



func attach_all_to_bed():
	for obj in attached_objects:
		if is_instance_valid(obj) and obj != self: # ตรวจสอบว่า obj ไม่ใช่ตัวเองก่อนสั่ง
			if is_instance_valid(obj): # เช็คว่าวัตถุยังอยู่ในเกมไหม (ไม่ถูกลบไปก่อน)
				# 1. หยุดฟิสิกส์ (ถ้ามี)
				if obj is RigidBody3D:
					obj.freeze = true
				elif obj is CharacterBody3D:
					# ถ้าเป็น NPC ให้สั่งหยุดเดินผ่านสคริปต์ของมัน
					if obj.has_method("snap_to_bed"): 
						obj.snap_to_bed() 

				# 2. เปลี่ยนพ่อแม่มาเป็นเตียง
				obj.reparent(bed_marker, true)
				
				# 3. (Optional) จัดตำแหน่งของแต่ละชิ้น
				# ถ้าไม่อยากให้ของทับกันที่จุดเดียว อาจจะไม่ต้องเซต position = 0
				print("ยึด ", obj.name, " ติดกับเตียงเรียบร้อย")


# ฟังก์ชันที่จะถูกเรียกหลังจากสแกนเสร็จ
func start_post_scan_sequence():
	# 1. ลุกจากเตียง
	await movement_comp.wake_up()
	
	# 2. เริ่มคุยโดยใช้ไฟล์ Index ที่ 1 และไปที่ Label "~ after_scan"
	if dialogue_comp:
		# ระบุ (Index, Label)
		dialogue_comp.start_specific_dialogue(1, "after_scan")
