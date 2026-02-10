class_name Inventory extends RefCounted

# [数据] 背包物品列表。
var items: Array[ItemData] = []
var size: int = 4  # 背包大小，默认 4 格。

# [初始化] 构造函数。
func _init(size_: int = 4) -> void:
	size = size_
	for i in range(size):
		items.push_back(AirItem.new())

# [写入] 自动放入第一个空槽位。
func add_item_auto(item: ItemData) -> void:
	var i: int = 0;
	if get_items_size() >= size || i > size: return
	while !(items.get(i) as AirItem):
		i+=1
	items[i] = item

func add_item(item: ItemData,slot_id: int) -> bool:
	if slot_id >= 0 && slot_id < size:
		items[slot_id] = item
		return true
	return false

func add_items(items_: Array[ItemData]) -> void:
	var i: int = 0;
	for item in items_:
		if get_items_size() >= size || i > size: return
		while !(items.get(i) as AirItem):
			i+=1
		items[i] = item


# [写入] 从指定槽位移除物品。
func remove_item(index: int) -> bool:
	if index >= 0 and index <= size:
		items[index] = AirItem.new()
		return true
	return false

# [读取] 获取指定槽位物品。
func get_item(index: int) -> ItemData:
	if index >= 0 and index < size:
		return items.get(index)
	return null

# [读取] 获取全部物品。
func get_items() -> Array[ItemData]:
	return items

# [读取] 统计指定物品数量。
func get_item_count(item_id: String) -> int:
	var count = 0
	for item in items:
		if item.item_id == item_id:
			count += 1
	return count

# [读取] 获取指定物品首个索引。
func get_item_index(item_id: String) -> int:
	var count = 0
	for item in items:
		if item.item_id == item_id:
			return count
		count += 1
	return -1

# [读取] 获取背包容量。
func get_size() -> int:
	return size
	
# [读取] 获取背包容量。
func get_items_size() -> int:
	var size: int = 0;
	for item in items:
		if item.item_id != "0":
			size += 1
	return size

# [写入] 清空背包。
func clear() -> void:
	items.clear()
	for i in range(size):
		items.push_back(AirItem.new())

# [校验] 判断背包是否已满。
func is_full() -> bool:
	return get_items_size() >= size

# [校验] 判断背包是否为空。
func is_empty() -> bool:
	return items.is_empty()
