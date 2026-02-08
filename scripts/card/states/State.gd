extends Node
class_name State

var card: Card_Base

# 抛物线高度（可按状态调）
var parabola_height: float = 0.5

func _init(card_: Card_Base) -> void:
	card = card_

func _input(event: InputEvent) -> void:
	pass
	
func _process(delta: float) -> void:
	if card.moving_ablity:
		card.elapsed = minf(card.elapsed + delta, card.duration)
		var t: float = card.elapsed / card.duration

		# X / Z 线性插值
		card.global_position.x = lerp(card.global_position.x, card.target_pos.x, t)
		card.global_position.z = lerp(card.global_position.z, card.target_pos.z, t)

		# Y 轴：线性 + 抛物线
		var base_y: float= lerp(card.global_position.y, card.target_pos.y, t)
		var parabola: float= parabola_height * 4.0 * t * (1.0 - t)
		card.global_position.y = base_y + parabola

		# 到达终点
		if t >= 1.0:
			card.global_position = card.target_pos
			card.moving_ablity = false

func _ready() -> void:
	pass
	
# ===================== 启动移动 =====================
func _move(target_pos: Vector3, duration: float, height: float = 0.5) -> void:
	card.target_pos = target_pos
	card.duration = maxf(duration, 0.001)
	card.elapsed = 0.0
	card.moving_ablity = true
	parabola_height = height
