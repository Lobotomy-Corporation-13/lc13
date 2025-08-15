/datum/attribute/prudence
	name = PRUDENCE_ATTRIBUTE
	desc = "Attribute responsible for maximum sanity points."
	affected_stats = list("Max Sanity")
	initial_stat_value = DEFAULT_HUMAN_MAX_SANITY

/datum/attribute/prudence/get_printed_level_bonus(mob/living/carbon/refrence_user)
	var/modifier = (SSmaptype.chosen_trait == FACILITY_TRAIT_XP_MOD ? 1.7 : PRUDENCE_MOD)
	if(refrence_user)
		return refrence_user.getRawMaxSanity() + round(level * modifier)
	return round(level * modifier) + initial_stat_value
