// ============================================================
// Seven Association — Requisition Catalog
// ============================================================
// A handheld shop for ordering investigation equipment.

/// A handheld catalog for ordering Seven Association investigation equipment.
/obj/item/seven_catalog
	name = "Seven requisition catalog"
	desc = "A handheld catalog for ordering Seven Association investigation equipment. Payment drawn from your registered account."
	icon = 'icons/obj/device.dmi'
	icon_state = "hand_tele"
	w_class = WEIGHT_CLASS_SMALL

	/// Static catalog entries
	var/static/list/catalog_items

/obj/item/seven_catalog/proc/init_catalog()
	if(catalog_items)
		return
	catalog_items = list(
		list(
			"name" = "Surveillance Recorder",
			"desc" = "A deployable recorder that captures nearby speech.",
			"cost" = 500,
			"path" = /obj/item/seven_recorder,
			"amount" = 1
		),
		list(
			"name" = "Intel Camera",
			"desc" = "A silent camera that creates intel snapshots.",
			"cost" = 400,
			"path" = /obj/item/camera/seven_intel,
			"amount" = 1
		),
		list(
			"name" = "Intel Report x3",
			"desc" = "Three blank intelligence report forms.",
			"cost" = 50,
			"path" = /obj/item/intel_report,
			"amount" = 3
		),
		list(
			"name" = "Backpack Scanner",
			"desc" = "A scanner that silently reveals backpack contents.",
			"cost" = 500,
			"path" = /obj/item/seven_scanner,
			"amount" = 1
		),
		list(
			"name" = "Surveillance Kit",
			"desc" = "A box with spy glasses and a camera bug.",
			"cost" = 350,
			"path" = /obj/item/storage/box/seven_spyglass,
			"amount" = 1
		),
		list(
			"name" = "Investigation Dossier",
			"desc" = "A dossier for filing intel reports for EXP.",
			"cost" = 100,
			"path" = /obj/item/seven_dossier,
			"amount" = 1
		),
		list(
			"name" = "Surveillance Receiver",
			"desc" = "A receiver for tuning into deployed recorders.",
			"cost" = 250,
			"path" = /obj/item/seven_receiver,
			"amount" = 1
		),
		list(
			"name" = "Signal Interceptor",
			"desc" = "Intercepts PDA messages with anonymized IDs.",
			"cost" = 1000,
			"path" = /obj/item/seven_pda_interceptor,
			"amount" = 1
		),
		list(
			"name" = "Film Cartridge",
			"desc" = "A camera film cartridge to reload your intel camera.",
			"cost" = 50,
			"path" = /obj/item/camera_film,
			"amount" = 1
		)
	)

/obj/item/seven_catalog/attack_self(mob/user)
	init_catalog()
	ui_interact(user)

/obj/item/seven_catalog/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SevenCatalog", name)
		ui.open()

/obj/item/seven_catalog/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/seven_catalog/ui_data(mob/user)
	var/list/data = list()
	// Get user's balance
	var/balance = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/card/id/id = H.get_idcard(TRUE)
		if(id?.registered_account)
			balance = id.registered_account.account_balance
	data["balance"] = balance
	data["items"] = catalog_items
	return data

/obj/item/seven_catalog/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(action != "purchase")
		return

	var/item_index = text2num(params["index"])
	if(!item_index || item_index < 1 || item_index > length(catalog_items))
		return

	var/list/entry = catalog_items[item_index]
	var/cost = entry["cost"]
	var/path = entry["path"]
	var/amount = entry["amount"]

	if(!ishuman(usr))
		return
	var/mob/living/carbon/human/buyer = usr
	var/obj/item/card/id/id = buyer.get_idcard(TRUE)
	if(!id?.registered_account)
		to_chat(buyer, span_warning("No registered bank account found."))
		return
	if(!id.registered_account.has_money(cost))
		to_chat(buyer, span_warning("Insufficient funds. Need [cost] Ahn."))
		return
	id.registered_account.adjust_money(-cost)
	var/spawned = 0
	for(var/i in 1 to amount)
		var/obj/item/new_item = new path(get_turf(buyer))
		if(new_item)
			buyer.put_in_hands(new_item)
			spawned++
	if(spawned > 1)
		to_chat(buyer, span_notice("Purchased [spawned]x [entry["name"]] for [cost] Ahn."))
	else
		to_chat(buyer, span_notice("Purchased [entry["name"]] for [cost] Ahn."))
	. = TRUE
