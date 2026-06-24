//That fucking flower that I hate, coded by Xeros, design by Jackfrost7157 on the LC13 discord with minor alterations by Xeros
/mob/living/simple_animal/hostile/abnormality/gossypium
	name = "Drenched Gossypium"
	desc = "A large, round cluster of white flowers, marred by patches of bloodstains. Its roots dangle beneath the cluster."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi'
	icon_state = "whitegossy"
	icon_living = "whitegossy"
	portrait = "drenched_gossypium"
	maxHealth = 1300
	health = 1300
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -12
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.2)
	ranged = TRUE
	melee_damage_lower = 10
	melee_damage_upper = 14
	ranged_cooldown_time = 3 //wtf was Jackfrost thinking giving this thing 5 max
	rapid_melee = 2.5
	move_to_delay = 4.5
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/abnormalities/fragment/attack.ogg'
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
		"Approach" = 0,
	)
	work_damage_amount = 5
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust

	ego_list = list(
		/datum/ego_datum/weapon/white_gossypium,
		/datum/ego_datum/armor/white_gossypium,
	)
	gift_type =  /datum/ego_gifts/white_gossypium //"Terrible EGO Gift", look inside
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS// Mediocre at worst

	observation_prompt = "A field of white, yet somehow dark flowers is ahead. <br>\
		The sky is red, the air windy and bleak. <br>\
		One giant flower flutters amidst the field. <br>\
		It resembles a person waving from afar."
	observation_choices = list(
		"Approach" = list(TRUE, "As you head for the giant flower, <br>\
			the smaller ones make way. <br>\
			They close up their petals as you pass, <br> \
			as if to bow down in respect. <br>\
			Once you arrived at the end, <br>\
			the giant flower drooped low to offer a present."),
		"Ignore it" = list(FALSE, "You look away and continue on your path. <br>\
			The massive flower begins shaking violently, perhaps in an attempt to catch your attention. <br>\
			It appears a tad unnatural, a tad unsettling. <br>\
			You steel yourself and escape the field of flowers."),
	)

	var/burst_cooldown
	var/burst_cooldown_time = 10 SECONDS



//WORK STUFF
/mob/living/simple_animal/hostile/abnormality/gossypium/AttemptWork(mob/living/carbon/human/user, work_type) //Code shamelessly yoinked from KQE
	if((work_type != "Approach"))
		return TRUE
	if(work_type == "Approach")
		if(!GiftUser(user, 18, 100))//always gives a gift
			to_chat(user, span_notice("The cluster of flowers pays you no mind as you approach."))
			return FALSE
		to_chat(user, span_notice("As you head for the giant flower, several smaller ones close their petals, as if bowing down in respect."))
		to_chat(user, span_notice("Once you arrived at the end, the giant flower drooped low to offer a present."))

/mob/living/simple_animal/hostile/abnormality/gossypium/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(50))
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/gossypium/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/gossypium/PostWorkEffect(mob/living/carbon/human/user, work_type)
	var/brooch = user.ego_gift_list[BROOCH]
	if((work_type != "Approach")) //No dropping qlip on Approach
		if(istype(brooch, /datum/ego_gifts/white_gossypium))
			if(prob(20))
				datum_reference.qliphoth_change(1)
		else
			if(prob(80))
				datum_reference.qliphoth_change(-1)



//BREACH STUFF
/mob/living/simple_animal/hostile/abnormality/gossypium/Initialize(mapload) //Code shamelessly yoinked from Nosferatu
	. = ..()
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0)

/mob/living/simple_animal/hostile/abnormality/gossypium/Life()
	. = ..()
	var/datum/component/bloodfeast/gathered_blood = GetComponent(/datum/component/bloodfeast)
	if(gathered_blood.blood_amount > 500)
		Enrage(gathered_blood)
		gathered_blood.blood_amount -= 750 //Prevent it from looping
	return

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/Enrage(datum/component/bloodfeast/bloodfeast_component)
	if(IsContained()) // No bricking the mob by Berzerking when we aren't supposed to.
		return
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/transform.ogg', 35, 8)
	icon_state = "redgossy"
	rapid_melee += 0.5 //Was gonna have this douche calm down after a while and not stack but it kept breaking so you'll just have to deal with the bastard snowballing

/mob/living/simple_animal/hostile/abnormality/gossypium/Move()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/Goto(target, delay, minimum_distance)
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/MoveToTarget(list/possible_targets)
	if(!can_act)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/DestroySurroundings()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/AttackingTarget(atom/attack_target)
	if(!can_act)
		return
	if(burst_cooldown <= world.time && prob(50))
		thornBurst()
		return ..()
	new /obj/effect/decal/cleanable/blood get_turf(target)
	if (istype(target, /mob/living))
		var/mob/living/H = target
		H.apply_lc_bleed(1)
		return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/AttackCondition(atom/attack_target)
	. = TRUE
	if(!Adjacent(attack_target)) //Prevents this bozo from getting Extendo-Arms after doing the burst
		return FALSE

/mob/living/simple_animal/hostile/abnormality/gossypium/OpenFire()
	if(!can_act)
		return

	ranged_cooldown = world.time + ranged_cooldown_time
	vineStab(target)

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/vineStab(atom/attack_target) //single target
	if(!can_act)
		return
	can_act = FALSE
	playsound(get_turf(src), 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	var/turf/T = get_turf(attack_target)
	SLEEP_CHECK_DEATH(1)
	new /obj/effect/temp_visual/vine(T, src)
	SLEEP_CHECK_DEATH(1)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/thornBurst() //expanding square in melee
	if(burst_cooldown > world.time)
		return
	burst_cooldown = world.time + burst_cooldown_time
	can_act = FALSE
	var/turf/origin = get_turf(src)
	playsound(origin, 'sound/abnormalities/ebonyqueen/strongcharge.ogg', 75, 0, 5)
	playsound(origin, 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	SLEEP_CHECK_DEATH(6)
	for(var/turf/T in spiral_range_turfs(2, origin))
		new /obj/effect/temp_visual/vine(T, src)
	SLEEP_CHECK_DEATH(5)
	can_act = TRUE



//VINE STUFF
/obj/effect/temp_visual/vine //Keeping this shit far away for organization purposes
	name = "thirsting vines"
	desc = "A target warning you of incoming pain"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	icon_state = "vines"
	duration = 6
	layer = RIPPLE_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.
	var/vine_damage = 25 //40 less BLACK Damage than Ebony
	var/mob/living/source //who made this, anyway


/obj/effect/temp_visual/vine/Initialize(mapload, new_source)
	. = ..()
	if(new_source)
		source = new_source
	addtimer(CALLBACK(src, PROC_REF(explode)), 0.4 SECONDS)

/obj/effect/temp_visual/vine/proc/explode()
	var/turf/target_turf = get_turf(src)
	if(!target_turf)
		return
	if(QDELETED(source) || source?.stat == DEAD || !source)
		return
	playsound(target_turf, 'sound/abnormalities/ebonyqueen/attack.ogg', 40, 0, 8)
	new /obj/effect/temp_visual/thornspike(target_turf)
	var/list/hit = source.HurtInTurf(target_turf, list(), damage = vine_damage, damage_type = BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, mech_damage = vine_damage/2, attack_type = (ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in hit)
		if(L.stat == DEAD || L.throwing)
			continue
		L.visible_message(span_userdanger("[src] knocks [L] away!"), span_userdanger("[src] knocks you away!"))
		var/turf/thrownat = get_ranged_target_turf(src, pick(GLOB.alldirs), 2)
		L.throw_at(thrownat, 1, 1, spin = TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
		L.apply_lc_bleed(3)
		new /obj/effect/decal/cleanable/blood get_turf(L)
	for(var/obj/vehicle/sealed/mecha/M in hit) //also damage mechs.
		for(var/O in M.occupants)
			var/mob/living/occupant = O
			to_chat(occupant, span_userdanger("Your [M.name] is struck by [src]!"))
	qdel(src)

/obj/effect/temp_visual/vine/Destroy()
	source = null
	return ..()
