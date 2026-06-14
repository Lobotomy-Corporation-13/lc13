/*
 * Curtain Call — zeal_s4n1: The Distorted Priest.
 *
 * A hooded body puppeted by an escort of orbiting blades. Lore is in
 * lore_notes.md; for implementation purposes the priest is a single
 * HP pool — the blades are weapons, not separate kill targets, so
 * the body falling ends the fight regardless of how many blades are alive.
 *
 * Core gimmick: every cast of Blade Dash detaches one orbit blade,
 * draws a free-angle line from the priest through the target (extending
 * past so the total line is at least 7 tiles long), telegraphs for 0.8s,
 * and dashes the blade through it for BLACK damage. The blade hovers
 * at the landing tile for 3 seconds, then chains into another dash on
 * a fresh nearby human (dash_chain_length times) before returning to
 * orbit. Two extra abilities — Sermon Volley (every blade dashes in
 * rapid sequence) and Verdict's Cage (blades park around a player and
 * all dash inward) — escalate the pressure.
 *
 * Skull Mark: the priest periodically tags one human with a skull
 * overlay; marked players are preferred targets for every blade
 * ability until the mark expires.
 *
 * Phase scaling: starting with 2 blades, gains +1 each time HP drops
 * past 80/60/40/20%, capped at 6.
 *
 * Body Sweep: short-range 5x5 BLACK knockback AoE on the body itself,
 * triggered when humans are close enough — adapted from azarus's
 * HouseEdge.
 */

// The talking_sword sprite the blade uses faces NW (handle bottom-right,
// tip upper-left). Get_Angle returns degrees clockwise from north, and
// matrix().Turn is clockwise; for a target due north we need to rotate
// the sprite from 315° to 0° = +45°. If the dashes look misaligned in
// playtest, retune this single number (try 90, 135, 180, 225).
#define BLADE_ANGLE_OFFSET 45

// ---------- Temp visuals ----------

/obj/effect/temp_visual/blade_priest_dash_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#aa0033"
	duration = 8
	randomdir = FALSE

/obj/effect/temp_visual/blade_priest_sweep_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#5e1620"
	duration = 16
	randomdir = FALSE

/obj/effect/temp_visual/blade_priest_cage_park
	name = "verdict"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#220011"
	duration = 18
	randomdir = FALSE

// ---------- The orbiting blade ----------

/obj/effect/possessed_blade
	name = "possessed blade"
	desc = "When the station falls into chaos, it's nice to have a friend by your side."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "talking_sword"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/living/simple_animal/hostile/distortion/blade_priest/parent_priest
	/// "stored" (in orbit, waiting for an order) or "active" (loose on
	/// the field, running a dash chain). Every order proc flips this so
	/// the priest's main tick won't redundantly retrigger a blade that's
	/// already in flight.
	var/state = "stored"
	/// Preferred orbit direction. Alternates per blade so the swarm
	/// doesn't all sweep in the same direction.
	var/preferred_cw = TRUE
	/// world.time at which this blade last finished a dash chain and
	/// returned to orbit. The priest's `blade_reuse_cooldown_time`
	/// gates how soon it can be detached again. Initialized to 0 so
	/// freshly-spawned blades are immediately eligible.
	var/orbit_returned_at = 0

/obj/effect/possessed_blade/Initialize(mapload, mob/living/simple_animal/hostile/distortion/blade_priest/priest, clockwise = TRUE)
	. = ..()
	parent_priest = priest
	preferred_cw = clockwise
	if(priest)
		priest.active_blades += src
		StartOrbit()

/obj/effect/possessed_blade/Destroy()
	StopOrbit()
	if(parent_priest && !QDELETED(parent_priest))
		parent_priest.active_blades -= src
	parent_priest = null
	return ..()

/obj/effect/possessed_blade/proc/StartOrbit()
	if(QDELETED(parent_priest))
		return
	orbit(parent_priest, 48, preferred_cw, 24, 36, FALSE)

/obj/effect/possessed_blade/proc/StopOrbit()
	if(orbiting)
		var/datum/component/orbiter/O = orbiting
		O.end_orbit(src)

/// Unified dash-chain entry point. The order proc shapes ONLY the first
/// dash via the override args; follow-up dashes autonomously pick a
/// target via parent_priest.PickBladeTarget. dir_override direction-locks
/// the first dash (Scatter/Inversion); start_turf_override forceMoves the
/// blade before the first dash (Inversion's perimeter launch).
/obj/effect/possessed_blade/proc/BeginDashChain(turns_remaining = 0, atom/initial_target = null, dir_override = null, turf/start_turf_override = null)
	set waitfor = FALSE
	if(QDELETED(src) || QDELETED(parent_priest) || parent_priest.dying)
		return
	if(state == "active")
		return
	state = "active"
	StopOrbit()
	var/turf/start = start_turf_override || get_turf(parent_priest)
	if(!start)
		ReturnToOrbit()
		return
	forceMove(start)
	pixel_x = 0
	pixel_y = 0
	RunSingleDash(initial_target, dir_override)
	while(turns_remaining > 0 && !QDELETED(src) && !QDELETED(parent_priest) && !parent_priest.dying)
		turns_remaining--
		RunSingleDash(null, null)
	ReturnToOrbit()

/// One dash leg. force_target / dir_override only apply to the first
/// dash of a chain; subsequent calls pass null/null and the blade
/// picks autonomously.
/obj/effect/possessed_blade/proc/RunSingleDash(atom/force_target, dir_override)
	if(QDELETED(src) || QDELETED(parent_priest) || parent_priest.dying)
		return
	var/turf/blade_turf = get_turf(src)
	if(!blade_turf)
		return
	var/turf/end_turf
	if(dir_override)
		end_turf = get_ranged_target_turf(blade_turf, dir_override, 8)
	else
		var/atom/target = force_target || parent_priest.PickBladeTarget(blade_turf)
		if(!target || QDELETED(target))
			sleep(30)
			return
		var/turf/target_turf = get_turf(target)
		if(!target_turf)
			return
		var/dist_to_target = get_dist(blade_turf, target_turf)
		var/overshoot = max(0, 7 - dist_to_target) + 3
		end_turf = get_ranged_target_turf_direct(blade_turf, target_turf, dist_to_target + overshoot)
	if(!end_turf)
		return
	var/list/raw_line = getline(blade_turf, end_turf)
	var/list/line = list()
	var/turf/landing = blade_turf
	for(var/turf/T in raw_line)
		if(T.density)
			break
		landing = T
		line += T
	if(!length(line))
		return
	transform = matrix().Turn(Get_Angle(blade_turf, landing) + BLADE_ANGLE_OFFSET)
	// Telegraph: 0.8s of warning tiles along the whole projected line.
	for(var/turf/T as anything in line)
		new /obj/effect/temp_visual/blade_priest_dash_warning(T)
	playsound(blade_turf, 'sound/weapons/rapierhit.ogg', 35, TRUE, 5)
	sleep(8)
	if(QDELETED(src) || QDELETED(parent_priest) || parent_priest.dying)
		return
	var/dx_px = (landing.x - blade_turf.x) * 32
	var/dy_px = (landing.y - blade_turf.y) * 32
	animate(src, pixel_x = dx_px, pixel_y = dy_px, time = 4, easing = QUAD_EASING)
	playsound(blade_turf, 'sound/weapons/rapierhit.ogg', 75, TRUE, 6)
	var/list/been_hit = list()
	for(var/turf/T as anything in line)
		been_hit = parent_priest.HurtInTurf(T, been_hit, parent_priest.blade_dash_damage, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in been_hit)
		parent_priest.ApplyBladeRupture(L)
	sleep(4)
	if(QDELETED(src))
		return
	forceMove(landing)
	pixel_x = 0
	pixel_y = 0
	sleep(30)

/obj/effect/possessed_blade/proc/ReturnToOrbit()
	if(QDELETED(src))
		return
	if(QDELETED(parent_priest) || parent_priest.dying)
		state = "active"
		return
	transform = matrix()
	pixel_x = 0
	pixel_y = 0
	state = "stored"
	orbit_returned_at = world.time
	StartOrbit()

// ---------- The Distorted Priest ----------

/mob/living/simple_animal/hostile/distortion/blade_priest
	name = "Blade Priest"
	desc = "A black-hooded figure walks the stage in absolute silence. \
		Blades circle them at shoulder height, unsupported."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "blade_priest"
	icon_living = "blade_priest"
	icon_dead = "blade_priest"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("blade_priest")
	maxHealth = 3500
	health = 3500
	melee_damage_lower = 0
	melee_damage_upper = 0
	speak_chance = 0
	turns_per_move = 5
	move_to_delay = 7
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 0.6)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	// Distortion-base FearEffect is one-shot per breach_affected tag, fine
	// at default ZAYIN_LEVEL for atmosphere. Override if a refracted boss
	// version wants it noisier.

	// ---- Blade orbit + phase scaling ----
	var/list/active_blades = list()
	var/starting_blade_count = 4
	/// HP fractions at which the priest grows additional orbit blades.
	/// Cap = starting_blade_count + length(phase_blade_counts) *
	/// blades_per_threshold = 4 + 3*2 = 10 blades at full ladder.
	var/list/phase_blade_counts = list(0.75, 0.50, 0.25)
	var/blades_per_threshold = 2
	var/next_blade_threshold_index = 1

	// ---- Blade dash tuning ----
	var/blade_dash_damage = 80
	/// Rupture stacks applied to every human hit by a blade dash. Marked
	/// players take an additional `blade_rupture_marked_bonus` on top —
	/// the skull mark deepens the cut. Rupture caps at 50 stacks per
	/// the base status effect.
	var/blade_rupture_stacks = 10
	var/blade_rupture_marked_bonus = 10
	/// Follow-up dashes after the first; 4 = 5 total dashes per chain.
	/// Shared by every order — the order only shapes the first dash.
	var/dash_chain_length = 4
	/// After a blade returns to orbit it sits idle this long before
	/// becoming eligible to be detached again. Applies to every order.
	var/blade_reuse_cooldown_time = 6 SECONDS
	/// Floor on how many blades an order must detach. Below this the
	/// cast short-circuits with a 1s retry — never a single-blade order.
	var/order_blade_floor = 2

	// ---- Skull mark ----
	var/datum/weakref/marked_player
	var/image/skull_overlay
	var/mark_cooldown = 0
	var/mark_cooldown_time = 12 SECONDS
	var/mark_duration = 8 SECONDS

	// ---- Body Sweep ----
	var/body_sweep_cooldown = 0
	var/body_sweep_cooldown_time = 5 SECONDS
	var/body_sweep_damage = 35
	var/body_sweep_knockback_dist = 3
	var/body_sweep_telegraph = 16

	// ---- Blade-aegis damage reduction ----
	/// Per-stored-blade damage reduction. 0.1 = 10% off incoming damage
	/// per orbiting blade, clamped by `blade_aegis_max_reduction`.
	var/blade_aegis_per_blade = 0.1
	/// Hard ceiling on the reduction — 0.9 keeps at least 10% of damage
	/// landing even at the full ladder (10 blades = 90% reduction floor).
	var/blade_aegis_max_reduction = 0.9

	// ---- Sermon Volley (BLUE) ----
	var/volley_cooldown = 0
	var/volley_cooldown_time = 20 SECONDS
	/// Deciseconds between spawned blades within a single Volley.
	var/volley_blade_stagger = 3

	// ---- Scatter (RED) ----
	var/scatter_cooldown = 0
	var/scatter_cooldown_time = 18 SECONDS

	// ---- Inversion (PURPLE) ----
	var/inversion_cooldown = 0
	var/inversion_cooldown_time = 30 SECONDS
	var/inversion_perimeter_distance = 6
	/// Deciseconds the perimeter telegraph holds before the convergence.
	var/inversion_telegraph_time = 15

	// ---- Order lock ----
	// While the priest is "ordering" a blade attack, his body locks in
	// place and the sprite switches to a colour-coded order variant for
	// the duration. The lock encompasses the order itself PLUS a short
	// recovery window so players get a punish opening.
	var/order_lock_time_scatter   = 4 SECONDS
	var/order_lock_time_volley    = 5 SECONDS
	var/order_lock_time_inversion = 6 SECONDS
	var/order_icon_scatter   = "blade_priest_red_order"
	var/order_icon_volley    = "blade_priest_blue_order"
	var/order_icon_inversion = "blade_priest_purple_order"
	/// TRUE while EnterOrder has set the locked sprite. ExitOrder clears.
	var/in_order = FALSE
	var/order_timer_id

	// ---- Speech throttling ----
	/// Earliest world.time at which the priest will speak again. Any
	/// SpeakLine call before this drops silently. Bypassed by direct
	/// `say()` calls (only the death line uses that path).
	var/speak_cooldown = 0
	var/speak_cooldown_time = 8 SECONDS

	// ---- Refraction Railway recognition ----
	/// Character this boss recognizes among the railway party, matched as a
	/// case-insensitive substring of a member's mob name. Empty = no one.
	var/recognition_target_name = "Raye Alecinn"
	/// Two-part recognition line, said at the start of combat when matched.
	var/recognition_line_1 = "Raye Alecinn. The one who told them what I do here. I hold no anger for you, child."
	var/recognition_line_2 = "Your friend, the one I cured... I carved the wickedness out. They're so peaceful now, Raye."
	/// Said as the priest fades on death (replaces his normal death line when
	/// Raye is the one who puts him down).
	var/boss_final_line = "...I only... carved out the cruelty... that was kindness... wasn't it, Raye...?"
	/// Once-guard so recognition is attempted a single time per fight.
	var/recognition_attempted = FALSE
	/// TRUE once a party member was actually recognized this fight; makes the
	/// death sequence speak only the final recognition line.
	var/recognized = FALSE
	/// While TRUE the recognition sequence (both halves + 3s after) owns the
	/// priest's voice; every other line is dropped. Sanctioned lines pass
	/// via recognition_bypass.
	var/recognition_locked = FALSE
	var/recognition_bypass = FALSE

	// ---- Lifecycle ----
	var/dying = FALSE
	var/death_fade_time = 2 SECONDS
	var/main_tick_timer_id

	var/list/mark_lines = list(
		"You. Step forward.",
		"This one. The Heart points to this one.",
		"Salvation has chosen you.",
	)
	var/list/volley_lines = list(
		"One after another. Let them confess in turn.",
		"Form a line. Be patient with the children.",
		"The Heart prepares your portion, child.",
	)
	var/list/scatter_lines = list(
		"Loose. All sides. All at once.",
		"Carve out their cruelty wherever it hides.",
		"The flock disperses.",
	)
	var/list/inversion_lines = list(
		"Hold them in place. Let them see.",
		"Verdict. From every side.",
	)
	var/list/blade_count_lines = list(
		"Another voice. Confess louder.",
		"The choir grows.",
		"Yes. More of us to hear you.",
	)
	var/list/death_lines = list(
		"...the blade... is heavy...",
		"...I was... saving them... wasn't I...",
		"...the kindness... was supposed to... carry...",
	)

/mob/living/simple_animal/hostile/distortion/blade_priest/refracted
	// Left empty for refraction-railway retuning. Override any var here
	// (blade_dash_damage, mark_cooldown_time, etc.) to adjust the fight
	// without touching shared logic.

/mob/living/simple_animal/hostile/distortion/blade_priest/Initialize(mapload)
	. = ..()
	skull_overlay = image('ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi', icon_state = "skull_base", layer = ABOVE_MOB_LAYER)
	// Two starting blades, alternating orbit direction.
	for(var/i in 1 to starting_blade_count)
		new /obj/effect/possessed_blade(get_turf(src), src, (i % 2 == 1))
	main_tick_timer_id = addtimer(CALLBACK(src, PROC_REF(MainTick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	scatter_cooldown = world.time + 4 SECONDS
	volley_cooldown = world.time + 12 SECONDS
	inversion_cooldown = world.time + 20 SECONDS
	mark_cooldown = world.time + 6 SECONDS
	addtimer(CALLBACK(src, PROC_REF(TryRecognition)), 1.5 SECONDS)

/mob/living/simple_animal/hostile/distortion/blade_priest/Destroy()
	deltimer(main_tick_timer_id)
	deltimer(order_timer_id)
	ClearMark()
	for(var/obj/effect/possessed_blade/B as anything in active_blades.Copy())
		if(!QDELETED(B))
			qdel(B)
	active_blades.Cut()
	return ..()

/mob/living/simple_animal/hostile/distortion/blade_priest/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

// Body has zero melee damage — the threat is the Body Sweep AoE that
// fires off the main tick when humans get close.
/mob/living/simple_animal/hostile/distortion/blade_priest/AttackingTarget(atom/attacked_target)
	return FALSE

// ---------- Main tick ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/MainTick()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	if(!can_act)
		return
	if(world.time >= mark_cooldown)
		TryMarkPlayer()
	if(world.time >= body_sweep_cooldown && HasMeleeThreat())
		INVOKE_ASYNC(src, PROC_REF(CastBodySweep))
	else if(world.time >= inversion_cooldown)
		INVOKE_ASYNC(src, PROC_REF(CastInversion))
	else if(world.time >= volley_cooldown)
		INVOKE_ASYNC(src, PROC_REF(CastVolley))
	else if(world.time >= scatter_cooldown)
		INVOKE_ASYNC(src, PROC_REF(CastScatter))

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/HasMeleeThreat()
	for(var/mob/living/carbon/human/H in range(2, src))
		if(H.stat != DEAD)
			return TRUE
	return FALSE

// ---------- Target picking ----------

/// Marked player first (if alive and within view of the caller turf),
/// then the nearest human in view. Used by every blade ability.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/PickBladeTarget(turf/from_turf)
	if(!from_turf)
		from_turf = get_turf(src)
	if(!from_turf)
		return null
	var/mob/living/carbon/human/marked = marked_player?.resolve()
	if(marked && marked.stat != DEAD && (marked in view(10, from_turf)))
		return marked
	var/mob/living/carbon/human/best
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in view(10, from_turf))
		if(H.stat == DEAD)
			continue
		var/d = get_dist(from_turf, H)
		if(d < best_dist)
			best_dist = d
			best = H
	return best

// ---------- Skull Mark ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/TryMarkPlayer()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	// Don't restamp if one is still up.
	var/mob/living/carbon/human/current = marked_player?.resolve()
	if(current && current.stat != DEAD)
		return
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(8, src))
		if(H.stat != DEAD)
			candidates += H
	if(!length(candidates))
		return
	var/mob/living/carbon/human/H = pick(candidates)
	marked_player = WEAKREF(H)
	H.add_overlay(skull_overlay)
	SpeakLine(mark_lines)
	mark_cooldown = world.time + mark_cooldown_time
	addtimer(CALLBACK(src, PROC_REF(ClearMark)), mark_duration)

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/ClearMark()
	var/mob/living/carbon/human/H = marked_player?.resolve()
	if(H)
		H.cut_overlay(skull_overlay)
	marked_player = null

// ---------- Order lock ----------

/// Lock the priest in place while a blade attack is issued: can_act=FALSE
/// (gates Move + MainTick), stops walk, swaps to colour-coded order sprite,
/// schedules ExitOrder after `duration`. Blade(s) run the order in parallel
/// — the priest's lock is the punish window, not the attack runtime.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/EnterOrder(order_icon, duration)
	if(stat == DEAD || dying)
		return
	in_order = TRUE
	can_act = FALSE
	walk(src, 0)
	icon_state = order_icon
	icon_living = order_icon
	deltimer(order_timer_id)
	order_timer_id = addtimer(CALLBACK(src, PROC_REF(ExitOrder)), duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/ExitOrder()
	in_order = FALSE
	order_timer_id = null
	if(stat == DEAD || dying)
		return
	icon_state = initial(icon_state)
	icon_living = initial(icon_living)
	can_act = TRUE

// ---------- Speech ----------

/// Has the priest's body say `message_or_list`. Accepts a single string
/// or a list to pick from. Throttled by `speak_cooldown_time` so back-
/// to-back order casts don't turn the priest into a chatterbox — extra
/// lines are dropped silently while the cooldown is active. The death
/// line bypasses by calling `say()` directly in `death()`.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/SpeakLine(message_or_list)
	if(!message_or_list || stat == DEAD)
		return
	if(world.time < speak_cooldown)
		return
	var/message
	if(islist(message_or_list))
		var/list/L = message_or_list
		if(!length(L))
			return
		message = pick(L)
	else
		message = message_or_list
	speak_cooldown = world.time + speak_cooldown_time
	say(message)

// ---------- Refraction Railway recognition ----------

/// Recognition + death lines bypass the lock; every other line is dropped
/// while the recognition sequence holds the priest's voice.
/mob/living/simple_animal/hostile/distortion/blade_priest/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(recognition_locked && !recognition_bypass)
		return
	return ..()

/// Says a framework-sanctioned line past the recognition lock + throttle.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/SpeakRecognition(message)
	if(!message)
		return
	recognition_bypass = TRUE
	say(message)
	recognition_bypass = FALSE

/// Start of combat: if a railway party member's mob name contains
/// recognition_target_name, play the two-part recognition line and hold the
/// speech lock through both parts plus 3 seconds.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/TryRecognition()
	if(recognition_attempted || stat == DEAD || dying)
		return
	recognition_attempted = TRUE
	if(!recognition_target_name)
		return
	var/datum/refraction_run/R = FindRefractionRunForZ(z)
	if(!R)
		return
	var/found = FALSE
	for(var/mob/M as anything in R.members)
		if(QDELETED(M))
			continue
		var/their_name = M.real_name || M.name
		if(their_name && findtext(their_name, recognition_target_name))
			found = TRUE
			break
	if(!found)
		return
	recognized = TRUE
	recognition_locked = TRUE
	SpeakRecognition(recognition_line_1)
	addtimer(CALLBACK(src, PROC_REF(RecognitionPart2)), 2 SECONDS)

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/RecognitionPart2()
	if(QDELETED(src) || stat == DEAD || dying)
		recognition_locked = FALSE
		return
	SpeakRecognition(recognition_line_2)
	addtimer(CALLBACK(src, PROC_REF(EndRecognitionLock)), 3 SECONDS)

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/EndRecognitionLock()
	recognition_locked = FALSE

// ---------- Per-hit Rupture application ----------

/// Stacks Rupture on a living target hit by any blade dash, with a
/// flat bonus when the target is the current Skull Mark holder.
/// Cap-handling is the responsibility of the Rupture status (max 50).
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/ApplyBladeRupture(mob/living/L)
	if(QDELETED(L) || L.stat == DEAD)
		return
	var/stacks = blade_rupture_stacks
	var/mob/living/marked = marked_player?.resolve()
	if(marked && L == marked)
		stacks += blade_rupture_marked_bonus
	L.apply_lc_rupture(stacks)

// ---------- Blade picking helpers ----------

/// A blade is eligible to be detached when (a) it's currently stored
/// (orbiting, not on the field) and (b) its post-return reuse cooldown
/// has elapsed. Applies to every order — Volley, Scatter, Inversion.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/BladeIsReady(obj/effect/possessed_blade/B)
	if(QDELETED(B))
		return FALSE
	if(B.state != "stored")
		return FALSE
	if(world.time < B.orbit_returned_at + blade_reuse_cooldown_time)
		return FALSE
	return TRUE

/// Returns the list of blades each order should detach this cast. Target
/// count = half of stored blades, floored at order_blade_floor (default 2).
/// Walks the orbit and picks the first `target_count` blades passing
/// BladeIsReady. May return shorter than target_count if too few are
/// off-cooldown — the caller decides whether to short-circuit.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/PickBladesForOrder()
	var/stored_count = 0
	for(var/obj/effect/possessed_blade/B as anything in active_blades)
		if(!QDELETED(B) && B.state == "stored")
			stored_count++
	var/target_count = max(order_blade_floor, round(stored_count / 2))
	var/list/picked = list()
	for(var/obj/effect/possessed_blade/B as anything in active_blades)
		if(length(picked) >= target_count)
			break
		if(BladeIsReady(B))
			picked += B
	return picked

// ---------- Sermon Volley (BLUE) ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/CastVolley()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	var/list/blades = PickBladesForOrder()
	if(length(blades) < order_blade_floor)
		volley_cooldown = world.time + 1 SECONDS
		return
	volley_cooldown = world.time + volley_cooldown_time
	EnterOrder(order_icon_volley, order_lock_time_volley)
	SpeakLine(volley_lines)
	playsound(get_turf(src), 'sound/weapons/rapierhit.ogg', 60, TRUE, 8)
	var/i = 0
	for(var/obj/effect/possessed_blade/B as anything in blades)
		addtimer(CALLBACK(src, PROC_REF(LaunchVolleyBlade), B), i * volley_blade_stagger)
		i++

/// Per-blade callback for Volley's stagger. Re-picks the target at the
/// moment of launch so a freshly-marked player gets pulled in.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/LaunchVolleyBlade(obj/effect/possessed_blade/B)
	if(QDELETED(src) || QDELETED(B) || dying)
		return
	if(B.state != "stored")
		return
	var/atom/picked_target = PickBladeTarget(get_turf(src))
	B.BeginDashChain(dash_chain_length, picked_target, null, null)

// ---------- Scatter (RED) ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/CastScatter()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	var/list/blades = PickBladesForOrder()
	if(length(blades) < order_blade_floor)
		scatter_cooldown = world.time + 1 SECONDS
		return
	scatter_cooldown = world.time + scatter_cooldown_time
	EnterOrder(order_icon_scatter, order_lock_time_scatter)
	SpeakLine(scatter_lines)
	playsound(get_turf(src), 'sound/weapons/rapierhit.ogg', 60, TRUE, 8)
	var/list/dirs = shuffle(list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST))
	var/i = 1
	for(var/obj/effect/possessed_blade/B as anything in blades)
		if(i > length(dirs))
			break
		var/launch_dir = dirs[i]
		i++
		INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/effect/possessed_blade, BeginDashChain), dash_chain_length, null, launch_dir, null)

// ---------- Inversion (PURPLE) ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/CastInversion()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	var/list/blades = PickBladesForOrder()
	if(length(blades) < order_blade_floor)
		inversion_cooldown = world.time + 1 SECONDS
		return
	var/turf/center = get_turf(src)
	if(!center)
		inversion_cooldown = world.time + 1 SECONDS
		return
	inversion_cooldown = world.time + inversion_cooldown_time
	EnterOrder(order_icon_inversion, order_lock_time_inversion)
	SpeakLine(inversion_lines)
	playsound(center, 'sound/weapons/rapierhit.ogg', 50, TRUE, 6)
	var/list/dirs = shuffle(list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST))
	var/list/staged = list()  // assoc list of blade => perimeter_turf
	var/i = 1
	for(var/obj/effect/possessed_blade/B as anything in blades)
		if(i > length(dirs))
			break
		var/park_dir = dirs[i]
		i++
		var/turf/perimeter = get_ranged_target_turf(center, park_dir, inversion_perimeter_distance)
		if(!perimeter || perimeter.density)
			continue
		// Detach the blade, teleport to perimeter, face the priest.
		B.state = "active"
		B.StopOrbit()
		B.forceMove(perimeter)
		B.pixel_x = 0
		B.pixel_y = 0
		B.transform = matrix().Turn(Get_Angle(perimeter, center) + BLADE_ANGLE_OFFSET)
		var/inward_dir = get_dir(perimeter, center)
		var/turf/line_end = get_ranged_target_turf(perimeter, inward_dir, inversion_perimeter_distance + 3)
		var/list/line = getline(perimeter, line_end)
		for(var/turf/T as anything in line)
			new /obj/effect/temp_visual/blade_priest_dash_warning(T)
		staged[B] = perimeter
	if(!length(staged))
		return
	addtimer(CALLBACK(src, PROC_REF(FireInversion), staged, center), inversion_telegraph_time)

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/FireInversion(list/staged, turf/center)
	if(QDELETED(src) || stat == DEAD || dying)
		for(var/obj/effect/possessed_blade/B as anything in staged)
			if(!QDELETED(B))
				B.ReturnToOrbit()
		return
	if(!center)
		return
	for(var/obj/effect/possessed_blade/B as anything in staged)
		if(QDELETED(B))
			continue
		var/turf/perimeter = staged[B]
		if(!perimeter)
			continue
		var/inward_dir = get_dir(perimeter, center)
		B.state = "stored"
		INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/effect/possessed_blade, BeginDashChain), dash_chain_length, null, inward_dir, perimeter)

// ---------- Body Sweep ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/CastBodySweep()
	if(QDELETED(src) || stat == DEAD || dying)
		return
	can_act = FALSE
	walk(src, 0)
	body_sweep_cooldown = world.time + body_sweep_cooldown_time
	var/turf/center = get_turf(src)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/blade_priest_sweep_warning(T)
	playsound(center, 'sound/magic/clockwork/invoke_general.ogg', 60, FALSE, 5)
	SLEEP_CHECK_DEATH(body_sweep_telegraph)
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		been_hit = HurtInTurf(T, been_hit, body_sweep_damage, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			var/throw_dir = get_dir(center, L)
			var/turf/throw_at_turf = get_ranged_target_turf(L, throw_dir, body_sweep_knockback_dist)
			if(throw_at_turf)
				L.throw_at(throw_at_turf, body_sweep_knockback_dist, 2, src)
	playsound(center, 'sound/weapons/rapierhit.ogg', 70, FALSE, 6)
	can_act = TRUE

// ---------- Phase scaling: new blades on HP thresholds ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && amount > 0 && stat != DEAD && !dying)
		var/reduction = min(CountStoredBlades() * blade_aegis_per_blade, blade_aegis_max_reduction)
		if(reduction > 0)
			amount *= (1 - reduction)
	. = ..(amount, updating_health, forced)
	if(stat == DEAD || dying || !maxHealth || health <= 0)
		return
	if(next_blade_threshold_index > length(phase_blade_counts))
		return
	var/ratio = health / maxHealth
	while(next_blade_threshold_index <= length(phase_blade_counts) \
		&& ratio <= phase_blade_counts[next_blade_threshold_index])
		SpawnExtraBlades(blades_per_threshold)
		next_blade_threshold_index++

/// Counts only blades currently in the stored (orbit) state. Active
/// blades on the field don't shield the priest — the aegis is about the
/// in-orbit escort, so killing the priest gets easier as more blades are
/// loosed onto the field.
/mob/living/simple_animal/hostile/distortion/blade_priest/proc/CountStoredBlades()
	var/n = 0
	for(var/obj/effect/possessed_blade/B as anything in active_blades)
		if(!QDELETED(B) && B.state == "stored")
			n++
	return n

/mob/living/simple_animal/hostile/distortion/blade_priest/proc/SpawnExtraBlades(count = 1)
	for(var/i in 1 to count)
		var/clockwise = (length(active_blades) % 2 == 0)
		new /obj/effect/possessed_blade(get_turf(src), src, clockwise)
	SpeakLine(blade_count_lines)
	playsound(get_turf(src), 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)

// ---------- Death ----------

/mob/living/simple_animal/hostile/distortion/blade_priest/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	recognition_locked = FALSE
	deltimer(order_timer_id)
	in_order = FALSE
	// Bypass the speech throttle — the death line should always land. A
	// recognized run says only the final recognition line, not the normal one.
	if(recognized && boss_final_line)
		SpeakRecognition(boss_final_line)
	else
		say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
	ClearMark()
	for(var/obj/effect/possessed_blade/B as anything in active_blades.Copy())
		if(QDELETED(B))
			continue
		B.StopOrbit()
		animate(B, alpha = 0, time = 1.5 SECONDS)
		QDEL_IN(B, 1.5 SECONDS)
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

#undef BLADE_ANGLE_OFFSET
