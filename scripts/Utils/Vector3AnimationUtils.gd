extends Object
class_name Vector3AnimationUtils

var time: int = 0
var end_time: int = 500
var value: Vector3 = Vector3.ZERO
var start_value: Vector3 = Vector3.ZERO
var end_value: Vector3 = Vector3.ONE
var done: bool = false

@export var ease_type: EaseType = EaseType.LINEAR
@export var auto_calc: bool = true
@export var loop: bool = false
@export var ping_pong: bool = false

enum EaseType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT
}

var _is_running: bool = false
var _origin_start: Vector3 = Vector3.ZERO


func _init(_start: Vector3 = Vector3.ZERO, _end: Vector3 = Vector3.ONE, _duration: int = 500, _ease: EaseType = EaseType.LINEAR) -> void:
	start_value = _start
	end_value = _end
	end_time = _duration
	ease_type = _ease
	_origin_start = _start
	value = _start
	time = 0
	done = end_time <= 0 and start_value.is_equal_approx(end_value)


func update(delta: float) -> void:
	if not _is_running or done or not auto_calc:
		return

	if end_time <= 0:
		_complete_once()
		return

	time += int(delta * 1000.0)
	if time >= end_time:
		_complete_once()
		return

	var p: float = _calc_ease(float(time) / float(end_time))
	value = start_value.lerp(end_value, p)


func calc_by_progress(progress: float) -> Vector3:
	var p: float = clamp(progress, 0.0, 1.0)
	var eased: float = _calc_ease(p)
	value = start_value.lerp(end_value, eased)
	time = int(float(end_time) * p)
	done = p >= 1.0
	if done:
		_is_running = false
	return value


func play(resume_from_current: bool = false) -> void:
	if not resume_from_current or done:
		time = 0
		done = false
		value = start_value

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


func reset() -> void:
	time = 0
	done = false
	_is_running = false
	start_value = _origin_start
	value = start_value


func set_target(new_end_value: Vector3, new_duration: int = -1) -> void:
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
		_:
			return progress


func _complete_once() -> void:
	value = end_value
	done = true
	time = max(end_time, 0)
	_is_running = false

	if not loop:
		return

	if ping_pong:
		var temp: Vector3 = start_value
		start_value = end_value
		end_value = temp
		time = 0
		done = false
		_is_running = true
		value = start_value
		return

	start_value = _origin_start
	value = start_value
	time = 0
	done = false
	_is_running = true
