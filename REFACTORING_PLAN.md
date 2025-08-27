# Guild Hall Refactoring Plan

## Overview
The current `guild_hall.gd` file is 2034 lines long and handles everything from UI management to business logic. This refactoring plan breaks it down into a modular room system with proper inheritance and separation of concerns.

## Current Issues

### 1. **Monolithic Architecture**
- Single 2034-line file handling all functionality
- Mixed responsibilities (UI, business logic, data management)
- Difficult to maintain and extend
- No code reuse between similar features

### 2. **No Room System**
- All functionality hardcoded into main guild hall
- No way to add new rooms efficiently
- No room-specific state management
- No room navigation system

### 3. **Scattered Business Logic**
- UI logic mixed with business logic
- Validation logic duplicated across functions
- No centralized data formatting
- Difficult to test individual components

## Proposed Solution: Room-Based Architecture

**Architectural Decision**: Room management has been integrated into GuildManager as a singleton rather than using a separate RoomManager class. This provides better centralization and avoids runtime instantiation issues.

### 1. **Base Room System**
```
scenes/rooms/
├── base_room.gd          # Base class for all rooms
├── main_hall_room.gd     # Main hall functionality
├── roster_room.gd        # Character management
├── quests_room.gd        # Quest management
├── recruitment_room.gd   # Character recruitment
└── training_room.gd      # Character training (future)

mechanics/Singletons/
└── guild_manager.gd      # Room management integrated into GuildManager
```

### 2. **Inheritance Structure**
```
BaseRoom (abstract base class)
├── MainHallRoom
├── RosterRoom
├── QuestsRoom
├── RecruitmentRoom
├── TrainingRoom
├── LibraryRoom
├── WorkshopRoom
├── ArmoryRoom
└── HealersGuildRoom
```

### 3. **Business Logic Centralization**
Move all business logic to `GuildManager`:
- Data formatting and validation
- UI state calculations
- Room availability logic
- Notification data generation

## Implementation Benefits

### 1. **Code Reuse**
- Common room functionality in `BaseRoom`
- Shared UI patterns and responsive layout
- Consistent navigation and state management

### 2. **Maintainability**
- Each room is a separate, focused file
- Clear separation of concerns
- Easier to debug and modify individual features

### 3. **Extensibility**
- Easy to add new rooms by extending `BaseRoom`
- Room-specific functionality isolated
- Modular room unlocking system

### 4. **Testing**
- Individual rooms can be tested in isolation
- Business logic separated from UI
- Clear interfaces between components

## Implementation Steps

### Phase 1: Foundation (COMPLETED)
- [x] Create `BaseRoom` class with common functionality
- [x] Create `RoomManager` for navigation and state management
- [x] Create `MainHallRoom` as first example room
- [x] Add UI business logic methods to `GuildManager`

### Phase 2: Room Extraction (COMPLETED)
- [x] Extract roster functionality to `RosterRoom`
- [x] Extract quest functionality to `QuestsRoom`
- [x] Extract recruitment functionality to `RecruitmentRoom`
- [x] Update main guild hall to use room system

### Phase 3: New Room Creation
- [ ] Create `TrainingRoom` for character training
- [ ] Create `LibraryRoom` for skill development
- [ ] Create `WorkshopRoom` for equipment crafting
- [ ] Create `ArmoryRoom` for equipment management
- [ ] Create `HealersGuildRoom` for healing injured characters

### Phase 4: Integration
- [ ] Update scene files to use new room classes
- [ ] Implement room navigation system
- [ ] Add room unlocking logic
- [ ] Update save/load system for room states

### Phase 5: Optimization
- [ ] Remove old monolithic guild_hall.gd
- [ ] Optimize room loading and transitions
- [ ] Add room-specific performance optimizations
- [ ] Implement room state caching

## File Size Reduction

### Current State
- `guild_hall.gd`: 2034 lines
- Mixed responsibilities
- Difficult to navigate

### After Refactoring
- `base_room.gd`: ~150 lines (common functionality)
- `room_manager.gd`: ~200 lines (navigation logic)
- `main_hall_room.gd`: ~400 lines (main hall specific)
- `roster_room.gd`: ~300 lines (character management)
- `quests_room.gd`: ~350 lines (quest management)
- `recruitment_room.gd`: ~250 lines (recruitment specific)
- `guild_manager.gd`: +200 lines (business logic)

**Total**: ~1850 lines (10% reduction) but much better organized

## Code Quality Improvements

### 1. **Single Responsibility Principle**
- Each room handles only its specific functionality
- Business logic centralized in GuildManager
- UI logic separated from data logic

### 2. **Open/Closed Principle**
- Easy to add new rooms without modifying existing code
- BaseRoom provides extension points
- RoomManager handles new room types automatically

### 3. **Dependency Inversion**
- Rooms depend on abstractions (BaseRoom interface)
- GuildManager provides data through well-defined interfaces
- UI components depend on data contracts, not implementations

### 4. **Interface Segregation**
- Each room implements only the methods it needs
- Clear separation between room types
- Minimal coupling between components

## Migration Strategy

### 1. **Gradual Migration**
- Keep existing guild_hall.gd during transition
- Create new rooms alongside existing code
- Migrate functionality room by room
- Remove old code only after new system is stable

### 2. **Backward Compatibility**
- Maintain existing UI structure during transition
- Keep all existing functionality working
- Add new features to room system
- Gradual UI updates to match new architecture

### 3. **Testing Strategy**
- Test each room in isolation
- Verify room navigation works correctly
- Ensure save/load compatibility
- Test room unlocking system

## Future Extensibility

### 1. **New Room Types**
- Easy to add specialized rooms (Treasury, Barracks, etc.)
- Room-specific features (training, crafting, etc.)
- Custom room behaviors and interactions

### 2. **Room Modifications**
- Room upgrades and expansions
- Room-specific events and interactions
- Dynamic room content based on guild state

### 3. **Advanced Features**
- Room-specific save states
- Room transition animations
- Room-specific UI themes
- Multi-room interactions

## Conclusion

This refactoring will transform the monolithic guild hall into a modular, extensible room system that's easier to maintain, test, and extend. The inheritance structure provides code reuse while the separation of concerns improves code quality and developer productivity.

The room-based architecture will make it much easier to add new features like the training room, library, workshop, and other specialized areas planned for the guild progression system.
