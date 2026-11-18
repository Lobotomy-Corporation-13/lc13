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
	special = "Repeated hits on one target build momentum (+1, +2, +3...). Switching targets or 5 seconds idle resets it. \
		Use in hand to rally nearby Wedge allies: +5 momentum and 2 black strength. \
		At 15+ momentum, click a distant target to dash through them, spending all momentum for +10% damage each (max 400%)."
	force = 68
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	// Current momentum stacks.
	var/momentum = 0
	// Momentum the next hit on the same target grants. Goes up by 1 with each hit.
	var/momentum_gain = 1
	// The target the current momentum chain is built on.
	var/datum/weakref/momentum_target
	// How long without a hit before momentum resets.
	var/momentum_decay_time = 5 SECONDS
	// Timer that resets momentum once it runs out.
	var/momentum_decay_timer
	// How much momentum is required to show the wind.
	var/wind_momentum = 15
	// Whether the wind is currently shown.
	var/wind_active = FALSE
	// How long the rally takes to call.
	var/rally_delay = 2 SECONDS
	// Range in tiles the rally reaches allies in.
	var/rally_range = 5
	// Momentum the rally grants to the user's spear and to each ally's Wedge weapon.
	var/rally_momentum = 5
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
	// Extra damage percent the finisher deals per momentum.
	var/finisher_bonus_per_momentum = 10
	// Most extra damage percent the finisher can deal.
	var/finisher_max_bonus = 400
	// World time when the next finisher is allowed.
	var/finisher_cooldown = 0
	// Cooldown between finishers, started when one lands.
	var/finisher_cooldown_time = 15 SECONDS
	// Whether the finisher is winding up. The user cannot attack or rally while it is.
	var/finisher_charging = FALSE

/obj/item/ego_weapon/city/wedge/neocity/dropped(mob/user)
	. = ..()
	ResetMomentum()
	wind_active = FALSE

/obj/item/ego_weapon/city/wedge/neocity/examine(mob/user)
	. = ..()
	. += span_notice("Momentum: [momentum] ([wind_momentum] needed for the finisher).")

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

// Starts the rally cooldown and grants momentum to the user's spear, and momentum and black strength to nearby Wedge Office members.
/obj/item/ego_weapon/city/wedge/neocity/proc/Rally(mob/living/carbon/human/user)
	rally_cooldown = world.time + rally_cooldown_time
	new /obj/effect/temp_visual/screech(get_turf(user))
	playsound(loc, 'sound/effects/ordeals/steel/gcorp_chitter.ogg', 40, TRUE)
	AddMomentum(rally_momentum, user)
	for(var/mob/living/carbon/human/ally in view(rally_range, user))
		if(ally == user || ally.stat == DEAD)
			continue
		if(!istype(ally.wear_suit, /obj/item/clothing/suit/armor/ego_gear/city/wedge))
			continue
		ally.apply_lc_black_strength(rally_black_strength)
		to_chat(ally, span_nicegreen("[user]'s call steadies you."))
		var/obj/item/held = ally.get_active_held_item()
		if(istype(held, /obj/item/ego_weapon/city/wedge/neocity))
			var/obj/item/ego_weapon/city/wedge/neocity/ally_spear = held
			ally_spear.AddMomentum(rally_momentum, ally)
		else if(istype(held, /obj/item/ego_weapon/lance/wedge))
			var/obj/item/ego_weapon/lance/wedge/ally_lance = held
			ally_lance.AddMomentum(rally_momentum, ally)

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
		HitMomentum(target, user)

// Grants momentum for a hit on target, 1 more than the last hit. A hit on a different target than the last one restarts the chain.
/obj/item/ego_weapon/city/wedge/neocity/proc/HitMomentum(mob/living/target, mob/living/user)
	var/mob/living/last_target = momentum_target?.resolve()
	if(last_target && last_target != target)
		ResetMomentum()
	momentum_target = WEAKREF(target)
	AddMomentum(momentum_gain, user)
	momentum_gain++

// Adds momentum and restarts the decay timer.
/obj/item/ego_weapon/city/wedge/neocity/proc/AddMomentum(amount, mob/living/user)
	momentum += amount
	momentum_decay_timer = addtimer(CALLBACK(src, PROC_REF(ResetMomentum)), momentum_decay_time, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)
	UpdateWind(user)

// Clears momentum, the per-hit gain and the tracked target.
/obj/item/ego_weapon/city/wedge/neocity/proc/ResetMomentum()
	momentum = 0
	momentum_gain = initial(momentum_gain)
	momentum_target = null
	deltimer(momentum_decay_timer)
	momentum_decay_timer = null
	if(isliving(loc))
		UpdateWind(loc)

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
	// Refresh first, in case the spear changed hands since the last hit.
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

// Winds up on the user, then dashes through the target and strikes, spending all momentum for extra damage.
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

// Hits the target with force raised by the current momentum and the finisher's sound, then resets momentum.
/obj/item/ego_weapon/city/wedge/neocity/proc/FinisherStrike(mob/living/target, mob/living/user)
	var/base_force = force
	var/bonus_percent = min(momentum * finisher_bonus_per_momentum, finisher_max_bonus)
	force = base_force * (1 + bonus_percent / 100)
	hitsound = 'sound/weapons/fixer/wedge_leader_transpierce.ogg'
	target.attackby(src, user)
	hitsound = initial(hitsound)
	force = base_force
	ResetMomentum()

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

// Shows the wind while the spear has enough momentum and is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/city/wedge/neocity/proc/UpdateWind(mob/living/user)
	var/should_show = (momentum >= wind_momentum && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

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
	special = "Repeated uncharged hits on one target build momentum (+1, +2, +3...). Switching targets or 8 seconds idle resets it. \
		Charging at 6+ momentum starts at high speed, but stops after 4 tiles and spends all momentum."
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
	// Current momentum stacks.
	var/momentum = 0
	// Momentum the next hit on the same target grants. Goes up by 1 with each hit.
	var/momentum_gain = 1
	// The target the current momentum chain is built on.
	var/datum/weakref/momentum_target
	// How long without a hit before momentum resets.
	var/momentum_decay_time = 8 SECONDS
	// Timer that resets momentum once it runs out.
	var/momentum_decay_timer
	// How much momentum is required to activate the wind effect.
	var/wind_momentum = 6
	// Whether the wind effect is currently active.
	var/wind_active = FALSE
	// Starting charge speed when boosted
	var/increased_charge_speed = -1.5
	// Whether the current charge was started with enough momentum.
	var/boosted_charge = FALSE
	// Tiles moved during this boosted charge.
	var/boosted_tiles = 0
	// Most tiles a boosted charge can move before it ends.
	var/max_boosted_tiles = 4

/obj/item/ego_weapon/lance/wedge/dropped(mob/user)
	. = ..()
	ResetMomentum()
	wind_active = FALSE

/obj/item/ego_weapon/lance/wedge/examine(mob/user)
	. = ..()
	. += span_notice("Momentum: [momentum] ([wind_momentum] needed for an empowered charge).")

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
		HitMomentum(target, user)
	else if(boosted_charge)
		ResetMomentum()

/obj/item/ego_weapon/lance/wedge/UserBump(mob/living/carbon/human/user, atom/A)
	if(boosted_charge && ishuman(A))
		ResetMomentum()
	return ..()

// Grants momentum for a hit on target, 1 more than the last hit. A hit on a different target than the last one restarts the chain.
/obj/item/ego_weapon/lance/wedge/proc/HitMomentum(mob/living/target, mob/living/user)
	var/mob/living/last_target = momentum_target?.resolve()
	if(last_target && last_target != target)
		ResetMomentum()
	momentum_target = WEAKREF(target)
	AddMomentum(momentum_gain, user)
	momentum_gain++

// Adds momentum and restarts the decay timer.
/obj/item/ego_weapon/lance/wedge/proc/AddMomentum(amount, mob/living/user)
	momentum += amount
	momentum_decay_timer = addtimer(CALLBACK(src, PROC_REF(ResetMomentum)), momentum_decay_time, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)
	UpdateWind(user)

// Clears momentum, the per-hit gain and the tracked target.
/obj/item/ego_weapon/lance/wedge/proc/ResetMomentum()
	momentum = 0
	momentum_gain = initial(momentum_gain)
	momentum_target = null
	deltimer(momentum_decay_timer)
	momentum_decay_timer = null
	if(isliving(loc))
		UpdateWind(loc)

/obj/item/ego_weapon/lance/wedge/LowerLance(user)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	UpdateWind(living_user)
	if(momentum >= wind_momentum)
		boosted_charge = TRUE
		playsound(living_user, 'sound/weapons/fixer/wedge_charge.ogg', 100, TRUE)
		charge_speed = increased_charge_speed
		living_user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/charge, multiplicative_slowdown = charge_speed)

/obj/item/ego_weapon/lance/wedge/RaiseLance(user)
	. = ..()
	boosted_charge = FALSE
	boosted_tiles = 0

/obj/item/ego_weapon/lance/wedge/UserMoved(mob/user)
	. = ..()
	if(raised || !boosted_charge)
		return
	boosted_tiles++
	if(boosted_tiles < max_boosted_tiles)
		return
	to_chat(user, span_warning("The winds around [src] die down and your charge loses its momentum."))
	ResetMomentum()
	RaiseLance(user)

// Shows the wind while the lance has enough momentum and is in the active hand. Redraws only on a change.
/obj/item/ego_weapon/lance/wedge/proc/UpdateWind(mob/living/user)
	var/should_show = (momentum >= wind_momentum && src == user.get_active_held_item())
	if(should_show == wind_active)
		return
	wind_active = should_show
	user.update_inv_hands()

/obj/item/ego_weapon/lance/wedge/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands || !wind_active)
		return
	. += mutable_appearance(icon_file, "[inhand_icon_state]_wind")
