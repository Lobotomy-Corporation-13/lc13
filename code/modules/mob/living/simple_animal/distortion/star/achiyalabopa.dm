/// Achiyalabopa - STAR level distortion boss
/mob/living/simple_animal/hostile/distortion/achiyalabopa
	name = "Achiyalabopa"
	desc = "A magnificent golden being of immense power. Its very presence fills you with overwhelming awe."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "achiyalabopa"
	icon_living = "achiyalabopa"
	icon_dead = "achiyalabopa_dead"
	maxHealth = 25000
	health = 25000
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2)
	melee_damage_lower = 20
	melee_damage_upper = 40
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "smites"
	attack_verb_simple = "smite"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/weapons/guns/manager_wind.ogg'
	death_sound = 'sound/spookoween/ghosty_wind.ogg'
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	vision_range = 15
	aggro_vision_range = 20
	move_to_delay = 4
	fear_level = ALEPH_LEVEL
	can_spawn = 0
	del_on_death = TRUE
	pixel_x = -16
	base_pixel_x = -16
	/// Reference to the storm
	var/datum/weather/achiyalabopa_storm/storm
	/// Reference to the Coreflame
	var/obj/item/coreflame/coreflame
	/// Is Achiyalabopa currently vulnerable?
	var/is_vulnerable = FALSE

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Initialize()
	. = ..()

	// Set golden light
	set_light(8, 6, LIGHT_COLOR_ORANGE)

	// Start the storm
	storm = SSweather.run_weather(/datum/weather/achiyalabopa_storm)

	// Spawn the Coreflame at a nearby location
	var/turf/spawn_turf = get_turf(src)
	if(spawn_turf)
		// Spawn it a bit away from Achiyalabopa
		var/turf/coreflame_turf = locate(spawn_turf.x + 10, spawn_turf.y, spawn_turf.z)
		if(!coreflame_turf)
			coreflame_turf = spawn_turf

		coreflame = new /obj/item/coreflame(coreflame_turf)

	visible_message(span_userdanger("Achiyalabopa descends upon the city! Darkness engulfs everything!"))
	playsound(src, 'sound/magic/clockwork/narsie_attack.ogg', 100, TRUE, 50)

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Life()
	. = ..()
	if(!.)
		return FALSE

	// Apply Awe Struck to all visible humans
	ApplyAweStruck()

/mob/living/simple_animal/hostile/distortion/achiyalabopa/death(gibbed)
	// End the storm (which will also clean up reapers)
	if(storm && !QDELETED(storm))
		SSweather.end_weather(storm)

	visible_message(span_userdanger("Achiyalabopa lets out a final roar as it falls! The storm begins to dissipate!"))
	playsound(src, 'sound/effects/explosion3.ogg', 100, TRUE, 50)

	return ..()

/// Applies Awe Struck status to all humans who can see Achiyalabopa
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/ApplyAweStruck()
	for(var/mob/living/carbon/human/H in view(vision_range, src))
		if(H.stat == DEAD)
			continue

		// Skip if they have immunity (Hope or Will of Humanity)
		if(HAS_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE))
			continue

		// Apply or refresh Awe Struck
		var/datum/status_effect/awe_struck/awe = H.has_status_effect(/datum/status_effect/awe_struck)
		if(!awe)
			awe = H.apply_status_effect(/datum/status_effect/awe_struck)
			if(awe)
				awe.source_mob = src

/// Makes Achiyalabopa vulnerable for a duration
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/MakeVulnerable(duration, obj/effect/piercing_spear/spear)
	if(is_vulnerable)
		return

	is_vulnerable = TRUE

	// Change resistances to make vulnerable
	ChangeResistances(list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0))

	// Visual indication
	animate(src, color = "#FF8888", time = 5)
	visible_message(span_userdanger("[src]'s defenses weaken! Now is the time to strike!"))

	// If spear is provided, attach it to Achiyalabopa
	if(spear && !QDELETED(spear))
		// Move spear to Achiyalabopa's location and attach visually
		spear.forceMove(loc)
		spear.pixel_x = pixel_x
		spear.pixel_y = 48 // Position higher for tall sprite
		spear.layer = ABOVE_MOB_LAYER
		// Rotate to look like it's impaled at an angle
		spear.transform = matrix().Turn(165) // Slight angle, not completely upside down
		spear.name = "impaled divine spear"
		spear.desc = "The divine spear has pierced through Achiyalabopa's golden armor, exposing its weakness."
		// Make it pulse/glow while impaled
		animate(spear, alpha = 200, time = 10, loop = -1)
		animate(alpha = 255, time = 10)

		// Store reference to remove later
		var/obj/effect/piercing_spear/impaled_spear = spear

		// Set timer to remove spear when vulnerability ends
		addtimer(CALLBACK(src, PROC_REF(RemoveImpaledSpear), impaled_spear), duration)

	// Set timer to restore vulnerability
	addtimer(CALLBACK(src, PROC_REF(RestoreDefenses)), duration)

/// Removes the impaled spear
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/RemoveImpaledSpear(obj/effect/piercing_spear/spear)
	if(spear && !QDELETED(spear))
		animate(spear, alpha = 0, time = 10)
		QDEL_IN(spear, 10)

/// Restores Achiyalabopa's normal defenses
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/RestoreDefenses()
	if(!is_vulnerable)
		return

	is_vulnerable = FALSE

	// Restore original resistances
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))

	// Visual indication
	animate(src, color = initial(color), time = 10)
	visible_message(span_warning("[src]'s defenses return to normal!"))

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Destroy()
	storm = null
	coreflame = null
	return ..()

/// Awe Struck - Prevents approaching Achiyalabopa and applies fragility
/datum/status_effect/awe_struck
	id = "awe_struck"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/awe_struck
	/// Reference to Achiyalabopa
	var/mob/living/simple_animal/hostile/distortion/achiyalabopa/source_mob
	/// Visual overlay effect
	var/mutable_appearance/awe_overlay

/atom/movable/screen/alert/status_effect/awe_struck
	name = "Awe Struck"
	desc = "You are filled with overwhelming awe and cannot approach this magnificent being."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "awe_struck"

/datum/status_effect/awe_struck/on_apply()
	. = ..()
	if(!.)
		return

	// Apply 6 fragility
	owner.apply_lc_fragile(6)

	// Add visual overlay
	awe_overlay = mutable_appearance('icons/effects/effects.dmi', "golden_glow", ABOVE_MOB_LAYER)
	owner.add_overlay(awe_overlay)

	// Register signal for movement restriction
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(PreventApproach))

	to_chat(owner, span_userdanger("You are overwhelmed by awe! You cannot bring yourself to approach!"))
	return TRUE

/datum/status_effect/awe_struck/on_remove()
	// Remove visual overlay
	if(awe_overlay)
		owner.cut_overlay(awe_overlay)
		QDEL_NULL(awe_overlay)

	// Unregister signal
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)

	to_chat(owner, span_notice("The overwhelming awe fades..."))
	return ..()

/datum/status_effect/awe_struck/proc/PreventApproach(datum/source, atom/new_loc)
	SIGNAL_HANDLER

	if(!source_mob || QDELETED(source_mob))
		qdel(src)
		return

	// Check if owner still has line of sight to Achiyalabopa
	if(!(owner in view(source_mob.vision_range, source_mob)))
		qdel(src)
		return

	// Calculate distances
	var/current_distance = get_dist(owner, source_mob)
	var/new_distance = get_dist(new_loc, source_mob)

	// Prevent moving closer
	if(new_distance < current_distance)
		to_chat(owner, span_warning("You cannot bring yourself to approach!"))
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Hope - Grants immunity to Awe Struck and damage buff
/datum/status_effect/hope
	id = "hope"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/hope
	/// Visual overlay effect
	var/mutable_appearance/hope_overlay

/atom/movable/screen/alert/status_effect/hope
	name = "Hope"
	desc = "You are filled with hope! You are immune to awe and deal increased damage."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "hope"

/datum/status_effect/hope/on_apply()
	. = ..()
	if(!.)
		return

	// Grant trait for Awe Struck immunity
	ADD_TRAIT(owner, TRAIT_COMBATFEAR_IMMUNE, "hope")

	// Apply damage buff
	owner.apply_lc_strength(4)

	// Add visual overlay
	hope_overlay = mutable_appearance('icons/effects/effects.dmi', "shield2", ABOVE_MOB_LAYER)
	owner.add_overlay(hope_overlay)

	to_chat(owner, span_nicegreen("You are filled with hope! Nothing can stop you now!"))
	return TRUE

/datum/status_effect/hope/on_remove()
	// Remove trait
	REMOVE_TRAIT(owner, TRAIT_COMBATFEAR_IMMUNE, "hope")

	// Remove visual overlay
	if(hope_overlay)
		owner.cut_overlay(hope_overlay)
		QDEL_NULL(hope_overlay)

	to_chat(owner, span_notice("The feeling of hope fades..."))
	return ..()

/// Will of Humanity - Special status for Coreflame holder
/datum/status_effect/will_of_humanity
	id = "will_of_humanity"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/will_of_humanity
	/// Reference to the Coreflame item
	var/obj/item/coreflame/coreflame_item
	/// Visual overlay effect
	var/mutable_appearance/will_overlay
	/// Action: Hope Aura
	var/datum/action/cooldown/hope_aura/hope_action
	/// Spell: Piercing Strike
	var/obj/effect/proc_holder/spell/pointed/piercing_strike/strike_spell

/atom/movable/screen/alert/status_effect/will_of_humanity
	name = "Will of Humanity"
	desc = "You carry the Will of Humanity! You can spread hope and strike down those who threaten humanity."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "will_of_humanity"

/datum/status_effect/will_of_humanity/on_creation(mob/living/new_owner, obj/item/coreflame/coreflame)
	. = ..()
	if(.)
		coreflame_item = coreflame

/datum/status_effect/will_of_humanity/on_apply()
	. = ..()
	if(!.)
		return

	// Add visual overlay
	will_overlay = mutable_appearance('icons/effects/effects.dmi', "blessed", ABOVE_MOB_LAYER)
	owner.add_overlay(will_overlay)

	// Grant ability actions
	hope_action = new(owner)
	hope_action.Grant(owner)

	// Grant spell
	strike_spell = new(owner)
	owner.AddSpell(strike_spell)

	to_chat(owner, span_userdanger("You are now the Will of Humanity! Use your abilities to save everyone!"))
	return TRUE

/datum/status_effect/will_of_humanity/on_remove()

	// Remove visual overlay
	if(will_overlay)
		owner.cut_overlay(will_overlay)
		QDEL_NULL(will_overlay)

	// Remove actions
	if(hope_action)
		hope_action.Remove(owner)
		QDEL_NULL(hope_action)

	// Remove spell
	if(strike_spell)
		owner.RemoveSpell(strike_spell)

	// Drop the Coreflame if still held
	if(coreflame_item && !QDELETED(coreflame_item))
		owner.dropItemToGround(coreflame_item)

	to_chat(owner, span_warning("The Will of Humanity has left you..."))
	return ..()

/datum/status_effect/will_of_humanity/tick()
	// Check if still holding the Coreflame
	if(!coreflame_item || QDELETED(coreflame_item))
		qdel(src)
		return

	// Check if Coreflame is still in inventory
	var/holding_coreflame = FALSE
	for(var/obj/item/I in owner.get_contents())
		if(I == coreflame_item)
			holding_coreflame = TRUE
			break

	if(!holding_coreflame)
		qdel(src)
		return
