// ============================================================
// Dieci Association — Knowledge Tome
// ============================================================
// Sacred book that serves as the Dieci's primary tool.
// Scan hostiles for bestiary entries, observe living targets for behavioral data,
// examine dead bodies for medical/spiritual knowledge, and manage the knowledge shop.

/// The Dieci Knowledge Tome — a sacred book for recording knowledge, scanning creatures, and purchasing supplies.
/obj/item/dieci_tome
	name = "Knowledge Tome"
	desc = "A sacred tome of the Dieci Association. Used to record observations, scan creatures, and manage active knowledge."
	icon = 'icons/obj/storage.dmi'
	icon_state = "bible"
	inhand_icon_state = "bible"
	worn_icon_state = "bible"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	/// Weakref to the owning Dieci fixer
	var/datum/weakref/owner_ref
	/// Bestiary database — list of assoc lists with scanned creature data
	var/list/bestiary_database = list()
	/// Current bestiary page (1-indexed)
	var/bestiary_page = 1
	/// Weakref to the currently observed target
	var/datum/weakref/observed_target_ref
	/// Current TGUI tab
	var/current_tab = "knowledge"
	/// Static shop catalog (shared across all tomes)
	var/static/list/shop_items
	/// Currently active event (Director-only)
	var/datum/dieci_event/active_event
	/// world.time after which a new event can be started
	var/event_cooldown_until = 0
	/// Tome Studies — permanent knowledge sources that can be re-learned unlimited times
	var/list/tome_studies

/obj/item/dieci_tome/Destroy()
	stop_observation()
	if(active_event)
		active_event.fail()
		QDEL_NULL(active_event)
	owner_ref = null
	bestiary_database.Cut()
	return ..()

// ============================================================
// Helpers
// ============================================================

/// Resolve the owner weakref to a mob.
/obj/item/dieci_tome/proc/get_owner_mob()
	return owner_ref?.resolve()

/// Get the owner's dieci_knowledge component.
/obj/item/dieci_tome/proc/get_knowledge_comp()
	var/mob/living/owner_mob = get_owner_mob()
	if(!owner_mob)
		return null
	return owner_mob.GetComponent(/datum/component/dieci_knowledge)

/// Get the owner's association_exp component.
/obj/item/dieci_tome/proc/get_exp_comp()
	var/mob/living/owner_mob = get_owner_mob()
	if(!owner_mob)
		return null
	return owner_mob.GetComponent(/datum/component/association_exp)

/// Convert a mob's max HP to a knowledge level (1-5).
/obj/item/dieci_tome/proc/hp_to_knowledge_level(max_hp)
	if(max_hp <= 100)
		return 1
	if(max_hp <= 300)
		return 2
	if(max_hp <= 600)
		return 3
	if(max_hp <= 1000)
		return 4
	return 5

// ============================================================
// Core Interactions
// ============================================================

/obj/item/dieci_tome/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	// Auto-assign ownership to first Dieci user
	if(!owner_ref)
		var/datum/component/association_exp/exp = H.GetComponent(/datum/component/association_exp)
		if(!exp || exp.association_type != ASSOCIATION_DIECI)
			to_chat(H, span_warning("Only Dieci Association members can attune to this tome."))
			return
		owner_ref = WEAKREF(H)
		to_chat(H, span_nicegreen("You attune the Knowledge Tome to yourself."))
	// Verify ownership
	var/mob/living/owner_mob = get_owner_mob()
	if(H != owner_mob)
		to_chat(H, span_warning("This tome is attuned to someone else."))
		return
	init_shop()
	init_studies()
	ui_interact(H)

/obj/item/dieci_tome/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	// Verify ownership
	var/mob/living/owner_mob = get_owner_mob()
	if(!owner_mob || H != owner_mob)
		return
	// Range check — 7 tiles
	if(get_dist(H, target) > 7)
		to_chat(H, span_warning("Too far away to use the tome on that."))
		return
	// Route based on target type
	if(istype(target, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/hostile_mob = target
		if(hostile_mob.stat == DEAD)
			examine_dead_hostile(hostile_mob, H)
		else
			scan_hostile(hostile_mob, H)
		return
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.stat == DEAD && ishuman(C))
			examine_dead_body(C, H)
		else if(C.stat != DEAD)
			start_observation(C, H)
		return

// ============================================================
// Bestiary Scanning
// ============================================================

/// Scan a hostile mob for bestiary data. Awards 1 EXP and Behavioral knowledge.
/obj/item/dieci_tome/proc/scan_hostile(mob/living/simple_animal/hostile/target, mob/living/carbon/human/user)
	// Skip NPC dialogue mobs — they're not valid research subjects
	if(istype(target, /mob/living/simple_animal/hostile/ui_npc))
		to_chat(user, span_warning("This individual is not a valid research subject."))
		return
	// Check if already scanned this species
	var/target_type = target.type
	for(var/list/entry in bestiary_database)
		if(entry["type_path"] == "[target_type]")
			to_chat(user, span_notice("You have already recorded [target.name] in your bestiary."))
			return
	// Build bestiary entry
	var/knowledge_level = hp_to_knowledge_level(target.maxHealth)
	var/list/entry = list(
		"name" = target.name,
		"desc" = target.desc,
		"type_path" = "[target_type]",
		"max_health" = target.maxHealth,
		"melee_damage" = target.melee_damage_upper,
		"knowledge_level" = knowledge_level
	)
	bestiary_database += list(entry)
	// Award EXP
	var/datum/component/association_exp/exp = get_exp_comp()
	if(exp)
		exp.modify_exp(1)
	// Award Behavioral knowledge
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, knowledge_level, null, "Bestiary: [target.name]")
	to_chat(user, span_nicegreen("Creature scanned: [target.name]. Behavioral L[knowledge_level] knowledge gained."))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)

// ============================================================
// Observation System
// ============================================================

/// Mark a living carbon for behavioral observation.
/obj/item/dieci_tome/proc/start_observation(mob/living/carbon/target, mob/living/carbon/human/user)
	// Check if already observing this target
	var/mob/living/current = observed_target_ref?.resolve()
	if(current == target)
		to_chat(user, span_warning("You are already observing [target]."))
		return
	// Can't observe fellow Dieci members
	var/datum/component/association_exp/target_exp = target.GetComponent(/datum/component/association_exp)
	if(target_exp && target_exp.association_type == ASSOCIATION_DIECI)
		to_chat(user, span_warning("You cannot observe fellow Dieci members."))
		return
	// Clear previous observation
	stop_observation()
	// Set new observation
	observed_target_ref = WEAKREF(target)
	RegisterSignal(target, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_observed_damage))
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_observed_death))
	to_chat(user, span_nicegreen("You begin observing [target]. Watch for interesting behaviors..."))

/// Stop observing the current target.
/obj/item/dieci_tome/proc/stop_observation()
	var/mob/living/target = observed_target_ref?.resolve()
	if(target)
		UnregisterSignal(target, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
	observed_target_ref = null

/// Signal handler: observed target takes damage. 20% chance on >10 damage → EXP + Behavioral L1.
/obj/item/dieci_tome/proc/on_observed_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(damage <= 10)
		return
	if(!prob(20))
		return
	var/mob/living/owner_mob = get_owner_mob()
	if(!owner_mob || owner_mob.stat == DEAD)
		return
	var/mob/living/target = source
	if(!(target in view(7, owner_mob)))
		return
	INVOKE_ASYNC(src, PROC_REF(award_observation), owner_mob, target)

/// Async proc to award observation EXP and knowledge (since signal handlers can't sleep).
/obj/item/dieci_tome/proc/award_observation(mob/living/owner_mob, mob/living/target)
	var/datum/component/association_exp/exp = get_exp_comp()
	if(exp)
		exp.modify_exp(1)
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, 1, null, "Observation: [target.name]")
	to_chat(owner_mob, span_notice("Interesting behavior noted. Behavioral L1 knowledge gained."))

/// Signal handler: observed target died. Stop observation.
/obj/item/dieci_tome/proc/on_observed_death(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/owner_mob = get_owner_mob()
	if(owner_mob)
		to_chat(owner_mob, span_warning("Your observation subject has died."))
	stop_observation()

// ============================================================
// Dead Body Examination
// ============================================================

/// Examine a dead human body. 5s do_after. Player body = 5 EXP + Spiritual L3, NPC = 3 EXP + Medical L2.
/obj/item/dieci_tome/proc/examine_dead_body(mob/living/carbon/human/target, mob/living/carbon/human/user)
	// Check if already examined
	if(HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		to_chat(user, span_warning("This body has already been examined by a Dieci member."))
		return
	to_chat(user, span_notice("You begin examining the remains of [target]..."))
	if(!do_after(user, 5 SECONDS, target))
		to_chat(user, span_warning("Examination interrupted."))
		return
	// Double-check state after do_after
	if(target.stat != DEAD)
		to_chat(user, span_warning("[target] is no longer dead."))
		return
	if(HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		to_chat(user, span_warning("Someone else already examined this body."))
		return
	// Apply trait to prevent re-examination
	ADD_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)
	// Register for revive to clear the trait
	RegisterSignal(target, COMSIG_LIVING_REVIVE, PROC_REF(on_body_revived))
	// Determine EXP and knowledge type based on player vs NPC
	var/is_player = target.mind && target.ckey
	var/exp_amount
	var/knowledge_type
	var/knowledge_level
	if(is_player)
		exp_amount = 5
		knowledge_type = DIECI_KNOWLEDGE_TYPE_SPIRITUAL
		knowledge_level = 3
	else
		exp_amount = 3
		knowledge_type = DIECI_KNOWLEDGE_TYPE_MEDICAL
		knowledge_level = 2
	// Award EXP
	var/datum/component/association_exp/exp = get_exp_comp()
	if(exp)
		exp.modify_exp(exp_amount)
	// Award knowledge
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(dk)
		dk.add_active_knowledge(knowledge_type, knowledge_level, null, "Body Exam: [target.name]")
	to_chat(user, span_nicegreen("Examination complete. [knowledge_type] L[knowledge_level] knowledge gained. (+[exp_amount] EXP)"))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)

/// Signal handler: examined body was revived. Clear the examination trait.
/obj/item/dieci_tome/proc/on_body_revived(datum/source)
	SIGNAL_HANDLER
	var/mob/living/target = source
	REMOVE_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)
	UnregisterSignal(target, COMSIG_LIVING_REVIVE)

/// Examine a dead hostile mob body. 5s do_after. Awards 3 EXP + Medical L2 knowledge.
/obj/item/dieci_tome/proc/examine_dead_hostile(mob/living/simple_animal/hostile/target, mob/living/carbon/human/user)
	// Check if already examined
	if(HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		to_chat(user, span_warning("This body has already been examined by a Dieci member."))
		return
	to_chat(user, span_notice("You begin examining the remains of [target]..."))
	if(!do_after(user, 5 SECONDS, target))
		to_chat(user, span_warning("Examination interrupted."))
		return
	// Double-check state after do_after
	if(target.stat != DEAD)
		to_chat(user, span_warning("[target] is no longer dead."))
		return
	if(HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		to_chat(user, span_warning("Someone else already examined this body."))
		return
	// Apply trait to prevent re-examination
	ADD_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)
	// Register for revive to clear the trait
	RegisterSignal(target, COMSIG_LIVING_REVIVE, PROC_REF(on_body_revived))
	// Award 3 EXP + Medical L2
	var/datum/component/association_exp/exp = get_exp_comp()
	if(exp)
		exp.modify_exp(3)
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_MEDICAL, 2, null, "Body Exam: [target.name]")
	to_chat(user, span_nicegreen("Examination complete. Medical L2 knowledge gained. (+3 EXP)"))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)

// ============================================================
// Shop System
// ============================================================

/// Initialize the static shop catalog.
/obj/item/dieci_tome/proc/init_shop()
	if(shop_items)
		return
	shop_items = list(
		list(
			"name" = "Basic Healing Kit",
			"desc" = "A basic medical kit with 20 uses. Heals brute and burn damage.",
			"cost" = 200,
			"path" = /obj/item/dieci_healing_kit,
			"amount" = 1
		),
		list(
			"name" = "Standard Healing Kit",
			"desc" = "A standard medical kit with 40 uses. Improved potency.",
			"cost" = 400,
			"path" = /obj/item/dieci_healing_kit/standard,
			"amount" = 1
		),
		list(
			"name" = "Advanced Healing Kit",
			"desc" = "An advanced medical kit with 80 uses. Maximum potency.",
			"cost" = 800,
			"path" = /obj/item/dieci_healing_kit/advanced,
			"amount" = 1
		),
		list(
			"name" = "Sacred Seasoning",
			"desc" = "A blessed spice. Apply to food to grant healing when consumed.",
			"cost" = 200,
			"path" = /obj/item/dieci_sacred_seasoning,
			"amount" = 1
		)
	)

// ============================================================
// Tome Studies — Permanent Knowledge Sources
// ============================================================

/// Initialize the tome studies catalog. 15 entries: 6 L1, 6 L2, 3 L3.
/obj/item/dieci_tome/proc/init_studies()
	if(tome_studies)
		return
	tome_studies = list(
		// L1 — V1 (free)
		list("id" = 1, "type" = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, "level" = 1, "source" = "Study: Ruins Fauna", "flavor" = "Field observations of Ruins-dwelling creatures and their territorial instincts.", "cost" = 0, "unlocked" = TRUE),
		list("id" = 2, "type" = DIECI_KNOWLEDGE_TYPE_MEDICAL, "level" = 1, "source" = "Study: Relic Trauma Care", "flavor" = "A primer on treating wounds sustained from Relic exposure and E.G.O. manifestation.", "cost" = 0, "unlocked" = TRUE),
		list("id" = 3, "type" = DIECI_KNOWLEDGE_TYPE_SPIRITUAL, "level" = 1, "source" = "Study: Charity Doctrine", "flavor" = "Reflections on Dieci's founding principles of charity and community.", "cost" = 0, "unlocked" = TRUE),
		// L1 — V2 (1800 Ahn)
		list("id" = 4, "type" = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, "level" = 1, "source" = "Study: Backstreet Predators", "flavor" = "Documented behaviors of gangs and Syndicates operating in the Backstreets.", "cost" = 1800, "unlocked" = FALSE),
		list("id" = 5, "type" = DIECI_KNOWLEDGE_TYPE_MEDICAL, "level" = 1, "source" = "Study: Battlefield Triage", "flavor" = "Emergency medical procedures developed for combat zone casualties.", "cost" = 1800, "unlocked" = FALSE),
		list("id" = 6, "type" = DIECI_KNOWLEDGE_TYPE_SPIRITUAL, "level" = 1, "source" = "Study: Orphan's Parable", "flavor" = "A collection of parables told to orphans raised under Dieci's care.", "cost" = 1800, "unlocked" = FALSE),
		// L2 — V1 (2000 Ahn)
		list("id" = 7, "type" = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, "level" = 2, "source" = "Study: Distortion Analysis", "flavor" = "Comprehensive analysis of Distortion behavioral patterns and pre-manifestation signs.", "cost" = 2000, "unlocked" = FALSE),
		list("id" = 8, "type" = DIECI_KNOWLEDGE_TYPE_MEDICAL, "level" = 2, "source" = "Study: Advanced Triage", "flavor" = "Advanced surgical techniques adapted from K Corp. ampule therapy research.", "cost" = 2000, "unlocked" = FALSE),
		list("id" = 9, "type" = DIECI_KNOWLEDGE_TYPE_SPIRITUAL, "level" = 2, "source" = "Study: Saints and Relics", "flavor" = "Theological writings on the Saints and their Holy Relics, compiled across branches.", "cost" = 2000, "unlocked" = FALSE),
		// L2 — V2 (2500 Ahn)
		list("id" = 10, "type" = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, "level" = 2, "source" = "Study: Abnormality Protocols", "flavor" = "Behavioral analysis of Abnormalities documented from L Corp. facility records.", "cost" = 2500, "unlocked" = FALSE),
		list("id" = 11, "type" = DIECI_KNOWLEDGE_TYPE_MEDICAL, "level" = 2, "source" = "Study: Prosthetic Anatomy", "flavor" = "Detailed diagrams of prosthetic integration points, sourced from Calw's medical archives.", "cost" = 2500, "unlocked" = FALSE),
		list("id" = 12, "type" = DIECI_KNOWLEDGE_TYPE_SPIRITUAL, "level" = 2, "source" = "Study: The Smoke War", "flavor" = "First-hand spiritual accounts of the Smoke War and its impact on the City's soul.", "cost" = 2500, "unlocked" = FALSE),
		// L3 (3000 Ahn each)
		list("id" = 13, "type" = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, "level" = 3, "source" = "Study: Sweeper Autopsy", "flavor" = "Dissection notes on Sweeper anatomy, detailing the melted-down human core within.", "cost" = 3000, "unlocked" = FALSE),
		list("id" = 14, "type" = DIECI_KNOWLEDGE_TYPE_MEDICAL, "level" = 3, "source" = "Study: E.G.O. Manifestation", "flavor" = "Clinical records of E.G.O. emergence, documenting the boundary between mind and weapon.", "cost" = 3000, "unlocked" = FALSE),
		list("id" = 15, "type" = DIECI_KNOWLEDGE_TYPE_SPIRITUAL, "level" = 3, "source" = "Study: Forbidden Chronicle", "flavor" = "A forbidden account of the White Nights and Dark Days, and the Light that touched the City.", "cost" = 3000, "unlocked" = FALSE)
	)

/// Study a tome entry, adding permanent knowledge to Active Knowledge. Can be repeated unlimited times.
/obj/item/dieci_tome/proc/study_knowledge(study_id, mob/living/carbon/human/user)
	init_studies()
	var/list/study
	for(var/list/s in tome_studies)
		if(s["id"] == study_id)
			study = s
			break
	if(!study)
		return
	if(!study["unlocked"])
		to_chat(user, span_warning("This study has not been unlocked yet."))
		return
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(!dk)
		return
	if(length(dk.active_knowledge) >= dk.max_knowledge)
		to_chat(user, span_warning("Your Active Knowledge is full."))
		return
	// Check for active duplicate (same type + level + source)
	for(var/list/entry in dk.active_knowledge)
		if(entry["type"] == study["type"] && entry["level"] == study["level"] && entry["source"] == study["source"])
			to_chat(user, span_warning("You already have this knowledge active. Consume it first."))
			return
	to_chat(user, span_notice("You study the tome entry..."))
	if(!do_after(user, 3 SECONDS, src))
		to_chat(user, span_warning("Study interrupted."))
		return
	if(dk.add_active_knowledge(study["type"], study["level"], study["flavor"], study["source"], TRUE))
		// Add to stored knowledge as unlimited reread entry
		var/list/stored_entry = list(
			"type" = study["type"],
			"level" = study["level"],
			"flavor" = study["flavor"],
			"source" = study["source"],
			"rereads_remaining" = -1,
			"permanent" = TRUE
		)
		dk.stored_knowledge += list(stored_entry)
		// Hide from Studies tab
		study["studied"] = TRUE
		to_chat(user, span_nicegreen("[study["source"]]: [study["type"]] L[study["level"]] knowledge gained and stored permanently."))
		playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)
	else
		to_chat(user, span_warning("Failed to add knowledge. Capacity may be full."))

// ============================================================
// TGUI Interface
// ============================================================

/obj/item/dieci_tome/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DieciTome", name)
		ui.open()

/obj/item/dieci_tome/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/dieci_tome/ui_data(mob/user)
	var/list/data = list()
	data["tab"] = current_tab

	// Knowledge data (stored knowledge for display — active knowledge is in the action viewer)
	var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
	if(dk)
		data["stored_knowledge"] = dk.stored_knowledge
		data["stored_count"] = length(dk.stored_knowledge)
		data["synthesis_cost"] = dk.synthesis_cost
	else
		data["stored_knowledge"] = list()
		data["stored_count"] = 0
		data["synthesis_cost"] = 3

	// Tome Studies data
	init_studies()
	data["tome_studies"] = tome_studies

	// Observation data
	var/mob/living/observed = observed_target_ref?.resolve()
	data["observed_target"] = observed ? observed.name : null

	// Bestiary data
	data["bestiary"] = bestiary_database
	data["bestiary_page"] = bestiary_page
	data["bestiary_total"] = length(bestiary_database)

	// Shop data
	init_shop()
	data["shop_items"] = shop_items
	var/balance = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/card/id/id = H.get_idcard(TRUE)
		if(id?.registered_account)
			balance = id.registered_account.account_balance
	data["balance"] = balance

	// EXP data
	var/datum/component/association_exp/exp = get_exp_comp()
	if(exp)
		data["total_exp"] = exp.total_exp
		data["skill_points"] = exp.skill_points_available
	else
		data["total_exp"] = 0
		data["skill_points"] = 0

	// Event data
	var/is_director = FALSE
	if(exp && exp.rank == "director")
		is_director = TRUE
	data["is_director"] = is_director
	if(active_event?.active)
		data["has_active_event"] = TRUE
		data["event_name"] = active_event.event_name
		data["event_current_tick"] = active_event.current_tick
		data["event_total_ticks"] = active_event.total_ticks
		var/can_tick = TRUE
		if(active_event.current_tick > 0 && world.time < active_event.last_tick_time + active_event.tick_interval)
			can_tick = FALSE
		data["event_can_tick"] = can_tick
		var/cooldown_left = 0
		if(active_event.current_tick > 0)
			cooldown_left = max(0, round((active_event.last_tick_time + active_event.tick_interval - world.time) / 10))
		data["event_tick_cooldown"] = cooldown_left
	else
		data["has_active_event"] = FALSE
	data["event_on_cooldown"] = world.time < event_cooldown_until
	data["event_cooldown_left"] = max(0, round((event_cooldown_until - world.time) / 10))

	return data

/obj/item/dieci_tome/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		// Tab switching
		if("tab")
			current_tab = params["tab"]
			return TRUE

		// Record active knowledge to tome
		if("record")
			var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
			if(!dk)
				return
			var/mob/living/owner_mob = get_owner_mob()
			if(!owner_mob)
				return
			to_chat(owner_mob, span_notice("Recording knowledge to the tome..."))
			if(!do_after(owner_mob, DIECI_RECORD_TIME, src))
				to_chat(owner_mob, span_warning("Recording interrupted."))
				return
			var/count = dk.record_to_tome()
			if(count > 0)
				to_chat(owner_mob, span_nicegreen("[count] knowledge entries recorded to the tome."))
			else
				to_chat(owner_mob, span_warning("No new entries to record."))
			return TRUE

		// Remove a stored knowledge entry
		if("remove_stored")
			var/datum/component/dieci_knowledge/rm_dk = get_knowledge_comp()
			if(!rm_dk)
				return
			var/rm_index = text2num(params["index"])
			if(!rm_index || rm_index < 1 || rm_index > length(rm_dk.stored_knowledge))
				return
			var/list/entry = rm_dk.stored_knowledge[rm_index]
			rm_dk.stored_knowledge.Cut(rm_index, rm_index + 1)
			var/mob/living/owner_mob = get_owner_mob()
			if(owner_mob)
				to_chat(owner_mob, span_notice("Removed [entry["type"]] L[entry["level"]] from stored knowledge."))
			return TRUE

		// Synthesize stored knowledge
		if("synthesize")
			var/datum/component/dieci_knowledge/synth_dk = get_knowledge_comp()
			if(!synth_dk)
				return
			var/synth_type = params["type"]
			var/synth_level = text2num(params["level"])
			if(!synth_type || !synth_level)
				return
			synth_dk.synthesize(synth_type, synth_level)
			return TRUE

		// Purchase a tome study unlock
		if("purchase_study")
			var/study_id = text2num(params["study_id"])
			if(!study_id)
				return
			init_studies()
			var/list/study
			for(var/list/s in tome_studies)
				if(s["id"] == study_id)
					study = s
					break
			if(!study || study["unlocked"])
				return
			var/cost = study["cost"]
			if(!ishuman(usr))
				return
			var/mob/living/carbon/human/buyer = usr
			var/obj/item/card/id/id = buyer.get_idcard(TRUE)
			if(!id?.registered_account)
				to_chat(buyer, span_warning("No registered bank account found."))
				return
			if(!id.registered_account.has_money(cost))
				to_chat(buyer, span_warning("Insufficient funds. Need [cost] Ahn."))
				return
			id.registered_account.adjust_money(-cost)
			study["unlocked"] = TRUE
			to_chat(buyer, span_nicegreen("Unlocked [study["source"]] for [cost] Ahn."))
			playsound(get_turf(buyer), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)
			return TRUE

		// Study a tome entry for permanent knowledge
		if("study")
			var/study_id = text2num(params["study_id"])
			if(!study_id)
				return
			var/mob/living/owner_mob = get_owner_mob()
			if(!owner_mob || !ishuman(owner_mob))
				return
			study_knowledge(study_id, owner_mob)
			return TRUE

		// Re-read stored knowledge from tome
		if("reread")
			var/datum/component/dieci_knowledge/dk = get_knowledge_comp()
			if(!dk)
				return
			var/mob/living/owner_mob = get_owner_mob()
			if(!owner_mob)
				return
			to_chat(owner_mob, span_notice("Re-reading the tome..."))
			if(!do_after(owner_mob, DIECI_REREAD_TIME, src))
				to_chat(owner_mob, span_warning("Re-reading interrupted."))
				return
			var/count = dk.reread_from_tome()
			if(count > 0)
				to_chat(owner_mob, span_nicegreen("[count] knowledge entries restored from the tome."))
			else
				to_chat(owner_mob, span_warning("No stored entries to re-read, or knowledge is full."))
			return TRUE

		// Bestiary page navigation
		if("bestiary_page")
			var/new_page = text2num(params["page"])
			if(!new_page || new_page < 1)
				return
			if(new_page > length(bestiary_database))
				return
			bestiary_page = new_page
			return TRUE

		// Stop observation
		if("stop_observation")
			stop_observation()
			to_chat(usr, span_notice("Observation stopped."))
			return TRUE

		// Start a new event (Director-only)
		if("start_event")
			var/datum/component/association_exp/start_exp = get_exp_comp()
			if(!start_exp || start_exp.rank != "director")
				to_chat(usr, span_warning("Only the Director can host events."))
				return
			if(active_event?.active)
				to_chat(usr, span_warning("An event is already in progress."))
				return
			if(world.time < event_cooldown_until)
				to_chat(usr, span_warning("Events are on cooldown."))
				return
			var/event_type = params["event_type"]
			var/datum/dieci_event/new_event
			switch(event_type)
				if("book_reading")
					new_event = new /datum/dieci_event/book_reading()
				if("training_session")
					new_event = new /datum/dieci_event/training_session()
				if("charity_sermon")
					new_event = new /datum/dieci_event/charity_sermon()
				else
					return
			var/mob/living/carbon/human/director = get_owner_mob()
			if(!director)
				qdel(new_event)
				return
			if(!new_event.start(director))
				qdel(new_event)
				return
			active_event = new_event
			return TRUE

		// Perform event tick (Director-only)
		if("event_tick")
			if(!active_event?.active)
				return
			var/success = active_event.perform_tick()
			if(!active_event.active)
				// Event completed or failed
				event_cooldown_until = world.time + DIECI_EVENT_COOLDOWN
				QDEL_NULL(active_event)
			return success

		// Cancel active event
		if("cancel_event")
			if(!active_event?.active)
				return
			active_event.fail()
			event_cooldown_until = world.time + DIECI_EVENT_COOLDOWN
			QDEL_NULL(active_event)
			return TRUE

		// Purchase shop item
		if("purchase")
			var/item_index = text2num(params["index"])
			if(!item_index || item_index < 1 || item_index > length(shop_items))
				return
			var/list/entry = shop_items[item_index]
			var/cost = entry["cost"]
			var/path = entry["path"]
			var/amount = entry["amount"]
			if(!ishuman(usr))
				return
			var/mob/living/carbon/human/buyer = usr
			var/obj/item/card/id/id = buyer.get_idcard(TRUE)
			if(!id?.registered_account)
				to_chat(buyer, span_warning("No registered bank account found."))
				return
			if(!id.registered_account.has_money(cost))
				to_chat(buyer, span_warning("Insufficient funds. Need [cost] Ahn."))
				return
			id.registered_account.adjust_money(-cost)
			for(var/i in 1 to amount)
				var/obj/item/new_item = new path(get_turf(buyer))
				if(new_item)
					// Set owner on healing kits and seasoning
					if(istype(new_item, /obj/item/dieci_healing_kit))
						var/obj/item/dieci_healing_kit/kit = new_item
						kit.owner_ref = owner_ref
					else if(istype(new_item, /obj/item/dieci_sacred_seasoning))
						var/obj/item/dieci_sacred_seasoning/spice = new_item
						spice.owner_ref = owner_ref
					buyer.put_in_hands(new_item)
			to_chat(buyer, span_notice("Purchased [entry["name"]] for [cost] Ahn."))
			return TRUE
