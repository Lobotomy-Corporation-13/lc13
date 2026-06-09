/*
 * The Murmur — Phase 3 minion mob. Stationary, projectile-permeable,
 * draws a beam to the Knight that scales the Knight's charge tick down.
 * Spawned on the arena perimeter by the Caretaker; killing them is the
 * second player priority alongside body-blocking anti-Knight projectiles.
 *
 * Build-order steps 11 (skeleton + beam + charge multiplier),
 * 13 (3 reused Phase 2 attacks), 14 (4 new movement-friendly attacks).
 */

// ---------- Attack ID enum ----------

#define MURMUR_ATTACK_ERRANT_DRAFTS 1
#define MURMUR_ATTACK_CHASE_THE_BUG 2
#define MURMUR_ATTACK_BURNOUT_BILL  3
#define MURMUR_ATTACK_WHISPER_HEX   4
#define MURMUR_ATTACK_MEMORY_STAB   5
#define MURMUR_ATTACK_ECHO_MOTE     6
#define MURMUR_ATTACK_DRAG_PULSE    7

// ---------- Custom beam type (tint only) ----------

/obj/effect/ebeam/serio_murmur
	color = "#9966ff"

// ---------- Mob ----------

/mob/living/simple_animal/hostile/serio_murmur
	name = "murmur"
	desc = "A reinforcing voice. While alive, it tugs at the Knight's charge."
	icon = 'icons/effects/effects.dmi'
	icon_state = "static"
	color = "#9966ff"
	faction = list("serio_zeal")
	maxHealth = 1000
	health = 1000
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.8)
	// Anti-Knight lances phase through via projectile_phasing = PASSGLASS.
	// Players still impact us normally with their EGO/weapon projectiles
	// since those don't set projectile_phasing.
	pass_flags_self = PASSGLASS
	melee_damage_lower = 0
	melee_damage_upper = 0
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	density = TRUE
	speed = 4
	move_to_delay = 999
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	/// Back-ref to the Caretaker that spawned this Murmur.
	var/mob/living/simple_animal/hostile/serio_caretaker/parent_caretaker
	/// Knight this Murmur is tethered to.
	var/mob/living/simple_animal/hostile/serio_knight/knight_ref
	/// The persistent beam tether obj.
	var/datum/beam/charge_beam
	/// Which attack this Murmur runs on its cadence (one of the 7 IDs).
	var/assigned_attack = MURMUR_ATTACK_ERRANT_DRAFTS
	/// World.time of next attack cast.
	var/next_attack_at = 0

/mob/living/simple_animal/hostile/serio_murmur/Initialize(mapload, mob/living/parent, mob/living/knight, attack_id)
	. = ..()
	toggle_ai(AI_OFF)
	parent_caretaker = parent
	knight_ref = knight
	if(attack_id)
		assigned_attack = attack_id
	if(knight_ref && !QDELETED(knight_ref))
		knight_ref.active_murmur_beams++
		charge_beam = Beam(knight_ref, "1-full", time = INFINITY, beam_type = /obj/effect/ebeam/serio_murmur)
	next_attack_at = world.time + rand(2 SECONDS, 4 SECONDS)

/mob/living/simple_animal/hostile/serio_murmur/Destroy()
	if(knight_ref && !QDELETED(knight_ref))
		knight_ref.active_murmur_beams = max(0, knight_ref.active_murmur_beams - 1)
	if(charge_beam && !QDELETED(charge_beam))
		qdel(charge_beam)
	charge_beam = null
	if(parent_caretaker && !QDELETED(parent_caretaker))
		parent_caretaker.active_murmurs -= src
	parent_caretaker = null
	knight_ref = null
	return ..()

/// Stationary for the duration of Phase 3.
/mob/living/simple_animal/hostile/serio_murmur/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_murmur/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/serio_murmur/Life()
	. = ..()
	if(stat == DEAD)
		return
	if(world.time >= next_attack_at)
		FireAssignedAttack()
		next_attack_at = world.time + rand(8 SECONDS, 12 SECONDS)

/// Dispatches to the right attack proc based on `assigned_attack`.
/// IDs 1-3 reuse the Caretaker's existing Phase 2 procs (called with
/// `weakened = TRUE` so damage/decay/shatter scale down). IDs 4-7 are
/// new Murmur-only attacks that fire from the Murmur's own tile.
/mob/living/simple_animal/hostile/serio_murmur/proc/FireAssignedAttack()
	if(QDELETED(src) || stat == DEAD)
		return
	switch(assigned_attack)
		if(MURMUR_ATTACK_ERRANT_DRAFTS)
			if(parent_caretaker && !QDELETED(parent_caretaker))
				parent_caretaker.InvokeErrantDrafts(TRUE)
		if(MURMUR_ATTACK_CHASE_THE_BUG)
			if(parent_caretaker && !QDELETED(parent_caretaker))
				parent_caretaker.InvokeChaseTheBug(TRUE)
		if(MURMUR_ATTACK_BURNOUT_BILL)
			if(parent_caretaker && !QDELETED(parent_caretaker))
				parent_caretaker.InvokeBurnoutBill(TRUE)
		if(MURMUR_ATTACK_WHISPER_HEX)
			FireWhisperHex()
		if(MURMUR_ATTACK_MEMORY_STAB)
			FireMemoryStab()
		if(MURMUR_ATTACK_ECHO_MOTE)
			FireEchoMote()
		if(MURMUR_ATTACK_DRAG_PULSE)
			FireDragPulse()

// ---------- Step 14: four new Murmur-only attacks ----------

// Whisper-Hex: a stationary 3x3 hex on a random nearby tile. 2s
// telegraph then detonates. Players step off; no contraction, no
// forced movement.
/obj/effect/temp_visual/serio_whisper_hex
	name = "whisper hex"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#9966ff"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 2.5 SECONDS
	alpha = 180
	var/damage = 25
	var/mob/living/source

/obj/effect/temp_visual/serio_whisper_hex/Initialize(mapload, mob/living/new_source)
	. = ..()
	source = new_source
	addtimer(CALLBACK(src, PROC_REF(Detonate)), 2 SECONDS, TIMER_STOPPABLE)

/obj/effect/temp_visual/serio_whisper_hex/proc/Detonate()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/turf/A in range(1, T))
		for(var/mob/living/carbon/human/H in A)
			if(H.stat == DEAD)
				continue
			H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))

/mob/living/simple_animal/hostile/serio_murmur/proc/FireWhisperHex()
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/candidates = list()
	for(var/turf/T in range(8, center))
		if(get_dist(T, center) < 4)
			continue
		if(T.density)
			continue
		candidates += T
	if(!length(candidates))
		return
	new /obj/effect/temp_visual/serio_whisper_hex(pick(candidates), src)

// Memory-Stab: a stationary 1-tile-wide line beam from the Murmur in a
// random cardinal. 1.5s telegraph, then detonates along the line.
/obj/effect/temp_visual/serio_memory_stab_telegraph
	name = "memory stab"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#9966ff"
	alpha = 130
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1.6 SECONDS

/obj/effect/temp_visual/serio_memory_stab_detonation
	name = "memory stab"
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	color = "#9966ff"
	alpha = 200
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 0.6 SECONDS

/mob/living/simple_animal/hostile/serio_murmur/proc/FireMemoryStab()
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/line_dir = pick(GLOB.cardinals)
	var/list/line_tiles = list()
	var/turf/cur = center
	for(var/i in 1 to 8)
		cur = get_step(cur, line_dir)
		if(!cur || cur.density)
			break
		line_tiles += cur
		new /obj/effect/temp_visual/serio_memory_stab_telegraph(cur)
	if(!length(line_tiles))
		return
	addtimer(CALLBACK(src, PROC_REF(MemoryStabDetonate), line_tiles), 1.5 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_murmur/proc/MemoryStabDetonate(list/line_tiles)
	if(!islist(line_tiles))
		return
	for(var/turf/T as anything in line_tiles)
		if(!T)
			continue
		new /obj/effect/temp_visual/serio_memory_stab_detonation(T)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(20, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))

// Echo-Mote: a single walker spawned at the Murmur's tile. Walks 5-6
// tiles in a random cardinal, dealing damage to anything on each tile
// it lands on. No snow overlay (vs. Phase 2 Echo of Her).
/obj/effect/temp_visual/serio_echo_mote
	name = "echo"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#9966ff"
	alpha = 200
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 5 SECONDS
	var/mob/living/source
	var/walk_dir
	var/walk_distance = 6
	var/step_delay = 4
	var/damage = 25
	var/walked = 0

/obj/effect/temp_visual/serio_echo_mote/Initialize(mapload, mob/living/new_source, custom_walk_dir)
	. = ..()
	source = new_source
	walk_dir = custom_walk_dir || pick(GLOB.cardinals)
	addtimer(CALLBACK(src, PROC_REF(StepForward)), step_delay)

/obj/effect/temp_visual/serio_echo_mote/proc/StepForward()
	if(QDELETED(src) || walked >= walk_distance)
		return
	var/turf/T = get_step(src, walk_dir)
	if(!T || T.density)
		return
	forceMove(T)
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
	walked++
	addtimer(CALLBACK(src, PROC_REF(StepForward)), step_delay)

/mob/living/simple_animal/hostile/serio_murmur/proc/FireEchoMote()
	var/turf/T = get_turf(src)
	if(!T)
		return
	new /obj/effect/temp_visual/serio_echo_mote(T, src)

// Drag-Pulse: one-time 1-tile pull on each player within 6 tiles of
// the Murmur. Brief disruption, no continuous suction.
/obj/effect/temp_visual/serio_drag_pulse
	name = "drag pulse"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#9966ff"
	alpha = 200
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 0.7 SECONDS

/mob/living/simple_animal/hostile/serio_murmur/proc/FireDragPulse()
	var/turf/center = get_turf(src)
	if(!center)
		return
	new /obj/effect/temp_visual/serio_drag_pulse(center)
	for(var/mob/living/carbon/human/H in view(6, center))
		if(H.stat == DEAD)
			continue
		var/pull_dir = get_dir(H, src)
		if(!pull_dir)
			continue
		var/turf/dest = get_step(H, pull_dir)
		if(dest && !dest.density)
			H.Move(dest, pull_dir)
