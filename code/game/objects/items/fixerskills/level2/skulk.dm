
//Skulk
/obj/item/book/granter/action/skill/skulk
	granted_action = /datum/action/cooldown/skulk
	actionname = "Skulk"
	name = "Level 2 Skill: Skulk"
	level = 2
	custom_premium_price = 1200

/datum/action/cooldown/skulk
	name = "Skulk"
	desc = "Become invisible for 10 seconds, but you are pacified for 12 seconds."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "skulk"
	cooldown_time = 30 SECONDS
	var/duration = 10 SECONDS

/datum/action/cooldown/skulk/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if (owner.stat == DEAD)
		return FALSE

	//become invisible to mobs
	owner.invisibility = INVISIBILITY_OBSERVER
	owner.alpha = 35

	//apply pacify for duration + 2 seconds
	var/mob/living/L = owner
	if(L)
		L.apply_status_effect(/datum/status_effect/pacify, duration + 2 SECONDS)

	addtimer(CALLBACK(src, PROC_REF(Recall),), duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	StartCooldown()

/datum/action/cooldown/skulk/proc/Recall()
	owner.invisibility = 0
	owner.alpha = 255
