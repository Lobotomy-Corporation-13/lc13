/*
 * Curtain Call — zeal_s5n1 (serio_zeal_w1): Phase 1 of the Serio Zeal
 * finale boss. "Star" performs the borrowed acts of the prior 8 Curtain
 * Call bosses through translucent afterimages. The Pressure meter is the
 * only path to Phase 2 — HP damage cycles via the Railroading passive
 * (HP refills, +25% Pressure, encounter continues). See
 * serio_brainstorm.md in this directory for the full design.
 *
 * First-pass MVP: Star mob + afterimage framework + three implemented
 * subtypes (Capo Sweep, Azarus Scatter Dice, Reaper Refraction Sweep)
 * exercising the spawn-position archetypes. The other five afterimages
 * are visual stubs that dissipate without effect.
 */

// ---------- Star ----------

/mob/living/simple_animal/hostile/young_star
	name = "Serio Zeal"
	desc = "A young star on the stage, smiling brightly under the lights. \
		Something flickers behind their eyes."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "young_star"
	icon_living = "young_star"
	icon_dead = "young_star"
	faction = list("serio_zeal")
	maxHealth = 4800
	health = 4800
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "brushes past"
	attack_verb_simple = "brush past"
	attack_sound = null
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	sight = SEE_MOBS
	density = TRUE
	speed = 4
	move_to_delay = 15
	loot = list()
	butcher_results = null
	guaranteed_butcher_results = null
	silk_results = null
	/// 0–100. The only victory condition; reaching 100 kills Star, which
	/// lets the existing wave-controller see the room empty and advance.
	var/pressure = 0
	/// Live afterimages this Star has spawned and not yet dissipated.
	var/list/active_afterimages = list()
	var/main_tick_timer
	/// Set TRUE once Crack() fires so death() lets ..() through and
	/// Railroad doesn't fight it.
	var/cracking = FALSE
	// ---- Tuning knobs (per-instance vars so admins can tweak live) ----
	/// Pressure cap. Reaching it triggers Crack().
	var/pressure_max = 100
	/// Pressure gained per damage hit ≥ damage_hit_threshold.
	var/pressure_per_damage_hit = 1
	/// Pressure gained per player who dodged a cast's damage zone.
	var/pressure_per_dodge = 3
	/// Pressure gained per misfire that resolved.
	var/pressure_per_misfire = 5
	/// Pressure gained when Railroad fires (HP cycled).
	var/pressure_per_railroad = 25
	/// Minimum damage value for a hit to count toward pressure.
	var/damage_hit_threshold = 10
	/// Translucent tint applied to every afterimage at spawn.
	var/afterimage_color = "#1e61ff"
	/// Pressure values at which each tier begins (Tier 1 = under tier_2).
	var/tier_2_threshold = 34
	var/tier_3_threshold = 67
	/// Minimum gap between afterimage waves, per tier. Tighter at higher
	/// pressure. Each wave actually waits max(this, longest spawned
	/// afterimage's total_duration) so the previous wave always fully
	/// resolves before the next fires.
	var/cooldown_tier_1 = 5 SECONDS
	var/cooldown_tier_2 = 4 SECONDS
	var/cooldown_tier_3 = 3 SECONDS
	/// View range afterimages use to enumerate "players around Star".
	var/view_range = 15
	/// Shared cooldown across every misfire panic line so a Tier 3 wave's
	/// multiple misfires don't talk over each other.
	var/misfire_line_cooldown_duration = 3 SECONDS
	/// `world.time` after which the next panic line is allowed to play.
	var/misfire_line_next_time = 0
	/// Star is locked in place + tinted while a wave's longest cast resolves.
	var/summoning = FALSE
	var/saved_color
	/// Tint applied to Star during the summoning window.
	var/summon_tint = "#a0c8ff"
	/// Roster of afterimage paths Star can cast. Picked round-robin/random
	/// per wave; tier scales how many concurrent casts go out at once.
	var/static/list/attack_roster = list(
		/obj/effect/serio_afterimage/capo_sweep,
		/obj/effect/serio_afterimage/azarus_dice,
		/obj/effect/serio_afterimage/reaper_sweep,
		/obj/effect/serio_afterimage/understudy_dash,
		/obj/effect/serio_afterimage/eric_marker,
		/obj/effect/serio_afterimage/snow_eyes,
		/obj/effect/serio_afterimage/blade_volley,
		/obj/effect/serio_afterimage/achiya_bolt,
	)
	/// attack_key → tier{1,2,3} → list of panic lines. Seeded from brainstorm.
	var/list/panic_lines

/mob/living/simple_animal/hostile/young_star/Initialize(mapload)
	. = ..()
	InitPanicLines()
	UpdateHUD()
	main_tick_timer = addtimer(CALLBACK(src, PROC_REF(MainTick)), GetTierCooldown(), TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/young_star/Destroy()
	if(main_tick_timer)
		deltimer(main_tick_timer)
		main_tick_timer = null
	for(var/obj/effect/serio_afterimage/A as anything in active_afterimages)
		if(!QDELETED(A))
			qdel(A)
	active_afterimages.Cut()
	return ..()

/// Tier 1 (0–33) = 1 cast/wave; Tier 2 (34–66) = 2; Tier 3 (67–100) = 4.
/mob/living/simple_animal/hostile/young_star/proc/GetPressureTier()
	if(pressure >= tier_3_threshold)
		return 3
	if(pressure >= tier_2_threshold)
		return 2
	return 1

/mob/living/simple_animal/hostile/young_star/proc/GetTierCastCount()
	switch(GetPressureTier())
		if(3)
			return 4
		if(2)
			return 2
	return 1

/mob/living/simple_animal/hostile/young_star/proc/GetTierCooldown()
	switch(GetPressureTier())
		if(3)
			return cooldown_tier_3
		if(2)
			return cooldown_tier_2
	return cooldown_tier_1

/mob/living/simple_animal/hostile/young_star/proc/MainTick()
	main_tick_timer = null
	if(QDELETED(src) || stat == DEAD || cracking)
		return
	var/longest = 0
	for(var/i in 1 to GetTierCastCount())
		var/path = pick(attack_roster)
		var/obj/effect/serio_afterimage/AF = new path(get_turf(src), src)
		if(QDELETED(AF))
			continue
		if(AF.total_duration > longest)
			longest = AF.total_duration
	if(longest > 0)
		EnterSummoningState(longest)
	var/next_delay = max(GetTierCooldown(), longest)
	main_tick_timer = addtimer(CALLBACK(src, PROC_REF(MainTick)), next_delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/young_star/proc/EnterSummoningState(duration)
	if(summoning)
		return
	summoning = TRUE
	saved_color = color
	color = summon_tint
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, type)
	addtimer(CALLBACK(src, PROC_REF(ExitSummoningState)), duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/young_star/proc/ExitSummoningState()
	if(!summoning)
		return
	summoning = FALSE
	color = saved_color
	saved_color = null
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, type)

/mob/living/simple_animal/hostile/young_star/proc/UpdatePressure(amount, reason)
	if(cracking || stat == DEAD)
		return
	pressure = clamp(pressure + amount, 0, pressure_max)
	UpdateHUD()
	if(pressure >= pressure_max)
		Crack()

/mob/living/simple_animal/hostile/young_star/proc/UpdateHUD()
	maptext_width = 96
	maptext_height = 32
	maptext_x = -32
	maptext_y = 40
	var/p = round(pressure)
	var/color
	switch(GetPressureTier())
		if(3)
			color = "#ff5f5f"
		if(2)
			color = "#ffd86b"
		else
			color = "#cccccc"
	maptext = MAPTEXT("<font color='[color]'><b>PRESSURE [p]%</b></font>")

/mob/living/simple_animal/hostile/young_star/proc/OnPlayerDodged(mob/living/dodger)
	if(QDELETED(dodger) || dodger.stat == DEAD)
		return
	UpdatePressure(pressure_per_dodge, "dodge")

/mob/living/simple_animal/hostile/young_star/proc/OnMisfireResolved(attack_key)
	if(QDELETED(src))
		return
	SayPanicLine(attack_key, GetPressureTier())
	UpdatePressure(pressure_per_misfire, "misfire")

/mob/living/simple_animal/hostile/young_star/proc/SayPanicLine(attack_key, tier)
	if(world.time < misfire_line_next_time)
		return
	if(!islist(panic_lines))
		return
	var/list/tiers = panic_lines[attack_key]
	if(!islist(tiers))
		return
	var/list/lines = tiers["tier[tier]"]
	if(!islist(lines) || !length(lines))
		return
	misfire_line_next_time = world.time + misfire_line_cooldown_duration
	say(pick(lines))

/// Damage feedback: small pressure tick on any meaningful hit. Railroad is
/// handled in death(), not here — pressure ticks happen on every hit
/// regardless of whether HP would empty.
/mob/living/simple_animal/hostile/young_star/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	if(. >= damage_hit_threshold)
		UpdatePressure(pressure_per_damage_hit, "damage")

/// Star can't be killed by HP in Phase 1: any incoming death gets
/// railroaded into a full HP refill + +25% pressure. Once Crack() has
/// fired (pressure reached max), we let ..() through so the standard
/// death pipeline runs and the wave system handles the rest.
/mob/living/simple_animal/hostile/young_star/death(gibbed)
	if(cracking)
		return ..()
	Railroad()

/mob/living/simple_animal/hostile/young_star/proc/Railroad()
	if(cracking)
		return
	adjustBruteLoss(-maxHealth, forced = TRUE)
	visible_message(span_userdanger("[src] is yanked back into the act — the track holds the curtain up!"))
	do_sparks(8, FALSE, get_turf(src))
	UpdatePressure(pressure_per_railroad, "railroad")

/// Pressure max: play the cracking beat and inflict a lethal hit on
/// ourselves so the normal death pipeline fires. The wave-controller
/// notices the empty room and advances to wave 2 on its own.
/mob/living/simple_animal/hostile/young_star/proc/Crack()
	if(cracking)
		return
	cracking = TRUE
	visible_message(span_userdanger("[src] cracks — the stage lights stutter as the act collapses inward!"))
	do_sparks(12, FALSE, get_turf(src))
	adjustBruteLoss(maxHealth * 2, forced = TRUE)

/// Brainstorm-seeded panic lines (one or two per tier per implemented
/// attack). Stubbed attacks get a generic fallback so the table is dense.
/mob/living/simple_animal/hostile/young_star/proc/InitPanicLines()
	panic_lines = list(
		"capo_sweep" = list(
			"tier1" = list(
				"Apologies — let me try that one more cleanly.",
				"A little improvised flourish there. Moving on.",
			),
			"tier2" = list(
				"Ah — that wasn't the cue, sorry, sorry—",
				"Hold on, hold on, the timing slipped—",
			),
			"tier3" = list(
				"I-I missed my mark, I rehearsed this, I swear—!",
				"Th-that wasn't supposed to swing back, I—",
			),
		),
		"azarus_dice" = list(
			"tier1" = list(
				"How about that — synchronised dice, an unintended twist.",
				"A little structure where I'd planned chaos. Onward.",
			),
			"tier2" = list(
				"They were supposed to be different, they—",
				"Ah, that's not what the script said, sorry—",
			),
			"tier3" = list(
				"Th-they're all the same, why are they all the—!",
				"Forget what you just saw, please, forget what you—",
			),
		),
		"eric_marker" = list(
			"tier1" = list(
				"A reframed beat — the cue lands a moment late, on purpose.",
				"Patience, audience — the mark is still on its way.",
			),
			"tier2" = list(
				"Wait, that — that's coming back the wrong way—",
				"Sorry, sorry, I lost the marker—",
			),
			"tier3" = list(
				"I-I forgot to set the cue, please move—!",
				"It's going to land — it's going to land here—!",
			),
		),
		"understudy_dash" = list(
			"tier1" = list(
				"A rehearsal sketch — consider it a preview of the design.",
				"The unfinished version, presented in good faith. Onward.",
			),
			"tier2" = list(
				"It's not — it's not done, sorry, the costume—",
				"Wait, don't look at that yet—",
			),
			"tier3" = list(
				"Th-that's the placeholder, I haven't — I haven't—",
				"Don't look, please don't look at the costume—",
			),
		),
		"reaper_sweep" = list(
			"tier1" = list(
				"A little self-inflicted dramatic irony — staying in character.",
				"Note the artistic choice — turning the blade on the author.",
			),
			"tier2" = list(
				"Ah — that's me, that — ow—",
				"Wait, the direction's reversed, I—",
			),
			"tier3" = list(
				"Th-that's coming at me, it's coming — ow, ow—!",
				"I-I had the math the wrong way, agh—",
			),
		),
	)

// ---------- Afterimage base ----------

/obj/effect/serio_afterimage
	name = "afterimage"
	desc = "A translucent echo of someone Star learned to imitate."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = ""
	color = "#1e61ff"
	alpha = 110
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE
	var/mob/living/simple_animal/hostile/young_star/parent_star
	var/is_misfire = FALSE
	var/attack_key = "generic"
	/// Wall-clock time from spawn to dissipation. Read by Star's MainTick
	/// to extend the cooldown past `cast_cooldown` if the longest cast in
	/// the wave runs longer than the base 5s.
	var/total_duration = 1 SECONDS
	/// Plays at spawn (after SetupSpawn) so players hear the borrowed boss
	/// even if the afterimage is small / off-screen. null = silent.
	var/spawn_sound = null
	var/spawn_sound_volume = 55
	var/spawn_sound_extra_range = 4
	/// Telegraph visual the borrowed boss uses for this attack. Implemented
	/// subtypes spawn it directly in PerformAttack; stub subtypes carry it
	/// as documentation for the next-pass implementer.
	var/borrowed_warning_visual = null
	/// Strike visual the borrowed boss uses on impact. Same docs role.
	var/borrowed_impact_visual = null

/obj/effect/serio_afterimage/Initialize(mapload, mob/living/simple_animal/hostile/young_star/parent)
	. = ..()
	if(!istype(parent))
		return INITIALIZE_HINT_QDEL
	parent_star = parent
	parent.active_afterimages += src
	color = parent.afterimage_color
	is_misfire = parent.RollMisfire()
	SetupSpawn()
	if(spawn_sound)
		playsound(get_turf(src), spawn_sound, spawn_sound_volume, TRUE, spawn_sound_extra_range)
	INVOKE_ASYNC(src, PROC_REF(PerformAttack))

/obj/effect/serio_afterimage/Destroy()
	if(parent_star)
		parent_star.active_afterimages -= src
		parent_star = null
	return ..()

/// Subtype hook: reposition the afterimage from the default (on Star's
/// tile) to wherever this borrowed attack wants to fire from.
/obj/effect/serio_afterimage/proc/SetupSpawn()
	return

/obj/effect/serio_afterimage/proc/PerformAttack()
	sleep(1 SECONDS)
	Dissipate()

/obj/effect/serio_afterimage/proc/Dissipate()
	if(QDELETED(src))
		return
	qdel(src)

/obj/effect/serio_afterimage/proc/PickRandomPlayer()
	if(!parent_star)
		return null
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(parent_star.view_range, parent_star))
		if(H.stat == DEAD)
			continue
		candidates += H
	return length(candidates) ? pick(candidates) : null

/obj/effect/serio_afterimage/proc/PickAllPlayers()
	. = list()
	if(!parent_star)
		return
	for(var/mob/living/carbon/human/H in view(parent_star.view_range, parent_star))
		if(H.stat == DEAD)
			continue
		. += H

/mob/living/simple_animal/hostile/young_star/proc/RollMisfire()
	return prob(round(pressure * 0.7))

// ---------- Implemented: Capo Sweep ----------
// Afterimage spawns one tile in front of a random player, facing them,
// then sweeps a 3-deep cone forward. Misfire (Hitbox Desync) plays the
// visual one way but the damage cone snaps perpendicular at strike time.

/obj/effect/serio_afterimage/capo_sweep
	name = "afterimage — Capo"
	icon_state = "capo_boss"
	attack_key = "capo_sweep"
	total_duration = 1.5 SECONDS
	spawn_sound = 'sound/weapons/ego/thumb_east_podao_clash.ogg'
	spawn_sound_volume = 50
	/// capo_and_rat.dm:18 — orange sweep telegraph.
	borrowed_warning_visual = /obj/effect/temp_visual/capo_sweep_warning
	/// capo_and_rat.dm — sweep impact (also used by lunge/leap/flurry).
	borrowed_impact_visual = /obj/effect/temp_visual/thumb_east_aoe_impact

/obj/effect/serio_afterimage/capo_sweep/SetupSpawn()
	var/mob/living/carbon/human/target = PickRandomPlayer()
	if(!target)
		return
	var/turf/in_front = get_step(get_turf(target), turn(target.dir, 180))
	if(!in_front)
		in_front = get_turf(target)
	forceMove(in_front)
	setDir(get_dir(src, target))

/obj/effect/serio_afterimage/capo_sweep/PerformAttack()
	var/wind_up = is_misfire ? 0.3 SECONDS : 0.6 SECONDS
	sleep(wind_up)
	if(QDELETED(src))
		return
	// Telegraph cone in the visual direction.
	var/visual_dir = dir
	var/list/visual_turfs = BuildConeTurfs(visual_dir, 3)
	for(var/turf/T as anything in visual_turfs)
		new /obj/effect/temp_visual/capo_sweep_warning(T)
	// Misfire: damage cone snaps to a perpendicular dir at strike time.
	var/strike_dir = is_misfire ? turn(visual_dir, pick(90, -90)) : visual_dir
	sleep(0.25 SECONDS)
	if(QDELETED(src))
		return
	var/list/strike_turfs = (strike_dir == visual_dir) ? visual_turfs : BuildConeTurfs(strike_dir, 3)
	var/list/danger_humans = list()
	for(var/turf/T as anything in visual_turfs)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_boostedsweep.ogg', 70, FALSE, 5)
	var/list/hit = list()
	for(var/turf/T as anything in strike_turfs)
		new /obj/effect/temp_visual/thumb_east_aoe_impact(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(35, BLACK_DAMAGE, parent_star, attack_type = ATTACK_TYPE_SPECIAL)
			hit |= H
	for(var/mob/living/H as anything in danger_humans)
		if(!(H in hit))
			parent_star?.OnPlayerDodged(H)
	if(is_misfire && parent_star)
		parent_star.OnMisfireResolved(attack_key)
	Dissipate()

/obj/effect/serio_afterimage/capo_sweep/proc/BuildConeTurfs(facing, max_depth)
	. = list()
	var/turf/center = get_turf(src)
	for(var/depth in 1 to max_depth)
		center = get_step(center, facing)
		if(!center)
			break
		. += center
		var/turf/L = get_step(center, turn(facing, 90))
		if(L)
			. += L
		var/turf/R = get_step(center, turn(facing, -90))
		if(R)
			. += R

// ---------- Implemented: Azarus Scatter Dice ----------
// Afterimage spawns within 3 of Star. 1s later, 3 dice drop around each
// player in view; each die lands 1.5s after spawn and deals AoE scaling
// with the face it lands on (1–2 = 1-tile splash, 3–4 = +knockback,
// 5–6 = 2-tile splash). Misfire (Dice Duplicate) forces every die in the
// wave to land on the same face — predictable lane.

/obj/effect/serio_afterimage/azarus_dice
	name = "afterimage — Azarus"
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "herald"
	attack_key = "azarus_dice"
	// 1s pre-roll + 3s spin + 0.2s bounce + small buffer = ~4.4s.
	total_duration = 4.5 SECONDS
	spawn_sound = 'sound/items/coinflip.ogg'
	spawn_sound_volume = 55
	/// No pre-spawn telegraph — the spinning die IS the warning.
	borrowed_warning_visual = null
	/// azarus.dm:166 — small smoke puff per AoE tile on die-land.
	borrowed_impact_visual = /obj/effect/temp_visual/small_smoke/halfsecond

/obj/effect/serio_afterimage/azarus_dice/SetupSpawn()
	if(!parent_star)
		return
	var/list/nearby = list()
	for(var/turf/open/T in view(3, parent_star))
		nearby += T
	if(length(nearby))
		forceMove(pick(nearby))

/obj/effect/serio_afterimage/azarus_dice/PerformAttack()
	sleep(1 SECONDS)
	if(QDELETED(src))
		return
	// Misfire = Dice Duplicate: cache one roll, force every die to land on
	// it. Clean run lets each die roll independently in Land().
	var/dupe_face = is_misfire ? rand(1, 6) : 0
	for(var/mob/living/carbon/human/H as anything in PickAllPlayers())
		var/list/around = list()
		for(var/turf/open/T in view(2, H))
			around += T
		var/dice_count = rand(3, 4)
		for(var/i in 1 to dice_count)
			if(!length(around))
				break
			var/turf/landing = pick(around)
			around -= landing
			SpawnDie(landing, dupe_face)
	// Wait for the dice to spin (3s) + bounce-down (0.2s) before panicking.
	sleep(3.4 SECONDS)
	if(is_misfire && parent_star)
		parent_star.OnMisfireResolved(attack_key)
	Dissipate()

/// Drops a self-spinning ghost-die at `landing`. `forced_face` 0 = random
/// roll on land, anything 1-6 = lock that face (for the misfire variant).
/obj/effect/serio_afterimage/azarus_dice/proc/SpawnDie(turf/landing, forced_face)
	if(!landing)
		return
	var/obj/structure/azarus_die/serio/D = new(landing)
	if(parent_star)
		D.color = parent_star.afterimage_color
		D.parent_star_ref = parent_star
	if(forced_face)
		D.forced_result = forced_face

// ---------- Subtype: Azarus die, self-spinning ghost variant ----------
// Skips the boss-owner table-score machinery; auto-spins on creation,
// self-applies its dice-impact AoE on Land, lingers visually for 2s, then
// fades and qdels. Identical spin animation + 3s wait + impact-scaling
// rules as the boss's /obj/structure/azarus_die. Tinted by the spawner.

/obj/structure/azarus_die/serio
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	/// If non-zero, Land() uses this face instead of roll(6).
	var/forced_result = 0
	/// Duration of the bounce-down landing animation.
	var/land_animation_time = 0.2 SECONDS
	/// How long the die stays visible after landing, fading out.
	var/linger_after_land = 2 SECONDS
	/// Back-ref to Star so OnPlayerDodged can be reported.
	var/mob/living/simple_animal/hostile/young_star/parent_star_ref

/obj/structure/azarus_die/serio/Initialize(mapload)
	. = ..()
	// Boss owner-binding skipped — kick the spin loop directly.
	INVOKE_ASYNC(src, PROC_REF(StartSpin))

/obj/structure/azarus_die/serio/Destroy()
	parent_star_ref = null
	return ..()

/// Override of the boss's Land(): no LockIn, no OnDieLanded. Stops the
/// spin and the result-cycle, animates the bounce-down (chained with a
/// fade-out so both run sequentially on the same atom), and defers the
/// damage + impact sound until the bounce completes (`pixel_z == 0`).
/obj/structure/azarus_die/serio/Land()
	deltimer(spin_timer)
	spin_timer = null
	result = forced_result ? forced_result : roll(6)
	spinning = FALSE
	update_icon()
	// Bounce down, then fade. Second animate() omits the atom on purpose
	// so it chains onto the first instead of replacing it.
	animate(src, pixel_z = 0, time = land_animation_time, easing = BOUNCE_EASING)
	animate(alpha = 0, time = linger_after_land, easing = SINE_EASING)
	addtimer(CALLBACK(src, PROC_REF(DoLandImpact)), land_animation_time)
	QDEL_IN(src, land_animation_time + linger_after_land)

/obj/structure/azarus_die/serio/proc/DoLandImpact()
	if(QDELETED(src))
		return
	playsound(src, 'sound/items/dodgeball.ogg', 70, TRUE, 5)
	DiceImpact()

/obj/structure/azarus_die/serio/DiceImpact()
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/radius = (result >= 6) ? 2 : 1
	var/dmg = result * dice_impact_per_pip
	var/list/aoe_turfs = list()
	for(var/turf/T in range(radius, center))
		aoe_turfs += T
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	var/list/danger_humans = list()
	for(var/turf/T as anything in aoe_turfs)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	var/list/hit = list()
	for(var/turf/T as anything in aoe_turfs)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(dmg, BLACK_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
			hit |= H
	if(parent_star_ref && !QDELETED(parent_star_ref))
		for(var/mob/living/H as anything in danger_humans)
			if(!(H in hit))
				parent_star_ref.OnPlayerDodged(H)

// ---------- Implemented: Reaper Refraction Sweep ----------
// One afterimage spawns one tile behind each player in view, facing the
// player. After 2s, sweeps a 3-deep cone through the player. Misfire
// (Cone Dir Inverted) sweeps the cone backward — toward arena center
// where Star usually stands. With multiple afterimages on stage, all
// inverted cones converge on Star → scaled self-damage by tier.

/obj/effect/serio_afterimage/reaper_sweep
	name = "afterimage — Mirror-Shattered Reaper"
	icon_state = "mirror_shattered"
	attack_key = "reaper_sweep"
	total_duration = 2.5 SECONDS
	spawn_sound = 'sound/abnormalities/wayward_passenger/ripspace_begin.ogg'
	spawn_sound_volume = 45
	/// mirror_shattered_reaper.dm:35 — pre-sweep cone reticle.
	borrowed_warning_visual = /obj/effect/temp_visual/mirror_warning
	/// mirror_shattered_reaper.dm:52 — sweep impact glass-crack.
	borrowed_impact_visual = /obj/effect/temp_visual/mirror_impact
	/// Set during SetupSpawn so PerformAttack can swing at the right player.
	var/mob/living/carbon/human/locked_target
	/// Whether THIS instance is the chosen "fan out and fire" instance —
	/// the spawn proc fans out one afterimage per player; only the first
	/// instance per wave actually runs the fan-out. See class note below.
	var/is_lead = TRUE

/obj/effect/serio_afterimage/reaper_sweep/SetupSpawn()
	// Star casts a single reaper_sweep "wave" per main-tick slot; that
	// wave actually wants to drop ONE afterimage per player. We achieve
	// that by having the first-spawned instance set itself up and then
	// fan extra siblings for every other player. Siblings are flagged
	// `is_lead = FALSE` so they don't fan again.
	if(!parent_star)
		return
	var/list/players = PickAllPlayers()
	if(!length(players))
		return
	locked_target = players[1]
	PlaceBehind(locked_target)
	if(!is_lead)
		return
	for(var/i in 2 to length(players))
		var/mob/living/carbon/human/H = players[i]
		var/obj/effect/serio_afterimage/reaper_sweep/sibling = new(get_turf(parent_star), parent_star)
		if(!QDELETED(sibling))
			sibling.is_lead = FALSE
			sibling.locked_target = H
			sibling.PlaceBehind(H)

/obj/effect/serio_afterimage/reaper_sweep/proc/PlaceBehind(mob/living/carbon/human/target)
	if(!target)
		return
	var/turf/behind = get_step(get_turf(target), turn(target.dir, 180))
	if(!behind)
		behind = get_turf(target)
	forceMove(behind)
	setDir(get_dir(src, target))

/obj/effect/serio_afterimage/reaper_sweep/PerformAttack()
	sleep(2 SECONDS)
	if(QDELETED(src) || QDELETED(locked_target))
		Dissipate()
		return
	var/forward_dir = get_dir(src, locked_target)
	if(!forward_dir)
		forward_dir = dir
	// Misfire: cone faces the opposite direction (inward toward Star).
	var/cone_dir = is_misfire ? turn(forward_dir, 180) : forward_dir
	var/list/cone_turfs = BuildConeFromHere(cone_dir, 3)
	var/list/danger_humans = list()
	for(var/turf/T as anything in cone_turfs)
		new /obj/effect/temp_visual/mirror_warning(T)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	sleep(0.3 SECONDS)
	if(QDELETED(src))
		return
	playsound(get_turf(src), 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg', 70, TRUE, 5)
	var/list/hit = list()
	for(var/turf/T as anything in cone_turfs)
		new /obj/effect/temp_visual/mirror_impact(T)
		for(var/mob/living/L in T)
			if(L.stat == DEAD)
				continue
			// Inverted cone catches Star too.
			L.deal_damage(40, BLACK_DAMAGE, parent_star, attack_type = ATTACK_TYPE_SPECIAL)
			if(ishuman(L))
				hit |= L
	for(var/mob/living/H as anything in danger_humans)
		if(!(H in hit))
			parent_star?.OnPlayerDodged(H)
	if(is_misfire && parent_star && is_lead)
		parent_star.OnMisfireResolved(attack_key)
	Dissipate()

/obj/effect/serio_afterimage/reaper_sweep/proc/BuildConeFromHere(facing, max_depth)
	. = list()
	var/turf/center = get_turf(src)
	for(var/depth in 1 to max_depth)
		center = get_step(center, facing)
		if(!center)
			break
		. += center
		var/turf/L = get_step(center, turn(facing, 90))
		if(L)
			. += L
		var/turf/R = get_step(center, turn(facing, -90))
		if(R)
			. += R

// ---------- Implemented: Understudy Costume Dash ----------
// The afterimage is a real /mob/living/carbon/human in a generic Fixer
// outfit + fedora + gas mask, godmoded so it can't be damaged. The
// /obj/effect shim is a thin spawner — picks the 2-4-tile-from-player
// spawn turf, hands a back-ref to the carbon mob, and dissipates.
//
// Misfire (Costume Not Loaded): each worn clothing item has both its
// icon_state and worn_icon_state slammed to "", falling through to the
// debug sprite. Telegraph halves. Damage stays at the clean default.

/obj/effect/serio_afterimage/understudy_dash
	name = "afterimage — Understudy (spawner)"
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_64x96.dmi'
	icon_state = ""
	alpha = 0
	attack_key = "understudy_dash"
	total_duration = 1.8 SECONDS
	spawn_sound = null
	borrowed_warning_visual = /obj/effect/temp_visual/understudy_warning
	borrowed_impact_visual = /obj/effect/temp_visual/small_smoke/halfsecond

/obj/effect/serio_afterimage/understudy_dash/SetupSpawn()
	var/mob/living/carbon/human/target = PickRandomPlayer()
	if(!target)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(4, target))
		var/d = get_dist(T, target)
		if(d >= 2 && d <= 4)
			candidates += T
	var/turf/spawn_turf = length(candidates) ? pick(candidates) : get_turf(target)
	new /mob/living/carbon/human/serio_afterimage_understudy(spawn_turf, parent_star, target, is_misfire, total_duration)

/obj/effect/serio_afterimage/understudy_dash/PerformAttack()
	Dissipate()

// ----- The carbon mob that wears the costume and runs the dash. -----

/mob/living/carbon/human/serio_afterimage_understudy
	name = "afterimage"
	desc = "A translucent echo wearing someone else's wardrobe."
	faction = list("serio_zeal")
	alpha = 120
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	var/mob/living/simple_animal/hostile/young_star/parent_star
	var/mob/living/carbon/human/locked_target
	var/is_misfire = FALSE
	var/attack_key = "understudy_dash"
	var/dash_damage = 26
	var/dash_reach = 6
	/// Telegraph window before the strip lands. Misfire halves it.
	var/dash_delay = 0.8 SECONDS
	/// Items we equipped; qdel'd in Destroy so nothing drops to the floor.
	var/list/tracked_costume = list()

/mob/living/carbon/human/serio_afterimage_understudy/Initialize(mapload, mob/living/simple_animal/hostile/young_star/parent, mob/living/carbon/human/target, misfire, lifetime)
	. = ..()
	if(!parent || !target)
		return INITIALIZE_HINT_QDEL
	parent_star = parent
	locked_target = target
	is_misfire = misfire
	color = parent.afterimage_color
	status_flags |= GODMODE
	setDir(get_dir(src, locked_target))
	if(parent_star)
		RegisterSignal(parent_star, COMSIG_PARENT_QDELETING, PROC_REF(OnParentGone))
		RegisterSignal(parent_star, COMSIG_LIVING_DEATH, PROC_REF(OnParentGone))
	QDEL_IN(src, lifetime)
	// equipOutfit + equip_to_slot_or_del can sleep (mob_can_equip → do_after
	// → stoplag), so defer the dressing + dash kickoff out of Initialize.
	INVOKE_ASYNC(src, PROC_REF(EquipAndDash))

/mob/living/carbon/human/serio_afterimage_understudy/proc/EquipAndDash()
	if(QDELETED(src))
		return
	equipOutfit(/datum/outfit/job/efixer)
	equip_to_slot_or_del(new /obj/item/clothing/head/fedora(src), ITEM_SLOT_HEAD)
	equip_to_slot_or_del(new /obj/item/clothing/mask/gas(src), ITEM_SLOT_MASK)
	for(var/obj/item/I in get_equipped_items(TRUE))
		tracked_costume += I
		ADD_TRAIT(I, TRAIT_NODROP, REF(src))
		if(is_misfire)
			I.icon_state = ""
			I.worn_icon_state = ""
			I.update_icon()
	if(is_misfire)
		regenerate_icons()
	playsound(get_turf(src), 'sound/effects/splat.ogg', 55, TRUE, 4)
	PerformDash()

/mob/living/carbon/human/serio_afterimage_understudy/Destroy()
	if(parent_star)
		UnregisterSignal(parent_star, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
		parent_star = null
	for(var/obj/item/I as anything in tracked_costume)
		if(!QDELETED(I))
			qdel(I)
	tracked_costume.Cut()
	locked_target = null
	return ..()

/mob/living/carbon/human/serio_afterimage_understudy/proc/OnParentGone(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/mob/living/carbon/human/serio_afterimage_understudy/proc/PerformDash()
	if(QDELETED(src) || QDELETED(locked_target))
		return
	sleep(0.3 SECONDS)
	if(QDELETED(src) || QDELETED(locked_target))
		return
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(locked_target)
	if(!start || !dest)
		return
	var/dir_to = get_dir(start, dest)
	setDir(dir_to)
	// Aim 2 tiles past target so the dash ends on top of them.
	var/turf/endpoint = dest
	for(var/i in 1 to 2)
		var/turf/nxt = get_step(endpoint, dir_to)
		if(!nxt || nxt.density)
			break
		endpoint = nxt
	var/list/line = getline(start, endpoint)
	if(length(line) > dash_reach + 1)
		line.Cut(dash_reach + 2)
	// Strip = 3-tile-wide corridor centered on the line.
	var/list/strip = list()
	for(var/turf/T in line)
		for(var/turf/W in range(1, T))
			strip |= W
	for(var/turf/T as anything in strip)
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 55, TRUE, 4)
	var/delay = is_misfire ? (dash_delay * 0.5) : dash_delay
	sleep(delay)
	if(QDELETED(src))
		return
	// Snap to the last non-dense line turf.
	var/turf/landing = start
	var/broken = FALSE
	for(var/turf/T in line)
		if(T.density)
			broken = TRUE
		else if(!broken)
			landing = T
	if(landing && !landing.density)
		forceMove(landing)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 70, TRUE, 5)
	var/list/danger_humans = list()
	for(var/turf/T as anything in strip)
		for(var/mob/living/carbon/human/H in T)
			if(H == src)
				continue
			danger_humans |= H
	var/list/hit = list()
	for(var/turf/T as anything in strip)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/carbon/human/H in T)
			if(H == src || H.stat == DEAD)
				continue
			H.deal_damage(dash_damage, RED_DAMAGE, parent_star, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			hit |= H
	for(var/mob/living/H as anything in danger_humans)
		if(!(H in hit))
			parent_star?.OnPlayerDodged(H)
	if(is_misfire && parent_star)
		parent_star.OnMisfireResolved(attack_key)

// ---------- Implemented: Eric Sanguine Marker ----------
// Afterimage spawns on a random tile within 3 of Star. For every player
// in 15-view, it paints a marker at the player's current tile and then
// blooms an AoE outward through concentric rings, then collapses back
// inward through the same rings — the Banquet pattern from nosferatu.dm
// (Banquet() proc berzerk branch).
//
// Misfire (Null-Pointer Marker): the outward bloom never fires. The
// marker sits inert for the full expected duration and then implodes
// straight onto its center tile as a single point-strike. Multi-player
// markers all implode simultaneously.

/obj/effect/serio_afterimage/eric_marker
	name = "afterimage — Greed-Touched Eric"
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "b_boss"
	attack_key = "eric_marker"
	total_duration = 3.5 SECONDS
	spawn_sound = 'sound/abnormalities/nosferatu/attack_special.ogg'
	spawn_sound_volume = 50
	borrowed_warning_visual = /obj/effect/temp_visual/greed_burst_warning
	borrowed_impact_visual = /obj/effect/temp_visual/greed_minion_burst
	var/marker_damage = 22
	/// Outermost ring index. 2 = 5x5 footprint (rings 0/1/2).
	var/marker_radius = 2
	/// Pre-bloom dwell time after warnings appear.
	var/initial_delay = 0.5 SECONDS
	/// Sleep between each ring step in the expansion.
	var/ring_step_delay = 0.5 SECONDS

/obj/effect/serio_afterimage/eric_marker/SetupSpawn()
	if(!parent_star)
		return
	var/list/nearby = list()
	for(var/turf/open/T in view(3, parent_star))
		nearby += T
	if(length(nearby))
		forceMove(pick(nearby))

/obj/effect/serio_afterimage/eric_marker/PerformAttack()
	if(QDELETED(src))
		return
	sleep(0.5 SECONDS)
	if(QDELETED(src))
		return
	var/list/players = PickAllPlayers()
	if(!length(players))
		Dissipate()
		return
	for(var/mob/living/carbon/human/H as anything in players)
		var/turf/center = get_turf(H)
		if(center)
			INVOKE_ASYNC(src, PROC_REF(DropMarker), center)
	// Wait for the markers to finish their dance. Clean cycles outward
	// then inward (radius+1 outward steps + radius+1 inward steps);
	// misfire just dwells once then implodes.
	var/cycle_steps = (marker_radius + 1) * 2
	sleep(initial_delay + (cycle_steps * ring_step_delay))
	if(is_misfire && parent_star)
		parent_star.OnMisfireResolved(attack_key)
	Dissipate()

/obj/effect/serio_afterimage/eric_marker/proc/DropMarker(turf/center)
	if(!center)
		return
	// Group AoE tiles by ring distance (index 0 = center, 1 = first ring, …).
	var/list/list/rings = list()
	for(var/i in 0 to marker_radius)
		rings += list(list())
	var/list/all_aoe = list()
	for(var/turf/T in range(marker_radius, center))
		var/d = get_dist(center, T)
		if(d > marker_radius)
			continue
		rings[d + 1] += T
		all_aoe += T
	// Paint warnings on every AoE tile (the boss's per-tile pre-strike reticle).
	for(var/turf/T as anything in all_aoe)
		new /obj/effect/temp_visual/greed_burst_warning(T)
	// Snapshot humans inside the AoE at warning-paint time for dodge tracking.
	var/list/danger_humans = list()
	for(var/turf/T as anything in all_aoe)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	sleep(initial_delay)
	if(QDELETED(src))
		return
	var/list/hit = list()
	if(is_misfire)
		// No outward bloom — dwell, then a single center-tile point-strike.
		sleep((marker_radius + 1) * ring_step_delay * 2)
		if(QDELETED(src))
			return
		ApplyRing(rings[1], hit)
	else
		// Outward: rings 1..N (skip the center on the way out).
		for(var/r in 1 to marker_radius)
			if(QDELETED(src))
				return
			ApplyRing(rings[r + 1], hit)
			sleep(ring_step_delay)
		// Inward: rings N..0 (this time include the center as the final pop).
		for(var/r = marker_radius, r >= 0, r--)
			if(QDELETED(src))
				return
			ApplyRing(rings[r + 1], hit)
			sleep(ring_step_delay)
	for(var/mob/living/H as anything in danger_humans)
		if(!(H in hit))
			parent_star?.OnPlayerDodged(H)

/obj/effect/serio_afterimage/eric_marker/proc/ApplyRing(list/tiles, list/hit)
	if(!islist(tiles))
		return
	for(var/turf/T as anything in tiles)
		new /obj/effect/temp_visual/greed_minion_burst(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(marker_damage, RED_DAMAGE, parent_star, attack_type = ATTACK_TYPE_SPECIAL)
			hit |= H

// ---------- Stubs (visual only — fill in next pass) ----------
// Each stub spawns at Star's tile with the borrowed boss's icon_state,
// sits for a beat, and dissipates without effect. No damage, no misfire.
//
// The `borrowed_warning_visual` / `borrowed_impact_visual` vars below
// document which temp_visual classes each boss uses for telegraphing
// and striking its real attack, so the next-pass implementer can spawn
// the correct effects without hunting through the boss files.

/obj/effect/serio_afterimage/snow_eyes
	name = "afterimage — Snow Cabin"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "eyeturf_blink"
	attack_key = "snow_eyes"
	spawn_sound = 'sound/effects/glassbr1.ogg'
	spawn_sound_volume = 40
	/// snow_cabin.dm:38 — bone-stab line wall-to-wall telegraph.
	borrowed_warning_visual = /obj/effect/temp_visual/snow_cabin_bone_stab_warning
	/// snow_cabin.dm:49 — bone spike strike sprite.
	borrowed_impact_visual = /obj/effect/temp_visual/snow_cabin_bone_stab

/obj/effect/serio_afterimage/blade_volley
	name = "afterimage — Blade Priest"
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "blade_priest"
	attack_key = "blade_volley"
	spawn_sound = 'sound/weapons/rapierhit.ogg'
	spawn_sound_volume = 50
	/// blade_priest.dm:40 — single-blade dash telegraph (used per blade
	/// in the volley sequencing).
	borrowed_warning_visual = /obj/effect/temp_visual/blade_priest_dash_warning
	/// Blade Priest impacts use no dedicated visual — the blade-projectile
	/// itself does. Leave null; implementer can spawn the blade obj instead.
	borrowed_impact_visual = null

/obj/effect/serio_afterimage/achiya_bolt
	name = "afterimage — Achiyalabopa"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs4.dmi'
	icon_state = "achiyalabopa"
	attack_key = "achiya_bolt"
	spawn_sound = 'sound/abnormalities/thunderbird/tbird_bolt.ogg'
	spawn_sound_volume = 45
	/// achiyalabopa.dm:60 — pre-strike skystrike telegraph on the target
	/// tile. Lives long enough to cover the bolt's wind-up.
	borrowed_warning_visual = /obj/effect/temp_visual/divine_judgment_warning
	/// achiyalabopa.dm:72 — the lightning column drop sprite.
	borrowed_impact_visual = /obj/effect/temp_visual/divine_judgment_strike
