/*
 * Curtain Call — zeal_s1n1: Thumb East Capo + Capo Rat duo.
 * Capo kit themed on /obj/item/ego_weapon/city/thumb_east/podao/tiantui.
 * Rat kit's Hogtie is a half-duration, no-gibs riff on dusk red's
 * TrashDisposal — internals keep the `td_*` prefix as a pointer.
 */

// ---------- Telegraph and warning effects ----------

/obj/effect/temp_visual/capo_lunge_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff3030"
	duration = 15

/obj/effect/temp_visual/capo_sweep_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff8030"
	duration = 11

/obj/effect/temp_visual/capo_leap_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#9e1638"
	light_range = 2
	duration = 21

/obj/effect/temp_visual/capo_flurry_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#9e1638"
	duration = 6

/obj/effect/temp_visual/capo_rat_loading_marker
	name = "loading up"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ffd060"
	duration = 40

// Subtypes dusk red's telegraph just to match the Hogtie windup length.
/obj/effect/temp_visual/trash_disposal_telegraph/capo_rat
	duration = 4.05 SECONDS

// Tracking reticule for the Flurry finisher: 2s following + 1.5s locked.
/obj/effect/temp_visual/trash_disposal_telegraph/capo_flurry
	color = "#ff3030"
	duration = 4 SECONDS

// ---------- Thumb East Capo (Node zeal_s1n1: boss) ----------
/mob/living/simple_animal/hostile/thumb_east_capo
	name = "Thumb East Capo"
	desc = "A capo of the Thumb East family, dressed for an audience. \
		They are not here for the line — only for the show."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "capo_boss"
	icon_living = "capo_boss"
	// Keep the standing sprite on death so the fade-out isn't a blank tile.
	icon_dead = "capo_boss"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("thumb_east")
	maxHealth = 2000
	health = 2000
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	speak_chance = 0
	turns_per_move = 5
	move_to_delay = 6
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	// FALSE + opt out of the wave's auto-delete so the death() fade can play.
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()

	// Tiantui magazine — rounds spent at cast (miss or hit), refilled by rat.
	var/current_ammo = 8
	var/max_ammo     = 8

	var/lunge_ammo_cost      = 1
	var/lunge_cooldown       = 0
	var/lunge_cooldown_time  = 6 SECONDS
	/// Tiles the lunge line extends BEYOND the target's snapshot tile.
	var/lunge_past_target    = 4

	var/sweep_ammo_cost      = 1
	var/sweep_cooldown       = 0
	var/sweep_cooldown_time  = 8 SECONDS

	var/leap_ammo_cost       = 2
	var/leap_cooldown        = 0
	var/leap_cooldown_time   = 15 SECONDS
	var/leap_radius          = 2

	var/flurry_ammo_cost     = 6
	var/flurry_cooldown      = 0
	var/flurry_cooldown_time = 25 SECONDS
	var/flurry_dash_hits     = 5

	// Base ability damage; Tiantui Star adds a capped % enrage on top (see
	// AbilityDamage).
	var/lunge_damage           = 20
	var/sweep_damage           = 18
	var/leap_damage            = 35
	var/flurry_dash_damage     = 15
	var/flurry_finisher_damage = 25

	// Status stacks — only Sweep / Leap / Flurry finisher use the burst
	// threshold; everything else passes the no_burst sentinel.
	var/basic_tremor_stacks    = 1
	var/basic_overheat_stacks  = 1
	var/lunge_tremor_per_tile  = 1
	var/lunge_overheat_stacks  = 2
	var/sweep_tremor_stacks    = 1
	var/sweep_overheat_stacks  = 2
	var/leap_tremor_stacks     = 2
	var/leap_overheat_stacks   = 2
	var/flurry_dash_tremor_per_tile = 1
	var/flurry_dash_overheat   = 2
	var/flurry_finisher_tremor = 2
	var/flurry_finisher_overheat = 3
	var/tremor_burst_threshold = 25
	var/tremor_no_burst_threshold = 999

	// ---- Tiantui Star ----
	// star_stage: 0 none, 1 Tiantui Star (<=60% HP), 2 Shin (<=40% HP).
	// Ability damage is multiplied by 1 + missing_HP_fraction * max_buff,
	// so the bonus scales with missing HP and tops out at the stage cap
	// (+25% Stage 1, +50% Stage 2) as HP approaches zero.
	var/star_stage             = 0
	var/star_stage1_threshold  = 0.60
	var/star_stage2_threshold  = 0.40
	var/star_stage1_max_buff   = 0.25
	var/star_stage2_max_buff   = 0.50
	/// Underlay (rendered behind the Capo) for the active star stage.
	var/mutable_appearance/star_underlay

	var/list/flurry_taunts = list(
		"Hush up an' watch — this is how tigers go down!",
		"Fixin' to empty the whole magazine on y'all. Keep up!",
		"Quit yer dodgin' and bleed pretty for the crowd, would ya?",
		"Hwell, that's enough warmup. Y'all earned the finishin' move.",
	)

	var/list/reload_taunts = list(
		"Hwell, that's the good stuff. Y'all just keep standin', then.",
		"Mighty kind of the lil' fella. Now where were we, hm?",
		"Phew, that was gettin' embarrassin'. Cover yer ears, partners.",
		"Aw, didn'tcha think I'd let y'all walk outta here, didja?",
		"Y'all just bought yerselves another round. Hope y'all enjoy it!",
	)

	var/list/empty_lines = list(
		"Hwell, shoot — I'm bone dry! Fetch me a mag, lil' fella!",
		"Empty! Quit lazin' about an' load me up!",
		"...click. Rat! Reload, 'fore these folks get ideas!",
	)

	var/list/death_lines = list(
		"Hwell... reckon the tiger got et this time...",
		"...good show, partners. Y'all earned... the bow...",
		"Don't... don't fret over me now, lil' fella...",
		"Curtain's... comin' down on me first, huh...",
	)
	/// Length of the death fade-out.
	var/death_fade_time = 2 SECONDS
	var/dying = FALSE

	/// Cleared in death() so the rat is qdel'd with the boss.
	var/mob/living/simple_animal/hostile/rat/capo_rat/pet_rat

/mob/living/simple_animal/hostile/thumb_east_capo/refracted

// Block self-movement during any special; forceMove still works.
/mob/living/simple_animal/hostile/thumb_east_capo/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

// At range, fire a special; in melee, fire Sweep or fall through to the
// inherited Flurry/basic path. Sweep is melee-only so the 3x3 marker
// never lands away from the Capo.
/mob/living/simple_animal/hostile/thumb_east_capo/handle_automated_action()
	if(!can_act)
		return
	if(!pet_rat)
		pet_rat = locate(/mob/living/simple_animal/hostile/rat/capo_rat) in range(15, src)
	if(target && !QDELETED(target) && stat != DEAD && current_ammo > 0)
		var/d = get_dist(src, target)
		if(d >= 2)
			if(current_ammo >= leap_ammo_cost && world.time >= leap_cooldown && d >= 3 && d <= 7)
				walk(src, 0)
				INVOKE_ASYNC(src, PROC_REF(LeapFinisher), target)
				return
			if(current_ammo >= lunge_ammo_cost && world.time >= lunge_cooldown && d >= 2 && d <= 6)
				walk(src, 0)
				INVOKE_ASYNC(src, PROC_REF(Lunge), target)
				return
		else if(d == 1)
			if(current_ammo >= sweep_ammo_cost && world.time >= sweep_cooldown \
				&& (current_ammo < flurry_ammo_cost || world.time < flurry_cooldown))
				walk(src, 0)
				INVOKE_ASYNC(src, PROC_REF(Sweep), target)
				return
	return ..()

/mob/living/simple_animal/hostile/thumb_east_capo/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	if(current_ammo >= flurry_ammo_cost && world.time >= flurry_cooldown)
		INVOKE_ASYNC(src, PROC_REF(Flurry), attacked_target)
		return
	. = ..()
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(!faction_check_mob(L))
			ApplyHitStatuses(L, basic_tremor_stacks,
				/* can_burst = */ FALSE, basic_overheat_stacks)

/// Always-Tremor, Overheat-when-armed. `can_burst` is reserved for Sweep,
/// Leap Finisher, and the Flurry finisher. Tiantui Star adds flat bonuses
/// to the inflicted stacks (Stage 1: +1 Overheat; Stage 2: +2 Tremor and
/// +2 Overheat). Overheat — bonus included — still requires ammo.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/ApplyHitStatuses(mob/living/L, tremor_stacks, can_burst, overheat_stacks)
	if(QDELETED(L) || L == src || faction_check_mob(L))
		return
	if(star_stage >= 2)
		tremor_stacks += 2
		overheat_stacks += 2
	else if(star_stage >= 1)
		overheat_stacks += 1
	if(tremor_stacks > 0)
		L.apply_lc_tremor(tremor_stacks,
			can_burst ? tremor_burst_threshold : tremor_no_burst_threshold)
	if(overheat_stacks > 0 && current_ammo > 0)
		L.apply_lc_overheat(overheat_stacks)

/// Ability damage with the Tiantui Star missing-HP bonus folded in. Used
/// only by specials — basic melee never calls it, so the buff is
/// ability-only as intended.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/AbilityDamage(base)
	if(star_stage <= 0 || !maxHealth)
		return base
	var/missing_fraction = clamp(1 - health / maxHealth, 0, 1)
	var/max_buff = (star_stage >= 2) ? star_stage2_max_buff : star_stage1_max_buff
	return round(base * (1 + missing_fraction * max_buff))

// ---- Tiantui Star stage tracking ----
/mob/living/simple_animal/hostile/thumb_east_capo/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	UpdateStarStage()

/mob/living/simple_animal/hostile/thumb_east_capo/proc/UpdateStarStage()
	if(stat == DEAD || dying || !maxHealth || health <= 0)
		return
	var/ratio = health / maxHealth
	var/new_stage = 0
	if(ratio <= star_stage2_threshold)
		new_stage = 2
	else if(ratio <= star_stage1_threshold)
		new_stage = 1
	if(new_stage == star_stage)
		return
	// Only announce/flash when escalating, not if healed back up.
	var/escalating = new_stage > star_stage
	star_stage = new_stage
	UpdateStarOverlay()
	if(escalating)
		if(star_stage >= 2)
			say("Can't leave a dance unfinished. Ain't that right?")
		else if(star_stage >= 1)
			say("That's more like it. Y'all are firin' me up!")
		playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_clash.ogg', 70, FALSE, 6)

/// Swaps the behind-the-Capo underlay to match the current star stage.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/UpdateStarOverlay()
	if(star_underlay)
		underlays -= star_underlay
		star_underlay = null
	var/state = null
	if(star_stage >= 2)
		state = "foolish"
	else if(star_stage >= 1)
		state = "recklessSecond"
	if(state)
		star_underlay = mutable_appearance('icons/mob/clothing/ego_gear/ego_gifts.dmi', state)
		underlays += star_underlay

/mob/living/simple_animal/hostile/thumb_east_capo/proc/SpendAmmo(cost)
	if(current_ammo < cost)
		return FALSE
	current_ammo = max(0, current_ammo - cost)
	if(current_ammo <= 0)
		OnEmptyMagazine()
	return TRUE

/// Fires once when the magazine empties: announce it, and if the pet is
/// playing dead, rouse it early at half HP so it can run a reload.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/OnEmptyMagazine()
	say(pick(empty_lines))
	playsound(get_turf(src), 'sound/weapons/gun/general/dry_fire.ogg', 60, FALSE, 4)
	if(!pet_rat)
		pet_rat = locate(/mob/living/simple_animal/hostile/rat/capo_rat) in range(15, src)
	if(!QDELETED(pet_rat) && pet_rat.downed)
		pet_rat.ReviveForReload()

/mob/living/simple_animal/hostile/thumb_east_capo/proc/Refill()
	current_ammo = max_ammo
	visible_message(span_warning("[src] slams a fresh magazine into [p_their()] podao."))
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_reload_end.ogg', 60, FALSE, 4)
	say(pick(reload_taunts))

// 3x3 strip across the whole line (shock-centipede TailAttack); breaks
// at the first wall or water tile — the Capo can't dash through either.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Lunge(atom/L_target)
	if(!can_act || stat == DEAD || !L_target || QDELETED(L_target))
		return
	if(!SpendAmmo(lunge_ammo_cost))
		return
	can_act = FALSE
	walk(src, 0)
	lunge_cooldown = world.time + lunge_cooldown_time
	face_atom(L_target)
	var/turf/start = get_turf(src)
	var/turf/target_turf = get_turf(L_target)
	if(!start || !target_turf)
		can_act = TRUE
		return
	var/turf/end_turf = get_ranged_target_turf_direct(start, target_turf,
		get_dist(start, target_turf) + lunge_past_target)
	var/list/raw_line = getline(start, end_turf)
	var/list/line_strip = list()
	var/turf/landing = start
	for(var/turf/T in raw_line)
		if(T.density || istype(T, /turf/open/water))
			break
		landing = T
		line_strip += T
	new /obj/effect/temp_visual/thumb_east_aoe_impact(start)
	var/list/warned = list()
	for(var/turf/T in line_strip)
		for(var/turf/TF in range(1, T))
			if(TF in warned)
				continue
			warned += TF
			new /obj/effect/temp_visual/capo_lunge_warning(TF)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_detonation.ogg', 80, FALSE, 6)
	SLEEP_CHECK_DEATH(13)
	var/list/been_hit = list()
	for(var/turf/T in line_strip)
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			new /obj/effect/temp_visual/thumb_east_aoe_impact(TF)
			been_hit = HurtInTurf(TF, been_hit, AbilityDamage(lunge_damage), RED_DAMAGE,
				check_faction = TRUE, hurt_mechs = TRUE,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			for(var/mob/living/L in TF)
				ApplyHitStatuses(L, lunge_tremor_per_tile,
					/* can_burst = */ FALSE, lunge_overheat_stacks)
	if(landing && landing != start)
		forceMove(landing)
		var/datum/beam/trail = start.Beam(src, "1-full", time = 2)
		if(trail)
			trail.visuals.color = "#9e1638"
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_boostedlunge.ogg', 80, FALSE, 6)
	can_act = TRUE

// Melee-only 3x3 around the target's snapshot tile; Tremor-burst gated.
// Bails if the target stepped out of melee in the INVOKE_ASYNC gap.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Sweep(atom/S_target)
	if(!can_act || stat == DEAD || !S_target || QDELETED(S_target))
		return
	if(get_dist(src, S_target) > 1)
		return
	if(!SpendAmmo(sweep_ammo_cost))
		return
	can_act = FALSE
	walk(src, 0)
	sweep_cooldown = world.time + sweep_cooldown_time
	face_atom(S_target)
	var/turf/center = get_turf(S_target)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/capo_sweep_warning(T)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_detonation.ogg', 80, FALSE, 5)
	SLEEP_CHECK_DEATH(9)
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/thumb_east_aoe_impact(T)
		been_hit = HurtInTurf(T, been_hit, AbilityDamage(sweep_damage), RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			ApplyHitStatuses(L, sweep_tremor_stacks,
				/* can_burst = */ TRUE, sweep_overheat_stacks)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_boostedsweep.ogg', 80, FALSE, 5)
	can_act = TRUE

// Telegraphed 5x5 slam; Capo lifts off (pixel_z animation) and lands on
// the snapshot. Tremor-burst gated. Mirrors stone_keeper's entrance_fall.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/LeapFinisher(atom/L_target)
	if(!can_act || stat == DEAD || !L_target || QDELETED(L_target))
		return
	if(!SpendAmmo(leap_ammo_cost))
		return
	can_act = FALSE
	walk(src, 0)
	leap_cooldown = world.time + leap_cooldown_time
	face_atom(L_target)
	var/turf/center = get_turf(L_target)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in view(leap_radius, center))
		new /obj/effect/temp_visual/capo_leap_warning(T)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_leap_prep.ogg', 90, FALSE, 8)
	var/old_density = density
	density = FALSE
	pixel_z = 0
	animate(src, pixel_z = 128, alpha = 50, time = 5)
	SLEEP_CHECK_DEATH(19)
	if(!QDELETED(center))
		forceMove(center)
	animate(src, pixel_z = 0, alpha = 255, time = 2)
	density = old_density
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_leap_impact.ogg', 90, FALSE, 10)
	var/list/been_hit = list()
	for(var/turf/T in view(leap_radius, center))
		new /obj/effect/temp_visual/thumb_east_aoe_impact(T)
		been_hit = HurtInTurf(T, been_hit, AbilityDamage(leap_damage), RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.Knockdown(3 SECONDS)
			ApplyHitStatuses(L, leap_tremor_stacks,
				/* can_burst = */ TRUE, leap_overheat_stacks)
	can_act = TRUE

// Five 1-wide line dashes (each re-snapshotting the target tile) into a
// 3x3 finisher with Knockdown. Burst-eligible on the finisher only.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Flurry(atom/F_target)
	if(!can_act || stat == DEAD || !F_target || QDELETED(F_target))
		return
	if(!SpendAmmo(flurry_ammo_cost))
		return
	can_act = FALSE
	walk(src, 0)
	flurry_cooldown = world.time + flurry_cooldown_time
	say(pick(flurry_taunts))
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_clash.ogg', 90, FALSE, 10)
	new /obj/effect/temp_visual/weapon_stun(get_turf(src))
	SLEEP_CHECK_DEATH(5)
	for(var/i in 1 to flurry_dash_hits)
		if(QDELETED(F_target) || stat == DEAD)
			break
		FlurryLineDash(F_target)
		SLEEP_CHECK_DEATH(4)
	if(stat == DEAD || QDELETED(F_target))
		can_act = TRUE
		return
	// Finisher telegraph follows the player (2s), locks in place (1.5s),
	// then the Capo leaps to the locked tile — dodgeable by leaving it.
	face_atom(F_target)
	var/obj/effect/temp_visual/trash_disposal_telegraph/capo_flurry/track = new(get_turf(src))
	walk_towards(track, F_target, 0.1 SECONDS)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_leap_prep.ogg', 90, FALSE, 8)
	SLEEP_CHECK_DEATH(20)
	walk(track, 0)
	var/turf/locked = get_turf(track) || get_turf(F_target)
	if(locked)
		for(var/turf/W in range(2, locked))
			new /obj/effect/temp_visual/capo_leap_warning(W)
	SLEEP_CHECK_DEATH(15)
	qdel(track)
	if(locked)
		// Leap animation mirroring the tiantui FlurryCombo finisher: rise
		// and fade out toward the locked tile, then slam back in fast from
		// the takeoff direction.
		var/x_to_offset = 0
		if(locked.x > x)
			x_to_offset = 32
		else if(locked.x < x)
			x_to_offset = -32
		face_atom(locked)
		playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_detonation.ogg', 80, FALSE, 10)
		animate(src, 0.4 SECONDS, easing = QUAD_EASING, pixel_y = base_pixel_y + 16, pixel_x = base_pixel_x + x_to_offset, alpha = 0)
		SLEEP_CHECK_DEATH(4)
		var/turf/landing = get_step_towards(locked, src) || locked
		if(!landing || landing.density)
			landing = locked
		forceMove(landing)
		pixel_x = (base_pixel_x + x_to_offset) * 2.5 * -1
		pixel_y = base_pixel_y + 16
		animate(src, 0.2 SECONDS, easing = QUAD_EASING, pixel_y = base_pixel_y, pixel_x = base_pixel_x, alpha = 255)
		SLEEP_CHECK_DEATH(2)
		do_attack_animation(locked)
		playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_leap_impact.ogg', 80, TRUE, 10)
		var/list/been_hit = list()
		for(var/turf/U in range(2, locked))
			new /obj/effect/temp_visual/thumb_east_aoe_impact(U)
			been_hit = HurtInTurf(U, been_hit, AbilityDamage(flurry_finisher_damage), RED_DAMAGE,
				check_faction = TRUE, hurt_mechs = TRUE,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			for(var/mob/living/L in U)
				if(L == src || faction_check_mob(L))
					continue
				L.Knockdown(2 SECONDS)
				ApplyHitStatuses(L, flurry_finisher_tremor,
					/* can_burst = */ TRUE, flurry_finisher_overheat)
	can_act = TRUE

// One Flurry dash — 1-wide line, no end-tile AoE. Non-burst.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/FlurryLineDash(atom/F_target)
	if(stat == DEAD || !F_target || QDELETED(F_target))
		return
	face_atom(F_target)
	var/turf/start = get_turf(src)
	var/turf/target_turf = get_turf(F_target)
	if(!start || !target_turf)
		return
	var/turf/end_turf = get_ranged_target_turf_direct(start, target_turf,
		get_dist(start, target_turf) + lunge_past_target)
	var/list/raw_line = getline(start, end_turf)
	var/list/line_strip = list()
	var/turf/landing = start
	for(var/turf/T in raw_line)
		if(T.density || istype(T, /turf/open/water))
			break
		landing = T
		line_strip += T
	new /obj/effect/temp_visual/thumb_east_aoe_impact(start)
	for(var/turf/T in line_strip)
		new /obj/effect/temp_visual/capo_flurry_warning(T)
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_detonation.ogg', 80, FALSE, 5)
	SLEEP_CHECK_DEATH(5)
	var/list/been_hit = list()
	for(var/turf/T in line_strip)
		new /obj/effect/temp_visual/thumb_east_aoe_impact(T)
		been_hit = HurtInTurf(T, been_hit, AbilityDamage(flurry_dash_damage), RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			ApplyHitStatuses(L, flurry_dash_tremor_per_tile,
				/* can_burst = */ FALSE, flurry_dash_overheat)
	if(landing && landing != start)
		forceMove(landing)
		var/datum/beam/trail = start.Beam(src, "1-full", time = 2)
		if(trail)
			trail.visuals.color = "#9e1638"
	playsound(get_turf(src), 'sound/weapons/ego/thumb_east_podao_attack.ogg', 70, FALSE, 4)

// Death sequence: say a parting line, fade out, and call the rat to its
// side to fade with it. del_on_death is FALSE, so we qdel after the fade.
/mob/living/simple_animal/hostile/thumb_east_capo/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	// Say the parting line while still alive — dead mobs can't speak (the
	// joey NPC dodges this the same way). Then run the standard death.
	say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
	if(!pet_rat)
		pet_rat = locate(/mob/living/simple_animal/hostile/rat/capo_rat) in range(15, src)
	if(!QDELETED(pet_rat))
		pet_rat.BeginDeathFade(get_turf(src))
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Capo Rat (Node zeal_s1n1: pet) ----------
/mob/living/simple_animal/hostile/rat/capo_rat
	name = "Capo Rat"
	desc = "Larger than a back-alley rat, dyed red where the Capo's coat \
		brushes it. Stays close to its handler."
	color = "#ff3030"
	faction = list("thumb_east")
	maxHealth = 600
	health = 600
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_lower = 8
	melee_damage_upper = 12
	move_to_delay = 4
	// Never auto-deleted: it Plays Dead in combat and fades out by hand
	// when the Capo falls, so it manages its own removal.
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	butcher_results = null

	var/attack_dld_stacks = 3

	// Hogtie kit (dusk red TrashDisposal, half-duration, no gibs).
	var/td_cooldown                = 0
	var/td_cooldown_time           = 12 SECONDS
	var/td_telegraph_windup        = 4.05 SECONDS
	var/td_human_pin_duration      = 4 SECONDS
	var/td_max_hits                = 8
	var/td_time_between_hits       = 1 SECONDS
	var/td_damagetaken_cap         = 200
	var/td_damagetaken             = 0
	var/td_damage_per_hit          = 7
	var/td_dld_stacks_per_hit      = 4
	var/td_active                  = FALSE
	var/td_throwing                = FALSE
	/// TRUE only during the windup; Move() blocks on this.
	var/td_charging                = FALSE
	var/td_lunge_reset_timer

	// Reload-run state machine: "fighting" / "to_reload" / "loading" / "to_capo".
	var/reload_mode = "fighting"
	var/obj/effect/landmark/refraction/reload_point/reload_landmark
	var/mob/living/simple_animal/hostile/thumb_east_capo/capo_target
	var/load_pickup_time = 4 SECONDS

	// Downed loop (Elliot pattern).
	var/downed       = FALSE
	var/revive_time  = 10 SECONDS
	var/saved_color  = "#ff3030"

	/// Set when the Capo dies — the rat runs to its side and fades out.
	var/dying = FALSE
	var/death_fade_time = 2 SECONDS

// ---- AI dispatcher ----
/mob/living/simple_animal/hostile/rat/capo_rat/handle_automated_action()
	if(downed || dying)
		return
	if(!can_act || td_active || td_throwing)
		return  // animating Trash Disposal or pinned mid-sequence
	if(reload_mode != "fighting")
		StepReloadRun()
		return  // do NOT run the inherited hostile loop while couriering
	// Lazily cache the Capo on first fighting tick.
	if(!capo_target)
		capo_target = locate(/mob/living/simple_animal/hostile/thumb_east_capo) in range(20, src)
	// Capo dry? Start the reload run.
	if(reload_landmark && capo_target && !QDELETED(capo_target) \
		&& capo_target.stat != DEAD && capo_target.current_ammo <= 0)
		StartReloadRun()
		return
	// Trash Disposal — open-fire at range, melee fallback otherwise.
	// Cancel any persistent walk_to BEFORE INVOKE_ASYNC so BYOND can't
	// take one more chase step in the gap before TrashDisposalTelegraph
	// flips `td_throwing` and freezes us.
	if(target && !QDELETED(target) && world.time >= td_cooldown)
		var/d = get_dist(src, target)
		if(d >= 2 && d <= 7 && isliving(target))
			walk(src, 0)
			td_throwing = TRUE
			td_charging = TRUE
			INVOKE_ASYNC(src, PROC_REF(TrashDisposalTelegraph), target)
			return
	return ..()

// Blocks self-movement during the Hogtie windup; throw_at bypasses this.
/mob/living/simple_animal/hostile/rat/capo_rat/Move(atom/newloc, dir, step_x, step_y)
	if(td_charging || downed)
		return FALSE
	return ..()

// Once the master is fading, refuse any new target — covers the base AI,
// attacked_by, and TrashDisposalCleanup's re-target.
/mob/living/simple_animal/hostile/rat/capo_rat/GiveTarget(atom/new_target)
	if(dying)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rat/capo_rat/AttackingTarget(atom/attacked_target)
	if(downed || !can_act || reload_mode != "fighting" || td_active)
		return
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(!faction_check_mob(L))
			L.apply_lc_defense_level_down(attack_dld_stacks)
	return ..()

/mob/living/simple_animal/hostile/rat/capo_rat/Initialize(mapload)
	. = ..()
	for(var/obj/effect/landmark/refraction/reload_point/L in GLOB.landmarks_list)
		if(L.z == z)
			reload_landmark = L
			break
	RegisterSignal(src, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(OnTrashDisposalDamage))

/mob/living/simple_animal/hostile/rat/capo_rat/proc/OnTrashDisposalDamage(datum/source, damage_amount)
	SIGNAL_HANDLER
	if(td_active)
		td_damagetaken += damage_amount

// ---- Hogtie (telegraph → throw → pin → rip) ----

/mob/living/simple_animal/hostile/rat/capo_rat/proc/TrashDisposalTelegraph(mob/living/victim)
	if(downed || stat == DEAD || td_active || QDELETED(victim))
		return
	face_atom(victim)
	can_act = FALSE
	td_throwing = TRUE
	td_charging = TRUE
	move_resist = INFINITY
	LoseTarget()
	walk(src, 0)
	var/obj/effect/temp_visual/trash_disposal_telegraph/warning = new /obj/effect/temp_visual/trash_disposal_telegraph/capo_rat(get_turf(src))
	visible_message(span_userdanger("[src] coils to leap at [victim]!"))
	playsound(get_turf(src), 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)
	walk_towards(warning, victim, 0.1 SECONDS)
	SLEEP_CHECK_DEATH(td_telegraph_windup)
	td_charging = FALSE
	move_resist = initial(move_resist)
	can_act = TRUE
	if(QDELETED(victim) || stat == DEAD)
		td_throwing = FALSE
		return
	throw_at(victim, 7, 5, src, FALSE)
	visible_message(span_danger("[src] leaps at [victim]!"))
	td_lunge_reset_timer = addtimer(CALLBACK(src, PROC_REF(TrashDisposalAbort)), 2 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/rat/capo_rat/proc/TrashDisposalAbort()
	td_throwing = FALSE
	td_charging = FALSE
	td_active = FALSE
	move_resist = initial(move_resist)
	can_act = TRUE

/mob/living/simple_animal/hostile/rat/capo_rat/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(td_throwing && isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(!faction_check_mob(L))
			td_throwing = FALSE
			INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), L)
			return
	else if(td_throwing && throwingdatum)
		// Catches a target that went prone — sweep the landing tile.
		var/turf/landing = get_turf(src)
		for(var/mob/living/L in landing)
			if(L == throwingdatum.target && !faction_check_mob(L))
				td_throwing = FALSE
				INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), L)
				return
	if(td_throwing)
		td_throwing = FALSE
		can_act = TRUE
	. = ..()

/mob/living/simple_animal/hostile/rat/capo_rat/proc/TrashDisposalInitiate(mob/living/victim)
	if(downed || stat == DEAD || QDELETED(victim))
		return
	td_damagetaken = 0
	td_active = TRUE
	td_cooldown = world.time + td_cooldown_time
	td_time_between_hits = initial(td_time_between_hits)
	td_damage_per_hit = initial(td_damage_per_hit)
	deltimer(td_lunge_reset_timer)
	if(ishuman(victim))
		var/mob/living/carbon/human/H = victim
		H.Paralyze(td_human_pin_duration)
	else if(istype(victim, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/animal_trash = victim
		animal_trash.toggle_ai(AI_OFF)
		walk_to(animal_trash, 0)
		animal_trash.LoseTarget()
	victim.visible_message(
		span_danger("[victim] is pinned down by [src]!"),
		span_userdanger("You're pinned down by [src]!"))
	var/turf/pin_turf = get_turf(victim)
	new /obj/effect/temp_visual/weapon_stun(pin_turf)
	forceMove(pin_turf)
	INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, 1)

/mob/living/simple_animal/hostile/rat/capo_rat/proc/TrashDisposalHit(mob/living/victim, hit_count)
	if(!td_active || downed || stat == DEAD)
		TrashDisposalCleanup(victim)
		return
	if(td_damagetaken >= td_damagetaken_cap)
		TrashDisposalCleanup(victim)
		return
	if(QDELETED(victim) || victim.stat == DEAD)
		TrashDisposalCleanup(null)
		return
	if(!do_after(src, td_time_between_hits, target = victim))
		TrashDisposalCleanup(victim)
		return
	do_attack_animation(victim)
	playsound(src, attack_sound, 100, TRUE)
	victim.deal_damage(td_damage_per_hit, melee_damage_type, src,
		flags = (DAMAGE_FORCED),
		attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	if(!faction_check_mob(victim))
		victim.apply_lc_defense_level_down(td_dld_stacks_per_hit)
	visible_message(span_danger("[src] tears into [victim]!"))
	td_time_between_hits = max(2, td_time_between_hits - 1)
	td_damage_per_hit += 1
	if(victim.health <= 0 || hit_count >= td_max_hits)
		TrashDisposalCleanup(victim)
		return
	INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, hit_count + 1)

/mob/living/simple_animal/hostile/rat/capo_rat/proc/TrashDisposalCleanup(mob/living/victim)
	td_active = FALSE
	td_throwing = FALSE
	td_time_between_hits = initial(td_time_between_hits)
	td_damage_per_hit = initial(td_damage_per_hit)
	td_damagetaken = 0
	move_resist = initial(move_resist)
	// Always free the victim from the pin, but don't wake our own AI back
	// up or re-target if the master is already fading.
	if(victim && !QDELETED(victim))
		if(ishuman(victim))
			victim.remove_status_effect(/datum/status_effect/incapacitating/paralyzed)
		else if(istype(victim, /mob/living/simple_animal/hostile))
			var/mob/living/simple_animal/hostile/freed = victim
			freed.toggle_ai(AI_ON)
	if(dying)
		return
	can_act = TRUE
	if(victim && !QDELETED(victim) && isliving(victim) && victim.stat != DEAD)
		GiveTarget(victim)

// ---- Reload-run state machine ----
/mob/living/simple_animal/hostile/rat/capo_rat/proc/StartReloadRun()
	if(downed || stat == DEAD)
		return
	reload_mode = "to_reload"
	LoseTarget()
	visible_message(span_warning("[src] scurries off to fetch ammunition!"))
	StepReloadRun()

/mob/living/simple_animal/hostile/rat/capo_rat/proc/StepReloadRun()
	if(downed || stat == DEAD)
		return
	switch(reload_mode)
		if("to_reload")
			if(!reload_landmark || QDELETED(reload_landmark))
				reload_mode = "fighting"
				walk(src, 0)
				return
			walk_to(src, reload_landmark, 0, move_to_delay)
			if(get_dist(src, reload_landmark) <= 0)
				walk(src, 0)
				reload_mode = "loading"
				new /obj/effect/temp_visual/capo_rat_loading_marker(get_turf(src))
				playsound(get_turf(src), 'sound/items/handling/ammobox_pickup.ogg', 40, TRUE)
				addtimer(CALLBACK(src, PROC_REF(FinishLoading)), load_pickup_time)
		if("to_capo")
			if(!capo_target || QDELETED(capo_target) || capo_target.stat == DEAD)
				reload_mode = "fighting"
				color = saved_color
				walk(src, 0)
				return
			walk_to(src, capo_target, 1, move_to_delay)
			if(get_dist(src, capo_target) <= 1)
				walk(src, 0)
				capo_target.Refill()
				reload_mode = "fighting"
				color = saved_color

/mob/living/simple_animal/hostile/rat/capo_rat/proc/FinishLoading()
	if(QDELETED(src) || downed || stat == DEAD || reload_mode != "loading")
		return
	reload_mode = "to_capo"
	color = "#ffd060"
	visible_message(span_warning("[src] grabs a fresh magazine and bolts for [capo_target]!"))

// ---- Downed loop (Elliot pattern) ----

/mob/living/simple_animal/hostile/rat/capo_rat/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(downed || dying)
		return 0
	. = ..()
	if(stat != DEAD && !downed && health <= 1)
		EnterDowned()

/mob/living/simple_animal/hostile/rat/capo_rat/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(downed || dying)
		return BULLET_ACT_BLOCK
	return ..()

// Catches lethal damage that bypassed adjustHealth (fire DoT, direct
// writes) and reroutes to Downed; suppresses the base deadmouse spawn.
/mob/living/simple_animal/hostile/rat/capo_rat/death(gibbed)
	if(!downed && !dying && !QDELETED(src) && !gibbed)
		EnterDowned()
		return FALSE
	SSmobs.cheeserats -= src
	return ..(gibbed = TRUE)

/mob/living/simple_animal/hostile/rat/capo_rat/proc/EnterDowned()
	if(downed)
		return
	downed       = TRUE
	can_act      = FALSE
	density      = FALSE
	health       = 1
	status_flags |= GODMODE
	walk(src, 0)
	reload_mode  = "fighting"
	LoseTarget()
	icon_state   = icon_dead
	saved_color  = color
	visible_message(span_warning("[src] keels over!"))
	playsound(get_turf(src), 'sound/effects/mousesqueek.ogg', 40, TRUE)
	addtimer(CALLBACK(src, PROC_REF(StandBackUp)), revive_time)

/mob/living/simple_animal/hostile/rat/capo_rat/proc/StandBackUp()
	if(QDELETED(src) || !downed)
		return
	downed       = FALSE
	density      = TRUE
	health       = maxHealth
	status_flags &= ~GODMODE
	icon_state   = icon_living
	color        = saved_color
	can_act      = TRUE
	visible_message(span_warning("[src] gets back up!"))
	playsound(get_turf(src), 'sound/effects/mousesqueek.ogg', 50, TRUE)

// Early rouse triggered when the Capo runs dry mid-Plays-Dead: gets up at
// half HP (vs the full-HP StandBackUp) so it can run a reload. The pending
// StandBackUp timer no-ops since `downed` is already cleared.
/mob/living/simple_animal/hostile/rat/capo_rat/proc/ReviveForReload()
	if(!downed)
		return
	downed       = FALSE
	density      = TRUE
	health       = round(maxHealth * 0.5)
	status_flags &= ~GODMODE
	icon_state   = icon_living
	color        = saved_color
	can_act      = TRUE
	visible_message(span_warning("[src] springs back up at its master's call!"))
	playsound(get_turf(src), 'sound/effects/mousesqueek.ogg', 50, TRUE)

// Called from the Capo's death(): drop everything, scurry to the Capo's
// tile, and fade out alongside it.
/mob/living/simple_animal/hostile/rat/capo_rat/proc/BeginDeathFade(turf/capo_turf)
	if(dying)
		return
	dying = TRUE
	td_active = FALSE
	td_throwing = FALSE
	td_charging = FALSE
	downed = FALSE
	reload_mode = "fighting"
	status_flags &= ~GODMODE
	move_resist = initial(move_resist)
	density = FALSE
	icon_state = icon_living
	color = saved_color
	can_act = FALSE
	LoseTarget()
	walk(src, 0)
	// Leave the wave's living set (we won't fire a death) so the boss room
	// can still clear while we play out the fade.
	var/datum/refraction_wave_controller/C = GLOB.refraction_wave_mob_owners[src]
	if(C)
		C.DropMob(src)
	if(capo_turf)
		walk_towards(src, capo_turf, move_to_delay)
	visible_message(span_warning("[src] scrambles to its master's side..."))
	playsound(get_turf(src), 'sound/effects/mousesqueek.ogg', 40, TRUE)
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

/mob/living/simple_animal/hostile/rat/capo_rat/refracted
