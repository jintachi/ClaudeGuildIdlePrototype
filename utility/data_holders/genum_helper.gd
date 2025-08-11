## This acts as a middle-layer where if I need strings, but want the consistency of Enums.
class_name GenumHelper

## Used to get the name of an Audio Bus based on its corresponding Enum in [class Genum]
const BUS_NAME : Dictionary[Genum.BusID, String] = {
	Genum.BusID.MASTER: &"Master",
	Genum.BusID.OST: &"OST",
	Genum.BusID.SFX: &"SFX",
	Genum.BusID.UI: &"UI",
	Genum.BusID.AMBIENT: &"Ambient"
}

const ITEM_TIER : Dictionary[StringName, Genum.Rarity] = {
	&"motal": Genum.Rarity.MOTAL,
	&"pebbled": Genum.Rarity.PEBBLED,
	&"cometary": Genum.Rarity.COMETARY,
	&"planetary": Genum.Rarity.PLANETARY,
	&"stellar": Genum.Rarity.STELLAR,
	&"nebulous": Genum.Rarity.NEBULOUS,
	&"cosmic": Genum.Rarity.COSMIC
}

const MATERIAL_TYPE : Dictionary[Genum.MaterialType, StringName] = {
	Genum.MaterialType.CLOTH: &"cloth",
	Genum.MaterialType.DUST: &"dust",
	Genum.MaterialType.LEATHER: &"leather",
	Genum.MaterialType.WOOD: &"wood",
	Genum.MaterialType.METAL: &"metal"
}
