/**
 * Resurgence Clan - Raider Variants
 *
 * Base raider type and specialized subtypes for the raid system.
 * Raiders have loot mode (no density, ignore targets) until attacked.
 */

/// How often raiders check for loot/trampling opportunities (deciseconds)
#define RAIDER_LOOT_CHECK_INTERVAL 2 SECONDS
/// Minimum value for an item to be worth stealing
#define RAIDER_MIN_ITEM_VALUE 5
/// Maximum items a raider can carry
#define RAIDER_MAX_STOLEN_ITEMS 5
/// Damage dealt to farm plots when trampled
#define RAIDER_TRAMPLE_DAMAGE 100

// ==================== BASE RAIDER ====================

/**
 * Base raider type for all raid units.
 * Provides loot mode, item stealing, farm trampling, and crate opening.
 */
/mob/living/simple_animal/hostile/clan/raider
	name = "Clan Raider"
	desc = "A mechanical raider from the Insurgence Clan."
	faction = list("insurgence_raiders")
	can_protect = FALSE
	teleport_away = TRUE

	/// Items this raider has stolen
	var/list/stolen_items = list()
	/// Maximum items this raider can carry
	var/max_stolen = RAIDER_MAX_STOLEN_ITEMS
	/// Timer for loot checking
	var/loot_check_timer
	/// Whether this raider should trample farms
	var/trampler = FALSE
	/// Whether this raider can open crates
	var/crate_looter = FALSE
	/// Whether this raider can break locked crates
	var/crate_breaker = FALSE
	/// Whether in loot mode (no density, ignores targets)
	var/loot_mode = TRUE
	/// Current combat target being fought
	var/mob/living/combat_target
	/// Whether this raider is retreating to spawn
	var/retreating = FALSE

/mob/living/simple_animal/hostile/clan/raider/Initialize(mapload)
	. = ..()
	loot_check_timer = addtimer(CALLBACK(src, PROC_REF(raider_loot_tick)), RAIDER_LOOT_CHECK_INTERVAL, TIMER_LOOP | TIMER_STOPPABLE)
	enter_loot_mode()

/mob/living/simple_animal/hostile/clan/raider/Destroy()
	if(loot_check_timer)
		deltimer(loot_check_timer)
	drop_stolen_items()
	combat_target = null
	return ..()

/mob/living/simple_animal/hostile/clan/raider/death(gibbed)
	drop_stolen_items()
	combat_target = null
	return ..()

// ==================== LOOT/COMBAT MODE ====================

/// Enter loot mode - no density, ignore targets, focus on stealing
/mob/living/simple_animal/hostile/clan/raider/proc/enter_loot_mode()
	loot_mode = TRUE
	density = FALSE
	combat_target = null
	LoseTarget()
	log_admin("RAID DEBUG: [type] entered loot mode at [AREACOORD(src)]")

/// Exit loot mode and enter combat mode
/mob/living/simple_animal/hostile/clan/raider/proc/enter_combat_mode(mob/living/attacker)
	if(!loot_mode)
		// Already in combat mode - just update target if needed
		if(attacker && !combat_target)
			combat_target = attacker
			GiveTarget(attacker)
		return
	loot_mode = FALSE
	density = TRUE
	if(attacker)
		combat_target = attacker
		GiveTarget(attacker)
	log_admin("RAID DEBUG: [type] entered combat mode at [AREACOORD(src)], target: [attacker]")

/// Check if combat target is dead and return to loot mode
/mob/living/simple_animal/hostile/clan/raider/Life()
	. = ..()
	if(stat == DEAD)
		return

	// If in combat mode, check if target is dead or gone
	if(!loot_mode)
		if(!combat_target || QDELETED(combat_target) || combat_target.stat == DEAD)
			log_admin("RAID DEBUG: [type] target eliminated, returning to loot mode")
			enter_loot_mode()
		else if(get_dist(src, combat_target) > aggro_vision_range)
			log_admin("RAID DEBUG: [type] target escaped, returning to loot mode")
			enter_loot_mode()

// ==================== RETREAT LOGIC ====================

/// Check if inventory is full and we should retreat
/mob/living/simple_animal/hostile/clan/raider/proc/check_should_retreat()
	if(retreating)
		return FALSE
	if(length(stolen_items) >= max_stolen)
		begin_retreat()
		return TRUE
	return FALSE

/// Begin retreating to spawn point with stolen loot
/mob/living/simple_animal/hostile/clan/raider/proc/begin_retreat()
	if(retreating)
		return

	retreating = TRUE
	log_admin("RAID DEBUG: [type] inventory full ([length(stolen_items)]/[max_stolen]) - beginning retreat")
	visible_message(span_warning("[src] begins retreating with its stolen loot!"))

	// Enter retreat mode - ignore targets
	loot_mode = FALSE
	combat_target = null
	LoseTarget()

	// Tell the raider component to handle navigation back to spawn
	var/datum/component/raider/raider_comp = GetComponent(/datum/component/raider)
	if(raider_comp)
		raider_comp.begin_retreat()
	else
		// No component - just teleport away immediately
		retreat_teleport()

/// Called when raider reaches spawn point - teleport away with loot
/mob/living/simple_animal/hostile/clan/raider/proc/retreat_teleport()
	log_admin("RAID DEBUG: [type] successfully retreating with [length(stolen_items)] items")
	visible_message(span_warning("[src] vanishes with its stolen goods!"))

	// Play teleport effect
	playsound(src, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 25, TRUE)
	new /obj/effect/temp_visual/beam_out(get_turf(src))

	// Items are taken with the raider (not dropped)
	stolen_items.Cut()

	// Notify the raid system
	var/datum/component/raider/raider_comp = GetComponent(/datum/component/raider)
	if(raider_comp?.raid)
		raider_comp.raid.on_raider_escaped(src)

	// Delete the raider
	qdel(src)

/// Override CanAttack to also ignore targets while retreating
/mob/living/simple_animal/hostile/clan/raider/CanAttack(atom/the_target)
	if(loot_mode || retreating)
		return FALSE
	return ..()

// ==================== ATTACK DETECTION ====================

/// When attacked with item, switch to combat mode
/mob/living/simple_animal/hostile/clan/raider/attackby(obj/item/O, mob/user, params)
	. = ..()
	if(isliving(user) && O.force > 0)
		var/mob/living/L = user
		enter_combat_mode(L)

/// When hit by projectile, switch to combat mode
/mob/living/simple_animal/hostile/clan/raider/bullet_act(obj/projectile/P)
	. = ..()
	if(P.firer && isliving(P.firer))
		var/mob/living/L = P.firer
		enter_combat_mode(L)

/// When punched, switch to combat mode
/mob/living/simple_animal/hostile/clan/raider/attack_hand(mob/living/carbon/M)
	. = ..()
	if(M.a_intent == INTENT_HARM)
		enter_combat_mode(M)

/// When attacked by animal, switch to combat mode
/mob/living/simple_animal/hostile/clan/raider/attack_animal(mob/living/simple_animal/M, damage)
	. = ..()
	if(M && damage > 0)
		enter_combat_mode(M)

// ==================== MOVEMENT & LOOTING ====================

/// Collect items every time we move
/mob/living/simple_animal/hostile/clan/raider/Move()
	. = ..()
	if(. && stat != DEAD)
		try_steal_items()
		if(trampler)
			try_trample_farms()

/// Called periodically for actions that shouldn't happen every move
/mob/living/simple_animal/hostile/clan/raider/proc/raider_loot_tick()
	if(stat == DEAD)
		return
	if(crate_looter)
		try_open_crates()
	// Backup collection in case we're standing still
	try_steal_items()

// ==================== STEALING ====================

/// Attempt to steal items from the ground
/mob/living/simple_animal/hostile/clan/raider/proc/try_steal_items()
	if(length(stolen_items) >= max_stolen)
		return FALSE

	for(var/obj/item/I in range(1, src))
		if(I.anchored)
			continue
		if(I.loc == src)
			continue

		var/value = get_item_trade_value(I)
		if(value >= RAIDER_MIN_ITEM_VALUE)
			steal_item(I)
			return TRUE

	return FALSE

/// Steal a specific item
/mob/living/simple_animal/hostile/clan/raider/proc/steal_item(obj/item/I)
	if(!I || QDELETED(I))
		return FALSE

	I.forceMove(src)
	stolen_items += I
	visible_message(span_warning("[src] snatches [I]!"))
	log_admin("RAID: [type] stole [I.type] at [AREACOORD(src)]")

	// Check if we should retreat with our loot
	check_should_retreat()
	return TRUE

/// Drop all stolen items at current location
/mob/living/simple_animal/hostile/clan/raider/proc/drop_stolen_items()
	if(!stolen_items.len)
		return

	var/turf/drop_loc = get_turf(src)
	for(var/obj/item/I in stolen_items)
		I.forceMove(drop_loc)
	stolen_items.Cut()

// ==================== FARM TRAMPLING ====================

/// Attempt to trample nearby farm plots
/mob/living/simple_animal/hostile/clan/raider/proc/try_trample_farms()
	for(var/obj/structure/farm_plot/plot in range(1, src))
		trample_farm(plot)
		return TRUE
	return FALSE

/// Trample a farm plot, damaging it and destroying any planted crops
/mob/living/simple_animal/hostile/clan/raider/proc/trample_farm(obj/structure/farm_plot/plot)
	if(!plot || QDELETED(plot))
		return

	visible_message(span_danger("[src] tramples [plot]!"))
	playsound(plot, 'sound/effects/grillehit.ogg', 50, TRUE)

	if(plot.myseed)
		visible_message(span_warning("[plot.myseed.plantname] is destroyed!"))
		QDEL_NULL(plot.myseed)
		plot.harvest = FALSE
		plot.age = 0
		plot.harvest_work_points = 0
		plot.update_icon()

	plot.take_damage(RAIDER_TRAMPLE_DAMAGE, BRUTE, MELEE)
	log_admin("RAID: [type] trampled farm plot at [AREACOORD(plot)]")

// ==================== CRATE LOOTING ====================

/// Attempt to open nearby closed crates/closets
/mob/living/simple_animal/hostile/clan/raider/proc/try_open_crates()
	for(var/obj/structure/closet/crate in range(1, src))
		if(!crate.opened && !crate.locked && !crate.welded)
			open_crate(crate)
			return TRUE
		else if(!crate.opened && (crate.locked || crate.welded) && crate_breaker)
			attack_crate(crate)
			return TRUE
	return FALSE

/// Open a crate to access its contents
/mob/living/simple_animal/hostile/clan/raider/proc/open_crate(obj/structure/closet/crate)
	if(!crate || QDELETED(crate))
		return

	visible_message(span_danger("[src] pries open [crate]!"))
	playsound(crate, 'sound/machines/closet_open.ogg', 50, TRUE)

	crate.opened = TRUE
	crate.dump_contents()
	crate.update_icon()

	log_admin("RAID: [type] opened crate [crate.type] at [AREACOORD(crate)]")
	try_steal_items()

/// Attack a locked/welded crate to break it open
/mob/living/simple_animal/hostile/clan/raider/proc/attack_crate(obj/structure/closet/crate)
	if(!crate || QDELETED(crate))
		return

	visible_message(span_danger("[src] bashes [crate]!"))
	playsound(crate, 'sound/weapons/smash.ogg', 50, TRUE)

	crate.take_damage(melee_damage_upper, BRUTE, MELEE)
	log_admin("RAID: [type] attacked crate [crate.type] at [AREACOORD(crate)]")

// ==================== RAIDER SCOUT ====================

/// Fast raider that steals items and tramples farm plots
/mob/living/simple_animal/hostile/clan/raider/scout
	name = "Raider Scout"
	desc = "A swift mechanical raider from the Insurgence Clan. It moves with predatory intent, grabbing anything valuable it passes."
	icon_state = "clan_scout"
	icon_living = "clan_scout"
	icon_dead = "clan_scout_dead"
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	trampler = TRUE

	var/max_speed = 1.5
	var/normal_speed = 3
	var/max_attack_speed = 4
	var/normal_attack_speed = 1

/mob/living/simple_animal/hostile/clan/raider/scout/ChargeUpdated()
	move_to_delay = normal_speed - (normal_speed - max_speed) * charge / max_charge
	rapid_melee = normal_attack_speed + (max_attack_speed - normal_attack_speed) * charge / max_charge
	UpdateSpeed()
	var/flamelayer = layer + 0.1
	var/flame
	if(charge > 7)
		cut_overlays()
		flame = "scout_blue"
	else if(charge > 3)
		cut_overlays()
		flame = "scout_red"
	else
		cut_overlays()
		return
	var/mutable_appearance/colored_overlay = mutable_appearance(icon, flame, flamelayer)
	add_overlay(colored_overlay)

/mob/living/simple_animal/hostile/clan/raider/scout/AttackingTarget()
	. = ..()
	if(charge > 1)
		charge -= 2

/mob/living/simple_animal/hostile/clan/raider/scout/death(gibbed)
	cut_overlays()
	charge = 0
	return ..()

// ==================== PILLAGER SCOUT ====================

/// Versatile raider that can steal, trample, and loot crates
/mob/living/simple_animal/hostile/clan/raider/scout/pillager
	name = "Pillager Scout"
	desc = "A cunning mechanical raider built for looting. It efficiently strips areas of anything valuable."
	max_stolen = RAIDER_MAX_STOLEN_ITEMS + 2
	crate_looter = TRUE

// ==================== RAIDER DEFENDER ====================

/// Heavy raider that opens crates and breaks locked ones
/mob/living/simple_animal/hostile/clan/raider/defender
	name = "Raider Defender"
	desc = "A hulking mechanical raider from the Insurgence Clan. Its large frame can pry open containers and carry heavy loads."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_48x48.dmi'
	icon_state = "defender"
	icon_living = "defender"
	icon_dead = "defender_dead"
	pixel_x = -8
	base_pixel_x = -8
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	health = 1200
	maxHealth = 1200
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	attack_sound = 'sound/weapons/purple_tear/blunt2.ogg'
	silk_results = list(/obj/item/stack/sheet/silk/azure_simple = 2,
						/obj/item/stack/sheet/silk/azure_advanced = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 3)
	melee_damage_lower = 20
	melee_damage_upper = 25
	max_stolen = RAIDER_MAX_STOLEN_ITEMS + 3
	crate_looter = TRUE
	crate_breaker = TRUE

	var/max_speed = 1.5
	var/normal_speed = 3

/mob/living/simple_animal/hostile/clan/raider/defender/ChargeUpdated()
	if(charge >= max_charge)
		move_to_delay = max_speed
	else
		move_to_delay = normal_speed

#undef RAIDER_LOOT_CHECK_INTERVAL
#undef RAIDER_MIN_ITEM_VALUE
#undef RAIDER_MAX_STOLEN_ITEMS
#undef RAIDER_TRAMPLE_DAMAGE
