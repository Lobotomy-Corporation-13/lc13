/**
 * Resurgence Machine Fabricator
 *
 * A specialized pod for resurgence machines that can:
 * - Display health, faith, and faith events for occupants
 * - Accept food to extract protein for storage
 * - Revive dead machines at the cost of 50 protein
 * - Purge chemicals at the cost of 5 faith
 */

/// Cost in protein to revive a dead machine
#define FABRICATOR_REVIVE_COST 50
/// Cost in faith to purge chemicals
#define FABRICATOR_PURGE_COST 5
/// Animation duration for opening/closing
#define FABRICATOR_ANIM_TIME 3.2 SECONDS

/obj/structure/resurgence_fabricator
	name = "machine fabricator"
	desc = "A sophisticated pod designed to repair and maintain resurgence machines. Feed it protein-rich food to power its revival systems."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "fab_robot_open"
	density = TRUE
	anchored = TRUE

	/// Whether the pod is currently open
	var/state_open = TRUE
	/// The mob currently inside
	var/mob/living/carbon/human/occupant = null
	/// Stored protein for revival
	var/stored_protein = 0
	/// Maximum protein storage
	var/max_protein = 200
	/// Whether an animation is currently playing
	var/animating = FALSE

/obj/structure/resurgence_fabricator/Initialize(mapload)
	. = ..()
	update_icon_state()

/obj/structure/resurgence_fabricator/Destroy()
	if(occupant)
		eject_occupant()
	return ..()

/obj/structure/resurgence_fabricator/update_icon_state()
	if(state_open)
		icon_state = "fab_robot_open"
	else
		icon_state = "fab_robot"

/obj/structure/resurgence_fabricator/examine(mob/user)
	. = ..()
	. += span_notice("Stored protein: [stored_protein]/[max_protein]")
	if(state_open)
		. += span_notice("Alt-click to close. Click to enter.")
	else
		. += span_notice("Alt-click to open.")
	if(occupant)
		. += span_notice("Currently occupied by [occupant].")

/obj/structure/resurgence_fabricator/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(animating)
		to_chat(user, span_warning("The fabricator is still cycling."))
		return
	if(state_open)
		close_pod()
	else
		open_pod()

/obj/structure/resurgence_fabricator/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(animating)
		to_chat(user, span_warning("The fabricator is still cycling."))
		return

	// If open and no occupant, user can enter
	if(state_open && !occupant)
		enter_pod(user)
		return

	// If closed with occupant, open the UI
	if(!state_open && occupant)
		ui_interact(user)
		return

	// If open with occupant somehow, just note it
	if(occupant)
		to_chat(user, span_notice("[occupant] is inside the fabricator."))

/// Allow dragging mobs into the pod
/obj/structure/resurgence_fabricator/MouseDrop_T(mob/target, mob/user)
	if(HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !ishuman(target) || !ISADVANCEDTOOLUSER(user))
		return
	if(animating)
		to_chat(user, span_warning("The fabricator is still cycling."))
		return
	if(!state_open)
		to_chat(user, span_warning("The fabricator is closed."))
		return
	if(occupant)
		to_chat(user, span_warning("The fabricator is already occupied."))
		return

	var/mob/living/carbon/human/H = target
	enter_pod(H)

/// Feed food to the fabricator to add protein
/obj/structure/resurgence_fabricator/attackby(obj/item/I, mob/living/user, params)
	// Accept food items
	if(istype(I, /obj/item/food))
		feed_protein(I, user)
		return

	return ..()

/// Extract protein from food and add to storage
/obj/structure/resurgence_fabricator/proc/feed_protein(obj/item/food/F, mob/user)
	if(stored_protein >= max_protein)
		to_chat(user, span_warning("The fabricator's protein storage is full."))
		return

	// Check for protein in the food's reagents
	var/protein_amount = 0
	if(F.reagents)
		protein_amount = F.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment/protein)

	if(protein_amount <= 0)
		to_chat(user, span_warning("[F] contains no protein."))
		return

	// Add to storage
	var/added = min(protein_amount, max_protein - stored_protein)
	stored_protein += added

	to_chat(user, span_notice("You feed [F] to the fabricator. Extracted [added] units of protein."))
	playsound(src, 'sound/machines/closet_open.ogg', 50, TRUE)
	qdel(F)

/obj/structure/resurgence_fabricator/proc/enter_pod(mob/living/carbon/human/M)
	if(!state_open || occupant || animating)
		return

	M.forceMove(src)
	occupant = M
	to_chat(M, span_notice("You climb into the fabricator pod."))
	close_pod()

/obj/structure/resurgence_fabricator/proc/eject_occupant()
	if(!occupant)
		return

	var/mob/living/M = occupant
	occupant = null
	M.forceMove(get_turf(src))

/obj/structure/resurgence_fabricator/proc/open_pod()
	if(state_open || animating)
		return

	animating = TRUE
	flick("fab_robot_a", src)
	addtimer(CALLBACK(src, PROC_REF(finish_open)), FABRICATOR_ANIM_TIME)

/obj/structure/resurgence_fabricator/proc/finish_open()
	animating = FALSE
	state_open = TRUE
	update_icon_state()
	if(occupant)
		eject_occupant()

/obj/structure/resurgence_fabricator/proc/close_pod()
	if(!state_open || animating)
		return

	animating = TRUE
	flick("fab_robot_a_close", src)
	addtimer(CALLBACK(src, PROC_REF(finish_close)), FABRICATOR_ANIM_TIME)

/obj/structure/resurgence_fabricator/proc/finish_close()
	animating = FALSE
	state_open = FALSE
	update_icon_state()
	if(occupant)
		to_chat(occupant, span_notice("The fabricator pod hums to life around you."))

/// Allow occupant to resist out
/obj/structure/resurgence_fabricator/container_resist_act(mob/living/user)
	if(animating)
		to_chat(user, span_warning("Wait for the pod to finish cycling."))
		return
	visible_message(span_notice("[user] climbs out of [src]."))
	open_pod()

/obj/structure/resurgence_fabricator/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == occupant)
		occupant = null

/obj/structure/resurgence_fabricator/relaymove(mob/living/user, direction)
	if(!state_open)
		container_resist_act(user)

// ============================================
// TGUI Interface
// ============================================

/obj/structure/resurgence_fabricator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceFabricator", name)
		ui.open()

/obj/structure/resurgence_fabricator/ui_state(mob/user)
	return GLOB.default_state

/obj/structure/resurgence_fabricator/ui_data(mob/user)
	var/list/data = list()

	data["open"] = state_open
	data["animating"] = animating
	data["stored_protein"] = stored_protein
	data["max_protein"] = max_protein
	data["revive_cost"] = FABRICATOR_REVIVE_COST
	data["purge_cost"] = FABRICATOR_PURGE_COST

	data["has_occupant"] = !!occupant
	data["is_resurgence_machine"] = FALSE

	if(occupant)
		data["occupant_name"] = occupant.name

		// Health info
		switch(occupant.stat)
			if(CONSCIOUS)
				data["occupant_stat"] = "Conscious"
				data["occupant_stat_state"] = "good"
			if(SOFT_CRIT)
				data["occupant_stat"] = "Critical"
				data["occupant_stat_state"] = "average"
			if(UNCONSCIOUS, HARD_CRIT)
				data["occupant_stat"] = "Unconscious"
				data["occupant_stat_state"] = "average"
			if(DEAD)
				data["occupant_stat"] = "Dead"
				data["occupant_stat_state"] = "bad"

		data["occupant_health"] = occupant.health
		data["occupant_max_health"] = occupant.maxHealth
		data["occupant_brute"] = occupant.getBruteLoss()
		data["occupant_burn"] = occupant.getFireLoss()
		data["occupant_tox"] = occupant.getToxLoss()
		data["occupant_oxy"] = occupant.getOxyLoss()

		// Check for resurgence machine species
		if(istype(occupant.dna?.species, /datum/species/resurgence_machine))
			data["is_resurgence_machine"] = TRUE

			// Get faith info from core
			var/obj/item/organ/resurgence_core/core = occupant.getorganslot(ORGAN_SLOT_HEART)
			if(core)
				data["faith"] = core.faith
				data["max_faith"] = core.max_faith
				data["faith_rate"] = core.faith_change_rate
				data["faith_level"] = core.get_faith_level_name()

				// Get all faith events
				var/list/events = list()
				for(var/category in core.faith_events)
					var/datum/faith_event/event = core.faith_events[category]
					if(event && !event.hidden)
						var/time_remaining = event.get_time_remaining()
						events += list(list(
							"category" = category,
							"description" = event.description,
							"change" = event.faith_change,
							"time_remaining" = time_remaining
						))
				data["faith_events"] = events

		// Get reagents/chemicals in occupant
		var/list/reagents = list()
		if(occupant.reagents?.reagent_list?.len)
			for(var/datum/reagent/R in occupant.reagents.reagent_list)
				reagents += list(list(
					"name" = R.name,
					"volume" = round(R.volume, 0.1)
				))
		data["occupant_reagents"] = reagents

		// Check stomach reagents too
		var/list/stomach_reagents = list()
		var/obj/item/organ/stomach/belly = occupant.getorganslot(ORGAN_SLOT_STOMACH)
		if(belly?.reagents?.reagent_list?.len)
			for(var/datum/reagent/R in belly.reagents.reagent_list)
				// Skip food reagents that are being digested
				if(!belly.food_reagents || !belly.food_reagents[R.type])
					stomach_reagents += list(list(
						"name" = R.name,
						"volume" = round(R.volume, 0.1)
					))
		data["stomach_reagents"] = stomach_reagents

		// Can we revive?
		data["can_revive"] = (occupant.stat == DEAD && stored_protein >= FABRICATOR_REVIVE_COST && data["is_resurgence_machine"])
		// Can we purge?
		var/has_reagents = (length(reagents) > 0 || length(stomach_reagents) > 0)
		data["can_purge"] = has_reagents && data["is_resurgence_machine"]

	return data

/obj/structure/resurgence_fabricator/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("open")
			if(!animating)
				open_pod()
			return TRUE

		if("close")
			if(!animating && state_open)
				close_pod()
			return TRUE

		if("revive")
			attempt_revive(usr)
			return TRUE

		if("purge")
			attempt_purge(usr)
			return TRUE

	return FALSE

/// Attempt to revive a dead resurgence machine
/obj/structure/resurgence_fabricator/proc/attempt_revive(mob/user)
	if(!occupant)
		to_chat(user, span_warning("No occupant in the fabricator."))
		return

	if(occupant.stat != DEAD)
		to_chat(user, span_warning("The occupant is not dead."))
		return

	if(!istype(occupant.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, span_warning("This fabricator can only revive resurgence machines."))
		return

	if(stored_protein < FABRICATOR_REVIVE_COST)
		to_chat(user, span_warning("Insufficient protein. Need [FABRICATOR_REVIVE_COST], have [stored_protein]."))
		return

	// Consume protein
	stored_protein -= FABRICATOR_REVIVE_COST

	// Revive the occupant
	if(occupant.revive(full_heal = TRUE, admin_revive = TRUE))
		occupant.grab_ghost(force = TRUE) // Even suicides

		// Get their core and set faith to 25
		var/obj/item/organ/resurgence_core/core = occupant.getorganslot(ORGAN_SLOT_HEART)
		if(core)
			core.faith = 25

			// Add negative faith event for 5 minutes
			var/datum/faith_event/revival_trauma = new(
				"Recently revived - existential dread.",
				-2, // Strong negative effect
				5 MINUTES,
				"revival_trauma"
			)
			core.add_faith_event("revival_trauma", revival_trauma)

		visible_message(span_notice("[src] hums loudly as it reconstructs [occupant]!"))
		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
		to_chat(occupant, span_warning("You have been rebuilt by the fabricator. You feel... hollow."))

		log_game("[key_name(user)] revived [key_name(occupant)] using the resurgence fabricator.")
	else
		// Refund if revive failed
		stored_protein += FABRICATOR_REVIVE_COST
		to_chat(user, span_warning("Revival failed. The occupant cannot be revived."))

/// Attempt to purge all chemicals from occupant
/obj/structure/resurgence_fabricator/proc/attempt_purge(mob/user)
	if(!occupant)
		to_chat(user, span_warning("No occupant in the fabricator."))
		return

	if(!istype(occupant.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, span_warning("This fabricator can only purge chemicals from resurgence machines."))
		return

	// Get the core to check faith
	var/obj/item/organ/resurgence_core/core = occupant.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		to_chat(user, span_warning("The occupant has no resurgence core."))
		return

	if(core.faith < FABRICATOR_PURGE_COST)
		to_chat(user, span_warning("The occupant doesn't have enough faith. Need [FABRICATOR_PURGE_COST], have [core.faith]."))
		return

	// Check if there are any reagents to purge
	var/has_reagents = FALSE
	if(occupant.reagents?.reagent_list?.len)
		has_reagents = TRUE
	var/obj/item/organ/stomach/belly = occupant.getorganslot(ORGAN_SLOT_STOMACH)
	if(belly?.reagents?.reagent_list?.len)
		has_reagents = TRUE

	if(!has_reagents)
		to_chat(user, span_notice("The occupant has no chemicals to purge."))
		return

	// Drain faith
	core.adjust_faith(-FABRICATOR_PURGE_COST)

	// Purge blood reagents
	if(occupant.reagents)
		occupant.reagents.clear_reagents()

	// Purge stomach reagents
	if(belly?.reagents)
		belly.reagents.clear_reagents()
		belly.food_reagents = list() // Clear food tracking too

	visible_message(span_notice("[src] flushes chemicals from [occupant]'s system."))
	playsound(src, 'sound/effects/spray2.ogg', 50, TRUE)
	to_chat(occupant, span_notice("You feel the fabricator flush all chemicals from your body."))

	log_game("[key_name(user)] purged chemicals from [key_name(occupant)] using the resurgence fabricator (cost: [FABRICATOR_PURGE_COST] faith).")

// ============================================
// Faith Event Subtype for Revival
// ============================================

/datum/faith_event/revival_trauma
	category = "revival_trauma"

#undef FABRICATOR_REVIVE_COST
#undef FABRICATOR_PURGE_COST
#undef FABRICATOR_ANIM_TIME
