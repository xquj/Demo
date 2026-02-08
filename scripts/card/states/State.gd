extends Node
class_name State

var card: Card_Base
var _entered: bool = false

# 抛物线高度（可按状态调）
var parabola_height: float = 0.5

# 运动模式：线性/抛物线/二次贝塞尔
enum MoveMode {
	LINEAR,
	PARABOLA,
	BEZIER
}

# 运动配置
var move_mode: int = MoveMode.PARABOLA
var move_ease: float = 1.0
var move_rotate_enabled: bool = false
var move_scale_enabled: bool = false
var move_control_pos: Vector3 = Vector3.ZERO

func _init(card_: Card_Base) -> void:
	card = card_

func enter() -> void:
	# 状态进入时的初始化
	pass

func exit() -> void:
	# 状态退出时的清理
	pass

func handle_input(event: InputEvent) -> void:
	# 输入代理
	pass

func update(delta: float) -> void:
	# 逻辑更新代理
	pass

func transition_to(state_script: Script) -> void:
	# 使用脚本切换到新状态
	if card == null:
		push_warning("State transition failed: card is null.")
		return
	if state_script == null:
		push_warning("State transition failed: state_script is null.")
		return
	var next_state: State = state_script.new(card)
	_change_state(next_state)
	
#=============================================== 内部 ===========================================================
func _change_state(next_state: State) -> void:
	# 内部状态切换逻辑
	if card == null:
		push_warning("State transition failed: card is null.")
		return
	if next_state == null:
		push_warning("State transition failed: next_state is null.")
		return
	if card.state == next_state:
		return
	if card.state != null:
		card.state._exit_internal()
	card.state = next_state
	next_state._enter_internal()

func _input(event: InputEvent) -> void:
	# 统一输入入口
	handle_input(event)

func _process(delta: float) -> void:
	# 确保 enter 仅触发一次
	if not _entered:
		_enter_internal()
	# 处理移动再进行状态更新
	_update_movement(delta)
	update(delta)

func _enter_internal() -> void:
	# 防止重复进入
	if _entered:
		return
	_entered = true
	enter()

func _exit_internal() -> void:
	# 防止重复退出
	if not _entered:
		return
	exit()
	_entered = false

func _update_movement(delta: float) -> void:
	# 运动插值更新
	# 用法：由 _process 内部驱动，无需手动调用
	if card == null or not card.moving_ablity:
		return
	if card.duration <= 0.0:
		_finish_move()
		return
	card.elapsed = minf(card.elapsed + delta, card.duration)
	var t: float = card.elapsed / card.duration
	var eased_t: float = ease(t, move_ease)

	# 位置/旋转/缩放插值
	var next_pos: Vector3 = _calculate_position(eased_t)
	card.global_position = next_pos
	_apply_rotation(eased_t)
	_apply_scale(eased_t)

	# 到达终点
	if t >= 1.0:
		_finish_move()

# ===================== 启动移动 =====================
func _move(
	target_pos: Vector3,
	duration: float,
	height: float = 0.5,
	mode: int = MoveMode.PARABOLA,
	ease_weight: float = 1.0
) -> void:
	# 通用移动入口（支持模式和曲线）
	# 用法：_move(Vector3(1, 1, 1), 0.5, 0.3, MoveMode.PARABOLA, 1.0)
	if card == null:
		push_warning("Move failed: card is null.")
		return
	card.start_pos = card.global_position
	card.target_pos = target_pos
	card.duration = maxf(duration, 0.001)
	card.elapsed = 0.0
	card.moving_ablity = true
	parabola_height = height
	move_mode = mode
	move_ease = maxf(ease_weight, 0.01)
	move_rotate_enabled = false
	move_scale_enabled = false
	move_control_pos = card.control_pos

func _move_with_control(
	target_pos: Vector3,
	control_pos: Vector3,
	duration: float,
	ease_weight: float = 1.0
) -> void:
	# 二次贝塞尔移动（指定控制点）
	# 用法：_move_with_control(target, control, 0.6, 1.2)
	_move(target_pos, duration, 0.0, MoveMode.BEZIER, ease_weight)
	move_control_pos = control_pos
	card.control_pos = control_pos

func _move_with_rotation(
	target_pos: Vector3,
	target_rot: Vector3,
	duration: float,
	height: float = 0.5,
	mode: int = MoveMode.PARABOLA,
	ease_weight: float = 1.0
) -> void:
	# 移动时插值旋转
	# 用法：_move_with_rotation(target, Vector3(0, PI, 0), 0.5)
	_move(target_pos, duration, height, mode, ease_weight)
	card.start_rot = card.rotation
	card.target_rot = target_rot
	move_rotate_enabled = true

func _move_with_control_rotation(
	target_pos: Vector3,
	control_pos: Vector3,
	target_rot: Vector3,
	duration: float,
	ease_weight: float = 1.0
) -> void:
	# 贝塞尔移动并插值旋转
	# 用法：_move_with_control_rotation(target, control, Vector3(0, PI, 0), 0.6)
	_move_with_control(target_pos, control_pos, duration, ease_weight)
	card.start_rot = card.rotation
	card.target_rot = target_rot
	move_rotate_enabled = true

func _move_with_scale(
	target_pos: Vector3,
	target_scale: Vector3,
	duration: float,
	height: float = 0.5,
	mode: int = MoveMode.PARABOLA,
	ease_weight: float = 1.0
) -> void:
	# 移动时插值缩放
	# 用法：_move_with_scale(target, Vector3(1.2, 1.2, 1.2), 0.5)
	_move(target_pos, duration, height, mode, ease_weight)
	card.start_scale = card.scale
	card.target_scale = target_scale
	move_scale_enabled = true

func _finish_move() -> void:
	# 移动收尾，确保落点正确
	# 用法：内部自动调用，不建议外部直接触发
	if card == null:
		return
	card.global_position = card.target_pos
	if move_rotate_enabled:
		card.rotation = card.target_rot
	if move_scale_enabled:
		card.scale = card.target_scale
	card.moving_ablity = false
	move_rotate_enabled = false
	move_scale_enabled = false

func _calculate_position(t: float) -> Vector3:
	# 根据模式计算当前位置
	# 用法：内部用于插值计算
	match move_mode:
		MoveMode.LINEAR:
			return card.start_pos.lerp(card.target_pos, t)
		MoveMode.BEZIER:
			return _quadratic_bezier(card.start_pos, move_control_pos, card.target_pos, t)
		MoveMode.PARABOLA, _:
			var base_pos: Vector3 = card.start_pos.lerp(card.target_pos, t)
			var parabola: float = parabola_height * 4.0 * t * (1.0 - t)
			base_pos.y += parabola
			return base_pos

func _quadratic_bezier(start: Vector3, control: Vector3, target: Vector3, t: float) -> Vector3:
	# 二次贝塞尔曲线公式
	# 用法：内部函数，提供 BEZIER 模式的曲线插值
	var u: float = 1.0 - t
	return (u * u) * start + (2.0 * u * t) * control + (t * t) * target

func _apply_rotation(t: float) -> void:
	# 旋转插值（使用角度插值防止跨界）
	# 用法：启用 move_rotate_enabled 时自动执行
	if not move_rotate_enabled:
		return
	card.rotation.x = lerp_angle(card.start_rot.x, card.target_rot.x, t)
	card.rotation.y = lerp_angle(card.start_rot.y, card.target_rot.y, t)
	card.rotation.z = lerp_angle(card.start_rot.z, card.target_rot.z, t)

func _apply_scale(t: float) -> void:
	# 缩放插值
	# 用法：启用 move_scale_enabled 时自动执行
	if not move_scale_enabled:
		return
	card.scale = card.start_scale.lerp(card.target_scale, t)
