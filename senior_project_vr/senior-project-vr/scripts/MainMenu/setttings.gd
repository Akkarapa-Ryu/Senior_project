extends Panel

var music_bus = AudioServer.get_bus_index("Music") # มาจาก Audio

func _on_btn_mute_toggled(toggled_on: bool) -> void: # ปุ่มปิดเสียงดนตรี
	AudioServer.set_bus_mute(AudioServer.is_bus_mute(music_bus), toggled_on)
