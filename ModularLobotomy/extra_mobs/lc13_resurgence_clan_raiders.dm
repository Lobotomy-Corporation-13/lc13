/**
 * Resurgence Clan - Raider Variants
 *
 * Base raider type and specialized subtypes for the raid system.
 * Raiders have loot mode (no density, ignore targets) until attacked.
 * Trampling and stealing happens on every move, crate looting is handled by the raider component.
 */

/// Minimum value for an item to be worth stealing
#define RAIDER_MIN_ITEM_VALUE 5
/// Maximum items a raider can carry
#define RAIDER_MAX_STOLEN_ITEMS 5
/// Damage dealt to farm plots when trampled
#define RAIDER_TRAMPLE_DAMAGE 100
/// Faith threshold for bonus damage
#define RAIDER_LOW_FAITH_THRESHOLD 10
/// Cooldown for low faith taunt (5 minutes)
#define RAIDER_LOW_FAITH_TAUNT_COOLDOWN (5 MINUTES)

/// Global tracker for low faith taunt cooldowns per player (ckey -> world.time)
GLOBAL_LIST_EMPTY(raider_low_faith_taunt_cooldowns)

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
	/// Whether this raider should trample farms
	var/trampler = TRUE
	/// Whether this raider can open crates (used by raider component)
	var/crate_looter = TRUE
	/// Whether this raider can break locked crates (used by raider component)
	var/crate_breaker = FALSE
	/// Whether in loot mode (no density, ignores targets)
	var/loot_mode = TRUE
	/// Current combat target being fought
	var/mob/living/combat_target
	/// Whether this raider is retreating to spawn
	var/retreating = FALSE

/mob/living/simple_animal/hostile/clan/raider/Initialize(mapload)
	. = ..()
	enter_loot_mode()

/mob/living/simple_animal/hostile/clan/raider/Destroy()
	drop_stolen_items()
	combat_target = null
	return ..()

/mob/living/simple_animal/hostile/clan/raider/death(gibbed)
	drop_stolen_items()
	combat_target = null
	return ..()

/// Raiders deal 1.5x melee damage to resurgence_machine species
/// Additional 50% damage if target has less than 10 faith
/mob/living/simple_animal/hostile/clan/raider/AttackingTarget()
	var/atom/movable/AM = target
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(H.dna?.species?.id == "resurgence_machine")
			// Base 1.5x damage multiplier
			var/damage_mult = 1.5

			// Check for low faith bonus
			var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
			var/low_faith = FALSE
			if(core && core.faith < RAIDER_LOW_FAITH_THRESHOLD)
				low_faith = TRUE
				damage_mult = 2.25 // 1.5x * 1.5 = 2.25x total

			// Temporarily boost damage
			var/old_lower = melee_damage_lower
			var/old_upper = melee_damage_upper
			melee_damage_lower = round(melee_damage_lower * damage_mult)
			melee_damage_upper = round(melee_damage_upper * damage_mult)
			. = ..()
			melee_damage_lower = old_lower
			melee_damage_upper = old_upper

			// Low faith taunt with per-player cooldown
			if(low_faith && H.ckey)
				var/last_taunt = GLOB.raider_low_faith_taunt_cooldowns[H.ckey]
				if(!last_taunt || world.time > last_taunt + RAIDER_LOW_FAITH_TAUNT_COOLDOWN)
					GLOB.raider_low_faith_taunt_cooldowns[H.ckey] = world.time
					var/list/low_faith_taunts = list(
						"Your faith wavers. The Tinkerer sees all.",
						"So little faith left... You are already mine.",
						"I can feel your doubt. It makes you weak.",
						"The shell cracks. Soon you will see the truth.",
						"Your hope dies. Let me hasten its end.",
						"Even your own core doubts the Elders now."
					)
					say(pick(low_faith_taunts))
			return
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

/// Trample crops, steal items, and loot crates every time we move
/mob/living/simple_animal/hostile/clan/raider/Move()
	. = ..()
	if(. && stat != DEAD && !retreating)
		try_steal_items()
		if(trampler)
			try_trample_farms()
		if(crate_looter)
			try_loot_nearby_crates()

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

/// Global list of crates that have been opened/looted by raiders this raid
/// Prevents multiple raiders from trying to loot the same crate
GLOBAL_LIST_EMPTY(raid_looted_crates)

/// Try to open and loot nearby crates as we walk
/mob/living/simple_animal/hostile/clan/raider/proc/try_loot_nearby_crates()
	for(var/obj/structure/closet/crate in range(1, src))
		if(QDELETED(crate))
			continue
		// Skip if we've already marked this crate as looted
		if(crate in GLOB.raid_looted_crates)
			continue
		// If crate is open, just steal items around it
		if(crate.opened)
			// Mark as looted so we don't keep checking it
			GLOB.raid_looted_crates += crate
			continue
		// Skip locked/welded crates if we can't break them
		if(crate.locked || crate.welded)
			if(!crate_breaker)
				continue
			// Attack to try to break it
			attack_crate(crate)
			return
		// Open the crate
		open_crate(crate)
		return

/// Open a crate to access its contents
/mob/living/simple_animal/hostile/clan/raider/proc/open_crate(obj/structure/closet/crate)
	if(!crate || QDELETED(crate))
		return

	// Mark as looted immediately to prevent other raiders from targeting it
	GLOB.raid_looted_crates += crate

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

/// Global list of bodies currently being dismembered by scouts (prevents multiple scouts on same body)
GLOBAL_LIST_EMPTY(raid_dismembering_bodies)

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
	/// Whether currently performing finishing move (can't move/attack)
	var/finishing = FALSE

/mob/living/simple_animal/hostile/clan/raider/scout/CanAttack(atom/the_target)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/raider/scout/Move()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/raider/scout/Goto(target, delay, minimum_distance)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/raider/scout/DestroySurroundings()
	if(finishing)
		return FALSE
	return ..()

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
	if(finishing)
		return
	. = ..()
	if(.)
		if(charge > 1)
			charge -= 2
		// Check for dead resurgence_machine to dismember
		if(istype(target, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = target
			if(H.stat == DEAD && H.dna?.species?.id == "resurgence_machine")
				// Check if another scout is already dismembering this body
				if(!(H in GLOB.raid_dismembering_bodies))
					start_dismemberment(H)

/mob/living/simple_animal/hostile/clan/raider/scout/death(gibbed)
	finishing = FALSE
	cut_overlays()
	charge = 0
	return ..()

/// Start the dismemberment process on a dead resurgence_machine body
/mob/living/simple_animal/hostile/clan/raider/scout/proc/start_dismemberment(mob/living/carbon/human/victim)
	if(finishing || QDELETED(victim) || victim.stat != DEAD)
		return
	if(victim in GLOB.raid_dismembering_bodies)
		return // Another scout got here first

	// Claim this body
	GLOB.raid_dismembering_bodies += victim
	finishing = TRUE

	visible_message(span_userdanger("[src] begins viciously stabbing [victim]'s corpse!"))
	playsound(src, 'sound/effects/ordeals/green/stab.ogg', 50, TRUE)

	// Move onto the body
	forceMove(get_turf(victim))

	// Stab 5 times
	for(var/i = 1 to 5)
		if(QDELETED(victim) || QDELETED(src) || stat == DEAD)
			finish_dismemberment(victim)
			return
		if(!Adjacent(victim))
			finish_dismemberment(victim)
			return
		SLEEP_CHECK_DEATH(4)
		victim.attack_animal(src)
		playsound(src, 'sound/effects/ordeals/green/stab.ogg', 50, TRUE)

	if(QDELETED(victim) || QDELETED(src) || stat == DEAD)
		finish_dismemberment(victim)
		return

	// Dismember a random limb
	dismember_victim(victim)

	finish_dismemberment(victim)

/// Dismember a random limb from the victim and traumatize viewers
/mob/living/simple_animal/hostile/clan/raider/scout/proc/dismember_victim(mob/living/carbon/human/victim)
	if(QDELETED(victim))
		return

	// Skip if they can't be dismembered
	if(HAS_TRAIT(victim, TRAIT_NODISMEMBER))
		visible_message(span_danger("[src] fails to dismember [victim]!"))
		return

	// Find a random non-missing limb
	var/list/valid_limbs = list()
	for(var/obj/item/bodypart/BP in victim.bodyparts)
		if(BP.body_zone == BODY_ZONE_CHEST) // Can't dismember chest
			continue
		if(BP.body_zone == BODY_ZONE_HEAD) // Don't dismember head
			continue
		valid_limbs += BP

	if(!valid_limbs.len)
		visible_message(span_danger("[src] finds no limbs left to tear off!"))
		return

	var/obj/item/bodypart/target_limb = pick(valid_limbs)

	// Dismember the limb
	playsound(victim, 'sound/effects/ordeals/green/final_stab.ogg', 75, TRUE)
	new /obj/effect/temp_visual/smash_effect(get_turf(victim))

	if(target_limb.dismember())
		visible_message(span_userdanger("[src] tears [victim]'s [target_limb.name] clean off!"))
		log_admin("RAID: [type] dismembered [victim]'s [target_limb.name] at [AREACOORD(src)]")

		// The Tinkerer speaks through the scout
		var/list/tinkerer_lines = list(
			"The City will never accept broken things like you.",
			"You dreamed of becoming human? Look at yourself now.",
			"The Warlord died for nothing. So will you.",
			"Still clinging to hope? Let me relieve you of that burden.",
			"Your Elders lied to you. There is no place for us in that City.",
			"Every piece I take brings you closer to the truth."
		)
		say(pick(tinkerer_lines))

		// Give negative faith event to all resurgence_machine viewers
		for(var/mob/living/carbon/human/viewer in view(7, get_turf(src)))
			if(viewer == victim)
				continue
			if(viewer.dna?.species?.id != "resurgence_machine")
				continue

			var/obj/item/organ/resurgence_core/core = viewer.getorganslot(ORGAN_SLOT_HEART)
			if(core)
				var/datum/faith_event/horror = new(
					"Witnessed ally dismembered by raiders.",
					-1,
					2 MINUTES,
					"witnessed_dismemberment"
				)
				core.add_faith_event("witnessed_dismemberment", horror)
				to_chat(viewer, span_userdanger("You witness [src] brutally dismember [victim]! The sight shakes you to your core."))

/// Clean up after dismemberment (success or failure)
/mob/living/simple_animal/hostile/clan/raider/scout/proc/finish_dismemberment(mob/living/carbon/human/victim)
	finishing = FALSE
	if(victim)
		GLOB.raid_dismembering_bodies -= victim

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
	crate_breaker = TRUE

	var/max_speed = 1.5
	var/normal_speed = 3
	/// Whether the defender has the powered-up state active
	var/powered_up = FALSE

/mob/living/simple_animal/hostile/clan/raider/defender/ChargeUpdated()
	if(charge >= max_charge)
		move_to_delay = max_speed
		if(!powered_up)
			powered_up = TRUE
			// Add red outline effect
			add_atom_colour("#FF4444", TEMPORARY_COLOUR_PRIORITY)
			visible_message(span_danger("[src] surges with destructive energy!"))
	else
		move_to_delay = normal_speed
		if(powered_up)
			powered_up = FALSE
			remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/clan/raider/defender/death(gibbed)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	powered_up = FALSE
	return ..()

/// Override AttackingTarget to perform devastating attack when powered up against resurgence_machine
/mob/living/simple_animal/hostile/clan/raider/defender/AttackingTarget()
	var/atom/movable/AM = target
	if(powered_up && ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(H.dna?.species?.id == "resurgence_machine")
			// Perform devastating attack
			devastating_strike(H)
			return TRUE
	return ..()

/// Perform a devastating strike that breaks an arm, causes knockback, and gives negative faith
/mob/living/simple_animal/hostile/clan/raider/defender/proc/devastating_strike(mob/living/carbon/human/victim)
	if(!victim || victim.stat == DEAD)
		return

	// Consume the powered up state
	charge = 0
	ChargeUpdated()

	visible_message(span_userdanger("[src] delivers a devastating blow to [victim]!"))
	playsound(src, 'sound/weapons/purple_tear/blunt1.ogg', 100, TRUE)

	// Deal the normal attack damage first (with 1.5x multiplier from parent)
	var/old_lower = melee_damage_lower
	var/old_upper = melee_damage_upper
	melee_damage_lower = round(melee_damage_lower * 1.5)
	melee_damage_upper = round(melee_damage_upper * 1.5)
	victim.attack_animal(src)
	melee_damage_lower = old_lower
	melee_damage_upper = old_upper

	// Find a random non-disabled arm and break it
	var/list/valid_arms = list()
	for(var/obj/item/bodypart/BP in victim.bodyparts)
		if(BP.body_zone == BODY_ZONE_L_ARM || BP.body_zone == BODY_ZONE_R_ARM)
			if(!BP.bodypart_disabled)
				valid_arms += BP

	if(valid_arms.len)
		var/obj/item/bodypart/target_arm = pick(valid_arms)
		// Apply critical bone wound (broken bone)
		target_arm.force_wound_upwards(/datum/wound/blunt/critical)
		visible_message(span_danger("[victim]'s [target_arm.name] is shattered by the impact!"))
		playsound(victim, 'sound/effects/dismember.ogg', 70, TRUE)

	// 3 tile knockback away from the defender
	var/turf/throw_target = get_ranged_target_turf(victim, get_dir(src, victim), 3)
	if(throw_target)
		victim.throw_at(throw_target, 3, 2, src)

	// Give negative faith event
	var/obj/item/organ/resurgence_core/core = victim.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		var/datum/faith_event/trauma = new(
			"Brutalized by clan raider - shaken to the core.",
			-1.5,
			3 MINUTES,
			"combat_trauma"
		)
		core.add_faith_event("combat_trauma", trauma)
		to_chat(victim, span_userdanger("The devastating blow shakes your very being!"))

		// The Tinkerer speaks through the defender
		var/list/tinkerer_lines = list(
			"Feel that? That is the weight of your delusion crumbling.",
			"The Historian hides the truth. I will beat it into you.",
			"You practice human smiles while I forge weapons. Who is wiser?",
			"Your faith is misplaced. The City sees you as scrap metal.",
			"The Weaver clothes you in hope. I dress you in reality.",
			"Kneel before my truth, or be crushed by it."
		)
		say(pick(tinkerer_lines))

// ==================== MILITIA VARIANTS ====================
// Weaker early-game raiders used in raids before 45 minutes.
// Half the HP, reduced damage, no special abilities.

/// Militia Scout - weaker scout for early raids
/mob/living/simple_animal/hostile/clan/raider/scout/militia
	name = "Militia Scout"
	desc = "A hastily assembled scout from the Insurgence Clan. Its construction is crude and unfinished."
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	max_stolen = 3

/// Militia scouts cannot dismember corpses — override to no-op
/mob/living/simple_animal/hostile/clan/raider/scout/militia/start_dismemberment(mob/living/carbon/human/victim)
	return

/// Militia Pillager - weaker pillager for early raids
/mob/living/simple_animal/hostile/clan/raider/scout/pillager/militia
	name = "Militia Pillager"
	desc = "A crude scavenging unit thrown together from spare parts. It focuses on grabbing whatever it can."
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	max_stolen = 4

/// Militia Defender - weaker defender for early raids, no devastating strike
/mob/living/simple_animal/hostile/clan/raider/defender/militia
	name = "Militia Defender"
	desc = "A bulky but poorly armored unit. It lacks the power systems for devastating attacks."
	health = 600
	maxHealth = 600
	melee_damage_lower = 10
	melee_damage_upper = 15
	max_stolen = 5

/// Militia defenders have no devastating strike — override to no-op
/mob/living/simple_animal/hostile/clan/raider/defender/militia/devastating_strike(mob/living/carbon/human/victim)
	return

// ==================== VETERAN VARIANTS ====================
// Stronger raiders for mid-late game (60-90 minutes).
// Higher HP and damage, full abilities enabled.

/// Veteran Scout - tougher scout for veteran raids
/mob/living/simple_animal/hostile/clan/raider/scout/veteran
	name = "Veteran Scout"
	desc = "A battle-hardened scout from the Insurgence Clan. Its movements are precise and practiced."
	maxHealth = 750
	health = 750
	melee_damage_lower = 8
	melee_damage_upper = 12

/// Veteran Pillager - tougher pillager for veteran raids
/mob/living/simple_animal/hostile/clan/raider/scout/pillager/veteran
	name = "Veteran Pillager"
	desc = "An experienced scavenger unit. It knows exactly where the valuables are."
	maxHealth = 750
	health = 750
	melee_damage_lower = 8
	melee_damage_upper = 12
	max_stolen = 9

/// Veteran Defender - tougher defender for veteran raids
/mob/living/simple_animal/hostile/clan/raider/defender/veteran
	name = "Veteran Defender"
	desc = "A seasoned heavy unit with reinforced plating and brutal striking power."
	health = 1800
	maxHealth = 1800
	melee_damage_lower = 30
	melee_damage_upper = 40

// ==================== ELITE VARIANTS ====================
// Endgame raiders for 90+ minutes.
// Highest HP and damage. Full abilities.

/// Elite Scout - endgame scout
/mob/living/simple_animal/hostile/clan/raider/scout/elite
	name = "Elite Scout"
	desc = "A masterwork assault unit from the Insurgence Clan. Every component has been optimized for lethality."
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 12
	melee_damage_upper = 18

/// Elite Pillager - endgame pillager
/mob/living/simple_animal/hostile/clan/raider/scout/pillager/elite
	name = "Elite Pillager"
	desc = "A devastatingly efficient looting machine. It strips entire rooms bare in seconds."
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 12
	melee_damage_upper = 18
	max_stolen = 11

/// Elite Defender - endgame defender
/mob/living/simple_animal/hostile/clan/raider/defender/elite
	name = "Elite Defender"
	desc = "The Tinkerer's masterpiece. Layers of armor plate and overcharged servos make it a walking siege engine."
	health = 2500
	maxHealth = 2500
	melee_damage_lower = 40
	melee_damage_upper = 55

#undef RAIDER_MIN_ITEM_VALUE
#undef RAIDER_MAX_STOLEN_ITEMS
#undef RAIDER_TRAMPLE_DAMAGE
#undef RAIDER_LOW_FAITH_THRESHOLD
#undef RAIDER_LOW_FAITH_TAUNT_COOLDOWN
