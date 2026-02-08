extends Sprite3D
class_name Card_Base 

# ===================== 全局通用配置 =====================
# 卡牌所属队伍ID，-1表示未分配队伍
@export var team_id: int = -1;
# 卡牌的碰撞检测区域，用于鼠标交互
@export var area: Area3D
# 卡牌的原始颜色，用于恢复颜色动画
@export var original_modulate: Color
# 鼠标是否进入卡牌区域
var is_entered: bool = false
# 鼠标是否点击了卡牌
var is_clicked: bool = false
# 卡牌是否可以移动（用于控制动画播放）
var move_ability: bool = true
#===================== 卡牌基本属性 ===========================
# 卡牌售卖回报
var selling_price: Array[ItemDate] = []
# 卡牌家族名称
var family_name: String
# 卡牌家族图片
var family_texture: Texture2D
# 卡牌技能类型
enum Type {
	Immediately,   # 即时(一次性)
	Permanent,     # 永久(随时生效)
	Initiative     # 主动(回合末生效)
}
var skill_type: Type = Type.Immediately
# 卡牌名称
var card_name: String
# 卡牌召唤所需费用
var cost: int = 0
# 卡牌技能介绍
var skill: String
# ==================== 运动状态 =======================
# 3D运动基础记录
# 卡牌移动的起始世界坐标位置
var start_pos: Vector3 = Vector3.ZERO
# 卡牌移动的目标世界坐标位置
var target_pos: Vector3 = Vector3.ZERO
# 卡牌旋转的起始角度（欧拉角）
var start_rotation: Vector3 = Vector3.ZERO
# 当前动画已消耗的时间（秒）

var elapsed_time: float = 0.0
# 移动动画的总时长（秒）
var move_duration: float = 1.0
# 抛物线运动的最大高度（用于XYZ轴抛物线效果）
var peak_height: Vector3 = Vector3(0,0.5,0)
# X轴目标旋转角度（度）
var target_x_rotate: float = 0.0
# Y轴目标旋转角度（度）
var target_y_rotate: float = 0.0
# Z轴目标旋转角度（度）
var target_z_rotate: float = 0.0
# ==================== 动画效果 =========================
# 颜色动画工具类实例，用于处理卡牌颜色的渐变效果
var colorAnimation: ColorAnimationUtils
# ==================== 性能优化缓存 =========================
var _cached_player: PlayerEntity = null  # 缓存的玩家对象
var _cached_player_team_id: int = -1     # 缓存的玩家team_id
const PARABOLA_MULTIPLIER: float = 4.0   # 抛物线计算常量
# ==================== 常量定义 =========================
const SELECTED_COLOR: Color = Color(0.627, 0.627, 0.627, 1.0)  # 选中时的颜色
const COLOR_ANIM_DURATION: int = 100  # 颜色动画时长
const Y_OFFSET_SELECTED: float = 0.02  # 选中时Y轴偏移

# TODO: 提取更多魔法数字为常量（如0.3, 0.2, 0.5, 0.1等位置偏移值）
# ====================== 卡牌状态机制 =========================
enum States {
	DEALING,   # 发牌状态
	SELECTING, # 选牌状态
	WAITING,   # 等待状态
	DISCARD,   # 丢弃状态
	TO_HELD,   # 手持状态(过渡)
	HELD,	   # 手持状态
	TO_SHOWING,# 手持状态(过度)
	SHOWING,   # 展示状态(一般)
	TO_ACTIVATE# 可激活状态(点击卡牌 -> 激活效果 -> 回到展示/丢弃状态)
}
var state: States = States.DEALING #卡牌状态
# 上一次使用的回合
var pre_round: int = -999

# 节点初始化函数，在场景加载时自动调用
func _ready() -> void:
	# 自动查找子节点Area3D（如果未在编辑器中指定）
	if area == null:
		for child in get_children():
			if child is Area3D:
				area = child
	# 绑定鼠标进入/离开事件到Area3D，用于检测鼠标悬停
	area.mouse_entered.connect(func(): mouse_entered(true))
	area.mouse_exited.connect(func(): mouse_entered(false))
	# 初始化颜色动画工具，起始和目标颜色都是当前颜色（保持原色）
	colorAnimation = ColorAnimationUtils.new(modulate, modulate, COLOR_ANIM_DURATION)
	colorAnimation.play(true)
	# 保存原始颜色，用于后续恢复
	original_modulate = modulate
	# 初始隐藏碰撞区，发牌完成后显示（避免发牌过程中误触）
	area.visible = false
	# 初始化卡牌状态
	init()
	
# ===================== 核心帧更新（合并两套3D运动逻辑） =====================
# 每帧更新函数，处理卡牌的动画和状态逻辑
# delta: 上一帧到当前帧的时间间隔（秒）
func _process(delta: float) -> void:
	# 如果卡牌不可见，直接返回，不进行任何处理
	if not visible:
		return
	# 更新颜色动画，根据时间插值计算当前颜色
	colorAnimation.update(delta)
	# 应用计算出的颜色到卡牌材质
	modulate = colorAnimation.value
	
	# 处理颜色高亮（根据选中状态和鼠标悬停状态更新颜色）
	_update_color_highlight()
	
	# 根据卡牌当前状态执行相应的逻辑
	match state:
		States.DEALING:
			# 发牌状态：卡牌从卡池飞向选择区域
			if move_ability:
				# 计算当前动画进度（0.0到1.0）
				var progress = _update_movement_progress(delta)
				# 应用3D移动和旋转动画
				_apply_3d_movement(progress)
				var target_rot = _apply_3d_rotation(progress)
				# 动画完成后切换到选牌状态
				if progress >= 1.0:
					_finalize_movement(target_rot)
					switch_state(States.SELECTING)
		States.SELECTING:
			# 选牌状态：卡牌从选择区域移动到玩家等待区域
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 获取卡牌所属的玩家对象（使用缓存优化）
				var player = _get_cached_player()
				if player != null:
					# 根据卡牌在等待组中的索引计算目标X坐标
					if player.team_id == global.local_player.team_id:
						target_pos = global.WAIT_Area1_Label.position
					else:
						target_pos = global.WAIT_Area2_Label.position
					var idx = player.waitingGroup.find(self)
					target_pos.x += 0.5 + idx * 0.3
					# 应用3D移动和旋转动画
					_apply_3d_movement(progress)
					var target_rot = _apply_3d_rotation(progress)
					# 动画完成后切换到等待状态
					if progress >= 1.0:
						_finalize_movement(target_rot)
						switch_state(States.WAITING)
		States.WAITING:
			# 等待状态：卡牌在等待区域，可以被选中、捕猎或售卖
			# 如果被选中，会有Y轴上下浮动的动画效果
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 只更新Y轴位置（上下浮动效果），不更新X和Z轴
				_apply_3d_movement(progress, false, false, true)
				# 动画完成后交换起始和目标位置，实现来回浮动
				if progress >= 1.0:
					_finalize_y_movement()
		States.DISCARD:
			# 丢弃状态：卡牌被售卖后飞向弃牌堆
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 应用3D移动和旋转动画（飞向弃牌堆）
				_apply_3d_movement(progress)
				var target_rot = _apply_3d_rotation(progress)
				# 动画完成后停止移动
				if progress >= 1.0:
					_finalize_movement(target_rot)
					move_ability = false
					var player = _get_cached_player()
					player.can_combo = true
					team_id = -1
		States.TO_HELD:
			# 到手牌状态（过渡）：卡牌从等待区域移动到玩家手牌区域
			if move_ability:
				var progress = _update_movement_progress(delta)
				var player = _get_cached_player()
				if player != null:
					# 应用3D移动和旋转动画
					_apply_3d_movement(progress)
					var target_rot = _apply_3d_rotation(progress)
					# 动画完成后切换到手持状态
					if progress >= 1.0:
						_finalize_movement(target_rot)
						switch_state(States.HELD)
		States.HELD:
			# 手持状态：卡牌在玩家手牌区域，可以被选中用于连招
			# 如果被选中，会有Y轴上下浮动的动画效果
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 只更新X轴位置（上下浮动效果），不更新Y和Z轴
				_apply_3d_movement(progress, true, false, false)
				# 动画完成后交换起始和目标位置，实现来回浮动
				if progress >= 1.0:
					_finalize_y_movement()
		States.TO_SHOWING:
			# 到展示牌状态（过渡）：卡牌从手牌区域移动到玩家展示区域
			if move_ability:
				var progress = _update_movement_progress(delta)
				var player = _get_cached_player()
				if player != null:
					# 应用3D移动和旋转动画
					_apply_3d_movement(progress)
					var target_rot = _apply_3d_rotation(progress)
					# 动画完成后切换到手持状态
					if progress >= 1.0:
						_finalize_movement(target_rot)
						switch_state(States.SHOWING)
		States.SHOWING:
			# 展示状态：卡牌在玩家展示区域，可以被选中用于连招
			# 如果被选中，会有Y轴上下浮动的动画效果
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 只更新X轴位置（上下浮动效果），不更新Y和Z轴
				_apply_3d_movement(progress, true, false, false)
				# 动画完成后交换起始和目标位置，实现来回浮动
				if progress >= 1.0:
					_finalize_y_movement()
			elif can_take_effect():
				switch_state(States.TO_ACTIVATE)
		States.TO_ACTIVATE:
			if move_ability:
				var progress = _update_movement_progress(delta)
				# 只更新X轴位置（上下浮动效果），不更新Y和Z轴
				_apply_3d_movement(progress, true, false, false)
				# 动画完成后交换起始和目标位置，实现来回浮动
				if progress >= 1.0:
					_finalize_y_movement()
			elif !can_take_effect():
				switch_state(States.SHOWING)
	
# ===================== 输入处理（原card_dealing的_input逻辑完全保留） =====================
# 处理全局输入事件（鼠标点击等）
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		# 处理鼠标右键：显示卡牌信息面板
		if event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
			if is_entered:
				global.DetailedCard = self
				global.Card_Info_Panel.visible = true
		# 处理鼠标左键：根据卡牌状态执行不同操作
		if event.is_pressed()  and event.button_index == MOUSE_BUTTON_LEFT:
			is_clicked = true
		if event.is_released() and is_clicked:
			is_clicked = false
			# 根据卡牌当前状态处理点击事件
			match state:
				# 选牌状态：点击后将卡牌添加到玩家等待组
				States.SELECTING:
					if is_entered:
						# 只有在选牌阶段且卡牌未在移动时才能选择
						if global.current_state == global.GameState.SELECTING and global.player_activity != null and !move_ability:
							move_ability = true
							# 设置卡牌所属队伍
							team_id = global.player_activity.team_id
							# 恢复原始颜色
							_set_color_animation(original_modulate)
							
							# 将卡牌添加到活跃玩家的等待组
							global.player_activity.waitingGroup.push_back(self)
							# 从选择组中移除卡牌
							var select_idx = global.selectGroup.find(self)  # 优化：只查找一次
							if select_idx >= 0:
								global.selectGroup.remove_at(select_idx)
							# 增加回合数
							global.round += 1
							# 根据队伍ID设置目标Z坐标和旋转（不同队伍在不同位置）
							# TODO: 提取0.5, 180, -0.5等魔法数字为常量
							if team_id == 1:
								target_pos.z = 0.5
							else:
								target_y_rotate = 180
								target_pos.z = -0.5
				# 等待状态：点击选中卡牌（用于捕猎或售卖）
				States.WAITING:
					if is_entered:
							var pos = target_pos
							pos.y = start_pos.y + Y_OFFSET_SELECTED
							_select_card(pos,Vector3(0.01,0,0))
				# 手持状态：在连招阶段点击选中卡牌（用于组合连招）
				States.HELD:
					if is_entered && global.current_state == global.GameState.COMBOING:
						# 只能选中自己队伍的卡牌
						if global.player_activity.team_id == team_id:
							var pos = target_pos
							pos.x = start_pos.x + Y_OFFSET_SELECTED
							_select_card(pos,Vector3(0.01,0,0))
				# 可激活状态
				States.TO_ACTIVATE:
					if is_entered:
						global.current_play_turn += 1
						pre_round = global.game_progress
						take_effect()
						match skill_type:
							Type.Immediately:
								switch_state(States.DISCARD)
							Type.Permanent:
								switch_state(States.SHOWING)
							Type.Initiative:
								switch_state(States.SHOWING)


# 鼠标进入/离开处理（优化：使用辅助函数）
# 当鼠标进入或离开卡牌区域时调用
# on: true表示鼠标进入，false表示鼠标离开
func mouse_entered(on: bool):
	is_entered = on
	if on:
		# 鼠标进入时显示高亮颜色
		_set_color_animation(SELECTED_COLOR)
	else:
		# 鼠标离开时恢复原始颜色
		_set_color_animation(original_modulate)
		
# 切换状态初始化（优化：提取公共逻辑）
# 根据当前状态调用相应的初始化函数，设置状态相关的参数
func init() -> void:
	match state:
		States.DEALING:
			_init_dealing_state()
		States.SELECTING:
			_init_selecting_state()
		States.WAITING:
			_init_waiting_state()
		States.DISCARD:
			_init_discard_state()
		States.TO_HELD:
			_init_to_held_state()
		States.HELD:
			_init_held_state()
		States.TO_SHOWING:
			_init_to_showing_state()
		States.SHOWING:
			_init_showing_state()
		States.TO_ACTIVATE:
			_init_to_activate_state()
# ===================== 辅助函数：优化重复计算 =====================
# 更新颜色高亮（优化：提取公共逻辑）
# 根据卡牌是否被选中和鼠标是否悬停来更新卡牌颜色
func _update_color_highlight() -> void:
	match state:
		States.WAITING, States.HELD:
			# 如果当前卡牌被选中，显示选中颜色
			if global.selectedCard == self:
				_set_color_animation(SELECTED_COLOR)
			# 如果鼠标未悬停且未被选中，恢复原始颜色
			elif !is_entered:
				_set_color_animation(original_modulate)

# 设置颜色动画（优化：统一颜色动画设置）
# 设置卡牌颜色动画的目标颜色和动画时长
# target_color: 目标颜色值
func _set_color_animation(target_color: Color) -> void:
	colorAnimation.set_target(target_color, COLOR_ANIM_DURATION)
	colorAnimation.play(true)

# 更新运动进度（优化：提取重复的进度计算）
# 更新动画已消耗时间，并返回当前进度（0.0到1.0）
# delta: 上一帧到当前帧的时间间隔（秒）
# 返回: 动画进度值（0.0表示开始，1.0表示完成）
func _update_movement_progress(delta: float) -> float:
	elapsed_time = minf(elapsed_time + delta, move_duration)
	return elapsed_time / move_duration

# 完成Y轴移动（优化：提取重复的Y轴移动完成逻辑）
# 完成Y轴浮动动画后，交换起始和目标位置，实现来回浮动的效果
func _finalize_y_movement() -> void:
	position = target_pos
	# 交换起始和目标位置，使卡牌可以反向浮动
	var temp: Vector3 = target_pos
	target_pos = start_pos
	start_pos = temp
	move_ability = false

# 选中卡牌处理（优化：提取重复的选中逻辑）
# 处理卡牌被选中时的逻辑：取消之前选中的卡牌，设置当前卡牌为选中状态
# TODO: 添加选中卡牌时的音效和视觉反馈
func _select_card(target_pos_: Vector3,peak_height_: Vector3) -> void:
	# 如果之前有选中的卡牌，取消其选中状态（恢复位置和动画参数）
	if global.selectedCard != self:
		if global.selectedCard != null:
			#global.selectedCard.reparent(global.Cube_Desk)
			global.selectedCard.move_ability = true
			global.selectedCard.elapsed_time = 0.0
			global.selectedCard.peak_height = Vector3(0,0,0)
			global.selectedCard.move_duration = 0.1
		# 设置当前卡牌为选中状态，启动浮动动画
		global.selectedCard = self
		#global.selectedCard.reparent(global.camera)
		move_ability = true
		target_pos = target_pos_
		elapsed_time = 0.0
		peak_height = peak_height_
		move_duration = 0.1
	else:
		#global.selectedCard.reparent(global.Cube_Desk)
		move_ability = true
		elapsed_time = 0.0
		peak_height = Vector3(0,0,0)
		global.selectedCard = null
		move_duration = 0.1
		

# 初始化基础状态（优化：提取公共初始化逻辑）
# 设置状态的基础参数，多个状态初始化函数会调用此函数
# duration: 移动动画的时长（秒）
# height: 抛物线运动的最大高度
# show_area: 是否显示碰撞检测区域
func _init_base_state(duration: float, height: Vector3, show_area: bool = true) -> void:
	start_rotation = rotation
	start_pos = position
	move_duration = duration
	peak_height = height
	target_x_rotate = 0.0
	target_y_rotate = 0.0
	target_z_rotate = 0.0
	move_ability = false
	area.visible = show_area
	elapsed_time = 0.0

# 初始化发牌状态
# 设置发牌状态的初始参数：卡牌从卡池飞出，带有旋转动画
# TODO: 提取状态配置数据到常量或配置结构体
func _init_dealing_state() -> void:
	# 设置初始旋转角度（从背面旋转到正面）
	start_rotation = Vector3(deg_to_rad(-270), deg_to_rad(180), 0.0)
	rotation = start_rotation
	start_pos = global.Deck.position
	move_duration = 0.8
	peak_height = Vector3(0,0.5,0)
	# 根据卡牌在选择组中的索引计算目标位置（水平排列）
	var idx = global.selectGroup.find(self)
	target_pos = Vector3(start_pos.x + 0.3 + idx * 0.3, global.Deck.position.y, global.Deck.position.z)
	# 设置目标旋转角度（完成翻转）
	target_x_rotate = 180.0
	target_y_rotate = 180.0
	target_z_rotate = 360.0
	team_id = -1

# 初始化选牌状态
# 设置选牌状态的参数：卡牌在选择区域等待被选择
func _init_selecting_state() -> void:
	_init_base_state(0.3, Vector3(0,0.01,0), true)
	team_id = -1

# 初始化等待状态
# 设置等待状态的参数：卡牌在玩家等待区域，可以被操作
func _init_waiting_state() -> void:
	_init_base_state(0.3, Vector3(0,0.01,0), true)

# 初始化丢弃状态
# 设置丢弃状态的参数：卡牌被售卖后飞向弃牌堆
func _init_discard_state() -> void:
	# 如果卡牌有队伍归属，从玩家的等待组中移除并添加到弃牌组
	if team_id != -1:
		var player = _get_cached_player()
		if player != null and player.waitingGroup.has(self):
			var idx = player.waitingGroup.find(self)
			player.waitingGroup.remove_at(idx)
			move_duration = 1
			peak_height = Vector3(1,0.8,0)
				# 设置旋转动画（翻转效果）
			if team_id == global.local_player.team_id:
				target_x_rotate = 270.0
				target_y_rotate = 90.0
				target_z_rotate = -90.0
			else:
				target_x_rotate = 90.0
				target_y_rotate = 90.0
				target_z_rotate = -90.0
		if player != null and player.hand_cards.has(self):
			var idx = player.hand_cards.find(self)
			player.hand_cards.remove_at(idx)
			move_duration = 0.4
			peak_height = Vector3(0.4,0,0)
			target_x_rotate = 90.0
			target_y_rotate = 0
			target_z_rotate = 0
		if player != null and player.showing_cards.has(self):
			var idx = player.showing_cards.find(self)
			player.showing_cards.remove_at(idx)
			move_duration = 0.4
			peak_height = Vector3(0.4,0,0)
			target_x_rotate = 90.0
			target_y_rotate = 0
			target_z_rotate = 0
		global.discardGroup.push_back(self)
		_clear_player_cache()
		player.can_combo = false
	# 恢复原始颜色
	_set_color_animation(original_modulate)
	# 设置目标位置为弃牌堆位置
	target_pos = global.discardPile.position
	start_rotation = rotation
	start_pos = position
	move_ability = true
	area.visible = false
	elapsed_time = 0.0

# 初始化到手牌状态
# 设置到手牌状态的参数：卡牌从等待区域移动到玩家手牌区域
func _init_to_held_state() -> void:
	var player = _get_cached_player()
	if player != null:
		player.can_combo = false
		# 从等待组中移除卡牌（如果存在）
		if team_id != -1 and player.waitingGroup.has(self):
			var idx = player.waitingGroup.find(self)
			player.waitingGroup.remove_at(idx)
		# 添加到玩家手牌组
		if !player.hand_cards.has(self):
			player.hand_cards.push_back(self)
			if team_id == global.local_player.team_id:
				target_x_rotate = 90.0
				target_y_rotate = 90.0
				target_z_rotate = -90.0
			else:
				target_x_rotate = 270.0
				target_y_rotate = 90.0
				target_z_rotate = -90.0
			move_duration = 0.5
			peak_height = Vector3(0.8,0.4,0)
		else:
			move_duration = 0.1
			peak_height = Vector3(0.1,0.0,0)
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = position
	# 根据队伍ID设置目标Z坐标（不同队伍的手牌在不同深度）
	# TODO: 提取0.3, -0.3等魔法数字为常量
	var held_pos: Vector3
	if team_id == global.local_player.team_id:
		held_pos = global.HELD_Area1_Label.position
	else:
		held_pos = global.HELD_Area2_Label.position
	target_pos.x = held_pos.x
	target_pos.z = held_pos.z
	# 根据卡牌在手牌中的索引计算目标X坐标（手牌水平排列）
	var idx = player.hand_cards.find(self)
	target_pos.y = held_pos.y - 0.5 - idx * 0.2
	move_ability = true
	elapsed_time = 0.0

# 初始化手持状态
# 设置手持状态的参数：卡牌在玩家手牌区域
func _init_held_state() -> void:
	_set_color_animation(original_modulate)
	_init_base_state(0.2, Vector3(0.01,0,0), true)
	var player = _get_cached_player()
	if player != null:
		player.can_combo = true
	
# 初始化到展示牌状态
# 设置到手牌状态的参数：卡牌从手牌区域移动到展示区域
func _init_to_showing_state() -> void:
	var player = _get_cached_player()
	if player != null:
		# 从等待组中移除卡牌（如果存在）
		if team_id != -1 and player.hand_cards.has(self):
			var idx: int = player.hand_cards.find(self)
			player.hand_cards.remove_at(idx)
			#其他卡牌调整顺序
			for i in range(idx, player.hand_cards.size()):
				player.hand_cards.get(i).switch_state(States.TO_HELD)
		# 添加到玩家手牌组
		player.showing_cards.push_back(self)
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = position
	move_duration = 0.1
	peak_height = Vector3(0.25,0,0)
	# 根据卡牌在手牌中的索引计算目标X/Z坐标（手牌水平排列）
	var idx = player.showing_cards.find(self)
	const limit: int = 7
	var offsets_z: int = (idx / limit)
	target_pos.z = global.Showing_Area_Label.position.z + (0.15 if team_id == 1 else -0.15) + offsets_z * (0.3 if team_id == 1 else -0.3)
	target_pos.x = global.Showing_Area_Label.position.x + 0.005
	target_pos.y = (global.Showing_Area_Label.position.y + 0.4) - (idx % limit - 1) * 0.2
	move_ability = true
	elapsed_time = 0.0
	

# 初始化展示状态
# 设置展示状态的参数：卡牌在玩家展示区域
func _init_showing_state() -> void:
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = position
	move_duration = 0.1
	target_pos.x = global.Showing_Area_Label.position.x + 0.005
	peak_height = Vector3(0,0,0)
	move_ability = true
	elapsed_time = 0.0

# 初始化可激活状态
# 设置可激活状态的参数：卡牌在玩家展示区域
func _init_to_activate_state() -> void:
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = position
	move_duration = 0.1
	target_pos.x = global.Showing_Area_Label.position.x + 0.025
	target_x_rotate = 0.0
	target_y_rotate = 0.0
	target_z_rotate = 0.0
	peak_height = Vector3(0,0,0)
	move_ability = true
	elapsed_time = 0.0

# 计算并应用3D移动（优化：提取重复逻辑）
# 根据进度值插值计算卡牌的位置，支持X、Y、Z轴的独立控制
# progress: 动画进度值（0.0到1.0）
# update_x: 是否更新X轴位置
# update_z: 是否更新Z轴位置
# update_y: 是否更新Y轴位置（Y轴使用抛物线效果）
func _apply_3d_movement(progress: float, update_x: bool = true, update_z: bool = true, update_y: bool = true) -> void:
	if update_x:
		# X轴线性插值
		var linear_x = lerp(start_pos.x, target_pos.x, progress)
		# X轴抛物线效果（使卡牌飞行时有弧线轨迹）
		var parabola_x = PARABOLA_MULTIPLIER * peak_height.x * progress * (1 - progress)
		position.x = linear_x + parabola_x
	if update_z:
		# Z轴线性插值
		var linear_z = lerp(start_pos.z, target_pos.z, progress)
		# Z轴抛物线效果（使卡牌飞行时有弧线轨迹）
		var parabola_z = PARABOLA_MULTIPLIER * peak_height.z * progress * (1 - progress)
		position.z = linear_z + parabola_z
	if update_y:
		# Y轴线性插值
		var linear_y = lerp(start_pos.y, target_pos.y, progress)
		# Y轴抛物线效果（使卡牌飞行时有弧线轨迹）
		var parabola_y = PARABOLA_MULTIPLIER * peak_height.y * progress * (1 - progress)
		position.y = linear_y + parabola_y

# 计算并应用3D旋转（优化：提取重复逻辑）
# 根据进度值插值计算卡牌的旋转角度
# progress: 动画进度值（0.0到1.0）
# 返回: 目标旋转角度（用于动画完成时设置最终角度）
func _apply_3d_rotation(progress: float) -> Vector3:
	# 计算目标旋转角度（起始角度 + 旋转增量）
	var target_x_rot = start_rotation.x + deg_to_rad(target_x_rotate)
	var target_y_rot = start_rotation.y + deg_to_rad(target_y_rotate)
	var target_z_rot = start_rotation.z + deg_to_rad(target_z_rotate)
	# 对每个轴进行角度插值
	rotation.x = lerp(start_rotation.x, target_x_rot, progress)
	rotation.y = lerp(start_rotation.y, target_y_rot, progress)
	rotation.z = lerp(start_rotation.z, target_z_rot, progress)
	return Vector3(target_x_rot, target_y_rot, target_z_rot)

# 完成运动并设置最终位置和旋转（优化：提取重复逻辑）
# 动画完成后，将卡牌位置和旋转设置为目标值，确保精确对齐
# target_rot: 目标旋转角度（由_apply_3d_rotation返回）
func _finalize_movement(target_rot: Vector3) -> void:
	position = target_pos
	rotation.x = target_rot.x
	rotation.y = target_rot.y
	rotation.z = target_rot.z

# 获取缓存的玩家对象（优化：避免重复的数组访问和计算）
# 根据team_id获取对应的玩家对象，使用缓存机制避免重复查找
# 返回: 玩家对象，如果team_id无效则返回null
func _get_cached_player() -> PlayerEntity:
	# 如果缓存为空或team_id发生变化，重新获取玩家对象
	if _cached_player == null or _cached_player_team_id != team_id:
		if team_id > 0 and team_id <= global.players.size():
			_cached_player = global.players[team_id - 1]
			_cached_player_team_id = team_id
		else:
			return null
	return _cached_player

# 清除玩家缓存（状态切换时调用）
# 当卡牌状态切换或team_id变化时，清除缓存的玩家对象，确保数据正确
func _clear_player_cache() -> void:
	_cached_player = null
	_cached_player_team_id = -1

# 切换状态
# 切换到新的卡牌状态，并初始化该状态的参数
# state: 目标状态
# TODO: 添加状态转换验证，确保状态转换的合法性
func switch_state(state: States) -> void:
	# 只有在状态发生变化时才执行切换
	if (state != self.state):
		self.state = state
		# 清除缓存，确保状态切换后数据正确
		_clear_player_cache()
		# 初始化新状态的参数
		init()

# 能否释放技能
func can_take_effect() -> bool:
	return ((skill_type == Type.Permanent or skill_type == Type.Immediately or global.current_state == global.GameState.END) 
		and pre_round != global.game_progress)
	
# 技能
func take_effect() -> void:
	pass
