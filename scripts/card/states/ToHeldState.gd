extends State
class_name ToHeldState

func enter() -> void:
	super.enter()
	if card.player == null:
		push_warning("ToHeldState: card.player is null, skip transition.")
		return
	if card.player != null and not card.player.hand_cards.has(card):
		card.player.hand_cards.push_back(card)
	var idx = card.player.hand_cards.find(card) + 1

	var target: Dictionary = SceneLayoutSystem.get_to_held_target(card, idx)
	var target_pos: Vector3 = target.get("position", card.global_position)
	var target_rot: Vector3 = target.get("rotation", card.rotation)
	var target_parent: Node = target.get("parent")
	var duration: float = float(target.get("duration", HandLayoutConfig.TO_HELD_DURATION))
	if target_parent != null:
		card.reparent(target_parent)

	global.debug_log(
		"ToHeldState.enter: card=%s team=%s idx=%s rot=(%.2f, %.2f, %.2f)" % [
			card.card_id,
			str(card.team_id),
			str(idx),
			rad_to_deg(target_rot.x),
			rad_to_deg(target_rot.y),
			rad_to_deg(target_rot.z)
		]
	)

	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2, target_pos.y, (card.start_pos.z + target_pos.z) / 2), target_rot, duration)

func exit() -> void:
	super.exit()
	if card.player == null:
		return
	if card.player.waitingGroup.has(card):
		card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))

func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(load("res://scripts/card/states/HeldState.gd"))

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
