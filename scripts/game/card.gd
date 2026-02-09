extends Node3D
class_name Card3D

signal card_clicked(card)
signal hover_changed(card, hovered)

var data: Dictionary = {}
var owner = null
var manager = null
var lane_index: int = -1
var zone: String = "deck"
var attack: int = 0
var max_health: int = 0
var health: int = 0

@onready var frame: Sprite3D = $Frame
@onready var art: Sprite3D = $Art
@onready var cost_gem: Sprite3D = $CostGem
@onready var cost_label: Label3D = $CostLabel
@onready var name_label: Label3D = $Name
@onready var stats_label: Label3D = $Stats
@onready var desc_label: Label3D = $Description
@onready var area: Area3D = $Area3D

var base_scale: Vector3
var hover_scale := Vector3(1.08, 1.08, 1.08)
var base_position: Vector3

func _ready() -> void:
	base_scale = scale
	base_position = global_position
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(func(): _set_hover(true))
	area.mouse_exited.connect(func(): _set_hover(false))

func setup(card_data: Dictionary, owner_state, manager_ref) -> void:
	data = card_data
	owner = owner_state
	manager = manager_ref
	attack = int(card_data.get("attack", 0))
	max_health = int(card_data.get("health", 0))
	health = max_health
	name_label.text = str(card_data.get("name", "Unknown"))
	_update_stats()
	desc_label.text = str(card_data.get("description", ""))
	_set_art_texture(card_data.get("art", ""))
	_update_cost_display()

func _set_art_texture(path: String) -> void:
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path)
	if tex == null:
		tex = _create_fallback_texture()
	art.texture = tex

func _create_fallback_texture() -> Texture2D:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.1, 0.1, 1))
	for y in range(8, 120, 8):
		for x in range(8, 120, 8):
			if (x + y) % 16 == 0:
				image.set_pixel(x, y, Color(0.8, 0.8, 0.8, 1))
	return ImageTexture.create_from_image(image)

func _update_cost_display() -> void:
	var cost_type := str(data.get("cost_type", ""))
	var cost_value := int(data.get("cost", 0))
	cost_gem.modulate = Color(0.7, 0.1, 0.1, 1) if cost_type == "blood" else Color(0.7, 0.7, 0.9, 1)
	cost_gem.visible = cost_value > 0
	cost_label.text = str(cost_value)

func _update_stats() -> void:
	if is_spell():
		stats_label.text = ""
	else:
		stats_label.text = str(attack) + "/" + str(health)

func is_spell() -> bool:
	return data.get("type", "unit") == "spell"

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	_update_stats()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	_update_stats()

func _set_hover(hovered: bool) -> void:
	if zone == "hand":
		scale = hover_scale if hovered else base_scale
		global_position = base_position + Vector3(0, 0.04, 0) if hovered else base_position
	emit_signal("hover_changed", self, hovered)

func _on_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		emit_signal("card_clicked", self)
