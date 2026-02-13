extends Sprite3D
class_name Card_Base

enum States {
	DEALING,
	SELECTING,
	TO_WAIT,
	WAITING,
	TO_HELD,
	HELD,
	DISCARD
}

const DEALING_STATE_SCRIPT: Script = preload("res://scripts/card/states/DealingState.gd")
const SELECTING_STATE_SCRIPT: Script = preload("res://scripts/card/states/SelectingState.gd")
const TO_WAIT_STATE_SCRIPT: Script = preload("res://scripts/card/states/ToWaitState.gd")
const WAITING_STATE_SCRIPT: Script = preload("res://scripts/card/states/WaitingState.gd")
const TO_HELD_STATE_SCRIPT: Script = preload("res://scripts/card/states/ToHeldState.gd")
const HELD_STATE_SCRIPT: Script = preload("res://scripts/card/states/HeldState.gd")
const DISCARD_STATE_SCRIPT: Script = preload("res://scripts/card/states/DiscardState.gd")

var card_name: String
var family_name: String
var health: int
var cost: int
var selling_price: int
var team_id: int
var player: PlayerEntity
var card_id: String
var keywords: Array[String] = []

var state: State
var color_animation: ColorAnimationUtils

var start_pos: Vector3
var target_pos: Vector3
var start_rot: Vector3
var target_rot: Vector3
var start_scale: Vector3
var target_scale: Vector3
var control_pos: Vector3
var moving_ability: bool
var duration: float
var elapsed: float

var original_modulate: Color
var original_scale: Vector3

func _ready() -> void:
	team_id = -1
	player = null
	original_scale = scale
	original_modulate = modulate
	color_animation = ColorAnimationUtils.new(modulate, modulate, 0)
	rotation = Vector3(deg_to_rad(90), deg_to_rad(90), deg_to_rad(0))
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

func apply_data(card_def: Dictionary) -> void:
	card_id = str(card_def.get("id", ""))
	card_name = str(card_def.get("name", ""))
	family_name = str(card_def.get("family", ""))
	health = int(card_def.get("health", 0))
	cost = int(card_def.get("cost", 0))
	selling_price = int(card_def.get("selling_price", 0))
	keywords.clear()
	for keyword in card_def.get("keywords", []):
		keywords.push_back(str(keyword))
	var texture_path: String = str(card_def.get("texture", ""))
	if texture_path != "":
		var front_texture: Texture2D = load(texture_path)
		if front_texture != null:
			texture = front_texture

func _process(delta: float) -> void:
	state._process(delta)
	color_animation.update(delta)
	modulate = color_animation.value

func _input(event: InputEvent) -> void:
	state._input(event)

func set_color(color: Color, dur: int) -> void:
	if color_animation.end_color != color:
		color_animation.set_target(color, dur)
		color_animation.play(true)

func switch_state(next_state: States) -> void:
	if state == null:
		return
	var state_script: Script = _get_state_script(next_state)
	if state_script == null:
		return
	state.transition_to(state_script)

func _get_state_script(next_state: States) -> Script:
	match next_state:
		States.DEALING:
			return DEALING_STATE_SCRIPT
		States.SELECTING:
			return SELECTING_STATE_SCRIPT
		States.TO_WAIT:
			return TO_WAIT_STATE_SCRIPT
		States.WAITING:
			return WAITING_STATE_SCRIPT
		States.TO_HELD:
			return TO_HELD_STATE_SCRIPT
		States.HELD:
			return HELD_STATE_SCRIPT
		States.DISCARD:
			return DISCARD_STATE_SCRIPT
		_:
			return null
