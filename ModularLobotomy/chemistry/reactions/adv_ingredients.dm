
//These are just the middlemen

/datum/chemical_reaction/zephyrium_chloride
	results = list(/datum/reagent/zephyrium_chloride = 1)
	required_reagents = list(/datum/reagent/nexalite = 1, /datum/reagent/omnicarbide = 1, /datum/reagent/thermate = 1)

/datum/chemical_reaction/hyperlithium_oxide
	results = list(/datum/reagent/hyperlithium_oxide = 1)
	required_reagents = list(/datum/reagent/lithene = 1, /datum/reagent/synthryl = 1, /datum/reagent/oxalite = 1)

/datum/chemical_reaction/radionex
	results = list(/datum/reagent/radionex = 1)
	required_reagents = list(/datum/chemical_reaction/zephyrium_chloride = 1, /datum/chemical_reaction/hyperlithium_oxide = 1)
