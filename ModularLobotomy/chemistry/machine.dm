/obj/machinery/chem_dispenser/lc13
	dispensable_reagents = list(
		/datum/reagent/oxalite,
		/datum/reagent/hydrene,
		/datum/reagent/xenotride,
		/datum/reagent/lithene,
		/datum/reagent/ferroxan,
		/datum/reagent/virothane,
		/datum/reagent/synthryl,
		/datum/reagent/purite,
		/datum/reagent/omnicarbide,
		/datum/reagent/velocium,
		/datum/reagent/cryostraline,
		/datum/reagent/nexalite,
		/datum/reagent/thermate,
		/datum/reagent/verdite,
		/datum/reagent/ionovium,
	)

/obj/machinery/chem_dispenser/lc13/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/sheet/glass(src, 1)
