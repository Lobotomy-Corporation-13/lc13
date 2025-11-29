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

	// Get mob harvest data
	var/datum/harvest_data/data = get_harvest_data(source)
	if(!data)
		remove_mark()
		return

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
// MAIN HARVEST DATA GETTER
// ============================================

/datum/component/rce_harvest_mark/proc/get_harvest_data(mob/living/L)
	// Check mob type and assign appropriate data
	if(istype(L, /mob/living/simple_animal/hostile/xcorp))
		return get_xcorp_harvest_data(L)
	else if(istype(L, /mob/living/simple_animal/hostile/clan))
		return get_clan_harvest_data(L)

	// Unknown mob type - return null
	return null

// ============================================
// X-CORP MOB HARVEST DATA
// ============================================

/datum/component/rce_harvest_mark/proc/get_xcorp_harvest_data(mob/living/simple_animal/hostile/xcorp/X)
	var/datum/harvest_data/data = new

	// Base X-Corp grunt (Laute)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp) && !X.type != /mob/living/simple_animal/hostile/xcorp)
		data.traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_HEAVY)
		data.drop_count = 1
		data.drop_chance = 100
		data.base_value = 10
		return data

	// X-Corp DPS (Studiose)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp/dps))
		data.traits = list(TRAIT_ORGANIC, TRAIT_WEAPONIZED, TRAIT_AGILE)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 80
		data.base_value = 20
		return data

	// X-Corp Tank (Nimis)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp/tank))
		data.traits = list(TRAIT_ORGANIC, TRAIT_ARMORED, TRAIT_HEAVY)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 85
		data.base_value = 22
		return data

	// X-Corp Scout (Praepropere)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp/scout))
		data.traits = list(TRAIT_ORGANIC, TRAIT_AGILE, TRAIT_VOLATILE)
		data.drop_count = 1
		data.drop_chance = 75
		data.base_value = 22
		return data

	// X-Corp Sapper (Ardenter)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp/sapper))
		data.traits = list(TRAIT_ORGANIC, TRAIT_PSIONIC, TRAIT_ABERRANT, TRAIT_TOXIC)
		data.drop_count = 1
		data.drop_chance = 90
		data.base_value = 22
		return data

	// X-Corp Heart Units (Elite)
	if(istype(X, /mob/living/simple_animal/hostile/xcorp/heart))
		// Heart DPS (Sumptus Excessivi)
		if(istype(X, /mob/living/simple_animal/hostile/xcorp/heart/dps))
			data.traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_WEAPONIZED, TRAIT_BERSERKER)
			data.drop_count = prob(50) ? 2 : 1
			data.drop_chance = 80
			data.base_value = 35
			return data

		// Heart Ranged (Sicarius)
		if(istype(X, /mob/living/simple_animal/hostile/xcorp/heart/ranged))
			data.traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_PRECISION, TRAIT_AGILE)
			data.drop_count = prob(50) ? 2 : 1
			data.drop_chance = 80
			data.base_value = 35
			return data

		// Base Heart (Accumulatio)
		data.traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_HEAVY, TRAIT_REGENERATIVE)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 80
		data.base_value = 35
		return data

	// Default X-Corp
	data.traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_HEAVY)
	data.drop_count = 1
	data.drop_chance = 100
	data.base_value = 10
	return data

// ============================================
// RESURGENCE CLAN HARVEST DATA
// ============================================

/datum/component/rce_harvest_mark/proc/get_clan_harvest_data(mob/living/simple_animal/hostile/clan/C)
	var/datum/harvest_data/data = new

	// Check if greed-touched variant
	var/is_greed = findtext("[C.type]", "greed")

	// Scout
	if(istype(C, /mob/living/simple_animal/hostile/clan/scout))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_LIGHTWEIGHT, TRAIT_FODDER) : \
			list(TRAIT_MECHANICAL, TRAIT_LIGHTWEIGHT, TRAIT_FODDER)
		data.drop_count = 1
		data.drop_chance = 100
		data.base_value = is_greed ? 10 : 8
		return data

	// Defender
	if(istype(C, /mob/living/simple_animal/hostile/clan/defender))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_ARMORED, TRAIT_OSSIFIED) : \
			list(TRAIT_MECHANICAL, TRAIT_ARMORED, TRAIT_HEAVY)
		data.drop_count = 1
		data.drop_chance = 90
		data.base_value = is_greed ? 20 : 15
		return data

	// Drone
	if(istype(C, /mob/living/simple_animal/hostile/clan/drone))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_NEURAL, TRAIT_TOXIC) : \
			list(TRAIT_MECHANICAL, TRAIT_ADAPTIVE, TRAIT_FODDER)
		data.drop_count = 1
		data.drop_chance = 95
		data.base_value = is_greed ? 15 : 10
		return data

	// Demolisher
	if(istype(C, /mob/living/simple_animal/hostile/clan/demolisher))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_BRUTAL) : \
			list(TRAIT_MECHANICAL, TRAIT_ARMORED, TRAIT_WEAPONIZED, TRAIT_HEAVY)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 85
		data.base_value = is_greed ? 30 : 22
		return data

	// Assassin
	if(istype(C, /mob/living/simple_animal/hostile/clan/assassin))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_AGILE, TRAIT_ELITE, TRAIT_ABERRANT) : \
			list(TRAIT_MECHANICAL, TRAIT_AGILE, TRAIT_WEAPONIZED, TRAIT_LIGHTWEIGHT)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 75
		data.base_value = is_greed ? 35 : 25
		return data

	// Ranged units
	if(istype(C, /mob/living/simple_animal/hostile/clan/ranged))
		return get_clan_ranged_harvest_data(C, is_greed)

	// Default clan unit
	data.traits = is_greed ? \
		list(TRAIT_HYBRID, TRAIT_FODDER) : \
		list(TRAIT_MECHANICAL, TRAIT_FODDER)
	data.drop_count = 1
	data.drop_chance = 95
	data.base_value = is_greed ? 12 : 10
	return data

// ============================================
// CLAN RANGED UNIT HARVEST DATA
// ============================================

/datum/component/rce_harvest_mark/proc/get_clan_ranged_harvest_data(mob/living/simple_animal/hostile/clan/ranged/R, is_greed)
	var/datum/harvest_data/data = new

	// Sniper
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/sniper))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_PRECISION, TRAIT_ABERRANT) : \
			list(TRAIT_MECHANICAL, TRAIT_PRECISION, TRAIT_LIGHTWEIGHT)
		data.drop_count = 1
		data.drop_chance = 80
		data.base_value = is_greed ? 22 : 18
		return data

	// Gunner
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/gunner))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_FODDER) : \
			list(TRAIT_MECHANICAL, TRAIT_WEAPONIZED, TRAIT_FODDER)
		data.drop_count = 1
		data.drop_chance = 85
		data.base_value = is_greed ? 25 : 20
		return data

	// Rapid
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/rapid))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_VOLATILE, TRAIT_ERRATIC) : \
			list(TRAIT_MECHANICAL, TRAIT_ENERGIZED, TRAIT_LIGHTWEIGHT)
		data.drop_count = 1
		data.drop_chance = 90
		data.base_value = is_greed ? 20 : 15
		return data

	// Warper
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/warper))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_NEURAL, TRAIT_PSIONIC, TRAIT_CORRUPTED) : \
			list(TRAIT_MECHANICAL, TRAIT_NEURAL, TRAIT_PSIONIC)
		data.drop_count = prob(50) ? 2 : 1
		data.drop_chance = 75
		data.base_value = is_greed ? 35 : 28
		return data

	// Harpooner
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/harpooner))
		data.traits = is_greed ? \
			list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_BRUTAL) : \
			list(TRAIT_MECHANICAL, TRAIT_WEAPONIZED, TRAIT_HEAVY)
		data.drop_count = 1
		data.drop_chance = 80
		data.base_value = is_greed ? 30 : 25
		return data

	// Corrupter (Boss)
	if(istype(R, /mob/living/simple_animal/hostile/clan/ranged/corrupter))
		data.traits = list(TRAIT_HYBRID, TRAIT_CORRUPTED, TRAIT_ELITE, TRAIT_HIVEMIND)
		data.drop_count = prob(50) ? 3 : 2
		data.drop_chance = 60
		data.base_value = 60
		return data

	// Default ranged
	data.traits = is_greed ? \
		list(TRAIT_HYBRID, TRAIT_WEAPONIZED) : \
		list(TRAIT_MECHANICAL, TRAIT_WEAPONIZED)
	data.drop_count = 1
	data.drop_chance = 85
	data.base_value = is_greed ? 20 : 18
	return data

// ============================================
// VISUAL EFFECTS
// ============================================

// Visual effect for extraction
/obj/effect/temp_visual/harvest_extract
	name = "biological extraction"
	icon = 'icons/effects/effects.dmi'
	icon_state = "soulglow"
	layer = ABOVE_MOB_LAYER
	duration = 20

/obj/effect/temp_visual/harvest_extract/Initialize()
	. = ..()
	color = "#FF00FF"
	animate(src, alpha = 0, transform = matrix() * 2, time = duration)
