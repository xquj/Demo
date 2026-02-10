extends Node3D

# ====================【缓存与常量】====================
var tick : int = 0;
var _cached_cards_node: Node = null  # 缓存 Cards 节点引用
var _cached_players_size: int = 0    # 缓存玩家数量
const HAND_CARDS_MAX: int = 14       # 手牌上限
const DEAL_INTERVAL: int = 30        # 发牌间隔（帧）
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.cube_rot_animation.play(true)
	global.current_play_turn = 0
	global.round = 0
	global.game_progress = 1
	global.deck = $Scene3D/Desk/Deck
	global.multi_player_node = $MultiPlayer
	global.wait_area1_label = $Scene3D/Desk/WaitArea1
	global.wait_area2_label = $Scene3D/Desk/WaitArea2
	global.camera = $LocalPlayer/SpringArm3D/Camera3D
	global.discard_pile = $Scene3D/Desk/DiscardPile
	global.cards_number_label = $Scene3D/Desk/HeldArea1/CardsNumber
	global.showing_area_label = $Scene3D/Desk/ShowArea
	global.held_area1_label = $Scene3D/Desk/HeldArea1
	global.held_area2_label = $Scene3D/Desk/HeldArea2
	global.cube_desk = $Scene3D/Desk
	pass

# ====================【辅助函数】====================
# 更新玩家活跃状态：提取重复逻辑，减少状态分支重复代码。
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
	global.cube_rot_animation.update(delta)
	# 缓存节点引用，避免每帧重复查找。
	if _cached_cards_node == null:
		_cached_cards_node = $Cards
	
	# 使用常量并缓存手牌数量，避免重复读取。
	var hand_size = global.local_player.hand_cards.size()
	global.cards_number_label.text = "(" + str(hand_size) + "/" + str(HAND_CARDS_MAX) + ")"
	match global.current_state:
		global.GameState.DEALING:
			if global.spring_length_animation.done && global.spring_length_animation.end_value == 3:
				global.spring_length_animation.set_target(1,200)
				global.spring_length_animation.play(true)
				
			for player in global.players:
				player.can_combo = true
			global.round = global.game_progress - 1;
			if global.selected_group.size() >= global.players.size() * 2:
				if !global.selected_group.back().moving_ability:
					global.current_state = global.GameState.SELECTING
			else:
				if tick % DEAL_INTERVAL == 0:
					# 使用缓存节点发牌，减少树遍历开销。
					var cards_count = _cached_cards_node.get_child_count()
					if cards_count > 0:
						var source_sprite: Sprite3D = _cached_cards_node.get_child((tick / DEAL_INTERVAL) % cards_count).duplicate()
						source_sprite.visible = true
						initialize_card(source_sprite)
		global.GameState.SELECTING:
			if global.selected_group.size() == 0:
				global.current_state = global.GameState.WAITING
			# 复用辅助函数更新玩家活跃状态。
			_update_player_activity()
			for player in global.players:
				player.process()
		global.GameState.WAITING:
			if global.cube_rot_animation.done && global.cube_rot_animation.end_value == 90:
				global.current_state = global.GameState.COMBOING
				global.spring_rot_x_animation.set_target(45,200)
				global.spring_rot_x_animation.play(true)
			global.round = global.game_progress - 1;
			global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)
		global.GameState.COMBOING:
			if global.spring_length_animation.done && global.spring_length_animation.end_value == 3:
				global.spring_length_animation.set_target(1,200)
				global.spring_length_animation.play(true)
				
				
			if global.round > global.game_progress:
				global.current_state = global.GameState.END
				global.round = 0;
				return
			# 复用辅助函数更新玩家活跃状态。
			_update_player_activity()
			for player in global.players:
				player.process()
		global.GameState.END:
			global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)
			if global.cube_rot_animation.end_value != 0:
				global.spring_length_animation.set_target(3,200)
				global.spring_length_animation.play(true)
				global.cube_rot_animation.set_target(0,500)
				global.cube_rot_animation.play(true)
			
			if global.cube_rot_animation.done && global.cube_rot_animation.end_value == 0:
				global.player_activity = null
				global.game_progress += 1
				global.current_state = global.GameState.DEALING
				global.cube_desk.global_rotation.z = 0
	tick+=1

		
func initialize_card(sprite: Sprite3D) -> void:
	# 为新卡牌挂载脚本并纳入选牌组。
	sprite.set_script(load("res://scripts/card/card_base.gd"))
	global.selected_group.push_back(sprite)
	var last_card = global.selected_group.back()
	if last_card.get_parent() == null:
		global.cube_desk.add_child(last_card)



func _on_sell_button_up() -> void:
	if global.current_state == global.GameState.WAITING:
		if global.selected_card != null:
			# 缓存玩家对象，避免重复数组访问。
			var card = global.selected_card
			var player = global.players[card.team_id - 1]
			player.inventory_temporary.add_items(card.selling_price)
			
			card.switch_state(card.States.DISCARD)
			global.selected_card = null
			
			
func _on_tame_button_up() -> void:
	if global.current_state == global.GameState.WAITING:
		if global.selected_card != null:
			# 缓存玩家对象，避免重复数组访问。
			var card = global.selected_card
			var player = global.players[card.team_id - 1]
			if player.hand_cards.size() < HAND_CARDS_MAX:
				card.switch_state(card.States.TO_HELD)
				global.selected_card = null
				
func _hover(m_x:float,m_y:float,x:float,y:float,x1:float,y1:float) -> bool:
	return m_x >= x and m_x <= x1 and m_y >= y and m_y <= y1
