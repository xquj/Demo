extends RefCounted
class_name BattleFlow

var game_scene: GameScene3D
var turn_system: TurnSystem
var card_spawn_system: CardSpawnSystem
var _waiting_ready_teams: Dictionary = {}
var _combo_turn_order: Array[int] = []
var _combo_turn_index: int = 0

func _init(game_scene_: GameScene3D, turn_system_: TurnSystem, card_spawn_system_: CardSpawnSystem) -> void:
	game_scene = game_scene_
	turn_system = turn_system_
	card_spawn_system = card_spawn_system_

func request_state_change(state: global.GameState) -> bool:
	if state == global.current_state:
		return false
	if global.is_transitional_state():
		push_warning("BattleFlow: ignored state request while transitioning: %s -> %s" % [str(global.current_state), str(state)])
		return false
	match state:
		global.GameState.DEALING:
			global.debug_log("BattleFlow: request state DEALING")
			_init_dealing_state()
			return true
		global.GameState.SELECTING:
			global.debug_log("BattleFlow: request state SELECTING")
			_init_selecting_state()
			return true
		global.GameState.WAITING:
			global.debug_log("BattleFlow: request state WAITING")
			_init_waiting_state()
			return true
		global.GameState.COMBOING:
			global.debug_log("BattleFlow: request state COMBOING")
			_init_comboing_state()
			return true
		_:
			push_warning("BattleFlow: unsupported state request: %s" % str(state))
			return false

func try_enter_comboing_from_waiting() -> bool:
	if global.current_state != global.GameState.WAITING:
		return false
	if global.cube_rot_animation.end_value == 90:
		return false
	for player in global.players:
		if not player.can_combo:
			return false
		if player.waitingGroup.size() > 0:
			return false
	return request_state_change(global.GameState.COMBOING)

func request_advance_combo_round(requester: PlayerEntity) -> bool:
	if global.current_state != global.GameState.COMBOING:
		return false
	if requester == null or global.player_activity == null:
		return false
	if requester.team_id != global.player_activity.team_id:
		return false
	_combo_turn_index += 1
	if _combo_turn_index >= _combo_turn_order.size():
		request_state_change(global.GameState.DEALING)
	return true

func process_formal_state() -> void:
	match global.current_state:
		global.GameState.DEALING:
			_handle_dealing_state()
		global.GameState.SELECTING:
			_handle_selecting_state()
		global.GameState.WAITING:
			_handle_waiting_state()
		global.GameState.COMBOING:
			_handle_comboing_state()

func process_transitional_state() -> void:
	match global.current_state:
		global.GameState.TO_DEALING:
			_handle_to_dealing_state()
		global.GameState.TO_SELECTING:
			_handle_to_selecting_state()
		global.GameState.TO_WAITING:
			_handle_to_waiting_state()
		global.GameState.TO_COMBOING:
			_handle_to_comboing_state()

func reset_match_state() -> void:
	global.current_play_turn = 0
	global.round = 0
	global.game_progress = 1
	global.cube_rot_animation.play(true)

func _init_dealing_state() -> void:
	global.current_state = global.GameState.TO_DEALING
	global.camera_controller.switch_state(global.camera_controller.STATE.Up, 250)
	global.player_activity = null
	global.game_progress += 1
	global.cube_rot_animation.set_target(0, 500)
	global.cube_rot_animation.play(true)

func _init_selecting_state() -> void:
	global.current_state = global.GameState.TO_SELECTING

func _init_waiting_state() -> void:
	global.current_state = global.GameState.TO_WAITING
	_waiting_ready_teams.clear()
	for player in global.players:
		_waiting_ready_teams[player.team_id] = false

func _init_comboing_state() -> void:
	global.current_state = global.GameState.TO_COMBOING
	global.round = 0
	_build_combo_turn_order()
	_combo_turn_index = 0
	global.cube_rot_animation.set_target(90, 500)
	global.cube_rot_animation.play(true)
	global.camera_controller.switch_state(global.camera_controller.STATE.Up, 250)

func _handle_dealing_state() -> void:
	for player in global.players:
		player.can_combo = true
	global.round = global.game_progress - 1
	if _finished_dealing():
		if not global.selected_group.back().moving_ability:
			request_state_change(global.GameState.SELECTING)
		return
	card_spawn_system.spawn_next_card_if_due()

func _handle_selecting_state() -> void:
	if global.selected_group.size() == 0:
		request_state_change(global.GameState.WAITING)
	_update_player_activity()
	for player in global.players:
		player.process()

func _handle_waiting_state() -> void:
	for player in global.players:
		if player.waitingGroup.size() > 0:
			_waiting_ready_teams[player.team_id] = false
	_update_player_activity()
	for player in global.players:
		player.process()

func _handle_comboing_state() -> void:
	_update_player_activity()
	for player in global.players:
		player.process()

func _handle_to_dealing_state() -> void:
	if not global.camera_controller.is_moving:
		if global.camera_controller.is_state(global.camera_controller.STATE.Up):
			global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
		else:
			global.current_state = global.GameState.DEALING

func _handle_to_selecting_state() -> void:
	global.current_state = global.GameState.SELECTING

func _handle_to_waiting_state() -> void:
	global.current_state = global.GameState.WAITING

func _handle_to_comboing_state() -> void:
	if not global.camera_controller.is_moving:
		if global.camera_controller.is_state(global.camera_controller.STATE.Up):
			global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
		else:
			global.current_state = global.GameState.COMBOING

func _finished_dealing() -> bool:
	return global.selected_group.size() >= global.players.size() * 2

func request_waiting_ready(player: PlayerEntity) -> bool:
	if player == null:
		return false
	if global.current_state != global.GameState.WAITING:
		return false
	if not _waiting_ready_teams.has(player.team_id):
		return false
	if player.waitingGroup.size() > 0:
		_waiting_ready_teams[player.team_id] = false
		return false
	_waiting_ready_teams[player.team_id] = true
	for p in global.players:
		if p.waitingGroup.size() > 0:
			return false
	for p in global.players:
		if not bool(_waiting_ready_teams.get(p.team_id, false)):
			return false
	return request_state_change(global.GameState.COMBOING)

func _update_player_activity() -> void:
	var players_size: int = global.players.size()
	if players_size <= 0:
		return
	if global.current_state == global.GameState.COMBOING:
		if _combo_turn_order.is_empty():
			return
		var safe_index: int = mini(_combo_turn_index, _combo_turn_order.size() - 1)
		var active_team_id_combo: int = _combo_turn_order[safe_index]
		for player in global.players:
			var is_active_combo: bool = player.team_id == active_team_id_combo
			player.is_active = is_active_combo
			if is_active_combo:
				global.player_activity = player
		return
	if global.current_state == global.GameState.WAITING:
		for player in global.players:
			player.is_active = true
		global.player_activity = global.players[0]
		return

	if global.current_state == global.GameState.SELECTING:
		var total_picks: int = players_size * 2
		var committed_picks: int = clampi(total_picks - global.selected_group.size(), 0, total_picks - 1)
		var snake_index: int = committed_picks
		if committed_picks >= players_size:
			snake_index = total_picks - 1 - committed_picks
		var start_index: int = posmod(global.game_progress - 1, players_size)
		var active_index: int = posmod(start_index + snake_index, players_size)
		var active_player_selecting: PlayerEntity = global.players[active_index]
		for player in global.players:
			var is_active_selecting: bool = player == active_player_selecting
			player.is_active = is_active_selecting
			if is_active_selecting:
				global.player_activity = player
		return

	var active_team_id: int = posmod(global.round, players_size) + 1
	for player in global.players:
		var is_active: bool = player.team_id == active_team_id
		player.is_active = is_active
		if is_active:
			global.player_activity = player

func _build_combo_turn_order() -> void:
	_combo_turn_order.clear()
	var players_size: int = global.players.size()
	if players_size <= 0:
		return
	var start_index: int = posmod(global.game_progress - 1, players_size)
	for i in range(players_size):
		var player: PlayerEntity = global.players[(start_index + i) % players_size]
		_combo_turn_order.push_back(player.team_id)
