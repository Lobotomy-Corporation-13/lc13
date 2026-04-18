// Artistic EXP Component
// Tracks artistic experience and skill points for Ring artists

/datum/component/artistic_exp
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Current artistic EXP
	var/exp = 0
	/// Skill points available to spend
	var/skill_points = 0
	/// Skill points already spent
	var/skill_points_spent = 0
	/// Schools the player has invested in
	var/list/schools_invested = list()
	/// Maximum number of schools this player can invest in (2 for students, 3 for apprentice, 4 for maestro)
	var/max_schools = 2
	/// The main school this player identifies with (for examine text)
	var/main_school = null
	/// List of final grades received from Maestro grading (for round end report)
	var/list/grades_received = list()

	/// EXP thresholds for skill points (fast for first 4 levels, then slows down)
	var/static/list/exp_thresholds = list(30, 70, 120, 180, 350, 600, 950, 1400, 1950, 2600, 3350, 4200)

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

/// Show school info to other Ring artists, EXP info only to Maestro
/datum/component/artistic_exp/proc/on_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	// Only other Ring artists can see school info
	var/examiner_is_artist = FALSE
	var/examiner_is_maestro = FALSE
	if(ishuman(examiner))
		var/mob/living/carbon/human/examiner_human = examiner
		if(examiner_human.GetComponent(/datum/component/artistic_exp))
			examiner_is_artist = TRUE
		if(istype(examiner_human.dna?.species, /datum/species/corporist_maestro))
			examiner_is_maestro = TRUE

	if(examiner_is_artist && main_school)
		var/school_name = get_school_display_name(main_school)
		var/is_maestro = istype(H.dna?.species, /datum/species/corporist_maestro)
		if(is_maestro)
			examine_list += span_notice("[H.p_they(TRUE)] [H.p_are()] currently studying the [school_name] school.")
		else
			examine_list += span_notice("[H.p_they(TRUE)] [H.p_are()] a follower of the [school_name] school.")

	// Only Maestro examiners can see EXP stats
	if(examiner_is_maestro)
		examine_list += span_notice("Artistic EXP: [exp] | Skill Points: [skill_points]/[skill_points + skill_points_spent]")

/// Convert school ID to display name
/datum/component/artistic_exp/proc/get_school_display_name(school_id)
	switch(school_id)
		if("fauvist")
			return "Fauvist"
		if("pointillist")
			return "Pointillist"
		if("cubist")
			return "Cubist"
		if("corporist")
			return "Corporist"
	return "Unknown"

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

/// Add EXP from artistic activities (flat amounts for consistent progression)
/datum/component/artistic_exp/proc/add_activity_exp(activity_type)
	var/exp_gain = 0

	switch(activity_type)
		if("create_artwork")
			exp_gain = 5
		if("add_body")
			exp_gain = 3
		if("arrange_part")
			exp_gain = 2
		if("submit_custom")
			exp_gain = 5

	if(exp_gain > 0)
		modify_exp(exp_gain)

/// Add flat EXP for completing refinement minigame based on grade
/datum/component/artistic_exp/proc/add_refine_exp(grade)
	var/exp_gain = 0
	switch(grade)
		if("F")
			exp_gain = 5
		if("C")
			exp_gain = 10
		if("B")
			exp_gain = 15
		if("A")
			exp_gain = 25
		if("S")
			exp_gain = 40

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
	if(length(schools_invested) >= max_schools)
		return FALSE // Max schools reached
	return TRUE

/// Register investment in a school
/datum/component/artistic_exp/proc/invest_in_school(school_name)
	if(!(school_name in schools_invested))
		schools_invested += school_name

/// Grant starting skill points and set max schools based on role
/datum/component/artistic_exp/proc/grant_starting_points(role)
	switch(role)
		if("maestro")
			skill_points = 8
			max_schools = 4
			to_chat(parent, span_nicegreen("As a Maestro, you start with 8 skill points and can invest in all 4 schools."))
		if("apprentice")
			// Add 4 skill points (don't overwrite existing points if they were a student)
			skill_points += 4
			max_schools = 3
			to_chat(parent, span_nicegreen("As an Apprentice, you gain 4 skill points and can invest in up to 3 schools."))
		// Students start with 0 skill points and max 2 schools (default)

/// Record a grade received from Maestro judgment (for round end tracking)
/datum/component/artistic_exp/proc/record_grade(grade)
	grades_received += grade

	// Also notify the antag datum if present
	var/mob/living/carbon/human/H = parent
	if(istype(H) && H.mind)
		var/datum/antagonist/ring_artist/artist = H.mind.has_antag_datum(/datum/antagonist/ring_artist)
		if(artist)
			artist.grades_received += grade
