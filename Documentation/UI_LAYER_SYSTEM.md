# UI Layer System

The UI Layer system provides a centralized way to manage UI elements that should appear above all other content in the game. This system ensures consistent layering, proper cleanup, and better organization of UI components.

## Architecture

### Core Components

1. **UILayer.tscn** - The main UI layer scene with organized containers
2. **UILayer.gd** - Manages the UI layer containers and element tracking
3. **UILayerManager** - Singleton that provides easy access to the UI layer
4. **DragPreviewManager** - Specialized manager for drag preview functionality

### UI Layer Structure

```
UILayer (CanvasLayer, layer=10)
├── UIElements (Control)
    ├── Tooltips (z_index=1000)
    ├── ContextMenus (z_index=900)
    ├── Modals (z_index=800)
    ├── Overlays (z_index=700)
    └── Notifications (z_index=600)
```

## Usage Examples

### Adding Tooltips

```gdscript
# Using TooltipManager (automatically uses UI Layer)
TooltipManager.show_tooltip(item, target_control)

# Direct usage
var tooltip_scene = preload("res://ui/components/ItemTooltip.tscn")
var tooltip = UILayerManager.add_tooltip_to_layer(tooltip_scene)
```

### Adding Context Menus

```gdscript
# Using ContextMenuManager (automatically uses UI Layer)
ContextMenuManager.show_context_menu(items, position)

# Direct usage
var menu_scene = preload("res://ui/components/ContextMenu.tscn")
var menu = UILayerManager.add_context_menu_to_layer(menu_scene)
```

### Adding Modal Dialogs

```gdscript
# Direct usage
var modal_scene = preload("res://ui/components/CharacterEquipmentPanel.tscn")
var modal = UILayerManager.add_modal_to_layer(modal_scene)
```

### Adding Overlays

```gdscript
# For drag previews
DragPreviewManager.show_item_drag_preview(item, position)

# For other overlays
var overlay_scene = preload("res://ui/components/SomeOverlay.tscn")
var overlay = UILayerManager.add_overlay_to_layer(overlay_scene)
```

### Adding Notifications

```gdscript
# Direct usage
var notification_scene = preload("res://ui/components/Notification.tscn")
var notification = UILayerManager.add_notification_to_layer(notification_scene)
```

## UI Element Types

### Tooltips (z_index=1000)
- Item tooltips
- Help tooltips
- Hover information
- **Characteristics**: Temporary, follow mouse/cursor, auto-hide

### Context Menus (z_index=900)
- Right-click menus
- Action menus
- **Characteristics**: Positioned at cursor, dismissible, single instance

### Modals (z_index=800)
- Dialog boxes
- Equipment panels
- Settings windows
- **Characteristics**: Blocking, centered, require explicit dismissal

### Overlays (z_index=700)
- Drag previews
- Loading indicators
- Progress bars
- **Characteristics**: Non-blocking, temporary, visual feedback

### Notifications (z_index=600)
- System messages
- Achievement notifications
- Status updates
- **Characteristics**: Auto-dismiss, non-blocking, queueable

## Best Practices

### 1. Use Appropriate UI Element Types
- **Tooltips**: For hover information
- **Context Menus**: For right-click actions
- **Modals**: For important dialogs that require attention
- **Overlays**: For temporary visual feedback
- **Notifications**: For system messages

### 2. Proper Cleanup
```gdscript
# Always clean up UI elements when done
UILayerManager.remove_from_layer(ui_element)

# Or use the specialized managers
TooltipManager.hide_tooltip()
ContextMenuManager.hide_context_menu()
DragPreviewManager.hide_drag_preview()
```

### 3. Use Static Helper Functions
```gdscript
# Preferred approach
UILayerManager.add_tooltip_to_layer(tooltip_scene)
UILayerManager.add_modal_to_layer(modal_scene)

# Instead of direct instance access
UILayerManager.instance.add_tooltip(tooltip_scene)
```

### 4. Scene Structure
- Keep UI scenes focused on single responsibilities
- Use proper anchoring and sizing
- Test at different screen resolutions
- Consider responsive design

## Migration Guide

### From Direct Scene Addition
```gdscript
# Old way
get_tree().current_scene.add_child(ui_element)

# New way
UILayerManager.add_modal_to_layer(ui_scene)
```

### From Root Addition
```gdscript
# Old way
get_tree().root.add_child(ui_element)

# New way
UILayerManager.add_overlay_to_layer(ui_scene)
```

## Manager Integration

### TooltipManager
- Automatically uses UI Layer for tooltips
- Provides hover timing and positioning
- Handles tooltip lifecycle

### ContextMenuManager
- Automatically uses UI Layer for context menus
- Manages menu positioning and dismissal
- Handles menu item selection

### DragPreviewManager
- Specialized for drag and drop operations
- Provides smooth drag preview experience
- Handles drag preview positioning

## Troubleshooting

### UI Elements Not Appearing
1. Check if UILayerManager is properly initialized
2. Verify the UI element is added to the correct container
3. Check z_index values
4. Ensure the UI element is visible

### Z-Index Issues
- Tooltips: 1000 (highest)
- Context Menus: 900
- Modals: 800
- Overlays: 700
- Notifications: 600 (lowest)

### Performance Considerations
- UI Layer is always present but lightweight
- Elements are properly cleaned up when removed
- Use appropriate UI element types to avoid conflicts
- Consider pooling for frequently used elements

## Future Enhancements

- UI element pooling for better performance
- Animation system integration
- Theme system integration
- Accessibility features
- Multi-resolution support improvements
