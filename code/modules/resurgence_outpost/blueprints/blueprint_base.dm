/**
 * Resurgence Outpost - Blueprint Base
 *
 * Base blueprint structure that players place and add materials to.
 * When all required materials are added, the blueprint constructs
 * into the target structure.
 */

/obj/structure/resurgence_blueprint
	name = "blueprint"
	desc = "A construction blueprint. Add the required materials to build it."
	icon = 'icons/obj/structures.dmi'
	icon_state = "lattice"
	anchored = TRUE
	density = FALSE
	layer = 2.5
	alpha = 100  // Transparent ghost appearance
	color = "#80c0ff"  // Light blue tint

	/// The structure type this blueprint builds
	var/result_type = null
	/// Display name for the structure being built
	var/result_name = "structure"

	/// List of required materials: type path -> amount needed
	var/list/required_materials = list()
	/// List of materials already added: type path -> amount added
	var/list/added_materials = list()

	/// Base time it takes to add each material batch
	var/build_time = 2 SECONDS
	/// XP awarded per material unit added
	var/xp_per_material = 2
	/// Sound to play when adding materials
	var/build_sound = 'sound/items/deconstruct.ogg'
	/// Sound to play when construction completes
	var/complete_sound = 'sound/items/Ratchet.ogg'

	/// Whether this blueprint is currently being worked on
	var/being_built = FALSE
	/// Reference to the last person who contributed materials (for beauty bonus)
	var/mob/last_builder = null
	/// If TRUE, the result structure will not be anchored (e.g., trash cart)
	var/unanchored_result = FALSE
	/// Category this blueprint belongs to (set by outpost_planner)
	var/blueprint_category = ""
	/// Base beauty value for production structures (negative)
	var/production_beauty = -15
	/// Base beauty value for non-production structures
	var/base_beauty = 5

/obj/structure/resurgence_blueprint/Initialize(mapload)
	. = ..()
	init_materials()
	update_desc()

/// Override in subtypes to set required materials
/obj/structure/resurgence_blueprint/proc/init_materials()
	return

/// Update description to show required materials
/obj/structure/resurgence_blueprint/proc/update_desc()
	var/list/desc_parts = list()
	desc_parts += "A blueprint for building a [result_name]."
	desc_parts += ""
	desc_parts += "<b>Required Materials:</b>"

	for(var/material_type in required_materials)
		var/needed = required_materials[material_type]
		var/added = added_materials[material_type] || 0
		var/material_name = get_material_name(material_type)
		var/status = added >= needed ? "COMPLETE" : "[added]/[needed]"
		desc_parts += "  [material_name]: [status]"

	desc_parts += ""
	desc_parts += get_completion_status()

	desc = desc_parts.Join("\n")

/// Get human-readable name for a material type
/obj/structure/resurgence_blueprint/proc/get_material_name(material_type)
	// Create temporary instance to get name
	var/obj/item/temp = new material_type()
	var/mat_name = temp.name
	qdel(temp)
	return capitalize(mat_name)

/// Get completion percentage text
/obj/structure/resurgence_blueprint/proc/get_completion_status()
	var/total_needed = 0
	var/total_added = 0
	for(var/material_type in required_materials)
		total_needed += required_materials[material_type]
		total_added += min(added_materials[material_type] || 0, required_materials[material_type])

	if(total_needed <= 0)
		return "Ready to build!"

	var/percent = round((total_added / total_needed) * 100)
	return "Progress: [percent]%"

/// Check if a material type is needed
/obj/structure/resurgence_blueprint/proc/needs_material(material_type)
	for(var/required_type in required_materials)
		if(ispath(material_type, required_type))
			// Special case: don't accept cloth as cotton
			if(required_type == /obj/item/stack/sheet/cotton)
				if(ispath(material_type, /obj/item/stack/sheet/cotton/cloth))
					continue
			var/needed = required_materials[required_type]
			var/added = added_materials[required_type] || 0
			if(added < needed)
				return required_type
	return null

/// Check if all materials have been added
/obj/structure/resurgence_blueprint/proc/is_complete()
	for(var/material_type in required_materials)
		var/needed = required_materials[material_type]
		var/added = added_materials[material_type] || 0
		if(added < needed)
			return FALSE
	return TRUE

/// Get build time accounting for player's construction stat
/obj/structure/resurgence_blueprint/proc/get_build_time(mob/user)
	var/time = build_time
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			time *= get_stat_speed_modifier(core.stat_crafting)
	return time

/// Award crafting XP to a player for building
/obj/structure/resurgence_blueprint/proc/award_construction_xp(mob/user, amount)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.award_xp("crafting", amount)

/// Get beauty bonus from player's crafting stat
/obj/structure/resurgence_blueprint/proc/get_construction_beauty_bonus(mob/user)
	if(!ishuman(user))
		return 0
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		return get_stat_beauty_bonus(core.stat_crafting)
	return 0

/// Calculate the beauty value for the constructed structure
/// Production structures get negative beauty, others get positive based on crafting skill
/obj/structure/resurgence_blueprint/proc/calculate_beauty_value(mob/user)
	// Production structures always have negative beauty (industrial equipment)
	if(blueprint_category == "Production")
		return production_beauty

	// Other structures get positive beauty based on crafting skill
	var/beauty = base_beauty
	var/skill_bonus = get_construction_beauty_bonus(user)
	return beauty + skill_bonus

/obj/structure/resurgence_blueprint/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click to rotate. Hit with an outpost planner to remove.")

/obj/structure/resurgence_blueprint/attackby(obj/item/I, mob/living/user, params)
	// Outpost planner can remove blueprints
	if(istype(I, /obj/item/resurgence_outpost_planner))
		remove_blueprint_with_planner(user)
		return

	// Check if this material is needed
	var/matching_type = needs_material(I.type)
	if(!matching_type)
		to_chat(user, span_warning("The [name] doesn't need [I.name]."))
		return ..()

	if(being_built)
		to_chat(user, span_warning("Someone is already working on this blueprint."))
		return

	var/needed = required_materials[matching_type]
	var/added = added_materials[matching_type] || 0
	var/remaining = needed - added

	// Handle stacks
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		var/to_add = min(S.amount, remaining)

		being_built = TRUE
		to_chat(user, span_notice("You begin adding [I.name] to the [name]..."))

		if(!do_after(user, get_build_time(user), target = src))
			being_built = FALSE
			return

		// Verify stack still exists and has enough
		if(QDELETED(S) || S.amount < to_add)
			being_built = FALSE
			to_chat(user, span_warning("You no longer have enough materials."))
			return

		S.use(to_add)
		added_materials[matching_type] = added + to_add
		playsound(src, build_sound, 50, TRUE)
		to_chat(user, span_notice("You add [to_add] [I.name] to the [name]."))

		// Award construction XP for materials added
		award_construction_xp(user, to_add * xp_per_material)
		last_builder = user

		being_built = FALSE

	// Handle non-stack items (components, etc.)
	else
		being_built = TRUE
		to_chat(user, span_notice("You begin adding [I.name] to the [name]..."))

		if(!do_after(user, get_build_time(user), target = src))
			being_built = FALSE
			return

		if(QDELETED(I))
			being_built = FALSE
			to_chat(user, span_warning("You no longer have the materials."))
			return

		qdel(I)
		added_materials[matching_type] = added + 1
		playsound(src, build_sound, 50, TRUE)
		to_chat(user, span_notice("You add [I.name] to the [name]."))

		// Award construction XP for materials added
		award_construction_xp(user, xp_per_material)
		last_builder = user

		being_built = FALSE

	update_desc()

	// Check if construction is complete
	if(is_complete())
		complete_construction(user)

/// Called when all materials have been added - builds the actual structure
/obj/structure/resurgence_blueprint/proc/complete_construction(mob/user)
	if(!result_type)
		to_chat(user, span_warning("Error: Blueprint has no result type defined!"))
		return

	to_chat(user, span_notice("You finish building the [result_name]!"))
	playsound(src, complete_sound, 50, TRUE)

	var/turf/T = get_turf(src)

	// Handle turf creation (walls, floors) differently from structures
	if(ispath(result_type, /turf))
		// Change the turf to the new type
		var/turf/new_turf = T.ChangeTurf(result_type)
		if(new_turf)
			// Update smoothing for the new wall and its neighbors
			QUEUE_SMOOTH(new_turf)
			QUEUE_SMOOTH_NEIGHBORS(new_turf)
	else
		// Create the result structure
		var/atom/result = new result_type(T)
		if(result)
			// Copy rotation if applicable
			if(istype(result, /obj/structure))
				var/obj/structure/S = result
				S.setDir(dir)
				// Auto-anchor built structures unless unanchored_result is set
				if(!unanchored_result)
					S.anchored = TRUE

			// Apply beauty based on category
			var/beauty_value = calculate_beauty_value(user)
			if(beauty_value != 0)
				result.AddComponent(/datum/component/beauty, beauty_value)

	// Remove the blueprint
	qdel(src)

/// Alt-click to rotate
/obj/structure/resurgence_blueprint/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	// Rotate 90 degrees clockwise
	setDir(turn(dir, -90))
	to_chat(user, span_notice("You rotate the [name]."))

/// Right-click verb to remove
/obj/structure/resurgence_blueprint/verb/remove_blueprint()
	set name = "Remove Blueprint"
	set category = "Object"
	set src in oview(1)

	var/mob/user = usr
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return

	// Return some materials if any were added
	var/returned_anything = FALSE
	for(var/material_type in added_materials)
		var/amount = added_materials[material_type]
		if(amount > 0)
			// Return half of added materials (rounded down, minimum 0)
			var/return_amount = round(amount / 2)
			if(return_amount > 0)
				if(ispath(material_type, /obj/item/stack))
					new material_type(get_turf(src), return_amount)
				else
					for(var/i in 1 to return_amount)
						new material_type(get_turf(src))
				returned_anything = TRUE

	if(returned_anything)
		to_chat(user, span_notice("You dismantle the [name] and recover some materials."))
	else
		to_chat(user, span_notice("You remove the [name]."))

	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(src)

/// Remove blueprint when hit with a blueprint planner
/obj/structure/resurgence_blueprint/proc/remove_blueprint_with_planner(mob/user)
	// Return some materials if any were added
	var/returned_anything = FALSE
	for(var/material_type in added_materials)
		var/amount = added_materials[material_type]
		if(amount > 0)
			// Return half of added materials (rounded down, minimum 0)
			var/return_amount = round(amount / 2)
			if(return_amount > 0)
				if(ispath(material_type, /obj/item/stack))
					new material_type(get_turf(src), return_amount)
				else
					for(var/i in 1 to return_amount)
						new material_type(get_turf(src))
				returned_anything = TRUE

	if(returned_anything)
		to_chat(user, span_notice("You dismantle the [name] and recover some materials."))
	else
		to_chat(user, span_notice("You remove the [name]."))

	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(src)
