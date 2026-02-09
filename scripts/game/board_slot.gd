extends Node3D
class_name BoardSlot

signal slot_clicked(slot)
signal hover_changed(slot, hovered)

@export var lane_index: int = 0
@export var is_player_slot: bool = true

@onready var indicator: MeshInstance3D = $Indicator
@onready var area: Area3D = $Area3D

var highlight_color := Color(0.3, 0.7, 0.4, 0.6)
var base_color := Color(0.15, 0.15, 0.15, 0.4)

func _ready() -> void:
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(func(): _set_hover(true))
	area.mouse_exited.connect(func(): _set_hover(false))
	_set_color(base_color)

func set_highlight(active: bool) -> void:
	_set_color(highlight_color if active else base_color)

func _set_hover(hovered: bool) -> void:
	emit_signal("hover_changed", self, hovered)

func _set_color(color: Color) -> void:
	var mat := indicator.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
		indicator.set_surface_override_material(0, mat)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color

func _on_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		emit_signal("slot_clicked", self)
