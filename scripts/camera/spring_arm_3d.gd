extends SpringArm3D

const CAMERA_ACTIONS: Array[StringName] = [
	CameraController.ACTION_VIEW_FRONT,
	CameraController.ACTION_VIEW_LEFT,
	CameraController.ACTION_VIEW_BACK,
	CameraController.ACTION_VIEW_RIGHT,
	CameraController.ACTION_TOGGLE,
	CameraController.ACTION_FOCUS_HAND,
	CameraController.ACTION_FOCUS_BOARD,
]

func _ready() -> void:
	global.camera_controller.initialize()
	_ensure_camera_actions_registered()

func _process(delta: float) -> void:
	global.camera_controller.update(delta)
	global.camera_controller.apply_to_spring_arm(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo:
		# API 接入：全部通过动作名分发到 CameraController。
		for action_name in CAMERA_ACTIONS:
			if event.is_action_pressed(action_name):
				if global.camera_controller.handle_camera_action(action_name, 260):
					return

func _ensure_camera_actions_registered() -> void:
	# 统一在运行时注册默认动作，避免依赖 project.godot 预配置。
	_register_action_if_missing(CameraController.ACTION_VIEW_FRONT, KEY_W)
	_register_action_if_missing(CameraController.ACTION_VIEW_LEFT, KEY_A)
	_register_action_if_missing(CameraController.ACTION_VIEW_BACK, KEY_S)
	_register_action_if_missing(CameraController.ACTION_VIEW_RIGHT, KEY_D)
	_register_action_if_missing(CameraController.ACTION_TOGGLE, KEY_C)
	_register_action_if_missing(CameraController.ACTION_FOCUS_HAND, KEY_Q)
	_register_action_if_missing(CameraController.ACTION_FOCUS_BOARD, KEY_E)

func _register_action_if_missing(action_name: StringName, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)
