# Inventory System Redesign Checklist - Idle Guild Management Game

Based on analysis of the current system and idle game requirements, here's a comprehensive checklist for redesigning the inventory system for guild management and character progression.

## 🏗️ **Architecture & Design**

### **Core Inventory System**
- [ ] **Redesign Inventory Class Structure**
  - [ ] Create `InventoryManager` singleton (similar to GuildManager pattern)
  - [ ] Implement `InventoryItem` with enhanced properties (rarity, stats, durability)
  - [ ] Add `InventorySlot` system for better organization
  - [ ] Create `ItemDatabase` for centralized item definitions

- [ ] **Modular Room Integration**
  - [ ] Design `InventoryAccess` interface that all rooms can implement
  - [ ] Create room-specific inventory filters and permissions
  - [ ] Implement inventory context switching (what items are relevant per room)
  - [ ] Add inventory state management per room

### **Data Structure Redesign**
- [ ] **Enhanced Item Properties**
  - [ ] Item categories: Equipment, Consumables, Materials, Quest Items, Key Items
  - [ ] Item quality tiers (1-star, 2-star, 3-star) - consistent with character system
  - [ ] Item rarity system (Common → Legendary) - WoW-style quality spread
  - [ ] Item flags system (crafting, trading, contracts, consumables, etc.)
  - [ ] Equipment stat bonuses (multiplicative [x] and additive [+] modifiers)
  - [ ] Consumable charges system (1-use, multi-use, infinite use)
  - [ ] Item value system for trading and economy

- [ ] **Inventory Organization**
  - [ ] Tabbed inventory UI (All Items, Crafting, Trading, Contracts, Consumables, Key Items)
  - [ ] Item stacking (up to 999 for most items)
  - [ ] Specialized storage upgrades (Crafting Warehouse, etc.)
  - [ ] Item sorting (Newest, Base Value, Name)
  - [ ] Search functionality with monochrome filtering
  - [ ] Key items (no inventory space, separate tab only)

## 🏛️ **Room Integration Patterns**

### **Universal Inventory Access**
- [ ] **BaseRoom Integration**
  - [ ] Add inventory access methods to `BaseRoom` class
  - [ ] Implement room-specific inventory context
  - [ ] Create inventory state persistence per room

- [ ] **Room-Specific Inventory Features**
  - [ ] **Main Hall**: Overview of all items, quest consumable assignment
  - [ ] **Roster Room**: Equipment management, character gear assignment (right-click menu)
  - [ ] **Quests Room**: Quest consumables, field item slots, auto-consume slots
  - [ ] **Recruitment Room**: Character recruitment (no inventory items needed)
  - [ ] **Training Room**: Training materials, character enhancement items
  - [ ] **Merchant's Guild**: Trading interface, item valuation, excess item sales
  - [ ] **Blacksmith's Guild**: Equipment crafting materials, equipment upgrades, material processing
  - [ ] **Healer's Guild**: Healing consumables, medical supplies
  - [ ] **Auction/Market Room**: Rare item auctions, high-value sales (150-250% base value)

### **Inventory Context System**
- [ ] **Context-Aware Filtering**
  - [ ] Each room shows relevant items based on context
  - [ ] Smart filtering (e.g., "Show items needed for current quest")
  - [ ] Quick actions based on room context

- [ ] **Cross-Room Item Usage**
  - [ ] Items can be used across multiple rooms
  - [ ] Item effects persist across room transitions
  - [ ] Shared item state management

## 🎨 **UI/UX Design**

### **Inventory Interface Components**
- [ ] **Main Inventory Panel**
  - [ ] Grid-based item display
  - [ ] Drag-and-drop functionality
  - [ ] Item tooltips with detailed information
  - [ ] Quick-use buttons for consumables

- [ ] **Room-Specific Inventory Views**
  - [ ] Compact inventory widgets for each room
  - [ ] Context-sensitive item actions
  - [ ] Quick access to relevant items
  - [ ] Item requirement indicators

### **Inventory Management UI**
- [ ] **Item Management**
  - [ ] Item sorting (name, value, rarity, type)
  - [ ] Item filtering and search
  - [ ] Bulk operations (sell, use, transfer)
  - [ ] Item comparison interface

- [ ] **Inventory Expansion**
  - [ ] Inventory capacity upgrades
  - [ ] Storage expansion options
  - [ ] Item organization tools

## 🔧 **Technical Implementation**

### **Integration with Existing Systems**
- [ ] **GuildManager Integration**
  - [ ] Add inventory to GuildManager's resource management
  - [ ] Integrate with existing save/load system
  - [ ] Connect with quest reward system
  - [ ] Link with character equipment system

- [ ] **Signal System Integration**
  - [ ] Add inventory-related signals to SignalBus
  - [ ] Implement inventory change notifications
  - [ ] Create room-specific inventory events

### **Data Persistence**
- [ ] **Save/Load System**
  - [ ] Integrate inventory with existing save slots
  - [ ] Implement inventory data migration
  - [ ] Add inventory backup/restore functionality

- [ ] **Performance Optimization**
  - [ ] Lazy loading for large inventories
  - [ ] Item caching system
  - [ ] Efficient inventory updates

## 🎮 **Idle Game Specific Features**

### **Character Equipment System**
- [ ] **Equipment Slots**
  - [ ] Add equipment slots to Character class (weapon, armor, accessories)
  - [ ] Update character serialization to save equipment data
  - [ ] Equipment affects quest success rates and stat bonuses
  - [ ] Equipment quality tiers (1-star, 2-star, 3-star)

- [ ] **Equipment Assignment**
  - [ ] Right-click menu for character equipment assignment
  - [ ] Equipment popup/UI for manual gear assignment
  - [ ] Equipment comparison and stat preview
  - [ ] Equipment upgrade system at Blacksmith's Guild

### **Quest Integration System**
- [ ] **Quest Rewards**
  - [ ] Equipment rewards (guaranteed on rare quests, 2-5% bonus chance)
  - [ ] Material rewards (quest-type specific: hunting→monster parts, escort→trade documents)
  - [ ] Quest items (guaranteed from main story, unlock bonus missions)
  - [ ] Update CompactQuestCard and Quest classes for new reward system

- [ ] **Consumable Integration**
  - [ ] Field item slots (unlockable upgrade)
  - [ ] Consumable charges system (1-use, multi-use, infinite use)
  - [ ] Quest-specific consumable bonuses
  - [ ] Auto-consume slots for quest automation
  - [ ] Consumable return system (items with charges return after quest completion)

### **Material Processing System**
- [ ] **Raw Materials**
  - [ ] Monster parts and natural materials (ore, wood, fibers)
  - [ ] Quest-type specific material rewards
  - [ ] Material processing at guilds (ore→ingots at Blacksmith's Guild)
  - [ ] Material crafting into equipment and building components

- [ ] **Sub-stat Bonuses**
  - [ ] Materials enhance quest success rates
  - [ ] Flat [+] modifiers for substat-related item rewards
  - [ ] Multiplicative [x] bonuses for substat effectiveness
  - [ ] Materials consumed when quest starts (not by characters)

### **Economy & Trading System**
- [ ] **Vendor System**
  - [ ] Excess item sales at Merchant's Guild
  - [ ] Dynamic pricing (more sales = lower prices, cap at 15% of base value)
  - [ ] Item value system with @export var value: int = 0
  - [ ] Sell price modifiers and upgrades

- [ ] **Auction/Market System**
  - [ ] Auction/Market room for rare items
  - [ ] Auction slots with timers
  - [ ] Success chance for auctions
  - [ ] Sale price range (150-250% of base value)
  - [ ] High-value item sales

### **Automation & Quality of Life**
- [ ] **Auto-Consume System**
  - [ ] Auto-consume slots at Quest Board
  - [ ] Automatic consumable assignment to quests
  - [ ] Reduced effectiveness for auto-consumed items
  - [ ] Lock slots until quest completion

- [ ] **Inventory Management**
  - [ ] New item notifications (first time only)
  - [ ] Item codex UI for discovered items
  - [ ] Inventory capacity checks for quest completion
  - [ ] "Accept and Sell Remaining" option for full inventory
  - [ ] Inventory access during quest reward overflow

## 🧪 **Testing & Quality Assurance**

### **System Testing**
- [ ] **Room Integration Testing**
  - [ ] Test inventory access in all rooms
  - [ ] Verify room-specific filtering works
  - [ ] Test cross-room item usage
  - [ ] Validate inventory state persistence

- [ ] **Edge Case Testing**
  - [ ] Full inventory scenarios
  - [ ] Item stacking edge cases
  - [ ] Save/load with complex inventories
  - [ ] Performance with large item counts

### **User Experience Testing**
- [ ] **Usability Testing**
  - [ ] Inventory navigation flow
  - [ ] Item management efficiency
  - [ ] Room transition smoothness
  - [ ] UI responsiveness

## 📋 **Implementation Priority**

### **Phase 1: Core Foundation** ✅ **COMPLETED**
1. ✅ Redesign InventoryManager singleton
2. ✅ Create enhanced InventoryItem class
3. ✅ Implement basic room integration
4. ✅ Add inventory to save/load system

### **Phase 2: Character Equipment System**
1. Add equipment slots to Character class
2. Update character serialization for equipment
3. Create equipment assignment UI (right-click menu)
4. Implement equipment stat bonuses and modifiers
5. Add tooltip system to theme.tres

### **Phase 3: Quest Integration**
1. Update quest reward system (equipment, materials, consumables)
2. Implement consumable charges system
3. Create field item slots and auto-consume system
4. Update CompactQuestCard and Quest classes
5. Add material processing system

### **Phase 4: Inventory UI & Management**
1. Create tabbed inventory UI with filtering
2. Implement specialized storage upgrades
3. Add search functionality and sorting
4. Create inventory capacity checks
5. Add new item notifications

### **Phase 5: Economy & Trading**
1. Implement vendor system with dynamic pricing
2. Create auction/market room
3. Add item value system
4. Implement excess item sales

### **Phase 6: Polish & Testing**
1. Comprehensive testing across all systems
2. UI/UX refinements and tooltips
3. Performance optimization
4. Documentation and cleanup

## 🔗 **Integration Points**

The inventory system should integrate with:
- **GuildManager**: Resource management, save/load
- **Room System**: Context-aware access, state management
- **Quest System**: Item requirements, rewards
- **Character System**: Equipment, consumables
- **UI System**: Responsive layout, theming
- **Signal System**: Event notifications, state changes

## 📝 **Current System Analysis**

### **Existing Components**
- ✅ Basic `Inventory` class with slot management
- ✅ `InventoryItem` class with basic properties
- ✅ Room-specific item filters in current inventory
- ✅ Save/load functionality for inventory data

### **Integration Patterns**
- ✅ Rooms access GuildManager directly for resources
- ✅ BaseRoom class provides common room functionality
- ✅ Signal system for room and state changes
- ✅ Centralized resource management in GuildManager

### **Areas for Improvement**
- 🔄 Convert inventory to singleton pattern (like GuildManager)
- 🔄 Enhance item properties and categorization
- 🔄 Improve room-specific inventory access
- 🔄 Add advanced inventory management features
- 🔄 Integrate with equipment and character systems

This modular approach ensures that the inventory system enhances every room while maintaining clean separation of concerns and allowing for easy expansion and modification.
