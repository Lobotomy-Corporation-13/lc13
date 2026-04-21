/// A physical seal dropped from Laevateinn when an unseal threshold is crossed.
/// Dense structure that blocks movement. Debug sprite for now.
/obj/structure/laevateinn_seal
	name = "Laevateinn seal"
	desc = "A heavy chain seal torn from the relic sword Laevateinn. It radiates residual heat."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "uzi9mm-0"
	density = TRUE
	anchored = TRUE
	max_integrity = 200

/// Warning indicator for where a seal is about to land.
/obj/effect/temp_visual/seal_warning
	name = "seal impact warning"
	icon = 'icons/effects/effects.dmi'
	icon_state = "spreadwarning"
	layer = BELOW_MOB_LAYER
	duration = 15
	alpha = 128
