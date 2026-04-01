// Thumb Spider Weapons
// Thumbfather weapons are subtypes of /obj/item/ego_weapon/city (NOT thumb_east)
// Thumbapprentice weapons are basic city ego weapons
//
////////////////////////////////////////////////////////////
// THUMB NURSEFATHER WEAPON SYSTEM
//
// The Thumbfather Rapier and Katana are a dual-wield pair designed around the Poise/Concentration system.
// They use a unique ammo type called Acceleration Rounds (stacks to 12, double normal capacity).
//
// === CORE LOOP ===
// Acceleration Rounds are spent by dual-wield follow-ups and combo actions. Basic attacks do not spend ammo.
// Every time a round is spent, a detonation sound plays and the camera shakes.
// When a round is spent:
//   - Rapier: grants 5 Poise to user + applies 4 Overheat to target
//   - Katana: grants 1 Concentration to user + applies 3 Tremor to target (no burst)
// Poise crits also passively boost status effects regardless of combo state:
//   - Rapier crit: +2 Overheat to target
//   - Katana crit: +2 Tremor to target (no burst)
//
// === DUAL-WIELD ===
// Every 2nd non-combo hit with one weapon triggers the partner weapon at 25% damage.
// The follow-up spends ammo from the partner and grants its buffs/debuffs.
// Dual-wield follow-ups do NOT advance, trigger, or interact with the combo in any way.
// The swing counter only increments on non-combo hits.
//
// === COMBO (3 stages, costs 4 rounds total, requires weapon swapping) ===
// The combo uses a lunge -> AoE sweep -> finisher pattern, similar to Thumb East weapons,
// but requires swapping between the rapier and katana between each stage.
//
// 1. LUNGE: Click a target from range with either weapon (costs 1 round).
//    Dashes to the target and auto-attacks if in range. 13 second lunge cooldown.
//    If the lunge falls short, you can still land a melee hit with the SAME weapon to continue.
// 2. AoE SWEEP: Hit the target in melee with the OTHER weapon (costs 1 round).
//    Deals the weapon hit + AoE damage (50% of weapon force) in a radius around the user.
//    Hitting with the same weapon as the lunge BREAKS the combo.
// 3. FINISHER: Hit the target in melee with the STARTING weapon (costs 2 rounds).
//    Deals 150% weapon force, then Tremor Bursts the target and deals bonus RED damage
//    equal to (target's Tremor stacks + Overheat stacks).
//    Hitting with the wrong weapon BREAKS the combo.
//
// The combo resets after 5 seconds of inactivity (7 seconds during the finisher window).
// Combo state is synced between both weapons so either can be used at the correct stage.
//
// Example: Rapier (lunge) -> Katana (AoE sweep) -> Rapier (finisher)
//      or: Katana (lunge) -> Rapier (AoE sweep) -> Katana (finisher)
//
// === RELOAD ===
// - Channeled reload: 0.6s start + 0.4s per round loaded. Can be interrupted (fumble).
// - Hit weapon with ammo OR hit ammo with weapon to reload (reverse reload).
// - Loading Acceleration Rounds into one weapon also loads 1 round into the partner (linked reload).
// - Reload start resets the combo and plays sound effects.
// - Alt-click to manually unload a single round.
//
// === SOUNDS ===
// - Rapier hitsound: thumb_east_rifle_attack.ogg
// - Katana hitsound: thumb_east_podao_attack.ogg
// - Detonation (on every ammo spend): weapon's detonation_sound
// - Combo stages use lunge/sweep/finisher sounds from the Thumb East weapon set.
// - Reload uses rifle reload start/load/end/fail sounds.
////////////////////////////////////////////////////////////

// Combo stages
#define NURSEFATHER_COMBO_NONE 0
#define NURSEFATHER_COMBO_LUNGE 1
#define NURSEFATHER_COMBO_ATTACK2 2
#define NURSEFATHER_COMBO_FINISHER 3

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
/// Also creates the spent cartridge, plays a detonation sound, and applies weapon-specific buffs/debuffs.
/// volume: controls the detonation sound volume (default 90, use lower for dual-wield follow-ups)
/proc/spend_acceleration_round(obj/item/ego_weapon/city/weapon, mob/living/user, mob/living/target, volume = 90)
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
	// Play detonation sound on every ammo spend
	var/detonation_sfx
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		detonation_sfx = R.detonation_sound
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		detonation_sfx = K.detonation_sound
	playsound(weapon, detonation_sfx, volume, FALSE, 10)
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

/// Combo finisher: tremor burst the target and deal bonus RED damage equal to (tremor + overheat stacks)
/proc/thumbfather_finisher(mob/living/target, mob/living/user)
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

/// Hits all living mobs in a radius around the user, excluding user and primary target. Used for the AoE sweep.
/proc/thumbfather_radius_aoe(obj/item/ego_weapon/city/weapon, mob/living/user, mob/living/target, radius)
	var/aoe_damage = round(initial(weapon.force) * 0.5)
	for(var/turf/T in orange(radius, user))
		new /obj/effect/temp_visual/thumb_east_aoe_impact(T)
		for(var/mob/living/L in T)
			if(L == user || L == target)
				continue
			L.deal_damage(aoe_damage, weapon.damtype, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

/// Syncs combo state to both weapons. Sets combo_stage and combo_starter_is_rapier on each.
/proc/sync_nursefather_combo(obj/item/ego_weapon/city/weapon, mob/living/user, new_stage, new_starter_is_rapier)
	var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(weapon, user)
	var/list/weapons = list(weapon)
	if(partner)
		weapons += partner
	for(var/obj/item/ego_weapon/city/W in weapons)
		if(is_thumbfather_rapier(W))
			var/obj/item/ego_weapon/city/thumbfather_rapier/R = W
			deltimer(R.combo_reset_timer)
			R.combo_stage = new_stage
			R.combo_starter_is_rapier = new_starter_is_rapier
		else
			var/obj/item/ego_weapon/city/thumbfather_katana/K = W
			deltimer(K.combo_reset_timer)
			K.combo_stage = new_stage
			K.combo_starter_is_rapier = new_starter_is_rapier

/// Resets combo state on both weapons. Shows a warning message if the combo was in progress.
/proc/reset_nursefather_combo(obj/item/ego_weapon/city/weapon, mob/living/user, show_message = TRUE)
	// Check if we should show a reset message (only if combo was in progress past lunge)
	var/was_in_combo = FALSE
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		was_in_combo = (R.combo_stage != NURSEFATHER_COMBO_NONE && R.combo_stage != NURSEFATHER_COMBO_LUNGE)
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		was_in_combo = (K.combo_stage != NURSEFATHER_COMBO_NONE && K.combo_stage != NURSEFATHER_COMBO_LUNGE)
	if(show_message && was_in_combo)
		to_chat(user, span_warning("Your combo resets!"))
	sync_nursefather_combo(weapon, user, NURSEFATHER_COMBO_NONE, FALSE)

/// Starts a combo expiry timer on the active weapon. Resets combo on both weapons when it fires.
/proc/start_nursefather_combo_timer(obj/item/ego_weapon/city/weapon, mob/living/user, extra_time = 0)
	var/duration
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		deltimer(R.combo_reset_timer)
		duration = R.combo_reset_duration + extra_time
		R.combo_reset_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reset_nursefather_combo), weapon, user, TRUE), duration, TIMER_STOPPABLE)
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		deltimer(K.combo_reset_timer)
		duration = K.combo_reset_duration + extra_time
		K.combo_reset_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reset_nursefather_combo), weapon, user, TRUE), duration, TIMER_STOPPABLE)
	// Also cancel any existing timer on the partner so we don't double-reset
	var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(weapon, user)
	if(partner)
		if(is_thumbfather_rapier(partner))
			var/obj/item/ego_weapon/city/thumbfather_rapier/R = partner
			deltimer(R.combo_reset_timer)
		else
			var/obj/item/ego_weapon/city/thumbfather_katana/K = partner
			deltimer(K.combo_reset_timer)

/// Channeled reload proc for thumbfather weapons. Loads rounds with do_after, with linked reload for partner.
/proc/thumbfather_reload(obj/item/ego_weapon/city/weapon, obj/item/stack/thumb_east_ammo/ammo, mob/living/user, list/current_ammo, max_ammo, list/accepted_ammo_table)
	if(!(ammo.type in accepted_ammo_table))
		to_chat(user, span_warning("The [ammo.name] are incompatible with the [weapon.name]."))
		return
	var/bullets_in_gun = length(current_ammo)
	if(bullets_in_gun >= max_ammo)
		to_chat(user, span_warning("The [weapon.name] cannot fit any more ammunition - it is fully loaded."))
		return
	var/obj/item/ego_weapon/city/partner = find_thumbfather_partner(weapon, user)
	var/is_acceleration = istype(ammo, /obj/item/stack/thumb_east_ammo/acceleration)
	var/remaining_capacity = max_ammo - bullets_in_gun
	var/amount_to_load = min(ammo.amount, remaining_capacity)

	// Reload start: reset combo and play start sound
	playsound(weapon, 'sound/weapons/ego/thumb_east_rifle_reload_start.ogg', 90, FALSE, 10)
	to_chat(user, span_info("You begin loading your [weapon.name]..."))

	// Set busy on the weapon and reset combo
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		R.busy = TRUE
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		K.busy = TRUE
	reset_nursefather_combo(weapon, user)

	// Calculate how many channeling steps we need - we load 2 rounds per step
	var/load_steps = CEILING(amount_to_load / 2, 1)

	if(do_after(user, 0.6 SECONDS, weapon, progress = TRUE, interaction_key = "thumbfather_reload", max_interact_count = 1))
		// Load 2 rounds per channeling step
		for(var/i in 1 to load_steps)
			if(do_after(user, 0.4 SECONDS, weapon, progress = TRUE, interaction_key = "thumbfather_reload", max_interact_count = 1))
				var/rounds_this_step = min(2, max_ammo - length(current_ammo))
				var/loaded_this_step = 0
				for(var/j in 1 to rounds_this_step)
					if(!ammo || QDELETED(ammo) || ammo.amount < 1)
						break
					var/obj/item/stack/thumb_east_ammo/bullet = ammo.split_stack(user, 1)
					if(!bullet)
						break
					bullet.forceMove(weapon)
					current_ammo += bullet
					loaded_this_step++
				if(!loaded_this_step)
					break
				if(is_thumbfather_rapier(weapon))
					var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
					R.current_ammo_type = ammo.type
					R.current_ammo_name = ammo.name
				else
					var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
					K.current_ammo_type = ammo.type
					K.current_ammo_name = ammo.name
				playsound(weapon, 'sound/weapons/ego/thumb_east_rifle_reload_load.ogg', 90, FALSE, 8)
				to_chat(user, span_info("You load [loaded_this_step] round\s into the [weapon.name]."))
				// Linked reload: also load 2 into partner per step
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
					var/partner_loaded = 0
					for(var/k in 1 to 2)
						if(!((ammo.type in partner_accepted) && length(partner_ammo) < partner_max && ammo && !QDELETED(ammo) && ammo.amount >= 1))
							break
						var/obj/item/stack/thumb_east_ammo/partner_bullet = ammo.split_stack(user, 1)
						if(partner_bullet)
							partner_bullet.forceMove(partner)
							partner_ammo += partner_bullet
							partner_loaded++
					if(partner_loaded)
						if(is_thumbfather_rapier(partner))
							var/obj/item/ego_weapon/city/thumbfather_rapier/R = partner
							R.current_ammo_type = ammo.type
							R.current_ammo_name = ammo.name
						else
							var/obj/item/ego_weapon/city/thumbfather_katana/K = partner
							K.current_ammo_type = ammo.type
							K.current_ammo_name = ammo.name
						to_chat(user, span_info("[partner_loaded] round\s also loaded into your [partner.name]."))
			else
				// Reload interrupted mid-loading
				playsound(weapon, 'sound/weapons/ego/thumb_east_rifle_reload_fail.ogg', 100, FALSE, 6)
				user.visible_message(span_danger("[user] fumbles while reloading!"), span_danger("Your reload is interrupted!"))
				if(is_thumbfather_rapier(weapon))
					var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
					R.busy = FALSE
				else
					var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
					K.busy = FALSE
				return
		// Reload complete
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), weapon, 'sound/weapons/ego/thumb_east_rifle_reload_end.ogg', 90, FALSE, 10), 0.2 SECONDS)
	else
		to_chat(user, span_danger("You abort your reload!"))

	// Clear busy
	if(is_thumbfather_rapier(weapon))
		var/obj/item/ego_weapon/city/thumbfather_rapier/R = weapon
		R.busy = FALSE
	else
		var/obj/item/ego_weapon/city/thumbfather_katana/K = weapon
		K.busy = FALSE

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
	hitsound = 'sound/weapons/ego/thumb_east_rifle_attack.ogg'
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
	special = "This is a Thumbfather dual-wield weapon. <b>Load it with acceleration propellant ammunition</b> and dual-wield it with its partner to unlock its full potential."
	/// Detailed combo description shown on examine
	var/combo_description = "This weapon's combo consists of a <b>long-range lunge</b>, followed by an <b>AoE sweep with the other weapon</b>, and ends with a powerful <b>finisher that detonates Tremor and Overheat</b>.\n"+\
	"<b>Lunge</b>: Attack a target from range to dash at them (costs 1 round).\n"+\
	"<b>AoE Sweep</b>: Swap to your other weapon and hit the target (costs 1 round). Deals AoE damage around you.\n"+\
	"<b>Finisher</b>: Swap back to your starting weapon and hit the target (costs 2 rounds). Tremor Bursts and deals bonus RED damage equal to built-up Tremor + Overheat stacks.\n"+\
	"Hitting with the wrong weapon at any stage <b>breaks the combo</b>. The combo expires after 5 seconds of inactivity."
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
	/// Current combo stage (synced between both weapons)
	var/combo_stage = NURSEFATHER_COMBO_NONE
	/// Whether the combo was started by the rapier (TRUE) or katana (FALSE) (synced between both weapons)
	var/combo_starter_is_rapier = FALSE
	/// Timer for combo reset
	var/combo_reset_timer
	/// Duration before combo resets from inactivity
	var/combo_reset_duration = 5 SECONDS
	/// Whether we can lunge
	var/lunge_ready = TRUE
	/// Lunge distance in tiles
	var/lunge_range = 3
	/// Cooldown between lunges
	var/lunge_cooldown_duration = 13 SECONDS
	/// Timer for lunge cooldown
	var/lunge_cooldown_timer
	/// Base radius for AoE sweep
	var/attack2_aoe_radius = 1
	/// Are we currently performing a channeled action (reloading)?
	var/busy = FALSE
	/// Cooldown for balloon alerts
	var/balloon_alert_cooldown

	// Sound variables
	var/lunge_sound = 'sound/weapons/ego/thumb_east_rifle_boostedlunge.ogg'
	var/sweep_sound = 'sound/weapons/ego/thumb_east_rifle_boostedsweep.ogg'
	var/finisher_sound = 'sound/weapons/ego/thumb_east_rifle_boostedfinisher.ogg'
	var/detonation_sound = 'sound/weapons/ego/thumb_east_rifle_detonation.ogg'
	var/dryfire_sound = 'sound/weapons/gun/general/dry_fire.ogg'

/obj/item/ego_weapon/city/thumbfather_rapier/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

/obj/item/ego_weapon/city/thumbfather_rapier/Destroy(force)
	for(var/obj/item/stack/thumb_east_ammo/leftover in current_ammo)
		leftover.forceMove(get_turf(src))
	current_ammo = null
	deltimer(combo_reset_timer)
	deltimer(lunge_cooldown_timer)
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
	. += span_info(combo_description)
	. += span_notice("Every 2nd non-combo hit triggers a <b>dual-wield follow-up</b> from your partner weapon at 25% damage, spending a round from it.")
	. += span_notice("Spending a round from this rapier grants <b>5 Poise</b> to you and applies <b>4 Overheat</b> to the target. Poise crits also apply +2 Overheat.")
	. += span_notice("<b>Hit the weapon with ammunition</b> to reload (channeled). <b>Alt-click</b> to unload a round.")
	if(combo_stage == NURSEFATHER_COMBO_LUNGE)
		. += span_green("Combo active: lunge landed! [combo_starter_is_rapier ? "Switch to katana" : "Hit with rapier"] for the AoE sweep!")
	else if(combo_stage == NURSEFATHER_COMBO_ATTACK2)
		. += span_green("Combo active: AoE sweep ready! [combo_starter_is_rapier != is_thumbfather_rapier(src) ? "Hit with this weapon!" : "Switch to your other weapon!"]")
	else if(combo_stage == NURSEFATHER_COMBO_FINISHER)
		. += span_green("Combo active: finisher ready! [combo_starter_is_rapier == is_thumbfather_rapier(src) ? "Hit with this weapon!" : "Switch to your other weapon!"]")
	. += span_danger("This weapon's AoE is indiscriminate. <b>Watch out for friendly fire</b>.")

/// On Poise crit: boost overheat by 2
/obj/item/ego_weapon/city/thumbfather_rapier/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	target.apply_lc_overheat(2)

/// Called when the lunge cooldown expires
/obj/item/ego_weapon/city/thumbfather_rapier/proc/ReadyToLunge(mob/user)
	lunge_ready = TRUE
	lunge_cooldown_timer = null
	if(combo_stage == NURSEFATHER_COMBO_NONE)
		to_chat(user, span_nicegreen("You're ready to lunge and begin a new combo again."))
		user.balloon_alert(user, "You're ready to lunge again.")
	else
		to_chat(user, span_nicegreen("You're ready to lunge again, once your current combo is finished."))
		user.balloon_alert(user, "You're ready to lunge again.")

/// Lunge opener: dash towards the target from range and auto-attack if we reach them
/obj/item/ego_weapon/city/thumbfather_rapier/proc/Lunge(mob/living/target, mob/living/user)
	if(!can_see(user, target, lunge_range))
		to_chat(user, span_warning("You can't reach your target!"))
		if(balloon_alert_cooldown < world.time)
			user.balloon_alert(user, "You can't reach your target!")
			balloon_alert_cooldown = world.time + 0.4 SECONDS
		return FALSE
	if(!lunge_ready)
		to_chat(user, span_warning("You're not ready to lunge yet!"))
		if(balloon_alert_cooldown < world.time)
			user.balloon_alert(user, "You're not ready to lunge yet!")
			balloon_alert_cooldown = world.time + 0.4 SECONDS
		return FALSE

	// Set combo stage on both weapons
	sync_nursefather_combo(src, user, NURSEFATHER_COMBO_LUNGE, TRUE)
	if(spend_acceleration_round(src, user, target))
		lunge_ready = FALSE
		lunge_cooldown_timer = addtimer(CALLBACK(src, PROC_REF(ReadyToLunge), user), lunge_cooldown_duration)
		shake_camera(user, 1.5, 3)
		to_chat(user, span_danger("You lunge at [target] using the propulsion from your [src.name]!"))
		var/turf/takeoff_turf = get_turf(user)
		new /obj/effect/temp_visual/thumb_east_aoe_impact(takeoff_turf)
		for(var/i in 2 to get_dist(user, target))
			step_towards(user, target)
		if(get_dist(user, target) < 2)
			hitsound = lunge_sound
			target.attackby(src, user)
		else
			to_chat(user, span_warning("Your lunge falls short of hitting your target!"))
		start_nursefather_combo_timer(src, user)
		return TRUE
	else
		to_chat(user, span_warning("You pull the trigger to lunge at [target], but you have no ammo left."))
		playsound(src, dryfire_sound, 65)
		sync_nursefather_combo(src, user, NURSEFATHER_COMBO_NONE, FALSE)
		return FALSE

/// Main attack proc with combo handling and weapon-swap enforcement
/obj/item/ego_weapon/city/thumbfather_rapier/attack(mob/living/target, mob/living/carbon/human/user)
	if(busy)
		return
	var/weapon_is_rapier = TRUE
	switch(combo_stage)
		if(NURSEFATHER_COMBO_NONE)
			. = ..()
		if(NURSEFATHER_COMBO_LUNGE)
			// Lunge hit must be with the starting weapon
			if(weapon_is_rapier != combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to land the lunge hit with your starting weapon."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				. = ..()
				hitsound = initial(hitsound)
				user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.1)
				sync_nursefather_combo(src, user, NURSEFATHER_COMBO_ATTACK2, combo_starter_is_rapier)
				start_nursefather_combo_timer(src, user)
				to_chat(user, span_info("Combo: switch to your [combo_starter_is_rapier ? "katana" : "rapier"] and hit!"))
		if(NURSEFATHER_COMBO_ATTACK2)
			// AoE sweep must be with the OTHER weapon from the starter
			if(weapon_is_rapier == combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to switch weapons."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				if(spend_acceleration_round(src, user, target))
					shake_camera(user, 1.5, 3)
					hitsound = null
					. = ..()
					playsound(src, sweep_sound, 90, FALSE, 10)
					hitsound = initial(hitsound)
					user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.3)
					thumbfather_radius_aoe(src, user, target, attack2_aoe_radius)
					sync_nursefather_combo(src, user, NURSEFATHER_COMBO_FINISHER, combo_starter_is_rapier)
					start_nursefather_combo_timer(src, user, 2 SECONDS)
					to_chat(user, span_info("Combo: switch back to your [combo_starter_is_rapier ? "rapier" : "katana"] for the finisher!"))
				else
					reset_nursefather_combo(src, user)
					playsound(src, dryfire_sound, 65)
					. = ..()
		if(NURSEFATHER_COMBO_FINISHER)
			// Finisher must be with the STARTING weapon
			if(weapon_is_rapier != combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to finish with your starting weapon."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				var/spent1 = spend_acceleration_round(src, user, target)
				var/spent2 = spend_acceleration_round(src, user, target)
				if(spent1 || spent2)
					shake_camera(user, 2, 4)
					var/original_force = force
					force = round(force * 1.5)
					hitsound = null
					. = ..()
					playsound(src, finisher_sound, 90, FALSE, 10)
					hitsound = initial(hitsound)
					force = original_force
					user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.2)
					thumbfather_finisher(target, user)
				else
					playsound(src, dryfire_sound, 65)
					. = ..()
				reset_nursefather_combo(src, user, FALSE)
	// Dual-wield: trigger partner every 2nd hit, spending ammo for poise/concentration/effects
	// Only triggers on non-combo hits - combo attacks do NOT count towards or trigger dual-wield follow-ups
	if(!busy_dual_strike && combo_stage == NURSEFATHER_COMBO_NONE)
		swing_count++
		if(swing_count >= 2)
			swing_count = 0
			var/obj/item/ego_weapon/city/thumbfather_katana/partner = find_thumbfather_partner(src, user)
			if(partner && !partner.busy_dual_strike && (target in view(partner.reach, user)))
				INVOKE_ASYNC(src, PROC_REF(DualWieldFollowUp), partner, user, target)

/// Delayed dual-wield follow-up attack with the partner weapon
/obj/item/ego_weapon/city/thumbfather_rapier/proc/DualWieldFollowUp(obj/item/ego_weapon/city/thumbfather_katana/partner, mob/living/carbon/human/user, mob/living/target)
	sleep(0.2 SECONDS)
	if(QDELETED(partner) || QDELETED(user) || QDELETED(target))
		return
	if(!(target in view(partner.reach, user)))
		return
	spend_acceleration_round(partner, user, target, 50)
	partner.busy_dual_strike = TRUE
	var/original_force = partner.force
	partner.force = round(original_force * 0.25)
	user.do_attack_animation(target, null, partner)
	target.attacked_by(partner, user)
	partner.force = original_force
	partner.busy_dual_strike = FALSE

/// Lunge from range + reverse reload
/obj/item/ego_weapon/city/thumbfather_rapier/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	// Reverse reload: clicking ammo with the weapon
	if(istype(target, /obj/item/stack/thumb_east_ammo))
		var/obj/item/stack/thumb_east_ammo/ammo = target
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_reload), src, ammo, user, current_ammo, max_ammo, accepted_ammo_table)
		return TRUE
	if(!isliving(target))
		return TRUE
	if(busy)
		return TRUE
	// Lunge from range
	if(!proximity_flag && combo_stage == NURSEFATHER_COMBO_NONE)
		Lunge(target, user)
		return TRUE

/// Load ammo by hitting the weapon with it
/obj/item/ego_weapon/city/thumbfather_rapier/attackby(obj/item/stack/thumb_east_ammo/I, mob/living/user, params)
	if(!istype(I))
		return ..()
	if(busy)
		return
	if(!(I.type in accepted_ammo_table))
		to_chat(user, span_warning("The [I.name] are incompatible with the [src.name]."))
		return
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_reload), src, I, user, current_ammo, max_ammo, accepted_ammo_table)

/// Unload a round by alt-clicking
/obj/item/ego_weapon/city/thumbfather_rapier/AltClick(mob/user)
	. = ..()
	if(busy)
		return
	if(length(current_ammo))
		var/obj/item/stack/thumb_east_ammo/round = current_ammo[length(current_ammo)]
		current_ammo -= round
		round.forceMove(get_turf(src))
		to_chat(user, span_info("You unload a round from the [src.name]."))
		playsound(src, 'sound/weapons/gun/pistol/drop_small.ogg', 90, FALSE)
		reset_nursefather_combo(src, user)
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
	hitsound = 'sound/weapons/ego/thumb_east_podao_attack.ogg'
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
	special = "This is a Thumbfather dual-wield weapon. <b>Load it with acceleration propellant ammunition</b> and dual-wield it with its partner to unlock its full potential."
	/// Detailed combo description shown on examine
	var/combo_description = "This weapon's combo consists of a <b>long-range lunge</b>, followed by an <b>AoE sweep with the other weapon</b>, and ends with a powerful <b>finisher that detonates Tremor and Overheat</b>.\n"+\
	"<b>Lunge</b>: Attack a target from range to dash at them (costs 1 round).\n"+\
	"<b>AoE Sweep</b>: Swap to your other weapon and hit the target (costs 1 round). Deals AoE damage around you.\n"+\
	"<b>Finisher</b>: Swap back to your starting weapon and hit the target (costs 2 rounds). Tremor Bursts and deals bonus RED damage equal to built-up Tremor + Overheat stacks.\n"+\
	"Hitting with the wrong weapon at any stage <b>breaks the combo</b>. The combo expires after 5 seconds of inactivity."
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
	/// Current combo stage (synced between both weapons)
	var/combo_stage = NURSEFATHER_COMBO_NONE
	/// Whether the combo was started by the rapier (TRUE) or katana (FALSE) (synced between both weapons)
	var/combo_starter_is_rapier = FALSE
	/// Timer for combo reset
	var/combo_reset_timer
	/// Duration before combo resets from inactivity
	var/combo_reset_duration = 5 SECONDS
	/// Whether we can lunge
	var/lunge_ready = TRUE
	/// Lunge distance in tiles
	var/lunge_range = 3
	/// Cooldown between lunges
	var/lunge_cooldown_duration = 13 SECONDS
	/// Timer for lunge cooldown
	var/lunge_cooldown_timer
	/// Base radius for AoE sweep
	var/attack2_aoe_radius = 1
	/// Are we currently performing a channeled action (reloading)?
	var/busy = FALSE
	/// Cooldown for balloon alerts
	var/balloon_alert_cooldown

	// Sound variables
	var/lunge_sound = 'sound/weapons/ego/thumb_east_podao_boostedlunge.ogg'
	var/sweep_sound = 'sound/weapons/ego/thumb_east_podao_boostedsweep.ogg'
	var/finisher_sound = 'sound/weapons/ego/thumb_east_rifle_boostedfinisher.ogg'
	var/detonation_sound = 'sound/weapons/ego/thumb_east_podao_detonation.ogg'
	var/dryfire_sound = 'sound/weapons/gun/general/dry_fire.ogg'

/obj/item/ego_weapon/city/thumbfather_katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8, -12, -12)

/obj/item/ego_weapon/city/thumbfather_katana/Destroy(force)
	for(var/obj/item/stack/thumb_east_ammo/leftover in current_ammo)
		leftover.forceMove(get_turf(src))
	current_ammo = null
	deltimer(combo_reset_timer)
	deltimer(lunge_cooldown_timer)
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
	. += span_info(combo_description)
	. += span_notice("Every 2nd non-combo hit triggers a <b>dual-wield follow-up</b> from your partner weapon at 25% damage, spending a round from it.")
	. += span_notice("Spending a round from this katana grants <b>1 Concentration</b> to you and applies <b>3 Tremor</b> to the target. Poise crits also apply +2 Tremor.")
	. += span_notice("<b>Hit the weapon with ammunition</b> to reload (channeled). <b>Alt-click</b> to unload a round.")
	if(combo_stage == NURSEFATHER_COMBO_LUNGE)
		. += span_green("Combo active: lunge landed! [combo_starter_is_rapier ? "Switch to katana" : "Hit with rapier"] for the AoE sweep!")
	else if(combo_stage == NURSEFATHER_COMBO_ATTACK2)
		. += span_green("Combo active: AoE sweep ready! [combo_starter_is_rapier != is_thumbfather_rapier(src) ? "Hit with this weapon!" : "Switch to your other weapon!"]")
	else if(combo_stage == NURSEFATHER_COMBO_FINISHER)
		. += span_green("Combo active: finisher ready! [combo_starter_is_rapier == is_thumbfather_rapier(src) ? "Hit with this weapon!" : "Switch to your other weapon!"]")
	. += span_danger("This weapon's AoE is indiscriminate. <b>Watch out for friendly fire</b>.")

/// On Poise crit: boost tremor by 2
/obj/item/ego_weapon/city/thumbfather_katana/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	target.apply_lc_tremor(2, INFINITY)

/// Called when the lunge cooldown expires
/obj/item/ego_weapon/city/thumbfather_katana/proc/ReadyToLunge(mob/user)
	lunge_ready = TRUE
	lunge_cooldown_timer = null
	if(combo_stage == NURSEFATHER_COMBO_NONE)
		to_chat(user, span_nicegreen("You're ready to lunge and begin a new combo again."))
		user.balloon_alert(user, "You're ready to lunge again.")
	else
		to_chat(user, span_nicegreen("You're ready to lunge again, once your current combo is finished."))
		user.balloon_alert(user, "You're ready to lunge again.")

/// Lunge opener: dash towards the target from range and auto-attack if we reach them
/obj/item/ego_weapon/city/thumbfather_katana/proc/Lunge(mob/living/target, mob/living/user)
	if(!can_see(user, target, lunge_range))
		to_chat(user, span_warning("You can't reach your target!"))
		if(balloon_alert_cooldown < world.time)
			user.balloon_alert(user, "You can't reach your target!")
			balloon_alert_cooldown = world.time + 0.4 SECONDS
		return FALSE
	if(!lunge_ready)
		to_chat(user, span_warning("You're not ready to lunge yet!"))
		if(balloon_alert_cooldown < world.time)
			user.balloon_alert(user, "You're not ready to lunge yet!")
			balloon_alert_cooldown = world.time + 0.4 SECONDS
		return FALSE

	// Set combo stage on both weapons - katana is the starter
	sync_nursefather_combo(src, user, NURSEFATHER_COMBO_LUNGE, FALSE)
	if(spend_acceleration_round(src, user, target))
		lunge_ready = FALSE
		lunge_cooldown_timer = addtimer(CALLBACK(src, PROC_REF(ReadyToLunge), user), lunge_cooldown_duration)
		shake_camera(user, 1.5, 3)
		to_chat(user, span_danger("You lunge at [target] using the propulsion from your [src.name]!"))
		var/turf/takeoff_turf = get_turf(user)
		new /obj/effect/temp_visual/thumb_east_aoe_impact(takeoff_turf)
		for(var/i in 2 to get_dist(user, target))
			step_towards(user, target)
		if(get_dist(user, target) < 2)
			hitsound = lunge_sound
			target.attackby(src, user)
		else
			to_chat(user, span_warning("Your lunge falls short of hitting your target!"))
		start_nursefather_combo_timer(src, user)
		return TRUE
	else
		to_chat(user, span_warning("You pull the trigger to lunge at [target], but you have no ammo left."))
		playsound(src, dryfire_sound, 65)
		sync_nursefather_combo(src, user, NURSEFATHER_COMBO_NONE, FALSE)
		return FALSE

/// Main attack proc with combo handling and weapon-swap enforcement
/obj/item/ego_weapon/city/thumbfather_katana/attack(mob/living/target, mob/living/carbon/human/user)
	if(busy)
		return
	var/weapon_is_rapier = FALSE
	switch(combo_stage)
		if(NURSEFATHER_COMBO_NONE)
			. = ..()
		if(NURSEFATHER_COMBO_LUNGE)
			// Lunge hit must be with the starting weapon
			if(weapon_is_rapier != combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to land the lunge hit with your starting weapon."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				. = ..()
				hitsound = initial(hitsound)
				user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.1)
				sync_nursefather_combo(src, user, NURSEFATHER_COMBO_ATTACK2, combo_starter_is_rapier)
				start_nursefather_combo_timer(src, user)
				to_chat(user, span_info("Combo: switch to your [combo_starter_is_rapier ? "katana" : "rapier"] and hit!"))
		if(NURSEFATHER_COMBO_ATTACK2)
			// AoE sweep must be with the OTHER weapon from the starter
			if(weapon_is_rapier == combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to switch weapons."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				if(spend_acceleration_round(src, user, target))
					shake_camera(user, 1.5, 3)
					hitsound = null
					. = ..()
					playsound(src, sweep_sound, 90, FALSE, 10)
					hitsound = initial(hitsound)
					user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.3)
					thumbfather_radius_aoe(src, user, target, attack2_aoe_radius)
					sync_nursefather_combo(src, user, NURSEFATHER_COMBO_FINISHER, combo_starter_is_rapier)
					start_nursefather_combo_timer(src, user, 2 SECONDS)
					to_chat(user, span_info("Combo: switch back to your [combo_starter_is_rapier ? "rapier" : "katana"] for the finisher!"))
				else
					reset_nursefather_combo(src, user)
					playsound(src, dryfire_sound, 65)
					. = ..()
		if(NURSEFATHER_COMBO_FINISHER)
			// Finisher must be with the STARTING weapon
			if(weapon_is_rapier != combo_starter_is_rapier)
				to_chat(user, span_warning("Combo broken! You needed to finish with your starting weapon."))
				reset_nursefather_combo(src, user, FALSE)
				. = ..()
			else
				var/spent1 = spend_acceleration_round(src, user, target)
				var/spent2 = spend_acceleration_round(src, user, target)
				if(spent1 || spent2)
					shake_camera(user, 2, 4)
					var/original_force = force
					force = round(force * 1.5)
					hitsound = null
					. = ..()
					playsound(src, finisher_sound, 90, FALSE, 10)
					hitsound = initial(hitsound)
					force = original_force
					user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.2)
					thumbfather_finisher(target, user)
				else
					playsound(src, dryfire_sound, 65)
					. = ..()
				reset_nursefather_combo(src, user, FALSE)
	// Dual-wield: trigger partner every 2nd hit, spending ammo for poise/concentration/effects
	// Only triggers on non-combo hits - combo attacks do NOT count towards or trigger dual-wield follow-ups
	if(!busy_dual_strike && combo_stage == NURSEFATHER_COMBO_NONE)
		swing_count++
		if(swing_count >= 2)
			swing_count = 0
			var/obj/item/ego_weapon/city/thumbfather_rapier/partner = find_thumbfather_partner(src, user)
			if(partner && !partner.busy_dual_strike && (target in view(partner.reach, user)))
				INVOKE_ASYNC(src, PROC_REF(DualWieldFollowUp), partner, user, target)

/// Delayed dual-wield follow-up attack with the partner weapon
/obj/item/ego_weapon/city/thumbfather_katana/proc/DualWieldFollowUp(obj/item/ego_weapon/city/thumbfather_rapier/partner, mob/living/carbon/human/user, mob/living/target)
	sleep(0.2 SECONDS)
	if(QDELETED(partner) || QDELETED(user) || QDELETED(target))
		return
	if(!(target in view(partner.reach, user)))
		return
	spend_acceleration_round(partner, user, target, 50)
	partner.busy_dual_strike = TRUE
	var/original_force = partner.force
	partner.force = round(original_force * 0.25)
	user.do_attack_animation(target, null, partner)
	target.attacked_by(partner, user)
	partner.force = original_force
	partner.busy_dual_strike = FALSE

/// Lunge from range + reverse reload
/obj/item/ego_weapon/city/thumbfather_katana/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	// Reverse reload: clicking ammo with the weapon
	if(istype(target, /obj/item/stack/thumb_east_ammo))
		var/obj/item/stack/thumb_east_ammo/ammo = target
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_reload), src, ammo, user, current_ammo, max_ammo, accepted_ammo_table)
		return TRUE
	if(!isliving(target))
		return TRUE
	if(busy)
		return TRUE
	// Lunge from range
	if(!proximity_flag && combo_stage == NURSEFATHER_COMBO_NONE)
		Lunge(target, user)
		return TRUE

/// Load ammo by hitting the weapon with it
/obj/item/ego_weapon/city/thumbfather_katana/attackby(obj/item/stack/thumb_east_ammo/I, mob/living/user, params)
	if(!istype(I))
		return ..()
	if(busy)
		return
	if(!(I.type in accepted_ammo_table))
		to_chat(user, span_warning("The [I.name] are incompatible with the [src.name]."))
		return
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(thumbfather_reload), src, I, user, current_ammo, max_ammo, accepted_ammo_table)

/// Unload a round by alt-clicking
/obj/item/ego_weapon/city/thumbfather_katana/AltClick(mob/user)
	. = ..()
	if(busy)
		return
	if(length(current_ammo))
		var/obj/item/stack/thumb_east_ammo/round = current_ammo[length(current_ammo)]
		current_ammo -= round
		round.forceMove(get_turf(src))
		to_chat(user, span_info("You unload a round from the [src.name]."))
		playsound(src, 'sound/weapons/gun/pistol/drop_small.ogg', 90, FALSE)
		reset_nursefather_combo(src, user)
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
	icon_state = "thumb_east_acceleration"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_POCKETS
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
	icon_state = "thumb_east_acceleration_spent"
	max_amount = 12
	merge_type = /obj/item/stack/thumb_east_ammo/spent/acceleration

#undef NURSEFATHER_COMBO_NONE
#undef NURSEFATHER_COMBO_LUNGE
#undef NURSEFATHER_COMBO_ATTACK2
#undef NURSEFATHER_COMBO_FINISHER
