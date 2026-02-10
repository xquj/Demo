extends Sprite3D
class_name Card_Base 

#基本属性
var card_name: String
var family_name: String
var health: int
var cost: int
var selling_price: int
var team_id: int
var player: PlayerEntity
#状态机
var state: State
#动画
var color_animation: ColorAnimationUtils;
# 位移相关参数
var start_pos: Vector3
var target_pos: Vector3
# 旋转相关参数（用于状态机插值）
var start_rot: Vector3
var target_rot: Vector3
# 缩放相关参数（用于状态机插值）
var start_scale: Vector3
var target_scale: Vector3
# 贝塞尔控制点
var control_pos: Vector3
# 运动开关与时间参数
var moving_ability: bool
var duration: float
var elapsed: float
#Other
var original_modulate: Color
var original_scale: Vector3

func _ready() -> void:
	team_id = -1
	player = null
	original_scale = scale
	original_modulate = modulate
	color_animation = ColorAnimationUtils.new(modulate,modulate,0)
	rotation = Vector3(deg_to_rad(90),deg_to_rad(90),deg_to_rad(0))
	global_position = global.deck.global_position
	start_pos = global_position
	start_rot = rotation
	target_rot = rotation
	start_scale = scale
	target_scale = scale
	control_pos = global_position
	moving_ability = false
	duration = 0.0
	elapsed = 0.0
	state = DealingState.new(self)
	
func _process(delta: float) -> void:
	state._process(delta)
	color_animation.update(delta)
	modulate = color_animation.value
	
func _input(event: InputEvent) -> void:
	state._input(event)

func set_color(color: Color,dur: int) -> void:
	if color_animation.end_color != color:
		color_animation.set_target(color,dur)
		color_animation.play(true)
		
	
		
