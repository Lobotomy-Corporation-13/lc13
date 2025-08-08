/proc/is_in_sight(atom/first_atom, atom/second_atom)
	var/turf/first_turf = get_turf(first_atom)
	var/turf/second_turf = get_turf(second_atom)

	if(!first_turf || !second_turf)
		return FALSE

	return inLineOfSight(first_turf.x, first_turf.y, second_turf.x, second_turf.y, first_turf.z)

///Returns all atoms present in a circle around the center
/proc/circle_range(center = usr,radius = 3)

	var/turf/center_turf = get_turf(center)
	var/list/atoms = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/atom/checked_atom as anything in range(radius, center_turf))
		var/dx = checked_atom.x - center_turf.x
		var/dy = checked_atom.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			atoms += checked_atom

	return atoms

///Returns all atoms present in a circle around the center but uses view() instead of range() (Currently not used)
/proc/circle_view(center=usr,radius=3)

	var/turf/center_turf = get_turf(center)
	var/list/atoms = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/atom/checked_atom as anything in view(radius, center_turf))
		var/dx = checked_atom.x - center_turf.x
		var/dy = checked_atom.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			atoms += checked_atom

	return atoms

///Returns the distance between two atoms
/proc/get_dist_euclidean(atom/first_location, atom/second_location)
	var/dx = first_location.x - second_location.x
	var/dy = first_location.y - second_location.y

	var/dist = sqrt(dx ** 2 + dy ** 2)

	return dist

///Returns a list of turfs around a center based on RANGE_TURFS()
/proc/circle_range_turfs(center = usr, radius = 3)

	var/turf/center_turf = get_turf(center)
	var/list/turfs = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/turf/checked_turf as anything in RANGE_TURFS(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			turfs += checked_turf
	return turfs

///Returns a list of turfs around a center based on view()
/proc/circle_view_turfs(center=usr,radius=3) //Is there even a diffrence between this proc and circle_range_turfs()? // Yes
	var/turf/center_turf = get_turf(center)
	var/list/turfs = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/turf/checked_turf in view(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			turfs += checked_turf
	return turfs

///Returns the list of turfs around the outside of a center based on RANGE_TURFS()
/proc/border_diamond_range_turfs(atom/center = usr, radius = 3)
	var/turf/center_turf = get_turf(center)
	var/list/turfs = list()

	for(var/turf/checked_turf as anything in RANGE_TURFS(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		var/abs_sum = abs(dx) + abs(dy)
		if(abs_sum == radius)
			turfs += checked_turf
	return turfs

///Returns a slice of a list of turfs, defined by the ones that are inside the inner/outer angle's bounds
/proc/slice_off_turfs(atom/center, list/turf/turfs, inner_angle, outer_angle)
	var/turf/center_turf = get_turf(center)
	var/list/sliced_turfs = list()

	for(var/turf/checked_turf as anything in turfs)
		var/angle_to = get_angle(center_turf, checked_turf)
		if(angle_to < inner_angle || angle_to > outer_angle)
			continue
		sliced_turfs += checked_turf
	return sliced_turfs

/**
 * Behaves like the orange() proc, but only looks in the outer range of the function (The "peel" of the orange).
 * This is useful for things like checking if a mob is in a certain range, but not within a smaller range.
 *
 * @params outer_range - The outer range of the cicle to pull from.
 * @params inner_range - The inner range of the circle to NOT pull from.
 * @params center - The center of the circle to pull from, can be an atom (we'll apply get_turf() to it within circle_x_turfs procs.)
 * @params view_based - If TRUE, we'll use circle_view_turfs instead of circle_range_turfs procs.
 */
/proc/turf_peel(outer_range, inner_range, center, view_based = FALSE)
	if(inner_range > outer_range) // If the inner range is larger than the outer range, you're using this wrong.
		CRASH("Turf peel inner range is larger than outer range!")
	var/list/peel = list()
	var/list/outer
	var/list/inner
	if(view_based)
		outer = circle_view_turfs(center, outer_range)
		inner = circle_view_turfs(center, inner_range)
	else
		outer = circle_range_turfs(center, outer_range)
		inner = circle_range_turfs(center, inner_range)
	for(var/turf/possible_spawn as anything in outer)
		if(possible_spawn in inner)
			continue
		peel += possible_spawn

	if(!length(peel))
		return center //Offer the center only as a default case when we don't have a valid circle.
	return peel

///check if 2 diagonal turfs are blocked by dense objects
/proc/diagonally_blocked(turf/our_turf, turf/dest_turf)
	if(get_dist(our_turf, dest_turf) != 1)
		return FALSE
	var/direction_to_turf = get_dir(dest_turf, our_turf)
	if(!ISDIAGONALDIR(direction_to_turf))
		return FALSE
	for(var/direction_check in GLOB.cardinals)
		if(!(direction_check & direction_to_turf))
			continue
		var/turf/test_turf = get_step(dest_turf, direction_check)
		if(isnull(test_turf))
			continue
		if(!test_turf.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
	return TRUE
