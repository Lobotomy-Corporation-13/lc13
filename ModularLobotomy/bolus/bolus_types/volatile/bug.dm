//This is a Bolus is slightly bug themed?

/obj/item/bolus/volatile/bug
	name = "chitin bolus"
	desc = "A bolus that includes crushed chitin."
	icon_state = "bolus_chitin"
	abilities = list(
			"WOOD 9: User sprouts an antenna.",
			"WATER 6: User's body can now produce webs at will.",
			"FIRE 4: User gained Nearsightedness.",
			"FIRE 7: User gained the ability to sense enemies through walls.",
			"EARTH 7: User's arm transforms to a bug-like form.",
			"METAL 4: User's body produces chitin shards.",
			)


/obj/item/bolus/volatile/bug/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 9)
		if(user.has_dna() && !HAS_TRAIT(user, TRAIT_GENELESS) && !HAS_TRAIT(user, TRAIT_BADDNA))
			user.dna.add_mutation(ANTENNA)

	if(water_in >= 6)
		if(user.has_dna() && !HAS_TRAIT(user, TRAIT_GENELESS) && !HAS_TRAIT(user, TRAIT_BADDNA))
			user.dna.add_mutation(/datum/mutation/human/webbing)

	if(fire_in >= 4)
		if(user.has_dna() && !HAS_TRAIT(user, TRAIT_GENELESS) && !HAS_TRAIT(user, TRAIT_BADDNA))
			user.dna.add_mutation(/datum/mutation/human/nearsight)

	if(fire_in >= 7)
		if(user.has_dna() && !HAS_TRAIT(user, TRAIT_GENELESS) && !HAS_TRAIT(user, TRAIT_BADDNA))
			user.dna.add_mutation(/datum/mutation/human/thermal)

	if(earth_in >= 7)
		user.emote("scream")
		var/obj/item/bodypart/arm = pick(user.get_bodypart(BODY_ZONE_R_ARM), user.get_bodypart(BODY_ZONE_L_ARM))
		arm.species_id = "fly"
		new /obj/effect/gibspawner/generic(get_turf(user))

	if(metal_in >= 4)
		CreateShard(user)


/obj/item/bolus/volatile/bug/proc/CreateShard(mob/living/carbon/human/user)
	if(prob(75))
		addtimer(CALLBACK(src, PROC_REF(CreateShard), user), 30 SECONDS)
	new /obj/item/chitin_shard (get_turf(src))

