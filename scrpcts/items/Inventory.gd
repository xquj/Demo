class_name Inventory extends RefCounted

# 背包物品列表
var items: Array[ItemDate] = []
var size: int = 4  # 背包大小，默认20格

# 构造函数
func _init(size_: int = 4) -> void:
	size = size_
	for i in range(size):
		items.push_back(AirItem.new())

# 向背包添加物品
func add_item_(item: ItemDate) -> void:
	var i: int = 0;
	if get_items_size() >= size || i > size: return
	while !(items.get(i) as AirItem):
		i+=1
	items[i] = item

func add_item(item: ItemDate,slot_id: int) -> bool:
	if slot_id >= 0 && slot_id < size:
		items[slot_id] = item
		return true
	return false

func add_items(items_: Array[ItemDate]) -> void:
	var i: int = 0;
	for item in items_:
		if get_items_size() >= size || i > size: return
		while !(items.get(i) as AirItem):
			i+=1
		items[i] = item


# 从背包移除物品
func remove_item(index: int) -> bool:
	if index >= 0 and index <= size:
		items[index] = AirItem.new()
		return true
	return false

# 获取背包指定格子的物品
func get_item(index: int) -> ItemDate:
	if index >= 0 and index < size:
		return items.get(index)
	return null

# 获取背包所有物品
func get_items() -> Array[ItemDate]:
	return items

# 获取背包中指定物品的数量
func get_item_count(item_id: String) -> int:
	var count = 0
	for item in items:
		if item.item_id == item_id:
			count += 1
	return count

# 获取背包中指定物品的位置
func get_item_index(item_id: String) -> int:
	var count = 0
	for item in items:
		if item.item_id == item_id:
			return count
		count += 1
	return -1

# 获取背包大小
func get_size() -> int:
	return size
	
# 获取背包大小
func get_items_size() -> int:
	var size: int = 0;
	for item in items:
		if item.item_id != "0":
			size += 1
	return size

# 清空背包
func clear() -> void:
	items.clear()
	for i in range(size):
		items.push_back(AirItem.new())

# 检查背包是否已满
func is_full() -> bool:
	return get_items_size() >= size

# 检查背包是否为空
func is_empty() -> bool:
	return items.is_empty()
