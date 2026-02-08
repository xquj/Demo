
class_name MultiPlayer extends PlayerEntity
func process() -> void:
	super.process()
	for card in waitingGroup:
		if card.get_script() == null:
			card.set_script(load("res://scrpcts/status/card_selecting.gd"))
