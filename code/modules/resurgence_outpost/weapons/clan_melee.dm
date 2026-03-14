/**
 * Resurgence Outpost - Clan Melee Weapons
 *
 * All clan melee weapons in one file.
 * Uses a rarity system with faith-based damage scaling.
 * Damage = base_force × rarity_multiplier × faith_multiplier.
 *
 * Standard: Blade (fast), Mace (slow/heavy)
 * Gimmick: Spear (momentum), Gauntlets (taunt/lockdown), Dagger (backstab)
 */

// ==================== Rarity Helper Procs ====================

/// Returns damage multiplier for a given clan weapon rarity
/proc/clan_rarity_multiplier(rarity)
	switch(rarity)
		if(CLAN_RARITY_MILITIA)
			return 0.75
		if(CLAN_RARITY_REGULAR)
			return 1.0
		if(CLAN_RARITY_VETERAN)
			return 1.35
		if(CLAN_RARITY_ELITE)
			return 1.75
	return 1.0

/// Returns small damage multiplier for clan ammo rarity
/proc/clan_ammo_rarity_multiplier(rarity)
	switch(rarity)
		if(CLAN_RARITY_MILITIA)
			return 1.0
		if(CLAN_RARITY_REGULAR)
			return 1.05
		if(CLAN_RARITY_VETERAN)
			return 1.1
		if(CLAN_RARITY_ELITE)
			return 1.15
	return 1.0

/// Returns outline color hex for a given clan weapon rarity (matches grid crafting tier colors)
/proc/clan_rarity_color(rarity)
	switch(rarity)
		if(CLAN_RARITY_MILITIA)
			return "#22cc44"
		if(CLAN_RARITY_REGULAR)
			return "#4488ff"
		if(CLAN_RARITY_VETERAN)
			return "#cc44ff"
		if(CLAN_RARITY_ELITE)
			return "#ffcc00"
	return "#666666"

/// Returns display name for a given clan weapon rarity
/proc/clan_rarity_name(rarity)
	switch(rarity)
		if(CLAN_RARITY_MILITIA)
			return "Militia"
		if(CLAN_RARITY_REGULAR)
			return "Regular"
		if(CLAN_RARITY_VETERAN)
			return "Veteran"
		if(CLAN_RARITY_ELITE)
			return "Elite"
	return "Unknown"

// ==================== Base Clan Weapon ====================

/obj/item/melee/clan_weapon
	name = "clan weapon"
	desc = "A weapon forged by the Resurgence Clan."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "claymore"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	force = 15
	damtype = RED_DAMAGE
	item_flags = NEEDS_PERMIT
	/// Weapon rarity tier — determines damage multiplier and outline color
	var/rarity = CLAN_RARITY_REGULAR
	/// Base weapon type name for dynamic name generation (e.g., "blade", "mace")
	var/base_weapon_name = "weapon"

/obj/item/melee/clan_weapon/Initialize()
	. = ..()
	update_rarity_visuals()

/// Set weapon rarity and update visuals/name
/obj/item/melee/clan_weapon/proc/set_rarity(new_rarity)
	rarity = new_rarity
	update_rarity_visuals()
	if(rarity == CLAN_RARITY_REGULAR)
		name = "clan [base_weapon_name]"
	else
		name = "[lowertext(clan_rarity_name(rarity))] clan [base_weapon_name]"

/// Update the outline filter to match current rarity
/obj/item/melee/clan_weapon/proc/update_rarity_visuals()
	var/color = clan_rarity_color(rarity)
	remove_filter("clan_rarity")
	add_filter("clan_rarity", 2, list("type" = "outline", "color" = color, "size" = 1))

/// Get faith-based damage multiplier for the user
/obj/item/melee/clan_weapon/proc/get_faith_multiplier(mob/living/user)
	if(!ishuman(user))
		return 1.0
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		return 1.0
	if(core.faith >= 80)
		return 1.15
	if(core.faith >= 60)
		return 1.0
	if(core.faith >= 40)
		return 0.9
	if(core.faith >= 20)
		return 0.8
	return 0.7

/obj/item/melee/clan_weapon/attack(mob/living/target, mob/living/user)
	var/rarity_mult = clan_rarity_multiplier(rarity)
	var/faith_mult = get_faith_multiplier(user)
	var/total_mult = rarity_mult * faith_mult
	var/original_force = force
	force = round(force * total_mult)
	if(faith_mult < 0.9)
		to_chat(user, span_warning("The weapon feels sluggish in your hands..."))
	else if(faith_mult > 1.0)
		to_chat(user, span_notice("Faith empowers your strike!"))
	. = ..()
	force = original_force

/obj/item/melee/clan_weapon/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [clan_rarity_name(rarity)]")
	. += span_notice("This weapon's power scales with your faith level.")

// ==================== Clan Blade ====================
// Fast, lower damage. Inspired by scout units.

/obj/item/melee/clan_weapon/blade
	name = "clan blade"
	desc = "A sleek blade forged in the clan style. Its edge hums with potential energy. Fast and precise."
	icon_state = "claymore"
	base_weapon_name = "blade"
	force = 20
	throwforce = 15
	armour_penetration = 5
	block_chance = 15
	sharpness = SHARP_EDGED
	attack_speed = 0.875
	attack_verb_continuous = list("slashes", "cuts", "strikes")
	attack_verb_simple = list("slash", "cut", "strike")
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/melee/clan_weapon/blade/militia
	name = "militia clan blade"
	desc = "A crude blade hastily forged from scrap metal. Barely sharp, but functional."
	rarity = CLAN_RARITY_MILITIA

/obj/item/melee/clan_weapon/blade/veteran
	name = "veteran clan blade"
	desc = "A battle-tested blade with a razor edge. Its balance speaks to expert craftsmanship."
	rarity = CLAN_RARITY_VETERAN

/obj/item/melee/clan_weapon/blade/elite
	name = "elite clan blade"
	desc = "A masterwork blade that seems to cut through the air itself. The pinnacle of clan weaponsmithing."
	rarity = CLAN_RARITY_ELITE

// ==================== Clan Mace ====================
// Slow, high damage. Inspired by defender units.

/obj/item/melee/clan_weapon/mace
	name = "clan mace"
	desc = "A heavy bludgeon forged in the clan style. Slow but devastating, capable of crushing armor and structures alike."
	icon_state = "stunprod"
	base_weapon_name = "mace"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 30
	throwforce = 20
	armour_penetration = 10
	block_chance = 20
	sharpness = SHARP_NONE
	attack_speed = 1.5
	attack_verb_continuous = list("bashes", "crushes", "smashes")
	attack_verb_simple = list("bash", "crush", "smash")
	hitsound = 'sound/weapons/smash.ogg'

/obj/item/melee/clan_weapon/mace/militia
	name = "militia clan mace"
	desc = "A crude bludgeon made from scrap metal and wood. Heavy and unwieldy, but it gets the job done."
	rarity = CLAN_RARITY_MILITIA

/obj/item/melee/clan_weapon/mace/veteran
	name = "veteran clan mace"
	desc = "A reinforced bludgeon with a weighted head. Each swing carries tremendous force."
	rarity = CLAN_RARITY_VETERAN

/obj/item/melee/clan_weapon/mace/elite
	name = "elite clan mace"
	desc = "A masterwork bludgeon with a head of compressed alloy. It can crack through any defense."
	rarity = CLAN_RARITY_ELITE

// ==================== Scout's Spear ====================
// Acceleration gimmick — momentum builds on consecutive hits.

/obj/item/melee/clan_weapon/spear
	name = "clan spear"
	desc = "A lightweight spear inspired by clan scout units. Gains momentum with each consecutive strike, increasing speed and power."
	icon_state = "spearglass0"
	base_weapon_name = "spear"
	force = 15
	throwforce = 20
	armour_penetration = 5
	block_chance = 10
	sharpness = SHARP_POINTY
	attack_speed = 1.0
	attack_verb_continuous = list("stabs", "jabs", "thrusts")
	attack_verb_simple = list("stab", "jab", "thrust")
	hitsound = 'sound/weapons/bladeslice.ogg'
	/// Current momentum level (0-10)
	var/momentum = 0
	/// The target we're building momentum against
	var/mob/living/last_target
	/// Timer ID for momentum decay
	var/momentum_decay_timer

/obj/item/melee/clan_weapon/spear/attack(mob/living/target, mob/living/user)
	if(target != last_target)
		reset_momentum()
		last_target = target

	var/faith_mult = get_faith_multiplier(user)
	var/momentum_gain
	if(faith_mult >= 1.15)
		momentum_gain = 2
	else if(faith_mult >= 1.0)
		momentum_gain = 1.5
	else if(faith_mult >= 0.9)
		momentum_gain = 1
	else
		momentum_gain = 0.5

	momentum = min(10, momentum + momentum_gain)

	var/rarity_mult = clan_rarity_multiplier(rarity)
	var/momentum_damage_bonus = 1 + momentum * 0.05
	var/original_force = force
	var/original_speed = attack_speed
	force = round(force * rarity_mult * faith_mult * momentum_damage_bonus)
	attack_speed = max(0.5, 1.0 - momentum * 0.05)

	update_momentum_visuals()

	. = ..()

	force = original_force
	attack_speed = original_speed

	momentum = max(0, momentum - 1)

	if(momentum_decay_timer)
		deltimer(momentum_decay_timer)
	momentum_decay_timer = addtimer(CALLBACK(src, PROC_REF(reset_momentum)), 5 SECONDS, TIMER_STOPPABLE)

/// Reset momentum to 0 and clear visuals
/obj/item/melee/clan_weapon/spear/proc/reset_momentum()
	momentum = 0
	last_target = null
	momentum_decay_timer = null
	cut_overlays()
	attack_speed = initial(attack_speed)

/// Update flame overlays based on momentum level
/obj/item/melee/clan_weapon/spear/proc/update_momentum_visuals()
	cut_overlays()
	update_rarity_visuals()

/obj/item/melee/clan_weapon/spear/examine(mob/user)
	. = ..()
	if(momentum >= 8)
		. += span_notice("The spear burns with intense blue energy!")
	else if(momentum >= 4)
		. += span_notice("The spear glows with red energy.")
	. += span_notice("Momentum builds with consecutive hits on the same target.")

/obj/item/melee/clan_weapon/spear/militia
	name = "militia clan spear"
	desc = "A crude spear hastily assembled from scrap. Barely balanced, but functional."
	rarity = CLAN_RARITY_MILITIA

/obj/item/melee/clan_weapon/spear/veteran
	name = "veteran clan spear"
	desc = "A battle-tested spear with expert balance. Momentum builds quickly in skilled hands."
	rarity = CLAN_RARITY_VETERAN

/obj/item/melee/clan_weapon/spear/elite
	name = "elite clan spear"
	desc = "A masterwork spear that hums with energy. Each strike builds devastating momentum."
	rarity = CLAN_RARITY_ELITE

// ==================== Defender's Gauntlets ====================
// Taunt/lockdown gimmick — forces hostiles to target you.

/obj/item/melee/clan_weapon/gauntlets
	name = "clan gauntlets"
	desc = "Heavy gauntlets inspired by clan defender units. Each strike draws enemy attention, and can create a lockdown zone."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "gauntlettemplate"
	base_weapon_name = "gauntlets"
	force = 18
	throwforce = 10
	armour_penetration = 5
	block_chance = 30
	sharpness = SHARP_NONE
	attack_speed = 1.0
	attack_verb_continuous = list("punches", "slams", "crushes")
	attack_verb_simple = list("punch", "slam", "crush")
	hitsound = 'sound/weapons/smash.ogg'
	COOLDOWN_DECLARE(lockdown_cd)

/obj/item/melee/clan_weapon/gauntlets/attack(mob/living/target, mob/living/user)
	if(istype(target, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/H = target
		H.GiveTarget(user)
		to_chat(user, span_notice("You slam [target], drawing its attention!"))
	. = ..()

/obj/item/melee/clan_weapon/gauntlets/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, lockdown_cd))
		to_chat(user, span_warning("The gauntlets are still recharging. ([round((lockdown_cd - world.time) / 10)]s remaining)"))
		return

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 8)
		to_chat(user, span_warning("You lack sufficient faith to activate the lockdown. (Need 8, have [core ? round(core.faith, 0.1) : 0])"))
		return

	core.adjust_faith(-8)
	COOLDOWN_START(src, lockdown_cd, 30 SECONDS)

	to_chat(user, span_danger("You slam your gauntlets together, creating a lockdown zone!"))
	playsound(src, 'sound/weapons/resonator_blast.ogg', 50, TRUE)

	for(var/turf/T in range(1, user))
		var/obj/effect/defender_field/DF = new(T)
		DF.defender = null
		QDEL_IN(DF, 5 SECONDS)

	for(var/mob/living/simple_animal/hostile/M in range(2, user))
		if(M.stat == DEAD)
			continue
		M.GiveTarget(user)

/obj/item/melee/clan_weapon/gauntlets/examine(mob/user)
	. = ..()
	. += span_notice("Click in-hand to activate Lockdown Pulse (8 faith, 30s cooldown).")
	. += span_notice("Each melee hit taunts hostile mobs to target you.")

/obj/item/melee/clan_weapon/gauntlets/militia
	name = "militia clan gauntlets"
	desc = "Crude gauntlets cobbled from scrap metal. Heavy but effective at drawing attention."
	rarity = CLAN_RARITY_MILITIA

/obj/item/melee/clan_weapon/gauntlets/veteran
	name = "veteran clan gauntlets"
	desc = "Reinforced gauntlets with integrated field generators. Their lockdown pulse is formidable."
	rarity = CLAN_RARITY_VETERAN

/obj/item/melee/clan_weapon/gauntlets/elite
	name = "elite clan gauntlets"
	desc = "Masterwork gauntlets that crackle with energy. Nothing escapes their lockdown."
	rarity = CLAN_RARITY_ELITE

// ==================== Assassin's Dagger ====================
// Backstab gimmick — bonus damage from behind, scales with faith.

/obj/item/melee/clan_weapon/dagger
	name = "clan dagger"
	desc = "A sleek dagger inspired by clan assassin units. Devastating when striking from behind."
	icon_state = "switchblade"
	base_weapon_name = "dagger"
	force = 12
	throwforce = 15
	armour_penetration = 10
	block_chance = 5
	sharpness = SHARP_EDGED
	attack_speed = 0.75
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("stabs", "slashes", "shanks")
	attack_verb_simple = list("stab", "slash", "shank")
	hitsound = 'sound/weapons/bladeslice.ogg'

/// Get backstab multiplier based on faith (replaces normal faith scaling)
/obj/item/melee/clan_weapon/dagger/proc/get_backstab_multiplier(mob/living/user)
	if(!ishuman(user))
		return 1.25
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		return 1.25
	if(core.faith >= 80)
		return 2.5
	if(core.faith >= 60)
		return 2.0
	if(core.faith >= 40)
		return 1.75
	if(core.faith >= 20)
		return 1.5
	return 1.25

/// Check if the user is behind the target
/obj/item/melee/clan_weapon/dagger/proc/is_behind_target(mob/living/target, mob/living/user)
	var/target_dir = target.dir
	var/attack_dir = get_dir(target, user)
	if(target_dir == NORTH && (attack_dir & SOUTH))
		return TRUE
	if(target_dir == SOUTH && (attack_dir & NORTH))
		return TRUE
	if(target_dir == EAST && (attack_dir & WEST))
		return TRUE
	if(target_dir == WEST && (attack_dir & EAST))
		return TRUE
	return FALSE

/obj/item/melee/clan_weapon/dagger/attack(mob/living/target, mob/living/user)
	var/rarity_mult = clan_rarity_multiplier(rarity)
	var/original_force = force

	if(is_behind_target(target, user))
		var/backstab_mult = get_backstab_multiplier(user)
		force = round(force * rarity_mult * backstab_mult)
		to_chat(user, span_danger("You strike from the shadows!"))
		playsound(src, 'sound/weapons/bladeslice.ogg', 70, TRUE)
	else
		var/faith_mult = get_faith_multiplier(user)
		force = round(force * rarity_mult * faith_mult)

	. = ..()
	force = original_force

/obj/item/melee/clan_weapon/dagger/examine(mob/user)
	. = ..()
	. += span_notice("Deals bonus damage when striking from behind (backstab).")
	. += span_notice("Backstab damage scales with your faith level.")

/obj/item/melee/clan_weapon/dagger/militia
	name = "militia clan dagger"
	desc = "A crude shiv cobbled from scrap. Not elegant, but it gets the job done from behind."
	rarity = CLAN_RARITY_MILITIA

/obj/item/melee/clan_weapon/dagger/veteran
	name = "veteran clan dagger"
	desc = "A razor-sharp dagger balanced for silent strikes. Its edge finds gaps in any defense."
	rarity = CLAN_RARITY_VETERAN

/obj/item/melee/clan_weapon/dagger/elite
	name = "elite clan dagger"
	desc = "A masterwork assassin's blade. In faithful hands, a single backstab can fell any foe."
	rarity = CLAN_RARITY_ELITE
