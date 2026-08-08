//Another basic and common bolus.
//Earth Counterpart to the charred bolus

/obj/item/bolus/rust
	name = "rust bolus"
	desc = "A bolus that focuses on giving armor and clearing odd damage types."
	icon_state = "bolus_rust"
	abilities = list(
			"WOOD 3: User's body purges all toxin damage, but their body goes into a critical state.",
			"WATER 3: User's body is cleaned of all burns, but their mind goes mad.",
			"FIRE 2: User gains Red Strength 4",
			"FIRE 4: User's body is slowed as their legs turn to metal. This slowness lasts a while, but the leg will never return.",
			"EARTH 2: User's body purges a mild amount of toxin and burn damage.",
			"EARTH 4: User's skin melts off, causing an extremely painful reaction.",
			"METAL 1: User gains Protection 1",
			"METAL 3: User gains Protection 2",
			"METAL 5: User gains Protection 4",
			)

/obj/item/bolus/rust/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 3)
		user.adjustToxLoss(-999)
		user.adjustBruteLoss(user.health+4)	//This.... Should crit you?

	if(water_in >= 3)
		user.adjustFireLoss(-999)
		user.adjustSanityLoss(999)

	if(fire_in >= 2)
		user.apply_lc_red_strength(4)

	if(fire_in >= 4)
		var/obj/item/bodypart/leg = pick(user.get_bodypart(BODY_ZONE_R_LEG), user.get_bodypart(BODY_ZONE_L_LEG))
		leg.species_id = "silver golem"
		user.add_movespeed_modifier(/datum/movespeed_modifier/rust_bolus)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/rust_bolus), 60 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

	if(earth_in >= 2)
		user.adjustFireLoss(-10)
		user.adjustToxLoss(-10)

	if(earth_in >= 4)
		if(!istype(user.dna.species, /datum/species/krokodil_addict))
			to_chat(user, span_danger("Your skin starts to fall off!"))
			user.adjustBruteLoss(50) // holy shit your skin just FELL THE FUCK OFF
			user.set_species(/datum/species/krokodil_addict)

	if(metal_in >= 1)
		user.apply_lc_protection(1)

	if(metal_in >= 3)
		user.apply_lc_protection(2)

	if(metal_in >= 5)
		user.apply_lc_protection(4)


//Movespeed loss from a metal leg
/datum/movespeed_modifier/rust_bolus
	multiplicative_slowdown = 0.2

