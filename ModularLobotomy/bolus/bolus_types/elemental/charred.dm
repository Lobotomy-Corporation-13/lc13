//Another basic and common bolus
//These 5 boluses are basic elemental boluses with one major and 2 minor effects, with 2 options being negative

/obj/item/bolus/charred
	name = "charred bolus"
	desc = "A bolus that focuses on strength."
	icon_state = "bolus_charred"
	abilities = list(
			"WATER 2: User gains a small movement boost.",
			"WATER 4: User gains 8 Bleed.",
			"WOOD 3: User is set alight.",
			"FIRE 1: Applies 1 Strength for a short period of time.",
			"FIRE 3: Applies 2 Strength for a short period of time.",
			"FIRE 5: Applies 5 Strength for a short period of time.",
			"EARTH 2: User heals 20 SP",
			"EARTH 4: User gains 3 Tremor.",
			"METAL 3: User gains confusion.",
			)

/obj/item/bolus/charred/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 3)
		user.adjust_fire_stacks(3)
		user.IgniteMob()

	if(water_in >= 2)
		user.add_movespeed_modifier(/datum/movespeed_modifier/charred_bolus)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/charred_bolus), 60 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

	if(water_in >= 4)
		user.apply_lc_bleed(8)

	if(fire_in >= 1)
		user.apply_lc_strength(1)

	if(fire_in >= 3)
		user.apply_lc_strength(2)

	if(fire_in >= 5)
		user.apply_lc_strength(4)

	if(earth_in >= 2)
		user.adjustSanityLoss(-20)

	if(earth_in >= 4)
		user.apply_lc_tremor(3, 3)

	if(metal_in >= 3)
		user.set_confusion(10)


//Movespeed boost
/datum/movespeed_modifier/charred_bolus
	multiplicative_slowdown = -0.1
