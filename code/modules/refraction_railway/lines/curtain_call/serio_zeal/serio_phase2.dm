/*
 * Phase 2 attack rotation tick. Cadence per bracket: 6s / 5s / 4s.
 * The actual attack-spawn lives in serio_anti_knight.dm
 * (FireAntiKnightForBracket).
 *
 * Uses an addtimer-chained tick rather than a sleep-in-while loop so
 * the schedule is robust: each invocation queues the next, no risk of
 * the loop "losing" its sleep / async context.
 *
 * Murmurs, Knight charge mechanic, and Sage support all run from
 * their own timers and don't gate on this tick.
 *
 * Build-order step 6 (and used by 7-9 for the same cadence path).
 */

/mob/living/simple_animal/hostile/serio_overseer/proc/Phase2Tick()
	if(!phase_2 || QDELETED(src))
		return
	var/bracket = 1
	if(parent_crystal && !QDELETED(parent_crystal))
		bracket = parent_crystal.current_bracket
	// Anti-Knight cadence: B1=6s, B2=10s (volley is a 5-lance salvo,
	// big hit-count per cast — needs a recovery window), B3=4s.
	var/cadence
	switch(bracket)
		if(1)
			cadence = 6 SECONDS
		if(2)
			cadence = 10 SECONDS
		else
			cadence = 4 SECONDS
	FireAntiKnightForBracket(bracket)
	addtimer(CALLBACK(src, PROC_REF(Phase2Tick)), cadence, TIMER_STOPPABLE)

// ---------- Resolution (step 17) ----------

/// Snaps the Crystal's icon_state to the given value and fires the
/// shatter-glass cue. Called on Phase 2 entry (crack) and on each of
/// the Knight's three slashes (shatter_1 / shatter_2 / shatter_3).
/mob/living/simple_animal/hostile/serio_overseer/proc/SetCrystalIconState(new_state)
	if(QDELETED(parent_crystal))
		return
	parent_crystal.icon_state = new_state
	parent_crystal.icon_living = new_state
	playsound(parent_crystal, 'sound/weapons/ego/shattering_window.ogg', 60, TRUE)

/// Bracket-3 slash: shake the crystal briefly, then break it (fade +
/// clear underlay) and release the sealed star to float down. The
/// final-beat dialogue begins at the same moment the float starts;
/// the dissolve cinematic follows 8s later.
/mob/living/simple_animal/hostile/serio_overseer/proc/ShatterAndFinalBeat()
	if(!phase_2)
		return
	EndBracket3Storm()
	phase_2 = FALSE
	if(QDELETED(parent_crystal))
		PlayFinalBeatDialogue()
		addtimer(CALLBACK(src, PROC_REF(DissolveSequence)), 8 SECONDS, TIMER_STOPPABLE)
		return
	var/mob/living/simple_animal/hostile/serio_crystal/C = parent_crystal
	// Pixel-jitter shake — 5 swings of 1ds each (~0.5s total).
	var/base_px = C.base_pixel_x
	animate(C, pixel_x = base_px - 4, time = 1)
	animate(pixel_x = base_px + 4, time = 1)
	animate(pixel_x = base_px - 4, time = 1)
	animate(pixel_x = base_px + 4, time = 1)
	animate(pixel_x = base_px, time = 1)
	addtimer(CALLBACK(src, PROC_REF(BreakCrystalAndFloat)), 0.5 SECONDS, TIMER_STOPPABLE)

/// Final beat — crystal fades out, sealed-star underlay is replaced
/// with a free-floating temp_visual that drifts to ground level,
/// dialogue plays, dissolve cinematic queued.
/mob/living/simple_animal/hostile/serio_overseer/proc/BreakCrystalAndFloat()
	var/turf/T = parent_crystal ? get_turf(parent_crystal) : null
	if(parent_crystal && !QDELETED(parent_crystal))
		parent_crystal.underlays.Cut()
		animate(parent_crystal, alpha = 0, time = 1 SECONDS)
	if(T)
		new /obj/effect/temp_visual/serio_floating_star(T)
	PlayFinalBeatDialogue()
	addtimer(CALLBACK(src, PROC_REF(DissolveSequence)), 8 SECONDS, TIMER_STOPPABLE)

/// Backwards-compatible entry-point. The B3 slash path now routes
/// through ShatterAndFinalBeat for the shatter cinematic; anything
/// that wants to end the encounter without the cinematic can still
/// call EndEncounter directly.
/mob/living/simple_animal/hostile/serio_overseer/proc/EndEncounter()
	if(!phase_2)
		return
	phase_2 = FALSE
	PlayFinalBeatDialogue()
	addtimer(CALLBACK(src, PROC_REF(DissolveSequence)), 8 SECONDS, TIMER_STOPPABLE)

/// Cleans up the encounter. Fades the Overseer out, spawns the
/// crystal-shatter visual at the crystal tile, and queues qdel on
/// every Phase 2 actor: Overseer, crystal, Knight, Sage, all live
/// Murmurs. When the Overseer (the wave's boss = TRUE mob) is
/// gone, the standard wave-clear hook fires.
/mob/living/simple_animal/hostile/serio_overseer/proc/DissolveSequence()
	visible_message(span_userdanger("[src] dissolves."))
	animate(src, alpha = 0, time = 3 SECONDS)
	if(parent_crystal && !QDELETED(parent_crystal))
		new /obj/effect/temp_visual/serio_crystal_shatter(get_turf(parent_crystal))
		QDEL_IN(parent_crystal, 3 SECONDS)
	if(knight_ref && !QDELETED(knight_ref))
		QDEL_IN(knight_ref, 5 SECONDS)
	if(sage_ref && !QDELETED(sage_ref))
		QDEL_IN(sage_ref, 5 SECONDS)
	for(var/mob/living/simple_animal/hostile/serio_murmur/M as anything in active_murmurs)
		if(!QDELETED(M))
			QDEL_IN(M, 3 SECONDS)
	QDEL_IN(src, 3 SECONDS)

/// Crystal shatter cinematic. Reuses the 96x96 violet warning icon
/// scaled up + faded as the seal breaks apart.
/obj/effect/temp_visual/serio_crystal_shatter
	name = "shattered seal"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#c30fff"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 3 SECONDS
	alpha = 230

/obj/effect/temp_visual/serio_crystal_shatter/Initialize(mapload)
	. = ..()
	// Fade out + scale up as the seal pieces fly apart.
	animate(src, alpha = 0, transform = matrix() * 1.4, time = 3 SECONDS)

/// Free-floating sealed_star visual spawned at the Crystal tile once
/// the third slash lands and the seal cracks open. Starts at the
/// pixel offset the underlay was using and slowly drifts to ground
/// level. Lifetime spans the final dialogue + dissolve sequence so
/// the star stays visible until the encounter cleans itself up.
/obj/effect/temp_visual/serio_floating_star
	name = "sealed star"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "sealed_star"
	pixel_y = 32
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 11 SECONDS

/obj/effect/temp_visual/serio_floating_star/Initialize(mapload)
	. = ..()
	// 3-second gentle drift down to the floor.
	animate(src, pixel_y = 0, time = 3 SECONDS, easing = SINE_EASING)
