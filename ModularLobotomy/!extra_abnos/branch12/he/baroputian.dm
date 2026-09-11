#define PYTHAGOREAN(A,B,C,D) sqrt(((A-B)**2)+((C-D)**2))
#define LILI_BEHAVIOR_MODE_STEAL 1
#define LILI_BEHAVIOR_MODE_RETURN 2
#define LILI_BEHAVIOR_MODE_ATTACK 3

/*
* The Baroputians: Entities decended from something they call
* \"The great Baromez\". They covet items that belong to other
* creatures yet are violently agressive if found in number.
* They are also agressive to Baroputians of other colors.
* Rarely a Baroputian that has decorated themselves with red
* leaves will appear called a \"Flower\". Flowers tend to be
* hunted down and violently killed by their kin for being
* different.
*/
/mob/living/simple_animal/hostile/abnormality/branch12/baromez
	name = "Baromez"
	desc = "A red leafed plant that has a strange underdeveloped fruit."
	icon = 'ModularLobotomy/_Lobotomyicons/baroputian.dmi'
	icon_state = "barostem"
	icon_living = "barostem"
	density = FALSE
	maxHealth = 120
	health = 120
	melee_damage_lower = 0
	melee_damage_upper = 0
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	stop_automated_movement_when_pulled = TRUE
	search_objects = FALSE
	mob_size = MOB_SIZE_SMALL
	del_on_death = TRUE

	can_breach = TRUE
	threat_level = HE_LEVEL
	start_qliphoth = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(80, 60, 45, 30, 30),
		ABNORMALITY_WORK_INSIGHT = list(20, 40, 45, 50, 60),
		ABNORMALITY_WORK_ATTACHMENT = 20,
		ABNORMALITY_WORK_REPRESSION = -10,
	)

	work_damage_amount = 8
	work_damage_type = WHITE_DAMAGE
	can_patrol = FALSE
	wander = FALSE
	vision_range = 0

	//Generally mundane breach
	neutral_droprate = 30
	bad_droprate = 70

	ego_list = list(
		/datum/ego_datum/weapon/branch12/barostem,
		/datum/ego_datum/armor/branch12/barostem,
	)

	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12
	var/active = FALSE
	var/size = 1
	var/max_followers = 6
	var/resources = 30
	var/max_resources = 50
	var/list/followers = list()

	//Flow Field Variables
	var/got_world_map = FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(NaturalStart)), 1 SECONDS)

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/ZeroQliphoth()
	invisibility = INVISIBILITY_MAXIMUM
	if(length(GLOB.department_centers) && !active)
		var/turf/W = pick(GLOB.department_centers)
		forceMove(W)
	NaturalStart()
	. = ..()
	invisibility = initial(invisibility)
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/FindTarget()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/update_icon_state()
	. = ..()
	if(IsContained())
		name = "Baromez"
		desc = "A red leafed plant that has a strange underdeveloped fruit."
		icon_state = "barostem"
	else
		name = "lillibag"
		desc = "A large sack made of leather."
		icon_state = "bag[size]"
	icon_living = icon_state

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/Life()
	. = ..()
	if(!.) // Dead
		return
	if(!active)
		return
	//If we got a world map check once and share with minions
	if(!got_world_map && SSflowfield.FindMap(AddIdentifier(get_turf(src))))
		ShareMap()
		got_world_map = TRUE

	//If less than 5 followers and at least 10 resources, spawn a follower
	if(LAZYLEN(followers) < max_followers && (resources >= 10 && resources < max_resources))
		var/mob/living/simple_animal/hostile/baroputian/stealer = new(get_turf(src))
		resources -= 10
		RegisterMob(stealer)
	//No one is left. Decay.
	if(LAZYLEN(followers) <= 0)
		adjustHealth(5)
	//If 20 items stolen call everyone back and escape.
	if(resources >= max_resources)
		var/where_is_everyone = FALSE
		for(var/L in followers)
			if(istype(L, /mob/living/simple_animal/hostile/baroputian))
				var/mob/living/simple_animal/hostile/baroputian/I = L
				I.behavior_mode = LILI_BEHAVIOR_MODE_RETURN
				where_is_everyone = TRUE
				continue

		if(!where_is_everyone)
			QDEL_IN(src, 2)

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/attackby(obj/item/C, mob/user)
	. = ..()
	if(!istype(user, /mob/living/simple_animal/hostile/baroputian))
		EnrageAll(user)

//Explode into consumed loot on death.
/mob/living/simple_animal/hostile/abnormality/branch12/baromez/death(gibbed)
	var/spew_turf = pick(get_adjacent_open_turfs(src))
	for(var/atom/movable/i in contents)
		i.forceMove(spew_turf)
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/Destroy()
	UnregisterAll()
	return ..()

//Put item in bag and calculate resource gain.
/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/RecieveItem(atom/movable/thing)
	thing.forceMove(src)
	if(isliving(thing))
		resources += 10
	else
		resources += 1

	if(LAZYLEN(contents) >= 4 || resources >= 10)
		size = 2
	if(LAZYLEN(contents) >= 15 || resources >= 30)
		size = 3
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/NaturalStart()
	if(IsContained())
		return
	SSflowfield.MakeMyMap(src, AddIdentifier(get_turf(src)))
	active = TRUE
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/ShareMap()
	var/our_identifier = AddIdentifier(get_turf(src))
	for(var/L in followers)
		if(istype(L, /mob/living/simple_animal/hostile/baroputian))
			var/mob/living/simple_animal/hostile/baroputian/I = L
			I.GrabHomeMap(our_identifier)

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/EnrageAll(mob/living/offender)
	for(var/L in followers)
		if(istype(L, /mob/living/simple_animal/hostile/baroputian))
			var/mob/living/simple_animal/hostile/baroputian/I = L
			I.DropItem()
			I.behavior_mode = LILI_BEHAVIOR_MODE_ATTACK
			I.GiveTarget(offender)

/*---------------\
|Mob Registration|
\---------------*/

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/RegisterMob(mob/living/L)
	RegisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob))
	if(istype(L, /mob/living/simple_animal/hostile/baroputian))
		var/mob/living/simple_animal/hostile/baroputian/entity = L
		entity.home = tag
		entity.faction = faction.Copy()
		entity.GrabHomeMap(AddIdentifier(get_turf(src)))
		followers += L

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/UnregisterMob(mob/living/L)
	UnregisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	if(istype(L, /mob/living/simple_animal/hostile/baroputian))
		var/mob/living/simple_animal/hostile/baroputian/entity = L
		entity.home = null
		entity.behavior_mode = LILI_BEHAVIOR_MODE_ATTACK
		followers -= L

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/UnregisterAll()
	for(var/mob/living/L in followers)
		UnregisterMob(L)
	followers.Cut()

//---------------------------------------------------
/*------\
|Minions|
\------*/

/mob/living/simple_animal/hostile/baroputian
	name = "baroputian"
	desc = "A diminutive \"plant sheep\" twisted into a humanoid form."
	icon = 'ModularLobotomy/_Lobotomyicons/baroputian.dmi'
	icon_state = "baroputian"
	icon_living = "baroputian"
	environment_smash = TRUE
	density = FALSE
	friendly_verb_continuous = "smacks"
	friendly_verb_simple = "smack"
	faction = list("hostile")
	maxHealth = 20
	melee_damage_lower = 5
	melee_damage_upper = 15
	vision_range = 8
	aggro_vision_range = 10
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 2)
	stop_automated_movement_when_pulled = TRUE
	search_objects = TRUE
	mob_size = MOB_SIZE_SMALL
	can_be_held = TRUE
	del_on_death = TRUE
	var/obj/item/held_item
	var/allies = 0
	var/behavior_mode = LILI_BEHAVIOR_MODE_STEAL
	var/behavior_change_cooldown = 0
	var/behavior_change_delay = 3 SECONDS
	//Uses tags
	var/home

	//Experimental Pathfinding
	var/smart_pathing = TRUE
	var/walk_timer = null
	var/list/walk_path = list()
	//Flow field map to their bag
	var/list/world_map = list()
	//Possibly a terrible attempt at sorting
	var/alist/walk_variables = alist(
		//Very generous
		"attempts" = 50,
		"thinking" = FALSE,
		//If we redraw a map when we reach our dest
		"remap_on_dest" = TRUE,
		//Countdown for how many times we keep our map.
		"redraw" = 0,
		//Travels strictly in adjacent tiles
		"no_diagonals" = FALSE,
		//checks closed turfs afterwards to avoid them
		"careful" = TRUE,
		/*
		* To prevent the path_step from jolting forward
		* this value tracks the last time we took a step.
		*/
		"walk_cooldown" = 0,
		)

/*-----\
|Vitals|
\-----*/

/mob/living/simple_animal/hostile/baroputian/Initialize()
	. = ..()
	AddComponent(/datum/component/swarming)

/mob/living/simple_animal/hostile/baroputian/Move(atom/newloc, direct, glide_size_override)
	. = ..()
	if(!.)
		return
	walk_variables["walk_cooldown"] = world.time + move_to_delay

/mob/living/simple_animal/hostile/baroputian/Destroy()
	if(TIMER_COOLDOWN_CHECK(src,walk_timer))
		deltimer(walk_timer)

	if(held_item)
		DropItem()
	return ..()

/mob/living/simple_animal/hostile/baroputian/handle_automated_movement()
	. = ..()
	if(stat == DEAD || !can_act) // Dead
		return FALSE
	if(behavior_change_cooldown <= world.time && behavior_mode != LILI_BEHAVIOR_MODE_RETURN && !target)
		behavior_change_cooldown = world.time + behavior_change_delay + rand(1,5)
		if(allies > 2)
			behavior_mode = LILI_BEHAVIOR_MODE_ATTACK
		else
			behavior_mode = LILI_BEHAVIOR_MODE_STEAL

	if(!target)
		if(length(world_map) && (held_item || isliving(pulling) || behavior_mode == LILI_BEHAVIOR_MODE_RETURN))
			if(world_map)
				var/our_coords = "[x],[y]"
				if(our_coords in world_map)
					walk_path = world_map.Copy()
					WalkPing()
					return
		walk_rand(src, move_to_delay)


/mob/living/simple_animal/hostile/baroputian/AttackingTarget()
	if(!can_act)
		return
	var/distance = get_dist(src,target)
	if(distance > 1)
		return ..()

	if(isitem(target) && !held_item)
		return GrabItem(target)

	if(home)
		if(IsHome(target))
			var/mob/living/simple_animal/hostile/abnormality/branch12/baromez/bag = target
			if(isliving(pulling) && pulling != bag && pulling != src)
				var/mob/living/H = pulling
				bag.RecieveItem(H)
			if(held_item)
				bag.RecieveItem(held_item)
				held_item = null
				cut_overlays()
			//If returning home just go inside.
			if(behavior_mode == LILI_BEHAVIOR_MODE_RETURN)
				QDEL_IN(src, 1)
				return
			stop_pulling()
			SLEEP_CHECK_DEATH(1)
			LoseTarget()
			return

	//If no home just throw everything in the local trash bin.
	else if(istype(target,/obj/machinery/disposal/bin))
		var/obj/machinery/disposal/bin/B = target
		if(isliving(pulling))
			var/mob/living/H = pulling
			if(H.stat != CONSCIOUS)
				B.place_item_in_disposal(H, src)
				stop_pulling()
		if(held_item)
			B.place_item_in_disposal(held_item, src)
			held_item = null
			cut_overlays()
		stop_pulling()
		SLEEP_CHECK_DEATH(1)
		LoseTarget()
		return

	if(isliving(target))
		var/mob/living/L = target
		if(L) //If subject is in crit and is not being pulled by a ally, grab them.
			if(L.stat != CONSCIOUS && !istype(L.pulledby,/mob/living/simple_animal/hostile/baroputian))
				start_pulling(target)
				SLEEP_CHECK_DEATH(1)
				LoseTarget()
				return
	return ..()

/mob/living/simple_animal/hostile/baroputian/update_overlays()
	. = ..()
	if(held_item)
		//Grab the item and lift it 20 pixels above their head.
		var/mutable_appearance/new_overlay = mutable_appearance(held_item.icon, held_item.icon_state)
		new_overlay.pixel_y = 20
		. += new_overlay

/mob/living/simple_animal/hostile/baroputian/attackby(obj/item/C, mob/user)
	. = ..()
	if(!user)
		return
	DropItem()

/mob/living/simple_animal/hostile/baroputian/mob_try_pickup(mob/living/user)
	. = ..()
	if(!.)
		return
	say("BAAAAAH!")

/*--------\
|Targeting|
\--------*/

//Targetting Override
/mob/living/simple_animal/hostile/baroputian/Found(atom/A)
	//If behavior return, only target home.
	switch(behavior_mode)
		if(LILI_BEHAVIOR_MODE_RETURN)
			if(IsHome(A))
				return TRUE

/mob/living/simple_animal/hostile/baroputian/CanAttack(atom/the_target)
	//If is item and no held item.
	if(isitem(the_target) && !held_item)
		var/obj/O = the_target
		if(!O.anchored)
			return TRUE
	//If with loot or a body, bring it back to base.
	if((isliving(pulling) || held_item))
		if(home)
			if(IsHome(the_target))
				return TRUE
		else if(istype(the_target,/obj/machinery/disposal/bin))
			return TRUE

	//If living and your not pulling anything, and the subject is unconcious, grab em.
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L)
			//If is pulling living or holding a item ignore this thing.
			if(isliving(pulling) || held_item)
				return FALSE
			//If subject is in crit and is not being pulled by a ally, grab them.
			if(L.stat != CONSCIOUS && !istype(L.pulledby,/mob/living/simple_animal/hostile/baroputian))
				return TRUE
			if(behavior_mode != LILI_BEHAVIOR_MODE_ATTACK)
				return FALSE
	//Return to normal targeting
	return ..()

//Scan for allies in the same breath as scanning for enemies
/mob/living/simple_animal/hostile/baroputian/ListTargets(max_range = vision_range)
	allies = 0
	. = ..()
	if(!islist(.))
		return
	for(var/mob/living/simple_animal/hostile/baroputian/lilli in .)
		allies++

/*---------------\
|Collecting Items|
\---------------*/
/mob/living/simple_animal/hostile/baroputian/proc/GrabItem(atom/movable/the_target)
	can_act = FALSE
	if(isturf(the_target.loc))
		the_target.forceMove(src)
		held_item = the_target
		update_icon()
	can_act = TRUE

/mob/living/simple_animal/hostile/baroputian/proc/DropItem()
	if(!held_item)
		return
	if(held_item.loc != src)
		held_item = null
		return
	held_item.forceMove(get_turf(src))
	held_item = null
	update_icon()

/*---\
|Misc|
\---*/
/mob/living/simple_animal/hostile/baroputian/proc/IsHome(mob/living/L)
	if(istype(L, /mob/living/simple_animal/hostile/abnormality/branch12/baromez))
		var/mob/living/simple_animal/hostile/abnormality/branch12/baromez/bag = L
		if(bag.tag == home)
			return TRUE

/mob/living/simple_animal/hostile/baroputian/proc/GrabHomeMap(label)
	if(!(SSflowfield.FindMap(label)))
		return
	world_map = SSflowfield.CopyMap(label)

/*---------------------------\
|Experimental Map Pathfinding|
\---------------------------*/
//Who needs hard refrences when i got numbers. -IP
/mob/living/simple_animal/hostile/baroputian/Goto(target, delay, minimum_distance)
	if(!can_act)
		return
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE

	if(smart_pathing)
		var/dist = get_dist(src,target)
		var/min_distance = max(1, minimum_distance)
		if(dist > min_distance && dist < 10 && target)
			if(PathStep(target))
				walk(src,0)
				return

	deltimer(walk_timer)
	walk_timer = null
	return ..()

//Summoning the Path
/mob/living/simple_animal/hostile/baroputian/proc/PathStep(atom/trg)
	var/turf/trg_turf = get_turf(trg)
	if(!trg || !trg_turf || walk_variables["thinking"])
		return
	var/turf/our_turf = get_turf(src)
	var/good_path = FALSE
	//true false seems to not play well with alists
	walk_variables["thinking"] = TRUE
	var/our_tag = "[x],[y]"
	var/trg_tag = "[trg.x],[trg.y]"
	var/walk_path_dir = null
	//If our tag is in the map and our targets tag is in the map just reuse.
	if((our_tag in walk_path) && (trg_tag in walk_path) && walk_variables["redraw"] < 2)
		walk_path_dir = walk_path[trg_tag]

	//If our target isnt stationary just keep the map.
	if(walk_path_dir != "dest")
		if(FormPath(trg_turf,our_turf))
			good_path = TRUE

	//To prevent us using the same map forever we will redraw after 2 attempts
	walk_variables["redraw"] += 1

	walk_variables["thinking"] = FALSE
	if(length(walk_path) && good_path)
		WalkPing(0)
		walk_variables["redraw"] = 0
		return TRUE
	//reset redraw counter

//The actual movement that is called over and over.
/mob/living/simple_animal/hostile/baroputian/proc/WalkPing(timer_called = 0)
	if(QDELETED(src))
		return
	if(stat == DEAD)
		walk(src,0)
		return
	if(client || !can_act)
		return
	if(!isturf(loc))
		return
	//If next to target do not move into them.
	var/min_dist_check = get_dist(target,src)
	var/min_check = max(1, minimum_distance)
	if(min_dist_check <= min_check)
		return
	if(!timer_called)
		//Stop automated walking
		walk(src,0)
	//Give me our xy tag.
	var/our_tag = "[x],[y]"
	var/turf/steppers = get_step(src, walk_path[our_tag])
	var/timer_cooldown = max(1, move_to_delay)
	if(our_tag in walk_path)
		var/walk_tag = walk_path[our_tag]
		deltimer(walk_timer)
		walk_timer = null

		if(walk_tag == "dest")
			//causes "jolts" of movement
			if(target && walk_variables["remap_on_dest"])
				Goto(target, move_to_delay)
			return
		//No double stepping
		if(walk_variables["walk_cooldown"] <= world.time)
			Move(steppers, walk_path[our_tag])
		if(timer_called < 20)
			walk_timer = addtimer(CALLBACK(src, PROC_REF(WalkPing), timer_called + 1), timer_cooldown, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/baroputian/proc/FormPath(turf/start,turf/end)
	walk_path = list()
	var/max_cycles = walk_variables["attempts"] + move_to_delay
	var/turf/focus_turf = start
	var/list/openf = list()
	var/list/dir_list = list()
	var/list/closed_turfs = list()
	for(var/cycle = 1 to max_cycles)
		if(!focus_turf)
			//If no focus_turf then something has gone terribly wrong.
			stack_trace("FormPath:focus_turfmissing:cycle[cycle]:[type]")
			return
		if(get_dist(focus_turf, start) > 20)
			break
		var/list/temp_list = ReturnAdjacentTurfs(focus_turf, walk_variables["no_diagonals"])
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
					if(walk_variables["careful"])
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
				//Add turf to openf
				if(!(T in openf))
					openf += T
				//Appraise turf
				openf[T] = AppraiseTurf(T,start,end)
				if(openf[T] >= 1000)
					closed_turfs += focus_turf
					closed_turfs[focus_turf] = 1000

		//Add checked focus_turfs to closed_turfs list.
		closed_turfs += focus_turf
		if(focus_turf in openf)
			closed_turfs[focus_turf] = openf[focus_turf]
		closed_turfs[focus_turf] = 0

		//If focus_turf is the end dont worry about checking more.
		if(focus_turf == end)
			break

		//If we have openf turfs to choose from then pick one of those to check.
		if(length(openf))
			var/good_options = openf - closed_turfs
			focus_turf = ReturnLowestValue(good_options)
			//Look i dont care whats behind that wall your not pathing through it. Unless.
			if(good_options[focus_turf] >= 1000)
				break

	var/tag_turf = "[x],[y]"
	var/list/replace_walk_path = FormatDirections(dir_list, start,focus_turf)
	//We are not in the list how can we possibly use this map?
	if(!(tag_turf in replace_walk_path))
		return FALSE
	walk_path = replace_walk_path.Copy()
	return TRUE

/mob/living/simple_animal/hostile/baroputian/proc/FormatDirections(list/dir_list = list(), turf/start, turf/end)
	. = list()
	if(!length(dir_list))
		stack_trace("FormatDirections:NoDirList:[type]")
		return

	if(!start || !end)
		stack_trace("FormatDirections:nostartorend:[type]")
		return

	var/list/return_list = list()
	for(var/turf/floor in dir_list)
		var/tag_turf = "[floor.x],[floor.y]"
		return_list += tag_turf
		return_list[tag_turf] = dir_list[floor]
		if(floor == start)
			return_list[tag_turf] = "dest"

	return return_list

/mob/living/simple_animal/hostile/baroputian/proc/AppraiseTurf(turf/T, turf/start, turf/end)
	. = 0
	if(T == end)
		return -1
	if(T.density || !istype(T, /turf/open))
		return 10000
	//Hcost
	var/h_cost = CountDist(T,end)
	//Gcost
	var/g_cost = CountDist(T,start)

	. += (h_cost + g_cost)


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
			. += 10
			total_extra += 10
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
		var/fire_resist = 1
		if(FIRE in damage_coeff)
			fire_resist = damage_coeff[FIRE]
		. += 100 * fire_resist
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

/*-----------------------\
|Shared Pathfinding Procs|
\-----------------------*/
/mob/living/simple_animal/proc/ReturnAdjacentTurfs(turf/focus_turf, strict_adjacent = FALSE)
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
	return return_list

/mob/living/simple_animal/proc/CountDist(turf/T, turf/dest)
	if(!T || !dest)
		return 0
	return PYTHAGOREAN(T.x,dest.x,T.y,dest.y) * 10

//For dangerous turfs. If a dangerous turf is north of a arrow pointing northeast it will change it to east.
/mob/living/simple_animal/proc/FlattenDiagonal(direct, remove_dir)
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
#undef LILI_BEHAVIOR_MODE_STEAL
#undef LILI_BEHAVIOR_MODE_RETURN
#undef LILI_BEHAVIOR_MODE_ATTACK
