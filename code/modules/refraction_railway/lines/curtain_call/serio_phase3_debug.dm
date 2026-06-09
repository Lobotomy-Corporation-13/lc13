/*
 * Phase 3 debug Caretaker — admin/test spawn that drops you into Phase 3
 * immediately, bypassing Phase 1 and Phase 2.
 *
 * Lets you iterate on steps 2-17 from the implementation plan without
 * playing through the pressure meter + red/blue cycle every time.
 *
 * For production trigger testing (step 1 specifically), use the regular
 * Caretaker — this debug variant skips that path.
 */

/mob/living/simple_animal/hostile/serio_caretaker/debug_phase3
	name = "Caretaker (Phase 3 debug)"
	desc = "A debug variant. Skips Phase 1 and Phase 2 entirely; opens at Phase 3."

/mob/living/simple_animal/hostile/serio_caretaker/debug_phase3/Initialize(mapload)
	. = ..()
	// Parent Initialize calls SpawnCrystalNearby() and starts MainTick.
	// We jump to Phase 3 0.5s later so the crystal bind has settled.
	// EnterPhase3 sets phase_3 = TRUE, which causes the next MainTick
	// to early-return, so Phase 2 mechanics never run.
	addtimer(CALLBACK(src, PROC_REF(JumpToPhase3)), 0.5 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_caretaker/debug_phase3/proc/JumpToPhase3()
	if(QDELETED(src) || QDELETED(parent_crystal))
		return
	// Mirror TriggerPhase3Entry's invuln-flip without the HP refill +
	// the visible_message strain beat — we want Phase 3 active
	// instantly with the crystal at full HP.
	parent_crystal.is_invulnerable_p3 = TRUE
	parent_crystal.ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	EnterPhase3()
