//Zwei Assoc Veteran
/datum/job/kcorpdrone
	title = "Kcorp Lead Film Director"
	department_head = list("the director")
	faction = "Station"
	supervisors = "the director."
	selection_color = "#26294F"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/kcorpdrone
	faction_positions = 1
	display_order = 110
	trusted_only = FALSE
	access = list("kcorp")
	minimal_access = list("kcorp")
	radio_channel_name = "Kcorp"
	radio_channel_color = "#26294F"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "."

/datum/job/kcorpdrone/equip(mob/living/carbon/human/H, visualsOnly = FALSE, announce = TRUE, latejoin = FALSE, datum/outfit/outfit_override = null, client/preference_source)
	if(!H)
		return
	return H.change_mob_type(/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder,get_turf(H),title,TRUE)
