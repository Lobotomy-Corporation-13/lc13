#define CASSOWARY_HANDS_LAYER 1
#define CASSOWARY_TOTAL_LAYERS 1

/mob/living/simple_animal/hostile/corroded_cassowary
	name = "corroded cassowary"
	desc = "A large, flightless bird that has been corrupted by some unknown force. Its feathers are tainted with an unnatural sheen."
	icon = 'ModularLobotomy/_Lobotomyicons/tinkerer_corrosions.dmi'  // Placeholder icon for now
	icon_state = "cassowary"  // Placeholder icon state
	icon_living = "cassowary"
	icon_dead = "cassowary_dead"
	speak_chance = 30
	speak = list("SKREEEE!", "KRAWK!", "HISSSS!")
	emote_hear = list("screeches.", "hisses.", "clicks aggressively.")
	emote_taunt = list("flares its wings", "stamps its feet", "glares menacingly")
	speak_emote = list("screeches", "shrieks", "caws")
	maxHealth = 1200
	health = 1200
	loot = list(/obj/effect/gibspawner/robot)
	butcher_results = list(/obj/item/food/meat/slab/robot = 3)
	response_help_continuous = "pats"
	response_help_simple = "pat"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"
	move_to_delay = 2.5
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 30
	melee_damage_upper = 36
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/slash.ogg'

	// Ranged attack variables
	ranged = TRUE
	ranged_cooldown_time = 5 SECONDS
	retreat_distance = 3
	minimum_distance = 2
	ranged_message = "prepares to dash at"

	// Item holding capabilities
	dextrous = TRUE
	held_items = list(null, null)
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)

	var/list/cassowary_overlays[CASSOWARY_TOTAL_LAYERS]
	var/screeches = 0

	// Storage system
	var/list/stored_items = list()
	var/max_storage = 50

	// Repair system
	var/next_repair = 0
	var/repair_cooldown = 600 // 60 seconds

	//Sidesteping
	var/sidesteping = TRUE

	// Alert teleport system
	var/alert = FALSE

	// Dash charge system
	var/dash_charges = 5
	var/max_dash_charges = 5
	var/next_charge_regen = 0
	var/charge_regen_time = 30 SECONDS
	var/dash_range = 4
	var/dash_ignore_walls = FALSE
	var/dash_damage = 5
	var/dash_tremor = 2
	var/next_dash_devastating = FALSE
	var/dash_warning_time = 0
	var/dash_enabled = TRUE

	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/hostile/corroded_cassowary/player/Login()
	. = ..()
	to_chat(src, span_purple("You have been reborn as a servant of the Tinkerer!"))
	to_chat(src, span_notice("You can:"))
	to_chat(src, span_notice("- Passively regenerate health over time"))
	to_chat(src, span_notice("- Collect and expel items using magnetic systems"))
	to_chat(src, span_notice("- Commune with other converted beings"))

	// Add antagonist datum if they have a mind
	if(mind && !mind.has_antag_datum(/datum/antagonist/tinkerer_corrosion))
		mind.add_antag_datum(/datum/antagonist/tinkerer_corrosion)

/mob/living/simple_animal/hostile/corroded_cassowary/Initialize()
	. = ..()
	faction = list("neutral")

/mob/living/simple_animal/hostile/corroded_cassowary/player/Initialize()
	. = ..()
	// Grant abilities
	var/datum/action/innate/converted_ability/commune/commune = new()
	commune.Grant(src)

	var/datum/action/cooldown/converted_ability/magnetic_collection/collect = new()
	collect.Grant(src)

	var/datum/action/innate/converted_ability/expel_storage/expel = new()
	expel.Grant(src)

	var/datum/action/cooldown/converted_ability/devastating_dash/devastate = new()
	devastate.Grant(src)

	var/datum/action/innate/converted_ability/toggle_dash/toggle = new()
	toggle.Grant(src)

/mob/living/simple_animal/hostile/corroded_cassowary/is_literate()
	return TRUE

// Override adjustHealth to trigger teleport when alert
/mob/living/simple_animal/hostile/corroded_cassowary/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	// Check if taking damage while alert
	if(amount > 0 && alert && !stat)
		alert = FALSE // Use up the alert
		amount = 0
		visible_message(span_warning("[src] instinctively reacts to the attack, and dashes away!"))
		TeleportOnDamage()

	// Call parent to handle actual health adjustment
	return ..(amount, updating_health, forced)

// Teleport proc based on TryToTeleportMob from records.dm
/mob/living/simple_animal/hostile/corroded_cassowary/proc/TeleportOnDamage()
	var/turf/open/T = null
	var/list/turf_list = list()
	var/teleport_min_distance = 3
	var/teleport_max_distance = 5

	// Get potential teleport locations
	turf_list = spiral_range_turfs(teleport_max_distance, get_turf(src), teleport_min_distance)

	// Remove dense turfs
	for(var/turf/TT in turf_list)
		if(TT.density)
			turf_list -= TT

	// Try to find a valid teleport location
	for(var/i = 1 to 5)
		if(!LAZYLEN(turf_list))
			break
		T = pick(turf_list)
		turf_list -= T
		// Check if we can path to it
		if(LAZYLEN(get_path_to(src, T, TYPE_PROC_REF(/turf, Distance_cardinal), 0, teleport_max_distance * 2)))
			break
		T = null

	// Didn't find anything, abort
	if(!istype(T))
		return FALSE

	// Create visual trail effect
	var/list/line_list = getline(get_turf(src), T)
	for(var/i = 1 to length(line_list))
		var/turf/TT = line_list[i]
		var/obj/effect/temp_visual/decoy/D = new (TT, src)
		D.alpha = min(150 + i*15, 255)
		animate(D, alpha = 0, time = 2 + i*2)

	// Teleport and play sounds
	playsound(src, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)
	forceMove(T)
	playsound(T, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)

	visible_message(span_warning("[src] phases through space to avoid damage!"))
	return TRUE

/mob/living/simple_animal/hostile/corroded_cassowary/Moved()
	. = ..()
	if (sidesteping)
		MoveVFX()

/mob/living/simple_animal/hostile/corroded_cassowary/proc/MoveVFX()
	set waitfor = FALSE
	var/obj/viscon_filtereffect/distortedform_trail/trail = new(src.loc,themob = src, waittime = 5)
	trail.vis_contents += src
	trail.filters += filter(type="drop_shadow", x=0, y=0, size=3, offset=2, color=rgb(252, 68, 40))
	trail.filters += filter(type = "blur", size = 3)
	animate(trail, alpha=120)
	animate(alpha = 0, time = 10)

/mob/living/simple_animal/hostile/corroded_cassowary/Life()
	. = ..()
	if(!.)
		return

	// Self-repair over time
	if(health < maxHealth && world.time > next_repair)
		adjustBruteLoss(-100, 0)
		visible_message(span_notice("[src]'s mechanisms whir as damage is repaired."))
		next_repair = world.time + repair_cooldown
		alert = TRUE // Enable alert after healing

	// Regenerate dash charges
	if(dash_charges < max_dash_charges && world.time > next_charge_regen)
		dash_charges++
		next_charge_regen = world.time + charge_regen_time

/mob/living/simple_animal/hostile/corroded_cassowary/death(gibbed)
	// Drop all stored items
	if(length(stored_items))
		var/turf/T = get_turf(src)
		visible_message(span_notice("[src]'s storage compartment bursts open!"))
		for(var/obj/item/I in stored_items)
			I.forceMove(T)
		stored_items.Cut()
	return ..()

/mob/living/simple_animal/hostile/corroded_cassowary/examine(mob/user)
	. = ..()
	// Show storage status
	if(length(stored_items) > 0)
		. += span_notice("Storage compartment: [length(stored_items)]/[max_storage] items.")
	else
		. += span_notice("Storage compartment is empty.")
	// Show dash charges
	if(user == src)
		. += span_notice("Dash charges: [dash_charges]/[max_dash_charges]")

/mob/living/simple_animal/hostile/corroded_cassowary/AttackingTarget()
	if(client)
		screech()
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		L.apply_lc_tremor(4, 55)
		if(dash_charges < max_dash_charges)
			dash_charges++
		if(prob(20))  // 20% chance to throw
			var/atom/throw_target = get_edge_target_turf(L, dir)
			L.throw_at(throw_target, 2, 5, src)
			visible_message(span_danger("[src] sends [L] flying with its talons!"))

/mob/living/simple_animal/hostile/corroded_cassowary/CanSmashTurfs(turf/T)
	return FALSE  // Cassowaries can't smash walls

/mob/living/simple_animal/hostile/corroded_cassowary/can_use_guns(obj/item/G)
	to_chat(src, span_warning("Your talons cannot properly grip the trigger!"))
	return FALSE

/mob/living/simple_animal/hostile/corroded_cassowary/proc/screech()
	screeches++
	if(screeches >= rand(3,8))
		playsound(src, 'sound/misc/cassowary_speak.ogg', 50)
		screeches = 0

// Override OpenFire for dash attack
/mob/living/simple_animal/hostile/corroded_cassowary/OpenFire(atom/A)
	// Check if dashing is disabled
	if(!dash_enabled)
		return // Dashing is disabled

	// Check if we have charges
	if(dash_charges <= 0)
		return // No charges, can't dash

	// Check if this is a devastating dash
	if(next_dash_devastating)
		next_dash_devastating = FALSE
		PerformDevastatingDash(A)
		return

	// Consume a charge
	dash_charges--

	// Perform the dash
	var/turf/target_turf = get_turf(src)
	var/list/line_turfs = list(target_turf)
	var/list/mobs_to_hit = list()

	// Get line to target
	for(var/turf/T in getline(src, get_ranged_target_turf_direct(src, A, dash_range)))
		if(!dash_ignore_walls && T.density)
			break
		target_turf = T
		line_turfs += T

	// Move to final position
	forceMove(target_turf)

	// Visual and damage effects along the path
	for(var/i = 1 to line_turfs.len)
		var/turf/T = line_turfs[i]
		if(!istype(T))
			continue

		// Collect mobs to hit
		for(var/mob/living/L in view(1, T))
			if(L != src)
				mobs_to_hit |= L

		// Create visual trail
		var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(T, src)
		D.alpha = min(150 + i*15, 255)
		animate(D, alpha = 0, time = 2 + i*2)

		// Smoke effects
		for(var/turf/TT in range(T, 1))
			new /obj/effect/temp_visual/small_smoke/halfsecond(TT)

		// Sound effect
		playsound(src, 'sound/effects/hokma_meltdown_short.ogg', 25, 1)

		// Open doors in path
		for(var/obj/machinery/door/MD in T.contents)
			if(MD.density)
				INVOKE_ASYNC(MD, TYPE_PROC_REF(/obj/machinery/door, open))

	// Damage all collected mobs
	for(var/mob/living/L in mobs_to_hit)
		L.deal_damage(dash_damage, melee_damage_type)
		L.apply_lc_tremor(dash_tremor, 55)

		// Apply BLACK fragile with scaling based on existing stacks
		var/datum/status_effect/stacking/damtype_protection/black/fragile/existing_fragile = L.has_status_effect(/datum/status_effect/stacking/damtype_protection/black/fragile)
		var/fragile_to_apply = 1
		if(existing_fragile)
			// If they have fragile, apply 1 + their current stacks (e.g., 3 stacks = apply 1 + 3 = 4 total)
			fragile_to_apply = 1 + existing_fragile.stacks
		L.apply_lc_black_fragile(fragile_to_apply)

		L.visible_message(span_danger("[src] tears through [L] with a devastating dash!"))

	// Set ranged cooldown
	ranged_cooldown = world.time + ranged_cooldown_time

	visible_message(span_danger("[src] dashes through everything in its path!"))

// Proc for devastating dash with delay and warning
/mob/living/simple_animal/hostile/corroded_cassowary/proc/PerformDevastatingDash(atom/A)
	// Consume a charge
	dash_charges--

	// Warning phase
	visible_message(span_userdanger("[src] crouches low, dark energy gathering around its form!"))
	playsound(src, 'sound/magic/blind.ogg', 100, 1)
	var/turf/warning_target = get_turf(A)

	for(var/turf/T in getline(get_turf(src), warning_target))
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			TF.add_overlay(icon('icons/effects/effects.dmi', "purplesparkles"))
			addtimer(CALLBACK(TF, TYPE_PROC_REF(/atom, cut_overlay), \
								icon('icons/effects/effects.dmi', "purplesparkles")), 3 SECONDS)

	playsound(get_turf(src), 'sound/weapons/fixer/generic/energy3.ogg', 75, FALSE, 3)

	// 4 second delay
	if(!do_after(src, 3 SECONDS, target = A))
		to_chat(src, span_warning("Devastating dash interrupted!"))
		return

	// Perform the devastating dash
	var/turf/target_turf = get_turf(src)
	var/list/line_turfs = list(target_turf)
	var/list/mobs_to_hit = list()

	// Get line to target with increased range
	for(var/turf/T in getline(src, get_ranged_target_turf_direct(src, A, dash_range + 3)))
		if(!dash_ignore_walls && T.density)
			break
		target_turf = T
		line_turfs += T

	// Move to final position
	forceMove(target_turf)

	// Enhanced visual and damage effects along the path
	for(var/i = 1 to line_turfs.len)
		var/turf/T = line_turfs[i]
		if(!istype(T))
			continue

		// Collect mobs to hit
		for(var/mob/living/L in view(1, T))
			if(L != src)
				mobs_to_hit |= L

		// Create enhanced visual trail
		var/obj/effect/temp_visual/decoy/DD = new /obj/effect/temp_visual/decoy(T, src)
		DD.alpha = 255
		DD.color = "#000000"
		animate(DD, alpha = 0, time = 5 + i*3)

		// Black smoke effects
		for(var/turf/TT in range(1, T))
			var/obj/effect/temp_visual/small_smoke/halfsecond/S = new(TT)
			S.color = "#000000"

		// Devastating sound effect
		playsound(T, 'sound/misc/cassowary_speak.ogg', 75, 1)

	// Deal devastating damage to all collected mobs
	for(var/mob/living/L in mobs_to_hit)
		// Apply 100 BLACK damage
		L.deal_damage(100, BLACK_DAMAGE)

		// Check for tremor burst and dismemberment
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			// Check if they have enough tremor for burst
			var/datum/status_effect/stacking/lc_tremor/T = H.has_status_effect(/datum/status_effect/stacking/lc_tremor)
			if(T && T.stacks >= 20)
				// Trigger tremor burst manually
				H.visible_message(span_warning("[H]'s body convulses violently as tremor bursts through them!"))
				T.TremorBurst()

				// Dismember an arm
				var/obj/item/bodypart/arm = pick(H.get_bodypart(BODY_ZONE_L_ARM), H.get_bodypart(BODY_ZONE_R_ARM))
				if(arm)
					arm.dismember()
					H.visible_message(span_warning("[src]'s devastating dash tears [H]'s [arm.name] clean off!"))
			else
				// Apply extra tremor if not enough for burst
				H.apply_lc_tremor(20, 55)
		else
			// Non-humans just deal extra damage
			L.deal_damage(300, BLACK_DAMAGE)

		L.visible_message(span_warning("[src] tears through [L] with apocalyptic force!"))

	// Set extended ranged cooldown
	ranged_cooldown = world.time + ranged_cooldown_time * 2

	visible_message(span_warning("[src] unleashes a devastating dash, leaving destruction in its wake!"))

	// Screen shake for nearby players
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.client)
			shake_camera(H, 4, 2)

// Ability datums for cassowary
/datum/action/innate/converted_ability
	background_icon_state = "bg_ecult"

/datum/action/innate/converted_ability/commune
	name = "Commune with Machinery"
	desc = "Send a message through the mechanical network to other converted beings."
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "transmit"

/datum/action/innate/converted_ability/commune/Activate()
	var/message = stripped_input(owner, "What message do you wish to transmit?", "Mechanical Communion")
	if(!message)
		return

	for(var/mob/living/simple_animal/hostile/corroded_cassowary/C in GLOB.mob_living_list)
		to_chat(C, span_purple("<b>Mechanical Communion:</b> [owner.name] transmits, \"[message]\""))
	for(var/mob/living/simple_animal/hostile/corroded_human/H in GLOB.mob_living_list)
		to_chat(H, span_purple("<b>Mechanical Communion:</b> [owner.name] transmits, \"[message]\""))

	to_chat(owner, span_purple("You transmit your message through the mechanical network."))

/datum/action/cooldown/converted_ability
	background_icon_state = "bg_ecult"
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE

/datum/action/cooldown/converted_ability/emergency_repair
	name = "Emergency Repair"
	desc = "Channel for 8 seconds to restore a portion of your health. Interrupted if you take damage."
	button_icon_state = "rust_wave"
	cooldown_time = 120 SECONDS

/datum/action/cooldown/converted_ability/emergency_repair/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner

	// Start channeling message
	C.visible_message(span_notice("[C] begins channeling repair protocols, mechanisms whirring!"), \
		span_notice("Channeling emergency repair protocols..."))

	playsound(C, 'sound/items/welder2.ogg', 50, TRUE)

	// Visual effect during channeling
	new /obj/effect/temp_visual/heal(get_turf(C), "#FF0000")

	// 8 second channel - will interrupt if damaged, moved, stunned, etc
	if(!do_after(C, 8 SECONDS, target = C))
		to_chat(C, span_warning("Emergency repair interrupted!"))
		return FALSE

	// Channel successful - apply heal
	C.visible_message(span_notice("[C]'s damaged components rapidly repair themselves!"), \
		span_notice("Emergency repair complete!"))

	// Heal amount based on max health
	var/heal_amount = C.maxHealth * 0.4
	C.adjustBruteLoss(-heal_amount)

	// Final visual effect
	new /obj/effect/temp_visual/heal(get_turf(C), "#FF0000")
	playsound(C, 'sound/items/welder2.ogg', 50, TRUE)

	StartCooldown()
	return TRUE

/datum/action/cooldown/converted_ability/magnetic_collection
	name = "Magnetic Collection"
	desc = "Activate magnetic systems to pull all nearby items into your storage compartment. Maximum 50 items."
	icon_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "transmute"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/converted_ability/magnetic_collection/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner

	if(length(C.stored_items) >= C.max_storage)
		to_chat(C, span_warning("Storage compartment full! Cannot collect more items."))
		return FALSE

	C.visible_message(span_notice("[C]'s form hums with magnetic energy!"), \
		span_notice("Activating magnetic collection systems..."))

	playsound(C, 'sound/effects/EMPulse.ogg', 50, TRUE)

	// Visual effect - magnetic pull
	var/datum/effect_system/spark_spread/S = new
	S.set_up(10,0,C.loc)
	S.start()

	// Delay before collection
	if(do_after(C, 2 SECONDS, C))
		perform_collection_cassowary()
		StartCooldown()
	else
		to_chat(C, span_warning("Canceled magnetic collection systems..."))

	return TRUE

/datum/action/cooldown/converted_ability/magnetic_collection/proc/perform_collection_cassowary()
	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner
	var/collected = 0

	for(var/obj/item/I in view(1, C))
		if(length(C.stored_items) >= C.max_storage)
			break
		if(I.anchored)
			continue
		if(istype(I, /obj/item/organ)) // Don't collect organs
			continue

		I.forceMove(C)
		C.stored_items += I
		collected++

	if(collected)
		to_chat(C, span_notice("Collected [collected] item\s. Storage: [length(C.stored_items)]/[C.max_storage]"))
		playsound(C, 'sound/machines/ping.ogg', 50, TRUE)
	else
		to_chat(C, span_warning("No items found to collect."))

/datum/action/innate/converted_ability/expel_storage
	name = "Expel Storage"
	desc = "Open storage compartment and drop all collected items."
	icon_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "manip"

/datum/action/innate/converted_ability/expel_storage/Activate()
	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner

	if(!length(C.stored_items))
		to_chat(C, span_warning("Storage compartment is empty."))
		return

	var/turf/T = get_turf(C)
	var/expelled = 0

	C.visible_message(span_notice("[C]'s storage compartment opens with a hiss!"), \
		span_notice("Expelling all stored items..."))

	playsound(C, 'sound/mecha/mech_shield_drop.ogg', 50, TRUE)

	for(var/obj/item/I in C.stored_items)
		I.forceMove(T)
		expelled++

	C.stored_items.Cut()
	to_chat(C, span_notice("Expelled [expelled] item\s from storage."))

/datum/action/cooldown/converted_ability/devastating_dash
	name = "Devastating Dash"
	desc = "Charge up your next dash attack to deal massive BLACK damage. Has a 4 second wind-up with warning. Deals 100 BLACK damage and dismembers targets with 20+ tremor."
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "cleave"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/converted_ability/devastating_dash/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner

	if(C.dash_charges <= 0)
		to_chat(C, span_warning("You need at least one dash charge to use this ability!"))
		return FALSE

	if(C.next_dash_devastating)
		to_chat(C, span_warning("Your next dash is already empowered!"))
		return FALSE

	C.next_dash_devastating = TRUE
	C.visible_message(span_danger("[C] begins charging dark energy for a devastating attack!"), \
		span_userdanger("You charge your next dash with apocalyptic force!"))

	playsound(C, 'sound/magic/charge.ogg', 50, TRUE)

	// Visual effect to show charging
	var/obj/effect/temp_visual/decoy/charge = new /obj/effect/temp_visual/decoy(get_turf(C), C)
	charge.alpha = 100
	charge.color = "#000000"
	animate(charge, alpha = 255, time = 1 SECONDS)
	animate(alpha = 0, time = 1 SECONDS)

	StartCooldown()
	return TRUE

/datum/action/innate/converted_ability/toggle_dash
	name = "Toggle Dash Attacks"
	desc = "Enable or disable your dash attacks. When disabled, you will not dash at enemies."
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "mad_touch"
	var/enabled = TRUE

/datum/action/innate/converted_ability/toggle_dash/Activate()
	var/mob/living/simple_animal/hostile/corroded_cassowary/C = owner

	C.dash_enabled = !C.dash_enabled
	enabled = C.dash_enabled

	if(C.dash_enabled)
		to_chat(C, span_notice("Dash attacks ENABLED. You will now dash at enemies when attacking from range."))
		button_icon_state = "mad_touch"
	else
		to_chat(C, span_warning("Dash attacks DISABLED. You will no longer dash at enemies."))
		button_icon_state = "mansus_grasp"

#undef CASSOWARY_HANDS_LAYER
#undef CASSOWARY_TOTAL_LAYERS
