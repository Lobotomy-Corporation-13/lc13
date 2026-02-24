// ============================================================
// Dieci Association — Events System (Director-Only)
// ============================================================
// Public events that the Director hosts for EXP and community benefits.
// Director performs ticks (channeling) in a zone; attendees receive benefits.

// ============================================================
// Base Event Datum
// ============================================================

/// Base datum for Dieci hosted events. Subtypes define specific tick/completion behaviors.
/datum/dieci_event
	/// Human-readable event name
	var/event_name = "Event"
	/// Key used for TGUI identification
	var/event_type_key = ""
	/// Ahn cost to start the event
	var/ahn_cost = 0
	/// Total number of ticks to complete the event
	var/total_ticks = 6
	/// Current tick number (0 = not started)
	var/current_tick = 0
	/// Minimum interval between ticks
	var/tick_interval = 40 SECONDS
	/// Radius of the event zone
	var/zone_radius = 5
	/// The Director hosting this event
	var/mob/living/host
	/// The center turf where the event was started
	var/turf/center_turf
	/// Zone visual effects
	var/list/obj/effect/contract_zone/zone_effects = list()
	/// Per-attendee tick count tracking (mob ref → count)
	var/list/attendee_ticks = list()
	/// Whether the event is currently active
	var/active = FALSE
	/// world.time of the last completed tick
	var/last_tick_time = 0
	/// Flavor lines the Director says each tick
	var/list/flavor_lines = list()
	/// Base EXP per tick for the Director
	var/base_exp = 3
	/// Additional EXP per non-Dieci attendee per tick
	var/per_attendee_exp = 2

/datum/dieci_event/Destroy()
	cleanup()
	host = null
	center_turf = null
	return ..()

/// Start the event. Deducts ahn, spawns zone, sets active. Returns TRUE on success.
/datum/dieci_event/proc/start(mob/living/carbon/human/director)
	host = director
	center_turf = get_turf(director)
	// Deduct ahn
	var/obj/item/card/id/id = director.get_idcard(TRUE)
	if(!id?.registered_account || !id.registered_account.has_money(ahn_cost))
		to_chat(director, span_warning("Insufficient funds. Need [ahn_cost] Ahn."))
		return FALSE
	id.registered_account.adjust_money(-ahn_cost)
	// Spawn zone effects (visible to all)
	spawn_zones()
	active = TRUE
	current_tick = 0
	last_tick_time = 0
	to_chat(director, span_nicegreen("[event_name] has begun! Perform [total_ticks] ticks to complete the event."))
	return TRUE

/// Spawn zone visual effects around the center turf.
/datum/dieci_event/proc/spawn_zones()
	for(var/turf/T in view(zone_radius, center_turf))
		var/obj/effect/contract_zone/Z = new(T)
		Z.invisibility = 0 // Events are public — visible to all
		Z.color = "#FFD700"
		zone_effects += Z

/// Perform a single event tick. Called by the Director via the Tome TGUI.
/datum/dieci_event/proc/perform_tick()
	if(!active || !host)
		return FALSE
	if(current_tick >= total_ticks)
		return FALSE
	// Check tick interval cooldown (skip for first tick)
	if(current_tick > 0 && world.time < last_tick_time + tick_interval)
		to_chat(host, span_warning("You must wait before the next tick. ([round((last_tick_time + tick_interval - world.time) / 10)]s remaining)"))
		return FALSE
	// Check host is in zone
	if(get_dist(host, center_turf) > zone_radius)
		to_chat(host, span_warning("You must be within the event zone to perform a tick."))
		return FALSE
	// 5s channeling
	to_chat(host, span_notice("Channeling [event_name]..."))
	if(!do_after(host, 5 SECONDS))
		fail()
		return FALSE
	// Verify still in zone after channeling
	if(get_dist(host, center_turf) > zone_radius)
		fail()
		return FALSE
	// Tick succeeded
	current_tick++
	last_tick_time = world.time
	// Director says flavor line
	if(current_tick <= length(flavor_lines))
		host.say(flavor_lines[current_tick])
	// Gather everyone in zone
	var/list/all_in_zone = get_all_in_zone()
	var/list/non_dieci = get_non_dieci(all_in_zone)
	// Apply benefits to all attendees
	apply_tick_benefits(all_in_zone)
	// Award EXP to Director (scaled by non-Dieci attendees)
	var/scaled_exp = base_exp + per_attendee_exp * length(non_dieci)
	var/datum/component/association_exp/director_exp = host.GetComponent(/datum/component/association_exp)
	if(director_exp)
		director_exp.modify_exp(scaled_exp)
	// Check for active Host Event contract — double EXP if at waypoint
	for(var/datum/association_squad/S in GLOB.association_squads)
		if(!(host in S.members))
			continue
		for(var/datum/association_contract/host_event/HEC in S.active_contracts)
			if(HEC.state == CONTRACT_STATE_ACTIVE && HEC.required_event_type == event_type_key && HEC.is_near_waypoint(center_turf))
				// Award bonus EXP equal to the base amount (doubling)
				if(director_exp)
					director_exp.modify_exp(scaled_exp)
		break
	// Award knowledge to Director
	award_tick_knowledge()
	// Award base EXP to other Dieci members in zone
	for(var/mob/living/M in all_in_zone)
		if(M == host)
			continue
		var/datum/component/association_exp/member_exp = M.GetComponent(/datum/component/association_exp)
		if(member_exp && member_exp.association_type == ASSOCIATION_DIECI)
			member_exp.modify_exp(base_exp)
	// Track attendee ticks for non-Dieci
	for(var/mob/living/A in non_dieci)
		var/aref = ref(A)
		if(!attendee_ticks[aref])
			attendee_ticks[aref] = 0
		attendee_ticks[aref]++
	// Check completion
	if(current_tick >= total_ticks)
		complete()
	return TRUE

/// Get all living non-host mobs in the event zone.
/datum/dieci_event/proc/get_all_in_zone()
	var/list/result = list()
	for(var/mob/living/L in view(zone_radius, center_turf))
		if(L == host)
			continue
		if(L.stat == DEAD)
			continue
		result += L
	return result

/// Filter a list of mobs to only non-Dieci members.
/datum/dieci_event/proc/get_non_dieci(list/mobs)
	var/list/result = list()
	for(var/mob/living/L in mobs)
		var/datum/component/association_exp/exp = L.GetComponent(/datum/component/association_exp)
		if(exp && exp.association_type == ASSOCIATION_DIECI)
			continue
		result += L
	return result

/// Override: apply per-tick benefits to all mobs in zone.
/datum/dieci_event/proc/apply_tick_benefits(list/all_in_zone)
	return

/// Override: award knowledge to the Director per tick.
/datum/dieci_event/proc/award_tick_knowledge()
	return

/// Complete the event successfully.
/datum/dieci_event/proc/complete()
	active = FALSE
	apply_completion_benefits()
	// Complete matching Host Event contract
	for(var/datum/association_squad/S in GLOB.association_squads)
		if(!(host in S.members))
			continue
		for(var/datum/association_contract/host_event/HEC in S.active_contracts)
			if(HEC.state == CONTRACT_STATE_ACTIVE && HEC.required_event_type == event_type_key)
				HEC.on_event_complete()
				break
		break
	to_chat(host, span_nicegreen("[event_name] completed successfully!"))
	playsound(get_turf(host), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	cleanup()

/// Fail the event (channeling interrupted).
/datum/dieci_event/proc/fail()
	active = FALSE
	to_chat(host, span_userdanger("[event_name] has failed! The channeling was interrupted. No refund."))
	cleanup()

/// Override: apply completion bonuses.
/datum/dieci_event/proc/apply_completion_benefits()
	return

/// Clean up zone effects.
/datum/dieci_event/proc/cleanup()
	for(var/obj/effect/contract_zone/Z in zone_effects)
		qdel(Z)
	zone_effects.Cut()

// ============================================================
// Book Reading — 500 ahn, 6 ticks, 40s interval
// ============================================================
// Per tick: attendees heal 17% max SP
// EXP: 3 + 2/attendee per tick
// Completion: spiritual_calm status effect

/datum/dieci_event/book_reading
	event_name = "Book Reading"
	event_type_key = "book_reading"
	ahn_cost = 500
	total_ticks = 6
	tick_interval = 40 SECONDS
	base_exp = 3
	per_attendee_exp = 2
	flavor_lines = list(
		"Let us begin today's reading...",
		"And so the story continues...",
		"Listen well to these words...",
		"The tale grows ever deeper...",
		"We approach the climax...",
		"And thus concludes our reading."
	)

/datum/dieci_event/book_reading/apply_tick_benefits(list/all_in_zone)
	var/list/non_dieci = get_non_dieci(all_in_zone)
	for(var/mob/living/L in non_dieci)
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			var/heal_amount = H.maxSanity * 0.17
			H.adjustSanityLoss(-heal_amount)

/datum/dieci_event/book_reading/award_tick_knowledge()
	var/datum/component/dieci_knowledge/dk = host.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_SPIRITUAL, 1, null, "Book Reading")

/datum/dieci_event/book_reading/apply_completion_benefits()
	// Grant spiritual_calm to non-Dieci attendees based on ticks attended
	for(var/aref in attendee_ticks)
		var/mob/living/attendee = locate(aref)
		if(!attendee || QDELETED(attendee) || attendee.stat == DEAD)
			continue
		var/ticks = attendee_ticks[aref]
		var/calm_duration = ticks * 60 SECONDS
		attendee.apply_status_effect(/datum/status_effect/spiritual_calm, calm_duration)
		to_chat(attendee, span_nicegreen("You feel spiritually at peace. The calm will last [ticks] minutes."))

// ============================================================
// Training Session — 1000 ahn, 6 ticks, 50s interval
// ============================================================
// Per tick: attendees get +4 all attributes (stacks to +20, 5min timer resets)
// EXP: 7 + 4/attendee per tick

/datum/dieci_event/training_session
	event_name = "Training Session"
	event_type_key = "training_session"
	ahn_cost = 1000
	total_ticks = 6
	tick_interval = 50 SECONDS
	base_exp = 7
	per_attendee_exp = 4
	flavor_lines = list(
		"Let us begin the exercises!",
		"Push through the pain!",
		"Discipline is strength!",
		"Feel your limits expanding!",
		"Almost there — give it everything!",
		"Excellent work, everyone!"
	)

/datum/dieci_event/training_session/apply_tick_benefits(list/all_in_zone)
	var/list/non_dieci = get_non_dieci(all_in_zone)
	for(var/mob/living/L in non_dieci)
		if(!ishuman(L))
			continue
		// Apply or stack the training buff
		var/datum/status_effect/dieci_training/existing = L.has_status_effect(/datum/status_effect/dieci_training)
		if(existing)
			existing.add_stack()
		else
			L.apply_status_effect(/datum/status_effect/dieci_training)

/datum/dieci_event/training_session/award_tick_knowledge()
	var/datum/component/dieci_knowledge/dk = host.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_SPIRITUAL, 1, null, "Training Session")

// ============================================================
// Charity Sermon — 1800 ahn, 7 ticks, 60s interval
// ============================================================
// Per tick: 255 ahn split among non-Dieci attendees (max 85 each)
// EXP: 16 + 10/attendee per tick
// Director earns no ahn

/datum/dieci_event/charity_sermon
	event_name = "Charity Sermon"
	event_type_key = "charity_sermon"
	ahn_cost = 1800
	total_ticks = 7
	tick_interval = 60 SECONDS
	base_exp = 16
	per_attendee_exp = 10
	flavor_lines = list(
		"Brothers and sisters, let us gather...",
		"Charity is the foundation of society...",
		"Through giving, we find purpose...",
		"Let your generosity flow freely...",
		"The world rewards the charitable...",
		"Share what you have, and receive tenfold...",
		"Go forth with the blessing of Dieci."
	)

/datum/dieci_event/charity_sermon/apply_tick_benefits(list/all_in_zone)
	// Distribute 255 ahn among non-Dieci attendees
	var/list/non_dieci = get_non_dieci(all_in_zone)
	if(!length(non_dieci))
		return
	var/per_person = min(85, round(255 / length(non_dieci)))
	if(per_person <= 0)
		return
	for(var/mob/living/L in non_dieci)
		if(!ishuman(L))
			continue
		var/mob/living/carbon/human/H = L
		var/obj/item/card/id/id = H.get_idcard(TRUE)
		if(id?.registered_account)
			id.registered_account.adjust_money(per_person)
			to_chat(H, span_nicegreen("You receive [per_person] Ahn from the charity sermon."))

/datum/dieci_event/charity_sermon/award_tick_knowledge()
	var/datum/component/dieci_knowledge/dk = host.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_SPIRITUAL, 1, null, "Charity Sermon")

// ============================================================
// Status Effects
// ============================================================

/// Spiritual Calm — heals 10 SP every 10s. Variable duration from Book Reading attendance.
/datum/status_effect/spiritual_calm
	id = "spiritual_calm"
	duration = -1
	tick_interval = 10 SECONDS
	alert_type = null

/datum/status_effect/spiritual_calm/on_creation(mob/living/new_owner, custom_duration)
	if(custom_duration)
		duration = custom_duration
	return ..()

/datum/status_effect/spiritual_calm/tick()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.adjustSanityLoss(-10)

/// Dieci Training — stacking attribute buff from Training Session. +4 all attributes per stack, max +20. 5min expiry timer resets on new stacks.
/datum/status_effect/dieci_training
	id = "dieci_training"
	duration = -1
	tick_interval = -1
	alert_type = null
	/// Total attribute bonus applied
	var/total_bonus = 0
	/// Timer ID for the 5-minute expiry
	var/expiry_timer

/datum/status_effect/dieci_training/on_creation(mob/living/new_owner)
	. = ..()
	if(!.)
		return
	add_stack()

/// Add +4 to all attributes (max +20 total). Resets the 5-minute expiry timer.
/datum/status_effect/dieci_training/proc/add_stack()
	if(total_bonus >= 20)
		// Already at max — just reset timer
		reset_expiry()
		return
	total_bonus += 4
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		for(var/atr_type in H.attributes)
			var/datum/attribute/atr = H.attributes[atr_type]
			if(istype(atr))
				atr.adjust_buff(H, 4)
	reset_expiry()

/// Reset the 5-minute expiry timer.
/datum/status_effect/dieci_training/proc/reset_expiry()
	if(expiry_timer)
		deltimer(expiry_timer)
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), 5 MINUTES, TIMER_STOPPABLE)

/// Timer callback — remove the effect when it expires.
/datum/status_effect/dieci_training/proc/expire()
	expiry_timer = null
	qdel(src)

/datum/status_effect/dieci_training/on_remove()
	// Remove accumulated attribute buffs
	if(ishuman(owner) && total_bonus > 0)
		var/mob/living/carbon/human/H = owner
		for(var/atr_type in H.attributes)
			var/datum/attribute/atr = H.attributes[atr_type]
			if(istype(atr))
				atr.adjust_buff(H, -total_bonus)
	if(expiry_timer)
		deltimer(expiry_timer)
		expiry_timer = null
