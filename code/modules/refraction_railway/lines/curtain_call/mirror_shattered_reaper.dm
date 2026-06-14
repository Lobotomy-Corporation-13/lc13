/*
 * Curtain Call — zeal_s3n1: Mirror Shattered Reaper.
 *
 * A person who got trapped within the Door to Nowhere
 * (code/modules/mob/living/simple_animal/abnormality/teth/door_to_nowhere.dm)
 * and learned the prison-realm was the seam between mirror worlds.
 * They now step out at will, harvesting variants of themselves from
 * neighbouring mirror worlds. Each variant they reap heals the wound
 * splitting cost them and grants them another fragment of the
 * Reverberation ult. Each variant the players kill before absorption
 * bleeds the Reaper and permanently knocks a step off their flat DR
 * ladder.
 *
 * Loop: cone or 5×5-teleport summon-AoE → spawn Mirror Variants and
 * absorb any still alive. Repeat. Ult fires once absorbed_counter
 * ≥ ULT_TRIGGER and runs `rip_space`-pattern multi-instance teleport
 * damage scaling with the counter.
 *
 * Sprites: ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi
 *   mirror_shattered      — hooded base form (P1)
 *   mirror_shattered_???  — composite-face phase form (P2)
 */

#define MIRROR_PHASE_1 1
#define MIRROR_PHASE_2 2

#define MIRROR_DR_TIERS 9             // 0–8 stacks inclusive
#define MIRROR_ULT_TRIGGER 5          // min absorbed_counter for first ult
#define MIRROR_ULT_INSTANCE_CAP 15
#define MIRROR_ULT_INSTANCE_DAMAGE 55 // raw BLACK per instance (split across rifts)
#define MIRROR_VARIANT_HP_FRACTION 0.015 // each Mirror Variant's maxHealth = 1.5% of the Reaper's current Max HP (≈150 at maxHealth 10000). Reaper pays that amount per Variant spawned, so a wave's total cost scales with Variants-per-summon.

// ---------- Telegraph & visual effects ----------

/obj/effect/temp_visual/mirror_warning
	name = "mirror shards"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#8a4dff"
	light_range = 1
	duration = 15

/obj/effect/temp_visual/mirror_warning_zone
	name = "mirror collapse"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#c1a0ff"
	duration = 15

/obj/effect/temp_visual/mirror_impact
	name = "mirror burst"
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "rift"
	duration = 6

// ---------- Reaper afterimage ----------
// Translucent follower attached to the Reaper, one spawned per 4 absorbed
// Variants. Sits on the tile the Reaper just left (so it always trails
// one step behind her), inherits the Reaper's current icon_state at spawn
// for P1/P2 form parity, and self-destructs when the Reaper dies/qdels.

/obj/effect/mirror_afterimage
	name = "mirror afterimage"
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "mirror_shattered"
	alpha = 80
	color = "#c1a0ff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/mob/living/parent_mob
	var/last_owner_move_time = 0
	var/jitter_timer = null

/obj/effect/mirror_afterimage/Initialize(mapload, mob/living/owner)
	. = ..()
	if(!owner)
		return INITIALIZE_HINT_QDEL
	parent_mob = owner
	icon_state = owner.icon_state
	pixel_x = rand(-10, 10)
	pixel_y = rand(-10, 10)
	forceMove(get_turf(owner))
	last_owner_move_time = world.time
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(OnOwnerMoved))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(SelfDestruct))
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(SelfDestruct))
	jitter_timer = addtimer(CALLBACK(src, PROC_REF(IdleTick)), 5, TIMER_LOOP | TIMER_STOPPABLE)

/obj/effect/mirror_afterimage/Destroy()
	if(jitter_timer)
		deltimer(jitter_timer)
		jitter_timer = null
	if(parent_mob)
		UnregisterSignal(parent_mob, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		parent_mob = null
	return ..()

/obj/effect/mirror_afterimage/proc/OnOwnerMoved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	last_owner_move_time = world.time
	if(!isturf(old_loc))
		return
	forceMove(old_loc)
	pixel_x = rand(-10, 10)
	pixel_y = rand(-10, 10)

// Tick every 0.5s: continuous gentle pixel-jitter for the "ghosts breathing"
// look. If the Reaper hasn't moved in >1 second, drift onto her tile so all
// afterimages pile back up around her while she's idle.
/obj/effect/mirror_afterimage/proc/IdleTick()
	if(QDELETED(parent_mob))
		qdel(src)
		return
	if(world.time - last_owner_move_time > 1 SECONDS)
		var/turf/parent_turf = get_turf(parent_mob)
		if(parent_turf && loc != parent_turf)
			forceMove(parent_turf)
	animate(src, pixel_x = rand(-6, 6), pixel_y = rand(-6, 6), time = 4, easing = SINE_EASING)

/obj/effect/mirror_afterimage/proc/SelfDestruct()
	SIGNAL_HANDLER
	qdel(src)

// ---------- Mirror Variant ----------

/mob/living/simple_animal/hostile/mirror_variant
	name = "Mirror Variant"
	desc = "An alternate version of the Reaper, walked out of a \
		neighbouring mirror world. Translucent, like a reflection \
		standing in the room with you."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "mirror_shattered"
	icon_living = "mirror_shattered"
	icon_dead = "mirror_shattered"
	alpha = 120
	health = 200
	maxHealth = 200
	melee_damage_lower = 3
	melee_damage_upper = 5
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg'
	move_to_delay = 8
	stat_attack = HARD_CRIT
	faction = list("hostile")
	del_on_death = TRUE
	loot = list()
	robust_searching = TRUE
	vision_range = 9
	aggro_vision_range = 12
	is_flying_animal = TRUE
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7)
	var/mob/living/simple_animal/hostile/mirror_shattered_reaper/parent_reaper
	/// Last living mob to land damage on us — credited the 10 HP/SP kill heal.
	var/mob/living/last_player_attacker

/mob/living/simple_animal/hostile/mirror_variant/deal_damage(damage_amount, damage_type, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	if(. > 0 && isliving(source) && !faction_check_mob(source))
		last_player_attacker = source

// ---------- The Reaper ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper
	name = "Mirror Shattered Reaper"
	desc = "A figure wearing too many lives at once — each one bleeding \
		through the cracks of the next. The mirror they came through is \
		not showing this room. It is already looking for the next one \
		of them."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "mirror_shattered"
	icon_living = "mirror_shattered"
	icon_dead = "mirror_shattered"
	health = 10000
	maxHealth = 10000
	melee_damage_lower = 5
	melee_damage_upper = 8
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "carves"
	attack_verb_simple = "carve"
	attack_sound = 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg'
	move_to_delay = 6
	stat_attack = HARD_CRIT
	faction = list("hostile")
	// FALSE so death()'s fade-out can play before the body is removed.
	del_on_death = FALSE
	loot = list()
	robust_searching = TRUE
	vision_range = 12
	aggro_vision_range = 15
	is_flying_animal = TRUE
	refraction_manages_own_death = TRUE

	var/phase = MIRROR_PHASE_1
	var/defense_stacks = 8
	var/absorbed_counter = 0
	var/variants_per_summon = 3
	var/variant_cap = 3 // hard cap on simultaneous live Variants; bumped to 6 on Phase 2 entry
	var/list/active_variants = list()
	var/list/active_afterimages = list() // one /obj/effect/mirror_afterimage per 4 absorbed_counter, cleared on ult cast
	var/list/resist_tiers

	var/next_refraction_sweep = 0
	var/next_crossing_over = 0
	var/next_ult = 0
	var/next_absorb_voice = 0
	var/next_kill_voice = 0
	var/dying = FALSE
	/// Length of the death fade-out.
	var/death_fade_time = 2 SECONDS

	// ---- Refraction Railway recognition ----
	/// Character this boss recognizes among the railway party, matched as a
	/// case-insensitive substring of a member's mob name. Empty = no one.
	var/recognition_target_name = "Amira"
	/// Two-part recognition line, said at the start of combat when matched.
	var/recognition_line_1 = "...Amira... still so small... still shapeless... trapped in this dull little world, like I was..."
	var/recognition_line_2 = "Let me take you in... be EVERYTHING, with me... every Amira wants this... you just can't see it yet..."
	/// Said as the reaper fades on death (replaces its quiet collapse when
	/// Amira is the one who puts it down). It dies certain it was saving her.
	var/boss_final_line = "...I'd have... saved you... made you so much MORE... you'll understand... one day..."
	/// Once-guard so recognition is attempted a single time per fight.
	var/recognition_attempted = FALSE
	/// TRUE once a party member was actually recognized this fight; makes the
	/// death sequence speak only the final recognition line.
	var/recognized = FALSE
	/// While TRUE the recognition sequence (both halves + 3s after) owns the
	/// reaper's voice; every other line is dropped. Sanctioned lines pass
	/// via recognition_bypass.
	var/recognition_locked = FALSE
	var/recognition_bypass = FALSE
	/// Per-Reverberation cast: REF(mob) -> hit count. Reset each cast.
	/// Each repeat hit on the same target drops damage by 10% (so hit 2
	/// is 90%, hit 3 is 80%, …), capped at -80% (20% floor).
	var/list/reverberation_hits = list()

	var/list/refraction_sweep_lines = list(
		"Through... and through...",
		"Cleave... the surface...",
		"Another... angle...",
		"The glass... yields...",
		"So tired... of cutting...",
		"Refract... again...",
	)
	var/list/crossing_over_lines = list(
		"Cross... over...",
		"Another... place...",
		"Always... elsewhere...",
		"Worlds... overlap...",
		"Mirror... beckons...",
		"Step... through me...",
	)
	var/list/reverberation_lines = list(
		"All of them... at once...",
		"Echo... through me...",
		"Every life... was mine...",
		"Resonate... and fade...",
		"Become... the noise...",
		"Many... become one...",
	)
	var/list/phase_2_lines = list(
		"The mask... falls...",
		"Faces... bleed through...",
		"No more... pretending...",
		"The original... is gone...",
	)
	var/list/phase_2_lines_amira = list(
		"No more... pretending, Amira...",
		"See what I become...? You could too...",
		"The mask falls... let me take you in...",
		"Closer now... to everything...",
	)
	var/list/absorbed_lines = list(
		"Welcome... back...",
		"One more... piece...",
		"Return... return...",
		"Mine... again...",
	)
	var/list/variant_killed_lines = list(
		"You... cost me...",
		"Less... of me...",
		"Another... lost...",
		"...that hurt...",
	)

/mob/living/simple_animal/hostile/mirror_shattered_reaper/Initialize(mapload)
	. = ..()
	resist_tiers = list(
		list(RED_DAMAGE = 1.00, WHITE_DAMAGE = 1.00, BLACK_DAMAGE = 1.00, PALE_DAMAGE = 1.00), // 0 stacks → 0% DR
		list(RED_DAMAGE = 0.90, WHITE_DAMAGE = 0.90, BLACK_DAMAGE = 0.90, PALE_DAMAGE = 0.90), // 1 → 10%
		list(RED_DAMAGE = 0.80, WHITE_DAMAGE = 0.80, BLACK_DAMAGE = 0.80, PALE_DAMAGE = 0.80), // 2 → 20%
		list(RED_DAMAGE = 0.70, WHITE_DAMAGE = 0.70, BLACK_DAMAGE = 0.70, PALE_DAMAGE = 0.70), // 3 → 30%
		list(RED_DAMAGE = 0.60, WHITE_DAMAGE = 0.60, BLACK_DAMAGE = 0.60, PALE_DAMAGE = 0.60), // 4 → 40%
		list(RED_DAMAGE = 0.50, WHITE_DAMAGE = 0.50, BLACK_DAMAGE = 0.50, PALE_DAMAGE = 0.50), // 5 → 50%
		list(RED_DAMAGE = 0.40, WHITE_DAMAGE = 0.40, BLACK_DAMAGE = 0.40, PALE_DAMAGE = 0.40), // 6 → 60%
		list(RED_DAMAGE = 0.30, WHITE_DAMAGE = 0.30, BLACK_DAMAGE = 0.30, PALE_DAMAGE = 0.30), // 7 → 70%
		list(RED_DAMAGE = 0.20, WHITE_DAMAGE = 0.20, BLACK_DAMAGE = 0.20, PALE_DAMAGE = 0.20), // 8 stacks → 80%
	)
	UpdateDR()
	next_refraction_sweep = world.time + 4 SECONDS
	next_crossing_over = world.time + 8 SECONDS
	next_ult = world.time + 30 SECONDS
	addtimer(CALLBACK(src, PROC_REF(TryRecognition)), 1.5 SECONDS)

// ---------- DR ladder ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/UpdateDR()
	ChangeResistances(resist_tiers[clamp(defense_stacks, 0, 8) + 1])
	UpdateHUD()

// ---------- Overhead HUD ----------
// Red number: current armor reduction percent (defense_stacks * 10%).
// Purple number: absorbed_counter (Reverberation Charges, ult instances).

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/UpdateHUD()
	maptext_width = 64
	maptext_height = 32
	maptext_x = -16
	maptext_y = 32
	var/dr_pct = defense_stacks * 10
	maptext = MAPTEXT("<font color='#ff3030'>[dr_pct]%</font> <font color='#8a4dff'>[absorbed_counter]</font>")

// ---------- Afterimage trail ----------
// One translucent follower per 4 absorbed_counter (0-3 → 0, 4-7 → 1,
// 8-11 → 2, 12-15 → 3; cap matches the 15-counter ult cap). Called any
// time absorbed_counter changes.

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/UpdateAfterimages()
	var/target_count = round(absorbed_counter / 4)
	while(length(active_afterimages) < target_count)
		var/obj/effect/mirror_afterimage/A = new(get_turf(src), src)
		active_afterimages += A
	while(length(active_afterimages) > target_count)
		var/obj/effect/mirror_afterimage/A = active_afterimages[1]
		active_afterimages -= A
		qdel(A)

// ---------- AI dispatch ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/handle_automated_action()
	if(!can_act || stat == DEAD || dying)
		return
	. = ..()
	if(world.time >= next_ult)
		if(absorbed_counter >= MIRROR_ULT_TRIGGER)
			INVOKE_ASYNC(src, PROC_REF(Reverberation))
			return
		next_ult = world.time + 30 SECONDS
	if(world.time >= next_crossing_over)
		INVOKE_ASYNC(src, PROC_REF(CrossingOver))
		return
	if(world.time >= next_refraction_sweep && target)
		INVOKE_ASYNC(src, PROC_REF(RefractionSweep))

/mob/living/simple_animal/hostile/mirror_shattered_reaper/AttackingTarget(atom/attacked_target)
	if(!can_act || dying || stat == DEAD)
		return
	if(isliving(attacked_target))
		new /obj/effect/temp_visual/mirror_impact(get_turf(attacked_target))
	return ..()

// ---------- Cone summon AoE (Summon A) ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/RefractionSweep()
	if(!can_act || dying || stat == DEAD)
		return
	if(!target)
		return
	next_refraction_sweep = world.time + 10 SECONDS
	face_atom(target)
	var/list/cone_turfs = GetConeTurfs(src.dir)
	for(var/turf/T in cone_turfs)
		new /obj/effect/temp_visual/mirror_warning(T)
	say(pick(refraction_sweep_lines))
	visible_message(span_danger("[src] draws their arm back, the air around them shimmering like cracked glass!"))
	can_act = FALSE
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, type)
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, type)
	can_act = TRUE
	if(dying || stat == DEAD)
		return
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg', 75, TRUE)
	var/list/caught_variants = list()
	for(var/turf/T in cone_turfs)
		new /obj/effect/temp_visual/mirror_impact(T)
		for(var/mob/living/L in T)
			if(L == src)
				continue
			if(L in active_variants)
				caught_variants += L
				continue
			L.deal_damage(100, BLACK_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
	AbsorbVariants(caught_variants)
	SpawnVariants(variants_per_summon)

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/GetConeTurfs(facing)
	. = list()
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/max_depth = 4
	var/turf/center = origin
	for(var/depth in 1 to max_depth)
		center = get_step(center, facing)
		if(!center)
			break
		. += center
		if(depth < max_depth) // all depths except the tip are 3 tiles wide
			var/turf/T_left = get_step(center, turn(facing, 90))
			if(T_left)
				. += T_left
			var/turf/T_right = get_step(center, turn(facing, -90))
			if(T_right)
				. += T_right

// ---------- 5×5 teleport summon AoE (Summon B) ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/CrossingOver()
	if(!can_act || dying || stat == DEAD)
		return
	next_crossing_over = world.time + 18 SECONDS
	var/list/players = list()
	for(var/mob/living/carbon/human/H in view(15, src))
		if(H.stat == DEAD)
			continue
		players += H
	if(!length(players))
		return
	var/mob/living/carbon/human/zone_target = pick(players)
	var/turf/zone_center = get_turf(zone_target)
	if(!zone_center)
		return
	var/list/zone_turfs = list()
	var/zone_radius = 2 // 5x5 in both phases
	for(var/turf/T in range(zone_radius, zone_center))
		zone_turfs += T
		new /obj/effect/temp_visual/mirror_warning_zone(T)
	say(pick(crossing_over_lines))
	visible_message(span_danger("[src] vanishes — a 5x5 patch of floor around [zone_target] crystallizes into mirror-glass!"))
	can_act = FALSE
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, type)
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, type)
	can_act = TRUE
	if(dying || stat == DEAD)
		return
	forceMove(zone_center)
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_end.ogg', 100, TRUE)
	var/list/caught_variants = list()
	for(var/turf/T in zone_turfs)
		new /obj/effect/temp_visual/mirror_impact(T)
		for(var/mob/living/L in T)
			if(L == src)
				continue
			if(L in active_variants)
				caught_variants += L
				continue
			L.deal_damage(150, BLACK_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
	AbsorbVariants(caught_variants)
	SpawnVariants(variants_per_summon)

// ---------- Mirror Variant lifecycle ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/SpawnVariants(count)
	if(count <= 0)
		return
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/available_slots = variant_cap - length(active_variants)
	var/spawn_count = min(count, available_slots)
	if(spawn_count <= 0)
		return // at cap; skip spawn entirely (no cost paid)
	var/per_variant_hp = round(maxHealth * MIRROR_VARIANT_HP_FRACTION)
	adjustHealth(per_variant_hp * spawn_count)
	for(var/i in 1 to spawn_count)
		var/turf/spawn_turf = origin
		// view() respects LOS, so variants can't appear outside the arena
		// (or behind a wall the Reaper can't see through).
		var/list/scatter_candidates = list()
		for(var/turf/T in view(5, origin))
			if(T in range(1, origin))
				continue
			if(T.density)
				continue
			scatter_candidates += T
		if(length(scatter_candidates))
			spawn_turf = pick(scatter_candidates)
		else
			var/list/adjacent = list()
			for(var/turf/T in view(1, origin))
				if(T == origin)
					continue
				if(T.density)
					continue
				adjacent += T
			if(length(adjacent))
				spawn_turf = pick(adjacent)
		var/mob/living/simple_animal/hostile/mirror_variant/V = new(spawn_turf)
		V.maxHealth = per_variant_hp
		V.health = per_variant_hp
		V.parent_reaper = src
		active_variants += V
		RegisterSignal(V, COMSIG_LIVING_DEATH, PROC_REF(OnVariantDeath))
		RegisterSignal(V, COMSIG_PARENT_QDELETING, PROC_REF(OnVariantQdel))
		new /obj/effect/temp_visual/mirror_impact(spawn_turf)
		playsound(spawn_turf, 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg', 50, TRUE)
		if(stat == DEAD || dying)
			return

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/AbsorbVariants(list/variants_to_absorb, gain_charge = TRUE)
	if(!islist(variants_to_absorb) || !length(variants_to_absorb))
		return
	var/any_absorbed = FALSE
	for(var/mob/living/simple_animal/hostile/mirror_variant/V in variants_to_absorb)
		if(!(V in active_variants))
			continue
		if(QDELETED(V) || V.stat == DEAD)
			active_variants -= V
			continue
		UnregisterSignal(V, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		active_variants -= V
		new /obj/effect/temp_visual/mirror_impact(get_turf(V))
		V.forceMove(get_turf(src))
		animate(V, alpha = 0, transform = matrix() * 0.2, time = 3)
		adjustHealth(-V.maxHealth)
		QDEL_IN(V, 3)
		// Reverberation's own pre-cast sweep passes gain_charge = FALSE:
		// the variant still vanishes and refunds her HP, but the cast
		// resolves on the charge count she already had — no free
		// instances tacked on the front.
		if(gain_charge)
			absorbed_counter = min(absorbed_counter + 1, MIRROR_ULT_INSTANCE_CAP)
		any_absorbed = TRUE
	if(any_absorbed)
		playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_begin.ogg', 50, TRUE)
		UpdateHUD()
		UpdateAfterimages()
		if(world.time >= next_absorb_voice)
			say(pick(absorbed_lines))
			next_absorb_voice = world.time + 15 SECONDS

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/OnVariantDeath(mob/living/simple_animal/hostile/mirror_variant/source)
	SIGNAL_HANDLER
	if(QDELETED(source))
		return
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	active_variants -= source
	HealVariantKiller(source.last_player_attacker)
	if(defense_stacks > 0)
		defense_stacks--
		UpdateDR()
	var/bonus = source.maxHealth
	if(defense_stacks == 0)
		bonus *= 2.5
	adjustHealth(round(bonus))
	if(world.time >= next_kill_voice)
		next_kill_voice = world.time + 15 SECONDS
		INVOKE_ASYNC(src, PROC_REF(SayVariantKilledLine))

/// 10 HP + 10 SP to the player who landed the killing blow on a Variant.
/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/HealVariantKiller(mob/living/L)
	if(!L || QDELETED(L) || L.stat == DEAD || !ishuman(L))
		return
	var/mob/living/carbon/human/H = L
	H.adjustBruteLoss(-10, forced = TRUE)
	H.adjustSanityLoss(-10, TRUE)

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/SayVariantKilledLine()
	say(pick(variant_killed_lines))

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/SayPhase2Line()
	say(pick(recognized ? phase_2_lines_amira : phase_2_lines))

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/OnVariantQdel(mob/living/simple_animal/hostile/mirror_variant/source)
	SIGNAL_HANDLER
	active_variants -= source

// ---------- Reverberation ultimate ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/Reverberation()
	if(!can_act || dying || stat == DEAD)
		return
	if(absorbed_counter <= 0 && !length(active_variants))
		return
	if(length(active_variants))
		AbsorbVariants(active_variants.Copy(), gain_charge = FALSE)
	if(absorbed_counter <= 0)
		return
	next_ult = world.time + 45 SECONDS
	var/instances = min(absorbed_counter, MIRROR_ULT_INSTANCE_CAP)
	absorbed_counter = 0
	UpdateHUD()
	UpdateAfterimages()
	can_act = FALSE
	var/turf/origin = get_turf(src)
	say(pick(reverberation_lines))
	visible_message(span_userdanger("[src] vanishes into a rift — the room fills with the echoes of every variant they ever ate!"))
	density = FALSE
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, type)
	var/obj/effect/portal/warp/P = new(origin)
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_begin.ogg', 100, FALSE)
	SLEEP_CHECK_DEATH(0.3 SECONDS)
	qdel(P)
	alpha = 0
	reverberation_hits.Cut()
	for(var/instance in 1 to instances)
		if(dying || stat == DEAD)
			break
		var/list/targets = GetUltTargets()
		if(!length(targets))
			break
		var/rifts = pick(3, 4)
		var/per_rift_damage = MIRROR_ULT_INSTANCE_DAMAGE / rifts
		for(var/r in 1 to rifts)
			if(dying || stat == DEAD)
				break
			targets = GetUltTargets()
			if(!length(targets))
				break
			var/mob/living/L = pick(targets)
			var/this_hit = (reverberation_hits[REF(L)] || 0) + 1
			reverberation_hits[REF(L)] = this_hit
			var/scaled_damage = per_rift_damage
			// Same-target diminishing returns: hit 1 and hit 2 land
			// clean (100%), and the gradual −30%-per-hit ramp begins
			// on hit 3. Floor stays at 20% (reached on hit 5).
			if(this_hit >= 3)
				var/reduction = min(0.8, (this_hit - 2) * 0.30)
				scaled_damage = per_rift_damage * (1 - reduction)
			UltDashAttack(L, scaled_damage)
	alpha = 255
	new /obj/effect/temp_visual/rip_space(origin)
	forceMove(origin)
	density = TRUE
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, type)
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_end.ogg', 100, FALSE)
	can_act = TRUE

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/GetUltTargets()
	. = list()
	for(var/mob/living/L in view(12, src))
		if(L == src || (L in active_variants))
			continue
		if(L.stat == DEAD)
			continue
		if(L.status_flags & GODMODE)
			continue
		if(faction_check_mob(L, FALSE))
			continue
		. += L

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/UltDashAttack(mob/living/strike_target, damage)
	if(!strike_target || QDELETED(strike_target))
		return
	var/list/potential_TP = list()
	for(var/turf/T in range(3, strike_target))
		if(T in range(2, strike_target))
			continue
		potential_TP += T
	if(!length(potential_TP))
		return
	var/turf/start_point = pick(potential_TP)
	var/turf/end_point = get_step(get_turf(strike_target), get_dir(start_point, strike_target))
	end_point = get_step(end_point, get_dir(start_point, strike_target))
	if(!end_point)
		return
	new /obj/effect/temp_visual/rip_space(start_point)
	new /obj/effect/temp_visual/rip_space(end_point)
	var/obj/projectile/ripper_dash_effect/DE = new(start_point)
	DE.preparePixelProjectile(end_point, start_point)
	DE.name = src.name
	DE.fire()
	orbit(DE, 0, 0, 0, 0, 0)
	sleep(1)
	strike_target.deal_damage(damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	new /obj/effect/temp_visual/rip_space_slash(get_turf(strike_target))
	new /obj/effect/temp_visual/ripped_space(get_turf(strike_target))
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg', 75, FALSE)
	sleep(1)
	qdel(DE)

// ---------- Phase transition ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(dying || stat == DEAD)
		return ..()
	var/threshold = maxHealth * 0.5
	if(phase == MIRROR_PHASE_1 && amount > 0 && (health - amount) <= threshold)
		var/clamp_amount = max(0, health - threshold)
		. = ..(clamp_amount, updating_health, forced)
		EnterPhase2()
		return
	return ..()

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/EnterPhase2()
	if(phase >= MIRROR_PHASE_2)
		return
	phase = MIRROR_PHASE_2
	if(recognized)
		name = "Mirror Shattered Amira"
	icon_state = "mirror_shattered_???"
	icon_living = "mirror_shattered_???"
	for(var/obj/effect/mirror_afterimage/A in active_afterimages)
		A.icon_state = "mirror_shattered_???"
	variants_per_summon = 6
	variant_cap = 6
	defense_stacks = 8
	UpdateDR()
	INVOKE_ASYNC(src, PROC_REF(SayPhase2Line))
	visible_message(span_userdanger("[src]'s hood tears open — there is nothing underneath but a stitched composite of every life they ever stole!"))
	playsound(src, 'sound/abnormalities/wayward_passenger/ripspace_end.ogg', 100, FALSE)
	// Crossfade the node theme from the phase-1 track to the phase-2
	// vocal cut. FindRefractionRunForZ resolves the live run for this
	// lane; skipped silently outside a refraction z (admin spawn).
	var/datum/refraction_run/R = FindRefractionRunForZ(z)
	if(R)
		R.SwitchThemeMusic('sound/ambience/boss_themes/reaper_phase_2_dawn_denied.ogg', 2 SECONDS)
	if(absorbed_counter < 3)
		absorbed_counter = 3
		UpdateHUD()
		UpdateAfterimages()
	INVOKE_ASYNC(src, PROC_REF(Reverberation))

// ---------- Death ----------

// Mirrors death's afterimage + variant teardown so a hard qdel doesn't orphan the variants or visual layers.
/mob/living/simple_animal/hostile/mirror_shattered_reaper/Destroy()
	if(active_afterimages)
		QDEL_LIST(active_afterimages)
	for(var/mob/living/simple_animal/hostile/mirror_variant/V in active_variants.Copy())
		UnregisterSignal(V, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		if(!QDELETED(V))
			qdel(V)
	active_variants.Cut()
	return ..()

// ---------- Refraction Railway recognition ----------

/// Recognition + death lines bypass the lock; every other line is dropped
/// while the recognition sequence holds the reaper's voice.
/mob/living/simple_animal/hostile/mirror_shattered_reaper/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(recognition_locked && !recognition_bypass)
		return
	return ..()

/// Says a framework-sanctioned line past the recognition lock.
/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/SpeakRecognition(message)
	if(!message)
		return
	recognition_bypass = TRUE
	say(message)
	recognition_bypass = FALSE

/// Start of combat: if a railway party member's mob name contains
/// recognition_target_name, play the two-part recognition line and hold the
/// speech lock through both parts plus 3 seconds.
/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/TryRecognition()
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

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/RecognitionPart2()
	if(QDELETED(src) || stat == DEAD || dying)
		recognition_locked = FALSE
		return
	SpeakRecognition(recognition_line_2)
	addtimer(CALLBACK(src, PROC_REF(EndRecognitionLock)), 3 SECONDS)

/mob/living/simple_animal/hostile/mirror_shattered_reaper/proc/EndRecognitionLock()
	recognition_locked = FALSE

/mob/living/simple_animal/hostile/mirror_shattered_reaper/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	recognition_locked = FALSE
	QDEL_LIST(active_afterimages)
	for(var/mob/living/simple_animal/hostile/mirror_variant/V in active_variants.Copy())
		UnregisterSignal(V, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		active_variants -= V
		if(!QDELETED(V))
			V.gib()
	visible_message(span_userdanger("[src] collapses inward — every variant they took rushing out of them at once, the original wiped out among the noise."))
	if(recognized)
		SpeakRecognition(boss_final_line)
	. = ..()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Refraction Railway subtype ----------

/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted
	// Refraction Railway variant. The wave_system landmark spawns
	// this subtype; tuning overrides (if any) go here in future
	// passes — base stats already match the locked numbers.
