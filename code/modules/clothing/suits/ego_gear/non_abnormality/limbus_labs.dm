
/obj/item/clothing/suit/armor/ego_gear/city/udjat_limbus
	name = "LCA Udjat Scout Armor"
	desc = "It says Limbus Company on the tag. Used by limbus Udjat officers."
	icon_state = "udjat"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 20)

/obj/item/clothing/suit/armor/ego_gear/city/udjat_combat
	name = "LCA Udjat Combat Armor"
	desc = "LCA Udjat heavy armor. Quite heavy, and will slow your movement."
	icon_state = "udjat_combat"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 60, BLACK_DAMAGE = 60, PALE_DAMAGE = 40)
	slowdown = 0.2



///Old Stuff we shouldn't use anymore.
/obj/item/clothing/suit/armor/ego_gear/limbus_labs
	name = "limbus company low-security armor"
	desc = "It says Limbus Company on the tag. Used by low-security officers."
	icon_state = "lowsec"
	icon = 'icons/obj/clothing/ego_gear/limbus_labs.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/limbus_labs.dmi'
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 0)

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/highsec
	name = "limbus company high-security armor"
	desc = "It says Limbus Company on the tag. Used by high-security officers."
	icon_state = "lccb"

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/jacket
	name = "limbus company kevlar coat"
	desc = "It says Limbus Company on the tag. Used by specific officers."
	flags_inv = NONE
	icon_state = "damageofficer"
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/jacket
	name = "limbus company kevlar coat"
	desc = "It says Limbus Company on the tag. Used by junior officers."
	icon_state = "lccb_officer"
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/hsc
	name = "limbus company high-sec commander jacket"
	desc = "It says Limbus Company on the tag. Used by the high security commander."
	icon_state = "lccb_hsc"
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/lsc
	name = "limbus company low-sec commander jacket"
	desc = "It says Limbus Company on the tag. Used by the low security commander."
	icon_state = "lccb_lsc"
	equip_delay_self = 0


//Hats
/obj/item/clothing/head/beret/sec/lccb_commander
	name = "lccb officer cap"
	desc = "A black cap used by limbus company commanders"
	icon_state = "lccb_cap"

/obj/item/clothing/head/beret/sec/lccb
	name = "lccb riot helmet"
	desc = "A helmet used by lccb."
	icon_state = "lccb_helmet"
	flags_inv = HIDEHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES|HEADCOVERSMOUTH
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""

//Labcoats
/obj/item/clothing/suit/armor/ego_gear/limbus_labs/cmo
	name = "limbus company CMO labcoat"
	desc = "It says Limbus Company on the tag. Used by the Limbus Company Chief Medical Officer."
	icon_state = "cmo"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/doctor
	name = "limbus company doctor labcoat"
	desc = "It says Limbus Company on the tag. Used by the Limbus Company Surgeon."
	icon_state = "doctor"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/chem
	name = "limbus company pharmacist labcoat"
	desc = "It says Limbus Company on the tag. Used by the Limbus Company Pharmacist."
	icon_state = "pharmacist"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/lr
	name = "limbus company LR labcoat"
	desc = "It says Limbus Company on the tag. Used by the Limbus Company Lead Researcher."
	icon_state = "lr"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/sresearch
	name = "limbus company SR labcoat"
	desc = "It says Limbus Company on the tag. Used by the Limbus Company Senior Researcher."
	icon_state = "seniorresearch"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/research
	name = "limbus company research labcoat"
	desc = "It says Limbus Company on the tag. Used by Limbus Company Researchers."
	icon_state = "research"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0

/obj/item/clothing/suit/armor/ego_gear/limbus_labs/arch
	name = "limbus company archivist labcoat"
	desc = "It says Limbus Company on the tag. Used by Limbus Company Archivists."
	icon_state = "paperwork"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	equip_delay_self = 0


//LCE Research issue - the brown longcoat. Subtypes /limbus rather than /limbus_labs because
//that is the parent carrying limbus_suits.dmi / limbus_suit.dmi, where the sprite lives.
/obj/item/clothing/suit/armor/ego_gear/limbus/lce_longcoat
	name = "LCE longcoat"
	desc = "A heavy brown longcoat with red piping at the lapel and cuff. Standard issue to Limbus Company Extraction research staff, and the only armour most of them will ever wear."
	icon_state = "lce_longcoat"
	flags_inv = NONE
	armor = list(RED_DAMAGE = 10, WHITE_DAMAGE = 10, BLACK_DAMAGE = 10, PALE_DAMAGE = 0)
	equip_delay_self = 0
