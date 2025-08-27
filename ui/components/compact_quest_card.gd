extends Button
class_name CompactQuestCard

@export var rank_label: Label
@export var title_label: Label
@export var duration_label: Label
@export var party_label: Label
@export var success_label: Label
@export var assigned_members: Label
@export var requirements_label: Label
@export var rewards_label: Label
var _quest:Quest

func _ready():
	# The 'pressed' signal is connected via the editor to _on_pressed
	pass

func get_quest() -> Quest:
	return _quest

func populate_with_quest(quest_data: Quest):
	"""Populate the card with quest data"""
	_quest = quest_data
	
	# Check if all export variables are properly connected, and connect them if needed
	if not rank_label or not title_label or not duration_label or not party_label or not success_label or not requirements_label or not rewards_label:
		print("Auto-connecting export variables in CompactQuestCard...")
		rank_label = get_node("InnerPanel/VBoxContainer/HeaderContainer/RankLabel")
		title_label = get_node("InnerPanel/VBoxContainer/HeaderContainer/TitleLabel")
		duration_label = get_node("InnerPanel/VBoxContainer/MetricsContainer/DurationLabel")
		party_label = get_node("InnerPanel/VBoxContainer/MetricsContainer/PartyLabel")
		success_label = get_node("InnerPanel/VBoxContainer/MetricsContainer/SuccessLabel")
		assigned_members = get_node("InnerPanel/VBoxContainer/Assigned Members")
		requirements_label = get_node("InnerPanel/VBoxContainer/RequirementsLabel")
		rewards_label = get_node("InnerPanel/VBoxContainer/RewardsLabel")
		
		# Check again after connecting
		if not rank_label or not title_label or not duration_label or not party_label or not success_label or not requirements_label or not rewards_label:
			print("Error: Failed to connect export variables in CompactQuestCard!")
			return
		
	# Set rank and title
	rank_label.text = "[%s]" % quest_data.get_rank_name()
	rank_label.add_theme_color_override("font_color", get_rank_color(quest_data.quest_rank))
	title_label.text = quest_data.quest_name
	
	# Set duration
	var minutes = int(quest_data.duration / 60)
	var seconds = int(quest_data.duration) % 60
	duration_label.text = "⏱️ %02d:%02d" % [minutes, seconds]
	
	# Set party size
	party_label.text = "👥 %d-%d" % [quest_data.min_party_size, quest_data.max_party_size]
	
	# Set requirements
	requirements_label.text = get_compact_requirements_text(quest_data)
	
	# Set rewards
	rewards_label.text = get_compact_rewards_text(quest_data)

func set_success_rate(success_rate: float):
	"""Set the success rate display (for when party is selected)"""
	if not success_label:
		return
		
	if success_rate >= 0:
		success_label.text = "🎯 %d%%" % int(success_rate * 100)
		success_label.visible = true
	else:
		success_label.visible = false

func set_selected(selected: bool):
	"""Set the visual state for selection"""
	if selected:
		add_theme_stylebox_override("normal", get_theme_stylebox("pressed", "Button"))
		print("DEBUG: I've been selected: " + str(self._quest))
	else:
		remove_theme_stylebox_override("normal")
		#set_selected(false)

func _on_pressed():
	"""Emit signal when card is clicked"""
	print("I've been pressed!"+str(self._quest))
	if _quest:
		SignalBus.quest_card_selected.emit(self)

func get_rank_color(rank: Quest.QuestRank) -> Color:
	"""Get color for quest rank"""
	match rank:
		Quest.QuestRank.F: return Color.GRAY
		Quest.QuestRank.E: return Color.LIGHT_BLUE
		Quest.QuestRank.D: return Color.BLUE
		Quest.QuestRank.C: return Color.GREEN
		Quest.QuestRank.B: return Color.ORANGE
		Quest.QuestRank.A: return Color.RED
		Quest.QuestRank.S: return Color.PURPLE
		Quest.QuestRank.SS: return Color.GOLD
		Quest.QuestRank.SSS: return Color.WHITE
		_: return Color.WHITE

func get_compact_requirements_text(quest: Quest) -> String:
	"""Get compact requirements text for quest cards"""
	var req_parts = []
	
	# Class requirements
	if quest.required_tank:
		req_parts.append("🛡️ Tank")
	if quest.required_healer:
		req_parts.append("💚 Healer")
	if quest.required_support:
		req_parts.append("🔮 Support")
	if quest.required_attacker:
		req_parts.append("⚔️ Attacker")
	
	# Stat requirements (show most important one)
	if quest.min_total_health > 0:
		req_parts.append("❤️ %d+" % quest.min_total_health)
	elif quest.min_total_defense > 0:
		req_parts.append("🛡️ %d+" % quest.min_total_defense)
	elif quest.min_total_attack_power > 0:
		req_parts.append("⚔️ %d+" % quest.min_total_attack_power)
	elif quest.min_total_spell_power > 0:
		req_parts.append("🔮 %d+" % quest.min_total_spell_power)
	elif quest.min_substat_requirement > 0:
		req_parts.append("📊 %d+" % quest.min_substat_requirement)
	
	return " ".join(req_parts) if not req_parts.is_empty() else "No special requirements"

func get_compact_rewards_text(quest: Quest) -> String:
	"""Get compact rewards text for quest cards"""
	var reward_parts = []
	
	reward_parts.append("💰 %d Gold" % quest.gold_reward)
	reward_parts.append("⭐ %d XP" % quest.base_experience)
	
	if quest.influence_reward > 0:
		reward_parts.append("👑 %d Inf" % quest.influence_reward)
	
	return " | ".join(reward_parts)

func set_active_party_roster(quest: Quest):
	var roster_list = []
	
	for member in quest.assigned_party :
		roster_list.append(member.get_class_icon()+" | "+member.character_name)
	
	assigned_members.text = "\n" .join(roster_list)

func get_active_party_roster() -> String :
	return assigned_members.text
