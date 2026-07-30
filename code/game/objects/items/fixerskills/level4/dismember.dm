//Dismember
/obj/item/book/granter/action/skill/dismember
	granted_action = /datum/action/cooldown/dismember
	actionname = "Dismember"
	name = "Level 4 Skill: Dismember"
	level = 4
	custom_premium_price = 2400

/datum/action/cooldown/dismember
	name = "Execute"
	desc = "Execute adjacent targets below 25% HP. Dismembers arms from humans, gibs simple animals."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "dismember"
	cooldown_time = 2 MINUTES

/datum/action/cooldown/dismember/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if(owner.stat == DEAD)
		return FALSE

	var/executed_anyone = FALSE

	//Check all living mobs around you
	for(var/mob/living/M in view(1, get_turf(src)))
		if(M == owner)
			continue

		//Check if target is below 20% max HP
		if(M.health > M.maxHealth * 0.25)
			continue

		//Handle carbon mobs (humans and similar)
		if(iscarbon(M))
			var/mob/living/carbon/C = M

			//Skip if they can't be dismembered
			if(HAS_TRAIT(C, TRAIT_NODISMEMBER))
				continue

			//Lop off a random arm
			new /obj/effect/temp_visual/smash_effect(get_turf(C))
			var/obj/item/bodypart/arm = pick(C.get_bodypart(BODY_ZONE_R_ARM), C.get_bodypart(BODY_ZONE_L_ARM))

			var/did_the_thing = (arm?.dismember()) //not all limbs can be removed, so important to check that we did. the. thing.
			if(did_the_thing)
				executed_anyone = TRUE
				to_chat(owner, span_boldnotice("You execute [C] by dismembering their arm!"))

		//Handle simple animals
		else if(isanimal(M))
			var/mob/living/simple_animal/S = M

			//Skip if they have godmode
			if(S.status_flags & GODMODE)
				continue

			//Gib them
			new /obj/effect/temp_visual/smash_effect(get_turf(S))
			S.gib()
			executed_anyone = TRUE
			to_chat(owner, span_boldnotice("You execute [S]!"))

	//Only play sound and start cooldown if we executed someone
	if(executed_anyone)
		playsound(get_turf(src), 'sound/abnormalities/woodsman/woodsman_attack.ogg', 75, 0, 5)
		StartCooldown()
	else
		to_chat(owner, span_warning("No valid targets below 25% HP in range!"))

