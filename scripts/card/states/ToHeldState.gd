extends State
class_name ToHeldState

func enter() -> void:
	super.enter()
	card.player.hand_cards.push_back(card)
	var idx = card.player.hand_cards.find(card) + 1

	var target_pos: Vector3
	var target_rot: Vector3
	var is_local: bool = card.team_id == global.local_player.team_id

	if is_local:
		target_rot = Vector3(deg_to_rad(-15.0), 0.0, 0.0)
		target_pos = Vector3(global.camera.global_position.x, global.camera.global_position.y - 0.6 + idx * 0.001, global.camera.global_position.z - 0.1 + idx * 0.001)
		var local_parent: Node = global.local_hand_anchor if global.local_hand_anchor != null else global.camera
		card.reparent(local_parent)
	else:
		var remote_anchor: Node3D = global.remote_hand_anchor if global.remote_hand_anchor != null else global.multi_player_node
		target_pos = Vector3(remote_anchor.global_position.x, remote_anchor.global_position.y + idx * 0.001, remote_anchor.global_position.z + idx * 0.001)
		target_rot = Vector3(deg_to_rad(-125.0), deg_to_rad(180.0), 0.0)
		var remote_parent: Node = global.remote_hand_anchor if global.remote_hand_anchor != null else global.multi_player_node
		card.reparent(remote_parent)
	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2,target_pos.y,(card.start_pos.z + target_pos.z) / 2),target_rot,0.2)

func exit() -> void:
	super.exit()
	if card.player.waitingGroup.has(card):
		card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))

func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(load("res://scripts/card/states/HeldState.gd"))

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
