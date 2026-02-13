extends RefCounted
class_name SceneLayoutSystem

const ENABLE_RUNTIME_LABEL_LAYOUT: bool = false

func apply_default_layout(refs: Dictionary, _animate: bool = false) -> void:
	if not ENABLE_RUNTIME_LABEL_LAYOUT:
		return
	_bind_label_to_anchor(refs, "wait_area_1", "local_wait_anchor")
	_bind_label_to_anchor(refs, "held_area_1", "local_held_anchor")
	_bind_label_to_anchor(refs, "wait_area_2", "remote_wait_anchor")
	_bind_label_to_anchor(refs, "held_area_2", "remote_held_anchor")

static func get_to_held_target(card: Card_Base, hand_index_1_based: int) -> Dictionary:
	var is_local: bool = card != null and global.local_player != null and card.team_id == global.local_player.team_id
	var jitter: float = float(hand_index_1_based) * HandLayoutConfig.TO_HELD_JITTER_STEP
	var target_pos: Vector3 = Vector3.ZERO
	var parent: Node = null
	if is_local:
		target_pos = Vector3(
			global.camera.global_position.x,
			global.camera.global_position.y - 0.6 + jitter,
			global.camera.global_position.z - 0.1 + jitter
		)
		parent = global.local_hand_anchor if global.local_hand_anchor != null else global.camera
	else:
		var remote_anchor: Node3D = global.remote_hand_anchor if global.remote_hand_anchor != null else global.multi_player_node
		target_pos = Vector3(
			remote_anchor.global_position.x,
			remote_anchor.global_position.y + jitter,
			remote_anchor.global_position.z + jitter
		)
		parent = global.remote_hand_anchor if global.remote_hand_anchor != null else global.multi_player_node
	return {
		"position": target_pos,
		"rotation": CardViewPolicy.get_to_held_rotation(card),
		"parent": parent,
		"duration": HandLayoutConfig.TO_HELD_DURATION
	}

static func calculate_held_layout(
	card: Card_Base,
	index: int,
	count: int,
	base_bottom_local_origin: Vector3,
	base_rot_origin: Vector3
) -> Dictionary:
	var center_index: float = float(count - 1) * 0.5
	var slot: float = float(index) - center_index
	var spread_scale: float = maxf(float(count) / 8.0, 1.0)
	var offset: float = HandLayoutConfig.FAN_CARD_SPACING / spread_scale
	var slot_denom: float = maxf(center_index, 1.0)
	var slot_norm: float = absf(slot) / slot_denom
	var arc_factor: float = 1.0 - clampf(slot_norm, 0.0, 1.0)
	var t: float = 0.5
	if count > 1:
		t = float(index) / float(count - 1)

	var fan_offset_sign: float = CardViewPolicy.get_fan_offset_sign(card)
	var fan_rotation_sign: float = CardViewPolicy.get_fan_rotation_sign(card)
	var bottom_local_pos: Vector3 = base_bottom_local_origin
	bottom_local_pos.x = base_bottom_local_origin.x + slot * offset * fan_offset_sign
	bottom_local_pos.y = base_bottom_local_origin.y + lerp(-HandLayoutConfig.FAN_EDGE_DROP, HandLayoutConfig.FAN_CENTER_RISE, arc_factor)

	var target_rot: Vector3 = base_rot_origin
	target_rot.x = CardViewPolicy.get_hand_tilt_x_rad(card)
	var angle_deg: float = lerp(-HandLayoutConfig.FAN_SPREAD_DEG * 0.5, HandLayoutConfig.FAN_SPREAD_DEG * 0.5, t)
	var angle_rad: float = deg_to_rad(angle_deg)
	target_rot.z = -angle_rad * fan_rotation_sign

	var half_height: float = get_half_height(card)
	var new_up: Vector3 = Basis.from_euler(target_rot).y.normalized()
	var local_pos: Vector3 = bottom_local_pos + new_up * half_height
	return {
		"local_pos": local_pos,
		"bottom_local_pos": bottom_local_pos,
		"rotation": target_rot,
		"global_pos": to_parent_global(card, local_pos)
	}

static func get_bottom_anchor_pos(card: Card_Base, center_pos: Vector3, basis: Basis) -> Vector3:
	return center_pos - basis.y.normalized() * get_half_height(card)

static func to_parent_global(card: Card_Base, local_pos: Vector3) -> Vector3:
	if card == null:
		return local_pos
	var parent: Node3D = card.get_parent() as Node3D
	if parent == null:
		return local_pos
	return parent.to_global(local_pos)

static func get_half_height(card: Card_Base) -> float:
	if card == null or card.texture == null:
		return 0.0
	return card.texture.get_size().y * card.pixel_size * card.scale.y * 0.5

func _bind_label_to_anchor(refs: Dictionary, label_key: String, anchor_key: String) -> void:
	var label: Label3D = refs.get(label_key) as Label3D
	var anchor: Node3D = refs.get(anchor_key) as Node3D
	if label == null or anchor == null:
		return
	label.global_position = anchor.global_position
