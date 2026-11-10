/datum/distortion_territory
	var/mob/living/simple_animal/hostile/distortion/advanced/owner
	var/turf/origin
	//The turfs that are within the territory.
	var/list/claimed = list()
	//The turfs that are next to the territory, but are not claimed
	var/list/frontier = list()
	var/cap = 2000
	//Making it a bit harder to enter buildings, so the streets are prioritized
	var/door_cost = 6
	//Checking how far the distortion has progressed, based on the size of its territory.
	var/stage = 0
	var/list/stage_thresholds = list(100, 400, 1000)
	var/paused = FALSE
	var/growth_rate
	var/growth_timer
	var/oddity_interval = 20 SECONDS
	var/oddity_player_range = 7
	var/oddity_timer

/datum/distortion_territory/New(mob/living/simple_animal/hostile/distortion/advanced/new_owner, turf/new_origin)
	owner = new_owner
	origin = new_origin
	cap = owner.territory_cap
	if(length(owner.territory_stages))
		stage_thresholds = owner.territory_stages.Copy()
	growth_rate = owner.territory_growth_rate
	frontier[origin] = 0

/datum/distortion_territory/Destroy()
	Revert()
	owner = null
	origin = null
	return ..()

//Removes all claimed turfs and frontier turfs, and stops the growth timer.
//Called when the territory is destroyed, such as on the death of the distortion.
/datum/distortion_territory/proc/Revert()
	if(growth_timer)
		deltimer(growth_timer)
		growth_timer = null
	if(oddity_timer)
		deltimer(oddity_timer)
		oddity_timer = null
	claimed.Cut()
	frontier.Cut()

// It's a loop, where as long as there is amount left, the territory is below its cap, and there are frontier turfs, it claims the cheapest one.
/datum/distortion_territory/proc/Claim(amount)
	while(amount > 0 && claimed.len < cap && frontier.len)
		var/turf/T = CheapestFrontierTurf()
		var/distance = frontier[T]
		frontier -= T
		amount -= TurfCost(T)
		ClaimTurf(T, distance)
	UpdateStage()

//Using the size of the territory, it checks how many stage thresholds have been reached. Returning the total number of thresholds passed
/datum/distortion_territory/proc/StageFor(size)
	var/result = 0
	for(var/threshold in stage_thresholds)
		if(size >= threshold)
			result++
	if(size >= cap)
		result++
	return result

//Sets the stage based on the size of the territory and notifies the owner of any changes.
/datum/distortion_territory/proc/UpdateStage()
	var/new_stage = StageFor(claimed.len)
	if(new_stage == stage)
		return
	var/old_stage = stage
	stage = new_stage
	message_admins("[owner] reached territory stage [new_stage] ([claimed.len] turfs) [ADMIN_FLW(owner)] in [ADMIN_VERBOSEJMP(owner)].")
	owner.OnStageChange(old_stage, new_stage)

/datum/distortion_territory/proc/StartGrowing(interval)
	if(growth_timer)
		deltimer(growth_timer)
	growth_timer = addtimer(CALLBACK(src, PROC_REF(Grow)), interval, TIMER_STOPPABLE | TIMER_LOOP)
	ScheduleOddity()

//Gets triggered every growth interval, and causes the distortion to claim turfs passively.
/datum/distortion_territory/proc/Grow()
	if(!owner || owner.stat == DEAD || paused)
		return
	Claim(GrowthAmount())
	owner.OnTerritoryGrown()

//How many turfs the territory grows by. The default is 10, or 15% of its size, whichever is larger.
//With growth_rate set it is growth_rate / sqrt(size), at least 5: a big burst at first that keeps slowing down.
/datum/distortion_territory/proc/GrowthAmount()
	if(growth_rate)
		return max(5, round(growth_rate / sqrt(max(1, claimed.len))))
	return max(10, round(claimed.len * 0.15))

//Looks through the list of frontier turfs, and returns the one with the lowest cost.
/datum/distortion_territory/proc/CheapestFrontierTurf()
	var/turf/best
	var/best_cost = INFINITY
	for(var/turf/T in frontier)
		if(frontier[T] < best_cost)
			best = T
			best_cost = frontier[T]
	return best

/datum/distortion_territory/proc/TurfCost(turf/T)
	if(locate(/obj/machinery/door) in T)
		return door_cost
	if(locate(/obj/structure/mineral_door) in T)
		return door_cost
	return 1

//It adds a turf to the territory and marks all of its neighbors as frontier turfs.
//Also, when claiming a turf, it sets all of the new frontier turfs to have a one higher cost than the claimed turf. (If it has a door, it will be +6 instead)
//That way, once it starts expanding really far, it will start creeping into buildings later on.
/datum/distortion_territory/proc/ClaimTurf(turf/T, distance = 0)
	claimed[T] = distance
	//Check each cardinal direction for a new frontier turf.
	for(var/dir in GLOB.cardinals)
		var/turf/next = get_step(T, dir)
		if(!next || Contains(next) || !Eligible(next))
			continue
		var/next_cost = distance + TurfCost(next)
		//Only update the new frontier turf's cost if it's new or cheaper than the existing cost.
		if(isnull(frontier[next]) || frontier[next] > next_cost)
			frontier[next] = next_cost
	owner.OnTurfClaimed(T)

//Just make sure they don't expand to some place weird like water or space.
/datum/distortion_territory/proc/Eligible(turf/T)
	if(T.z != origin.z || isclosedturf(T))
		return FALSE
	if(istype(T, /turf/open/water) || isspaceturf(T))
		return FALSE
	return TRUE

//Checks if a turf is within the territory.
/datum/distortion_territory/proc/Contains(turf/T)
	return !isnull(claimed[T])

/datum/distortion_territory/proc/Size()
	return claimed.len

/datum/distortion_territory/proc/RandomTurf()
	if(!claimed.len)
		return get_turf(owner)
	return pick(claimed)

//This allows the distortion to get a list of the nearest claimed turfs, from origin. With n being the total number of turfs we want to find.
//This uses a breadth-first search to find the nearest claimed turfs.
/datum/distortion_territory/proc/NearestTurfs(n)
	var/list/result = list(origin)
	var/list/seen = list()
	seen[origin] = TRUE
	var/i = 1
	//While we still have turfs to check and haven't found enough claimed turfs, check each one's neighbors.
	while(i <= result.len && result.len < n)
		var/turf/T = result[i++]
		//Check each cardinal direction for a new claimed turf.
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			//Skip invalid, already seen, or unclaimed turfs.
			if(!next || seen[next] || !Contains(next))
				continue
			seen[next] = TRUE
			result += next
			if(result.len >= n)
				break
	return result

//Sets up a timer to start spawning oddities.
//The interval between oddity spawns decreases as the territory stage increases.
/datum/distortion_territory/proc/ScheduleOddity()
	if(oddity_timer)
		deltimer(oddity_timer)
	oddity_timer = addtimer(CALLBACK(src, PROC_REF(TickOddity)), oddity_interval / (stage + 1), TIMER_STOPPABLE)

/datum/distortion_territory/proc/TickOddity()
	oddity_timer = null
	if(!owner || owner.stat == DEAD)
		return
	ScheduleOddity()
	if(!claimed.len || !length(owner.oddities))
		return
	//Try to find a claimed turf with a player nearby. After 5 attempts, we don't spawn an oddity.
	for(var/i in 1 to 5)
		var/turf/T = pick(claimed)
		if(!PlayerNear(T))
			continue
		var/path = pick(owner.oddities)
		new path(T, owner)
		return

//Checks if there is a player nearby, so we don't spawn an oddity where nobody can see it.
//This would not be laggy, since in the worse case of 20 living players, we only check 20 distances a max of 5 times.
/datum/distortion_territory/proc/PlayerNear(turf/T)
	for(var/mob/M as anything in GLOB.player_list)
		if(!isliving(M) || M.stat == DEAD)
			continue
		if(M.z == T.z && get_dist(M, T) <= oddity_player_range)
			return TRUE
	return FALSE
