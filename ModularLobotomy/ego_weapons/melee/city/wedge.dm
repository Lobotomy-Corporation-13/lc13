//Wedge - Grade 4 with two range.
/obj/item/ego_weapon/city/wedge
	name = "wedge office spear"
	desc = "A black, ornate spear. Some say it pierces any weakness... Though that may just be what the office who used these says."
	icon_state = "wedge"
	force = 74
	reach = 2		//Has 2 Square Reach.
	attack_speed = 1
	stuntime = 5
	damtype = BLACK_DAMAGE

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/item/ego_weapon/city/wedge/neocity
	name = "wedge office operator spear"
	special = "Hits on a target within 1 tile grant 4 poise. Hits on a target 2 tiles away grant 2 concentration. \
		Use in hand to rally, granting yourself 5 poise, and nearby Wedge Office members 5 poise and 2 black strength. \
		While the winds are active, click a target out of reach to wind up, then dash through them and strike. If that strike crits, it consumes all \
		your poise and concentration to deal 1% extra damage per poise, multiplied by concentration, up to 400%."
	force = 68
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	// Poise granted by a hit on a target within 1 tile.
	var/close_hit_poise = 4
	// Concentration granted by a hit on a target 2 tiles away.
	var/far_hit_concentration = 2
	// How much poise is required to show the wind.
	var/wind_poise = 10
	// Whether the wind is currently shown.
	var/wind_active = FALSE
	// How long the rally takes to call.
	var/rally_delay = 2 SECONDS
	// Range in tiles the rally reaches allies in.
	var/rally_range = 5
	// Poise the rally grants to the user and each ally.
	var/rally_poise = 5
	// Black strength the rally grants to each ally.
	var/rally_black_strength = 2
	// World time when the next rally is allowed.
	var/rally_cooldown = 0
	// Cooldown between rallies.
	var/rally_cooldown_time = 10 SECONDS
	// How long the finisher winds up before teleporting.
	var/finisher_windup = 3 SECONDS
	// Range in tiles the finisher target has to stay seen within.
	var/finisher_range = 7
	// Extra damage percent a crit finisher deals per poise, multiplied by concentration.
	var/finisher_bonus_per_poise = 1
	// Most extra damage percent a crit finisher can deal.
	var/finisher_max_bonus = 400
	// World time when the next finisher is allowed.
	var/finisher_cooldown = 0
	// Cooldown between finishers, started when one lands.
	var/finisher_cooldown_time = 25 SECONDS
	// Whether the finisher is winding up. The user cannot attack or rally while it is.
	var/finisher_charging = FALSE
	// Whether the finisher strike is being dealt right now, so OnPoiseCrit knows to record the crit.
	var/finisher_striking = FALSE
	// Whether the finisher strike crit.
	var/finisher_crit = FALSE
	// Force before the finisher strike changed it, restored after the strike.
	var/finisher_base_force = 0

/obj/item/ego_weapon/city/wedge/neocity/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!user)
		return
	RegisterSignal(user, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(OnPoiseCrit), override = TRUE)

/obj/item/ego_weapon/city/wedge/neocity/dropped(mob/user)
	. = ..()
	wind_active = FALSE
	if(user)
		UnregisterSignal(user, COMSIG_POISE_CRIT_ATTACKER)

/obj/item/ego_weapon/city/wedge/neocity/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(finisher_charging || !CanUseEgo(user))
		return
	if(rally_cooldown > world.time)
		to_chat(user, span_warning("You cannot rally again for another [DisplayTimeText(rally_cooldown - world.time)]."))
		return
	user.visible_message(span_notice("[user] raises [src] and calls out to [user.p_their()] office."), span_notice("You raise [src] and call out to your office."))
	var/visual_overlay = mutable_appearance('icons/effects/effects.dmi', "blip")
	user.add_overlay(visual_overlay)
	if(!do_after(user, rally_delay, user, interaction_key = src))
		user.cut_overlay(visual_overlay)
		return
	user.cut_overlay(visual_overlay)
	Rally(user)

// Starts the rally cooldown and grants poise to the user, and poise and black strength to nearby Wedge Office members.
/obj/item/ego_weapon/city/wedge/neocity/proc/Rally(mob/living/carbon/human/user)
	rally_cooldown = world.time + rally_cooldown_time
	new /obj/effect/temp_visual/screech(get_turf(user))
	playsound(loc, 'sound/effects/ordeals/steel/gcorp_chitter.ogg', 40, TRUE)
	user.apply_lc_poise(rally_poise)
	UpdateWind(user)
	for(var/mob/living/carbon/human/ally in view(rally_range, user))
		if(ally == user || ally.stat == DEAD)
			continue
		if(!istype(ally.wear_suit, /obj/item/clothing/suit/armor/ego_gear/city/wedge))
			continue
		ally.apply_lc_poise(rally_poise)
		ally.apply_lc_black_strength(rally_black_strength)
		to_chat(ally, span_nicegreen("[user]'s call steadies you."))
		var/obj/item/ego_weapon/city/wedge/neocity/ally_spear = ally.get_active_held_item()
		if(istype(ally_spear))
			ally_spear.UpdateWind(ally)

/obj/item/ego_weapon/city/wedge/neocity/attack(mob/living/target, mob/living/user)
	if(finisher_charging)
		return
	var/target_living = FALSE
	if(target.stat != DEAD)
		target_living = TRUE
	. = ..()
	if(!. || QDELETED(user))
		return
	if(target_living)
		var/distance = get_dist(user, target)
		if(distance <= 1)
			user.apply_lc_poise(close_hit_poise)
		else if(distance == 2)
			user.apply_lc_concentration(far_hit_concentration)
	UpdateWind(user)

// Clicking out of reach looks for a finisher target around the clicked tile and winds up on it.
/obj/item/ego_weapon/city/wedge/neocity/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(finisher_charging)
		return
	var/turf/clicked_turf = get_turf(target)
	if(!clicked_turf || get_dist(user, clicked_turf) <= reach)
		return
	if(!CanUseEgo(user))
		return
	// Refresh first, in case poise decayed since the last hit.
	UpdateWind(user)
	if(!wind_active)
		return
	if(finisher_cooldown > world.time)
		to_chat(user, span_warning("You cannot use your finisher for another [DisplayTimeText(finisher_cooldown - world.time)]."))
		return
	var/mob/living/finisher_target = FindFinisherTarget(clicked_turf, user)
	if(!finisher_target)
		return
	Finisher(finisher_target, user)

// Picks a target in the 3x3 around center, center tile first. Hostile mobs come first, then humans outside the Wedge Office.
/obj/item/ego_weapon/city/wedge/neocity/proc/FindFinisherTarget(turf/center, mob/living/user)
	var/list/turfs = list(center) + (RANGE_TURFS(1, center) - center)
	for(var/turf/T as anything in turfs)
		for(var/mob/living/simple_animal/hostile/H in T)
			if(H.stat != DEAD)
				return H
	for(var/turf/T as anything in turfs)
		for(var/mob/living/carbon/human/H in T)
			if(H == user || H.stat == DEAD)
				continue
			if(istype(H.wear_suit, /obj/item/clothing/suit/armor/ego_gear/city/wedge))
				continue
			return H
	return null

// Winds up on the user, then dashes through the target and strikes. A crit spends all poise and concentration for extra damage.
/obj/item/ego_weapon/city/wedge/neocity/proc/Finisher(mob/living/target, mob/living/user)
	if(!FinisherWindup(target, user))
		to_chat(user, span_warning("You lose sight of your opening!"))
		return
	if(QDELETED(target) || target.stat == DEAD || !can_see(user, target, finisher_range))
		to_chat(user, span_warning("You lose sight of your opening!"))
		return
	FinisherDash(target, user)
	finisher_cooldown = world.time + finisher_cooldown_time
	FinisherStrike(target, user)

// Plays the wind and charge sound and holds the user turned away from the target. TRUE if the windup finished.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherWindup(mob/living/target, mob/living/user)
	user.visible_message(span_userdanger("[user] lowers [src] and fixes [user.p_their()] eyes on [target]...!"), span_danger("You fix your eyes on [target]...!"))
	var/mutable_appearance/wind_overlay = mutable_appearance('icons/effects/96x96.dmi', "wedge_finisher_wind", ABOVE_MOB_LAYER)
	wind_overlay.pixel_x = -32
	wind_overlay.pixel_y = -32
	user.add_overlay(wind_overlay)
	playsound(user, 'sound/weapons/fixer/wedge_leader_charge.ogg', 70, TRUE)
	finisher_charging = TRUE
	FinisherCheck(user, target)
	var/wound_up = do_after(user, finisher_windup, target, IGNORE_TARGET_LOC_CHANGE, TRUE, CALLBACK(src, PROC_REF(FinisherCheck), user, target))
	finisher_charging = FALSE
	user.cut_overlay(wind_overlay)
	return wound_up

// Moves the user through the target to the far side of them, or onto their tile if that one is blocked.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherDash(mob/living/target, mob/living/user)
	var/turf/start = get_turf(user)
	var/turf/landing = get_step(target, get_dir(start, target))
	if(!landing || landing.is_blocked_turf(TRUE))
		landing = get_turf(target)
	user.forceMove(landing)
	user.face_atom(target)
	DashVisuals(start, landing, get_turf(target))

// Hits the target with the finisher's bonus force and sound, then spends all poise and concentration if it crit.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherStrike(mob/living/target, mob/living/user)
	finisher_crit = FALSE
	finisher_striking = TRUE
	finisher_base_force = force
	hitsound = 'sound/weapons/fixer/wedge_leader_transpierce.ogg'
	target.attackby(src, user)
	hitsound = initial(hitsound)
	force = finisher_base_force
	finisher_striking = FALSE
	if(QDELETED(user) || !finisher_crit)
		return
	user.remove_status_effect(/datum/status_effect/stacking/poise)
	user.remove_status_effect(/datum/status_effect/stacking/concentration)
	UpdateWind(user)

/obj/item/ego_weapon/city/wedge/neocity/proc/DashVisuals(turf/start, turf/landing, turf/target_turf)
	if(start != landing)
		start.Beam(landing, "wedge_transpierce", time = 6)
		var/obj/effect/temp_visual/wedge_transpierce_tip/tip = new(landing)
		tip.transform = matrix().Turn(Get_Angle(start, landing))
	new /obj/effect/temp_visual/wedge_transpierce_burst(target_turf)

/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherCheck(mob/living/user, mob/living/target)
	if(!can_see(user, target, finisher_range))
		return FALSE
	var/away = get_dir(target, user)
	if(away)
		user.setDir(away)
	return TRUE

// Shows the wind while the user has enough poise and the spear is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/city/wedge/neocity/proc/UpdateWind(mob/living/user)
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	var/should_show = (P && P.stacks >= wind_poise && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

// Sent mid-attack, after the crit roll and before the hit's damage, with full stacks, so raising force here boosts this hit.
/obj/item/ego_weapon/city/wedge/neocity/proc/OnPoiseCrit(mob/living/user, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	if(!P)
		return
	var/datum/status_effect/stacking/concentration/C = user.has_status_effect(/datum/status_effect/stacking/concentration)
	if(finisher_striking)
		finisher_crit = TRUE
		var/concentration = C ? max(C.stacks, 1) : 1
		var/bonus_percent = min(P.stacks * finisher_bonus_per_poise * concentration, finisher_max_bonus)
		force = finisher_base_force * (1 + bonus_percent / 100)

/obj/item/ego_weapon/city/wedge/neocity/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands || !wind_active)
		return
	. += mutable_appearance(icon_file, "[icon_state]_wind")

// Flash on the target of the Wedge spear finisher dash.
/obj/effect/temp_visual/wedge_transpierce_burst
	icon = 'icons/effects/96x96.dmi'
	icon_state = "wedge_transpierce_burst"
	pixel_x = -32
	pixel_y = -32
	base_pixel_x = -32
	base_pixel_y = -32
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	duration = 6

// Spear tip on the end of the finisher dash beam. Drawn pointing north; DashVisuals() turns it to the beam's angle.
/obj/effect/temp_visual/wedge_transpierce_tip
	icon = 'icons/effects/96x96.dmi'
	icon_state = "wedge_transpierce_tip"
	pixel_x = -32
	pixel_y = -32
	base_pixel_x = -32
	base_pixel_y = -32
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	duration = 6

//Wedge lance - Grade 6
/obj/item/ego_weapon/lance/wedge
	name = "wedge office fixer lance"
	desc = "A black lance with a long, tapered head. Wedge office fixers favor it for keeping a suspect at a distance."
	special = "Hits outside a charge on a target within 1 tile grant 4 poise. Hits outside a charge on a target 2 tiles away grant 2 concentration. \
		Charging with 15+ poise starts the charge at high speed and builds damage faster, but it stops shortly after reaching full damage and consumes all poise."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	icon_state = "wedge_lance"
	lefthand_file = 'icons/mob/inhands/96x96_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/96x96_righthand.dmi'
	inhand_x_dimension = 96
	inhand_y_dimension = 96
	force = 64
	force_cap = 80
	attack_speed = 2
	reach = 2
	stuntime = 5
	damtype = BLACK_DAMAGE
	default_attack_verbs = list("pierces", "jabs")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 40,
		TEMPERANCE_ATTRIBUTE = 40,
		JUSTICE_ATTRIBUTE = 40,
	)
	// Poise granted by a hit outside a charge on a target within 1 tile.
	var/close_hit_poise = 4
	// Concentration granted by a hit outside a charge on a target 2 tiles away.
	var/far_hit_concentration = 2
	// How much poise is required to activate the wind effect.
	var/wind_poise = 15
	// Whether the wind effect is currently active.
	var/wind_active = FALSE
	// Starting charge speed when boosted
	var/increased_charge_speed = -1.5
	// How much force is added per tile while boosted.
	var/increased_force_per_tile = 6
	// Whether the current charge was started with enough poise.
	var/boosted_charge = FALSE
	// Tiles moved since this charge hit force_cap.
	var/tiles_past_cap = 0
	var/max_tiles_past_cap = 4

/obj/item/ego_weapon/lance/wedge/dropped(mob/user)
	. = ..()
	wind_active = FALSE

/obj/item/ego_weapon/lance/wedge/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	var/target_living = FALSE
	if(target.stat != DEAD)
		target_living = TRUE
	. = ..()
	if(QDELETED(user))
		return
	if(target_living && raised)
		var/distance = get_dist(user, target)
		if(distance <= 1)
			user.apply_lc_poise(close_hit_poise)
		else if(distance == 2)
			user.apply_lc_concentration(far_hit_concentration)
	UpdateWind(user)

/obj/item/ego_weapon/lance/wedge/LowerLance(user)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	UpdateWind(living_user)
	var/datum/status_effect/stacking/poise/P = living_user.has_status_effect(/datum/status_effect/stacking/poise)
	if(P && P.stacks >= wind_poise)
		boosted_charge = TRUE
		playsound(living_user, 'sound/weapons/fixer/wedge_charge.ogg', 100, TRUE)
		charge_speed = increased_charge_speed
		living_user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/charge, multiplicative_slowdown = charge_speed)
		force_per_tile = increased_force_per_tile

/obj/item/ego_weapon/lance/wedge/RaiseLance(user)
	. = ..()
	force_per_tile = initial(force_per_tile)
	boosted_charge = FALSE
	tiles_past_cap = 0

/obj/item/ego_weapon/lance/wedge/UserMoved(mob/user)
	var/was_capped = (force >= force_cap)
	. = ..()
	if(raised || !boosted_charge || !was_capped)
		return
	tiles_past_cap++
	if(tiles_past_cap < max_tiles_past_cap)
		return
	to_chat(user, span_warning("The winds around [src] die down and your charge loses its momentum."))
	if(isliving(user))
		var/mob/living/living_user = user
		living_user.remove_status_effect(/datum/status_effect/stacking/poise)
		UpdateWind(living_user)
	RaiseLance(user)

// Shows the wind while the user has enough poise and the lance is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/lance/wedge/proc/UpdateWind(mob/living/user)
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	var/should_show = (P && P.stacks >= wind_poise && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

/obj/item/ego_weapon/lance/wedge/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands || !wind_active)
		return
	. += mutable_appearance(icon_file, "[inhand_icon_state]_wind")
