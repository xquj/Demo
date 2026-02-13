class_name SimpleAiController extends PlayerController

enum Mode {
	BALANCED,
	AGGRESSIVE,
	GREEDY
}

const MAX_HAND_CARDS: int = 14

var mode: int = Mode.BALANCED
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _tick: int = 0
var _last_select_tick: int = -9999
var _last_waiting_tick: int = -9999
var _last_combo_tick: int = -9999

func _init(mode_: int = Mode.BALANCED) -> void:
	mode = mode_
	_rng.randomize()

func process(player: PlayerEntity) -> void:
	if player == null:
		return
	if player == global.local_player:
		return
	_tick += 1
	if global.is_transitional_state():
		return
	if not player.is_active:
		return

	match global.current_state:
		global.GameState.SELECTING:
			_process_selecting(player)
		global.GameState.WAITING:
			_process_waiting(player)
		global.GameState.COMBOING:
			_process_comboing(player)

func _process_selecting(_player: PlayerEntity) -> void:
	var think_interval: int = _get_select_think_interval()
	if _tick - _last_select_tick < think_interval:
		return
	var target: Card_Base = _pick_selecting_card()
	if target == null:
		return
	if target.moving_ability:
		return
	if not (target.state is SelectingState):
		return
	target.switch_state(Card_Base.States.TO_WAIT)
	_last_select_tick = _tick

func _process_waiting(player: PlayerEntity) -> void:
	var think_interval: int = _get_waiting_think_interval(player)
	if _tick - _last_waiting_tick < think_interval:
		return

	if player.waitingGroup.size() > 0:
		if player.hand_cards.size() >= MAX_HAND_CARDS:
			_last_waiting_tick = _tick
			return
		var target: Card_Base = _pick_waiting_card(player)
		if target != null and not target.moving_ability and target.state is WaitingState:
			target.switch_state(Card_Base.States.TO_HELD)
			_last_waiting_tick = _tick
		return

	if global.game_sense != null:
		global.game_sense.request_waiting_ready(player)
		_last_waiting_tick = _tick

func _process_comboing(player: PlayerEntity) -> void:
	var think_interval: int = _get_combo_think_interval(player)
	if _tick - _last_combo_tick < think_interval:
		return
	if global.game_sense != null:
		global.game_sense.request_advance_combo_round(player)
		_last_combo_tick = _tick

func _pick_selecting_card() -> Card_Base:
	var candidates: Array[Card_Base] = []
	for card in global.selected_group:
		if card == null:
			continue
		if not (card.state is SelectingState):
			continue
		candidates.push_back(card)
	if candidates.is_empty():
		return null
	return _pick_weighted_best(candidates, true)

func _pick_waiting_card(player: PlayerEntity) -> Card_Base:
	var candidates: Array[Card_Base] = []
	for card in player.waitingGroup:
		if card == null:
			continue
		if not (card.state is WaitingState):
			continue
		candidates.push_back(card)
	if candidates.is_empty():
		return null
	return _pick_weighted_best(candidates, false)

func _pick_weighted_best(candidates: Array[Card_Base], selecting_phase: bool) -> Card_Base:
	var scored: Array[Dictionary] = []
	for card in candidates:
		var score: float = _score_card(card, selecting_phase)
		scored.push_back({"card": card, "score": score})

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)

	var sample_size: int = mini(3, scored.size())
	var pick_index: int = 0
	var roll: float = _rng.randf()
	if sample_size > 1:
		if roll > 0.82:
			pick_index = mini(2, sample_size - 1)
		elif roll > 0.45:
			pick_index = 1

	return scored[pick_index]["card"] as Card_Base

func _score_card(card: Card_Base, selecting_phase: bool) -> float:
	var hp_weight: float
	var cost_weight: float
	var sell_weight: float
	match mode:
		Mode.AGGRESSIVE:
			hp_weight = 3.0
			cost_weight = 1.1
			sell_weight = 0.4
		Mode.GREEDY:
			hp_weight = 1.4
			cost_weight = 0.8
			sell_weight = 3.2
		_:
			hp_weight = 2.2
			cost_weight = 1.0
			sell_weight = 1.5

	var score: float = float(card.health) * hp_weight + float(card.cost) * cost_weight + float(card.selling_price) * sell_weight
	if selecting_phase and card.cost <= 1:
		score += 0.5
	if card.keywords.has("boss"):
		score += 0.8
	if card.keywords.has("starter"):
		score += 0.4
	score += _rng.randf_range(-0.25, 0.25)
	return score

func _get_select_think_interval() -> int:
	match mode:
		Mode.AGGRESSIVE:
			return 8
		Mode.GREEDY:
			return 16
		_:
			return 12

func _get_waiting_think_interval(player: PlayerEntity) -> int:
	var base: int
	match mode:
		Mode.AGGRESSIVE:
			base = 10
		Mode.GREEDY:
			base = 18
		_:
			base = 14
	if player.waitingGroup.size() > 1 and player.hand_cards.size() < MAX_HAND_CARDS - 2:
		base = maxi(6, base - 3)
	return base

func _get_combo_think_interval(player: PlayerEntity) -> int:
	var base: int
	match mode:
		Mode.AGGRESSIVE:
			base = 14
		Mode.GREEDY:
			base = 24
		_:
			base = 18
	if player.can_combo:
		base = maxi(10, base - 2)
	return base
