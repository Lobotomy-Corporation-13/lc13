/mob/living/simple_animal/hostile/abnormality/tangle
	name = "Tangle"
	desc = "What seems to be a severed head laying in a tangle of hair."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "tangle"
	icon_living = "tangle"
	portrait = "tangle"
	maxHealth = 1600
	health = 1600
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 0		//Doesn't attack
	melee_damage_upper = 0
	rapid_melee = 2
	melee_damage_type = WHITE_DAMAGE
	stat_attack = HARD_CRIT
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 80,
		ABNORMALITY_WORK_INSIGHT = list(50, 50, 40, 40, 40),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 40, 40, 40),
		ABNORMALITY_WORK_REPRESSION = list(50, 50, 40, 40, 40),
	)
	work_damage_amount = 5
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth
	ego_list = list(
		/datum/ego_datum/weapon/rapunzel,
		/datum/ego_datum/armor/rapunzel,
	)
	gift_type =  /datum/ego_gifts/rapunzel
	abnormality_origin = ABNORMALITY_ORIGIN_WONDERLAB

	var/chosen
	var/instinct_count

/mob/living/simple_animal/hostile/abnormality/tangle/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/tangle/CanAttack(atom/the_target)
	return FALSE

//Grab a list of all agents and picks one
/mob/living/simple_animal/hostile/abnormality/tangle/Initialize()
	. = ..()
	var/list/potentialmarked = list()
	for(var/mob/living/carbon/human/L in GLOB.player_list)
		if(L.stat >= HARD_CRIT || L.sanity_lost || z != L.z) // Dead or in hard crit, insane, or on a different Z level.
			continue
		if(HAS_TRAIT(usr, TRAIT_WORK_FORBIDDEN)) //Don't get non agents
			continue
		potentialmarked += L.tag

	if(length(potentialmarked) <= 1) //If there's only one or none of you, then don't do it. I'm not that evil.
		return
	chosen = pick(potentialmarked)

/mob/living/simple_animal/hostile/abnormality/tangle/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	// If your'e the chosen, lower
	if(user.tag == chosen)
		datum_reference.qliphoth_change(-1)
		icon_state = "tangleawake"
		return

	if(work_type == ABNORMALITY_WORK_INSTINCT)
		instinct_count+=1
		if((instinct_count==3) || (instinct_count == 6))
			datum_reference.qliphoth_change(-1)
			icon_state = "tangleawake"

/mob/living/simple_animal/hostile/abnormality/tangle/BreachEffect()
	. = ..()
	icon_state = "tangle"
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	var/obj/structure/spreading/tangle_hair/hair = new(src)
	hair.RegisterMob(src)

// Hair turf
/obj/structure/spreading/tangle_hair
	gender = PLURAL
	name = "blonde hair"
	desc = "a patch of blonde hair."
	icon = 'icons/effects/effects.dmi'
	icon_state = "tanglehair"
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	max_integrity = 20
	base_icon_state = "tanglehair"
	var/rapid_growth_charges = 4
	var/mob/living/simple_animal/hostile/abnormality/tangle/connected_abno

/obj/structure/spreading/tangle_hair/Destroy()
	UnregisterMob()
	return ..()

/obj/structure/spreading/tangle_hair/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(expand)), 5 SECONDS)

/obj/structure/spreading/tangle_hair/expand()
	//It gets really fast for a few moments before slowing down
	var/spread_offset = (5 SECONDS) + rand(1,10) - ((1 SECONDS) * rapid_growth_charges)
	rapid_growth_charges--
	addtimer(CALLBACK(src, PROC_REF(expand)), spread_offset)
//	if(connected_abno.hair_list.len>=150)
// 		return
	return ..()

/obj/structure/spreading/tangle_hair/Crossed(atom/movable/AM)
	. = ..()
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.deal_damage(1, WHITE_DAMAGE, attack_type = (ATTACK_TYPE_ENVIRONMENT), blocked = H.run_armor_check(null, RED_DAMAGE))
		if(prob(10))
			H.Immobilize(5)
			to_chat(H, span_warning("You get caught in the hair!"))

/obj/structure/spreading/tangle_hair/PlaceStructure(turf/T)
	. = ..()
	if(!. || !istype(. , type))
		return
	var/obj/structure/spreading/tangle_hair/A = .
	if(connected_abno)
		A.RegisterMob(connected_abno)

/obj/structure/spreading/tangle_hair/play_attack_sound(damage_amount, damage_type = BRUTE)
	playsound(loc, 'sound/creatures/venus_trap_hit.ogg', 60, TRUE)

//Signal Stuff
/obj/structure/spreading/tangle_hair/proc/RegisterMob(mob/living/L)
	if(!L)
		return
	if(!istype(L, /mob/living/simple_animal/hostile/abnormality/tangle))
		return
	connected_abno = L
	RegisterSignal(connected_abno, list(COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob))

/obj/structure/spreading/tangle_hair/proc/UnregisterMob()
	if(!connected_abno)
		return
	UnregisterSignal(connected_abno, list(COMSIG_PARENT_QDELETING))
	connected_abno = null
	SelfDestruct()
