/*
 * Nova Flare — core node boss: the refracted "Grandfather".
 *
 * Two-phase fight, subtyped from the base Grandfather + mutant_heart so the
 * base file (ModularLobotomy\extra_mobs\lc13_nuke_clowns.dm) stays untouched.
 *
 * Phase 1: 4 refracted hearts shield him (he is damage-immune + immobile
 * while any heart lives — inherited from the base boss). Each heart's HP is
 * 50% of the boss's already-scaled maxHealth. He auto-wails every 15s,
 * dealing WHITE + RED Fragile and summoning reinforcement clowns.
 * Phase 2 (hearts dead): mobile; Meat Barrage + (on mask break / periodic)
 * Grief Stomp. Mask still breaks at 50% HP into the inherited RED-weak
 * enrage. On death, all nearby clowns die.
 *
 * Player-facing briefing text lives in passives.dm / attacks.dm.
 */

// Targeting reticle marking each tile a Grief Stomp will hit. Lasts the
// windup so it clears as the stomp lands. Subtyped off the base temp_visual
// (not /target) to avoid the megafauna fireball/explosion behaviour.
/obj/effect/temp_visual/grief_stomp_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	light_range = 2
	duration = 8

// ---------- Refracted heart ----------
// Inherits the base mutant_heart's boss-attach scan, blood beam, immobility,
// no-attack, del_on_death and spawned_hearts de-registration. The boss
// overwrites maxHealth/health at spawn.

/mob/living/simple_animal/hostile/mutant_heart/refracted
	name = "refracted heart"
	desc = "A swollen, mistuned heart wired into the Grandfather. Strike it \
		and it lashes back."
	/// Incoming projectile/ranged damage is multiplied by this.
	var/projectile_resist = 0.5
	/// Backlash: on being damaged, weaken everything nearby.
	var/pulse_cooldown = 0
	var/pulse_cooldown_time = 1 SECONDS
	var/pulse_range = 2
	var/defense_down_stacks = 3

/mob/living/simple_animal/hostile/mutant_heart/refracted/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(attack_type & ATTACK_TYPE_RANGED)
		damage_amount *= projectile_resist
	return ..()

/mob/living/simple_animal/hostile/mutant_heart/refracted/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(amount >= 0 || stat == DEAD)
		return
	if(world.time < pulse_cooldown)
		return
	pulse_cooldown = world.time + pulse_cooldown_time
	playsound(get_turf(src), 'sound/creatures/lc13/lovetown/abomination_stagetransition.ogg', 40, TRUE, 3)
	new /obj/effect/temp_visual/blood_shield(src.loc)
	for(var/mob/living/L in range(pulse_range, src))
		L.apply_lc_defense_level_down(defense_down_stacks)

// ---------- Refracted Grandfather ----------

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted
	desc = "The family's head. It will not fall while the hearts still beat \
		for it."
	scream_cooldown_time = 15 SECONDS
	/// RED Fragile stacks applied by the wail.
	var/scream_fragile_stacks = 2
	/// Cooldown for the phase-2 (hearts destroyed) Meat Barrage. The normal
	/// single-bomb Meat Drop keeps the inherited meat_cooldown_time (~2.5s).
	var/meat_barrage_cooldown_time = 6 SECONDS
	/// One-shot guard: hearts spawn once, after wave HP-scaling has applied.
	var/hearts_spawned = FALSE
	/// Square radius (tiles) the 4 hearts spawn at around the boss.
	var/heart_offset = 3
	/// Each heart's maxHealth as a fraction of the boss's scaled maxHealth.
	var/heart_hp_fraction = 0.5
	/// Phase-2 Grief Stomp.
	var/grief_stomp_cooldown = 0
	var/grief_stomp_cooldown_time = 10 SECONDS
	var/grief_stomp_range = 2
	var/grief_stomp_damage = 40
	var/grief_stomp_def_stacks = 10
	/// Reinforcement pool — mostly Son/Father, rare Sister/Mother.
	var/list/reinforcement_weights = list(
		/mob/living/simple_animal/hostile/mutant_clown/refracted = 70,
		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = 20,
		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = 10,
	)

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/Life()
	. = ..()
	if(!.)
		return
	if(stat == DEAD)
		return
	// Spawn the hearts one tick after spawn so the wave system's
	// post-`new` HP scaling has already applied to maxHealth.
	if(!hearts_spawned)
		hearts_spawned = TRUE
		SpawnHearts()
		return
	// Phase 1: immobile behind hearts, so drive the wail off Life().
	if(LAZYLEN(spawned_hearts))
		if(scream_cooldown <= world.time)
			INVOKE_ASYNC(src, PROC_REF(Scream))
		return
	// Phase 2: stage-2 periodic Grief Stomp.
	if(current_stage >= 2 && can_act && target && grief_stomp_cooldown <= world.time)
		INVOKE_ASYNC(src, PROC_REF(GriefStomp))

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/Scream()
	..()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(!faction_check_mob(H))
			H.apply_lc_red_fragile(scream_fragile_stacks)
	if(LAZYLEN(spawned_hearts))
		SpawnReinforcements()

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/proc/SpawnHearts()
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	var/list/offsets = list(
		list(heart_offset, heart_offset),
		list(heart_offset, -heart_offset),
		list(-heart_offset, heart_offset),
		list(-heart_offset, -heart_offset),
	)
	for(var/list/off in offsets)
		var/turf/T = locate(center.x + off[1], center.y + off[2], center.z)
		if(!T || T.density)
			T = center
		var/mob/living/simple_animal/hostile/mutant_heart/refracted/Hh = new(T)
		Hh.maxHealth = round(maxHealth * heart_hp_fraction)
		Hh.health = Hh.maxHealth
		Hh.del_on_death = TRUE
		Hh.butcher_results = null
		Hh.guaranteed_butcher_results = null
		if(C)
			C.RegisterSpawnedMob(Hh)

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/proc/SpawnReinforcements()
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	var/np = C ? C.num_players : 1
	var/count = max(1, np)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/i in 1 to count)
		var/spawn_path = pickweight(reinforcement_weights)
		var/list/open = list()
		for(var/turf/open/T in range(2, center))
			if(!T.density)
				open += T
		var/turf/dest = length(open) ? pick(open) : center
		var/mob/living/simple_animal/hostile/mutant_clown/M = new spawn_path(dest)
		M.del_on_death = TRUE
		M.butcher_results = null
		M.guaranteed_butcher_results = null
		if(C)
			C.RegisterSpawnedMob(M)

// Hearts alive → the inherited single-bomb Meat Drop (~2.5s). Once every
// heart is destroyed it escalates into a multi-bomb barrage.
/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/MeatDrop()
	if(LAZYLEN(spawned_hearts))
		return ..()
	meat_cooldown = world.time + meat_barrage_cooldown_time
	if(!target)
		return
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	var/np = C ? C.num_players : 1
	var/barrage_count = 2 + np
	playsound(get_turf(target), 'sound/magic/arbiter/repulse.ogg', 20, 0, 5)
	var/list/spots = list()
	spots += get_turf(target)
	for(var/mob/living/carbon/human/H in view(7, src))
		if(!faction_check_mob(H))
			spots += get_turf(H)
	for(var/turf/T in view(5, src))
		spots += T
	for(var/i in 1 to barrage_count)
		if(!length(spots))
			break
		var/turf/T = pick(spots)
		spots -= T
		new /obj/effect/temp_visual/meat_warning(T, src)

// Mask-break opener: the inherited enrage, then a Grief Stomp.
/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/BreakMask()
	..()
	INVOKE_ASYNC(src, PROC_REF(GriefStomp))

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/proc/GriefStomp()
	if(stat == DEAD || !can_act)
		return
	grief_stomp_cooldown = world.time + grief_stomp_cooldown_time
	can_act = FALSE
	if(target)
		face_atom(target)
	for(var/turf/T in view(grief_stomp_range, src))
		new /obj/effect/temp_visual/grief_stomp_warning(T)
	playsound(get_turf(src), 'sound/abnormalities/mountain/slam.ogg', 70, FALSE, 5)
	SLEEP_CHECK_DEATH(7)
	var/list/been_hit = list()
	for(var/turf/T in view(grief_stomp_range, src))
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, grief_stomp_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in range(grief_stomp_range, src))
		if(!faction_check_mob(L))
			L.apply_lc_defense_level_down(grief_stomp_def_stacks)
	SLEEP_CHECK_DEATH(4)
	can_act = TRUE

// On death, drag the whole family down with him.
/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/death(gibbed)
	for(var/mob/living/simple_animal/hostile/mutant_clown/Clown in range(12, src))
		if(Clown == src)
			continue
		Clown.death()
	for(var/mob/living/simple_animal/hostile/mutant_heart/Hh in spawned_hearts.Copy())
		qdel(Hh)
	. = ..()
