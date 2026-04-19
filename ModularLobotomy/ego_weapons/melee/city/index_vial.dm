// Index Vial - Weapon swapping system similar to Black Silence Gloves
// Use in hand to randomly swap to a weapon form you haven't used yet
// After using all 9 forms, furioso becomes available

/obj/item/ego_weapon/index_vial
	name = "caduceus"
	desc = "A vial containing a strange liquid that can transform into various weapons."
	icon = 'icons/obj/spider_house/index/index_vial_icon.dmi'
	icon_state = "index_vial_inactive"
	inhand_icon_state = "index_vial_inactive"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_32x32_right.dmi'
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
	/// Whether furioso is currently being performed
	var/furioso_active = FALSE
	/// Whether the defense system is currently active against unauthorized users
	var/defense_active = FALSE
	/// Tracks how many times each mob has triggered the defense system (mob ref → count)
	var/list/defense_strikes = list()
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

/obj/item/ego_weapon/index_vial/equip_to_best_slot(mob/M, check_hand = TRUE)
	if(defense_active)
		to_chat(M, span_warning("The vial is shifting too wildly to store!"))
		return FALSE
	. = ..()

/obj/item/ego_weapon/index_vial/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(defense_active && slot != ITEM_SLOT_HANDS)
		to_chat(M, span_warning("The vial is shifting too wildly to store!"))
		return FALSE
	. = ..()

/obj/item/ego_weapon/index_vial/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	if(slot == ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_MOB_SHIFTCLICKON, PROC_REF(try_furioso))
		// Apprentice recognition message
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.mind?.assigned_role == "Index Proxy Apprentice")
				to_chat(H, span_notice("Caduceus begins to shake rapidly as your hands touch its frame; however, it calms down as soon as it recognizes your purpose."))
		// Defense system: unauthorized users on city maps trigger weapon cycling + scythe attack
		if(!is_authorized(user))
			INVOKE_ASYNC(src, PROC_REF(start_defense_system), user)

/obj/item/ego_weapon/index_vial/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_SHIFTCLICKON)
	stop_defense_system()

/obj/item/ego_weapon/index_vial/Destroy()
	stop_defense_system()
	return ..()

/// Checks if a user is authorized to use the weapon without triggering the defense system
/obj/item/ego_weapon/index_vial/proc/is_authorized(mob/user)
	if(!ishuman(user))
		return TRUE
	var/mob/living/carbon/human/H = user
	if(H.mind?.assigned_role in list("Oracle Proxy", "Index Proxy Apprentice"))
		return TRUE
	// Defense only triggers on city maps
	if(!(SSmaptype.maptype in SSmaptype.citymaps))
		return TRUE
	// Defense doesn't trigger on the testing range
	if(is_tutorial_level(H.z))
		return TRUE
	return FALSE

/// Rapidly cycles weapon forms over ~5 seconds, then attacks with scythe if still held
/obj/item/ego_weapon/index_vial/proc/start_defense_system(mob/living/user)
	if(defense_active)
		return
	defense_active = TRUE
	w_class = WEIGHT_CLASS_BULKY

	// Track how many times this mob has triggered the defense system
	var/user_ref = REF(user)
	var/strikes = defense_strikes[user_ref] || 0
	strikes++
	defense_strikes[user_ref] = strikes

	// 3rd offense — skip the cycling and immediately attack
	if(strikes >= 3)
		to_chat(user, span_userdanger("The vial has had enough of you!"))
		playsound(get_turf(src), 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)
		if(!QDELETED(src) && !QDELETED(user) && user.is_holding(src))
			defense_scythe_attack(user)
		stop_defense_system()
		return

	to_chat(user, span_userdanger("The vial rejects your touch! It begins shifting wildly!"))
	playsound(get_turf(src), 'sound/weapons/black_vial/vial_swap.ogg', 50, TRUE)

	// Cycle through random weapon forms with decreasing intervals (~5 seconds total)
	var/list/intervals = list(5, 5, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1)
	for(var/delay in intervals)
		if(QDELETED(src) || QDELETED(user) || !user.is_holding(src))
			stop_defense_system()
			return
		var/random_form = pick(weapon_forms)
		icon_state = random_form
		inhand_icon_state = random_form
		if(isliving(user))
			user.update_inv_hands()
		playsound(get_turf(src), 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)
		sleep(delay)

	// Still holding after ~5 seconds — attack with scythe
	if(!QDELETED(src) && !QDELETED(user) && user.is_holding(src))
		defense_scythe_attack(user)
	stop_defense_system()

/// Transforms to scythe and attacks the unauthorized user
/obj/item/ego_weapon/index_vial/proc/defense_scythe_attack(mob/living/user)
	icon_state = "index_vial_scythe"
	inhand_icon_state = "index_vial_scythe"
	user.update_inv_hands()
	to_chat(user, span_userdanger("The vial locks into scythe form and turns on you!"))
	playsound(get_turf(src), 'sound/weapons/black_vial/index_vial_scythe.ogg', 50, TRUE)
	user.deal_damage(80, PALE_DAMAGE, src, flags = DAMAGE_FORCED)
	user.dropItemToGround(src, TRUE)

/// Stops the defense system and resets to the default inactive vial state
/obj/item/ego_weapon/index_vial/proc/stop_defense_system()
	defense_active = FALSE
	w_class = initial(w_class)
	icon_state = "index_vial_inactive"
	inhand_icon_state = "index_vial_inactive"
	unlocked_list = list()
	unlocked = FALSE
	swing_count = 0
	furioso_active = FALSE

/obj/item/ego_weapon/index_vial/attack_hand(mob/user)
	// If someone unauthorized tries to grab the weapon from another mob, slice them
	if(ismob(loc) && loc != user && !is_authorized(user))
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			to_chat(H, span_userdanger("The vial slices your hand as you reach for it!"))
			playsound(get_turf(src), 'sound/weapons/black_vial/index_vial_scythe.ogg', 50, TRUE)
			H.deal_damage(80, PALE_DAMAGE, src, flags = DAMAGE_FORCED)
		return
	return ..()

/obj/item/ego_weapon/index_vial/can_be_pulled(user, grab_state, force)
	if(iscarbon(user) && !is_authorized(user))
		var/mob/living/carbon/C = user
		to_chat(C, span_userdanger("The vial slices your hand as you reach for it!"))
		playsound(get_turf(src), 'sound/weapons/black_vial/index_vial_scythe.ogg', 50, TRUE)
		C.deal_damage(80, PALE_DAMAGE, src, flags = DAMAGE_FORCED)
		return FALSE
	return ..()

/obj/item/ego_weapon/index_vial/canStrip(mob/who)
	. = ..()
	if(!.)
		return TRUE // Pass through to doStrip for the damage check

/obj/item/ego_weapon/index_vial/doStrip(mob/who)
	if(!is_authorized(who))
		if(ishuman(who))
			var/mob/living/carbon/human/H = who
			to_chat(H, span_userdanger("The vial slices your hand as you reach for it!"))
			playsound(get_turf(src), 'sound/weapons/black_vial/index_vial_scythe.ogg', 50, TRUE)
			H.deal_damage(80, PALE_DAMAGE, src, flags = DAMAGE_FORCED)
		return FALSE
	return ..()

/obj/item/ego_weapon/index_vial/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(!is_authorized(user))
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
			// Furioso unlocked - can freely swap to any form
			available = weapon_forms.Copy()
		else
			// All forms used, unlock furioso
			unlocked = TRUE
			to_chat(user, span_userdanger("You've mastered all weapon forms! Furioso is now available!"))
			return

	// Set cooldown for next swap
	var/new_swap_time = world.time + swap_cooldown

	// 5% chance to become fpoon
	if(prob(5))
		var/obj/item/ego_weapon/index_vial/fpoon/new_weapon = new(user.drop_location())
		new_weapon.unlocked_list = unlocked_list.Copy()
		new_weapon.unlocked = unlocked
		new_weapon.next_swap_time = new_swap_time
		playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)
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
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)

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
	// Prevent reset if furioso is unlocked
	if(unlocked)
		to_chat(user, span_warning("Furioso is unlocked. You cannot reset while it's available."))
		return
	// Return to inactive state, resetting progress
	var/obj/item/ego_weapon/index_vial/new_vial = new /obj/item/ego_weapon/index_vial(user.drop_location())
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)
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

	// 5% chance to become fpoon
	if(prob(5))
		var/obj/item/ego_weapon/index_vial/fpoon/new_weapon = new(user.drop_location())
		new_weapon.unlocked_list = unlocked_list.Copy()
		new_weapon.unlocked = unlocked
		new_weapon.next_swap_time = new_swap_time
		playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)
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
	playsound(user, 'sound/weapons/black_vial/vial_swap.ogg', 25, TRUE)
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
	if(furioso_active)
		return
	INVOKE_ASYNC(src, PROC_REF(furioso), user)

/obj/item/ego_weapon/index_vial/proc/furioso(mob/living/user)
	furioso_active = TRUE
	// Collect targets in range
	var/list/targets = list()
	for(var/mob/living/L in range(8, user))
		if(L == user)
			continue
		if(L.status_flags & GODMODE)
			continue
		if(L.stat == DEAD)
			continue
		targets += L

	if(!LAZYLEN(targets))
		to_chat(user, span_warning("There are no enemies nearby!"))
		furioso_active = FALSE
		return

	// Weapon data for Furioso - each weapon has: name, icon, hits, damage, damtype, sound, move
	// Note: damtype uses literal strings ("red", "white", "black", "pale") to ensure proper retrieval from the nested list
	var/static/list/furioso_weapons = list(
		list("name" = "hatchet", "icon" = "index_vial_hatchet", "hits" = 5, "damage" = 30, "damtype" = "red", "sound" = 'sound/weapons/black_vial/index_vial_hatchet.ogg', "move" = "flurry"),
		list("name" = "stiletto", "icon" = "index_vial_stiletto", "hits" = 4, "damage" = 35, "damtype" = "white", "sound" = 'sound/weapons/black_vial/index_vial_stiletto.ogg', "move" = "circle"),
		list("name" = "bastard sword", "icon" = "index_vial_bsword", "hits" = 2, "damage" = 75, "damtype" = "black", "sound" = 'sound/weapons/black_vial/index_vial_bsword.ogg', "move" = "dashthrough"),
		list("name" = "rapier", "icon" = "index_vial_rapier", "hits" = 3, "damage" = 50, "damtype" = "white", "sound" = 'sound/weapons/black_vial/index_vial_rapier.ogg', "move" = "lunge"),
		list("name" = "hammer", "icon" = "index_vial_hammer", "hits" = 2, "damage" = 90, "damtype" = "red", "sound" = 'sound/weapons/black_vial/index_vial_hammer.ogg', "move" = "leapsmash"),
		list("name" = "greatsword", "icon" = "index_vial_gsword", "hits" = 2, "damage" = 100, "damtype" = "black", "sound" = 'sound/weapons/black_vial/index_vial_gsword.ogg', "move" = "dashthrough_heavy"),
		list("name" = "lance", "icon" = "index_vial_lance", "hits" = 2, "damage" = 95, "damtype" = "white", "sound" = 'sound/weapons/black_vial/index_vial_lance.ogg', "move" = "charge"),
		list("name" = "whip", "icon" = "index_vial_whip", "hits" = 2, "damage" = 60, "damtype" = "black", "sound" = 'sound/weapons/black_vial/index_vial_whip.ogg', "move" = "ranged"),
		list("name" = "scythe", "icon" = "index_vial_scythe", "hits" = 1, "damage" = 80, "damtype" = "pale", "sound" = 'sound/weapons/black_vial/index_vial_scythe.ogg', "move" = "reap")
	)

	/// Beam trail colors by damage type
	var/static/list/beam_colors = list(
		"red" = "#9e1638",
		"white" = "#a8c8d8",
		"black" = "#4a0e4e",
		"pale" = "#d0d0d0"
	)

	furioso_start(user, targets)

	// Save original target list so furioso_end can clean up all muted targets,
	// even ones removed from 'targets' during the attack loop due to death
	var/list/all_targets = targets.Copy()

	for(var/list/weapon_data in furioso_weapons)
		var/mob/living/target = furioso_pick_target(targets)
		if(!target)
			break
		furioso_attack(user, target, weapon_data, beam_colors)

	furioso_end(user, all_targets)

/obj/item/ego_weapon/index_vial/proc/furioso_start(mob/living/user, list/targets)
	ADD_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)
	user.status_flags |= GODMODE
	user.Stun(60 SECONDS, ignore_canstun = TRUE)
	user.anchored = TRUE
	for(var/mob/living/L in targets)
		L.Stun(60 SECONDS, ignore_canstun = TRUE)
		if(!istype(L, /mob/living/simple_animal/hostile/debugdummy))
			ADD_TRAIT(L, TRAIT_MUTE, TIMESTOP_TRAIT)
		walk(L, 0)
		if(isanimal(L))
			var/mob/living/simple_animal/S = L
			S.toggle_ai(AI_OFF)

/// Picks a valid living target from the list, removing dead/deleted ones. Returns null if none remain.
/obj/item/ego_weapon/index_vial/proc/furioso_pick_target(list/targets)
	var/mob/living/target = pick(targets)
	if(QDELETED(target) || target.stat == DEAD)
		targets -= target
		if(!LAZYLEN(targets))
			return null
		target = pick(targets)
		if(QDELETED(target))
			return null
	return target

/// Dispatches each furioso weapon attack to its unique movement helper
/obj/item/ego_weapon/index_vial/proc/furioso_attack(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	if(QDELETED(user) || QDELETED(target))
		return
	// Update weapon visuals
	icon_state = weapon_data["icon"]
	inhand_icon_state = weapon_data["icon"]
	user.update_inv_hands()

	var/move_type = weapon_data["move"]
	switch(move_type)
		if("flurry")
			furioso_flurry(user, target, weapon_data, colors)
		if("circle")
			furioso_circle(user, target, weapon_data, colors)
		if("dashthrough")
			furioso_dashthrough(user, target, weapon_data, colors, FALSE)
		if("dashthrough_heavy")
			furioso_dashthrough(user, target, weapon_data, colors, TRUE)
		if("lunge")
			furioso_lunge(user, target, weapon_data, colors)
		if("leapsmash")
			furioso_leapsmash(user, target, weapon_data, colors)
		if("charge")
			furioso_charge(user, target, weapon_data, colors)
		if("ranged")
			furioso_ranged(user, target, weapon_data, colors)
		if("reap")
			furioso_reap(user, target, weapon_data, colors)

/// Shared dash helper: afterimage at origin, forceMove, colored beam trail, face target
/obj/item/ego_weapon/index_vial/proc/furioso_dash_to(mob/living/user, turf/destination, mob/living/target, beam_color)
	var/turf/origin = get_turf(user)
	new /obj/effect/temp_visual/decoy/fading/halfsecond(origin, user)
	user.forceMove(destination)
	user.dir = get_dir(user, target)
	var/datum/beam/trail = origin.Beam(user, "1-full", time = 2)
	if(trail && beam_color)
		trail.visuals.color = beam_color

/// Shared hit helper: sound, visual effect, damage
/obj/item/ego_weapon/index_vial/proc/furioso_hit(mob/living/user, mob/living/target, list/weapon_data, effect_type)
	if(QDELETED(user) || QDELETED(target))
		return
	playsound(user, weapon_data["sound"], 40, TRUE)
	user.do_attack_animation(target)
	if(effect_type)
		new effect_type(get_turf(target))
	target.deal_damage(weapon_data["damage"], weapon_data["damtype"], user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

/// Hatchet: rapid repositioning around target between each hit
/obj/item/ego_weapon/index_vial/proc/furioso_flurry(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	var/beam_color = colors[weapon_data["damtype"]]
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		var/turf/dest = get_step(target.loc, pick(GLOB.cardinals))
		if(!dest)
			dest = get_turf(target)
		furioso_dash_to(user, dest, target, beam_color)
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/smash_effect)
		sleep(0.15 SECONDS)
	sleep(0.2 SECONDS)

/// Stiletto: orbit target, hitting from each cardinal direction
/obj/item/ego_weapon/index_vial/proc/furioso_circle(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	var/beam_color = colors[weapon_data["damtype"]]
	var/list/cardinals = list(NORTH, EAST, SOUTH, WEST)
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		var/dir = cardinals[((i - 1) % 4) + 1]
		var/turf/dest = get_step(target.loc, dir)
		if(!dest)
			dest = get_turf(target)
		furioso_dash_to(user, dest, target, beam_color)
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/slice)
		sleep(0.2 SECONDS)
	sleep(0.2 SECONDS)

/// Bastard Sword / Greatsword: dash through target and back. heavy = camera shake + red smash
/obj/item/ego_weapon/index_vial/proc/furioso_dashthrough(mob/living/user, mob/living/target, list/weapon_data, list/colors, heavy)
	var/beam_color = colors[weapon_data["damtype"]]
	var/effect_type = heavy ? /obj/effect/temp_visual/smash_effect/red : /obj/effect/temp_visual/dir_setting/slash
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Dash through target to the other side
		var/turf/dest = get_ranged_target_turf_direct(user, target, get_dist(user, target) + 2)
		if(!dest)
			dest = get_turf(target)
		furioso_dash_to(user, dest, target, beam_color)
		furioso_hit(user, target, weapon_data, effect_type)
		if(heavy)
			shake_camera(target, 1, 2)
		sleep(0.3 SECONDS)
	sleep(0.2 SECONDS)

/// Rapier: retreat then lunge from distance for each hit
/obj/item/ego_weapon/index_vial/proc/furioso_lunge(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	var/beam_color = colors[weapon_data["damtype"]]
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Retreat to 3 tiles away
		var/turf/retreat = get_ranged_target_turf_direct(target, user, 3)
		if(retreat)
			user.forceMove(retreat)
			user.dir = get_dir(user, target)
		sleep(0.1 SECONDS)
		// Lunge in
		var/turf/dest = get_step(target.loc, get_dir(user, target))
		if(!dest)
			dest = get_turf(target)
		furioso_dash_to(user, dest, target, beam_color)
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/slice)
		sleep(0.2 SECONDS)
	sleep(0.2 SECONDS)

/// Hammer: leap from above with pixel animation and camera shake
/obj/item/ego_weapon/index_vial/proc/furioso_leapsmash(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Afterimage + animate upward and fade out
		new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(user), user)
		animate(user, 0.3 SECONDS, easing = QUAD_EASING, pixel_y = user.base_pixel_y + 16, alpha = 0)
		sleep(0.3 SECONDS)
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Land next to target
		var/turf/dest = get_step(target.loc, pick(GLOB.cardinals))
		if(!dest)
			dest = get_turf(target)
		user.forceMove(dest)
		user.dir = get_dir(user, target)
		// Slam down from above
		user.pixel_y = user.base_pixel_y + 16
		animate(user, 0.15 SECONDS, easing = QUAD_EASING, pixel_y = user.base_pixel_y, alpha = 255)
		sleep(0.15 SECONDS)
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/smash_effect/red)
		shake_camera(target, 1.5, 3)
		sleep(0.3 SECONDS)
	sleep(0.2 SECONDS)

/// Lance: charge from distance through target
/obj/item/ego_weapon/index_vial/proc/furioso_charge(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	var/beam_color = colors[weapon_data["damtype"]]
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Position 4 tiles away
		var/turf/retreat = get_ranged_target_turf_direct(target, user, 4)
		if(retreat)
			user.forceMove(retreat)
			user.dir = get_dir(user, target)
		new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(user), user)
		sleep(0.15 SECONDS)
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Charge through target
		var/turf/dest = get_ranged_target_turf_direct(user, target, get_dist(user, target) + 2)
		if(!dest)
			dest = get_turf(target)
		furioso_dash_to(user, dest, target, beam_color)
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/smash_effect)
		sleep(0.3 SECONDS)
	sleep(0.2 SECONDS)

/// Whip: stay at range and lash with beam visuals
/obj/item/ego_weapon/index_vial/proc/furioso_ranged(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	var/beam_color = colors[weapon_data["damtype"]]
	// Position at 3 tiles away
	var/turf/range_pos = get_ranged_target_turf_direct(target, user, 3)
	if(range_pos && get_dist(user, target) != 3)
		furioso_dash_to(user, range_pos, target, beam_color)
	for(var/i in 1 to weapon_data["hits"])
		if(QDELETED(src) || QDELETED(user) || QDELETED(target))
			return
		// Beam lash from user to target represents the whip
		var/turf/user_turf = get_turf(user)
		var/datum/beam/lash = user_turf.Beam(target, "1-full", time = 3)
		if(lash && beam_color)
			lash.visuals.color = beam_color
		furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/slice)
		sleep(0.4 SECONDS)
	sleep(0.2 SECONDS)

/// Scythe: dramatic finisher leap (thumb-style fade out, teleport, slam in)
/obj/item/ego_weapon/index_vial/proc/furioso_reap(mob/living/user, mob/living/target, list/weapon_data, list/colors)
	if(QDELETED(src) || QDELETED(user) || QDELETED(target))
		return
	// Afterimage at origin
	new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(user), user)

	// Fade out with upward arc toward target
	var/horizontal_difference = target.x - user.x
	var/x_offset = 0
	if(horizontal_difference > 0)
		x_offset = 32
	else if(horizontal_difference < 0)
		x_offset = -32
	animate(user, 0.4 SECONDS, easing = QUAD_EASING, pixel_y = user.base_pixel_y + 16, pixel_x = user.base_pixel_x + x_offset, alpha = 0)
	sleep(0.4 SECONDS)
	if(QDELETED(src) || QDELETED(user) || QDELETED(target))
		return

	// Teleport to target
	var/turf/dest = get_step(target.loc, pick(GLOB.cardinals))
	if(!dest)
		dest = get_turf(target)
	user.forceMove(dest)
	user.dir = get_dir(user, target)

	// Slam in from opposite direction (appear to come from where we started)
	user.pixel_x = user.base_pixel_x + (x_offset * -2)
	user.pixel_y = user.base_pixel_y + 16
	animate(user, 0.2 SECONDS, easing = QUAD_EASING, pixel_y = user.base_pixel_y, pixel_x = user.base_pixel_x, alpha = 255)
	sleep(0.2 SECONDS)

	// Final strike
	furioso_hit(user, target, weapon_data, /obj/effect/temp_visual/smash_effect)
	shake_camera(target, 2, 4)
	sleep(0.3 SECONDS)

/obj/item/ego_weapon/index_vial/proc/furioso_end(mob/living/user, list/targets)
	user.status_flags &= ~GODMODE
	user.AdjustStun(-60 SECONDS, ignore_canstun = TRUE)
	user.anchored = FALSE
	REMOVE_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)

	// Ensure pixel position and alpha are reset (leapsmash/reap use animate())
	user.pixel_x = user.base_pixel_x
	user.pixel_y = user.base_pixel_y
	user.alpha = 255

	for(var/mob/living/L in targets)
		L.AdjustStun(-60 SECONDS, ignore_canstun = TRUE)
		REMOVE_TRAIT(L, TRAIT_MUTE, TIMESTOP_TRAIT)
		if(isanimal(L))
			var/mob/living/simple_animal/S = L
			S.toggle_ai(initial(S.AIStatus))

	// Replace with a fresh base vial to fully reset force/damtype/w_class/etc.
	var/obj/item/ego_weapon/index_vial/new_vial = new /obj/item/ego_weapon/index_vial(user)
	new_vial.defense_strikes = defense_strikes.Copy()
	to_chat(user, span_notice("Furioso-Replica complete. The vial returns to its inactive state."))
	user.put_in_hands(new_vial)
	qdel(src)

// ============================================
// HATCHET - Small, fast weapon with protection on hit
// ============================================
/obj/item/ego_weapon/index_vial/hatchet
	name = "caduceus - hatchet"
	desc = "When hacking through the ribs with a hatchet... This is barely a weapon, but it's better than a fork."
	special = "On hit, gain protection."
	icon_state = "index_vial_hatchet"
	inhand_icon_state = "index_vial_hatchet"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_32x32_right.dmi'
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
	name = "caduceus - stiletto"
	desc = "When penetrating the lungs with a stiletto... I couldn't help but feel a dreadful chill run down my back whenever I'm given this weapon."
	special = "On hit, inflict mental decay on the target."
	icon_state = "index_vial_stiletto"
	inhand_icon_state = "index_vial_stiletto"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_48x48_right.dmi'
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
	name = "caduceus - bastard sword"
	desc = "When cleaving through the shoulder and the skull with a bastard sword... This sword is passable, but that quality leaves a lot to be desired."
	special = "On hit, inflict 5 Overheat."
	icon_state = "index_vial_bsword"
	inhand_icon_state = "index_vial_bsword"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_48x48_right.dmi'
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
		// Inflict 5 OVERHEAT on hit
	if(isliving(M))
		M.apply_lc_overheat(5)

// ============================================
// RAPIER - Precise thrusts with defense debuff
// ============================================
/obj/item/ego_weapon/index_vial/rapier
	name = "caduceus - rapier"
	desc = "When punching 10 or more holes in the torso with a rapier... A weapon longer and sharper than the stiletto. I enjoy the rapier as well."
	special = "On hit, inflict white fragility on the target."
	icon_state = "index_vial_rapier"
	inhand_icon_state = "index_vial_rapier"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_48x48_right.dmi'
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
	name = "caduceus - hammer"
	desc = "When caving in the back of the skull with a hammer... Simple, but final. It will crush whatever it hits."
	special = "On hit, deal stamina damage to the target."
	icon_state = "index_vial_hammer"
	inhand_icon_state = "index_vial_hammer"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_48x48_right.dmi'
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
	name = "caduceus - greatsword"
	desc = "When rending the body with a greatsword... It is important to find your center of gravity and take advantage of its sheer mass."
	special = "On hit, inflict red fragility on the target."
	icon_state = "index_vial_gsword"
	inhand_icon_state = "index_vial_gsword"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_64x64_right.dmi'
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
	name = "caduceus - lance"
	desc = "When boring a 20-inch hole with a lance... I'd consider this weapon a jackpot. This lance has a self-propelling property."
	special = "On hit, inflict white fragility on the target. Has extended reach."
	icon_state = "index_vial_lance"
	inhand_icon_state = "index_vial_lance"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_64x64_right.dmi'
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
	name = "caduceus - whip"
	desc = "When ripping the flesh to ten thousand strips with a whip... I am quite fond of it. It tears a strip off the target's flesh, and with it their resolve."
	special = "On hit, inflict black fragility on the target. Has extended reach."
	icon_state = "index_vial_whip"
	inhand_icon_state = "index_vial_whip"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_48x48_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_48x48_right.dmi'
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
	name = "caduceus - scythe"
	desc = "When lacerating through space itself with a scythe, like a certain someone... This weapon became my favorite, most familiar, and sharpest weapon."
	special = "Deals high pale damage. No special effect needed."
	icon_state = "index_vial_scythe"
	inhand_icon_state = "index_vial_scythe"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_64x64_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_64x64_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/black_vial/index_vial_scythe.ogg'
	force = 80
	damtype = PALE_DAMAGE
	attack_speed = 1.5
	w_class = WEIGHT_CLASS_BULKY
	max_swings = 1
	attack_verb_continuous = list("lacerates", "reaps", "scythes")
	attack_verb_simple = list("lacerate", "reap", "scythe")

// ============================================
// FPOON - Rare joke weapon (5% chance on swap)
// ============================================
/obj/item/ego_weapon/index_vial/fpoon
	name = "caduceus - fpoon"
	desc = "A fpoon. It's a spoon with fork tines. Why did the vial turn into this?"
	special = "Attack yourself to end it all with a fpoon. How embarrassing."
	icon_state = "index_vial_fpoon"
	inhand_icon_state = "index_vial_fpoon"
	lefthand_file = 'icons/obj/spider_house/index/index_vial_32x32_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_vial_32x32_right.dmi'
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
		if(!is_tutorial_level(user.z))
			for(var/mob/P in GLOB.player_list)
				to_chat(P, span_userdanger("[uppertext(user.real_name)] has died to a fpoon. How embarrassing."))
		return
	. = ..()
	if(!.)
		return
	// Inflict 5 bleed on hit
	if(isliving(M))
		M.apply_lc_bleed(5)

// ================== INDEX EGO DATUMS ==================
// Placed here rather than in _cityweapons_datums.dm / _cityarmor_datums.dm
// to prevent DM merge conflicts with other sub-PRs that modify those shared files.

/* --- Index Caduceus (Maestro Weapon) --- */

/// Caduceus (Base/Inactive)
/datum/ego_datum/weapon/city/index_vial
	item_path = /obj/item/ego_weapon/index_vial
	cost = 100
	ego_tags = list(EGO_TAG_VERSATILE_DAMAGE, EGO_TAG_HAZARDOUS)

/// Caduceus - Hatchet
/datum/ego_datum/weapon/city/index_vial/hatchet
	item_path = /obj/item/ego_weapon/index_vial/hatchet
	cost = 30
	ego_tags = list(EGO_TAG_SUSTAIN)

/// Caduceus - Stiletto
/datum/ego_datum/weapon/city/index_vial/stiletto
	item_path = /obj/item/ego_weapon/index_vial/stiletto
	cost = 35
	ego_tags = list(EGO_TAG_DOT)

/// Caduceus - Bastard Sword
/datum/ego_datum/weapon/city/index_vial/bsword
	item_path = /obj/item/ego_weapon/index_vial/bsword
	cost = 60
	ego_tags = list(EGO_TAG_DOT)

/// Caduceus - Rapier
/datum/ego_datum/weapon/city/index_vial/rapier
	item_path = /obj/item/ego_weapon/index_vial/rapier
	cost = 50
	ego_tags = list(EGO_TAG_DEBUFFER)

/// Caduceus - Hammer
/datum/ego_datum/weapon/city/index_vial/hammer
	item_path = /obj/item/ego_weapon/index_vial/hammer
	cost = 70
	ego_tags = list(EGO_TAG_DEBUFFER)

/// Caduceus - Greatsword
/datum/ego_datum/weapon/city/index_vial/gsword
	item_path = /obj/item/ego_weapon/index_vial/gsword
	cost = 80
	ego_tags = list(EGO_TAG_DEBUFFER)

/// Caduceus - Lance
/datum/ego_datum/weapon/city/index_vial/lance
	item_path = /obj/item/ego_weapon/index_vial/lance
	cost = 80
	ego_tags = list(EGO_TAG_REACH, EGO_TAG_DEBUFFER)

/// Caduceus - Whip
/datum/ego_datum/weapon/city/index_vial/whip
	item_path = /obj/item/ego_weapon/index_vial/whip
	cost = 60
	ego_tags = list(EGO_TAG_REACH, EGO_TAG_DEBUFFER)

/// Caduceus - Scythe
/datum/ego_datum/weapon/city/index_vial/scythe
	item_path = /obj/item/ego_weapon/index_vial/scythe
	cost = 70
	ego_tags = list()

/// Caduceus - Fpoon
/datum/ego_datum/weapon/city/index_vial/fpoon
	item_path = /obj/item/ego_weapon/index_vial/fpoon
	cost = 5
	ego_tags = list(EGO_TAG_HAZARDOUS, EGO_TAG_DOT)

/* --- Index Apprentice (Chains/Procuration — dispense armor) --- */

/// Index Apprentice Chains (dispenses apprentice armor)
/datum/ego_datum/weapon/city/index_chains
	item_path = /obj/item/ego_weapon/city/index_apprentice_chains
	dispense_path = /obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice
	cost = 50
	ego_tags = list(EGO_TAG_MOBILITY, EGO_TAG_AOE_RADIAL)

/// Effloresced E.G.O :: Procuration (dispenses apprentice armor)
/datum/ego_datum/weapon/city/index_procuration
	item_path = /obj/item/ego_weapon/city/index_procuration
	dispense_path = /obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice
	cost = 70
	ego_tags = list(EGO_TAG_MOBILITY)

/* --- Index Armor --- */

/// Index Proxy Apprentice Armor
/datum/ego_datum/armor/city/index_apprentice
	item_path = /obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice
	cost = 70
	ego_tags = list(EGO_TAG_MOBILITY)

/// Wandering Index Proxy Armor
/datum/ego_datum/armor/city/index_wanderer
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	cost = 100
