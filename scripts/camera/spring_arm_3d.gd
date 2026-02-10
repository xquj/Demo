extends SpringArm3D

const CAMERA_ACTIONS: Array[StringName] = [
	&"camera_view_front",
	&"camera_view_left",
	&"camera_view_back",
	&"camera_view_right",
]

func _ready() -> void:
	global.camera_controller.initialize()

func _process(delta: float) -> void:
	global.camera_controller.update(delta)
	global.camera_controller.apply_to_spring_arm(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo:
		# API 接入优先：从 InputMap 动作名驱动相机方向。
		for action_name in CAMERA_ACTIONS:
			if InputMap.has_action(action_name) and event.is_action_pressed(action_name):
				if global.camera_controller.handle_board_action(action_name, 260):
					return

		# 兼容兜底：若未配置 InputMap，则仍支持 WASD。
		if global.camera_controller.focus_board_by_wasd(event.keycode, 260):
			return

		# 保留 C 键：在“手牌视角 <-> 桌面默认视角”之间切换。
		if event.keycode == KEY_C:
			global.camera_controller.toggle_state(260)
