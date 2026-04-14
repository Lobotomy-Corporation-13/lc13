/// Palermitan EXP Component — tracks EXP, skill points, and role duel counts for the apprentice.
/datum/component/palermitan_exp
	/// Total accumulated EXP (never decreases)
	var/exp = 0
	/// Available skill points to spend
	var/skill_points = 0
	/// Skill points already spent
	var/skill_points_spent = 0
	/// Associative list: role name -> duel count (e.g. "Butcher" = 3)
	var/list/role_duel_counts = list()
	/// List of school IDs the player has invested points in
	var/list/schools_invested = list()
	/// Maximum number of schools that can be invested in
	var/max_schools = 3

	/// EXP thresholds for earning skill points
	var/static/list/exp_thresholds = list(
		20,
		50,
		80,
		120,
		170,
		220,
		280,
		350,
		430,
		500,
	)

/datum/component/palermitan_exp/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/// Add EXP (positive only). Checks for new skill points.
/datum/component/palermitan_exp/proc/modify_exp(amount)
	if(amount <= 0)
		return
	exp += amount
	check_skill_points()
	// Notify the player
	var/mob/living/L = parent
	if(L)
		to_chat(L, span_notice("You gained [amount] Palermitan EXP! (Total: [exp])"))

/// Checks if we've earned new skill points from crossing EXP thresholds.
/datum/component/palermitan_exp/proc/check_skill_points()
	var/total_points_earned = 0
	for(var/i in 1 to length(exp_thresholds))
		if(exp >= exp_thresholds[i])
			total_points_earned = i
		else
			break
	var/new_points = total_points_earned - skill_points_spent
	if(new_points > skill_points)
		var/gained = new_points - skill_points
		skill_points = new_points
		var/mob/living/L = parent
		if(L && gained > 0)
			to_chat(L, span_boldnotice("You earned [gained] new skill point[gained > 1 ? "s" : ""]! (Available: [skill_points])"))

/// Spend skill points. Returns TRUE if successful.
/datum/component/palermitan_exp/proc/spend_skill_point(cost = 1)
	if(skill_points < cost)
		return FALSE
	skill_points -= cost
	skill_points_spent += cost
	return TRUE

/// Get the next EXP threshold needed for the next skill point.
/datum/component/palermitan_exp/proc/get_next_threshold()
	var/total_points = skill_points + skill_points_spent
	if(total_points >= length(exp_thresholds))
		return exp_thresholds[length(exp_thresholds)]
	return exp_thresholds[total_points + 1]

/// Get the current EXP threshold (the one we just passed).
/datum/component/palermitan_exp/proc/get_current_threshold()
	var/total_points = skill_points + skill_points_spent
	if(total_points <= 0)
		return 0
	if(total_points > length(exp_thresholds))
		return exp_thresholds[length(exp_thresholds)]
	return exp_thresholds[total_points]

/// Increment the duel count for a specific role.
/datum/component/palermitan_exp/proc/increment_role_duel(role_name)
	if(!role_name)
		return
	if(!(role_name in role_duel_counts))
		role_duel_counts[role_name] = 0
	role_duel_counts[role_name] += 1
	var/mob/living/L = parent
	if(L)
		to_chat(L, span_notice("Duel count vs [role_name]: [role_duel_counts[role_name]]"))

/// Get the duel count for a specific role.
/datum/component/palermitan_exp/proc/get_role_duel_count(role_name)
	if(!(role_name in role_duel_counts))
		return 0
	return role_duel_counts[role_name]

/// Check if the player can invest in a new school (hasn't hit max, or already invested in this one).
/datum/component/palermitan_exp/proc/can_invest_in_school(school_id)
	if(school_id in schools_invested)
		return TRUE
	return length(schools_invested) < max_schools

/// Register that the player has invested in a school.
/datum/component/palermitan_exp/proc/invest_in_school(school_id)
	if(!(school_id in schools_invested))
		schools_invested += school_id
