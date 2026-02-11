extends Node3D
class_name GameSense3D
# ====================【常量与缓存】====================
# 手牌上限（用于“驯服”动作时的容量判断，以及 UI 显示）。
const HAND_CARDS_MAX: int = 14
# 发牌节奏（按帧间隔控制，每 DEAL_INTERVAL 帧尝试发一张）。
const DEAL_INTERVAL: int = 30

# 全局帧计数器：用于发牌索引轮转与节奏控制。
var tick: int = 0
# 新卡牌工厂：基于卡牌模板场景 + JSON 数据生成卡牌。
var _card_factory: CardFactory = CardFactory.new()

# 场景入口：绑定全局节点引用并重置本局状态。
func _ready() -> void:
	global.game_sense = self
	_setup_global_references()
	_reset_match_state()


# 每帧主循环：更新相机/动画、刷新 UI、驱动状态机。
func _process(delta: float) -> void:
	_update_camera_and_animations(delta)
	_update_hand_count_label()
	_process_game_formal_state()
	_process_game_transitional_state()
	tick += 1


# 输入转发给相机控制器。
func _input(event: InputEvent) -> void:
	global.camera_controller._input_event(event)


# 卖出按钮：仅在 WAITING 状态且有选中卡牌时生效。
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


# 驯服按钮：仅在 WAITING 状态、有选中卡牌且手牌未满时生效。
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


# 通用矩形命中检测（当前脚本内保留给 UI/交互逻辑复用）。
func _hover(m_x: float, m_y: float, x: float, y: float, x1: float, y1: float) -> bool:
	return m_x >= x and m_x <= x1 and m_y >= y and m_y <= y1


# 初始化新卡牌：纳入 selected_group，并放入桌面节点。
func initialize_card(card: Card_Base) -> void:
	global.selected_group.push_back(card)
	var last_card: Card_Base = global.selected_group.back()
	if last_card.get_parent() == null:
		global.cube_desk.add_child(last_card)


# 绑定运行期依赖到 global，集中管理场景节点引用。
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



# 重置对局进度与旋转动画初始状态。
func _reset_match_state() -> void:
	global.current_play_turn = 0
	global.round = 0
	global.game_progress = 1
	global.cube_rot_animation.play(true)


# 更新镜头控制器与桌面旋转动画。
func _update_camera_and_animations(delta: float) -> void:
	global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)
	global.camera_controller._update(delta)
	global.cube_rot_animation.update(delta)


# 刷新手牌计数标签（格式：当前/上限）。
func _update_hand_count_label() -> void:
	var hand_size: int = global.local_player.hand_cards.size()
	global.cards_number_label.text = "(%s/%s)" % [str(hand_size), str(HAND_CARDS_MAX)]

func _switch_state(state: global.GameState) -> void:
	if state == global.current_state: return
	match state:
		global.GameState.DEALING:
			_init_dealing_state()
		global.GameState.SELECTING:
			_init_selecting_state()
		global.GameState.WAITING:
			_init_waiting_state()
		global.GameState.COMBOING:
			_init_comboing_state()

#进入状态接口
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
	
func _init_comboing_state() -> void:
	global.current_state = global.GameState.TO_COMBOING
	global.cube_rot_animation.set_target(90,500)
	global.cube_rot_animation.play(true)
	global.camera_controller.switch_state(global.camera_controller.STATE.Up, 250)
	


# 统一状态分发入口，避免在 _process 中堆叠分支。(正式态)
func _process_game_formal_state() -> void:
	match global.current_state:
		global.GameState.DEALING:
			_handle_dealing_state()
		global.GameState.SELECTING:
			_handle_selecting_state()
		global.GameState.WAITING:
			_handle_waiting_state()
		global.GameState.COMBOING:
			_handle_comboing_state()
			
# 发牌阶段：恢复普通镜头、设置可连招、按节奏发牌，发牌完成后进入 SELECTING。
func _handle_dealing_state() -> void:
	for player in global.players:
		player.can_combo = true

	global.round = global.game_progress - 1
	if _finished_dealing():
		if not global.selected_group.back().moving_ability:
			_switch_state(global.GameState.SELECTING)
		return

	if tick % DEAL_INTERVAL == 0:
		_spawn_next_card()


# 选牌阶段：若无待选卡进入 WAITING，并推动玩家逻辑。
func _handle_selecting_state() -> void:
	if global.selected_group.size() == 0:
		_switch_state(global.GameState.WAITING)

	_update_player_activity()
	for player in global.players:
		player.process()


# 等待阶段：等待桌面旋转到目标角度后进入 COMBOING。
func _handle_waiting_state() -> void:
		
	global.round = global.game_progress - 1


# 连招阶段：回合超限则进入 END，否则持续推动活跃玩家处理。
func _handle_comboing_state() -> void:
	if global.round > global.game_progress:
		_switch_state(global.GameState.DEALING)
		global.round = 0
		return

	_update_player_activity()
	for player in global.players:
		player.process()


# 统一状态分发入口，避免在 _process 中堆叠分支。(过渡态)
func _process_game_transitional_state() -> void:
	match global.current_state:
		global.GameState.TO_DEALING:
			_handle_to_dealing_state()
		global.GameState.TO_SELECTING:
			_handle_to_selecting_state()
		global.GameState.TO_WAITING:
			_handle_to_waiting_state()
		global.GameState.TO_COMBOING:
			_handle_to_comboing_state()
			
# 到发牌阶段的过渡态
func _handle_to_dealing_state() -> void:
	if !global.camera_controller.is_moving:
		if global.camera_controller.is_state(global.camera_controller.STATE.Up):
			global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
		else:
			global.current_state = global.GameState.DEALING


# 到选牌阶段的过渡态
func _handle_to_selecting_state() -> void:
	global.current_state = global.GameState.SELECTING


# 到等待阶段的过渡态
func _handle_to_waiting_state() -> void:
	global.current_state = global.GameState.WAITING


# 到连招阶段的过渡态
func _handle_to_comboing_state() -> void:
	if !global.camera_controller.is_moving:
		if global.camera_controller.is_state(global.camera_controller.STATE.Up):
			global.camera_controller.switch_state(global.camera_controller.STATE.Normal, 250)
		else:
			global.current_state = global.GameState.COMBOING
		
	
# 判断当前轮次发牌是否达到“玩家数 * 2”的目标数量。
func _finished_dealing() -> bool:
	return global.selected_group.size() >= global.players.size() * 2


# 生成下一张卡：按 tick 节奏从 CardFactory 动态实例化。
func _spawn_next_card() -> void:
	var cards_count: int = _card_factory.get_cards_count()
	if cards_count == 0:
		return

	var card_index: int = (tick / DEAL_INTERVAL) % cards_count
	var card: Card_Base = _card_factory.create_card_by_index(card_index)
	if card == null:
		return
	initialize_card(card)


# 根据 round 与 game_progress 计算活跃玩家，并同步到 global.player_activity。
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
