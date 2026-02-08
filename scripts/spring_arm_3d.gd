extends SpringArm3D

var spring_length_delta: float = 0;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.spring_length_animation = AnimationUtils.new(1,1,500)
	global.spring_length_animation.play(true)
	global.spring_rotX_animation = AnimationUtils.new(45,45,500)
	global.spring_rotX_animation.play(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global.spring_rotX_animation.update(delta)
	global.spring_length_animation.update(delta)
	spring_length = global.spring_length_animation.value
	rotation.x = deg_to_rad(global.spring_rotX_animation.value)

func _input(event: InputEvent) -> void:
	pass
