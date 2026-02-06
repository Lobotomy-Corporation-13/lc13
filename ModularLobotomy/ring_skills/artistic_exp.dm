// Artistic EXP Component
// Tracks artistic experience and skill points for Ring artists

/datum/component/artistic_exp
	/// Current artistic EXP
	var/exp = 0
	/// Skill points available to spend
	var/skill_points = 0
	/// Skill points already spent
	var/skill_points_spent = 0
	/// Schools the player has invested in (max 2)
	var/list/schools_invested = list()

	/// EXP thresholds for skill points
	var/static/list/exp_thresholds = list(50, 150, 300, 500, 750, 1050, 1400, 1800)

/datum/component/artistic_exp/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/artistic_exp/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/artistic_exp/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)
	. = ..()

/// Show EXP info when Maestro examines this player
/datum/component/artistic_exp/proc/on_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER

	if(!ishuman(examiner))
		return

	var/mob/living/carbon/human/H = examiner

	// Only Maestro can see grade history
	if(!istype(H.dna?.species, /datum/species/corporist_maestro))
		return

	examine_list += span_notice("Artistic EXP: [exp] | Skill Points: [skill_points]/[skill_points + skill_points_spent]")

/// Get the next EXP threshold
/datum/component/artistic_exp/proc/get_next_threshold()
	var/total_points = skill_points + skill_points_spent
	if(total_points >= length(exp_thresholds))
		return exp_thresholds[length(exp_thresholds)] // Return max threshold
	return exp_thresholds[total_points + 1]

/// Get the current EXP threshold (the one we just passed)
/datum/component/artistic_exp/proc/get_current_threshold()
	var/total_points = skill_points + skill_points_spent
	if(total_points <= 0)
		return 0
	if(total_points > length(exp_thresholds))
		return exp_thresholds[length(exp_thresholds)]
	return exp_thresholds[total_points]

/// Modify EXP (positive or negative)
/datum/component/artistic_exp/proc/modify_exp(amount)
	exp = max(0, exp + amount) // Can't go below 0

	if(amount > 0)
		to_chat(parent, span_nicegreen("You gained [amount] Artistic EXP! ([exp] total)"))
	else if(amount < 0)
		to_chat(parent, span_warning("You lost [abs(amount)] Artistic EXP! ([exp] total)"))

	check_skill_points()

/// Add EXP from artistic activities (percentage of next threshold)
/datum/component/artistic_exp/proc/add_activity_exp(activity_type)
	var/next_threshold = get_next_threshold()
	var/exp_gain = 0

	switch(activity_type)
		if("create_artwork")
			exp_gain = round(next_threshold * 0.03) // 3%
		if("add_body")
			exp_gain = round(next_threshold * 0.02) // 2%
		if("refine")
			exp_gain = round(next_threshold * 0.03) // 3%
		if("refine_good")
			exp_gain = round(next_threshold * 0.05) // 5% for A/S technique grade

	if(exp_gain > 0)
		modify_exp(exp_gain)

/// Check if we've earned new skill points
/datum/component/artistic_exp/proc/check_skill_points()
	var/total_points_earned = 0

	for(var/i in 1 to length(exp_thresholds))
		if(exp >= exp_thresholds[i])
			total_points_earned = i
		else
			break

	var/new_points = total_points_earned - skill_points_spent
	if(new_points > skill_points)
		var/points_gained = new_points - skill_points
		skill_points = new_points
		to_chat(parent, span_greentext("You earned [points_gained] new skill point(s)! Open the Ring Skill Tree to spend them."))
		// Play sound
		var/mob/M = parent
		if(istype(M))
			SEND_SOUND(M, sound('sound/machines/chime.ogg'))

/// Spend a skill point
/datum/component/artistic_exp/proc/spend_skill_point(cost = 1)
	if(skill_points < cost)
		return FALSE
	skill_points -= cost
	skill_points_spent += cost
	return TRUE

/// Refund all skill points (for Maestro respec)
/datum/component/artistic_exp/proc/refund_all_points()
	skill_points += skill_points_spent
	skill_points_spent = 0
	schools_invested = list()
	return TRUE

/// Check if player can invest in a school
/datum/component/artistic_exp/proc/can_invest_in_school(school_name)
	if(school_name in schools_invested)
		return TRUE // Already invested
	if(length(schools_invested) >= 2)
		return FALSE // Max 2 schools
	return TRUE

/// Register investment in a school
/datum/component/artistic_exp/proc/invest_in_school(school_name)
	if(!(school_name in schools_invested))
		schools_invested += school_name

/// Grant starting skill points based on role
/datum/component/artistic_exp/proc/grant_starting_points(role)
	switch(role)
		if("maestro")
			skill_points = 8
			to_chat(parent, span_nicegreen("As a Maestro, you start with 8 skill points."))
		if("apprentice")
			skill_points = 4
			to_chat(parent, span_nicegreen("As an Apprentice, you start with 4 skill points."))
		// Students start with 0
