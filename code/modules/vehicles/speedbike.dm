/obj/vehicle/ridden/speedbike
	name = "Speedbike"
	icon = 'icons/obj/bike.dmi'
	icon_state = "speedbike_blue"
	layer = LYING_MOB_LAYER
	var/overlay_state = "cover_blue"
	var/mutable_appearance/overlay

/obj/vehicle/ridden/speedbike/Initialize()
	. = ..()
	overlay = mutable_appearance(icon, overlay_state, ABOVE_MOB_LAYER)
	add_overlay(overlay)
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/speedbike)

/obj/vehicle/ridden/speedbike/Move(newloc,move_dir)
	if(has_buckled_mobs())
		new /obj/effect/temp_visual/dir_setting/speedbike_trail(loc,move_dir)
	return ..()

/obj/vehicle/ridden/speedbike/red
	icon_state = "speedbike_red"
	overlay_state = "cover_red"

//BM SPEEDWAGON

/obj/vehicle/ridden/speedwagon
	name = "BM Speedwagon"
	desc = "Push it to the limit, walk along the razor's edge."
	icon = 'icons/obj/car.dmi'
	icon_state = "speedwagon"
	layer = LYING_MOB_LAYER
	var/static/mutable_appearance/overlay
	max_buckled_mobs = 4
	max_occupants = 4
	var/crash_all = FALSE //CHAOS
	pixel_y = -48
	pixel_x = -48

/obj/vehicle/ridden/speedwagon/Initialize()
	. = ..()
	overlay = mutable_appearance(icon, "speedwagon_cover", ABOVE_MOB_LAYER)
	add_overlay(overlay)
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/speedwagon)

/obj/vehicle/ridden/speedwagon/Bump(atom/A)
	. = ..()
	if(!A.density || !has_buckled_mobs())
		return

	var/atom/throw_target = get_edge_target_turf(A, dir)
	if(crash_all)
		if(ismovable(A))
			var/atom/movable/AM = A
			AM.throw_at(throw_target, 4, 3)
		visible_message("<span class='danger'>[src] crashes into [A]!</span>")
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		H.Paralyze(100)
		H.adjustStaminaLoss(30)
		H.deal_damage(rand(20,35), BRUTE, attack_type = (ATTACK_TYPE_MELEE))
		if(!crash_all)
			H.throw_at(throw_target, 4, 3)
			visible_message("<span class='danger'>[src] crashes into [H]!</span>")
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)

/obj/vehicle/ridden/speedwagon/Moved()
	. = ..()
	if(!has_buckled_mobs())
		return
	for(var/atom/A in range(2, src))
		if(!(A in buckled_mobs))
			Bump(A)

// MIDDLE NURSEFATHER SPEEDWAGON
/obj/vehicle/ridden/speedwagon/middle
	name = "the Middle's ride"
	desc = "A vehicle claimed by the Middle. Seats four — perfect for a family outing with your siblings."
	icon_state = "middle_car"
	key_type = /obj/item/key/middle_car
	COOLDOWN_DECLARE(bump_cooldown)

/obj/vehicle/ridden/speedwagon/middle/Initialize()
	. = ..()
	cut_overlays()
	overlay = mutable_appearance(icon, "middle_car_cover", ABOVE_MOB_LAYER)
	add_overlay(overlay)
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/speedwagon)

/obj/vehicle/ridden/speedwagon/middle/Move(newloc, move_dir)
	if(!isturf(newloc))
		return ..()
	if(!check_corridor_width(newloc, move_dir))
		return FALSE
	return ..()

/// Returns TRUE if the corridor at the target turf is wide enough perpendicular to the movement direction
/obj/vehicle/ridden/speedwagon/middle/proc/check_corridor_width(turf/T, move_dir)
	var/perp1
	var/perp2
	if(move_dir & (NORTH|SOUTH))
		perp1 = EAST
		perp2 = WEST
	else if(move_dir & (EAST|WEST))
		perp1 = NORTH
		perp2 = SOUTH
	else
		return TRUE
	var/turf/side1 = get_step(T, perp1)
	var/turf/side2 = get_step(T, perp2)
	if(!side1 || side1.density || !side2 || side2.density)
		return FALSE
	return TRUE

/// Returns TRUE if the turf and its neighbors have enough clearance for the 3x3 car
/obj/vehicle/ridden/speedwagon/middle/proc/check_turf_clearance(turf/T)
	for(var/dir in GLOB.cardinals)
		var/turf/neighbor = get_step(T, dir)
		if(!neighbor || neighbor.density)
			return FALSE
	return TRUE

/obj/vehicle/ridden/speedwagon/middle/Bump(atom/A)
	if(!A.density || !has_buckled_mobs())
		return
	if(!COOLDOWN_FINISHED(src, bump_cooldown))
		return
	if(isliving(A))
		var/mob/living/L = A
		var/atom/throw_target = get_edge_target_turf(L, dir)
		L.throw_at(throw_target, 3, 2)
		visible_message("<span class='danger'>[src] shoves [L] out of the way!</span>")
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		COOLDOWN_START(src, bump_cooldown, 3 SECONDS)
		movedelay = 6
		addtimer(CALLBACK(src, PROC_REF(reset_speed)), 2 SECONDS)

/obj/vehicle/ridden/speedwagon/middle/proc/reset_speed()
	movedelay = 2

/obj/vehicle/ridden/speedwagon/middle/attackby(obj/item/I, mob/user, params)
	if(is_key(I))
		return ..()
	if(I.force > 0)
		visible_message("<span class='danger'>[user] strikes [src] with [I], ejecting all passengers!</span>")
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		unbuckle_all_mobs(force = TRUE)
		return
	return ..()

/obj/vehicle/ridden/speedwagon/middle/can_be_pulled(user, grab_state, force)
	return FALSE

// MIDDLE CAR SUMMONING PHONE
/obj/item/middle_car_phone
	name = "suspicious phone"
	desc = "This device raises purple levels to unknown highs."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "suspiciousphone"
	color = "#9b30ff"
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("dumps")
	attack_verb_simple = list("dump")
	/// The car linked to this phone
	var/obj/vehicle/ridden/speedwagon/middle/car
	/// Total ahn withdrawn via favors this round
	var/total_favors_withdrawn = 0
	COOLDOWN_DECLARE(phone_cooldown)
	COOLDOWN_DECLARE(favor_cooldown)

/obj/item/middle_car_phone/attack_self(mob/living/user)
	var/choice = tgui_alert(user, "What do you need?", "Car Phone", list("Call Car", "Call in a Favor"))
	if(!choice || QDELETED(src) || QDELETED(user) || !user.is_holding(src))
		return
	if(choice == "Call in a Favor")
		call_favor(user)
		return
	if(!COOLDOWN_FINISHED(src, phone_cooldown))
		to_chat(user, span_warning("The phone is still on cooldown."))
		return
	var/turf/T = get_turf(user)
	if(!T)
		return
	var/obj/vehicle/ridden/speedwagon/middle/temp_car = car
	if(!temp_car)
		temp_car = new(T)
	if(!temp_car.check_turf_clearance(T))
		to_chat(user, span_warning("There isn't enough space to summon the car here."))
		if(!car)
			qdel(temp_car)
		return
	to_chat(user, span_notice("You dial the number..."))
	playsound(T, 'sound/machines/twobeep_high.ogg', 50, TRUE)
	COOLDOWN_START(src, phone_cooldown, 30 SECONDS)
	if(!car || QDELETED(car))
		car = temp_car
		car.forceMove(T)
		var/obj/item/key/middle_car/K = new(car)
		car.inserted_key = K
		var/obj/item/key/middle_car/spare = new(T)
		user.put_in_hands(spare)
		to_chat(user, span_notice("You pocket the spare key."))
	else
		if(car.has_buckled_mobs())
			car.unbuckle_all_mobs(force = TRUE)
		car.forceMove(T)
	car.alpha = 0
	car.pixel_x = car.base_pixel_x - 96
	playsound(T, 'sound/effects/bang.ogg', 50, TRUE)
	animate(car, pixel_x = car.base_pixel_x, alpha = 255, time = 0.5 SECONDS, easing = QUAD_EASING)
	addtimer(CALLBACK(src, PROC_REF(car_arrival), T), 0.5 SECONDS)

/obj/item/middle_car_phone/proc/car_arrival(turf/T)
	if(QDELETED(car))
		return
	playsound(T, 'sound/effects/bang.ogg', 70, TRUE)
	to_chat(get_hearers_in_view(7, T), span_danger("The Middle's ride screeches to a halt!"))
	for(var/mob/living/L in range(1, T))
		if(car.is_occupant(L))
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(get_attribute_level(H, FORTITUDE_ATTRIBUTE) >= 200)
				continue
		var/atom/throw_target = get_edge_target_turf(L, get_dir(T, L))
		L.throw_at(throw_target, 3, 2)
		visible_message("<span class='danger'>[L] is knocked back by [car]'s arrival!</span>")

/// Call in a favor — request ahn from siblings via the phone.
/obj/item/middle_car_phone/proc/call_favor(mob/living/user)
	if(!COOLDOWN_FINISHED(src, favor_cooldown))
		var/time_left = DisplayTimeText(COOLDOWN_TIMELEFT(src, favor_cooldown))
		to_chat(user, span_warning("Your contact isn't picking up. Try again in [time_left]."))
		return
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		to_chat(user, span_warning("You don't have a bank account to wire to."))
		return
	var/amount = input(user, "How much ahn do you need wired? (1-1500)", "Call in a Favor") as null|num
	if(isnull(amount) || QDELETED(src) || QDELETED(user) || !user.is_holding(src))
		return
	amount = clamp(round(amount), 1, 1500)
	if(amount <= 0)
		return
	to_chat(user, span_notice("You dial a number..."))
	playsound(user, 'sound/machines/twobeep_high.ogg', 30, TRUE)
	if(!do_after(user, 20, src))
		return
	var/list/flavor_lines = list(
		"Hey, it's me. Wire me something, yeah? ...Good lookin' out.",
		"Brother, I need a favor. The usual. ...You're the best.",
		"Listen, I'm throwin' a little get-together. Need some funds. ...Appreciate it.",
		"It's your favorite sibling. Cash me out, I'll owe you one. ...Heh, another one.",
		"I need ahn. Don't ask. ...Thanks, you're a real one.",
	)
	to_chat(user, span_notice("\"[pick(flavor_lines)]\""))
	COOLDOWN_START(src, favor_cooldown, 2 MINUTES)
	total_favors_withdrawn += amount
	if(total_favors_withdrawn > 8000)
		to_chat(user, span_warning("Your contact sounds hesitant. \"You're racking up quite a tab, brother...\""))
		message_admins("[ADMIN_LOOKUPFLW(user)] (Middle Nursefather) has called in [total_favors_withdrawn] ahn in favors this round.")
	addtimer(CALLBACK(src, PROC_REF(favor_arrival), user, account, amount), rand(3 SECONDS, 5 SECONDS))

/// Deposit the favor ahn into the user's bank account.
/obj/item/middle_car_phone/proc/favor_arrival(mob/living/user, datum/bank_account/account, amount)
	if(QDELETED(user) || QDELETED(account))
		return
	account.adjust_money(amount)
	if(!QDELETED(user))
		to_chat(user, span_notice("Your phone buzzes. [amount] ahn has been wired to your account."))
