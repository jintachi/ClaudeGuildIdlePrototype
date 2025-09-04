# TODO List

## Completed Tasks
- [x] Create notification system with fade in/wait/fade out functionality
- [x] Add quest completion notification (fade in, 5s wait, fade out)
- [x] Add quest start notification
- [x] Replace quest completion popup with 'Quest Complete: Accept Results' button
- [x] Refresh quest panel after sending party on quest
- [x] Reset quest tab to show 'Select a quest first' message after quest dispatch
- [x] Fix stats comparison table disappearing when adding characters to party
- [x] Convert quest panels to clickable selection with visual states
- [x] Auto-select first quest when entering quest tab
- [x] Remove individual 'Select Quest' buttons from quest panels
- [x] Add highlighted border and darker background for selected quest
- [x] Implement theme-based quest panel selection system
- [x] Add injury notifications for party members injured on quests
- [x] Add quest completion text display in main hall showing party members and rewards
- [x] Redesign main hall with side-by-side active and completed quests panels
- [x] Fix completed quest display showing current injury state instead of completion-time injury state
- [x] Add in-game UI scaling controls (preset scale buttons: 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
- [x] Fix UI scaling runtime errors (enum access and theme property access)
- [x] Implement Training Room with character potential system, training courses, and compatibility bonuses

## Current Tasks
- [x] Fix stats comparison table update issues between quest selection and party management
- [x] Implement injury notifications and quest completion display
- [x] Redesign main hall layout with completed quests panel
- [x] Fix injury state persistence bug in completed quest display
- [x] Implement in-game UI scaling controls (preset scale options)
- [x] Debug and fix UI scaling runtime errors
- [x] Replace +/- UI scale buttons with preset scale options (0.5, 0.75, 1.0, 1.5, 2.0, 3.0)

## Character Progression System

### Experience & Leveling
- [x] **Experience System Enhancement**
  - [x] Add experience gain from quest completion (based on quest difficulty and success rate)
  - [x] Implement enhanced experience calculation with multiple factors
  - [x] Add experience multipliers for different quest types (combat vs. gathering vs. social)
  - [x] Create level-up notification system with stat increase display
  - [x] Implement experience display in character panels (current XP / XP needed for next level)
  - [x] Add experience bar visualization in character panels
    - [x] Created reusable ExperienceBar component with color-coded progress
    - [x] Integrated into Adventurer Inspection Panel with full experience display
    - [x] Added to character panels in guild hall with compact mode
    - [x] Enhanced party selection tooltips with experience information
    - [x] Added to recruit panels for experienced characters
    - [x] Implemented automatic refresh after quest completion

- [x] **Leveling Mechanics**
  - [x] Implement class-based stat gain system with probabilities
  - [x] Add quality-based bonuses to stat gain chances and amounts
  - [x] Create character variance through randomized stat gains (0-3 per stat)
  - [x] Balance experience requirements for different ranks (F to SSS)
  - [x] Add bonus experience for quests with higher success rates
  - [x] Implement experience sharing between party members
- [x] Add experience penalties for failed quests
- [ ] Create "rest bonus" system for characters who haven't quested recently (TODO: Implement after Inn system is added)

### Skill & Substat Progression
- [ ] **Substat Development**
  - [ ] Enhance substat improvement system (currently 10% chance per quest)
  - [ ] Add substat training facilities in guild hall
  - [ ] Create substat specialization paths (e.g., Master Gatherer, Elite Diplomat)
  - [ ] Implement substat-based quest bonuses (higher substats = better quest rewards)
  - [ ] Add substat decay system for unused skills over time

- [ ] **Skill Training**
  - [ ] Create training room UI for manual substat improvement
  - [ ] Add training costs (gold, time, resources)
  - [ ] Implement training success rates based on character quality and rank
  - [ ] Add skill books/scrolls as rare quest rewards
  - [ ] Create skill synergy bonuses (e.g., high gathering + high stealth = better rare material gathering)

### Rank & Promotion System
- [ ] **Promotion Mechanics**
  - [ ] Design promotion quest system (currently placeholder)
  - [ ] Create promotion quest generation based on character class and current rank
  - [ ] Add promotion quest difficulty scaling with rank
  - [ ] Implement promotion ceremony/celebration UI
  - [ ] Add rank-based guild benefits (higher ranks unlock better quests)

- [ ] **Rank Benefits**
  - [ ] Add rank-based stat bonuses and multipliers
  - [ ] Implement rank-based quest availability (higher ranks = better quests)
  - [ ] Create rank-based equipment slots and bonuses
  - [ ] Add rank-based guild influence generation
  - [ ] Implement rank-based recruitment costs and requirements

### Character Development UI
- [x] **Enhanced Character Panels**
  - [x] Redesign character panels to show progression information
  - [x] Add experience bar with visual progress indicator
  - [x] Create detailed stat breakdown (base stats vs. rank bonuses vs. equipment)
  - [x] Add substat progress bars and improvement indicators
  - [x] Implement character comparison tool (side-by-side stat comparison)
  - [x] Create Adventurer Inspection Panel with comprehensive character details

- [ ] **Character Details View**
  - [ ] Create detailed character view with full progression history
  - [ ] Add quest history and performance tracking
  - [ ] Implement character achievements and milestones
  - [ ] Create character biography and personality traits
  - [ ] Add character relationship system (mentorship, rivalry, friendship)

### Equipment & Gear System
- [ ] **Equipment Basics**
  - [ ] Design equipment system (weapons, armor, accessories)
  - [ ] Create equipment stats and bonuses
  - [ ] Implement equipment requirements (level, rank, class)
  - [ ] Add equipment durability and maintenance system
  - [ ] Create equipment crafting and enhancement system

- [ ] **Equipment Progression**
  - [ ] Add equipment tiers (Common, Uncommon, Rare, Epic, Legendary)
  - [ ] Implement equipment set bonuses
  - [ ] Create equipment enhancement/enchantment system
  - [ ] Add equipment specialization for different quest types
  - [ ] Implement equipment trading and marketplace

### Class Specialization
- [ ] **Class Abilities**
  - [ ] Implement class-specific abilities (currently placeholder)
  - [ ] Create ability unlock system based on rank and level
  - [ ] Add ability cooldowns and resource costs
  - [ ] Implement ability synergy between party members
  - [ ] Create ability training and improvement system

- [ ] **Class Progression Paths**
  - [ ] Design class specialization trees (e.g., Tank → Guardian vs. Berserker)
  - [ ] Create multi-classing system for high-level characters
  - [ ] Add class-specific quest types and bonuses
  - [ ] Implement class-based guild roles and responsibilities
  - [ ] Create class-specific equipment and abilities

### Character Management
- [ ] **Character Retirement & Succession**
  - [ ] Implement character retirement system (age, injury, personal choice)
  - [ ] Create character succession (passing knowledge to new recruits)
  - [ ] Add character legacy system (retired characters provide guild benefits)
  - [ ] Implement character death system for dangerous quests
  - [ ] Create character memorial and tribute system

- [ ] **Character Relationships**
  - [ ] Add character relationship system (mentorship, rivalry, romance)
  - [ ] Implement relationship bonuses for questing together
  - [ ] Create character personality traits and compatibility
  - [ ] Add character backstory generation and development
  - [ ] Implement character loyalty and guild commitment system

### Quality & Rarity System
- [ ] **Quality Progression**
  - [ ] Implement quality improvement system (1-star to 3-star)
  - [ ] Create quality-based stat bonuses and multipliers
  - [ ] Add quality-based recruitment costs and rarity
  - [ ] Implement quality-based quest availability and rewards
  - [ ] Create quality-based character potential and growth rates

### Guild Hall Progression
- [x] **Training Facilities**
  - [x] Add training room for manual stat improvement
  - [ ] Create library for skill book storage and research
  - [ ] Implement workshop for equipment crafting and enhancement
  - [ ] Add medical bay for injury treatment and prevention
  - [ ] Create barracks for character rest and recovery bonuses

- [ ] **Guild Benefits**
  - [ ] Implement guild level system based on member progression
  - [ ] Add guild-wide bonuses for high-level members
  - [ ] Create guild reputation system affecting quest availability
  - [ ] Implement guild treasury and resource management
  - [ ] Add guild events and challenges for member progression

## Quest Balancing & Debugging
- [x] **Quest Completion Auto-Save**
  - [x] Save game immediately when quest completion is triggered
  - [x] Ensure quest state is preserved in save data
  - [x] Handle offline progress for active quests

- [x] **Success Chance Display**
  - [x] Show suggested success chance for quests in UI
  - [x] Color-code success chances (green/yellow/orange/red)
  - [x] Update success chance when party selection changes
  - [x] Display success chance percentage in quest panels

- [x] **Enhanced Success Calculation**
  - [x] Higher stats over requirements = easier completion
  - [x] Stat overage bonuses (each point over requirement adds bonus)
  - [x] Substat matching characters get better chances
  - [x] Substat overage bonuses (points over requirement add significant bonus)
  - [x] Individual character success calculation based on their contribution

- [x] **Quest Balancing Improvements**
  - [x] Implement stat overage bonus system
  - [x] Enhanced substat relevance bonuses
  - [x] Individual character success chance calculation
  - [x] Better quest completion logic with proper success rates

## Character Recruitment System Enhancement

### Recruitment UI & Experience
- [ ] **Enhanced Recruitment Interface**
  - [ ] Redesign recruitment panel with character portraits and detailed previews
  - [ ] Add character backstory generation and display during recruitment
  - [ ] Implement character personality traits and compatibility indicators
  - [ ] Create recruitment cost breakdown with resource preview
  - [ ] Add recruitment success rate indicators based on guild reputation
  - [ ] Implement recruitment filters (class, quality, cost range, etc.)

- [ ] **Character Customization**
  - [ ] **Add character renaming functionality** - Allow players to rename characters after recruitment
  - [ ] Implement character appearance customization (portrait selection from available options)
  - [ ] Add character biography editing and personal history creation
  - [ ] Create character personality trait selection and modification
  - [ ] Implement character background story customization
  - [ ] Add character voice/accent selection for flavor text

- [ ] **Recruitment Mechanics**
  - [ ] Implement recruitment quality scaling based on guild level and reputation
  - [ ] Add recruitment events and special character appearances
  - [ ] Create recruitment contracts with different terms and benefits
  - [ ] Implement recruitment competition with other guilds
  - [ ] Add recruitment bonuses for successful quest completion streaks
  - [ ] Create recruitment penalties for failed quests or guild reputation loss

### Character Preview & Information
- [ ] **Detailed Character Preview**
  - [ ] Add full character stat preview before recruitment
  - [ ] Implement character potential and growth rate indicators
  - [ ] Create character compatibility analysis with current roster
  - [ ] Add character quest history and performance predictions
  - [ ] Implement character personality compatibility with existing members
  - [ ] Create character special abilities and unique traits preview

- [ ] **Recruitment Decision Support**
  - [ ] Add character comparison tools for multiple candidates
  - [ ] Implement roster gap analysis (what classes/roles are needed)
  - [ ] Create recruitment cost-benefit analysis
  - [ ] Add character potential vs. immediate value assessment
  - [ ] Implement recruitment recommendations based on current guild needs

### Recruitment Progression
- [ ] **Recruitment Facility Upgrades**
  - [ ] Add recruitment office upgrades for better candidate quality
  - [ ] Implement recruitment network expansion for wider candidate pool
  - [ ] Create recruitment training for guild staff to improve candidate assessment
  - [ ] Add recruitment advertising and reputation building
  - [ ] Implement recruitment events and job fairs

- [ ] **Advanced Recruitment Features**
  - [ ] Add recruitment contracts with different terms (temporary, permanent, apprenticeship)
  - [ ] Implement character referrals from existing guild members
  - [ ] Create recruitment quests to test candidate abilities
  - [ ] Add recruitment interviews and character interaction
  - [ ] Implement recruitment bonuses for successful character development

## Save System Enhancement
- [x] **Multi-Slot Save System**
  - [x] Implement 3 save slots in a single JSON file
  - [x] Create save slot selection UI with slot information display
  - [x] Add load, new game, and delete functionality for each slot
  - [x] Implement save file migration from old single-slot format
  - [x] Add confirmation dialogs for overwrite and delete operations
  - [x] Display save slot information (influence, gold, members, save date)

## Quest Management Improvements
- [x] **Quest Completion UI Redesign**
  - [x] Separate active quests from awaiting completion quests
  - [x] Create dedicated "Awaiting Completion" panel
  - [x] Add "Accept All Completed Quests" button
  - [x] Fix quest panel redrawing issue that prevented clicking accept results
  - [x] Optimize quest display updates to only refresh when needed

## Future Tasks
- [ ] Add art assets for quest panels
- [ ] Implement hover states for quest panels
- [ ] Add sound effects for quest selection

## Inventory System Redesign (Idle Game Focus)

### Character Equipment System
- [ ] **Add equipment slots to Character class** - Add weapon, armor, and accessory slots to character data structure
- [ ] **Update character serialization** - Ensure equipment data is properly saved and loaded
- [ ] **Create right-click menu system** - Implement context menu for character interactions (equipment, training, etc.)
- [ ] **Equipment assignment UI** - Create popup/interface for manually assigning equipment to characters
- [ ] **Equipment stat bonuses** - Implement multiplicative [x] and additive [+] modifiers for equipment
- [ ] **Tooltip system** - Add comprehensive tooltip system to theme.tres with proper styling and fonts

### Quest System Integration
- [ ] **Quest reward system overhaul** - Update quests to reward equipment, materials, and consumables
- [ ] **Equipment rewards** - Add guaranteed equipment on rare quests, 2-5% bonus chance on regular quests
- [ ] **Material rewards** - Implement quest-type specific materials (hunting→monster parts, escort→trade documents)
- [ ] **Quest items** - Add guaranteed quest items from main story, items that unlock bonus missions
- [ ] **Update CompactQuestCard** - Modify quest cards to display new reward types
- [ ] **Update Quest class** - Enhance quest data structure for new reward system

### Consumable System
- [ ] **Consumable charges system** - Implement 1-use, multi-use, and infinite use consumables
- [ ] **Field item slots** - Create unlockable slots for quest consumables (first guild hall upgrade)
- [ ] **Auto-consume slots** - Add automatic consumable assignment at quest board
- [ ] **Quest-specific consumables** - Create consumables that enhance specific quest types
- [ ] **Consumable return system** - Items with charges return after quest completion

### Material Processing
- [ ] **Raw materials system** - Implement monster parts, ore, wood, fibers, etc.
- [ ] **Material processing** - Create guild-based processing (ore→ingots at Blacksmith's Guild)
- [ ] **Sub-stat bonuses** - Materials enhance quest success rates and provide item reward bonuses
- [ ] **Crafting system** - Materials used to create equipment and building components

### Inventory Management
- [ ] **Tabbed inventory UI** - Create All Items, Crafting, Trading, Contracts, Consumables, Key Items tabs
- [ ] **Item stacking** - Implement 999-item stacking with charge display
- [ ] **Specialized storage** - Crafting Warehouse and other storage upgrades
- [ ] **Search and sorting** - Newest, Base Value, Name sorting with search bar
- [ ] **Key items** - Separate tab for items that don't take inventory space
- [ ] **Inventory capacity checks** - Handle quest completion when inventory is full

### Economy & Trading
- [ ] **Vendor system** - Excess item sales at Merchant's Guild with dynamic pricing
- [ ] **Auction/Market room** - New room for rare item auctions (150-250% base value)
- [ ] **Item value system** - Add @export var value: int = 0 to all items
- [ ] **Dynamic pricing** - More sales = lower prices, cap at 15% of base value

### Unlock Progression
- [ ] **Field item slots** - First guild hall upgrade requiring Blacksmith's Guild and Merchant's Guild
- [ ] **Storage upgrades** - Specialized storage unlocks for different item types
- [ ] **Auto-consume system** - Unlockable automation for quest consumables
- [ ] **Auction system** - High-level unlock for rare item sales

### Main Story & Content
- [ ] **Main story quests** - Create main story line with guaranteed quest item rewards
- [ ] **Bonus mission unlocks** - Quest items that unlock special missions with better rewards
- [ ] **Character class unlocks** - Facility upgrades unlock new character classes for recruitment
