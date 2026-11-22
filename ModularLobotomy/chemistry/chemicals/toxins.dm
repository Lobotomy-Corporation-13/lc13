/datum/reagent/glysantin
	name = "glysantin"
	description = "A simple poison. Occasionally used as an antitoxin."
	color = "#93cfc2"
	sanity_restore = 2

/datum/reagent/glysantin/on_mob_life(mob/living/carbon/M)
	if(prob(10))
		M.vomit(70)
	M.adjustToxLoss(2*REM, 0)
	..()
	return TRUE


/datum/reagent/chloronicotine
	name = "chloronicotine"
	description = "A nicotine-like substance that works as a toxin in humans, but has some useful effects. \
		Poisonous, but keeps you awake."
	color = "#4a5c4a"

/datum/reagent/chloronicotine/on_mob_life(mob/living/M)
	M.adjustToxLoss(0.1*REM, 0)
	M.AdjustUnconscious(-5)

	..()
	return TRUE


/datum/reagent/brainrot
	name = "brainrot"
	description = "A chemical that can damage the brain rather significantly and quickly. \
		Used in District 7 backstreets to cause hallucinations."
	color = "#6baf65"

/datum/reagent/brainrot/on_mob_life(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3*REM, 90)
	if(prob(10))
		M.hallucination += 1
	..()
	return TRUE


/datum/reagent/methylmercury
	name = "methylmercury"
	description = "A chemical that causes it's users to be rather weak. it lasts a long itme in the system and is very hard to detect."
	color = "#cccccc"
	metabolization_rate = 0.125 * REAGENTS_METABOLISM

/datum/reagent/methylmercury/on_mob_life(mob/living/M)
	if(prob(8))
		to_chat(M, span_danger("You feel so weak!"))
		M.Stun(40)
		M.Knockdown(40)
		M.adjustToxLoss(2*REM, 0)
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3*REM, 90)
	..()
	return TRUE



/datum/reagent/betamethasone
	name = "betamethasone"
	description = "A chemical that does mute the user occasionally, but heals oxyloss rather quickly!"
	color = "#abd0d1"

/datum/reagent/betamethasone/on_mob_life(mob/living/M)
	M.adjustOxyLoss(-7*REM, 0)
	if(prob(10))
		M.silent = max(M.silent, 30)
	..()
	return TRUE
