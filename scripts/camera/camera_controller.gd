extends Object
class_name CameraController

var arm: SpringArm3D
var camera: Camera3D
var spring_length_animation: AnimationUtils = AnimationUtils.new(1,1,0)
var spring_rot_animation: Vector3AnimationUtils = Vector3AnimationUtils.new(Vector3(0,0,0),Vector3(0,0,0),0)
var is_moving: bool
var state: STATE = STATE.Normal
var time: int = 0
var key_down: int

enum STATE{
	Other,
	Normal,
	Up,
	Forward,
	Down,
	Left,
	Right
}

func _init(arm_ : SpringArm3D,camera_ : Camera3D) -> void:
	arm = arm_
	camera = camera_
	_enter()
	
func _enter() -> void:
	key_down = -999
	spring_rot_animation.play(true)
	spring_length_animation.play(true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _update(delta: float) -> void:
	animation_update(delta)
	camera_update(delta)
	
func _input_event(event: InputEvent) -> void:
	pass
		
func animation_update(delta: float) -> void:
	is_moving = !spring_length_animation.done || !spring_rot_animation.done
	spring_rot_animation.update(delta)
	spring_length_animation.update(delta)
	arm.spring_length = spring_length_animation.value
	camera.rotation = Vector3(deg_to_rad(spring_rot_animation.value.x),deg_to_rad(spring_rot_animation.value.y),deg_to_rad(spring_rot_animation.value.z))

func camera_update(delta: float) -> void:
	match state:
		STATE.Normal:
			move_(1,Vector3(0,0,0),time)
		STATE.Up:
			move_(3,Vector3(0,0,0),time)
		STATE.Down:
			move_(1,Vector3(0,0,0),time)
		STATE.Left:
			move_(1,Vector3(0,45,0),time)
		STATE.Right:
			move_(1,Vector3(0,-45,0),time)


func switch_state(state_: STATE,time_: int) -> void:
	if state_ != state:
		state = state_
		is_moving = true
	time = time_

func move_(length: float,rot: Vector3,time_: int) -> void:
	time = time_
	_set_targte_spring_length(length,time_)
	_set_targte_spring_rot(rot,time_)
	is_moving = !spring_length_animation.done || !spring_rot_animation.done
	
func is_state(state_: STATE) -> bool:
	return  state == state_

func _set_targte_spring_length(length: float,time: int) -> void:
	if spring_length_animation.end_value != length:
		spring_length_animation.set_target(length,time)
		spring_length_animation.play(true)

func _set_targte_spring_rot(rot: Vector3,time: int) -> void:
	if spring_rot_animation.end_value != rot:
		spring_rot_animation.set_target(rot,time)
		spring_rot_animation.play(true)
