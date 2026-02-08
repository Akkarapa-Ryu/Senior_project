extends Sprite3D

@onready var scroll_container = $UI/Control/ScrollContainer_y # ระบุพาธให้ถูกตามรูปของคุณ

# ฟังก์ชันสำหรับเลื่อน ScrollContainer โดยตรง
func scroll_with_controller(direction: float, speed: float = 20.0):
	if scroll_container:
		# ดึงค่าตำแหน่งการเลื่อนปัจจุบัน
		var current_scroll = scroll_container.scroll_vertical
		# คำนวณตำแหน่งใหม่ (direction จะเป็น -1 สำหรับขึ้น และ 1 สำหรับลง)
		scroll_container.scroll_vertical = current_scroll + (direction * speed)
