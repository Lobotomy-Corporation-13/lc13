/datum/action/cooldown/exploitgap
	name = "Exploit the Gap"
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "quickslash"
	cooldown_time = 90 SECONDS
	var/list/affected = list()
	var/range = 1
	var/affect_self = FALSE

/datum/action/cooldown/exploitgap/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if (owner.stat == DEAD)
		return FALSE

	//increase speed
	if (ishuman(owner))
		owner.add_movespeed_modifier(/datum/movespeed_modifier/exploitgap)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/exploitgap), 2 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		addtimer(CALLBACK(src, PROC_REF(GapSpotted)), 2 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		StartCooldown()

/datum/action/cooldown/exploitgap/proc/GapSpotted()
	for(var/mob/living/L in view(range, owner))
		if(L.stat == DEAD)
			continue
		if (L == owner && !affect_self)
			owner.say("	Tch... I’ve rusted all too soon, haven't I?.")
			continue
		owner.say("You're full of gaps.")
		L.apply_status_effect(/datum/status_effect/rend_sevendirector)


/datum/status_effect/rend_sevendirector
	id = "seven director rend armor"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300 //30 seconds
	alert_type = null

/datum/status_effect/rend_sevendirector/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.physiology.red_mod *= 1.2
		L.physiology.white_mod *= 1.2
		L.physiology.black_mod *= 1.2
		L.physiology.pale_mod *= 1.2
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/sevendirector)

/datum/status_effect/rend_sevendirector/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.physiology.red_mod /= 1.2
		L.physiology.white_mod /= 1.2
		L.physiology.black_mod /= 1.2
		L.physiology.pale_mod /= 1.2
		return
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/sevendirector)

/datum/movespeed_modifier/exploitgap
	variable = TRUE
	multiplicative_slowdown = -0.6
