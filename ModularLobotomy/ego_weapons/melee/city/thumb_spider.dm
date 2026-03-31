// Thumb Spider Weapons
// Thumbfather weapons are subtypes of /obj/item/ego_weapon/city (NOT thumb_east)
// Thumbapprentice weapons are basic city ego weapons
//
////////////////////////////////////////////////////////////
// THUMB NURSEFATHER WEAPON SYSTEM
//
// The Thumbfather Rapier and Katana are a dual-wield pair designed around the Poise/Concentration system.
// They use a unique ammo type called Acceleration Rounds (stacks to 12, double normal).
//
// === CORE LOOP ===
// Only dual-wield follow-ups and combo actions spend Acceleration Rounds. Basic attacks do not.
// When a round is spent:
//   - Rapier: grants 5 Poise to user + applies 4 Overheat to target
//   - Katana: grants 1 Concentration to user + applies 3 Tremor to target (no burst)
// Poise crits outside the combo also boost status effects:
//   - Rapier crit: +2 Overheat to target
//   - Katana crit: +2 Tremor to target (no burst)
//
// === DUAL-WIELD ===
// Every 2nd hit with one weapon triggers the partner weapon at 25% damage.
// The follow-up still spends ammo and grants buffs, but does NOT advance the cross-combo.
//
// === CROSS-COMBO (3 stages, costs 4 rounds total) ===
// 1. OPENER: Click a target from range with either weapon (costs 1 round). Records which weapon started.
// 2. SWITCH: Hit the target in melee with the OTHER weapon (costs 1 round). Must swap active hand.
//    - Hitting with the same weapon as the opener BREAKS the combo.
// 3. FINISHER: Hit the target in melee with the STARTING weapon (costs 2 rounds). Must swap back.
//    - Hitting with the wrong weapon BREAKS the combo.
//    - The finisher rolls for a Poise crit. If it crits:
//      a) Reads the target's current Tremor + Overheat stacks
//      b) Forces a Tremor Burst (knockdown)
//      c) Deals bonus RED damage equal to (tremor stacks + overheat stacks)
// The combo resets after 5 seconds of inactivity.
//
// Example: Rapier (range) -> Katana (melee) -> Rapier (melee, finisher)
//      or: Katana (range) -> Rapier (melee) -> Katana (melee, finisher)
//
// === RELOAD ===
// - Hit weapon with ammo OR hit ammo with weapon to reload (reverse reload)
// - Loading Acceleration Rounds into one weapon also loads 1 round into the partner (linked reload)
// - Reload is instant (no channeling)
////////////////////////////////////////////////////////////

// Cross-combo stages
#define CROSS_NONE 0
#define CROSS_OPENED 1
#define CROSS_SWITCHED 2

////////////////////////////////////////////////////////////
// THUMBFATHER SHARED PROCS

/// Helper proc to find the partner thumbfather weapon in the user's other hand
/proc/find_thumbfather_partner(obj/item/ego_weapon/city/source, mob/living/carbon/human/user)
	if(!istype(user))
		return null
	for(var/obj/item/ego_weapon/city/W in user.held_items)
		if(W == source)
			continue
		if(istype(W, /obj/item/ego_weapon/city/thumbfather_rapier) || istype(W, /obj/item/ego_weapon/city/thumbfather_katana))
			return W
	return null

/// Returns TRUE if this weapon is the rapier type
/proc/is_thumbfather_rapier(obj/item/ego_weapon/city/weapon)
	return istype(weapon, /obj/item/ego_weapon/city/thumbfather_rapier)

/// Spends one acceleration round from the weapon if available. Returns TRUE if spent, FALSE otherwise.
/// Also creates the spent cartridge and applies weapon-specific buffs/debuffs.
/proc/spend_acceleration_round(obj/item/ego_weapon/city/weapon, mob/living/user, mob/living/target)
	// Access ammo list via the thumbfather vars
	var/list/ammo_list
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		ammo_list = R.current_ammo
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		ammo_list = K.current_ammo
	if(!length(ammo_list))
		return FALSE
	var/obj/item/stack/thumb_east_ammo/acceleration/accel_round
	for(var/obj/item/stack/thumb_east_ammo/acceleration/round in ammo_list)
		accel_round = round
		break
	if(!accel_round)
		return FALSE
	ammo_list -= accel_round
	if(!length(ammo_list))
		if(is_thumbfather_rapier(weapon))
			var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
			R.current_ammo_type = null
			R.current_ammo_name = ""
		else
			var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
			K.current_ammo_type = null
			K.current_ammo_name = ""
	var/obj/item/stack/thumb_east_ammo/spent/new_spent = new accel_round.spent_type(weapon)
	new_spent.forceMove(get_turf(weapon))
	if(is_thumbfather_rapier(weapon))
		user.apply_lc_poise(accel_round.poise_base)
		if(isliving(target))
			target.apply_lc_overheat(4)
	else
		user.apply_lc_concentration(accel_round.concentration_base)
		if(isliving(target))
			target.apply_lc_tremor(3, INFINITY)
	qdel(accel_round)
	return TRUE

/// Cross-combo finisher: tremor burst the target and deal bonus RED damage equal to (tremor + overheat stacks)
/proc/thumbfather_cross_finisher(mob/living/target, mob/living/user)
	var/tremor_stacks = 0
	var/overheat_stacks = 0
	var/datum/status_effect/stacking/lc_tremor/T = target.has_status_effect(/datum/status_effect/stacking/lc_tremor)
	if(T)
		tremor_stacks = T.stacks
	var/datum/status_effect/stacking/lc_burn/B = target.has_status_effect(/datum/status_effect/stacking/lc_burn)
	if(B)
		overheat_stacks = B.stacks
	var/bonus_damage = tremor_stacks + overheat_stacks
	if(T)
		T.TremorBurst()
	if(bonus_damage > 0)
		target.deal_damage(bonus_damage, RED_DAMAGE, source = user, attack_type = ATTACK_TYPE_MELEE)
		to_chat(user, span_green("Your finishing strike detonates for [bonus_damage] bonus damage!"))
	to_chat(target, span_userdanger("[user]'s finishing strike detonates the built-up tremor and heat!"))

/// Syncs cross-combo state to both weapons
/proc/sync_cross_combo(obj/item/ego_weapon/city/weapon, obj/item/ego_weapon/city/partner, new_stage, new_starter_is_rapier)
	var/list/weapons = list(weapon)
	if(partner)
		weapons += partner
	for(var/obj/item/ego_weapon/city/W in weapons)
		if(is_thumbfather_rapier(W))
			var/obj/item/ego_weapon/city/thumbfather_rapier/R = W
			deltimer(R.cross_combo_timer)
			R.cross_combo_stage = new_stage
			R.cross_combo_starter_is_rapier = new_starter_is_rapier
			if(new_stage != CROSS_NONE)
				R.cross_combo_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reset_cross_combo), weapon, partner), 5 SECONDS, TIMER_STOPPABLE)
		else
			var/obj/item/ego_weapon/city/thumbfather_katana/K = W
			deltimer(K.cross_combo_timer)
			K.cross_combo_stage = new_stage
			K.cross_combo_starter_is_rapier = new_starter_is_rapier
			if(new_stage != CROSS_NONE)
				K.cross_combo_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reset_cross_combo), weapon, partner), 5 SECONDS, TIMER_STOPPABLE)

/// Resets cross-combo on timeout
/proc/reset_cross_combo(obj/item/ego_weapon/city/weapon, obj/item/ego_weapon/city/partner)
	sync_cross_combo(weapon, partner, CROSS_NONE, FALSE)
	if(ismob(weapon?.loc))
		to_chat(weapon.loc, span_warning("Your cross-combo has expired."))

/// Handles melee hit cross-combo logic. Returns TRUE if finisher should trigger.
/proc/handle_cross_combo_melee(obj/item/ego_weapon/city/weapon, mob/living/carbon/human/user, cross_stage, starter_is_rapier)
	if(cross_stage == CROSS_NONE)
		return FALSE
	var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(weapon, user)
	var/weapon_is_rapier = is_thumbfather_rapier(weapon)
	if(cross_stage == CROSS_OPENED)
		if(weapon_is_rapier != starter_is_rapier)
			sync_cross_combo(weapon, partner, CROSS_SWITCHED, starter_is_rapier)
			to_chat(user, span_info("Cross-combo: weapon switch! Finish with your starting weapon!"))
			return FALSE
		else
			sync_cross_combo(weapon, partner, CROSS_NONE, FALSE)
			to_chat(user, span_warning("Cross-combo broken! You needed to switch weapons."))
			return FALSE
	if(cross_stage == CROSS_SWITCHED)
		if(weapon_is_rapier == starter_is_rapier)
			sync_cross_combo(weapon, partner, CROSS_NONE, FALSE)
			return TRUE
		else
			sync_cross_combo(weapon, partner, CROSS_NONE, FALSE)
			to_chat(user, span_warning("Cross-combo broken! You needed to finish with your starting weapon."))
			return FALSE
	return FALSE

/// Synchronous reload proc for thumbfather weapons. Loads rounds from ammo stack into weapon, with linked reload for partner.
/proc/thumbfather_reload(obj/item/ego_weapon/city/weapon, obj/item/stack/thumb_east_ammo/ammo, mob/living/user, list/current_ammo, max_ammo, list/accepted_ammo_table)
	if(!(ammo.type in accepted_ammo_table))
		to_chat(user, span_warning("The [ammo.name] are incompatible with the [weapon.name]."))
		return
	var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(weapon, user)
	var/is_acceleration = istype(ammo, /obj/item/stack/thumb_east_ammo/acceleration)
	// Load rounds into this weapon up to capacity
	while(length(current_ammo) < max_ammo && ammo && !QDELETED(ammo) && ammo.amount >= 1)
		var/obj/item/stack/thumb_east_ammo/bullet = ammo.split_stack(user, 1)
		if(!bullet)
			break
		bullet.forceMove(weapon)
		current_ammo += bullet
		// Update ammo type tracking
		if(is_thumbfather_rapier(weapon))
			var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
			R.current_ammo_type = ammo.type
			R.current_ammo_name = ammo.name
		else
			var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
			K.current_ammo_type = ammo.type
			K.current_ammo_name = ammo.name
		to_chat(user, span_info("You load a [ammo.singular_name] into the [weapon.name]."))
		// Linked reload: also load 1 into partner for each round loaded
		if(is_acceleration && partner)
			var/list/partner_ammo
			var/partner_max
			var/list/partner_accepted
			if(is_thumbfather_rapier(partner))
				var/obj/item/ego_weapon/city/thumbfather_rapier/R = partner
				partner_ammo = R.current_ammo
				partner_max = R.max_ammo
				partner_accepted = R.accepted_ammo_table
			else
				var/obj/item/ego_weapon/city/thumbfather_katana/K = partner
				partner_ammo = K.current_ammo
				partner_max = K.max_ammo
				partner_accepted = K.accepted_ammo_table
			if((ammo.type in partner_accepted) && length(partner_ammo) < partner_max && ammo && !QDELETED(ammo) && ammo.amount >= 1)
				var/obj/item/stack/thumb_east_ammo/partner_bullet = ammo.split_stack(user, 1)
				if(partner_bullet)
					partner_bullet.forceMove(partner)
					partner_ammo += partner_bullet
					if(is_thumbfather_rapier(partner))
						var/obj/item/ego_weapon/city/thumbfather_rapier/R = partner
						R.current_ammo_type = ammo.type
						R.current_ammo_name = ammo.name
					else
						var/obj/item/ego_weapon/city/thumbfather_katana/K = partner
						K.current_ammo_type = ammo.type
						K.current_ammo_name = ammo.name
					to_chat(user, span_info("A round is also loaded into your [partner.name]."))

////////////////////////////////////////////////////////////
// THUMBFATHER RAPIER
/obj/item/ego_weapon/city/thumbfather_rapier
	name = "thumbfather rapier"
	desc = "A slender, elegant rapier favored by a thumbfather. Its reach is deceptively long."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbfather_rapier"
	inhand_icon_state = "thumbfather_rapier"
	base_pixel_x = 8
	base_pixel_y = 8
	force = 45
	damtype = RED_DAMAGE
	attack_speed = 0.8
	attack_verb_continuous = list("thrusts", "pierces", "lunges")
	attack_verb_simple = list("thrust", "pierce", "lunge")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	/// Ammo types this weapon can load
	var/list/accepted_ammo_table = list(
		/obj/item/stack/thumb_east_ammo/acceleration,
	)
	/// Maximum ammo capacity
	var/max_ammo = 6
	/// Loaded rounds
	var/list/current_ammo = list()
	/// Type path of currently loaded ammo
	var/current_ammo_type
	/// Display name of currently loaded ammo
	var/current_ammo_name = ""
	/// Whether this weapon is currently performing a dual-wield follow-up attack
	var/busy_dual_strike = FALSE
	/// Tracks hits for dual-wield (triggers on every 2nd hit)
	var/swing_count = 0
	/// Cross-combo stage: CROSS_NONE, CROSS_OPENED, CROSS_SWITCHED
	var/cross_combo_stage = CROSS_NONE
	/// Whether the combo was started by the rapier (TRUE) or katana (FALSE)
	var/cross_combo_starter_is_rapier = FALSE
	/// Timer ID for cross-combo reset
	var/cross_combo_timer
	/// Whether we're currently in a finisher
	var/in_finisher = FALSE

/obj/item/ego_weapon/city/thumbfather_rapier/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

/obj/item/ego_weapon/city/thumbfather_rapier/Destroy(force)
	for(var/obj/item/stack/thumb_east_ammo/leftover in current_ammo)
		leftover.forceMove(get_turf(src))
	current_ammo = null
	return ..()

/obj/item/ego_weapon/city/thumbfather_rapier/equipped(mob/user, slot)
	. = ..()
	RegisterSignal(user, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit), override = TRUE)

/obj/item/ego_weapon/city/thumbfather_rapier/dropped(mob/user)
	UnregisterSignal(user, COMSIG_POISE_CRIT_ATTACKER)
	return ..()

/obj/item/ego_weapon/city/thumbfather_rapier/examine(mob/user)
	. = ..()
	. += span_danger("There are [length(current_ammo)]/[max_ammo] rounds of [length(current_ammo) > 0 ? current_ammo_name : "ammunition"] currently loaded.")
	if(cross_combo_stage == CROSS_OPENED)
		. += span_info("Cross-combo: waiting for weapon switch.")
	else if(cross_combo_stage == CROSS_SWITCHED)
		. += span_info("Cross-combo: finisher ready!")

/// On Poise crit: if finisher, detonate. Otherwise, boost overheat by 2.
/obj/item/ego_weapon/city/thumbfather_rapier/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	if(in_finisher)
		in_finisher = FALSE
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_cross_finisher), target, source)
	else
		target.apply_lc_overheat(2)

/obj/item/ego_weapon/city/thumbfather_rapier/attack(mob/living/target, mob/living/carbon/human/user)
	// Cross-combo melee: advance or break based on weapon order
	var/is_finisher = FALSE
	if(!busy_dual_strike && cross_combo_stage != CROSS_NONE)
		is_finisher = handle_cross_combo_melee(src, user, cross_combo_stage, cross_combo_starter_is_rapier)
	if(is_finisher)
		in_finisher = TRUE
		// Finisher spends 2 rounds
		spend_acceleration_round(src, user, target)
		spend_acceleration_round(src, user, target)
	. = ..()
	in_finisher = FALSE
	// Dual-wield: trigger partner every 2nd hit, spending ammo for poise/concentration/effects
	if(!busy_dual_strike)
		swing_count++
		if(swing_count >= 2)
			swing_count = 0
			var/obj/item/ego_weapon/city/thumbfather_katana/partner = find_thumbfather_partner(src, user)
			if(partner && !partner.busy_dual_strike && (target in view(partner.reach, user)))
				// Spend ammo on the dual-wield follow-up (this is where buffs/debuffs come from)
				spend_acceleration_round(partner, user, target)
				partner.busy_dual_strike = TRUE
				var/original_force = partner.force
				partner.force = round(original_force * 0.25)
				playsound(partner.loc, partner.hitsound, 50, FALSE)
				user.do_attack_animation(target, null, partner)
				target.attacked_by(partner, user)
				partner.force = original_force
				partner.busy_dual_strike = FALSE

/// Reverse reload + cross-combo opener from range
/obj/item/ego_weapon/city/thumbfather_rapier/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	// Reverse reload: clicking ammo with the weapon
	if(istype(target, /obj/item/stack/thumb_east_ammo))
		var/obj/item/stack/thumb_east_ammo/ammo = target
		thumbfather_reload(src, ammo, user, current_ammo, max_ammo, accepted_ammo_table)
		return TRUE
	// Cross-combo opener from range (spends 1 round)
	if(isliving(target) && !proximity_flag && cross_combo_stage == CROSS_NONE)
		if(spend_acceleration_round(src, user, target))
			var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(src, user)
			sync_cross_combo(src, partner, CROSS_OPENED, TRUE)
			to_chat(user, span_info("Cross-combo started with rapier! Switch to katana and hit!"))
			return TRUE

/// Load ammo by hitting the weapon with it
/obj/item/ego_weapon/city/thumbfather_rapier/attackby(obj/item/stack/thumb_east_ammo/I, mob/living/user, params)
	if(!istype(I))
		return ..()
	thumbfather_reload(src, I, user, current_ammo, max_ammo, accepted_ammo_table)

/// Unload a round by using in-hand
/obj/item/ego_weapon/city/thumbfather_rapier/AltClick(mob/user)
	. = ..()
	if(length(current_ammo))
		var/obj/item/stack/thumb_east_ammo/round = current_ammo[length(current_ammo)]
		current_ammo -= round
		round.forceMove(get_turf(src))
		to_chat(user, span_info("You unload a round from the [src.name]."))
		if(!length(current_ammo))
			current_ammo_type = null
			current_ammo_name = ""
	else
		to_chat(user, span_warning("The [src.name] is empty."))

////////////////////////////////////////////////////////////
// THUMBFATHER KATANA
/obj/item/ego_weapon/city/thumbfather_katana
	name = "thumbfather katana"
	desc = "A finely crafted katana carried by a thumbfather. Each swing carries the weight of authority."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbfather_katana"
	inhand_icon_state = "thumbfather_katana"
	base_pixel_x = 8
	base_pixel_y = 8
	force = 55
	damtype = RED_DAMAGE
	attack_speed = 1.1
	attack_verb_continuous = list("slashes", "cleaves", "cuts")
	attack_verb_simple = list("slash", "cleave", "cut")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	/// Ammo types this weapon can load
	var/list/accepted_ammo_table = list(
		/obj/item/stack/thumb_east_ammo/acceleration,
	)
	/// Maximum ammo capacity
	var/max_ammo = 6
	/// Loaded rounds
	var/list/current_ammo = list()
	/// Type path of currently loaded ammo
	var/current_ammo_type
	/// Display name of currently loaded ammo
	var/current_ammo_name = ""
	/// Whether this weapon is currently performing a dual-wield follow-up attack
	var/busy_dual_strike = FALSE
	/// Tracks hits for dual-wield (triggers on every 2nd hit)
	var/swing_count = 0
	/// Cross-combo stage: CROSS_NONE, CROSS_OPENED, CROSS_SWITCHED
	var/cross_combo_stage = CROSS_NONE
	/// Whether the combo was started by the rapier (TRUE) or katana (FALSE)
	var/cross_combo_starter_is_rapier = FALSE
	/// Timer ID for cross-combo reset
	var/cross_combo_timer
	/// Whether we're currently in a finisher
	var/in_finisher = FALSE

/obj/item/ego_weapon/city/thumbfather_katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

/obj/item/ego_weapon/city/thumbfather_katana/Destroy(force)
	for(var/obj/item/stack/thumb_east_ammo/leftover in current_ammo)
		leftover.forceMove(get_turf(src))
	current_ammo = null
	return ..()

/obj/item/ego_weapon/city/thumbfather_katana/equipped(mob/user, slot)
	. = ..()
	RegisterSignal(user, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit), override = TRUE)

/obj/item/ego_weapon/city/thumbfather_katana/dropped(mob/user)
	UnregisterSignal(user, COMSIG_POISE_CRIT_ATTACKER)
	return ..()

/obj/item/ego_weapon/city/thumbfather_katana/examine(mob/user)
	. = ..()
	. += span_danger("There are [length(current_ammo)]/[max_ammo] rounds of [length(current_ammo) > 0 ? current_ammo_name : "ammunition"] currently loaded.")
	if(cross_combo_stage == CROSS_OPENED)
		. += span_info("Cross-combo: waiting for weapon switch.")
	else if(cross_combo_stage == CROSS_SWITCHED)
		. += span_info("Cross-combo: finisher ready!")

/// On Poise crit: if finisher, detonate. Otherwise, boost tremor by 2.
/obj/item/ego_weapon/city/thumbfather_katana/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	if(in_finisher)
		in_finisher = FALSE
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_cross_finisher), target, source)
	else
		target.apply_lc_tremor(2, INFINITY)

/obj/item/ego_weapon/city/thumbfather_katana/attack(mob/living/target, mob/living/carbon/human/user)
	var/is_finisher = FALSE
	if(!busy_dual_strike && cross_combo_stage != CROSS_NONE)
		is_finisher = handle_cross_combo_melee(src, user, cross_combo_stage, cross_combo_starter_is_rapier)
	if(is_finisher)
		in_finisher = TRUE
		// Finisher spends 2 rounds
		spend_acceleration_round(src, user, target)
		spend_acceleration_round(src, user, target)
	. = ..()
	in_finisher = FALSE
	// Dual-wield: trigger partner every 2nd hit, spending ammo for poise/concentration/effects
	if(!busy_dual_strike)
		swing_count++
		if(swing_count >= 2)
			swing_count = 0
			var/obj/item/ego_weapon/city/thumbfather_rapier/partner = find_thumbfather_partner(src, user)
			if(partner && !partner.busy_dual_strike && (target in view(partner.reach, user)))
				// Spend ammo on the dual-wield follow-up (this is where buffs/debuffs come from)
				spend_acceleration_round(partner, user, target)
				partner.busy_dual_strike = TRUE
				var/original_force = partner.force
				partner.force = round(original_force * 0.25)
				playsound(partner.loc, partner.hitsound, 50, FALSE)
				user.do_attack_animation(target, null, partner)
				target.attacked_by(partner, user)
				partner.force = original_force
				partner.busy_dual_strike = FALSE

/// Reverse reload + cross-combo opener from range
/obj/item/ego_weapon/city/thumbfather_katana/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(istype(target, /obj/item/stack/thumb_east_ammo))
		var/obj/item/stack/thumb_east_ammo/ammo = target
		thumbfather_reload(src, ammo, user, current_ammo, max_ammo, accepted_ammo_table)
		return TRUE
	// Cross-combo opener from range (spends 1 round)
	if(isliving(target) && !proximity_flag && cross_combo_stage == CROSS_NONE)
		if(spend_acceleration_round(src, user, target))
			var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(src, user)
			sync_cross_combo(src, partner, CROSS_OPENED, FALSE)
			to_chat(user, span_info("Cross-combo started with katana! Switch to rapier and hit!"))
			return TRUE

/// Load ammo by hitting the weapon with it
/obj/item/ego_weapon/city/thumbfather_katana/attackby(obj/item/stack/thumb_east_ammo/I, mob/living/user, params)
	if(!istype(I))
		return ..()
	thumbfather_reload(src, I, user, current_ammo, max_ammo, accepted_ammo_table)

/// Unload a round by alt-clicking
/obj/item/ego_weapon/city/thumbfather_katana/AltClick(mob/user)
	. = ..()
	if(length(current_ammo))
		var/obj/item/stack/thumb_east_ammo/round = current_ammo[length(current_ammo)]
		current_ammo -= round
		round.forceMove(get_turf(src))
		to_chat(user, span_info("You unload a round from the [src.name]."))
		if(!length(current_ammo))
			current_ammo_type = null
			current_ammo_name = ""
	else
		to_chat(user, span_warning("The [src.name] is empty."))

////////////////////////////////////////////////////////////
// THUMBAPPRENTICE WEAPONS - Subtypes of /obj/item/ego_weapon/city
/obj/item/ego_weapon/city/thumbapprentice_katana
	name = "thumb apprentice katana"
	desc = "A standard-issue katana given to apprentices of the Thumb. Simple but effective."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbapprentice_katana"
	inhand_icon_state = "thumbapprentice_katana"
	base_pixel_x = 8
	base_pixel_y = 8
	force = 40
	damtype = RED_DAMAGE
	attack_speed = 1
	attack_verb_continuous = list("slashes", "cuts", "strikes")
	attack_verb_simple = list("slash", "cut", "strike")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/city/thumbapprentice_katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

/obj/item/ego_weapon/city/thumbapprentice_greatsword
	name = "thumb apprentice greatsword"
	desc = "A heavy greatsword entrusted to apprentices of the Thumb. What it lacks in speed, it makes up for in raw power."
	icon = 'icons/obj/spider_house/thumb/thumb_weapon_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_left.dmi'
	righthand_file = 'icons/obj/spider_house/thumb/thumb_weapon_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	icon_state = "thumbapprentice_greatsword"
	inhand_icon_state = "thumbapprentice_greatsword"
	base_pixel_x = 8
	base_pixel_y = 8
	force = 55
	damtype = RED_DAMAGE
	attack_speed = 1.5
	attack_verb_continuous = list("cleaves", "smashes", "crushes")
	attack_verb_simple = list("cleave", "smash", "crush")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/city/thumbapprentice_greatsword/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

////////////////////////////////////////////////////////////
// ACCELERATION ROUNDS - Unique ammo for thumbfather weapons
/obj/item/stack/thumb_east_ammo/acceleration
	name = "acceleration propellant ammunition"
	desc = "Specialized propellant ammunition designed for dual-wielded thumbfather weapons. These rounds accelerate the wielder's reflexes, granting heightened focus and poise.\n\
	When loaded into a thumbfather rapier, spending a round grants Poise. When loaded into a thumbfather katana, spending a round grants Concentration.\n\
	Loading one thumbfather weapon will also load a round into the partner weapon in your other hand."
	singular_name = "acceleration propellant round"
	max_amount = 12
	merge_type = /obj/item/stack/thumb_east_ammo/acceleration
	icon_state = "thumb_east"
	spent_type = /obj/item/stack/thumb_east_ammo/spent/acceleration
	tremor_base = 0
	burn_base = 0
	flat_force_base = 6
	heat_generation = 1
	/// Poise stacks granted to the user when spent by a rapier
	var/poise_base = 5
	/// Concentration stacks granted to the user when spent by a katana
	var/concentration_base = 1

/obj/item/stack/thumb_east_ammo/acceleration/examine(mob/user)
	. = ..()
	. += span_notice("Grants [poise_base] Poise when spent by a thumbfather rapier.")
	. += span_notice("Grants [concentration_base] Concentration when spent by a thumbfather katana.")
	. += span_notice("Loading one thumbfather weapon will also load a round into the partner weapon.")

/obj/item/stack/thumb_east_ammo/spent/acceleration
	name = "spent acceleration propellant casings"
	desc = "A spent cartridge of acceleration propellant ammunition. The residual energy has been fully expended."
	singular_name = "spent acceleration propellant casing"
	merge_type = /obj/item/stack/thumb_east_ammo/spent/acceleration
