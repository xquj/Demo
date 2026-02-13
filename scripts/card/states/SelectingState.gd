extends State
class_name SelectingState

const TO_WAIT_STATE_SCRIPT: Script = preload("res://scripts/card/states/ToWaitState.gd")

var area: Area3D
var is_entered: bool
var start_pos: Vector3

func enter() -> void:
	super.enter()
	for child in card.get_children():
		if child as Area3D:
			area = child
			break
	if area != null:
		var on_entered: Callable = Callable(self, "_on_area_mouse_entered")
		var on_exited: Callable = Callable(self, "_on_area_mouse_exited")
		if not area.mouse_entered.is_connected(on_entered):
			area.mouse_entered.connect(on_entered)
		if not area.mouse_exited.is_connected(on_exited):
			area.mouse_exited.connect(on_exited)
	start_pos = card.global_position

func exit() -> void:
	super.exit()
	if area != null:
		var on_entered: Callable = Callable(self, "_on_area_mouse_entered")
		var on_exited: Callable = Callable(self, "_on_area_mouse_exited")
		if area.mouse_entered.is_connected(on_entered):
			area.mouse_entered.disconnect(on_entered)
		if area.mouse_exited.is_connected(on_exited):
			area.mouse_exited.disconnect(on_exited)
		area.visible = false
	card.set_color(card.original_modulate, 100)
	if global.game_sense != null:
		global.game_sense.on_selecting_card_committed(card)

func update(delta: float) -> void:
	super.update(delta)
	if area != null and global.current_state == global.GameState.SELECTING:
		area.visible = true

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				transition_to(TO_WAIT_STATE_SCRIPT)

func mouse_entered(entered: bool) -> void:
	if area == null:
		return
	if card.state != self or !area.visible:
		return
	is_entered = entered
	if entered:
		card.set_color(Color(0.588, 0.588, 0.588, 1.0), 100)
		_move(Vector3(start_pos.x, start_pos.y + 0.01, start_pos.z), 0.1, 0, 1)
	else:
		card.set_color(card.original_modulate, 100)
		_move(Vector3(start_pos.x, start_pos.y, start_pos.z), 0.1, 0, 1)

func _on_area_mouse_entered() -> void:
	mouse_entered(true)

func _on_area_mouse_exited() -> void:
	mouse_entered(false)
