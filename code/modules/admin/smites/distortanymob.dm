
/// Should distort someone into any mob.
/datum/smite/distortanymob
	name = "Distort Into Any Mob"

/datum/smite/distortanymob/effect(client/user, mob/living/target)
	. = ..()
	var/instant = FALSE
	var/forced = FALSE
	var/mob/living/chosen_distortion = null
	if(istype(target, /mob/living/simple_animal/hostile/distortion))
		switch(tgui_alert(user,"Target is a distortion. Force distortion again?","GET DISTORTED",list("Yes", "No"), 0))
			if("Yes")
				forced = TRUE
			if("No")
				return

	if(tgui_alert(user,"Choose distortion?","GET DISTORTED",list("Yes", "No"), 0) == "Yes")
		chosen_distortion = tgui_input_list(user,"Which one?","Select a mob", subtypesof(/mob/living/))

	if(tgui_alert(user,"Instant distortion?","GET DISTORTED",list("Yes", "No"), 0) == "Yes")
		instant = TRUE

	message_admins("[key_name_admin(usr)] is causing [key_name(target)] to distort.") //Extra logging to make ABSOLUTELY SURE that admins see this
	log_admin("[key_name(usr)] caused [key_name(target)] to distort.")
	target.BecomeDistortion(chosen_distortion, instant, forced)
