extends RefCounted
class_name SignalBridge

var flow: BattleFlow
var event_bus: EventBus

func _init(flow_: BattleFlow, event_bus_: EventBus) -> void:
	flow = flow_
	event_bus = event_bus_

func connect_event_bus() -> void:
	if event_bus == null or flow == null:
		return
	if not event_bus.end_waiting_requested.is_connected(_on_end_waiting_requested):
		event_bus.end_waiting_requested.connect(_on_end_waiting_requested)
	if not event_bus.end_combo_requested.is_connected(_on_end_combo_requested):
		event_bus.end_combo_requested.connect(_on_end_combo_requested)

func _on_end_waiting_requested() -> void:
	flow.request_waiting_ready(global.local_player)

func _on_end_combo_requested() -> void:
	flow.request_advance_combo_round(global.local_player)
