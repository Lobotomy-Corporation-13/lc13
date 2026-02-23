// Dieci Association Armor — Section 4

/// Associate-tier Dieci armor. Standard-issue black robes.
/obj/item/clothing/suit/armor/ego_gear/city/dieci
	name = "dieci association gear"
	desc = "A dark robe with golden trim worn by Dieci Association members."
	icon = 'icons/obj/clothing/ego_gear/dieci_icon.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/dieci_worn.dmi'
	icon_state = "dieci_mook"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 10, BLACK_DAMAGE = 20, PALE_DAMAGE = 20)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/// Veteran-tier Dieci armor. Improved protection for experienced members.
/obj/item/clothing/suit/armor/ego_gear/city/dieci/vet
	name = "dieci association veteran gear"
	desc = "A long black robe with a yellow scarf used by the veterans of Dieci Association."
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	icon_state = "dieci_vet"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 10, BLACK_DAMAGE = 30, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/// Director-tier Dieci armor. The finest protection for the section leader.
/obj/item/clothing/suit/armor/ego_gear/city/dieci/director
	name = "dieci association director gear"
	desc = "An ornate black and gold robe worn by the Director of Dieci Association."
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	icon_state = "dieci_vet"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 20, BLACK_DAMAGE = 30, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)
