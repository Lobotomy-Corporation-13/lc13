//These are the reactions
/datum/chemical_reaction/healing_gel
	results = list(/datum/reagent/abnormality/healing_gel = 2)
	required_reagents = list(/datum/reagent/neuroxene7 = 1, /datum/reagent/virothane = 1, /datum/reagent/zephyrium_chloride = 1)

/datum/chemical_reaction/sanity_gel
	results = list(/datum/reagent/abnormality/sanity_gel = 2)
	required_reagents = list(/datum/reagent/neuroxene7 = 1, /datum/reagent/virothane = 1, /datum/chemical_reaction/hyperlithium_oxide = 1)

//Takes a mixture of all the items for a mixed gel.
/datum/chemical_reaction/mixed_gel
	results = list(/datum/reagent/abnormality/mixed_gel = 2)
	required_reagents = list(/datum/reagent/abnormality/healing_gel = 1, /datum/chemical_reaction/sanity_gel = 1,
		/datum/chemical_reaction/radionex = 1)


/datum/chemical_reaction/burn_salve
	results = list(/datum/reagent/abnormality/burn_salve = 2)
	required_reagents = list(/datum/reagent/xenotride = 1, /datum/reagent/virothane = 1,
		/datum/reagent/nexalite = 1)

/datum/chemical_reaction/antitoxin
	results = list(/datum/reagent/antitoxin = 2)
	required_reagents = list(/datum/reagent/ionovium = 1, /datum/reagent/synthryl = 1,
		/datum/reagent/plasmorite = 1)
