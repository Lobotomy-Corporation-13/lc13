/*
 * Nova Flare — Sector 2: refracted Motus Temple encounters.
 * Node 1 The Hive (mad-fly nests/flies), Node 2 The Clan Wall (stone
 * guards), Node 3 The Scarlet Garden (refracted Scarlet Rose boss).
 */

// ---------- Thornlash telegraph ----------
// GrabAttack detonates the victim's Bleed instead of the base BLACK grab.
/obj/effect/rose_target/thornlash
	name = "lashing thorns"
	desc = "LOOK OUT!"

/obj/effect/rose_target/thornlash/GrabAttack()
	playsound(get_turf(src), 'sound/abnormalities/rosesign/vinegrab.ogg', 75, FALSE, 3)
	new /obj/effect/temp_visual/rose_vine(get_turf(src))
	for(var/mob/living/carbon/human/H in view(3, src))
		var/datum/status_effect/stacking/lc_bleed/B = H.has_status_effect(/datum/status_effect/stacking/lc_bleed)
		if(!B)
			continue
		for(var/i = 1 to 4)
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

/obj/structure/spreading/scarlet_vine/refracted/Initialize()
	. = ..()
	// Detach from any static vine_list the base Initialize() captured us into.
	if(connected_rose)
		connected_rose.vine_list -= src

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
	maxHealth = 200
	health = 200
	loot = list()
	use_base_nesting = FALSE
	var/burrow_bites = 0
	var/min_bites = 2
	var/sp_threshold = 0.5
	var/bite_sanity = 12
	var/bite_cooldown = 0
	var/bite_cooldown_time = 2 SECONDS
	var/reenter_cooldown = 0
	var/reenter_cooldown_time = 5 SECONDS

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
	H.deal_damage(bite_sanity, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
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
	maxHealth = 1650
	health = 1650
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	spawn_fly_type = /mob/living/simple_animal/hostile/mad_fly_swarm/refracted
	fly_cap = 6
	spawn_threshold = 4
	spawn_gib_on_death = FALSE
	/// Damage multiplier a host carrying a burrowed refracted fly deals.
	var/infested_dmg_mult = 1.5
	/// Flies hatched per production cycle.
	var/flies_per_batch = 2
	/// Each crossed hp_burst_fraction band of lost maxHealth bursts flies.
	var/hp_burst_fraction = 0.33
	var/burst_flies_count = 3
	var/bursts_done = 0
	/// On being hit, the attacker gets WHITE Fragile scaling with missing HP.
	var/white_fragile_max = 5
	var/white_fragile_hp_scale = 0.20

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
	while(bands > bursts_done)
		bursts_done++
		BurstFlies(burst_flies_count)

/// Spit out `count` flies on top of normal production (not fly_cap-gated).
/mob/living/simple_animal/hostile/mad_fly_nest/refracted/proc/BurstFlies(count)
	if(stat == DEAD)
		return
	visible_message(span_danger("\The [src] ruptures, spilling a fresh swarm!"))
	playsound(get_turf(src), 'sound/effects/splat.ogg', 60, TRUE, 4)
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	for(var/i in 1 to count)
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
	melee_damage_lower = 8
	melee_damage_upper = 11
	charge = 10
	ability_cooldown_time = 12 SECONDS
	stun_duration = 4 SECONDS
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

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
	var/shielded_mult = 0.15
	var/shield_fx_cooldown = 0
	var/thornlash_cooldown = 0
	var/thornlash_cooldown_time = 9 SECONDS

/mob/living/simple_animal/hostile/scarlet_rose/refracted/Initialize()
	. = ..()
	qdel(GetComponent(/datum/component/chemical_harvest))

/mob/living/simple_animal/hostile/scarlet_rose/refracted/Life()
	. = ..()
	if(!.)
		return
	if(stat == DEAD)
		return
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

// Vine Gauntlet: reduced incoming damage while vines remain near the rose.
/mob/living/simple_animal/hostile/scarlet_rose/refracted/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(amount > 0 && VinesShielding())
		amount *= shielded_mult
		if(world.time >= shield_fx_cooldown)
			shield_fx_cooldown = world.time + 0.5 SECONDS
			new /obj/effect/temp_visual/blood_shield(loc)
	return ..(amount, updating_health, forced)

/mob/living/simple_animal/hostile/scarlet_rose/refracted/proc/VinesShielding()
	for(var/obj/structure/spreading/scarlet_vine/refracted/W in range(gauntlet_check_range, src))
		if(!QDELETED(W))
			return TRUE
	return FALSE

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
