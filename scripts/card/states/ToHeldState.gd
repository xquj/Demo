extends State
class_name ToHeldState

func enter() -> void:
	super.enter()
	card.player.hand_cards.push_back(card)
	# 位置初始化：根据所属玩家计算手牌落点。
	var idx = card.player.hand_cards.find(card) + 1

	var hand_node: Node3D = _get_hand_node()
	if hand_node != null:
		card.reparent(hand_node)
	else:
		hand_node = card.get_parent() as Node3D
	if hand_node == null:
		return

	var target_pos: Vector3
	var target_rot: Vector3

	if card.team_id == global.local_player.team_id:
		target_rot = Vector3(deg_to_rad(-15), 0.0, 0.0)
		target_pos = hand_node.to_global(Vector3(0.0, idx * 0.001, 0.0))
	else:
		target_pos = hand_node.to_global(Vector3(0.0, idx * 0.001, 0.0))
		target_rot = Vector3(deg_to_rad(-135), deg_to_rad(180), 0.0)
	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2, target_pos.y, (card.start_pos.z + target_pos.z) / 2), target_rot, 0.2)

func _get_hand_node() -> Node3D:
	if card.team_id == global.local_player.team_id:
		return global.local_hand_node
	return global.enemy_hand_node

func exit() -> void:
	super.exit()
	if card.player.waitingGroup.has(card):
		card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(load("res://scripts/card/states/HeldState.gd"))


func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
