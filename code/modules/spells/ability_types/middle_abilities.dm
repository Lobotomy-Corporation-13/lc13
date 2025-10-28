// Middle-specific abilities

// Movespeed modifiers for Great Leap
/datum/movespeed_modifier/great_leap_flying
	id = "great_leap_flying"
	multiplicative_slowdown = -1.5 // Speed boost while flying

/datum/movespeed_modifier/great_leap_landing
	id = "great_leap_landing"
	multiplicative_slowdown = 2 // Slowdown while landing

/obj/effect/proc_holder/ability/great_leap
	name = "Great Leap"
	desc = "Leap high into the air and crash down with devastating force, dealing massive black damage to all enemies in sight."
	action_icon = 'icons/mob/actions/actions_changeling.dmi'
	action_icon_state = "adrenaline"
	base_icon_state = "adrenaline"
	cooldown_time = 60 SECONDS
	var/leap_duration = 10 SECONDS
	var/is_leaping = FALSE
	var/is_landing = FALSE
	var/mob/living/carbon/human/leaper
	var/obj/effect/temp_visual/great_leap_warning/warning_effect

/obj/effect/proc_holder/ability/great_leap/Perform(target, mob/user)
	if(!ishuman(user))
		return
	if(is_leaping || is_landing)
		// If already leaping, trigger landing early
		if(is_leaping && !is_landing)
			StartLanding()
		return

	leaper = user
	is_leaping = TRUE

	// Phase 1: Launch animation
	user.visible_message(span_danger("[user] crouches down and prepares for a mighty leap!"))
	playsound(user, 'sound/weapons/fixer/generic/middle_leap.ogg', 50, TRUE)

	// Animate jumping up
	animate(user, pixel_z = 128, alpha = 0, time = 5)
	sleep(5)

	// Phase 2: Flying state
	user.density = FALSE
	user.status_flags |= GODMODE // Make invulnerable during leap
	user.invisibility = 0 // Make invisible but still controllable

	// Add flying trait and speed boost
	ADD_TRAIT(user, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
	user.add_movespeed_modifier(/datum/movespeed_modifier/great_leap_flying)

	// Schedule automatic landing after duration
	addtimer(CALLBACK(src, PROC_REF(StartLanding)), leap_duration)

	return ..()

/obj/effect/proc_holder/ability/great_leap/proc/StartLanding()
	if(!leaper || is_landing)
		return

	is_landing = TRUE
	is_leaping = FALSE

	// Phase 3: Warning and preparation
	// Keep the player elevated and invisible while showing the ground warning
	leaper.pixel_z = 128 // Ensure player stays in the air
	leaper.alpha = 0 // Keep player invisible

	// Create warning effect that follows the player
	warning_effect = new /obj/effect/temp_visual/great_leap_warning(get_turf(leaper))
	warning_effect.follow_target = leaper
	warning_effect.start_following()

	// Switch from speed boost to slowdown
	leaper.remove_movespeed_modifier(/datum/movespeed_modifier/great_leap_flying)
	leaper.add_movespeed_modifier(/datum/movespeed_modifier/great_leap_landing)

	leaper.visible_message(span_boldwarning("A shadow appears on the ground!"))

	// Wait for warning duration (player can still move)
	sleep(1 SECONDS)
	var/turf/impact_turf = get_turf(leaper)
	playsound(impact_turf, 'sound/weapons/fixer/generic/middle_land.ogg', 100, TRUE, 10)
	sleep(2 SECONDS)

	// Phase 4: Impact
	PerformImpact()

/obj/effect/proc_holder/ability/great_leap/proc/PerformImpact()
	if(!leaper)
		return

	var/turf/impact_turf = get_turf(leaper)

	// Remove warning effect
	if(warning_effect)
		QDEL_NULL(warning_effect)

	// Remove flying trait and all speed modifiers
	REMOVE_TRAIT(leaper, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
	leaper.remove_movespeed_modifier(/datum/movespeed_modifier/great_leap_flying)
	leaper.remove_movespeed_modifier(/datum/movespeed_modifier/great_leap_landing)

	// Reset user state
	leaper.status_flags &= ~GODMODE // Remove invulnerability
	leaper.density = TRUE
	leaper.invisibility = initial(leaper.invisibility)

	// Fast falling animation
	leaper.pixel_z = 128
	leaper.alpha = 255
	animate(leaper, pixel_z = 0, time = 2)
	sleep(2)

	// Impact effects
	leaper.visible_message(span_userdanger("[leaper] CRASHES DOWN WITH TREMENDOUS FORCE!"))

	// Shockwave visual
	var/obj/effect/temp_visual/decoy/D = new(impact_turf, leaper)
	animate(D, alpha = 0, transform = matrix()*3, time = 10)

	// Screen shake for nearby mobs
	for(var/mob/living/M in view(10, impact_turf))
		if(M.client)
			shake_camera(M, 4, 3)

	// Deal damage to all visible enemies
	for(var/mob/living/L in view(5, leaper))
		if(L == leaper)
			continue

		// Check if target has a middle book equipped (immunity)
		var/has_middle_book = FALSE
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			var/obj/item/I = H.get_item_by_slot(ITEM_SLOT_BELT)
			if(istype(I, /obj/item/storage/book/middle))
				has_middle_book = TRUE

		if(has_middle_book)
			to_chat(L, span_notice("The Book of Vengeance protects you from [leaper]'s wrath!"))
			continue

		// Calculate damage
		var/base_damage = 100
		var/final_damage = base_damage
		var/datum/status_effect/stacking/vengeance_mark/VM = null

		// Hostile simple animals take 5x damage
		if(istype(L, /mob/living/simple_animal/hostile))
			final_damage = base_damage * 5
			L.visible_message(span_danger("[L] is struck with devastating force!"))
		else
			// Check for vengeance marks and apply bonus damage (only for non-hostile animals)
			VM = L.has_status_effect(/datum/status_effect/stacking/vengeance_mark)
			if(VM)
				var/bonus_mult = 1 + (VM.stacks * 0.1) // 10% per stack
				final_damage = base_damage * bonus_mult
				L.visible_message(span_danger("The vengeance marks on [L] amplify the damage!"))

		// Apply damage
		L.apply_damage(final_damage, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), get_dir(impact_turf, L))

		// Clear vengeance marks after damage
		if(VM)
			qdel(VM)

	// Reset ability state
	is_landing = FALSE
	is_leaping = FALSE
	leaper = null

// Warning effect that follows the player during landing
/obj/effect/temp_visual/great_leap_warning
	name = "ominous shadow"
	desc = "GET OUT OF THE WAY!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#8B00FF" // Purple color
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	randomdir = FALSE
	duration = 3 SECONDS
	layer = POINT_LAYER
	var/mob/follow_target

/obj/effect/temp_visual/great_leap_warning/proc/start_following()
	if(follow_target)
		RegisterSignal(follow_target, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(target_moved))

/obj/effect/temp_visual/great_leap_warning/proc/target_moved(mob/user, atom/new_location)
	SIGNAL_HANDLER
	var/turf/new_turf = get_turf(new_location)
	if(new_turf)
		forceMove(new_turf)

/obj/effect/temp_visual/great_leap_warning/Destroy()
	if(follow_target)
		UnregisterSignal(follow_target, COMSIG_MOVABLE_PRE_MOVE)
		follow_target = null
	return ..()
