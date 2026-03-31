// Thumb Spider Weapons
// Thumbfather weapons are subtypes of thumb_east (inherit ammo combo system)
// Thumbapprentice weapons are basic city ego weapons

////////////////////////////////////////////////////////////
// THUMBFATHER WEAPONS - Subtypes of /obj/item/ego_weapon/city/thumb_east
/obj/item/ego_weapon/city/thumb_east/thumbfather_rapier
	name = "thumbfather rapier"
	desc = "A slender, elegant rapier favored by a thumbfather. Its reach is deceptively long."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbfather_rapier"
	inhand_icon_state = "thumbfather_rapier"
	force = 45
	damtype = RED_DAMAGE
	attack_speed = 0.8
	attack_verb_continuous = list("thrusts", "pierces", "lunges")
	attack_verb_simple = list("thrust", "pierce", "lunge")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/city/thumb_east/thumbfather_katana
	name = "thumbfather katana"
	desc = "A finely crafted katana carried by a thumbfather. Each swing carries the weight of authority."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbfather_katana"
	inhand_icon_state = "thumbfather_katana"
	force = 55
	damtype = RED_DAMAGE
	attack_speed = 1.1
	attack_verb_continuous = list("slashes", "cleaves", "cuts")
	attack_verb_simple = list("slash", "cleave", "cut")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

////////////////////////////////////////////////////////////
// THUMBAPPRENTICE WEAPONS - Subtypes of /obj/item/ego_weapon/city
/obj/item/ego_weapon/city/thumbapprentice_katana
	name = "thumb apprentice katana"
	desc = "A standard-issue katana given to apprentices of the Thumb. Simple but effective."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbapprentice_katana"
	inhand_icon_state = "thumbapprentice_katana"
	force = 40
	damtype = RED_DAMAGE
	attack_speed = 1
	attack_verb_continuous = list("slashes", "cuts", "strikes")
	attack_verb_simple = list("slash", "cut", "strike")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/city/thumbapprentice_greatsword
	name = "thumb apprentice greatsword"
	desc = "A heavy greatsword entrusted to apprentices of the Thumb. What it lacks in speed, it makes up for in raw power."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbapprentice_greatsword"
	inhand_icon_state = "thumbapprentice_greatsword"
	force = 55
	damtype = RED_DAMAGE
	attack_speed = 1.5
	attack_verb_continuous = list("cleaves", "smashes", "crushes")
	attack_verb_simple = list("cleave", "smash", "crush")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)
