/**
 * Resurgence Outpost - Comms Console
 *
 * Wall-mounted console for trading with external factions.
 * Must be placed in an Export Warehouse room to function.
 */

/obj/structure/comms_console
	name = "comms console"
	desc = "A wall-mounted communications console for trading with external factions. Must be placed in an Export Warehouse room to function."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "req_comp0"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER

	/// Direction this console is facing (towards the room, away from wall)
	var/wall_dir = SOUTH

	/// Last scan results: closet ref -> list of item data
	var/list/last_scan_results

	/// Currently selected closets for sale
	var/list/selected_for_sale = list()

	/// Whether a transaction is in progress
	var/busy = FALSE

	/// Shopping cart for purchases: list of (type, quantity, price)
	var/list/shopping_cart = list()

	/// Timestamp when faction was connected (for static fade effect)
	var/connection_time = 0

/obj/structure/comms_console/Initialize(mapload)
	. = ..()
	apply_wall_offset()

/obj/structure/comms_console/examine(mob/user)
	. = ..()
	if(!is_in_export_warehouse())
		. += span_warning("This console is not in an Export Warehouse room. Designate the room first.")
	else
		. += span_notice("Click to open the trading interface.")
	. += span_notice("Outpost Credits: [GLOB.resurgence_credits]")

/// Apply pixel offset to hug the wall
/obj/structure/comms_console/proc/apply_wall_offset()
	switch(wall_dir)
		if(NORTH)
			pixel_y = 32
			pixel_x = 0
		if(SOUTH)
			pixel_y = -32
			pixel_x = 0
		if(EAST)
			pixel_x = 32
			pixel_y = 0
		if(WEST)
			pixel_x = -32
			pixel_y = 0

/// Check if in Export Warehouse
/obj/structure/comms_console/proc/is_in_export_warehouse()
	var/area/resurgence_outpost/room/R = get_area(src)
	if(!istype(R))
		return FALSE
	return R.room_type == ROOM_TYPE_EXPORT_WAREHOUSE

/// Get the warehouse room
/obj/structure/comms_console/proc/get_warehouse_room()
	var/area/resurgence_outpost/room/R = get_area(src)
	if(!istype(R) || R.room_type != ROOM_TYPE_EXPORT_WAREHOUSE)
		return null
	return R

/obj/structure/comms_console/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(!is_in_export_warehouse())
		to_chat(user, span_warning("This console must be in an Export Warehouse room."))
		return

	ui_interact(user)

// ===== TGUI Interface =====

/obj/structure/comms_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceTrading", "Comms Console - Trade Terminal")
		ui.open()

/obj/structure/comms_console/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/resurgence_trading)
	)

/obj/structure/comms_console/ui_data(mob/user)
	var/list/data = list()

	data["in_warehouse"] = is_in_export_warehouse()
	data["busy"] = busy
	data["credits"] = GLOB.resurgence_credits
	data["connection_time"] = connection_time
	data["current_time"] = world.time

	// Connected faction data
	var/datum/trading_faction/connected = GLOB.resurgence_trading.connected_faction
	if(connected)
		data["connected_faction"] = list(
			"id" = connected.id,
			"name" = connected.name,
			"desc" = connected.desc,
			"speaker_name" = connected.speaker_name,
			"speaker_title" = connected.speaker_title,
			"speaker_portrait" = connected.speaker_portrait,
			"current_dialogue" = connected.get_current_dialogue(),
			"reputation" = connected.reputation,
			"reputation_label" = connected.get_reputation_label(),
			"current_cash" = connected.current_cash,
			"max_cash" = connected.max_cash,
			"can_trade" = connected.can_trade
		)
	else
		data["connected_faction"] = null

	// All factions list
	data["factions"] = list()
	for(var/datum/trading_faction/F in GLOB.resurgence_trading.factions)
		// Show ??? for undiscovered factions
		var/display_name = F.discovered ? F.name : "???"
		var/display_desc = F.discovered ? F.desc : "An unknown faction. Connect to learn more."
		var/display_speaker = F.discovered ? F.speaker_name : "???"
		data["factions"] += list(list(
			"id" = F.id,
			"name" = display_name,
			"desc" = display_desc,
			"speaker_name" = display_speaker,
			"reputation" = F.discovered ? F.reputation : 0,
			"reputation_label" = F.discovered ? F.get_reputation_label() : "???",
			"current_cash" = F.discovered ? F.current_cash : 0,
			"max_cash" = F.discovered ? F.max_cash : 0,
			"can_trade" = F.can_trade,
			"is_connected" = (F == connected),
			"discovered" = F.discovered
		))

	// Scanned closets for selling
	data["scanned_closets"] = list()
	if(last_scan_results && connected)
		for(var/obj/structure/closet/C in last_scan_results)
			if(QDELETED(C))
				continue
			var/list/closet_data = list(
				"ref" = REF(C),
				"name" = C.name,
				"items" = list(),
				"selected" = (C in selected_for_sale),
				"total_value" = 0
			)
			var/closet_total = 0
			for(var/list/item_data in last_scan_results[C])
				var/item_value = item_data["value"] * connected.get_sell_modifier()
				closet_total += round(item_value)
				closet_data["items"] += list(list(
					"name" = item_data["name"],
					"count" = item_data["count"],
					"value" = round(item_value)
				))
			closet_data["total_value"] = closet_total
			data["scanned_closets"] += list(closet_data)

	// Calculate selected total
	var/selected_total = 0
	if(connected)
		for(var/obj/structure/closet/C in selected_for_sale)
			if(QDELETED(C) || !(C in last_scan_results))
				continue
			for(var/list/item_data in last_scan_results[C])
				selected_total += round(item_data["value"] * connected.get_sell_modifier())
	data["selected_total"] = selected_total

	// Faction stock for buying
	data["faction_stock"] = list()
	if(connected && connected.can_trade)
		for(var/list/stock_item in connected.stock)
			var/buy_price = get_item_buy_value(stock_item["base_price"], connected)
			data["faction_stock"] += list(list(
				"type" = "[stock_item["type"]]",
				"name" = stock_item["name"],
				"quantity" = stock_item["quantity"],
				"price" = buy_price
			))

	// Shopping cart
	data["cart"] = shopping_cart.Copy()
	var/cart_total = 0
	for(var/list/cart_item in shopping_cart)
		cart_total += cart_item["total"]
	data["cart_total"] = cart_total

	return data

/obj/structure/comms_console/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		// Faction connection
		if("connect")
			var/faction_id = params["faction"]
			if(GLOB.resurgence_trading.connect_faction(faction_id))
				var/datum/trading_faction/F = GLOB.resurgence_trading.connected_faction
				if(F)
					playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)
					// Mark faction as discovered on first connection
					F.discovered = TRUE
				// Set connection time for static fade effect
				connection_time = world.time
				// Clear previous scan/cart when switching factions
				last_scan_results = null
				selected_for_sale = list()
				shopping_cart = list()
			return TRUE

		if("disconnect")
			GLOB.resurgence_trading.disconnect_faction()
			connection_time = 0
			last_scan_results = null
			selected_for_sale = list()
			shopping_cart = list()
			return TRUE

		// Selling
		if("scan")
			scan_warehouse()
			return TRUE

		if("toggle_select")
			var/ref = params["ref"]
			var/obj/structure/closet/C = locate(ref)
			if(C && !QDELETED(C) && (C in last_scan_results))
				if(C in selected_for_sale)
					selected_for_sale -= C
				else
					selected_for_sale += C
			return TRUE

		if("select_all")
			selected_for_sale = list()
			if(last_scan_results)
				for(var/obj/structure/closet/C in last_scan_results)
					if(!QDELETED(C))
						selected_for_sale += C
			return TRUE

		if("deselect_all")
			selected_for_sale = list()
			return TRUE

		if("sell")
			if(!busy && length(selected_for_sale))
				sell_selected(usr)
			return TRUE

		// Buying
		if("add_to_cart")
			var/item_type = params["type"]
			var/quantity = text2num(params["quantity"])
			add_to_cart(item_type, quantity)
			return TRUE

		if("remove_from_cart")
			var/item_type = params["type"]
			remove_from_cart(item_type)
			return TRUE

		if("clear_cart")
			shopping_cart = list()
			return TRUE

		if("purchase")
			if(!busy && length(shopping_cart))
				purchase_cart(usr)
			return TRUE

	return FALSE

// ===== Warehouse Scanning =====

/obj/structure/comms_console/proc/scan_warehouse()
	var/area/resurgence_outpost/room/warehouse = get_warehouse_room()
	if(!warehouse)
		return

	last_scan_results = list()
	selected_for_sale = list()

	for(var/turf/T in warehouse.contents)
		for(var/obj/structure/closet/C in T)
			if(QDELETED(C))
				continue

			// Aggregate items by name to combine duplicates
			var/list/item_aggregates = list()  // name -> list(count, total_value)

			for(var/obj/item/I in C.contents)
				var/base_value = get_item_trade_value(I)
				var/item_count = 1
				var/item_name = I.name

				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					item_count = S.amount
					base_value *= item_count

				// Aggregate by name
				if(item_name in item_aggregates)
					item_aggregates[item_name]["count"] += item_count
					item_aggregates[item_name]["value"] += base_value
				else
					item_aggregates[item_name] = list(
						"count" = item_count,
						"value" = base_value
					)

			// Convert aggregates to item list
			var/list/item_list = list()
			for(var/item_name in item_aggregates)
				item_list += list(list(
					"name" = item_name,
					"count" = item_aggregates[item_name]["count"],
					"value" = item_aggregates[item_name]["value"]
				))

			if(length(item_list))
				last_scan_results[C] = item_list

	playsound(src, 'sound/machines/terminal_prompt.ogg', 25, TRUE)

// ===== Selling =====

/obj/structure/comms_console/proc/sell_selected(mob/user)
	if(busy)
		return
	if(!length(selected_for_sale))
		to_chat(user, span_warning("No containers selected for sale."))
		return

	var/datum/trading_faction/faction = GLOB.resurgence_trading.connected_faction
	if(!faction || !faction.can_trade)
		to_chat(user, span_warning("Not connected to a trading faction."))
		return

	// Calculate total value
	var/total_value = 0
	for(var/obj/structure/closet/C in selected_for_sale)
		if(QDELETED(C) || !(C in last_scan_results))
			continue
		for(var/list/item_data in last_scan_results[C])
			total_value += round(item_data["value"] * faction.get_sell_modifier())

	// Check if faction can afford
	if(faction.current_cash < total_value)
		to_chat(user, span_warning("[faction.name] cannot afford this sale. They only have [faction.current_cash] credits."))
		return

	busy = TRUE
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)

	// Export each container with animation
	var/list/to_sell = selected_for_sale.Copy()
	for(var/obj/structure/closet/C in to_sell)
		if(QDELETED(C))
			continue
		fulton_export(C, faction)
		sleep(5)

	// Add credits and adjust reputation
	GLOB.resurgence_trading.add_credits(total_value)
	faction.current_cash -= total_value

	// Calculate and apply rep gain based on transaction value
	var/rep_gain = faction.on_trade_completed(total_value, TRUE)

	// Show result message with rep gain info
	if(rep_gain > 0)
		to_chat(user, span_notice("Sale complete! Earned [total_value] credits. (+[rep_gain] reputation with [faction.name])"))
	else
		to_chat(user, span_notice("Sale complete! Earned [total_value] credits."))

	// Clear and rescan
	selected_for_sale = list()
	last_scan_results = list()
	busy = FALSE
	scan_warehouse()

/obj/structure/comms_console/proc/fulton_export(obj/structure/closet/target, datum/trading_faction/faction)
	if(QDELETED(target))
		return

	var/turf/T = get_turf(target)

	// Create balloon effect
	var/mutable_appearance/balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_expand")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	target.add_overlay(balloon)

	playsound(T, 'sound/items/fultext_deploy.ogg', 50, TRUE, -3)
	sleep(4)

	target.cut_overlay(balloon)
	balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	target.add_overlay(balloon)

	animate(target, pixel_z = 10, time = 10)
	sleep(10)
	animate(target, pixel_z = 20, time = 10)
	sleep(10)

	playsound(T, 'sound/items/fultext_launch.ogg', 50, TRUE, -3)
	animate(target, pixel_z = 200, alpha = 0, time = 20)
	sleep(20)

	// Delete contents first
	for(var/atom/movable/AM in target.contents)
		qdel(AM)
	qdel(target)

// ===== Buying =====

/obj/structure/comms_console/proc/add_to_cart(item_type_str, quantity)
	var/datum/trading_faction/faction = GLOB.resurgence_trading.connected_faction
	if(!faction || !faction.can_trade)
		return

	// Find the stock item
	for(var/list/stock_item in faction.stock)
		if("[stock_item["type"]]" == item_type_str)
			var/available = stock_item["quantity"]
			quantity = clamp(quantity, 1, available)

			var/buy_price = get_item_buy_value(stock_item["base_price"], faction)
			var/total = buy_price * quantity

			// Check if already in cart
			for(var/list/cart_item in shopping_cart)
				if(cart_item["type"] == item_type_str)
					// Update existing entry
					var/new_qty = min(cart_item["quantity"] + quantity, available)
					cart_item["quantity"] = new_qty
					cart_item["total"] = buy_price * new_qty
					return

			// Add new entry
			shopping_cart += list(list(
				"type" = item_type_str,
				"name" = stock_item["name"],
				"quantity" = quantity,
				"price" = buy_price,
				"total" = total
			))
			return

/obj/structure/comms_console/proc/remove_from_cart(item_type_str)
	for(var/list/cart_item in shopping_cart)
		if(cart_item["type"] == item_type_str)
			shopping_cart -= list(cart_item)
			return

/obj/structure/comms_console/proc/purchase_cart(mob/user)
	if(busy)
		return
	if(!length(shopping_cart))
		to_chat(user, span_warning("Shopping cart is empty."))
		return

	var/datum/trading_faction/faction = GLOB.resurgence_trading.connected_faction
	if(!faction || !faction.can_trade)
		to_chat(user, span_warning("Not connected to a trading faction."))
		return

	// Calculate total cost and item count
	var/total_cost = 0
	var/total_items = 0
	for(var/list/cart_item in shopping_cart)
		total_cost += cart_item["total"]
		total_items += cart_item["quantity"]

	// Check credits
	if(GLOB.resurgence_credits < total_cost)
		to_chat(user, span_warning("Not enough credits! Need [total_cost], have [GLOB.resurgence_credits]."))
		return

	// Verify stock availability
	for(var/list/cart_item in shopping_cart)
		var/found = FALSE
		for(var/list/stock_item in faction.stock)
			if("[stock_item["type"]]" == cart_item["type"])
				if(stock_item["quantity"] < cart_item["quantity"])
					to_chat(user, span_warning("Not enough [cart_item["name"]] in stock!"))
					return
				found = TRUE
				break
		if(!found)
			to_chat(user, span_warning("[cart_item["name"]] is no longer available!"))
			return

	busy = TRUE

	// Deduct credits
	GLOB.resurgence_trading.remove_credits(total_cost)
	faction.current_cash += total_cost

	// Create delivery crate with appropriate size
	var/turf/spawn_turf = get_turf(src)
	var/obj/structure/closet/crate/resurgence_delivery/delivery = new(spawn_turf)

	// Set size tier based on item count and cost
	var/size_tier = get_delivery_size_tier(total_items, total_cost)
	delivery.set_size_tier(size_tier)

	// Start off-screen for animation
	delivery.pixel_z = 200
	delivery.alpha = 0

	// Spawn items into crate
	for(var/list/cart_item in shopping_cart)
		for(var/list/stock_item in faction.stock)
			if("[stock_item["type"]]" == cart_item["type"])
				var/item_path = stock_item["type"]
				var/qty = cart_item["quantity"]

				// Reduce stock
				stock_item["quantity"] -= qty

				// Spawn items
				if(ispath(item_path, /obj/item/stack))
					new item_path(delivery, qty)
				else
					for(var/i in 1 to qty)
						new item_path(delivery)
				break

	// Generate and attach note from faction
	var/obj/item/paper/note = generate_faction_note(faction, total_cost)
	if(note)
		delivery.attach_note(note)

	// Delivery animation
	var/mutable_appearance/chute = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
	chute.pixel_y = 10
	delivery.add_overlay(chute)

	playsound(src, 'sound/items/fultext_launch.ogg', 50, TRUE)

	animate(delivery, pixel_z = 100, alpha = 255, time = 10)
	sleep(10)
	animate(delivery, pixel_z = 0, time = 20, easing = BOUNCE_EASING)
	sleep(20)

	delivery.cut_overlay(chute)
	playsound(src, 'sound/weapons/thudswoosh.ogg', 30, TRUE)

	// Calculate and apply rep gain based on transaction value
	var/rep_gain = faction.on_trade_completed(total_cost, FALSE)

	// Show result message with rep gain info
	if(rep_gain > 0)
		to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits. Delivery has arrived. (+[rep_gain] reputation with [faction.name])"))
	else
		to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits. Delivery has arrived."))

	shopping_cart = list()
	busy = FALSE

/// Determine delivery size tier based on item count and cost
/obj/structure/comms_console/proc/get_delivery_size_tier(total_items, total_cost)
	// Size tiers 1-6 based on order size
	// Combine both metrics for a balanced assessment
	if(total_items <= 3 && total_cost < 50)
		return 1  // Smallest - deliverypackage1
	else if(total_items <= 8 && total_cost < 150)
		return 2  // Small - deliverypackage2
	else if(total_items <= 15 && total_cost < 300)
		return 3  // Medium - deliverypackage3
	else if(total_items <= 30 && total_cost < 500)
		return 4  // Large - deliverypackage4
	else if(total_items <= 50 && total_cost < 800)
		return 5  // Very Large - deliverypackage5
	else
		return 6  // Huge - deliverybox
