/*
 * Curtain Call — zeal_s3n2: The Snow Cabin.
 *
 * The cabin protects its master by morphing into a dream-place that
 * eats its visitors. Theme: flesh + snow fused. Players fight inside a
 * 15x10 arena pre-built by the mapper. Floor weakpoints / hatching events
 * land on any open turf (mouths, meatpods, ice prisons) except the snow
 * and ice variants the cabin can't pierce; eyes mount on any closed wall
 * except the fakeglass — see IsValidFloorTile / IsValidWallTile. The
 * cabin itself is an
 * invisible controller mob; players damage it only through weakpoints
 * it spits up onto the floor (eyes + mouths). On a separate Phase 2
 * timer it also spawns environmental hatching events that disgorge
 * meatling and yagaslave minions.
 *
 * All tuning lives as `var/`s on the cabin mob itself — refracted
 * subtypes override what they need. Subordinate classes (mouth, meatpod,
 * ice_prison) keep a `parent_cabin` ref and read their durations through
 * it so retuning happens in one place.
 */

// ---------- Temp visuals ----------

/obj/effect/temp_visual/snow_cabin_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#c44b6e"

// Allow the caller to override duration so the cabin's bladed_teeth_windup
// var stays the single source of truth.
/obj/effect/temp_visual/snow_cabin_warning/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

/obj/effect/temp_visual/snow_cabin_bone_stab_warning
	name = "splintering wood"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "bone_stab_warning"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/snow_cabin_bone_stab_warning/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

/obj/effect/temp_visual/snow_cabin_bone_stab
	name = "bone spike"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "bone_stab"
	layer = BELOW_MOB_LAYER
	duration = 20

/obj/effect/temp_visual/snow_cabin_bladed_teeth
	name = "bladed teeth"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "bladed_teeth"
	layer = BELOW_MOB_LAYER
	duration = 6

/obj/effect/temp_visual/snow_cabin_ice_spike_rise
	name = "rising ice"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "ice_spikes_rise"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER
	duration = 3

/obj/effect/temp_visual/snow_cabin_ice_spike
	name = "ice spike"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "ice_spikes"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER
	duration = 15

/obj/effect/temp_visual/snow_cabin_ice_rupture_rise
	name = "rising ice"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "ice_rupture_rise"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER
	duration = 4

/obj/effect/temp_visual/snow_cabin_ice_rupture
	name = "ice spike"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "ice_rupture"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER
	duration = 15

/obj/effect/temp_visual/snow_cabin_ice_shard_warning
	name = "splintering ice"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "large_ice_shards_warning"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/snow_cabin_ice_shard_warning/Initialize(mapload, custom_duration)
	if(custom_duration)
		duration = custom_duration
	. = ..()

/obj/effect/temp_visual/snow_cabin_ice_shards
	name = "ice shards"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "large_ice_shards"
	pixel_x = -1
	pixel_y = -8
	layer = BELOW_MOB_LAYER
	duration = 15

// Persistent floor scarring. Tracked on the parent cabin so they can be
// faded out together when the cabin dies (each crack gets its own random
// interval so the room "rots closed" organically rather than all-at-once).
// Only the cabin's floor-bound parts leave these behind — mouths and
// hatched meatpods. Eyes (mounted on walls) and free-roaming minions don't.
/obj/effect/snow_cabin_meat_crack
	name = "meat crack"
	desc = "The floorboards have split apart, showing something pink and warm beneath."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "meat_crack"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
	var/mob/living/simple_animal/hostile/snow_cabin/parent_cabin

/obj/effect/snow_cabin_meat_crack/Initialize(mapload, mob/living/simple_animal/hostile/snow_cabin/cabin)
	. = ..()
	if(cabin)
		parent_cabin = cabin
		cabin.active_meat_cracks += src

/obj/effect/snow_cabin_meat_crack/Destroy()
	if(parent_cabin && !QDELETED(parent_cabin))
		parent_cabin.active_meat_cracks -= src
	parent_cabin = null
	return ..()

// ---------- Eye weakpoint ----------

/mob/living/simple_animal/hostile/snow_cabin_eye
	name = "watchful eye"
	desc = "A clouded eye blinks where there was wood. It will not look away."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "eyeturf_blink"
	icon_living = "eyeturf_blink"
	icon_dead = "eyeturf_blink"
	mob_biotypes = MOB_ORGANIC
	faction = list("snow_cabin")
	maxHealth = 200
	health = 200
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON
	melee_damage_lower = 0
	melee_damage_upper = 0
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	var/mob/living/simple_animal/hostile/snow_cabin/parent_cabin

/mob/living/simple_animal/hostile/snow_cabin_eye/Initialize(mapload, mob/living/simple_animal/hostile/snow_cabin/cabin)
	. = ..()
	parent_cabin = cabin
	toggle_ai(AI_OFF)
	addtimer(CALLBACK(src, PROC_REF(FaceNearestPlayer)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/snow_cabin_eye/Destroy()
	parent_cabin = null
	return ..()

/mob/living/simple_animal/hostile/snow_cabin_eye/Move()
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin_eye/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin_eye/proc/FaceNearestPlayer()
	if(QDELETED(src) || stat == DEAD)
		return
	var/mob/living/carbon/human/closest
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in range(8, src))
		if(H.stat == DEAD)
			continue
		var/d = get_dist(src, H)
		if(d < best_dist)
			best_dist = d
			closest = H
	if(closest)
		setDir(get_dir(src, closest))

// Eyes are on the walls — no meat_crack on the floor when they die.
/mob/living/simple_animal/hostile/snow_cabin_eye/death(gibbed)
	if(parent_cabin)
		parent_cabin.OnEyeKilled(src)
	. = ..()
	QDEL_IN(src, 5)

// ---------- Mouth weakpoint ----------

// Cycle: closed (rest — the kill window) → opening (transition, no
// attacks) → open (biting) → closing (transition, no attacks) →
// closed. Stage durations live as vars on the parent cabin.
//
// Icon-state legend:
//   "mouthturf_closed"  — static, resting closed (kill window)
//   "mouthturf_open"    — animated open-up transition
//   "mouthturf_opened"  — static, resting open (danger window)
//   "mouthturf_close"   — animated close-down transition
//   "mouthturf_chomp"   — bite flash, played briefly on each successful hit

/mob/living/simple_animal/hostile/snow_cabin_mouth
	name = "gnawing mouth"
	desc = "Teeth ring an open ring of meat where there was floor. It tastes the air."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "mouthturf_closed"
	icon_living = "mouthturf_closed"
	icon_dead = "mouthturf_closed"
	mob_biotypes = MOB_ORGANIC
	faction = list("snow_cabin")
	maxHealth = 400
	health = 400
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON
	melee_damage_lower = 80
	melee_damage_upper = 80
	melee_damage_type = RED_DAMAGE
	// Mouths take 40% less damage from the four core types (×0.6). The
	// data sheet renders this row automatically, so no passive card.
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 0.6)
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	attack_sound = 'sound/hallucinations/growl1.ogg'
	var/mob/living/simple_animal/hostile/snow_cabin/parent_cabin
	/// "closed" / "opening" / "open" / "closing". AttackingTarget rejects
	/// anything that isn't "open".
	var/mouth_state = "closed"
	var/cycle_timer_id

/mob/living/simple_animal/hostile/snow_cabin_mouth/Initialize(mapload, mob/living/simple_animal/hostile/snow_cabin/cabin)
	. = ..()
	parent_cabin = cabin
	icon_state = "mouthturf_closed"
	cycle_timer_id = addtimer(CALLBACK(src, PROC_REF(StartOpening)), parent_cabin?.mouth_closed_duration || 4 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/snow_cabin_mouth/Destroy()
	deltimer(cycle_timer_id)
	parent_cabin = null
	return ..()

/mob/living/simple_animal/hostile/snow_cabin_mouth/Move()
	return FALSE

/// Gate on top of the standard melee path. Bites only land while the
/// mouth is in the open state; closed and either transition stage block
/// the attack entirely. On a connect, flash the chomp sprite.
/mob/living/simple_animal/hostile/snow_cabin_mouth/AttackingTarget(atom/attacked_target)
	if(mouth_state != "open")
		return FALSE
	. = ..()
	if(.)
		PlayChompAnimation()

// State 1 → 2: closed → opening. The animated open sprite plays the
// transition; bites still can't fire.
/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/StartOpening()
	if(QDELETED(src) || stat == DEAD)
		return
	mouth_state = "opening"
	icon_state = "mouthturf_open"
	icon_living = "mouthturf_open"
	cycle_timer_id = addtimer(CALLBACK(src, PROC_REF(FinishOpening)), parent_cabin?.mouth_transition_duration || 11, TIMER_STOPPABLE)

// State 2 → 3: opening → open. Icon settles on the static "opened"
// sprite. AttackingTarget's mouth_state gate now lets bites land.
/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/FinishOpening()
	if(QDELETED(src) || stat == DEAD)
		return
	mouth_state = "open"
	icon_state = "mouthturf_opened"
	icon_living = "mouthturf_opened"
	cycle_timer_id = addtimer(CALLBACK(src, PROC_REF(StartClosing)), parent_cabin?.mouth_open_duration || 3 SECONDS, TIMER_STOPPABLE)

// State 3 → 4: open → closing. The animated close sprite plays the
// transition. AttackingTarget's state gate now blocks new bites.
/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/StartClosing()
	if(QDELETED(src) || stat == DEAD)
		return
	mouth_state = "closing"
	icon_state = "mouthturf_close"
	icon_living = "mouthturf_close"
	cycle_timer_id = addtimer(CALLBACK(src, PROC_REF(FinishClosing)), parent_cabin?.mouth_transition_duration || 11, TIMER_STOPPABLE)

// State 4 → 1: closing → closed. The kill window opens — icon settles on
// the static "closed" sprite.
/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/FinishClosing()
	if(QDELETED(src) || stat == DEAD)
		return
	mouth_state = "closed"
	icon_state = "mouthturf_closed"
	icon_living = "mouthturf_closed"
	cycle_timer_id = addtimer(CALLBACK(src, PROC_REF(StartOpening)), parent_cabin?.mouth_closed_duration || 4 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/PlayChompAnimation()
	icon_state = "mouthturf_chomp"
	icon_living = "mouthturf_chomp"
	playsound(src, 'sound/items/eatfood.ogg', 70, TRUE)
	addtimer(CALLBACK(src, PROC_REF(RestoreOpenIcon)), parent_cabin?.mouth_chomp_anim_duration || 6, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/snow_cabin_mouth/proc/RestoreOpenIcon()
	if(QDELETED(src) || stat == DEAD)
		return
	if(mouth_state == "open")
		icon_state = "mouthturf_opened"
		icon_living = "mouthturf_opened"

// Mouths ARE part of the floor; their death leaves the floor scarred.
/mob/living/simple_animal/hostile/snow_cabin_mouth/death(gibbed)
	if(parent_cabin)
		parent_cabin.OnMouthKilled(src)
	. = ..()
	new /obj/effect/snow_cabin_meat_crack(get_turf(src), parent_cabin)
	QDEL_IN(src, 5)

// ---------- Meatpod hatching event + meatling minion ----------

/obj/effect/snow_cabin_meatpod
	name = "meatpod"
	desc = "A wet, twitching sac, taut against something inside trying to get out."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "meatpod"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE
	var/mob/living/simple_animal/hostile/snow_cabin/parent_cabin
	var/hatch_timer_id

/obj/effect/snow_cabin_meatpod/Initialize(mapload, mob/living/simple_animal/hostile/snow_cabin/cabin)
	. = ..()
	parent_cabin = cabin
	hatch_timer_id = addtimer(CALLBACK(src, PROC_REF(Hatch)), parent_cabin?.meatpod_hatch_delay || 4 SECONDS, TIMER_STOPPABLE)

/obj/effect/snow_cabin_meatpod/Destroy()
	deltimer(hatch_timer_id)
	if(parent_cabin)
		parent_cabin.active_meatpods -= src
		parent_cabin = null
	return ..()

/obj/effect/snow_cabin_meatpod/proc/Hatch()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return
	visible_message(span_warning("[src] splits open!"))
	playsound(T, 'sound/effects/splat.ogg', 70, TRUE)
	// The pod was anchored to the floor — it leaves a scar where it burst.
	new /obj/effect/snow_cabin_meat_crack(T, parent_cabin)
	var/mob/living/simple_animal/hostile/cabin_meatling/M = new(T)
	if(parent_cabin)
		M.faction = list("snow_cabin")
		parent_cabin.active_minions += M
		M.AddComponent(/datum/component/snow_cabin_minion_owner, parent_cabin)
	qdel(src)

/datum/component/snow_cabin_minion_owner
	var/mob/living/simple_animal/hostile/snow_cabin/cabin

/datum/component/snow_cabin_minion_owner/Initialize(mob/living/simple_animal/hostile/snow_cabin/cabin_ref)
	. = ..()
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	cabin = cabin_ref
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(OnDeath))
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(OnQdel))

/datum/component/snow_cabin_minion_owner/proc/OnDeath(mob/living/M)
	SIGNAL_HANDLER
	if(cabin && !QDELETED(cabin))
		cabin.active_minions -= M

/datum/component/snow_cabin_minion_owner/proc/OnQdel(mob/living/M)
	SIGNAL_HANDLER
	if(cabin && !QDELETED(cabin))
		cabin.active_minions -= M

/mob/living/simple_animal/hostile/cabin_meatling
	name = "meatling"
	desc = "A small, scuttling lump of flesh with too many teeth for its size."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "meatboi"
	icon_living = "meatboi"
	icon_dead = "meat_crack"
	mob_biotypes = MOB_ORGANIC
	faction = list("snow_cabin")
	maxHealth = 150
	health = 150
	move_to_delay = 5
	melee_damage_lower = 12
	melee_damage_upper = 18
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "gnaws at"
	attack_verb_simple = "gnaw at"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN

// Free-roaming minion — disconnected from the cabin once spawned. No
// floor scar when it dies.
/mob/living/simple_animal/hostile/cabin_meatling/death(gibbed)
	. = ..()
	QDEL_IN(src, 5)

// ---------- Ice prison hatching event + yagaslave minion ----------

/obj/effect/snow_cabin_ice_prison
	name = "growing ice"
	desc = "A small block of ice that does not feel cold. Something is moving inside it."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "iceprision1_short"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE
	var/mob/living/simple_animal/hostile/snow_cabin/parent_cabin
	/// 1 or 2 — visual variant.
	var/variant = 1
	var/grown_timer_id
	var/ripe_timer_id
	var/hatch_timer_id

/obj/effect/snow_cabin_ice_prison/Initialize(mapload, mob/living/simple_animal/hostile/snow_cabin/cabin)
	. = ..()
	parent_cabin = cabin
	variant = pick(1, 2)
	icon_state = "iceprision[variant]_short"
	grown_timer_id = addtimer(CALLBACK(src, PROC_REF(BecomeGrown)), parent_cabin?.ice_prison_seed_duration || 5 SECONDS, TIMER_STOPPABLE)

/obj/effect/snow_cabin_ice_prison/Destroy()
	deltimer(grown_timer_id)
	deltimer(ripe_timer_id)
	deltimer(hatch_timer_id)
	if(parent_cabin)
		parent_cabin.active_ice_prisons -= src
		parent_cabin = null
	return ..()

/obj/effect/snow_cabin_ice_prison/proc/BecomeGrown()
	if(QDELETED(src))
		return
	icon_state = "iceprision[variant]"
	ripe_timer_id = addtimer(CALLBACK(src, PROC_REF(BecomeRipe)), parent_cabin?.ice_prison_grown_duration || 4 SECONDS, TIMER_STOPPABLE)

/obj/effect/snow_cabin_ice_prison/proc/BecomeRipe()
	if(QDELETED(src))
		return
	icon_state = "iceprision[variant]_full"
	desc = "A block of ice the size of a person. Something is shifting inside."
	hatch_timer_id = addtimer(CALLBACK(src, PROC_REF(Hatch)), parent_cabin?.ice_prison_ripe_duration || 3 SECONDS, TIMER_STOPPABLE)

/obj/effect/snow_cabin_ice_prison/proc/Hatch()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return
	visible_message(span_userdanger("[src] cracks open!"))
	playsound(T, 'sound/effects/glassbr1.ogg', 70, TRUE)
	var/mob/living/simple_animal/hostile/cabin_yagaslave/Y = new(T)
	if(parent_cabin)
		Y.faction = list("snow_cabin")
		parent_cabin.active_minions += Y
		Y.AddComponent(/datum/component/snow_cabin_minion_owner, parent_cabin)
	qdel(src)

/mob/living/simple_animal/hostile/cabin_yagaslave
	name = "yagaslave"
	desc = "A hunched, hollow-eyed thing carved out of the cabin's deepest cold."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "yagaslave"
	icon_living = "yagaslave"
	icon_dead = "yagaslave"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("snow_cabin")
	maxHealth = 250
	health = 250
	move_to_delay = 6
	melee_damage_lower = 15
	melee_damage_upper = 22
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "rakes at"
	attack_verb_simple = "rake at"
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN

// Free-roaming minion — disconnected from the cabin. No floor scar; just
// despawn.
/mob/living/simple_animal/hostile/cabin_yagaslave/death(gibbed)
	. = ..()
	QDEL_IN(src, 5)

// ---------- The Snow Cabin (invisible controller) ----------

/mob/living/simple_animal/hostile/snow_cabin
	name = "the Snow Cabin"
	desc = "It is keeping something safe. It is willing to bend any shape to do so."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "the_cabin"
	icon_living = "the_cabin"
	icon_dead = "the_cabin"
	alpha = 0
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	mob_biotypes = MOB_ORGANIC
	faction = list("snow_cabin")
	// 6500 base HP preserves the old integrity-system kill count: ~32 eye
	// kills (200 BRUTE each) or ~16 mouth kills (400 BRUTE each), matching
	// the old 100-integrity / 3-per-eye / 6-per-mouth budget. Boss nodes
	// scale this by the player count (wave_system.dm: H.maxHealth *= n
	// for `is_boss` nodes), so 4 players get a 26000-HP cabin and pay for
	// it with the extra DPS the bigger party brings to the weakpoints.
	maxHealth = 6500
	health = 6500
	melee_damage_lower = 0
	melee_damage_upper = 0
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN

	// ---------- Tunable knobs ----------
	// Phase tuning. The boss is invulnerable to direct player attacks
	// (see attack_hand / attack_paw / attackby / bullet_act below); its
	// HP is moved exclusively by weakpoint deaths calling adjustBruteLoss.
	// Wave-system HP scaling multiplies maxHealth per player at spawn time.
	/// Fraction of maxHealth at which Phase 2 triggers. 0.5 = 50% HP.
	var/phase_2_threshold = 0.5
	/// 1 = Phase 1, 2 = Phase 2.
	var/phase = 1

	// Weakpoint spawn targets per phase. Main tick fills to these.
	var/eye_target_phase_1   = 6
	var/eye_target_phase_2   = 12
	var/mouth_target_phase_1 = 4
	var/mouth_target_phase_2 = 10
	/// Tile-distance cap from the cabin for spawning eyes (walls) and
	/// mouths / meatpods / ice prisons (floor). The cabin doesn't move,
	/// so the eligible-tile cache is built once and reused.
	var/weakpoint_spawn_range = 20
	/// Tile-distance cap from the cabin for considering a player part of
	/// this encounter. Targeting (AoE picks), gating (HasActivePlayers),
	/// voice fallback, and the death broadcast all use this — players on
	/// the other side of the map are ignored even on the same Z.
	var/arena_range = 20
	/// Minimum spacing between any two weakpoints (eye OR mouth). A
	/// candidate tile is rejected if any existing eye or mouth sits
	/// within this many tiles of it (chebyshev). 2 = at least a 2-tile
	/// gap between weakpoints.
	var/weakpoint_min_spacing = 2

	// Mouth state machine timings (read by /snow_cabin_mouth via parent_cabin).
	var/mouth_closed_duration     = 4 SECONDS
	var/mouth_open_duration       = 3 SECONDS
	var/mouth_transition_duration = 11
	var/mouth_chomp_anim_duration = 6

	// Phase 2 hatching event cadence + per-event timings.
	var/meatpod_cap               = 3
	var/meatpod_spawn_interval    = 12 SECONDS
	var/meatpod_hatch_delay       = 4 SECONDS
	var/ice_prison_cap            = 2
	var/ice_prison_spawn_interval = 14 SECONDS
	var/ice_prison_seed_duration  = 5 SECONDS
	var/ice_prison_grown_duration = 4 SECONDS
	var/ice_prison_ripe_duration  = 3 SECONDS
	// Hard caps on alive minions per type. Each spawn gate counts the
	// already-alive minions PLUS any pending pods/prisons that will
	// produce one when they hatch, so the cap holds across the whole
	// spawn pipeline.
	var/meatling_cap              = 2
	var/yagaslave_cap             = 1

	// AoE damage (per tile / per hit).
	var/bone_stab_damage     = 60
	var/bladed_teeth_damage  = 50
	var/ice_spike_damage     = 100
	var/ice_shard_damage     = 80

	// AoE cooldowns.
	var/bone_stab_cooldown    = 12 SECONDS
	var/bladed_teeth_cooldown = 10 SECONDS
	var/ice_spike_cooldown    = 18 SECONDS
	var/ice_shard_cooldown    = 28 SECONDS

	// AoE shape parameters.
	/// Bone Stab Line sweeps wall-to-wall in 3-wide / 3-tall chunks.
	/// bone_stab_chunk_delay (deciseconds) is the gap between consecutive
	/// chunks rising — pianist-style wave.
	var/bone_stab_chunk_delay         = 1
	/// Bladed Teeth covers a fraction of the floor (per phase).
	var/bladed_teeth_phase_1_coverage = 0.25
	var/bladed_teeth_phase_2_coverage = 0.40
	/// Ice shards pick N random floor tiles within ice_shard_radius of a player.
	var/ice_shard_count_min           = 6
	var/ice_shard_count_max           = 10
	var/ice_shard_radius              = 3

	// Telegraph wind-up durations (deciseconds).
	var/bone_stab_windup    = 15
	var/bladed_teeth_windup = 12
	var/ice_spike_windup    = 12
	var/ice_shard_windup    = 20

	// Phase 2 multiplier — multiplies CooldownScaled() base.
	var/phase_2_cooldown_factor = 0.75

	// ---------- Runtime state (not tuning) ----------

	/// Active weakpoint mobs spawned by the boss.
	var/list/active_eyes = list()
	var/list/active_mouths = list()
	/// Active pre-burst meatpods and pre-hatch ice prisons.
	var/list/active_meatpods = list()
	var/list/active_ice_prisons = list()
	/// Spawned minions still alive (meatlings + yagaslaves).
	var/list/active_minions = list()
	/// Persistent floor decals left by mouth deaths, meatpod bursts, and
	/// the cabin's own death scatter. Iterated on cabin death so each
	/// crack can fade out at its own random interval.
	var/list/active_meat_cracks = list()

	/// Cached floor tiles (mouths, meatpods, ice prisons spawn here) and
	/// wall tiles (eyes spawn here). Built lazily on first need.
	var/list/cached_floor_tiles
	var/list/cached_wall_tiles
	/// Cached area-lock. Snapshotted on first GetFloorTiles / GetWallTiles
	/// call (the cabin can't move, so it's safe to freeze once). Tile
	/// validators reject any turf in a different area.
	var/area/locked_area

	// Cooldown timestamps (world.time of next ready).
	var/next_bone_stab = 0
	var/next_bladed_teeth = 0
	var/next_ice_spike = 0
	var/next_ice_shard = 0
	var/next_meatpod_spawn = 0
	var/next_ice_prison_spawn = 0

	var/main_tick_timer_id

	// ---------- Voice line pools ----------
	// The cabin speaks through whichever mouth weakpoint is alive when a
	// special attack fires; if no mouths are alive the line falls back to a
	// whispered visible_message. Tone: bestial, ceremonial, furious.
	// Ellipsis = relished pause; "!" = the verdict landing.
	var/list/lines_bone_stab = list(
		"Splinters... through the soft of you!",
		"Bones for trespassers!",
		"Hold still... the floor holds you!",
		"Drink, floor! Drink them dry!",
	)
	var/list/lines_bladed_teeth = list(
		"Open... and bite!",
		"Teeth in the wood... teeth in your throat!",
		"Soft meat! Soft, soft meat!",
		"The cabin hungers... and you are here!",
	)
	var/list/lines_ice_spike = list(
		"Pinned... for the master!",
		"Stand! Stand and freeze!",
		"Cold for him... cold for him!",
		"Ice through the warm of you!",
	)
	var/list/lines_ice_shard = list(
		"Shatter! Shatter! Every last one!",
		"The dream itself is biting!",
		"Glass for the unwelcome!",
		"Cold breaks... cold breaks you!",
	)
	var/list/lines_phase_2 = list(
		"Enough! Enough indulgence!",
		"You wake him... I do not have to pretend!",
		"Hospitality... rescinded!",
		"The dream has teeth! The dream has bones!",
	)

/mob/living/simple_animal/hostile/snow_cabin/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	// Pin the area-lock at spawn so IsValidFloorTile / IsValidWallTile
	// reject any turf outside this arena, even before the floor/wall
	// caches are built. The cabin doesn't move so this never needs to
	// be refreshed.
	locked_area = get_area(src)
	// Start the cabin's tick loop. 1s granularity is plenty.
	main_tick_timer_id = addtimer(CALLBACK(src, PROC_REF(MainTick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	// Seed AoE timers so the first attacks land a couple seconds in.
	next_bone_stab    = world.time + 6 SECONDS
	next_bladed_teeth = world.time + 4 SECONDS
	next_ice_spike    = world.time + 10 SECONDS

/mob/living/simple_animal/hostile/snow_cabin/Destroy()
	deltimer(main_tick_timer_id)
	CleanupArena()
	return ..()

/mob/living/simple_animal/hostile/snow_cabin/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/Move()
	return FALSE

// ---------- Invulnerable to all direct player attacks ----------
// The cabin's HP only moves via weakpoint deaths feeding adjustBruteLoss.
// Block every "player hits the cabin" vector — melee, items, projectiles —
// silently. damage_coeff already zeros the four LC13 types for any AoE
// damage path that uses deal_damage.

/mob/living/simple_animal/hostile/snow_cabin/attack_hand(mob/living/carbon/human/M)
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/attack_paw(mob/living/carbon/human/M)
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/attackby(obj/item/I, mob/living/user, params)
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/bullet_act(obj/projectile/P, def_zone, piercing_hit)
	return BULLET_ACT_BLOCK

// ---------- Main tick ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/MainTick()
	if(QDELETED(src) || stat == DEAD)
		return
	if(!HasActivePlayers())
		return
	// Weakpoint spawning — refill toward the phase's targets every tick.
	// One per tick keeps the initial fill from being a burst, and means a
	// killed weakpoint is replaced within ~1 second.
	if(length(active_eyes) < GetEyeTarget())
		SpawnEye()
	if(length(active_mouths) < GetMouthTarget())
		SpawnMouth()
	// Phase 2 hatching events. The minion cap is checked against
	// (alive minions of that type) + (pending pods/prisons of that type)
	// so the cap survives the whole spawn → hatch → death cycle.
	if(phase == 2)
		if(world.time >= next_meatpod_spawn \
			&& length(active_meatpods) < meatpod_cap \
			&& (CountActiveMeatlings() + length(active_meatpods)) < meatling_cap)
			SpawnMeatpod()
			next_meatpod_spawn = world.time + meatpod_spawn_interval
		if(world.time >= next_ice_prison_spawn \
			&& length(active_ice_prisons) < ice_prison_cap \
			&& (CountActiveYagaslaves() + length(active_ice_prisons)) < yagaslave_cap)
			SpawnIcePrison()
			next_ice_prison_spawn = world.time + ice_prison_spawn_interval
	// AoE attacks. Bone Stab Line and Bladed Teeth keep their raw
	// cooldowns in Phase 2 — their Phase 2 buff is bigger area, not
	// faster firing. Ice Spike and Ice Shard Spray still get the
	// ×phase_2_cooldown_factor reduction.
	if(world.time >= next_bone_stab)
		INVOKE_ASYNC(src, PROC_REF(BoneStabLine))
		next_bone_stab = world.time + bone_stab_cooldown
	if(world.time >= next_bladed_teeth)
		INVOKE_ASYNC(src, PROC_REF(BladedTeeth))
		next_bladed_teeth = world.time + bladed_teeth_cooldown
	if(world.time >= next_ice_spike)
		INVOKE_ASYNC(src, PROC_REF(IceSpike))
		next_ice_spike = world.time + CooldownScaled(ice_spike_cooldown)
	if(phase == 2 && world.time >= next_ice_shard)
		INVOKE_ASYNC(src, PROC_REF(IceShardSpray))
		next_ice_shard = world.time + CooldownScaled(ice_shard_cooldown)

/mob/living/simple_animal/hostile/snow_cabin/proc/CooldownScaled(base)
	if(phase == 2)
		return round(base * phase_2_cooldown_factor)
	return base

/mob/living/simple_animal/hostile/snow_cabin/proc/GetEyeTarget()
	return (phase == 2) ? eye_target_phase_2 : eye_target_phase_1

/mob/living/simple_animal/hostile/snow_cabin/proc/GetMouthTarget()
	return (phase == 2) ? mouth_target_phase_2 : mouth_target_phase_1

/mob/living/simple_animal/hostile/snow_cabin/proc/HasActivePlayers()
	for(var/mob/living/carbon/human/H in range(arena_range, src))
		if(H.stat == DEAD)
			continue
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/proc/CountActiveMeatlings()
	var/n = 0
	for(var/mob/M as anything in active_minions)
		if(istype(M, /mob/living/simple_animal/hostile/cabin_meatling) && M.stat != DEAD)
			n++
	return n

/mob/living/simple_animal/hostile/snow_cabin/proc/CountActiveYagaslaves()
	var/n = 0
	for(var/mob/M as anything in active_minions)
		if(istype(M, /mob/living/simple_animal/hostile/cabin_yagaslave) && M.stat != DEAD)
			n++
	return n

/// Pick one of the cabin's currently-living mouths and have it say `message`.
/// If no mouth is alive, falls back to a whispered visible_message that
/// reaches everyone on the cabin's Z. Pass a list of lines to pick from, or
/// a single string for a fixed line.
/mob/living/simple_animal/hostile/snow_cabin/proc/Speak(message_or_list)
	if(!message_or_list)
		return
	var/message
	if(islist(message_or_list))
		var/list/L = message_or_list
		if(!length(L))
			return
		message = pick(L)
	else
		message = message_or_list
	var/list/candidates = list()
	for(var/mob/living/M as anything in active_mouths)
		if(!QDELETED(M) && M.stat != DEAD)
			candidates += M
	if(length(candidates))
		var/mob/living/speaker = pick(candidates)
		speaker.say(message)
		return
	// No mouth alive — fall back so a line is never silently dropped.
	for(var/mob/living/carbon/human/H in range(arena_range, src))
		to_chat(H, span_warning("The walls whisper: \"[message]\""))

// ---------- Floor tile resolution ----------

/// TRUE if T is a floor the cabin can sprout a weakpoint or hatch event
/// through. Tile must be in the cabin's own area (area-lock prevents
/// cross-arena bleed when multiple arenas share a Z). Snow and ice
/// variants are excluded — the cabin can't pierce them.
/// /turf/open/floor/plating/ice/smooth is a subtype of
/// /turf/open/floor/plating/ice, so the single istype on the parent
/// covers both.
/mob/living/simple_animal/hostile/snow_cabin/proc/IsValidFloorTile(turf/T)
	if(!isopenturf(T))
		return FALSE
	if(locked_area && get_area(T) != locked_area)
		return FALSE
	if(istype(T, /turf/open/floor/holofloor/snow))
		return FALSE
	if(istype(T, /turf/open/floor/plating/ice))
		return FALSE
	return TRUE

/// TRUE if T is a wall the cabin can mount an eye on. Tile must be in
/// the cabin's own area. Fakeglass and the cheap reinforced family are
/// excluded — the eye can't anchor through either.
/mob/living/simple_animal/hostile/snow_cabin/proc/IsValidWallTile(turf/T)
	if(!isclosedturf(T))
		return FALSE
	if(locked_area && get_area(T) != locked_area)
		return FALSE
	if(istype(T, /turf/closed/indestructible/fakeglass))
		return FALSE
	if(istype(T, /turf/closed/indestructible/reinforced/cheap))
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/snow_cabin/proc/GetFloorTiles()
	if(!islist(cached_floor_tiles) || !length(cached_floor_tiles))
		// Snapshot the area-lock once. The cabin can't move, so this
		// captures the arena the boss was placed in and pins every
		// future validator call to it.
		if(!locked_area)
			locked_area = get_area(src)
		cached_floor_tiles = list()
		for(var/turf/T in Z_TURFS(z))
			if(!IsValidFloorTile(T))
				continue
			if(get_dist(src, T) > weakpoint_spawn_range)
				continue
			cached_floor_tiles += T
	return cached_floor_tiles

/mob/living/simple_animal/hostile/snow_cabin/proc/GetWallTiles()
	if(!islist(cached_wall_tiles) || !length(cached_wall_tiles))
		if(!locked_area)
			locked_area = get_area(src)
		cached_wall_tiles = list()
		for(var/turf/T in Z_TURFS(z))
			if(!IsValidWallTile(T))
				continue
			if(get_dist(src, T) > weakpoint_spawn_range)
				continue
			cached_wall_tiles += T
	return cached_wall_tiles

/mob/living/simple_animal/hostile/snow_cabin/proc/PickRandomFloorTile()
	var/list/tiles = GetFloorTiles()
	if(!length(tiles))
		return null
	return pick(tiles)

/mob/living/simple_animal/hostile/snow_cabin/proc/PickRandomFloorTileWithoutLandmark()
	// For mouth / meatpod / ice-prison spawns: reject tiles within
	// weakpoint_min_spacing of an existing eye OR mouth, and tiles
	// already hosting a hatching event. Falls through to any floor tile
	// if the spacing rule wipes the pool clean.
	var/list/tiles = GetFloorTiles()
	if(!length(tiles))
		return null
	var/list/clean = list()
	for(var/turf/T in tiles)
		if(TileTooCloseToWeakpoint(T) || TileHasHatchEvent(T))
			continue
		clean += T
	if(!length(clean))
		return pick(tiles)
	return pick(clean)

/mob/living/simple_animal/hostile/snow_cabin/proc/PickRandomWallTileWithoutEye()
	// For eye spawns: reject walls within weakpoint_min_spacing of any
	// existing eye OR mouth so weakpoints don't clump.
	var/list/tiles = GetWallTiles()
	if(!length(tiles))
		return null
	var/list/clean = list()
	for(var/turf/T in tiles)
		if(TileTooCloseToWeakpoint(T))
			continue
		clean += T
	if(!length(clean))
		return pick(tiles)
	return pick(clean)

/// TRUE if any active eye or mouth sits within weakpoint_min_spacing of T
/// (chebyshev distance). Used by both pickers to keep weakpoints spread out.
/mob/living/simple_animal/hostile/snow_cabin/proc/TileTooCloseToWeakpoint(turf/T)
	if(!T)
		return FALSE
	for(var/mob/living/M as anything in active_eyes)
		if(get_dist(T, get_turf(M)) <= weakpoint_min_spacing)
			return TRUE
	for(var/mob/living/M as anything in active_mouths)
		if(get_dist(T, get_turf(M)) <= weakpoint_min_spacing)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/snow_cabin/proc/TileHasHatchEvent(turf/T)
	for(var/obj/effect/snow_cabin_meatpod/P as anything in active_meatpods)
		if(get_turf(P) == T)
			return TRUE
	for(var/obj/effect/snow_cabin_ice_prison/I as anything in active_ice_prisons)
		if(get_turf(I) == T)
			return TRUE
	return FALSE

// ---------- Weakpoint spawning ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/SpawnEye()
	// Eyes are mounted on the wood walls, not the hotelwood floor.
	var/turf/T = PickRandomWallTileWithoutEye()
	if(!T)
		return
	var/mob/living/simple_animal/hostile/snow_cabin_eye/E = new(T, src)
	active_eyes += E

/mob/living/simple_animal/hostile/snow_cabin/proc/SpawnMouth()
	var/turf/T = PickRandomFloorTileWithoutLandmark()
	if(!T)
		return
	var/mob/living/simple_animal/hostile/snow_cabin_mouth/M = new(T, src)
	active_mouths += M

/mob/living/simple_animal/hostile/snow_cabin/proc/SpawnMeatpod()
	var/turf/T = PickRandomFloorTileWithoutLandmark()
	if(!T)
		return
	var/obj/effect/snow_cabin_meatpod/P = new(T, src)
	active_meatpods += P

/mob/living/simple_animal/hostile/snow_cabin/proc/SpawnIcePrison()
	var/turf/T = PickRandomFloorTileWithoutLandmark()
	if(!T)
		return
	var/obj/effect/snow_cabin_ice_prison/I = new(T, src)
	active_ice_prisons += I

// ---------- Weakpoint death callbacks ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/OnEyeKilled(mob/living/M)
	active_eyes -= M
	BleedCabin(M.maxHealth)

/mob/living/simple_animal/hostile/snow_cabin/proc/OnMouthKilled(mob/living/M)
	active_mouths -= M
	BleedCabin(M.maxHealth)

/// Applies BRUTE damage to the cabin equal to the killed weakpoint's
/// maxHealth, then checks for the Phase 2 transition. Death is handled by
/// the normal simple_animal health-zero path (adjustBruteLoss → updatehealth
/// → death) — no manual death() call required.
/mob/living/simple_animal/hostile/snow_cabin/proc/BleedCabin(amount)
	if(stat == DEAD)
		return
	adjustBruteLoss(amount)
	if(phase == 1 && health <= maxHealth * phase_2_threshold)
		EnterPhase2()

/mob/living/simple_animal/hostile/snow_cabin/proc/EnterPhase2()
	phase = 2
	Speak(lines_phase_2)
	// Seed Phase 2 spawn timers so the new events don't all fire at once.
	next_meatpod_spawn    = world.time + 5 SECONDS
	next_ice_prison_spawn = world.time + 8 SECONDS
	next_ice_shard        = world.time + 12 SECONDS

// ---------- AoE: Bone Stab Line ----------

/// Dispatcher. Phase 1 fires one wall-to-wall sweep in a random cardinal
/// direction. Phase 2 fires two perpendicular sweeps at the same time —
/// one on the N–S axis, one on the E–W axis — slicing the room with an X.
/mob/living/simple_animal/hostile/snow_cabin/proc/BoneStabLine()
	var/list/floor = GetFloorTiles()
	if(!length(floor))
		return
	// Arena bounds — derived from the floor cache so the sweep runs from
	// wall to wall regardless of room shape.
	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY
	for(var/turf/T as anything in floor)
		if(T.x < min_x)
			min_x = T.x
		if(T.x > max_x)
			max_x = T.x
		if(T.y < min_y)
			min_y = T.y
		if(T.y > max_y)
			max_y = T.y
	Speak(lines_bone_stab)
	if(phase == 2)
		var/v_dir = pick(NORTH, SOUTH)
		var/h_dir = pick(EAST, WEST)
		INVOKE_ASYNC(src, PROC_REF(SweepBoneSpikes), v_dir, min_x, max_x, min_y, max_y)
		INVOKE_ASYNC(src, PROC_REF(SweepBoneSpikes), h_dir, min_x, max_x, min_y, max_y)
	else
		var/dir = pick(NORTH, SOUTH, EAST, WEST)
		INVOKE_ASYNC(src, PROC_REF(SweepBoneSpikes), dir, min_x, max_x, min_y, max_y)

/// One sweep. Picks a 3-wide perpendicular stripe, paints the warning
/// across the whole path, waits bone_stab_windup, then raises one
/// 1×3 / 3×1 chunk every bone_stab_chunk_delay deciseconds.
/mob/living/simple_animal/hostile/snow_cabin/proc/SweepBoneSpikes(direction, min_x, max_x, min_y, max_y)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/chunks = list()
	var/list/all_tiles = list()
	if(direction == NORTH || direction == SOUTH)
		// Sweep along the Y axis; the perpendicular stripe is 3 wide on X.
		if(max_x - min_x < 2)
			return
		var/center_x = rand(min_x + 1, max_x - 1)
		var/list/y_values = list()
		for(var/y in min_y to max_y)
			if(direction == NORTH)
				y_values += y
			else
				y_values.Insert(1, y)
		for(var/y in y_values)
			var/list/chunk = list()
			for(var/dx in -1 to 1)
				var/turf/T = locate(center_x + dx, y, z)
				if(IsValidFloorTile(T))
					chunk += T
					all_tiles += T
			if(length(chunk))
				chunks += list(chunk)
	else
		// EAST/WEST: sweep along the X axis; stripe is 3 tall on Y.
		if(max_y - min_y < 2)
			return
		var/center_y = rand(min_y + 1, max_y - 1)
		var/list/x_values = list()
		for(var/x in min_x to max_x)
			if(direction == EAST)
				x_values += x
			else
				x_values.Insert(1, x)
		for(var/x in x_values)
			var/list/chunk = list()
			for(var/dy in -1 to 1)
				var/turf/T = locate(x, center_y + dy, z)
				if(IsValidFloorTile(T))
					chunk += T
					all_tiles += T
			if(length(chunk))
				chunks += list(chunk)
	if(!length(chunks))
		return
	// Telegraph: paint the entire stripe up-front so players can read it.
	for(var/turf/T as anything in all_tiles)
		var/obj/effect/temp_visual/snow_cabin_bone_stab_warning/W = new(T, bone_stab_windup)
		W.setDir(direction)
	SLEEP_CHECK_DEATH(bone_stab_windup)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 70, TRUE)
	// Wave: raise one chunk at a time, sleeping bone_stab_chunk_delay
	// between chunks so the spikes visibly march across the room.
	for(var/list/chunk as anything in chunks)
		if(QDELETED(src) || stat == DEAD)
			return
		if(length(chunk))
			playsound(chunk[1], 'sound/abnormalities/ebonyqueen/attack.ogg', 50, TRUE)
		for(var/turf/T as anything in chunk)
			new /obj/effect/temp_visual/snow_cabin_bone_stab(T)
			for(var/mob/living/L in T)
				if(faction_check_mob(L))
					continue
				if(!ishuman(L))
					continue
				L.deal_damage(bone_stab_damage, RED_DAMAGE, src,
					attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		if(bone_stab_chunk_delay > 0)
			sleep(bone_stab_chunk_delay)

// ---------- AoE: Bladed Teeth ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/BladedTeeth()
	// Cover a fraction of the entire floor — 25% in Phase 1, 40% in Phase 2.
	var/list/floor = GetFloorTiles()
	if(!length(floor))
		return
	var/coverage = (phase == 2) ? bladed_teeth_phase_2_coverage : bladed_teeth_phase_1_coverage
	var/count = round(length(floor) * coverage)
	if(count <= 0)
		return
	var/list/pool = floor.Copy()
	var/list/picks = list()
	for(var/i in 1 to count)
		if(!length(pool))
			break
		var/turf/T = pick_n_take(pool)
		picks += T
		new /obj/effect/temp_visual/snow_cabin_warning(T, bladed_teeth_windup)
	Speak(lines_bladed_teeth)
	SLEEP_CHECK_DEATH(bladed_teeth_windup)
	playsound(get_turf(src), 'sound/weapons/bite.ogg', 50, TRUE)
	for(var/turf/T as anything in picks)
		new /obj/effect/temp_visual/snow_cabin_bladed_teeth(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			if(!ishuman(L))
				continue
			L.deal_damage(bladed_teeth_damage, RED_DAMAGE, src,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

// ---------- AoE: Ice Spike ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/IceSpike()
	var/mob/living/carbon/human/target = PickRandomPlayer()
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	// Collect the 3×3 affected tiles up-front. The "rise" animation alone
	// was only ~0.4s and felt unreadable, so the telegraph now uses the
	// shaking-ice-shards warning for ice_spike_windup deciseconds.
	var/list/area_turfs = list()
	for(var/turf/T in range(1, center))
		if(!istype(T, /turf/open))
			continue
		area_turfs += T
		new /obj/effect/temp_visual/snow_cabin_ice_shard_warning(T, ice_spike_windup)
	Speak(lines_ice_spike)
	SLEEP_CHECK_DEATH(ice_spike_windup)
	// Pick a variant (spikes vs rupture) for visual variety at strike time.
	var/use_rupture = prob(50)
	var/strike_type = use_rupture ? /obj/effect/temp_visual/snow_cabin_ice_rupture : /obj/effect/temp_visual/snow_cabin_ice_spike
	playsound(center, 'sound/effects/glassbr1.ogg', 60, TRUE)
	for(var/turf/T as anything in area_turfs)
		new strike_type(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			if(!ishuman(L))
				continue
			L.deal_damage(ice_spike_damage, PALE_DAMAGE, src,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

// ---------- AoE: Ice Shard Spray ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/IceShardSpray()
	// Wider but still centered: sample within ice_shard_radius of a player.
	var/mob/living/carbon/human/target = PickRandomPlayer()
	if(!target)
		return
	var/turf/center = get_turf(target)
	if(!center)
		return
	var/list/pool = list()
	for(var/turf/T in range(ice_shard_radius, center))
		if(IsValidFloorTile(T))
			pool += T
	if(!length(pool))
		return
	var/count = rand(ice_shard_count_min, ice_shard_count_max)
	var/list/picks = list()
	for(var/i in 1 to count)
		if(!length(pool))
			break
		var/turf/T = pick_n_take(pool)
		picks += T
		new /obj/effect/temp_visual/snow_cabin_ice_shard_warning(T, ice_shard_windup)
	Speak(lines_ice_shard)
	SLEEP_CHECK_DEATH(ice_shard_windup)
	playsound(get_turf(src), 'sound/effects/glassbr3.ogg', 70, TRUE)
	for(var/turf/T as anything in picks)
		new /obj/effect/temp_visual/snow_cabin_ice_shards(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			if(!ishuman(L))
				continue
			L.deal_damage(ice_shard_damage, PALE_DAMAGE, src,
				attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

// ---------- Player targeting ----------

/mob/living/simple_animal/hostile/snow_cabin/proc/PickRandomPlayer()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in range(arena_range, src))
		if(H.stat == DEAD)
			continue
		candidates += H
	if(!length(candidates))
		return null
	return pick(candidates)

// ---------- Death / cleanup ----------

/mob/living/simple_animal/hostile/snow_cabin/death(gibbed)
	. = ..()
	// Announce + scatter a few more meat_crack decals as the room "rots open."
	for(var/mob/living/carbon/human/H in range(arena_range, src))
		to_chat(H, span_userdanger("The cabin breaks apart around you."))
	var/list/floor = GetFloorTiles()
	for(var/i in 1 to min(8, length(floor)))
		var/turf/T = pick(floor)
		new /obj/effect/snow_cabin_meat_crack(T, src)
	CleanupArena()

/mob/living/simple_animal/hostile/snow_cabin/proc/CleanupArena()
	for(var/mob/living/M as anything in active_eyes)
		if(!QDELETED(M))
			qdel(M)
	active_eyes.Cut()
	for(var/mob/living/M as anything in active_mouths)
		if(!QDELETED(M))
			qdel(M)
	active_mouths.Cut()
	for(var/obj/effect/snow_cabin_meatpod/P as anything in active_meatpods)
		if(!QDELETED(P))
			qdel(P)
	active_meatpods.Cut()
	for(var/obj/effect/snow_cabin_ice_prison/I as anything in active_ice_prisons)
		if(!QDELETED(I))
			qdel(I)
	active_ice_prisons.Cut()
	for(var/mob/living/M as anything in active_minions)
		if(!QDELETED(M))
			qdel(M)
	active_minions.Cut()
	// Meat cracks fade out at staggered intervals so the room "rots
	// closed" rather than vanishing all at once. Mirrors the vine-fade
	// pattern in snow_whites_apple.dm:132-139.
	for(var/obj/effect/snow_cabin_meat_crack/C as anything in active_meat_cracks)
		if(QDELETED(C))
			continue
		var/del_time = rand(3, 8)
		animate(C, alpha = 0, time = del_time SECONDS)
		QDEL_IN(C, del_time SECONDS)
	active_meat_cracks.Cut()

// ---------- Refraction tuning subtype ----------

/mob/living/simple_animal/hostile/snow_cabin/refracted
	// Left empty for refraction-railway tuning. Override any var here
	// (eye_target_phase_2, bone_stab_damage, mouth_open_duration, etc.) to
	// retune the fight without touching shared logic.
