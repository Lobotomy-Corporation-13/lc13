#define PYTHAGOREAN(A,B,C,D) sqrt(((A-B)**2)+((C-D)**2))

SUBSYSTEM_DEF(flowfield)
	name = "Flowfield"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_PATH
	//The maximum amount of attempts for the flowfield.
	var/attempts = 0
	var/max_range = 100
	var/currently_running = 0

	//Labels currently being scanned so we dont get duplicates.
	var/list/currently_scanning_labels = list()

	//List of directional world maps.
	var/list/maps = list()

/datum/controller/subsystem/flowfield/Recover()
	flags |= SS_NO_INIT // Make extra sure we don't initialize twice.

/datum/controller/subsystem/flowfield/Initialize()
	attempts = world.maxz * world.maxy
	return ..()

/datum/controller/subsystem/flowfield/stat_entry(msg)
	msg = "MAPS:[length(maps)]"
	return ..()

//These procs are called remotely from atoms.

/datum/controller/subsystem/flowfield/proc/MakeMyMap(atom/source, label)
	currently_scanning_labels += label
	if(!label || (locate(label) in currently_scanning_labels))
		currently_scanning_labels -= label
		return

	var/turf/thing_location = get_turf(source)
	if(!thing_location)
		currently_scanning_labels -= label
		return
	var/list/flow_map = Start(thing_location)
	if(!(label in maps))
		maps += label
	maps[label] = flow_map
	currently_scanning_labels -= label

/datum/controller/subsystem/flowfield/proc/FindMap(label)
	if(label in maps)
		return TRUE

/datum/controller/subsystem/flowfield/proc/CopyMap(label)
	if(!(label in maps))
		return list()
	var/list/return_map = maps[label]
	return return_map.Copy()

/*
* The purpose of this system is to create a map when called by an object.
* This map will consist of text xyz coords keys with directional elements.
* When a creature needs a map leading to a place this will provide the
* direction to their destination in exchange for their coords.
*/

/datum/controller/subsystem/flowfield/proc/Start(atom/source)
	var/turf/start = get_turf(source)
	var/turf/focus_turf = start
	var/list/openf = list()
	var/list/dir_list = list()
	var/list/closed_turfs = list()
	for(var/cycle = 1 to attempts)
		//This is to give a slight delay and ease the burdon of processing
		if(!(cycle % 15))
			sleep(5)

		if(!focus_turf)
			//If no focus_turf then something has gone terribly wrong.
			stack_trace("FormPath:focus_turfmissing:cycle[cycle]:[type]")
			return

		var/list/temp_list = ReturnAdjacentTurfs(focus_turf)
		var/list/total_list = openf + closed_turfs
		for(var/turf/T in temp_list)
			var/new_dir = get_dir(T,focus_turf)
			//Replace dir if new check is made.
			if(T in dir_list)
				//Skip steps that are already paths.
			//	if(T in closed_turfs && T != start)
			//		continue
				var/tval = total_list[T]
				var/nval
				//If its pointing at something that is cheaper than it then steal its val
				var/turf/pointing_at = get_step(T, dir_list[T])
				//Dont bother if its just a wall
				if(tval >= 1000)
					var/list/double_check_turfs = ReturnAdjacentTurfs(T, TRUE)
					for(var/turf/check in double_check_turfs)
						if(!(check in dir_list))
							continue
						var/flattened_dir = FlattenDiagonal(dir_list[check], get_dir(check,T))
						if(flattened_dir)
							dir_list[check] = flattened_dir
					continue
				//If in total_list with a openf value and is diagonal
				if(pointing_at in total_list && pointing_at.y != T.y && pointing_at.x != T.x)
					nval = total_list[pointing_at]
				if(nval && nval < tval)
					dir_list[T] = new_dir
					openf[T] = nval

			else
				dir_list += T
				dir_list[T] = new_dir
				//This is so that they stop when they are within 1 tile of the destination
				if(get_dist(start, T) <= 1)
					dir_list[T] = "dest"
				//Add turf to openf
				if(!(T in openf))
					openf += T
				//Appraise turf
				openf[T] = AppraiseTurf(T,start)
				if(openf[T] >= 1000)
					closed_turfs += focus_turf
					closed_turfs[focus_turf] = 1000

	// Only good for seeing how far the scanning is going.
		var/image/effect_flick = image('icons/effects/cult_effects.dmi',focus_turf,"bloodsparkles",CLOSED_FIREDOOR_LAYER)
		flick_overlay_view(effect_flick, focus_turf, 1)

		//Add checked focus_turfs to closed_turfs list.
		closed_turfs += focus_turf
		if(focus_turf in openf)
			closed_turfs[focus_turf] = openf[focus_turf]
		closed_turfs[focus_turf] = 0

		//If we have openf turfs to choose from then pick one of those to check.
		if(length(openf))
			var/good_options = openf - closed_turfs
			focus_turf = ReturnLowestValue(good_options)
			//Look i dont care whats behind that wall your not pathing through it. Unless.
			if(good_options[focus_turf] >= 1000)
				break

	return FormatDirections(dir_list, start)

/datum/controller/subsystem/flowfield/proc/FormatDirections(list/dir_list = list())
	. = list()
	if(!length(dir_list))
		stack_trace("FormatDirections:NoDirList:[type]")
		return

	var/list/return_list = list()
	for(var/turf/floor in dir_list)
		var/tag_turf = "[floor.x],[floor.y]"
		var/direction_thing = dir_list[floor]
		if(direction_thing == "null")
			continue
		return_list += tag_turf
		return_list[tag_turf] = direction_thing

	return return_list

/datum/controller/subsystem/flowfield/proc/AppraiseTurf(turf/T, turf/start)
	. = 0
	if(T.density || !istype(T, /turf/open))
		return 10000
	//Gcost
	var/g_cost = CountDist(T,start)
	if(g_cost / 10 == max_range)
		return 10000

	. += g_cost


	//If not open turf its likely a wall.
	var/turf/open/O = T
	if(istype(O, /turf/open/water/deep))
		var/turf/open/water/deep/watar = O
		if(!watar.safe)
			return 10000
	if(O.slowdown)
		. += O.slowdown

	//Do not go on forever, stop when we reach critical mass.
	var/total_extra = 0
	/*
	* Lets just get silly with it, a total of 20 items can be checked
	* If one item cycle returns early then we can use the extra charges
	* on the next.
	*/
	var/total_check = 0

	for(var/obj/structure/S in O)
		total_check++
		if(total_extra > 50 || total_check >= 15)
			break
		if(S.density)
			if(S.resistance_flags & INDESTRUCTIBLE || istype(S, /obj/structure/railing))
				return 10000
			. += 20
			total_extra += 20
			break

	for(var/obj/machinery/M in O)
		total_check++
		if(total_extra > 50 || total_check >= 20)
			break
		if(M.density)
			if(!istype(M,/obj/machinery/door))
				if(M.resistance_flags & INDESTRUCTIBLE)
					return 10000
				. += 20
				total_extra += 20
				break
			//Mostly because im sick of them ignoring doors.
			. -= 10
			total_extra -= 10

	for(var/obj/effect/turf_fire/F in O)
		total_check++
		if(total_extra > 50 || total_check >= 5)
			break
		if(QDELETED(F))
			continue
		. += 100
		break

	if(total_extra > 50)
		return

	for(var/mob/living/L in O)
		total_check++
		if(total_check >= 10)
			break
		if(L.density)
			. += 10
			break

/datum/controller/subsystem/flowfield/proc/ReturnAdjacentTurfs(turf/focus_turf, strict_adjacent = FALSE)
	var/list/return_list = list()
	//Just give me adjacent turfs
	var/fx = focus_turf.x
	var/fy = focus_turf.y
	var/fz = focus_turf.z
	if(strict_adjacent)
		return_list += block(fx - 1,fy,fz,fx + 1,fy,fz) - focus_turf
		return_list += block(fx,fy -1 ,fz,fx,fy + 1,fz) - focus_turf
	else
		return_list += block(fx -1,fy -1,fz,fx +1,fy +1,fz) - focus_turf

	if(!length(return_list))
		stack_trace("ReturnAdjacentTurfsFail")

	return return_list

/datum/controller/subsystem/flowfield/proc/CountDist(turf/T, turf/dest)
	if(!T || !dest)
		return 0
	return PYTHAGOREAN(T.x,dest.x,T.y,dest.y) * 10

//For dangerous turfs. If a dangerous turf is north of a arrow pointing northeast it will change it to east.
/datum/controller/subsystem/flowfield/proc/FlattenDiagonal(direct, remove_dir)
	if(direct == NORTHWEST)
		if(remove_dir == NORTH)
			return WEST
		if(remove_dir == WEST)
			return NORTH
	if(direct == NORTHEAST)
		if(remove_dir == NORTH)
			return EAST
		if(remove_dir == EAST)
			return NORTH
	if(direct == SOUTHEAST)
		if(remove_dir == SOUTH)
			return EAST
		if(remove_dir == EAST)
			return SOUTH
	if(direct == SOUTHWEST)
		if(remove_dir == SOUTH)
			return WEST
		if(remove_dir == WEST)
			return SOUTH

#undef PYTHAGOREAN
