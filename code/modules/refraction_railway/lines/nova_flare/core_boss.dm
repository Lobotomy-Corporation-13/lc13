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

// Backlash hook lives on deal_damage instead of adjustHealth: the parent
// adjustHealth chain can flag the heart DEAD before our override runs,
// which silently swallows the pulse. deal_damage returns the post-
// reduction damage in `.`, so we can fire on any positive incoming hit
// even on the killing blow.
/mob/living/simple_animal/hostile/mutant_heart/refracted/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(attack_type & ATTACK_TYPE_RANGED)
		damage_amount *= projectile_resist
	. = ..()
	if(. <= 0)
		return
	if(world.time < pulse_cooldown)
		return
	pulse_cooldown = world.time + pulse_cooldown_time
	playsound(get_turf(src), 'sound/creatures/lc13/lovetown/abomination_stagetransition.ogg', 40, TRUE, 3)
	new /obj/effect/temp_visual/blood_shield(src.loc)
	for(var/mob/living/L in range(pulse_range, src))
		if(L == src)
			continue
		L.apply_lc_defense_level_down(defense_down_stacks)

// ---------- Refracted Grandfather ----------

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted
	desc = "The family's head. It will not fall while the hearts still beat \
		for it."
	// Refracted bosses are disposable — no corpse or organ drop. Spawned
	// hearts get cleaned up explicitly in death() below.
	loot = list()
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
		// If the ideal corner is blocked, search outward for the nearest
		// non-dense open turf so hearts don't all pile onto the boss tile
		// (which would also make their tether beams zero-length / invisible).
		if(!T || T.density)
			T = null
			for(var/turf/open/candidate in range(2, locate(center.x + off[1], center.y + off[2], center.z) || center))
				if(!candidate.density)
					T = candidate
					break
			if(!T)
				T = center
		var/mob/living/simple_animal/hostile/mutant_heart/refracted/Hh = new(T)
		Hh.maxHealth = round(maxHealth * heart_hp_fraction)
		Hh.health = Hh.maxHealth
		Hh.del_on_death = TRUE
		Hh.butcher_results = null
		Hh.guaranteed_butcher_results = null
		if(C)
			C.RegisterSpawnedMob(Hh)
		// The base mutant_heart Initialize auto-binds to the nearest boss in
		// view(10) and draws its own beam, but the bind is fragile (depends
		// on the view check passing at exactly the Initialize tick) and can
		// silently no-op. Replace it with an explicit boss-anchored beam.
		if(Hh.current_connection)
			qdel(Hh.current_connection)
			Hh.current_connection = null
		Hh.connected_mob = src
		if(!(Hh in spawned_hearts))
			spawned_hearts += Hh
		Hh.current_connection = Beam(Hh, icon_state = "blood", time = INFINITY, maxdistance = heart_offset * 4, beam_type = /obj/effect/ebeam/blood_connection)

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

// Hearts alive → Meat Drop drops one bomb on every nearby human (not just
// the boss's current target). Once every heart is destroyed it escalates
// into the Meat Barrage: lock onto half the lobby (rounded up, minimum 1)
// and rain bombs directly on each locked target's current tile every 0.5
// seconds for 4 seconds. Targets must keep moving to survive.
/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/MeatDrop()
	if(LAZYLEN(spawned_hearts))
		meat_cooldown = world.time + meat_cooldown_time
		playsound(get_turf(src), 'sound/magic/arbiter/repulse.ogg', 25, FALSE, 5)
		for(var/mob/living/carbon/human/H in view(7, src))
			if(faction_check_mob(H))
				continue
			var/turf/T = get_turf(H)
			if(!T)
				continue
			new /obj/effect/temp_visual/meat_warning(T, src)
		return
	meat_cooldown = world.time + meat_barrage_cooldown_time
	if(!target)
		return
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	var/np = C ? C.num_players : 1
	var/target_count = max(1, round((np + 1) / 2))
	var/list/candidates = list()
	if(ishuman(target) && !faction_check_mob(target))
		candidates += target
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H in candidates)
			continue
		if(!faction_check_mob(H))
			candidates += H
	if(!length(candidates))
		return
	var/list/locked = list()
	for(var/i in 1 to min(target_count, length(candidates)))
		var/mob/living/carbon/human/L = pick(candidates)
		candidates -= L
		locked += L
	playsound(get_turf(src), 'sound/magic/arbiter/repulse.ogg', 35, FALSE, 6)
	// 8 ticks × 0.5s = 4 seconds of barrage. Each tick drops one warning
	// per still-living locked target on that target's CURRENT tile.
	for(var/i in 0 to 7)
		addtimer(CALLBACK(src, PROC_REF(MeatBarrageTick), locked), i * (0.5 SECONDS))

/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/proc/MeatBarrageTick(list/locked)
	if(stat == DEAD)
		return
	for(var/mob/living/carbon/human/H in locked)
		if(QDELETED(H) || H.stat == DEAD)
			continue
		var/turf/T = get_turf(H)
		if(!T)
			continue
		new /obj/effect/temp_visual/meat_warning(T, src)

// Mask-break opener: inlined parent body (minus the gibspawner spawn so
// refracted bosses leave no remains), then a Grief Stomp. Kept in sync
// with /mob/living/simple_animal/hostile/mutant_clown/BreakMask().
/mob/living/simple_animal/hostile/mutant_clown/boss/refracted/BreakMask()
	can_act = FALSE
	icon_living = icon_state + "_unmasked"
	icon_state = icon_living
	desc += "Now with their mask broken... You can see their mutated face."
	current_stage = 2
	retreat_distance = 0
	minimum_distance = 0
	say(maskbreak_say_1)
	move_to_delay = move_speed_maskbreak
	UpdateSpeed()
	playsound(get_turf(src), 'sound/creatures/lc13/lovetown/scream.ogg', 50, TRUE, 3)
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))
	INVOKE_ASYNC(src, PROC_REF(GriefStomp))
	SLEEP_CHECK_DEATH(25)
	ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 1.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2))
	say(maskbreak_say_2)
	can_act = TRUE

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
