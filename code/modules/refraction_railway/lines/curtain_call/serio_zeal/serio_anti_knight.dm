/*
 * Phase 2 anti-Knight attack rotation. Spawned by the Overseer from
 * Phase2Loop based on the current bracket. All attacks aim at the
 * Knight; players intercept by body-blocking the projectile/seeker
 * path (lance, salvo, seeker, chaser) or by standing on the Knight's
 * tile during the telegraph (Knight-aware AoE).
 *
 * Build-order steps 6-9. Charge-loss values per the plan's per-bracket
 * table: B1 lance 6, B2 salvo 4 each, B3 seeker 8, B3 K-aware AoE 25,
 * B3 chaser 8.
 */

// ---------- Echo-line anchor visual ----------

/// Faint pulsing tile west of the Overseer. Pure visual — marks the
/// spawn point of every anti-Knight projectile so players learn where
/// to pre-stack interceptors.
/obj/effect/temp_visual/serio_echo_anchor
	name = "echo line"
	desc = "The air here folds inward. Things crystallise out of it."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#c30fff"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 100
	duration = 10 MINUTES

/obj/effect/temp_visual/serio_echo_anchor/Initialize(mapload)
	. = ..()
	animate(src, alpha = 50, time = 1.5 SECONDS, loop = -1, easing = SINE_EASING)
	animate(alpha = 100, time = 1.5 SECONDS, easing = SINE_EASING)

// ---------- Anti-Knight lance projectile ----------

/obj/projectile/serio_lance
	name = "violet lance"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "logic"
	color = "#c30fff"
	damage = 60
	damage_type = BLACK_DAMAGE
	// 4x slower than typical SS13 projectiles so players have time to
	// see the trajectory + step into the path. With speed = 4 the
	// lance moves about 2.5 tiles/s.
	speed = 4
	homing = TRUE
	homing_turn_speed = 6
	// Phase through the crystal (and any other PASSGLASS-marked mob)
	// without applying damage. phasing_ignore_direct_target preserves
	// the hit on the Knight — see prehit_pierce in projectile.dm:607.
	projectile_phasing = PASSGLASS
	phasing_ignore_direct_target = TRUE
	// Ricochet off walls. Pattern borrowed from /obj/projectile/flame_fixer
	// in ModularLobotomy/extra_mobs/lc13_humanoids.dm:731. Walls bounce
	// the lance instead of stopping it; the crystal still phases via
	// PASSGLASS, and mobs (Knight, players) still impact normally.
	ricochets_max = 5
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_incidence_leeway = 0
	/// Charge subtracted from the Knight if this lance hits.
	var/charge_loss_on_hit = 25

/obj/projectile/serio_lance/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(istype(target, /mob/living/simple_animal/hostile/serio_knight))
		var/mob/living/simple_animal/hostile/serio_knight/K = target
		// Parent on_hit already applied HP damage. Pass 0 here so we
		// don't double-damage; the charge_loss is the only extra hit.
		K.OnAntiKnightHit(0, charge_loss_on_hit)
	else if(ishuman(target))
		// Lance hits on players apply mental decay; if the player is
		// already marked, shatter the mark (sanity payoff) and pile on
		// 3 BLACK fragile stacks so subsequent hits hurt more.
		var/mob/living/carbon/human/H = target
		H.apply_lc_mental_decay(rand(4, 8))
		var/datum/status_effect/mental_detonate/MD = H.has_status_effect(/datum/status_effect/mental_detonate)
		if(MD)
			MD.shatter()
			H.apply_lc_black_fragile(3)

/// Ricochet off closed turfs (walls) but not floors. Matches the
/// flame_fixer pattern at lc13_humanoids.dm:749.
/obj/projectile/serio_lance/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	return FALSE

/// Phase through the Sage without applying damage — the Sage is a
/// background support mob for the encounter; projectiles target the
/// Knight only. Crystal phasing is handled separately via PASSGLASS.
/// Also handles the player defense-bubble intercept: if a human has
/// the bubble status, the lance consumes one charge and qdels
/// without applying damage to the player.
/obj/projectile/serio_lance/prehit_pierce(atom/A)
	if(istype(A, /mob/living/simple_animal/hostile/serio_sage))
		return PROJECTILE_PIERCE_PHASE
	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		var/datum/status_effect/serio_defense_bubble/B = H.has_status_effect(/datum/status_effect/serio_defense_bubble)
		if(B)
			B.ConsumeCharge()
			return PROJECTILE_DELETE_WITHOUT_HITTING
	return ..()

/// Switches the lance to fly directly at the Knight after the
/// "curve-around-the-crystal" waypoint phase. We snap the angle to
/// the Knight's exact bearing AND disable homing — the Knight is
/// locked at a fixed tile, so a straight line works, and disabling
/// homing avoids the 1-pixel offset clamp in process_homing that
/// otherwise nudges the lance off-target each tick.
/obj/projectile/serio_lance/proc/SwitchHomingToKnight(mob/living/new_target)
	if(QDELETED(src) || QDELETED(new_target))
		return
	var/turf/T_self = get_turf(src)
	var/turf/T_target = get_turf(new_target)
	if(T_self && T_target)
		set_angle(Get_Angle(src, T_target))
	homing = FALSE
	homing_target = null

// ---------- B3 seeker (chaser-style, wall-pathfinding, single-hit) ----------

/// Walks tile-to-tile toward the Knight using the Errant Drafts seek
/// loop. Dies on first contact — with a player (body-block) or with
/// the Knight (intended target). Pathfinds around walls so it can't
/// be cheesed by line-of-sight tricks.
/obj/effect/temp_visual/serio_anti_knight_seeker
	name = "void seeker"
	desc = "A crawling whisper that pathfinds toward the Knight."
	icon = 'icons/effects/effects.dmi'
	icon_state = "curseblob"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 12 SECONDS
	alpha = 200
	var/mob/living/simple_animal/hostile/serio_knight/target_knight
	var/turf/targetturf
	var/mob/living/source
	var/moving_dir
	var/previous_moving_dir
	var/more_previouser_moving_dir
	var/moving = 0
	// Recalculate the direction every single tile so the seeker picks
	// the most direct cardinal toward the Knight on each step.
	// Without this it would walk 4 tiles in one direction before
	// reconsidering, which made off-axis seekers overshoot and miss.
	var/standard_moving_before_recalc = 1
	var/tiles_per_step = 1
	var/speed = 6
	var/damage = 76
	var/charge_loss = 18
	var/currently_seeking = FALSE

/obj/effect/temp_visual/serio_anti_knight_seeker/Initialize(mapload, mob/living/new_source, mob/living/simple_animal/hostile/serio_knight/new_target)
	. = ..()
	source = new_source
	target_knight = new_target
	// Light-purple outline mirroring the Cold Word Puddle so the
	// crawler reads as the same family of "ambient hazard" against
	// the stage floor. Same filter pattern as the radioactive
	// component (code/datums/components/radioactive.dm:32).
	add_filter("serio_seeker_glow", 2, list("type" = "outline", "color" = "#c890ff80", "size" = 1))
	addtimer(CALLBACK(src, PROC_REF(seek_target)), 5)

/// Pick a cardinal direction toward target_knight, with anti-jitter
/// logic borrowed from serio_errant_draft.get_target_dir.
/obj/effect/temp_visual/serio_anti_knight_seeker/proc/get_target_dir()
	. = get_cardinal_dir(src, targetturf)
	if((. != previous_moving_dir && . == more_previouser_moving_dir) || . == 0)
		var/list/cardinal_copy = GLOB.cardinals.Copy()
		cardinal_copy -= more_previouser_moving_dir
		. = pick(cardinal_copy)

/// Cardinal-step seek loop. Same shape as the Errant Drafts chaser
/// (serio_overseer.dm:1699) but the target is the Knight instead of
/// a player-pool, and ApplyContactDamage kills the seeker on any
/// contact so it functions as a single-hit projectile-equivalent.
/obj/effect/temp_visual/serio_anti_knight_seeker/proc/seek_target()
	if(currently_seeking)
		return
	currently_seeking = TRUE
	targetturf = get_turf(target_knight)
	while(src && !QDELETED(src) && currently_seeking && x && y)
		if(QDELETED(target_knight) || target_knight.stat == DEAD)
			break
		targetturf = get_turf(target_knight)
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
			if(ApplyContactDamage())
				return
			moving--
			sleep(speed)

/// Single-hit damage check. Returns TRUE if the seeker hit something
/// (player or Knight) and should die. Body-blocking players soak the
/// hit without any charge loss; Knight hit triggers OnAntiKnightHit.
/obj/effect/temp_visual/serio_anti_knight_seeker/proc/ApplyContactDamage()
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		H.deal_damage(damage, BLACK_DAMAGE, source, attack_type = (ATTACK_TYPE_SPECIAL))
		qdel(src)
		return TRUE
	for(var/mob/living/simple_animal/hostile/serio_knight/K in T)
		if(K.stat == DEAD)
			continue
		K.OnAntiKnightHit(damage, charge_loss)
		qdel(src)
		return TRUE
	return FALSE

// ---------- Overseer fire procs ----------

/// Pick a random anchor tile from the column for projectile spawn.
/// Returns null if the column is empty (e.g. Phase 2 entered in a
/// tight space where no column tiles could be located).
/mob/living/simple_animal/hostile/serio_overseer/proc/PickEchoAnchor()
	if(!length(echo_anchor_pool))
		return null
	return pick(echo_anchor_pool)

/// Resolve the waypoint a lance should aim at first based on which
/// column row it spawned from. Top half of the column → aim 2 tiles
/// above the crystal; bottom half → 2 tiles below; the centre row
/// picks randomly. The lance flies to the waypoint, then switches
/// homing to the Knight (see FireLanceFromAnchor). This makes the
/// projectile arc around the Overseer + crystal rather than going
/// straight through them.
/mob/living/simple_animal/hostile/serio_overseer/proc/GetWaypointForAnchor(turf/anchor)
	if(!anchor || QDELETED(parent_crystal))
		return null
	var/turf/crystal_turf = get_turf(parent_crystal)
	if(!crystal_turf)
		return null
	var/dy = anchor.y - crystal_turf.y
	var/target_dy
	if(dy > 0)
		target_dy = 2
	else if(dy < 0)
		target_dy = -2
	else
		target_dy = prob(50) ? 2 : -2
	return locate(crystal_turf.x, crystal_turf.y + target_dy, crystal_turf.z)

/// Shared lance builder. Spawns a serio_lance at `anchor`, aims it at
/// the waypoint (or the Knight if no waypoint), and schedules the
/// waypoint→Knight homing-target switch after 2 seconds so the lance
/// curves cleanly around the crystal.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireLanceFromAnchor(turf/anchor, charge_loss, lance_speed, turn_speed, lance_damage)
	if(QDELETED(src) || QDELETED(knight_ref) || !anchor)
		return null
	var/turf/waypoint = GetWaypointForAnchor(anchor)
	var/atom/initial_target = waypoint || knight_ref
	var/obj/projectile/serio_lance/P = new(anchor)
	if(QDELETED(P))
		return null
	P.starting = anchor
	P.firer = src
	P.fired_from = src
	P.yo = initial_target.y - anchor.y
	P.xo = initial_target.x - anchor.x
	P.original = knight_ref
	if(!isnull(charge_loss))
		P.charge_loss_on_hit = charge_loss
	if(!isnull(lance_speed))
		P.speed = lance_speed
	if(!isnull(lance_damage))
		P.damage = lance_damage
	P.preparePixelProjectile(initial_target, anchor)
	P.fire()
	// Set homing target manually (not via set_homing_target) so we
	// don't pick up its random offset values.
	P.homing_target = initial_target
	P.homing = TRUE
	P.homing_offset_x = 0
	P.homing_offset_y = 0
	if(!isnull(turn_speed))
		P.homing_turn_speed = turn_speed
	if(waypoint)
		addtimer(CALLBACK(P, TYPE_PROC_REF(/obj/projectile/serio_lance, SwitchHomingToKnight), knight_ref), 2 SECONDS, TIMER_STOPPABLE)
	return P

/// B1 lance. Single lance from a random column tile. Arcs around the
/// crystal via the waypoint, then homes onto the Knight.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightLance()
	if(QDELETED(knight_ref) || !length(echo_anchor_pool))
		return
	var/turf/anchor = PickEchoAnchor()
	FireLanceFromAnchor(anchor, charge_loss = 25, lance_speed = 4, turn_speed = 6)

/// B3 lance chaser. Same arc shape as B1 lance but with a tighter
/// homing turn radius and bigger charge bite. Designed to come in
/// after the seeker so interceptors have to re-position quickly.
/// Fires 2-3 lances per cast, each from an independently-picked
/// column tile, staggered 0.25s apart so players can read the wave.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightLanceChaser()
	if(QDELETED(knight_ref) || !length(echo_anchor_pool))
		return
	var/count = rand(2, 3)
	for(var/i in 1 to count)
		addtimer(CALLBACK(src, PROC_REF(FireAntiKnightLanceChaserOne)), (i - 1) * 0.25 SECONDS, TIMER_STOPPABLE)

/// One projectile of the B3 chaser wave. Stagger-scheduled by
/// FireAntiKnightLanceChaser.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightLanceChaserOne()
	if(QDELETED(src) || QDELETED(knight_ref) || !length(echo_anchor_pool))
		return
	var/turf/anchor = PickEchoAnchor()
	FireLanceFromAnchor(anchor, charge_loss = 18, lance_speed = 3.2, turn_speed = 10)

/// B2 salvo. Five lances staggered 0.3s apart, each from a different
/// column row. Bottom-to-top firing order. Each lance picks the
/// waypoint matching its column row (top half → north of crystal,
/// bottom half → south, middle row → random). If the column shrunk
/// (fewer than 5 valid tiles, e.g. arena edge), fires what it can.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightSalvo()
	if(QDELETED(knight_ref) || !length(echo_anchor_pool))
		return
	var/list/anchors = echo_anchor_pool.Copy()
	for(var/i in 1 to length(anchors))
		var/turf/anchor = anchors[i]
		addtimer(CALLBACK(src, PROC_REF(FireSalvoLanceAt), anchor), (i - 1) * 0.3 SECONDS, TIMER_STOPPABLE)

/// One projectile of the B2 salvo. Stagger-scheduled by
/// FireAntiKnightSalvo so each anchor in the column gets its own
/// firing tick.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireSalvoLanceAt(turf/anchor)
	if(QDELETED(src) || QDELETED(knight_ref) || !anchor)
		return
	// Salvo lances: 50% damage and 50% charge bite of the base lance —
	// 5 hits per cast adds up fast, so each one carries less weight.
	FireLanceFromAnchor(anchor, charge_loss = 3, lance_speed = 4, turn_speed = 8, lance_damage = 30)

/// B3 seeker. Wall-pathfinding chaser variant of Errant Drafts.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightSeeker()
	if(QDELETED(knight_ref) || !length(echo_anchor_pool))
		return
	var/turf/anchor = PickEchoAnchor()
	if(!anchor)
		return
	new /obj/effect/temp_visual/serio_anti_knight_seeker(anchor, src, knight_ref)

/// B3 Knight-aware AoE. Spawns a void macro AoE directly on the
/// Knight's tile with the is_knight_aware flag set. 5-second telegraph
/// — long warning window. Player intercept is by standing on the
/// Knight's tile during the telegraph; see serio_void_macro_aoe.Blowup().
/// If un-intercepted, the AoE drains the Knight's charge fully (100%).
/// Cannot re-fire while a K-aware AoE is already telegraphing.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireKnightAwareAoE()
	if(QDELETED(knight_ref) || aoe_charging)
		return
	var/turf/knight_turf = get_turf(knight_ref)
	if(!knight_turf)
		return
	aoe_charging = TRUE
	var/obj/effect/temp_visual/serio_void_macro_aoe/A = new(knight_turf, src, 5 SECONDS)
	A.is_knight_aware = TRUE
	// K-aware override: typepath default is 140 (Phase 2 barrage value).
	A.damage = 150
	knight_ref.say("Intercept this one — it will be a heavy blow!")
	// Release the charging lock just after detonation completes. The
	// extra 0.5s buffer covers the Blowup() processing window.
	addtimer(CALLBACK(src, PROC_REF(ClearAoECharging)), 5 SECONDS + 0.5 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_overseer/proc/ClearAoECharging()
	aoe_charging = FALSE

/// Dispatcher. Picks the right attack(s) for the current bracket;
/// B3 rolls between three sub-attacks per cast for variety.
/mob/living/simple_animal/hostile/serio_overseer/proc/FireAntiKnightForBracket(bracket)
	switch(bracket)
		if(1)
			FireAntiKnightLance()
		if(2)
			FireAntiKnightSalvo()
		if(3)
			var/roll = rand(1, 100)
			if(roll <= 40)
				FireAntiKnightSeeker()
			else if(roll <= 75)
				FireKnightAwareAoE()
			else
				FireAntiKnightLanceChaser()
