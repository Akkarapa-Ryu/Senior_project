extends CanvasLayer

# เพิ่มไปที่ Project > Project Settings > Globals ชื่อว่า "SceneTransition" และใส่ path ของ .tscn ด้วย แล้วจะสามารถเรียกใช้ที่ script อื่นได้
func change_scene(target: String) -> void: # func ที่ใข้เปลี่ยน scence โดยใช้ animation ที่ทำขึ้นใน godot
	$AnimationPlayer.play("dissolve") # "dissolve" คือชื่อ animation ให้ทำการเล่น
	await $AnimationPlayer.animation_finished # รอ animation เล่นจบ
	get_tree().change_scene_to_file(target)
	$AnimationPlayer.play_backwards("dissolve") # เล่นถอยหลังไปที่เฟรมแรก
