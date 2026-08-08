//This is a Bolus is slightly bug themed?

/obj/item/bolus/odd
	name = "odd bolus"
	desc = "A bolus that is used for various effects."
	icon_state = "bolus_odd"
	abilities = list(
			"WOOD 9: User sprouts an antenna.",
			"WATER 3: User seemed confused, and was slightly poisoned by the bolus.",
			"WATER 7: User's HP is healed by a great amount.",
			"FIRE 2: User ignites.",
			"FIRE 5: User seems to have gained heightened hand to hand combat abilities.",
			"EARTH 6: User's arm transforms to a bug-like form.",
			"EARTH 8: User is petrified.",
			"METAL 4: User's body produces chitin shards.",
			)


/obj/item/bolus/odd/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 9)
		if(user.has_dna() && !HAS_TRAIT(user, TRAIT_GENELESS) && !HAS_TRAIT(user, TRAIT_BADDNA))
			user.dna.add_mutation(ANTENNA)

	if(water_in >= 3)
		user.set_confusion(10)
		user.set_drugginess(15)
		user.adjustToxLoss(5)	//Just go to safety.

	if(water_in >= 7)
		//This one is good for healing if you can get up to Water 7.
		user.adjustBruteLoss(-100)

	if(fire_in >= 2)
		user.adjust_fire_stacks(2)
		user.IgniteMob()

	if(fire_in >= 5)
		if(user.fisticuffs_bonus < 15)
			user.fisticuffs_bonus = 15	//It's pretty funny.

	if(earth_in >= 6)
		user.emote("scream")
		var/obj/item/bodypart/arm = pick(user.get_bodypart(BODY_ZONE_R_ARM), user.get_bodypart(BODY_ZONE_L_ARM))
		arm.species_id = "fly"
		new /obj/effect/gibspawner/generic(get_turf(user))

	if(earth_in >= 8)
		user.petrify()

	if(metal_in >= 4)
		CreateShard(user)



/obj/item/bolus/odd/proc/CreateShard(mob/living/carbon/human/user)
	if(prob(75))
		addtimer(CALLBACK(src, PROC_REF(CreateShard), user), 30 SECONDS)
	new /obj/item/chitin_shard (get_turf(src))

/obj/item/chitin_shard
	name = "chitin shard"
	desc = "It's a shard of chitin you found. Probably good for throwing."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	icon_state = "ratscalpel"
	force = 5
	throwforce = 30
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/chitin_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..())
		qdel(src)
