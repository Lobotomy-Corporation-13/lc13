
//Mostly harmless drug.

/datum/reagent/abnormality/lunaphetamine
	name = "lunaphetamine"
	description = "An illegal substance found on the moon."
	color = "#6baf65"
	sanity_restore = 2

/datum/reagent/abnormality/lunaphetamine/on_mob_life(mob/living/M)
	if(prob(10))
		//Get a random between Blind, Confusion, Mute and drowsy, and none. This is used by the lunar rabbits
		var/effect_choice = rand(1,3)
		switch(effect_choice)
			if(1)
				M.set_confusion(10)
			if(2)
				M.drowsyness += 30
			if(3)
				M.adjust_blindness(5)

	..()
	return TRUE

/datum/reagent/abnormality/heavyblood
	name = "Heavyblood"
	description = "An illegal substance made in some backstreets. Heals wounds but makes you tired."
	color = "#6baf65"
	health_restore = 2

/datum/reagent/abnormality/heavyblood/on_mob_life(mob/living/M)
	if(prob(10))
		M.drowsyness += 30
	..()
	return TRUE

/datum/reagent/abnormality/blindsight
	name = "Blindsight"
	description = "An old medicine rarely used that slowly deteriorates sight, but adds some resistance to damage."
	color = "#6baf65"
	damage_mods = list(0.9, 0.9, 0.9, 0.9)

/datum/reagent/abnormality/heavyblood/on_mob_life(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_EYES,0.25*REM)
	..()
