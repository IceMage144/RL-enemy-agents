extends "res://Databases/DatabaseBase.gd"

func get_monster(monster_name):
	return self.get_entry(monster_name)

func get_monsters_in_group(group_name):
	return self.get_entries_in_group(group_name)

func get_minion(minion_name):
	self._get_from_tab("Minions", minion_name)

func get_elite(elite_name):
	self._get_from_tab("Elites", elite_name)

func get_boss(boss_name):
	self._get_from_tab("Bosses", boss_name)