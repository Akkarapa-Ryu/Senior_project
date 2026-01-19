extends CharacterBody3D

# ส่วนนี้มาจาก Gemini ------------------------------
@onready var label = $Sprite3D/SubViewport/Control/Label # ลาก Label มาใส่
@onready var ui_container = $Sprite3D # ตัวที่จะเปิด/ปิด

# รายการบทสนทนา
var dialog_lines: Array[String] = [
	"สวัสดีเจ้าผู้กล้า!",
	"ข้ามีภารกิจให้เจ้าทำ...",
	"ช่วยไปกำจัดแมลงสาบหลังบ้านให้ที",
	"ขอบคุณมาก!"
]

var current_line = -1

func _ready():
	ui_container.visible = false # เริ่มมาให้ซ่อนไว้ก่อน

func interact_talking():
	current_line += 1
	
	if current_line < dialog_lines.size():
		ui_container.visible = true
		label.text = dialog_lines[current_line]
	else:
		# จบบทสนทนา
		ui_container.visible = false
		current_line = -1
# ส่วนนี้มาจาก Gemini ------------------------------
