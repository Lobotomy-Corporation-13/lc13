/datum/species/resurgence_machine
	name = "Resurgence Machine"
	id = "resurgence_machine"
	say_mod = "states"
	species_traits = list(NOBLOOD)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_NOFIRE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOCLONELOSS,
		TRAIT_XENO_IMMUNE,
		TRAIT_BRUTESANITY,
	)
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	mutantheart = /obj/item/organ/resurgence_core
	mutanteyes = /obj/item/organ/eyes/robotic/shield
	mutantears = /obj/item/organ/ears/cybernetic
	mutantliver = /obj/item/organ/liver/cybernetic
	mutantstomach = /obj/item/organ/stomach/cybernetic
	mutantlungs = /obj/item/organ/lungs/cybernetic
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = "synth"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT

/datum/species/resurgence_machine/on_species_gain(mob/living/carbon/C)
	. = ..()
	for(var/X in C.bodyparts)
		var/obj/item/bodypart/O = X
		O.change_bodypart_status(BODYPART_ROBOTIC, FALSE, TRUE)
		O.brute_reduction = 5
		O.burn_reduction = 4

	// Machines don't eat, hunger or metabolise foods
	C.set_safe_hunger_level()

	// Apply personalization if client is connected
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(H.client?.prefs)
			// Client is connected, apply personalization now
			apply_resurgence_personalization(H)
		else
			// Client not connected yet, register for login signal
			RegisterSignal(C, COMSIG_MOB_LOGIN, PROC_REF(on_resurgence_login))

/// Called when a resurgence machine logs in without personalization applied
/datum/species/resurgence_machine/proc/on_resurgence_login(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOB_LOGIN)

	// Apply personalization now that client is connected
	apply_resurgence_personalization(source)

/datum/species/resurgence_machine/on_species_loss(mob/living/carbon/C)
	. = ..()
	UnregisterSignal(C, COMSIG_MOB_LOGIN)
	for(var/X in C.bodyparts)
		var/obj/item/bodypart/O = X
		O.change_bodypart_status(BODYPART_ORGANIC, FALSE, TRUE)
		O.brute_reduction = initial(O.brute_reduction)
		O.burn_reduction = initial(O.burn_reduction)

// Helper proc to get the core organ
/datum/species/resurgence_machine/proc/get_core(mob/living/carbon/human/H)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		return core
	return null

/// Update the faith HUD display for this machine
/mob/living/carbon/human/proc/update_faith_hud()
	if(!client || !hud_used?.faith_display)
		return
	if(!istype(dna?.species, /datum/species/resurgence_machine))
		return

	var/obj/item/organ/resurgence_core/core = getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		return

	// Map faith levels to mood icon states
	// mood1 = worst (Despairing), mood9 = best (Inspired)
	var/faith_percent = core.faith / core.max_faith
	var/icon_state_num
	if(faith_percent >= 0.9)
		icon_state_num = 9 // Inspired (best)
	else if(faith_percent >= 0.8)
		icon_state_num = 8
	else if(faith_percent >= 0.7)
		icon_state_num = 7
	else if(faith_percent >= 0.6)
		icon_state_num = 6 // Steady
	else if(faith_percent >= 0.5)
		icon_state_num = 5 // Neutral
	else if(faith_percent >= 0.4)
		icon_state_num = 4
	else if(faith_percent >= 0.3)
		icon_state_num = 3 // Wavering
	else if(faith_percent >= 0.2)
		icon_state_num = 2
	else
		icon_state_num = 1 // Despairing (worst)

	hud_used.faith_display.icon_state = "mood[icon_state_num]"

	// Color the icon based on faith change rate (sum of all active faith events)
	// Red = losing faith, Green = gaining faith, White = stable
	// Intensity scales from 0 at rate 0, to max at rate ±5
	// This requires multiple stacking events to achieve deep colors
	var/rate = core.faith_change_rate
	if(rate > 0)
		// Gaining faith - green tint, intensity scales with rate (0 to 5 maps to 0% to 100%)
		var/intensity = clamp(rate / 5, 0, 1) // 0 at rate 0, 1 at rate 5+
		// Interpolate from white (255,255,255) to pure green (0,255,0)
		var/red_val = round(255 * (1 - intensity))
		var/blue_val = round(255 * (1 - intensity))
		hud_used.faith_display.color = rgb(red_val, 255, blue_val)
	else if(rate < 0)
		// Losing faith - red tint, intensity scales with rate (0 to -5 maps to 0% to 100%)
		var/intensity = clamp(abs(rate) / 5, 0, 1) // 0 at rate 0, 1 at rate -5 or lower
		// Interpolate from white (255,255,255) to pure red (255,0,0)
		var/green_val = round(255 * (1 - intensity))
		var/blue_val = round(255 * (1 - intensity))
		hud_used.faith_display.color = rgb(255, green_val, blue_val)
	else
		// Stable - no tint (white/neutral)
		hud_used.faith_display.color = null
