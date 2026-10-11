
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
	smart_pathing = TRUE
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
	var/identifier = AddIdentifier(get_turf(src))
	if(!SSflowfield.FindMap(identifier))
		SSflowfield.MakeMyMap(src, identifier)
	active = TRUE
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/baromez/proc/ShareMap()
	var/our_identifier = AddIdentifier(get_turf(src))
	for(var/L in followers)
		if(istype(L, /mob/living/simple_animal/hostile/baroputian))
			var/mob/living/simple_animal/hostile/baroputian/I = L
			I.GrabFlowMap(our_identifier)

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
		entity.GrabFlowMap(AddIdentifier(get_turf(src)))
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



/*-----\
|Vitals|
\-----*/

/mob/living/simple_animal/hostile/baroputian/Initialize()
	. = ..()
	AddComponent(/datum/component/swarming)

/mob/living/simple_animal/hostile/baroputian/Destroy()
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

/mob/living/simple_animal/hostile/baroputian/WalkWithMap()
	if(stat == DEAD || !can_act) // Dead
		return FALSE
	if(!target)
		if(world_map && (held_item || isliving(pulling) || behavior_mode == LILI_BEHAVIOR_MODE_RETURN))
			var/list/walk_map = world_map.CheckMap("[x],[y]")
			if(length(walk_map))
				walk_path = walk_map.Copy()
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

#undef LILI_BEHAVIOR_MODE_STEAL
#undef LILI_BEHAVIOR_MODE_RETURN
#undef LILI_BEHAVIOR_MODE_ATTACK
