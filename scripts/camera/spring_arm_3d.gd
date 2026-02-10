extends SpringArm3D

func _ready() -> void:
	global.camera_controller.initialize()

func _process(delta: float) -> void:
	global.camera_controller.update(delta)
	global.camera_controller.apply_to_spring_arm(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo:
		# 邪恶冥刻风格：WASD 快速切换桌面观察角度。
		# W=前 / A=左 / S=后 / D=右
		if global.camera_controller.focus_board_by_wasd(event.keycode, 260):
			return
		# 保留 C 键：在“手牌视角 <-> 桌面默认视角”之间切换。
		if event.keycode == KEY_C:
			global.camera_controller.toggle_state(260)
