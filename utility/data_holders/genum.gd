## This is where all the game's common Enums are listed.
class_name Genum

## The Enum used for Audio Buses.
enum BusID {
	MASTER,
	OST,
	SFX,
	UI,
	AMBIENT
}

## The Enum to attach to items to declare how that item is allowed to interact.
enum ItemTags {
	MATERIAL, ## Used for crafting
	CONSUMABLE, ## Is consumed on use
	SLOTTABLE, ## Can be slotted into equips
	EQUIPMENT, ## Can be equipped
	WEAPON
}

## For declaring the rarity of an Item
enum Rarity {
	MOTAL, ## Tier 1, lvl 1-10
	PEBBLED, ## Tier 2, lvl 11 - 20
	COMETARY, ## Tier 3, lvl 21 - 30
	PLANETARY, ## Tier 4, lvl 31 - 40
	STELLAR, ## Tier 5, lvl 41 - 50
	NEBULOUS, ## Tier 6, lvl 51 - 60
	COSMIC ## Tier 7, lvl 61 - 70
}

enum AspectType {
	VOID,
	MOON,
	SUN,
	STARS,
	ASTEROID
}

enum AffinityType {
	SOLARI,
	ASTRAL,
	LUNARI,
	GRAVITY,
	CELESTIAL,
	RADIANT,
	UMBRAL,
	METEOR,
	COMET,
	IMPACT,
	EMPYRIAN,
	ORRERY
}

enum EquipLocation {
	HELM,
	POWER_CORE,
	SHOULDER,
	BODY,
	WRIST,
	GLOVES,
	WAIST,
	LEGS,
	FEET,
	MODULE,
	FOCUS,
	FRAME,
	AUXILLARY
}

enum MaterialType {
	CLOTH,
	DUST,
	LEATHER,
	METAL,
	WOOD
}

enum StatType {
	HEALTH,
	AETHER,
	ATTACK,
	ATTACK_POWER,
	MAGIC,
	MAGIC_POWER,
	BARRIER,
	STAMINA,
	CRIT_RATE,
	CRIT_DMG,
	EVASION,
	TOT_SPELL_ATK,
	TOT_PHYS_ATK,
	SPELL_DMG_UP,
	ATK_DMG_UP,
	ATH_ON_HIT
}
