extends Sprite3D
class_name Card_Base 

#基本属性
var card_name: String
var family_name: String
var health: int
var cost: int
var selling_price: int
#状态
var state: State
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
var moving_ablity: bool
var duration: float
var elapsed: float

func _ready() -> void:
	rotation = Vector3(deg_to_rad(90),deg_to_rad(90),deg_to_rad(0))
	global_position = global.Deck.global_position
	start_pos = global_position
	start_rot = rotation
	target_rot = rotation
	start_scale = scale
	target_scale = scale
	control_pos = global_position
	moving_ablity = false
	duration = 0.0
	elapsed = 0.0
	state = DealingState.new(self)
	
func _process(delta: float) -> void:
	state._process(delta)
	
func _input(event: InputEvent) -> void:
	state._input(event)
