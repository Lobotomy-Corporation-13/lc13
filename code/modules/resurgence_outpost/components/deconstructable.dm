/**
 * Resurgence Outpost - Deconstructable Component
 *
 * Added to structures built via the blueprint system.
 * Allows deconstruction with an experimental welding tool.
 */

/datum/component/resurgence_deconstructable
	/// Materials to return on deconstruction (type -> amount)
	var/list/return_materials = list()

/datum/component/resurgence_deconstructable/Initialize(list/materials = null)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	if(materials)
		return_materials = materials.Copy()

	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))

/datum/component/resurgence_deconstructable/Destroy()
	UnregisterSignal(parent, COMSIG_PARENT_ATTACKBY)
	return ..()

/// Handle being attacked by items - check for experimental welder
/datum/component/resurgence_deconstructable/proc/on_attackby(datum/source, obj/item/weapon, mob/user, params)
	SIGNAL_HANDLER

	if(!istype(weapon, /obj/item/weldingtool/experimental))
		return

	// Must be on and have fuel
	var/obj/item/weldingtool/experimental/welder = weapon
	if(!welder.isOn())
		to_chat(user, span_warning("The welder must be on to deconstruct."))
		return COMPONENT_NO_AFTERATTACK

	// Start deconstruction - need to use INVOKE_ASYNC since we're in a signal handler
	INVOKE_ASYNC(src, PROC_REF(attempt_deconstruct), user, welder)
	return COMPONENT_NO_AFTERATTACK

/// Attempt to deconstruct the parent structure
/datum/component/resurgence_deconstructable/proc/attempt_deconstruct(mob/user, obj/item/weldingtool/experimental/welder)
	var/atom/target = parent
	if(QDELETED(target))
		return

	to_chat(user, span_notice("You begin deconstructing [target]..."))
	playsound(target, 'sound/items/welder.ogg', 50, TRUE)

	if(!do_after(user, 2 SECONDS, target = target))
		to_chat(user, span_warning("You stop deconstructing [target]."))
		return

	if(QDELETED(target) || QDELETED(welder))
		return

	// Check welder still on
	if(!welder.isOn())
		to_chat(user, span_warning("The welder turned off!"))
		return

	// Use some fuel
	welder.use(1)

	// Return materials
	var/turf/drop_loc = get_turf(target)
	var/returned_anything = FALSE
	for(var/material_type in return_materials)
		var/amount = return_materials[material_type]
		if(amount > 0)
			// Return half of materials (rounded down, minimum 1 if any were used)
			var/return_amount = max(1, round(amount / 2))
			if(ispath(material_type, /obj/item/stack))
				new material_type(drop_loc, return_amount)
			else
				for(var/i in 1 to return_amount)
					new material_type(drop_loc)
			returned_anything = TRUE

	if(returned_anything)
		to_chat(user, span_notice("You deconstruct [target] and recover some materials."))
	else
		to_chat(user, span_notice("You deconstruct [target]."))

	playsound(drop_loc, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(target)
