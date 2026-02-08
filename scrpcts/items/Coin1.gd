class_name Coin1 extends ItemDate

# 构造函数
func _init() -> void:
	# 设置货币属性
	var item_id_ = "1"
	var name_ = "Coin 1"
	var description_ = "A level 1 currency item"
	var item_type_ = "currency"
	var texture_: Texture2D = load("res://textrue/coin/coin1.png")
	# 调用父类构造函数
	super(item_id_, name_, description_, item_type_, texture_)
