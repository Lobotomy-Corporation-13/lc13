/*
 * Curtain Call — zeal_s5n1 (serio_zeal_w1): Phase 1 of the Serio Zeal
 * finale boss. "Star" performs the borrowed acts of the prior 8 Curtain
 * Call bosses through translucent afterimages. The Pressure meter is the
 * only path to Phase 2 — HP damage cycles via the Railroading passive
 * (HP refills, +25% Pressure, encounter continues). See
 * serio_brainstorm.md in this directory for the full design.
 *
 * All eight afterimages implemented with clean + misfire variants: Capo
 * Sweep, Azarus Scatter Dice, Reaper Refraction Sweep, Understudy
 * Costume Dash, Eric Sanguine Marker, Snow Cabin Bone Stab Line, Blade
 * Priest Volley, Achiyalabopa Divine Thunderbolt. Each feeds pressure
 * via dodges, damage hits, and misfire resolution.
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
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "strikes with their cane"
	attack_verb_simple = "strike with their cane"
	attack_sound = 'sound/weapons/genhit2.ogg'
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
	/// Pressure gained each time accumulated incoming damage crosses
	/// `damage_pressure_threshold_pct` of maxHealth.
	var/pressure_per_damage_hit = 1
	/// Pressure gained when an attack (afterimage cast or wind-up melee
	/// AoE) misses every target. Per-attack, NOT per-dodger.
	var/pressure_per_attack_miss = 1
	/// Pressure gained per wave that produced a misfire. Dedup'd by
	/// wave_id — three misfires in one summon still only count once.
	var/pressure_per_misfire = 1
	/// Pressure gained when Railroad fires (HP cycled).
	var/pressure_per_railroad = 25
	/// Fraction of maxHealth that must accumulate (across any number of
	/// hits) before one `pressure_per_damage_hit` tick fires. 0.05 = 5%.
	var/damage_pressure_threshold_pct = 0.05
	/// Running total of damage taken since the last pressure tick. Reset
	/// (minus one threshold) every time a tick fires; can roll multiple
	/// ticks from a single big hit if it overshoots.
	var/damage_pressure_accumulator = 0
	/// Increments at every MainTick; afterimages capture this as their
	/// `wave_id` so the misfire-pressure dedup can collapse same-wave
	/// reports into a single tick.
	var/wave_counter = 0
	/// Last wave_id that already counted toward misfire pressure. Reset
	/// every wave by virtue of being strictly less than wave_counter.
	var/last_misfire_wave_counted = 0
	// ---- Teleport ladder ----
	/// HP fraction at which the next quick teleport fires. Decrements by
	/// `teleport_threshold_step` per trigger; reset every Railroad so each
	/// HP cycle gives the player roughly six teleport-windows worth of dodges.
	var/next_teleport_threshold = 0.85
	var/teleport_threshold_step = 0.15
	// ---- 5x5 wind-up AoE ----
	/// Per-melee-swing chance the cane hit starts the galaxy-aura wind-up.
	var/aoe_proc_chance = 25
	var/aoe_wind_up_duration = 1.5 SECONDS
	var/aoe_cooldown_time = 8 SECONDS
	var/aoe_damage = 35
	var/aoe_knockback = 4
	var/aoe_cooldown_until = 0
	var/aoe_winding_up = FALSE
	var/list/aoe_warning_visuals = list()
	var/aoe_resolve_timer_id
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
	/// Multi-cast tiers stagger their summons by this delay so each
	/// borrowed-boss act gets a beat to land before the next telegraphs.
	var/summon_stagger_delay = 1 SECONDS
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
	if(aoe_resolve_timer_id)
		deltimer(aoe_resolve_timer_id)
		aoe_resolve_timer_id = null
	ClearAoEWarning()
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
	wave_counter++
	var/longest = 0
	var/cast_count = GetTierCastCount()
	for(var/i in 1 to cast_count)
		if(QDELETED(src) || stat == DEAD || cracking)
			return
		var/path = pick(attack_roster)
		// Pass wave_counter through the constructor so SetupSpawn (and any
		// helper mob it spawns, like the understudy carbon) sees the
		// correct wave_id immediately.
		var/obj/effect/serio_afterimage/AF = new path(get_turf(src), src, wave_counter)
		if(!QDELETED(AF) && AF.total_duration > longest)
			longest = AF.total_duration
		playsound(get_turf(src), 'sound/weapons/black_silence/snap.ogg', 60, FALSE, 6)
		// Stagger waves: 1s pause between summons so multi-cast tiers read
		// as "Star is throwing one persona after another" instead of an
		// instant pile of telegraph-soup. The first summon fires
		// immediately; only summons 2..N wait.
		if(i < cast_count)
			sleep(summon_stagger_delay)
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

/// An attack (afterimage cast or wind-up melee AoE) resolved without
/// hitting anyone in its danger zone. Fires once per attack — not once
/// per dodging player — so a wide AoE that misses three people still
/// only adds `pressure_per_attack_miss`.
/mob/living/simple_animal/hostile/young_star/proc/OnAttackMissed(attack_key)
	if(QDELETED(src) || cracking || stat == DEAD)
		return
	UpdatePressure(pressure_per_attack_miss, "missed_[attack_key]")

/// A misfire resolved on `attack_key` belonging to wave `wave_id`. The
/// panic line always plays; pressure only ticks once per wave so a
/// Tier-3 quad-cast with three misfires still only adds one tick.
/mob/living/simple_animal/hostile/young_star/proc/OnMisfireResolved(attack_key, wave_id = 0)
	if(QDELETED(src))
		return
	SayPanicLine(attack_key, GetPressureTier())
	if(cracking || stat == DEAD)
		return
	if(wave_id > 0 && wave_id == last_misfire_wave_counted)
		return
	last_misfire_wave_counted = wave_id
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

/// Damage feedback: pressure ticks fire when accumulated incoming
/// damage crosses 5% of maxHealth, not per-hit. Lets cautious chip
/// damage still feed the meter while keeping high-DPS bursts from
/// snowballing it — predictable 20 ticks per HP bar (5% × 20 = 100%).
/// Railroad is handled separately in death(). After the pressure
/// bookkeeping, check whether the hit crossed a teleport ladder rung.
/mob/living/simple_animal/hostile/young_star/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	if(. <= 0)
		return
	damage_pressure_accumulator += .
	var/threshold = max(1, round(maxHealth * damage_pressure_threshold_pct))
	while(damage_pressure_accumulator >= threshold)
		damage_pressure_accumulator -= threshold
		UpdatePressure(pressure_per_damage_hit, "damage")
	CheckTeleportThreshold()

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
	playsound(get_turf(src), 'sound/weapons/black_silence/unlock.ogg', 75, FALSE, 8)
	UpdatePressure(pressure_per_railroad, "railroad")
	// Fresh HP bar → fresh teleport ladder. Next 15% chunk lost
	// triggers a teleport again.
	next_teleport_threshold = 0.85

/// Steps the teleport ladder down whenever the HP fraction crosses the
/// next rung. Uses `while` so a single fat hit that overshoots multiple
/// rungs still fires the right number of teleports (each via a 1s
/// addtimer stagger so they don't all collapse into one frame).
/mob/living/simple_animal/hostile/young_star/proc/CheckTeleportThreshold()
	if(QDELETED(src) || stat == DEAD || cracking)
		return
	if(!maxHealth)
		return
	var/ratio = health / maxHealth
	var/delay = 0
	while(ratio <= next_teleport_threshold && next_teleport_threshold > 0)
		next_teleport_threshold -= teleport_threshold_step
		if(delay <= 0)
			QuickTeleport()
		else
			addtimer(CALLBACK(src, PROC_REF(QuickTeleport)), delay, TIMER_STOPPABLE)
		delay += 1 SECONDS

/// Quick teleport copied from the resurgence_core augment: contractor-
/// baton thump SFX, ninja phase-out at origin, phase-in at destination.
/// Also cancels any pending 5x5 wind-up — Star can't pivot mid-cast.
/mob/living/simple_animal/hostile/young_star/proc/QuickTeleport()
	if(QDELETED(src) || stat == DEAD || cracking)
		return
	if(aoe_winding_up)
		CancelAoEFromTeleport()
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(view_range, src))
		if(T == origin || T.density)
			continue
		candidates += T
	if(!length(candidates))
		return
	var/turf/dest = pick(candidates)
	playsound(origin, 'sound/effects/contractorbatonhit.ogg', 35, FALSE, 9)
	new /obj/effect/temp_visual/dir_setting/ninja/phase/out(origin)
	forceMove(dest)
	new /obj/effect/temp_visual/dir_setting/ninja/phase(dest)

/// 25% chance on every landed basic melee. Paints a galaxy-aura warning
/// in the 5x5 around Star and schedules ResolveAoE after the wind-up.
/// Star can still walk while winding up — `RepaintAoEWarning` rebuilds
/// the 5x5 around the new position on every move so the warning visual
/// stays anchored to Star's current tile. If Star teleports during the
/// wind-up, CancelAoEFromTeleport kills the timer and clears the visuals.
/mob/living/simple_animal/hostile/young_star/proc/StartAoEWindup()
	if(aoe_winding_up || world.time < aoe_cooldown_until || cracking || stat == DEAD)
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	aoe_winding_up = TRUE
	aoe_cooldown_until = world.time + aoe_cooldown_time
	RepaintAoEWarning(center)
	playsound(center, 'sound/magic/staff_change.ogg', 55, TRUE, 5)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(OnMoveDuringAoE))
	aoe_resolve_timer_id = addtimer(CALLBACK(src, PROC_REF(ResolveAoE)), aoe_wind_up_duration, TIMER_STOPPABLE)

/// Paints the 5x5 galaxy-aura around `center`. Clears any existing
/// warning first so move-driven repaints don't leak instances.
/mob/living/simple_animal/hostile/young_star/proc/RepaintAoEWarning(turf/center)
	ClearAoEWarning()
	if(!center)
		return
	for(var/turf/T in range(2, center))
		var/obj/effect/temp_visual/serio_galaxy_aura/W = new(T, aoe_wind_up_duration)
		aoe_warning_visuals += W

/// Signal handler — Star moved while winding up the cane AoE. Snap the
/// warning to the new tile so the player sees the AoE following Star.
/mob/living/simple_animal/hostile/young_star/proc/OnMoveDuringAoE(datum/source)
	SIGNAL_HANDLER
	if(!aoe_winding_up)
		return
	RepaintAoEWarning(get_turf(src))

/// Fires the 5x5 PALE damage + 4-tile knockback. Reports a miss to
/// pressure if no one was in the zone when the timer fired. Spawns a
/// red galaxy-burst impact on every tile so the damage frame reads as
/// "the warning detonated", not "the warning just disappeared".
/mob/living/simple_animal/hostile/young_star/proc/ResolveAoE()
	aoe_resolve_timer_id = null
	if(!aoe_winding_up)
		return
	aoe_winding_up = FALSE
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	ClearAoEWarning()
	if(QDELETED(src) || stat == DEAD || cracking)
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	playsound(center, 'sound/magic/clockwork/narsie_attack.ogg', 60, FALSE, 6)
	// One big centerpiece explosion + per-tile sparkles. The sparkles
	// read as "damage was applied here", the centered boom reads as the
	// AoE itself going off.
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/cult/sparks(T)
	var/list/hit = list()
	for(var/turf/T in range(2, center))
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(aoe_damage, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			var/throw_dir = get_dir(center, H) || pick(GLOB.alldirs)
			var/turf/throw_dest = get_ranged_target_turf(H, throw_dir, aoe_knockback)
			if(throw_dest)
				H.throw_at(throw_dest, aoe_knockback, 2, src)
			hit |= H
	if(!length(hit))
		OnAttackMissed("melee_aoe")

/mob/living/simple_animal/hostile/young_star/proc/CancelAoEFromTeleport()
	if(!aoe_winding_up)
		return
	aoe_winding_up = FALSE
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	if(aoe_resolve_timer_id)
		deltimer(aoe_resolve_timer_id)
		aoe_resolve_timer_id = null
	ClearAoEWarning()

/mob/living/simple_animal/hostile/young_star/proc/ClearAoEWarning()
	for(var/obj/effect/temp_visual/serio_galaxy_aura/V as anything in aoe_warning_visuals)
		if(!QDELETED(V))
			qdel(V)
	aoe_warning_visuals.Cut()

/// Basic cane swing rolls the 5x5 wind-up after each landed strike.
/// `..()` does the normal melee damage; we only chain the wind-up on a
/// successful hit so an empty-air swing doesn't burn the AoE timer.
/mob/living/simple_animal/hostile/young_star/AttackingTarget(atom/attacked_target)
	. = ..()
	if(. && prob(aoe_proc_chance))
		StartAoEWindup()

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
		"snow_eyes" = list(
			"tier1" = list(
				"Negative space — every wall needs windows.",
				"An interrupted line; the audience finishes the rest in their head.",
			),
			"tier2" = list(
				"Ah, the row's — the row's not solid, sorry—",
				"Wait, that's not — that's full of gaps—",
			),
			"tier3" = list(
				"Th-there's holes, why are there holes—",
				"It was supposed to be a wall, it was supposed to be—!",
			),
		),
		"blade_volley" = list(
			"tier1" = list(
				"A redirected verse — turning the line back upon the speaker.",
				"Bit of self-effacing staging there. As I was saying—",
			),
			"tier2" = list(
				"Wait — that's me, that's coming at — !",
				"Wrong way, wrong way, ah—",
			),
			"tier3" = list(
				"I-I had the names backwards, agh—!",
				"Th-the blade, the blade — !",
			),
		),
		"achiya_bolt" = list(
			"tier1" = list(
				"An afterthought of lightning. Onward.",
				"A delayed verdict — the heavens are slow tonight.",
			),
			"tier2" = list(
				"Ah — I aimed where you were, not where you are—",
				"You moved? Sorry, sorry, you moved—",
			),
			"tier3" = list(
				"I-I lost track of you, I missed, I—",
				"Wait, you moved? You moved — please—",
			),
		),
	)

// ---------- Star wind-up warning ----------
// Painted across the 5x5 around Star during the 1.5s cane-AoE wind-up.
// duration is set by the caller so a teleport-cancel can qdel it early
// without waiting for the default to expire.
/obj/effect/temp_visual/serio_galaxy_aura
	name = "galaxy aura"
	icon = 'icons/effects/effects.dmi'
	icon_state = "galaxy_aura"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1.5 SECONDS

/obj/effect/temp_visual/serio_galaxy_aura/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

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
	/// Star's wave_counter at the moment this afterimage spawned. Used
	/// by ReportMisfire to dedup multi-misfire waves on the boss side.
	var/wave_id = 0
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

/obj/effect/serio_afterimage/Initialize(mapload, mob/living/simple_animal/hostile/young_star/parent, wave_id_arg = 0)
	. = ..()
	if(!istype(parent))
		return INITIALIZE_HINT_QDEL
	parent_star = parent
	wave_id = wave_id_arg
	parent.active_afterimages += src
	color = parent.afterimage_color
	is_misfire = parent.RollMisfire()
	SetupSpawn()
	if(is_misfire)
		ApplyMisfireGlitch()
	if(spawn_sound)
		playsound(get_turf(src), spawn_sound, spawn_sound_volume, TRUE, spawn_sound_extra_range)
	INVOKE_ASYNC(src, PROC_REF(PerformAttack))

/// Visual misfire tell: low-alpha flicker that pulses for the whole
/// afterimage's lifetime. Skipped if alpha is too low to be visibly
/// affected — those subtypes (snow_eyes, understudy_dash) are
/// spawner-only and convey misfire through their summoned entity.
/obj/effect/serio_afterimage/proc/ApplyMisfireGlitch()
	if(alpha < 40)
		return
	var/base_alpha = alpha
	animate(src, alpha = round(base_alpha * 0.35), time = 1, loop = -1, easing = LINEAR_EASING)
	animate(alpha = base_alpha, time = 2, easing = LINEAR_EASING)

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

/// Convenience for subtypes: routes the misfire report through Star
/// with this afterimage's wave_id so the boss can dedup multi-misfire
/// waves into a single pressure tick (while still letting every
/// individual misfire say its panic line).
/obj/effect/serio_afterimage/proc/ReportMisfire()
	if(!is_misfire || !parent_star)
		return
	parent_star.OnMisfireResolved(attack_key, wave_id)

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
	total_duration = 2 SECONDS
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
	var/wind_up = is_misfire ? 0.5 SECONDS : 0.8 SECONDS
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
	sleep(0.45 SECONDS)
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
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)
	if(is_misfire)
		ReportMisfire()
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
	if(is_misfire)
		ReportMisfire()
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
	/// Back-ref to Star so attack-miss feedback can be routed.
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
		if(length(danger_humans) && !length(hit))
			parent_star_ref.OnAttackMissed("azarus_dice")

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
	total_duration = 4 SECONDS
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
	/// Pre-strike wait, during which the afterimage pivots to face the
	/// player every track step. Long enough that players see the pivot
	/// and have to commit to a dodge before the cone resolves.
	var/track_duration = 3 SECONDS
	/// How often the pivot refreshes during track_duration. Lower = smoother.
	var/track_step = 2

/// Constructor override so the sibling's lead status and target are
/// known BEFORE the base Initialize runs SetupSpawn. Previously the
/// lead spawned siblings with `new(...)` and then set is_lead = FALSE
/// post-construction — but SetupSpawn had already executed during
/// `new()` with is_lead = TRUE (the default), so every sibling
/// cascaded into spawning its OWN siblings. Result: an exponentially
/// growing pile of reaper afterimages that never qdel'd, jamming
/// Star's active_afterimages forever. Setting the override args BEFORE
/// `..()` closes that race.
/obj/effect/serio_afterimage/reaper_sweep/Initialize(mapload, mob/living/simple_animal/hostile/young_star/parent, wave_id_arg = 0, mob/living/carbon/human/sibling_target = null)
	if(sibling_target)
		is_lead = FALSE
		locked_target = sibling_target
	. = ..()

/obj/effect/serio_afterimage/reaper_sweep/SetupSpawn()
	// Star casts a single reaper_sweep "wave" per main-tick slot; that
	// wave actually wants to drop ONE afterimage per player. The lead
	// instance picks the first player and fans extra siblings for every
	// other player; siblings come in with is_lead = FALSE pre-set by the
	// ctor, so they skip the fan-out entirely.
	if(!parent_star)
		return
	if(!is_lead)
		PlaceBehind(locked_target)
		return
	var/list/players = PickAllPlayers()
	if(!length(players))
		return
	locked_target = players[1]
	PlaceBehind(locked_target)
	for(var/i in 2 to length(players))
		new /obj/effect/serio_afterimage/reaper_sweep(get_turf(parent_star), parent_star, wave_id, players[i])

/obj/effect/serio_afterimage/reaper_sweep/proc/PlaceBehind(mob/living/carbon/human/target)
	if(!target)
		return
	var/turf/behind = get_step(get_turf(target), turn(target.dir, 180))
	if(!behind)
		behind = get_turf(target)
	forceMove(behind)
	setDir(get_dir(src, target))

/obj/effect/serio_afterimage/reaper_sweep/PerformAttack()
	// Track the player throughout the wind-up: every track_step the
	// afterimage pivots its dir toward the target's current tile. Tells
	// the player "this swing is coming for you" — they have to commit
	// to a dodge before the strike resolves. On misfire the cone flips
	// inward at the last beat, so the tracking pivot is a feint.
	var/remaining = track_duration
	while(remaining > 0)
		if(QDELETED(src))
			return
		if(QDELETED(locked_target))
			Dissipate()
			return
		var/track_dir = get_dir(src, locked_target)
		if(track_dir)
			setDir(track_dir)
		sleep(track_step)
		remaining -= track_step
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
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)
	if(is_misfire && is_lead)
		ReportMisfire()
	Dissipate()

/obj/effect/serio_afterimage/reaper_sweep/proc/BuildConeFromHere(facing, max_depth)
	. = list()
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/is_diagonal = (facing == NORTHEAST || facing == NORTHWEST \
		|| facing == SOUTHEAST || facing == SOUTHWEST)
	var/turf/prev = origin
	var/turf/center = origin
	for(var/depth in 1 to max_depth)
		var/turf/new_center = get_step(center, facing)
		if(!new_center)
			break
		. |= new_center
		var/turf/L = get_step(new_center, turn(facing, 90))
		if(L)
			. |= L
		var/turf/R = get_step(new_center, turn(facing, -90))
		if(R)
			. |= R
		// Diagonal cones leave checker-gaps between consecutive centers
		// (and at depth 1, between origin and the first center). Fill the
		// two cardinal tiles that bridge each pair so the AoE reads as a
		// solid wedge instead of a sparse mosaic.
		if(is_diagonal)
			var/turf/fill_x = locate(new_center.x, prev.y, new_center.z)
			if(fill_x)
				. |= fill_x
			var/turf/fill_y = locate(prev.x, new_center.y, new_center.z)
			if(fill_y)
				. |= fill_y
		prev = new_center
		center = new_center

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
	new /mob/living/carbon/human/serio_afterimage_understudy(spawn_turf, parent_star, target, is_misfire, total_duration, wave_id)

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
	/// Wave_id passed in from the spawner afterimage. Used by Star's
	/// OnMisfireResolved dedup so multiple understudies in one wave share
	/// the same wave_id.
	var/wave_id = 0

/mob/living/carbon/human/serio_afterimage_understudy/Initialize(mapload, mob/living/simple_animal/hostile/young_star/parent, mob/living/carbon/human/target, misfire, lifetime, wave_id_arg = 0)
	. = ..()
	if(!parent || !target)
		return INITIALIZE_HINT_QDEL
	parent_star = parent
	locked_target = target
	is_misfire = misfire
	wave_id = wave_id_arg
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
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)
	if(is_misfire && parent_star)
		parent_star.OnMisfireResolved(attack_key, wave_id)

// ---------- Implemented: Eric Sanguine Marker ----------
// Afterimage spawns near Star. For every visible human it paints a 3x3
// warning centered on their current tile, then resolves the area in two
// steps. Clean blooms OUTWARD (center pops first, then the ring of 8
// edge tiles). Misfire implodes INWARD (ring pops first, center after).
// Same total damage either way — the order changes which tile a player
// can safely cross during the strike.

/obj/effect/serio_afterimage/eric_marker
	name = "afterimage — Greed-Touched Eric"
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "b_boss"
	attack_key = "eric_marker"
	total_duration = 2.5 SECONDS
	spawn_sound = 'sound/abnormalities/nosferatu/attack_special.ogg'
	spawn_sound_volume = 50
	borrowed_warning_visual = /obj/effect/temp_visual/greed_burst_warning
	borrowed_impact_visual = /obj/effect/temp_visual/greed_minion_burst
	var/marker_damage = 22
	/// Pre-bloom dwell time after warnings appear.
	var/initial_delay = 0.5 SECONDS
	/// Delay between the two AoE steps (center then ring, or ring then center).
	var/step_delay = 0.4 SECONDS

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
	// Wait the markers out: initial dwell + the two staged AoE steps.
	sleep(initial_delay + (step_delay * 2))
	if(is_misfire)
		ReportMisfire()
	Dissipate()

/obj/effect/serio_afterimage/eric_marker/proc/DropMarker(turf/center)
	if(!center)
		return
	var/list/ring_tiles = list()
	var/list/all_aoe = list()
	for(var/turf/T in range(1, center))
		all_aoe += T
		if(T != center)
			ring_tiles += T
	for(var/turf/T as anything in all_aoe)
		new /obj/effect/temp_visual/greed_burst_warning(T)
	var/list/danger_humans = list()
	for(var/turf/T as anything in all_aoe)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	sleep(initial_delay)
	if(QDELETED(src))
		return
	var/list/hit = list()
	if(is_misfire)
		// Inward implode: ring first, then center.
		ApplyTiles(ring_tiles, hit)
		sleep(step_delay)
		if(QDELETED(src))
			return
		ApplyTiles(list(center), hit)
	else
		// Outward bloom: center first, then ring.
		ApplyTiles(list(center), hit)
		sleep(step_delay)
		if(QDELETED(src))
			return
		ApplyTiles(ring_tiles, hit)
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed("eric_marker")

/obj/effect/serio_afterimage/eric_marker/proc/ApplyTiles(list/tiles, list/hit)
	if(!islist(tiles))
		return
	for(var/turf/T as anything in tiles)
		new /obj/effect/temp_visual/greed_minion_burst(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(marker_damage, RED_DAMAGE, parent_star, attack_type = ATTACK_TYPE_SPECIAL)
			hit |= H

// ---------- Implemented: Snow Cabin Bone Stab Line ----------
// Afterimage sits invisibly on Star's tile so the stab line uses Star as
// the row's origin/center. On cast: scatter 4-6 ambient eye visuals
// (pure flavor) around Star within 5 tiles, then telegraph a wall-to-
// wall cardinal row through Star's tile and resolve as bone spikes.
// Eyes don't act, attack, or block — they just watch.
//
// Misfire (Row Skip): only the even-indexed tiles in the row spawn. Both
// the telegraph AND the strike skip the same tiles, so players can read
// the gaps in advance and reposition onto a safe odd-indexed tile.

/obj/effect/serio_afterimage/snow_eyes
	name = "afterimage — Snow Cabin"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "eyeturf_blink"
	alpha = 0
	attack_key = "snow_eyes"
	total_duration = 2.5 SECONDS
	spawn_sound = 'sound/effects/glassbr1.ogg'
	spawn_sound_volume = 40
	/// snow_cabin.dm:38 — bone-stab line wall-to-wall telegraph.
	borrowed_warning_visual = /obj/effect/temp_visual/snow_cabin_bone_stab_warning
	/// snow_cabin.dm:49 — bone spike strike sprite.
	borrowed_impact_visual = /obj/effect/temp_visual/snow_cabin_bone_stab
	var/spike_damage = 35
	var/eye_count_min = 4
	var/eye_count_max = 6
	var/eye_range = 5
	/// Half-length of the row in tiles. 8 = a 17-tile total row centered on Star.
	var/row_half_length = 8
	var/clean_wind_up = 1.2 SECONDS
	var/misfire_wind_up = 0.7 SECONDS

/obj/effect/serio_afterimage/snow_eyes/SetupSpawn()
	if(!parent_star)
		return
	// Sit on Star's tile so the row is centered on the stage focal point.
	forceMove(get_turf(parent_star))

/obj/effect/serio_afterimage/snow_eyes/PerformAttack()
	if(QDELETED(src) || !parent_star)
		Dissipate()
		return
	SpawnAmbientEyes()
	sleep(0.6 SECONDS)
	if(QDELETED(src))
		return
	var/turf/center = get_turf(parent_star)
	if(!center)
		Dissipate()
		return
	// Pick a cardinal axis for the row. NORTH = vertical (varies Y),
	// EAST = horizontal (varies X). South/West are equivalent — the row
	// extends in BOTH directions from center.
	var/axis = pick(NORTH, EAST)
	var/list/row_turfs = BuildRow(center, axis, row_half_length)
	if(!length(row_turfs))
		Dissipate()
		return
	// Misfire: keep only even-indexed tiles (1-based). Visible gaps in
	// both telegraph and strike give players the read-and-reposition out.
	var/list/strike_turfs = list()
	if(is_misfire)
		for(var/i in 1 to length(row_turfs))
			if((i % 2) == 0)
				strike_turfs += row_turfs[i]
	else
		strike_turfs = row_turfs.Copy()
	if(!length(strike_turfs))
		Dissipate()
		return
	var/wind_up = is_misfire ? misfire_wind_up : clean_wind_up
	for(var/turf/T as anything in strike_turfs)
		var/obj/effect/temp_visual/snow_cabin_bone_stab_warning/W = new(T, wind_up)
		W.setDir(axis)
	var/list/danger_humans = list()
	for(var/turf/T as anything in strike_turfs)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	sleep(wind_up)
	if(QDELETED(src))
		return
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 70, TRUE, 5)
	var/list/hit = list()
	for(var/turf/T as anything in strike_turfs)
		new /obj/effect/temp_visual/snow_cabin_bone_stab(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(spike_damage, RED_DAMAGE, parent_star,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			hit |= H
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)
	if(is_misfire)
		ReportMisfire()
	Dissipate()

/obj/effect/serio_afterimage/snow_eyes/proc/SpawnAmbientEyes()
	if(!parent_star)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(eye_range, parent_star))
		candidates += T
	var/count = rand(eye_count_min, eye_count_max)
	for(var/i in 1 to count)
		if(!length(candidates))
			break
		var/turf/T = pick_n_take(candidates)
		new /obj/effect/temp_visual/serio_ambient_eye(T)

/// 3-wide row centered on `center` along `axis`. For NORTH/SOUTH the row
/// varies Y and is 3 columns wide on X; for EAST/WEST it varies X and is
/// 3 rows tall on Y. Matches the source cabin's `SweepBoneSpikes` shape.
/obj/effect/serio_afterimage/snow_eyes/proc/BuildRow(turf/center, axis, half_length)
	. = list()
	if(!center)
		return
	var/dx = (axis == EAST || axis == WEST) ? 1 : 0
	var/dy = (axis == NORTH || axis == SOUTH) ? 1 : 0
	// Perpendicular offsets: 3-wide stripe on the axis perpendicular to
	// the row's direction of travel.
	var/perp_dx = (axis == NORTH || axis == SOUTH) ? 1 : 0
	var/perp_dy = (axis == EAST || axis == WEST) ? 1 : 0
	for(var/i in -half_length to half_length)
		for(var/p in -1 to 1)
			var/turf/T = locate(
				center.x + (dx * i) + (perp_dx * p),
				center.y + (dy * i) + (perp_dy * p),
				center.z,
			)
			if(T && !T.density)
				. += T

// Pure-flavor watcher. Spawned around Star while the bone stab winds up,
// fades out shortly after the strike resolves. No collision, no damage,
// no AI — the brainstorm's "they simply watch" beat made literal.
/obj/effect/temp_visual/serio_ambient_eye
	name = "watchful eye"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "eyeturf_blink"
	color = "#1e61ff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 2 SECONDS
	alpha = 200

// ---------- Implemented: Blade Priest Volley ----------
// Afterimage spawns within 4 tiles of Star and stacks four blade icons
// at its tile as a setup telegraph. Then launches the blades one at a
// time, with a stagger between each launch — mirrors Sermon Volley's
// LaunchVolleyBlade pattern from blade_priest.dm. Each blade re-picks
// its target at launch time so a freshly-repositioned player gets
// pulled in; otherwise it carves a column toward the nearest human.
//
// Misfire (Target Swap): every blade locks Star as its target instead.
// All four columns converge on Star — self-damage + rupture
// multiplicity per the brainstorm.

/obj/effect/serio_afterimage/blade_volley
	name = "afterimage — Blade Priest"
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "blade_priest"
	attack_key = "blade_volley"
	total_duration = 4.5 SECONDS
	spawn_sound = 'sound/weapons/rapierhit.ogg'
	spawn_sound_volume = 50
	/// blade_priest.dm:40 — dash telegraph painted along the column.
	borrowed_warning_visual = /obj/effect/temp_visual/blade_priest_dash_warning
	borrowed_impact_visual = null
	var/blade_count = 4
	/// Deciseconds between successive setup-icon stacks.
	var/blade_setup_delay = 2
	/// Wall-clock gap between successive blade launches.
	var/blade_launch_stagger = 0.6 SECONDS
	/// Time the per-blade column telegraph holds before the strike resolves.
	var/blade_telegraph = 0.5 SECONDS
	var/blade_damage = 18
	var/blade_rupture_stacks = 3
	var/column_overshoot = 3

/obj/effect/serio_afterimage/blade_volley/SetupSpawn()
	if(!parent_star)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(4, parent_star))
		candidates += T
	if(length(candidates))
		forceMove(pick(candidates))

/obj/effect/serio_afterimage/blade_volley/PerformAttack()
	sleep(0.5 SECONDS)
	if(QDELETED(src) || !parent_star)
		Dissipate()
		return
	// Setup beat: stack `blade_count` blade icons so players can read the
	// volley size before the first launch.
	for(var/i in 1 to blade_count)
		if(QDELETED(src))
			return
		new /obj/effect/temp_visual/serio_volley_blade(get_turf(src))
		playsound(get_turf(src), 'sound/weapons/rapierhit.ogg', 30, TRUE, 3)
		sleep(blade_setup_delay)
	// Launch sequentially. Each blade is async so their strikes can
	// resolve in parallel as the next launches.
	for(var/i in 1 to blade_count)
		if(QDELETED(src))
			return
		LaunchBlade()
		if(i < blade_count)
			sleep(blade_launch_stagger)
	// Hold for the last blade's telegraph + strike to resolve before the
	// afterimage dissipates.
	sleep(blade_telegraph + 0.2 SECONDS)
	if(is_misfire)
		ReportMisfire()
	Dissipate()

/// Async single blade dash. Re-picks target at launch (mirrors
/// LaunchVolleyBlade from the source), paints column telegraph, strikes
/// along the line, applies damage + rupture, reports dodgers. Uses
/// `get_ranged_target_turf_direct` for a free-angle line so a target
/// that isn't lined up cardinally / diagonally still gets a proper
/// column — the source RunSingleDash does the same.
/obj/effect/serio_afterimage/blade_volley/proc/LaunchBlade()
	set waitfor = FALSE
	if(QDELETED(src) || !parent_star)
		return
	// Misfire: every blade aims at Star, no matter the player positions.
	var/atom/target = is_misfire ? parent_star : PickNearestPlayer()
	if(!target || QDELETED(target))
		return
	var/turf/start = get_turf(src)
	var/turf/target_tile = get_turf(target)
	if(!start || !target_tile || start == target_tile)
		return
	var/dist = get_dist(start, target_tile)
	var/turf/end = get_ranged_target_turf_direct(start, target_tile, dist + column_overshoot)
	if(!end)
		return
	var/list/raw_line = getline(start, end)
	var/list/column = list()
	for(var/turf/T as anything in raw_line)
		if(T.density)
			break
		column += T
	if(!length(column))
		return
	for(var/turf/T as anything in column)
		new /obj/effect/temp_visual/blade_priest_dash_warning(T)
	var/list/danger_humans = list()
	for(var/turf/T as anything in column)
		for(var/mob/living/carbon/human/H in T)
			danger_humans |= H
	playsound(start, 'sound/weapons/rapierhit.ogg', 45, TRUE, 5)
	sleep(blade_telegraph)
	if(QDELETED(src))
		return
	playsound(start, 'sound/weapons/rapierhit.ogg', 65, TRUE, 6)
	// Spawn the flying-blade visual in parallel with the damage tick.
	// Mirrors the source priest's RunSingleDash: rotate the talking_sword
	// sprite to face the landing turf, then pixel-animate it across the
	// column at the same flight speed.
	var/turf/landing = column[length(column)]
	SpawnBladeFlight(start, landing)
	var/list/hit = list()
	for(var/turf/T as anything in column)
		for(var/mob/living/L in T)
			if(L.stat == DEAD)
				continue
			if(!ishuman(L) && L != parent_star)
				continue
			L.deal_damage(blade_damage, BLACK_DAMAGE, parent_star,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			L.apply_lc_rupture(blade_rupture_stacks)
			if(ishuman(L))
				hit |= L
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)

/// Pixel-animates a talking_sword sprite from `start` to `landing` so
/// the player sees the blade physically traverse the column. Rotation
/// uses the same +45° offset the source blade_priest uses to align its
/// NW-pointing sprite with the dash direction.
/obj/effect/serio_afterimage/blade_volley/proc/SpawnBladeFlight(turf/start, turf/landing)
	if(!start || !landing || start == landing)
		return
	var/obj/effect/serio_volley_blade_flight/B = new(start)
	if(parent_star)
		B.color = parent_star.afterimage_color
	B.transform = matrix().Turn(Get_Angle(start, landing) + 45)
	var/dx_px = (landing.x - start.x) * 32
	var/dy_px = (landing.y - start.y) * 32
	var/flight_time = 4
	animate(B, pixel_x = dx_px, pixel_y = dy_px, time = flight_time, easing = QUAD_EASING)
	QDEL_IN(B, flight_time + 2)

/obj/effect/serio_afterimage/blade_volley/proc/PickNearestPlayer()
	if(!parent_star)
		return null
	var/mob/living/carbon/human/best
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in view(parent_star.view_range, parent_star))
		if(H.stat == DEAD)
			continue
		var/d = get_dist(parent_star, H)
		if(d < best_dist)
			best_dist = d
			best = H
	return best

// Four of these stack at the afterimage's tile during volley setup —
// the "blades accumulate" beat. Purely a telegraph visual; the dash
// column applies the damage, not the stacked icons.
/obj/effect/temp_visual/serio_volley_blade
	name = "floating blade"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "talking_sword"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 180

// The animating blade that pixel-flies from the afterimage's tile to
// the landing turf during a launch. Not a temp_visual subtype so we
// control its qdel via QDEL_IN — pixel animations need the loc to be
// stable for the duration of the animate() call.
/obj/effect/serio_volley_blade_flight
	name = "blade"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "talking_sword"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

// ---------- Implemented: Achiyalabopa Divine Thunderbolt ----------
// Afterimage spawns on a random tile within Star's view, then drops a
// handful of 3x3 thunderbolt warnings around the room — one centered on
// each visible player plus a few random extras for clean casts. Each
// thunderbolt is a self-resolving /obj/effect/divine_thunderbolt
// instance: it sits as a warning for `duration`, then auto-explodes for
// PALE damage in a `range = 1` AoE based on who's standing in it AT
// EXPLOSION TIME. Players who walk out before the explosion are safe.
//
// Misfire (Stale Target): the timing compresses (shorter warning
// window) and the extra random thunderbolts are dropped. Result is a
// smaller, faster, easier-to-dodge spread — players quickly learn to
// sidestep on telegraph and the misfire feedback adds up.

/obj/effect/serio_afterimage/achiya_bolt
	name = "afterimage — Achiyalabopa"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs4.dmi'
	icon_state = "achiyalabopa"
	pixel_x = -16
	base_pixel_x = -16
	attack_key = "achiya_bolt"
	total_duration = 3 SECONDS
	spawn_sound = 'sound/abnormalities/thunderbird/tbird_bolt.ogg'
	spawn_sound_volume = 45
	/// achiyalabopa.dm:60 — pre-strike skystrike telegraph on the target tile.
	borrowed_warning_visual = /obj/effect/temp_visual/divine_judgment_warning
	/// achiyalabopa.dm:72 — the lightning column drop sprite.
	borrowed_impact_visual = /obj/effect/temp_visual/divine_judgment_strike
	var/bolt_damage = 30
	var/clean_telegraph = 2 SECONDS
	var/misfire_telegraph = 1 SECONDS
	/// Extra random thunderbolts clean casts scatter to flood the stage.
	var/clean_extra_bolts = 3
	/// Minimum spacing between random thunderbolt centers.
	var/extra_min_spacing = 2

/obj/effect/serio_afterimage/achiya_bolt/SetupSpawn()
	if(!parent_star)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(parent_star.view_range, parent_star))
		candidates += T
	if(length(candidates))
		forceMove(pick(candidates))

/obj/effect/serio_afterimage/achiya_bolt/PerformAttack()
	if(QDELETED(src) || !parent_star)
		Dissipate()
		return
	sleep(0.4 SECONDS)
	if(QDELETED(src))
		return
	var/telegraph_duration = is_misfire ? misfire_telegraph : clean_telegraph
	// Drop one thunderbolt per visible player + extras on clean casts.
	var/list/cluster_centers = list()
	for(var/mob/living/carbon/human/H as anything in PickAllPlayers())
		var/turf/T = get_turf(H)
		if(!T)
			continue
		cluster_centers |= T
		SpawnThunderbolt(T, telegraph_duration)
	if(!length(cluster_centers))
		Dissipate()
		return
	if(!is_misfire)
		SpawnRandomThunderbolts(cluster_centers, telegraph_duration, clean_extra_bolts)
	// Snapshot every human currently inside any 3x3 — these are the
	// "threatened" set for dodge tracking. After the bolts auto-explode
	// we'll check who's still standing in a 3x3 vs. who walked out.
	var/list/danger_humans = list()
	for(var/turf/center as anything in cluster_centers)
		for(var/turf/T in range(1, center))
			for(var/mob/living/carbon/human/H in T)
				danger_humans |= H
	// Each thunderbolt fires its own Explode timer at `telegraph_duration`.
	// Wait the window out (+ a small buffer for the timer to fire).
	sleep(telegraph_duration + 0.3 SECONDS)
	if(QDELETED(src))
		return
	// Post-snapshot: any threatened human still inside any 3x3 took a hit.
	// Anyone who walked clear dodged — credit pressure to parent_star.
	var/list/hit = list()
	for(var/mob/living/H as anything in danger_humans)
		if(QDELETED(H))
			continue
		var/turf/now = get_turf(H)
		if(!now)
			continue
		for(var/turf/center as anything in cluster_centers)
			if(get_dist(now, center) <= 1)
				hit |= H
				break
	if(length(danger_humans) && !length(hit))
		parent_star?.OnAttackMissed(attack_key)
	if(is_misfire)
		ReportMisfire()
	Dissipate()

/obj/effect/serio_afterimage/achiya_bolt/proc/SpawnThunderbolt(turf/center, telegraph_duration)
	if(!center)
		return
	var/obj/effect/divine_thunderbolt/serio/E = new(center, telegraph_duration, bolt_damage)
	E.parent_star = parent_star

/// Scatter `count` extra thunderbolts on random nearby floor tiles,
/// honoring a minimum spacing from already-staged centers. Mirrors the
/// boss's SummonThunder extra-bolt loop.
/obj/effect/serio_afterimage/achiya_bolt/proc/SpawnRandomThunderbolts(list/avoid_centers, telegraph_duration, count)
	if(!parent_star || count <= 0)
		return
	var/list/candidates = list()
	for(var/turf/open/T in view(parent_star.view_range, parent_star))
		candidates += T
	var/list/picked = list()
	var/safety = 50
	while(length(picked) < count && length(candidates) && safety > 0)
		safety--
		var/turf/T = pick_n_take(candidates)
		var/too_close = FALSE
		for(var/turf/already as anything in avoid_centers)
			if(get_dist(T, already) < extra_min_spacing)
				too_close = TRUE
				break
		if(too_close)
			continue
		for(var/turf/already as anything in picked)
			if(get_dist(T, already) < extra_min_spacing)
				too_close = TRUE
				break
		if(too_close)
			continue
		picked += T
	for(var/turf/T as anything in picked)
		SpawnThunderbolt(T, telegraph_duration)

// Subtype of the source thunderbolt that lets the afterimage customize
// the warning duration and the AoE damage per spawn. The parent's
// `master` field stays null (it's only used to call ShaveAndKillReapers
// on Phase-1 reaper kills, which don't apply here), but we keep a
// `parent_star` ref so a future pass could route damage attribution.
/obj/effect/divine_thunderbolt/serio
	var/mob/living/simple_animal/hostile/young_star/parent_star

/obj/effect/divine_thunderbolt/serio/Initialize(mapload, custom_duration, custom_damage)
	// Set tunables BEFORE calling super — parent's addtimer reads
	// `duration` immediately so we have to land the override first.
	if(custom_duration)
		duration = custom_duration
	if(custom_damage)
		boom_damage = custom_damage
	. = ..()

/obj/effect/divine_thunderbolt/serio/Destroy()
	parent_star = null
	return ..()
