// The qliphoth deterrence lasso. Five seconds of standing still - or two and a half times that at
// range - buys a tether that halves what a specimen can do and stops it tripping the corridor
// lights, for as long as whoever holds the other end stays close and in line of sight.
//
// The loose-specimen alarm it suppresses is split across the two files that own the types it
// touches: the area counter and the light switching are in lce_areas.dm, and the specimen's side
// of it - trips_alarm, counted_area, RefreshAlarmPresence() - is in lcl_abno.dm.

/*			THE LASSO			*/

/obj/item/qliphoth_lasso
	name = "qliphoth deterrence lasso"
	desc = "A grounded catch pole. The standing loop on the end is humming cable on a sprung \
		collar - worked over a specimen that will hold still for it, it takes the weight out of \
		them, for as long as you stay near and in sight."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_lasso.dmi'
	icon_state = "lasso"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	inhand_icon_state = "chain"
	w_class = WEIGHT_CLASS_NORMAL
	///The specimen on the other end.
	var/mob/living/simple_animal/hostile/limbus_abno/tethered
	var/datum/beam/tether
	var/obj/effect/lce_lasso_glow/glow
	///How long it takes to work around a specimen, who has to hold still for all of it.
	var/attach_time = 3 SECONDS
	///Multiplier on that when the line is cast from range instead of worked on by hand.
	var/ranged_time_mult = 2.5
	///The half-drawn line of a cast in progress, and the flag that stops a second one starting.
	var/datum/beam/casting_beam
	var/connecting = FALSE
	var/tension = 0
	var/max_tension = 100
	///Within this many tiles the tension bleeds off instead of building.
	var/safe_range = 4
	///Tension aside, the cable is only so long - at this range it tears loose outright.
	var/break_range = 8
	var/tension_per_tile = 6
	var/tension_blocked = 14
	var/tension_decay = 9
	///Half the flicker cycle; the pair of animate() calls loops as twice this.
	var/flicker_time = 2 SECONDS
	var/flicker_alpha = 255
	//What we set the specimen's numbers to. On release we only undo values that still match
	//these - if something else has moved them since, they are not ours to put back.
	var/applied_lower
	var/applied_upper
	var/applied_obj

/obj/item/qliphoth_lasso/Destroy()
	Release(silent = TRUE)
	QDEL_NULL(casting_beam)
	return ..()

/obj/item/qliphoth_lasso/examine(mob/user)
	. = ..()
	if(!tethered)
		. += span_notice("Unattached. Use it on a specimen that is holding still.")
		. += span_notice("It can be cast at one from up to [break_range - 1] tiles off, but takes \
			[ranged_time_mult] times as long to close, and neither of you can move while it does.")
		return
	. += span_notice("Tethered to [tethered].")
	. += span_notice("Tension: [round(tension)]%. Distance and closed doors both raise it.")
	. += span_warning("Past [break_range] tiles it tears loose outright.")

///Shared gate for both ways of getting the loop on: by hand and cast from range.
/obj/item/qliphoth_lasso/proc/CanLasso(mob/living/simple_animal/hostile/limbus_abno/target, mob/user)
	if(tethered)
		to_chat(user, span_warning("[src] is already tethered to [tethered]."))
		return FALSE
	if(connecting)
		to_chat(user, span_warning("[src] is already out, and still closing."))
		return FALSE
	if(target.stat >= DEAD)
		to_chat(user, span_warning("There is nothing left in [target] to deter."))
		return FALSE
	for(var/obj/item/qliphoth_lasso/other in GLOB.lce_active_lassos)
		if(other.tethered == target)
			to_chat(user, span_warning("[target] is already wearing a lasso."))
			return FALSE
	return TRUE

/obj/item/qliphoth_lasso/attack(mob/living/M, mob/living/user)
	if(!istype(M, /mob/living/simple_animal/hostile/limbus_abno))
		return ..()
	var/mob/living/simple_animal/hostile/limbus_abno/target = M
	if(!CanLasso(target, user))
		return
	user.visible_message(span_warning("[user] begins working [src] around [target]..."), \
		span_notice("You begin working [src] around [target]. They have to stay still."))
	//The specimen is the do_after target, so the engine aborts this the instant they move.
	if(!do_after(user, attach_time, target))
		to_chat(user, span_warning("[target] moved before you could close the loop."))
		return
	Attach(target, user)

//Cast from across the room instead. Same loop, but thrown and worked closed at a distance, so it
//takes ranged_time_mult times as long and wants a clear line the whole way.
/obj/item/qliphoth_lasso/afterattack(atom/target, mob/user, proximity_flag, params)
	. = ..()
	if(proximity_flag)   //Arm's reach is attack()'s business.
		return
	if(!istype(target, /mob/living/simple_animal/hostile/limbus_abno))
		return
	var/mob/living/simple_animal/hostile/limbus_abno/specimen = target
	if(!CanLasso(specimen, user))
		return
	if(get_dist(user, specimen) >= break_range)
		to_chat(user, span_warning("[specimen] is further off than the cable is long."))
		return
	if(!can_see(user, specimen, break_range))
		to_chat(user, span_warning("You need a clear line to [specimen]."))
		return
	var/cast_time = attach_time * ranged_time_mult
	user.visible_message(span_warning("[user] casts [src] out towards [specimen]..."), \
		span_notice("You cast [src] out towards [specimen]. Neither of you can move now."))
	connecting = TRUE
	//The line is not a tether yet, so it fades in over the cast rather than snapping on whole.
	casting_beam = user.Beam(specimen, "beam", 'icons/effects/beam.dmi', INFINITY, INFINITY)
	if(casting_beam.visuals)
		casting_beam.visuals.color = TensionColour()
		casting_beam.visuals.alpha = 0
		animate(casting_beam.visuals, alpha = 255, time = cast_time)
	var/landed = do_after(user, cast_time, specimen)
	connecting = FALSE
	//Gone either way: on a miss the half-drawn line vanishes, on a hit Attach() draws the real one.
	QDEL_NULL(casting_beam)
	if(!landed)
		to_chat(user, span_warning("The line goes slack before it can close around [specimen]."))
		return
	Attach(specimen, user)

/obj/item/qliphoth_lasso/proc/Attach(mob/living/simple_animal/hostile/limbus_abno/target, mob/user)
	if(tethered || QDELETED(target))
		return FALSE
	tethered = target
	tension = 0
	GLOB.lce_active_lassos += src

	//Blunted, not disarmed. Recorded so Release can tell our changes from anybody else's.
	applied_obj = 0
	applied_lower = round(target.melee_damage_lower * 0.5)
	applied_upper = round(target.melee_damage_upper * 0.5)
	target.obj_damage = applied_obj
	target.melee_damage_lower = applied_lower
	target.melee_damage_upper = applied_upper

	target.trips_alarm = FALSE
	target.RefreshAlarmPresence()

	icon_state = "lasso_live"
	StartVisuals()
	START_PROCESSING(SSobj, src)
	target.visible_message(span_boldwarning("The lasso closes around [target], and the air goes quiet."))
	to_chat(target, span_userdanger("Something earths you. You feel dulled, and lighter, and held."))
	playsound(src, 'sound/effects/sparks2.ogg', 50, TRUE)
	return TRUE

///Whoever is carrying the spool, however deep in their bags it is - and the spool itself when
///nobody is. The beam hangs off this rather than off the item, because an item sitting in a
///backpack never Moves when its owner walks, so a beam rooted in it would stay where they
///picked it up.
/obj/item/qliphoth_lasso/proc/BeamOrigin()
	var/mob/holder = get(src, /mob)
	return holder || src

/obj/item/qliphoth_lasso/proc/RefreshBeam()
	if(QDELETED(tethered))
		return
	var/atom/origin = BeamOrigin()
	if(tether && !QDELETED(tether.origin) && tether.origin == origin)
		return
	//A beam's origin is fixed at creation, so changing hands means a new one.
	QDEL_NULL(tether)
	tether = origin.Beam(tethered, "beam", 'icons/effects/beam.dmi', INFINITY, INFINITY)
	UpdateTensionColour()

//Picking the lasso up, bagging it and dropping it all move it, so this covers every way it can
//change hands.
/obj/item/qliphoth_lasso/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	RefreshBeam()

/obj/item/qliphoth_lasso/proc/StartVisuals()
	if(QDELETED(tethered))
		return
	RefreshBeam()
	glow = new(tethered)
	//render_source shows a copy of the specimen, which `color` then tints - so the flicker is
	//clipped to their sprite by construction rather than by a mask that has to be kept in step.
	glow.render_source = tethered.ClaimRenderTarget()
	tethered.vis_contents += glow
	glow.alpha = 0
	//A fade each way, looping - so the visible cycle is twice flicker_time.
	animate(glow, alpha = flicker_alpha, time = flicker_time, loop = -1)
	animate(alpha = 0, time = flicker_time)
	UpdateTensionColour()

///Light blue at rest, through blue, to red at breaking point. BlendRGB is the engine helper in
///code/__HELPERS/icons.dm - no need for our own.
/obj/item/qliphoth_lasso/proc/TensionColour()
	var/frac = clamp(tension / max_tension, 0, 1)
	if(frac < 0.5)
		return BlendRGB("#8fdcff", "#2b6bff", frac * 2)
	return BlendRGB("#2b6bff", "#ff3b3b", (frac - 0.5) * 2)

/obj/item/qliphoth_lasso/proc/UpdateTensionColour()
	var/tint = TensionColour()
	if(glow)
		glow.color = tint
		//An outline in the same colour on top of the wash, so a tethered specimen still reads as
		//one down a corridor where the tint alone would wash out against their own sprite.
		//Re-adding under the same name replaces it - add_filter rebuilds from filter_data.
		glow.add_filter("lasso_outline", 1, list("type" = "outline", "size" = 1, "color" = tint))
	if(tether?.visuals)
		tether.visuals.color = tint

/obj/item/qliphoth_lasso/process(delta_time)
	if(QDELETED(tethered) || tethered.stat >= DEAD)
		Release()
		return
	var/turf/mine = get_turf(src)
	var/turf/theirs = get_turf(tethered)
	if(!mine || !theirs || mine.z != theirs.z)
		Release()
		return
	//Backstop for a holder that stopped being one without the item moving - gibbed, say.
	RefreshBeam()

	var/dist = get_dist(mine, theirs)
	//Hard limit. Past this the cable is simply out of length, whatever the tension says.
	if(dist >= break_range)
		Snap()
		return
	var/sighted = can_see(src, tethered, 9)
	if(!sighted)
		//A closed door or a wall between the two ends is the same as being pulled taut.
		tension += tension_blocked
	else if(dist > safe_range)
		tension += (dist - safe_range) * tension_per_tile
	else
		tension -= tension_decay
	tension = clamp(tension, 0, max_tension)
	UpdateTensionColour()

	if(tension >= max_tension)
		Snap()

/obj/item/qliphoth_lasso/proc/Snap()
	var/mob/living/simple_animal/hostile/limbus_abno/freed = tethered
	if(freed)
		freed.visible_message(span_boldwarning("The lasso on [freed] snaps taut and tears loose!"))
		playsound(freed, 'sound/effects/snap.ogg', 70, TRUE)
	Release()

/obj/item/qliphoth_lasso/proc/Release(silent = FALSE)
	STOP_PROCESSING(SSobj, src)
	GLOB.lce_active_lassos -= src
	if(tether)
		QDEL_NULL(tether)
	var/mob/living/simple_animal/hostile/limbus_abno/freed = tethered
	tethered = null
	if(glow)
		if(!QDELETED(freed))
			freed.vis_contents -= glow
			freed.ReleaseRenderTarget()
		QDEL_NULL(glow)
	tension = 0
	icon_state = initial(icon_state)
	if(QDELETED(freed))
		return
	//Back to the values on the type, not the values it happened to have when the lasso went on -
	//and only where our own number is still sitting there. If the specimen enraged mid-tether and
	//rewrote its own damage, that is its business and we leave it alone.
	if(freed.obj_damage == applied_obj)
		freed.obj_damage = initial(freed.obj_damage)
	if(freed.melee_damage_lower == applied_lower)
		freed.melee_damage_lower = initial(freed.melee_damage_lower)
	if(freed.melee_damage_upper == applied_upper)
		freed.melee_damage_upper = initial(freed.melee_damage_upper)
	freed.trips_alarm = TRUE
	freed.RefreshAlarmPresence()
	if(!silent)
		to_chat(freed, span_nicegreen("The weight comes back. You are yourself again."))

//Not by the thing wearing it. A specimen cannot pick its own lasso up...
/obj/item/qliphoth_lasso/attack_hand(mob/user)
	if(user == tethered)
		to_chat(user, span_warning("Your hands will not close on it. It is earthed to you."))
		return
	return ..()

//...nor drag it around after itself.
/obj/item/qliphoth_lasso/can_be_pulled(user, grab_state, force)
	if(user == tethered)
		return FALSE
	return ..()

/obj/effect/lce_lasso_glow
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	plane = FLOAT_PLANE
	layer = FLOAT_LAYER
	appearance_flags = KEEP_TOGETHER
	anchored = TRUE

GLOBAL_LIST_EMPTY(lce_active_lassos)
