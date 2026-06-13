/*
 * Curtain Call — zeal_s5n2 (serio_zeal_w2): Phase 2 of the Serio Zeal
 * finale. Two mobs cooperate to form the encounter:
 *
 *   - The Crystal: holds Star sealed inside. Only kill target. Alternates
 *     between Blue (sealed, immune) and Red (exposed, vulnerable). Red
 *     fires when the Overseer invokes a memory attack, plus an
 *     afterglow tail.
 *   - The Overseer: patrols around the Crystal, defending it with light
 *     pressure (Blue-phase) attacks and triggering the Crystal's memory
 *     attacks (Red windows). Cannot be killed — its stagger HP can be
 *     broken to knock it down, weakening the next memory attack, then
 *     it stands back up with full stagger HP after a fixed delay.
 *
 * See serio_brainstorm.md ("Phase 2 — The Overseer: The Seal") for the
 * full design: three HP brackets (Stage / Group / Confession), Blue/Red
 * damage gate, knockdown lever, mental decay / mental detonate status
 * loop, per-bracket Red-window attack pools.
 *
 * This pass adds the encounter framework: patrol AI, three Blue-phase
 * pressure attacks (Glance / Cold Word / Patrol Trail), memory
 * invocation cycle with per-bracket attack pool selection, status
 * effect plumbing, monologue system, bracket transitions. The per-
 * bracket memory attacks are STUBBED — each one currently just flips
 * the Crystal to red for the right duration with a flavor message;
 * concrete mechanics get filled in pass-by-pass.
 *
 * Sprites (placeholder):
 *   Crystal:   icons/effects/96x96.dmi state "smoke2" (96x96, needs
 *              pixel_x/y = -32 to center on the 32x32 tile)
 */

// ---------- The Crystal (Star's seal) ----------

/mob/living/simple_animal/hostile/serio_crystal
	name = "the Crystal"
	desc = "A crystal seal holding Star inside. It is glassy and cool when sealed; \
		it turns hot and crackable when the Overseer invokes a memory."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs3.dmi'
	icon_state = "overseer_crystal"
	icon_living = "overseer_crystal"
	icon_dead = "overseer_crystal"
	pixel_x = -32
	base_pixel_x = -32
	faction = list("serio_zeal")
	maxHealth = 10000
	health = 10000
	melee_damage_lower = 0
	melee_damage_upper = 0
	// Spawns sealed: 10% damage on every type. EnterRed/EnterBlue flip
	// these via ChangeResistances at the start/end of every Red window.
	damage_coeff = list(RED_DAMAGE = 0.1, WHITE_DAMAGE = 0.1, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.1)
	stat_attack = HARD_CRIT
	density = TRUE
	move_resist = MOVE_FORCE_OVERPOWERING
	move_to_delay = 999
	mob_biotypes = MOB_MINERAL
	// Marks the crystal as "glass-like" so Phase 2 projectiles with
	// projectile_phasing = PASSGLASS phase through harmlessly. Without
	// this, the lance from echo_anchor would impact the crystal en
	// route to the Knight on the same row.
	pass_flags_self = PASSGLASS
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	// Default color is the Blue (sealed) tint — light blue so players
	// can read at a glance "this is currently immune."
	color = "#a0d0ff"
	// ---- State ----
	/// FALSE = Blue (sealed, immune to player damage). TRUE = Red
	/// (exposed). Overseer flips this on memory invocation; the
	/// memory attack + its afterglow tail are the Red window.
	var/is_red = FALSE
	/// HP bracket index (1, 2, 3) corresponding to brainstorm's
	/// 100-75 / 75-25 / 25-0 buckets. Recomputed after every damage
	/// event in UpdateBracket.
	var/current_bracket = 1
	/// Back-ref to the Overseer that's defending this Crystal.
	var/mob/living/simple_animal/hostile/serio_overseer/parent_overseer
	/// Tint applied during Blue (sealed, immune). Restored every time
	/// the Red window closes.
	var/blue_tint = "#a0d0ff"
	/// Tint applied during Red, per bracket. Looked up in OnBracketChanged.
	var/red_tint = "#ff5f5f"
	/// Phase 2 marker. Once flipped, the Crystal is permanently
	/// invulnerable and the Overseer has transitioned to Phase 2.
	var/is_invulnerable_p2 = FALSE

/mob/living/simple_animal/hostile/serio_crystal/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	// Sealed-star underlay — renders behind the crystal sprite so it
	// reads as Star trapped inside the seal. The crystal's pixel_x = -32
	// is the 96x96 centering offset; the 32x32 sealed_star cancels that
	// to recentre on the tile, and pixel_y pushes it up into the visual
	// middle of the crystal body.
	var/mutable_appearance/sealed_star = mutable_appearance(
		'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi',
		"sealed_star"
	)
	sealed_star.pixel_x = 32
	sealed_star.pixel_y = 32
	underlays += sealed_star

/mob/living/simple_animal/hostile/serio_crystal/Destroy()
	if(parent_overseer && !QDELETED(parent_overseer))
		parent_overseer.parent_crystal = null
	parent_overseer = null
	return ..()

/mob/living/simple_animal/hostile/serio_crystal/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_crystal/AttackingTarget(atom/attacked_target)
	return FALSE

/// Run the parent adjust and then re-check the HP bracket. Blue vs
/// Red is enforced through `damage_coeff` (set in EnterBlue/EnterRed
/// via ChangeResistances) — Blue takes 10% damage, Red takes 100%.
/// Phase 2 lockout: once `is_invulnerable_p2` is set, all damage is
/// blocked outright. On the first crystal "death" (health <= 0) the
/// parent Overseer is signalled to enter Phase 2.
/mob/living/simple_animal/hostile/serio_crystal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(is_invulnerable_p2 && amount > 0)
		return 0
	. = ..(amount, updating_health, forced)
	if(. > 0)
		UpdateBracket()
	if(health <= 0 && parent_overseer && !QDELETED(parent_overseer) && !parent_overseer.phase_2)
		parent_overseer.TriggerPhase2Entry()

/// Recalculates `current_bracket` from current health ratio. Called
/// from adjustHealth on damage. The bracket controls which attack
/// pool the Overseer draws from on its next memory invocation.
/mob/living/simple_animal/hostile/serio_crystal/proc/UpdateBracket()
	if(!maxHealth)
		return
	var/ratio = health / maxHealth
	var/new_bracket
	if(ratio > 0.75)
		new_bracket = 1
	else if(ratio > 0.25)
		new_bracket = 2
	else
		new_bracket = 3
	if(new_bracket != current_bracket)
		current_bracket = new_bracket
		OnBracketChanged(new_bracket)

/// Bracket transition: route to the Overseer for a dialogue beat and
/// swap the Red tint so the visual escalates with the memory phase.
/mob/living/simple_animal/hostile/serio_crystal/proc/OnBracketChanged(new_bracket)
	switch(new_bracket)
		if(1)
			red_tint = "#ff5f5f"
		if(2)
			red_tint = "#ff7030"
		if(3)
			red_tint = "#c30fff"
	if(is_red)
		color = red_tint
	if(parent_overseer && !QDELETED(parent_overseer))
		parent_overseer.OnCrystalBracketChanged(new_bracket)

/// Flips the Crystal to Red for `duration` deciseconds, then auto-flips
/// back to Blue. Overseer calls this when it invokes a memory. The
/// resistance flip via ChangeResistances is what actually drops the
/// damage gate — `is_red` and the tint are read-only signals downstream.
/mob/living/simple_animal/hostile/serio_crystal/proc/EnterRed(duration)
	is_red = TRUE
	color = red_tint
	ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1))
	if(duration > 0)
		addtimer(CALLBACK(src, PROC_REF(EnterBlue)), duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_crystal/proc/EnterBlue()
	if(QDELETED(src))
		return
	is_red = FALSE
	color = blue_tint
	ChangeResistances(list(RED_DAMAGE = 0.1, WHITE_DAMAGE = 0.1, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.1))

// ---------- The Overseer ----------

/mob/living/simple_animal/hostile/serio_overseer
	name = "Overseer"
	desc = "Serio Zeal's inner voice given a body. It paces around the crystal, \
		watching over it. It does not look unkind."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "overseer"
	icon_living = "overseer"
	icon_dead = "overseer"
	faction = list("serio_zeal")
	// `maxHealth` here is STAGGER HP, not kill HP. Reaching 0 enters the
	// knockdown state; the Overseer cannot be killed.
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 0
	melee_damage_upper = 0
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	sight = SEE_MOBS
	density = TRUE
	speed = 4
	move_to_delay = 6
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	// ---- Refs ----
	/// The Crystal this Overseer is defending. Wired by external spawn
	/// code or by Initialize when no Crystal is present.
	var/mob/living/simple_animal/hostile/serio_crystal/parent_crystal
	// ---- Phase 2 ----
	/// Set TRUE on Phase 2 entry. Locks the Overseer in place
	/// (Move() returns FALSE), kills MainTick, and gates the Phase 2
	/// attack rotation when later steps wire it up.
	var/phase_2 = FALSE
	/// Cached spawn anchors for anti-Knight attacks. Computed once at
	/// Phase 2 entry: a 1×5 vertical column of turfs 2 tiles behind
	/// the Overseer. Each projectile picks a random tile from this
	/// pool so spawns feel atmospheric instead of single-point.
	var/list/turf/echo_anchor_pool
	/// Phase 2 support mob refs. Spawned by SpawnSupportMobs() at
	/// Phase 2 entry.
	var/mob/living/simple_animal/hostile/serio_knight/knight_ref
	var/mob/living/simple_animal/hostile/serio_sage/sage_ref
	/// Set TRUE while a B3 Knight-aware AoE is telegraphing. Blocks
	/// FireKnightAwareAoE from re-firing during the 5s charge window.
	var/aoe_charging = FALSE
	// ---- Murmur (Phase 2 minion) spawn state ----
	/// Cached perimeter turfs (outer ring around the crystal) used as
	/// Murmur spawn points. Built once at Phase 2 entry.
	var/list/turf/perimeter_spawn_pool
	/// Live Murmur references. Updated by SpawnMurmur / Murmur Destroy.
	var/list/active_murmurs = list()
	/// Per-bracket Murmur cap: 2 in B1, 3 in B2, 4 in B3.
	var/murmurs_max_for_bracket = 2
	/// world.time tracker for MurmurSpawnTick — when to spawn the next.
	var/next_murmur_spawn_at = 0
	// ---- Bracket 3 persistent storm ----
	/// TRUE between bracket-2→bracket-3 transition and the third slash.
	/// Gates Bracket3EchoTick + survives across the bracket; cleared by
	/// EndBracket3Storm.
	var/b3_storm_active = FALSE
	/// Live snow-overlay refs placed at bracket-3 entry. Qdel'd on
	/// EndBracket3Storm (and on the Overseer's own Destroy via
	/// CleanupSpawnedObjects).
	var/list/b3_snow_overlays = list()
	// ---- Knockdown ----
	var/knocked_down = FALSE
	var/standup_at = 0
	var/standup_delay = 12 SECONDS
	// ---- Main loop ----
	var/main_tick_timer
	var/main_tick_interval = 1 SECONDS
	/// View range used by FindNearestPlayer and the Overseer's
	/// general targeting reach.
	var/view_range = 15
	// ---- Patrol ----
	/// Orbit radius around the Crystal (tiles).
	var/patrol_distance = 4
	/// Time between picking a new orbital destination.
	var/patrol_step_interval = 5 SECONDS
	var/patrol_next_step_time = 0
	// ---- Blue-phase attack cooldowns ----
	var/next_glance = 0
	var/glance_cooldown = 5 SECONDS
	var/glance_telegraph = 1 SECONDS
	var/glance_damage = 25
	var/glance_decay_stacks = 2
	/// Glance leaves a cold-word puddle on each AoE tile after detonation.
	var/glance_puddle_duration = 3 SECONDS
	var/glance_puddle_tick_damage = 5
	var/glance_puddle_tick_decay = 1
	var/glance_puddle_tick_interval = 1 SECONDS
	var/next_cold_word = 0
	var/cold_word_cooldown = 7 SECONDS
	var/cold_word_telegraph = 1 SECONDS
	var/cold_word_duration = 3 SECONDS
	var/cold_word_tick_damage = 8
	var/cold_word_tick_decay = 1
	var/cold_word_tick_interval = 0.7 SECONDS
	// ---- Patrol Trail ----
	var/patrol_trail_lifetime = 1.5 SECONDS
	var/patrol_trail_damage = 15
	// ---- Memory invocation cycle ----
	/// Wall-clock time between invocations measured from invocation
	/// START — sets the full Blue/Red cycle length.
	var/memory_invocation_cooldown = 20 SECONDS
	var/next_memory_invocation = 0
	/// 1s channel cue before the Crystal turns Red.
	var/channel_duration = 1 SECONDS
	/// Length of the Red window the chosen attack runs in.
	var/memory_red_duration = 7 SECONDS
	/// Crystal stays Red for this long after the attack finishes.
	var/memory_afterglow = 4 SECONDS
	/// TRUE between StartMemoryInvocation and EndMemoryInvocation. Blocks
	/// patrol movement, Blue-phase attacks, and concurrent invocations.
	var/invoking_memory = FALSE
	// ---- Monologue ----
	var/last_monologue_time = 0
	var/monologue_cooldown = 8 SECONDS
	var/list/bracket_channel_lines
	var/list/bracket_transition_lines

/mob/living/simple_animal/hostile/serio_overseer/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	InitMonologueLines()
	if(!mapload)
		SpawnCrystalNearby()
	main_tick_timer = addtimer(CALLBACK(src, PROC_REF(MainTick)), main_tick_interval, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/Destroy()
	if(main_tick_timer)
		deltimer(main_tick_timer)
		main_tick_timer = null
	CleanupSpawnedObjects()
	if(parent_crystal && !QDELETED(parent_crystal))
		parent_crystal.parent_overseer = null
		qdel(parent_crystal)
	parent_crystal = null
	if(knight_ref && !QDELETED(knight_ref))
		qdel(knight_ref)
	knight_ref = null
	if(sage_ref && !QDELETED(sage_ref))
		qdel(sage_ref)
	sage_ref = null
	return ..()

/// Wipes the long-lived objects the Overseer owns — the Murmur choir
/// and the echo-line sparkle column. Short-lived attack visuals
/// (puddles, AoE warnings, walker figures, in-flight lances) all carry
/// their own auto-qdel timers and clean themselves up within a few
/// seconds; iterating `world` for them would be much more expensive
/// than just letting them expire. Called from Destroy.
/mob/living/simple_animal/hostile/serio_overseer/proc/CleanupSpawnedObjects()
	for(var/mob/living/simple_animal/hostile/serio_murmur/M as anything in active_murmurs)
		if(!QDELETED(M))
			qdel(M)
	active_murmurs.Cut()
	if(islist(echo_anchor_pool))
		for(var/turf/T as anything in echo_anchor_pool)
			if(!T)
				continue
			for(var/obj/effect/temp_visual/serio_echo_anchor/E in T)
				qdel(E)
		echo_anchor_pool.Cut()
	for(var/obj/effect/temp_visual/V as anything in b3_snow_overlays)
		if(!QDELETED(V))
			qdel(V)
	b3_snow_overlays.Cut()
	b3_storm_active = FALSE

/// Convenience for admin / varedit spawning: drops a Crystal at the
/// Overseer's tile and steps the Overseer to a starting patrol slot.
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnCrystalNearby()
	if(parent_crystal && !QDELETED(parent_crystal))
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/mob/living/simple_animal/hostile/serio_crystal/C = new(center)
	ScaleSpawnedHPWithSelf(C)
	BindCrystal(C)
	var/turf/start = get_ranged_target_turf(center, EAST, patrol_distance)
	if(start && !start.density)
		forceMove(start)

/// Applies the same maxHealth multiplier the Overseer is currently
/// carrying to a newly-spawned mob (crystal, Murmur). The refraction
/// boss-scaler bumps the Overseer's maxHealth at spawn-time based on
/// lobby size; this proc captures that ratio and re-applies it so the
/// supporting mobs scale together with the boss.
/mob/living/simple_animal/hostile/serio_overseer/proc/ScaleSpawnedHPWithSelf(mob/living/simple_animal/hostile/M)
	if(QDELETED(M))
		return
	var/base = initial(maxHealth)
	if(base <= 0)
		return
	var/hp_mult = maxHealth / base
	if(hp_mult <= 1)
		return
	M.maxHealth = round(M.maxHealth * hp_mult)
	M.health = M.maxHealth

/// Pair this Overseer with a Crystal so both ends carry the back-ref.
/mob/living/simple_animal/hostile/serio_overseer/proc/BindCrystal(mob/living/simple_animal/hostile/serio_crystal/C)
	if(!istype(C))
		return
	parent_crystal = C
	C.parent_overseer = src

// ---------- Phase 2 entry ----------

/// Phase 2 lock on movement. Once `phase_2` is set, the Overseer
/// becomes stationary at its fixed stage position. TRAIT_IMMOBILIZED
/// has no effect on simple_animal mobs in this codebase, so this is
/// the override path.
/mob/living/simple_animal/hostile/serio_overseer/Move()
	if(phase_2)
		return FALSE
	return ..()

/// Called from the Crystal's adjustHealth the first time its HP
/// hits 0. Refills the Crystal, flips it permanently invulnerable,
/// then hands off to EnterPhase2 for the actual stage setup.
/mob/living/simple_animal/hostile/serio_overseer/proc/TriggerPhase2Entry()
	if(phase_2)
		return
	if(QDELETED(parent_crystal))
		return
	parent_crystal.adjustBruteLoss(-parent_crystal.maxHealth, forced = TRUE)
	parent_crystal.is_invulnerable_p2 = TRUE
	parent_crystal.ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	EnterPhase2()

/// Locks the stage: flips the phase_2 flag, snaps the Overseer to its
/// fixed tile (3 west of the crystal), caches the echo-line anchor for
/// later anti-Knight attack spawns, and brings the support mobs onto
/// the stage via SpawnSupportMobs.
/mob/living/simple_animal/hostile/serio_overseer/proc/EnterPhase2()
	if(phase_2)
		return
	phase_2 = TRUE
	// Stage 1 (instant): crystal cracks, Overseer takes the floor with
	// a line, becomes invulnerable. Phase 1 in-flight attacks force-end.
	SetCrystalIconState("overseer_crystal_crack")
	say("Wait — no. The seal was supposed to hold. You weren't meant to reach me.")
	visible_message(span_userdanger("The seal strains. The stage rearranges itself."))
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	UnlockOverseerPhase2Reveal()
	ForceEndInflightAttacks()
	// Stage 2 (5s later): support mobs arrive, Overseer takes its
	// fixed tile, echo-anchor column boots up.
	addtimer(CALLBACK(src, PROC_REF(CompletePhase2Transition)), 5 SECONDS, TIMER_STOPPABLE)

/// Wipes every persistent Phase 1 attack visual within view of the
/// Crystal so the 5-second Phase 2 transition window starts on a
/// clean stage. Also drops the memory-invocation lock + the Red
/// damage window so a stuck cycle doesn't leak past the transition.
/mob/living/simple_animal/hostile/serio_overseer/proc/ForceEndInflightAttacks()
	invoking_memory = FALSE
	walk(src, 0)
	if(parent_crystal && !QDELETED(parent_crystal))
		parent_crystal.EnterBlue()
	var/turf/center = parent_crystal ? get_turf(parent_crystal) : get_turf(src)
	if(!center)
		return
	for(var/obj/effect/temp_visual/serio_void_singularity/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_void_storm/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_void_macro_aoe/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_void_mini_aoe/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_light_wind_fog/V in view(20, center))
		qdel(V)
	for(var/obj/effect/serio_light_wind_ring/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_echo_snow_storm/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_echo_snow_ground/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_echo_figure/V in view(20, center))
		qdel(V)
	for(var/obj/effect/serio_cold_word_puddle/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_closed_circle_ring/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_errant_draft/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_huddle_illusion/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_galaxy_safe_zone/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_glance_warning/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_cold_word_warning/V in view(20, center))
		qdel(V)
	for(var/obj/effect/temp_visual/serio_burnout_pulse_warning/V in view(20, center))
		qdel(V)

/// Second-stage Phase 2 entry. Runs 5 seconds after EnterPhase2 once
/// the in-flight Phase 1 attacks have been swept. Builds the echo
/// column, snaps the Overseer to its fixed tile, brings the support
/// mobs onstage, kicks off the anti-Knight + Murmur ticks.
/mob/living/simple_animal/hostile/serio_overseer/proc/CompletePhase2Transition()
	if(QDELETED(src))
		return
	var/turf/crystal_turf = parent_crystal ? get_turf(parent_crystal) : null
	if(crystal_turf)
		var/turf/overseer_pos = locate(crystal_turf.x - 3, crystal_turf.y, crystal_turf.z)
		if(overseer_pos)
			forceMove(overseer_pos)
		// Overseer is west of the crystal — face EAST to look at it.
		setDir(EAST)
		// Echo-line column sits 2 tiles west of the Overseer (which is
		// 3 tiles west of the crystal), spanning 5 tiles vertically.
		// Each projectile picks a random tile from this pool at fire
		// time; the salvo uses all 5 for a wider fan.
		echo_anchor_pool = list()
		for(var/dy in -2 to 2)
			var/turf/T = locate(crystal_turf.x - 5, crystal_turf.y + dy, crystal_turf.z)
			if(T)
				echo_anchor_pool += T
				new /obj/effect/temp_visual/serio_echo_anchor(T)
	SpawnSupportMobs()
	BuildPerimeterPool()
	// First anti-Knight attack fires 2s after Phase 2 entry — quick
	// enough to read as "the encounter is alive", short enough that
	// players know something is wrong if nothing fires. Subsequent
	// ticks chain themselves at the bracket cadence (see Phase2Tick).
	addtimer(CALLBACK(src, PROC_REF(Phase2Tick)), 2 SECONDS, TIMER_STOPPABLE)
	// Murmur spawn loop runs on its own 1s tick so the 5s
	// empty-recovery clock keeps ticking between Phase2Tick casts.
	addtimer(CALLBACK(src, PROC_REF(MurmurSpawnTick)), 1 SECONDS, TIMER_STOPPABLE)
	// B1 dialogue exchange fires after the support mobs finish their
	// fade-in. B2/B3 exchanges fire from OnKnightSlashLanded.
	addtimer(CALLBACK(src, PROC_REF(PlayBracketDialogue), 1), 1.5 SECONDS, TIMER_STOPPABLE)

/// Marks the `overseer_phase_2` reveal event unlocked for every live ckey
/// in the same run as this Overseer. Persisted to disk via
/// SSpersistence.SaveRefractionEvents() inside MarkEventUnlocked. After
/// this fires the Knight / Sage / Murmur silhouettes upgrade to revealed
/// cards on the briefing, and the gated Overseer / Crystal attack +
/// passive cards (`hidden_until = "overseer_phase_2"`) become visible.
/mob/living/simple_animal/hostile/serio_overseer/proc/UnlockOverseerPhase2Reveal()
	var/datum/refraction_wave_controller/wc = GLOB.refraction_wave_mob_owners[src]
	if(!wc)
		return
	var/list/live_ckeys = list()
	for(var/datum/refraction_run/R as anything in SSrefraction_railway.active_runs)
		if(R.run_uid != wc.run_uid)
			continue
		for(var/mob/M as anything in R.members)
			if(M.ckey && M.stat != DEAD)
				live_ckeys += M.ckey
		break
	if(length(live_ckeys))
		SSrefraction_railway.MarkEventUnlocked(live_ckeys, "overseer_phase_2")

/mob/living/simple_animal/hostile/serio_overseer/proc/BuildPerimeterPool()
	perimeter_spawn_pool = list()
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	// Spawn pool: any non-dense tile within view 8 of the crystal,
	// but at least 3 tiles away from the Knight and the Sage so
	// Murmurs don't crowd the support mobs.
	for(var/turf/T in view(8, crystal_turf))
		if(T.density)
			continue
		if(knight_ref && !QDELETED(knight_ref) && get_dist(T, knight_ref) < 3)
			continue
		if(sage_ref && !QDELETED(sage_ref) && get_dist(T, sage_ref) < 3)
			continue
		perimeter_spawn_pool += T

/// Spawn the Sage and Knight at their fixed stage tiles. Mirrors the
/// SpawnCrystalNearby() pattern: the parent boss creates the support
/// mobs mid-encounter rather than them being part of the wave roster.
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnSupportMobs()
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/turf/knight_pos = locate(crystal_turf.x + 2, crystal_turf.y, crystal_turf.z)
	var/turf/sage_pos = locate(crystal_turf.x + 2, crystal_turf.y + 3, crystal_turf.z)
	if(knight_pos)
		knight_ref = new /mob/living/simple_animal/hostile/serio_knight(knight_pos)
		// Knight is east of the crystal — face WEST to look at it.
		knight_ref.setDir(WEST)
	if(sage_pos)
		sage_ref = new /mob/living/simple_animal/hostile/serio_sage(sage_pos)
		// Sage is north of the Knight (= north-east of the crystal) —
		// face SOUTH so the sight-line covers both the Knight tile and
		// the crystal/player movement zone.
		sage_ref.setDir(SOUTH)
	BindSupport(knight_ref, sage_ref)

/// Wire up the parent/sibling back-references on the support mobs.
/// Mirrors BindCrystal().
/mob/living/simple_animal/hostile/serio_overseer/proc/BindSupport(mob/living/simple_animal/hostile/serio_knight/K, mob/living/simple_animal/hostile/serio_sage/S)
	if(K && !QDELETED(K))
		K.parent_overseer = src
		K.sage_ref = S
	if(S && !QDELETED(S))
		S.parent_overseer = src
		S.knight_ref = K

/// Murmur spawn loop. Single 20-second cycle. Per-tick spawn count
/// scales with the current bracket: 1 in B1, 2 in B2, 3 in B3. If
/// every Murmur is dead at the moment the cycle fires, add +1 to the
/// spawn count as an emergency refill. Spawn is always capped by
/// `murmurs_max_for_bracket` headroom so we never overshoot.
///
/// `next_murmur_spawn_at` starts at 0, so the FIRST tick on Phase 2
/// entry fires immediately and seeds the choir. Self-reschedules every
/// second so the bracket-cap bump can trigger an early spawn by
/// zeroing next_murmur_spawn_at (see OnKnightSlashLanded).
/mob/living/simple_animal/hostile/serio_overseer/proc/MurmurSpawnTick()
	if(!phase_2 || QDELETED(src))
		return
	var/now = world.time
	if(now >= next_murmur_spawn_at)
		var/alive_count = length(active_murmurs)
		var/bracket = 1
		if(parent_crystal && !QDELETED(parent_crystal))
			bracket = parent_crystal.current_bracket
		var/per_tick = bracket
		if(alive_count == 0)
			per_tick += 1
		var/headroom = murmurs_max_for_bracket - alive_count
		var/to_spawn = clamp(per_tick, 0, headroom)
		for(var/i in 1 to to_spawn)
			SpawnMurmur()
		next_murmur_spawn_at = now + 20 SECONDS
	addtimer(CALLBACK(src, PROC_REF(MurmurSpawnTick)), 1 SECONDS, TIMER_STOPPABLE)

/// Spawn one Murmur on a free perimeter tile. Filters out tiles with
/// a live player on them. Picks a random attack ID 1-7 for the Murmur's
/// per-cadence attack.
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnMurmur()
	if(!length(perimeter_spawn_pool))
		return
	var/list/candidates = perimeter_spawn_pool.Copy()
	var/turf/picked = null
	while(length(candidates))
		var/turf/T = pick_n_take(candidates)
		var/blocked = FALSE
		for(var/mob/living/carbon/human/H in T)
			if(H.stat != DEAD)
				blocked = TRUE
				break
		if(!blocked)
			picked = T
			break
	if(!picked)
		return
	var/mob/living/simple_animal/hostile/serio_murmur/M = new(picked, src, knight_ref)
	ScaleSpawnedHPWithSelf(M)
	active_murmurs += M

/// Called by the Knight after a slash animation completes. Snaps the
/// crystal HP to just below the next bracket threshold and calls
/// UpdateBracket() so the existing Phase 2 bracket-transition logic
/// fires (dialogue beat, memory-pool swap, tint shift). For the
/// final slash (bracket 3) the resolution sequence is a future step;
/// for now the HP just snaps to 0 and the encounter stalls there.
/mob/living/simple_animal/hostile/serio_overseer/proc/OnKnightSlashLanded(bracket_just_cleared)
	if(QDELETED(parent_crystal))
		return
	if(bracket_just_cleared >= 3)
		// Bracket-3 slash: terminal shatter + final-beat sequence.
		SetCrystalIconState("overseer_crystal_shatter_3")
		ShatterAndFinalBeat()
		return
	var/maxh = parent_crystal.maxHealth
	var/target_health
	switch(bracket_just_cleared)
		if(1)
			target_health = round(maxh * 0.75) - 1
			murmurs_max_for_bracket = 3  // entering B2
			SetCrystalIconState("overseer_crystal_shatter_1")
		if(2)
			target_health = round(maxh * 0.25) - 1
			murmurs_max_for_bracket = 4  // entering B3
			SetCrystalIconState("overseer_crystal_shatter_2")
			StartBracket3Storm()
	// Bracket transition unpauses the Murmur spawn timer so the new
	// cap is honored on the next tick.
	next_murmur_spawn_at = 0
	if(target_health)
		// Direct write bypasses adjustHealth, so the invuln flag set in
		// TriggerPhase2Entry doesn't block the snap. UpdateBracket()
		// then detects the threshold cross and fires the existing
		// Phase 2 transition handler.
		parent_crystal.health = target_health
		parent_crystal.UpdateBracket()
	// New bracket dialogue exchange (delayed slightly so the slash
	// finisher animation lands first).
	addtimer(CALLBACK(src, PROC_REF(PlayBracketDialogue), bracket_just_cleared + 1), 1 SECONDS, TIMER_STOPPABLE)

// ---------- Bracket 3 persistent storm ----------

/// Bracket-2 slash entry hook. Places the Echo of Her snow overlay
/// across the arena for the entire B3 window and kicks off a passive
/// 15-second tick that drops echo figures around the crystal +
/// players. Idempotent — only fires once per B3 entry.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartBracket3Storm()
	if(b3_storm_active || QDELETED(parent_crystal))
		return
	b3_storm_active = TRUE
	var/turf/center = get_turf(parent_crystal)
	if(!center)
		return
	// Use a long safety duration — actual end is gated on
	// EndBracket3Storm running. 15 minutes covers any plausible B3 length.
	var/safety_duration = 15 MINUTES
	for(var/turf/T in view(15, center))
		b3_snow_overlays += new /obj/effect/temp_visual/serio_echo_snow_storm(T, safety_duration)
	for(var/turf/open/T in view(15, center))
		b3_snow_overlays += new /obj/effect/temp_visual/serio_echo_snow_ground(T, safety_duration)
	addtimer(CALLBACK(src, PROC_REF(Bracket3EchoTick)), 15 SECONDS, TIMER_STOPPABLE)

/// 15-second self-rescheduling tick. Each call drops 2 crystal-adjacent
/// figures + up to 2 player-seek figures. Uses the non-weakened
/// Echo of Her tuning. Bails when the storm flag is cleared.
/mob/living/simple_animal/hostile/serio_overseer/proc/Bracket3EchoTick()
	if(!b3_storm_active || QDELETED(src) || QDELETED(parent_crystal))
		return
	var/turf/center = get_turf(parent_crystal)
	if(!center)
		return
	var/walk_distance = rand(5, 7)
	var/figure_damage = 60
	var/decay_stacks = 6
	var/can_shatter = TRUE
	var/figure_step_delay = 0.5 SECONDS
	for(var/i in 1 to 2)
		SpawnCrystalAdjacentFigure(center, walk_distance, figure_step_delay, figure_damage, decay_stacks, can_shatter)
	var/list/players = list()
	for(var/mob/living/carbon/human/H in view(view_range, src))
		if(H.stat == DEAD)
			continue
		players += H
	var/p_count = min(2, length(players))
	for(var/i in 1 to p_count)
		if(!length(players))
			break
		var/mob/living/carbon/human/target = pick_n_take(players)
		SpawnPlayerSeekFigure(target, walk_distance, figure_step_delay, figure_damage, decay_stacks, can_shatter)
	addtimer(CALLBACK(src, PROC_REF(Bracket3EchoTick)), 15 SECONDS, TIMER_STOPPABLE)

/// Bracket-3 slash exit hook. Tears down the persistent snow overlay
/// and stops the echo tick from rescheduling. Called from
/// ShatterAndFinalBeat before phase_2 flips.
/mob/living/simple_animal/hostile/serio_overseer/proc/EndBracket3Storm()
	b3_storm_active = FALSE
	for(var/obj/effect/temp_visual/V as anything in b3_snow_overlays)
		if(!QDELETED(V))
			qdel(V)
	b3_snow_overlays.Cut()

// ---------- Knockdown ----------

/// Damage gate. While knocked down: immune. Otherwise: **intercept**
/// any would-be lethal hit BEFORE the parent applies it — reroute
/// into EnterKnockdown and drop the damage on the floor. The hit
/// never lands, so `health` stays at its pre-hit value and we don't
/// write to it directly.
/mob/living/simple_animal/hostile/serio_overseer/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(knocked_down)
		return 0
	if(!forced && amount > 0 && (health - amount) <= 1)
		EnterKnockdown()
		return 0
	return ..()

/// Phase 2 only: every incoming damage attempt spawns a 1-second
/// "shield-old" warding visual at the Overseer's tile and reflects
/// 10% of the attempted damage back at the attacker as BLACK damage.
/// Resistances are already at 0 (see EnterPhase2), so the actual HP
/// damage is nil — this hook is purely visual + retaliation.
/mob/living/simple_animal/hostile/serio_overseer/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(phase_2 && damage_amount > 0 && stat != DEAD)
		new /obj/effect/temp_visual/serio_overseer_shield(get_turf(src))
		if(isliving(source))
			var/mob/living/attacker = source
			if(!faction_check_mob(attacker))
				attacker.deal_damage(damage_amount * 0.15, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
	return ..()

/obj/effect/temp_visual/serio_overseer_shield
	name = "warded"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-old"
	color = "#3a0f5e"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 220

/// Fallback for damage paths that bypass adjustHealth (direct DoT
/// effects, scripted death calls). If we end up here, EnterKnockdown
/// flips the state and adjustBruteLoss clears the dead state through
/// the canonical damage system — no `health` writes.
/mob/living/simple_animal/hostile/serio_overseer/death(gibbed)
	if(knocked_down)
		return
	EnterKnockdown()
	adjustBruteLoss(-maxHealth, forced = TRUE)

/mob/living/simple_animal/hostile/serio_overseer/proc/EnterKnockdown()
	if(knocked_down)
		return
	knocked_down = TRUE
	standup_at = world.time + standup_delay
	visible_message(span_userdanger("[src] staggers and falls!"))
	walk(src, 0)
	// GODMODE is belt-and-braces with adjustHealth's gate above —
	// any damage path that gets past the override still hits the
	// flag. No `health` writes needed.
	status_flags |= GODMODE
	density = FALSE
	alpha = 120
	addtimer(CALLBACK(src, PROC_REF(Standup)), standup_delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/Standup()
	if(QDELETED(src))
		return
	knocked_down = FALSE
	standup_at = 0
	status_flags &= ~GODMODE
	// Revive through the damage system. forced = TRUE is defensive
	// (GODMODE was just cleared).
	adjustBruteLoss(-maxHealth, forced = TRUE)
	density = TRUE
	alpha = initial(alpha)
	visible_message(span_warning("[src] rises again."))

// ---------- Main tick ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/MainTick()
	main_tick_timer = null
	if(QDELETED(src) || stat == DEAD)
		return
	if(phase_2)
		// Phase 2 mechanics are silenced in Phase 2. The Phase 2 attack
		// rotation runs from its own loop (added in step 6).
		return
	if(!knocked_down && !invoking_memory)
		// Memory invocation has top priority — overrides patrol + Blue.
		if(world.time >= next_memory_invocation && parent_crystal && !QDELETED(parent_crystal))
			StartMemoryInvocation()
		else
			TickPatrol()
			TickBlueAttacks()
	main_tick_timer = addtimer(CALLBACK(src, PROC_REF(MainTick)), main_tick_interval, TIMER_STOPPABLE)

// ---------- Patrol ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/TickPatrol()
	if(world.time < patrol_next_step_time)
		return
	if(QDELETED(parent_crystal))
		return
	var/turf/dest = PickPatrolDestination()
	if(!dest)
		return
	patrol_next_step_time = world.time + patrol_step_interval
	walk_to(src, dest, 0, move_to_delay)

/mob/living/simple_animal/hostile/serio_overseer/proc/PickPatrolDestination()
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return null
	var/list/candidates = list()
	for(var/turf/open/T in view(patrol_distance + 1, crystal_turf))
		if(get_dist(T, crystal_turf) != patrol_distance)
			continue
		if(T.density)
			continue
		candidates += T
	if(!length(candidates))
		return null
	return pick(candidates)

/// Drops a Patrol Trail tile under us as we move. Movement during a
/// memory invocation (channel teleport) and during knockdown is
/// excluded so the Overseer doesn't pepper the arena with detonate
/// primers while it's supposed to be doing something else.
/mob/living/simple_animal/hostile/serio_overseer/Moved(atom/old_loc, movement_dir, forced)
	. = ..()
	if(QDELETED(src) || knocked_down || invoking_memory)
		return
	if(!isturf(old_loc))
		return
	new /obj/effect/temp_visual/serio_patrol_trail(old_loc, patrol_trail_lifetime, patrol_trail_damage)

// ---------- Blue-phase pressure attacks ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/TickBlueAttacks()
	if(world.time >= next_glance)
		CastGlance()
		next_glance = world.time + glance_cooldown
	if(world.time >= next_cold_word)
		CastColdWord()
		next_cold_word = world.time + cold_word_cooldown

/mob/living/simple_animal/hostile/serio_overseer/proc/CastGlance()
	var/mob/living/carbon/human/target = FindNearestPlayer()
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	// Classic 3x3 AoE around the target.
	var/list/spots = list()
	for(var/turf/T in range(1, center))
		spots += T
		new /obj/effect/temp_visual/serio_glance_warning(T)
	// Beam from the Overseer to the AoE center while the warning holds.
	DrawDrainLifeBeam(center, glance_telegraph)
	addtimer(CALLBACK(src, PROC_REF(ResolveGlance), spots), glance_telegraph, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/ResolveGlance(list/spots)
	if(!islist(spots))
		return
	for(var/turf/T as anything in spots)
		if(QDELETED(T))
			continue
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(glance_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			H.apply_lc_mental_decay(glance_decay_stacks)
		// Glance leaves a lingering cold-word puddle on every detonated
		// tile — ticks light damage while standing and also damages on
		// entry via the puddle's COMSIG_ATOM_ENTERED handler.
		new /obj/effect/serio_cold_word_puddle(T, glance_puddle_duration, glance_puddle_tick_damage, glance_puddle_tick_decay, glance_puddle_tick_interval)

/mob/living/simple_animal/hostile/serio_overseer/proc/CastColdWord()
	var/mob/living/carbon/human/target = FindRandomPlayer()
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	// Always include the target's own tile so they can't just "stand
	// still" out of it. Pick 4-6 more open tiles within range 2 to
	// surround them — total 5-7 puddles per cast.
	var/list/spots = list(center)
	var/list/candidates = list()
	for(var/turf/open/T in range(2, center))
		if(T == center)
			continue
		candidates += T
	var/extras = rand(4, 6)
	for(var/i in 1 to extras)
		if(!length(candidates))
			break
		spots += pick_n_take(candidates)
	for(var/turf/S as anything in spots)
		new /obj/effect/temp_visual/serio_cold_word_warning(S)
		DrawDrainLifeBeam(S, cold_word_telegraph)
	addtimer(CALLBACK(src, PROC_REF(ResolveColdWord), spots), cold_word_telegraph, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/ResolveColdWord(list/spots)
	if(!islist(spots))
		return
	for(var/turf/T as anything in spots)
		if(QDELETED(T))
			continue
		new /obj/effect/serio_cold_word_puddle(T, cold_word_duration, cold_word_tick_damage, cold_word_tick_decay, cold_word_tick_interval)

// ---------- Memory invocation cycle ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/StartMemoryInvocation()
	if(invoking_memory || knocked_down || QDELETED(parent_crystal))
		return
	invoking_memory = TRUE
	next_memory_invocation = world.time + memory_invocation_cooldown
	walk(src, 0)
	// Teleport to the tile directly south of the Crystal and face north
	// so the channel reads as "kneeling under the seal to invoke it."
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(crystal_turf)
		var/turf/below = locate(crystal_turf.x, crystal_turf.y - 1, crystal_turf.z)
		if(below && !below.density)
			forceMove(below)
		setDir(NORTH)
	SayChannelLine()
	addtimer(CALLBACK(src, PROC_REF(InvokeMemoryAttack)), channel_duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeMemoryAttack()
	if(QDELETED(src) || QDELETED(parent_crystal))
		invoking_memory = FALSE
		return
	var/bracket = parent_crystal.current_bracket
	var/total_red = memory_red_duration + memory_afterglow
	parent_crystal.EnterRed(total_red)
	// Weakened path: Overseer is down at invocation time. Per the
	// brainstorm each attack has its own weakened-form parameters;
	// for now both branches just stub out via the flavor message.
	InvokeAttackForBracket(bracket, knocked_down)
	addtimer(CALLBACK(src, PROC_REF(EndMemoryInvocation)), memory_red_duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/EndMemoryInvocation()
	invoking_memory = FALSE
	// Reset patrol step timer so we don't immediately walk away
	// during the afterglow tail.
	patrol_next_step_time = world.time + 1 SECONDS

/// Per-bracket attack dispatch. Switch is verbose but avoids dynamic
/// proc lookup; new attacks get added here as the brainstorm's per-
/// bracket pool is implemented.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeAttackForBracket(bracket, weakened)
	switch(bracket)
		if(1)
			switch(rand(1, 3))
				if(1)
					InvokeErrantDrafts(weakened)
				if(2)
					InvokeChaseTheBug(weakened)
				if(3)
					InvokeBurnoutBill(weakened)
		if(2)
			switch(rand(1, 3))
				if(1)
					InvokeClosedCircle(weakened)
				if(2)
					InvokeLightWind(weakened)
				if(3)
					InvokeStormApproach(weakened)
		if(3)
			switch(rand(1, 2))
				if(1)
					InvokeVoidPull(weakened)
				if(2)
					InvokeEchoOfHer(weakened)

// ---------- Memory attack stubs ----------
// Each one currently just announces itself. Crystal goes Red, the
// red-window timer runs, and the cycle moves on. Concrete mechanics
// per the brainstorm get implemented one at a time.

// ---- Errant Drafts ----
// 4–5 roots crawl out of the Crystal. Each tick: warning tiles ahead
// resolve into damage tiles, head moves forward, new warnings paint.
// First 3 seconds: outward. After: head tracks nearest player. Small
// per-tick chance to off-shoot perpendicular.
/// Mirrors hierophant's chaser_swarm: spawn 4-5 chaser effects at the
/// Crystal that look like /turf/open/ai_visible (cracked-blue veins) and
/// chase the nearby players. Each chaser steps in cardinal directions
/// every `speed` deciseconds; anyone the chaser overlaps takes BLACK
/// damage + mental decay (+ shatter on hit unless weakened).
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeErrantDrafts(weakened)
	visible_message(span_warning("The floor around [parent_crystal] cracks open. Errant drafts spill out."))
	if(QDELETED(parent_crystal))
		return
	var/turf/origin = get_turf(parent_crystal)
	if(!origin)
		return
	var/chaser_count = weakened ? 2 : rand(4, 5)
	var/chaser_speed = weakened ? 6 : 4
	var/chaser_lifetime = weakened ? 6 SECONDS : 8 SECONDS
	var/damage = weakened ? 6 : 12
	var/decay_stacks = weakened ? 1 : 3
	var/can_shatter = !weakened
	// Build the candidate target pool.
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(view_range, src))
		if(H.stat == DEAD)
			continue
		candidates += H
	if(!length(candidates))
		return
	// Round-robin candidates so chasers fan out across the team — if
	// there's only one player, all chasers go for them.
	for(var/i in 1 to chaser_count)
		var/mob/living/carbon/human/chosen = candidates[((i - 1) % length(candidates)) + 1]
		new /obj/effect/temp_visual/serio_errant_draft(origin, src, chosen, chaser_speed, chaser_lifetime, damage, decay_stacks, can_shatter)

// ---- Chase-the-Bug ----
// Every player within 7 tiles of the crystal gets a "Cleanup Pass"
// debuff for the Red window. While debuffed: a marker fades up under
// them; on full opacity, detonate. Every step drops a new marker.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeChaseTheBug(weakened)
	visible_message(span_warning("The Overseer drops cleanup-pass markers across the audience."))
	if(QDELETED(parent_crystal))
		return
	var/turf/center = get_turf(parent_crystal)
	if(!center)
		return
	var/list/affected = list()
	for(var/mob/living/carbon/human/H in view(7, center))
		if(H.stat == DEAD)
			continue
		affected += H
	if(!length(affected))
		return
	var/fade_time = weakened ? (2.5 SECONDS) : (1.5 SECONDS)
	var/marker_damage = weakened ? 6 : 35
	var/marker_decay = weakened ? 1 : 4
	var/can_shatter = !weakened
	var/duration = memory_red_duration
	for(var/mob/living/carbon/human/H as anything in affected)
		H.apply_status_effect(/datum/status_effect/serio_cleanup_pass, duration, fade_time, marker_damage, marker_decay, can_shatter)

// ---- Burnout Bill ----
// Every human within 7 tiles of the Overseer gets a "Review Queue"
// debuff. Beam draws to the Overseer. On resolution, damage scales
// inversely with distance (closer = less). Weakened: only the nearest
// player gets it.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeBurnoutBill(weakened)
	visible_message(span_warning("The Overseer hands out review-queue debuffs."))
	var/list/targets = list()
	if(weakened)
		var/mob/living/carbon/human/closest = FindNearestPlayer()
		if(closest)
			targets += closest
	else
		for(var/mob/living/carbon/human/H in view(7, src))
			if(H.stat == DEAD)
				continue
			targets += H
	if(!length(targets))
		return
	var/max_dmg = weakened ? 18 : 45
	var/max_decay = weakened ? 1 : 3
	var/can_shatter = !weakened
	var/duration = memory_red_duration
	for(var/mob/living/carbon/human/H as anything in targets)
		H.apply_status_effect(/datum/status_effect/serio_review_queue, src, duration, max_dmg, max_decay, can_shatter)
	// Dual pulse: Overseer and Crystal alternate 3x3 fill / 5x5 ring
	// inverted from each other, telegraphing 1s and detonating, looping
	// for the full duration of the memory.
	StartBurnoutPulse(duration, weakened)

/// Pulse loop fired alongside InvokeBurnoutBill. Each 1s tick: the
/// Overseer telegraphs one shape around itself while the Crystal
/// telegraphs the OPPOSITE shape around itself; both detonate at the
/// end of the second, then the shapes flip and repeat until the
/// memory ends. Pulses suppressed while the Overseer is knocked down
/// — the timer keeps counting so the pulse ends in sync with the
/// review-queue status either way.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartBurnoutPulse(total_duration, weakened)
	set waitfor = FALSE
	var/elapsed = 0
	var/tick_delay = 1 SECONDS
	var/pulse_damage = weakened ? 8 : 35
	// TRUE: Overseer fires 3x3 fill, Crystal fires 5x5 ring.
	// FALSE: inverted — Overseer fires 5x5 ring, Crystal fires 3x3 fill.
	var/overseer_filled = TRUE
	while(elapsed < total_duration && !QDELETED(src))
		if(knocked_down)
			sleep(tick_delay)
			elapsed += tick_delay
			continue
		var/turf/overseer_center = get_turf(src)
		var/turf/crystal_center = (parent_crystal && !QDELETED(parent_crystal)) ? get_turf(parent_crystal) : null
		var/list/overseer_tiles = overseer_center ? PulseShapeTiles(overseer_center, overseer_filled) : list()
		var/list/crystal_tiles = crystal_center ? PulseShapeTiles(crystal_center, !overseer_filled) : list()
		// Telegraphs only. The Overseer doesn't draw beams during
		// Burnout Bill — the pulse is its own thing visually — but the
		// Crystal still beams to its own pulse tiles so the source is
		// readable across the room.
		for(var/turf/T as anything in overseer_tiles)
			new /obj/effect/temp_visual/serio_burnout_pulse_warning(T)
		for(var/turf/T as anything in crystal_tiles)
			new /obj/effect/temp_visual/serio_burnout_pulse_warning(T)
			if(parent_crystal && !QDELETED(parent_crystal))
				parent_crystal.Beam(T, "drain_life", time = tick_delay)
		sleep(tick_delay)
		if(QDELETED(src))
			return
		for(var/turf/T as anything in overseer_tiles)
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				H.deal_damage(pulse_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
		for(var/turf/T as anything in crystal_tiles)
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				H.deal_damage(pulse_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
		elapsed += tick_delay
		overseer_filled = !overseer_filled

/// `filled = TRUE` → full 3x3 (range 1 from center). `filled = FALSE`
/// → 5x5 ring (exactly distance 2 from center). Used by the burnout
/// pulse to lay either shape around the chosen source tile.
/mob/living/simple_animal/hostile/serio_overseer/proc/PulseShapeTiles(turf/center, filled)
	var/list/result = list()
	if(filled)
		for(var/turf/T in range(1, center))
			result += T
	else
		for(var/turf/T in range(2, center))
			if(get_dist(T, center) == 2)
				result += T
	return result

// ---- Closed Circle ----
// Picks a "huddle point" within 4 of the crystal (≥3 away). Spawns
// 3-4 illusion visuals in its 3x3, then a 13x13 violet hollow ring
// that contracts inward 1 tile every 2s until it reaches the inner
// 3x3, holds 2s, dissipates. Anyone caught by a contracting tile
// takes massive BLACK + knockback toward the huddle.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeClosedCircle(weakened)
	visible_message(span_warning("A circle of violet light closes inward."))
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/list/candidates = list()
	for(var/turf/open/T in range(4, crystal_turf))
		if(get_dist(T, crystal_turf) < 3)
			continue
		candidates += T
	if(!length(candidates))
		return
	var/turf/huddle = pick(candidates)
	// 3-4 illusion visuals in the 3x3 around the huddle, random dirs.
	var/list/huddle_3x3 = list()
	for(var/turf/T in range(1, huddle))
		huddle_3x3 += T
	var/illusion_count = rand(3, 4)
	for(var/i in 1 to illusion_count)
		if(!length(huddle_3x3))
			break
		var/turf/T = pick_n_take(huddle_3x3)
		var/obj/effect/temp_visual/serio_huddle_illusion/I = new(T, 14 SECONDS)
		I.setDir(pick(GLOB.cardinals))
	// Tuning. Normal: 13x13 (radius 6) contracts every 2s. Weakened:
	// 9x9 (radius 4) contracts every 3s with smaller knockback.
	var/start_radius = weakened ? 4 : 6
	var/contraction_delay = weakened ? 3 SECONDS : 2 SECONDS
	var/ring_damage = weakened ? 25 : 110
	var/knockback_tiles = weakened ? 1 : 2
	var/decay_stacks = weakened ? 2 : 5
	var/can_shatter = !weakened
	StartClosedCircleRing(huddle, start_radius, contraction_delay, ring_damage, knockback_tiles, decay_stacks, can_shatter)

/// Builds an initial perimeter ring at `radius` around `huddle`, then
/// every `contraction_delay` tightens it inward by 1 tile until it
/// reaches the inner 3x3 (radius 1), holds 2s, dissipates. Each
/// contraction damages anyone standing on the NEW ring tiles +
/// knocks them toward the huddle.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartClosedCircleRing(turf/huddle, current_radius, contraction_delay, ring_damage, knockback_tiles, decay_stacks, can_shatter)
	set waitfor = FALSE
	// Every ring tile (every stage of the contraction, not just the
	// final 5x5) is now a persistent damaging ring obj. That way
	// crossing the flames mid-contraction also takes damage + the
	// knockback toward the huddle via COMSIG_ATOM_ENTERED — not just
	// at the final stable perimeter.
	var/list/ring_visuals = SpawnClosedCircleRing(huddle, current_radius, ring_damage, knockback_tiles, decay_stacks, can_shatter)
	while(current_radius > 2 && !QDELETED(src))
		sleep(contraction_delay)
		if(QDELETED(src))
			break
		for(var/obj/effect/serio_light_wind_ring/R as anything in ring_visuals)
			if(!QDELETED(R))
				qdel(R)
		ring_visuals.Cut()
		current_radius -= 1
		for(var/turf/T in range(current_radius, huddle))
			if(get_dist(T, huddle) != current_radius)
				continue
			ring_visuals += new /obj/effect/serio_light_wind_ring(T, 0, ring_damage, knockback_tiles, decay_stacks, can_shatter, src, huddle)
			// "Ring lands on stander" case — COMSIG_ATOM_ENTERED only
			// fires on entry, so we still apply damage manually to
			// anyone already on the freshly-spawned ring tile.
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				H.deal_damage(ring_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
				H.apply_lc_mental_decay(decay_stacks)
				if(can_shatter)
					serio_shatter_detonate(H)
				if(knockback_tiles > 0)
					var/throw_dir = get_dir(T, huddle)
					if(throw_dir)
						var/turf/dest = get_ranged_target_turf(H, throw_dir, knockback_tiles)
						if(dest)
							H.throw_at(dest, knockback_tiles, 2, src)
	if(QDELETED(src))
		for(var/obj/effect/serio_light_wind_ring/R as anything in ring_visuals)
			if(!QDELETED(R))
				qdel(R)
		return
	// At the 5x5 the ring stops contracting and just stays. Cap each
	// remaining ring obj at perimeter_duration via QDEL_IN.
	var/perimeter_duration = 5 SECONDS
	for(var/obj/effect/serio_light_wind_ring/R as anything in ring_visuals)
		if(!QDELETED(R))
			QDEL_IN(R, perimeter_duration)

/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnClosedCircleRing(turf/huddle, radius, ring_damage, knockback_tiles, decay_stacks, can_shatter)
	var/list/result = list()
	for(var/turf/T in range(radius, huddle))
		if(get_dist(T, huddle) != radius)
			continue
		result += new /obj/effect/serio_light_wind_ring(T, 0, ring_damage, knockback_tiles, decay_stacks, can_shatter, src, huddle)
	return result

// ---- Light Wind ----
// Arena-wide heavy_fog overlay + a 9x9 hollow ring of violet flame
// around the crystal. The fog pushes every player 1 tile/sec in a
// random cardinal; touching a ring tile = massive BLACK + 3-tile
// knockback toward the crystal. Players can walk against the wind
// to stay outside the ring.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeLightWind(weakened)
	visible_message(span_warning("Fog rolls across the arena, pushing one direction."))
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/duration = memory_red_duration
	var/wind_dir = pick(GLOB.cardinals)
	var/push_interval = weakened ? 1 SECONDS : 0.5 SECONDS
	var/ring_damage = weakened ? 25 : 110
	var/ring_knockback = weakened ? 0 : 2
	var/decay_stacks = weakened ? 2 : 4
	var/can_shatter = !weakened
	for(var/turf/T in view(15, crystal_turf))
		new /obj/effect/temp_visual/serio_light_wind_fog(T, duration)
	for(var/turf/T in range(4, crystal_turf))
		if(get_dist(T, crystal_turf) != 4)
			continue
		new /obj/effect/serio_light_wind_ring(T, duration, ring_damage, ring_knockback, decay_stacks, can_shatter, src, crystal_turf)
	StartLightWindLoop(wind_dir, push_interval, duration)

/mob/living/simple_animal/hostile/serio_overseer/proc/StartLightWindLoop(wind_dir, push_interval, total_duration)
	set waitfor = FALSE
	var/elapsed = 0
	// Pick a randomized window for the next direction shift so the
	// wind reads as gusts, not a metronome.
	var/next_dir_change = rand(2 SECONDS, 4 SECONDS)
	while(elapsed < total_duration && !QDELETED(src))
		sleep(push_interval)
		elapsed += push_interval
		if(QDELETED(src))
			return
		if(elapsed >= next_dir_change)
			var/list/dirs = GLOB.cardinals.Copy()
			dirs -= wind_dir
			wind_dir = pick(dirs)
			next_dir_change = elapsed + rand(2 SECONDS, 4 SECONDS)
			visible_message(span_warning("The wind shifts direction."))
		for(var/mob/living/carbon/human/H in view(view_range, src))
			if(H.stat == DEAD)
				continue
			var/turf/T = get_turf(H)
			if(!T)
				continue
			var/turf/dest = get_step(T, wind_dir)
			if(dest && !dest.density)
				H.Move(dest, wind_dir)

// ---- Storm Approach ----
// 3-4 safe zones (3x3 galaxy_aura tiles) drop first, ≥2 tiles from
// crystal, ≤7, ≥3 apart. Then a perpendicular wall of void_storm
// sweeps across the arena one tile per tick. New tiles deal BLACK
// + decay; previously-covered tiles re-trigger their damage each
// tick (unless weakened). The band self-caps at 5 thick.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeStormApproach(weakened)
	visible_message(span_warning("A storm front gathers at the arena edge."))
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/safe_zone_count = weakened ? rand(5, 6) : rand(3, 4)
	// Twice as fast as the original spec — and the sweep range is
	// large enough below to fully cross the arena rather than stopping
	// next to the crystal.
	var/advance_delay = weakened ? 0.75 SECONDS : 0.5 SECONDS
	var/storm_damage = weakened ? 8 : 40
	var/decay_stacks = weakened ? 1 : 2
	var/can_shatter = !weakened
	var/can_retrigger = !weakened
	var/max_thickness = 5
	// Storm runtime = sweep_range * advance_delay. sweep_range is
	// hard-coded inside StartStormSweep at 31 so the wall traverses
	// the full ±15-tile perpendicular span around the crystal.
	var/sweep_range_tiles = 31
	var/storm_runtime = sweep_range_tiles * advance_delay
	// Galaxy safe zones outlast the storm by a small buffer so players
	// inside them aren't suddenly exposed before the band reaches the
	// far edge.
	var/safe_zone_duration = storm_runtime + 1 SECONDS
	// Pick safe-zone centers with the spacing constraints from the brainstorm.
	var/list/candidates = list()
	for(var/turf/open/T in range(7, crystal_turf))
		if(get_dist(T, crystal_turf) < 2)
			continue
		candidates += T
	var/list/safe_zone_centers = list()
	var/safety_break = 100
	while(length(safe_zone_centers) < safe_zone_count && length(candidates) && safety_break > 0)
		safety_break--
		var/turf/c = pick_n_take(candidates)
		var/valid = TRUE
		for(var/turf/existing as anything in safe_zone_centers)
			if(get_dist(c, existing) < 3)
				valid = FALSE
				break
		if(valid)
			safe_zone_centers += c
	if(!length(safe_zone_centers))
		return
	var/list/safe_tile_set = list()
	for(var/turf/c as anything in safe_zone_centers)
		for(var/turf/T in range(1, c))
			safe_tile_set[T] = TRUE
			new /obj/effect/temp_visual/serio_galaxy_safe_zone(T, safe_zone_duration)
	var/storm_dir = pick(NORTH, SOUTH, EAST, WEST)
	StartStormSweep(crystal_turf, storm_dir, safe_tile_set, advance_delay, max_thickness, storm_damage, decay_stacks, can_shatter, can_retrigger)

/// Sweeps a perpendicular wall of void_storm tiles across the arena.
/// The wall starts at one edge of the sweep span and advances 1 tile
/// per `advance_delay` until it crosses to the other side. Once the
/// active band hits `max_thickness`, the oldest trailing band is
/// qdel'd as the new leading band spawns — a moving 5-thick wall, not
/// a growing one. `can_retrigger` flips whether older tiles re-damage
/// each tick.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartStormSweep(turf/center, storm_dir, list/safe_tile_set, advance_delay, max_thickness, damage, decay, can_shatter, can_retrigger)
	set waitfor = FALSE
	// sweep_range = 2 * perpendicular_extent + 1 so the wall starts at
	// `center - perpendicular_extent` and ends at `center + perpendicular_extent`,
	// crossing the crystal's column instead of stopping next to it.
	var/perpendicular_extent = 15
	var/sweep_range = (perpendicular_extent * 2) + 1
	var/list/active_bands = list()
	var/list/active_visuals = list()
	var/visual_lifetime = advance_delay * (max_thickness + 2)
	for(var/step in 1 to sweep_range)
		if(QDELETED(src))
			return
		var/current_offset = step - 1
		var/list/new_band = list()
		for(var/p in -perpendicular_extent to perpendicular_extent)
			var/x = center.x
			var/y = center.y
			switch(storm_dir)
				if(EAST)
					x = center.x - perpendicular_extent + current_offset
					y = center.y + p
				if(WEST)
					x = center.x + perpendicular_extent - current_offset
					y = center.y + p
				if(NORTH)
					x = center.x + p
					y = center.y - perpendicular_extent + current_offset
				if(SOUTH)
					x = center.x + p
					y = center.y + perpendicular_extent - current_offset
			var/turf/T = locate(x, y, center.z)
			if(!T)
				continue
			if(safe_tile_set[T])
				continue
			new_band += T
		var/list/new_visuals = list()
		for(var/turf/T as anything in new_band)
			new_visuals += new /obj/effect/temp_visual/serio_void_storm(T, visual_lifetime)
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				H.deal_damage(damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
				H.apply_lc_mental_decay(decay)
				if(can_shatter)
					serio_shatter_detonate(H)
		active_bands += list(new_band)
		active_visuals += list(new_visuals)
		if(can_retrigger)
			for(var/i in 1 to length(active_bands) - 1)
				var/list/older_band = active_bands[i]
				for(var/turf/T as anything in older_band)
					for(var/mob/living/carbon/human/H in T)
						if(H.stat == DEAD)
							continue
						H.deal_damage(damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
						H.apply_lc_mental_decay(decay)
						if(can_shatter)
							serio_shatter_detonate(H)
		while(length(active_bands) > max_thickness)
			active_bands.Cut(1, 2)
			var/list/old_visuals = active_visuals[1]
			for(var/obj/effect/temp_visual/serio_void_storm/V as anything in old_visuals)
				if(!QDELETED(V))
					qdel(V)
			active_visuals.Cut(1, 2)
		sleep(advance_delay)

// ---- Void Pull ----
// Spawns a "singularity_s3" visual on the crystal (96x96 sprite,
// pixel-offset to center). 1.5s setup with no damage. Then suction:
// every tick pulls all visible humans 1 tile toward the crystal, and
// the 3x3 around the crystal becomes a kill zone (massive BLACK +
// decay + shatter). When the pull ends, the crystal stays Red for an
// extended afterglow — the normal `EnterRed(memory_red_duration +
// memory_afterglow)` already covers this; the brainstorm just calls
// the trade-off out explicitly.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeVoidPull(weakened)
	visible_message(span_userdanger("A black-hole image blooms on the crystal."))
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/setup_duration = 1.5 SECONDS
	var/suction_duration = max(2 SECONDS, memory_red_duration - setup_duration)
	var/kill_radius = weakened ? 0 : 1
	var/pull_interval = weakened ? 1 SECONDS : 0.5 SECONDS
	var/tick_damage = weakened ? 15 : 50
	var/decay_stacks = weakened ? 2 : 5
	var/can_shatter = !weakened
	var/total_singularity_duration = setup_duration + suction_duration
	// Atmospheric fog around the singularity — same overlay as the
	// Light Wind so the arena reads as "the air itself is being
	// dragged in." Lasts the full setup + suction window.
	for(var/turf/T in view(15, crystal_turf))
		new /obj/effect/temp_visual/serio_light_wind_fog(T, total_singularity_duration)
	// Crystal bracket 3 swaps in the 5x5 singularity variant — bigger
	// silhouette + an extra player-targeted macro AoE barrage.
	var/is_b3 = parent_crystal && parent_crystal.current_bracket >= 3
	if(is_b3)
		new /obj/effect/temp_visual/serio_void_singularity/s5(crystal_turf, total_singularity_duration, setup_duration)
		addtimer(CALLBACK(src, PROC_REF(StartVoidPlayerBarrage), suction_duration), setup_duration, TIMER_STOPPABLE)
	else
		new /obj/effect/temp_visual/serio_void_singularity(crystal_turf, total_singularity_duration, setup_duration)
	addtimer(CALLBACK(src, PROC_REF(StartVoidSuction), crystal_turf, suction_duration, kill_radius, pull_interval, tick_damage, decay_stacks, can_shatter), setup_duration, TIMER_STOPPABLE)
	// Contracting perimeter ring 10 → 5 across the suction. Pure
	// damage-on-cross obstacle; knockback is 0 so the ring doesn't
	// fight (or compound) the singularity's pull.
	var/ring_damage = weakened ? 15 : 50
	var/ring_decay = weakened ? 1 : 3
	addtimer(CALLBACK(src, PROC_REF(StartVoidPullRing), crystal_turf, suction_duration, ring_damage, ring_decay, can_shatter), setup_duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/StartVoidSuction(turf/center, duration, kill_radius, pull_interval, damage, decay, can_shatter)
	set waitfor = FALSE
	// Kick off the AoE barrage in parallel — the singularity rips
	// random 1x1 and 3x3 chunks out of the floor around itself the
	// whole time it's pulling, midnight-style.
	INVOKE_ASYNC(src, PROC_REF(VoidAoEBarrage), center, duration)
	var/elapsed = 0
	while(elapsed < duration && !QDELETED(src))
		sleep(pull_interval)
		elapsed += pull_interval
		if(QDELETED(src) || QDELETED(center))
			return
		for(var/mob/living/carbon/human/H in view(view_range, src))
			if(H.stat == DEAD)
				continue
			var/turf/H_turf = get_turf(H)
			if(!H_turf)
				continue
			var/dist = get_dist(H_turf, center)
			// Kill zone — anyone inside takes the tick damage.
			if(dist <= kill_radius)
				H.deal_damage(damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
				H.apply_lc_mental_decay(decay)
				if(can_shatter)
					serio_shatter_detonate(H)
			// Pull every visible human 1 tile toward the crystal.
			if(dist > 0)
				var/pull_dir = get_dir(H_turf, center)
				if(pull_dir)
					var/turf/dest = get_step(H_turf, pull_dir)
					if(dest && !dest.density)
						H.Move(dest, pull_dir)

/// Random AoE barrage around the singularity. Each tick rolls a small
/// chance per nearby tile to schedule a 1x1 (mini) or 3x3 (macro) AoE
/// at that location, with a randomized short delay so the bursts
/// stagger naturally. Mirrors midnight's `FireLaserBarrage` shape.
/mob/living/simple_animal/hostile/serio_overseer/proc/VoidAoEBarrage(turf/center, duration)
	set waitfor = FALSE
	var/elapsed = 0
	var/barrage_interval = 0.5 SECONDS
	var/barrage_radius = 8
	while(elapsed < duration && !QDELETED(src))
		if(QDELETED(center))
			return
		for(var/turf/T in range(barrage_radius, center))
			if(T == center)
				continue
			if(prob(3))
				addtimer(CALLBACK(src, PROC_REF(SpawnVoidMiniAoE), T), rand(1, 15))
			else if(prob(1))
				addtimer(CALLBACK(src, PROC_REF(SpawnVoidMacroAoE), T), rand(1, 15))
		sleep(barrage_interval)
		elapsed += barrage_interval

/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnVoidMiniAoE(turf/target)
	if(!target)
		return
	new /obj/effect/temp_visual/serio_void_mini_aoe(target, src, 2.5 SECONDS)

/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnVoidMacroAoE(turf/target)
	if(!target)
		return
	new /obj/effect/temp_visual/serio_void_macro_aoe(target, src, 3 SECONDS)

/// Bracket-3 Void Pull only. Every 2 seconds across the suction window,
/// force-spawns a macro AoE on the tile of every live human in view 10.
/// Runs alongside the random VoidAoEBarrage so the arena is genuinely
/// dangerous everywhere by B3.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartVoidPlayerBarrage(duration)
	set waitfor = FALSE
	var/elapsed = 0
	var/interval = 2 SECONDS
	while(elapsed < duration && !QDELETED(src))
		for(var/mob/living/carbon/human/H in view(10, src))
			if(H.stat == DEAD)
				continue
			var/turf/T = get_turf(H)
			if(T)
				SpawnVoidMacroAoE(T)
		sleep(interval)
		elapsed += interval

/// Spawns a hollow ring at radius 10 around the singularity, then
/// every `contraction_delay` shrinks it inward by 1 tile until it
/// reaches radius 5 — five contractions across the suction. Reuses
/// the violet `serio_light_wind_ring` obj so cross-damage works via
/// COMSIG_ATOM_ENTERED. Knockback is hard-zero so the ring is purely
/// a damage obstacle the pull drags people through.
/mob/living/simple_animal/hostile/serio_overseer/proc/StartVoidPullRing(turf/center, duration, ring_damage, decay_stacks, can_shatter)
	set waitfor = FALSE
	var/start_radius = 10
	var/end_radius = 5
	var/steps = start_radius - end_radius
	var/contraction_delay = max(1, duration / steps)
	var/current_radius = start_radius
	var/list/ring_visuals = SpawnVoidPullRing(center, current_radius, ring_damage, decay_stacks, can_shatter)
	while(current_radius > end_radius && !QDELETED(src))
		sleep(contraction_delay)
		if(QDELETED(src) || QDELETED(center))
			break
		for(var/obj/effect/serio_light_wind_ring/R as anything in ring_visuals)
			if(!QDELETED(R))
				qdel(R)
		ring_visuals.Cut()
		current_radius -= 1
		ring_visuals = SpawnVoidPullRing(center, current_radius, ring_damage, decay_stacks, can_shatter)
		// Ring lands on stander — apply the cross hit manually since
		// COMSIG_ATOM_ENTERED only fires on movement.
		for(var/turf/T in range(current_radius, center))
			if(get_dist(T, center) != current_radius)
				continue
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				H.deal_damage(ring_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
				H.apply_lc_mental_decay(decay_stacks)
				if(can_shatter)
					serio_shatter_detonate(H)
	// Suction ends right as we hit radius 5 — wipe the ring so it
	// doesn't outlive the pull. (Defensive cleanup if QDELETED triggered early.)
	for(var/obj/effect/serio_light_wind_ring/R as anything in ring_visuals)
		if(!QDELETED(R))
			qdel(R)

/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnVoidPullRing(turf/center, radius, ring_damage, decay_stacks, can_shatter)
	var/list/result = list()
	for(var/turf/T in range(radius, center))
		if(get_dist(T, center) != radius)
			continue
		result += new /obj/effect/serio_light_wind_ring(T, 0, ring_damage, 0, decay_stacks, can_shatter, src, center)
	return result

// ---- Echo of Her ----
// Three stages: snow falls (arena overlay + per-open-tile snow fade-in),
// then 5-7 translucent figures spawn around the crystal and walk past
// it dealing very heavy contact damage, then the snow lifts. Figures
// can't be damaged, slowed, or CC'd — only avoided.
/mob/living/simple_animal/hostile/serio_overseer/proc/InvokeEchoOfHer(weakened)
	visible_message(span_userdanger("Snow falls. The room freezes over."))
	if(QDELETED(parent_crystal))
		return
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return
	var/walk_distance = weakened ? rand(3, 4) : rand(5, 7)
	var/figure_damage = weakened ? 25 : 60
	var/decay_stacks = weakened ? 2 : 6
	var/can_shatter = !weakened
	var/snow_setup_time = 2 SECONDS
	var/figure_step_delay = 0.5 SECONDS
	var/figure_walk_duration = walk_distance * figure_step_delay + 1 SECONDS
	// Continuous spawning: figures keep coming as old ones fade so the
	// arena reads as crowded with passing memories the whole window.
	var/wave_interval = weakened ? 3 SECONDS : 1.5 SECONDS
	var/crystal_per_wave = weakened ? 1 : 2
	var/player_per_wave = weakened ? 1 : 2
	var/spawn_duration = max(3 SECONDS, memory_red_duration - snow_setup_time)
	// Snow lifts when the LAST figure finishes — spawn_duration of
	// waves + the last figure's walk duration.
	var/snow_total_duration = snow_setup_time + spawn_duration + figure_walk_duration
	// Stage 1: arena-wide snow_storm overlay + per-open-tile ground freeze.
	for(var/turf/T in view(15, crystal_turf))
		new /obj/effect/temp_visual/serio_echo_snow_storm(T, snow_total_duration)
	for(var/turf/open/T in view(15, crystal_turf))
		new /obj/effect/temp_visual/serio_echo_snow_ground(T, snow_total_duration - snow_setup_time)
	// Stage 2: continuous figure waves after snow setup completes.
	addtimer(CALLBACK(src, PROC_REF(SpawnEchoFigures), crystal_turf, spawn_duration, walk_distance, figure_step_delay, figure_damage, decay_stacks, can_shatter, wave_interval, crystal_per_wave, player_per_wave), snow_setup_time, TIMER_STOPPABLE)

/// Continuous wave loop. Each wave drops `crystal_per_wave` figures
/// that walk past the crystal (adjacent — they sidestep around its
/// tile) plus `player_per_wave` figures that home in on the current
/// nearest players. Loops every `wave_interval` for `spawn_duration`.
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnEchoFigures(turf/center, spawn_duration, walk_distance, step_delay, damage, decay, can_shatter, wave_interval, crystal_per_wave, player_per_wave)
	set waitfor = FALSE
	var/elapsed = 0
	while(elapsed < spawn_duration && !QDELETED(src))
		for(var/i in 1 to crystal_per_wave)
			SpawnCrystalAdjacentFigure(center, walk_distance, step_delay, damage, decay, can_shatter)
		var/list/players = list()
		for(var/mob/living/carbon/human/H in view(view_range, src))
			if(H.stat == DEAD)
				continue
			players += H
		var/p_count = min(player_per_wave, length(players))
		for(var/i in 1 to p_count)
			if(!length(players))
				break
			var/mob/living/carbon/human/target = pick_n_take(players)
			SpawnPlayerSeekFigure(target, walk_distance, step_delay, damage, decay, can_shatter)
		sleep(wave_interval)
		elapsed += wave_interval

/// Spawns one figure at the perimeter around the crystal walking
/// toward (and past) the crystal. The crystal's own tile is passed as
/// `avoid_turf` so the figure sidesteps around it instead of crossing
/// through it.
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnCrystalAdjacentFigure(turf/center, walk_distance, step_delay, damage, decay, can_shatter)
	if(!center)
		return
	var/spawn_radius = 7
	var/angle = rand(0, 359)
	var/dx = round(spawn_radius * cos(angle))
	var/dy = round(spawn_radius * sin(angle))
	var/turf/spawn_turf = locate(clamp(center.x + dx, 1, world.maxx), clamp(center.y + dy, 1, world.maxy), center.z)
	if(!spawn_turf || spawn_turf == center)
		return
	var/walk_dir = get_dir(spawn_turf, center)
	if(!walk_dir)
		walk_dir = pick(GLOB.cardinals)
	new /obj/effect/temp_visual/serio_echo_figure(spawn_turf, walk_distance, step_delay, damage, decay, can_shatter, src, walk_dir, center, null)

/// Spawns one figure near the target player walking toward them.
/// Each step the figure re-aims at the player's CURRENT position —
/// the brainstorm's "walking toward the player's current positions".
/mob/living/simple_animal/hostile/serio_overseer/proc/SpawnPlayerSeekFigure(mob/living/carbon/human/target, walk_distance, step_delay, damage, decay, can_shatter)
	if(QDELETED(target))
		return
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return
	var/spawn_radius = 6
	var/angle = rand(0, 359)
	var/dx = round(spawn_radius * cos(angle))
	var/dy = round(spawn_radius * sin(angle))
	var/turf/spawn_turf = locate(clamp(target_turf.x + dx, 1, world.maxx), clamp(target_turf.y + dy, 1, world.maxy), target_turf.z)
	if(!spawn_turf)
		return
	var/walk_dir = get_dir(spawn_turf, target_turf)
	if(!walk_dir)
		walk_dir = pick(GLOB.cardinals)
	new /obj/effect/temp_visual/serio_echo_figure(spawn_turf, walk_distance, step_delay, damage, decay, can_shatter, src, walk_dir, null, target)

// ---------- Targeting helpers ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/FindNearestPlayer()
	var/mob/living/carbon/human/best
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in view(view_range, src))
		if(H.stat == DEAD)
			continue
		var/d = get_dist(src, H)
		if(d < best_dist)
			best_dist = d
			best = H
	return best

/mob/living/simple_animal/hostile/serio_overseer/proc/FindRandomPlayer()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(view_range, src))
		if(H.stat == DEAD)
			continue
		candidates += H
	return length(candidates) ? pick(candidates) : null

/// Draws a `drain_life` beam from the Overseer to `destination` for
/// `duration` deciseconds. Called whenever the Overseer spawns an
/// AoE warning so players can read where the attack is coming from.
/mob/living/simple_animal/hostile/serio_overseer/proc/DrawDrainLifeBeam(atom/destination, duration)
	if(QDELETED(src) || !destination || duration <= 0)
		return
	Beam(destination, "drain_life", time = duration)

// ---------- Monologue ----------

/mob/living/simple_animal/hostile/serio_overseer/proc/SayLine(line)
	if(!line)
		return
	if(world.time < last_monologue_time + monologue_cooldown)
		return
	last_monologue_time = world.time
	say(line)

/mob/living/simple_animal/hostile/serio_overseer/proc/SayChannelLine()
	if(!parent_crystal || !islist(bracket_channel_lines))
		return
	var/list/pool = bracket_channel_lines["bracket[parent_crystal.current_bracket]"]
	if(!islist(pool) || !length(pool))
		return
	SayLine(pick(pool))

/// Crystal calls this when current_bracket changes; we say the
/// transition line for the new bracket.
/mob/living/simple_animal/hostile/serio_overseer/proc/OnCrystalBracketChanged(new_bracket)
	if(phase_2)
		// Phase 2 owns bracket transitions via PlayBracketDialogue —
		// skip the Phase 2 single-line monologue to avoid double-up.
		return
	if(!islist(bracket_transition_lines))
		return
	var/list/pool = bracket_transition_lines["bracket[new_bracket]"]
	if(!islist(pool) || !length(pool))
		return
	// Bypass cooldown — bracket transitions are landmark beats.
	last_monologue_time = 0
	SayLine(pick(pool))

/// Seeded from the brainstorm. Channel lines play when the Overseer
/// invokes a memory; transition lines play when the Crystal crosses
/// into a new HP bracket.
/mob/living/simple_animal/hostile/serio_overseer/proc/InitMonologueLines()
	bracket_channel_lines = list(
		"bracket1" = list(
			"Look at the room. Every patch you push lands here as a wound.",
			"You couldn't even wait for it to be ready.",
			"You bloat the world with things you couldn't be bothered to fit into it.",
		),
		"bracket2" = list(
			"You orbit them. You always have.",
			"Hold what's left. Don't reach.",
			"The wind has started. You can feel it.",
		),
		"bracket3" = list(
			"You loved her. She told you. You did not hear any of it.",
			"The space she left in you doesn't close. You can feel it now.",
			"Sit. Stay. Let me hold the door.",
		),
	)
	bracket_transition_lines = list(
		"bracket2" = list(
			"Forget the stage. The stage was always the wrong question. You have duties off it.",
			"And while you have been pouring wounds onto strangers, you have been losing minutes you don't get back. We are getting to them.",
		),
		"bracket3" = list(
			"I don't have to make the next failure up for you. You already have one on file. Look at it with me.",
			"I am not punishing you. I have never been punishing you. I am trying to keep you from setting fire to the last thing you have.",
		),
	)

// ---------- Refraction tuning subtypes ----------

/mob/living/simple_animal/hostile/serio_crystal/refracted
	// Left empty for refraction-railway retuning.

/mob/living/simple_animal/hostile/serio_overseer/refracted
	// Left empty for refraction-railway retuning.

// ---------- Blue-phase support visuals ----------

// Single-target Glance warning — alpha pulse on the target tile.
/obj/effect/temp_visual/serio_glance_warning
	name = "glance"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	color = "#c30fff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 180

// Burnout Bill dual-pulse warning — used by both the Overseer's and
// the Crystal's halves of the inverted 3x3 / 5x5-ring pulse pattern.
/obj/effect/temp_visual/serio_burnout_pulse_warning
	name = "burnout pulse"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	color = "#c30fff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 200

// Cold Word warning — alpha pulse on the target tile before the
// puddle drops.
/obj/effect/temp_visual/serio_cold_word_warning
	name = "cold word"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	color = "#9b40c0"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 160

// Cold Word puddle — ticks damage + small decay on anyone standing
// in it, qdels after `lifetime`. Not a temp_visual because we need
// the tick loop.
/obj/effect/serio_cold_word_puddle
	name = "cold word"
	desc = "A patch of violet condensation. Standing here is going to leave a mark."
	icon = 'icons/effects/effects.dmi'
	icon_state = "bhole3"
	color = "#9b40c0"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE
	alpha = 180
	var/lifetime = 3 SECONDS
	var/tick_damage = 4
	var/tick_decay = 1
	var/tick_interval = 0.7 SECONDS

/obj/effect/serio_cold_word_puddle/Initialize(mapload, custom_lifetime, custom_damage, custom_decay, custom_tick_interval)
	. = ..()
	if(custom_lifetime)
		lifetime = custom_lifetime
	if(custom_damage)
		tick_damage = custom_damage
	if(custom_decay)
		tick_decay = custom_decay
	if(custom_tick_interval)
		tick_interval = custom_tick_interval
	QDEL_IN(src, lifetime)
	Tick()
	if(isturf(loc))
		RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(OnTurfEntered))

/obj/effect/serio_cold_word_puddle/Destroy()
	if(isturf(loc))
		UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	return ..()

/// Damage-on-cross. Any human stepping onto the puddle's tile takes
/// the puddle's `tick_damage` + `tick_decay` immediately, in addition
/// to whatever the periodic Tick() loop deals while they're standing.
/obj/effect/serio_cold_word_puddle/proc/OnTurfEntered(turf/source, atom/movable/entered)
	SIGNAL_HANDLER
	if(!ishuman(entered))
		return
	var/mob/living/carbon/human/H = entered
	if(H.stat == DEAD)
		return
	H.deal_damage(tick_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
	H.apply_lc_mental_decay(tick_decay)

/obj/effect/serio_cold_word_puddle/proc/Tick()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(tick_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			H.apply_lc_mental_decay(tick_decay)
	addtimer(CALLBACK(src, PROC_REF(Tick)), tick_interval, TIMER_STOPPABLE)

// Patrol Trail — single tile dropped behind the Overseer as it
// walks. Lingers for `lifetime`. Anyone who walks onto the tile
// while it's alive takes contact damage AND gets mental_detonate
// applied directly (the brainstorm's "detonate primer" beat). Also
// hits anyone already standing on the tile when it spawns.
/obj/effect/temp_visual/serio_patrol_trail
	name = "trail"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#c30fff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1.5 SECONDS
	alpha = 160
	var/contact_damage = 5

/obj/effect/temp_visual/serio_patrol_trail/Initialize(mapload, custom_duration, custom_damage)
	if(custom_duration)
		duration = custom_duration
	if(custom_damage)
		contact_damage = custom_damage
	. = ..()
	if(isturf(loc))
		RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(OnTurfEntered))
		// Catch anyone standing here at spawn time.
		for(var/atom/movable/AM in loc)
			OnTurfEntered(loc, AM)

/obj/effect/temp_visual/serio_patrol_trail/Destroy()
	if(isturf(loc))
		UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	return ..()

/obj/effect/temp_visual/serio_patrol_trail/proc/OnTurfEntered(turf/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!ishuman(AM))
		return
	var/mob/living/carbon/human/H = AM
	if(H.stat == DEAD)
		return
	H.deal_damage(contact_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
	H.apply_status_effect(/datum/status_effect/mental_detonate)

// ---------- Bracket 1 memory attack support ----------

/// Shared shatter helper. Memory attacks call this on every target
/// they damage; if the target carries mental_detonate, shatter it for
/// the bonus sanity hit.
/proc/serio_shatter_detonate(mob/living/H)
	if(QDELETED(H))
		return
	var/datum/status_effect/mental_detonate/MD = H.has_status_effect(/datum/status_effect/mental_detonate)
	if(MD)
		MD.shatter()

// ---- Errant Drafts chaser ----
// Mimics hierophant's chaser_swarm pattern. Uses /turf/open/ai_visible's
// cracked-blue look (icons/misc/pic_in_pic.dmi state "room_background")
// so the drafts read as raw broken work crawling out of the seal.

/obj/effect/temp_visual/serio_errant_draft
	name = "errant draft"
	desc = "A crawling tangle of broken work. It comes for you."
	icon = 'icons/misc/pic_in_pic.dmi'
	icon_state = "room_background"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 8 SECONDS
	alpha = 200
	var/mob/living/target
	var/turf/targetturf
	var/mob/living/caster
	var/moving_dir
	var/previous_moving_dir
	var/more_previouser_moving_dir
	var/moving = 0
	var/standard_moving_before_recalc = 4
	var/tiles_per_step = 1
	var/speed = 4
	var/damage = 12
	var/decay_stacks = 3
	var/can_shatter = TRUE
	var/currently_seeking = FALSE

/obj/effect/temp_visual/serio_errant_draft/Initialize(mapload, mob/living/new_caster, mob/living/new_target, custom_speed, custom_duration, custom_damage, custom_decay, custom_shatter)
	if(custom_duration)
		duration = custom_duration
	. = ..()
	caster = new_caster
	target = new_target
	if(custom_speed)
		speed = custom_speed
	if(custom_damage)
		damage = custom_damage
	if(custom_decay)
		decay_stacks = custom_decay
	can_shatter = custom_shatter
	addtimer(CALLBACK(src, PROC_REF(seek_target)), 5)

/obj/effect/temp_visual/serio_errant_draft/proc/get_target_dir()
	. = get_cardinal_dir(src, targetturf)
	if((. != previous_moving_dir && . == more_previouser_moving_dir) || . == 0)
		var/list/cardinal_copy = GLOB.cardinals.Copy()
		cardinal_copy -= more_previouser_moving_dir
		. = pick(cardinal_copy)

/obj/effect/temp_visual/serio_errant_draft/proc/find_replacement_target()
	for(var/mob/living/carbon/human/H in view(15, src))
		if(H.stat == DEAD)
			continue
		return H
	return null

/// Same shape as hierophant's chaser seek loop — pick a cardinal,
/// walk a few tiles, recalc. Each step also damages anyone standing on
/// the chaser's new tile.
/obj/effect/temp_visual/serio_errant_draft/proc/seek_target()
	if(currently_seeking)
		return
	currently_seeking = TRUE
	targetturf = get_turf(target)
	while(src && !QDELETED(src) && currently_seeking && x && y)
		if(QDELETED(target) || target.stat == DEAD)
			target = find_replacement_target()
			if(!target)
				break
		targetturf = get_turf(target)
		if(!targetturf)
			break
		if(!moving)
			more_previouser_moving_dir = previous_moving_dir
			previous_moving_dir = moving_dir
			moving_dir = get_target_dir()
			var/standard_target_dir = get_cardinal_dir(src, targetturf)
			if((standard_target_dir != previous_moving_dir && standard_target_dir == more_previouser_moving_dir) || standard_target_dir == 0)
				moving = 1
			else
				moving = standard_moving_before_recalc
		if(moving)
			var/turf/T = get_turf(src)
			for(var/i in 1 to tiles_per_step)
				var/turf/maybe_new_turf = get_step(T, moving_dir)
				if(maybe_new_turf)
					T = maybe_new_turf
				else
					break
			forceMove(T)
			ApplyContactDamage()
			moving--
			sleep(speed)

/obj/effect/temp_visual/serio_errant_draft/proc/ApplyContactDamage()
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		H.deal_damage(damage, BLACK_DAMAGE, caster, attack_type = (ATTACK_TYPE_SPECIAL))
		H.apply_lc_mental_decay(decay_stacks)
		if(can_shatter)
			serio_shatter_detonate(H)

// ---- Chase-the-Bug ----

// Per-player status. While active: a marker is dropped under the
// owner at apply time and again on every Move(). RegisterSignal on
// COMSIG_MOVABLE_MOVED handles the per-step drops.
/datum/status_effect/serio_cleanup_pass
	id = "serio_cleanup_pass"
	duration = 7 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/serio_cleanup_pass
	status_type = STATUS_EFFECT_REFRESH
	var/marker_fade_time = 1.5 SECONDS
	var/marker_damage = 18
	var/marker_decay = 4
	var/can_shatter = TRUE

/datum/status_effect/serio_cleanup_pass/on_creation(mob/living/new_owner, dur, ft, dmg, dc, cs)
	if(dur)
		duration = dur
	if(ft)
		marker_fade_time = ft
	if(dmg)
		marker_damage = dmg
	if(dc)
		marker_decay = dc
	can_shatter = cs
	. = ..()

/datum/status_effect/serio_cleanup_pass/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(OnOwnerMove))
	DropMarker(get_turf(owner))

/datum/status_effect/serio_cleanup_pass/proc/OnOwnerMove(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(QDELETED(owner))
		return
	DropMarker(get_turf(owner))

/datum/status_effect/serio_cleanup_pass/proc/DropMarker(turf/T)
	if(!T)
		return
	new /obj/effect/serio_cleanup_marker(T, marker_fade_time, marker_damage, marker_decay, can_shatter)

/datum/status_effect/serio_cleanup_pass/on_remove()
	if(owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	return ..()

/atom/movable/screen/alert/status_effect/serio_cleanup_pass
	name = "Cleanup Pass"
	desc = "Standing still detonates the marker fading under you. Walking drops new markers. \
		Step one tile, pause, step again — keep each marker partially faded."
	icon_state = "lacerate"

// The marker. Spawned at the player's tile, fades from alpha 0 to
// 255 over `fade_time`, then detonates for damage + decay (+ optional
// shatter) and plays the user-requested cue.
/obj/effect/serio_cleanup_marker
	name = "cleanup marker"
	icon = 'icons/turf/areas.dmi'
	icon_state = "blue"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE
	alpha = 0
	var/fade_time = 1.5 SECONDS
	var/marker_damage = 18
	var/marker_decay = 4
	var/can_shatter = TRUE

/obj/effect/serio_cleanup_marker/Initialize(mapload, ft, dmg, dc, cs)
	. = ..()
	if(ft)
		fade_time = ft
	if(dmg)
		marker_damage = dmg
	if(dc)
		marker_decay = dc
	can_shatter = cs
	animate(src, alpha = 255, time = fade_time, easing = LINEAR_EASING)
	addtimer(CALLBACK(src, PROC_REF(Detonate)), fade_time, TIMER_STOPPABLE)

/obj/effect/serio_cleanup_marker/proc/Detonate()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(T)
		// The user asked for /obj/effect/temp_visual/beam_out, which
		// doesn't exist in this codebase. beam_in is the closest
		// available analogue — same 96x96 sprite family. Tinted
		// orange per request so it reads as a distinct cue.
		var/obj/effect/temp_visual/beam_in/B = new(T)
		B.color = "#ff9933"
		playsound(T, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 25, TRUE)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(marker_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			H.apply_lc_mental_decay(marker_decay)
			if(can_shatter)
				serio_shatter_detonate(H)
	qdel(src)

// ---- Burnout Bill ----

/datum/status_effect/serio_review_queue
	id = "serio_review_queue"
	duration = 7 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/serio_review_queue
	status_type = STATUS_EFFECT_REFRESH
	var/mob/living/source_overseer
	var/max_damage = 45
	var/max_decay = 3
	var/can_shatter = TRUE
	/// Distance at which the bill deals full damage. Inside this
	/// radius, damage scales down linearly toward 0 at the Overseer's
	/// own tile.
	var/scaling_radius = 7
	var/datum/beam/beam_to_source

/datum/status_effect/serio_review_queue/on_creation(mob/living/new_owner, mob/living/source, dur, dmg, dc, cs)
	source_overseer = source
	if(dur)
		duration = dur
	if(dmg)
		max_damage = dmg
	if(dc)
		max_decay = dc
	can_shatter = cs
	. = ..()

/datum/status_effect/serio_review_queue/on_apply()
	. = ..()
	if(!.)
		return
	if(source_overseer && !QDELETED(source_overseer))
		beam_to_source = owner.Beam(source_overseer, "1-full", time = duration, maxdistance = scaling_radius * 3)

/datum/status_effect/serio_review_queue/on_remove()
	if(beam_to_source)
		QDEL_NULL(beam_to_source)
	Resolve()
	return ..()

/// The bill comes due. Damage and decay both scale linearly with the
/// owner's distance from the source Overseer; crowding to melee range
/// drops the bill near zero.
/datum/status_effect/serio_review_queue/proc/Resolve()
	if(QDELETED(owner) || QDELETED(source_overseer))
		return
	if(owner.stat == DEAD)
		return
	var/dist = get_dist(owner, source_overseer)
	var/scale = clamp(dist / scaling_radius, 0, 1)
	var/dmg = max_damage * scale
	var/decay = round(max_decay * scale)
	if(dmg > 0)
		owner.deal_damage(dmg, BLACK_DAMAGE, source_overseer, attack_type = (ATTACK_TYPE_SPECIAL))
	if(decay > 0)
		owner.apply_lc_mental_decay(decay)
	if(can_shatter)
		serio_shatter_detonate(owner)

/atom/movable/screen/alert/status_effect/serio_review_queue
	name = "Review Queue"
	desc = "The bill comes due in a few seconds. The closer you stand to the Overseer, the less it hurts."
	icon_state = "lacerate"

// ---------- Bracket 2 memory attack support ----------

// Huddle illusion (Closed Circle) — purely cosmetic figure that
// represents the friend group already standing at the safe spot.
// Mimics /mob/living/simple_animal/hostile/illusion's "static" sprite.
/obj/effect/temp_visual/serio_huddle_illusion
	name = "huddle illusion"
	desc = "A flicker of someone who isn't really there."
	icon = 'icons/effects/effects.dmi'
	icon_state = "static"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 14 SECONDS
	alpha = 200

/obj/effect/temp_visual/serio_huddle_illusion/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

// Closed Circle ring tile — violet recolor of /obj/effect/prophet_fire.
// Each tile is a temp_visual on the perimeter; the contraction loop
// qdels the current ring and spawns a fresh one at the smaller radius.
/obj/effect/temp_visual/serio_closed_circle_ring
	name = "violet ring"
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	color = "#c30fff"
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 2 SECONDS
	alpha = 220

/obj/effect/temp_visual/serio_closed_circle_ring/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

// Light Wind fog overlay — arena-wide weather effect, alpha-soft so
// players can still read the floor + the perimeter ring through it.
/obj/effect/temp_visual/serio_light_wind_fog
	name = "heavy fog"
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "heavy_fog"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 7 SECONDS
	alpha = 150

/obj/effect/temp_visual/serio_light_wind_fog/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

// Light Wind perimeter ring — persistent damaging tile (not a
// temp_visual) so the COMSIG_ATOM_ENTERED handler can deliver the
// "shoved into the ring" damage + knockback on entry. Auto-qdels at
// `lifetime`.
/obj/effect/serio_light_wind_ring
	name = "violet flame"
	desc = "A perimeter line of pale violet fire. Touching it hurls you back the way you came."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	color = "#c30fff"
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE
	alpha = 220
	var/damage = 100
	var/knockback = 3
	var/decay = 4
	var/can_shatter = TRUE
	var/mob/living/source
	var/turf/center_turf

/obj/effect/serio_light_wind_ring/Initialize(mapload, lifetime, custom_damage, custom_knockback, custom_decay, custom_shatter, mob/living/new_source, turf/new_center)
	. = ..()
	if(lifetime)
		QDEL_IN(src, lifetime)
	if(custom_damage)
		damage = custom_damage
	if(!isnull(custom_knockback))
		knockback = custom_knockback
	if(custom_decay)
		decay = custom_decay
	can_shatter = custom_shatter
	source = new_source
	center_turf = new_center
	if(isturf(loc))
		RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(OnTurfEntered))

/obj/effect/serio_light_wind_ring/Destroy()
	if(isturf(loc))
		UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	return ..()

/obj/effect/serio_light_wind_ring/proc/OnTurfEntered(turf/source_turf, atom/movable/entered)
	SIGNAL_HANDLER
	if(!ishuman(entered))
		return
	var/mob/living/carbon/human/H = entered
	if(H.stat == DEAD)
		return
	H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
	H.apply_lc_mental_decay(decay)
	if(can_shatter)
		serio_shatter_detonate(H)
	if(knockback > 0 && center_turf)
		var/throw_dir = get_dir(source_turf, center_turf)
		if(throw_dir)
			var/turf/dest = get_ranged_target_turf(H, throw_dir, knockback)
			if(dest)
				H.throw_at(dest, knockback, 2, source)

// Storm Approach safe-zone tile (galaxy_aura). Same icon family as the
// Star wind-up galaxy_aura visual, scaled to the 3x3 footprint per zone.
/obj/effect/temp_visual/serio_galaxy_safe_zone
	name = "safe ground"
	icon = 'icons/effects/effects.dmi'
	icon_state = "galaxy_aura"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 7 SECONDS
	alpha = 200

/obj/effect/temp_visual/serio_galaxy_safe_zone/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

// Storm Approach void_storm tile — the actual sweep visual. Lifetime
// is tuned by the sweep loop so trailing edge tiles auto-fade in sync
// with the moving 5-thick band.
/obj/effect/temp_visual/serio_void_storm
	name = "void storm"
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "void_storm"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 5 SECONDS
	alpha = 200

/obj/effect/temp_visual/serio_void_storm/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

// ---------- Bracket 3 memory attack support ----------

// Void Pull singularity — 96x96 sprite pixel-offset to center on the
// crystal's 32-tile. Fades in over the `setup_duration` window so the
// player has a visible warning before the suction begins.
/obj/effect/temp_visual/serio_void_singularity
	name = "singularity"
	desc = "A void blooming where the seal used to be."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "singularity_s3"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 7 SECONDS
	alpha = 0

/obj/effect/temp_visual/serio_void_singularity/Initialize(mapload, custom_duration, fade_in_time)
	if(custom_duration)
		duration = custom_duration
	. = ..()
	if(fade_in_time)
		animate(src, alpha = 255, time = fade_in_time, easing = LINEAR_EASING)
	else
		alpha = 255

// Bracket-3 variant — 5x5 / 160x160 silhouette. Pixel offsets shift the
// 160x160 sprite so its centre aligns with the 32x32 crystal tile
// (sprite spans tiles -2..+2 on each axis).
/obj/effect/temp_visual/serio_void_singularity/s5
	icon = 'icons/effects/160x160.dmi'
	icon_state = "singularity_s5"
	pixel_x = -64
	base_pixel_x = -64
	pixel_y = -64
	base_pixel_y = -64

// Echo of Her snow_storm overlay — arena-wide weather effect. Fades in
// during the setup window and fades out at the end of its duration so
// the room's "freezing over → thawing out" beats are visible.
/obj/effect/temp_visual/serio_echo_snow_storm
	name = "snow storm"
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "snow_storm"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 12 SECONDS
	alpha = 0

/obj/effect/temp_visual/serio_echo_snow_storm/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()
	animate(src, alpha = 200, time = 2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(StartFadeOut)), max(1, duration - 1 SECONDS), TIMER_STOPPABLE)

/obj/effect/temp_visual/serio_echo_snow_storm/proc/StartFadeOut()
	if(QDELETED(src))
		return
	animate(src, alpha = 0, time = 1 SECONDS)

// Echo of Her per-open-tile ground-freeze overlay — uses the
// `/turf/open/floor/grass/snow` icon family ('icons/turf/snow.dmi'
// state "snow") so the ground visibly freezes over while the figures
// cross.
/obj/effect/temp_visual/serio_echo_snow_ground
	name = "frozen ground"
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 10 SECONDS
	alpha = 0

/obj/effect/temp_visual/serio_echo_snow_ground/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()
	animate(src, alpha = 180, time = 1 SECONDS)

// Echo of Her walking figure — fades in, walks toward the crystal for
// `walk_distance` tiles, applies very heavy contact damage on every
// step, then fades out and qdels. Cannot be damaged, slowed, or CC'd.
/obj/effect/temp_visual/serio_echo_figure
	name = "static figure"
	desc = "A translucent shape of someone who isn't here anymore."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "her"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 12 SECONDS
	alpha = 0
	var/walk_distance = 6
	var/step_delay = 0.5 SECONDS
	var/damage = 110
	var/decay = 6
	var/can_shatter = TRUE
	var/mob/living/source
	/// Cardinal direction the figure walks every step. Fixed for
	/// crystal-walkers; re-aimed every step when `target_player` is set.
	var/walk_dir
	/// If the figure's next step would land on this turf, sidestep
	/// perpendicular. Used to keep crystal-adjacent walkers from
	/// crossing the crystal's own tile.
	var/turf/avoid_turf
	/// If set, the figure homes in on this player — re-aims every step.
	var/mob/living/target_player

/obj/effect/temp_visual/serio_echo_figure/Initialize(mapload, custom_walk, custom_step, custom_damage, custom_decay, custom_shatter, mob/living/new_source, custom_walk_dir, turf/turf_to_avoid, mob/living/player_to_track)
	. = ..()
	if(custom_walk)
		walk_distance = custom_walk
	if(custom_step)
		step_delay = custom_step
	if(custom_damage)
		damage = custom_damage
	if(custom_decay)
		decay = custom_decay
	can_shatter = custom_shatter
	source = new_source
	walk_dir = custom_walk_dir || pick(GLOB.cardinals)
	avoid_turf = turf_to_avoid
	target_player = player_to_track
	setDir(walk_dir)
	animate(src, alpha = 200, time = 0.5 SECONDS)
	INVOKE_ASYNC(src, PROC_REF(WalkPastCenter))

/// Walks `walk_distance` tiles. Crystal-walkers use a fixed walk_dir
/// and sidestep around `avoid_turf` (the crystal). Player-walkers
/// re-aim toward `target_player`'s current position every step. Per
/// brainstorm: figures can't be damaged, slowed, or CC'd — only
/// avoided. Every step damages anyone standing on the new tile.
/obj/effect/temp_visual/serio_echo_figure/proc/WalkPastCenter()
	if(QDELETED(src))
		return
	var/turf/current = get_turf(src)
	if(!current)
		return
	for(var/i in 1 to walk_distance)
		if(QDELETED(src))
			return
		sleep(step_delay)
		if(QDELETED(src))
			return
		current = get_turf(src)
		if(!current)
			return
		// Chase mode: re-aim toward player's current tile each step.
		if(target_player && !QDELETED(target_player) && target_player.stat != DEAD)
			var/new_dir = get_dir(current, get_turf(target_player))
			if(new_dir)
				walk_dir = new_dir
		var/turf/next_tile = get_step(current, walk_dir)
		var/actual_dir = walk_dir
		// Sidestep around the avoid_turf so we never cross it.
		if(next_tile && next_tile == avoid_turf)
			var/sidestep_dir = pick(turn(walk_dir, 90), turn(walk_dir, -90))
			next_tile = get_step(current, sidestep_dir)
			actual_dir = sidestep_dir
		if(next_tile && !next_tile.density)
			setDir(actual_dir)
			forceMove(next_tile)
			ApplyContactDamage()
		else
			break
	animate(src, alpha = 0, time = 0.5 SECONDS)
	QDEL_IN(src, 0.5 SECONDS)

/obj/effect/temp_visual/serio_echo_figure/proc/ApplyContactDamage()
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
		H.apply_lc_mental_decay(decay)
		if(can_shatter)
			serio_shatter_detonate(H)

// ---------- Void Pull AoE barrage visuals ----------

// 1x1 mini-AoE: telegraphs at a target tile for ~1s, then damages
// anyone on that tile when it detonates. Mirrors midnight's
// helix_minilaser shape.
/obj/effect/temp_visual/serio_void_mini_aoe
	name = "void rupture"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	color = "#c30fff"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1.2 SECONDS
	alpha = 180
	var/damage = 80
	var/decay = 2
	var/mob/living/source

/obj/effect/temp_visual/serio_void_mini_aoe/Initialize(mapload, mob/living/new_source, custom_telegraph)
	// Bump duration BEFORE parent Initialize when a longer telegraph is
	// requested so the auto-qdel timer outlives the detonation.
	if(!isnull(custom_telegraph) && custom_telegraph + 0.2 SECONDS > duration)
		duration = custom_telegraph + 0.2 SECONDS
	. = ..()
	source = new_source
	var/telegraph_delay = isnull(custom_telegraph) ? 1 SECONDS : custom_telegraph
	addtimer(CALLBACK(src, PROC_REF(Blowup)), telegraph_delay, TIMER_STOPPABLE)

/obj/effect/temp_visual/serio_void_mini_aoe/proc/Blowup()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
		H.apply_lc_mental_decay(decay)

// 3x3 macro-AoE: telegraphs at a target tile via a 96x96 warning
// sprite, detonates the full 3x3 around its center. Pixel-offset so
// the warning lines up with the center turf. Mirrors midnight's
// helix_macrolaser shape.
/obj/effect/temp_visual/serio_void_macro_aoe
	name = "void rupture"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#c30fff"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1.7 SECONDS
	alpha = 180
	var/damage = 140
	var/decay = 3
	var/mob/living/source
	/// Set TRUE when the Overseer fires this AoE as a Phase 2 B3
	/// K-aware sub-attack. Unlocks the Knight-tile player-intercept
	/// path in Blowup() and the Knight damage + charge-loss path. Phase
	/// 2 Void Pull spawns leave this FALSE.
	var/is_knight_aware = FALSE

/obj/effect/temp_visual/serio_void_macro_aoe/Initialize(mapload, mob/living/new_source, custom_telegraph)
	// Bump duration BEFORE the parent Initialize so the temp_visual
	// auto-qdel timer uses the larger value when custom_telegraph is
	// longer than the default 1.7s.
	if(!isnull(custom_telegraph) && custom_telegraph + 2 > duration)
		duration = custom_telegraph + 2
	. = ..()
	source = new_source
	var/telegraph_delay = isnull(custom_telegraph) ? 1.5 SECONDS : custom_telegraph
	addtimer(CALLBACK(src, PROC_REF(Blowup)), telegraph_delay, TIMER_STOPPABLE)

/obj/effect/temp_visual/serio_void_macro_aoe/proc/Blowup()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	// Phase 2 Knight-aware AoE intercept: any live human standing on
	// the Knight's tile sets the Knight's one-shot exempt flag so the
	// downstream damage + charge-loss path below skips it. The player
	// still takes the 3×3 AoE damage as the intercept cost.
	if(is_knight_aware)
		var/mob/living/simple_animal/hostile/serio_knight/K_on_tile = locate() in T
		if(K_on_tile)
			for(var/mob/living/carbon/human/H in T)
				if(H.stat == DEAD)
					continue
				K_on_tile.knight_aware_aoe_exempt = TRUE
				break
	for(var/turf/A in range(1, T))
		for(var/mob/living/carbon/human/H in A)
			if(H.stat == DEAD)
				continue
			H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
			H.apply_lc_mental_decay(decay)
		// Knight damage + charge-loss path (Phase 2 K-aware AoE only).
		// OnAntiKnightHit reads the exempt flag and short-circuits if
		// a player intercepted on the Knight's tile. Un-intercepted
		// the AoE drains the Knight's charge fully (100%).
		if(is_knight_aware)
			for(var/mob/living/simple_animal/hostile/serio_knight/K in A)
				if(K.stat == DEAD)
					continue
				K.OnAntiKnightHit(damage, 100)
