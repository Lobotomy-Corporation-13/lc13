/obj/item/stack/refiner_filter
	name = "PE Filters"
	singular_name = "PE filter"
	desc = "Filters used to refine PE."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "blue"
	amount = 1
	max_amount = 50
	novariants = TRUE
	merge_type = /obj/item/stack/refiner_filter

/obj/item/stack/refiner_filter/blue
	name = "Blue PE Filters"
	singular_name = "blue PE filter"
	desc = "A filter used to refine PE. This has a filter strength of 2"
	icon_state = "blue"
	merge_type = /obj/item/stack/refiner_filter/blue

/obj/item/stack/refiner_filter/green
	name = "Green PE Filters"
	singular_name = "green PE filter"
	desc = "A filter used to refine PE. This has a filter strength of 3"
	icon_state = "green"
	merge_type = /obj/item/stack/refiner_filter/green

/obj/item/stack/refiner_filter/red
	name = "Red PE Filters"
	singular_name = "red PE filter"
	desc = "A filter used to refine PE. This has a filter strength of 6"
	icon_state = "red"
	merge_type = /obj/item/stack/refiner_filter/red

/obj/item/stack/refiner_filter/yellow
	name = "Yellow PE Filters"
	singular_name = "yellow PE filter"
	desc = "A filter used to refine PE. This has a filter strength of 10"
	icon_state = "yellow"
	merge_type = /obj/item/stack/refiner_filter/yellow

/obj/item/storage/bag/pe_filter
	name = "PE filter bag"
	desc = "A specialized bag for storing PE filters and PE boxes."
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel"
	worn_icon_state = "satchel"
	slot_flags = ITEM_SLOT_BELT

/obj/item/storage/bag/pe_filter/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_combined_w_class = 100
	STR.max_items = 30
	STR.set_holdable(list(
		/obj/item/stack/refiner_filter,
	))
