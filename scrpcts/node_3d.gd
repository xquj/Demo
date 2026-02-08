extends Node3D

# ==================== 性能优化缓存 =========================
var tick : int = 0;
var _cached_cards_node: Node = null  # 缓存的cards节点
var _cached_players_size: int = 0    # 缓存的玩家数量
const HAND_CARDS_MAX: int = 14       # 手牌上限常量
const DEAL_INTERVAL: int = 30        # 发牌间隔常量
var rot_animation:AnimationUtils = AnimationUtils.new(0,0,100)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rot_animation.play(true)
	global.current_play_turn = 0
	global.round = 0
	global.game_progress = 1
	global.Deck = $Scene3D/Desk/deck
	global.WAIT_Area1_Label = $Scene3D/Desk/WaitArea1
	global.WAIT_Area2_Label = $Scene3D/Desk/WaitArea2
	global.camera = $LPlayer/SpringArm3D/Camera3D
	global.RoundEnd_Panel = $CanvasLayer/RoundEnd_Panel
	global.discardPile = $Scene3D/Desk/discardPile
	global.Tame_Panel = $CanvasLayer/Tame_Panel
	global.Combo_Panel = $CanvasLayer/Combo_Panel
	global.Card_Info_Panel = $CanvasLayer/CardInfoPanel
	global.Cards_Number_Label = $Scene3D/Desk/HeldArea1/CardsNumber
	global.Showing_Area_Label = $Scene3D/Desk/ShowArea
	global.HELD_Area1_Label = $Scene3D/Desk/HeldArea1
	global.HELD_Area2_Label = $Scene3D/Desk/HeldArea2
	global.Cube_Desk = $Scene3D/Desk
	pass

# ===================== 辅助函数：优化重复计算 =====================
# 更新玩家活跃状态（优化：提取重复逻辑）
func _update_player_activity() -> void:
	var players_size = global.players.size()  # 缓存数组大小
	var threshold = players_size + global.game_progress - 1
	
	for player in global.players:
		var is_active: bool
		if global.round < threshold:
			is_active = (player.team_id == ((global.round) % 2 + 1))
		else:
			is_active = (player.team_id == (players_size - ((global.round) % 2)))
		
		player.is_active = is_active
		if is_active:
			global.player_activity = player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rot_animation.update(delta)
	# 优化：缓存节点引用
	if _cached_cards_node == null:
		_cached_cards_node = $cards
	
	# 优化：使用常量并缓存手牌数量
	var hand_size = global.local_player.hand_cards.size()
	global.Cards_Number_Label.text = "(" + str(hand_size) + "/" + str(HAND_CARDS_MAX) + ")"
	match global.current_state:
		global.GameState.DEALING:
			if global.spring_length_animation.done && global.spring_length_animation.end_value == 3:
				global.spring_length_animation.set_target(1,200)
				global.spring_length_animation.play(true)
				
			for player in global.players:
				player.can_combo = true
			global.round = global.game_progress - 1;
			global.Tame_Panel.visible = false
			if global.selectGroup.size() >= global.players.size() * 2:
				if !global.selectGroup.back().move_ability:
					global.current_state = global.GameState.SELECTING
			else:
				if tick % DEAL_INTERVAL == 0:
					# 优化：使用缓存的节点引用
					var cards_count = _cached_cards_node.get_child_count()
					if cards_count > 0:
						var source_sprite: Sprite3D = _cached_cards_node.get_child((tick / DEAL_INTERVAL) % cards_count).duplicate()
						source_sprite.visible = true
						initialize_card(source_sprite)
				
		global.GameState.SELECTING:
			global.Tame_Panel.visible = false
			if global.selectGroup.size() == 0:
				global.current_state = global.GameState.WAITING
			# 优化：使用辅助函数更新玩家活跃状态
			_update_player_activity()
			for player in global.players:
				player.process()
		global.GameState.WAITING:
			if rot_animation.done && rot_animation.end_value == 90:
				global.current_state = global.GameState.COMBOING
			global.round = global.game_progress - 1;
			# 优化：简化条件判断
			global.Tame_Panel.visible = (global.selectedCard != null)
			# 优化：使用更高效的方式计算总大小
			var total_waiting_size: int = 0;
			for player in global.players:
				total_waiting_size += player.waitingGroup.size()
				if !player.can_combo:
					total_waiting_size = -9999
			if total_waiting_size == 0 && rot_animation.end_value != 90:
				global.spring_length_animation.set_target(3,200)
				global.spring_length_animation.play(true)
				global.spring_rotX_animation.set_target(0,200)
				global.spring_rotX_animation.play(true)
				rot_animation.set_target(90,500)
				rot_animation.play(true)
			global.Cube_Desk.rotation.z = deg_to_rad(rot_animation.value)
		global.GameState.COMBOING:
			if global.spring_length_animation.done && global.spring_length_animation.end_value == 3:
				global.spring_length_animation.set_target(1,200)
				global.spring_length_animation.play(true)
				
				
			if global.round > global.game_progress:
				global.current_state = global.GameState.END
				global.round = 0;
				return
			# 优化：使用辅助函数更新玩家活跃状态
			_update_player_activity()
			for player in global.players:
				player.process()
			global.Combo_Panel.visible = true
		global.GameState.END:
			global.RoundEnd_Panel.visible = true
			if global.round > global.players.size() - 1:
				if rot_animation.end_value != 0:
					global.spring_length_animation.set_target(3,200)
					global.spring_length_animation.play(true)
					rot_animation.set_target(0,500)
					rot_animation.play(true)
			else:
				global.player_activity = global.players.get(global.round)
			global.Cube_Desk.rotation.z = deg_to_rad(rot_animation.value)
			if rot_animation.done && rot_animation.end_value == 0:
				global.spring_rotX_animation.set_target(45,200)
				global.spring_rotX_animation.play(true)
				global.RoundEnd_Panel.visible = false
				global.player_activity = null
				global.game_progress += 1
				global.current_state = global.GameState.DEALING
				global.Cube_Desk.rotation.z = 0
	tick+=1
	pass
	
func initialize_card(sprite: Sprite3D) -> void:
	# 优化：缓存路径替换结果
	var script_path = sprite.texture.resource_path.replace("res://textrue/cards/", "res://scrpcts/status/").replace(".png", ".gd")
	sprite.set_script(load(script_path))
	global.selectGroup.push_back(sprite)
	var last_card = global.selectGroup.back()
	if last_card.get_parent() == null:
		global.Cube_Desk.add_child(last_card)



func _on_sell_button_up() -> void:
	if global.current_state == global.GameState.WAITING:
		if global.selectedCard != null:
			# 优化：缓存玩家对象，避免重复数组访问
			var card = global.selectedCard
			var player = global.players[card.team_id - 1]
			player.inventory_temporary.add_items(card.selling_price)
			
			card.switch_state(card.States.DISCARD)
			global.selectedCard = null
			
			
func _on_tame_button_up() -> void:
	if global.current_state == global.GameState.WAITING:
		if global.selectedCard != null:
			# 优化：缓存玩家对象，避免重复数组访问
			var card = global.selectedCard
			var player = global.players[card.team_id - 1]
			if player.hand_cards.size() < HAND_CARDS_MAX:
				card.switch_state(card.States.TO_HELD)
				global.selectedCard = null
				

func _on_round_end_button_up() -> void:
	if global.GameState.END:
		global.round += 1;
