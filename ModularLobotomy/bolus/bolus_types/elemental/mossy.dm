//Another basic and common bolus.
//Wood Counterpart to the charred bolus

/obj/item/bolus/mossy
	name = "mossy bolus"
	desc = "A bolus that focuses on healing others."
	icon_state = "bolus_mossy"
	abilities = list(
			"WOOD 1: User heals 10 SP",
			"WOOD 3: User heals 10 SP",
			"WOOD 5: User heals 10 SP",
			"WATER 2: User heals 10 SP",
			"WATER 4: User is slowed for a period of time.",
			"FIRE 2: User heals 40 SP and is set alight.",
			"FIRE 4: User enters into a Berserker Rage state.",
			"EARTH 3: User sprouts vines.",
			"METAL 3: User will fall madly in love with someone and go into a confused state.",
			)
	var/sleep_tick = 10

/obj/item/bolus/mossy/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 1)
		user.adjustSanityLoss(-10)

	if(wood_in >= 3)
		user.adjustSanityLoss(-10)

	if(wood_in >= 5)
		user.adjustSanityLoss(-10)

	if(water_in >= 2)
		user.adjustSanityLoss(-10)

	if(water_in >= 4)
		user.add_movespeed_modifier(/datum/movespeed_modifier/mossy_bolus)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/mossy_bolus), 60 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

	if(fire_in >= 2)
		user.adjustSanityLoss(-40)
		user.adjust_fire_stacks(2)
		user.IgniteMob()

	if(fire_in >= 4)
		if(!user.sanity_lost)
			user.adjustSanityLoss(500)
		QDEL_NULL(user.ai_controller)
		user.ai_controller = /datum/ai_controller/insane/murder
		user.InitializeAIController()
	//The berserker Rage

	if(earth_in >= 3)
		new /obj/structure/spreading/bolus_vine (get_turf(user))
		user.Immobilize(3 SECONDS)

	if(metal_in >= 3)

		user.set_confusion(30)
		var/list/valentines = list()
		for(var/mob/living/M in GLOB.player_list)
			if(!M.stat && M.mind)
				valentines |= M

		var/date = pick(valentines)
		forge_valentines_objective(user, date)



//Movespeed boost
/datum/movespeed_modifier/mossy_bolus
	multiplicative_slowdown = 0.4


//The vines

/obj/structure/spreading/bolus_vine
	gender = PLURAL
	name = "bitter flora"
	desc = "Branches that grow from wilting stems."
	icon = 'icons/effects/spacevines.dmi'
	icon_state = "Med1"
	base_icon_state = "Med1"
	color = "#808000"
	max_integrity = 15
	resistance_flags = FLAMMABLE
	pass_flags_self = LETPASSTHROW
	armor = list(
		MELEE = 0,
		BULLET = 0,
		FIRE = -50,
		RED_DAMAGE = 20,
		WHITE_DAMAGE = 0,
		BLACK_DAMAGE = 80,
		PALE_DAMAGE = -50,
	)

/obj/structure/spreading/bolus_vine/Crossed(atom/movable/AM)
	. = ..()
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(prob(10))
			H.Immobilize(5)
			to_chat(H, span_warning("You get caught in the vines!"))


/obj/structure/spreading/bolus_vine/play_attack_sound(damage_amount, damage_type = BRUTE)
	playsound(loc, 'sound/creatures/venus_trap_hit.ogg', 60, TRUE)

/obj/structure/spreading/bolus_vine/Initialize()
	. = ..()
	expand()

/obj/structure/spreading/bolus_vine/expand()
	addtimer(CALLBACK(src, PROC_REF(expand)), 10 SECONDS)
	return ..()

