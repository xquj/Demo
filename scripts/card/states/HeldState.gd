extends State
class_name HeldState


var area: Area3D
var is_entered: bool
var base_local_pos: Vector3
var base_pos: Vector3
var base_rot: Vector3
var base_bottom_local_pos: Vector3

const HOVER_HEIGHT: float = 0.04
const HOVER_FORWARD: float = 0.02
const HOVER_ROT_DEG: float = 0.005
const HOVER_DURATION: float = 0.12
const FAN_SPREAD_DEG: float = 14.0
const FAN_SPREAD_MIN_DEG: float = 6.0
const FAN_SHRINK_START_COUNT: int = 6
const FAN_SHRINK_STEP_DEG: float = 1.0
const FAN_CURVE_OUT: float = 0.03

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
	base_local_pos = card.position
	base_pos = card.global_position
	base_rot = card.rotation
	base_bottom_local_pos = _get_bottom_anchor_pos(base_local_pos, card.transform.basis)
	
func exit() -> void:
	super.exit()
	if area != null:
		area.visible = false
	card.set_color(card.original_modulate,100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	if global.spring_rotX_animation.done and global.cube_rot_animation.done:
		_update_hand_layout()


func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				pass
				#transition_to(load("res://scripts/card/states/ToWaitState.gd"))
	
func mouse_entered(entered: bool) -> void:
	if card.state != self or area == null or !area.visible or !global.cube_rot_animation.done or !global.spring_rotX_animation.done:
		return
	is_entered = entered
	if entered:
		card.set_color(Color(0.75, 0.75, 0.75, 1.0),100)
		var forward: Vector3 = -Vector3.FORWARD
		var target_pos: Vector3 = _get_parent_global_pos(
			base_local_pos + Vector3(0.0, HOVER_HEIGHT, 0.0) + forward * HOVER_FORWARD
		)
		var target_rot: Vector3 = base_rot + Vector3(deg_to_rad(-HOVER_ROT_DEG), 0.0, 0.0)
		_move_with_rotation(target_pos, target_rot, HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)
	else:
		card.set_color(card.original_modulate,100)
		var target_pos: Vector3 = _get_parent_global_pos(base_local_pos)
		_move_with_rotation(target_pos, base_rot, HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)

func _update_hand_layout() -> void:
	if card == null or card.player == null:
		return
	if card.team_id != global.local_player.team_id:
		return
	var hand_cards: Array = card.player.hand_cards
	var count: int = hand_cards.size()
	if count == 0:
		return
	var index: int = hand_cards.find(card)
	if index == -1:
		return
	var shrink_steps: int = max(0, count - FAN_SHRINK_START_COUNT)
	var spread_deg: float = max(FAN_SPREAD_MIN_DEG, FAN_SPREAD_DEG - float(shrink_steps) * FAN_SHRINK_STEP_DEG)
	var t: float = 0.5
	if count > 1:
		t = float(index) / float(count - 1)
	var angle_deg: float = lerp(-spread_deg * 0.5, spread_deg * 0.5, t)
	var angle_rad: float = deg_to_rad(angle_deg)
	base_rot.z = -angle_rad
	var basis: Basis = Basis.from_euler(base_rot)
	var new_up: Vector3 = basis.y.normalized()
	var forward_dir: Vector3 = -basis.z.normalized()
	var half_height: float = _get_half_height()
	var curve_t: float = 1.0 - abs(2.0 * t - 1.0)
	var curve_offset: float = FAN_CURVE_OUT * curve_t * curve_t
	base_local_pos = base_bottom_local_pos + new_up * half_height + forward_dir * curve_offset
	base_pos = _get_parent_global_pos(base_local_pos)
	if !is_entered and !card.moving_ablity:
		if card.global_position.distance_to(base_pos) > 0.0001 or card.rotation != base_rot:
			_move_with_rotation(base_pos, base_rot, 0.0, 0.0, MoveMode.LINEAR, 1.0)

func _get_half_height() -> float:
	if card == null or card.texture == null:
		return 0.0
	return card.texture.get_size().y * card.pixel_size * card.scale.y * 0.5

func _get_bottom_anchor_pos(center_pos: Vector3, basis: Basis) -> Vector3:
	return center_pos - basis.y.normalized() * _get_half_height()

func _get_parent_global_pos(local_pos: Vector3) -> Vector3:
	if card == null:
		return local_pos
	var parent: Node3D = card.get_parent() as Node3D
	if parent == null:
		return local_pos
	return parent.to_global(local_pos)
