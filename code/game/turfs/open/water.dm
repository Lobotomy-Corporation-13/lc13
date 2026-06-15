/turf/open/water
	gender = PLURAL
	name = "water"
	desc = "Shallow water."
	icon = 'icons/turf/floors.dmi'
	icon_state = "riverwater_motion"
	baseturfs = /turf/open/chasm/lavaland
	// initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	// planetary_atmos = FALSE
	slowdown = 1
	bullet_sizzle = TRUE
	bullet_bounce_sound = null //needs a splashing sound one day.

	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER

/turf/open/water/jungle
	// initial_gas_mix = OPENTURF_DEFAULT_ATMOS

// Bloodfiend Origins quirk: stepping onto a water turf panics the
// holder. The quirk's own cooldown gate handles the per-step rate
// limit so we don't need to dedup here.
/turf/open/water/Entered(atom/movable/AM, atom/old_loc)
	. = ..()
	if(!ishuman(AM))
		return
	if(!HAS_TRAIT(AM, TRAIT_BLOODFIEND))
		return
	var/mob/living/carbon/human/H = AM
	var/datum/quirk/starlight_bloodfiend_origins/Q = locate() in H.roundstart_quirks
	if(Q)
		Q.ApplyWaterPanic(30, 100, "step")
