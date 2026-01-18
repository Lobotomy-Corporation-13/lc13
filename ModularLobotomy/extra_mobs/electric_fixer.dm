// Electric Fixer - Amber Knight
// An aggressive combo-based attacker with Ramp Up system

#define ABILITY_NONE 0
#define ABILITY_DASH 1
#define ABILITY_JUMP 2
#define ABILITY_CIRCUIT 3

/mob/living/simple_animal/hostile/humanoid/fixer/electric
	name = "Amber Knight"
	desc = "Feminine guy, dressed in mainly black with neon accents, with bright amber eyes."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "electic"
	icon_living = "electic"
	faction = list("echo_office")
	gender = MALE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 3
	stat_attack = HARD_CRIT
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 14
	melee_damage_upper = 20
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	a_intent = INTENT_HARM
	mob_size = MOB_SIZE_HUGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	loot_weapon = list(
		/obj/item/ego_weapon/city/echo/twins/sodom,
		/obj/item/ego_weapon/city/echo/twins/gomorrah,
	)
	loot_armor = list(
		/obj/item/clothing/suit/armor/ego_gear/city/echo/maid_dress,
	)

	// Ramp Up System
	var/ramp_up = 0
	var/max_ramp_up = 10
	var/showtime_ramp_up = 15
	var/in_showtime = FALSE
	var/showtime_duration = 10 SECONDS
	var/showtime_damage_mult = 0.25  // 75% less damage
	var/post_showtime_stun = 8 SECONDS
	var/base_ability_delay = 3 SECONDS
	var/ramp_up_reduction = 0.1 SECONDS

	// Ability State
	var/current_ability = ABILITY_NONE
	var/last_ability_time = 0
	var/ability_cooldown = 1 SECONDS

	// Dash Variables
	var/dash_damage = 20
	var/dash_count = 2

	// Jump Variables
	var/jump_damage = 20
	var/jump_aoe = 1

	// Circuit Variables
	var/circuit_damage = 20
	var/circuit_max_range = 5

	// Stagger state
	var/is_staggered = FALSE

	// Voice line cooldown
	var/last_voice_line = 0
	var/voice_line_cooldown = 3 SECONDS

	// Stagger resistance changes (more vulnerable when staggered after Showtime)
	var/list/stagger_resistances = list(RED_DAMAGE = 2.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 3.0)
	var/list/normal_resistances = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/Initialize()
	. = ..()
	// Start ability loop
	addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 1 SECONDS)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/Destroy()
	return ..()

// Get current ability delay based on ramp up
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/GetAbilityDelay()
	var/effective_ramp = in_showtime ? showtime_ramp_up : ramp_up
	return max(0.5 SECONDS, base_ability_delay - (effective_ramp * ramp_up_reduction))

// Get current damage multiplier
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/GetDamageMult()
	return in_showtime ? showtime_damage_mult : 1

// Voice line with cooldown check
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/TrySay(message)
	if(world.time < last_voice_line + voice_line_cooldown)
		return
	last_voice_line = world.time
	say(message)

// Add ramp up and check for showtime
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/AddRampUp()
	if(in_showtime)
		return
	ramp_up++
	if(ramp_up >= max_ramp_up)
		EnterShowtime()

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/EnterShowtime()
	in_showtime = TRUE
	say("The light's never been brighter!")
	visible_message(span_danger("[src]'s movements become blindingly fast!"))
	playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 75, TRUE)
	// Add visual effect
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "blessed", ABOVE_MOB_LAYER))
	// Timer to end showtime
	addtimer(CALLBACK(src, PROC_REF(EndShowtime)), showtime_duration)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/EndShowtime()
	in_showtime = FALSE
	ramp_up = 0
	// Enter stagger state - this prevents abilities from re-enabling can_act
	is_staggered = TRUE
	can_act = FALSE
	// Remove showtime overlay, add stagger overlay
	cut_overlays()
	var/mutable_appearance/stagger_overlay = mutable_appearance(icon, "small_stagger", layer + 0.1)
	add_overlay(stagger_overlay)
	// Make more vulnerable during stagger
	ChangeResistances(stagger_resistances)
	visible_message(span_warning("[src] collapses from exhaustion!"))
	say("Nothing but grey now.")
	// Use SLEEP_CHECK_DEATH pattern
	SLEEP_CHECK_DEATH(post_showtime_stun)
	// Recovery
	ChangeResistances(normal_resistances)
	cut_overlay(stagger_overlay)
	is_staggered = FALSE
	can_act = TRUE
	say("...The colors are coming back.")
	visible_message(span_notice("[src] recovers and rises back up."))

// Main ability loop
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/AbilityLoop()
	if(stat == DEAD)
		return
	if(!can_act || !target || is_staggered)
		addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 1 SECONDS)
		return
	if(world.time < last_ability_time + ability_cooldown)
		addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 0.5 SECONDS)
		return
	// Roll for next ability
	RollNextAbility()
	addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), GetAbilityDelay())

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/RollNextAbility()
	var/roll = rand(1, 100)
	switch(current_ability)
		if(ABILITY_NONE)
			// First ability - equal chance
			if(roll <= 33)
				StartBlazingDash()
			else if(roll <= 66)
				StartFantasiaLights()
			else
				StartAmberCircuits()
		if(ABILITY_DASH)
			// 50% Dash, 25% Jump, 25% Circuit
			if(roll <= 50)
				StartBlazingDash()
			else if(roll <= 75)
				StartFantasiaLights()
			else
				StartAmberCircuits()
		if(ABILITY_JUMP)
			// 50% Jump, 25% Dash, 25% Circuit
			if(roll <= 50)
				StartFantasiaLights()
			else if(roll <= 75)
				StartBlazingDash()
			else
				StartAmberCircuits()
		if(ABILITY_CIRCUIT)
			// 50% Circuit, 25% Dash, 25% Jump
			if(roll <= 50)
				StartAmberCircuits()
			else if(roll <= 75)
				StartBlazingDash()
			else
				StartFantasiaLights()

// Ability 1: Blazing Dash
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartBlazingDash()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_DASH
	last_ability_time = world.time
	// Wind-up delay
	var/delay = GetAbilityDelay()
	// Add warning overlays for dash path
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	var/dash_direction = get_dir(my_turf, target_turf)
	var/turf/check_turf = my_turf
	for(var/i in 1 to 7)
		check_turf = get_step(check_turf, dash_direction)
		if(!check_turf || isclosedturf(check_turf))
			break
		check_turf.add_overlay(warning_icon)
		addtimer(CALLBACK(check_turf, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), delay)
	// Visual telegraph
	TrySay(pick("Keep moving forward!", "Chase the light!", "Don't look back!"))
	visible_message(span_warning("[src] crouches, electricity crackling around them!"))
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	// Execute after delay - pass saved target position
	addtimer(CALLBACK(src, PROC_REF(ExecuteBlazingDash), target_turf), delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteBlazingDash(turf/initial_target)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	// First dash to saved position (where warning was shown)
	if(initial_target)
		DashToTurf(initial_target)
	// Second dash to current target position
	if(stat != DEAD && target && !is_staggered)
		DashToTarget()
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/DashToTarget()
	if(!target || stat == DEAD)
		return
	// Recalculate direction each dash (allows tracking moving targets)
	var/turf/target_turf = get_turf(target)
	DashToTurf(target_turf)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/DashToTurf(turf/destination)
	if(!destination || stat == DEAD || is_staggered)
		return
	var/list/hit_mobs = list()
	// Small delay before dash starts, scales with ramp up (1s base, 0.2s at 10 ramp up, 0.1s showtime)
	var/dash_delay
	if(in_showtime)
		dash_delay = 0.1 SECONDS
	else
		dash_delay = max(0.2 SECONDS, 1 SECONDS - (ramp_up * 0.08 SECONDS))
	if(!do_after(src, dash_delay, target = src))
		return
	var/turf/current = get_turf(src)
	var/enemy_direction = get_dir(src, destination)
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	for(var/i in 1 to 7)
		if(get_turf(src) != current || stat == DEAD)
			break
		var/turf/next = get_step(src, enemy_direction)
		if(isclosedturf(next))
			break
		sleep(0.5)
		current = next
		forceMove(next)
		// Electric trail effect and damage in 3x3 area around dash path
		for(var/turf/T in range(1, next))
			if(isclosedturf(T))
				continue
			new /obj/effect/temp_visual/justitia_effect(T)
			for(var/mob/living/L in T)
				if(!faction_check_mob(L, FALSE) && !(L in hit_mobs))
					var/actual_damage = dash_damage * GetDamageMult()
					L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
					hit_mobs += L

// Ability 2: Fantasia Lights (Jump Attack)
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartFantasiaLights()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_JUMP
	last_ability_time = world.time
	// Mark target position
	var/turf/target_turf = get_turf(target)
	// Warning duration (1s base, 0.2s at 10 ramp up, 0.1s showtime)
	var/warning_delay
	if(in_showtime)
		warning_delay = 0.1 SECONDS
	else
		warning_delay = max(0.2 SECONDS, 1 SECONDS - (ramp_up * 0.08 SECONDS))
	// Add warning overlays to landing zone
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	for(var/turf/T in range(jump_aoe, target_turf))
		T.add_overlay(warning_icon)
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), warning_delay)
	// Visual telegraph - NO jump animation yet, just prepare
	TrySay(pick("Reach for the sky!", "If you can see the light...", "Higher and higher!"))
	visible_message(span_warning("[src] prepares to leap!"))
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	// Execute after warning delay
	addtimer(CALLBACK(src, PROC_REF(ExecuteFantasiaLights), target_turf), warning_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteFantasiaLights(turf/landing_turf)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	if(!landing_turf)
		landing_turf = get_turf(src)
	// Jump UP first
	visible_message(span_warning("[src] leaps into the air!"))
	animate(src, pixel_z = 32, time = 0.2 SECONDS)
	sleep(2)
	// Land at marked position
	forceMove(landing_turf)
	animate(src, pixel_z = 0, time = 0.1 SECONDS)
	playsound(src, 'sound/effects/sparks4.ogg', 75, TRUE)
	// AoE damage at landing
	for(var/turf/T in range(jump_aoe, landing_turf))
		new /obj/effect/temp_visual/justitia_effect(T)
		for(var/mob/living/L in T)
			if(!faction_check_mob(L, FALSE))
				var/actual_damage = jump_damage * GetDamageMult()
				L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

// Ability 3: Amber Circuits (Circle AoE)
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartAmberCircuits()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_CIRCUIT
	last_ability_time = world.time
	// Stop moving
	var/turf/my_turf = get_turf(src)
	// Warning duration (1s base, 0.2s at 10 ramp up, 0.1s showtime)
	var/warning_delay
	if(in_showtime)
		warning_delay = 0.1 SECONDS
	else
		warning_delay = max(0.2 SECONDS, 1 SECONDS - (ramp_up * 0.08 SECONDS))
	// Mark concentric circles with 1-tile gaps (distance 1, 3)
	var/list/marked_turfs = list()
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	for(var/turf/T in range(circuit_max_range, my_turf))
		var/dist = get_dist(my_turf, T)
		if(dist == 1 || dist == 3 || dist == 4 || dist == 5) // Rings at distance 1, 3, 4, and 5
			marked_turfs += T
			// Add warning overlay that lasts until attack executes
			T.add_overlay(warning_icon)
			addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), warning_delay)
	TrySay(pick("Let the light spread!", "Illuminate the path!", "Can you see it now?"))
	visible_message(span_warning("Amber circuits spread out from [src]!"))
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	// Execute after warning delay
	addtimer(CALLBACK(src, PROC_REF(ExecuteAmberCircuits), marked_turfs), warning_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteAmberCircuits(list/turfs)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	playsound(src, 'sound/effects/sparks4.ogg', 75, TRUE)
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/justitia_effect(T)
		for(var/mob/living/L in T)
			if(!faction_check_mob(L, FALSE))
				var/actual_damage = circuit_damage * GetDamageMult()
				L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

// Don't move during abilities or stagger
/mob/living/simple_animal/hostile/humanoid/fixer/electric/Move()
	if(!can_act || is_staggered)
		return FALSE
	return ..()

// Attack handling - instant kill insane/panicking targets
/mob/living/simple_animal/hostile/humanoid/fixer/electric/AttackingTarget(atom/attacked_target)
	if(!can_act || is_staggered)
		return FALSE
	// Check for sanity_lost before the attack (like Liu weapons)
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		if(H.sanity_lost)
			say(pick("...The light's gone from your eyes.", "You stopped seeing it, didn't you?", "Nothing but grey now."))
			visible_message(span_danger("[src] executes [H] mercilessly!"))
			playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 75, TRUE)
			H.death()
	. = ..()

// Visual effects
/obj/effect/temp_visual/electric_sparks
	name = "electric sparks"
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity2"
	duration = 5
	layer = ABOVE_MOB_LAYER

#undef ABILITY_NONE
#undef ABILITY_DASH
#undef ABILITY_JUMP
#undef ABILITY_CIRCUIT
