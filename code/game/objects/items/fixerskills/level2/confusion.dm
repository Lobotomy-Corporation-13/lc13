//Confusion
/obj/item/book/granter/action/skill/confusion
	granted_action = /datum/action/cooldown/confusion
	actionname = "Confusion"
	name = "Level 2 Skill: Confusion"
	level = 2
	custom_premium_price = 1200

/datum/action/cooldown/confusion
	name = "Confusion"
	desc = "After a 1 second warning, confuses humans and damages simple mobs that are looking at you. Applies 4 stacks of feeble."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "confusion"
	cooldown_time = 50 SECONDS

/datum/action/cooldown/confusion/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if (owner.stat == DEAD)
		return FALSE

	// Start the gaze attack
	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(PerformGaze))

/datum/action/cooldown/confusion/proc/PerformGaze()
	// Visual warning - green glow
	owner.set_light(3, 5, "#00FF00", TRUE)
	to_chat(owner, span_notice("You begin emitting a confusing aura..."))

	// Create visual effect for all nearby turfs
	for(var/turf/T in view(7, owner))
		if(T.density)
			continue
		new /obj/effect/temp_visual/confusion_gaze(T)

	// 1 second delay
	sleep(10)

	// Check all mobs in view
	for(var/mob/living/M in viewers(7, owner))
		if(M.stat == DEAD || M == owner)
			continue

		// Check if the mob is looking at the user
		if(!is_A_facing_B(M, owner))
			continue

		// Apply LC feeble to all targets
		M.apply_lc_feeble(4)

		// Handle simple animals
		if(isanimal(M))
			M.adjustWhiteLoss(100)
			to_chat(M, span_userdanger("The confusing gaze overwhelms your mind!"))
			playsound(get_turf(M), 'sound/effects/magic.ogg', 30, TRUE)

		// Handle humans/carbon mobs
		else if(iscarbon(M))
			var/mob/living/carbon/C = M
			to_chat(C, span_userdanger("[owner] emits a horrible confusing aura!"))
			C.set_confusion(10)
			C.dizziness += 10
			C.adjust_blurriness(15)
			C.silent = 12
			playsound(get_turf(C), 'sound/effects/blobattack.ogg', 30, TRUE)

	// Turn off the light
	owner.set_light(0, 0, null, FALSE)

// Visual effect for confusion gaze
/obj/effect/temp_visual/confusion_gaze
	name = "confusing aura"
	desc = "A strange green shimmer in the air."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-old"
	color = "#00FF00"
	duration = 10
	alpha = 100

