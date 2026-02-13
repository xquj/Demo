extends SceneTree

const MAIN_SCENE_PATH: String = "res://scenes/node_3d.tscn"
const MAX_FRAMES: int = 900
const STEP_TIMEOUT_FRAMES: int = 240

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_bootstrap_match()
	var packed: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Simulation: failed to load scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return
	var scene: Node = packed.instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var game_scene: GameScene3D = scene as GameScene3D
	if game_scene == null:
		push_error("Simulation: scene root is not GameScene3D")
		quit(5)
		return

	var flow_error: String = await _run_forced_card_flow(game_scene)
	if not flow_error.is_empty():
		push_error("Simulation forced flow failed: %s" % flow_error)
		quit(6)
		return

	var seen_states: Dictionary = {}
	for i in range(MAX_FRAMES):
		await process_frame
		seen_states[global.current_state] = true
		var invariant_error: String = _validate_invariants()
		if not invariant_error.is_empty():
			push_error("Simulation invariant failed at frame %s: %s" % [str(i), invariant_error])
			quit(2)
			return

	if not seen_states.has(global.GameState.SELECTING):
		push_error("Simulation: never reached SELECTING state.")
		quit(3)
		return
	if not seen_states.has(global.GameState.WAITING):
		push_error("Simulation: never reached WAITING state.")
		quit(4)
		return

	print("Simulation: PASS, seen states=%s" % [str(seen_states.keys())])
	quit(0)

func _run_forced_card_flow(game_scene: GameScene3D) -> String:
	var factory: CardFactory = CardFactory.new()
	var card: Card_Base = factory.create_card_by_index(0)
	if card == null:
		return "failed to create card from CardFactory"
	game_scene.initialize_card(card)
	await process_frame
	await process_frame

	if global.selected_group.has(card):
		global.selected_group.remove_at(global.selected_group.find(card))
	card.team_id = global.local_player.team_id
	card.player = global.local_player
	if not global.local_player.waitingGroup.has(card):
		global.local_player.waitingGroup.push_back(card)
	card.start_pos = card.global_position
	card.switch_state(Card_Base.States.WAITING)
	await process_frame

	if not (card.state is WaitingState):
		return "card failed to enter WaitingState"

	card.switch_state(Card_Base.States.TO_HELD)
	if not await _wait_until(func() -> bool: return card.state is HeldState, STEP_TIMEOUT_FRAMES):
		return "TO_HELD did not reach HeldState in time"
	if not global.local_player.hand_cards.has(card):
		return "HeldState reached but card missing in local hand_cards"
	if global.local_player.waitingGroup.has(card):
		return "HeldState reached but card still in waitingGroup"

	card.switch_state(Card_Base.States.TO_WAIT)
	if not await _wait_until(func() -> bool: return card.state is WaitingState, STEP_TIMEOUT_FRAMES):
		return "TO_WAIT did not reach WaitingState in time"
	if not global.local_player.waitingGroup.has(card):
		return "WaitingState reached but card missing in waitingGroup"
	if global.local_player.hand_cards.has(card):
		return "WaitingState reached but card still in hand_cards"

	card.switch_state(Card_Base.States.DISCARD)
	if not await _wait_until(func() -> bool: return not card.moving_ability, STEP_TIMEOUT_FRAMES):
		return "Discard motion did not finish in time"
	if not global.discard_group.has(card):
		return "card missing in discard_group after discard"
	if card.player != null or card.team_id != -1:
		return "card ownership not cleared after discard"
	return ""

func _wait_until(predicate: Callable, timeout_frames: int) -> bool:
	for _i in range(timeout_frames):
		await process_frame
		if bool(predicate.call()):
			return true
	return false

func _bootstrap_match() -> void:
	global.reset_runtime_state()
	global.players = [
		LocalPlayer.new("Me", 1, false),
		MultiPlayer.new("Enemy", 2, false)
	]
	global.local_player = global.players[0]
	global.current_state = global.GameState.DEALING
	global.diagnostics_enabled = false

func _validate_invariants() -> String:
	for player in global.players:
		if player == null:
			return "player is null"
		var hand_set: Dictionary = {}
		for card in player.hand_cards:
			if card == null:
				return "null card in hand_cards"
			var key: int = card.get_instance_id()
			if hand_set.has(key):
				return "duplicate card in hand_cards: %s" % str(player.team_id)
			hand_set[key] = true
			if card.get_parent() == null:
				return "hand card parent is null"
		for card in player.waitingGroup:
			if card == null:
				return "null card in waitingGroup"
			if hand_set.has(card.get_instance_id()):
				return "card exists in both waitingGroup and hand_cards"
			if card.get_parent() == null:
				return "waiting card parent is null"
	return ""
