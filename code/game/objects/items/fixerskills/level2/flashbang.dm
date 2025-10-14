//Solar Flare
/obj/item/book/granter/action/skill/solarflare
	granted_action = /datum/action/cooldown/solarflare
	actionname = "Solar Flare"
	name = "Level 2 Skill: Solar Flare"
	level = 2
	custom_premium_price = 1200

/datum/action/cooldown/solarflare
	name = "Solar Flare"
	desc = "Creates 4 flashing light zones that explode after 2 seconds, dealing WHITE damage and blinding humans."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "solarflare"
	cooldown_time = 50 SECONDS

/datum/action/cooldown/solarflare/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if (owner.stat == DEAD)
		return FALSE

	var/turf/owner_turf = get_turf(owner)
	var/list/target_turfs = list()

	// Always include the turf below the owner
	target_turfs += owner_turf

	// Pick 3 random turfs within 3 tile view
	var/list/possible_turfs = list()
	for(var/turf/T in view(3, owner_turf))
		if(T != owner_turf)
			possible_turfs += T

	// Add 3 random turfs from the possible list
	for(var/i = 1 to min(3, length(possible_turfs)))
		var/turf/chosen_turf = pick(possible_turfs)
		target_turfs += chosen_turf
		possible_turfs -= chosen_turf

	// Create flashing light effects on each target turf
	for(var/turf/target_turf in target_turfs)
		new /obj/effect/flashing_lights(target_turf)

	to_chat(owner, span_notice("You create [length(target_turfs)] zones of flashing lights!"))
	StartCooldown()

// Flashing lights effect object
/obj/effect/flashing_lights
	name = "flashing lights"
	desc = "Bright, pulsing lights that seem ready to explode."
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparkles"
	color = "#FFFF00" // Yellow
	anchored = TRUE

/obj/effect/flashing_lights/Initialize()
	. = ..()
	// Set up the detonation timer for 2 seconds
	addtimer(CALLBACK(src, PROC_REF(detonate)), 2 SECONDS, TIMER_UNIQUE)

/obj/effect/flashing_lights/proc/detonate()
	// Get all mobs on this turf
	for(var/mob/living/M in get_turf(src))
		if(M.stat == DEAD)
			continue

		// Deal WHITE damage to all mobs
		M.adjustWhiteLoss(20)

		// Handle humans differently from simple animals
		if(ishuman(M))
			// Blind humans
			M.adjust_blindness(5)
			to_chat(M, span_userdanger("The flashing lights explode in a blinding burst!"))
		else if(isanimal(M))
			// Deal 3x more WHITE damage to simple animals (additional 60 damage)
			M.adjustWhiteLoss(60)
			to_chat(M, span_userdanger("The bright explosion overwhelms you!"))

	playsound(get_turf(src), 'sound/weapons/flashbang.ogg', 10, TRUE)
	// Clean up
	qdel(src)

