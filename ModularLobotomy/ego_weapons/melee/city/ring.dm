// The Ring - Syndicate of Artists
// Corporist School - Utilizes interaction between human bones and muscles
// "Those who utilize the interaction between human bones and muscles, and the contraction and elongation thereof."

// Tibia - Maestro Callisto's weapon, made from his own body
/obj/item/ego_weapon/city/ring/tibia
	name = "Tibia"
	desc = "A massive weapon composed of Callisto's own body. Several large pointed notches line its blade, designed to sculpt flesh with artistic precision."
	icon_state = "tibia"
	inhand_icon_state = "tibia"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 120
	damtype = RED_DAMAGE
	attack_speed = 1.8
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("sculpts", "carves", "reshapes", "cleaves")
	attack_verb_simple = list("sculpt", "carve", "reshape", "cleave")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

// Fascia - Corporist Apprentice's greatsword
/obj/item/ego_weapon/city/ring/fascia
	name = "Fascia"
	desc = "A white and yellow greatsword carried by Corporist apprentices. A removable panel on its side conceals a dark, skeletal frame with an interior made of viscera and ribs."
	icon_state = "fascia"
	inhand_icon_state = "fascia"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 90
	damtype = RED_DAMAGE
	attack_speed = 1.4
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slashes", "cuts", "cleaves")
	attack_verb_simple = list("slash", "cut", "cleave")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)
