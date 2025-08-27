# Custom Room System (Resource-Based)

This system allows you to easily create custom rooms using resource files (`.res`) that contain template data for room creation.

## How to Create a Custom Room

### 1. Copy the Base Template

1. Copy `BaseRoomTemplate.res` and rename it to your room name (e.g., `TrainingRoom.res`)
2. Open the new `.res` file in the Godot editor

### 2. Customize the Resource File

1. **Basic Properties**:
   - `room_name`: The name of your room (e.g., "Training Room")
   - `room_description`: Description of what the room does
   - `is_unlocked`: Whether the room is available by default

2. **UI Configuration**:
   - `header_label`: Text for the room header
   - `left_panel_label`: Text for the left panel
   - `right_panel_label`: Text for the right panel
   - `action_button_text`: Text for the main action button

3. **Custom Properties** (optional):
   - Add any custom properties to the `custom_properties` dictionary
   - These will be applied to the room instance when created

### 3. Example Custom Room

Here's an example of a training room resource file:

```gdscript
[gd_resource type="Resource" script_class="RoomTemplate" load_steps=2 format=3 uid="uid://g2x3y4n5m6k7l"]

[ext_resource type="Script" path="res://scenes/rooms/custom_rooms/RoomTemplate.gd" id="1_0"]

[resource]
script = ExtResource("1_0")
template_name = "Training Room Template"
room_name = "Training Room"
room_description = "Train your guild members to improve their skills"
is_unlocked = true
header_label = "Train Your Guild Members"
left_panel_label = "Available Characters"
right_panel_label = "Training Information"
action_button_text = "Train Selected Character"
custom_properties = {
"character_list": "RoomContainer/MainContent/LeftPanel/LeftPanelScroll/LeftPanelVBox",
"training_info": "RoomContainer/MainContent/RightPanel/RightPanelScroll/RightPanelVBox",
"train_button": "RoomContainer/BottomPanel/ActionButton"
}
```

### 4. Add Navigation (Optional)

To add navigation buttons to your custom room, you can:

1. Add buttons to the main hall navigation
2. Use the `GuildManager.enter_room("Your Room Name")` method
3. The room will be automatically discovered and created

## File Structure

```
scenes/rooms/custom_rooms/
├── RoomTemplate.gd              # Resource class for room templates
├── BaseRoomTemplate.res         # Base template resource file
├── BaseRoomTemplate.tscn        # Base scene template (used internally)
├── BaseRoomTemplate.gd          # Base script template (used internally)
├── CustomRoomCreator.gd         # Custom room creation system
├── TrainingRoom.res             # Example training room
└── README.md                    # This file
```

## Automatic Discovery

The system automatically discovers any `.res` files in the `custom_rooms` folder (except `BaseRoomTemplate.res`). To use a custom room:

1. Place your room resource file in the `custom_rooms` folder
2. The room will be automatically discovered on startup
3. Use `GuildManager.enter_room("Your Room Name")` to navigate to it

## How It Works

1. **Template Discovery**: `CustomRoomCreator` scans the `custom_rooms` folder for `.res` files
2. **Resource Loading**: Each `.res` file is loaded as a `RoomTemplate` resource
3. **Room Creation**: When a room is requested, the template creates a room instance using `BaseRoomTemplate.tscn`
4. **Property Application**: Template properties are applied to the room instance
5. **UI Updates**: Labels and text are updated based on the template configuration

## Best Practices

1. **Naming**: Use descriptive names for your rooms (e.g., `TrainingRoom.res`, `ShopRoom.res`)
2. **Properties**: Keep custom properties simple and focused
3. **Testing**: Test your room thoroughly before adding it to production
4. **Documentation**: Add comments to your resource files to explain functionality

## Troubleshooting

- **Room not discovered**: Make sure the file is in the `custom_rooms` folder and has a `.res` extension
- **Resource errors**: Ensure your `.res` file has the correct `script_class="RoomTemplate"`
- **UI not working**: Check that custom properties match the expected node paths
- **Navigation issues**: Verify the room name matches exactly when calling `enter_room()`

## Advanced Usage

### Custom Properties

You can add custom properties to the `custom_properties` dictionary:

```gdscript
custom_properties = {
"training_cost": 10,
"max_training_level": 5,
"training_types": ["Combat", "Magic", "Skills"]
}
```

### Script Extensions

If you need custom script logic, you can:

1. Create a custom script that extends `BaseRoom`
2. Set the `script_template_path` in your resource file
3. The room will use your custom script instead of the base template

## Migration from Old System

If you have existing `.tscn` and `.gd` files from the old system:

1. Create a new `.res` file based on `BaseRoomTemplate.res`
2. Copy the relevant properties from your old files
3. Test the new resource-based room
4. Remove the old `.tscn` and `.gd` files once confirmed working

## Town Map Integration

**IMPORTANT**: When adding new rooms to the game, you must also update the Town Map to include navigation buttons for the new room.

### Adding New Rooms to Town Map

1. **Update TownMap.tscn**: Add a new button for your room in the ButtonContainer
2. **Update TownMap.gd**: Add the button export and travel handler
3. **Test Navigation**: Verify the button works correctly

### Example for New Room "Training Room":

```gdscript
# In TownMap.tscn - Add button:
[node name="TrainingButton" type="Button" parent="Background/MapContainer/ButtonContainer"]
layout_mode = 2
text = "Training Room"
tooltip_text = "Train your guild members"

# In TownMap.gd - Add export and handler:
@export var training_button: Button

func setup_button_connections():
    # ... existing connections ...
    if training_button:
        training_button.pressed.connect(_on_training_travel)

func _on_training_travel():
    """Travel to Training Room"""
    _travel_to_room("Training Room")
```

### Memory Checklist

- [ ] Add button to TownMap.tscn
- [ ] Add export variable to TownMap.gd
- [ ] Add button connection in setup_button_connections()
- [ ] Add travel handler function
- [ ] Test navigation from map
- [ ] Update this checklist for future rooms

This ensures that all rooms are accessible from the Town Map, providing a consistent navigation experience for players.
