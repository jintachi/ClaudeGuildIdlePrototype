# CompactQuestCard Component

A reusable UI component for displaying quest information in a compact, consistent format.

## Files
- `CompactQuestCard.tscn` - The scene file
- `compact_quest_card.gd` - The script file

## Usage

### Basic Usage
```gdscript
# Load and instantiate the component
var quest_card_scene = load("res://ui/components/CompactQuestCard.tscn")
var quest_card = quest_card_scene.instantiate() as CompactQuestCard

# Populate with quest data
quest_card.populate_with_quest(quest)

# Add to your UI
container.add_child(quest_card)
```

### Signal Handling
```gdscript
# Connect to quest selection
quest_card.quest_selected.connect(your_selection_handler)

# Handle the signal
func your_selection_handler(quest: Quest):
	print("Quest selected: ", quest.quest_name)
```

### Visual States
```gdscript
# Set selection state
quest_card.set_selected(true)  # or false

# Set success rate (for when party is selected)
quest_card.set_success_rate(0.85)  # Shows "🎯 85%"
quest_card.set_success_rate(-1)    # Hides success rate
```

## Features

### Display Elements
- **Rank Badge**: Color-coded quest rank (F, E, D, C, B, A, S, SS, SSS)
- **Quest Name**: The quest title
- **Duration**: Time in MM:SS format with ⏱️ icon
- **Party Size**: Min-max party size with 👥 icon
- **Success Rate**: Optional display with 🎯 icon (shown when party is selected)
- **Requirements**: Compact summary of class and stat requirements
- **Rewards**: Compact summary of gold, XP, and influence rewards

### Color Coding
- **F Rank**: Gray
- **E Rank**: Light Blue
- **D Rank**: Blue
- **C Rank**: Green
- **B Rank**: Orange
- **A Rank**: Red
- **S Rank**: Purple
- **SS Rank**: Gold
- **SSS Rank**: White

### Interactive Features
- Clickable button that emits `quest_selected` signal
- Visual selection state with pressed button styling
- Success rate display that can be shown/hidden

## Integration Examples

### Quests Room
Used for displaying available quests in the quest counter with selection functionality.

### Main Hall Room
Used for displaying active quests and quests awaiting completion with additional progress/status information.

## Customization

The component is designed to be extensible. You can:
- Add additional UI elements to the VBoxContainer
- Override the styling by modifying the theme
- Extend the component with additional methods for specific use cases
- Customize individual label elements through the export variables in the scene editor

### Export Variables
The component uses `@export` variables for all UI elements, making them easily accessible in the Godot editor:
- `rank_label`: The quest rank display
- `title_label`: The quest name display
- `duration_label`: The quest duration display
- `party_label`: The party size display
- `success_label`: The success rate display
- `requirements_label`: The requirements summary display
- `rewards_label`: The rewards summary display

## Dependencies
- Requires `Quest` class from `mechanics/quest.gd`
- Uses Godot's built-in UI controls (Button, Panel, VBoxContainer, HBoxContainer, Label)

## Troubleshooting

### Export Variable Issues
If you encounter "Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'Nil'" errors:
1. Ensure all export variables are properly connected in the scene file
2. Check that the NodePath connections in `CompactQuestCard.tscn` are correct
3. The component includes null checks to prevent runtime errors

### Integration Notes
- The component is used in both Quests Room and Main Hall Room
- All quest displays now use the same consistent format
- Old manual quest panel creation has been removed and replaced with this component
