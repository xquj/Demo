extends State
class_name DealingState

func _init(card_: Card_Base) -> void:
	super(card_)
	_move(Vector3(1,1,1),10)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	

func _input(event: InputEvent) -> void:
	super._input(event)
