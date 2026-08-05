
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

/datum/reagent/abnormality/blindsight/on_mob_life(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_EYES,0.25*REM)
	..()


/datum/reagent/abnormality/mindkill
	name = "Mindkill"
	description = "A drug that removes sanity but gives you visions."
	color = "#6baf65"
	sanity_restore = -1

/datum/reagent/abnormality/mindkill/on_mob_life(mob/living/M)
	. = ..()
	M.hallucination += 1


//Simple Drug for some fun.
//Like Space Drugs but not in space.0
/datum/reagent/junglejuice
	name = "Jungle juice"
	description = "An illegal chemical compound used as drug."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30

/datum/reagent/junglejuice/on_mob_life(mob/living/M)
	M.set_drugginess(15)
	if(isturf(M.loc) && !isspaceturf(M.loc))
		if(!HAS_TRAIT(M, TRAIT_IMMOBILIZED))
			if(prob(10))
				step(M, pick(GLOB.cardinals))
	if(prob(7))
		M.emote(pick("twitch","drool","moan","giggle"))
	return ..()

/datum/reagent/junglejuice/overdose_start(mob/living/M)
	to_chat(M, "<span class='userdanger'>You start tripping hard!</span>")

/datum/reagent/junglejuice/overdose_process(mob/living/M)
	if(M.hallucination < volume && prob(20))
		M.hallucination += 5
	return ..()


//This one gives you the psychotic brawler
/datum/reagent/madness
	name = "Madness"
	description = "An illegal chemical compound that causes one to go insane but also offers them some new... strange effects."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30
	var/datum/martial_art/psychotic_brawling/psychofist = new

/datum/reagent/madness/on_mob_metabolize(mob/living/L)
	. = ..()
	psychofist.teach(L)

/datum/reagent/madness/on_mob_end_metabolize(mob/living/L)
	psychofist.remove(L)
	qdel(psychofist)
	return ..()

/datum/reagent/madness/on_mob_life(mob/living/M)
	if((M.hallucination < 15) && prob(10))
		M.hallucination += 5

/datum/reagent/madness/overdose_start(mob/living/M)
	to_chat(M, "<span class='userdanger'>You can't stop shaking, your heart beats faster and faster...</span>")

/datum/reagent/madness/overdose_process(mob/living/M)
	M.Jitter(5)
	if(prob(5))
		M.drop_all_held_items()
	if(prob(15))
		M.emote(pick("twitch","drool"))
	if(prob(15))
		M.adjustToxLoss(2, 0)
	return ..()


//Way to get the void skill. No clue where it will be useful.
/datum/reagent/voidcall
	name = "VoidCall"
	description = "A compound that can pull you into the void."
	color = "#60A584" // rgb: 96, 165, 132

/datum/reagent/voidcall/on_mob_metabolize(mob/living/carbon/L)
	. = ..()
	if(L.has_dna() && !HAS_TRAIT(L, TRAIT_GENELESS) && !HAS_TRAIT(L, TRAIT_BADDNA))
		L.dna.add_mutation(/datum/mutation/human/void)

/datum/reagent/voidcall/on_mob_end_metabolize(mob/living/carbon/L)
	if(L.has_dna() && !HAS_TRAIT(L, TRAIT_GENELESS) && !HAS_TRAIT(L, TRAIT_BADDNA))
		L.dna.remove_mutation(/datum/mutation/human/void)
	return ..()
