extends Node
class_name AbilityLibrary

const ABILITIES := {
	"siphon": {
		"on_hit": Callable(AbilityLibrary, "_siphon_on_hit")
	},
	"rattle": {
		"on_death": Callable(AbilityLibrary, "_rattle_on_death")
	},
	"pierce": {
		"on_attack": Callable(AbilityLibrary, "_pierce_on_attack")
	},
	"seer": {
		"on_turn_start": Callable(AbilityLibrary, "_seer_on_turn_start")
	}
}

static func get_ability(id: String) -> Dictionary:
	return ABILITIES.get(id, {})

static func _siphon_on_hit(card, ctx: Dictionary) -> void:
	if card == null:
		return
	var heal_amount := 1
	card.heal(heal_amount)
	if ctx.has("manager"):
		ctx["manager"].spawn_floating_text("+" + str(heal_amount), card.global_position + Vector3(0, 0.2, 0))

static func _rattle_on_death(card, ctx: Dictionary) -> void:
	if ctx.has("manager"):
		ctx["manager"].spawn_rattle_token(card)

static func _pierce_on_attack(card, ctx: Dictionary) -> void:
	if ctx.has("manager") and ctx.has("target") and ctx["target"] != null:
		ctx["manager"].apply_scale_damage(card.owner, 1, true)

static func _seer_on_turn_start(card, ctx: Dictionary) -> void:
	if ctx.has("manager"):
		ctx["manager"].draw_card(ctx["manager"].active_player)
