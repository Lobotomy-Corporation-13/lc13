// RCE Harvest Mark Component - Marks mobs for body part drops

/datum/component/rce_harvest_mark
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/mark_duration = 60 SECONDS
	var/overlay_icon = 'icons/effects/effects.dmi'
	var/overlay_state = "shield2"
	var/image/mark_overlay

/datum/component/rce_harvest_mark/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/L = parent

	// Add visual overlay
	mark_overlay = image(overlay_icon, L, overlay_state, layer = ABOVE_MOB_LAYER)
	mark_overlay.alpha = 128
	mark_overlay.color = "#00FF00"
	L.add_overlay(mark_overlay)

	// Register for death signal
	RegisterSignal(L, COMSIG_LIVING_DEATH, PROC_REF(on_death))

	// Set timer to remove mark
	addtimer(CALLBACK(src, PROC_REF(remove_mark)), mark_duration)

/datum/component/rce_harvest_mark/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER

	// Initialize bestiary if needed
	if(!length(GLOB.rce_bestiary_entries))
		initialize_rce_bestiary()

	// Get harvest data from bestiary
	var/datum/rce_bestiary_entry/entry = get_bestiary_entry_for_mob(source)
	if(!entry)
		remove_mark()
		return

	var/datum/harvest_data/data = entry.get_harvest_data()

	// Drop body parts
	for(var/i in 1 to data.drop_count)
		if(!prob(data.drop_chance))
			continue

		var/obj/item/rce_bodypart/part = new /obj/item/rce_bodypart(get_turf(source))
		part.assign_traits(data.traits)
		part.base_value = rand(data.base_value * 0.8, data.base_value * 1.2) // ±20% variance
		part.source_mob = source.name

	// Visual and audio feedback
	playsound(source, 'sound/effects/blobattack.ogg', 50, TRUE)
	new /obj/effect/temp_visual/harvest_extract(get_turf(source))

	// Remove component after dropping parts
	remove_mark()

/datum/component/rce_harvest_mark/proc/remove_mark()
	var/mob/living/L = parent
	if(mark_overlay)
		L.cut_overlay(mark_overlay)
		mark_overlay = null
	qdel(src)

// ============================================
// HARVEST DATA STRUCTURE
// ============================================

// Data structure to hold mob harvest information
/datum/harvest_data
	var/list/traits = list()
	var/drop_count = 1
	var/drop_chance = 100
	var/base_value = 10

// ============================================
// VISUAL EFFECTS
// ============================================

// Visual effect for extraction
/obj/effect/temp_visual/harvest_extract
	name = "biological extraction"
	icon = 'icons/effects/effects.dmi'
	icon_state = "emppulse"
	layer = ABOVE_MOB_LAYER
	duration = 16
