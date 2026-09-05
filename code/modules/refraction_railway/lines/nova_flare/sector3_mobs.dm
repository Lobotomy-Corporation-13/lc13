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
	melee_damage_lower = 5
	melee_damage_upper = 7
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/defender/refracted
	maxHealth = 600
	health = 600
	melee_damage_lower = 8
	melee_damage_upper = 11
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
	/// Back-ref for achievement event hooks.
	var/datum/refraction_run/refraction_run_ref

/mob/living/simple_animal/hostile/clan/drone/refracted/Initialize()
	. = ..()
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

// Detect base Life()'s emergency-heal trigger by watching for
// overheal_cooldown to advance. The base sets it to `world.time +
// overheal_cooldown_time` inside the heal branch (and nowhere else), so
// any forward jump means the heal fired this tick. Fight-wide
// achievement — fails for every member ckey.
/mob/living/simple_animal/hostile/clan/drone/refracted/Life()
	var/pre_cooldown = overheal_cooldown
	. = ..()
	if(stat == DEAD || !refraction_run_ref)
		return
	if(overheal_cooldown > pre_cooldown)
		for(var/mob/Mem as anything in refraction_run_ref.members)
			if(Mem?.ckey)
				refraction_run_ref.FailAchievement(Mem.ckey, "drone_no_emergency_heal")

// ---------- Node 2: the clan firing line ----------

// Halved-damage projectile variants used by the refracted ranged trio.
// Base damages: medium 15, rapid 5, harpoon 20.
/obj/projectile/clan_bullet/medium/refracted
	damage = 8

/obj/projectile/clan_bullet/rapid/refracted
	damage = 3

/obj/projectile/clan_bullet/harpoon/refracted
	damage = 10

/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted
	maxHealth = 180
	health = 180
	move_to_delay = 6
	projectiletype = /obj/projectile/clan_bullet/medium/refracted
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

// Inlined base BurstFire(): swaps in the refracted medium bullet.
/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted/BurstFire(atom/target)
	if(stat == DEAD || !target)
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/clan_bullet/medium/refracted/P = new(startloc)
	P.preparePixelProjectile(target, src)
	P.firer = src
	P.fire()
	playsound(src, projectilesound, 50, TRUE)

/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted
	maxHealth = 115
	health = 115
	move_to_delay = 4
	projectiletype = /obj/projectile/clan_bullet/rapid/refracted
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted
	maxHealth = 210
	health = 210
	move_to_delay = 6
	melee_damage_lower = 5
	melee_damage_upper = 7
	projectiletype = /obj/projectile/clan_bullet/medium/refracted
	teleport_away = FALSE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null
	/// Charge spent per harpoon fired.
	var/harpoon_charge_cost = 20
	/// Back-ref for achievement event hooks.
	var/datum/refraction_run/refraction_run_ref

/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted/Initialize()
	. = ..()
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

// DropTarget() is the FAIL path — base PullLoop calls it on proximity
// break or chain timeout. The LOS-break path goes straight to
// ReleaseTarget() and is the GOOD path, so we leave that alone.
// Per-player: only the chained ckey loses the achievement.
/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted/DropTarget()
	var/mob/living/carbon/human/H = chained_target
	. = ..()
	if(refraction_run_ref && istype(H) && H.ckey)
		refraction_run_ref.FailAchievement(H.ckey, "harpooner_no_proximity_break")

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

// Inlined base FireHarpoon(): swaps in the refracted harpoon bullet.
/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted/FireHarpoon(atom/target)
	if(chained_target || world.time < harpoon_cooldown)
		return
	visible_message(span_danger("[src] fires a chain harpoon at [target]!"))
	playsound(src, 'sound/weapons/chainhit.ogg', 75, TRUE)
	var/obj/projectile/clan_bullet/harpoon/refracted/H = new(get_turf(src))
	H.firer = src
	H.preparePixelProjectile(target, src)
	H.fire()
	harpoon_cooldown = world.time + harpoon_cooldown_time

// ---------- Node 3: the Stone Keeper boss + pillars ----------

// Area-denial add; dies with the boss. Behaviour inherited (immobile, no
// melee, telegraphed laser tiles). HP is filled in at runtime by the
// keeper's summon_piller() (summoner.maxHealth * 1.5); the literal here
// is just a safety fallback if one is ever spawned without a summoner.
/mob/living/simple_animal/hostile/keeper_piller/refracted
	maxHealth = 1500
	health = 1500
	loot = list()
	/// Pillar HP = summoner.maxHealth * this multiplier.
	var/summoner_hp_mult = 0.5
	/// Set from the summoning keeper so Destroy() can earn the
	/// achievement.
	var/datum/refraction_run/refraction_run_ref
	/// Set to TRUE in death() so Destroy() can tell "player killed
	/// this" from "keeper's death loop qdel'd this." Without the
	/// flag, the keeper's cleanup qdel would spuriously award the
	/// achievement to every member.
	var/killed_by_damage = FALSE

// Accept the summoning keeper as new()'s second arg and scale our HP off
// its current maxHealth. The wave system's HP scaling has already
// applied to the keeper by the time it summons pillars (50% HP trigger),
// so this tracks the player-count-scaled value automatically.
/mob/living/simple_animal/hostile/keeper_piller/refracted/Initialize(mapload, mob/living/simple_animal/hostile/clan/stone_keeper/refracted/summoner)
	. = ..()
	if(summoner)
		maxHealth = round(summoner.maxHealth * summoner_hp_mult)
		health = maxHealth
		if(istype(summoner))
			refraction_run_ref = summoner.refraction_run_ref

// death() just records intent — the actual achievement award fires
// in Destroy() so it survives any path where the pillar is qdel'd
// without going through the full death chain. The flag distinguishes
// "player killed this" from "keeper's death loop qdel'd this," so the
// achievement isn't spuriously awarded during the keeper's cleanup.
/mob/living/simple_animal/hostile/keeper_piller/refracted/death(gibbed)
	killed_by_damage = TRUE
	return ..()

/mob/living/simple_animal/hostile/keeper_piller/refracted/Destroy()
	if(killed_by_damage && refraction_run_ref)
		for(var/mob/Mem as anything in refraction_run_ref.members)
			if(Mem?.ckey)
				refraction_run_ref.EarnAchievement(Mem.ckey, "keeper_kill_pillar")
	return ..()

// Blue mine scattered by the Stone Keeper after every Slam. A player
// stepping within 1 tile launches it: a short hop up, ~1s of beeps, then
// it explodes at the start of its descent for 30 PALE in a 1-tile radius
// and the mine deletes itself. Auto-despawns after 30s if never tripped.
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
	/// Pixel rise on launch — a small hop, not a full toss.
	var/launch_height = 15
	var/launch_up_time = 0.5 SECONDS
	var/airborne_beep_time = 1 SECONDS
	var/launch_down_time = 0.4 SECONDS
	/// "Ground" pixel_y. Jittered for stacked mines so they don't
	/// visually overlap. Fall/launch animations are relative to it.
	var/pixel_y_rest = 0
	/// Set by the spawning keeper so Explode() can post achievement
	/// fails to the right run.
	var/datum/refraction_run/refraction_run_ref

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
	// Begin descent and explode at the start of the lowering, then qdel.
	animate(src, pixel_y = pixel_y_rest, time = launch_down_time)
	Explode()
	sleep(launch_down_time)
	if(QDELETED(src))
		return
	qdel(src)

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
		if(refraction_run_ref && H.ckey)
			refraction_run_ref.FailAchievement(H.ckey, "keeper_no_mine_hit")

/mob/living/simple_animal/hostile/clan/stone_keeper/refracted
	maxHealth = 1820
	health = 1820
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
	/// Back-ref for achievement event hooks.
	var/datum/refraction_run/refraction_run_ref
	/// Live keeper_mine objs spawned by this keeper. Pruned on qdel via
	/// COMSIG_PARENT_QDELETING. Used by the "Mine Hoarder" achievement:
	/// any scatter that pushes length here >= 20 fails it.
	var/list/live_mines = list()
	/// Threshold for the Mine Hoarder achievement.
	var/mine_swarm_threshold = 20

/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/Initialize()
	. = ..()
	refraction_run_ref = FindRefractionRunForZ(z)
	if(refraction_run_ref)
		refraction_run_ref.InitAchievementsForMob(src)

/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/proc/OnTrackedMineQdel(obj/effect/keeper_mine/M)
	SIGNAL_HANDLER
	live_mines -= M

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
		var/obj/effect/keeper_mine/M = new mine_type(T)
		M.refraction_run_ref = refraction_run_ref
		live_mines += M
		RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(OnTrackedMineQdel))
		placed++
	if(placed > 0 && length(mine_lines) && world.time >= mine_taunt_cooldown)
		mine_taunt_cooldown = world.time + mine_taunt_cooldown_time
		say(pick(mine_lines))
	// Mine Hoarder: any scatter that pushes the live count over the
	// threshold fails for every member ckey. Fight-wide.
	if(refraction_run_ref && length(live_mines) >= mine_swarm_threshold)
		for(var/mob/Mem as anything in refraction_run_ref.members)
			if(Mem?.ckey)
				refraction_run_ref.FailAchievement(Mem.ckey, "keeper_no_mine_swarm")
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
		var/mob/living/simple_animal/hostile/keeper_piller/refracted/P = new(T, src)
		spawned_pillars += P
	icon_state = "stone_keeper"
	talking = FALSE
	can_act = TRUE

// Remove the pillars, then fall through to the base death() — which,
// with run_ending = FALSE, performs a normal clan death so the wave
// controller clears the node (no ending/Self-Detonate/Elliot/loot).
//
// Cleanup walks the whole z, not just `spawned_pillars` or
// `range(20, src)`: the tracked list can drift if a pillar is qdel'd
// outside our code path, and pillar spawner landmarks aren't
// guaranteed to be within 20 tiles of the keeper's death tile. Boss
// node is single-room so the full-z scan is cheap.
/mob/living/simple_animal/hostile/clan/stone_keeper/refracted/Destroy()
	for(var/turf/T as anything in Z_TURFS(z))
		for(var/mob/living/simple_animal/hostile/keeper_piller/P in T)
			if(!QDELETED(P))
				qdel(P)
	spawned_pillars.Cut()
	return ..()
