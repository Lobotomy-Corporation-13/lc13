/**
 * Resurgence Machine Fabricator
 *
 * A specialized pod for resurgence machines that can:
 * - Display health, faith, and faith events for occupants
 * - Accept food to extract protein for storage
 * - Accept metal sheets for revival material
 * - Revive dead machines at the cost of 50 metal
 * - Purge chemicals at the cost of 5 faith
 */

/// Cost in metal sheets to revive a dead machine
#define FABRICATOR_METAL_COST 50
/// Cost in faith to purge chemicals
#define FABRICATOR_PURGE_COST 5
/// Animation duration for opening/closing
#define FABRICATOR_ANIM_TIME 3.2 SECONDS
/// Time to attach a limb
#define FABRICATOR_LIMB_ATTACH_TIME 5 SECONDS
/// Time to remove a limb
#define FABRICATOR_LIMB_REMOVE_TIME 10 SECONDS
/// Maximum number of limbs that can be stored
#define FABRICATOR_MAX_LIMBS 10

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
	/// Stored metal sheets for revival
	var/stored_metal = 0
	/// Maximum metal storage
	var/max_metal = 50
	/// Whether an animation is currently playing
	var/animating = FALSE
	/// List of stored bodyparts for transplanting
	var/list/stored_limbs = list()
	/// Whether a limb operation is in progress
	var/limb_operating = FALSE

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
	. += span_notice("Stored metal: [stored_metal]/[max_metal]")
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

/// Feed food to the fabricator to add protein, or metal sheets for revival
/obj/structure/resurgence_fabricator/attackby(obj/item/I, mob/living/user, params)
	// Accept food items
	if(istype(I, /obj/item/food))
		feed_protein(I, user)
		return

	// Accept metal sheets
	if(istype(I, /obj/item/stack/sheet/metal))
		feed_metal(I, user)
		return

	// Accept bodyparts for storage
	if(istype(I, /obj/item/bodypart))
		store_limb(I, user)
		return

	return ..()

/// Store a limb in the fabricator
/obj/structure/resurgence_fabricator/proc/store_limb(obj/item/bodypart/BP, mob/user)
	if(length(stored_limbs) >= FABRICATOR_MAX_LIMBS)
		to_chat(user, span_warning("The fabricator's limb storage is full."))
		return

	if(!user.transferItemToLoc(BP, src))
		return

	stored_limbs += BP
	to_chat(user, span_notice("You insert [BP] into the fabricator's limb storage."))
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)

/// Eject a stored limb from the fabricator
/obj/structure/resurgence_fabricator/proc/eject_stored_limb(mob/user, limb_index)
	if(limb_index < 1 || limb_index > length(stored_limbs))
		to_chat(user, span_warning("Invalid limb selection."))
		return

	var/obj/item/bodypart/BP = stored_limbs[limb_index]
	if(!BP || QDELETED(BP))
		stored_limbs -= BP
		to_chat(user, span_warning("That limb is no longer available."))
		return

	stored_limbs -= BP
	BP.forceMove(get_turf(src))
	to_chat(user, span_notice("You eject [BP] from the fabricator."))
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)

/// Attempt to attach a stored limb to the occupant
/obj/structure/resurgence_fabricator/proc/attempt_attach_limb(mob/user, limb_index)
	if(!occupant)
		to_chat(user, span_warning("No occupant in the fabricator."))
		return

	if(!istype(occupant.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, span_warning("This fabricator can only attach limbs to resurgence machines."))
		return

	if(limb_operating)
		to_chat(user, span_warning("A limb operation is already in progress."))
		return

	if(limb_index < 1 || limb_index > length(stored_limbs))
		to_chat(user, span_warning("Invalid limb selection."))
		return

	var/obj/item/bodypart/BP = stored_limbs[limb_index]
	if(!BP || QDELETED(BP))
		stored_limbs -= BP
		to_chat(user, span_warning("That limb is no longer available."))
		return

	// Check if occupant is missing this limb type
	var/limb_zone = BP.body_zone
	var/obj/item/bodypart/existing = occupant.get_bodypart(limb_zone)
	if(existing)
		to_chat(user, span_warning("[occupant] already has a [existing.name]."))
		return

	// Start the attachment process
	limb_operating = TRUE
	to_chat(user, span_notice("The fabricator begins attaching [BP] to [occupant]..."))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	if(!do_after(user, FABRICATOR_LIMB_ATTACH_TIME, src))
		limb_operating = FALSE
		to_chat(user, span_warning("The limb attachment was interrupted."))
		return

	// Verify everything is still valid
	if(!occupant || QDELETED(occupant) || QDELETED(BP) || !(BP in stored_limbs))
		limb_operating = FALSE
		to_chat(user, span_warning("The limb attachment failed."))
		return

	// Check again if they still need the limb
	existing = occupant.get_bodypart(limb_zone)
	if(existing)
		limb_operating = FALSE
		to_chat(user, span_warning("[occupant] already has a [existing.name]."))
		return

	// Remove from storage and attach
	stored_limbs -= BP
	BP.attach_limb(occupant, TRUE)

	limb_operating = FALSE
	visible_message(span_notice("[src] successfully attaches [BP] to [occupant]!"))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	to_chat(occupant, span_notice("You feel a new limb being attached to your body."))

	log_game("[key_name(user)] attached [BP] to [key_name(occupant)] using the resurgence fabricator.")

/// Attempt to remove a limb from the occupant
/obj/structure/resurgence_fabricator/proc/attempt_remove_limb(mob/user, limb_zone)
	if(!occupant)
		to_chat(user, span_warning("No occupant in the fabricator."))
		return

	if(!istype(occupant.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, span_warning("This fabricator can only remove limbs from resurgence machines."))
		return

	if(limb_operating)
		to_chat(user, span_warning("A limb operation is already in progress."))
		return

	if(length(stored_limbs) >= FABRICATOR_MAX_LIMBS)
		to_chat(user, span_warning("The fabricator's limb storage is full."))
		return

	var/obj/item/bodypart/BP = occupant.get_bodypart(limb_zone)
	if(!BP)
		to_chat(user, span_warning("[occupant] doesn't have that limb."))
		return

	// Can't remove chest or head
	if(limb_zone == BODY_ZONE_CHEST || limb_zone == BODY_ZONE_HEAD)
		to_chat(user, span_warning("The fabricator cannot safely remove that body part."))
		return

	// Start the removal process
	limb_operating = TRUE
	to_chat(user, span_notice("The fabricator begins carefully removing [BP] from [occupant]..."))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	if(!do_after(user, FABRICATOR_LIMB_REMOVE_TIME, src))
		limb_operating = FALSE
		to_chat(user, span_warning("The limb removal was interrupted."))
		return

	// Verify everything is still valid
	if(!occupant || QDELETED(occupant))
		limb_operating = FALSE
		to_chat(user, span_warning("The limb removal failed."))
		return

	// Check if they still have the limb
	BP = occupant.get_bodypart(limb_zone)
	if(!BP)
		limb_operating = FALSE
		to_chat(user, span_warning("[occupant] no longer has that limb."))
		return

	// Check storage again
	if(length(stored_limbs) >= FABRICATOR_MAX_LIMBS)
		limb_operating = FALSE
		to_chat(user, span_warning("The fabricator's limb storage is full."))
		return

	// Remove and store the limb
	var/obj/item/bodypart/removed = BP.dismember()
	if(removed)
		removed.forceMove(src)
		stored_limbs += removed

		limb_operating = FALSE
		visible_message(span_notice("[src] carefully removes [removed] from [occupant] and stores it."))
		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
		to_chat(occupant, span_warning("You feel a limb being detached from your body."))

		log_game("[key_name(user)] removed [removed] from [key_name(occupant)] using the resurgence fabricator.")
	else
		limb_operating = FALSE
		to_chat(user, span_warning("The limb removal failed unexpectedly."))

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

/// Feed metal sheets to the fabricator for revival material
/obj/structure/resurgence_fabricator/proc/feed_metal(obj/item/stack/sheet/metal/M, mob/user)
	if(stored_metal >= max_metal)
		to_chat(user, span_warning("The fabricator's metal storage is full."))
		return

	var/space = max_metal - stored_metal
	var/to_add = min(M.amount, space)

	M.use(to_add)
	stored_metal += to_add

	to_chat(user, span_notice("You insert [to_add] metal sheet\s into the fabricator."))
	playsound(src, 'sound/machines/closet_open.ogg', 50, TRUE)

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
	data["stored_metal"] = stored_metal
	data["max_metal"] = max_metal
	data["metal_cost"] = FABRICATOR_METAL_COST
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
		data["can_revive"] = (occupant.stat == DEAD && stored_metal >= FABRICATOR_METAL_COST && data["is_resurgence_machine"])
		// Can we purge?
		var/has_reagents = (length(reagents) > 0 || length(stomach_reagents) > 0)
		data["can_purge"] = has_reagents && data["is_resurgence_machine"]

		// Get missing limbs for attachment
		var/list/missing_limbs = list()
		if(data["is_resurgence_machine"])
			var/list/limb_zones = list(
				BODY_ZONE_L_ARM,
				BODY_ZONE_R_ARM,
				BODY_ZONE_L_LEG,
				BODY_ZONE_R_LEG
			)
			for(var/zone in limb_zones)
				if(!occupant.get_bodypart(zone))
					missing_limbs += list(list(
						"zone" = zone,
						"name" = zone
					))
		data["missing_limbs"] = missing_limbs

		// Get removable limbs
		var/list/removable_limbs = list()
		if(data["is_resurgence_machine"])
			for(var/obj/item/bodypart/BP as anything in occupant.bodyparts)
				if(BP.body_zone == BODY_ZONE_CHEST || BP.body_zone == BODY_ZONE_HEAD)
					continue
				removable_limbs += list(list(
					"zone" = BP.body_zone,
					"name" = BP.name
				))
		data["removable_limbs"] = removable_limbs

	// Stored limbs data
	var/list/limbs_data = list()
	for(var/i in 1 to length(stored_limbs))
		var/obj/item/bodypart/BP = stored_limbs[i]
		if(BP && !QDELETED(BP))
			limbs_data += list(list(
				"index" = i,
				"name" = BP.name,
				"zone" = BP.body_zone
			))
	data["stored_limbs"] = limbs_data
	data["max_limbs"] = FABRICATOR_MAX_LIMBS
	data["limb_operating"] = limb_operating

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

		if("attach_limb")
			var/limb_index = text2num(params["limb_index"])
			attempt_attach_limb(usr, limb_index)
			return TRUE

		if("remove_limb")
			var/limb_zone = params["limb_zone"]
			attempt_remove_limb(usr, limb_zone)
			return TRUE

		if("eject_limb")
			var/limb_index = text2num(params["limb_index"])
			eject_stored_limb(usr, limb_index)
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

	if(stored_metal < FABRICATOR_METAL_COST)
		to_chat(user, span_warning("Insufficient metal. Need [FABRICATOR_METAL_COST], have [stored_metal]."))
		return

	// Consume metal
	stored_metal -= FABRICATOR_METAL_COST

	// Save the core before revival to preserve traits, stats, and passions
	// revive() with admin_revive calls regenerate_organs() which replaces the core
	var/obj/item/organ/resurgence_core/saved_core = occupant.getorganslot(ORGAN_SLOT_HEART)
	if(saved_core)
		saved_core.Remove(occupant, TRUE)

	// Revive the occupant (will create a new blank core via regenerate_organs)
	if(occupant.revive(full_heal = TRUE, admin_revive = TRUE))
		occupant.grab_ghost(force = TRUE) // Even suicides

		// Remove the blank core that regenerate_organs created
		var/obj/item/organ/resurgence_core/blank_core = occupant.getorganslot(ORGAN_SLOT_HEART)
		if(blank_core && blank_core != saved_core)
			blank_core.Remove(occupant, TRUE)
			qdel(blank_core)

		// Reinsert the original core with all traits, stats, and passions preserved
		if(saved_core)
			saved_core.Insert(occupant, TRUE, FALSE)
			saved_core.faith = 25

			// Re-apply trait effects that modify the mob directly
			// Call remove() first to clean up stale effects (e.g., bodypart reductions),
			// then apply() to reapply cleanly to current bodyparts
			for(var/datum/resurgence_trait/T in saved_core.applied_traits)
				T.remove()
				T.apply(occupant)

			// Add negative faith event for 5 minutes
			var/datum/faith_event/revival_trauma = new(
				"Recently revived - existential dread.",
				-2, // Strong negative effect
				5 MINUTES,
				"revival_trauma"
			)
			saved_core.add_faith_event("revival_trauma", revival_trauma)

		visible_message(span_notice("[src] hums loudly as it reconstructs [occupant]!"))
		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
		to_chat(occupant, span_warning("You have been rebuilt by the fabricator. You feel... hollow."))

		log_game("[key_name(user)] revived [key_name(occupant)] using the resurgence fabricator.")
	else
		// Refund if revive failed
		stored_metal += FABRICATOR_METAL_COST
		// Reinsert saved core even on failure
		if(saved_core)
			saved_core.Insert(occupant, TRUE, FALSE)
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

#undef FABRICATOR_METAL_COST
#undef FABRICATOR_PURGE_COST
#undef FABRICATOR_ANIM_TIME
#undef FABRICATOR_LIMB_ATTACH_TIME
#undef FABRICATOR_LIMB_REMOVE_TIME
#undef FABRICATOR_MAX_LIMBS
