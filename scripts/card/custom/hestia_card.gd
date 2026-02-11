extends Card_Base
class_name HestiaCard

func apply_data(card_def: Dictionary) -> void:
	super.apply_data(card_def)
	if "starter" not in keywords:
		keywords.push_back("starter")
