/// Mirage Reaper - Hostile mob spawned during Achiyalabopa's storm
/mob/living/simple_animal/hostile/mirage_reaper
	name = "Mirage Reaper"
	desc = "A feathery entity that materializes from the dark storm."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_reaper.dmi'
	icon_state = "reaper1"
	icon_living = "reaper1"
	icon_dead = "reaper1_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 7
	melee_damage_upper = 10
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	move_to_delay = 4
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/creatures/lc13/lovetown/slam.ogg'
	death_sound = 'sound/effects/ghost.ogg'
	emote_hear = list("echoes", "screeches")
	speak_chance = 5
	speed = 2
	del_on_death = TRUE
	can_patrol = TRUE
	patrol_cooldown_time = 30 SECONDS

/mob/living/simple_animal/hostile/mirage_reaper/patrol_select()
	if(!GLOB.mirage_reaper_spawns || !length(GLOB.mirage_reaper_spawns))
		return

	// Pick a random landmark to patrol to
	var/obj/effect/landmark/mirage_reaper_spawn/target = pick(GLOB.mirage_reaper_spawns)
	if(!target)
		return

	patrol_path = get_path_to(src, get_turf(target), /turf/proc/Distance_cardinal, 0, 200)

/mob/living/simple_animal/hostile/mirage_reaper/AttackingTarget(atom/attacked_target)
	// Check if target has Will of Humanity - if so, burn up
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(L.has_status_effect(/datum/status_effect/will_of_humanity))
			visible_message(span_warning("[src] bursts into flames upon touching [L]!"))
			playsound(get_turf(src), 'sound/magic/fireball.ogg', 50, TRUE)
			new /obj/effect/temp_visual/fire(get_turf(src))
			dust()
			return
	return ..()

/// Gwyliwr Nos - Night watcher with dash attack
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos
	name = "Gwyliwr Nos"
	desc = "A night watcher, enhanced by the dark storm."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_gwyliwr.dmi'
	icon_state = "gwyliwr_nos"
	icon_living = "gwyliwr_nos"
	icon_dead = "gwyliwr_nos_dead"
	maxHealth = 2400
	health = 2400
	pixel_x = -32
	base_pixel_x = -32
	melee_damage_lower = 25
	melee_damage_upper = 35
	damage_coeff = list(RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3)
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	move_to_delay = 3
	vision_range = 12
	aggro_vision_range = 18
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	death_sound = 'sound/effects/ghost2.ogg'
	del_on_death = FALSE
	fear_level = HE_LEVEL
	blood_volume = 0
	ranged = TRUE
	ranged_cooldown_time = 25 SECONDS
	/// Can act flag for dash
	var/can_act = TRUE
	/// Is currently in flying state
	var/is_flying = FALSE
	/// Damage taken while flying (for crash mechanic)
	var/flying_damage_taken = 0
	/// Original move delay
	var/original_move_delay
	/// Flight toggle action
	var/datum/action/cooldown/gwyliwr_flight/flight_action
	/// Shadow overlay effect
	var/mutable_appearance/shadow_overlay

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/Initialize()
	. = ..()
	original_move_delay = move_to_delay

	// Grant flight toggle action
	flight_action = new(src)
	flight_action.Grant(src)

	// Add shadow overlay
	shadow_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/bird_gwyliwr.dmi', "gwyliwr_nos_shadow", TURF_LAYER)
	shadow_overlay.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	add_overlay(shadow_overlay)

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/Destroy()
	// Remove flight action
	if(flight_action)
		flight_action.Remove(src)
		QDEL_NULL(flight_action)

	// Remove shadow overlay
	if(shadow_overlay)
		cut_overlay(shadow_overlay)
		QDEL_NULL(shadow_overlay)

	return ..()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/AttackingTarget(atom/attacked_target)
	// Cannot melee attack while flying
	if(is_flying)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/OpenFire(atom/A)
	if(!can_act)
		return
	if(ranged_cooldown <= world.time)
		NightDash(A)

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/attackby(obj/item/I, mob/living/user, params)
	// Immune to melee attacks with range < 2 while flying
	if(is_flying && I.reach < 2)
		visible_message(span_warning("[src] is too high to reach!"))
		new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
		return
	return ..()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/bullet_act(obj/projectile/P)
	// 50% chance to dodge projectiles while flying
	if(is_flying && prob(50))
		visible_message(span_warning("[P] passes harmlessly beneath [src]!"))
		new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	// Track damage while flying for crash mechanic
	if(is_flying && amount > 0)
		flying_damage_taken += amount
		if(flying_damage_taken >= 400)
			Crash()

/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/death(gibbed)
	if(is_flying)
		ExitFlight()
	..()

/// Toggles flying state
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/proc/ToggleFlight()
	if(is_flying)
		ExitFlight()
	else
		EnterFlight()

/// Enters flying state
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/proc/EnterFlight()
	if(is_flying)
		return

	is_flying = TRUE
	flying_damage_taken = 0

	// Visual changes
	icon_state = "gwyliwr_nos_fly"
	pixel_y = 28

	density = FALSE

	visible_message(span_warning("[src] takes to the air!"))
	playsound(get_turf(src), 'sound/effects/bamf.ogg', 50, TRUE)

/// Exits flying state
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/proc/ExitFlight()
	if(!is_flying)
		return

	is_flying = FALSE
	flying_damage_taken = 0

	// Restore visuals
	icon_state = "gwyliwr_nos"
	pixel_y = initial(pixel_y)

	density = TRUE

	visible_message(span_notice("[src] lands on the ground."))

/// Crashes from flying state due to damage
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/proc/Crash()
	if(!is_flying)
		return

	visible_message(span_userdanger("[src] crashes to the ground!"))
	playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 75, TRUE)

	ExitFlight()

	// Stun for a duration
	Stun(3 SECONDS)
	Knockdown(3 SECONDS)

/// Dash attack that deals 75 PALE damage and applies 5 PALE fragility (halved when flying)
/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/proc/NightDash(dash_target)
	// Halve cooldown when flying
	var/actual_cooldown = is_flying ? (ranged_cooldown_time / 2) : ranged_cooldown_time
	ranged_cooldown = world.time + actual_cooldown

	// Reduce damage by 50% when flying
	var/dash_damage = is_flying ? 37.5 : 75

	can_act = FALSE

	var/turf/target_turf = get_turf(dash_target)
	var/list/hit_mob = list()

	do_shaky_animation(2)
	if(do_after(src, 1 SECONDS, target = src))
		var/turf/wallcheck = get_turf(src)
		var/enemy_direction = get_dir(src, target_turf)

		for(var/i = 0 to 7)
			if(get_turf(src) != wallcheck || stat == DEAD)
				break

			wallcheck = get_step(src, enemy_direction)
			if(!wallcheck || wallcheck.density)
				break

			// Without this the attack happens instantly
			sleep(1)
			forceMove(wallcheck)
			playsound(wallcheck, 'sound/weapons/fwoosh.ogg', 20, 0, 4)

			for(var/turf/T in orange(get_turf(src), 1))
				if(isclosedturf(T))
					continue

				new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, enemy_direction)

				for(var/mob/living/L in T)
					if(L in hit_mob)
						continue
					if(faction_check_mob(L))
						continue

					hit_mob += L
					L.deal_damage(dash_damage, PALE_DAMAGE)

					// Apply 5 PALE fragility
					if(ishuman(L))
						var/mob/living/carbon/human/H = L
						H.apply_lc_pale_fragile(5)

					to_chat(L, span_userdanger("[src] strikes you with overwhelming force!"))

	can_act = TRUE

/// Action to toggle flying state
/datum/action/cooldown/gwyliwr_flight
	name = "Toggle Flight"
	desc = "Take to the air or land. While flying, you move faster and gain defensive bonuses, but your dash is weaker and you cannot melee attack."
	button_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "adjust_vision"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 5 SECONDS

/datum/action/cooldown/gwyliwr_flight/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/distortion/gwyliwr_nos))
		return FALSE
	var/mob/living/simple_animal/hostile/distortion/gwyliwr_nos/watcher = owner
	watcher.ToggleFlight()
	StartCooldown()
	return TRUE

/**
 * # Reaper Rift
 *
 * A rift that spawns mirage reapers passively.
 *
 * Spawns 2 mirage reapers every 4 seconds, up to a maximum of 10 reapers total.
 */
/obj/structure/reaper_rift
	name = "reaper rift"
	desc = "A rift from which mirage reapers emerge from the dark storm."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 100, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	max_integrity = 400
	icon = 'icons/obj/carp_rift.dmi'
	icon_state = "carp_rift"
	light_color = LIGHT_COLOR_PURPLE
	light_range = 10
	anchored = TRUE
	density = FALSE
	layer = MASSIVE_OBJ_LAYER
	/// The time since last reaper spawn.
	var/last_reaper_spawn = 0
	/// How often to spawn reapers (in deciseconds) - 4 seconds
	var/spawn_interval = 40
	/// Total number of reapers spawned by this rift
	var/reapers_spawned = 0
	/// Maximum number of reapers this rift can spawn
	var/max_reapers = 10

/obj/structure/reaper_rift/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/reaper_rift/examine(mob/user)
	. = ..()
	. += span_notice("It has spawned [reapers_spawned] out of [max_reapers] reapers.")

/obj/structure/reaper_rift/play_attack_sound(damage_amount, damage_type = BRUTE)
	playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)

/obj/structure/reaper_rift/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/reaper_rift/process(delta_time)
	// Stop spawning if we've reached the max
	if(reapers_spawned >= max_reapers)
		return

	// Increase time tracker
	last_reaper_spawn += delta_time

	// Spawn 2 reapers every 4 seconds
	if(last_reaper_spawn >= spawn_interval)
		new /mob/living/simple_animal/hostile/mirage_reaper(loc)
		new /mob/living/simple_animal/hostile/mirage_reaper(loc)
		reapers_spawned += 2
		last_reaper_spawn = 0
