/mob/living/simple_animal/hostile/limbus_abno/queen_bee
	true_name = "Queen Bee"
	maxHealth = 3500
	health = 3500 //A lot of HP due to not really being strong by itself, primarily relying on minions.
	pixel_x = -8
	base_pixel_x = -8
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	attack_sound = 'sound/weapons/bite.ogg'
	death_sound = 'sound/abnormalities/bee/death.ogg'
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/bee_egg,
	/datum/action/cooldown/limbus_abno_action/emit_spores,
	/datum/action/cooldown/bee_speech,
	/datum/action/cooldown/bee_swap)
	original_abno = /mob/living/simple_animal/hostile/abnormality/queen_bee
	abno_additional_instructions = "You like instinct, insight and attachment. You want the hive to expand, that requires food, and a lot of it. \
	Your mood improves the more meat there is in your surroundings, as your reign lives and dies on food. You can create workers from an egg and enough food, but that process is inefficient. \
	If your mood is low enough, you may forcefully try to get new soldiers by emitting infectious spores that will use their host to feed themselves."

	hunger_loss = 10
	kickstart_timer = 5 MINUTES
	hunger_bar = 100
	diet_list = list(/obj/item/food/meat) //A surprisingly simple diet for a WAW.
	diet_value  = 30
	desire_on_eat = 10
	desire_on_pet = 5
	rep_desire_gain = -5 //Actively attacking her will trigger the spore if done too much. Supressing her with fast weapons is a terrible idea.

	insight_cooldown_time = 3 MINUTES
	liked_objects_list = list(/obj/item/food/meat)
	liked_objects_value = 5


	ego_list = list(
		/datum/ego_datum/weapon/hornet,
		/datum/ego_datum/weapon/tattered_kingdom,
		/datum/ego_datum/armor/hornet,
	)

/mob/living/simple_animal/hostile/limbus_abno/queen_bee/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("queen_bee_root"))

///More or less the same spores as the original queen bee, with the main difference that it creates the special controllable bees.
/mob/living/simple_animal/hostile/limbus_abno/queen_bee/proc/EmitSpores(forced = FALSE)
	var/turf/target_c = get_turf(src)
	var/list/turf_list = list()
	turf_list = spiral_range_turfs(36, target_c)
	playsound(target_c, 'sound/abnormalities/bee/spores.ogg', 50, 1, 5)
	for(var/turf/open/T in turf_list)
		if(prob(25))
			new /obj/effect/temp_visual/bee_gas(T)
		for(var/mob/living/carbon/C in T.contents)
			if(IsFriend(C) && !forced)
				continue
			if(prob(90))
				var/datum/disease/bee_spawn/limbus_bee_spawn/D = new()
				C.ForceContractDisease(D, FALSE, TRUE)
	AdjustDesire(100)

/mob/living/simple_animal/hostile/limbus_abno/queen_bee/AdjustDesire(desire_amount)
	..()
	if(desire_bar <= 0)
		EmitSpores(TRUE)

/mob/living/simple_animal/hostile/limbus_abno/queen_bee/UnarmedAttack(atom/A, proximity)
	. = ..()
	if(!iscarbon(A))
		return
	var/mob/living/carbon/C = A
	var/datum/disease/bee_spawn/limbus_bee_spawn/D = new()
	D.spore_damage = 2
	C.ForceContractDisease(D, FALSE, TRUE)

/mob/living/simple_animal/hostile/limbus_abno/queen_bee/AdjustHunger(hunger_amount)
	..()
	if(starving)
		AdjustDesire(-30)

/datum/action/cooldown/limbus_abno_action/emit_spores
	name = "Emit Spores"
	desc = "Emit spores, infecting many in the facility with your children. This can only be used on low mood.."
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "mustard"
	transparent_when_unavailable = TRUE
	cooldown_time = 3 MINUTES
	desire_req = 50

/datum/action/cooldown/limbus_abno_action/emit_spores/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/queen_bee/queen = abno_user
	queen.EmitSpores(FALSE)
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/bee_egg
	name = "Birth Worker"
	desc = "Make an egg that will eventually grow into a worker bee who will fight and search for food. Costs nearly all your hunger to use. Severely increases your mood."
	icon_icon = 'icons/obj/food/food.dmi'
	button_icon_state = "egg-yellow"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/bee_egg/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 70)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/bee_egg/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/turf/T = get_turf(abno_user)
	new /obj/item/food/bee_egg(T)
	playsound(T, 'sound/effects/splat.ogg', 50, TRUE)
	StartCooldown()
	abno_user.AdjustHunger(-70) //Creating eggs like this is supposed to be very inefficient, living hosts are better.
	abno_user.AdjustDesire(70)

//We don't make this an egg subtype because it runs into some problems with the throwable code. Will make a controllable bee after some time.
/obj/item/food/bee_egg
	name = "Bee Egg"
	desc = "It is is pulsating with potential, one that will serve the queen well."
	icon_state = "egg-yellow"
	food_reagents = list(/datum/reagent/consumable/honey = 10)
	microwaved_type = /obj/item/food/boiledegg //Don't think about it.
	foodtypes = MEAT
	w_class = WEIGHT_CLASS_TINY

/obj/item/food/bee_egg/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(hatch_bee)), 2 MINUTES)

/obj/item/food/bee_egg/proc/hatch_bee()
	new /mob/living/simple_animal/hostile/worker_bee/lcl_bee(get_turf(src))
	qdel(src)

/mob/living/simple_animal/hostile/worker_bee/lcl_bee
	faction = list("neutral", "hostile") //Their AI lobotomy should prevent friendly attack, but better safe than sorry.
	created_bee_type = /mob/living/simple_animal/hostile/worker_bee/lcl_bee
	var/mob/living/simple_animal/hostile/limbus_abno/queen_bee/queen

/mob/living/simple_animal/hostile/worker_bee/lcl_bee/Initialize()
	. = ..()
	toggle_ai(AI_OFF)
	notify_ghosts("[src] is ready to serve the queen! Use the possess action to play.", null, null, source=src, action=NOTIFY_ORBIT)
	var/datum/action/cooldown/bee_speech/beech = new()
	beech.Grant(src)
	var/datum/action/cooldown/bee_scavenge/beenge = new() //I'm kinda pushing it with that one.
	beenge.Grant(src)

/mob/living/simple_animal/hostile/worker_bee/lcl_bee/death()
	if(queen)
		mind.transfer_to(queen)
	..()

/datum/action/cooldown/bee_scavenge
	name = "Scavenge for meat."
	desc = "Scavenge meat for the queen."
	icon_icon = 'icons/obj/food/food.dmi'
	button_icon_state = "meat"
	cooldown_time = 1.5 MINUTES

/datum/action/cooldown/bee_scavenge/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/scavenge_result = rand(1,3)
	var/turf/T = get_turf(owner)
	for(var/i = 1 to scavenge_result)
		new /obj/item/food/meat/slab(T)
	playsound(T, 'sound/effects/splat.ogg', 50, TRUE)
	StartCooldown()

/datum/action/cooldown/bee_swap
	name = "Worker Possession"
	desc = "Lets you take direct control of a worker bee as long as they are not already aware. If used as a worker bee, puts you back into your queen body."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "expand"
	cooldown_time = 1 MINUTES

/datum/action/cooldown/bee_swap/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/worker_bee/lcl_bee/user_bee
	if(istype(owner, /mob/living/simple_animal/hostile/worker_bee/lcl_bee))
		user_bee = owner
		if(user_bee.queen)
			user_bee.queen.ckey = user_bee.ckey
			user_bee.mind = null
			user_bee.queen = null
			qdel(src)
			return

	for(var/mob/living/simple_animal/hostile/worker_bee/lcl_bee/bee in GLOB.alive_mob_list)
		if(!bee.mind && !bee.ckey)
			bee.ckey = owner.ckey //We don't use transfer_to because it creates possession issues.
			var/datum/action/cooldown/bee_swap/bs = new /datum/action/cooldown/bee_swap()
			bs.Grant(bee)
			bee.queen = owner
			StartCooldown()

/datum/action/cooldown/bee_speech
	name = "Hivemind Speech"
	desc = "Lets you directly communicate with other bees."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "hivemind_channel"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/bee_speech/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/msg = stripped_input(usr, "What do you wish to tell the other bees?", null, "")
	if(!msg)
		return FALSE
	var/rendered = "<span class='abductor'><b>[owner]:</b> [msg]</span>"
	owner.log_talk(rendered, LOG_SAY, tag="bees")
	for(var/mob/living/simple_animal/hostile/worker_bee/lcl_bee/bee in GLOB.alive_mob_list)
		to_chat(bee, rendered)

	for(var/mob/living/simple_animal/hostile/limbus_abno/queen_bee/queen in GLOB.alive_mob_list)
		to_chat(queen, rendered)

	for(var/mob/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, owner)
		to_chat(M, "[link] [rendered]")
	StartCooldown()
