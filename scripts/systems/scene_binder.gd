extends RefCounted
class_name SceneBinder

const PATH_DECK: NodePath = ^"Scene3D/Desk/Piles/Deck"
const PATH_DISCARD_PILE: NodePath = ^"Scene3D/Desk/Piles/DiscardPile"
const PATH_CUBE_DESK: NodePath = ^"Scene3D/Desk"
const PATH_CARDS_NUMBER: NodePath = ^"Scene3D/Desk/Zones/HeldArea1/CardsNumber"
const PATH_SHOWING_AREA: NodePath = ^"Scene3D/Desk/Zones/ShowArea"
const PATH_WAIT_AREA_1: NodePath = ^"Scene3D/Desk/Zones/WaitArea1"
const PATH_WAIT_AREA_2: NodePath = ^"Scene3D/Desk/Zones/WaitArea2"
const PATH_HELD_AREA_1: NodePath = ^"Scene3D/Desk/Zones/HeldArea1"
const PATH_HELD_AREA_2: NodePath = ^"Scene3D/Desk/Zones/HeldArea2"
const PATH_END_WAITING: NodePath = ^"Scene3D/Desk/Interactive/EndWaiting"
const PATH_END_COMBO: NodePath = ^"Scene3D/Desk/Interactive/EndCombo"
const PATH_MULTI_PLAYER: NodePath = ^"MultiPlayer"
const PATH_LOCAL_PLAYER: NodePath = ^"LocalPlayer"
const PATH_CAMERA: NodePath = ^"LocalPlayer/CameraRig/Camera3D"
const PATH_HAND_ANCHOR: NodePath = ^"LocalPlayer/CameraRig/Hand"
const PATH_REMOTE_HAND_ANCHOR: NodePath = ^"MultiPlayer/Hand"
const PATH_SPRING_ARM: NodePath = ^"LocalPlayer/CameraRig"
const PATH_LOCAL_WAIT_ANCHOR: NodePath = ^"LocalPlayer/BoardAnchor/WaitAnchor"
const PATH_LOCAL_HELD_ANCHOR: NodePath = ^"LocalPlayer/BoardAnchor/HeldAnchor"
const PATH_REMOTE_WAIT_ANCHOR: NodePath = ^"MultiPlayer/BoardAnchor/WaitAnchor"
const PATH_REMOTE_HELD_ANCHOR: NodePath = ^"MultiPlayer/BoardAnchor/HeldAnchor"

func bind_global_references(root: Node) -> void:
	global.deck = _get_required_node(root, PATH_DECK) as Sprite3D
	global.discard_pile = _get_required_node(root, PATH_DISCARD_PILE) as Sprite3D
	global.cube_desk = _get_required_node(root, PATH_CUBE_DESK) as MeshInstance3D
	global.cards_number_label = _get_required_node(root, PATH_CARDS_NUMBER) as Label3D
	global.showing_area_label = _get_required_node(root, PATH_SHOWING_AREA) as Label3D
	global.wait_area1_label = _get_required_node(root, PATH_WAIT_AREA_1) as Label3D
	global.wait_area2_label = _get_required_node(root, PATH_WAIT_AREA_2) as Label3D
	global.held_area1_label = _get_required_node(root, PATH_HELD_AREA_1) as Label3D
	global.held_area2_label = _get_required_node(root, PATH_HELD_AREA_2) as Label3D
	global.local_player_node = _get_required_node(root, PATH_LOCAL_PLAYER) as Node3D
	global.multi_player_node = _get_required_node(root, PATH_MULTI_PLAYER) as Node3D
	global.camera = _get_required_node(root, PATH_CAMERA) as Camera3D
	global.local_hand_anchor = _get_required_node(root, PATH_HAND_ANCHOR) as Node3D
	global.remote_hand_anchor = _get_required_node(root, PATH_REMOTE_HAND_ANCHOR) as Node3D
	global.local_wait_anchor = _get_required_node(root, PATH_LOCAL_WAIT_ANCHOR) as Node3D
	global.local_held_anchor = _get_required_node(root, PATH_LOCAL_HELD_ANCHOR) as Node3D
	global.remote_wait_anchor = _get_required_node(root, PATH_REMOTE_WAIT_ANCHOR) as Node3D
	global.remote_held_anchor = _get_required_node(root, PATH_REMOTE_HELD_ANCHOR) as Node3D
	var spring_arm: SpringArm3D = _get_required_node(root, PATH_SPRING_ARM) as SpringArm3D
	if spring_arm != null and global.camera != null:
		global.camera_controller = CameraController.new(spring_arm, global.camera)

func create_layout_refs(root: Node) -> Dictionary:
	return {
		"wait_area_1": _get_required_node(root, PATH_WAIT_AREA_1) as Label3D,
		"wait_area_2": _get_required_node(root, PATH_WAIT_AREA_2) as Label3D,
		"show_area": _get_required_node(root, PATH_SHOWING_AREA) as Label3D,
		"held_area_1": _get_required_node(root, PATH_HELD_AREA_1) as Label3D,
		"held_area_2": _get_required_node(root, PATH_HELD_AREA_2) as Label3D,
		"cards_number": _get_required_node(root, PATH_CARDS_NUMBER) as Label3D,
		"end_waiting": _get_required_node(root, PATH_END_WAITING) as MeshInstance3D,
		"end_combo": _get_required_node(root, PATH_END_COMBO) as MeshInstance3D,
		"local_wait_anchor": _get_required_node(root, PATH_LOCAL_WAIT_ANCHOR) as Node3D,
		"local_held_anchor": _get_required_node(root, PATH_LOCAL_HELD_ANCHOR) as Node3D,
		"remote_wait_anchor": _get_required_node(root, PATH_REMOTE_WAIT_ANCHOR) as Node3D,
		"remote_held_anchor": _get_required_node(root, PATH_REMOTE_HELD_ANCHOR) as Node3D
	}

func _get_required_node(root: Node, path: NodePath) -> Node:
	var node: Node = root.get_node_or_null(path)
	if node == null:
		push_error("SceneBinder: missing required node: %s" % String(path))
	return node
