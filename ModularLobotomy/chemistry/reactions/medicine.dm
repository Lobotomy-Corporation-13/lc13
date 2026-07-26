//These are the reactions
/datum/chemical_reaction/healing_gel
	results = list(/datum/reagent/abnormality/healing_gel = 2)
	required_reagents = list(/datum/reagent/lithene = 1, /datum/reagent/virothane = 1, /datum/reagent/zephyrium_chloride = 1)

/datum/chemical_reaction/sanity_gel
	results = list(/datum/reagent/abnormality/sanity_gel = 2)
	required_reagents = list(/datum/reagent/lithene = 1, /datum/reagent/virothane = 1, /datum/reagent/hyperlithium_oxide = 1)

//Takes a mixture of all the items for a mixed gel.
/datum/chemical_reaction/mixed_gel
	results = list(/datum/reagent/abnormality/mixed_gel = 2)
	required_reagents = list(/datum/reagent/abnormality/healing_gel = 1, /datum/reagent/abnormality/sanity_gel = 1,
		/datum/reagent/radionex = 1)

//The basic Burn salve and anti-toxins
/datum/chemical_reaction/burn_salve
	results = list(/datum/reagent/abnormality/burn_salve = 2)
	required_reagents = list(/datum/reagent/xenotride = 1, /datum/reagent/virothane = 1,
		/datum/reagent/nexalite = 1)

/datum/chemical_reaction/antitoxin
	results = list(/datum/reagent/antitoxin = 2)
	required_reagents = list(/datum/reagent/ionovium = 1, /datum/reagent/synthryl = 1,
		/datum/reagent/virothane = 1)

// To make K-Corp Drugs you need Genetic Repair

/datum/chemical_reaction/healing_fast
	results = list(/datum/reagent/abnormality/healing_fast = 2)
	required_reagents = list(/datum/reagent/hydrene = 1, /datum/reagent/verdite = 1,
		/datum/reagent/abnormality/gene_repair = 1)

/datum/chemical_reaction/gene_repair
	results = list(/datum/reagent/abnormality/gene_repair = 3)
	required_reagents = list(/datum/reagent/omnicarbide = 1, /datum/reagent/ferroxan = 1,
		/datum/reagent/velocium = 1)

/datum/chemical_reaction/purgall
	results = list(/datum/reagent/purgall = 3)
	required_reagents = list(/datum/chemical_reaction/antitoxin = 1, /datum/reagent/ionovium = 1,
		/datum/reagent/hydrene = 1)

/datum/chemical_reaction/lc13_synthflesh
	results = list(/datum/reagent/medicine/c2/synthflesh = 3)
	required_reagents = list(/datum/chemical_reaction/antitoxin = 1, /datum/chemical_reaction/healing_gel = 1,
		/datum/chemical_reaction/burn_salve = 1)





