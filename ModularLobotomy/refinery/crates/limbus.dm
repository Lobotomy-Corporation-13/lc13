
//	LCB Crate - LCB Sinner weapons and EGO.
//	LCC Crate - LCC and LCD Equipment.
//	LCE Crate - LCE EGO and LCA Udjat Equipment.


/obj/structure/lootcrate/limbus
	name = "Limbus Company Bus Crate"
	desc = "A crate recieved from limbus company. Open with a Crowbar."
	icon_state = "crate_lcb"
	rarechance = 15
	cosmeticchance = 25
	lootlist =	list(
		/obj/item/ego_weapon/mini/hayong,
		/obj/item/ego_weapon/shield/parry/walpurgisnacht,
		/obj/item/ego_weapon/lance/suenoimpossible,
		/obj/item/ego_weapon/shield/parry/sangria,
		/obj/item/ego_weapon/mini/soleil,
		/obj/item/ego_weapon/taixuhuanjing,
		/obj/item/ego_weapon/revenge,
		/obj/item/ego_weapon/shield/hearse,
		/obj/item/ego_weapon/mini/hearse,
		/obj/item/ego_weapon/raskolot,
		/obj/item/ego_weapon/vogel,
		/obj/item/ego_weapon/nobody,
		/obj/item/ego_weapon/ungezifer,
		/obj/item/clothing/suit/armor/ego_gear/limbus/limbus_coat,
		/obj/item/clothing/suit/armor/ego_gear/limbus/limbus_coat_short,
	)

	rareloot =	list(
		/obj/item/clothing/suit/armor/ego_gear/limbus/durante,
		/obj/item/ego_weapon/lance/sangre,
		/obj/item/ego_weapon/mini/crow,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/minos,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/cast,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/branch,

	)

	cosmeticloot = list(
		/obj/item/clothing/under/limbus/shirt,
		/obj/item/clothing/accessory/limbusvest,
		/obj/item/clothing/under/limbus/prison,
		/obj/item/clothing/neck/limbus_tie,
	)


/obj/structure/lootcrate/limbus_c
	name = "Limbus Company Clearance Crate"
	desc = "A crate recieved from limbus company. Open with a Crowbar."
	icon_state = "crate_lcc"
	rarechance = 15
	lootlist =	list(
		/obj/item/clothing/suit/armor/ego_gear/limbus_labs,
		/obj/item/ego_weapon/ranged/city/limbuspistol,
		/obj/item/ego_weapon/ranged/city/limbusautopistol,
		/obj/item/ego_weapon/ranged/city/limbusmagnum,
		/obj/item/ego_weapon/ranged/city/limbussmg,
		/obj/item/ego_weapon/ranged/city/limbusshottie,
		/obj/item/ego_weapon/shield/lccb,
		/obj/item/ego_weapon/city/lccb_bat,
		/obj/item/clothing/suit/armor/ego_gear/lccb

	)

	rareloot =	list(
		/obj/item/ego_weapon/shield/parry/osir,
		/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_admin,
		/obj/item/ego_weapon/city/bladelineage/lcd,
		/obj/item/ego_weapon/city/screw_atelier,
		/obj/item/ego_weapon/city/nester,
	)


/obj/structure/lootcrate/limbus_e
	name = "Limbus Company Extraction Crate"
	desc = "A crate recieved from limbus company. Open with a Crowbar."
	icon_state = "crate_lce"
	rarechance = 15
	cosmeticchance = 25
	ammochance = 25
	lootlist =	list(
		/obj/item/clothing/suit/armor/ego_gear/limbus/lce_longcoat,
		/obj/item/clothing/suit/armor/ego_gear/lce/smile,
		/obj/item/clothing/suit/armor/ego_gear/lce/hornet,
		/obj/item/clothing/suit/armor/ego_gear/lce/grinder,
		/obj/item/clothing/suit/armor/ego_gear/lce/unrequited,
		/obj/item/clothing/suit/armor/ego_gear/lce/beak,
		/obj/item/clothing/suit/armor/ego_gear/lce/prank,
		/obj/item/clothing/suit/armor/ego_gear/lce/match,
		/obj/item/clothing/suit/armor/ego_gear/lce/trick,
		/obj/item/clothing/suit/armor/ego_gear/lce/love,
		/obj/item/clothing/suit/armor/ego_gear/lce/despair,
		/obj/item/clothing/suit/armor/ego_gear/lce/acupuncture,

	)

	rareloot =	list(
		/obj/item/ego_weapon/ranged/city/udjat,
		/obj/item/ego_weapon/city/udjat_limbus,
		/obj/item/clothing/suit/armor/ego_gear/city/udjat_limbus,
		/obj/item/clothing/suit/armor/ego_gear/city/udjat_combat,

	)

	cosmeticloot = list(
		/obj/item/clothing/under/suit/lce,
		/obj/item/clothing/under/limbus/labs/commandsec,
	)

	ammoloot =	list(
		/obj/item/ego_mag/udjat,
	)

