// Material cost model for traces and ascension.
// A "cost" is a list("main" = list(list(tier, amount), ...), "trace" = ...).
// Main entries draw the path's sin-tied family; trace entries draw the path's
// ordeal-cluster family. Materials are counted from and spent out of the
// owner's inventory (including a cosmic material pouch).

// ---- Family identity ----

/// The path's main (sin-tied) material family key.
/datum/path/proc/GetMainKey()
	switch(type)
		if(/datum/path/destruction) return PATH_KEY_DESTRUCTION
		if(/datum/path/hunt) return PATH_KEY_HUNT
		if(/datum/path/erudition) return PATH_KEY_ERUDITION
		if(/datum/path/nihility) return PATH_KEY_NIHILITY
		if(/datum/path/harmony) return PATH_KEY_HARMONY
		if(/datum/path/preservation) return PATH_KEY_PRESERVATION
		if(/datum/path/abundance) return PATH_KEY_ABUNDANCE
	return PATH_KEY_DESTRUCTION

/// The path's trace (ordeal-cluster) material family key.
/datum/path/proc/GetTraceKey()
	switch(type)
		if(/datum/path/destruction, /datum/path/hunt)
			return TRACE_FAMILY_FANG
		if(/datum/path/erudition, /datum/path/nihility)
			return TRACE_FAMILY_LENS
		if(/datum/path/harmony, /datum/path/abundance)
			return TRACE_FAMILY_ICHOR
		if(/datum/path/preservation)
			return TRACE_FAMILY_WARD
	return TRACE_FAMILY_FANG

// ---- Ability access ----

/datum/path/proc/GetAbilityDatum(target)
	switch(target)
		if(PATH_ABILITY_BASIC) return basic_attack
		if(PATH_ABILITY_BURST) return burst_action
		if(PATH_ABILITY_ULTIMATE) return ultimate_action
		if(PATH_ABILITY_PASSIVE) return passive_effect
	return null

/datum/path/proc/GetAbilityLevel(target)
	var/datum/path_ability/a = GetAbilityDatum(target)
	return a ? a.level : 1

// ---- Counting / spending ----

/// How many of a (category, key, tier) material the owner holds.
/datum/path/proc/CountMat(cat, key, tier)
	if(!owner)
		return 0
	var/mt = GetPathMatType(cat, key, tier)
	if(!mt)
		return 0
	var/total = 0
	for(var/obj/item/stack/S in owner.GetAllContents())
		if(S.type == mt)
			total += S.amount
	return total

/// TRUE if the owner holds everything a cost requires.
/datum/path/proc/HasCost(list/cost)
	for(var/list/entry in cost["main"])
		if(CountMat("path", GetMainKey(), entry[1]) < entry[2])
			return FALSE
	for(var/list/entry in cost["trace"])
		if(CountMat("trace", GetTraceKey(), entry[1]) < entry[2])
			return FALSE
	return TRUE

/// Consumes `amount` of a (category, key, tier) from the owner's inventory.
/datum/path/proc/SpendMat(cat, key, tier, amount)
	var/mt = GetPathMatType(cat, key, tier)
	if(!mt || !owner)
		return
	var/remaining = amount
	for(var/obj/item/stack/S in owner.GetAllContents())
		if(remaining <= 0)
			break
		if(S.type != mt)
			continue
		var/take = min(remaining, S.amount)
		S.use(take)
		remaining -= take

/// Spends a whole cost (assumes HasCost already passed).
/datum/path/proc/SpendCost(list/cost)
	for(var/list/entry in cost["main"])
		SpendMat("path", GetMainKey(), entry[1], entry[2])
	for(var/list/entry in cost["trace"])
		SpendMat("trace", GetTraceKey(), entry[1], entry[2])

// ---- Ascension cost ----

/// Material cost (main only) to ascend FROM `phase` to `phase`+1.
/datum/path/proc/GetAscendCost(phase)
	var/list/main
	switch(phase)
		if(0) main = list(list(1, 4))
		if(1) main = list(list(1, 8))
		if(2) main = list(list(1, 5), list(2, 4))
		if(3) main = list(list(1, 8), list(2, 6))
		if(4) main = list(list(2, 8))
		if(5) main = list(list(2, 10), list(3, 3))
		else main = list()
	return list("main" = main, "trace" = list())

/// Material-gated ascension, triggered from the Path Screen.
/datum/path/proc/DoAscend()
	if(ascension_phase >= 6)
		return FALSE
	var/cap = level_caps[ascension_phase + 1]
	if(path_level < cap)
		to_chat(owner, span_warning("Reach the current level cap ([cap]) first."))
		return FALSE
	var/list/cost = GetAscendCost(ascension_phase)
	if(!HasCost(cost))
		to_chat(owner, span_warning("You lack the materials to ascend."))
		return FALSE
	SpendCost(cost)
	Ascend()
	RefreshLevel() // release any EXP banked past the old cap
	to_chat(owner, span_nicegreen("Ascended to phase [ascension_phase]! Level cap raised."))
	playsound(get_turf(owner), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	return TRUE

// ---- Node cost ----

/// The per-level ability cost schedule. Returns list("asc", "main", "trace")
/// for the given current ability level, or null if the ability is maxed.
/datum/path_node/proc/AbilityCostRow(lvl, is_basic)
	var/static/list/basic_sched
	var/static/list/gentle_sched
	if(!basic_sched)
		basic_sched = list(
			list("asc" = 2, "main" = list(list(1, 4)), "trace" = list(list(1, 2))),
			list("asc" = 3, "main" = list(list(2, 2)), "trace" = list(list(2, 2))),
			list("asc" = 4, "main" = list(list(2, 3)), "trace" = list(list(2, 4))),
			list("asc" = 5, "main" = list(list(3, 2)), "trace" = list(list(3, 2))),
			list("asc" = 6, "main" = list(list(3, 3)), "trace" = list(list(3, 6))),
			list("asc" = 6, "main" = list(list(3, 4)), "trace" = list(list(3, 8))),
		)
		gentle_sched = list(
			list("asc" = 1, "main" = list(list(1, 2)), "trace" = list()),
			list("asc" = 2, "main" = list(list(1, 4)), "trace" = list(list(1, 2))),
			list("asc" = 3, "main" = list(list(2, 2)), "trace" = list(list(2, 2))),
			list("asc" = 4, "main" = list(list(2, 3)), "trace" = list(list(2, 4))),
			list("asc" = 4, "main" = list(list(2, 5)), "trace" = list(list(2, 6))),
			list("asc" = 5, "main" = list(list(3, 2)), "trace" = list(list(3, 2))),
			list("asc" = 5, "main" = list(list(3, 3)), "trace" = list(list(3, 4))),
			list("asc" = 6, "main" = list(), "trace" = list(list(3, 6))),
			list("asc" = 6, "main" = list(), "trace" = list(list(3, 11))),
			list("asc" = 6, "main" = list(list(3, 3)), "trace" = list(list(3, 6))),
			list("asc" = 6, "main" = list(list(3, 4)), "trace" = list(list(3, 8))),
		)
	var/list/sched = is_basic ? basic_sched : gentle_sched
	if(lvl < 1 || lvl > length(sched))
		return null
	return sched[lvl]

/// Computes this node's material cost for the given path.
/datum/path_node/proc/GetCost(datum/path/P)
	var/list/cost = list("main" = list(), "trace" = list())
	switch(node_type)
		if(PATH_NODE_ABILITY)
			var/is_basic = (ability_target == PATH_ABILITY_BASIC)
			var/list/row = AbilityCostRow(P.GetAbilityLevel(ability_target), is_basic)
			if(row)
				cost["main"] = row["main"]
				cost["trace"] = row["trace"]
		if(PATH_NODE_STAT)
			var/t = required_ascension <= 2 ? 1 : (required_ascension <= 4 ? 2 : 3)
			cost["main"] = list(list(t, 2))
			cost["trace"] = list(list(t, 1))
		if(PATH_NODE_PASSIVE)
			switch(required_ascension)
				if(2) cost["main"] = list(list(1, 4), list(2, 2))
				if(4) cost["main"] = list(list(2, 4), list(3, 2))
				if(6) cost["main"] = list(list(3, 8))
				else cost["main"] = list(list(1, 4))
	return cost

/// The ascension phase this node requires right now (per-level for abilities).
/datum/path_node/proc/GetRequiredAscension(datum/path/P)
	if(node_type == PATH_NODE_ABILITY)
		var/is_basic = (ability_target == PATH_ABILITY_BASIC)
		var/list/row = AbilityCostRow(P.GetAbilityLevel(ability_target), is_basic)
		return row ? row["asc"] : required_ascension
	return required_ascension
