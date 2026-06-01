//A tribute to, and Designed mostly by InsightfulParasite, our lovely spriter. Coded by Kirie Saito.
/mob/living/simple_animal/hostile/abnormality/shrimp_exec
	name = "Shrimp Association Executive"
	desc = "A shrimp in a snazzy suit."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "executive"
	icon_living = "executive"
	core_icon = "shrimpexec_egg"
	portrait = "shrimp_executive"
	faction = list("shrimp")
	speak_emote = list("burbles")
	threat_level = WAW_LEVEL
	can_breach = TRUE
	start_qliphoth = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 30,
		ABNORMALITY_WORK_INSIGHT = 30,
		ABNORMALITY_WORK_ATTACHMENT = 30,
		ABNORMALITY_WORK_REPRESSION = -100,	//He's a snobby shrimp dude.
	)
	retreat_distance = 3
	minimum_distance = 4
	maxHealth = 700
	health = 700
	work_damage_amount = 11
	work_damage_type = WHITE_DAMAGE	//He insults you
	chem_type = /datum/reagent/abnormality/sin/pride

	ego_list = list(
		/datum/ego_datum/weapon/executive,
		/datum/ego_datum/armor/executive,
	)
	gift_type =  /datum/ego_gifts/executive

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/wellcheers = 1.5, // I... if you ever get a zayin this far in, good luck.
	)

	observation_prompt = "You sit in an office decorated with shrimp-related memorabilia. <br>\
		Various trophies and medals and other trinkets with shrimp on them. <br>A PHD in shrimpology printed on printer paper is displayed prominantly on the wall. <br>\
		\"Enjoying my collection? <br>I played college ball in Shrimp-Corp's nest, you know.\" <br>\
		A delicious looking shrimp in a snazzy suit sits before you in an immaculate office chair. <br>\
		\"But where are my manners... <br>Why don't you enjoy some of our finest locally produced champagne?\" <br>\
		The shrimp offers you a champagne glass full of... Something. <br>\
		It looks and smells like wellcheers grape soda. It's soda. <br>\
		You can even see the can's label torn off and stuck on the side. <br>Will you drink it?"
	observation_choices = list(
		"Drink the soda" = list(TRUE, "Before you can make a choice, two gigantic and heavily armed shrimp guards bust in through the door. <br>\
			They hold you down and force you to drink the soda, and you fall asleep... <br>... <br>Somewhere in the distance, you hear seagulls."),
		"Refuse" = list(TRUE, "Before you can make a choice, two gigantic and heavily armed shrimp guards bust in through the door. <br>\
			They hold you down and force you to drink the soda, and you fall asleep... <br>... <br>Somewhere in the distance, you hear seagulls."),
	)

	var/liked
	var/happy = TRUE
	pet_bonus = "blurbles" //saves a few lines of code by allowing funpet() to be called by attack_hand()
	var/hint_cooldown
	var/hint_cooldown_time = 30 SECONDS
	var/list/cooldown = list(
		"Stop meandering around and get to work!",
		"I can be quite patient at times, but you are beginning to test me!",
		"The service here can be dreadful at times. Why don't you just make yourself useful?",
	)

	var/list/instinct = list(
		"I am getting quite old, and my back is hurting me. Could you send a chiropractor to my office immediately?",
		"I am quite peckish, could you send me a charcuterie board?",
		"Could you get me a glass of pinot noir, please?",
		"Fetch me a bowl of shrimp fried rice? I'm looking to try this delicacy made by your finest shrimp chefs.",
		"Ah, I forgot to take my daily medication, could you bring it to me?",
	)

	var/list/insight = list(
		"Get me my phonograph, I would like to listen to Moonlight Sonata, 1st Movement.",
		"The plants in my office are dying, could you water them please?",
		"It is rather dull, with all the negotiations that we have been doing. Could you get me the morning crossword?",
		"I've noticed some dust collecting on the bookshelves, could you get someone to dust it?",
		"Ah, I seem to have spilt my wine, could you get it cleaned up?",
		"I think my suit needs to be dry-cleaned. Take it and go.",

	)

	var/list/attachment = list(
		"You know, I had this brand new deal that I am setting up. Care to listen sometime?",
		"I was wondering if YOU had any good business offers. It would be nice to hear from a fellow intellectual. Stop by and tell me sometime.",
		"Come, pull up a glass, old friend. Let's drink to a good deal!",
		"I'm thinking about buying stocks for my portfolio, what do you recommend I invest in?",
		"Got a moment to chat about something important? Let's catch up over a cup of coffee and discuss some potential business moves. Your insights are always valuable to me.",
		"I was wondering if you might be available to join me for a brief tête-à-tête over a cup of tea. Come on by when you are available.",
	)

	//A list of shit that it can create. Yes, it includes ego. How did a shrimp get ego? IDFK. I guess his company makes it.
	//Could diversify clerks I guess.
	var/list/dispenseitem= list(
		/obj/item/grenade/spawnergrenade/shrimp,
		/obj/item/grenade/spawnergrenade/shrimp/super,
		/obj/item/ego_weapon/ranged/pistol/soda,
		/obj/item/ego_weapon/ranged/sodasmg,
		/obj/item/ego_weapon/ranged/sodashotty,
		/obj/item/ego_weapon/ranged/sodarifle,
		/obj/item/clothing/suit/armor/ego_gear/zayin/soda,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers_red,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers_white,
	)

	var/obj/effect/proc_holder/ability/aimed/firingsquad/shootems
	var/fire_squad_cd = 0
	var/fire_squad_delay = 15 SECONDS

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/Initialize(mapload)
	. = ..()
	var/list/units_to_add = list(
		/mob/living/simple_animal/hostile/shrimp_soldier = 5,
		/mob/living/simple_animal/hostile/shrimp = 2
		)
	AddComponent(/datum/component/ai_leadership, units_to_add, 7, TRUE, TRUE)
	shootems = new()
	src.AddSpell(shootems)

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/handle_automated_action()
	. = ..()
	if(IsContained() || stat == DEAD || client)
		return
	if(target)
		/*
		* Okay so follow me here. The absolute of
		* their x minus their enemies x would be 1
		* if they are south of eachother.
		*/
		if(fire_squad_cd < world.time && (abs(x - target.x) < 2 || abs(y - target.y) < 2))
			fire_squad_cd = world.time + fire_squad_delay
			shootems.Perform(target,src)

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/WorkChance(mob/living/carbon/human/user, chance)
	if(happy)
		chance+=30
	return chance

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	var/turf/dispense_turf = get_step(src, pick(1,2,4,5,6,8,9,10))
	var/gift = pick(dispenseitem)
	new gift(dispense_turf)
	say("Here you are, my dear friend. High-quality firepower courtesy of shrimpcorp.")
	return

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/ZeroQliphoth(mob/living/carbon/human/user)
	datum_reference.qliphoth_change(1)
	return ..()

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/BreachEffect(mob/living/carbon/human/user, breach_type)
	pissed()
	return ..()

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/AttemptWork(mob/living/carbon/human/user, work_type)
	if(work_type == liked || !liked)
		happy = TRUE
		user.client?.give_award(/datum/award/achievement/abno/shrimp_assistant, user)
	else
		happy = FALSE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	liked = pick(ABNORMALITY_WORK_INSTINCT, ABNORMALITY_WORK_INSIGHT, ABNORMALITY_WORK_ATTACHMENT)
	switch(liked)
		if(ABNORMALITY_WORK_INSTINCT)
			say(pick(instinct))
		if(ABNORMALITY_WORK_INSIGHT)
			say(pick(insight))
		if(ABNORMALITY_WORK_ATTACHMENT)
			say(pick(attachment))

/mob/living/simple_animal/hostile/abnormality/shrimp_exec/proc/pissed()
	var/turf/W = pick(GLOB.department_centers)
	forceMove(W)
	var/iter = 1
	var/list/landing_area = block(W.x-1,W.y-1,W.z,W.x+1,W.y+1,W.z) - W
	for(var/turf/T in landing_area)
		var/obj/structure/closet/supplypod/extractionpod/pod = new()
		pod.explosionSize = list(0,0,0,0)
		if(iter > 5)
			new /mob/living/simple_animal/hostile/shrimp(pod)
		else
			new /mob/living/simple_animal/hostile/shrimp_soldier(pod)
		iter++

		new /obj/effect/pod_landingzone(T, pod)
		stoplag(2)

//repeat lines
/mob/living/simple_animal/hostile/abnormality/shrimp_exec/funpet()
	if(!liked)
		return
	if(hint_cooldown > world.time)
		say(pick(cooldown))
		return
	hint_cooldown = world.time + hint_cooldown_time
	switch(liked)
		if(ABNORMALITY_WORK_INSTINCT)
			say(pick(instinct))
		if(ABNORMALITY_WORK_INSIGHT)
			say(pick(insight))
		if(ABNORMALITY_WORK_ATTACHMENT)
			say(pick(attachment))
	return

/* Shrimpo boys */
/mob/living/simple_animal/hostile/shrimp
	name = "wellcheers corp liquidation intern"
	desc = "A shrimp that is extremely hostile to you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers"
	icon_living = "wellcheers"
	icon_dead = "wellcheers_dead"
	faction = list("shrimp")
	health = 400
	maxHealth = 400
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 24
	melee_damage_upper = 27
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "punches"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/bite.ogg'
	speak_emote = list("burbles")
	butcher_results = list(/obj/item/stack/spacecash/c50 = 1)
	guaranteed_butcher_results = list(/obj/item/stack/spacecash/c10 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/shrimple_simple = 4)

/mob/living/simple_animal/hostile/shrimp/Initialize()
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		del_on_death = FALSE

//You can put these guys about to guard an area.
/mob/living/simple_animal/hostile/shrimp_soldier
	name = "wellcheers corp hired liquidation officer"
	desc = "A shrimp that is there to guard an area."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_bad"
	icon_living = "wellcheers_bad"
	icon_dead = "wellcheers_bad_dead"
	faction = list("shrimp")
	health = 500	//They're here to help
	maxHealth = 500
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 14
	melee_damage_upper = 18
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "punches"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/bite.ogg'
	speak_emote = list("burbles")
	ranged = 1
	retreat_distance = 2
	minimum_distance = 3
	casingtype = /obj/item/ammo_casing/caseless/ego_shrimpsoldier
	projectilesound = 'sound/weapons/gun/pistol/shot_alt.ogg'
	butcher_results = list(/obj/item/stack/spacecash/c50 = 1)
	guaranteed_butcher_results = list(/obj/item/stack/spacecash/c20 = 1, /obj/item/stack/spacecash/c1 = 5)
	silk_results = list(/obj/item/stack/sheet/silk/shrimple_simple = 8, /obj/item/stack/sheet/silk/shrimple_advanced = 4)

/mob/living/simple_animal/hostile/shrimp_soldier/Initialize()
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		casingtype = /obj/item/ammo_casing/caseless/ego_shrimpsoldier/city
		del_on_death = FALSE

/obj/item/ammo_casing/caseless/ego_shrimpsoldier/city
	pellets = 3

/mob/living/simple_animal/hostile/shrimp_soldier/friendly
	name = "wellcheers corp assault officer"
	icon_state = "wellcheers_soldier"
	icon_living = "wellcheers_soldier"
	icon_dead = "wellcheers_soldier_dead"
	faction = list("neutral", "shrimp")

/obj/item/grenade/spawnergrenade/shrimp
	name = "instant shrimp task force grenade"
	desc = "A grenade used to call for a shrimp task force."
	icon_state = "shrimpnade"
	spawner_type = /mob/living/simple_animal/hostile/shrimp_soldier/friendly
	deliveryamt = 3

/obj/item/grenade/spawnergrenade/shrimp/super
	deliveryamt = 7	//Just randomly get double money.

/obj/item/grenade/spawnergrenade/shrimp/hostile
	spawner_type = list(/mob/living/simple_animal/hostile/shrimp, /mob/living/simple_animal/hostile/shrimp_soldier) //Gacha Only, just put it here with the other shrimp grenades.

/*--------------------------\
|Unique Firing Squad Ability|
\--------------------------*/
/obj/effect/proc_holder/ability/aimed/firingsquad
	name = "Firing Squad"
	desc = "Group from up to 5 shrimp soldiers from the surrounding area to preform a firing line in the direction you click."
	action_icon_state = "general_shadow0"
	action_background_icon_state = "bg_cult"
	base_icon_state = "general_shadow"
	cooldown = 15 SECONDS
	var/list/soldiers = list()

/obj/effect/proc_holder/ability/aimed/firingsquad/Perform(target, user)
	. = ..()
	//Turf Handling
	var/our_turf = get_turf(user)
	var/trg_turf = get_turf(target)
	if(!our_turf || !trg_turf)
		stack_trace("ShrimpleError1:ability/aimed/firingsquad")
		return

	var/direct = get_cardinal_dir(our_turf, trg_turf)
	var/turf/focus_turf = get_step(our_turf,direct)
	if(!focus_turf)
		stack_trace("ShrimpleError2:ability/aimed/firingsquad")
		return
	if(focus_turf.density)
		return

	var/focx = focus_turf.x
	var/focy = focus_turf.y
	var/focz = focus_turf.z
	var/xoffset1 = 0
	var/xoffset2 = 0
	var/yoffset1 = 0
	var/yoffset2 = 0

	//Gimme those offsets for the SQUARE
	if(direct == EAST || direct == WEST)
		yoffset1 = -2
		yoffset2 = 2
	if(direct == NORTH || direct == SOUTH)
		xoffset1 = -2
		xoffset2 = 2

	var/list/firing_line = block(focx+xoffset1,focy+yoffset1,focz,focx+xoffset2,focy+yoffset2,focz)

	for(var/turf/open_turf in firing_line)
		if(istype(open_turf, /turf/open) && !open_turf.density)
			continue
		firing_line -= open_turf
	var/line_length = length(firing_line)
	if(!line_length)
		return

	for(var/mob/living/simple_animal/hostile/shrimp_soldier/srimp in orange(6,get_turf(user)))
		if(srimp.client || srimp.AIStatus != AI_ON)
			//I take orders from a higher authority.
			continue
		if(length(soldiers) > line_length)
			break
		RegisterMob(srimp)

	if(length(soldiers) < line_length)
		firing_line.Cut(1,2)

	//We give Shrimp Executive the microphone.
	var/mob/living/caster = user

	if(length(soldiers) < 2)
		caster.say("Rea-, oh we dont have enough...")
		UnregisterAll()
		return

	var/list/temp_firing = firing_line.Copy()
	for(var/mob/living/simple_animal/hostile/shrimp_soldier/srimple in soldiers)
		if(!length(temp_firing))
			break
		var/turf/T = pop(temp_firing)
		walk_to(srimple,T)

	if(ishostile(caster) && !caster.client)
		var/mob/living/simple_animal/hostile/H = caster
		walk(caster,0)
		H.toggle_ai(AI_OFF)
	caster.say("Ready...")
	if(do_after(caster, 2 SECONDS, target = caster) && !QDELETED(caster))
		caster.say("FIRE!")
		if(do_after(caster, 1, target = caster) && !QDELETED(caster))
			Shootems(direct, firing_line)
	if(ishostile(caster) && !caster.client && !QDELETED(caster))
		var/mob/living/simple_animal/hostile/H = caster
		H.toggle_ai(AI_ON)
	UnregisterAll()

/obj/effect/proc_holder/ability/aimed/firingsquad/Destroy()
	UnregisterAll()
	return ..()

/obj/effect/proc_holder/ability/aimed/firingsquad/proc/Shootems(direct, list/correct_turfs)
	for(var/mob/living/simple_animal/hostile/shrimp_soldier/sri in soldiers)
		if(QDELETED(sri))
			continue
		var/turf/shrimple_geometry = get_turf(sri)
		if(!(shrimple_geometry in correct_turfs))
			UnregisterMob(sri)
			continue
		var/turf/shoot_turf = get_ranged_target_turf(get_turf(sri),direct,3)
		sri.Shoot(shoot_turf)

/obj/effect/proc_holder/ability/aimed/firingsquad/proc/RegisterMob(mob/living/L)
	if(!L)
		return
	RegisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob), override = TRUE)
	soldiers += L
	if(ishostile(L))
		var/mob/living/simple_animal/hostile/H = L
		H.toggle_ai(AI_OFF)

/obj/effect/proc_holder/ability/aimed/firingsquad/proc/UnregisterMob(mob/living/L)
	if(!L)
		return
	UnregisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	soldiers -= L
	if(ishostile(L))
		var/mob/living/simple_animal/hostile/H = L
		H.toggle_ai(AI_ON)

/obj/effect/proc_holder/ability/aimed/firingsquad/proc/UnregisterAll()
	for(var/mob/living/L in soldiers)
		UnregisterMob(L)
	soldiers.Cut()
