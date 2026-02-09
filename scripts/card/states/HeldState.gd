extends State
class_name HeldState


var area: Area3D
var is_entered: bool
var base_pos: Vector3
var base_rot: Vector3
var base_bottom_pos: Vector3

const HOVER_HEIGHT: float = 0.06
const HOVER_FORWARD: float = 0.08
const HOVER_ROT_DEG: float = 12.0
const HOVER_DURATION: float = 0.12
const FAN_SPREAD_DEG: float = 32.0

func enter() -> void:
	super.enter()
	#区域初始化
	for child in card.get_children():
		if child as Area3D:
			area = child
			break
	if area != null:
		area.mouse_entered.connect(func():mouse_entered(true))
		area.mouse_exited.connect(func():mouse_entered(false))
		area.visible = true
	base_pos = card.global_position
	base_rot = card.rotation
	base_bottom_pos = _get_bottom_anchor_pos(base_pos, card.global_transform.basis)
	
func exit() -> void:
	super.exit()
	if area != null:
		area.visible = false
	card.set_color(card.original_modulate,100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	_update_hand_layout()
	if !is_entered and !card.moving_ablity:
		card.global_position = base_pos
		card.rotation = base_rot


func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				pass
				#transition_to(load("res://scripts/card/states/ToWaitState.gd"))
	
func mouse_entered(entered: bool) -> void:
	if card.state != self or area == null or !area.visible:
		return
	is_entered = entered
	if entered:
		card.set_color(Color(0.75, 0.75, 0.75, 1.0),100)
		var forward: Vector3 = -global.camera.global_transform.basis.z.normalized()
		var target_pos: Vector3 = base_pos + Vector3(0.0, HOVER_HEIGHT, 0.0) + forward * HOVER_FORWARD
		var target_rot: Vector3 = base_rot + Vector3(deg_to_rad(-HOVER_ROT_DEG), 0.0, 0.0)
		_move_with_rotation(target_pos, target_rot, HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)
	else:
		card.set_color(card.original_modulate,100)
		_move_with_rotation(base_pos, base_rot, HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)

func _update_hand_layout() -> void:
	if card == null or card.player == null:
		return
	if card.team_id != global.local_player.team_id:
		return
	if is_entered:
		return
	var hand_cards: Array = card.player.hand_cards
	var count: int = hand_cards.size()
	if count == 0:
		return
	var index: int = hand_cards.find(card)
	if index == -1:
		return
	var t: float = 0.5
	if count > 1:
		t = float(index) / float(count - 1)
	var angle_deg: float = lerp(-FAN_SPREAD_DEG * 0.5, FAN_SPREAD_DEG * 0.5, t)
	var angle_rad: float = deg_to_rad(angle_deg)
	base_bottom_pos = _get_bottom_anchor_pos(card.global_position, card.global_transform.basis)
	base_rot = card.rotation
	base_rot.z = -angle_rad
	var new_up: Vector3 = Basis.from_euler(base_rot).y.normalized()
	var half_height: float = _get_half_height()
	base_pos = base_bottom_pos + new_up * half_height

func _get_half_height() -> float:
	if card == null or card.texture == null:
		return 0.0
	return card.texture.get_size().y * card.pixel_size * card.scale.y * 0.5

func _get_bottom_anchor_pos(center_pos: Vector3, basis: Basis) -> Vector3:
	return center_pos - basis.y.normalized() * _get_half_height()
