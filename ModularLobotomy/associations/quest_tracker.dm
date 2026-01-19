// Quest tracker datum for managing player quests
/datum/quest_tracker
	var/datum/mind/owner_mind
	var/list/active_quests = list()
	var/max_active_quests = 3
	var/list/completed_quests = list()
	var/total_quests_completed = 0
	var/ahn_earned = 0

/datum/quest_tracker/New(datum/mind/M)
	owner_mind = M
	RegisterSignal(M.current, COMSIG_QUEST_MOB_KILLED, PROC_REF(on_nearby_kill))

/datum/quest_tracker/Destroy()
	if(owner_mind?.current)
		UnregisterSignal(owner_mind.current, COMSIG_QUEST_MOB_KILLED)
	for(var/datum/city_quest/Q in active_quests)
		qdel(Q)
	active_quests.Cut()
	completed_quests.Cut()
	return ..()

/datum/quest_tracker/proc/add_quest(datum/city_quest/Q)
	if(active_quests.len >= max_active_quests)
		return FALSE
	active_quests += Q
	return TRUE

/datum/quest_tracker/proc/remove_quest(datum/city_quest/Q)
	active_quests -= Q
	if(Q.completed)
		completed_quests += Q.name
	qdel(Q) // Always delete to cleanup signals

/datum/quest_tracker/proc/check_all_quests()
	for(var/datum/city_quest/Q in active_quests)
		Q.check_completion()

/datum/quest_tracker/proc/on_nearby_kill(datum/source, mob/living/victim)
	for(var/datum/city_quest/hunt/Q in active_quests)
		Q.on_potential_kill(victim, owner_mind.current)

// Add quest_tracker variable to mind datum
/datum/mind
	var/datum/quest_tracker/quest_tracker

// Hook into death signal to send kill notifications
/mob/living/death(gibbed)
	. = ..()
	// Send signal to all nearby quest holders
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.mind?.quest_tracker)
			SEND_SIGNAL(H, COMSIG_QUEST_MOB_KILLED, src)


// Add on_potential_kill to hunt quests
/datum/city_quest/hunt/proc/on_potential_kill(mob/living/victim, mob/living/killer)
	if(get_dist(victim, killer) > 7)
		return
	on_target_death(victim)
