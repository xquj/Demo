extends RefCounted
class_name CardViewPolicy

static func is_local_owned_card(card: Card_Base) -> bool:
	return card != null and card.player != null and global.local_player != null and card.player == global.local_player

static func get_hand_tilt_x_rad(card: Card_Base) -> float:
	if card == null or global.local_player == null:
		return deg_to_rad(HandLayoutConfig.LOCAL_TILT_X_DEG)
	return deg_to_rad(HandLayoutConfig.LOCAL_TILT_X_DEG) if card.team_id == global.local_player.team_id else deg_to_rad(HandLayoutConfig.REMOTE_TILT_X_DEG)

static func get_to_held_rotation(card: Card_Base) -> Vector3:
	if card == null or global.local_player == null:
		return Vector3(deg_to_rad(HandLayoutConfig.LOCAL_TILT_X_DEG), 0.0, 0.0)
	var is_local: bool = card.team_id == global.local_player.team_id
	if is_local:
		return Vector3(deg_to_rad(HandLayoutConfig.LOCAL_TILT_X_DEG), 0.0, 0.0)
	return Vector3(
		deg_to_rad(HandLayoutConfig.REMOTE_TILT_X_DEG),
		deg_to_rad(HandLayoutConfig.REMOTE_YAW_DEG),
		0.0
	)

static func get_fan_offset_sign(card: Card_Base) -> float:
	if card == null or global.local_player == null:
		return 1.0
	return 1.0 if card.team_id == global.local_player.team_id else -1.0

static func get_fan_rotation_sign(_card: Card_Base) -> float:
	return 1.0

static func should_show_interaction_area(card: Card_Base) -> bool:
	return is_local_owned_card(card)
