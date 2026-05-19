/*
 * Nova Flare — Sector 3: refracted Resurgence Clan encounters.
 * Node 1 the clan vanguard (scout / defender / drone), Node 2 the clan
 * firing line (gunner / rapid / harpooner / defender), Node 3 the
 * refracted Stone Keeper boss + its pillars.
 *
 * Clan adds are stat-override-only (the clan/stone_guard/refracted
 * precedent): loot/butcher/silk nulled, teleport_away forced FALSE so
 * they die in place and the node clears; every kit (charge system,
 * lockdown, drone heal-beam, ranged specials, harpoon chain) inherited
 * unchanged. Numbers are first-pass finale-spike tuning knobs.
 */

// ---------- Node 1: the clan vanguard ----------

/mob/living/simple_animal/hostile/clan/scout/refracted
	maxHealth = 320
	health = 320
	melee_damage_lower = 7
	melee_damage_upper = 10
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/defender/refracted
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 18
	melee_damage_upper = 24
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/drone/refracted
	maxHealth = 500
	health = 500
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

// ---------- Node 2: the clan firing line ----------

/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted
	maxHealth = 450
	health = 450
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted
	maxHealth = 280
	health = 280
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted
	maxHealth = 520
	health = 520
	melee_damage_lower = 10
	melee_damage_upper = 14
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null
	/// Charge spent per harpoon fired.
	var/harpoon_charge_cost = 5

// Inlined replacement of base OpenFire(): also gates the harpoon on
// charge, falling through to a regular ranged shot when under-charged.
// Keep in sync with /clan/ranged/harpooner/OpenFire() if the base
// changes.
/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted/OpenFire(atom/A)
	if(chained_target)
		return FALSE
	if(ishuman(A) && world.time > harpoon_cooldown && charge >= harpoon_charge_cost)
		FireHarpoon(A)
		charge -= harpoon_charge_cost
		ChargeUpdated()
		return
	return ..()

// ---------- Node 3: the Stone Keeper boss + pillars ----------

// Area-denial add; dies with the boss. Behaviour inherited (immobile,
// no melee, telegraphed laser tiles); stat-override only.
/mob/living/simple_animal/hostile/keeper_piller/refracted
	maxHealth = 650
	health = 650
	loot = list()

// Blue mine scattered by the Stone Keeper after every Slam. A player
// stepping within 1 tile launches it: ~0.5s up, ~1s of beeps, then it
// explodes at the start of its descent for 30 PALE in a 1-tile radius
// around where it stood. After landing, if a player is still within 1
// tile the cycle restarts. Auto-despawns after 30s.
/obj/effect/keeper_mine
	name = "keeper's mine"
	desc = "A pulsing blue mine. Don't stand near it."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "uglymine"
	color = "#3aa0ff"
	density = FALSE
	anchored = TRUE
	layer = OBJ_LAYER
	var/detect_range = 1
	var/trigger_damage = 30
	/// Radius around the mine; 1 = a 3x3 area.
	var/explode_radius = 1
	/// PALE Fragile applied on hit (or +1 above current if higher).
	var/fragile_stacks = 3
	var/lifetime = 30 SECONDS
	/// TRUE during the spawn fall — proximity trigger is gated off
	/// until it lands.
	var/falling = TRUE
	var/fall_time = 0.5 SECONDS
	/// Pixel drop on spawn (~4 tiles up).
	var/fall_height = 128
	var/launching = FALSE
	/// Pixel rise on launch (10 tiles x 32px).
	var/launch_height = 320
	var/launch_up_time = 0.5 SECONDS
	var/airborne_beep_time = 1 SECONDS
	var/launch_down_time = 0.4 SECONDS
	/// "Ground" pixel_y. Jittered for stacked mines so they don't
	/// visually overlap. Fall/launch animations are relative to it.
	var/pixel_y_rest = 0

/obj/effect/keeper_mine/Initialize()
	. = ..()
	// If we're stacking on another mine on this turf, jitter our
	// resting offset (increments of 5) so they don't all overlap.
	for(var/obj/effect/keeper_mine/other in loc)
		if(other == src)
			continue
		pixel_x = pick(-10, -5, 5, 10)
		pixel_y_rest = pick(-10, -5, 5, 10)
		break
	START_PROCESSING(SSfastprocess, src)
	QDEL_IN(src, lifetime)
	// Drop in from above; cannot be triggered until it has landed.
	pixel_y = pixel_y_rest + fall_height
	animate(src, pixel_y = pixel_y_rest, time = fall_time)
	addtimer(CALLBACK(src, PROC_REF(Land)), fall_time)

/obj/effect/keeper_mine/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/effect/keeper_mine/proc/Land()
	if(QDELETED(src))
		return
	falling = FALSE
	playsound(get_turf(src), 'sound/effects/clang.ogg', 30, FALSE, 1)

/obj/effect/keeper_mine/process()
	if(launching || falling || QDELETED(src))
		return
	for(var/mob/living/carbon/human/H in range(detect_range, src))
		if(H.stat == DEAD)
			continue
		INVOKE_ASYNC(src, PROC_REF(TriggerCycle))
		return

/obj/effect/keeper_mine/proc/TriggerCycle()
	if(launching || QDELETED(src))
		return
	launching = TRUE
	animate(src, pixel_y = pixel_y_rest + launch_height, time = launch_up_time)
	sleep(launch_up_time)
	var/end_t = world.time + airborne_beep_time
	while(world.time < end_t)
		if(QDELETED(src))
			return
		playsound(get_turf(src), 'sound/items/timer.ogg', 30, FALSE, 1)
		sleep(2)
	if(QDELETED(src))
		return
	// Begin descent and explode at the start of the lowering.
	animate(src, pixel_y = pixel_y_rest, time = launch_down_time)
	Explode()
	sleep(launch_down_time)
	if(QDELETED(src))
		return
	launching = FALSE
	// On the next process tick, if a player is still within
	// detect_range the cycle re-triggers automatically.

/obj/effect/keeper_mine/proc/Explode()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	playsound(get_turf(src), 'sound/effects/explosion1.ogg', 60, FALSE, 4)
	for(var/mob/living/carbon/human/H in range(explode_radius, src))
		if(H.stat == DEAD)
			continue
		H.deal_damage(trigger_damage, PALE_DAMAGE)
		// PALE Fragile: 3 by default, or +1 above the target's current
		// stack if they already have it (refresh-to-higher is enforced
		// inside apply_lc_pale_fragile).
		var/datum/status_effect/stacking/damtype_protection/pale/fragile/F = H.has_status_effect(/datum/status_effect/stacking/damtype_protection/pale/fragile)
		var/stacks_to_apply = F ? (F.stacks + 1) : fragile_stacks
		H.apply_lc_pale_fragile(stacks_to_apply)

/mob/living/simple_animal/hostile/clan/stone_keeper/refracted
	maxHealth = 2800
	health = 2800
	melee_damage_lower = 24
	melee_damage_upper = 34
	tentacle_damage = 100
	del_on_death = TRUE
	run_ending = FALSE
	use_elliot_interactions = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null
	/// Pillars summoned at 50% HP, removed when the boss dies.
	var/list/spawned_pillars = list()
	/// Mine type scattered after every Slam / Annihilation Beam.
	var/mine_type = /obj/effect/keeper_mine
	/// Slam scatter (post-AoeAttack).
	var/mine_scatter_min = 2
	var/mine_scatter_max = 3
	var/mine_scatter_range = 2
	/// Beam scatter (post-Fire).
	var/beam_mine_count = 7
	var/beam_mine_range = 3
	/// Projectile-hit mine spawn.
	var/bullet_mine_cooldown = 0
	var/bullet_mine_cooldown_time = 1 SECONDS
	var/bullet_mine_range = 2
	/// Throttled bark when mines are scattered.
	var/mine_taunt_cooldown = 0
	var/mine_taunt_cooldown_time = 30 SECONDS
	var/list/mine_lines = list(
		"Movement... Restricted...",
		"Field... Seeded...",
		"Stand... Still...",
		"Mine... Order...",
		"Tread... Carefully...",
	)

// After every slam (the AoeAttack inherited from base), scatter slam
// mines around itself; do nothing if the slam killed us.
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/AoeAttack()
	. = ..()
	if(stat == DEAD)
		return .
	ScatterMines(mine_scatter_min, mine_scatter_max, mine_scatter_range)
	return .

// After every Annihilation Beam (the Fire proc that actually deals the
// line damage), scatter the bigger beam mine wave.
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/Fire(atom/target)
	. = ..()
	if(stat == DEAD)
		return .
	ScatterMines(beam_mine_count, beam_mine_count, beam_mine_range)
	return .

// On taking projectile damage, drop a single mine nearby (1s cooldown).
// `..()` keeps the inherited /clan/bullet_act behaviour (aggro mark,
// shield_link redirect).
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/bullet_act(obj/projectile/P)
	. = ..()
	if(stat == DEAD || QDELETED(src))
		return .
	if(world.time < bullet_mine_cooldown)
		return .
	bullet_mine_cooldown = world.time + bullet_mine_cooldown_time
	ScatterMines(1, 1, bullet_mine_range)
	return .

// Picks `rand(count_min, count_max)` open turfs within `radius` of
// itself and spawns `mine_type` on each. Stacking is allowed but
// discouraged: if the first roll lands on a turf that already has a
// mine, re-roll once; the second roll places regardless. The mine
// itself jitters its pixel offset so stacked mines don't overlap.
// Throttled bark on a successful scatter (shared 30s cooldown between
// slam, beam, and projectile-hit scatters).
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/proc/ScatterMines(count_min, count_max, radius)
	var/turf/center = get_turf(src)
	if(!center)
		return 0
	var/list/all_turfs = list()
	for(var/turf/open/T in range(radius, center))
		if(T.density)
			continue
		all_turfs += T
	if(!length(all_turfs))
		return 0
	var/count = rand(count_min, count_max)
	var/placed = 0
	for(var/i in 1 to count)
		var/turf/T = pick(all_turfs)
		if((locate(/obj/effect/keeper_mine) in T) && length(all_turfs) > 1)
			T = pick(all_turfs - T)
		new mine_type(T)
		placed++
	if(placed > 0 && length(mine_lines) && world.time >= mine_taunt_cooldown)
		mine_taunt_cooldown = world.time + mine_taunt_cooldown_time
		say(pick(mine_lines))
	return placed

// Inlined, shortened replacement of base summon_piller(): a brief
// telegraph, then a refracted pillar at every nova_core refraction
// spawner on this z. The stock ~14s monologue and the full RED heal are
// intentionally dropped (railway boss = single HP bar). Keep in sync
// with /clan/stone_keeper/summon_piller() if the base changes.
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/summon_piller()
	var/list/spots = list()
	for(var/obj/effect/landmark/refraction/spawner/nova_core/L in GLOB.landmarks_list)
		if(L.z == z)
			spots += L
	if(!length(spots))
		return
	talking = TRUE
	can_act = FALSE
	icon_state = "stone_keeper_attack"
	say("Witness, one of many toys of the city...")
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	for(var/obj/effect/landmark/refraction/spawner/nova_core/L in spots)
		var/turf/T = get_turf(L)
		if(!T)
			continue
		var/mob/living/simple_animal/hostile/keeper_piller/refracted/P = new(T)
		spawned_pillars += P
	icon_state = "stone_keeper"
	talking = FALSE
	can_act = TRUE

// Remove the pillars, then fall through to the base death() — which,
// with run_ending = FALSE, performs a normal clan death so the wave
// controller clears the node (no ending/Self-Detonate/Elliot/loot).
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/death(gibbed)
	for(var/mob/living/simple_animal/hostile/keeper_piller/P in spawned_pillars)
		if(!QDELETED(P))
			qdel(P)
	for(var/mob/living/simple_animal/hostile/keeper_piller/P in range(20, src))
		if(!QDELETED(P))
			qdel(P)
	spawned_pillars.Cut()
	return ..()
