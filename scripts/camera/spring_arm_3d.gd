extends SpringArm3D

func _ready() -> void:
	global.camera_controller.initialize()

func _process(delta: float) -> void:
	global.camera_controller.update(delta)
	global.camera_controller.apply_to_spring_arm(self)

func _input(event: InputEvent) -> void:
	# 按 C 键切换相机视角（手牌视角 <-> 桌面视角）。
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_C:
			global.camera_controller.toggle_state(260)
