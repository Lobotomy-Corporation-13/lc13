// ==========================================================
// Sea Terrors - Mob Pack
// Includes: Nervous Impairment, Nethersea Brand, 4 Mobs
// ==========================================================

// ==================== STATUS EFFECTS ====================

/// Nervous Impairment - Stacking debuff from Sea Terror mobs.
/// At 30 stacks: 25% maxHP BRUTE damage + 5 second stun, then removed.
/datum/status_effect/stacking/nervous_impairment
	id = "nervous_impairment"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = -1
	tick_interval = 20 SECONDS
	stack_decay = 0
	max_stacks = 30
	stack_threshold = 30
	consumed_on_threshold = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/nervous_impairment
	/// Custom overlay showing impairment severity (impairment_0 through impairment_7)
	var/mutable_appearance/impairment_overlay
	/// Tracks whether new stacks were gained since the last tick
	var/gained_stacks = TRUE

/atom/movable/screen/alert/status_effect/nervous_impairment
	name = "Nervous Impairment"
	desc = "The nethersea gnaws at your nerves... Stacks: "
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "nervous_impairment"

/datum/status_effect/stacking/nervous_impairment/on_apply()
	. = ..()
	if(!.)
		return
	impairment_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/status_sprites.dmi', "impairment_0")
	impairment_overlay.alpha = 100
	owner.add_overlay(impairment_overlay)

/datum/status_effect/stacking/nervous_impairment/tick()
	if(!can_have_status())
		qdel(src)
		return
	if(!gained_stacks)
		qdel(src)
		return
	gained_stacks = FALSE

/datum/status_effect/stacking/nervous_impairment/add_stacks(stacks_added)
	if(stacks_added > 0)
		gained_stacks = TRUE
		new /obj/effect/temp_visual/damage_effect/nervous_impairment(get_turf(owner))
	if(owner && impairment_overlay)
		owner.cut_overlay(impairment_overlay)
	. = ..()
	// After parent add_stacks, status may have been consumed and qdel'd
	if(owner && impairment_overlay && stacks > 0)
		var/threshold = max_stacks * 0.875
		var/level = min(7, round(stacks * 7 / threshold))
		impairment_overlay.icon_state = "impairment_[level]"
		owner.add_overlay(impairment_overlay)

/datum/status_effect/stacking/nervous_impairment/Destroy()
	if(owner && impairment_overlay)
		owner.cut_overlay(impairment_overlay)
	impairment_overlay = null
	return ..()

/datum/status_effect/stacking/nervous_impairment/stacks_consumed_effect()
	if(!owner)
		return
	var/damage = owner.maxHealth * 0.25
	owner.deal_damage(damage, BRUTE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
	owner.Stun(50)
	playsound(get_turf(owner), 'sound/weapons/ego/shattering_window.ogg', 50, 1)
	new /obj/effect/temp_visual/weapon_stun(get_turf(owner))
	to_chat(owner, span_userdanger("Your nervous system seizes up from the nethersea's influence!"))

/// Helper proc to apply Nervous Impairment stacks to a mob
/mob/living/proc/apply_nervous_impairment(stacks_to_add)
	if(IsStun())
		return
	var/datum/status_effect/stacking/nervous_impairment/S = has_status_effect(/datum/status_effect/stacking/nervous_impairment)
	if(!S)
		apply_status_effect(/datum/status_effect/stacking/nervous_impairment, stacks_to_add)
		return
	S.add_stacks(stacks_to_add)

/// Nethersea Exposure - Applied when a carbon stands on a Nethersea Brand.
/// Ticks every 5 seconds: 5% maxHP BRUTE + 3 Nervous Impairment stacks.
/// Shared across brand instances - moving between brands keeps the cooldown.
/datum/status_effect/nethersea_exposure
	id = "nethersea_exposure"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 5 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/nethersea_exposure

/atom/movable/screen/alert/status_effect/nethersea_exposure
	name = "Nethersea Exposure"
	desc = "The nethersea brand burns beneath your feet."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "nethersea_exposure"

/datum/status_effect/nethersea_exposure/tick()
	if(!owner || owner.stat == DEAD)
		qdel(src)
		return
	if(!locate(/obj/structure/spreading/nethersea_brand) in get_turf(owner))
		qdel(src)
		return
	var/damage = owner.maxHealth * 0.05
	owner.deal_damage(damage, BRUTE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
	owner.apply_nervous_impairment(3)
	to_chat(owner, span_warning("The nethersea brand sears into your flesh!"))

// ==================== STRUCTURES ====================

/// Nethersea Brand - Spreading ground hazard that damages carbons standing on it.
/obj/structure/spreading/nethersea_brand
	name = "nethersea brand"
	desc = "A dark, pulsing mark left by creatures of the deep sea. It burns to stand on."
	icon = 'icons/obj/smooth_structures/alien/weeds1.dmi'
	icon_state = "weeds1-15"
	pixel_x = -4
	pixel_y = -4
	alpha = 120
	max_integrity = 50
	expand_cooldown = 2 SECONDS

/obj/structure/spreading/nethersea_brand/Initialize()
	. = ..()
	for(var/mob/living/carbon/C in loc)
		if(!C.has_status_effect(/datum/status_effect/nethersea_exposure))
			C.apply_status_effect(/datum/status_effect/nethersea_exposure)

/obj/structure/spreading/nethersea_brand/Crossed(atom/movable/AM)
	. = ..()
	if(iscarbon(AM))
		var/mob/living/carbon/C = AM
		if(!C.has_status_effect(/datum/status_effect/nethersea_exposure))
			C.apply_status_effect(/datum/status_effect/nethersea_exposure)

/// Nethersea Brand Node - Spawned by Nethersea Founder on death.
/// Indestructible for 5 seconds, processes expansion to a 7 tile range.
/obj/structure/spreading/nethersea_brand/node
	name = "nethersea brand nexus"
	desc = "The epicenter of a nethersea brand. It pulses with deep sea energy."
	resistance_flags = INDESTRUCTIBLE
	can_expand = FALSE
	/// Range in tiles the brand will spread to
	var/brand_range = 7
	/// Failsafe time to stop processing
	var/stop_processing_time

/obj/structure/spreading/nethersea_brand/node/Initialize()
	. = ..()
	stop_processing_time = world.time + 30 SECONDS
	START_PROCESSING(SSobj, src)
	addtimer(CALLBACK(src, PROC_REF(make_destructible)), 5 SECONDS)

/obj/structure/spreading/nethersea_brand/node/process()
	if(world.time > stop_processing_time)
		STOP_PROCESSING(SSobj, src)
		return
	// Expand all regular brands in range
	for(var/obj/structure/spreading/nethersea_brand/B in range(brand_range, src))
		if(B == src || !B.can_expand)
			continue
		if(get_dist(src, B) >= brand_range)
			B.can_expand = FALSE
			continue
		if(B.last_expand <= world.time)
			B.expand()
	// Expand from the node's own position, creating regular brands
	if(last_expand <= world.time)
		last_expand = world.time + expand_cooldown
		var/turf/U = get_turf(src)
		if(!U)
			return
		var/list/spread_turfs = U.reachableAdjacentTurfs()
		shuffle_inplace(spread_turfs)
		for(var/turf/T in spread_turfs)
			var/obj/machinery/M = locate(/obj/machinery) in T
			if(M && M.density)
				continue
			if(locate(/obj/structure/spreading/nethersea_brand) in T)
				continue
			if(is_type_in_typecache(T, blacklisted_turfs))
				continue
			new /obj/structure/spreading/nethersea_brand(T)
			break

/// Removes INDESTRUCTIBLE flag after the initial 5 seconds
/obj/structure/spreading/nethersea_brand/node/proc/make_destructible()
	resistance_flags &= ~INDESTRUCTIBLE

/obj/structure/spreading/nethersea_brand/node/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

// ==================== NETHERSEA CRACK ====================

/// Nethersea Crack - A hole in the ground that spawns Sea Terror mobs
/// and spreads Nethersea Brand. Collapses when all spawns are exhausted.
/obj/structure/nethersea_crack
	name = "nethersea crack"
	desc = "A crack in the ground oozing with deep sea energy. Creatures stir within."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors32x32.dmi'
	icon_state = "deep_crack"
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	resistance_flags = INDESTRUCTIBLE
	/// Max total units this crack can spawn over its lifetime
	var/max_spawns = 6
	/// Max units alive at the same time
	var/max_alive = 2
	/// How many units have been spawned so far
	var/spawned_total = 0
	/// List of currently tracked spawned mobs
	var/list/spawned_mobs = list()
	/// Weighted list of mob types to spawn
	var/list/spawnable_types = list(
		/mob/living/simple_animal/hostile/sea_terror/slider = 3,
		/mob/living/simple_animal/hostile/sea_terror/runner = 2,
	)
	/// Cooldown tracker for mob spawning
	var/spawn_cooldown = 0
	/// Time between spawns
	var/spawn_cooldown_time = 15 SECONDS
	/// Range for brand spreading
	var/brand_range = 3
	/// Cooldown tracker for brand spreading
	var/brand_cooldown = 0
	/// Time between brand spread ticks
	var/brand_cooldown_time = 8 SECONDS
	/// Whether the crack is currently collapsing
	var/collapsing = FALSE

/obj/structure/nethersea_crack/Initialize()
	. = ..()
	emerge()
	spawn_cooldown = world.time + 3 SECONDS
	brand_cooldown = world.time + 2 SECONDS
	START_PROCESSING(SSobj, src)

/obj/structure/nethersea_crack/process()
	if(collapsing)
		return
	// Check for collapse: all spawns used and all mobs dead
	if(spawned_total >= max_spawns)
		cleanup_mob_list()
		if(!length(spawned_mobs))
			collapse()
			return
	// Spread brands
	if(brand_cooldown <= world.time)
		spread_brands()
		brand_cooldown = world.time + brand_cooldown_time
	// Spawn mobs - fill up to max_alive each cooldown
	if(spawn_cooldown <= world.time && spawned_total < max_spawns)
		cleanup_mob_list()
		while(length(spawned_mobs) < max_alive && spawned_total < max_spawns)
			spawn_mob()
		spawn_cooldown = world.time + spawn_cooldown_time

/obj/structure/nethersea_crack/Destroy()
	STOP_PROCESSING(SSobj, src)
	spawned_mobs.Cut()
	return ..()

/// Emergence animation when the crack first appears
/obj/structure/nethersea_crack/proc/emerge()
	alpha = 0
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	animate(src, alpha = 255, time = 5)
	playsound(T, 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 50, 1)
	visible_message(span_bolddanger("A crack opens in the ground, oozing with deep sea energy!"))

/// Collapse animation when all spawns are exhausted
/obj/structure/nethersea_crack/proc/collapse()
	if(collapsing)
		return
	collapsing = TRUE
	STOP_PROCESSING(SSobj, src)
	// Remove all brands in range
	for(var/obj/structure/spreading/nethersea_brand/B in range(brand_range, src))
		animate(B, alpha = 0, time = 1 SECONDS)
		QDEL_IN(B, 1 SECONDS)
	visible_message(span_danger("[src] crumbles and collapses in on itself!"))
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dusk_dig_in.ogg', 50, 1)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))
	animate(src, alpha = 0, time = 1 SECONDS)
	QDEL_IN(src, 1 SECONDS)

/// Removes dead or deleted mobs from the tracked list
/obj/structure/nethersea_crack/proc/cleanup_mob_list()
	for(var/i in length(spawned_mobs) to 1 step -1)
		var/mob/living/M = spawned_mobs[i]
		if(QDELETED(M) || M.stat == DEAD)
			spawned_mobs -= M

/// Spawns a mob from the weighted spawnable_types list with a burrow animation
/obj/structure/nethersea_crack/proc/spawn_mob()
	var/mob_type = pickweight(spawnable_types)
	// Cap founders at 2 alive at a time
	if(ispath(mob_type, /mob/living/simple_animal/hostile/sea_terror/founder))
		var/founder_count = 0
		for(var/mob/living/simple_animal/hostile/sea_terror/founder/F in spawned_mobs)
			founder_count++
		if(founder_count >= 2)
			mob_type = /mob/living/simple_animal/hostile/sea_terror/slider
	var/turf/T = get_turf(src)
	var/list/valid_turfs = list(T)
	for(var/turf/PT in RANGE_TURFS(2, T))
		if(!PT.is_blocked_turf_ignore_climbable())
			valid_turfs |= PT
	var/turf/target = pick(valid_turfs)
	var/mob/living/simple_animal/hostile/sea_terror/M = new mob_type(target)
	M.burrow_out()
	spawned_mobs += M
	spawned_total++

/// Spreads Nethersea Brand on and around the crack
/obj/structure/nethersea_crack/proc/spread_brands()
	// Create brand on own turf if not present
	if(!locate(/obj/structure/spreading/nethersea_brand) in get_turf(src))
		new /obj/structure/spreading/nethersea_brand(get_turf(src))
	// Expand existing brands in range
	for(var/obj/structure/spreading/nethersea_brand/B in range(brand_range, src))
		if(get_dist(src, B) >= brand_range)
			B.can_expand = FALSE
			continue
		if(B.can_expand && B.last_expand <= world.time)
			B.expand()

// --- Level 2: Nethersea Crack ---
/obj/structure/nethersea_crack/medium
	name = "nethersea crack"
	desc = "A sizable crack in the ground. The nethersea's presence grows stronger."
	max_spawns = 20
	max_alive = 5
	brand_range = 5
	spawn_cooldown_time = 12 SECONDS
	spawnable_types = list(
		/mob/living/simple_animal/hostile/sea_terror/slider = 3,
		/mob/living/simple_animal/hostile/sea_terror/runner = 2,
		/mob/living/simple_animal/hostile/sea_terror/founder = 1,
	)

// --- Level 3: Deep Nethersea Crack ---
/obj/structure/nethersea_crack/large
	name = "deep nethersea crack"
	desc = "A massive fissure tearing through the ground. The depths themselves pour through."
	max_spawns = 40
	max_alive = 8
	brand_range = 7
	spawn_cooldown_time = 10 SECONDS
	spawnable_types = list(
		/mob/living/simple_animal/hostile/sea_terror/slider = 3,
		/mob/living/simple_animal/hostile/sea_terror/runner = 3,
		/mob/living/simple_animal/hostile/sea_terror/founder = 2,
		/mob/living/simple_animal/hostile/sea_terror/reaper = 1,
	)

// ==================== BASE MOB ====================

/// Base Sea Terror mob - shared settings for all sea terror creatures.
/mob/living/simple_animal/hostile/sea_terror
	faction = list("sea_terror")
	gender = NEUTER
	melee_damage_type = BLACK_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	del_on_death = TRUE
	death_sound = 'sound/creatures/lc13/sea_terrors/seaterror_death.ogg'
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"

/// Returns TRUE if this mob is standing on a Nethersea Brand
/mob/living/simple_animal/hostile/sea_terror/proc/on_nethersea_brand()
	return locate(/obj/structure/spreading/nethersea_brand) in get_turf(src)

/// Burrow out animation - mob emerges from the ground with smoke and sound
/mob/living/simple_animal/hostile/sea_terror/proc/burrow_out()
	alpha = 0
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	animate(src, alpha = 255, time = 5)
	playsound(T, 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 25, 1)
	visible_message(span_bolddanger("[src] burrows out from the ground!"))

// ==================== DEEP SEA SLIDER ====================

/// Deep Sea Slider - Low HP, inflicts Nervous Impairment on hit.
/// On Nethersea Brand: 2 NI stacks instead of 1.
/mob/living/simple_animal/hostile/sea_terror/slider
	name = "deep sea slider"
	desc = "A sleek, fast-moving creature from the depths of the nethersea."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors32x32.dmi'
	icon_state = "seaslider"
	icon_living = "seaslider"
	maxHealth = 250
	health = 250
	melee_damage_lower = 8
	melee_damage_upper = 10
	move_to_delay = 3
	attack_sound = 'sound/creatures/lc13/sea_terrors/slider_attack.ogg'
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	death_message = "collapses into a dark puddle."

/mob/living/simple_animal/hostile/sea_terror/slider/AttackingTarget(atom/attacked_target)
	. = ..()
	if(. && ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		H.apply_nervous_impairment(on_nethersea_brand() ? 2 : 1)

// ==================== SHELL SEA RUNNER ====================

/// Shell Sea Runner - Very low HP, no density, passes through targets on hit.
/mob/living/simple_animal/hostile/sea_terror/runner
	name = "shell sea runner"
	desc = "A fragile but swift creature that darts through its targets."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors48x32.dmi'
	icon_state = "searunner"
	icon_living = "searunner"
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 100
	health = 100
	melee_damage_lower = 6
	melee_damage_upper = 8
	move_to_delay = 2
	attack_sound = 'sound/creatures/lc13/sea_terrors/runner_attack.ogg'
	attack_verb_continuous = "dashes through"
	attack_verb_simple = "dash through"
	death_message = "shatters into fragments."

/mob/living/simple_animal/hostile/sea_terror/runner/AttackingTarget(atom/attacked_target)
	. = ..()
	if(.)
		var/dir_to_target = get_dir(get_turf(src), get_turf(attacked_target))
		for(var/i = 1 to 2)
			var/turf/T = get_step(get_turf(src), dir_to_target)
			if(!T || T.density)
				return
			if(locate(/obj/structure/window) in T.contents)
				return
			for(var/obj/machinery/door/D in T.contents)
				if(D.density)
					return
			forceMove(T)
			SLEEP_CHECK_DEATH(2)

// ==================== BASIN SEA REAPER ====================

/// Basin Sea Reaper - Tanky mob with Standby/Combat states.
/// Standby: Slow, doesn't attack, moves towards attackers.
/// Combat (after 100 damage): Fast, attacks with NI, periodic pulse ability.
/mob/living/simple_animal/hostile/sea_terror/reaper
	name = "basin sea reaper"
	desc = "A massive creature from the deep basin. It stands eerily still, watching."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors32x32.dmi'
	icon_state = "seareaper"
	icon_living = "seareaper"
	maxHealth = 2500
	health = 2500
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.2)
	melee_damage_lower = 20
	melee_damage_upper = 30
	move_to_delay = 6
	attack_sound = 'sound/creatures/lc13/sea_terrors/reaper_attack.ogg'
	attack_verb_continuous = "cleaves"
	attack_verb_simple = "cleave"
	death_message = "lets out a deep groan before collapsing."
	/// Whether the reaper has entered combat mode
	var/combat_ready = FALSE
	/// Cooldown for the combat pulse ability
	var/combat_ability_cooldown = 0

/mob/living/simple_animal/hostile/sea_terror/reaper/AttackingTarget(atom/attacked_target)
	if(!combat_ready)
		return
	var/brand_bonus = on_nethersea_brand()
	if(brand_bonus)
		extra_damage += 20
	. = ..()
	if(brand_bonus)
		extra_damage -= 20
	if(. && isliving(attacked_target))
		var/mob/living/L = attacked_target
		L.apply_nervous_impairment(brand_bonus ? 4 : 2)

/// Enters combat state - becomes faster, aggressive, turns blue
/mob/living/simple_animal/hostile/sea_terror/reaper/proc/enter_combat()
	if(combat_ready)
		return
	combat_ready = TRUE
	color = "#4488FF"
	ChangeMoveToDelay(2)
	playsound(get_turf(src), 'sound/creatures/lc13/sea_terrors/reaper_scream.ogg', 50, 1)
	visible_message(span_danger("[src] shudders and enters a combat-ready state!"))

/mob/living/simple_animal/hostile/sea_terror/reaper/adjustHealth(amount, updating_health, forced)
	. = ..()
	if(!combat_ready && (maxHealth - health) >= 100)
		enter_combat()

/mob/living/simple_animal/hostile/sea_terror/reaper/Life()
	. = ..()
	if(!.)
		return
	if(!combat_ready)
		return
	if(combat_ability_cooldown > world.time)
		return
	combat_ability_cooldown = world.time + 5 SECONDS
	// Pulse visual and sound
	var/obj/effect/temp_visual/area_heal/pulse = new /obj/effect/temp_visual/area_heal(get_turf(src))
	pulse.color = "#112244"
	playsound(get_turf(src), 'sound/creatures/lc13/sea_terrors/reaper_pulse.ogg', 50, 1)
	// Inflict 3 Nervous Impairment on all visible non-allied mobs with < 15 NI
	for(var/mob/living/L in view(vision_range, src))
		if(L == src)
			continue
		if(faction_check_mob(L))
			continue
		var/datum/status_effect/stacking/nervous_impairment/NI = L.has_status_effect(/datum/status_effect/stacking/nervous_impairment)
		if(NI && NI.stacks >= 15)
			continue
		L.apply_nervous_impairment(3)
	// Gain OLU based on missing HP: 3 stacks per 10% missing HP
	var/missing_hp_chunks = round((maxHealth - health) / (maxHealth * 0.1))
	var/olu_stacks = 3 * missing_hp_chunks
	if(olu_stacks > 0)
		apply_lc_offense_level_up(olu_stacks)
	// Self-damage: 10% of max HP
	adjustHealth(maxHealth * 0.1)

// ==================== NETHERSEA FOUNDER ====================

/// Nethersea Founder - Medium HP, spreads Nethersea Brand on death.
/// On Nethersea Brand: 4 NI stacks instead of 2, +10% damage.
/mob/living/simple_animal/hostile/sea_terror/founder
	name = "nethersea founder"
	desc = "A creature that carries the nethersea's brand within its body."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors32x32.dmi'
	icon_state = "seafounder"
	icon_living = "seafounder"
	maxHealth = 800
	health = 800
	melee_damage_lower = 13
	melee_damage_upper = 16
	move_to_delay = 3
	attack_sound = 'sound/creatures/lc13/sea_terrors/founder_attack.ogg'
	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	death_message = "dissolves, spreading its brand onto the ground."

/mob/living/simple_animal/hostile/sea_terror/founder/AttackingTarget(atom/attacked_target)
	var/brand_bonus = on_nethersea_brand()
	if(brand_bonus)
		extra_damage += 10
	. = ..()
	if(brand_bonus)
		extra_damage -= 10
	if(. && isliving(attacked_target))
		var/mob/living/L = attacked_target
		L.apply_nervous_impairment(brand_bonus ? 4 : 2)

/mob/living/simple_animal/hostile/sea_terror/founder/death(gibbed)
	if(!on_nethersea_brand())
		new /obj/structure/spreading/nethersea_brand/node(get_turf(src))
	return ..()
