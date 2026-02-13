extends RefCounted
class_name BattlePresenter

const HAND_CARDS_MAX: int = 14

func update_camera_and_animations(delta: float) -> void:
	if global.cube_desk != null:
		global.cube_desk.global_rotation.z = deg_to_rad(global.cube_rot_animation.value)
	if global.camera_controller != null:
		global.camera_controller._update(delta)
	if global.cube_rot_animation != null:
		global.cube_rot_animation.update(delta)

func update_hand_count_label() -> void:
	var hand_size: int = 0
	if global.local_player != null:
		hand_size = global.local_player.hand_cards.size()
	if global.cards_number_label != null:
		global.cards_number_label.text = "(%s/%s)" % [str(hand_size), str(HAND_CARDS_MAX)]
