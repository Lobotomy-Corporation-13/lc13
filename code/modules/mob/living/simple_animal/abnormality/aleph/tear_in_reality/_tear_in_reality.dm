//Ah, sweet! Man-made horrors beyond my comprehension!
/mob/living/simple_animal/hostile/abnormality/reality_tear
	name = "Tear in Reality"
	desc = "Something is lost, strangely, you feel like you recognize it."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi'
	icon_state = "reality_tear"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_x = -32
	del_on_death = TRUE
	layer = ABOVE_OPEN_TURF_LAYER

	maxHealth = 5000
	health = 5000

	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = -2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1)
	stat_attack = HARD_CRIT
	faction = list("hostile")
	can_breach = TRUE
	threat_level = ALEPH_LEVEL
	start_qliphoth = 2

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 0,
		ABNORMALITY_WORK_INSIGHT = list(45, 25, 10, 0, 0),
		ABNORMALITY_WORK_ATTACHMENT = list(0, 0, 30, 50, 65),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 45, 45, 45),
	)
	work_damage_amount = 20
	work_damage_type =  WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/tir_claws,
		/datum/ego_datum/armor/tir_mask,
	)
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

///////////////CURRENTLY DOESN'T WORK/////////////////////////////////////

	var/spawn_progress = 18
	var/list/spawned_mobs = list()
	var/producing = FALSE

/mob/living/simple_animal/hostile/abnormality/reality_tear/proc/Produce()
	if(producing || stat == DEAD)
		return
	producing = TRUE
	SLEEP_CHECK_DEATH(6)
	visible_message(span_danger("Something rises from the static..."))
	for(var/i = 5 to 10)
		var/turf/T = get_step(get_turf(src), pick(0, EAST))
		var/picked_mob = /mob/living/simple_animal/hostile/_tir_cheers
		new picked_mob(T)

	//	if(prob(75)) ///Spawns Interdimensional Static 25% of the time, can lower to smth like 10% if needed
	//		picked_mob = pick() ///PUT YOUR ENEMIES HERE

	//	var/mob/living/simple_animal/hostile/ordeal/nb = new picked_mob(T)
	//	spawned_mobs += nb
	//	if(ordeal_reference)
	//		nb.ordeal_reference = ordeal_reference
	//		ordeal_reference.ordeal_mobs += nb
	//	SLEEP_CHECK_DEATH(1)
	SLEEP_CHECK_DEATH(2)
	icon = initial(icon)
	producing = FALSE
	spawn_progress = -10 // Large Cooldown

//////////////////////////////////////////////////////////////////////////

var/list/worked = list()

/mob/living/simple_animal/hostile/abnormality/reality_tear/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/reality_tear/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/reality_tear/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)

	//Code is copied directly from 680 KHz.
	if(!(user in worked))
		worked+=user
		new /obj/item/paper/fluff/plea(get_turf(user))

/mob/living/simple_animal/hostile/abnormality/reality_tear/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	var/turf/T = pick(GLOB.department_centers)
	if(breach_type != BREACH_MINING)
		forceMove(T)

/mob/living/simple_animal/hostile/abnormality/reality_tear/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

if(work_type == ABNORMALITY_WORK_INSTINCT)
	span_danger "You plunge your arm into the static, it hurts."
	span_danger "You pull out a paper, it thanks you for personally guiding them."
	datum_reference.qliphoth_change(-2) //Insta breaches & special message on Instinct

////////////////////////////////////////////////////////OPEN SOURCE FLUFF PAPER//////////////////////////////////
/obj/item/paper/fluff/plea
	name = "Strange Note"
	info = {"All that enters exits elsewhere.<br>
	The worlds align at the white noise intersection.<br>
	All that is needed for us to find eachother, are directions.<br>
	Please give us directions to the 13th Station.<br>
	Please give us directions to the "City".<br>
	Please give us directions to Lobotomy Corporation.<br>
	code/modules/mobs/living/simple_animal/abnormality/aleph/tear_in_reality<br>
	"}

