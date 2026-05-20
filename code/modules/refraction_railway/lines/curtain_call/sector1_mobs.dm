/*
 * Curtain Call — Sector 1 encounters.
 *
 * Node zeal_s1n1 (Opening Act, scene 1): a duo fight — a Thumb East Capo
 * and their pet Capo Rat. The pair shares a faction so they ignore each
 * other and focus the players.
 *
 * Capo kit: themed on the tiantui star's-blade podao
 * (/obj/item/ego_weapon/city/thumb_east/podao/tiantui in
 * ModularLobotomy/ego_weapons/melee/city/thumb.dm). All specials are
 * ammo-gated and resolve on the player's snapshot tile at cast — so
 * they're dodgeable, and ammo is spent at cast time, so missed shots
 * still burn rounds.
 *
 * Rat kit: melee tags with Tremor; telegraphed straight-line Dash; runs
 * fresh magazines from a reload landmark back to the Capo when the
 * Capo's clip is dry; at 1 HP it falls down dead (godmode, dead sprite,
 * no AI) and stands back up at full HP 10 s later — modelled on the
 * elliot_npc Downed/Unstun pattern.
 */

// ---------- Telegraph and warning effects ----------

/obj/effect/temp_visual/capo_lunge_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff3030"
	duration = 6

/obj/effect/temp_visual/capo_sweep_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff8030"
	duration = 8

/obj/effect/temp_visual/capo_leap_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#9e1638"
	light_range = 2
	duration = 15

/obj/effect/temp_visual/capo_flurry_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#9e1638"
	duration = 4

/obj/effect/temp_visual/capo_rat_dash_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ff3030"
	duration = 5

/obj/effect/temp_visual/capo_rat_loading_marker
	name = "loading up"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ffd060"
	duration = 40

// ---------- Thumb East Capo (Node zeal_s1n1: boss) ----------
/mob/living/simple_animal/hostile/thumb_east_capo
	name = "Thumb East Capo"
	desc = "A capo of the Thumb East family, dressed for an audience. \
		They are not here for the line — only for the show."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "capo_boss"
	icon_living = "capo_boss"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("thumb_east")
	maxHealth = 900
	health = 900
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
	del_on_death = TRUE
	loot = list()

	// ---- Tiantui magazine ----
	/// Rounds spent at cast (miss or hit). Refilled by the rat.
	var/current_ammo = 8
	var/max_ammo     = 8

	// ---- Per-special ammo costs / cooldowns ----
	var/lunge_ammo_cost      = 1
	var/lunge_cooldown       = 0
	var/lunge_cooldown_time  = 6 SECONDS
	/// Cap on lunge travel distance. Also caps the lunge's hit range.
	var/lunge_range          = 5

	var/sweep_ammo_cost      = 1
	var/sweep_cooldown       = 0
	var/sweep_cooldown_time  = 8 SECONDS

	var/leap_ammo_cost       = 2
	var/leap_cooldown        = 0
	var/leap_cooldown_time   = 15 SECONDS
	/// Leap-warning AoE radius (5×5 = 2-tile radius).
	var/leap_radius          = 2

	var/flurry_ammo_cost     = 6
	var/flurry_cooldown      = 0
	var/flurry_cooldown_time = 25 SECONDS
	/// Number of strikes in the Flurry sequence.
	var/flurry_hits          = 6

	/// `can_act` is inherited from /mob/living/simple_animal/hostile — we
	/// just toggle it during specials to block the chase loop and gate
	/// AttackingTarget so animations don't overlap.

	/// Aurafarming lines spoken when the Flurry resolves.
	var/list/flurry_taunts = list(
		"Hush up an' watch — this is how tigers go down!",
		"Fixin' to empty the whole magazine on y'all. Keep up!",
		"Quit yer dodgin' and bleed pretty for the crowd, would ya?",
		"Hwell, that's enough warmup. Y'all earned the finishin' move.",
	)

	/// Lines spoken when the rat brings a fresh magazine.
	var/list/reload_taunts = list(
		"Hwell, that's the good stuff. Y'all just keep standin', then.",
		"Mighty kind of the lil' fella. Now where were we, hm?",
		"Phew, that was gettin' embarrassin'. Cover yer ears, partners.",
		"Aw, didn'tcha think I'd let y'all walk outta here, didja?",
		"Y'all just bought yerselves another round. Hope y'all enjoy it!",
	)

	/// Pet rat, cached at first opportunity. Cleared in death() so the rat
	/// is qdel'd with the boss instead of being left orphaned.
	var/mob/living/simple_animal/hostile/rat/capo_rat/pet_rat

/mob/living/simple_animal/hostile/thumb_east_capo/refracted
	// Refraction Railway tuning of the Capo. Currently identical to base;
	// stats / gimmick will diverge here as the encounter is authored.

// ---- AI dispatcher: at range, fire a special; in melee, fire Flurry
// or fall through to basic; if out of ammo, just basic-melee. ----
/mob/living/simple_animal/hostile/thumb_east_capo/handle_automated_action()
	if(!can_act)
		// Animating a special — skip both our dispatch and the inherited
		// chase loop so the Capo doesn't try to move mid-animation.
		return
	if(!pet_rat)
		pet_rat = locate(/mob/living/simple_animal/hostile/rat/capo_rat) in range(15, src)
	if(target && !QDELETED(target) && stat != DEAD && current_ammo > 0)
		var/d = get_dist(src, target)
		// Only fire range-specials at distance — melee range is reserved
		// for AttackingTarget so the Flurry can land.
		if(d >= 2)
			if(current_ammo >= leap_ammo_cost && world.time >= leap_cooldown && d >= 3 && d <= 7)
				INVOKE_ASYNC(src, PROC_REF(LeapFinisher), target)
				return
			if(current_ammo >= lunge_ammo_cost && world.time >= lunge_cooldown && d >= 3 && d <= lunge_range)
				INVOKE_ASYNC(src, PROC_REF(Lunge), target)
				return
			if(current_ammo >= sweep_ammo_cost && world.time >= sweep_cooldown && d >= 2 && d <= 4)
				INVOKE_ASYNC(src, PROC_REF(Sweep), target)
				return
	return ..()

// In melee with ammo for it → Flurry. Otherwise basic melee (15-20 RED).
/mob/living/simple_animal/hostile/thumb_east_capo/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	if(current_ammo >= flurry_ammo_cost && world.time >= flurry_cooldown)
		INVOKE_ASYNC(src, PROC_REF(Flurry), attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/thumb_east_capo/proc/SpendAmmo(cost)
	if(current_ammo < cost)
		return FALSE
	current_ammo = max(0, current_ammo - cost)
	return TRUE

/// Called by the rat after a successful reload run.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Refill()
	current_ammo = max_ammo
	visible_message(span_warning("[src] slams a fresh magazine into [p_their()] podao."))
	playsound(get_turf(src), 'sound/weapons/gun/shotgun/rack.ogg', 50, TRUE)
	say(pick(reload_taunts))

// ---- Lunge: telegraphed dash-line at the target's snapshot tile. ----
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Lunge(atom/L_target)
	if(!can_act || stat == DEAD || !L_target || QDELETED(L_target))
		return
	if(!SpendAmmo(lunge_ammo_cost))
		return
	can_act = FALSE
	lunge_cooldown = world.time + lunge_cooldown_time
	face_atom(L_target)
	var/turf/start = get_turf(src)
	var/turf/dest  = get_turf(L_target)
	if(!start || !dest)
		can_act = TRUE
		return
	var/list/path = getline(start, dest)
	// Truncate the path to lunge_range so the Capo doesn't teleport across
	// the arena chasing a distant target.
	if(length(path) > lunge_range + 1)
		path.Cut(lunge_range + 2)
	for(var/turf/T in path)
		new /obj/effect/temp_visual/capo_lunge_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 50, TRUE, 4)
	SLEEP_CHECK_DEATH(4)
	var/list/been_hit = list()
	for(var/turf/T in path)
		if(T == start)
			continue
		new /obj/effect/temp_visual/dir_setting/cult/phase(T)
		been_hit = HurtInTurf(T, been_hit, 20, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.apply_lc_tremor(4)
	// Move to the end of the path (or as far as possible — the loop above
	// already applied damage, so it doesn't matter if the final tile is
	// blocked).
	var/turf/landing = path[length(path)]
	if(landing && !landing.density)
		forceMove(landing)
	playsound(get_turf(src), 'sound/weapons/punch1.ogg', 50, TRUE)
	can_act = TRUE

// ---- Sweep: 3×3 telegraphed AoE on the target's snapshot tile. ----
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Sweep(atom/S_target)
	if(!can_act || stat == DEAD || !S_target || QDELETED(S_target))
		return
	if(!SpendAmmo(sweep_ammo_cost))
		return
	can_act = FALSE
	sweep_cooldown = world.time + sweep_cooldown_time
	face_atom(S_target)
	var/turf/center = get_turf(S_target)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/capo_sweep_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 50, TRUE, 3)
	SLEEP_CHECK_DEATH(7)
	var/list/been_hit = list()
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, 18, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.apply_lc_tremor(2)
	playsound(get_turf(src), 'sound/weapons/punch3.ogg', 60, TRUE, 4)
	can_act = TRUE

// ---- Leap finisher: 5×5 telegraphed slam; Capo briefly airborne. ----
/mob/living/simple_animal/hostile/thumb_east_capo/proc/LeapFinisher(atom/L_target)
	if(!can_act || stat == DEAD || !L_target || QDELETED(L_target))
		return
	if(!SpendAmmo(leap_ammo_cost))
		return
	can_act = FALSE
	leap_cooldown = world.time + leap_cooldown_time
	face_atom(L_target)
	var/turf/center = get_turf(L_target)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in view(leap_radius, center))
		new /obj/effect/temp_visual/capo_leap_warning(T)
	playsound(get_turf(src), 'sound/abnormalities/babayaga/charge.ogg', 80, FALSE, 6)
	// Launch the Capo upward — mirrors stone_keeper's entrance_fall.
	var/old_density = density
	density = FALSE
	pixel_z = 0
	animate(src, pixel_z = 128, alpha = 50, time = 5)
	SLEEP_CHECK_DEATH(15)
	if(!QDELETED(center))
		forceMove(center)
	animate(src, pixel_z = 0, alpha = 255, time = 2)
	density = old_density
	playsound(get_turf(src), 'sound/abnormalities/babayaga/land.ogg', 80, FALSE, 8)
	var/list/been_hit = list()
	for(var/turf/T in view(leap_radius, center))
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, 35, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.Knockdown(3 SECONDS)
			L.apply_lc_tremor(3)
	can_act = TRUE

// ---- Flurry (Savage Tigerslayer's Perfected Flurry of Blades) ----
// Six rapid hits, each snapshotting the target's current tile fresh so
// a moving player has a chance to break the pattern. First five hits
// are single-tile RED + Tremor; the sixth is a 3×3 burst with Knockdown.
/mob/living/simple_animal/hostile/thumb_east_capo/proc/Flurry(atom/F_target)
	if(!can_act || stat == DEAD || !F_target || QDELETED(F_target))
		return
	if(!SpendAmmo(flurry_ammo_cost))
		return
	can_act = FALSE
	flurry_cooldown = world.time + flurry_cooldown_time
	say(pick(flurry_taunts))
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 80, FALSE, 6)
	for(var/i in 1 to flurry_hits)
		if(QDELETED(F_target) || stat == DEAD)
			break
		// Refresh snapshot tile each strike.
		var/turf/T = get_turf(F_target)
		if(!T)
			break
		face_atom(F_target)
		new /obj/effect/temp_visual/capo_flurry_warning(T)
		SLEEP_CHECK_DEATH(3)
		// Step adjacent for the visual.
		var/turf/dash_to = get_step_towards(src, T)
		if(dash_to && !dash_to.density)
			forceMove(dash_to)
		if(i < flurry_hits)
			// First five — single-tile RED + Tremor.
			var/list/been_hit = list()
			been_hit = HurtInTurf(T, been_hit, 15, RED_DAMAGE,
				check_faction = TRUE, hurt_mechs = TRUE,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			for(var/mob/living/L in T)
				if(L == src || faction_check_mob(L))
					continue
				L.apply_lc_tremor(2)
			playsound(get_turf(src), 'sound/weapons/punch1.ogg', 50, TRUE)
		else
			// Sixth — 3×3 finisher with Knockdown.
			var/list/been_hit = list()
			for(var/turf/U in range(1, T))
				new /obj/effect/temp_visual/smash_effect(U)
				been_hit = HurtInTurf(U, been_hit, 25, RED_DAMAGE,
					check_faction = TRUE, hurt_mechs = TRUE,
					attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				for(var/mob/living/L in U)
					if(L == src || faction_check_mob(L))
						continue
					L.Knockdown(2 SECONDS)
					L.apply_lc_tremor(3)
			playsound(get_turf(src), 'sound/weapons/punch3.ogg', 80, FALSE, 6)
		SLEEP_CHECK_DEATH(5)
	can_act = TRUE

// On boss death, clean up the rat (which would otherwise loop its Downed
// state indefinitely with no Capo to refuel).
/mob/living/simple_animal/hostile/thumb_east_capo/death(gibbed)
	if(!QDELETED(pet_rat))
		qdel(pet_rat)
	pet_rat = null
	return ..()

// ---------- Capo Rat (Node zeal_s1n1: pet) ----------
// Subtype of the base back-alley rat: keeps the gray mouse sprite (rendered
// bright red via `color`), shares the Capo's faction so they don't fight
// each other, and bumps stats so it survives more than a single hit.
/mob/living/simple_animal/hostile/rat/capo_rat
	name = "Capo Rat"
	desc = "Larger than a back-alley rat, dyed red where the Capo's coat \
		brushes it. Stays close to its handler."
	color = "#ff3030"
	faction = list("thumb_east")
	maxHealth = 200
	health = 200
	melee_damage_lower = 8
	melee_damage_upper = 12
	move_to_delay = 4
	del_on_death = TRUE
	loot = list()
	butcher_results = null

	// ---- Tremor on melee, mirrors stone_guard/refracted's attack_tremor. ----
	var/attack_tremor = 2

	// ---- Telegraphed straight-line dash. ----
	var/dash_cooldown      = 0
	var/dash_cooldown_time = 12 SECONDS
	var/dash_range         = 5
	// `can_act` inherited from /mob/living/simple_animal/hostile.

	// ---- Reload-run state machine. ----
	// "fighting"   — normal hostile AI
	// "to_reload"  — running to the reload landmark
	// "loading"    — at the landmark, picking up the package
	// "to_capo"    — running the package back to the Capo
	var/reload_mode = "fighting"
	var/obj/effect/landmark/refraction/reload_point/reload_landmark
	var/mob/living/simple_animal/hostile/thumb_east_capo/capo_target
	var/load_pickup_time = 4 SECONDS

	// ---- Downed loop (Elliot pattern). ----
	var/downed       = FALSE
	var/revive_time  = 10 SECONDS
	/// Cached restore color so post-revive coloring matches spawn.
	var/saved_color  = "#ff3030"

/mob/living/simple_animal/hostile/rat/capo_rat/Initialize(mapload)
	. = ..()
	// Find a reload point on our z-level. If the mapper hasn't placed one,
	// the rat just never enters reload mode.
	for(var/obj/effect/landmark/refraction/reload_point/L in GLOB.landmarks_list)
		if(L.z == z)
			reload_landmark = L
			break
	// Capo lookup is lazy (capo may not be spawned yet on this tick).

// ---- AI dispatcher ----
/mob/living/simple_animal/hostile/rat/capo_rat/handle_automated_action()
	if(downed)
		return
	if(!can_act)
		return  // animating a Dash
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
	// Dash if target in range and off cooldown.
	if(target && !QDELETED(target) && world.time >= dash_cooldown)
		var/d = get_dist(src, target)
		if(d >= 3 && d <= dash_range)
			INVOKE_ASYNC(src, PROC_REF(Dash), target)
			return
	return ..()

// Melee tags with Tremor in addition to the inherited bite.
/mob/living/simple_animal/hostile/rat/capo_rat/AttackingTarget(atom/attacked_target)
	if(downed || !can_act || reload_mode != "fighting")
		return
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(!faction_check_mob(L))
			L.apply_lc_tremor(attack_tremor)
	return ..()

// ---- Telegraphed straight-line dash. ----
/mob/living/simple_animal/hostile/rat/capo_rat/proc/Dash(atom/D_target)
	if(downed || !can_act || stat == DEAD || !D_target || QDELETED(D_target))
		return
	can_act = FALSE
	dash_cooldown = world.time + dash_cooldown_time
	face_atom(D_target)
	var/turf/start = get_turf(src)
	var/turf/dest  = get_turf(D_target)
	if(!start || !dest)
		can_act = TRUE
		return
	var/list/path = getline(start, dest)
	if(length(path) > dash_range + 1)
		path.Cut(dash_range + 2)
	for(var/turf/T in path)
		new /obj/effect/temp_visual/capo_rat_dash_warning(T)
	playsound(get_turf(src), 'sound/weapons/punch1.ogg', 50, TRUE, 3)
	SLEEP_CHECK_DEATH(4)
	var/list/been_hit = list()
	for(var/turf/T in path)
		if(T == start)
			continue
		if(T.density)
			break
		forceMove(T)
		been_hit = HurtInTurf(T, been_hit, 12, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.Knockdown(1 SECONDS)
		SLEEP_CHECK_DEATH(1)
	can_act = TRUE

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
				// Drop the package; resume normal AI.
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
	// Visual flag — recolor briefly to "carrying a package".
	color = "#ffd060"
	visible_message(span_warning("[src] grabs a fresh magazine and bolts for [capo_target]!"))

// ---- Downed loop (Elliot pattern) ----
// adjustHealth — short-circuit while downed; otherwise let the parent
// apply damage, then catch the "dropped below 1 HP" edge and Down us.
/mob/living/simple_animal/hostile/rat/capo_rat/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(downed)
		return 0
	. = ..()
	if(stat != DEAD && !downed && health <= 1)
		EnterDowned()

// Projectiles bypass adjustHealth's gate via deal_damage; block at the
// gun-level too so the rat is a true brick while downed.
/mob/living/simple_animal/hostile/rat/capo_rat/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(downed)
		return BULLET_ACT_BLOCK
	return ..()

// Belt-and-suspenders: if anything bypasses the adjustHealth gate and
// drives us to actual death (fire DoT / direct health writes), catch it
// here and route to Downed instead. The Capo's death() qdel's us,
// which goes through Destroy(), not death() — so this won't fight the
// boss-death cleanup.
// Also skips the base rat's deadmouse-food spawn (passes gibbed = TRUE
// to the parent), matching the railway's "clean room" preference.
/mob/living/simple_animal/hostile/rat/capo_rat/death(gibbed)
	if(!downed && !QDELETED(src) && !gibbed)
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

/mob/living/simple_animal/hostile/rat/capo_rat/refracted
	// Refraction Railway tuning of the pet rat. Currently identical to
	// base; stats / gimmick will diverge here as the encounter is authored.
