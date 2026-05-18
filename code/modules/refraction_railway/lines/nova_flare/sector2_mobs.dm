/*
 * Nova Flare — Sector 2: refracted Motus Temple encounters.
 *
 * Node 1 "The Hive": refracted mad-fly Nests (destructible spawner
 *   objective) that hatch refracted Flies. Flies burrow into players at
 *   <=50% sanity, drain sanity, and leave once the host recovers; while a
 *   fly is inside you, you hit Nests 50% harder.
 * Node 2 "The Clan Wall": refracted Stone Guards (charge/stagger/Transpierce
 *   identity kept).
 * Node 3 "The Scarlet Garden": refracted Scarlet Rose boss — a 5-tile vine
 *   field pre-spread at spawn (Vine Gauntlet: reduced damage while dense
 *   vines remain near it), cutting a vine snaps up to 4 adjacent vines, and
 *   Thornlash detonates accumulated Bleed. Vines vanish on rose death.
 *
 * Base file (lc13_motus_temple.dm) is touched only via defaulted gate vars
 * (mirrors the give_boss_achievement precedent). Conventions: loot=list(),
 * null butcher results, drop chemical_harvest, deferred runtime spawns,
 * INVOKE_ASYNC for sleeping attacks, RegisterSpawnedMob for runtime children.
 */

// ---------- Thornlash telegraph ----------
// Subtype of the rose_sign /obj/effect/rose_target: inherits its
// icon (64x64.dmi "warning_rose"), pixel offsets, and Initialize() ->
// addtimer(GrabAttack, 3 SECONDS) ground-marker delay. We only swap what
// GrabAttack does: detonate the victim's Bleed instead of the BLACK grab.

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
		// Pop the Bleed up to 4 times: BRUTE = current stacks, then halve;
		// clear it once a halved value falls to <=1.
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
// Self-contained: bound to its spawning rose via a NON-static ref so the
// base static connected_rose/vine_list are never relied on (instanced-z
// safety). Inherits armor / VineEffect / VineAttack / CanAllowThrough.

/obj/structure/spreading/scarlet_vine/refracted
	/// The refracted rose that owns this vine (non-static; replaces the
	/// base static connected_rose binding).
	var/mob/living/simple_animal/hostile/scarlet_rose/refracted/bound_rose
	/// TRUE when this vine is being torn down as part of a chain-break, so
	/// it does not itself re-propagate the chain.
	var/chained = FALSE

/obj/structure/spreading/scarlet_vine/refracted/Initialize()
	. = ..()
	// Base Initialize() may have captured us into the static vine_list of
	// whatever rose it scanned; detach immediately. bound_rose is assigned
	// by the rose right after `new`.
	if(connected_rose)
		connected_rose.vine_list -= src

/obj/structure/spreading/scarlet_vine/refracted/Destroy()
	if(bound_rose)
		bound_rose.bound_vines -= src
		bound_rose = null
	return ..()

// Chain-break: when destroyed BY DAMAGE (obj_destruction fires on integrity
// loss; a plain qdel from the rose's cleanup does NOT route here, so the
// mass teardown can't cascade), snap up to 4 adjacent refracted vines.
// Those are qdel'd (Destroy(), not obj_destruction) so they do not
// re-propagate — single-step only, never a full-field wipe.
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

// Inlined from /obj/structure/spreading/expand() (ModularLobotomy/
// lc13_structures.dm) + binding the new vine to bound_rose so regrown lane
// vines are torn down on rose death. Keep in sync with the base proc.
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
	maxHealth = 45
	health = 45
	loot = list()
	use_base_nesting = FALSE
	/// Burrow tuning.
	var/burrow_bites = 0
	var/min_bites = 2
	var/sp_threshold = 0.5
	var/bite_sanity = 12
	var/bite_cooldown = 0
	var/bite_cooldown_time = 2 SECONDS
	var/reenter_cooldown = 0
	var/reenter_cooldown_time = 5 SECONDS

/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/AttackingTarget(atom/attacked_target)
	. = ..() // 4x bite + lunge onto the target tile; base nesting gated off.
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
	. = ..() // grandparent upkeep; base devour/throw-up gated off.
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
	fly_cap = 3
	spawn_threshold = 14
	spawn_gib_on_death = FALSE
	/// Damage multiplier a host carrying a burrowed refracted fly deals.
	var/infested_dmg_mult = 1.5

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/Initialize()
	. = ..()
	qdel(GetComponent(/datum/component/chemical_harvest))

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(damage_amount > 0 && ismob(source))
		for(var/mob/living/simple_animal/hostile/mad_fly_swarm/refracted/F in source)
			if(F.nesting_target == source)
				damage_amount *= infested_dmg_mult
				break
	return ..()

// Inlined from base Produce() + wave-controller registration so the node
// tracks nest-born flies (base never registers them). Keep in sync.
/mob/living/simple_animal/hostile/mad_fly_nest/refracted/Produce()
	if(producing || stat == DEAD)
		return
	producing = TRUE
	icon_state = "egg_opening"
	SLEEP_CHECK_DEATH(10)
	visible_message(span_danger("\A new swarm climbs out of [src]!"))
	var/turf/T = get_step(get_turf(src), pick(0, EAST))
	var/mob/living/simple_animal/hostile/mad_fly_swarm/nb = new spawn_fly_type(T)
	nb.return_to_origin = TRUE
	spawned_mobs += nb
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	if(C)
		C.RegisterSpawnedMob(nb)
	SLEEP_CHECK_DEATH(2)
	icon_state = "egg"
	producing = FALSE
	spawn_progress = -5

/mob/living/simple_animal/hostile/mad_fly_nest/refracted/death(gibbed)
	for(var/mob/living/L in spawned_mobs.Copy())
		if(!QDELETED(L))
			L.death()
	spawned_mobs.Cut()
	return ..()

// ---------- Refracted Stone Guard ----------
// Vars only; charge/stagger/Transpierce/Move-gating all inherited.

/mob/living/simple_animal/hostile/clan/stone_guard/refracted
	maxHealth = 520
	health = 520
	melee_damage_lower = 8
	melee_damage_upper = 11
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
	. = ..() // grandparent upkeep only; base static-vine loop gated off.
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

// Vine Gauntlet: heavily reduced incoming damage while dense vines remain
// near the rose (amount > 0 = damage taken, per the stone_guard precedent).
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

// Inlined from base SpreadPlants() + binding. Keep in sync.
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
