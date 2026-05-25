/*
 * Curtain Call — zeal_s2n2: Greed Touched Eric.T.
 * A bloody clone of the friendly clinic NPC Eric.T (his deepest greed made
 * flesh). Pure summoner; conjures hordes of greed-touched and X-Corp mobs
 * whose deaths blood-beam their lifeblood back to him. Once his bloodfeast
 * pool fills, he detonates the room in a Greed Burst, sacrificing every
 * live summon and dropping his shield for a vulnerable window. Shield is
 * the friendly Eric's flat-subtract /obj/effect/temp_visual/blood_shield
 * pattern (eric_t.dm:791), with blood_resistance scaled by pool size.
 */

#define ERIC_PHASE_1 1
#define ERIC_PHASE_2 2
#define ERIC_PHASE_3 3

// ---------- Telegraph effects ----------

/obj/effect/temp_visual/greed_burst_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#aa0000"
	light_range = 2
	duration = 20

/obj/effect/temp_visual/greed_minion_burst
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff3030"
	duration = 8

// ---------- Sanguine Feast effects ----------

// Marker placed under each Sanguine Feast target. Shares the helix
// macrolaser's icon/state/offsets for visual consistency, but is a
// completely separate type with its own Blowup that runs blood damage
// and weak-mob execution (instead of the original 3-tile BLACK laser).
/obj/effect/temp_visual/sanguine_marker
	name = "Sanguine Feast"
	desc = "Reality folds around a hunger that is about to bite."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	// 4s warning + ~1s afterglow once the tendril resolves.
	duration = 50
	color = "#9e1638"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	var/mob/living/simple_animal/hostile/greed_touched_eric/source
	var/damage = 80
	var/execute_threshold = 800

/obj/effect/temp_visual/sanguine_marker/Initialize(mapload, mob/living/simple_animal/hostile/greed_touched_eric/eric)
	. = ..()
	source = eric
	addtimer(CALLBACK(src, PROC_REF(Blowup)), 40)

/obj/effect/temp_visual/sanguine_marker/Destroy()
	source = null
	return ..()

/obj/effect/temp_visual/sanguine_marker/proc/Blowup()
	if(QDELETED(src))
		return
	icon_state = "beamin"
	color = "#aa0000"
	transform *= 2.5
	pixel_y += 80
	var/turf/T = get_turf(src)
	if(!T)
		return
	playsound(T, 'sound/abnormalities/nosferatu/attack_special.ogg', 65, TRUE, 4)
	new /obj/effect/temp_visual/sanguine_tendril(T)
	new /obj/effect/decal/cleanable/blood/splatter(T)
	for(var/mob/living/L in T)
		if(L == source)
			continue
		if(ishuman(L))
			L.deal_damage(damage, RED_DAMAGE, source,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			L.apply_lc_bleed(3)
		else if(L.maxHealth < execute_threshold)
			// Execute non-human mob (including Eric's own summons) and feed
			// Eric extra blood — the "feast" eats whatever's caught in it.
			L.visible_message(span_warning("[L] withers into a husk as the feast claims it!"))
			if(source && !QDELETED(source))
				var/datum/component/bloodfeast/C = source.GetComponent(/datum/component/bloodfeast)
				if(C)
					C.AdjustBlood(round(L.maxHealth / 2))
					source.RecomputeShield()
			L.deal_damage(L.health + 200, RED_DAMAGE, source,
				flags = (DAMAGE_FORCED),
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

// 32x64 sprite from icons/mob/nest.dmi state "tendril" — rises out of the
// marker tile at the moment of impact, holds, then fades. Pure visual; the
// damage/execute logic lives in sanguine_marker.Blowup() above.
/obj/effect/temp_visual/sanguine_tendril
	name = "blood tendril"
	icon = 'icons/mob/nest.dmi'
	icon_state = "tendril"
	duration = 25
	layer = ABOVE_MOB_LAYER
	color = "#7a0000"

/obj/effect/temp_visual/sanguine_tendril/Initialize()
	. = ..()
	// Start collapsed beneath the floor, then rise into spike position.
	pixel_y = -80
	alpha = 0
	animate(src, pixel_y = -16, alpha = 255, time = 4, easing = QUAD_EASING)
	addtimer(CALLBACK(src, PROC_REF(StartFade)), 20)

/obj/effect/temp_visual/sanguine_tendril/proc/StartFade()
	if(QDELETED(src))
		return
	animate(src, alpha = 0, time = 5)

// ---------- Greed Touched Eric.T (boss) ----------

/mob/living/simple_animal/hostile/greed_touched_eric
	name = "Greed Touched Eric.T"
	desc = "A bloody shape wearing Eric's face — dripping wherever it stands, \
		looking at every drop of blood in the room as if it already owns it."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "b_boss"
	icon_living = "b_boss"
	icon_dead = "b_boss_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	// Shared with summons so faction_check_mob skips them on AoE pulses.
	faction = list("greed_clan", "hostile")
	maxHealth = 2200
	health = 2200
	melee_damage_lower = 0
	melee_damage_upper = 0
	speak_chance = 0
	turns_per_move = 5
	// Very slow stalker in P1/P2 — base hostile AI pursues to range 1, so he
	// slowly closes to adjacent without ever attacking (melee = 0).
	move_to_delay = 16
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2)
	// Lets death() play its own fade-out without the wave spawner del_on_death-ing him.
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null

	var/normal_state    = "b_boss"
	var/hardblood_state = "b_boss_hardblood"
	var/exhausted_state = "b_boss_exhausted"

	// ---- Bloodfeast shield ----
	/// Mirrors the friendly NPC's flat-subtract block. Recomputed from the
	/// bloodfeast pool every Life() tick; held at 0 during a Greed Burst window.
	var/blood_resistance = 0
	// Pushed up to 150 to force "kill the mobs first" play. Against the
	// 50-DPS / 200-HP player profile: 50-dmg swings bounce entirely
	// (0 through), 100-dmg specials still bounce, even 200-dmg crits
	// only land for 50. The only reliable way to chip Eric is to drain
	// his pool by killing his summons until the burst window opens.
	var/blood_resistance_cap = 150
	// Cap is high enough to absorb Sanguine Feast's execution bonuses (each
	// executed mob feeds maxHealth/2 blood — multiple executes can dump
	// 300+ extra in one feast).
	var/blood_cap            = 700
	var/blood_visual_threshold = 350
	/// Shield is forced to 0 until this timestamp regardless of pool refill.
	var/shield_locked_until = 0
	/// Cooldowns for the friendly NPC's "yep, waste of your time" quip and the warning.
	var/shielded_line = "Hm. The Heart provides. Your strikes do not, child."
	var/warning_line  = "Mind yourself, child. The Heart has plans for you."
	var/last_shielded_say = 0
	var/last_warning_say  = 0
	var/say_cooldown      = 30 SECONDS

	// ---- Summon loop ----
	/// Mobs we have summoned that are still alive; signal-managed.
	var/list/summoned_mobs = list()
	var/max_summons = 6
	var/summons_per_wave = 3
	var/summon_cooldown = 0
	var/summon_cooldown_time = 12 SECONDS
	/// Anti-stall: if 20s pass with no minion death, double next wave size once.
	var/last_minion_death_time = 0
	var/stall_grace_time = 20 SECONDS

	// ---- Greed Burst ----
	var/burst_telegraph_time = 2 SECONDS
	var/burst_window_time    = 6 SECONDS
	// Room-wide raw damage; halved by the standard 50% player DR. Kept
	// modest because there is no positional dodge — every fight will eat it.
	var/burst_player_damage  = 30
	// Localized 3x3 around each sacrificed minion; only hits players who
	// stand close, so it punishes failure to space. Heavier than the
	// room-wide pulse precisely because players have agency to avoid it.
	var/burst_minion_damage  = 50
	var/burst_minion_bleed   = 2
	/// Glutted: two bursts in a row with no Eric HP damage between them doubles the next.
	var/bursts_without_damage = 0
	var/glutted = FALSE
	var/hp_at_last_burst = 0

	// ---- Phase tracking ----
	var/phase = ERIC_PHASE_1
	var/phase_2_trigger_threshold = 0.50
	var/phase_3_trigger_threshold = 0.25
	var/phase_2_trigger_hp = 0
	var/phase_3_trigger_hp = 0
	var/phase_2_triggered = FALSE
	var/phase_3_triggered = FALSE

	// ---- Hardblood (phase 3) ----
	var/hardblood_cooldown = 0
	var/hardblood_cooldown_time = 10 SECONDS
	// 90 raw per strike = 45 effective post-DR; eating all 3 is ~68% HP
	// loss, plus a 1s Knockdown each so the player gets staggered between
	// strikes. P3 is Eric's last stand — losing a Hardblood cycle should hurt.
	var/hardblood_strike_damage = 90
	var/hardblood_knockdown_time = 1 SECONDS

	// ---- Sanguine Rush (phase 3 triple-dash) ----
	// Cribbed from /mob/living/simple_animal/hostile/humanoid/fixer/flame's
	// TripleDash — three back-to-back dashes, each hitting a 3x3 strip
	// along the path. Bleeds the player in addition to RED damage; alternates
	// with Hardblood Strike to keep P3 unpredictable.
	var/sanguine_rush_cooldown = 0
	var/sanguine_rush_cooldown_time = 15 SECONDS
	var/sanguine_rush_dash_damage = 40
	var/sanguine_rush_dash_bleed  = 2
	var/sanguine_rush_dash_range  = 7

	// ---- Sanguine Feast ----
	var/sanguine_feast_cooldown = 0
	var/sanguine_feast_cooldown_time = 30 SECONDS
	/// Raw damage to a player standing on the marker tile at Blowup. Heavy
	/// because the 4s marker telegraph is fully avoidable — stepping off
	/// the marked tile dodges it entirely.
	var/sanguine_feast_damage = 120
	/// Non-human mobs with maxHealth below this on the marker tile are executed.
	var/sanguine_feast_execute_threshold = 800
	/// Eric is locked in place this long while the helix markers play out;
	/// matches the marker's Blowup timing.
	var/sanguine_feast_charge_time = 4 SECONDS

	// ---- Lifecycle ----
	var/dying = FALSE
	var/death_fade_time = 2 SECONDS

	var/list/spawn_lines = list(
		"Welcome, livestock. The herd has been waiting for you.",
		"Anyways. The Heart of Greed has a place for you in the pen, child.",
		"Hm. Kids these days, walking right up to the altar. How blessed.",
	)
	var/list/burst_lines = list(
		"Harvest time, children. Sit still.",
		"Every drop. The Heart accepts its tithe.",
		"Bleed, children. The faithful do so willingly.",
	)
	var/list/phase_2_lines = list(
		"Is this all the herd has? The Heart still hungers.",
		"Hm. The sermon is over, children. Time you learned your place.",
	)
	var/list/phase_3_lines = list(
		"The sermon ends! The Heart hungers, and you children WILL feed it!",
		"Kids these days! The faithful would never make me work this hard. SIT STILL!",
	)
	var/list/death_lines = list(
		"...the herd... was almost... mine...",
		"...the Heart... was supposed to... fill me...",
		"...kids these days... never knew... their place...",
	)

/mob/living/simple_animal/hostile/greed_touched_eric/refracted

/mob/living/simple_animal/hostile/greed_touched_eric/Initialize(mapload)
	. = ..()
	// Red-tint the friendly NPC's existing boss sprite (CLAUDE.md: reuse icon_states).
	add_atom_colour("#aa0000", FIXED_COLOUR_PRIORITY)
	phase_2_trigger_hp = round(maxHealth * phase_2_trigger_threshold)
	phase_3_trigger_hp = round(maxHealth * phase_3_trigger_threshold)
	hp_at_last_burst = health
	last_minion_death_time = world.time
	// /datum/component/bloodfeast/Initialize(siphon, range, starting, threshold, max_amount)
	AddComponent(/datum/component/bloodfeast, TRUE, 2, 0, blood_visual_threshold, blood_cap)
	summon_cooldown = world.time + 3 SECONDS
	// Grace before the first Sanguine Feast so the fight opens with a wave.
	sanguine_feast_cooldown = world.time + 15 SECONDS
	addtimer(CALLBACK(src, PROC_REF(Greet)), 1 SECONDS)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/Greet()
	if(QDELETED(src) || dying || stat == DEAD)
		return
	say(pick(spawn_lines))

// ---------- Shield: flat subtraction + HP clamp ----------

/// Pulled from the friendly NPC's adjustHealth shield (eric_t.dm:791). Both
/// phase transitions clamp damage at the threshold and trigger the cutscene.
/mob/living/simple_animal/hostile/greed_touched_eric/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && amount > 0 && stat != DEAD && !dying)
		// Flat shield first.
		amount = max(0, amount - blood_resistance)
		if(amount == 0)
			new /obj/effect/temp_visual/blood_shield(loc)
			if(last_shielded_say < world.time - say_cooldown)
				say(shielded_line)
				last_shielded_say = world.time
			return 0
		// Phase-2 HP floor.
		if(!phase_2_triggered && (health - amount) <= phase_2_trigger_hp)
			amount = max(0, health - phase_2_trigger_hp)
			. = ..(amount, updating_health, forced)
			EnterPhase2()
			return
		// Phase-3 HP floor.
		if(!phase_3_triggered && (health - amount) <= phase_3_trigger_hp)
			amount = max(0, health - phase_3_trigger_hp)
			. = ..(amount, updating_health, forced)
			EnterPhase3()
			return
	return ..(amount, updating_health, forced)

/// Linear: pool 0 → 0 resistance, pool blood_cap → blood_resistance_cap.
/// Forced to 0 while a burst window is locked.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/RecomputeShield()
	if(world.time < shield_locked_until || phase == ERIC_PHASE_3)
		blood_resistance = 0
		return
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(!C || !blood_cap)
		blood_resistance = 0
		return
	var/ratio = clamp(C.blood_amount / blood_cap, 0, 1)
	blood_resistance = round(blood_resistance_cap * ratio)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/ShieldLocked()
	return world.time < shield_locked_until

/// Direct deposit from a dying summon. Wrapped so passive component absorbs
/// (which also call AdjustBlood) still trip the recompute via Life().
/mob/living/simple_animal/hostile/greed_touched_eric/proc/AdjustEricBlood(amount)
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(!C)
		return
	C.AdjustBlood(amount)
	RecomputeShield()

// ---------- Pure-summoner AI ----------

/mob/living/simple_animal/hostile/greed_touched_eric/handle_automated_action()
	if(!can_act || stat == DEAD || dying)
		return
	// Slow pursuit to ~1 tile from target — base AI handles target-find +
	// walk_to. Melee = 0 and AttackingTarget no-ops, so chasing-to-adjacent
	// never deals damage; the threat is Sanguine Feast and Greed Burst.
	. = ..()
	if(phase == ERIC_PHASE_3)
		// Whichever P3 ability is off cooldown first; they alternate naturally.
		if(world.time >= hardblood_cooldown)
			INVOKE_ASYNC(src, PROC_REF(HardbloodStrike))
		else if(world.time >= sanguine_rush_cooldown)
			INVOKE_ASYNC(src, PROC_REF(SanguineRush))
		return
	if(ShieldLocked())
		return
	// Sanguine Feast preempts a normal wave when off-cooldown and a human is in view.
	if(world.time >= sanguine_feast_cooldown && SanguineHasTargets())
		INVOKE_ASYNC(src, PROC_REF(SanguineFeast))
		return
	if(world.time >= summon_cooldown)
		SummonWave()

/mob/living/simple_animal/hostile/greed_touched_eric/Life()
	. = ..()
	if(stat == DEAD || dying)
		return
	// Drop dead/qdel'd summons before the burst-trigger checks them.
	for(var/mob/M in summoned_mobs)
		if(QDELETED(M) || M.stat == DEAD)
			summoned_mobs -= M
	RecomputeShield()
	// Auto-trigger Greed Burst on full pool.
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(C && C.blood_amount >= C.blood_cap && !ShieldLocked() && phase != ERIC_PHASE_3)
		INVOKE_ASYNC(src, PROC_REF(GreedBurst))

/mob/living/simple_animal/hostile/greed_touched_eric/AttackingTarget(atom/attacked_target)
	// Pure summoner in P1/P2 — let the parent run only in P3, where
	// melee_damage was bumped and he closes the distance properly.
	if(phase != ERIC_PHASE_3)
		return
	return ..()

/mob/living/simple_animal/hostile/greed_touched_eric/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

// ---------- Wave summon ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/GetWavePool()
	// Phase 1: X-Corp swarm (lighter, faster). Phase 2: greed-touched roster
	// (heavier, deadlier). All paths are /refracted variants tuned for the
	// boss; see the bottom of this file.
	if(phase >= ERIC_PHASE_2)
		return list(
			/mob/living/simple_animal/hostile/clan/scout/greed/refracted         = 25,
			/mob/living/simple_animal/hostile/clan/drone/greed/refracted         = 20,
			/mob/living/simple_animal/hostile/clan/defender/greed/refracted      = 15,
			/mob/living/simple_animal/hostile/clan/ranged/sniper/greed/refracted = 15,
			/mob/living/simple_animal/hostile/clan/ranged/gunner/greed/refracted = 15,
			/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed/refracted = 10,
		)
	return list(
		/mob/living/simple_animal/hostile/xcorp/dps/refracted    = 35,
		/mob/living/simple_animal/hostile/xcorp/scout/refracted  = 25,
		/mob/living/simple_animal/hostile/xcorp/sapper/refracted = 20,
		/mob/living/simple_animal/hostile/xcorp/tank/refracted   = 20,
	)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/SummonWave()
	if(!can_act || dying || stat == DEAD || phase == ERIC_PHASE_3)
		return
	// Anti-stall: if no summon has died in stall_grace_time, double the size.
	var/count = summons_per_wave
	if(world.time - last_minion_death_time >= stall_grace_time)
		count *= 2
	count = min(count, max_summons - length(summoned_mobs))
	if(count <= 0)
		summon_cooldown = world.time + summon_cooldown_time
		return
	var/list/pool = GetWavePool()
	var/list/valid_turfs = list()
	for(var/turf/T in orange(3, src))
		if(T.density)
			continue
		if(locate(/mob/living) in T)
			continue
		valid_turfs += T
	if(!length(valid_turfs))
		summon_cooldown = world.time + summon_cooldown_time
		return
	var/spawned = 0
	for(var/i in 1 to count)
		if(!length(valid_turfs))
			break
		var/mob_type = pickweight(pool)
		if(!mob_type)
			break
		var/turf/T = pick(valid_turfs)
		valid_turfs -= T
		new /obj/effect/temp_visual/dir_setting/cult/phase(T)
		playsound(T, 'sound/effects/curse4.ogg', 40, TRUE)
		var/mob/living/simple_animal/hostile/M = new mob_type(T)
		M.faction = faction.Copy()
		summoned_mobs += M
		RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(OnSummonDeath))
		RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(OnSummonQdel))
		spawned++
	if(spawned > 0)
		visible_message(span_warning("[src] calls forth [spawned] greed-touched follower\s!"))
		manual_emote("raises a bloody hand, calling more of the flock to the harvest.")
	summon_cooldown = world.time + summon_cooldown_time

// Beam + fade-out + bloodfeed: the dying summon's life-thread arcs back to Eric.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/OnSummonDeath(mob/living/simple_animal/hostile/source)
	SIGNAL_HANDLER
	if(QDELETED(source))
		return
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	summoned_mobs -= source
	last_minion_death_time = world.time
	// Stop the mob's death() from auto-qdel'ing before the fade completes.
	// (del_on_death lives on /mob/living/simple_animal/hostile, not /mob/living.)
	source.del_on_death = FALSE
	INVOKE_ASYNC(src, PROC_REF(DrainSummon), source)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/OnSummonQdel(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	summoned_mobs -= source

/mob/living/simple_animal/hostile/greed_touched_eric/proc/DrainSummon(mob/living/M)
	if(QDELETED(M) || QDELETED(src))
		return
	var/turf/corpse_turf = get_turf(M)
	if(!corpse_turf)
		qdel(M)
		return
	var/datum/beam/B = M.Beam(src, icon_state = "tentacle", time = 1 SECONDS)
	if(B)
		B.visuals.color = "#aa0000"
	playsound(corpse_turf, 'sound/abnormalities/nosferatu/bloodcollect.ogg', 50, TRUE)
	new /obj/effect/temp_visual/cult/sparks(corpse_turf)
	// Blood payout scales with the summon's HP pool — heavies are worth chasing.
	// /3 paces the fight to ~2 bursts per cleared "light wave" cycle in P1.
	var/blood_value = round(max(1, M.maxHealth / 3))
	// Bloodbags pay double (Phase 2's priority kill).
	if(istype(M, /mob/living/simple_animal/hostile/humanoid/blood/bag))
		blood_value *= 2
	AdjustEricBlood(blood_value)
	// Drop a fresh blood decal so the bloodfeast component's passive scan has
	// something to chew on while the corpse fades.
	if(!locate(/obj/effect/decal/cleanable/blood) in corpse_turf)
		var/obj/effect/decal/cleanable/blood/BD = new(corpse_turf)
		BD.bloodiness = 100
	animate(M, alpha = 0, time = 1 SECONDS)
	QDEL_IN(M, 1 SECONDS)

// ---------- Greed Burst ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/GreedBurst()
	if(!can_act || dying || stat == DEAD || phase == ERIC_PHASE_3)
		return
	can_act = FALSE
	walk(src, 0)
	say(pick(burst_lines))
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack_special.ogg', 80, TRUE, 6)
	// 2s telegraph: ring of warning tiles in view(8) and Eric jitters.
	for(var/turf/T in view(8, src))
		new /obj/effect/temp_visual/greed_burst_warning(T)
	var/end_telegraph = world.time + burst_telegraph_time
	while(world.time < end_telegraph)
		if(dying || stat == DEAD)
			can_act = TRUE
			return
		do_jitter_animation(300)
		sleep(5)
	if(dying || stat == DEAD)
		can_act = TRUE
		return
	// Detonation: room-wide RED pulse on players + sacrifice all live summons.
	playsound(get_turf(src), 'sound/effects/explosion1.ogg', 100, FALSE, 8)
	var/burst_damage = glutted ? burst_player_damage * 2 : burst_player_damage
	for(var/mob/living/L in view(8, src))
		if(L == src || faction_check_mob(L))
			continue
		L.deal_damage(burst_damage, RED_DAMAGE, src,
			attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		L.apply_lc_bleed(2)
	// Iterate over a snapshot — M.death() fires OnSummonDeath, which mutates summoned_mobs.
	for(var/mob/living/M in summoned_mobs.Copy())
		if(QDELETED(M) || M.stat == DEAD)
			continue
		var/turf/MT = get_turf(M)
		if(MT)
			for(var/turf/T in range(1, MT))
				new /obj/effect/temp_visual/greed_minion_burst(T)
				for(var/mob/living/L in T)
					if(L == src || L == M || faction_check_mob(L))
						continue
					L.deal_damage(burst_minion_damage, RED_DAMAGE, src,
						attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
					L.apply_lc_bleed(burst_minion_bleed)
		// Routes through OnSummonDeath → DrainSummon, so each sacrificed
		// minion still beams its blood back into Eric before fading.
		M.death()
	// Glutted check: did Eric take HP damage since the last burst? If not,
	// flag for double-damage on the NEXT burst. Resets when he takes a hit.
	if(health >= hp_at_last_burst)
		bursts_without_damage++
		if(bursts_without_damage >= 2)
			glutted = TRUE
	else
		bursts_without_damage = 0
		glutted = FALSE
	hp_at_last_burst = health
	// Aftermath: pool drained, shield locked off, summon timer reset.
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(C)
		C.blood_amount = 0
	shield_locked_until = world.time + burst_window_time
	blood_resistance = 0
	icon_state = exhausted_state
	manual_emote("stands quietly, the Heart's hunger temporarily slaked...")
	sleep(burst_window_time)
	if(dying || stat == DEAD)
		return
	icon_state = (phase == ERIC_PHASE_3) ? hardblood_state : normal_state
	// Brief breath before resuming summons so the window doesn't bleed into a wave.
	summon_cooldown = world.time + 3 SECONDS
	can_act = TRUE
	RecomputeShield()

// ---------- Sanguine Feast ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineHasTargets()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(QDELETED(H) || H.stat == DEAD)
			continue
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineFeast()
	if(!can_act || dying || stat == DEAD)
		return
	can_act = FALSE
	walk(src, 0)
	say("Settle down, children. The Heart wants a sample. All of it.")
	visible_message(span_userdanger("[src] reaches both hands toward the marked tiles, channeling a feast of blood!"))
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack_special.ogg', 60, TRUE, 6)
	var/spawned = 0
	for(var/mob/living/carbon/human/H in view(7, src))
		if(QDELETED(H) || H.stat == DEAD)
			continue
		var/turf/T = get_turf(H)
		if(!T)
			continue
		var/obj/effect/temp_visual/sanguine_marker/M = new(T, src)
		M.damage = sanguine_feast_damage
		M.execute_threshold = sanguine_feast_execute_threshold
		spawned++
	if(spawned == 0)
		// No humans landed under the cast — short retry cooldown.
		can_act = TRUE
		sanguine_feast_cooldown = world.time + 5 SECONDS
		return
	// Lock-in lasts only through the marker's Blowup tick; the visual lingers
	// another ~1.4s as afterglow but Eric is free to resume his loop.
	sleep(sanguine_feast_charge_time)
	if(!QDELETED(src) && stat != DEAD)
		can_act = TRUE
	sanguine_feast_cooldown = world.time + sanguine_feast_cooldown_time

// ---------- Phase 2: The Famine ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/EnterPhase2()
	if(phase_2_triggered || dying || stat == DEAD)
		return
	phase_2_triggered = TRUE
	phase = ERIC_PHASE_2
	INVOKE_ASYNC(src, PROC_REF(PlayPhase2Cutscene))

/mob/living/simple_animal/hostile/greed_touched_eric/proc/PlayPhase2Cutscene()
	if(dying || stat == DEAD)
		return
	can_act = FALSE
	walk(src, 0)
	say(pick(phase_2_lines))
	visible_message(span_userdanger("[src] presses both hands to his chest — the Heart of Greed beats faster, hungrier."))
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	var/end_time = world.time + 3 SECONDS
	while(world.time < end_time)
		if(dying || stat == DEAD)
			ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2))
			return
		do_jitter_animation(300)
		sleep(5)
	ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2))
	// Smaller bloodfeast cap = bursts come faster. Summon cadence and burst
	// window are intentionally unchanged — the swarm flow is the fun part,
	// and the roster swap (X-Corp → greed-touched) is the real escalation.
	// Cap scaled proportionally to P1's 700 (~5/7), still leaves headroom
	// for Sanguine Feast's execute bonuses.
	blood_cap = 500
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(C)
		C.blood_cap = 500
	can_act = TRUE
	RecomputeShield()

// ---------- Phase 3: Hardblood Greed ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/EnterPhase3()
	if(phase_3_triggered || dying || stat == DEAD)
		return
	phase_3_triggered = TRUE
	phase = ERIC_PHASE_3
	INVOKE_ASYNC(src, PROC_REF(PlayPhase3Cutscene))

/mob/living/simple_animal/hostile/greed_touched_eric/proc/PlayPhase3Cutscene()
	if(dying || stat == DEAD)
		return
	can_act = FALSE
	walk(src, 0)
	say(pick(phase_3_lines))
	visible_message(span_userdanger("[src] tears open his own chest and drinks straight from the Heart of Greed — the herd is forgotten!"))
	// Reclaim every summon's life-thread at once — visual closure on the wave loop.
	// Iterate over a snapshot; M.death() fires OnSummonDeath which mutates summoned_mobs.
	for(var/mob/living/M in summoned_mobs.Copy())
		if(QDELETED(M) || M.stat == DEAD)
			continue
		M.death()
	summoned_mobs.Cut()
	icon_state = hardblood_state
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack_special.ogg', 100, FALSE, 10)
	var/end_time = world.time + 3 SECONDS
	while(world.time < end_time)
		if(dying || stat == DEAD)
			return
		do_jitter_animation(300)
		sleep(5)
	// Permanent shield collapse: pool is unused now, shield stays at 0.
	blood_resistance = 0
	shield_locked_until = 0
	// P3 melee — drops the pure-summoner restriction. Adjacency hurts now.
	melee_damage_lower = 25
	melee_damage_upper = 35
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "rakes"
	attack_verb_simple = "rake"
	attack_sound = 'sound/abnormalities/nosferatu/attack.ogg'
	// Faster pursuit — the slow-stalker tempo was P1/P2; P3 he closes hard.
	move_to_delay = 6
	hardblood_cooldown = world.time + 4 SECONDS
	// Sanguine Rush opens slightly later so Hardblood lands first in P3.
	sanguine_rush_cooldown = world.time + 9 SECONDS
	can_act = TRUE

// Three teleport-strikes on the chosen target — simplified Hardblood Arts.
// Mirrors the bloodfiend boss's Leap from lc13_blood_fiend.dm:215 —
// three direction sparkles around the target (1s each), then three
// dash-strikes from those same directions with interstitial Eric-voice
// lines. Skips the cutter-weakness mechanic (P3 has no shield to gate).
/mob/living/simple_animal/hostile/greed_touched_eric/proc/HardbloodStrike()
	if(!can_act || dying || stat == DEAD)
		return
	var/mob/living/L = FindNearestEnemy()
	if(!L)
		hardblood_cooldown = world.time + 2 SECONDS
		return
	can_act = FALSE
	walk(src, 0)
	say("Hardblood arts. You children needed correcting.")
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_clash.ogg', 70, FALSE, 6)
	// Phase 1 of the bloodfiend pattern: drop 3 bloodsparkles around the
	// target, one per landing direction, 1s apart. Players see the bracket
	// forming before any strike lands.
	var/list/dirs_to_land = shuffle(list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
	var/list/dir_overlays = list()
	for(var/i in 1 to 3)
		if(QDELETED(L) || L.stat == DEAD || dying || stat == DEAD)
			break
		var/x
		var/y
		switch(dirs_to_land[i])
			if(NORTH)
				x = 0
				y = 32
			if(SOUTH)
				x = 0
				y = -32
			if(EAST)
				x = 32
				y = 0
			if(WEST)
				x = -32
				y = 0
			if(NORTHEAST)
				x = 32
				y = 32
			if(NORTHWEST)
				x = -32
				y = 32
			if(SOUTHEAST)
				x = 32
				y = -32
			if(SOUTHWEST)
				x = -32
				y = -32
		var/image/O = image(icon = 'icons/effects/cult_effects.dmi', icon_state = "bloodsparkles", pixel_x = x, pixel_y = y)
		L.add_overlay(O)
		dir_overlays.Add(O)
		playsound(L, 'ModularLobotomy/_Lobotomysounds/claw/eviscerate1.ogg', 80, TRUE)
		if(stat == DEAD)
			break
		sleep(1 SECONDS)
	if(dying || stat == DEAD)
		for(var/image/O in dir_overlays)
			L.cut_overlay(O)
		can_act = TRUE
		return
	say("Heart's snare! Be still, children!")
	// Phase 2: clear each sparkle as Eric teleports to that direction and
	// strikes from it. Interstitial lines mimic "Just..." / "ROT AWAY!!!".
	for(var/i in 1 to 3)
		if(i > length(dir_overlays))
			break
		L.cut_overlay(dir_overlays[i])
		if(QDELETED(L) || L.stat == DEAD || dying || stat == DEAD)
			continue
		var/turf/target_turf = get_step(get_turf(L), dirs_to_land[i])
		if(target_turf && !target_turf.density)
			forceMove(target_turf)
		face_atom(L)
		do_attack_animation(L)
		playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack.ogg', 70, FALSE, 4)
		if(i == 2)
			say("Settle down...")
		if(i == 3)
			say("REPENT, CHILDREN!")
		L.deal_damage(hardblood_strike_damage, RED_DAMAGE, src,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		L.apply_lc_bleed(3)
		L.Knockdown(hardblood_knockdown_time)
		new /obj/effect/decal/cleanable/blood/splatter(get_turf(L))
		// 1s gap lets a careful player step away before the next direction lands.
		sleep(1 SECONDS)
	hardblood_cooldown = world.time + hardblood_cooldown_time
	can_act = TRUE

// Three back-to-back dashes along a 3x3 strip. Same shape as the flame
// fixer's TripleDash (lc13_humanoids.dm:596), but blood splatters instead
// of mech_fire and a Wolf_Scratch claw-sound on every step.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineRush()
	if(!can_act || stat == DEAD || dying)
		return
	var/mob/living/L = FindNearestEnemy()
	if(!L)
		sanguine_rush_cooldown = world.time + 3 SECONDS
		return
	can_act = FALSE
	walk(src, 0)
	say("I told you to behave! Coming for it, children!")
	playsound(get_turf(src), 'sound/abnormalities/big_wolf/Wolf_Scratch.ogg', 80, FALSE, 6)
	visible_message(span_userdanger("[src] hunches forward, claws weeping crimson — about to rush!"))
	SLEEP_CHECK_DEATH(2 SECONDS)
	// Short tell so the very first dash isn't a surprise opener — players
	// catch the cue and can sidestep before the strip lands.
	if(!dying && stat != DEAD)
		say("BEHOLD, CHILDREN!")
	for(var/i in 1 to 3)
		if(QDELETED(L) || L.stat == DEAD || dying || stat == DEAD)
			break
		SanguineRushDash(L)
	sanguine_rush_cooldown = world.time + sanguine_rush_cooldown_time
	if(!dying && stat != DEAD)
		can_act = TRUE

/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineRushDash(atom/dash_target)
	if(QDELETED(dash_target) || dying || stat == DEAD)
		return
	var/list/hit_mobs = list()
	if(!do_after(src, 0.5 SECONDS, target = src))
		return
	var/turf/wallcheck = get_turf(src)
	var/enemy_direction = get_dir(src, get_turf(dash_target))
	for(var/i = 0 to sanguine_rush_dash_range)
		if(get_turf(src) != wallcheck || stat == DEAD)
			break
		wallcheck = get_step(src, enemy_direction)
		if(!ClearSky(wallcheck))
			break
		sleep(0.5)
		forceMove(wallcheck)
		playsound(wallcheck, 'sound/abnormalities/big_wolf/Wolf_Scratch.ogg', 50, FALSE, 4)
		for(var/turf/T in orange(get_turf(src), 1))
			if(isclosedturf(T))
				continue
			new /obj/effect/disappearing_bloodsplatter(T)
			for(var/mob/living/M in T)
				if(M == src || faction_check_mob(M) || (M in hit_mobs))
					continue
				M.deal_damage(sanguine_rush_dash_damage, RED_DAMAGE, src,
					attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				M.apply_lc_bleed(sanguine_rush_dash_bleed)
				LAZYADD(hit_mobs, M)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/FindNearestEnemy()
	var/mob/living/best
	var/best_dist = INFINITY
	for(var/mob/living/L in view(10, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		var/d = get_dist(src, L)
		if(d < best_dist)
			best_dist = d
			best = L
	return best

// ---------- Death ----------

/mob/living/simple_animal/hostile/greed_touched_eric/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
	// Kill all summons so the wave doesn't outlive the boss.
	// Iterate over a snapshot; M.death() fires OnSummonDeath which mutates summoned_mobs.
	for(var/mob/living/M in summoned_mobs.Copy())
		if(QDELETED(M) || M.stat == DEAD)
			continue
		M.visible_message(span_warning("[M] collapses as Eric's hold breaks!"))
		M.death()
	summoned_mobs.Cut()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Refracted summon variants ----------
// Boss-only tuning for a single 50-DPS / 200-HP / 50%-DR player baseline.
// Melee stays low (unavoidable chip); special/projectile/AoE behaviors
// inherit from the base mob since the player can telegraph-dodge them.

// ---- Greed-touched ----

/mob/living/simple_animal/hostile/clan/scout/greed/refracted
	maxHealth = 180
	health = 180
	melee_damage_lower = 5
	melee_damage_upper = 8

/mob/living/simple_animal/hostile/clan/drone/greed/refracted
	maxHealth = 280
	health = 280
	melee_damage_lower = 4
	melee_damage_upper = 6

/mob/living/simple_animal/hostile/clan/defender/greed/refracted
	maxHealth = 550
	health = 550
	melee_damage_lower = 8
	melee_damage_upper = 12

/mob/living/simple_animal/hostile/clan/ranged/sniper/greed/refracted
	maxHealth = 250
	health = 250
	melee_damage_lower = 4
	melee_damage_upper = 7

/mob/living/simple_animal/hostile/clan/ranged/gunner/greed/refracted
	maxHealth = 320
	health = 320
	melee_damage_lower = 5
	melee_damage_upper = 8

/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed/refracted
	maxHealth = 380
	health = 380
	melee_damage_lower = 6
	melee_damage_upper = 10

// ---- X-Corp ----

/mob/living/simple_animal/hostile/xcorp/dps/refracted
	maxHealth = 130
	health = 130
	melee_damage_lower = 5
	melee_damage_upper = 8

/mob/living/simple_animal/hostile/xcorp/scout/refracted
	maxHealth = 180
	health = 180
	melee_damage_lower = 4
	melee_damage_upper = 7

/mob/living/simple_animal/hostile/xcorp/sapper/refracted
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	// Scream goes off at random Life ticks; 10 raw = 5 effective. Without
	// this cap the inherited 20 spikes too hard against 200-HP players.
	scream_damage = 10

/mob/living/simple_animal/hostile/xcorp/tank/refracted
	maxHealth = 420
	health = 420
	melee_damage_lower = 7
	melee_damage_upper = 11

#undef ERIC_PHASE_1
#undef ERIC_PHASE_2
#undef ERIC_PHASE_3
