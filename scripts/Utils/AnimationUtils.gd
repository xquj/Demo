extends Object
class_name AnimationUtils

# ====================【可读可写状态】====================
# 已运行时长（毫秒）。
var time: int = 0
# 动画总时长（毫秒）。<= 0 时按“瞬时完成”处理。
var end_time: int = 500
# 当前值（外部直接读取）。
var value: float = 0.0
# 起始值。
var start_value: float = 0.0
# 目标值。
var end_value: float = 1.0
# 是否完成（到达目标值后为 true）。
var done: bool = false

# ====================【可配置参数】====================
@export var ease_type: EaseType = EaseType.LINEAR
# 是否允许 update() 自动按时间推进。
@export var auto_calc: bool = true
# 是否循环。
@export var loop: bool = false
# 循环时是否乒乓（往返）。
@export var ping_pong: bool = false

enum EaseType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT
}

# ====================【内部状态】====================
var _is_running: bool = false
# 记录初始起点，用于 reset()/普通 loop 的“回到最初起点”。
var _origin_start: float = 0.0


func _init(_start: float = 0.0, _end: float = 1.0, _duration: int = 500, _ease: EaseType = EaseType.LINEAR) -> void:
	start_value = _start
	end_value = _end
	end_time = _duration
	ease_type = _ease
	_origin_start = _start
	value = _start
	time = 0
	done = end_time <= 0 and is_equal_approx(start_value, end_value)


# 每帧更新（delta: 秒）。
func update(delta: float) -> void:
	if not _is_running or done:
		return
	if not auto_calc:
		return

	# 0ms 或负时长直接完成。
	if end_time <= 0:
		_complete_once()
		return

	time += int(delta * 1000.0)
	if time >= end_time:
		_complete_once()
		return

	var progress: float = float(time) / float(end_time)
	progress = _calc_ease(progress)
	value = lerp(start_value, end_value, progress)


# 手动按进度计算（0~1），并返回当前值。
func calc_by_progress(progress: float) -> float:
	var p: float = clamp(progress, 0.0, 1.0)
	var eased: float = _calc_ease(p)
	value = lerp(start_value, end_value, eased)
	time = int(float(end_time) * p)
	done = p >= 1.0
	if done:
		_is_running = false
	return value


# 启动动画。
# resume_from_current = false: 从 start_value 重新开始（并重置 time）。
# resume_from_current = true: 从当前 time/value 继续。
func play(resume_from_current: bool = false) -> void:
	if not resume_from_current:
		time = 0
		done = false
		value = start_value
	# 若之前已完成但希望“继续播放”，则从头再来一遍。
	elif done:
		time = 0
		done = false
		value = start_value

	# 时长<=0时，play 后下一帧 update 会立即完成；这里也可立即收敛。
	if end_time <= 0:
		_complete_once()
		return

	_is_running = true


func pause() -> void:
	_is_running = false


func stop(apply_end_value: bool = true) -> void:
	_is_running = false
	done = true
	time = max(end_time, 0)
	if apply_end_value:
		value = end_value


# 重置到“最初构造时的起点”，并停止。
func reset() -> void:
	time = 0
	done = false
	_is_running = false
	start_value = _origin_start
	value = start_value


# 以当前 value 作为新起点，切换目标并重新计时。
func set_target(new_end_value: float, new_duration: int = -1) -> void:
	start_value = value
	end_value = new_end_value
	if new_duration >= 0:
		end_time = new_duration
	time = 0
	done = false


func is_running() -> bool:
	return _is_running


func get_progress() -> float:
	if end_time <= 0:
		return 1.0 if done else 0.0
	return clamp(float(time) / float(end_time), 0.0, 1.0)


func _calc_ease(progress: float) -> float:
	match ease_type:
		EaseType.EASE_IN:
			return progress * progress
		EaseType.EASE_OUT:
			return 1.0 - (1.0 - progress) * (1.0 - progress)
		EaseType.EASE_IN_OUT:
			return 2.0 * progress * progress if progress < 0.5 else 1.0 - pow(-2.0 * progress + 2.0, 2.0) / 2.0
		EaseType.LINEAR:
			return progress
	return progress


func _complete_once() -> void:
	value = end_value
	done = true
	time = max(end_time, 0)
	_is_running = false

	if not loop:
		return

	if ping_pong:
		var temp: float = start_value
		start_value = end_value
		end_value = temp
		# 往返循环保持当前位置为新起点，从 0 重新计时。
		time = 0
		done = false
		_is_running = true
		value = start_value
		return

	# 普通循环：回到最初起点再播放。
	start_value = _origin_start
	value = start_value
	time = 0
	done = false
	_is_running = true
