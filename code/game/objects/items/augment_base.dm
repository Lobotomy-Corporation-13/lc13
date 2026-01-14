// Base augment item type - forward declaration
// Full implementation in ModularLobotomy/associations/augments.dm

/datum/augment_design
	var/list/form_data
	var/rank
	var/list/selected_effects_data = list()
	var/base_ep
	var/total_ep_cost
	var/remaining_ep
	var/base_ahn_cost
	var/effects_ahn_cost
	var/total_ahn_cost
	var/validation_error = ""

/obj/item/augment
	name = "Augment"
	var/datum/augment_design/design_details
	var/primary_color = "#FFFFFF"
	var/secondary_color = "#CCCCCC"
	var/active_augment = FALSE
