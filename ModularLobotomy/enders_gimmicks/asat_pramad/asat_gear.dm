// Asat Pramad's outfit.
//
// Built up one layer at a time. This is the under layer: the gilded waistcoat,
// purple tie and dark trousers worn beneath the white greatcoat. The coat, hat
// and gloves are separate items still to come.
//
// Sprites are the greyscale 'vice' uniform recoloured to his palette, so they
// keep the shading ramp of a stock jumpsuit and sit correctly on the mob.
//
// Everything lives in one icon file, asat_pramad.dmi:
//   uniform / uniform_worn   the waistcoat as an item and as worn
//   outfit                   coat, gloves and shoes, no head
//   head / dice / hat        the stacking pieces on their own
//   base                     outfit + hand-head
//   base_dice / base_hat     base wearing each crown piece

/obj/item/clothing/under/asat_pramad
	name = "gilded waistcoat"
	desc = "A high-collared gold waistcoat over dark trousers, finished with a deep violet tie. Cut for someone who expects to be looked at."
	icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	icon_state = "uniform"
	worn_icon_state = "uniform_worn"
	inhand_icon_state = "gy_suit"
	can_adjust = FALSE
