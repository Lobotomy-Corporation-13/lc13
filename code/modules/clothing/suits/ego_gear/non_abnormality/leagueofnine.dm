////////////////////////////////////////////////////////////
// technically purely e.g.o flavorwise but with totally different values - u shouldnt be able to get these in base lc13
// contempt & fell bullet onpar w/ theast armor cuz they only get 4 slots LOL
// sticking ego buffed to literally just be a reskin of south thumb soldato

/obj/item/clothing/suit/armor/ego_gear/city/sticking
	name = "N Corp. E.G.O::Sticking"
	desc = "Waiting for the prey to fall into a trap is a vital skill to learn for those who cannot face direct conflict."
	icon_state = "fourleaf_clover"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 20)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/clothing/suit/armor/ego_gear/city/contempt
	name = "N. Corp E.G.O:: Contempt, Awe"
	desc = "Reverence for a being of no significance is followed by a slight self-contempt."
	icon = 'icons/obj/clothing/ego_gear/abnormality/waw.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/abnormality/waw.dmi'
	icon_state = "contempt"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 70, PALE_DAMAGE = 50) //same as theast's, 'cept with a +10 to black - open to maintainer discussion
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)

/obj/item/clothing/suit/armor/ego_gear/city/fellbullet
	name = "N Corp. E.G.O::Fell Bullet"
	desc = "During a gory war, the devil approached a man with a deal. A shotgun that would blast anyone into fireworks, as if fired at point blank. However, the last shell would land on his beloved."
	icon = 'icons/obj/clothing/ego_gear/abnormality/he.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/abnormality/he.dmi'
	icon_state = "fell_bullet"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 30, BLACK_DAMAGE = 40, PALE_DAMAGE = 30) // 140 points - ripped from thumb east soldato
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

//add in jobber shit later
