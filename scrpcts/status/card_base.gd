extends Sprite3D
class_name Card_Base

# ===================== 通用配置 =====================
@export var team_id: int = -1
@export var area: Area3D
@export var original_modulate: Color

var is_entered := false
var is_clicked := false
var move_ability := true

# ===================== 卡牌属性 =====================
var selling_price: Array[ItemDate] = []
var family_name: String
var family_texture: Texture2D

enum Type { Immediately, Permanent, Initiative }
var skill_type: Type = Type.Immediately
var card_name: String
var cost := 0
var skill: String

# ===================== 运动与动画 =====================
var start_pos := Vector3.ZERO
var target_pos := Vector3.ZERO
var start_rotation := Vector3.ZERO
var elapsed_time := 0.0
var move_duration := 1.0
var peak_height := Vector3(0, 0.5, 0)
var target_x_rotate := 0.0
var target_y_rotate := 0.0
var target_z_rotate := 0.0

var colorAnimation: ColorAnimationUtils

# ===================== 缓存与静止状态 =====================
var _cached_player: PlayerEntity
var _cached_player_team_id := -1
var _idle_wobble_time := 0.0
var _idle_breathe_time := 0.0
var _rest_rotation := Vector3.ZERO
var _rest_position := Vector3.ZERO

# ===================== 常量 =====================
const PARABOLA_MULTIPLIER := 4.0
const SELECTED_COLOR := Color(0.627, 0.627, 0.627, 1.0)
const COLOR_ANIM_DURATION := 100
const Y_OFFSET_SELECTED := 0.02
const IDLE_WOBBLE_SPEED := 2.4
const IDLE_WOBBLE_DEGREES := Vector3(2.0, 3.0, 0.6)
const IDLE_BREATHE_SPEED := 1.4
const IDLE_BREATHE_HEIGHT := 0.008
const HOVER_LIFT_HEIGHT := 0.015
const EASE_IN_OUT_EXPONENT := 2.0
const HAND_FAN_MAX_DEGREES := 18.0
const HAND_FAN_RADIUS := 0.9
const HAND_FAN_Y_OFFSET := -0.55

# ===================== 状态 =====================
enum States { DEALING, SELECTING, WAITING, DISCARD, TO_HELD, HELD, TO_SHOWING, SHOWING, TO_ACTIVATE }
var state: States = States.DEALING
var pre_round := -999

func _ready() -> void:
	_setup_area()
	_setup_color_animation()
	_rest_rotation = rotation
	_rest_position = global_position
	area.visible = false
	init()

func _setup_area() -> void:
	if area == null:
		for child in get_children():
			if child is Area3D:
				area = child
	area.mouse_entered.connect(func(): mouse_entered(true))
	area.mouse_exited.connect(func(): mouse_entered(false))

func _setup_color_animation() -> void:
	colorAnimation = ColorAnimationUtils.new(modulate, modulate, COLOR_ANIM_DURATION)
	colorAnimation.play(true)
	original_modulate = modulate

func _process(delta: float) -> void:
	if not visible:
		return
	_update_color(delta)
	_update_state(delta)
	_update_idle(delta)

func _update_color(delta: float) -> void:
	colorAnimation.update(delta)
	modulate = colorAnimation.value
	_update_color_highlight()

func _update_state(delta: float) -> void:
	match state:
		States.DEALING:
			if move_ability and _step_full_movement(delta):
				switch_state(States.SELECTING)
		States.SELECTING:
			if move_ability:
				var player = _get_cached_player()
				if player != null:
					target_pos = global.WAIT_Area1_Label.global_position if player.team_id == global.local_player.team_id else global.WAIT_Area2_Label.global_position
					var idx = player.waitingGroup.find(self)
					target_pos.x += 0.5 + idx * 0.3
					if _step_full_movement(delta):
						switch_state(States.WAITING)
		States.WAITING:
			if move_ability and _step_axis_movement(delta, false, false, true):
				_finalize_y_movement()
		States.DISCARD:
			if move_ability and _step_full_movement(delta):
				move_ability = false
				var player = _get_cached_player()
				if player != null:
					player.can_combo = true
				team_id = -1
		States.TO_HELD:
			if move_ability:
				var player = _get_cached_player()
				if player != null and _step_full_movement(delta):
					switch_state(States.HELD)
		States.HELD:
			if move_ability and _step_axis_movement(delta, false, false, true):
				_finalize_y_movement()
		States.TO_SHOWING:
			if move_ability:
				var player = _get_cached_player()
				if player != null and _step_full_movement(delta):
					switch_state(States.SHOWING)
		States.SHOWING:
			if move_ability:
				if _step_axis_movement(delta, false, false, true):
					_finalize_y_movement()
			elif can_take_effect():
				switch_state(States.TO_ACTIVATE)
		States.TO_ACTIVATE:
			if move_ability:
				if _step_axis_movement(delta, false, false, true):
					_finalize_y_movement()
			elif !can_take_effect():
				switch_state(States.SHOWING)

func _update_idle(delta: float) -> void:
	if move_ability:
		return
	if _should_idle_wobble():
		_apply_idle_wobble(delta)
	else:
		_reset_idle_wobble()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
			if is_entered:
				global.DetailedCard = self
				global.Card_Info_Panel.visible = true
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			is_clicked = true
		if event.is_released() and is_clicked:
			is_clicked = false
			match state:
				States.SELECTING:
					if is_entered and global.current_state == global.GameState.SELECTING and global.player_activity != null and !move_ability:
						move_ability = true
						team_id = global.player_activity.team_id
						_set_color_animation(original_modulate)
						global.player_activity.waitingGroup.push_back(self)
						var select_idx = global.selectGroup.find(self)
						if select_idx >= 0:
							global.selectGroup.remove_at(select_idx)
						global.round += 1
						if team_id == 1:
							target_pos.z = 0.5
						else:
							target_y_rotate = 180
							target_pos.z = -0.5
				States.WAITING:
					if is_entered:
						var pos = target_pos
						pos.y = start_pos.y + Y_OFFSET_SELECTED
						_select_card(pos, Vector3(0.01, 0, 0))
				States.HELD:
					if is_entered and global.current_state == global.GameState.COMBOING:
						if global.player_activity.team_id == team_id:
							start_pos = global_position
							var pos = target_pos
							pos.x = start_pos.x + Y_OFFSET_SELECTED
							_select_card(pos, Vector3(0.01, 0, 0))
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

func mouse_entered(on: bool) -> void:
	is_entered = on
	_set_color_animation(SELECTED_COLOR if on else original_modulate)

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

func _update_color_highlight() -> void:
	match state:
		States.WAITING, States.HELD:
			if global.selectedCard == self:
				_set_color_animation(SELECTED_COLOR)
			elif !is_entered:
				_set_color_animation(original_modulate)

func _set_color_animation(target_color: Color) -> void:
	colorAnimation.set_target(target_color, COLOR_ANIM_DURATION)
	colorAnimation.play(true)

func _update_movement_progress(delta: float) -> float:
	if move_duration <= 0.0:
		elapsed_time = move_duration
		return 1.0
	elapsed_time = minf(elapsed_time + delta, move_duration)
	return elapsed_time / move_duration

func _step_full_movement(delta: float) -> bool:
	var progress = _update_movement_progress(delta)
	var eased_progress = _ease_in_out(progress)
	_apply_3d_movement(eased_progress)
	var target_rot = _apply_3d_rotation(eased_progress)
	if progress >= 1.0:
		_finalize_movement(target_rot)
		return true
	return false

func _step_axis_movement(delta: float, update_x: bool, update_z: bool, update_y: bool) -> bool:
	var progress = _update_movement_progress(delta)
	var eased_progress = _ease_in_out(progress)
	_apply_3d_movement(eased_progress, update_x, update_z, update_y)
	return progress >= 1.0

func _finalize_y_movement() -> void:
	global_position = target_pos
	var temp = target_pos
	target_pos = start_pos
	start_pos = temp
	_rest_rotation = rotation
	_rest_position = global_position
	move_ability = false

func _select_card(target_pos_: Vector3, peak_height_: Vector3) -> void:
	if global.selectedCard != self:
		if global.selectedCard != null:
			global.selectedCard.move_ability = true
			global.selectedCard.elapsed_time = 0.0
			global.selectedCard.peak_height = Vector3(0, 0, 0)
			global.selectedCard.move_duration = 0.1
		global.selectedCard = self
		move_ability = true
		target_pos = target_pos_
		elapsed_time = 0.0
		peak_height = peak_height_
		move_duration = 0.1
	else:
		move_ability = true
		elapsed_time = 0.0
		peak_height = Vector3(0, 0, 0)
		global.selectedCard = null
		move_duration = 0.1

func _init_base_state(duration: float, height: Vector3, show_area: bool = true) -> void:
	start_rotation = rotation
	start_pos = global_position
	move_duration = duration
	peak_height = height
	target_x_rotate = 0.0
	target_y_rotate = 0.0
	target_z_rotate = 0.0
	move_ability = false
	area.visible = show_area
	elapsed_time = 0.0

func _init_dealing_state() -> void:
	start_rotation = Vector3(deg_to_rad(-270), deg_to_rad(180), 0.0)
	rotation = start_rotation
	start_pos = global.Deck.global_position
	move_duration = 0.8
	peak_height = Vector3(0, 0.5, 0)
	var idx = global.selectGroup.find(self)
	target_pos = Vector3(start_pos.x + 0.3 + idx * 0.3, global.Deck.global_position.y, global.Deck.global_position.z)
	target_x_rotate = 180.0
	target_y_rotate = 180.0
	target_z_rotate = 360.0
	team_id = -1

func _init_selecting_state() -> void:
	_init_base_state(0.3, Vector3(0, 0.01, 0), true)
	team_id = -1

func _init_waiting_state() -> void:
	_init_base_state(0.3, Vector3(0, 0.01, 0), true)

func _init_discard_state() -> void:
	if team_id != -1:
		var player = _get_cached_player()
		if player != null and player.waitingGroup.has(self):
			var idx = player.waitingGroup.find(self)
			player.waitingGroup.remove_at(idx)
			move_duration = 1
			peak_height = Vector3(1, 0.8, 0)
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
			peak_height = Vector3(0.4, 0, 0)
			target_x_rotate = 90.0
			target_y_rotate = 0
			target_z_rotate = 0
		if player != null and player.showing_cards.has(self):
			var idx = player.showing_cards.find(self)
			player.showing_cards.remove_at(idx)
			move_duration = 0.4
			peak_height = Vector3(0.4, 0, 0)
			target_x_rotate = 90.0
			target_y_rotate = 0
			target_z_rotate = 0
		global.discardGroup.push_back(self)
		_clear_player_cache()
		player.can_combo = false
	_set_color_animation(original_modulate)
	target_pos = global.discardPile.global_position
	start_rotation = rotation
	start_pos = global_position
	move_ability = true
	area.visible = false
	elapsed_time = 0.0

func _init_to_held_state() -> void:
	var player = _get_cached_player()
	if player != null:
		player.can_combo = false
		if team_id != -1 and player.waitingGroup.has(self):
			var idx = player.waitingGroup.find(self)
			player.waitingGroup.remove_at(idx)
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
			peak_height = Vector3(0.8, 0.4, 0)
		else:
			move_duration = 0.1
			peak_height = Vector3(0.1, 0.0, 0)
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = global_position
	target_pos = _get_hand_fan_position(player)
	move_ability = true
	elapsed_time = 0.0

func _init_held_state() -> void:
	_set_color_animation(original_modulate)
	_init_base_state(0.2, Vector3(0.01, 0, 0), true)
	var player = _get_cached_player()
	if player != null:
		player.can_combo = true
		target_pos = _get_hand_fan_position(player)
		start_pos = global_position
		move_ability = true
		elapsed_time = 0.0

func _init_to_showing_state() -> void:
	var player = _get_cached_player()
	if player != null:
		if team_id != -1 and player.hand_cards.has(self):
			var idx: int = player.hand_cards.find(self)
			player.hand_cards.remove_at(idx)
			for i in range(idx, player.hand_cards.size()):
				player.hand_cards.get(i).switch_state(States.TO_HELD)
		player.showing_cards.push_back(self)
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = global_position
	move_duration = 0.1
	peak_height = Vector3(0.25, 0, 0)
	var idx = player.showing_cards.find(self)
	const limit: int = 7
	var offsets_z: int = (idx / limit)
	target_pos.z = global.Showing_Area_Label.global_position.z + (0.15 if team_id == 1 else -0.15) + offsets_z * (0.3 if team_id == 1 else -0.3)
	target_pos.x = global.Showing_Area_Label.global_position.x + 0.005
	target_pos.y = (global.Showing_Area_Label.global_position.y + 0.4) - (idx % limit - 1) * 0.2
	move_ability = true
	elapsed_time = 0.0

func _init_showing_state() -> void:
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = global_position
	move_duration = 0.1
	target_pos.x = global.Showing_Area_Label.global_position.x + 0.005
	peak_height = Vector3.ZERO
	move_ability = true
	elapsed_time = 0.0

func _init_to_activate_state() -> void:
	_set_color_animation(original_modulate)
	start_rotation = rotation
	start_pos = global_position
	move_duration = 0.1
	target_pos.x = global.Showing_Area_Label.global_position.x + 0.025
	target_x_rotate = 0.0
	target_y_rotate = 0.0
	target_z_rotate = 0.0
	peak_height = Vector3.ZERO
	move_ability = true
	elapsed_time = 0.0

func _apply_3d_movement(progress: float, update_x: bool = true, update_z: bool = true, update_y: bool = true) -> void:
	var parabola_factor = PARABOLA_MULTIPLIER * progress * (1.0 - progress)
	if update_x:
		global_position.x = lerp(start_pos.x, target_pos.x, progress) + parabola_factor * peak_height.x
	if update_z:
		global_position.z = lerp(start_pos.z, target_pos.z, progress) + parabola_factor * peak_height.z
	if update_y:
		global_position.y = lerp(start_pos.y, target_pos.y, progress) + parabola_factor * peak_height.y

func _apply_3d_rotation(progress: float) -> Vector3:
	var target_x_rot = start_rotation.x + deg_to_rad(target_x_rotate)
	var target_y_rot = start_rotation.y + deg_to_rad(target_y_rotate)
	var target_z_rot = start_rotation.z + deg_to_rad(target_z_rotate)
	rotation.x = lerp(start_rotation.x, target_x_rot, progress)
	rotation.y = lerp(start_rotation.y, target_y_rot, progress)
	rotation.z = lerp(start_rotation.z, target_z_rot, progress)
	return Vector3(target_x_rot, target_y_rot, target_z_rot)

func _finalize_movement(target_rot: Vector3) -> void:
	global_position = target_pos
	rotation = target_rot
	_rest_rotation = rotation
	_rest_position = global_position

func _get_cached_player() -> PlayerEntity:
	if _cached_player == null or _cached_player_team_id != team_id:
		if team_id > 0 and team_id <= global.players.size():
			_cached_player = global.players[team_id - 1]
			_cached_player_team_id = team_id
		else:
			return null
	return _cached_player

func _clear_player_cache() -> void:
	_cached_player = null
	_cached_player_team_id = -1

func _get_hand_fan_position(player: PlayerEntity) -> Vector3:
	var held_pos = global.HELD_Area1_Label.global_position if team_id == global.local_player.team_id else global.HELD_Area2_Label.global_position
	var count = max(1, player.hand_cards.size())
	var idx = player.hand_cards.find(self)
	var center = float(count - 1) / 2.0
	var t = 0.0 if count == 1 else (float(idx) - center) / center
	var angle_deg = t * HAND_FAN_MAX_DEGREES
	var angle_rad = deg_to_rad(angle_deg)
	var direction = -1.0 if team_id == global.local_player.team_id else 1.0
	var fan_offset = Vector3(
		sin(angle_rad) * HAND_FAN_RADIUS,
		HAND_FAN_Y_OFFSET + (1.0 - cos(angle_rad)) * 0.15,
		cos(angle_rad) * 0.05 * direction
	)
	target_z_rotate = angle_deg * direction
	target_x_rotate = 90.0 if team_id == global.local_player.team_id else 270.0
	target_y_rotate = 90.0
	return held_pos + fan_offset

func _should_idle_wobble() -> bool:
	return state in [States.WAITING, States.HELD, States.SHOWING, States.TO_ACTIVATE] and (is_entered or global.selectedCard == self)

func _apply_idle_wobble(delta: float) -> void:
	_idle_wobble_time += delta
	_idle_breathe_time += delta
	var wobble = Vector3(
		sin(_idle_wobble_time * IDLE_WOBBLE_SPEED) * deg_to_rad(IDLE_WOBBLE_DEGREES.x),
		cos(_idle_wobble_time * IDLE_WOBBLE_SPEED * 0.9) * deg_to_rad(IDLE_WOBBLE_DEGREES.y),
		sin(_idle_wobble_time * IDLE_WOBBLE_SPEED * 1.1) * deg_to_rad(IDLE_WOBBLE_DEGREES.z)
	)
	rotation = _rest_rotation + wobble
	var breathe_offset = sin(_idle_breathe_time * IDLE_BREATHE_SPEED) * IDLE_BREATHE_HEIGHT
	var hover_offset = HOVER_LIFT_HEIGHT if (is_entered or global.selectedCard == self) else 0.0
	global_position = _rest_position + Vector3(0.0, breathe_offset + hover_offset, 0.0)

func _reset_idle_wobble() -> void:
	_idle_wobble_time = 0.0
	_idle_breathe_time = 0.0
	rotation = _rest_rotation
	global_position = _rest_position

func _ease_in_out(t: float) -> float:
	var clamped = clampf(t, 0.0, 1.0)
	var smooth = clamped * clamped * (3.0 - 2.0 * clamped)
	return pow(smooth, EASE_IN_OUT_EXPONENT)

func switch_state(state: States) -> void:
	if state != self.state:
		self.state = state
		_clear_player_cache()
		init()

func can_take_effect() -> bool:
	return ((skill_type == Type.Permanent or skill_type == Type.Immediately or global.current_state == global.GameState.END)
		and pre_round != global.game_progress)

func take_effect() -> void:
	pass
