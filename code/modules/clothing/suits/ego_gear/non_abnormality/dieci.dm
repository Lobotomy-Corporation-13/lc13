// Dieci Association Armor — Section 4

/// Associate-tier Dieci armor. Standard-issue black robes. Heavy tomes weigh you down.
/obj/item/clothing/suit/armor/ego_gear/city/dieci
	name = "dieci association gear"
	desc = "A dark robe with golden trim worn by Dieci Association members. The weight of knowledge slows the wearer."
	icon = 'icons/obj/clothing/ego_gear/dieci_icon.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/dieci_worn.dmi'
	icon_state = "dieci_mook"
	slowdown = 0.2
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 40)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/// Veteran-tier Dieci armor. Improved protection for experienced members.
/obj/item/clothing/suit/armor/ego_gear/city/dieci/vet
	name = "dieci association veteran gear"
	desc = "A long black robe with a yellow scarf used by the veterans of Dieci Association. Reinforced bindings offer better protection at the cost of mobility."
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	icon_state = "dieci_vet"
	slowdown = 0.3
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 60)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/// Director-tier Dieci armor. The finest protection for the section leader.
/obj/item/clothing/suit/armor/ego_gear/city/dieci/director
	name = "dieci association director gear"
	desc = "An ornate black and gold robe worn by the Director of Dieci Association. Laden with protective wards that hinder movement."
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	icon_state = "dieci_vet"
	slowdown = 0.4
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 80)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)
