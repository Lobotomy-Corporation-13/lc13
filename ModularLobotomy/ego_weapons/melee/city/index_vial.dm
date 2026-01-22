// Index Vial - Weapon swapping system similar to Black Silence Gloves
// Use in hand to randomly swap to a weapon form you haven't used yet
// After using all 9 forms, furioso becomes available

/obj/item/ego_weapon/index_vial
	name = "index vial"
	desc = "A vial containing a strange liquid that can transform into various weapons."
	icon = 'icons/obj/index_vial_icon.dmi'
	icon_state = "index_vial_inactive"
	inhand_icon_state = "index_vial_inactive"
	lefthand_file = 'icons/obj/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/index_vial_32x32_right.dmi'
	force = 0
	w_class = WEIGHT_CLASS_SMALL
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 120,
		PRUDENCE_ATTRIBUTE = 120,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)
	/// List of weapon forms that have been used
	var/list/unlocked_list = list()
	/// Whether furioso is available
	var/unlocked = FALSE
	/// Maximum attacks before forced swap (0 = no limit for inactive)
	var/max_swings = 0
	/// Current attack count
	var/swing_count = 0
	/// World time when manual swap is allowed again
	var/next_swap_time = 0
	/// Cooldown between manual swaps (30 seconds)
	var/swap_cooldown = 30 SECONDS
	/// Mapping of form names to subtypes
	var/static/list/weapon_types = list(
		"index_vial_hatchet" = /obj/item/ego_weapon/index_vial/hatchet,
		"index_vial_stiletto" = /obj/item/ego_weapon/index_vial/stiletto,
		"index_vial_bsword" = /obj/item/ego_weapon/index_vial/bsword,
		"index_vial_rapier" = /obj/item/ego_weapon/index_vial/rapier,
		"index_vial_hammer" = /obj/item/ego_weapon/index_vial/hammer,
		"index_vial_gsword" = /obj/item/ego_weapon/index_vial/gsword,
		"index_vial_lance" = /obj/item/ego_weapon/index_vial/lance,
		"index_vial_whip" = /obj/item/ego_weapon/index_vial/whip,
		"index_vial_scythe" = /obj/item/ego_weapon/index_vial/scythe
	)
	/// All possible weapon forms (excluding inactive and fpoon)
	var/static/list/weapon_forms = list(
		"index_vial_hatchet",
		"index_vial_stiletto",
		"index_vial_bsword",
		"index_vial_rapier",
		"index_vial_hammer",
		"index_vial_gsword",
		"index_vial_lance",
		"index_vial_whip",
		"index_vial_scythe"
	)

/obj/item/ego_weapon/index_vial/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	if(slot == ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_MOB_SHIFTCLICKON, PROC_REF(try_furioso))

/obj/item/ego_weapon/index_vial/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_SHIFTCLICKON)

/obj/item/ego_weapon/index_vial/attack_self(mob/user)
	if(!CanUseEgo(user))
		return

	// Check cooldown
	if(world.time < next_swap_time)
		var/time_left = round((next_swap_time - world.time) / 10)
		to_chat(user, span_warning("The vial needs [time_left] more seconds to stabilize."))
		return

	// Get available forms (not yet used)
	var/list/available = weapon_forms - unlocked_list

	if(!length(available))
		if(unlocked)
			to_chat(user, span_notice("You've used all weapon forms. Furioso is ready!"))
		else
			// All forms used, unlock furioso
			unlocked = TRUE
			to_chat(user, span_userdanger("You've mastered all weapon forms! Furioso is now available!"))
		return

	// Set cooldown for next swap
	var/new_swap_time = world.time + swap_cooldown

	// 10% chance to become fpoon
	if(prob(10))
		var/obj/item/ego_weapon/index_vial/fpoon/new_weapon = new(user.drop_location())
		new_weapon.unlocked_list = unlocked_list.Copy()
		new_weapon.unlocked = unlocked
		new_weapon.next_swap_time = new_swap_time
		playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)
		to_chat(user, span_userdanger("The vial warps into... a fpoon?!"))
		qdel(src)
		user.put_in_hands(new_weapon)
		return

	// Pick random available form
	var/new_form = pick(available)
	unlocked_list += new_form

	// Get the appropriate subtype for this form
	var/weapon_type = weapon_types[new_form]
	if(!weapon_type)
		weapon_type = /obj/item/ego_weapon/index_vial

	// Create new weapon with the form
	var/obj/item/ego_weapon/index_vial/new_weapon = new weapon_type(user.drop_location())
	new_weapon.unlocked_list = unlocked_list.Copy()
	new_weapon.unlocked = unlocked
	new_weapon.next_swap_time = new_swap_time
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)

	qdel(src)
	user.put_in_hands(new_weapon)

	// Check if furioso should unlock
	if(new_weapon.unlocked_list.len >= 9 && !new_weapon.unlocked)
		new_weapon.unlocked = TRUE
		to_chat(user, span_userdanger("You've mastered all weapon forms! Furioso is now available!"))

/obj/item/ego_weapon/index_vial/AltClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	// Already inactive
	if(icon_state == "index_vial_inactive")
		to_chat(user, span_notice("The vial is already in its inactive state."))
		return
	// Return to inactive state, resetting progress
	var/obj/item/ego_weapon/index_vial/new_vial = new /obj/item/ego_weapon/index_vial(user.drop_location())
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)
	to_chat(user, span_notice("You return the vial to its inactive state, resetting your progress."))
	qdel(src)
	user.put_in_hands(new_vial)

/obj/item/ego_weapon/index_vial/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// Track swings and force swap if limit reached
	if(max_swings > 0)
		swing_count++
		if(swing_count >= max_swings)
			force_swap(user)

/obj/item/ego_weapon/index_vial/proc/force_swap(mob/user)
	// Get available forms (not yet used)
	var/list/available = weapon_forms - unlocked_list

	if(!length(available))
		// All forms used, unlock furioso
		if(!unlocked)
			unlocked = TRUE
			to_chat(user, span_userdanger("You've mastered all weapon forms! Furioso is now available!"))
		return

	// Set cooldown for next manual swap
	var/new_swap_time = world.time + swap_cooldown

	// 10% chance to become fpoon
	if(prob(10))
		var/obj/item/ego_weapon/index_vial/fpoon/new_weapon = new(user.drop_location())
		new_weapon.unlocked_list = unlocked_list.Copy()
		new_weapon.unlocked = unlocked
		new_weapon.next_swap_time = new_swap_time
		playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)
		to_chat(user, span_userdanger("The vial warps into... a fpoon?!"))
		qdel(src)
		user.put_in_hands(new_weapon)
		return

	// Pick random available form
	var/new_form = pick(available)
	unlocked_list += new_form

	// Get the appropriate subtype for this form
	var/weapon_type = weapon_types[new_form]
	if(!weapon_type)
		weapon_type = /obj/item/ego_weapon/index_vial

	// Create new weapon with the form
	var/obj/item/ego_weapon/index_vial/new_weapon = new weapon_type(user.drop_location())
	new_weapon.unlocked_list = unlocked_list.Copy()
	new_weapon.unlocked = unlocked
	new_weapon.next_swap_time = new_swap_time
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)
	to_chat(user, span_warning("The vial shifts, forcing you to change weapons!"))

	qdel(src)
	user.put_in_hands(new_weapon)

	// Check if furioso should unlock
	if(new_weapon.unlocked_list.len >= 9 && !new_weapon.unlocked)
		new_weapon.unlocked = TRUE
		to_chat(user, span_userdanger("You've mastered all weapon forms! Furioso is now available!"))

/obj/item/ego_weapon/index_vial/proc/try_furioso(mob/living/user, atom/target)
	SIGNAL_HANDLER
	if(!CanUseEgo(user))
		return
	if(user.get_active_held_item() != src)
		return
	if(!unlocked)
		to_chat(user, span_warning("You haven't used all weapon forms yet!"))
		return
	if(target == user)
		return
	INVOKE_ASYNC(src, PROC_REF(furioso), user)

/obj/item/ego_weapon/index_vial/proc/furioso(mob/living/user)
	// Collect targets in range
	var/list/targets = list()
	for(var/mob/living/L in range(8, user))
		if(L == user)
			continue
		if(faction_check(user.faction, L.faction))
			continue
		if(L.status_flags & GODMODE)
			continue
		if(L.stat == DEAD)
			continue
		targets += L

	if(!LAZYLEN(targets))
		to_chat(user, span_warning("There are no enemies nearby!"))
		return

	// Weapon data for Furioso - each weapon has: name, icon, hits, damage, damtype, sound
	var/static/list/furioso_weapons = list(
		list("name" = "hatchet", "icon" = "index_vial_hatchet", "hits" = 5, "damage" = 30, "damtype" = RED_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_hatchet.ogg'),
		list("name" = "stiletto", "icon" = "index_vial_stiletto", "hits" = 4, "damage" = 35, "damtype" = WHITE_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_stiletto.ogg'),
		list("name" = "bastard sword", "icon" = "index_vial_bsword", "hits" = 2, "damage" = 75, "damtype" = BLACK_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_bsword.ogg'),
		list("name" = "rapier", "icon" = "index_vial_rapier", "hits" = 3, "damage" = 50, "damtype" = WHITE_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_rapier.ogg'),
		list("name" = "hammer", "icon" = "index_vial_hammer", "hits" = 2, "damage" = 90, "damtype" = RED_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_hammer.ogg'),
		list("name" = "greatsword", "icon" = "index_vial_gsword", "hits" = 2, "damage" = 100, "damtype" = BLACK_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_gsword.ogg'),
		list("name" = "lance", "icon" = "index_vial_lance", "hits" = 2, "damage" = 95, "damtype" = WHITE_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_lance.ogg'),
		list("name" = "whip", "icon" = "index_vial_whip", "hits" = 2, "damage" = 60, "damtype" = BLACK_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_whip.ogg'),
		list("name" = "scythe", "icon" = "index_vial_scythe", "hits" = 1, "damage" = 100, "damtype" = PALE_DAMAGE, "sound" = 'sound/weapons/black_vial/index_vial_scythe.ogg')
	)

	furioso_start(user, targets)

	for(var/list/weapon_data in furioso_weapons)
		// Get a valid target
		var/mob/living/target = pick(targets)
		if(QDELETED(target) || target.stat == DEAD)
			targets -= target
			if(!LAZYLEN(targets))
				break
			target = pick(targets)
			if(QDELETED(target))
				break

		furioso_attack(user, target, weapon_data)

	furioso_end(user, targets)

/obj/item/ego_weapon/index_vial/proc/furioso_start(mob/living/user, list/targets)
	ADD_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)
	user.status_flags |= GODMODE
	user.Stun(60 SECONDS, ignore_canstun = TRUE)
	user.anchored = TRUE
	for(var/mob/living/L in targets)
		L.Stun(60 SECONDS, ignore_canstun = TRUE)
		ADD_TRAIT(L, TRAIT_MUTE, TIMESTOP_TRAIT)
		walk(L, 0)
		if(isanimal(L))
			var/mob/living/simple_animal/S = L
			S.toggle_ai(AI_OFF)

/obj/item/ego_weapon/index_vial/proc/furioso_attack(mob/living/user, mob/living/target, list/weapon_data)
	// Update visuals
	icon_state = weapon_data["icon"]
	inhand_icon_state = weapon_data["icon"]
	user.update_inv_hands()

	// Teleport to target
	var/turf/tp_loc = get_step(target.loc, pick(GLOB.cardinals))
	if(!tp_loc)
		tp_loc = get_turf(target)
	var/turf/prev_loc = get_turf(user)
	user.forceMove(tp_loc)
	user.dir = get_dir(user, target)
	prev_loc.Beam(tp_loc, "pt_ray", time = 10)

	// Perform hits
	var/hits = weapon_data["hits"]
	var/damage = weapon_data["damage"]
	var/damtype = weapon_data["damtype"]
	for(var/i in 1 to hits)
		playsound(user, weapon_data["sound"], 75, TRUE)
		new /obj/effect/temp_visual/smash_effect(get_turf(target))
		target.deal_damage(damage, damtype, user, attack_type = (ATTACK_TYPE_MELEE))
		sleep(0.2 SECONDS)
	sleep(0.3 SECONDS)

/obj/item/ego_weapon/index_vial/proc/furioso_end(mob/living/user, list/targets)
	user.status_flags &= ~GODMODE
	user.AdjustStun(-60 SECONDS, ignore_canstun = TRUE)
	user.anchored = FALSE
	REMOVE_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)

	for(var/mob/living/L in targets)
		L.AdjustStun(-60 SECONDS, ignore_canstun = TRUE)
		REMOVE_TRAIT(L, TRAIT_MUTE, TIMESTOP_TRAIT)
		if(isanimal(L))
			var/mob/living/simple_animal/S = L
			S.toggle_ai(initial(S.AIStatus))

	// Reset to inactive state
	icon_state = "index_vial_inactive"
	inhand_icon_state = "index_vial_inactive"
	user.update_inv_hands()
	unlocked = FALSE
	unlocked_list = list()
	to_chat(user, span_notice("Furioso complete. The vial returns to its inactive state."))

// ============================================
// HATCHET - Small, fast weapon with protection on hit
// ============================================
/obj/item/ego_weapon/index_vial/hatchet
	name = "index vial - hatchet"
	desc = "When hacking through the ribs with a hatchet... This is barely a weapon, but it's better than a fork."
	special = "On hit, gain protection."
	icon_state = "index_vial_hatchet"
	inhand_icon_state = "index_vial_hatchet"
	lefthand_file = 'icons/obj/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/index_vial_32x32_right.dmi'
	hitsound = 'sound/weapons/black_vial/index_vial_hatchet.ogg'
	force = 30
	damtype = RED_DAMAGE
	attack_speed = 0.4
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 7
	attack_verb_continuous = list("hacks", "chops", "cleaves")
	attack_verb_simple = list("hack", "chop", "cleave")

/obj/item/ego_weapon/index_vial/hatchet/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, gain protection (simulates Poise)
	user.apply_lc_protection(2)

// ============================================
// STILETTO - Quick stabbing with mental decay DOT
// ============================================
/obj/item/ego_weapon/index_vial/stiletto
	name = "index vial - stiletto"
	desc = "When penetrating the lungs with a stiletto... I couldn't help but feel a dreadful chill run down my back whenever I'm given this weapon."
	special = "On hit, inflict mental decay on the target."
	icon_state = "index_vial_stiletto"
	inhand_icon_state = "index_vial_stiletto"
	lefthand_file = 'icons/obj/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/index_vial_48x48_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	hitsound = 'sound/weapons/black_vial/index_vial_stiletto.ogg'
	force = 35
	damtype = WHITE_DAMAGE
	attack_speed = 0.5
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 6
	attack_verb_continuous = list("stabs", "pierces", "punctures")
	attack_verb_simple = list("stab", "pierce", "puncture")

/obj/item/ego_weapon/index_vial/stiletto/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, apply mental decay (simulates Sinking)
	M.apply_lc_mental_decay(2)

// ============================================
// BASTARD SWORD - Balanced with damage buff on hit
// ============================================
/obj/item/ego_weapon/index_vial/bsword
	name = "index vial - bastard sword"
	desc = "When cleaving through the shoulder and the skull with a bastard sword... This sword is passable, but that quality leaves a lot to be desired."
	special = "On hit, gain strength. Stacks up to 4 times."
	icon_state = "index_vial_bsword"
	inhand_icon_state = "index_vial_bsword"
	lefthand_file = 'icons/obj/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/index_vial_48x48_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	hitsound = 'sound/weapons/black_vial/index_vial_bsword.ogg'
	force = 75
	damtype = BLACK_DAMAGE
	attack_speed = 1
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 3
	attack_verb_continuous = list("cleaves", "slashes", "cuts")
	attack_verb_simple = list("cleave", "slash", "cut")

/obj/item/ego_weapon/index_vial/bsword/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, gain damage buff (simulates Offense Level Up) - max 4 stacks
	var/datum/status_effect/stacking/damage_up/S = user.has_status_effect(/datum/status_effect/stacking/damage_up)
	if(!S)
		user.apply_lc_strength(1)
	else if(S.stacks < 4)
		user.apply_lc_strength(S.stacks + 1)

// ============================================
// RAPIER - Precise thrusts with defense debuff
// ============================================
/obj/item/ego_weapon/index_vial/rapier
	name = "index vial - rapier"
	desc = "When punching 10 or more holes in the torso with a rapier... A weapon longer and sharper than the stiletto. I enjoy the rapier as well."
	special = "On hit, inflict white fragility on the target."
	icon_state = "index_vial_rapier"
	inhand_icon_state = "index_vial_rapier"
	lefthand_file = 'icons/obj/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/index_vial_48x48_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	hitsound = 'sound/weapons/black_vial/index_vial_rapier.ogg'
	force = 50
	damtype = WHITE_DAMAGE
	attack_speed = 0.7
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 4
	attack_verb_continuous = list("thrusts", "pierces", "stabs")
	attack_verb_simple = list("thrust", "pierce", "stab")

/obj/item/ego_weapon/index_vial/rapier/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, inflict white fragility (simulates Defense Level Down)
	M.apply_lc_white_fragile(2)

// ============================================
// HAMMER - Heavy strikes with stamina damage
// ============================================
/obj/item/ego_weapon/index_vial/hammer
	name = "index vial - hammer"
	desc = "When caving in the back of the skull with a hammer... Simple, but final. It will crush whatever it hits."
	special = "On hit, deal stamina damage to the target."
	icon_state = "index_vial_hammer"
	inhand_icon_state = "index_vial_hammer"
	lefthand_file = 'icons/obj/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/index_vial_48x48_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	hitsound = 'sound/weapons/black_vial/index_vial_hammer.ogg'
	force = 90
	damtype = RED_DAMAGE
	attack_speed = 1.2
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 2
	attack_verb_continuous = list("smashes", "crushes", "bashes")
	attack_verb_simple = list("smash", "crush", "bash")

/obj/item/ego_weapon/index_vial/hammer/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, deal stamina damage (simulates raising Stagger Threshold)
	M.adjustStaminaLoss(40)

// ============================================
// GREATSWORD - Heavy two-hander with RED vulnerability
// ============================================
/obj/item/ego_weapon/index_vial/gsword
	name = "index vial - greatsword"
	desc = "When rending the body with a greatsword... It is important to find your center of gravity and take advantage of its sheer mass."
	special = "On hit, inflict red fragility on the target."
	icon_state = "index_vial_gsword"
	inhand_icon_state = "index_vial_gsword"
	lefthand_file = 'icons/obj/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/index_vial_64x64_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/black_vial/index_vial_gsword.ogg'
	force = 100
	damtype = BLACK_DAMAGE
	attack_speed = 1.3
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 2
	attack_verb_continuous = list("rends", "cleaves", "devastates")
	attack_verb_simple = list("rend", "cleave", "devastate")

/obj/item/ego_weapon/index_vial/gsword/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, inflict red fragility (simulates Slash Fragility)
	M.apply_lc_red_fragile(2)

// ============================================
// LANCE - Long reach with WHITE vulnerability
// ============================================
/obj/item/ego_weapon/index_vial/lance
	name = "index vial - lance"
	desc = "When boring a 20-inch hole with a lance... I'd consider this weapon a jackpot. This lance has a self-propelling property."
	special = "On hit, inflict white fragility on the target. Has extended reach."
	icon_state = "index_vial_lance"
	inhand_icon_state = "index_vial_lance"
	lefthand_file = 'icons/obj/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/index_vial_64x64_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/black_vial/index_vial_lance.ogg'
	force = 95
	damtype = WHITE_DAMAGE
	attack_speed = 1.2
	reach = 2
	stuntime = 5
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 2
	attack_verb_continuous = list("impales", "gores", "pierces")
	attack_verb_simple = list("impale", "gore", "pierce")

/obj/item/ego_weapon/index_vial/lance/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, inflict white fragility (simulates Pierce Fragility)
	M.apply_lc_white_fragile(2)

// ============================================
// WHIP - Flexible weapon with BLACK vulnerability
// ============================================
/obj/item/ego_weapon/index_vial/whip
	name = "index vial - whip"
	desc = "When ripping the flesh to ten thousand strips with a whip... I am quite fond of it. It tears a strip off the target's flesh, and with it their resolve."
	special = "On hit, inflict black fragility on the target. Has extended reach."
	icon_state = "index_vial_whip"
	inhand_icon_state = "index_vial_whip"
	lefthand_file = 'icons/obj/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/index_vial_48x48_right.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 48
	hitsound = 'sound/weapons/black_vial/index_vial_whip.ogg'
	force = 60
	damtype = BLACK_DAMAGE
	attack_speed = 1.5
	reach = 4
	stuntime = 5
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 2
	attack_verb_continuous = list("lashes", "whips", "flays")
	attack_verb_simple = list("lash", "whip", "flay")

/obj/item/ego_weapon/index_vial/whip/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return
	// On hit, inflict black fragility (simulates Blunt Fragility)
	M.apply_lc_black_fragile(2)

// ============================================
// SCYTHE - Death's instrument with high damage
// ============================================
/obj/item/ego_weapon/index_vial/scythe
	name = "index vial - scythe"
	desc = "When lacerating through space itself with a scythe, like a certain someone... This weapon became my favorite, most familiar, and sharpest weapon."
	special = "Deals high pale damage. No special effect needed."
	icon_state = "index_vial_scythe"
	inhand_icon_state = "index_vial_scythe"
	lefthand_file = 'icons/obj/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/index_vial_64x64_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/black_vial/index_vial_scythe.ogg'
	force = 100
	damtype = PALE_DAMAGE
	attack_speed = 1.5
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 1
	attack_verb_continuous = list("lacerates", "reaps", "scythes")
	attack_verb_simple = list("lacerate", "reap", "scythe")

// ============================================
// FPOON - Rare joke weapon (1% chance on swap)
// ============================================
/obj/item/ego_weapon/index_vial/fpoon
	name = "index vial - fpoon"
	desc = "A fpoon. It's a spoon with fork tines. Why did the vial turn into this?"
	special = "Attack yourself to end it all with a fpoon. How embarrassing."
	icon_state = "index_vial_fpoon"
	inhand_icon_state = "index_vial_fpoon"
	lefthand_file = 'icons/obj/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/index_vial_32x32_right.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 5
	damtype = PALE_DAMAGE
	attack_speed = 1
	max_swings = 5
	attack_verb_continuous = list("pokes", "prods", "scoops")
	attack_verb_simple = list("poke", "prod", "scoop")

/obj/item/ego_weapon/index_vial/fpoon/attack(mob/living/M, mob/living/user)
	if(M == user)
		// Suicide with a fpoon
		to_chat(user, span_userdanger("You prepare to end it all... with a fpoon."))
		user.Jitter(5 SECONDS)
		if(!do_after(user, 5 SECONDS, M))
			to_chat(user, span_notice("You reconsider your life choices."))
			return
		user.death()
		for(var/mob/P in GLOB.player_list)
			to_chat(P, span_userdanger("[uppertext(user.real_name)] has died to a fpoon. How embarrassing."))
		return
	. = ..()
	if(!.)
		return
	// Inflict 5 bleed on hit
	if(isliving(M))
		M.apply_status_effect(/datum/status_effect/stacking/saw_bleed, 5)
