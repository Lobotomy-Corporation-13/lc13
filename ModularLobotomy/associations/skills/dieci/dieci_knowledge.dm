// ============================================================
// Dieci Association — Knowledge Component
// ============================================================
// Manages Active Knowledge entries (typed, leveled, consumable combat fuel)
// and Stored Knowledge (Tome backup with limited rereads).

/// Component that tracks a Dieci fixer's Active and Stored Knowledge entries.
/// Attached alongside association_exp when a Dieci member is registered.
/datum/component/dieci_knowledge
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Current consumable Active Knowledge entries.
	/// Each entry = list("type" = string, "level" = 1-5, "flavor" = string, "recorded" = FALSE)
	var/list/active_knowledge = list()
	/// Maximum Active Knowledge capacity (default 20, increased by Sage skills)
	var/max_knowledge = DIECI_MAX_KNOWLEDGE
	/// Stored Knowledge from Tome recording. Each entry has "rereads_remaining" in addition to type/level/flavor.
	var/list/stored_knowledge = list()
	/// Number of entries consumed for synthesis cost (default 3, reduced by Efficient Research to 2)
	var/synthesis_cost = 3
	/// Whether consumption of L3+ entries refunds a lower-level entry (Efficient Research passive)
	var/efficient_refund = FALSE
	/// Optional callback invoked when knowledge is consumed. Called with (list/consumed_entry)
	var/datum/callback/on_knowledge_consumed
	/// When TRUE, passive skills skip knowledge consumption (conserve for combo finishers)
	var/conserve_knowledge = FALSE

/datum/component/dieci_knowledge/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/dieci_knowledge/Destroy()
	active_knowledge.Cut()
	stored_knowledge.Cut()
	on_knowledge_consumed = null
	return ..()

// ============================================================
// Active Knowledge Management
// ============================================================

/// Add a new Active Knowledge entry. Returns TRUE if added, FALSE if at capacity or duplicate exists.
/// If permanent is TRUE, the entry cannot be used as a synthesis ingredient but can be consumed in combat.
/datum/component/dieci_knowledge/proc/add_active_knowledge(type, level, flavor, source, permanent = FALSE)
	if(length(active_knowledge) >= max_knowledge)
		to_chat(parent, span_warning("Your Active Knowledge is full ([max_knowledge]/[max_knowledge]). Consume or record entries to make space."))
		return FALSE
	level = clamp(level, 1, 5)
	if(!source)
		source = "Unknown"
	// Block duplicate: can't gain knowledge you already have active (must spend it first)
	for(var/list/existing in active_knowledge)
		if(existing["type"] == type && existing["level"] == level && existing["source"] == source)
			return FALSE
	if(!flavor)
		flavor = generate_flavor(type, level)
	var/list/entry = list("type" = type, "level" = level, "flavor" = flavor, "recorded" = FALSE, "source" = source)
	if(permanent)
		entry["permanent"] = TRUE
	active_knowledge += list(entry)
	return TRUE

/// Consume N entries starting from the lowest level. Returns list of consumed entries.
/datum/component/dieci_knowledge/proc/consume_lowest_knowledge(count = 1, min_level = 1)
	var/list/consumed = list()
	for(var/i in 1 to count)
		var/list/lowest = null
		var/lowest_index = 0
		for(var/j in 1 to length(active_knowledge))
			var/list/entry = active_knowledge[j]
			if(entry["level"] < min_level)
				continue
			if(!lowest || entry["level"] < lowest["level"])
				lowest = entry
				lowest_index = j
		if(!lowest)
			break
		consumed += list(lowest)
		active_knowledge.Cut(lowest_index, lowest_index + 1)
		// Efficient Research refund: L3+ consumption → refund 1 entry of type at level-1
		if(efficient_refund && lowest["level"] >= 3)
			add_active_knowledge(lowest["type"], lowest["level"] - 1, null, "Efficient Refund")
	// Notify consumption callback
	if(on_knowledge_consumed && length(consumed))
		for(var/list/c_entry in consumed)
			on_knowledge_consumed.Invoke(c_entry)
	return consumed

/// Consume the single highest-level entry of a given type. Returns the entry or null.
/datum/component/dieci_knowledge/proc/consume_highest_of_type(type)
	var/list/highest = null
	var/highest_index = 0
	for(var/i in 1 to length(active_knowledge))
		var/list/entry = active_knowledge[i]
		if(entry["type"] != type)
			continue
		if(!highest || entry["level"] > highest["level"])
			highest = entry
			highest_index = i
	if(!highest)
		return null
	active_knowledge.Cut(highest_index, highest_index + 1)
	// Efficient Research refund
	if(efficient_refund && highest["level"] >= 3)
		add_active_knowledge(highest["type"], highest["level"] - 1, null, "Efficient Refund")
	if(on_knowledge_consumed)
		on_knowledge_consumed.Invoke(highest)
	return highest

/// Consume the single lowest-level entry of a given type at or above min_level. Returns it or null.
/datum/component/dieci_knowledge/proc/consume_lowest_of_type(type, min_level = 1)
	var/list/lowest = null
	var/lowest_index = 0
	for(var/i in 1 to length(active_knowledge))
		var/list/entry = active_knowledge[i]
		if(entry["type"] != type)
			continue
		if(entry["level"] < min_level)
			continue
		if(!lowest || entry["level"] < lowest["level"])
			lowest = entry
			lowest_index = i
	if(!lowest)
		return null
	active_knowledge.Cut(lowest_index, lowest_index + 1)
	// Efficient Research refund
	if(efficient_refund && lowest["level"] >= 3)
		add_active_knowledge(lowest["type"], lowest["level"] - 1, null)
	if(on_knowledge_consumed)
		on_knowledge_consumed.Invoke(lowest)
	return lowest

/// Consume the single highest-level entry of any type. Returns the entry or null.
/datum/component/dieci_knowledge/proc/consume_highest_knowledge()
	var/list/highest = null
	var/highest_index = 0
	for(var/i in 1 to length(active_knowledge))
		var/list/entry = active_knowledge[i]
		if(!highest || entry["level"] > highest["level"])
			highest = entry
			highest_index = i
	if(!highest)
		return null
	active_knowledge.Cut(highest_index, highest_index + 1)
	if(efficient_refund && highest["level"] >= 3)
		add_active_knowledge(highest["type"], highest["level"] - 1, null, "Efficient Refund")
	if(on_knowledge_consumed)
		on_knowledge_consumed.Invoke(highest)
	return highest

// ============================================================
// Tome Recording + Re-reading
// ============================================================

/// Copy all unrecorded Active entries to Stored Knowledge.
/// Active entries are KEPT — recording is a backup, not a transfer. Stored entries get rereads_remaining = 7 - level.
/datum/component/dieci_knowledge/proc/record_to_tome()
	var/recorded_count = 0
	for(var/i in 1 to length(active_knowledge))
		var/list/entry = active_knowledge[i]
		if(entry["recorded"])
			continue
		var/list/stored_entry = list(
			"type" = entry["type"],
			"level" = entry["level"],
			"flavor" = entry["flavor"],
			"source" = entry["source"],
			"rereads_remaining" = max(1, 7 - entry["level"])
		)
		stored_knowledge += list(stored_entry)
		entry["recorded"] = TRUE
		recorded_count++
	return recorded_count

/// Restore Active Knowledge from Stored entries. Each stored entry decrements its rereads, removed at 0.
/// Unlimited entries (rereads_remaining = -1) are never decremented or removed. They restore as permanent.
/// Only restores up to available capacity. Skips entries that already have an active copy (must spend it first).
/datum/component/dieci_knowledge/proc/reread_from_tome()
	var/restored_count = 0
	var/list/to_remove = list()
	for(var/i in 1 to length(stored_knowledge))
		if(length(active_knowledge) >= max_knowledge)
			break
		var/list/stored_entry = stored_knowledge[i]
		// Skip if an active copy from this stored entry already exists (must spend it first)
		if(has_active_copy(stored_entry))
			continue
		// Add back as active knowledge (marked as already recorded)
		var/is_permanent = stored_entry["permanent"]
		var/list/new_entry = list(
			"type" = stored_entry["type"],
			"level" = stored_entry["level"],
			"flavor" = stored_entry["flavor"],
			"source" = stored_entry["source"],
			"recorded" = TRUE
		)
		if(is_permanent)
			new_entry["permanent"] = TRUE
		active_knowledge += list(new_entry)
		// Unlimited entries (-1) are never decremented or removed
		if(stored_entry["rereads_remaining"] != -1)
			stored_entry["rereads_remaining"]--
			if(stored_entry["rereads_remaining"] <= 0)
				to_remove += i
		restored_count++
	// Remove depleted stored entries (iterate backwards to preserve indices)
	for(var/i in length(to_remove) to 1 step -1)
		var/index = to_remove[i]
		stored_knowledge.Cut(index, index + 1)
	return restored_count

/// Check if a stored entry already has a matching active copy (same type + level + source). Blocks both fresh and re-read duplicates.
/datum/component/dieci_knowledge/proc/has_active_copy(list/stored_entry)
	for(var/list/entry in active_knowledge)
		if(entry["type"] == stored_entry["type"] && entry["level"] == stored_entry["level"] && entry["source"] == stored_entry["source"])
			return TRUE
	return FALSE

// ============================================================
// Synthesis
// ============================================================

/// Consume N stored entries of same type+level and produce 1 stored entry of level+1. Returns TRUE on success.
/// Permanent (study) entries cannot be used as synthesis ingredients. Operates on stored_knowledge only.
/datum/component/dieci_knowledge/proc/synthesize(type, level)
	if(level >= 5)
		to_chat(parent, span_warning("Cannot synthesize beyond level 5."))
		return FALSE
	// Count non-permanent stored entries matching type+level
	var/count = 0
	for(var/list/entry in stored_knowledge)
		if(entry["type"] == type && entry["level"] == level && !entry["permanent"])
			count++
	if(count < synthesis_cost)
		to_chat(parent, span_warning("Need [synthesis_cost] [type] L[level] stored entries to synthesize. You have [count]."))
		return FALSE
	// Consume from stored_knowledge
	var/consumed = 0
	for(var/i in length(stored_knowledge) to 1 step -1)
		if(consumed >= synthesis_cost)
			break
		var/list/entry = stored_knowledge[i]
		if(entry["type"] == type && entry["level"] == level && !entry["permanent"])
			stored_knowledge.Cut(i, i + 1)
			consumed++
	if(consumed < synthesis_cost)
		return FALSE
	// Add result to stored_knowledge
	var/new_level = level + 1
	var/list/new_entry = list(
		"type" = type,
		"level" = new_level,
		"flavor" = generate_flavor(type, new_level),
		"source" = "Synthesis",
		"rereads_remaining" = max(1, 7 - new_level)
	)
	stored_knowledge += list(new_entry)
	to_chat(parent, span_nicegreen("Synthesized [consumed] [type] L[level] stored entries into 1 [type] L[new_level] stored entry!"))
	return TRUE

// ============================================================
// Queries
// ============================================================

/// Returns total count of active knowledge entries.
/datum/component/dieci_knowledge/proc/get_knowledge_count()
	return length(active_knowledge)

/// Returns count of entries matching the given type.
/datum/component/dieci_knowledge/proc/get_count_by_type(type)
	var/count = 0
	for(var/list/entry in active_knowledge)
		if(entry["type"] == type)
			count++
	return count

/// Returns count of entries matching both type and level. If exclude_permanent is TRUE, skips permanent (study) entries.
/datum/component/dieci_knowledge/proc/get_count_by_type_and_level(type, level, exclude_permanent = FALSE)
	var/count = 0
	for(var/list/entry in active_knowledge)
		if(entry["type"] == type && entry["level"] == level)
			if(exclude_permanent && entry["permanent"])
				continue
			count++
	return count

// ============================================================
// Flavor Text Generator
// ============================================================

/// Generate a random flavor text snippet for a knowledge entry.
/datum/component/dieci_knowledge/proc/generate_flavor(type, level)
	switch(type)
		if(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
			return pick(list(
				"Notes on aggressive posturing patterns.",
				"Observations of territorial behaviors.",
				"Analysis of prey-stalking techniques.",
				"Study of fight-or-flight responses.",
				"Documented threat display sequences.",
				"Record of group hierarchy dynamics.",
				"Notes on environmental adaptation.",
				"Study of hunting coordination patterns."
			))
		if(DIECI_KNOWLEDGE_TYPE_MEDICAL)
			return pick(list(
				"Record of wound treatment procedures.",
				"Notes on physiological stress responses.",
				"Documentation of vital sign patterns.",
				"Analysis of tissue regeneration rates.",
				"Study of pain response thresholds.",
				"Record of emergency triage decisions.",
				"Notes on blood loss stabilization.",
				"Documentation of bone fracture patterns."
			))
		if(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
			return pick(list(
				"Reflections on mortality and purpose.",
				"Meditations on the nature of suffering.",
				"Contemplation of inner resilience.",
				"Observations on the bonds between people.",
				"Notes on the meaning of sacrifice.",
				"Study of faith under duress.",
				"Reflections on the weight of loss.",
				"Meditations on charity and selflessness."
			))
	return "A fragment of collected knowledge."
