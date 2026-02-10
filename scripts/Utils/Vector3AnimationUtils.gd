extends Object
class_name Vector3AnimationUtils

# 你指定的核心成员变量（严格保留，补充类型注解和注释）
var time: int = 0          # 已运行时间（毫秒，与end_time单位一致）
var end_time: int = 500    # 动画总时长（毫秒，默认500ms，可自定义）
var value: Vector3         # 动画当前计算结果值（实时更新，外部直接读取）
var start_value: Vector3   # 动画起始值
var end_value: Vector3     # 动画目标值
var done: bool = false     # 动画是否完成（完成后停止计算，外部可判断状态）

# 扩展可选配置（提升实用性，编辑器/代码可灵活修改）
@export var ease_type: EaseType = EaseType.LINEAR # 插值缓动类型
@export var auto_calc: bool = true                # 是否自动随时间计算（关闭则手动调用calc_by_progress）
@export var loop: bool = false                    # 是否循环播放
@export var ping_pong: bool = false               # 是否乒乓循环（到达目标后反向插值）

# 缓动类型枚举（覆盖常用场景，线性/先慢后快/先快后慢/先慢后快再慢）
enum EaseType {
	LINEAR,        # 线性插值（匀速，默认）
	EASE_IN,       # 缓入（先慢后快）
	EASE_OUT,      # 缓出（先快后慢，推荐UI动画）
	EASE_IN_OUT    # 缓入缓出（先慢后快再慢，推荐平滑动画）
}

# 私有状态变量（辅助动画逻辑，外部无需操作）
var _is_running: bool = false # 动画是否正在运行
var _is_reverse: bool = false # 乒乓循环是否处于反向状态
var _temp_start: Vector3 = Vector3(0.0,0.0,0.0)  # 临时保存起始值（乒乓循环/重置用）

# 构造方法（可选，快速初始化动画参数）
func _init(_start: Vector3 = Vector3(0.0,0.0,0.0), _end: Vector3 = Vector3(1.0,1.0,1.0), _duration: int = 500, _ease: EaseType = EaseType.LINEAR) -> void:
	start_value = _start
	end_value = _end
	end_time = _duration
	ease_type = _ease
	_temp_start = start_value
	reset() # 初始化后重置状态

# 核心：逐帧更新动画（传入delta时间，单位：秒，与Godot _process(delta)兼容）
# 外部调用：在节点的_process(delta)中调用，即可自动更新value
func update(delta: float) -> void:
	# 非运行中/已完成，直接返回
	if not _is_running or done:
		return
	
	# 优化：直接累加毫秒时间，避免重复类型转换
	time += int(delta * 1000.0)
	# 优化：缓存end_time的倒数，避免重复除法（但这里end_time可能变化，所以保留原逻辑）
	var progress: float
	if time >= end_time:
		progress = 1.0
		value = end_value
		_on_animation_complete()
		return
	else:
		progress = float(time) / float(end_time)
	
	# 应用缓动曲线，优化插值效果
	progress = _calc_ease(progress)
	
	# 核心插值计算：根据起始/目标值，计算当前value
	value = lerp(start_value, end_value, progress)

# 手动通过进度计算value（0~1，适用于非时间驱动的动画，如滚动条联动）
func calc_by_progress(progress: float) -> Vector3:
	var clamped_progress: float = clamp(progress, 0.0, 1.0) # 限制进度0~1，防止越界
	clamped_progress = _calc_ease(clamped_progress)
	value = lerp(start_value, end_value, clamped_progress)
	done = clamped_progress >= 1.0
	return value

# 启动动画（重置状态并开始运行，可指定是否从当前value继续）
func play(resume_from_current: bool = false) -> void:
	if not resume_from_current:
		reset() # 非继续播放则重置所有状态
	done = false
	_is_running = true

# 暂停动画（保留当前状态，调用play(true)可继续）
func pause() -> void:
	_is_running = false

# 停止动画（强制完成，value直接设为目标值，done=true）
func stop(apply_end_value: bool = true) -> void:
	_is_running = false
	done = true
	if apply_end_value:
		value = end_value
	time = end_time # 同步已运行时间为总时长

# 重置动画（恢复初始状态，所有属性回归默认，done=false）
func reset() -> void:
	time = 0
	done = false
	_is_running = false
	_is_reverse = false
	start_value = _temp_start # 恢复初始起始值
	value = start_value # 当前值回归起始值

# 重新设置动画目标值（无需重置，从当前value向新目标值插值）
func set_target(new_end_value: Vector3, new_duration: int = -1) -> void:
	start_value = value # 起始值设为当前value
	end_value = new_end_value
	if new_duration > 0:
		end_time = new_duration
	time = 0 # 重置已运行时间，重新开始插值
	done = false
	if _is_running:
		_is_running = true # 保持运行状态

# 私有：计算缓动曲线（将0~1的线性进度转换为缓动进度）
func _calc_ease(progress: float) -> float:
	match ease_type:
		EaseType.EASE_IN:
			return progress * progress # 二次方缓入
		EaseType.EASE_OUT:
			return 1.0 - (1.0 - progress) * (1.0 - progress) # 二次方缓出
		EaseType.EASE_IN_OUT:
			# 缓入缓出：前半段缓入，后半段缓出
			return 2 * progress * progress if progress < 0.5 else 1.0 - pow(-2 * progress + 2, 2) / 2
		EaseType.LINEAR:
			pass # 线性：直接返回原进度
	return progress

# 私有：动画完成回调（处理循环/乒乓循环/状态更新）
func _on_animation_complete() -> void:
	done = true
	_is_running = false
	value = end_value # 强制设为目标值，避免精度问题
	
	# 处理乒乓循环
	if ping_pong and loop:
		_is_reverse = !_is_reverse
		# 交换起始/目标值，实现反向插值
		var temp: Vector3 = start_value
		start_value = end_value
		end_value = temp
		play(true) # 从当前状态继续播放
	# 处理普通循环
	elif loop and not ping_pong:
		play(false) # 重置并重新播放
