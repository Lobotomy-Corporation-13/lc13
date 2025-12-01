/obj/machinery/chem_dispenser/lc13
	dispensable_reagents = list(
		/datum/reagent/neuroxene7,
		/datum/reagent/cryovium,
		/datum/reagent/xenotride,
		/datum/reagent/luminexium,
		/datum/reagent/quantaferrite,
		/datum/reagent/virothane,
		/datum/reagent/synthryl,
		/datum/reagent/plasmorite,
		/datum/reagent/omnicarbide,
		/datum/reagent/velocium,
		/datum/reagent/cryostraline,
		/datum/reagent/nexalite,
		/datum/reagent/osmarion,
		/datum/reagent/phasium_delta,
		/datum/reagent/ionovium,
	)

/obj/machinery/chem_dispenser/lc13/Initialize()
	. = ..()
	// Cache the old_parts first, we'll delete it after we've changed component_parts to a new list.
	// This stops handle_atom_del being called on every part when not necessary.
	var/list/old_parts = component_parts.Copy()

	component_parts = list()
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/sheet/glass(src, 1)
	component_parts += new /obj/item/stock_par