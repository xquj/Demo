extends RefCounted
class_name TurnSystem

const HAND_CARDS_MAX: int = 14

func sell_selected_card() -> void:
	if global.current_state != global.GameState.WAITING:
		return
	if global.selected_card == null:
		return
	var card: Card_Base = global.selected_card
	var player_index: int = card.team_id - 1
	if player_index < 0 or player_index >= global.players.size():
		push_warning("TurnSystem: invalid card team id when selling: %s" % str(card.team_id))
		return
	var player: PlayerEntity = global.players[player_index]
	player.add_items(card.selling_price)
	card.switch_state(card.States.DISCARD)
	global.selected_card = null

func tame_selected_card() -> void:
	if global.current_state != global.GameState.WAITING:
		return
	if global.selected_card == null:
		return
	var card: Card_Base = global.selected_card
	var player_index: int = card.team_id - 1
	if player_index < 0 or player_index >= global.players.size():
		push_warning("TurnSystem: invalid card team id when taming: %s" % str(card.team_id))
		return
	var player: PlayerEntity = global.players[player_index]
	if player.hand_cards.size() >= HAND_CARDS_MAX:
		return
	card.switch_state(card.States.TO_HELD)
	global.selected_card = null

func commit_selecting_card(card: Card_Base) -> void:
	global.round += 1
	if global.selected_group.has(card):
		global.selected_group.remove_at(global.selected_group.find(card))
	if global.player_activity != null:
		card.team_id = global.player_activity.team_id
		card.player = global.player_activity
		card.player.waitingGroup.push_back(card)
	card.start_pos = card.global_position

func enter_to_held(card: Card_Base) -> void:
	if card.player != null and not card.player.hand_cards.has(card):
		card.player.hand_cards.push_back(card)

func exit_to_held(card: Card_Base) -> void:
	if card.player != null and card.player.waitingGroup.has(card):
		card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))
