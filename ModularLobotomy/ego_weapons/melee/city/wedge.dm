/// Angle between where the target faces and where the attacker stands: 0 front, 45 front diagonal, 90 side,
/// 135 back diagonal, 180 back. Null when they share a tile, since there is no direction between them.
/proc/WedgeAttackAngle(mob/living/target, mob/living/attacker)
	var/to_attacker = get_dir(target, attacker)
	if(!to_attacker)
		return null
	var/angle = abs(dir2angle(target.dir) - dir2angle(to_attacker))
	return angle > 180 ? 360 - angle : angle

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
	special = "Hits grant poise, more the further you strike from the target's front. Hits from behind grant concentration instead. \
		Use in hand to rally, granting yourself 5 poise, and nearby Wedge Office members 5 poise and 2 black strength. \
		While the winds are active, click a target out of reach to wind up, then dash through them and strike. If that strike crits, it consumes all \
		your poise and concentration to deal 1% extra damage per poise, multiplied by concentration, up to 400%. Against simple creatures it always deals at least 100% extra damage."
	force = 68
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	/// How much poise is required to show the wind.
	var/wind_poise = 10
	/// Whether the wind is currently shown.
	var/wind_active = FALSE
	/// How long the rally takes to call.
	var/rally_delay = 2 SECONDS
	/// Range in tiles the rally reaches allies in.
	var/rally_range = 5
	/// Poise the rally grants to the user and each ally.
	var/rally_poise = 5
	/// Black strength the rally grants to each ally.
	var/rally_black_strength = 2
	/// World time when the next rally is allowed.
	var/rally_cooldown = 0
	/// Cooldown between rallies.
	var/rally_cooldown_time = 10 SECONDS
	/// How long the finisher winds up before teleporting.
	var/finisher_windup = 3 SECONDS
	/// Range in tiles the finisher target has to stay seen within.
	var/finisher_range = 7
	/// Extra damage percent a crit finisher deals per poise, multiplied by concentration.
	var/finisher_bonus_per_poise = 1
	/// Most extra damage percent a crit finisher can deal.
	var/finisher_max_bonus = 400
	/// Extra damage percent the finisher always deals to simple mobs.
	var/finisher_simple_bonus = 100
	/// World time when the next finisher is allowed.
	var/finisher_cooldown = 0
	/// Cooldown between finishers, started when one lands.
	var/finisher_cooldown_time = 25 SECONDS
	/// Whether the finisher is winding up. The user cannot attack or rally while it is.
	var/finisher_charging = FALSE
	/// Whether the finisher strike is being dealt right now, so OnPoiseCrit knows to record the crit.
	var/finisher_striking = FALSE
	/// Whether the finisher strike crit.
	var/finisher_crit = FALSE
	/// Force before the finisher strike changed it, restored after the strike.
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

/// Starts the rally cooldown and grants poise to the user, and poise and black strength to nearby Wedge Office members.
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
		// Show the wind on an ally's own spear right away instead of on their next hit.
		var/obj/item/ego_weapon/city/wedge/neocity/ally_spear = ally.get_active_held_item()
		if(istype(ally_spear))
			ally_spear.UpdateWind(ally)

/// Stops the attack chain, swings included, while the finisher winds up.
/obj/item/ego_weapon/city/wedge/neocity/pre_attack(atom/A, mob/living/user, params)
	if(finisher_charging)
		return TRUE
	return ..()

/obj/item/ego_weapon/city/wedge/neocity/attack(mob/living/target, mob/living/user)
	var/target_living = FALSE
	if(target.stat != DEAD)
		target_living = TRUE
	. = ..()
	// FALSE when the user could not use the weapon, so the hit never happened.
	if(!. || QDELETED(user))
		return
	if(target_living)
		var/relative_angle = WedgeAttackAngle(target, user)
		if(isnull(relative_angle))
			return
		if(relative_angle < 45)
			user.apply_lc_poise(1)
		else if(relative_angle < 90)
			user.apply_lc_poise(2)
		else if(relative_angle < 135)
			user.apply_lc_poise(4)
		else
			user.apply_lc_concentration(2)
	UpdateWind(user)

/// Clicking out of reach looks for a finisher target around the clicked tile and winds up on it.
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

/// Picks a target in the 3x3 around center, center tile first. Hostile mobs come first, then humans outside the Wedge Office.
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

/// Winds up on the user, then dashes through the target and strikes. A crit spends all poise and concentration for extra damage.
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

/// Plays the wind and charge sound and holds the user turned away from the target. TRUE if the windup finished.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherWindup(mob/living/target, mob/living/user)
	user.visible_message(span_userdanger("[user] lowers [src] and fixes [user.p_their()] eyes on [target]...!"), span_danger("You fix your eyes on [target]...!"))
	// Centered on the user; overlays take the user's dir, so the wind turns with them.
	var/mutable_appearance/wind_overlay = mutable_appearance('icons/effects/96x96.dmi', "wedge_finisher_wind", ABOVE_MOB_LAYER)
	wind_overlay.pixel_x = -32
	wind_overlay.pixel_y = -32
	user.add_overlay(wind_overlay)
	playsound(user, 'sound/weapons/fixer/wedge_leader_charge.ogg', 100, TRUE)
	finisher_charging = TRUE
	FinisherCheck(user, target)
	var/wound_up = do_after(user, finisher_windup, target, IGNORE_TARGET_LOC_CHANGE, TRUE, CALLBACK(src, PROC_REF(FinisherCheck), user, target), "wedge_finisher", 1)
	finisher_charging = FALSE
	user.cut_overlay(wind_overlay)
	return wound_up

/// Moves the user through the target to the far side of them, or onto their tile if that one is blocked.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherDash(mob/living/target, mob/living/user)
	var/turf/start = get_turf(user)
	var/turf/landing = get_step(target, get_dir(start, target))
	if(!landing || landing.is_blocked_turf(TRUE))
		landing = get_turf(target)
	user.forceMove(landing)
	user.face_atom(target)
	DashVisuals(start, landing, get_turf(target))

/// Hits the target with the finisher's bonus force and sound, then spends all poise and concentration if it crit.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherStrike(mob/living/target, mob/living/user)
	finisher_crit = FALSE
	finisher_striking = TRUE
	finisher_base_force = force
	// Simple mobs always take the flat bonus; anyone else gets theirs from OnPoiseCrit if the strike crits.
	if(isanimal(target))
		force = finisher_base_force * (1 + finisher_simple_bonus / 100)
	// The finisher strike uses its own hit sound.
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

/// Draws the finisher dash: a beam from start to landing, a burst on the target and a spear tip on the beam's end.
/obj/item/ego_weapon/city/wedge/neocity/proc/DashVisuals(turf/start, turf/landing, turf/target_turf)
	if(start != landing)
		start.Beam(landing, "wedge_transpierce", time = 6)
		var/obj/effect/temp_visual/wedge_transpierce_tip/tip = new(landing)
		var/matrix/M = matrix()
		M.Turn(Get_Angle(start, landing))
		tip.transform = M
	new /obj/effect/temp_visual/wedge_transpierce_burst(target_turf)

/// Checked every tick of the finisher windup: fails once the target is out of sight, and keeps the user turned away from them.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherCheck(mob/living/user, mob/living/target)
	if(!can_see(user, target, finisher_range))
		return FALSE
	var/away = get_dir(target, user)
	if(away)
		user.setDir(away)
	return TRUE

/// Shows or hides the wind to match the user's current poise.
/obj/item/ego_weapon/city/wedge/neocity/proc/UpdateWind(mob/living/user)
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	SetWind(user, P ? P.stacks : 0)

/// Shows the wind when the given poise is high enough and the spear is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/city/wedge/neocity/proc/SetWind(mob/living/user, poise)
	var/should_show = (poise >= wind_poise && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

/obj/item/ego_weapon/city/wedge/neocity/proc/OnPoiseCrit(mob/living/user, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	if(!P)
		return
	var/datum/status_effect/stacking/concentration/C = user.has_status_effect(/datum/status_effect/stacking/concentration)
	// Sent mid-attack, after the crit roll and before the hit's damage, with full stacks, so raising force here boosts this hit.
	if(finisher_striking)
		finisher_crit = TRUE
		var/concentration = C ? max(C.stacks, 1) : 1
		var/bonus_percent = min(P.stacks * finisher_bonus_per_poise * concentration, finisher_max_bonus)
		// Simple mobs keep their flat bonus when it is the larger one.
		if(isanimal(target))
			bonus_percent = max(bonus_percent, finisher_simple_bonus)
		force = finisher_base_force * (1 + bonus_percent / 100)
	SetWind(user, (C && C.stacks > 0) ? P.stacks : round(P.stacks / 2))

/obj/item/ego_weapon/city/wedge/neocity/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands || !wind_active)
		return
	. += mutable_appearance(icon_file, "[icon_state]_wind")

/// Flash on the target of the Wedge spear finisher dash.
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

/// Spear tip on the end of the finisher dash beam. Drawn pointing north; DashVisuals() turns it to the beam's angle.
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
	special = "Hits outside a charge grant poise, more the further you strike from the target's front. Hits from behind grant concentration instead. \
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

/obj/item/ego_weapon/lance/wedge/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!user)
		return
	RegisterSignal(user, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(OnPoiseCrit), override = TRUE)

/obj/item/ego_weapon/lance/wedge/dropped(mob/user)
	. = ..()
	wind_active = FALSE
	if(user)
		UnregisterSignal(user, COMSIG_POISE_CRIT_ATTACKER)

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
		var/relative_angle = WedgeAttackAngle(target, user)
		if(isnull(relative_angle))
			return
		if(relative_angle < 45)
			user.apply_lc_poise(1)
		else if(relative_angle < 90)
			user.apply_lc_poise(2)
		else if(relative_angle < 135)
			user.apply_lc_poise(4)
		else
			user.apply_lc_concentration(2)
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	SetWind(user, P ? P.stacks : 0)

/obj/item/ego_weapon/lance/wedge/LowerLance(user)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	var/datum/status_effect/stacking/poise/P = living_user.has_status_effect(/datum/status_effect/stacking/poise)
	SetWind(living_user, P ? P.stacks : 0)
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
		SetWind(living_user, 0)
	RaiseLance(user)

/// Shows the wind when the given poise is high enough and the lance is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/lance/wedge/proc/SetWind(mob/living/user, poise)
	var/should_show = (poise >= wind_poise && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

/obj/item/ego_weapon/lance/wedge/proc/OnPoiseCrit(mob/living/user, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	if(!P)
		return
	var/datum/status_effect/stacking/concentration/C = user.has_status_effect(/datum/status_effect/stacking/concentration)
	SetWind(user, (C && C.stacks > 0) ? P.stacks : round(P.stacks / 2))

/obj/item/ego_weapon/lance/wedge/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands || !wind_active)
		return
	. += mutable_appearance(icon_file, "[inhand_icon_state]_wind")
