/// Hope Aura - Grants Hope status effect to nearby humans
/datum/action/cooldown/hope_aura
	name = "Hope Aura"
	desc = "Inspire those around you with hope, granting them immunity to awe and increased damage for 60 seconds."
	button_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "golden_bud"
	background_icon_state = "bg_abnormality"
	cooldown_time = 30 SECONDS
	/// Range of the aura effect
	var/aura_range = 7

/datum/action/cooldown/hope_aura/Trigger()
	. = ..()
	if(!.)
		return FALSE

	if(!owner || !isliving(owner))
		return FALSE

	var/mob/living/user = owner

	// Visual and sound effects
	new /obj/effect/temp_visual/heal(get_turf(user), "#FFD700")
	playsound(user, 'sound/magic/staff_healing.ogg', 75, TRUE)

	// Apply Hope to nearby humans
	var/affected_count = 0
	for(var/mob/living/carbon/human/H in view(aura_range, user))
		if(H == user)
			continue
		if(H.stat == DEAD)
			continue

		// Apply Hope status effect
		H.apply_status_effect(/datum/status_effect/hope)
		new /obj/effect/temp_visual/heal(get_turf(H), "#FFD700")
		affected_count++

	to_chat(user, span_nicegreen("You inspire [affected_count] people with hope!"))
	user.visible_message(span_warning("[user] radiates an aura of hope!"))

	StartCooldown()
	return TRUE

/// Piercing Strike - Aimed spell that drops a spear from above
/obj/effect/proc_holder/spell/pointed/piercing_strike
	name = "Piercing Strike"
	desc = "Call down a divine spear at a target location. If it hits Achiyalabopa, it will temporarily weaken its defenses."
	action_icon = 'icons/mob/actions/actions_abnormality.dmi'
	action_icon_state = "spear_split"
	action_background_icon_state = "bg_abnormality"
	clothes_req = FALSE
	charge_max = 450 // 45 seconds
	range = 12
	active_msg = "You raise your hand to the heavens!"
	deactive_msg = "You lower your hand..."
	self_castable = FALSE
	var/spear_damage = 150

/obj/effect/proc_holder/spell/pointed/piercing_strike/cast(list/targets, mob/living/user)
	var/turf/target_turf = get_turf(targets[1])
	if(!target_turf)
		return

	ExecuteStrike(user, target_turf)
	return TRUE

/obj/effect/proc_holder/spell/pointed/piercing_strike/proc/ExecuteStrike(mob/living/user, turf/target_turf)
	set waitfor = FALSE

	// Visual effect - show targeting reticle
	for(var/turf/T in range(1, target_turf))
		new /obj/effect/temp_visual/cult/sparks(T)

	playsound(target_turf, 'sound/magic/staff_healing.ogg', 50, TRUE)
	user.visible_message(span_userdanger("[user] calls down a divine spear from the heavens!"))

	// Create the spear above
	var/obj/effect/piercing_spear/spear = new(target_turf)
	spear.pixel_y = 96 // Higher start position for taller sprite
	spear.alpha = 100

	// Animate it appearing with a subtle spin
	animate(spear, alpha = 255, time = 10)

	sleep(10)

	// Drop the spear with acceleration effect
	animate(spear, pixel_y = 0, time = 5, easing = EASE_IN)
	playsound(target_turf, 'sound/weapons/pierce.ogg', 100, TRUE)

	sleep(3)

	// Impact effects
	new /obj/effect/temp_visual/explosion(target_turf)
	playsound(target_turf, 'sound/magic/clockwork/ratvar_attack.ogg', 100, TRUE)

	// Deal damage to all mobs in the turf
	var/hit_achiyalabopa = FALSE
	var/mob/living/simple_animal/hostile/distortion/achiyalabopa/achy_target
	for(var/mob/living/L in target_turf)
		L.deal_damage(spear_damage, PALE_DAMAGE)
		to_chat(L, span_userdanger("You are struck by the divine spear!"))

		// Check if Achiyalabopa was hit
		if(istype(L, /mob/living/simple_animal/hostile/distortion/achiyalabopa))
			hit_achiyalabopa = TRUE
			achy_target = L

	// If Achiyalabopa was hit, impale it and make vulnerable
	if(hit_achiyalabopa && achy_target)
		achy_target.visible_message(span_userdanger("[achy_target] is impaled by the divine spear! Its defenses crumble!"))
		achy_target.MakeVulnerable(30 SECONDS, spear)
	else
		// Remove spear after a moment
		QDEL_IN(spear, 2 SECONDS)

/// Visual spear object
/obj/effect/piercing_spear
	name = "divine spear"
	desc = "A radiant spear of pure light, manifestation of humanity's will to survive."
	icon = 'ModularLobotomy/_Lobotomyicons/32x96.dmi'
	icon_state = "myform_staff" // Reusing the staff sprite for now, can be changed to a unique spear sprite
	layer = FLY_LAYER
	light_range = 4
	light_power = 3
	light_color = LIGHT_COLOR_ORANGE
	anchored = TRUE
	color = "#FFD700" // Golden color to match Achiyalabopa's theme

/obj/effect/piercing_spear/Initialize()
	. = ..()
	animate(src, transform = turn(matrix(), 15), time = 2)
