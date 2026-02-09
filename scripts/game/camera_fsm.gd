extends Node3D
class_name CameraFSM

enum CameraState {
	BASE,
	PUSH_IN,
	CARD_CLOSEUP,
	SCALE_FOCUS,
	DAMAGE_TILT,
	TURN_PULLBACK
}

@export var base_position := Vector3(0, 2.2, 4.8)
@export var base_rotation := Vector3(deg_to_rad(-25), 0, 0)
@export var push_in_position := Vector3(0, 2.0, 4.0)
@export var push_in_rotation := Vector3(deg_to_rad(-30), 0, 0)
@export var card_closeup_position := Vector3(0, 1.6, 3.2)
@export var card_closeup_rotation := Vector3(deg_to_rad(-20), 0, 0)
@export var scale_focus_position := Vector3(0, 2.5, 3.6)
@export var scale_focus_rotation := Vector3(deg_to_rad(-35), 0, 0)
@export var damage_tilt_rotation := Vector3(deg_to_rad(-25), 0, deg_to_rad(2))
@export var turn_pullback_position := Vector3(0, 2.6, 5.5)
@export var turn_pullback_rotation := Vector3(deg_to_rad(-28), 0, 0)

@export var transition_time := 0.4
@export var ease_type := Tween.EASE_OUT
@export var trans_type := Tween.TRANS_QUAD

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var current_state: CameraState = CameraState.BASE
var tween: Tween

func _ready() -> void:
	if pivot == null or camera == null:
		push_warning("Camera rig missing pivot or camera; camera FSM will fallback.")
		return
	_apply_state(CameraState.BASE, true)

func go_to_state(state: CameraState) -> void:
	_apply_state(state, false)

func _apply_state(state: CameraState, instant: bool) -> void:
	current_state = state
	if pivot == null:
		return
	var target_pos := base_position
	var target_rot := base_rotation
	match state:
		CameraState.BASE:
			target_pos = base_position
			target_rot = base_rotation
		CameraState.PUSH_IN:
			target_pos = push_in_position
			target_rot = push_in_rotation
		CameraState.CARD_CLOSEUP:
			target_pos = card_closeup_position
			target_rot = card_closeup_rotation
		CameraState.SCALE_FOCUS:
			target_pos = scale_focus_position
			target_rot = scale_focus_rotation
		CameraState.DAMAGE_TILT:
			target_pos = base_position
			target_rot = damage_tilt_rotation
		CameraState.TURN_PULLBACK:
			target_pos = turn_pullback_position
			target_rot = turn_pullback_rotation

	if tween:
		tween.kill()
	if instant:
		global_position = target_pos
		pivot.rotation = target_rot
		return
	tween = create_tween()
	tween.set_trans(trans_type).set_ease(ease_type)
	tween.parallel().tween_property(self, "global_position", target_pos, transition_time)
	tween.parallel().tween_property(pivot, "rotation", target_rot, transition_time)
