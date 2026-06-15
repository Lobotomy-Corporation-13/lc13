/*
 * The Murmur — Phase 2 minion mob. Stationary, projectile-permeable,
 * draws a beam to the Knight that scales the Knight's charge tick down.
 * Spawned on the arena perimeter by the Overseer; killing them is the
 * second player priority alongside body-blocking anti-Knight projectiles.
 *
 * Retaliation: any damage taken applies BLACK fragile stacks to the
 *   attacker (mirrors the mad_fly_nest pattern). Hitting Murmurs makes
 *   you take more BLACK damage for a while — the encounter wants you
 *   to think about who kills them and when.
 *
 * Attack rotation: every 5 seconds the Murmur picks Cold Word OR
 *   Glance (50/50) and casts a smaller mimic of the Overseer's
 *   version, with the beam drawn from the Murmur itself.
 *
 * Build-order step 11 (skeleton + beam + charge multiplier) plus the
 * post-step retaliation + Cold-Word / Glance mimic rework.
 */

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
	maxHealth = 800
	health = 800
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
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
	/// Back-ref to the Overseer that spawned this Murmur.
	var/mob/living/simple_animal/hostile/serio_overseer/parent_overseer
	/// Knight this Murmur is tethered to.
	var/mob/living/simple_animal/hostile/serio_knight/knight_ref
	/// The persistent beam tether obj.
	var/datum/beam/charge_beam
	/// world.time of next Cold Word / Glance cast.
	var/next_attack_at = 0
	// ---- Retaliation ----
	/// BLACK fragile stacks applied to any mob that damages this Murmur.
	var/black_fragile_per_hit = 3
	// ---- Attack tuning ----
	var/murmur_attack_cooldown = 5 SECONDS
	var/attack_telegraph = 1 SECONDS
	var/attack_damage = 20
	var/attack_decay_stacks_min = 4
	var/attack_decay_stacks_max = 8

/mob/living/simple_animal/hostile/serio_murmur/Initialize(mapload, mob/living/parent, mob/living/knight)
	. = ..()
	toggle_ai(AI_OFF)
	parent_overseer = parent
	knight_ref = knight
	if(knight_ref && !QDELETED(knight_ref))
		knight_ref.active_murmur_beams++
		charge_beam = Beam(knight_ref, "1-full", time = INFINITY, beam_type = /obj/effect/ebeam/serio_murmur)
	// First attack window: 2-4s after spawn so it doesn't fire instantly.
	next_attack_at = world.time + rand(2 SECONDS, 4 SECONDS)

/mob/living/simple_animal/hostile/serio_murmur/Destroy()
	if(knight_ref && !QDELETED(knight_ref))
		knight_ref.active_murmur_beams = max(0, knight_ref.active_murmur_beams - 1)
	if(charge_beam && !QDELETED(charge_beam))
		qdel(charge_beam)
	charge_beam = null
	if(parent_overseer && !QDELETED(parent_overseer))
		parent_overseer.active_murmurs -= src
	parent_overseer = null
	knight_ref = null
	return ..()

/// Stationary for the duration of Phase 2.
/mob/living/simple_animal/hostile/serio_murmur/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_murmur/AttackingTarget(atom/attacked_target)
	return FALSE

/// On death: heal nearby players a small amount, kick +5% charge onto
/// the Knight (one voice quieted, one step closer to the swing), then
/// immediately qdel the Murmur (and its beam) so no invisible corpse
/// + dangling beam lingers on the map. Parent death() handles standard
/// simple_animal stat changes; we run the side-effects before so the
/// visible_message order reads "Murmur dies → players heal → Knight
/// charges → Murmur disappears".
/mob/living/simple_animal/hostile/serio_murmur/death(gibbed)
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.stat == DEAD)
			continue
		H.adjustBruteLoss(-10, forced = TRUE)
		H.adjustFireLoss(-10, forced = TRUE)
		H.adjustSanityLoss(-10, forced = TRUE)
	if(knight_ref && !QDELETED(knight_ref) && knight_ref.stat != DEAD)
		knight_ref.charge_progress = clamp(knight_ref.charge_progress + 5, 0, 100)
		knight_ref.UpdateChargeMaptext()
	. = ..()
	qdel(src)

/mob/living/simple_animal/hostile/serio_murmur/Life()
	. = ..()
	if(stat == DEAD)
		return
	if(world.time >= next_attack_at)
		FireMurmurAttack()
		next_attack_at = world.time + murmur_attack_cooldown

// ---------- Retaliation ----------

/// Mirrors the mad_fly_nest pattern in sector2_mobs.dm:222. Any damage
/// from a non-faction-mate applies BLACK fragile stacks to the attacker,
/// so killing Murmurs costs the player ongoing damage vulnerability.
/mob/living/simple_animal/hostile/serio_murmur/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	if(stat == DEAD || maxHealth <= 0)
		return
	if(. > 0 && isliving(source))
		var/mob/living/attacker = source
		if(!faction_check_mob(attacker))
			attacker.apply_lc_black_fragile(black_fragile_per_hit)

// ---------- Attack rotation ----------

/// 50/50 between a Cold Word mimic and a Glance mimic. Both use the
/// same telegraph + damage / decay constants tuned on the Murmur.
/mob/living/simple_animal/hostile/serio_murmur/proc/FireMurmurAttack()
	if(QDELETED(src) || stat == DEAD)
		return
	if(prob(50))
		MurmurCastColdWord()
	else
		MurmurCastGlance()

/// Single 3×3 BLACK AoE around the nearest player, telegraphed and
/// preceded by a beam from the Murmur. Mirror of CastGlance, scaled
/// down: just the AoE + decay tick, no lingering puddle.
/mob/living/simple_animal/hostile/serio_murmur/proc/MurmurCastGlance()
	var/mob/living/carbon/human/target = FindMurmurTargetPlayer(nearest = TRUE)
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	var/list/spots = list()
	for(var/turf/T in range(1, center))
		spots += T
		new /obj/effect/temp_visual/serio_glance_warning(T)
	Beam(center, "drain_life", time = attack_telegraph)
	addtimer(CALLBACK(src, PROC_REF(ResolveMurmurGlance), spots), attack_telegraph, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_murmur/proc/ResolveMurmurGlance(list/spots)
	if(!islist(spots))
		return
	for(var/turf/T as anything in spots)
		if(QDELETED(T))
			continue
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.deal_damage(attack_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			H.apply_lc_mental_decay(rand(attack_decay_stacks_min, attack_decay_stacks_max))
			// Mark the target — if a Overseer lance lands on them
			// later, the lance will shatter this mark for sanity damage.
			H.apply_status_effect(/datum/status_effect/mental_detonate)

/// Scatter of 3-5 cold-word puddles around a random player, each with
/// its own telegraph beam from the Murmur. Mirror of CastColdWord.
/mob/living/simple_animal/hostile/serio_murmur/proc/MurmurCastColdWord()
	var/mob/living/carbon/human/target = FindMurmurTargetPlayer(nearest = FALSE)
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	var/list/spots = list(center)
	var/list/candidates = list()
	for(var/turf/open/T in range(2, center))
		if(T == center)
			continue
		candidates += T
	var/extras = rand(3, 5)
	for(var/i in 1 to extras)
		if(!length(candidates))
			break
		spots += pick_n_take(candidates)
	for(var/turf/S as anything in spots)
		new /obj/effect/temp_visual/serio_cold_word_warning(S)
		Beam(S, "drain_life", time = attack_telegraph)
	addtimer(CALLBACK(src, PROC_REF(ResolveMurmurColdWord), spots), attack_telegraph, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_murmur/proc/ResolveMurmurColdWord(list/spots)
	if(!islist(spots))
		return
	for(var/turf/T as anything in spots)
		if(QDELETED(T))
			continue
		// Anyone caught at puddle-spawn gets a chunk of decay + the
		// mark; later Overseer lance can shatter that mark. The
		// puddle's tick keeps dripping smaller decay separately.
		for(var/mob/living/carbon/human/H in T)
			if(H.stat == DEAD)
				continue
			H.apply_lc_mental_decay(rand(attack_decay_stacks_min, attack_decay_stacks_max))
			H.apply_status_effect(/datum/status_effect/mental_detonate)
		// Reuse the Overseer's puddle type — tuned tick: 6 BLACK / 1s for 2s.
		new /obj/effect/serio_cold_word_puddle(T, 2 SECONDS, 6, 1, 1 SECONDS)

/// Player lookup helper. `nearest = TRUE` picks the closest live human
/// in view; `nearest = FALSE` picks any live human at random.
/mob/living/simple_animal/hostile/serio_murmur/proc/FindMurmurTargetPlayer(nearest = TRUE)
	var/mob/living/carbon/human/best
	var/best_dist = INFINITY
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(8, src))
		if(H.stat == DEAD)
			continue
		if(nearest)
			var/d = get_dist(src, H)
			if(d < best_dist)
				best_dist = d
				best = H
		else
			candidates += H
	if(nearest)
		return best
	return length(candidates) ? pick(candidates) : null
