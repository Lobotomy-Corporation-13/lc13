// Draws which city factions run this round and gates their members behind a
// leader. Inert on any map that is not a city map.

SUBSYSTEM_DEF(city_factions)
	name = "City Factions"
	init_order = INIT_ORDER_CITY_FACTIONS
	flags = SS_NO_FIRE
	/// Every faction datum, drawn or not.
	var/list/datum/city_faction/all_factions = list()
	/// The factions enabled this round.
	var/list/datum/city_faction/active_factions = list()

/datum/controller/subsystem/city_factions/Initialize(timeofday)
	if(!(SSmaptype.maptype in SSmaptype.citymaps))
		return ..()

	var/list/majors = list()
	var/list/minors = list()
	for(var/faction_type in subtypesof(/datum/city_faction))
		var/datum/city_faction/faction = new faction_type()
		all_factions += faction
		switch(faction.category)
			if(CITY_FACTION_ALWAYS)
				active_factions += faction
			if(CITY_FACTION_MAJOR)
				majors += faction
			if(CITY_FACTION_MINOR)
				minors += faction

	for(var/i in 1 to CITY_FACTION_MAJOR_COUNT)
		if(!majors.len)
			break
		active_factions += pick_n_take(majors)

	for(var/i in 1 to CITY_FACTION_MINOR_COUNT)
		if(!minors.len)
			break
		active_factions += pick_n_take(minors)

	return ..()

/// Re-stamps every faction onto the job datums. SetupOccupations() rebuilds all
/// job datums from scratch, so this has to run again each time it does.
/datum/controller/subsystem/city_factions/proc/ApplyToJobs()
	for(var/datum/city_faction/faction in all_factions)
		faction.leader_filled = FALSE
		if(faction in active_factions)
			faction.LinkJobs()
		else
			faction.CloseFaction()

/// Assigns each active faction's leader before the main roundstart loop, so a
/// faction nobody wanted to lead is shut before its members can be handed out.
/datum/controller/subsystem/city_factions/proc/FillFactionLeaders()
	for(var/datum/city_faction/faction in active_factions)
		if(!faction.requires_leader)
			continue
		var/datum/job/leader = SSjob.GetJobType(faction.leader_job)
		if(!leader)
			continue
		var/filled = FALSE
		for(var/level in SSjob.level_order)
			var/list/candidates = SSjob.FindOccupationCandidates(leader, level)
			if(!candidates.len)
				continue
			if(SSjob.AssignRole(pick(candidates), leader.title))
				faction.OpenMembers()
				filled = TRUE
				break
		if(!filled)
			faction.CloseMembers()
