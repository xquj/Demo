class_name SceneRefs

var cards_number_label: Label3D = null
var showing_area_label: Label3D = null
var wait_area1_label: Label3D = null
var wait_area2_label: Label3D = null
var held_area1_label: Label3D = null
var held_area2_label: Label3D = null
var discard_pile: Sprite3D = null
var deck: Sprite3D = null
var camera: Camera3D = null
var local_hand_anchor: Node3D = null
var remote_hand_anchor: Node3D = null
var local_wait_anchor: Node3D = null
var local_held_anchor: Node3D = null
var remote_wait_anchor: Node3D = null
var remote_held_anchor: Node3D = null
var local_player_node: Node3D = null
var multi_player_node: Node3D = null
var cube_desk: MeshInstance3D = null
var camera_controller: CameraController = null
var cube_rot_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)
var game_sense: GameScene3D = null
var event_bus: EventBus = EventBus.new()
