extends Object
class_name ColorAnimationUtils

# 核心公共属性（与AnimationUtils保持一致，易记忆）
var time: int = 0          # 已运行时间（毫秒）
var end_time: int = 500    # 动画总时长（毫秒，默认500ms）
var done: bool = false     # 动画是否完成
var value: Color = Color.WHITE # 动画当前颜色值（实时更新，外部直接读取）

# 颜色动画专属配置
var start_color: Color = Color.WHITE # 起始颜色（默认白色）
var end_color: Color = Color.WHITE   # 目标颜色（默认白色）
@export var ease_type: EaseType = EaseType.LINEAR # 缓动类型
@export var loop: bool = false                    # 是否循环播放
@export var ping_pong: bool = false               # 是否乒乓循环（颜色互切）

# 缓动类型枚举（与AnimationUtils一致，统一规范）
enum EaseType {
	LINEAR,        # 线性匀速
	EASE_IN,       # 先慢后快
	EASE_OUT,      # 先快后慢（推荐UI）
	EASE_IN_OUT    # 先慢后快再慢（推荐平滑渐变）
}

# 私有状态变量
var _is_running: bool = false # 动画是否运行
var _temp_start: Color = Color.WHITE # 临时保存初始起始颜色

# 构造方法：快速初始化颜色动画参数（直接传起始/目标颜色，易用性拉满）
# 参数：起始颜色, 目标颜色, 总时长(毫秒), 缓动类型
func _init(_start: Color = Color.WHITE, _end: Color = Color.WHITE, _duration: int = 500, _ease: EaseType = EaseType.LINEAR) -> void:
	start_color = _start
	end_color = _end
	end_time = _duration
	ease_type = _ease
	_temp_start = start_color
	reset() # 初始化后重置状态

# 核心：逐帧更新动画（与AnimationUtils/Godot _process(delta)完全兼容）
func update(delta: float) -> void:
	if not _is_running or done:
		return
	# 优化：直接累加毫秒时间，避免重复类型转换
	time += int(delta * 1000.0)
	
	# 优化：提前判断完成状态，避免不必要的计算
	var progress: float
	if time >= end_time:
		progress = 1.0
		value = end_color
		_on_animation_complete()
		return
	else:
		progress = float(time) / float(end_time)
	
	# 应用缓动曲线
	progress = _calc_ease(progress)
	
	# 核心：RGB+透明度 四通道插值计算当前颜色（优化：使用lerp一次性计算）
	value = start_color.lerp(end_color, progress)

# 手动按进度计算颜色（0~1，适配滚动条/滑动面板等非时间驱动场景）
func calc_by_progress(progress: float) -> Color:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	clamped_progress = _calc_ease(clamped_progress)
	# 优化：使用Color.lerp一次性计算，更高效
	value = start_color.lerp(end_color, clamped_progress)
	done = clamped_progress >= 1.0
	return value

# 启动动画（resume_from_current=true：从当前颜色继续，false：重置后启动）
func play(resume_from_current: bool = false) -> void:
	if not resume_from_current:
		reset()
	done = false
	_is_running = true

# 暂停动画（保留当前颜色/时间/进度）
func pause() -> void:
	_is_running = false

# 停止动画（强制完成，直接应用目标颜色）
func stop(apply_end_value: bool = true) -> void:
	_is_running = false
	done = true
	if apply_end_value:
		value = end_color
	time = end_time

# 重置动画（恢复初始颜色/时间，done=false）
func reset() -> void:
	time = 0
	done = false
	_is_running = false
	start_color = _temp_start
	value = start_color # 重置当前颜色为起始颜色

# 动态修改目标颜色（从当前颜色无缝插值到新颜色，无需重置）
# 参数：新目标颜色, 新时长(毫秒，-1则使用原时长)
func set_target(new_end: Color, new_duration: int = -1) -> void:
	start_color = value # 起始颜色设为当前颜色
	end_color = new_end
	if new_duration > 0:
		end_time = new_duration
	time = 0
	done = false
	if _is_running:
		_is_running = true

# 私有：计算缓动曲线（与AnimationUtils完全一致，保证动画效果统一）
func _calc_ease(progress: float) -> float:
	match ease_type:
		EaseType.EASE_IN:
			return progress * progress
		EaseType.EASE_OUT:
			return 1.0 - (1.0 - progress) * (1.0 - progress)
		EaseType.EASE_IN_OUT:
			return 2 * progress * progress if progress < 0.5 else 1.0 - pow(-2 * progress + 2, 2) / 2
		EaseType.LINEAR:
			pass
	return progress

# 私有：动画完成回调（处理循环/乒乓循环，颜色互切）
func _on_animation_complete() -> void:
	done = true
	_is_running = false
	value = end_color # 强制设为目标颜色，避免插值精度误差
	
	# 乒乓循环：交换起始/目标颜色，反向渐变
	if ping_pong and loop:
		var temp: Color = start_color
		start_color = end_color
		end_color = temp
		play(true) # 从当前状态继续播放
	# 普通循环：重置后重新播放
	elif loop and not ping_pong:
		play(false)
