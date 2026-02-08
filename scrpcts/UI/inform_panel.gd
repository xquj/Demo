extends Panel

var text: String = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible:
		var label: Label = $Label
		label.text = text
		size.x = label.size.x + 5
		size.y = label.size.y + 7

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = event.position
		position.x -= size.x / 1.2
		position.y += 20


func 弃牌堆_exited() -> void:
	visible = false


func 弃牌堆_entered() -> void:
	text = "名称:弃牌堆"
	visible = true


func 发牌堆_entered() -> void:
	text = "名称:发牌堆"
	visible = true



func 发牌堆_exited() -> void:
	visible = false
