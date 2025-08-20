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
  - [ ] Implement experience display in character panels (current XP / XP needed for next level)
  - [ ] Add experience bar visualization in character panels

- [x] **Leveling Mechanics**
  - [x] Implement class-based stat gain system with probabilities
  - [x] Add quality-based bonuses to stat gain chances and amounts
  - [x] Create character variance through randomized stat gains (0-3 per stat)
  - [x] Balance experience requirements for different ranks (F to SSS)
  - [x] Add bonus experience for quests with higher success rates
  - [ ] Implement experience sharing between party members
  - [ ] Add experience penalties for failed quests
  - [ ] Create "rest bonus" system for characters who haven't quested recently

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
- [ ] **Training Facilities**
  - [ ] Add training room for manual stat improvement
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

## Future Tasks
- [ ] Add art assets for quest panels
- [ ] Implement hover states for quest panels
- [ ] Add sound effects for quest selection
