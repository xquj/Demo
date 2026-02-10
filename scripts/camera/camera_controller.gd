extends Object
class_name CameraController

# 相机组件引用
var arm: SpringArm3D
var camera: Camera3D

enum STATE{
	Other,
	Normal,
	Up,
	Forward,
	Down,
	Left,
	Right
}

# 相机基础插值动画（用于视角切换）
var spring_length_animation: AnimationUtils = AnimationUtils.new(1,1,0)
var spring_rot_animation: Vector3AnimationUtils = Vector3AnimationUtils.new(Vector3(0,0,0),Vector3(0,0,0),0)

# 运行状态
var is_moving: bool
var state: STATE = STATE.Normal
var time: int = 0
var key_down: int

# 邪恶冥刻风格：相机摇晃基础参数
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _shake_power: float = 0.0
var _shake_seed: float = 0.0

# 邪恶冥刻风格：视角预设（长度、欧拉角、切换时长）
var _state_profile: Dictionary = {
	STATE.Normal: {
		"length": 1.0,
		"rot": Vector3(0,0,0),
		"time": 240
	},
	STATE.Up: {
		"length": 2.9,
		"rot": Vector3(-8,0,0),
		"time": 320
	},
	STATE.Forward: {
		"length": 0.62,
		"rot": Vector3(5,0,0),
		"time": 200
	},
	STATE.Down: {
		"length": 1.35,
		"rot": Vector3(16,0,0),
		"time": 220
	},
	STATE.Left: {
		"length": 1.2,
		"rot": Vector3(0,42,2.2),
		"time": 260
	},
	STATE.Right: {
		"length": 1.2,
		"rot": Vector3(0,-42,-2.2),
		"time": 260
	}
}

func _init(arm_ : SpringArm3D,camera_ : Camera3D) -> void:
	arm = arm_
	camera = camera_
	_enter()
	
func _enter() -> void:
	key_down = -999
	spring_rot_animation.play(true)
	spring_length_animation.play(true)
	# 用系统时间生成随机种子，让每次晃动轨迹不同
	_shake_seed = float(Time.get_ticks_msec() % 10000)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _update(delta: float) -> void:
	animation_update(delta)
	camera_update(delta)
	
func _input_event(event: InputEvent) -> void:
	# 在控制器内部处理按键，直接调用switch_state完成切镜
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and !key_event.echo:
			key_down = int(key_event.keycode)
			match key_event.keycode:
				KEY_W:
					switch_state(STATE.Up,240)
					play_inscryption_shake(0.28,0.12)
				KEY_S:
					switch_state(STATE.Down,220)
					play_inscryption_shake(0.25,0.12)
				KEY_A:
					switch_state(STATE.Left,240)
					play_inscryption_shake(0.22,0.1)
				KEY_D:
					switch_state(STATE.Right,240)
					play_inscryption_shake(0.22,0.1)
				KEY_Q:
					switch_state(STATE.Forward,180)
					play_inscryption_shake(0.35,0.14)
				KEY_E,KEY_ESCAPE:
					switch_state(STATE.Normal,220)
					play_inscryption_shake(0.18,0.09)
		if !key_event.pressed:
			# 松开控制键后自动回正，避免卡在侧视角
			if key_event.keycode in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_Q]:
				if key_down == int(key_event.keycode):
					key_down = -999
					switch_state(STATE.Normal,200)
		
func animation_update(delta: float) -> void:
	is_moving = !spring_length_animation.done || !spring_rot_animation.done
	spring_rot_animation.update(delta)
	spring_length_animation.update(delta)
	arm.spring_length = spring_length_animation.value
	# 先应用基础旋转，再叠加摇晃偏移，保证切镜与晃动可同时存在
	var base_rot := Vector3(
		deg_to_rad(spring_rot_animation.value.x),
		deg_to_rad(spring_rot_animation.value.y),
		deg_to_rad(spring_rot_animation.value.z)
	)
	_apply_shake(delta,base_rot)

func camera_update(delta: float) -> void:
	# 邪恶冥刻同款切镜核心：同一镜头在多个观察角间做缓动切换
	var profile: Dictionary = _get_state_profile(state)
	var move_time: int = profile["time"]
	if time > 0:
		move_time = time
	move_(profile["length"],profile["rot"],move_time)


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

# 外部可调用：触发邪恶冥刻风格的镜头摇晃
# power建议范围：0.2~1.5，duration建议范围：0.1~0.45秒
func play_inscryption_shake(power: float = 0.6,duration: float = 0.22) -> void:
	_shake_power = max(power,0.0)
	_shake_duration = max(duration,0.0)
	_shake_timer = _shake_duration
	_shake_seed += 17.0

func _set_targte_spring_length(length: float,time: int) -> void:
	if spring_length_animation.end_value != length:
		spring_length_animation.set_target(length,time)
		spring_length_animation.play(true)

func _set_targte_spring_rot(rot: Vector3,time: int) -> void:
	if spring_rot_animation.end_value != rot:
		spring_rot_animation.set_target(rot,time)
		spring_rot_animation.play(true)

# 获取状态配置：若状态异常，回落到Normal，避免空配置报错
func _get_state_profile(state_: STATE) -> Dictionary:
	if _state_profile.has(state_):
		return _state_profile[state_]
	return _state_profile[STATE.Normal]

# 叠加邪恶冥刻风格摇晃：仅旋转抖动（修复位移偏移BUG）
func _apply_shake(delta: float,base_rot: Vector3) -> void:
	# 修复偏移BUG：摇晃仅作用在旋转，不再改写camera.position
	# 之前的位移抖动在部分层级结构下会与SpringArm计算叠加，造成视角被“推走”
	if _shake_timer <= 0.0 or _shake_duration <= 0.0 or _shake_power <= 0.0:
		camera.rotation = base_rot
		return
	
	_shake_timer -= delta
	if _shake_timer < 0.0:
		_shake_timer = 0.0
	var t := _shake_duration - _shake_timer
	var normalized_t := clamp(t / _shake_duration,0.0,1.0)
	# 逐帧衰减，前段更猛、后段快速收敛，模拟邪恶冥刻的“击打感”
	var fade := pow(1.0 - normalized_t,2.2)
	var amp := _shake_power * fade
	
	# 通过多频率正弦构造可控随机感，避免纯随机导致画面跳变
	var rx := sin((_shake_seed + t * 29.0) * 1.71)
	var ry := sin((_shake_seed + t * 37.0) * 2.13 + 0.9)
	var rz := sin((_shake_seed + t * 41.0) * 2.61 + 1.7)
	
	# 旋转摇晃（角度小但高频）
	var rot_offset_deg := Vector3(rx,ry * 0.72,rz * 0.62) * (1.5 * amp)
	camera.rotation = base_rot + Vector3(
		deg_to_rad(rot_offset_deg.x),
		deg_to_rad(rot_offset_deg.y),
		deg_to_rad(rot_offset_deg.z)
	)
