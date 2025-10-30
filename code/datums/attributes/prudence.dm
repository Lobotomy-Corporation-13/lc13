/datum/attribute/prudence
	name = PRUDENCE_ATTRIBUTE
	desc = "Attribute responsible for maximum sanity points."
	affected_stats = list("Max Sanity")
	initial_stat_value = DEFAULT_HUMAN_MAX_SANITY

/datum/attribute/prudence/get_printed_level_bonus()
	return round(get_level() * (PRUDENCE_MOD ? PRUDENCE_MOD : 1)) + initial_stat_value

/datum/attribute/prudence/on_update(mob/living/carbon/human/user)
	. = ..()
	initial_stat_value = SSmaptype.chosen_trait == FACILITY_TRAIT_XP_MOD ? DEFAULT_HUMAN_MAX_SANITY_XP : DEFAULT_HUMAN_MAX_SANITY
