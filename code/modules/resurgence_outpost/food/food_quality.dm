/**
 * Resurgence Outpost - Food Quality System
 *
 * Defines quality tiers for food and calculation formulas.
 * Quality affects faith bonus when eating.
 *
 * Quality is calculated using a random roll modified by cooking skill:
 * - Low skill = more random (can get lucky)
 * - High skill = consistently good results
 * - Kitchen room bonus: +1 quality tier
 *
 * Quality tier constants are defined in code/__DEFINES/food.dm:
 * QUALITY_AWFUL (0), QUALITY_POOR (2), QUALITY_DECENT (5),
 * QUALITY_GOOD (8), QUALITY_EXCELLENT (12), QUALITY_MASTERWORK (18)
 */

/// Global list mapping quality values to display names
GLOBAL_LIST_INIT(quality_tier_names, list(
	"[QUALITY_AWFUL]" = "Awful",
	"[QUALITY_POOR]" = "Poor",
	"[QUALITY_DECENT]" = "Decent",
	"[QUALITY_GOOD]" = "Good",
	"[QUALITY_EXCELLENT]" = "Excellent",
	"[QUALITY_MASTERWORK]" = "Masterwork"
))

/**
 * Get the display name for a quality tier value.
 *
 * Arguments:
 * * quality_value - The quality constant (0, 2, 5, 8, 12, or 18)
 *
 * Returns: Human-readable quality name
 */
/proc/get_quality_name(quality_value)
	return GLOB.quality_tier_names["[quality_value]"] || "Unknown"

/**
 * Calculate food quality based on cooking skill level.
 * Uses a weighted combination of skill and random luck.
 *
 * Arguments:
 * * skill_level - The cooking stat level (1-20)
 * * kitchen_bonus - TRUE if cooking in a designated Kitchen room
 *
 * Returns: Quality tier constant (QUALITY_AWFUL through QUALITY_MASTERWORK)
 */
/proc/calculate_food_quality(skill_level, kitchen_bonus = FALSE)
	skill_level = clamp(skill_level, 1, STAT_MAX_LEVEL)

	// Base roll: 0-20 range
	var/roll = rand(0, 20)

	// Skill weight: 0.3 at level 1, 0.9 at level 20
	// Higher skill means less randomness
	var/skill_weight = 0.3 + (skill_level - 1) * (0.6 / 19)

	// Final score combines skill and luck
	var/final_score = (skill_level * skill_weight) + (roll * (1 - skill_weight))

	// Kitchen room bonus: +3 to score (roughly +1 quality tier)
	if(kitchen_bonus)
		final_score += 3

	// Map to quality tier
	if(final_score >= 18)
		return QUALITY_MASTERWORK
	if(final_score >= 15)
		return QUALITY_EXCELLENT
	if(final_score >= 11)
		return QUALITY_GOOD
	if(final_score >= 7)
		return QUALITY_DECENT
	if(final_score >= 4)
		return QUALITY_POOR
	return QUALITY_AWFUL

/**
 * Get the next higher quality tier.
 * Used for common room eating bonus.
 *
 * Arguments:
 * * current_quality - The current quality tier value
 *
 * Returns: Next quality tier value (or same if already max)
 */
/proc/get_next_quality_tier(current_quality)
	switch(current_quality)
		if(QUALITY_AWFUL)
			return QUALITY_POOR
		if(QUALITY_POOR)
			return QUALITY_DECENT
		if(QUALITY_DECENT)
			return QUALITY_GOOD
		if(QUALITY_GOOD)
			return QUALITY_EXCELLENT
		if(QUALITY_EXCELLENT)
			return QUALITY_MASTERWORK
		if(QUALITY_MASTERWORK)
			return QUALITY_MASTERWORK  // Already max
	return current_quality

/**
 * Get cooking skill level from a mob.
 *
 * Arguments:
 * * user - The mob to check
 *
 * Returns: Cooking skill level (1 if not a resurgence machine)
 */
/proc/get_cooking_skill(mob/living/carbon/human/user)
	if(!istype(user))
		return 1
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1
	return core.stat_cooking

/**
 * Award cooking XP to a user.
 *
 * Arguments:
 * * user - The mob to award XP to
 * * amount - Amount of XP to award
 */
/proc/award_cooking_xp(mob/living/carbon/human/user, amount)
	if(!istype(user))
		return
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.award_xp("cooking", amount)
