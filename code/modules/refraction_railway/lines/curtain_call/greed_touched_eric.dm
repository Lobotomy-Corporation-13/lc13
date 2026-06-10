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
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#aa0000"
	light_range = 2
	duration = 20

/obj/effect/temp_visual/greed_minion_burst
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
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
		if(!ishuman(L))
			continue
		L.deal_damage(damage, RED_DAMAGE, source,
			attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		L.apply_lc_bleed(3)
	for(var/turf/scan_tile in range(1, T))
		for(var/mob/living/L in scan_tile)
			if(L == source || ishuman(L) || L.stat == DEAD)
				continue
			if(L.maxHealth >= execute_threshold)
				continue
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
	// Cap is high enough to absorb Sanguine Feast's execution bonuses (each
	// executed mob feeds maxHealth/2 blood — multiple executes can dump
	// 300+ extra in one feast).
	var/blood_cap            = 700
	var/blood_visual_threshold = 350
	/// Shield is forced to 0 until this timestamp regardless of pool refill.
	var/shield_locked_until = 0
	/// Gate so a chip-swing storm only triggers one panic-wave per 1.5s.
	var/shield_summon_cooldown = 0
	var/shield_summon_cooldown_time = 1.5 SECONDS
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
	/// Total RED damage pool for the burst — split evenly across every mob
	/// caught in view(5) at detonation, summons included. Alone the pulse
	/// is nearly lethal; in a full swarm the followers soak most of it.
	var/burst_total_damage   = 200
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
	// 45 raw per unsafe tile = ~22 effective post-DR.
	var/hardblood_strike_damage = 45
	/// Deciseconds the 5x5 mist holds before unsafe tiles deal damage.
	/// Matches the bloodboss dash's `do_after(15)` window.
	var/mist_telegraph_time = 15
	/// One sparkle overlay floats above the target per pending strike — the
	/// number of sparkles drives the loop, and each pulse consumes one.
	var/hardblood_strike_count = 3

	// ---- P3 blood-cost economy ----
	/// Pool spent each time HardbloodStrike fires.
	var/hardblood_cost = 60
	/// Pool spent each time SanguineRush fires.
	var/sanguine_rush_cost = 40
	/// Pool spent per Teleport().
	var/teleport_cost = 10
	/// Tracked so Life() can toggle the stagger visual when CC lands/expires.
	var/mutable_appearance/stagger_overlay

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
	var/sanguine_feast_cooldown_time = 15 SECONDS
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
	/// Phase-3 lines when Sana is the one bleeding him out. The preacher
	/// cracks into a desperate plea, still certain he is curing her.
	var/list/phase_3_lines_sana = list(
		"Why do you FIGHT me, Sana?! I only want to end your thirst!",
		"Stop this! The Heart is the CURE - let me GIVE it to you!",
	)
	var/list/death_lines = list(
		"...the herd... was almost... mine...",
		"...the Heart... was supposed to... fill me...",
		"...kids these days... never knew... their place...",
	)
	// ---- Refraction Railway recognition ----
	/// Character this boss recognizes among the railway party, matched as a
	/// case-insensitive substring of a member's mob name. Empty = no one.
	var/recognition_target_name = "Sana Valkyrie"
	/// Two-part recognition line, said at the start of combat when matched.
	var/recognition_line_1 = "Sana Valkyrie — you of all souls KNOW the thirst. Why do you still turn from the Heart?"
	var/recognition_line_2 = "It is the CURE, child — an end to the hunger. Why raise a blade at your own salvation?"
	/// Said as Eric fades on death (replaces his normal death line when Sana
	/// is the one who puts him down).
	var/boss_final_line = "...I only... wanted to end your hunger... why wouldn't you... let me, Sana..."
	/// Once-guard so recognition is attempted a single time per fight.
	var/recognition_attempted = FALSE
	/// TRUE once a party member was actually recognized this fight; makes the
	/// death sequence speak only the final recognition line.
	var/recognized = FALSE
	/// While TRUE the recognition sequence (both halves + 3s after) owns
	/// Eric's voice; every other line is dropped. Sanctioned lines pass via
	/// recognition_bypass.
	var/recognition_locked = FALSE
	var/recognition_bypass = FALSE

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
	addtimer(CALLBACK(src, PROC_REF(TryRecognition)), 1.5 SECONDS)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/Greet()
	if(QDELETED(src) || dying || stat == DEAD)
		return
	say(pick(spawn_lines))

// ---------- Refraction Railway recognition ----------

/// Recognition + death lines bypass the lock; every other line is dropped
/// while the recognition sequence holds Eric's voice.
/mob/living/simple_animal/hostile/greed_touched_eric/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(recognition_locked && !recognition_bypass)
		return
	return ..()

/// Says a framework-sanctioned line past the recognition lock.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SpeakRecognition(message)
	if(!message)
		return
	recognition_bypass = TRUE
	say(message)
	recognition_bypass = FALSE

/// Start of combat: if a railway party member's mob name contains
/// recognition_target_name, play the two-part recognition line and hold the
/// speech lock through both parts plus 3 seconds.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/TryRecognition()
	if(recognition_attempted || stat == DEAD || dying)
		return
	recognition_attempted = TRUE
	if(!recognition_target_name)
		return
	var/datum/refraction_run/R = FindRefractionRunForZ(z)
	if(!R)
		return
	var/found = FALSE
	for(var/mob/M as anything in R.members)
		if(QDELETED(M))
			continue
		var/their_name = M.real_name || M.name
		if(their_name && findtext(their_name, recognition_target_name))
			found = TRUE
			break
	if(!found)
		return
	recognized = TRUE
	recognition_locked = TRUE
	SpeakRecognition(recognition_line_1)
	addtimer(CALLBACK(src, PROC_REF(RecognitionPart2)), 2 SECONDS)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/RecognitionPart2()
	if(QDELETED(src) || stat == DEAD || dying)
		recognition_locked = FALSE
		return
	SpeakRecognition(recognition_line_2)
	addtimer(CALLBACK(src, PROC_REF(EndRecognitionLock)), 3 SECONDS)

/mob/living/simple_animal/hostile/greed_touched_eric/proc/EndRecognitionLock()
	recognition_locked = FALSE

// ---------- Shield: flat subtraction + HP clamp ----------

/// Pulled from the friendly NPC's adjustHealth shield (eric_t.dm:791). Both
/// phase transitions clamp damage at the threshold and trigger the cutscene.
/mob/living/simple_animal/hostile/greed_touched_eric/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && amount > 0 && stat != DEAD && !dying)
		amount = max(0, amount - blood_resistance)
		if(amount == 0)
			new /obj/effect/temp_visual/blood_shield(loc)
			if(last_shielded_say < world.time - say_cooldown)
				say(shielded_line)
				last_shielded_say = world.time
			if(phase != ERIC_PHASE_3 && world.time >= shield_summon_cooldown && !ShieldLocked())
				shield_summon_cooldown = world.time + shield_summon_cooldown_time
				INVOKE_ASYNC(src, PROC_REF(SummonWave))
			return 0
		if(!phase_2_triggered && (health - amount) <= phase_2_trigger_hp)
			amount = max(0, health - phase_2_trigger_hp)
			. = ..(amount, updating_health, forced)
			EnterPhase2()
			return
		if(!phase_3_triggered && (health - amount) <= phase_3_trigger_hp)
			amount = max(0, health - phase_3_trigger_hp)
			. = ..(amount, updating_health, forced)
			EnterPhase3()
			return
	return ..(amount, updating_health, forced)

/// Inverse: shield = round((blood_cap - blood_amount) / 4). Peak at an empty
/// pool, zero at a full one. Forced to 0 in P3 and during the post-burst window.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/RecomputeShield()
	if(world.time < shield_locked_until || phase == ERIC_PHASE_3)
		blood_resistance = 0
		return
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(!C || !blood_cap)
		blood_resistance = 0
		return
	var/missing = max(0, blood_cap - C.blood_amount)
	blood_resistance = round(missing / 4)

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

/// Single source of truth for every boss teleport: phase-out VFX at the
/// origin, phase-in VFX at the destination, blood-exit playsound, and the
/// P3 teleport_cost paid out of the pool.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/Teleport(turf/dest)
	if(!dest || QDELETED(src) || stat == DEAD || dying)
		return
	var/turf/origin = get_turf(src)
	if(origin)
		new /obj/effect/temp_visual/dir_setting/cult/phase/out(origin, dir)
	forceMove(dest)
	new /obj/effect/temp_visual/dir_setting/cult/phase(dest, dir)
	playsound(src, 'sound/magic/exit_blood.ogg', 100, FALSE, 4)
	if(phase == ERIC_PHASE_3 && teleport_cost > 0)
		SpendBlood(teleport_cost)

/// Try to spend `amount` from the bloodfeast pool. Insufficient pool ->
/// pool zeroes and Eric eats round(amount / 2) self-damage (forced past the
/// shield).
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SpendBlood(amount)
	if(amount <= 0 || stat == DEAD || dying)
		return
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(!C)
		return
	if(C.blood_amount >= amount)
		C.AdjustBlood(-amount)
		RecomputeShield()
		return
	C.blood_amount = 0
	RecomputeShield()
	var/self_damage = round(amount / 2)
	visible_message(span_warning("[src] tears at himself to fuel the Heart — wounds re-open for [self_damage]!"))
	adjustHealth(self_damage, forced = TRUE)

/// Show the stagger overlay any tick the boss is stunned/knocked/paralyzed
/// and hide it once the CC clears.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/UpdateStaggerOverlay()
	var/should_stagger = (stat != DEAD) && !dying && (IsStun() || IsKnockdown() || IsParalyzed())
	if(should_stagger && !stagger_overlay)
		stagger_overlay = mutable_appearance(icon, "small_stagger", layer + 0.1)
		add_overlay(stagger_overlay)
	else if(!should_stagger && stagger_overlay)
		cut_overlay(stagger_overlay)
		stagger_overlay = null

// ---------- Pure-summoner AI ----------

/mob/living/simple_animal/hostile/greed_touched_eric/handle_automated_action()
	if(!can_act || stat == DEAD || dying)
		return
	if(phase == ERIC_PHASE_3)
		if(world.time >= hardblood_cooldown)
			can_act = FALSE
			walk(src, 0)
			INVOKE_ASYNC(src, PROC_REF(HardbloodStrike))
			return
		if(world.time >= sanguine_rush_cooldown)
			can_act = FALSE
			walk(src, 0)
			INVOKE_ASYNC(src, PROC_REF(SanguineRush))
			return
	. = ..()
	if(phase == ERIC_PHASE_3)
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
	UpdateStaggerOverlay()
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
	if(phase != ERIC_PHASE_3)
		return
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/greed_touched_eric/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

// ---------- Wave summon ----------

/mob/living/simple_animal/hostile/greed_touched_eric/proc/GetWavePool()
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

/// Spawns a wave of greed-touched followers. Wave size and the field cap
/// both scale by +2 per human past the first in view, and stall_grace_time
/// without a minion death doubles the next wave.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SummonWave()
	if(!can_act || dying || stat == DEAD || phase == ERIC_PHASE_3)
		return
	var/humans_in_view = 0
	for(var/mob/living/carbon/human/H in view(8, src))
		if(H.stat == DEAD)
			continue
		humans_in_view++
	var/extras = max(0, (humans_in_view - 1) * 2)
	var/count = summons_per_wave + extras
	var/effective_max = max_summons + extras
	if(world.time - last_minion_death_time >= stall_grace_time)
		count *= 2
	count = min(count, effective_max - length(summoned_mobs))
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
	var/blood_value = round(max(1, M.maxHealth / 3))
	// Bloodbags pay double (Phase 2's priority kill).
	if(istype(M, /mob/living/simple_animal/hostile/humanoid/blood/bag))
		blood_value *= 2
	AdjustEricBlood(blood_value)
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
	for(var/turf/T in view(5, src))
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
	playsound(get_turf(src), 'sound/effects/explosion1.ogg', 100, FALSE, 8)
	var/total_damage = glutted ? burst_total_damage * 2 : burst_total_damage
	var/list/burst_targets = list()
	for(var/mob/living/L in view(5, src))
		if(L == src || QDELETED(L) || L.stat == DEAD)
			continue
		burst_targets += L
	if(length(burst_targets))
		var/split = round(total_damage / length(burst_targets))
		for(var/mob/living/L in burst_targets)
			L.deal_damage(split, RED_DAMAGE, src,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			if(ishuman(L))
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
		M.death()
	if(health >= hp_at_last_burst)
		bursts_without_damage++
		if(bursts_without_damage >= 2)
			glutted = TRUE
	else
		bursts_without_damage = 0
		glutted = FALSE
	hp_at_last_burst = health
	var/datum/component/bloodfeast/C = GetComponent(/datum/component/bloodfeast)
	if(C)
		C.blood_amount = 0
	shield_locked_until = world.time + burst_window_time
	blood_resistance = 0
	icon_state = exhausted_state
	visible_message(span_warning("[src] sags as the bloodfeast overflows — the Heart's hoard pours from every wound, leaving him defenseless."))
	manual_emote("buckles under the overflowing bloodfeast, the Heart's reserves spilling from his body...")
	sleep(burst_window_time)
	if(dying || stat == DEAD)
		return
	icon_state = (phase == ERIC_PHASE_3) ? hardblood_state : normal_state
	visible_message(span_userdanger("[src] shudders — the spilled bloodfeast surges back into him as the Heart re-asserts its grip!"))
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

/// Plants up to 6 sanguine_marker tendrils: humans first (one each), then
/// random open turfs in view at least 3 tiles from any prior marker.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineFeast()
	if(!can_act || dying || stat == DEAD)
		return
	can_act = FALSE
	walk(src, 0)
	say("Settle down, children. The Heart wants a sample. All of it.")
	visible_message(span_userdanger("[src] reaches both hands toward the marked tiles, channeling a feast of blood!"))
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack_special.ogg', 60, TRUE, 6)
	var/list/marker_turfs = list()
	var/marker_target = 6
	for(var/mob/living/carbon/human/H in view(7, src))
		if(length(marker_turfs) >= marker_target)
			break
		if(QDELETED(H) || H.stat == DEAD)
			continue
		var/turf/HT = get_turf(H)
		if(!HT)
			continue
		marker_turfs |= HT
	if(length(marker_turfs) < marker_target)
		var/list/candidate_turfs = list()
		for(var/turf/open/T in view(7, src))
			candidate_turfs += T
		candidate_turfs = shuffle(candidate_turfs)
		for(var/turf/picked in candidate_turfs)
			if(length(marker_turfs) >= marker_target)
				break
			var/valid = TRUE
			for(var/turf/existing in marker_turfs)
				if(get_dist(picked, existing) < 3)
					valid = FALSE
					break
			if(valid)
				marker_turfs += picked
	for(var/turf/T in marker_turfs)
		var/obj/effect/temp_visual/sanguine_marker/M = new(T, src)
		M.damage = sanguine_feast_damage
		M.execute_threshold = sanguine_feast_execute_threshold
	if(!length(marker_turfs))
		can_act = TRUE
		sanguine_feast_cooldown = world.time + 5 SECONDS
		return
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
	say(pick(recognized ? phase_3_lines_sana : phase_3_lines))
	visible_message(span_userdanger("[src] tears open his own chest and drinks straight from the Heart of Greed — the herd is forgotten!"))
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
	blood_resistance = 0
	shield_locked_until = 0
	var/datum/component/bloodfeast/PC = GetComponent(/datum/component/bloodfeast)
	if(PC)
		PC.blood_amount = round(blood_cap * 0.5)
	melee_damage_lower = 25
	melee_damage_upper = 35
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "rakes"
	attack_verb_simple = "rake"
	attack_sound = 'sound/abnormalities/nosferatu/attack.ogg'
	move_to_delay = 6
	hardblood_cooldown = world.time + 4 SECONDS
	sanguine_rush_cooldown = world.time + 9 SECONDS
	can_act = TRUE

// Mist marker attack — replicates the bloodboss dash pattern. Floats one
// sparkle above the target per pending strike, then loops once per sparkle:
// teleport adjacent, paint a 5x5 mist with the mirror-across-target tile safe,
// resolve damage, consume one sparkle. Disengage-teleports a few tiles back at
// the end of the cast.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/HardbloodStrike()
	if(dying || stat == DEAD)
		can_act = TRUE
		return
	var/mob/living/L = FindNearestEnemy()
	if(!L)
		hardblood_cooldown = world.time + 2 SECONDS
		can_act = TRUE
		return
	walk(src, 0)
	say("Hardblood arts. You children needed correcting.")
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_clash.ogg', 70, FALSE, 6)
	if(hardblood_cost > 0)
		SpendBlood(hardblood_cost)
	L.apply_status_effect(/datum/status_effect/bloodhold)
	var/list/sparkles = list()
	for(var/i in 1 to hardblood_strike_count)
		var/image/sparkle = image('icons/effects/cult_effects.dmi', L, "bloodsparkles", ABOVE_MOB_LAYER)
		sparkle.pixel_x = ((i - (hardblood_strike_count + 1) / 2) * 10)
		sparkle.pixel_y = 24
		sparkles += sparkle
		L.add_overlay(sparkle)
		addtimer(CALLBACK(L, TYPE_PROC_REF(/atom, cut_overlay), sparkle), 30 SECONDS)
	for(var/i in 1 to hardblood_strike_count)
		if(QDELETED(L) || L.stat == DEAD || dying || stat == DEAD)
			continue
		var/turf/center = get_turf(L)
		if(!center)
			continue
		var/list/teleport_candidates = list()
		for(var/turf/T in range(1, center))
			if(T == center)
				continue
			if(T.density)
				continue
			if(locate(/mob/living) in T)
				continue
			teleport_candidates += T
		var/turf/eric_pos = get_turf(src)
		if(length(teleport_candidates))
			eric_pos = pick(teleport_candidates)
			Teleport(eric_pos)
			face_atom(L)
		var/dx = clamp(eric_pos.x - center.x, -1, 1)
		var/dy = clamp(eric_pos.y - center.y, -1, 1)
		var/turf/safe_turf
		if(dx || dy)
			safe_turf = locate(center.x - dx, center.y - dy, center.z)
		if(!safe_turf || safe_turf.density)
			var/list/safe_candidates = list()
			for(var/turf/T in range(1, center))
				if(T == center)
					continue
				if(T.density)
					continue
				safe_candidates += T
			safe_turf = length(safe_candidates) ? pick(safe_candidates) : center
		for(var/turf/T in view(2, center))
			var/state = (T == safe_turf) ? "cloud_swirl" : "blood_cloud_swirl"
			var/image/mist = image('icons/effects/eldritch.dmi', T, state, CLOSED_FIREDOOR_LAYER)
			mist.plane = GAME_PLANE
			mist.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
			flick_overlay_view(mist, T, mist_telegraph_time)
		playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack.ogg', 70, FALSE, 4)
		if(i == 2)
			say("Settle down...")
		if(i >= 3)
			say("REPENT, CHILDREN!")
		SLEEP_CHECK_DEATH(mist_telegraph_time)
		for(var/turf/T in view(2, center))
			if(T == safe_turf)
				continue
			var/obj/effect/temp_visual/slice/blood = new(T)
			blood.color = "#b52e19"
			for(var/mob/living/L_hit in T)
				if(L_hit == src || faction_check_mob(L_hit))
					continue
				L_hit.deal_damage(hardblood_strike_damage, RED_DAMAGE, src,
					attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				L_hit.apply_lc_bleed(3)
		if(!QDELETED(L) && length(sparkles))
			L.cut_overlay(sparkles[1])
			sparkles.Cut(1, 2)
		SLEEP_CHECK_DEATH(1 SECONDS)
	if(!QDELETED(L) && length(sparkles))
		for(var/image/leftover in sparkles)
			L.cut_overlay(leftover)
		sparkles.Cut()
	if(!QDELETED(L) && stat != DEAD && !dying)
		var/turf/anchor = get_turf(L)
		if(anchor)
			var/list/escape_candidates = list()
			for(var/turf/T in view(6, anchor))
				if(get_dist(T, anchor) < 4)
					continue
				if(T.density)
					continue
				if(locate(/mob/living) in T)
					continue
				escape_candidates += T
			if(length(escape_candidates))
				Teleport(pick(escape_candidates))
	hardblood_cooldown = world.time + hardblood_cooldown_time
	can_act = TRUE

// Three back-to-back dashes along a 3x3 strip. Same shape as the flame
// fixer's TripleDash (lc13_humanoids.dm:596), but blood splatters instead
// of mech_fire and a Wolf_Scratch claw-sound on every step.
/mob/living/simple_animal/hostile/greed_touched_eric/proc/SanguineRush()
	if(stat == DEAD || dying)
		can_act = TRUE
		return
	var/mob/living/L = FindNearestEnemy()
	if(!L)
		sanguine_rush_cooldown = world.time + 3 SECONDS
		can_act = TRUE
		return
	walk(src, 0)
	say("I told you to behave! Coming for it, children!")
	playsound(get_turf(src), 'sound/abnormalities/big_wolf/Wolf_Scratch.ogg', 80, FALSE, 6)
	visible_message(span_userdanger("[src] hunches forward, claws weeping crimson — about to rush!"))
	if(sanguine_rush_cost > 0)
		SpendBlood(sanguine_rush_cost)
	SLEEP_CHECK_DEATH(2 SECONDS)
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

// Mirrors death's summon teardown so a hard qdel doesn't leave the wave alive without its summoner.
/mob/living/simple_animal/hostile/greed_touched_eric/Destroy()
	for(var/mob/living/M in summoned_mobs.Copy())
		if(QDELETED(M))
			continue
		UnregisterSignal(M, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		qdel(M)
	summoned_mobs.Cut()
	return ..()

/mob/living/simple_animal/hostile/greed_touched_eric/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	recognition_locked = FALSE
	if(recognized && boss_final_line)
		SpeakRecognition(boss_final_line)
	else
		say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
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
	maxHealth = 113
	health = 113
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/clan/drone/greed/refracted
	maxHealth = 175
	health = 175
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/clan/defender/greed/refracted
	maxHealth = 344
	health = 344
	melee_damage_lower = 2
	melee_damage_upper = 3

/mob/living/simple_animal/hostile/clan/ranged/sniper/greed/refracted
	maxHealth = 156
	health = 156
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/clan/ranged/gunner/greed/refracted
	maxHealth = 200
	health = 200
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed/refracted
	maxHealth = 238
	health = 238
	melee_damage_lower = 1
	melee_damage_upper = 3

// ---- X-Corp ----

/mob/living/simple_animal/hostile/xcorp/dps/refracted
	maxHealth = 81
	health = 81
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/xcorp/scout/refracted
	maxHealth = 113
	health = 113
	melee_damage_lower = 1
	melee_damage_upper = 2

/mob/living/simple_animal/hostile/xcorp/sapper/refracted
	maxHealth = 156
	health = 156
	melee_damage_lower = 1
	melee_damage_upper = 2
	// Scream goes off at random Life ticks; 10 raw = 5 effective. Without
	// this cap the inherited 20 spikes too hard against 200-HP players.
	scream_damage = 10

/mob/living/simple_animal/hostile/xcorp/tank/refracted
	maxHealth = 263
	health = 263
	melee_damage_lower = 2
	melee_damage_upper = 3

#undef ERIC_PHASE_1
#undef ERIC_PHASE_2
#undef ERIC_PHASE_3
