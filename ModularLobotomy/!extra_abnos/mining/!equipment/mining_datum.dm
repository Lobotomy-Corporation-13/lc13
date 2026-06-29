
/datum/ego_datum/weapon/miningss13
	well_enabled = FALSE
	origin = "Mining Abnos"

/datum/ego_datum/armor/miningss13
	// I'm making this definition just so I can add the origin var to these datum for a test range update. This armor def didn't exist before; it probably should have well_enabled = FALSE
	// But there could be a reason why it wasn't defined at first, maybe having the B12 armours in the well was intentional since they're harmless, so I'm just leaving this notice here
	origin = "Mining Abnos"

// --------TETH---------
// Ice Whelp - Frostbite
/datum/ego_datum/weapon/mining/frostbite
	item_path = /obj/item/ego_weapon/miningss13/whelp_blade
	cost = 20

/datum/ego_datum/armor/mining/frostbite
	item_path = /obj/item/clothing/suit/armor/ego_gear/miningss13/frostbite
	cost = 20

// Goliath - Goliath
/datum/ego_datum/weapon/mining/goliath
	item_path = /obj/item/ego_weapon/miningss13/goliath
	cost = 20

/datum/ego_datum/armor/mining/goliath
	item_path = /obj/item/clothing/suit/armor/ego_gear/miningss13/goliath
	cost = 20

// Hivelord - Ethereal
/datum/ego_datum/weapon/mining/ethereal
	item_path = /obj/item/ego_weapon/miningss13/ethereal
	cost = 20

/datum/ego_datum/armor/mining/ethereal
	item_path = /obj/item/clothing/suit/armor/ego_gear/miningss13/ethereal
	cost = 20
