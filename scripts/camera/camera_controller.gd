class_name CameraController
extends RefCounted

# ====================【相机状态机（可扩展）】====================
# 目标：
# 1) 用“状态”驱动相机，而不是在业务层散落 set_target。
# 2) 将镜头参数集中配置，方便后期新增状态（如：抽卡特写、结算特写）。
# 3) 提供“邪恶冥刻风格”的轻微动态摇摆，让镜头转动更有生命感。

enum CameraState {
	HAND,   # 手牌近景（玩家操作主视角）
	BOARD   # 桌面远景（回合切换/观察全局）
}

# 默认过渡时间（毫秒）
const DEFAULT_DURATION_MS: int = 220

# 邪恶冥刻风格：镜头在稳定阶段有细微呼吸/摇摆。
const SWAY_SPEED: float = 1.35
const SWAY_YAW_DEG: float = 0.7
const SWAY_ROLL_DEG: float = 0.45
const SWAY_PITCH_DEG: float = 0.25

# 相机预设参数结构：长度 + 欧拉角(度)
# 约定：
# - x = pitch（俯仰）
# - y = yaw（左右偏航）
# - z = roll（倾斜）
const PRESET_HAND := {
	"length": 1.0,
	"rot_x": 45.0,
	"rot_y": 0.0,
	"rot_z": 0.0,
}

# BOARD 视角略微侧偏+轻微倾斜，营造“邪恶冥刻”式桌面对视感。
const PRESET_BOARD := {
	"length": 3.0,
	"rot_x": 6.0,
	"rot_y": -7.0,
	"rot_z": 2.2,
}

# ====================【内部动画通道】====================
# 四个通道独立插值：长度、俯仰、偏航、倾斜。
var _spring_length_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)
var _rot_x_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)
var _rot_y_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)
var _rot_z_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)

# 当前状态/目标状态。
var _current_state: CameraState = CameraState.HAND
var _target_state: CameraState = CameraState.HAND

# 运行时参数（用于动态摇摆）。
var _time_acc: float = 0.0

# 初始化控制器（场景 ready 时调用一次）。
func initialize(initial_state: CameraState = CameraState.HAND, duration_ms: int = 500) -> void:
	_current_state = initial_state
	_target_state = initial_state
	_time_acc = 0.0

	var preset := _get_preset(initial_state)
	_spring_length_animation = AnimationUtils.new(preset["length"], preset["length"], duration_ms)
	_rot_x_animation = AnimationUtils.new(preset["rot_x"], preset["rot_x"], duration_ms)
	_rot_y_animation = AnimationUtils.new(preset["rot_y"], preset["rot_y"], duration_ms)
	_rot_z_animation = AnimationUtils.new(preset["rot_z"], preset["rot_z"], duration_ms)

	_spring_length_animation.play(true)
	_rot_x_animation.play(true)
	_rot_y_animation.play(true)
	_rot_z_animation.play(true)

# 每帧更新：
# 1) 先更新所有插值通道
# 2) 若稳定到目标，则确认当前状态
func update(delta: float) -> void:
	_time_acc += delta

	_spring_length_animation.update(delta)
	_rot_x_animation.update(delta)
	_rot_y_animation.update(delta)
	_rot_z_animation.update(delta)

	if is_pose_stable():
		_current_state = _target_state

# 将当前姿态应用到 SpringArm。
# 注意：
# - 主通道来自动画器
# - 稳态阶段叠加轻微摇摆（sway），让镜头不“死板”
func apply_to_spring_arm(spring_arm: SpringArm3D) -> void:
	if spring_arm == null:
		return

	var pitch_deg: float = _rot_x_animation.value
	var yaw_deg: float = _rot_y_animation.value
	var roll_deg: float = _rot_z_animation.value

	# 仅在姿态稳定时加入细微动态，避免过渡期叠加导致视觉噪声。
	if is_pose_stable():
		var sway_weight: float = _get_sway_weight(_current_state)
		if sway_weight > 0.0:
			pitch_deg += sin(_time_acc * SWAY_SPEED) * SWAY_PITCH_DEG * sway_weight
			yaw_deg += sin(_time_acc * SWAY_SPEED * 0.85) * SWAY_YAW_DEG * sway_weight
			roll_deg += cos(_time_acc * SWAY_SPEED * 0.65) * SWAY_ROLL_DEG * sway_weight

	spring_arm.spring_length = _spring_length_animation.value
	spring_arm.rotation = Vector3(
		deg_to_rad(pitch_deg),
		deg_to_rad(yaw_deg),
		deg_to_rad(roll_deg)
	)

# ====================【状态机 API（推荐业务层调用）】====================

# 请求切换到指定状态。
# force=true 可强制重新触发动画（用于希望重复播放镜头动作的场景）。
func request_state(next_state: CameraState, duration_ms: int = DEFAULT_DURATION_MS, force: bool = false) -> void:
	if !force and _target_state == next_state:
		return
	_target_state = next_state
	_apply_preset(_get_preset(next_state), duration_ms)

# 如果当前镜头已稳定且不在目标状态，则触发状态切换。
# 用于“只在必要时切换”，减少重复调用开销。
func ensure_state(next_state: CameraState, duration_ms: int = DEFAULT_DURATION_MS) -> void:
	if _target_state == next_state:
		return
	if is_pose_stable():
		request_state(next_state, duration_ms)

# 兼容旧接口：回到手牌视角。
func focus_hand(duration_ms: int = DEFAULT_DURATION_MS) -> void:
	request_state(CameraState.HAND, duration_ms)

# 兼容旧接口：切到桌面视角。
func focus_board(duration_ms: int = DEFAULT_DURATION_MS) -> void:
	request_state(CameraState.BOARD, duration_ms)

# 兼容旧接口：若目前是桌面目标，则回手牌。
func ensure_hand_length(duration_ms: int = DEFAULT_DURATION_MS) -> void:
	ensure_state(CameraState.HAND, duration_ms)

# 通用参数设置（保留给特殊镜头）。
# 建议仅用于临时演出镜头，主流程优先使用状态机接口。
func set_target(length: float, rot_x_deg: float, duration_ms: int = DEFAULT_DURATION_MS, rot_y_deg: float = 0.0, rot_z_deg: float = 0.0) -> void:
	_spring_length_animation.set_target(length, duration_ms)
	_spring_length_animation.play(true)
	_rot_x_animation.set_target(rot_x_deg, duration_ms)
	_rot_x_animation.play(true)
	_rot_y_animation.set_target(rot_y_deg, duration_ms)
	_rot_y_animation.play(true)
	_rot_z_animation.set_target(rot_z_deg, duration_ms)
	_rot_z_animation.play(true)

# 旋转是否稳定（供交互层判定，如卡牌 hover）。
func is_rot_stable() -> bool:
	return _rot_x_animation.done and _rot_y_animation.done and _rot_z_animation.done

# 姿态是否稳定（长度 + 全旋转）。
func is_pose_stable() -> bool:
	return _spring_length_animation.done and is_rot_stable()

func get_current_state() -> CameraState:
	return _current_state

func get_target_state() -> CameraState:
	return _target_state

# ====================【内部工具】====================

func _apply_preset(preset: Dictionary, duration_ms: int) -> void:
	set_target(
		preset["length"],
		preset["rot_x"],
		duration_ms,
		preset["rot_y"],
		preset["rot_z"]
	)

func _get_preset(state: CameraState) -> Dictionary:
	match state:
		CameraState.BOARD:
			return PRESET_BOARD
		_:
			return PRESET_HAND

# 不同状态可配置不同摇摆强度。
func _get_sway_weight(state: CameraState) -> float:
	match state:
		CameraState.BOARD:
			return 1.0   # 桌面观察时摇摆更明显
		CameraState.HAND:
			return 0.45  # 手牌操作时更克制，避免影响交互
		_:
			return 0.0
