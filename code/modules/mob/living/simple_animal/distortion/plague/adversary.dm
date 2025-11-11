//The Adversary - Plague Distortion
/mob/living/simple_animal/hostile/distortion/adversary
	name = "The Adversary"
	desc = "A figure wreathed in a sickly green aura, emanating plague and corruption."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "1x1x1x1"
	icon_living = "1x1x1x1"
	maxHealth = 2500
	health = 2500
	rapid_melee = 2
	move_to_delay = 4
	ranged = TRUE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	melee_damage_lower = 35
	melee_damage_upper = 45
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/distortions/the_adversary/slashhit.ogg'
	del_on_death = TRUE
	can_patrol = TRUE
	robust_searching = TRUE
	ranged_ignores_vision = TRUE

	fear_level = WAW_LEVEL

	// Action types
	attack_action_types = list(
		/datum/action/innate/distortion_attack/adversary_mass_infection,
		/datum/action/innate/distortion_attack/adversary_entanglement,
		/datum/action/innate/distortion_attack/adversary_unstable_eye,
		/datum/action/innate/distortion_attack/adversary_rejuvenate
	)

	// Ability cooldowns
	var/mass_infection_cooldown = 0
	var/mass_infection_cooldown_time = 17 SECONDS
	var/entanglement_cooldown = 0
	var/entanglement_cooldown_time = 18 SECONDS
	var/unstable_eye_cooldown = 0
	var/unstable_eye_cooldown_time = 25 SECONDS
	var/rejuvenate_cooldown = 0
	var/rejuvenate_cooldown_time = 200 SECONDS

	// Damage modifiers (affected by zombie kill stacks)
	var/mass_infection_damage_modifier = 1.0
	var/entanglement_damage_modifier = 1.0
	var/melee_damage_modifier = 1.0

	// Buff tracking
	var/damage_boost_stacks = 0
	var/speed_boost_active = FALSE

	// Casting control
	var/can_act = TRUE

	// Death tracking for remnants
	var/list/death_remnants = list()

	// Zoom tracking
	var/zoomed = FALSE
	var/original_sight = 0

	// Green aura lighting
	light_range = 3
	light_power = 2
	light_color = "#00FF00"

	// Looping sound for breathing
	var/datum/looping_sound/adversary_breathing/soundloop

/mob/living/simple_animal/hostile/distortion/adversary/Initialize()
	. = ..()

	// Register death tracking
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))

	// Initialize looping sound
	soundloop = new(list(src), FALSE)

	UpdateSpeed()

/mob/living/simple_animal/hostile/distortion/adversary/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	QDEL_NULL(soundloop)
	return ..()

/mob/living/simple_animal/hostile/distortion/adversary/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, "<h1>You are The Adversary, A Combat Distortion.</h1><br>\
		<b>|Plague Aura|: You emanate a sickly green aura of corruption.<br>\
		<br>\
		|Sweep Attack|: Your melee attacks sweep in a wide arc, hitting all enemies in front of you.<br>\
		<br>\
		|MASS INFECTION|: Fire an AoE shockwave after 1.7s windup.<br>\
		- Deals 200 BLACK damage initially, 100 BLACK after 8 tiles<br>\
		- Passes through walls<br>\
		- 17 second cooldown<br>\
		<br>\
		|ENTANGLEMENT|: Fire a stunning projectile after 0.75s windup.<br>\
		- Deals 30 BLACK damage and stuns for 3 seconds<br>\
		- Passes through walls<br>\
		- 18 second cooldown<br>\
		<br>\
		|UNSTABLE EYE|: Enhance your vision with corrupted sight.<br>\
		- 1.5 second slowdown, then zoomed vision for 5 seconds<br>\
		- Your vision blurs during the zoom<br>\
		- 25 second cooldown<br>\
		<br>\
		|REJUVENATE THE ROTTEN|: Raise all fallen enemies as zombies.<br>\
		- When humans die, they leave green remnants<br>\
		- Activate to raise all remnants as 700 HP zombies<br>\
		- Killing your own zombies grants speed boost (10s) and damage boost (30s, stacks 25%)<br>\
		- 200 second cooldown<br>\
		<br>\
		Grow stronger by consuming the dead!</b>")

// Override simple_animal's empty blur procs to enable blur effect
/mob/living/simple_animal/hostile/distortion/adversary/blur_eyes(amount)
	if(amount > 0)
		eye_blurry = max(amount, eye_blurry)
	update_eye_blur()

/mob/living/simple_animal/hostile/distortion/adversary/adjust_blurriness(amount)
	eye_blurry = max(eye_blurry + amount, 0)
	update_eye_blur()

/mob/living/simple_animal/hostile/distortion/adversary/set_blurriness(amount)
	eye_blurry = max(amount, 0)
	update_eye_blur()

// Sweep Melee Attack System
/mob/living/simple_animal/hostile/distortion/adversary/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE

	// Check attack cooldown (for player-controlled attacks)
	if(attack_is_on_cooldown)
		return FALSE

	// Check if attacking own zombie for instant kill + buffs
	if(istype(attacked_target, /mob/living/simple_animal/hostile/adversary_zombie))
		var/mob/living/simple_animal/hostile/adversary_zombie/zombie = attacked_target
		playsound(zombie, 'sound/distortions/the_adversary/slashhit.ogg', 50, TRUE)
		visible_message(span_danger("[src] consumes [zombie]!"))
		to_chat(src, span_nicegreen("You consume the corrupted flesh, growing stronger!"))

		// Kill zombie instantly
		zombie.death()

		// Apply speed boost
		if(!speed_boost_active)
			speed_boost_active = TRUE
			TemporarySpeedChange(-1.5, 10 SECONDS)
			addtimer(CALLBACK(src, PROC_REF(reset_speed_boost)), 10 SECONDS)

		// Apply damage boost stack
		damage_boost_stacks += 1
		recalculate_damage_modifiers()
		addtimer(CALLBACK(src, PROC_REF(remove_damage_stack)), 30 SECONDS)

		// Set cooldown for zombie consumption
		attack_is_on_cooldown = TRUE
		ResetAttackCooldown(attack_cooldown)

		return

	// Set attack on cooldown
	attack_is_on_cooldown = TRUE

	// Sweep attack - works on any target
	// Play swing sound
	playsound(src, 'sound/distortions/the_adversary/swing.ogg', 50, TRUE)

	// Show swipe effect
	new /obj/effect/temp_visual/swipe(get_step(src, SOUTHWEST), get_dir(src, attacked_target), "#055b05", "swipe_r_large")

	// Get sweep turfs (3 tiles in front)
	var/list/sweep_turfs = get_sweep_turfs(attacked_target)
	var/list/hit_mobs = list()

	// Collect all mobs in sweep area
	for(var/turf/T in sweep_turfs)
		for(var/mob/living/L in T)
			if(L == src)
				continue
			if(faction_check_mob(L))
				continue
			if(L in hit_mobs)
				continue
			hit_mobs += L

	// Attack all mobs in sweep
	var/hit_something = FALSE
	for(var/mob/living/L in hit_mobs)
		do_attack_animation(L, ATTACK_EFFECT_SLASH)
		playsound(L, 'sound/distortions/the_adversary/slashhit.ogg', 50, TRUE)
		var/damage = rand(melee_damage_lower, melee_damage_upper) * melee_damage_modifier
		L.deal_damage(damage, melee_damage_type, src, attack_type = (ATTACK_TYPE_MELEE))
		hit_something = TRUE

	// Reset attack cooldown
	ResetAttackCooldown(attack_cooldown)

	// If clicked on a non-living atom directly, still call parent for default behavior (like attacking structures)
	if(!hit_something && !isliving(attacked_target))
		do_attack_animation(attacked_target, ATTACK_EFFECT_SLASH)
		return ..()

	return hit_something

/mob/living/simple_animal/hostile/distortion/adversary/Move()
	if(!can_act)
		return FALSE
	return ..()
//he walk

/mob/living/simple_animal/hostile/distortion/adversary/proc/get_sweep_turfs(atom/target)
	. = list()
	var/turf/target_turf = get_step_towards(src, target)
	var/direction = get_dir(src, target)

	// Get the perpendicular directions for sweep
	var/left_dir
	var/right_dir

	switch(direction)
		if(NORTH, SOUTH)
			left_dir = WEST
			right_dir = EAST
		if(EAST, WEST)
			left_dir = NORTH
			right_dir = SOUTH
		if(NORTHEAST, SOUTHWEST)
			left_dir = NORTHWEST
			right_dir = SOUTHEAST
		if(NORTHWEST, SOUTHEAST)
			left_dir = NORTHEAST
			right_dir = SOUTHWEST

	. = list(get_step(target_turf, left_dir), target_turf, get_step(target_turf, right_dir))

// Death Tracking System
/mob/living/simple_animal/hostile/distortion/adversary/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER

	if(!ishuman(died))
		return FALSE
	if(died.z != z)
		return FALSE
	if(gibbed)
		return FALSE
	if(QDELETED(died))
		return FALSE

	// Store remnant data
	var/turf/death_turf = get_turf(died)
	var/human_name = "Unknown"
	if(died.real_name)
		human_name = died.real_name

	death_remnants += list(list("turf" = death_turf, "name" = human_name))

	// Spawn green remnant effect
	new /obj/effect/temp_visual/adversary_remnant(death_turf)

	return TRUE

// Buff System
/mob/living/simple_animal/hostile/distortion/adversary/proc/recalculate_damage_modifiers()
	var/multiplier = 1 + (damage_boost_stacks * 0.25)
	mass_infection_damage_modifier = multiplier
	entanglement_damage_modifier = multiplier
	melee_damage_modifier = multiplier

	to_chat(src, span_nicegreen("Damage boost: [damage_boost_stacks] stacks ([multiplier]x damage)"))

/mob/living/simple_animal/hostile/distortion/adversary/proc/remove_damage_stack()
	damage_boost_stacks = max(0, damage_boost_stacks - 1)
	recalculate_damage_modifiers()

/mob/living/simple_animal/hostile/distortion/adversary/proc/reset_speed_boost()
	speed_boost_active = FALSE

// Green remnant visual effect
/obj/effect/temp_visual/adversary_remnant
	name = "corrupted remnant"
	desc = "A sickly green wisp marking where someone died."
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	duration = 180 SECONDS
	light_range = 2
	light_power = 1
	light_color = "#00FF00"

// Adversary Zombie Mob
/mob/living/simple_animal/hostile/adversary_zombie
	name = "corrupted zombie"
	desc = "A shambling corpse, reanimated by plague energy."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "zombie"
	icon_living = "zombie"
	faction = list("hostile", "adversary")
	health = 700
	maxHealth = 700
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 20
	melee_damage_upper = 30
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/distortions/the_adversary/minionattack.ogg'
	speak_emote = list("groans")
	light_range = 2
	light_power = 1
	light_color = "#00FF00"
	var/original_name = "Unknown"

/mob/living/simple_animal/hostile/adversary_zombie/Initialize(mapload, human_name)
	. = ..()
	if(human_name)
		original_name = human_name
		name = "corrupted [human_name]"

// MASS INFECTION Projectile
/obj/projectile/magic/aoe/adversary_infection
	name = "plague shockwave"
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	pixel_y = -32
	icon_state = "shockwave"
	color = "#00FF00"
	alpha = 0
	damage = 200
	damage_type = BLACK_DAMAGE
	nodamage = FALSE
	speed = 0.8
	damage_falloff_tile = 0
	projectile_piercing = PASSMOB
	projectile_phasing = ALL // Passes through walls
	hitsound = 'sound/effects/attackblob.ogg'
	var/obj/effect/trail_type = /obj/effect/temp_visual/adversary_trail
	var/tiles_traveled = 0
	var/damage_modifier = 1.0

/obj/projectile/magic/aoe/adversary_infection/Initialize(mapload, damage_mod = 1.0)
	. = ..()
	damage_modifier = damage_mod
	damage = 200 * damage_modifier
	animate(src, alpha = 255, time = 5)

/obj/projectile/magic/aoe/adversary_infection/Moved(atom/OldLoc, Dir)
	. = ..()
	tiles_traveled++

	// Reduce damage after 8 tiles
	if(tiles_traveled > 8)
		damage = 100 * damage_modifier

	// Spawn trail effects
	for(var/turf/T in range(1, get_turf(src)))
		new trail_type(T)

/obj/projectile/magic/aoe/adversary_infection/Range()
	// Override AoE Range to damage all living mobs in 1 tile range
	if(proxdet)
		for(var/mob/living/L in range(1, get_turf(src)))
			if(L == firer)
				continue
			if(L.stat == DEAD)
				continue
			// Skip The Adversary and abnormality mobs
			if(istype(L, /mob/living/simple_animal/hostile/distortion/adversary))
				continue
			if(istype(L, /mob/living/simple_animal/hostile/abnormality))
				continue
			// Deal damage directly to targets in AoE
			L.deal_damage(damage, damage_type, source = firer, attack_type = (ATTACK_TYPE_RANGED))
			playsound(L, 'sound/distortions/the_adversary/slashhit.ogg', 50, TRUE)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))
	..()

/obj/projectile/magic/aoe/adversary_infection/prehit_pierce(atom/A)
	if(isliving(A))
		// Skip The Adversary and abnormality mobs
		if(istype(A, /mob/living/simple_animal/hostile/distortion/adversary))
			return PROJECTILE_PIERCE_PHASE // Phase through without hitting
		if(istype(A, /mob/living/simple_animal/hostile/abnormality))
			return PROJECTILE_PIERCE_PHASE // Phase through without hitting
		return PROJECTILE_PIERCE_HIT // Hit and pierce through all other living targets
	return ..()

/obj/projectile/magic/aoe/adversary_infection/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		// Don't play sound for The Adversary or abnormalities we're phasing through
		if(!istype(target, /mob/living/simple_animal/hostile/distortion/adversary) && !istype(target, /mob/living/simple_animal/hostile/abnormality))
			playsound(target, 'sound/distortions/the_adversary/slashhit.ogg', 50, TRUE)
	return BULLET_ACT_FORCE_PIERCE

/obj/effect/temp_visual/adversary_trail
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	duration = 5

// ENTANGLEMENT Projectile
/obj/projectile/adversary_entangle
	name = "entangling tendril"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "emitter"
	color = "#00FF00"
	damage = 30
	damage_type = BLACK_DAMAGE
	speed = 1.2
	projectile_piercing = PASSMOB // Pierce through mobs
	projectile_phasing = ALL // Passes through walls
	hitsound = 'sound/effects/splat.ogg'
	var/damage_modifier = 1.0

/obj/projectile/adversary_entangle/Initialize(mapload, damage_mod = 1.0)
	. = ..()
	damage_modifier = damage_mod
	damage = 30 * damage_modifier

/obj/projectile/adversary_entangle/prehit_pierce(atom/A)
	if(isliving(A))
		// Skip The Adversary and abnormality mobs
		if(istype(A, /mob/living/simple_animal/hostile/distortion/adversary))
			return PROJECTILE_PIERCE_PHASE // Phase through without hitting
		if(istype(A, /mob/living/simple_animal/hostile/abnormality))
			return PROJECTILE_PIERCE_PHASE // Phase through without hitting
		return PROJECTILE_PIERCE_HIT // Hit and pierce through all other living targets
	return ..()

/obj/projectile/adversary_entangle/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		// Don't affect The Adversary or abnormalities
		if(!istype(target, /mob/living/simple_animal/hostile/distortion/adversary) && !istype(target, /mob/living/simple_animal/hostile/abnormality))
			playsound(target, 'sound/distortions/the_adversary/slashhit.ogg', 50, TRUE)
			if(ishuman(target))
				var/mob/living/carbon/human/H = target
				H.Stun(30) // 3 seconds
	return BULLET_ACT_FORCE_PIERCE

// Action Datum 1: MASS INFECTION
/datum/action/innate/distortion_attack/adversary_mass_infection
	name = "MASS INFECTION"
	button_icon_state = "apocalypse_bird"
	chosen_attack_num = 1

/datum/action/innate/distortion_attack/adversary_mass_infection/Activate()
	var/mob/living/simple_animal/hostile/distortion/adversary/A = owner
	if(!istype(A))
		return

	if(A.mass_infection_cooldown > world.time)
		to_chat(A, span_warning("MASS INFECTION is on cooldown! ([round((A.mass_infection_cooldown - world.time) / 10, 0.1)]s remaining)"))
		return

	to_chat(A, span_notice("MASS INFECTION is now your active ranged attack. Click to fire after windup."))
	A.chosen_attack = 1

// Action Datum 2: ENTANGLEMENT
/datum/action/innate/distortion_attack/adversary_entanglement
	name = "ENTANGLEMENT"
	button_icon_state = "bluestar_gaze"
	chosen_attack_num = 2

/datum/action/innate/distortion_attack/adversary_entanglement/Activate()
	var/mob/living/simple_animal/hostile/distortion/adversary/A = owner
	if(!istype(A))
		return

	if(A.entanglement_cooldown > world.time)
		to_chat(A, span_warning("ENTANGLEMENT is on cooldown! ([round((A.entanglement_cooldown - world.time) / 10, 0.1)]s remaining)"))
		return

	to_chat(A, span_notice("ENTANGLEMENT is now your active ranged attack. Click to fire after windup."))
	A.chosen_attack = 2

// Action Datum 3: UNSTABLE EYE
/datum/action/innate/distortion_attack/adversary_unstable_eye
	name = "UNSTABLE EYE"
	button_icon_state = "spores"
	chosen_attack_num = 3

/datum/action/innate/distortion_attack/adversary_unstable_eye/Activate()
	var/mob/living/simple_animal/hostile/distortion/adversary/A = owner
	if(!istype(A))
		return

	if(A.unstable_eye_cooldown > world.time)
		to_chat(A, span_warning("UNSTABLE EYE is on cooldown! ([round((A.unstable_eye_cooldown - world.time) / 10, 0.1)]s remaining)"))
		return

	if(A.zoomed)
		to_chat(A, span_warning("You are already using UNSTABLE EYE!"))
		return

	A.unstable_eye_cooldown = world.time + A.unstable_eye_cooldown_time
	to_chat(A, span_warning("Channeling UNSTABLE EYE..."))

	// Play sound to all players on same z-level
	for(var/mob/M in GLOB.player_list)
		if(M.z == A.z)
			M.playsound_local(get_turf(M), 'sound/distortions/the_adversary/unstable_eye.ogg', 75, TRUE)

	// 1.5 second slowdown
	A.TemporarySpeedChange(2, 1.5 SECONDS)

	addtimer(CALLBACK(A, TYPE_PROC_REF(/mob/living/simple_animal/hostile/distortion/adversary, activate_unstable_eye)), 1.5 SECONDS)

// Action Datum 4: REJUVENATE THE ROTTEN
/datum/action/innate/distortion_attack/adversary_rejuvenate
	name = "REJUVENATE THE ROTTEN"
	button_icon_state = "hatching_chick"
	chosen_attack_num = 4

/datum/action/innate/distortion_attack/adversary_rejuvenate/Activate()
	var/mob/living/simple_animal/hostile/distortion/adversary/A = owner
	if(!istype(A))
		return

	if(A.rejuvenate_cooldown > world.time)
		to_chat(A, span_warning("REJUVENATE THE ROTTEN is on cooldown! ([round((A.rejuvenate_cooldown - world.time) / 10, 0.1)]s remaining)"))
		return

	if(!length(A.death_remnants))
		to_chat(A, span_warning("There are no remnants to rejuvenate!"))
		return

	A.rejuvenate_cooldown = world.time + A.rejuvenate_cooldown_time
	to_chat(A, span_warning("Channeling REJUVENATE THE ROTTEN..."))

	// Play sound to all players on same z-level
	for(var/mob/M in GLOB.player_list)
		if(M.z == A.z)
			M.playsound_local(get_turf(M), 'sound/distortions/the_adversary/rejuvenate_the_rotten.ogg', 75, TRUE)

	// 1.5 second slowdown
	A.TemporarySpeedChange(2, 1.5 SECONDS)

	addtimer(CALLBACK(A, TYPE_PROC_REF(/mob/living/simple_animal/hostile/distortion/adversary, rejuvenate_the_rotten)), 1.5 SECONDS)

// UNSTABLE EYE proc
/mob/living/simple_animal/hostile/distortion/adversary/proc/activate_unstable_eye()
	if(QDELETED(src) || stat == DEAD)
		return

	zoomed = TRUE
	original_sight = sight

	// Activate zoom
	sight |= SEE_TURFS | SEE_MOBS | SEE_THRU
	regenerate_icons()
	if(client)
		client.view_size.zoomOut(5.5, 10, dir)

	// Apply blur
	set_blurriness(50)

	visible_message(span_danger("[src]'s eyes glow with corrupted energy!"))
	to_chat(src, span_nicegreen("UNSTABLE EYE activated! Vision enhanced but blurred."))

	// Deactivate after 5 seconds
	addtimer(CALLBACK(src, PROC_REF(deactivate_unstable_eye)), 5 SECONDS)

/mob/living/simple_animal/hostile/distortion/adversary/proc/deactivate_unstable_eye()
	if(QDELETED(src) || stat == DEAD)
		return

	zoomed = FALSE

	// Restore vision
	sight = original_sight
	regenerate_icons()
	if(client)
		client.view_size.zoomIn()

	// Remove blur
	set_blurriness(0)

	to_chat(src, span_warning("UNSTABLE EYE fades..."))

// REJUVENATE THE ROTTEN proc
/mob/living/simple_animal/hostile/distortion/adversary/proc/rejuvenate_the_rotten()
	if(QDELETED(src) || stat == DEAD)
		return

	visible_message(span_danger("[src] raises the corrupted dead!"))

	var/zombies_raised = 0

	for(var/list/remnant_data in death_remnants)
		var/turf/spawn_turf = remnant_data["turf"]
		var/human_name = remnant_data["name"]

		// Remove remnant visual
		for(var/obj/effect/temp_visual/adversary_remnant/remnant in spawn_turf)
			qdel(remnant)

		// Spawn zombie with sound
		playsound(spawn_turf, 'sound/distortions/the_adversary/minionsummon.ogg', 50, TRUE)
		new /mob/living/simple_animal/hostile/adversary_zombie(spawn_turf, human_name)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(spawn_turf)
		zombies_raised++

	death_remnants = list()
	to_chat(src, span_nicegreen("You have raised [zombies_raised] corrupted zombie[zombies_raised == 1 ? "" : "s"]!"))

// OpenFire Handler
/mob/living/simple_animal/hostile/distortion/adversary/OpenFire(atom/A)
	if(!can_act)
		return

	if(chosen_attack == 1)
		// MASS INFECTION
		if(mass_infection_cooldown > world.time)
			return

		fire_mass_infection(A)
		return

	if(chosen_attack == 2)
		// ENTANGLEMENT
		if(entanglement_cooldown > world.time)
			return

		fire_entanglement(A)
		return

	// Default ranged attack if no ability selected
	return ..()

/mob/living/simple_animal/hostile/distortion/adversary/proc/fire_mass_infection(atom/target)
	can_act = FALSE
	face_atom(target)
	to_chat(src, span_warning("Channeling MASS INFECTION..."))

	// Play sounds
	playsound(src, 'sound/distortions/the_adversary/massinfection.ogg', 75, TRUE, 7)
	// Play far away sound to players > 7 tiles away on same z-level
	for(var/mob/M in GLOB.player_list)
		if(M.z == z && get_dist(src, M) > 7)
			M.playsound_local(get_turf(M), 'sound/distortions/the_adversary/massinfection_faraway.ogg', 50, TRUE)

	// Show warning overlay
	var/turf/target_turf = get_turf(target)
	target_turf.add_overlay(icon('icons/effects/effects.dmi', "shield"))

	SLEEP_CHECK_DEATH(1.7 SECONDS)

	target_turf.cut_overlay(icon('icons/effects/effects.dmi', "shield"))

	// Fire projectile
	var/obj/projectile/magic/aoe/adversary_infection/P = new(get_turf(src), mass_infection_damage_modifier)
	P.preparePixelProjectile(target, get_turf(src))
	P.fire()

	can_act = TRUE
	mass_infection_cooldown = world.time + mass_infection_cooldown_time
	chosen_attack = 0 // Reset to default

/mob/living/simple_animal/hostile/distortion/adversary/proc/fire_entanglement(atom/target)
	can_act = FALSE
	face_atom(target)
	to_chat(src, span_warning("Channeling ENTANGLEMENT..."))

	// Play sound
	playsound(src, 'sound/distortions/the_adversary/entanglement.ogg', 75, TRUE)

	SLEEP_CHECK_DEATH(0.75 SECONDS)

	// Fire projectile
	var/obj/projectile/adversary_entangle/P = new(get_turf(src), entanglement_damage_modifier)
	P.preparePixelProjectile(target, get_turf(src))
	P.fire()

	can_act = TRUE
	entanglement_cooldown = world.time + entanglement_cooldown_time
	chosen_attack = 0 // Reset to default

