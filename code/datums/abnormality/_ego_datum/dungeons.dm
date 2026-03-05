/*
This file holds the datums for weapons and/or gear exclusive to Away Missions and similar dungeons, I.E. the Outskirts Factory.
If you're wondering |WHY|, it's so that they can appear in the Test Range.
There are, presumably, other ways to do this, but this is the one that integrates the most cleanly with the current systems (maybe, I didn't make them).

In any case, none of these weapons or gear should be available in the Well, as they are made for the sole purpose of serving as loot in their respective dungeon(s).
Feel free to add your weapons if you make new dungeons with unique gear. -Xeros
*/

/*
------------------ Outskirts Factory (AKA the Grungeon) -------------------
*/

/datum/ego_datum/weapon/painprocess
	item_path = /obj/item/ego_weapon/painprocess
	cost = 100
	well_enabled = FALSE
	ego_tags = list(EGO_TAG_MULTIHIT, EGO_TAG_KNOCKBACK)

/datum/ego_datum/weapon/malicedescent
	item_path = /obj/item/ego_weapon/ranged/malicedescent
	cost = 100
	well_enabled = FALSE
	ego_tags = list(EGO_TAG_MULTIHIT, EGO_TAG_HAZARDOUS, EGO_TAG_SPLIT_DAMAGE)
