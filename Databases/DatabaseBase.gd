extends Node

func _ready():
	for child in self.get_children():
		var group_name = child.name.to_lower()
		for grand_child in child.get_children():
			grand_child.add_to_group(group_name)

func get_all_entries():
	var entry_list = []
	for child in self.get_children():
		for grand_child in child.get_children():
			entry_list.append(grand_child)
	return entry_list

func get_entry(entry_name):
	for child in self.get_children():
		if child.has_node(entry_name):
			return child.get_node(entry_name)
	# Entry does not exist
	assert(false)
	return null

func get_entries_in_group(group_name):
	return get_tree().get_nodes_in_group(group_name)

func _get_from_tab(tab, entry_name):
	return self.get_node(tab).get_child(entry_name)