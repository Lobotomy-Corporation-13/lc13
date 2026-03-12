//this is in a separate file other than the weak_edits cuz it has a good chunk of code
//fell bullet isnt in here cuz it doesnt have justice scaling
//sticking ego WILL be in here

/obj/item/ego_weapon/mini/fourleaf_clover/city // buffed red damage to the same dmg/atk-spd as BL blade
	force = 46
	attack_speed = 1.2
	icon_state = "sticking"
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
	)

/obj/item/ego_weapon/perversion/weak
	name = "N. Corp E.G.O. 'Perversion'"
	desc = "A twisting, ornate polearm extracted for the League of Nine. \n\
	'Be awed, or be awe-struck.'"
	special = "This weapon has two forms, each with differing special attacks. In its Lance form, it inflicts Gaze on targets, and in its Katana form, it deals additional damage to targets with Gaze. \n\
	Switching the weapon from Lance to Katana form has a cooldown, and performs a special attack, which damages every living thing, including you."
	friendlyfire = TRUE
	justicescale = FALSE
