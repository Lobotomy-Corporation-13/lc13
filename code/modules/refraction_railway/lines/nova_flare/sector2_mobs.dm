/*
 * Nova Flare — Sector 2: refracted Motus Temple encounters.
 * Node 1 The Hive (mad-fly nests/flies), Node 2 The Clan Wall (stone
 * guards), Node 3 The Scarlet Garden (refracted Scarlet Rose boss).
 */

// ---------- Thornlash telegraph ----------
// On the strike: 10 RED to each target, then a Bleed payload — detonate
// if it has 5+ Bleed, otherwise pile on 30 Bleed instead.
/obj/effect/rose_target/thornlash
	name = "lashing thorns"
	desc = "LOOK OUT!"
	/// Flat RED dealt to every target on the strike.
	var/strike_damage = 10
	/// Minimum Bleed on the target to detonate instead of stacking.
	var/detonate_threshold = 5
	/// Bleed applied when the target is under the detonate threshold.
	var/seed_bleed_stacks = 30
	/// Max detonation pulses.
	var/detonate_pops = 4

/obj/effect/rose_target/thornlash/GrabAttack()
	playsound(get_turf(src), 'sound/abnormalities/rosesign/vinegrab.ogg', 75, FALSE, 3)
	new /obj/effect/temp_visual/rose_vine(get_turf(src))
	for(var/mob/living/carbon/human/H in view(1, src))
		H.deal_damage(strike_damage, RED_DAMAGE)
		var/datum/status_effect/stacking/lc_bleed/B = H.has_status_effect(/datum/status_effect/stacking/lc_bleed)
		if(!B || B.stacks < detonate_threshold)
			H.apply_lc_bleed(seed_bleed_stacks)
			continue
		for(var/i = 1 to detonate_pops)
			if(QDELETED(B))
				break
			H.adjustBruteLoss(max(0, B.stacks))
			new /obj/effect/temp_visual/damage_effect/bleed(get_turf(H))
			B.stacks = round(B.stacks / 2)
			B.update_stacking_number()
			if(B.stacks <= 1)
				qdel(B)
				break
	qdel(src)

// ---------- Refracted Scarlet Vine ----------
// Bound to its rose via a non-static ref (instanced-z safe).

/obj/structure/spreading/scarlet_vine/refracted
	/// The refracted rose that owns this vine.
	var/mob/living/simple_animal/hostile/scarlet_rose/refracted/bound_rose
	/// TRUE while being torn down in a chain-break, to stop re-propagation.
	var/chained = FALSE
	/// Bleed applied to a human the vine grows onto.
	var/grow_bleed_stacks = 4

/obj/structure/spreading/scarlet_vine/refracted/Initialize()
	. = ..()
	// Detach from any static vine_list the base Initialize() captured us into.
	if(connected_rose)
		connected_rose.vine_list -= src
	// Growing onto a tile bleeds any human standing on it.
	for(var/mob/living/carbon/human/H in get_turf(src))
		H.apply_lc_bleed(grow_bleed_stacks)

/obj/structure/spreading/scarlet_vine/refracted/Destroy()
	if(bound_rose)
		bound_rose.bound_vines -= src
		bound_rose = null
	return ..()

// On being destroyed by damage, snap up to 4 adjacent refracted vines.
/obj/structure/spreading/scarlet_vine/refracted/obj_destruction(damage_flag)
	if(!chained)
		var/snapped = 0
		for(var/obj/structure/spreading/scarlet_vine/refracted/V in orange(1, src))
			if(QDELETED(V) || V.chained)
				continue
			V.chained = TRUE
			qdel(V)
			snapped++
			if(snapped >= 4)
				break
	return ..()

// Inlined base expand() plus binding the new vine to bound_rose.
/obj/structure/spreading/scarlet_vine/refracted/expand(bypasscooldown = FALSE)
	if(!can_expand)
		return
	if(!bypasscooldown)
		last_expand = world.time + expand_cooldown
	var/turf/U = get_turf(src)
	if(is_type_in_typecache(U, blacklisted_turfs))
		qdel(src)
		return FALSE
	var/list/spread_turfs = U.reachableAdjacentTurfs()
	shuffle_inplace(spread_turfs)
	for(var/turf/T in spread_turfs)
		var/obj/machinery/M = locate(/obj/machinery) in T
		if(M)
			if(M.density && !bypass_density)
				continue
		var/obj/structure/spreading/S = locate(/obj/structure/spreading) in T
		if(S)
			if(S.type != type)
				S.take_damage(conflict_damage, BRUTE, "melee", 1)
				break
			last_expand += (0.6 SECONDS)
			continue
		if(is_type_in_typecache(T, blacklisted_turfs))
			continue
		var/obj/structure/spreading/scarlet_vine/refracted/NV = new type(T)
		NV.bound_rose = bound_rose
		if(bound_rose)
			bound_rose.bound_vines += NV
		break
	return TRUE

// ---------- Refracted Mad Fly ----------

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted
	maxHealth = 350
	health = 350
	loot = list()
	use_base_nesting = FALSE
	var/burrow_bites = 0
	var/min_bites = 2
	var/sp_threshold = 0.5
	/// RED dealt per bite while burrowed inside the host.
	var/bite_damage = 12
	var/bite_cooldown = 0
	var/bite_cooldown_time = 2 SECONDS
	var/reenter_cooldown = 0
	var/reenter_cooldown_time = 5 SECONDS
	/// Cached refraction run for achievement-state writes (set in Initialize).
	var/datum/refraction_run/refraction_run_ref

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/Initialize()
	. = ..()
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/AttackingTarget(atom/attacked_target)
	. = ..()
	if(nesting_target)
		return
	if(world.time < reenter_cooldown)
		return
	if(!ishuman(attacked_target))
		return
	var/mob/living/carbon/human/H = attacked_target
	if(H.stat == DEAD)
		return
	if(H.sanityhealth > H.maxSanity * sp_threshold)
		return
	nesting_target = H
	burrow_bites = 0
	H.visible_message(span_danger("\The [src] burrows into [H]!"))
	forceMove(H)
	// "Welcoming Host": the player let a swarm burrow in. Earned.
	if(refraction_run_ref && H.ckey)
		refraction_run_ref.EarnAchievement(H.ckey, "swarm_let_burrow")

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/Life()
	. = ..()
	if(!.)
		return
	if(stat == DEAD || !nesting_target)
		return
	if(world.time < bite_cooldown)
		return
	bite_cooldown = world.time + bite_cooldown_time
	var/mob/living/carbon/human/H = nesting_target
	if(!ishuman(H) || H.stat == DEAD || H.sanity_lost)
		LeaveHost()
		return
	H.deal_damage(bite_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
	burrow_bites++
	H.visible_message(span_danger("\The [src] gnaws at [H] from the inside!"))
	if(burrow_bites >= min_bites && H.sanityhealth > H.maxSanity * sp_threshold)
		LeaveHost()

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/proc/LeaveHost()
	var/mob/living/H = nesting_target
	if(H)
		forceMove(get_turf(H))
		H.visible_message(span_danger("\The [src] crawls back out of [H]!"))
	nesting_target = null
	burrow_bites = 0
	reenter_cooldown = world.time + reenter_cooldown_time

// ---------- Refracted Mad Fly Nest ----------

/mob/living/simple_animal/hostile/mad_fly_nest/refracted
	maxHealth = 825
	health = 825
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	spawn_fly_type = /mob/living/simple_animal/hostile/mad_fly_swarm/refracted
	fly_cap = 1
	spawn_threshold = 8
	spawn_gib_on_death = FALSE
	/// Damage multiplier a host carrying a burrowed refracted fly deals.
	var/infested_dmg_mult = 1.5
	/// Flies hatched per production cycle.
	var/flies_per_batch = 1
	/// Each crossed hp_burst_fraction band of lost maxHealth bursts flies.
	var/hp_burst_fraction = 0.33
	var/burst_flies_count = 1
	var/bursts_done = 0
	/// Minimum gap between consecutive HP-band bursts.
	var/burst_cooldown = 0
	var/burst_cooldown_time = 10 SECONDS
	/// On being hit, the attacker gets WHITE Fragile scaling with missing HP.
	var/white_fragile_max = 5
	/// Stacks ramp to max once this fraction of maxHealth is missing.
	var/white_fragile_hp_scale = 0.90

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/Initialize()
	. = ..()
	qdel(GetComponent(/datum/component/chemical_harvest))

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(damage_amount > 0 && ismob(source))
		for(var/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/F in source)
			if(F.nesting_target == source)
				damage_amount *= infested_dmg_mult
				break
	. = ..()
	if(stat == DEAD || maxHealth <= 0)
		return
	if(. > 0 && isliving(source))
		var/mob/living/attacker = source
		if(!faction_check_mob(attacker))
			var/missing_frac = (maxHealth - health) / maxHealth
			var/ratio = clamp(missing_frac / white_fragile_hp_scale, 0, 1)
			var/stacks = clamp(round(ratio * white_fragile_max), 1, white_fragile_max)
			attacker.apply_lc_white_fragile(stacks)
	var/bands = round((maxHealth - health) / (maxHealth * hp_burst_fraction))
	if(bands > bursts_done && world.time >= burst_cooldown)
		bursts_done++
		burst_cooldown = world.time + burst_cooldown_time
		BurstFlies(burst_flies_count)

/// Spit out up to `count` flies, capped by the nest's remaining fly_cap
/// headroom. If the cap is already full, the burst is suppressed.
/mob/living/simple_animal/hostile/mad_fly_nest/refracted/proc/BurstFlies(count)
	if(stat == DEAD)
		return
	listclearnulls(spawned_mobs)
	for(var/mob/living/L in spawned_mobs)
		if(L.stat == DEAD || QDELETED(L))
			spawned_mobs -= L
	var/headroom = fly_cap - length(spawned_mobs)
	if(headroom <= 0)
		return
	var/actual = min(count, headroom)
	visible_message(span_danger("\The [src] ruptures, spilling a fresh swarm!"))
	playsound(get_turf(src), 'sound/effects/splat.ogg', 60, TRUE, 4)
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	for(var/i in 1 to actual)
		var/turf/T = get_step(get_turf(src), pick(0, EAST, WEST, NORTH, SOUTH))
		if(!T || T.density)
			T = get_turf(src)
		var/mob/living/simple_animal/hostile/mad_fly_swarm/nb = new spawn_fly_type(T)
		nb.return_to_origin = TRUE
		spawned_mobs += nb
		if(C)
			C.RegisterSpawnedMob(nb)

// Inlined base Produce(), hatching a whole batch and registering each fly.
/mob/living/simple_animal/hostile/mad_fly_nest/refracted/Produce()
	if(producing || stat == DEAD)
		return
	producing = TRUE
	icon_state = "egg_opening"
	SLEEP_CHECK_DEATH(5)
	visible_message(span_danger("\A new swarm climbs out of [src]!"))
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	for(var/i in 1 to flies_per_batch)
		if(length(spawned_mobs) >= fly_cap)
			break
		var/turf/T = get_step(get_turf(src), pick(0, EAST, WEST, NORTH, SOUTH))
		if(!T || T.density)
			T = get_turf(src)
		var/mob/living/simple_animal/hostile/mad_fly_swarm/nb = new spawn_fly_type(T)
		nb.return_to_origin = TRUE
		spawned_mobs += nb
		if(C)
			C.RegisterSpawnedMob(nb)
	SLEEP_CHECK_DEATH(2)
	icon_state = "egg"
	producing = FALSE
	spawn_progress = 0

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/death(gibbed)
	for(var/mob/living/L in spawned_mobs.Copy())
		if(!QDELETED(L))
			L.death()
	spawned_mobs.Cut()
	return ..()

// ---------- Refracted Stone Guard ----------

/mob/living/simple_animal/hostile/clan/stone_guard/refracted
	maxHealth = 800
	health = 800
	melee_damage_lower = 5
	melee_damage_upper = 7
	attack_tremor = 2
	charge = 10
	ability_cooldown_time = 12 SECONDS
	stun_duration = 4 SECONDS
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null
	/// Target Tremor stacks needed to flip its melee to BLACK for the strike.
	var/black_tremor_threshold = 30
	/// Cached refraction run for achievement-state writes (set in Initialize).
	var/datum/refraction_run/refraction_run_ref

/mob/living/simple_animal/hostile/clan/stone_guard/refracted/Initialize()
	. = ..()
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

// On hitting a target carrying 30+ Tremor, swap RED → BLACK for this strike.
// Stashed/restored so concurrent observers still see the default stat block.
/mob/living/simple_animal/hostile/clan/stone_guard/refracted/AttackingTarget(atom/attacked_target)
	if(!isliving(attacked_target))
		return ..()
	var/mob/living/L = attacked_target
	var/datum/status_effect/stacking/lc_tremor/T = L.has_status_effect(/datum/status_effect/stacking/lc_tremor)
	if(!T || T.stacks < black_tremor_threshold)
		return ..()
	// BLACK-swap path: the target took the punishing strike, so fail their
	// "Restraint" achievement for this run.
	if(refraction_run_ref && L.ckey)
		refraction_run_ref.FailAchievement(L.ckey, "guard_no_black_swap")
	var/saved_type = melee_damage_type
	melee_damage_type = BLACK_DAMAGE
	. = ..()
	melee_damage_type = saved_type

// ---------- Refracted Scarlet Rose (boss) ----------

/mob/living/simple_animal/hostile/scarlet_rose/refracted
	maxHealth = 1400
	health = 1400
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	drop_rose_item = FALSE
	manage_static_vines_on_destroy = FALSE
	use_base_vine_life = FALSE
	/// Non-static vine ownership (instanced-z safe).
	var/list/bound_vines = list()
	var/prespread_done = FALSE
	var/gauntlet_check_range = 2
	/// Incoming-damage reduction per nearby refracted vine.
	var/per_vine_reduction = 0.05
	/// Cap on the stacked per-vine damage reduction.
	var/max_vine_reduction = 0.40
	var/shield_fx_cooldown = 0
	var/thornlash_cooldown = 0
	var/thornlash_cooldown_time = 9 SECONDS
	/// Cached refraction run for achievement-state writes (set in Initialize).
	var/datum/refraction_run/refraction_run_ref
	/// "Stay Unbled" fails any player crossing this Bleed stack count.
	var/bleed_achievement_threshold = 40

/mob/living/simple_animal/hostile/scarlet_rose/refracted/Initialize()
	. = ..()
	qdel(GetComponent(/datum/component/chemical_harvest))
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

/mob/living/simple_animal/hostile/scarlet_rose/refracted/Life()
	. = ..()
	if(!.)
		return
	if(stat == DEAD)
		return
	// "Stay Unbled": any human in view carrying > threshold Bleed stacks
	// fails the achievement for the rest of the run. Polled per tick so
	// we don't need a status-effect signal hook.
	if(refraction_run_ref)
		for(var/mob/living/carbon/human/H in view(15, src))
			if(!H.ckey || H.stat == DEAD)
				continue
			var/datum/status_effect/stacking/lc_bleed/B = H.has_status_effect(/datum/status_effect/stacking/lc_bleed)
			if(B && B.stacks > bleed_achievement_threshold)
				refraction_run_ref.FailAchievement(H.ckey, "rose_no_high_bleed")
	// Deferred so the wave system's post-`new` HP scaling has applied.
	if(!prespread_done)
		prespread_done = TRUE
		PreSpreadVines()
		return
	for(var/obj/structure/spreading/scarlet_vine/refracted/W in bound_vines.Copy())
		if(QDELETED(W))
			continue
		if(W.last_expand <= world.time)
			W.expand()
	SpreadPlants()
	if(thornlash_cooldown <= world.time)
		thornlash_cooldown = world.time + thornlash_cooldown_time
		INVOKE_ASYNC(src, PROC_REF(Thornlash))

// Vine Gauntlet: 5% less incoming damage per nearby refracted vine,
// stacking up to a 40% cap. Cut a lane to strip the shield.
/mob/living/simple_animal/hostile/scarlet_rose/refracted/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(amount > 0)
		var/nearby_vines = CountShieldingVines()
		if(nearby_vines)
			var/reduction = min(max_vine_reduction, nearby_vines * per_vine_reduction)
			amount *= (1 - reduction)
			if(world.time >= shield_fx_cooldown)
				shield_fx_cooldown = world.time + 0.5 SECONDS
				new /obj/effect/temp_visual/blood_shield(loc)
	return ..(amount, updating_health, forced)

/mob/living/simple_animal/hostile/scarlet_rose/refracted/proc/CountShieldingVines()
	. = 0
	for(var/obj/structure/spreading/scarlet_vine/refracted/W in range(gauntlet_check_range, src))
		if(!QDELETED(W))
			.++

// Inlined base SpreadPlants() plus binding the new vine to the rose.
/mob/living/simple_animal/hostile/scarlet_rose/refracted/SpreadPlants()
	if(!isturf(loc) || isspaceturf(loc))
		return
	if(locate(/obj/structure/spreading/scarlet_vine) in get_turf(src))
		return
	var/obj/structure/spreading/scarlet_vine/refracted/NV = new(loc)
	NV.bound_rose = src
	bound_vines += NV

/mob/living/simple_animal/hostile/scarlet_rose/refracted/proc/PreSpreadVines()
	for(var/turf/open/T in range(5, get_turf(src)))
		if(T.density)
			continue
		if(locate(/obj/structure/spreading/scarlet_vine) in T)
			continue
		var/obj/structure/spreading/scarlet_vine/refracted/NV = new(T)
		NV.bound_rose = src
		bound_vines += NV

/mob/living/simple_animal/hostile/scarlet_rose/refracted/proc/Thornlash()
	if(stat == DEAD)
		return
	playsound(get_turf(src), 'sound/abnormalities/rosesign/vinegrab_prep.ogg', 75, FALSE, 5)
	for(var/mob/living/carbon/human/H in view(vine_range, src))
		if(faction_check_mob(H))
			continue
		new /obj/effect/rose_target/thornlash(get_turf(H))

/mob/living/simple_animal/hostile/scarlet_rose/refracted/Destroy()
	for(var/obj/structure/spreading/scarlet_vine/refracted/W in bound_vines.Copy())
		if(!QDELETED(W))
			W.bound_rose = null
			qdel(W)
	bound_vines.Cut()
	return ..()
