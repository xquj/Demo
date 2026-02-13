extends State
class_name HeldState

var area: Area3D
var is_entered: bool
var base_local_pos: Vector3
var base_pos: Vector3
var base_rot: Vector3
var base_rot_origin: Vector3
var base_bottom_local_pos: Vector3
var base_bottom_local_origin: Vector3

func enter() -> void:
	super.enter()
	for child in card.get_children():
		if child as Area3D:
			area = child
			break
	if area != null:
		var on_entered: Callable = Callable(self, "_on_area_mouse_entered")
		var on_exited: Callable = Callable(self, "_on_area_mouse_exited")
		if not area.mouse_entered.is_connected(on_entered):
			area.mouse_entered.connect(on_entered)
		if not area.mouse_exited.is_connected(on_exited):
			area.mouse_exited.connect(on_exited)
		area.visible = CardViewPolicy.should_show_interaction_area(card)
	base_local_pos = card.position
	base_pos = card.global_position
	base_rot = card.rotation
	base_rot_origin = card.rotation
	base_bottom_local_origin = SceneLayoutSystem.get_bottom_anchor_pos(card, base_local_pos, card.transform.basis)
	base_bottom_local_origin.x = 0.0
	base_bottom_local_pos = base_bottom_local_origin
	global.debug_log("HeldState.enter: card=%s team=%s" % [card.card_id, str(card.team_id)])

func exit() -> void:
	super.exit()
	if area != null:
		var on_entered: Callable = Callable(self, "_on_area_mouse_entered")
		var on_exited: Callable = Callable(self, "_on_area_mouse_exited")
		if area.mouse_entered.is_connected(on_entered):
			area.mouse_entered.disconnect(on_entered)
		if area.mouse_exited.is_connected(on_exited):
			area.mouse_exited.disconnect(on_exited)
		area.visible = false
	card.set_color(card.original_modulate,100)

func update(delta: float) -> void:
	super.update(delta)
	_update_hand_layout()

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if not CardViewPolicy.is_local_owned_card(card):
		return
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				pass

func mouse_entered(entered: bool) -> void:
	if not CardViewPolicy.is_local_owned_card(card):
		return
	if card.state != self or area == null or !area.visible or global.is_transitional_state():
		return
	is_entered = entered
	if entered:
		card.set_color(Color(0.75, 0.75, 0.75, 1.0),100)
		var forward: Vector3 = -Vector3.FORWARD
		var target_pos: Vector3 = SceneLayoutSystem.to_parent_global(
			card,
			base_local_pos + Vector3(0.0, HandLayoutConfig.HOVER_HEIGHT, 0.0) + forward * HandLayoutConfig.HOVER_FORWARD
		)
		var target_rot: Vector3 = base_rot + Vector3(deg_to_rad(-HandLayoutConfig.HOVER_ROT_DEG), 0.0, 0.0)
		_move_with_rotation(target_pos, target_rot, HandLayoutConfig.HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)
	else:
		card.set_color(card.original_modulate,100)
		var target_pos: Vector3 = SceneLayoutSystem.to_parent_global(card, base_local_pos)
		_move_with_rotation(target_pos, base_rot, HandLayoutConfig.HOVER_DURATION, 0.0, MoveMode.LINEAR, 1.0)

func _update_hand_layout() -> void:
	if card == null or card.player == null:
		return
	var hand_cards: Array = card.player.hand_cards
	var count: int = hand_cards.size()
	if count == 0:
		return
	var index: int = hand_cards.find(card)
	if index == -1:
		return
	var layout: Dictionary = SceneLayoutSystem.calculate_held_layout(
		card,
		index,
		count,
		base_bottom_local_origin,
		base_rot_origin
	)
	base_local_pos = layout.get("local_pos", base_local_pos)
	base_bottom_local_pos = layout.get("bottom_local_pos", base_bottom_local_pos)
	base_rot = layout.get("rotation", base_rot)
	base_pos = layout.get("global_pos", base_pos)
	if !is_entered and !card.moving_ability:
		if card.global_position.distance_to(base_pos) > 0.0001 or card.rotation != base_rot:
			_move_with_rotation(base_pos, base_rot, 0.1, 0.0, MoveMode.LINEAR, 1.0)

func _on_area_mouse_entered() -> void:
	mouse_entered(true)

func _on_area_mouse_exited() -> void:
	mouse_entered(false)
