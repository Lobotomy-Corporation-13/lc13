// Void Rangers: Asat Pramad's summoned troops.
//
// Deliberately plain. Every one is a straightforward melee simple animal with
// no overridden behaviour of its own; everything interesting about them comes
// from Asat's orders and the ai_leadership component he carries. They differ
// only in sprite and stat weight.
//
// Faction matters more than usual here. They come up carrying FACTION_ASAT
// alone, which is hostile: sharing it with Asat is what keeps them recruitable
// by his leadership component without making them peaceable toward anyone else.
// Standing them down adds "neutral" and nothing else, which is what humans
// share, so a stood-down ranger harms no one and still answers to him.

/// Faction tying the rangers to Asat, kept whether or not they are stood down.
#define FACTION_ASAT "asat_pramad"

/mob/living/simple_animal/hostile/void_ranger
	name = "void ranger"
	desc = "A shape that does not quite agree with the space around it."
	icon = 'ModularLobotomy/_Lobotomyicons/void_rangers.dmi'
	icon_state = "baryon"
	icon_living = "baryon"
	icon_dead = "baryon_dead"
	butcher_results = list(/obj/item/stack/trace_material/lens = 2, /obj/item/stack/path_material/gloom = 1)
	mob_biotypes = MOB_HUMANOID
	// Hostile unless Asat says otherwise.
	faction = list(FACTION_ASAT)

	maxHealth = 250
	health = 250
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)

	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 12
	melee_damage_upper = 16
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/slash.ogg'
	move_to_delay = 4
	speed = 1
	stat_attack = HARD_CRIT
	// Bodies stay: they have dead sprites and they leave materials behind.
	del_on_death = FALSE
	// Nothing organic comes out of them. Butchering yields Pathstrider
	// materials in place of meat, and the guaranteed meat harvest is cleared
	// outright the way the Fragmentum Touched mobs do it. What they are wound
	// in comes off as violet silk, graded by how heavy the ranger was.
	loot = list()
	guaranteed_butcher_results = null
	silk_results = list(/obj/item/stack/sheet/silk/violet_simple = 1)

	response_help_continuous = "reaches through"
	response_help_simple = "reach through"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"

	// Beam plumbing, off by default. Only the rangers that set `active_state`
	// and `ranged` below actually shoot; the rest stay purely melee.
	ranged_cooldown_time = 5 SECONDS
	minimum_distance = 2
	projectiletype = /obj/projectile/beam/void_ranger
	projectilesound = 'sound/weapons/laser2.ogg'
	/// Charged sprite flicked as the beam goes off. Null on melee rangers.
	var/active_state
	/// Rarity of the materials left behind. The lesser forms leave T1, the
	/// heavier ones T2.
	var/drop_tier = PATH_MAT_T1
/// Leaves Pathstrider materials behind, a little more than a fragmentum mob
/// does. Every dead sprite sits in the same file as its living one, so
/// icon_dead is all that is needed.
/mob/living/simple_animal/hostile/void_ranger/death(gibbed)
	DropMaterials()
	return ..()

/mob/living/simple_animal/hostile/void_ranger/proc/DropMaterials()
	var/turf/T = get_turf(src)
	if(!T)
		return
	// Family is rolled per corpse, so a squad leaves a mixed pile rather than
	// a neat stack of one thing.
	var/list/trace_families = list(
		TRACE_FAMILY_FANG, TRACE_FAMILY_LENS, TRACE_FAMILY_ICHOR, TRACE_FAMILY_WARD)
	var/list/path_families = list(
		PATH_KEY_DESTRUCTION, PATH_KEY_HUNT, PATH_KEY_ERUDITION, PATH_KEY_NIHILITY,
		PATH_KEY_HARMONY, PATH_KEY_PRESERVATION, PATH_KEY_ABUNDANCE)
	var/trace_type = GetPathMatType("trace", pick(trace_families), drop_tier)
	if(trace_type)
		new trace_type(T, rand(4, 7))
	var/path_type = GetPathMatType("path", pick(path_families), drop_tier)
	if(path_type)
		new path_type(T, rand(3, 5))

/// Flashes the charged sprite on the shot, the way the gloom peccatulum does.
/mob/living/simple_animal/hostile/void_ranger/OpenFire()
	if(active_state)
		flick(active_state, src)
	return ..()

// ---- 32x32 forms ----

/mob/living/simple_animal/hostile/void_ranger/baryon
	name = "baryon ranger"
	desc = "A ranger of settled matter, holding its edges together by will alone. It keeps its distance and lets the beam do the walking."
	icon_state = "baryon"
	icon_living = "baryon"
	icon_dead = "baryon_dead"
	ranged = TRUE
	active_state = "baryon_active"
	// Quick, and not built to be hit.
	maxHealth = 120
	health = 120
	move_to_delay = 2.5

/mob/living/simple_animal/hostile/void_ranger/antibaryon
	name = "antibaryon ranger"
	desc = "A ranger wearing its own absence. Looking at it too long is unpleasant."
	icon_state = "antibaryon"
	icon_living = "antibaryon"
	icon_dead = "antibaryon_dead"
	butcher_results = list(/obj/item/stack/trace_material/lens = 2, /obj/item/stack/path_material/gloom = 1)
	ranged = TRUE
	active_state = "antibaryon_active"
	// Slow, and takes a great deal of convincing.
	maxHealth = 250
	health = 250
	move_to_delay = 5
	melee_damage_lower = 14
	melee_damage_upper = 18

// ---- Projectiles ----

/// Seeking bolt. Passes straight through the company rather than stopping on
/// them, so a distorter behind the line does not shoot its own in the back.
/obj/projectile/void_ranger_bolt
	name = "void bolt"
	icon_state = "declone"
	damage = 14
	damage_type = BLACK_DAMAGE
	speed = 1.4
	range = 12
	projectile_piercing = PASSMOB
	homing_turn_speed = 20

/obj/projectile/void_ranger_bolt/fire(setAngle)
	if(isliving(original))
		set_homing_target(original)
	return ..()

/obj/projectile/void_ranger_bolt/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(isliving(target) && isliving(firer))
		var/mob/living/hit = target
		var/mob/living/shooter = firer
		if(hit != shooter && shooter.faction_check_mob(hit))
			return FALSE
	return ..()



/// Modelled on the gloom peccatulum's water jet, but it lands as BLACK damage.
/// Damage is set in on_hit rather than up front for the same reason the
/// original does it: the nodamage var does not behave for hitscan beams.
/obj/projectile/beam/void_ranger
	name = "void lance"
	icon_state = "snapshot"
	hitsound = null
	damage = 0
	damage_type = BLACK_DAMAGE
	hitscan = TRUE
	projectile_piercing = PASSMOB
	muzzle_type = /obj/effect/projectile/muzzle/laser/snapshot
	tracer_type = /obj/effect/projectile/tracer/laser/snapshot
	impact_type = /obj/effect/projectile/impact/laser/snapshot
	wound_bonus = -100
	bare_wound_bonus = -100
	/// Damage applied on a landed hit.
	var/beam_damage = 10

/obj/projectile/beam/void_ranger/on_hit(atom/target, blocked = FALSE)
	// Never shoot our own, including Asat.
	if(isliving(target) && isliving(firer))
		var/mob/living/hit = target
		var/mob/living/shooter = firer
		if(faction_check(shooter.faction, hit.faction, FALSE))
			return
	damage = beam_damage
	. = ..()
	qdel(src)

// ---- 32x48 forms ----
// These sprites are taller than a tile, so they stand above it rather than in
// it. Their fallen and overheated states live in the same file as the standing
// ones, so nothing ever has to swap `icon`.
// The 'soldier' state in that file is a beta sprite and is deliberately unused.

/// Fast, shallow hits. Damage per swing is low but `rapid_melee` triples the
/// rate, so its damage over time lands on the indigo noon sweeper's (which
/// swings once for 20-24). Closes with a leap that hits softer than its melee.
/mob/living/simple_animal/hostile/void_ranger/reaver
	name = "void ranger reaver"
	desc = "Built to close distance and nothing else."
	icon = 'ModularLobotomy/_Lobotomyicons/void_ranger_soldier.dmi'
	icon_state = "reaver"
	icon_living = "reaver"
	icon_dead = "reaver_dead"
	butcher_results = list(/obj/item/stack/trace_material/fang/t2 = 2, /obj/item/stack/path_material/envy/t2 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/violet_advanced = 1)
	drop_tier = PATH_MAT_T2
	maxHealth = 500
	health = 500
	rapid_melee = 3
	melee_damage_lower = 7
	melee_damage_upper = 8
	move_to_delay = 3
	attack_sound = 'sound/weapons/bladeslice.ogg'
	/// Cooldown tracking for the closing leap.
	var/leap_cooldown = 0
	var/leap_cooldown_time = 8 SECONDS
	/// Deliberately below a full melee exchange; the leap is for closing, not damage.
	var/leap_damage = 12
	var/leap_aoe = 1

/mob/living/simple_animal/hostile/void_ranger/reaver/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/void_ranger/reaver/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/void_ranger/reaver/MoveToTarget(list/possible_targets)
	. = ..()
	if(target && isliving(target))
		INVOKE_ASYNC(src, PROC_REF(ReaverLeap), target)

/// Springs onto the target's tile, striking everything around where it lands.
/// Modelled on the headless ichthys' jump.
/mob/living/simple_animal/hostile/void_ranger/reaver/proc/ReaverLeap(mob/living/leap_target)
	if(!isliving(leap_target) || !can_act)
		return
	if(leap_cooldown > world.time)
		return
	var/dist = get_dist(leap_target, src)
	if(dist <= 1 || dist > 6)
		return
	leap_cooldown = world.time + leap_cooldown_time
	can_act = FALSE
	animate(src, pixel_z = 16, time = 0.1 SECONDS)
	pixel_z = 16
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE)
	SLEEP_CHECK_DEATH(0.6 SECONDS)
	var/turf/landing = get_turf(leap_target)
	if(landing)
		forceMove(landing)
	animate(src, pixel_z = 0, time = 0.1 SECONDS)
	pixel_z = 0
	SLEEP_CHECK_DEATH(0.1 SECONDS)
	for(var/turf/T in view(leap_aoe, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(leap_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	can_act = TRUE

/// Hovers, fires seeking bolts, and calls targets out for the rest of the
/// company. Its lock is what makes a squad focus fire.
/mob/living/simple_animal/hostile/void_ranger/distorter
	name = "void ranger distorter"
	desc = "The air bends around it in ways that suggest effort."
	icon = 'ModularLobotomy/_Lobotomyicons/void_ranger_soldier.dmi'
	icon_state = "distorter"
	icon_living = "distorter"
	icon_dead = "distorter_dead"
	butcher_results = list(/obj/item/stack/trace_material/lens/t2 = 2, /obj/item/stack/path_material/pride/t2 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/violet_advanced = 1)
	drop_tier = PATH_MAT_T2
	maxHealth = 450
	health = 450
	melee_damage_lower = 16
	melee_damage_upper = 20
	is_flying_animal = TRUE
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	minimum_distance = 4
	retreat_distance = 3
	projectiletype = /obj/projectile/void_ranger_bolt
	projectilesound = 'sound/weapons/laser3.ogg'
	/// How long a called target stays marked.
	var/lock_duration = 10 SECONDS
	/// Locking is rarer than shooting, so it gets its own timer.
	var/lock_cooldown = 0
	var/lock_cooldown_time = 16 SECONDS
	/// How far the call carries to other rangers.
	var/lock_rally_range = 9

/mob/living/simple_animal/hostile/void_ranger/distorter/OpenFire(atom/A)
	// Seeking bolts need to be told what to chase; the parent fires them blind.
	if(isliving(A) && lock_cooldown <= world.time)
		LockOn(A)
	return ..()

/// Calls a target out: marks them, softens them, and turns the company onto
/// them. The mark is what the other rangers read when they retarget.
/mob/living/simple_animal/hostile/void_ranger/distorter/proc/LockOn(mob/living/quarry)
	if(!isliving(quarry) || QDELETED(quarry) || quarry.stat == DEAD)
		return FALSE
	if(faction_check_mob(quarry))
		return FALSE
	lock_cooldown = world.time + lock_cooldown_time
	quarry.apply_status_effect(/datum/status_effect/void_ranger_locked, lock_duration)
	// Two stacks, per the debuff's own helper, so it stacks and expires normally.
	quarry.apply_lc_fragile(2)
	visible_message(span_danger("[src] locks onto [quarry]!"))
	playsound(get_turf(src), 'sound/magic/curse.ogg', 45, TRUE)
	// Everyone in earshot swings onto the called target.
	for(var/mob/living/simple_animal/hostile/void_ranger/ally in view(lock_rally_range, src))
		if(ally == src || ally.stat == DEAD)
			continue
		if(ally.faction_check_mob(quarry))
			continue
		ally.GiveTarget(quarry)
	return TRUE

/// Marker sitting on whatever a distorter has called out.
/datum/status_effect/void_ranger_locked
	id = "void_ranger_locked"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/mutable_appearance/marker

/datum/status_effect/void_ranger_locked/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	return ..()

/datum/status_effect/void_ranger_locked/on_apply()
	marker = mutable_appearance('ModularLobotomy/_Lobotomyicons/asat_pramad.dmi', "lock_on", ABOVE_MOB_LAYER)
	marker.appearance_flags = RESET_COLOR | RESET_TRANSFORM
	owner.add_overlay(marker)
	to_chat(owner, span_userdanger("Something has your measure."))
	return TRUE

/datum/status_effect/void_ranger_locked/on_remove()
	if(marker)
		owner.cut_overlay(marker)
		marker = null

/// The heavy. Paints a beam on its mark, stands still while it does, then
/// empties a long burst and cooks itself doing it.
///
/// Sequence: two seconds of beam with no movement, a look to see the target
/// is still there, then twenty-five rounds over three seconds, then four
/// seconds glowing and helpless. Losing sight during the wind-up cancels the
/// whole thing for a short cooldown, so it can be broken by taking cover.
/mob/living/simple_animal/hostile/void_ranger/eliminator
	name = "void ranger eliminator"
	desc = "Sent when the matter is already decided."
	icon = 'ModularLobotomy/_Lobotomyicons/void_ranger_soldier.dmi'
	icon_state = "eliminator"
	icon_living = "eliminator"
	icon_dead = "eliminator_dead"
	butcher_results = list(/obj/item/stack/trace_material/ward/t2 = 2, /obj/item/stack/path_material/sloth/t2 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/violet_elegant = 1)
	drop_tier = PATH_MAT_T2
	maxHealth = 700
	health = 700
	melee_damage_lower = 22
	melee_damage_upper = 28
	move_to_delay = 5
	ranged = TRUE
	ranged_cooldown_time = 8 SECONDS
	minimum_distance = 5
	retreat_distance = 3
	projectiletype = /obj/projectile/void_ranger_slug
	projectilesound = 'sound/weapons/gun/smg/shot.ogg'

	/// Beam drawn to the mark during the wind-up.
	var/datum/beam/aim_beam
	/// TRUE while cooking down after a burst.
	var/overheated = FALSE
	var/aim_time = 2 SECONDS
	var/burst_shots = 25
	var/burst_duration = 2 SECONDS
	var/overheat_time = 4 SECONDS
	/// How far it must still see the mark when the beam finishes.
	var/firing_range = 7

/mob/living/simple_animal/hostile/void_ranger/eliminator/Move()
	if(!can_act || overheated)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/void_ranger/eliminator/AttackingTarget(atom/attacked_target)
	if(!can_act || overheated)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/void_ranger/eliminator/OpenFire(atom/A)
	if(!can_act || overheated)
		return FALSE
	// The whole sequence is run here rather than deferring to the parent, which
	// would fire a single shot immediately.
	INVOKE_ASYNC(src, PROC_REF(AimAndFire), A)
	return FALSE

/mob/living/simple_animal/hostile/void_ranger/eliminator/proc/AimAndFire(atom/mark)
	if(!mark || !can_act || overheated)
		return
	can_act = FALSE
	aim_beam = Beam(mark, icon_state = "1-full", time = aim_time)
	visible_message(span_warning("[src] settles, and a line of light finds [mark]."))
	playsound(get_turf(src), 'sound/weapons/gun/general/dry_fire.ogg', 60, TRUE)
	SLEEP_CHECK_DEATH(aim_time)
	if(aim_beam)
		QDEL_NULL(aim_beam)
	// Lost it. Nothing is fired and it has to start over.
	if(QDELETED(mark) || !(mark in view(firing_range, src)))
		visible_message(span_notice("[src] loses its line and lowers the weapon."))
		ranged_cooldown = world.time + 3 SECONDS
		can_act = TRUE
		return
	FireBarrage(mark)

/// Twenty-five rounds spread evenly across the burst.
/mob/living/simple_animal/hostile/void_ranger/eliminator/proc/FireBarrage(atom/mark)
	visible_message(span_userdanger("[src] opens up!"))
	var/gap = max(burst_duration / burst_shots, 1)
	for(var/i in 1 to burst_shots)
		if(QDELETED(src) || stat == DEAD)
			return
		if(QDELETED(mark))
			break
		Shoot(mark)
		SLEEP_CHECK_DEATH(gap)
	BeginOverheat()

/// Spent. Glowing, rooted, and unable to swing until it cools.
/mob/living/simple_animal/hostile/void_ranger/eliminator/proc/BeginOverheat()
	overheated = TRUE
	icon_state = "eliminator_overheated"
	icon_living = "eliminator_overheated"
	visible_message(span_warning("[src] glows white hot and stops dead."))
	playsound(get_turf(src), 'sound/effects/spray.ogg', 45, TRUE)
	addtimer(CALLBACK(src, PROC_REF(EndOverheat)), overheat_time)

/mob/living/simple_animal/hostile/void_ranger/eliminator/proc/EndOverheat()
	if(QDELETED(src))
		return
	overheated = FALSE
	icon_state = initial(icon_state)
	icon_living = initial(icon_living)
	can_act = TRUE
	ranged_cooldown = world.time + ranged_cooldown_time
	if(stat != DEAD)
		visible_message(span_notice("[src] cools, and moves again."))

/mob/living/simple_animal/hostile/void_ranger/eliminator/Destroy()
	if(aim_beam)
		QDEL_NULL(aim_beam)
	return ..()

/// Fired in bursts, so it is light per round.
/obj/projectile/void_ranger_slug
	name = "void round"
	icon_state = "black_bullet"
	damage = 10
	damage_type = BLACK_DAMAGE
	speed = 0.6
	range = 12
	projectile_piercing = PASSMOB

/obj/projectile/void_ranger_slug/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(isliving(target) && isliving(firer))
		var/mob/living/hit = target
		var/mob/living/shooter = firer
		if(hit != shooter && shooter.faction_check_mob(hit))
			return FALSE
	return ..()
