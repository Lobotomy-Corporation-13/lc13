// Corridor Entrance - a door whose twin (matched by string corridor_id) is conceptually the same door.
// Open one, the other opens. Walk through, you're teleported to the other side.
// While open, a "showcase" reveals the destination tile through the doorway.
// Always opaque to lighting (the door tile blocks light propagation even when open).

GLOBAL_LIST_EMPTY(corridor_entrances)

/obj/structure/corridor_entrance
	name = "corridor entrance"
	desc = "A heavy door etched with strange sigils. Its twin lies somewhere else."
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "metal"
	density = TRUE
	anchored = TRUE
	opacity = TRUE
	layer = CLOSED_DOOR_LAYER
	max_integrity = 1000
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)

	var/corridor_id = ""
	var/obj/structure/corridor_entrance/linked
	var/door_opened = FALSE
	var/isSwitchingStates = FALSE
	var/openSound = 'sound/effects/stonedoor_openclose.ogg'
	var/closeSound = 'sound/effects/stonedoor_openclose.ogg'
	var/open_anim_time = 10
	var/close_anim_time = 10
	var/obj/effect/corridor_showcase/showcase

/obj/structure/corridor_entrance/Initialize(mapload)
	. = ..()
	GLOB.corridor_entrances += src

/obj/structure/corridor_entrance/Destroy()
	GLOB.corridor_entrances -= src
	if(linked && !QDELETED(linked))
		linked.linked = null
		if(linked.door_opened)
			linked.force_close()
	linked = null
	QDEL_NULL(showcase)
	return ..()

/obj/structure/corridor_entrance/proc/find_linked()
	if(linked && !QDELETED(linked))
		return linked
	linked = null
	if(!corridor_id)
		return null
	for(var/obj/structure/corridor_entrance/C in GLOB.corridor_entrances - src)
		if(QDELETED(C))
			continue
		if(C.corridor_id == corridor_id)
			linked = C
			C.linked = src
			return linked
	return null

/obj/structure/corridor_entrance/Bumped(atom/movable/AM)
	..()
	if(!door_opened)
		return TryToSwitchState(AM)

/obj/structure/corridor_entrance/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(isSwitchingStates || !anchored)
		return
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(C.handcuffed)
			return
	SwitchState(user)

/obj/structure/corridor_entrance/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/corridor_entrance/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /obj/effect/beam))
		return !opacity

/obj/structure/corridor_entrance/proc/TryToSwitchState(atom/user)
	if(isSwitchingStates || !anchored)
		return
	if(isliving(user))
		var/mob/living/M = user
		if(world.time - M.last_bumped <= 60)
			return
		if(M.client)
			if(iscarbon(M))
				var/mob/living/carbon/C = M
				if(!C.handcuffed)
					SwitchState(user)
			else
				SwitchState(user)
	else if(ismecha(user))
		SwitchState(user)

/obj/structure/corridor_entrance/proc/SwitchState(mob/user)
	if(door_opened)
		Close()
	else
		Open(user)

/obj/structure/corridor_entrance/proc/Open(mob/user, propagated = FALSE)
	if(isSwitchingStates || door_opened)
		return FALSE
	var/obj/structure/corridor_entrance/twin = find_linked()
	if(!twin)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		if(user)
			user.balloon_alert(user, "no linked corridor")
		return FALSE
	isSwitchingStates = TRUE
	if(!propagated)
		INVOKE_ASYNC(twin, PROC_REF(Open), user, TRUE)
	create_showcase()
	playsound(src, openSound, 100, TRUE)
	flick("[initial(icon_state)]opening", src)
	sleep(open_anim_time)
	if(QDELETED(src))
		QDEL_NULL(showcase)
		return FALSE
	density = FALSE
	door_opened = TRUE
	layer = OPEN_DOOR_LAYER
	update_icon()
	isSwitchingStates = FALSE
	return TRUE

/obj/structure/corridor_entrance/proc/Close(propagated = FALSE)
	if(isSwitchingStates || !door_opened)
		return FALSE
	for(var/mob/living/L in get_turf(src))
		return FALSE
	var/obj/structure/corridor_entrance/twin = find_linked()
	if(twin && !propagated)
		if(twin.isSwitchingStates || !twin.door_opened)
			return FALSE
		for(var/mob/living/L in get_turf(twin))
			return FALSE
	isSwitchingStates = TRUE
	if(twin && !propagated)
		INVOKE_ASYNC(twin, PROC_REF(Close), TRUE)
	QDEL_NULL(showcase)
	playsound(src, closeSound, 100, TRUE)
	flick("[initial(icon_state)]closing", src)
	sleep(close_anim_time)
	if(QDELETED(src))
		return FALSE
	density = TRUE
	door_opened = FALSE
	layer = initial(layer)
	update_icon()
	isSwitchingStates = FALSE
	return TRUE

/obj/structure/corridor_entrance/proc/force_close()
	density = TRUE
	door_opened = FALSE
	layer = initial(layer)
	QDEL_NULL(showcase)
	update_icon()
	isSwitchingStates = FALSE

/obj/structure/corridor_entrance/Crossed(atom/movable/AM, oldloc, force_stop = 0)
	. = ..()
	if(!door_opened || force_stop || isobserver(AM))
		return
	var/obj/structure/corridor_entrance/twin = find_linked()
	if(!twin || QDELETED(twin))
		return
	if(get_turf(oldloc) == get_turf(twin))
		return
	do_teleport(AM, get_turf(twin), 0, channel = TELEPORT_CHANNEL_BLUESPACE, no_effects = TRUE)

/obj/structure/corridor_entrance/update_icon_state()
	icon_state = "[initial(icon_state)][door_opened ? "open" : ""]"

/obj/structure/corridor_entrance/proc/create_showcase()
	var/obj/structure/corridor_entrance/twin = find_linked()
	if(!twin)
		return
	showcase = new /obj/effect/corridor_showcase(null)
	showcase.setup_visuals(twin, src)

#define CORRIDOR_VIEW_DEPTH 5
#define CORRIDOR_VIEW_HALF_WIDTH 1

/obj/effect/corridor_showcase
	name = "corridor view"
	icon = null
	icon_state = ""
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/obj/structure/corridor_entrance/our_target
	var/obj/structure/corridor_entrance/our_door
	var/list/tiles = list()

/obj/effect/corridor_showcase/proc/setup_visuals(obj/structure/corridor_entrance/target, obj/structure/corridor_entrance/local_door)
	our_target = target
	our_door = local_door
	if(!target || !local_door)
		return
	var/turf/local_origin = get_turf(local_door)
	var/turf/target_origin = get_turf(target)
	if(!local_origin || !target_origin)
		return

	var/local_view = turn(local_door.dir, 180)
	var/target_view = target.dir
	var/list/lf = dir_offset(local_view)
	var/list/lr = dir_offset(turn(local_view, -90))
	var/list/tf = dir_offset(target_view)
	var/list/tr = dir_offset(turn(target_view, -90))

	for(var/d in 0 to CORRIDOR_VIEW_DEPTH - 1)
		for(var/w in -CORRIDOR_VIEW_HALF_WIDTH to CORRIDOR_VIEW_HALF_WIDTH)
			if(d == 0 && w != 0)
				continue
			var/turf/target_pos = locate(target_origin.x + d * tf[1] + w * tr[1], target_origin.y + d * tf[2] + w * tr[2], target_origin.z)
			if(!target_pos)
				continue
			var/obj/effect/corridor_showcase_tile/tile = new(null)
			tile.vis_contents += target_pos
			tile.pixel_x = world.icon_size * (d * lf[1] + w * lr[1])
			tile.pixel_y = world.icon_size * (d * lf[2] + w * lr[2])
			local_door.vis_contents += tile
			tiles += tile

/obj/effect/corridor_showcase/proc/dir_offset(d)
	switch(d)
		if(NORTH)
			return list(0, 1)
		if(SOUTH)
			return list(0, -1)
		if(EAST)
			return list(1, 0)
		if(WEST)
			return list(-1, 0)
	return list(0, 0)

/obj/effect/corridor_showcase/Destroy()
	for(var/obj/effect/corridor_showcase_tile/T in tiles)
		if(our_door && !QDELETED(our_door))
			our_door.vis_contents -= T
		qdel(T)
	tiles.Cut()
	our_target = null
	our_door = null
	return ..()


/obj/effect/corridor_showcase_tile
	name = "corridor view"
	icon = null
	icon_state = ""
	appearance_flags = KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	plane = ABOVE_LIGHTING_PLANE
	layer = BELOW_MOB_LAYER
	anchored = TRUE

/obj/effect/corridor_showcase_tile/Destroy()
	vis_contents = null
	return ..()

#undef CORRIDOR_VIEW_DEPTH
#undef CORRIDOR_VIEW_HALF_WIDTH
