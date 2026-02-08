extends Card_Base
class_name Card_Water
var family_bar: Sprite3D = Sprite3D.new()
var anima_family_bar: AnimationUtils
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	self.selling_price.append_array([Coin2.new()])
	family_texture = load("res://textrue/family/family4.png")
	family_name = "水"
	
	anima_family_bar = AnimationUtils.new(0.0,0.0,100)
	anima_family_bar.play(true)
	
	family_bar.texture = family_texture
	family_bar.position.y = 0.165
	family_bar.visible = false
	add_child(family_bar)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	anima_family_bar.update(delta)
	family_bar.scale = Vector3(anima_family_bar.value,anima_family_bar.value,anima_family_bar.value)
	match state:
		States.SELECTING:
			if move_ability:
				family_bar.visible = true
				anima_family_bar.set_target(0.0,30)
				anima_family_bar.play(true)
		States.WAITING:
			pass


func _input(event: InputEvent) -> void:
	super._input(event)
	

func switch_state(state: States) -> void:
	super.switch_state(state)
	family_bar.visible = false
	match state:
		States.SELECTING:
			family_bar.visible = true
			anima_family_bar.set_target(0.075,75)
			anima_family_bar.play(true)
		States.WAITING:
			family_bar.visible = true
			anima_family_bar.set_target(0.075,75)
			anima_family_bar.play(true)
		
