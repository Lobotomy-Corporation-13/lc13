//Wedge - Grade 4 with two range.
/obj/item/ego_weapon/city/wedge
	name = "wedge office spear"
	desc = "A black, ornate spear. Some say it pierces any weakness... Though that may just be what the office who used these says."
	icon_state = "wedge"
	force = 74
	reach = 2		//Has 2 Square Reach.
	attack_speed = 1
	stuntime = 5
	damtype = BLACK_DAMAGE

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/item/ego_weapon/city/wedge/neocity
	name = "wedge office operator spear"
	force = 68
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

//Wedge lance - Grade 6
/obj/item/ego_weapon/lance/wedge
	name = "wedge office fixer lance"
	desc = "A black lance with a long, tapered head. Wedge office fixers favor it for keeping a suspect at a distance."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	icon_state = "wedge_lance"
	lefthand_file = 'icons/mob/inhands/96x96_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/96x96_righthand.dmi'
	inhand_x_dimension = 96
	inhand_y_dimension = 96
	force = 64
	attack_speed = 2
	reach = 2
	stuntime = 5
	damtype = BLACK_DAMAGE
	default_attack_verbs = list("pierces", "jabs")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 40,
		TEMPERANCE_ATTRIBUTE = 40,
		JUSTICE_ATTRIBUTE = 40,
	)
