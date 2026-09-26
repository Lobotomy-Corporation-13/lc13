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
		faction.BuildVariants()
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
		var/datum/job/leader = faction.requires_leader ? SSjob.GetJobType(faction.leader_job) : null
		if(!leader)
			//No leader gate, or no leader job. Nobody is going to pick, so the
			//variant falls to the random branch rather than being skipped.
			ChooseVariant(faction, null)
			continue
		var/filled = FALSE
		for(var/level in SSjob.level_order)
			var/list/candidates = SSjob.FindOccupationCandidates(leader, level)
			if(!candidates.len)
				continue
			var/mob/dead/new_player/chosen = pick(candidates)
			if(SSjob.AssignRole(chosen, leader.title))
				faction.OpenMembers()
				//The leader's own job preference is the faction's choice. Read
				//here rather than on spawn because this runs before the standard
				//job loop, so members are dressed for it before they are dealt.
				ChooseVariant(faction, chosen)
				filled = TRUE
				break
		if(!filled)
			faction.CloseMembers()
		//Even a faction nobody led still needs a variant, or its base has no
		//identity to deploy with and its jobs read as unbranded on latejoin.
		ChooseVariant(faction, null)

/// Settle a faction's variant from its leader's chosen alt title, falling back
/// to the faction's default. Does nothing to a faction that has already chosen.
/datum/controller/subsystem/city_factions/proc/ChooseVariant(datum/city_faction/faction, mob/dead/new_player/leader_mob)
	if(faction.active_variant || !faction.variant_pool.len)
		return
	var/datum/job/leader = SSjob.GetJobType(faction.leader_job)
	var/chosen = leader_mob?.client?.prefs?.alt_titles_preferences[leader?.title]
	var/datum/city_faction_variant/V = faction.VariantForTitle(chosen)
	if(!V)
		V = faction.DefaultVariant()
	faction.SetVariant(V)
