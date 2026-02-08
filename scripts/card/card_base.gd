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
var target_pos: Vector3
var moving_ablity: bool
var duration: float
var elapsed: float

func _ready() -> void:
	global_position = global.Deck.global_position
	state = DealingState.new(self)
	
func _process(delta: float) -> void:
	state._process(delta)
	
func _input(event: InputEvent) -> void:
	state._input(event)
