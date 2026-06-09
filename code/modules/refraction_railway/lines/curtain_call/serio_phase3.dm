/*
 * Phase 3 attack rotation tick. Cadence per bracket: 6s / 5s / 4s.
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

/mob/living/simple_animal/hostile/serio_caretaker/proc/Phase3Tick()
	if(!phase_3 || QDELETED(src))
		return
	var/bracket = 1
	if(parent_crystal && !QDELETED(parent_crystal))
		bracket = parent_crystal.current_bracket
	// Anti-Knight cadence: B1=6s, B2=5s, B3=4s. Slower than Phase 2
	// because Phase 3 layers Murmurs (step 11+) on top of every cast.
	var/cadence
	switch(bracket)
		if(1)
			cadence = 6 SECONDS
		if(2)
			cadence = 5 SECONDS
		else
			cadence = 4 SECONDS
	FireAntiKnightForBracket(bracket)
	addtimer(CALLBACK(src, PROC_REF(Phase3Tick)), cadence, TIMER_STOPPABLE)

// ---------- Resolution (step 17) ----------

/// Called from OnKnightSlashLanded when the bracket-3 slash lands.
/// Stops all Phase 3 ticks (phase_3 = FALSE causes Phase3Tick and
/// MurmurSpawnTick to early-return on their next firing), plays the
/// final dialogue beat, and schedules the dissolve cinematic 8s out.
/mob/living/simple_animal/hostile/serio_caretaker/proc/EndEncounter()
	if(!phase_3)
		return
	phase_3 = FALSE
	PlayFinalBeatDialogue()
	addtimer(CALLBACK(src, PROC_REF(DissolveSequence)), 8 SECONDS, TIMER_STOPPABLE)

/// Cleans up the encounter. Fades the Caretaker out, spawns the
/// crystal-shatter visual at the crystal tile, and queues qdel on
/// every Phase 3 actor: Caretaker, crystal, Knight, Sage, all live
/// Murmurs. When the Caretaker (the wave's boss = TRUE mob) is
/// gone, the standard wave-clear hook fires.
/mob/living/simple_animal/hostile/serio_caretaker/proc/DissolveSequence()
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
