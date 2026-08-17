// City doors.
//
// These sit on /obj/machinery/door rather than on /obj/machinery/door/airlock,
// because all the City wants is the part everyone actually uses: walk into it,
// it checks your ID, it opens, it shuts again a few seconds later. The airlock
// subtype brings wires, bolts, electronics, painting and hacking with it, none
// of which the City has any use for.
//
// The one real addition is what happens when a door dies. Instead of being
// destroyed it drops to its broken sprite: the panel is gone, so it is no
// longer dense and no longer blocks sight, it cannot be opened or closed, and
// it cannot be damaged any further. It stays on the map as a hole in the wall
// until somebody feeds it sheets, which is a lot more useful to a round than a
// doorway that has silently become open floor.

/obj/machinery/door/city
	name = "door"
	desc = "A powered door on a card reader."
	icon = 'ModularLobotomy/_Lobotomyicons/city_doors.dmi'
	icon_state = "door-1"
	pixel_x = -16
	pixel_y = -8
	opacity = TRUE
	density = TRUE
	smoothing_groups = list(SMOOTH_GROUP_AIRLOCK)
	max_integrity = 300
	autoclose = TRUE
	glass = FALSE
	/// Sprite stem. States are "[base_state]-1" shut, "-0" open, "-b" wrecked.
	var/base_state = "door"
	/// Wrecked doors keep existing: no density, no opacity, no operating.
	var/broken = FALSE
	/// What it takes to put one back together.
	var/repair_material = /obj/item/stack/sheet/metal
	var/repair_amount = 5
	var/repair_time = 100
	/// Used when a repaired door starts shutting itself again.
	var/close_delay = 60
	/// Set while the refusal jitter is playing, so leaning on a door you
	/// cannot open rattles it once rather than every time you touch it.
	var/denying = FALSE

/obj/machinery/door/city/update_icon_state()
	if(broken)
		icon_state = "[base_state]-b"
	else
		icon_state = "[base_state]-[density ? 1 : 0]"

/// The sheet has no travel frames, so the animation hook is used for the audio
/// instead. It fires after open() and close() have decided they can proceed,
/// which is exactly where the sound belongs.
/obj/machinery/door/city/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src, 'sound/machines/door_open.ogg', 50, TRUE)
		if("closing")
			playsound(src, 'sound/machines/door_close.ogg', 50, TRUE)
		if("deny")
			if(!machine_stat)
				refuse()

/// Half a second of rattle when your card does not open it. Shake() restores
/// the base offsets itself, so this does not disturb the door's pixel_x.
/obj/machinery/door/city/proc/refuse()
	if(denying || broken)
		return
	denying = TRUE
	playsound(src, 'sound/machines/doorclick.ogg', 50, FALSE)
	Shake(2, 1, 25)
	addtimer(CALLBACK(src, PROC_REF(stop_refusing)), 5)

/obj/machinery/door/city/proc/stop_refusing()
	denying = FALSE

// open() and close() are rewritten rather than chained, because the parent
// sleeps five ticks between starting to move and another five before it
// updates the sprite. That gap exists to let an airlock's travel frames play.
// This sheet has no travel frames, so the gap just reads as the door being
// passable while it still looks shut. Here the sprite, the density and the
// opacity all change on the same line.

/obj/machinery/door/city/open()
	if(broken)
		return FALSE
	if(!density)
		return TRUE
	if(operating)
		return
	operating = TRUE
	do_animate("opening")
	density = FALSE
	set_opacity(FALSE)
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	layer = initial(layer)
	update_icon()
	operating = FALSE
	update_freelook_sight()
	if(autoclose)
		autoclose_in(close_delay)
	return TRUE

/obj/machinery/door/city/close()
	if(broken)
		return FALSE
	if(density)
		return TRUE
	if(operating || welded)
		return
	if(safe)
		for(var/atom/movable/blocker in get_turf(src))
			if(blocker.density && blocker != src)
				if(autoclose)
					autoclose_in(close_delay)
				return
	operating = TRUE
	do_animate("closing")
	layer = closingLayer
	density = TRUE
	flags_1 |= PREVENT_CLICK_UNDER_1
	if(visible && !glass)
		set_opacity(TRUE)
	update_icon()
	operating = FALSE
	update_freelook_sight()
	if(!can_crush)
		return TRUE
	if(safe)
		CheckForMobs()
	else
		crush()
	return TRUE

/obj/machinery/door/city/examine(mob/user)
	. = ..()
	if(!broken)
		return
	var/obj/item/stack/sheet/needed = repair_material
	. += span_warning("The leaf has been torn out of the frame. Fitting a \
		new one would take [repair_amount] sheets of [initial(needed.name)].")

// ------------------------------------------------------------- wrecking

/obj/machinery/door/city/obj_destruction(damage_flag)
	if(broken)
		return
	wreck()

/// Torn off its runners rather than deleted. Left passable and indestructible.
/obj/machinery/door/city/proc/wreck()
	broken = TRUE
	density = FALSE
	set_opacity(FALSE)
	operating = FALSE
	layer = initial(layer)
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	obj_integrity = max_integrity
	resistance_flags |= INDESTRUCTIBLE
	update_icon()
	update_freelook_sight()
	playsound(src, 'sound/effects/bang.ogg', 60, TRUE)
	visible_message(span_danger("[src] is torn out of its frame!"))

// -------------------------------------------------------------- repair

/obj/machinery/door/city/attackby(obj/item/I, mob/user, params)
	if(broken)
		return try_repair(I, user)
	return ..()

/obj/machinery/door/city/proc/try_repair(obj/item/I, mob/user)
	var/obj/item/stack/sheet/needed = repair_material
	if(!istype(I, repair_material))
		to_chat(user, span_warning("[src] needs [repair_amount] sheets of \
			[initial(needed.name)] before it will hang again."))
		return
	var/obj/item/stack/sheets = I
	if(sheets.get_amount() < repair_amount)
		to_chat(user, span_warning("You need [repair_amount] sheets of \
			[initial(needed.name)] to hang a new leaf."))
		return
	user.visible_message(span_notice("[user] starts fitting a new leaf into \
		[src]."), span_notice("You start fitting a new leaf into [src]."))
	playsound(src, 'sound/machines/door_close.ogg', 30, TRUE)
	if(!do_after(user, repair_time, target = src))
		return
	if(!broken || !sheets.use(repair_amount))
		return
	restore()
	user.visible_message(span_notice("[user] fits a new leaf into [src]."),
		span_notice("You fit a new leaf into [src]."))

/// Comes back open, so nobody standing in the doorway gets shut into a wall.
/// The usual autoclose then takes it from there.
/obj/machinery/door/city/proc/restore()
	broken = FALSE
	resistance_flags &= ~INDESTRUCTIBLE
	obj_integrity = max_integrity
	density = FALSE
	set_opacity(FALSE)
	update_icon()
	update_freelook_sight()
	if(autoclose)
		autoclose_in(close_delay)

// -------------------------------------------------------------- styles

/obj/machinery/door/city/clinic
	name = "clinic door"
	desc = "A clinic door, painted in the colours every medical wing in the \
		City uses."
	icon_state = "clinic-1"
	base_state = "clinic"

/obj/machinery/door/city/clinic/glass
	name = "clinic door"
	desc = "A glazed clinic door. You can see the corridor beyond it."
	icon_state = "clinic_glass-1"
	base_state = "clinic_glass"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/city/old
	name = "weathered door"
	desc = "A steel door that has been painted over more times than it has \
		been serviced."
	icon_state = "old-1"
	base_state = "old"

/obj/machinery/door/city/reinf
	name = "reinforced door"
	desc = "A heavy plated door. It sits badly in its frame."
	icon_state = "reinf-1"
	base_state = "reinf"
	max_integrity = 500
	repair_material = /obj/item/stack/sheet/plasteel

/obj/machinery/door/city/prison
	name = "barred door"
	desc = "A barred gate. Whatever it was built to hold, it is not holding \
		it now."
	icon_state = "prison-1"
	base_state = "prison"
	opacity = FALSE
	glass = TRUE
	max_integrity = 450
	repair_material = /obj/item/stack/sheet/plasteel

/obj/machinery/door/city/wood
	name = "wooden door"
	desc = "A panelled wooden door. The lock is newer than the rest of it."
	icon_state = "wood-1"
	base_state = "wood"
	max_integrity = 180
	repair_material = /obj/item/stack/sheet/mineral/wood

/obj/machinery/door/city/wood/old
	name = "old wooden door"
	desc = "A wooden door gone soft at the bottom rail."
	icon_state = "oldwood-1"
	base_state = "oldwood"
	max_integrity = 140

/obj/machinery/door/city/glass
	name = "glass door"
	desc = "A shop door, mostly glass in a thin frame."
	icon_state = "glass-1"
	base_state = "glass"
	opacity = FALSE
	glass = TRUE
	max_integrity = 150
	repair_material = /obj/item/stack/sheet/glass

/obj/machinery/door/city/glass/blue
	name = "glass door"
	desc = "A shop door in a painted frame."
	icon_state = "glass_blue-1"
	base_state = "glass_blue"

/obj/machinery/door/city/cam
	name = "service door"
	desc = "A flat service door with no handle on this side."
	icon_state = "cam-1"
	base_state = "cam"
