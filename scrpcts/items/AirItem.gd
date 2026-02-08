class_name AirItem extends ItemDate

# 构造函数
func _init() -> void:
	# 设置货币属性
	var item_id_ = "0"
	var name_ = "NULL"
	var description_ = "NULL"
	var item_type_ = "NULL"
	var texture_: Texture2D = null
	# 调用父类构造函数
	super(item_id_, name_, description_, item_type_, texture_)
