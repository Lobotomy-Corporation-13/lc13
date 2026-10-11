
/*
* The Flowfield system is my attempt to
* make maps that span the entire map
* without having inconceivable amounts
* of lag. The system needlessly ticks every
* few nanoseconds and checks a list of
* mapholder datums. A atom in the game calls
* MakeMyMap and creates a mapholder
* variable thats connected to a starting tile.
* flowfield then calls Beat in 5 of the mapholders
* which causes them to build a map from the central
* starting turf. From there it cycles through tiles
* and applies a value to them based on the type and
* contents of the turf. After a certain amount of
* beats the map is finished if the value of its
* focus turf hits 1000, the value of a wall.
* These maps can be used before the map is
* finished scanning if the entity is close enough.
* the downside however is that more than 5 actively
* scanning maps, hopefully, wont lag the game but take a long
* time to actually finish with map 6 not even starting
* until one of the earlier maps finish.
*/

SUBSYSTEM_DEF(flowfield)
	name = "Flowfield"
	flags = SS_BACKGROUND | SS_KEEP_TIMING
	wait = 2
	init_order = INIT_ORDER_GAMEDIRECTOR
	runlevels = RUNLEVEL_GAME

	//List of directional world maps.
	var/list/maps = list()

	/*
	* Amount of maps to cycle through and check.
	* Each map proc'ed scans 4 tiles around the
	* focus turf so cycle_limit * 4.
	*/
	var/cycle_limit = 5
	//Variable for tracking how many maps are currently running
	var/running_maps = 0

/datum/controller/subsystem/flowfield/Recover()
	flags |= SS_NO_INIT // Make extra sure we don't initialize twice.

/datum/controller/subsystem/flowfield/Initialize()
	. = ..()
	//Collect Flowmaps on Landmarks
	addtimer(CALLBACK(src, PROC_REF(CollectLandmarks)), 1 SECONDS)

/datum/controller/subsystem/flowfield/stat_entry(msg)
	msg = "|MAPS:[length(maps)]|SCANING:[running_maps]/[cycle_limit]"
	return ..()

// Im hoping this is enough checks to prevent lag.
/datum/controller/subsystem/flowfield/fire(resumed = FALSE)
	var/current_cycle = 0
	for(var/thing in maps)
		//Only cycle 5 maps before waiting
		if(current_cycle >= cycle_limit)
			break
		var/datum/mapholder/M = maps[thing]
		if(M.finish_running)
			//If map is finished running dont even call it.
			continue
		M.Beat()
		current_cycle++
	running_maps = current_cycle

//These procs are called remotely from atoms.
/datum/controller/subsystem/flowfield/proc/MakeMyMap(atom/source, label)
	if(FindMap(label))
		//If label already in list do not make a new one.
		return

	var/turf/thing_location = get_turf(source)
	if(!thing_location)
		return
	var/datum/mapholder/flow_map = new (label, thing_location)
	maps += label
	maps[label] = flow_map

/datum/controller/subsystem/flowfield/proc/FindMap(label)
	//Find and return the mapholder datum based on label.
	if(label in maps)
		return maps[label]

/datum/controller/subsystem/flowfield/proc/CollectLandmarks()
	//Collect all landmarks into flowmaps at the start
	var/list/landmarks = GLOB.department_centers
	for(var/turf/T in landmarks)
		MakeMyMap(T, AddIdentifier(T))

/*
* The purpose of this system is to create a map when called by an object.
* This map will consist of text xyz coords keys with directional elements.
* When a creature needs a map leading to a place this will provide the
* direction to their destination in exchange for their coords.
*/

/datum/mapholder
	var/id = ""
	var/max_range = 100
	var/finish_running = FALSE
	/*
	* If start causes hard deletes for the
	* turf we can use a text proc with the
	* start turfs coordnates. -IP
	*/
	var/turf/start
	var/turf/focus_turf
	var/list/openf = list()
	var/list/dir_list = list()
	var/list/closed_turfs = list()

/datum/mapholder/New(name, atom/source)
	if(!source)
		qdel(src)
		return
	if(name)
		id = name
	if(source)
		start = get_turf(source)
	if(!start)
		qdel(src)
		return
	focus_turf = start

/*
* One downside to makings a map is the fact that
* it has the chance of being outdated.
* This reset proc should allow the map to start
* over since the system avoids making multiple
* maps with the same label.
*/
/datum/mapholder/proc/ResetMap()
	openf.Cut()
	dir_list.Cut()
	closed_turfs.Cut()
	focus_turf = start
	finish_running = FALSE

//If coords not in map just return blank
/datum/mapholder/proc/CheckMap(coords = "")
	if(coords in dir_list)
		return dir_list
	return list()

//Subsystem calls this to update the map.
/datum/mapholder/proc/Beat()
	if(!focus_turf)
		//If no focus_turf then something has gone terribly wrong.
		stack_trace("FormPath:focus_turfmissing:[id]")
		return
	if(finish_running)
		return

	var/list/temp_list = ReturnAdjacentTurfs(focus_turf)
	var/list/total_list = openf + closed_turfs
	for(var/turf/T in temp_list)
		var/new_dir = get_dir(T,focus_turf)
		var/temp_coords = "[T.x],[T.y]"
		//Replace dir if new check is made.
		if(temp_coords in dir_list)
			var/tval = total_list[temp_coords]
			var/nval
			//If its pointing at something that is cheaper than it then steal its val
			var/turf/pointing_at = get_step(T, dir_list[T])
			//Dont bother if its just a wall
			if(tval >= 1000)
				var/list/double_check_turfs = ReturnAdjacentTurfs(T, TRUE)
				for(var/turf/check in double_check_turfs)
					var/check_coords = "[check.x],[check.y]"
					if(!(check_coords in dir_list))
						continue
					var/flattened_dir = FlattenDiagonal(dir_list[check_coords], get_dir(check,T))
					if(flattened_dir)
						dir_list[check_coords] = flattened_dir
				continue
			//If in total_list with a openf value and is diagonal
			if(pointing_at in total_list && pointing_at.y != T.y && pointing_at.x != T.x)
				nval = total_list[pointing_at]
			if(nval && nval < tval)
				dir_list[T] = new_dir
				openf[T] = nval

		else
			dir_list += temp_coords
			dir_list[temp_coords] = new_dir
			//This is so that they stop when they are within 1 tile of the destination
			if(get_dist(start, T) <= 1)
				dir_list[temp_coords] = "dest"
			//Add turf to openf
			if(!(T in openf))
				openf += T
			//Appraise turf
			openf[T] = AppraiseTurf(T,start)
			if(openf[T] >= 1000)
				closed_turfs += focus_turf
				closed_turfs[focus_turf] = 1000

/* Only good for seeing how far the scanning is going.
	var/image/effect_flick = image('icons/effects/cult_effects.dmi',focus_turf,"bloodsparkles",CLOSED_FIREDOOR_LAYER)
	flick_overlay_view(effect_flick, focus_turf, 1)
*/

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
			finish_running = TRUE
			openf.Cut()
	return TRUE

/datum/mapholder/proc/AppraiseTurf(turf/T, turf/start)
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

/datum/mapholder/proc/ReturnAdjacentTurfs(turf/focus_turf, strict_adjacent = FALSE)
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

/datum/mapholder/proc/CountDist(turf/T, turf/dest)
	if(!T || !dest)
		return 0
	return PYTHAGOREAN(T.x,dest.x,T.y,dest.y) * 10

/*
* For dangerous turfs. If a dangerous turf is north of a
* arrow pointing northeast it will change it to east.
*/
/datum/mapholder/proc/FlattenDiagonal(direct, remove_dir)
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
