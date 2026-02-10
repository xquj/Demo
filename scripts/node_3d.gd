extends Node3D

const HAND_CARDS_MAX: int = 14
const DEAL_INTERVAL: int = 30

var tick: int = 0
var _cards_node: Node = null

func _ready() -> void:
	_setup_global_references()
	_reset_match_state()


func _process(delta: float) -> void:
	_update_camera_and_animations(delta)
	_update_hand_count_label()
	_process_game_state()
	tick += 1


func _input(event: InputEvent) -> void:
	global.camera_controller._input_event(event)


func _on_sell_button_up() -> void:
	if global.current_state != global.GameState.WAITING:
		return
	if global.selected_card == null:
		return

	var card: Card_Base = global.selected_card
	var player: PlayerEntity = global.players[card.team_id - 1]
	player.inventory_temporary.add_items(card.selling_price)
	card.switch_state(card.States.DISCARD)
	global.selected_card = null


func _on_tame_button_up() -> void:
	if global.current_state != global.GameState.WAITING:
		return
	if global.selected_card == null:
		return

	var card: Card_Base = global.selected_card
	var player: PlayerEntity = global.players[card.team_id - 1]
	if player.hand_cards.size() >= HAND_CARDS_MAX:
		return

	card.switch_state(card.States.TO_HELD)
	global.selected_card = null


func _hover(m_x: float, m_y: float, x: float, y: float, x1: float, y1: float) -> bool:
	return m_x >= x and m_x <= x1 and m_y >= y and m_y <= y1


func initialize_card(sprite: Sprite3D) -> void:
	sprite.set_script(load("res://scripts/card/card_base.gd"))
	global.selected_group.push_back(sprite)
	var last_card: Card_Base = global.selected_group.back()
	if last_card.get_parent() == null:
		global.cube_desk.add_child(last_card)


func _setup_global_references() -> void:
	global.deck = $Scene3D/Desk/Deck
	global.discard_pile = $Scene3D/Desk/DiscardPile
	global.cube_desk = $Scene3D/Desk

	global.cards_number_label = $Scene3D/Desk/HeldArea1/CardsNumber
	global.showing_area_label = $Scene3D/Desk/ShowArea
	global.wait_area1_label = $Scene3D/Desk/WaitArea1
	global.wait_area2_label = $Scene3D/Desk/WaitArea2
	global.held_area1_label = $Scene3D/Desk/HeldArea1
	global.held_area2_label = $Scene3D/Desk/HeldArea2

	global.multi_player_node = $MultiPlayer
	global.camera = $LocalPlayer/SpringArm3D/Camera3D
	global.camera_controller = CameraController.new($LocalPlayer/SpringArm3D, $LocalPlayer/SpringArm3D/Camera3D)

	_cards_node = $Cards


func _reset_match_state() -> void:
	global.current_play_turn = 0
	global.round = 0
	global.game_progress = 1
	global.cube_rot_animation.play(true)


func _update_camera_and_animations(delta: float) -> void:
	global.camera_controller._update(delta)
	global.cube_rot_animation.update(delta)


func _update_hand_count_label() -> void:
	var hand_size: int = global.local_player.hand_cards.size()
	global.cards_number_label.text = "(%s/%s)" % [str(hand_size), str(HAND_CARDS_MAX)]


func _process_game_state() -> void:
	match global.current_state:
		global.GameState.DEALING:
			_handle_dealing_state()
		global.GameState.SELECTING:
			_handle_selecting_state()
		global.GameState.WAITING:
			_handle_waiting_state()
		global.GameState.COMBOING:
			_handle_comboing_state()
		global.GameState.END:
			_handle_end_state()


func _handle_dealing_state() -> void:
	global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
	for player in global.players:
		player.can_combo = true

	global.round = global.game_progress - 1
	if _finished_dealing():
		if not global.selected_group.back().moving_ability:
			global.current_state = global.GameState.SELECTING
		return

	if tick % DEAL_INTERVAL == 0:
		_spawn_next_card()


func _handle_selecting_state() -> void:
	if global.selected_group.size() == 0:
		global.current_state = global.GameState.WAITING

	_update_player_activity()
	for player in global.players:
		player.process()


func _handle_waiting_state() -> void:
	if global.cube_rot_animation.done and global.cube_rot_animation.end_value == 90:
		global.current_state = global.GameState.COMBOING
		global.camera_controller.switch_state(global.camera_controller.STATE.Up, 250)

	global.round = global.game_progress - 1
	global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)


func _handle_comboing_state() -> void:
	global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
	if global.round > global.game_progress:
		global.current_state = global.GameState.END
		global.round = 0
		return

	_update_player_activity()
	for player in global.players:
		player.process()


func _handle_end_state() -> void:
	global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)
	if global.cube_rot_animation.end_value != 0:
		global.camera_controller.switch_state(global.camera_controller.STATE.Up, 250)
		global.cube_rot_animation.set_target(0, 500)
		global.cube_rot_animation.play(true)

	if global.cube_rot_animation.done and global.cube_rot_animation.end_value == 0:
		global.player_activity = null
		global.game_progress += 1
		global.current_state = global.GameState.DEALING
		global.cube_desk.global_rotation.z = 0


func _finished_dealing() -> bool:
	return global.selected_group.size() >= global.players.size() * 2


func _spawn_next_card() -> void:
	if _cards_node == null:
		return

	var cards_count: int = _cards_node.get_child_count()
	if cards_count == 0:
		return

	var card_index: int = (tick / DEAL_INTERVAL) % cards_count
	var source_sprite: Sprite3D = _cards_node.get_child(card_index).duplicate()
	source_sprite.visible = true
	initialize_card(source_sprite)


func _update_player_activity() -> void:
	var players_size: int = global.players.size()
	var threshold: int = players_size + global.game_progress - 1

	for player in global.players:
		var is_active: bool
		if global.round < threshold:
			is_active = player.team_id == (global.round % 2 + 1)
		else:
			is_active = player.team_id == (players_size - (global.round % 2))

		player.is_active = is_active
		if is_active:
			global.player_activity = player
