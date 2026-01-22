extends CharacterBody3D

# --- ส่วนบทสนทนา ---
@export_group("Dialogu UI")
@export var player_ui: Sprite3D
@export var player_label: Label
@onready var npc_label = $Sprite3D/SubViewport/CenterContainer/PanelContainer/MarginContainer/Label
@onready var npc_ui = $Sprite3D


@export_group("Dialogue Logic")
@export var dialogue_resource: DialogueResource
@export var dialogue_start_node: String = "start" # ชื่อ Label ในไฟล์ เช่น ~ start

var current_step = -1


# --- ส่วนการเคลื่อนที่ ---
@export_group("Movement Settings")
@export var destination_node: Node3D  # ลากจุดมาร์ค (Marker3D) มาใส่ที่นี่
@export var follow_distance : float = 7
@export var resume_distance : float = 1.5
const ARRIVE_DISTANCE: float = 1.5 # ระยะที่ถือว่า "ถึงจุดมาร์คแล้ว"
const SPEED: float = 10.0
const ACCEL: float = 20.0
var player_node: Node3D
var has_reached_marker: bool = false
var last_target_pos: Vector3 = Vector3.ZERO


# --- สถานะ (State) ---
var is_talking: bool = false # เช็คว่ากำลังคุยอยู่ไหม
var can_follow: bool = false # ตอนเริ่มเกมจะยังไม่เดิน

@onready var dialogue_comp = $DialogueComponent
@onready var movement_comp = $MovementComponent


func _ready():
	# เมื่อคุยจบ (สัญญาณจาก Dialogue) ให้เริ่มเดิน (สั่งงานที่ Movement)
	dialogue_comp.dialogue_finished.connect(_on_talk_done)

func _on_talk_done():
	print("Main: คุยจบแล้ว สั่ง Movement ให้เริ่มเดิน")
	movement_comp.start_following()

# ฟังก์ชันนี้ไว้รับการกด Interact จาก Player
func interact_talk():
	dialogue_comp.interact_talking()
