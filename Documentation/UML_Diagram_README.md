# Claude Guild Idle Prototype - UML Class Diagram

This document contains a comprehensive UML class diagram for the Claude Guild Idle Prototype project, showing the main classes, their relationships, and key architectural patterns.

## Diagram Overview

The UML diagram is organized into several logical packages:

### 1. Core Game Mechanics
- **Character**: Represents guild members with stats, classes, ranks, and status
- **Quest**: Represents missions with requirements, rewards, and party assignments
- **InventoryItem**: Represents items with properties, rarity, and stacking
- **Inventory**: Manages item storage and room-specific filtering

### 2. Singleton Managers
- **GuildManager**: Central game state manager handling resources, roster, quests, and room navigation
- **SignalBus**: Centralized signal hub for decoupled communication between components

### 3. Room System
- **BaseRoom**: Abstract base class for all game rooms with common functionality
- **MainHallRoom**: Central hub showing active quests and promotions
- **QuestsRoom**: Quest selection and party assembly
- **RosterRoom**: Character management and inspection
- **RecruitmentRoom**: Character recruitment system
- **TrainingRoom**: Character training and development

### 4. UI Components
- **CompactQuestCard**: Quest display component
- **QuestCompletionPanel**: Quest results display
- **StatsComparisonTable**: Party vs quest requirements comparison
- **InventoryUI**: Inventory management interface
- **ExperienceBar**: Character experience display

### 5. Utility Systems
- **ResponsiveLayout**: UI scaling and layout management
- **UIUtilities**: Common UI helper functions

## Key Architectural Patterns

### Singleton Pattern
- `GuildManager` and `SignalBus` are implemented as Godot autoloads (singletons)
- Provides centralized state management and communication

### Inheritance Hierarchy
- All rooms inherit from `BaseRoom` abstract class
- Common room functionality is centralized in the base class

### Component Pattern
- UI components are modular and reusable
- Each component has a specific responsibility

### Observer Pattern
- `SignalBus` implements the observer pattern for decoupled communication
- Components emit and listen to signals without direct dependencies

## Relationships

### Composition Relationships
- `GuildManager` manages collections of `Character`, `Quest`, and `CompactQuestCard` objects
- `Inventory` contains `InventoryItem` objects
- `Quest` has assigned `Character` party members

### Inheritance Relationships
- All room classes inherit from `BaseRoom`
- UI components extend Godot's built-in UI classes

### Association Relationships
- `CompactQuestCard` displays `Quest` data
- `QuestCompletionPanel` shows `Quest` results
- `StatsComparisonTable` compares `Quest` requirements with `Character` stats

## How to View the Diagram

### Option 1: Online PlantUML Viewer
1. Copy the contents of `project_uml_diagram.puml`
2. Go to [PlantUML Online Server](http://www.plantuml.com/plantuml/uml/)
3. Paste the content and view the generated diagram

### Option 2: VS Code Extension
1. Install the "PlantUML" extension in VS Code
2. Open `project_uml_diagram.puml`
3. Use `Ctrl+Shift+P` and select "PlantUML: Preview Current Diagram"

### Option 3: Local PlantUML Installation
1. Install PlantUML (requires Java)
2. Run: `java -jar plantuml.jar project_uml_diagram.puml`
3. This generates a PNG file you can view

### Option 4: IntelliJ IDEA / PyCharm
1. Install the PlantUML plugin
2. Open the `.puml` file
3. The diagram will render automatically

## Key Design Decisions

### Godot-Specific Patterns
- Uses Godot's signal system for communication
- Leverages Godot's autoload system for singletons
- Extends Godot's built-in UI classes for components

### Separation of Concerns
- Game logic separated from UI presentation
- Room-specific logic isolated in individual room classes
- Centralized state management in GuildManager

### Extensibility
- New room types can easily inherit from BaseRoom
- New UI components can be added without affecting existing code
- Signal-based communication allows loose coupling

## Future Enhancements

The diagram shows a solid foundation that can be extended with:
- Additional room types (Library, Workshop, etc.)
- More complex quest mechanics
- Enhanced character progression systems
- Additional UI components for new features

## Notes

- This diagram represents the current state of the codebase
- Some implementation details may vary slightly from the diagram
- The diagram focuses on the main architectural patterns and relationships
- Godot-specific implementation details (like scene trees) are abstracted for clarity
