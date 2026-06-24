//For getting a checkerboard pattern.
#define GET_CHECKERBOARD_MAP(x,y) (ISEVEN(x) && ISODD(y)) || (ISODD(x) && ISEVEN(y)) ? TRUE : FALSE
//For quickly changing the stance
#define YINGLONG_STANCE_CHANGE(x) stance = x; update_icon()
//Icon stances for telegraphing
#define YINGLONG_IDLE 1
#define YINGLONG_SPARKS 2
#define YINGLONG_BARK 3

//F-02-14-23
/mob/living/simple_animal/hostile/abnormality/yinglong
	name = "Yinglong Dragon"
	desc = "A absurdly large dragon that is craning its neck down while the rest of its body floats above like a wall of clouds."
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "yinglong"
	icon_living = "yinglong"
	portrait = "yinglong"

	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -16
	base_pixel_y = -16
	offsets_pixel_x = list("south" = -32, "north" = -32, "west" = -32, "east" = -32)
	offsets_pixel_y = list("south" = -16, "north" = -16, "west" = -16, "east" = -16)
	occupied_tiles_up = 1

	maxHealth = 4500
	health = 4500
	ranged_cooldown_time = 5
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	ranged = TRUE
	is_flying_animal = TRUE

	threat_level = WAW_LEVEL
	can_breach = TRUE
	can_patrol = FALSE
	start_qliphoth = 3
	//TBD
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 0,
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 35, 40, 45),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 50, 55, 55),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 45, 50, 55),
	)
	work_damage_amount = 10
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride

	/*
	ego_list = list(
		/datum/ego_datum/weapon/tearstarnished,
		/datum/ego_datum/armor/tearstarnished,
	)
	gift_type = /datum/ego_gifts/tearstarnished
	*/
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	//Charges for skills
	var/flower_pins = 3
	//Each attack occurs in a certain order
	var/attack_cycle = 1
	//For icon Changes
	var/stance = YINGLONG_IDLE
	//projectile this mob uses in the DecendingPin attack
	var/pin_projectile_type = /obj/projectile/flowerpin
	//Abilities
	var/obj/effect/proc_holder/ability/levinfall/levin_a
	var/obj/effect/proc_holder/ability/relocate/reloc_a
	//Turfs we can currently effect
	var/list/arena_turfs = list()

/*
* F-02-14-23
*/

/*----------\
|Containment|
\----------*/
//WIP

/mob/living/simple_animal/hostile/abnormality/yinglong/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(breach_type != BREACH_MINING)
		Teleport()

/*-----\
|VITALS|
\-----*/

/mob/living/simple_animal/hostile/abnormality/yinglong/Initialize()
	. = ..()
	levin_a = new()
	src.AddSpell(levin_a)
	reloc_a = new()
	src.AddSpell(reloc_a)

/mob/living/simple_animal/hostile/abnormality/yinglong/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/yinglong/Destroy()
	if(levin_a)
		QDEL_NULL(levin_a)
	if(reloc_a)
		QDEL_NULL(reloc_a)
	arena_turfs.Cut()
	return ..()

/mob/living/simple_animal/hostile/abnormality/yinglong/update_icon_state()
	. = ..()
	if(stat == DEAD)
		return
	switch(stance)
		if(YINGLONG_IDLE)
			icon_state = "yinglong"
		if(YINGLONG_SPARKS)
			icon_state = "yinglong_s"
		if(YINGLONG_BARK)
			icon_state = "yinglong_a"

/*-----\
|ATTACK|
\-----*/

/mob/living/simple_animal/hostile/abnormality/yinglong/AttackingTarget(atom/attacked_target)
	if(!can_act && !client)
		return
	if(!target)
		GiveTarget(attacked_target)
	if(!isliving(attacked_target) && !ismecha(attacked_target))
		say("BASH")
		return ..()
	return OpenFire()

/mob/living/simple_animal/hostile/abnormality/yinglong/OpenFire()
	if(!can_act)
		return FALSE
	if(ranged_cooldown > world.time)
		return
	ranged_cooldown = world.time + ranged_cooldown_time
	AbilityRoulette(target)
	return

/*
* Wrath of the Inverted Scale: Always consume all Pin charges
* and deal 100 red damage to nearest target.
* (targeting possibly AOE or targeted AOE)
* If target is killed then 60 red damage times consumed
* pin charges is dealt to all enemies within sight. Ouch.
* ---
* The Descending Pin: Basic attack, flower burying pin charge?
* Damage increased with every 2 pin charges.
* ---
* Gathering Rain: Rapid attack for every pin.
* ---
* Levinfall: Scrap or have it consume a charge to inflict rupture.
* ---
* Since body is obscured should we include a baba yaga esque foot stomp?
*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/AbilityRoulette(trg = target)
	if(!trg)
		return
	can_act = FALSE
	YINGLONG_STANCE_CHANGE(YINGLONG_BARK)
	if(do_after(src, 2, target = src))
		switch(attack_cycle)
			//Attempt to spawn some pins
			if(-INFINITY to 3)
				DecendingPin(trg)
			if(4)
				DragonVortex()
			if(5)
				GatheringRain(trg)
			if(6)
				WrathScale(trg)
				attack_cycle = 0
	YINGLONG_STANCE_CHANGE(YINGLONG_IDLE)
	can_act = TRUE
	attack_cycle++

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/DecendingPin(trg)
	var/obj/projectile/flowerpin/first = DeferProjectile(/obj/projectile/flowerpin/slow, trg, get_turf(src), 8)
	var/first_angle = WRAP(first.Angle - 20, 0 ,360)
	var/angle_change = 0
	for(var/iteration = 1 to 4)
		var/obj/projectile/flowerpin/new_pin = DeferProjectile(pin_projectile_type, trg, get_turf(src), 8 + iteration)
		new_pin.set_angle(WRAP(first_angle + angle_change, 0 ,360))
		//-20, -10, 10, 20
		if(iteration != 2)
			angle_change += 10
			continue
		angle_change += 20

	do_after(src, 8, target = src)

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/GatheringRain(trg)
	var/attack_charges = flower_pins
	for(var/cycle = 1 to attack_charges)
		if(!do_after(src, 2, target = src))
			break
		if(!trg)
			trg = FindTarget()
			if(!trg)
				break
			continue
		DeferProjectile(pin_projectile_type, trg, get_turf(src))

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/WrathScale(trg)
	levin_a.Perform(null, src, arena_turfs)

	var/flower_charges = max(360 / 30, round(flower_pins / 2))
	var/fire_angle = 180
	if(flower_charges >= 1)
		for(var/iteration = 1 to flower_charges)
			var/obj/projectile/flowerpin/hellpin = DeferProjectile(pin_projectile_type, trg, get_turf(src), 10 + (iteration * 2))
			fire_angle = WRAP(fire_angle + 30, 0 ,360)
			hellpin.set_angle(fire_angle)

	do_after(src, 10 + (flower_charges * 2), target = src)

	flower_pins = 0

/*--------\
|LOGISTICS|
\--------*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/RetrieveArenaTurfs(turf/center)
	. = list()
	for(var/turf/T in  view(9, center))
		if(isfloorturf(T))
			. += T

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/Teleport()
	arena_turfs.Cut()
	reloc_a.Perform(null,src)
	arena_turfs = RetrieveArenaTurfs(get_turf(src))

/*--------\
|ABILITIES|
\--------*/
/mob/living/simple_animal/hostile/abnormality/yinglong/proc/DragonVortex()
	YINGLONG_STANCE_CHANGE(YINGLONG_SPARKS)
	do_after(src, 1.2 SECONDS, target = src)
	var/our_turf = get_turf(src)
	if(!our_turf)
		return
	var/list/directions = GLOB.cardinals.Copy()
	var/list/direction_pattern = FormatPattern()
	var/list/norm_pattern = FormatPatternOrbit()
	var/list/seco_pattern = FormatPatternOrbit(3, TRUE)

	for(var/i = 1 to 4)
		/*
		* Difficult to read but basically thesea
		* two dragon vortexes orbit around
		* the dragon with one orbiting clockwise
		* and the other counter clockwise
		* -IP
		*/
		if(ISEVEN(i))
			var/list/use_pattern = norm_pattern
			var/turf/vortex_turf = our_turf
			if(i == 4)
				use_pattern = seco_pattern
				vortex_turf = locate(x, y - 3, z)
			new /obj/effect/ambient_danger/dragonvortex(vortex_turf, faction, use_pattern)
			continue

		var/turf/deploy = get_step(our_turf, pop(directions))
		if(deploy.density)
			continue
		new /obj/effect/ambient_danger/dragonvortex(deploy, faction, direction_pattern)
	return direction_pattern

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/FormatPattern()
	var/list/return_list = list()
	//Gimme our cords. We arnt going to check anything on the turfs so just cords.
	var/originx = x
	var/originy = y
	for(var/cycle = 1 to 4)
		var/offsetx = 0
		var/offsety = 0
		var/turn_rate = 0
		var/initial_direction = NORTH
		switch(cycle)
			//South
			if(2)
				initial_direction = SOUTH
				offsety = -1
			//East
			if(3)
				initial_direction = EAST
				offsetx = 1
			//West
			if(4)
				initial_direction = WEST
				offsetx = -1
			//North
			else
				offsety = 1
		var/path_direction = initial_direction
		for(var/iteration = 1 to 5)
			var/x_tag = originx + offsetx
			var/y_tag = originy + offsety
			var/turf_tag = "[x_tag],[y_tag]"
			return_list += turf_tag
			turn_rate = turn_rate + 45
			path_direction = turn(initial_direction,turn_rate)
			return_list[turf_tag] = path_direction
			if(path_direction == NORTH || path_direction == NORTHWEST  || path_direction ==  NORTHEAST)
				offsety++
			if(path_direction == SOUTH  || path_direction ==  SOUTHWEST  || path_direction ==  SOUTHEAST)
				offsety--
			if(path_direction == EAST  || path_direction ==  NORTHEAST  || path_direction ==  SOUTHEAST)
				offsetx++
			if(path_direction == WEST  || path_direction ==  NORTHWEST  || path_direction ==  SOUTHWEST)
				offsetx--

	return return_list

/mob/living/simple_animal/hostile/abnormality/yinglong/proc/FormatPatternOrbit(pattern_size = 1, inverse = FALSE)
	var/list/return_list = list()
	var/iteration_mod = 2 * pattern_size
	var/originx = x
	var/originy = y
	//First tile is on us
	var/turf_tag = "[originx],[originy]"
	var/initial_path_dir = SOUTH
	return_list += turf_tag
	return_list[turf_tag] = initial_path_dir
	//Second tile is lower right
	//Redundant but good enough.
	var/path_direction = initial_path_dir
	/*
	* Difficult to explain but ill try -IP
	* The start variables are a initial offset
	* to place the coords we want in the lower right.
	* The next turf x is the coords we will hit next.
	*/
	var/offsetx = (inverse ? -1 : 1) * pattern_size
	var/offsety = -1 * pattern_size
	var/next_turf_x = originx + offsetx
	var/next_turf_y = originy + offsety
	var/next_turf_tag = "[next_turf_x],[next_turf_y]"
	//We will cycle 4 times and make 2 iterations for a total of 8
	for(var/cycle = 1 to 4)
		//These offsets replace the above offset
		offsetx = 0
		offsety = 0
		//We turn the path 90 degrees in either direction to get EAST or WEST
		path_direction = turn(path_direction, path_direction + (inverse ? 90 : -90))
		//If we go these directions offset the coords accordingly.
		if(path_direction == NORTH)
			offsety = 1
		if(path_direction == SOUTH)
			offsety = -1
		if(path_direction == EAST)
			offsetx = 1
		if(path_direction == WEST)
			offsetx = -1
		for(var/iteration = 1 to iteration_mod)
			//Add the tag to the list as a readable coordnate
			return_list += next_turf_tag
			//Assign a direction for the coord that a reader will obey
			return_list[next_turf_tag] = path_direction
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(locate(next_turf_x,next_turf_y,z), path_direction)
			/*
			* Add the offsets for the next coord we mess with.
			* Theoretically this SHOULD do 2 of each direction
			* and create a full square.
			*/
			next_turf_x += offsetx
			next_turf_y += offsety
			next_turf_tag = "[next_turf_x],[next_turf_y]"
	return return_list

/*--------\
|Levinfall|
\--------*/

/obj/effect/proc_holder/ability/levinfall
	name = "Levinfall"
	desc = "Apply fragile to creatures standing in a checker pattern around you. \"Cast away the land.\""
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 10 SECONDS

/obj/effect/proc_holder/ability/levinfall/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = user
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/levinfall/Perform(target, mob/living/user, area_list)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	if(!user)
		return
	if(!area_list || !length(area_list))
		area_list = view(get_turf(user))
	ToggleAct(user,FALSE)

	Fall(user, area_list)

	AbnoInteraction(user)
	ToggleAct(user,TRUE)

/obj/effect/proc_holder/ability/levinfall/proc/Fall(mob/living/dragon, list/arena_turfs)
	if(!dragon || !arena_turfs)
		return
	for(var/iteration = 1 to 2)
		var/attack_turfs = list()
		for(var/turf/T in arena_turfs)
			var/is_checkerboard = GET_CHECKERBOARD_MAP(T.x,T.y)
			//Should be checker pattern
			if(iteration == 1 && is_checkerboard)
				continue
			if(iteration == 2 && !is_checkerboard)
				continue
			//Find a way to just make this a damaging effect
			attack_turfs += T
			FlickOnAtom(T,'icons/effects/cult_effects.dmi',"floorglow_looping",2 SECONDS)
		if(!do_after(dragon, 2 SECONDS, target = dragon))
			break
		for(var/turf/damage_loc in attack_turfs)
			for(var/mob/living/L in damage_loc)
				if(IsPartOfCreature(dragon, L))
					continue
				L.apply_lc_rupture(2)
			new /obj/effect/temp_visual/lightningstrike(damage_loc)

//Think about moving this up from subtype to root -IP
/obj/effect/proc_holder/ability/levinfall/proc/IsPartOfCreature(creature, part)
	if(part == creature)
		return TRUE
	if(istype(part, /mob/living/simple_animal/projectile_blocker_dummy))
		var/mob/living/simple_animal/projectile_blocker_dummy/pbd = part
		if(pbd.parent == creature)
			return TRUE
/*
/obj/effect/proc_holder/ability/levinfall/AbnoInteraction(user)
	if(istype(user, /mob/living/simple_animal/hostile/abnormality/yinglong))
		var/mob/living/simple_animal/hostile/abnormality/yinglong/dragon = user
*/

/*-------\
|Relocate|
\-------*/

/obj/effect/proc_holder/ability/relocate
	name = "relocate"
	desc = "Move to another department center."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 10 SECONDS

/obj/effect/proc_holder/ability/relocate/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = user
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/relocate/Perform(target, mob/living/user)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	if(!user)
		return
	ToggleAct(user,FALSE)

	Teleport(user)

	AbnoInteraction(user)
	ToggleAct(user,TRUE)

/obj/effect/proc_holder/ability/relocate/proc/Teleport(mob/living/user)
	var/turf/target_turf = FindDestination(user)
	if(!target_turf)
		return
	var/obj/effect/temp_visual/decoy/egress = new(get_turf(user), user)
	animate(egress, pixel_z = 128, alpha = 0, time = 5)

	user.pixel_z = 128
	user.alpha = 0
	user.density = FALSE

	user.forceMove(target_turf)
	sleep(5 SECONDS)
	user.visible_message(span_danger("The ceiling dissapears and [user] leans down from the sky!"))
	animate(user, pixel_z = 0, alpha = 255, time = 10)
	sleep(10)
	var/obj/effect/temp_visual/decoy/D = new(target_turf, user)
	animate(D, alpha = 0, transform = matrix()*2, time = 5)
	user.density = TRUE

	//Cleaner Code Toss meatbags aside
	for(var/mob/living/carbon/human/H in range(1, target_turf))
		if(H.stat >= SOFT_CRIT)
			continue
		user.visible_message("[user] tosses [H] out of the way!")
		H.deal_damage(10, RED_DAMAGE, user)

		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(!H.anchored)
			H.throw_at(throw_target, rand(6, 10), 18, H)

/obj/effect/proc_holder/ability/relocate/proc/FindDestination(mob/living/user)
	var/list/teleport_options = GLOB.department_centers
	if(!length(teleport_options))
		return
	return pick(teleport_options)

/*-------------\
|Ambient Danger|
\-------------*/
/obj/effect/ambient_danger/dragonvortex
	name = "dragon vortex"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects32x48.dmi'
	icon_state = "drgvortex"
	max_hits = 10
	damage = 50
	damage_type = WHITE_DAMAGE

/obj/effect/ambient_danger/dragonvortex/Suffer(atom/A)
	. = ..()
	if(!.)
		return
	if(iscarbon(A))
		var/mob/living/carbon/human/H = A
		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(!H.anchored)
			H.throw_at(throw_target, 4, 5, H)


#undef GET_CHECKERBOARD_MAP
#undef YINGLONG_STANCE_CHANGE
#undef YINGLONG_IDLE
#undef YINGLONG_BARK
#undef YINGLONG_SPARKS
