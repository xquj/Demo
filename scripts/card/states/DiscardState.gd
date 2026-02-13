extends State
class_name DiscardState

func enter() -> void:
	super.enter()
	if card.player != null:
		if card.player.hand_cards.has(card):
			card.player.hand_cards.remove_at(card.player.hand_cards.find(card))
		if card.player.waitingGroup.has(card):
			card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))
	if not global.discard_group.has(card):
		global.discard_group.push_back(card)
	card.team_id = -1
	card.player = null
	if global.cube_desk != null:
		card.reparent(global.cube_desk)
	var target_pos: Vector3 = global.discard_pile.global_position if global.discard_pile != null else card.global_position
	_move_with_rotation(target_pos, Vector3(deg_to_rad(90), deg_to_rad(90), 0.0), 0.2, 0.0, MoveMode.LINEAR, 1.0)

func update(delta: float) -> void:
	super.update(delta)

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
