/*
This file holds EGO datums for things that aren't weapons and armour.
For example, Naked Nest's Serpent Infestation Cure is a non-EGO item from the basegame; it has a datum here.
However, auxiliary non-EGO items from the City gamemodes also have datums here, so they can appear in the Test Range.

When adding something here, you will have to decide whether it should be well blacklisted and whether it should be test range blacklisted.
If you want it in the well, mind that the cost will determine where it appears in its lootpool. These items will also generally not be able to be INSERTED INTO the well, only appear out of it.

Oh please give these a nice name by the way
*/

/datum/ego_datum/auxiliary
	cost = 999
	item_category = "Auxiliary"

/datum/ego_datum/auxiliary/New(datum/abnormality/DA)
	. = ..()
	if(!item_path)
		return
	var/atom/E = new item_path(src)

	// Filling out Information. This is a list that contains a bunch of stuff we'd like to pass into interfaces so we can display it on the EGO Purchase Console and the EGO Printer.
	information["name"] = src.name ? src.name : E.name // Use datum name where possible, otherwise use item's name
	information["description"] = E.desc

// Naked Nest - Cure (Can also be bought from the Cargo Console)
/datum/ego_datum/auxiliary/exuviae
	name = "Naked Nest Cure"
	item_category = "Extract"
	item_path = /obj/item/serpentspoison
	cost = 20
	ego_tags = list(EGO_TAG_SUSTAIN, EGO_TAG_SUPPORT)

// Jester of Nihil - Ace of Hearts/Spades/Diamonds/Clubs
// These are loot drops from defeating Nihil that can be used to upgrade Magical Girl/Jester of Nihil EGO armour/weapons.
// They are well blacklisted because the wishing well already has them hardcoded into a whitelist. If we ever rework the wishing well, we can make it use these datums instead.
/datum/ego_datum/auxiliary/nihil_card_heart
	name = "Ace of Hearts"
	item_category = "Consumable"
	item_path = /obj/item/nihil/heart
	cost = 150
	well_enabled = FALSE

/datum/ego_datum/auxiliary/nihil_card_spade
	name = "Ace of Spades"
	item_category = "Consumable"
	item_path = /obj/item/nihil/spade
	cost = 150
	well_enabled = FALSE

/datum/ego_datum/auxiliary/nihil_card_diamond
	name = "Ace of Diamonds"
	item_category = "Consumable"
	item_path = /obj/item/nihil/diamond
	cost = 150
	well_enabled = FALSE

/datum/ego_datum/auxiliary/nihil_card_club
	name = "Ace of Clubs"
	item_category = "Consumable"
	item_path = /obj/item/nihil/club
	cost = 150
	well_enabled = FALSE

// Thumb East Ammo Boxes
// Hold ammo used to power Thumb East weapon combos. Surplus are the boxes that appear in LC13, the rest are all from CoL.
/datum/ego_datum/auxiliary/thumb_east_ammobox
	name = "Thumb East Ammo Box: Surplus"
	origin = "City"
	item_category = "Ammo"
	item_path = /obj/item/storage/box/thumb_east_ammo
	cost = 40
	well_enabled = FALSE

/datum/ego_datum/auxiliary/thumb_east_ammobox/scorch
	name = "Thumb East Ammo Box: Scorch"
	item_path = /obj/item/storage/box/thumb_east_ammo/scorch
	cost = 60

/datum/ego_datum/auxiliary/thumb_east_ammobox/quake
	name = "Thumb East Ammo Box: Quake"
	item_path = /obj/item/storage/box/thumb_east_ammo/quake
	cost = 65

/datum/ego_datum/auxiliary/thumb_east_ammobox/inferno
	name = "Thumb East Ammo Box: Inferno"
	item_path = /obj/item/storage/box/thumb_east_ammo/inferno
	cost = 65

/datum/ego_datum/auxiliary/thumb_east_ammobox/tigermark
	name = "Thumb East Ammo Box: Tigermark"
	item_path = /obj/item/storage/box/thumb_east_ammo/tigermark
	cost = 80

// Middle Book of Vengeance and subtypes
// Mark attackers with Vengeance mark and provide IFF for Big Brother's leap.
// You can actually get them in both LC13 and COL.
/datum/ego_datum/auxiliary/middle_book
	name = "Book of Vengeance"
	origin = "City"
	item_category = "Accessory"
	item_path = /obj/item/storage/book/middle
	cost = 40
	well_enabled = FALSE
	ego_tags = list(EGO_TAG_DEBUFFER)

/datum/ego_datum/auxiliary/middle_book/younger
	name = "Book of Vengeance (Younger)"
	item_path = /obj/item/storage/book/middle/younger
	cost = 55

/datum/ego_datum/auxiliary/middle_book/big
	name = "Great Book of Vengeance"
	item_path = /obj/item/storage/book/middle/big
	cost = 70
