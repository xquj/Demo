extends SpringArm3D

func _ready() -> void:
	global.camera_controller.initialize()

func _process(delta: float) -> void:
	global.camera_controller.update(delta)
	global.camera_controller.apply_to_spring_arm(self)

func _input(event: InputEvent) -> void:
	pass
