extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# สั่งให้ Viewport หลักแสดงผลในแว่น VR
		get_viewport().use_xr = true
	else:
		print("OpenXR failed to initialize. Check your headset connection.")
