// Corporist Species - The Ring's Corporist School
// Full-body prosthetic species for Maestro and Apprentice

/datum/species/corporist_maestro
	name = "Corporist Maestro"
	id = "corporist_maestro"
	say_mod = "states"
	species_traits = list(NOBLOOD)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_NOMETABOLISM,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_NOFIRE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOCLONELOSS
	)
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = "maestro"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	bodypart_overides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/corporist_maestro,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/corporist_maestro,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/corporist_maestro,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/corporist_maestro,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/corporist_maestro,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/corporist_maestro
	)

/datum/species/corporist_maestro/on_species_gain(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ROBOTIC, FALSE, TRUE)
		BP.brute_reduction = 5
		BP.burn_reduction = 4
	C.set_safe_hunger_level()

/datum/species/corporist_maestro/on_species_loss(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ORGANIC, FALSE, TRUE)
		BP.brute_reduction = initial(BP.brute_reduction)
		BP.burn_reduction = initial(BP.burn_reduction)

/datum/species/corporist_apprentice
	name = "Corporist Apprentice"
	id = "corporist_apprentice"
	say_mod = "states"
	species_traits = list(NOBLOOD)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_NOMETABOLISM,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_NOFIRE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOCLONELOSS
	)
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = "apprentice"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	bodypart_overides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/corporist_apprentice,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/corporist_apprentice,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/corporist_apprentice,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/corporist_apprentice,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/corporist_apprentice,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/corporist_apprentice
	)

/datum/species/corporist_apprentice/on_species_gain(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ROBOTIC, FALSE, TRUE)
		BP.brute_reduction = 5
		BP.burn_reduction = 4
	C.set_safe_hunger_level()

/datum/species/corporist_apprentice/on_species_loss(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ORGANIC, FALSE, TRUE)
		BP.brute_reduction = initial(BP.brute_reduction)
		BP.burn_reduction = initial(BP.burn_reduction)
