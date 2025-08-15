/datum/attribute/fortitude
	name = FORTITUDE_ATTRIBUTE
	desc = "Attribute responsible for maximum health level."
	affected_stats = list("Max Health")
	initial_stat_value = DEFAULT_HUMAN_MAX_HEALTH

/datum/attribute/fortitude/get_printed_level_bonus(mob/living/carbon/refrence_user)
	var/modifier = (SSmaptype.chosen_trait == FACILITY_TRAIT_XP_MOD ? 1.7 : FORTITUDE_MOD)
	if(refrence_user)
		return refrence_user.getRawMaxHealth() + round(level * modifier)
	return round(level * modifier) + initial_stat_value

/datum/attribute/fortitude/on_update(mob/living/carbon/user)
	if(!istype(user))
		return FALSE
	user.death_threshold = HEALTH_THRESHOLD_DEAD - round((level + level_buff) * 0.5)
	user.hardcrit_threshold = HEALTH_THRESHOLD_FULLCRIT - round((level + level_buff) * 0.25)
	return TRUE
