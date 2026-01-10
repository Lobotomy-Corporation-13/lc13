// Faction Trader NPC
// Interactive traders found in faction hubs

/**
 * Faction Trader NPC
 *
 * A friendly NPC that handles in-person trading at faction hubs.
 * Players can interact with them to open the trading interface.
 */
/mob/living/simple_animal/faction_trader
	name = "Trader"
	desc = "A faction representative who handles trading."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "faceless"
	icon_living = "faceless"
	maxHealth = 200
	health = 200

	// Non-hostile, doesn't move
	wander = FALSE
	density = TRUE
	anchored = FALSE
	mob_size = MOB_SIZE_HUMAN
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID

	// Interaction
	response_help_continuous = "greets"
	response_help_simple = "greet"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"

	// Speech
	speak_emote = list("says")
	verb_say = "says"
	verb_ask = "asks"
	verb_exclaim = "exclaims"

	/// The faction this trader represents
	var/faction_id = null
	/// Reference to the faction datum
	var/datum/trading_faction/trading_faction
	/// Reference to the hub controller
	var/datum/faction_hub_controller/controller
	/// Idle dialogue lines to say randomly
	var/list/idle_lines = list()
	/// Time of last idle chat
	var/last_idle_chat = 0
	/// Minimum time between idle chats (in deciseconds)
	var/idle_chat_interval = 300  // 30 seconds
	/// Speech bubble icon state
	var/speech_bubble_type = "default2"

	// Trading state (per-user tracking via weak refs)
	/// Last scan results: crate ref -> list of item data
	var/list/last_scan_results
	/// Currently selected crates for sale
	var/list/selected_for_sale = list()
	/// Whether a transaction is in progress
	var/busy = FALSE
	/// Shopping cart for purchases: list of (type, quantity, price)
	var/list/shopping_cart = list()

/mob/living/simple_animal/faction_trader/Initialize(mapload)
	. = ..()
	// Find our faction
	if(faction_id && GLOB.resurgence_trading)
		trading_faction = GLOB.resurgence_trading.get_faction(faction_id)
		if(trading_faction)
			name = trading_faction.speaker_name
			desc = "[trading_faction.speaker_title]. They represent [trading_faction.name]."

	// Add speech bubble overlay to indicate this NPC can be talked to
	add_overlay(mutable_appearance('icons/mob/talk.dmi', speech_bubble_type, ABOVE_MOB_LAYER))

	// Set up idle chat
	setup_idle_lines()
	START_PROCESSING(SSobj, src)

/mob/living/simple_animal/faction_trader/Destroy()
	STOP_PROCESSING(SSobj, src)
	trading_faction = null
	controller = null
	last_scan_results = null
	selected_for_sale = null
	shopping_cart = null
	return ..()

/**
 * Set up idle dialogue lines based on faction
 */
/mob/living/simple_animal/faction_trader/proc/setup_idle_lines()
	idle_lines = list(
		"Looking for something?",
		"Take your time browsing.",
		"Let me know if you need anything."
	)

/mob/living/simple_animal/faction_trader/process(delta_time)
	// Random idle chat
	if(world.time - last_idle_chat > idle_chat_interval && prob(5))
		idle_chat()

/**
 * Say a random idle line
 */
/mob/living/simple_animal/faction_trader/proc/idle_chat()
	if(!length(idle_lines))
		return
	last_idle_chat = world.time
	var/line = pick(idle_lines)
	say(line)

/**
 * Handle being clicked on
 */
/mob/living/simple_animal/faction_trader/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(!isliving(user))
		return ..()

	if(stat == DEAD)
		return ..()

	// Open trading interface
	ui_interact(user)
	return TRUE

/**
 * Handle being examined
 */
/mob/living/simple_animal/faction_trader/examine(mob/user)
	. = ..()
	if(trading_faction)
		. += span_notice("Click to open the trading interface.")
		. += span_notice("Trading here gives you a 10% discount on purchases!")
		. += span_notice("You can sell items from crates placed nearby.")

// ===== TGUI Interface =====

/mob/living/simple_animal/faction_trader/ui_interact(mob/user, datum/tgui/ui)
	if(!trading_faction)
		to_chat(user, span_warning("[src] doesn't seem to have anything to trade."))
		return

	if(!trading_faction.can_trade)
		to_chat(user, span_warning("[src] refuses to trade with you."))
		say(trading_faction.get_dialogue("low_rep"))
		return

	// Greet the player on first interaction
	say(trading_faction.get_dialogue("greeting"))

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FactionTrader", "[name] - Trading")
		ui.open()

/mob/living/simple_animal/faction_trader/ui_data(mob/user)
	var/list/data = list()

	data["trader_name"] = name
	data["trader_title"] = trading_faction?.speaker_title || "Trader"
	data["faction_name"] = trading_faction?.name || "Unknown"
	data["can_trade"] = trading_faction?.can_trade || FALSE
	data["credits"] = GLOB.resurgence_credits
	data["discount_percent"] = round((1 - HUB_TRADING_DISCOUNT) * 100)
	data["busy"] = busy
	data["faction_cash"] = trading_faction?.current_cash || 0

	// Faction stock for buying
	data["faction_stock"] = list()
	if(trading_faction?.can_trade)
		var/buy_mod = get_buy_modifier()
		for(var/list/stock_item in trading_faction.stock)
			if(stock_item["quantity"] <= 0)
				continue
			// Minimum price of 3 even with discounts
			var/buy_price = max(3, round(stock_item["base_price"] * buy_mod))
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

	// Scanned crates for selling
	data["scanned_crates"] = list()
	if(last_scan_results && trading_faction)
		for(var/obj/structure/closet/C in last_scan_results)
			if(QDELETED(C))
				continue
			var/list/crate_data = list(
				"ref" = REF(C),
				"name" = C.name,
				"items" = list(),
				"selected" = (C in selected_for_sale),
				"total_value" = 0
			)
			var/crate_total = 0
			var/sell_mod = get_sell_modifier()
			for(var/list/item_data in last_scan_results[C])
				var/item_value = round(item_data["value"] * sell_mod)
				crate_total += item_value
				crate_data["items"] += list(list(
					"name" = item_data["name"],
					"count" = item_data["count"],
					"value" = item_value
				))
			crate_data["total_value"] = crate_total
			data["scanned_crates"] += list(crate_data)

	// Calculate selected total
	var/selected_total = 0
	if(trading_faction)
		var/sell_mod = get_sell_modifier()
		for(var/obj/structure/closet/C in selected_for_sale)
			if(QDELETED(C) || !(C in last_scan_results))
				continue
			for(var/list/item_data in last_scan_results[C])
				selected_total += round(item_data["value"] * sell_mod)
	data["selected_total"] = selected_total

	return data

/mob/living/simple_animal/faction_trader/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!isliving(user))
		return

	if(get_dist(user, src) > 3)
		to_chat(user, span_warning("You're too far away!"))
		return

	switch(action)
		// Buying
		if("add_to_cart")
			var/item_type = params["type"]
			var/quantity = text2num(params["quantity"])
			add_to_cart(item_type, quantity, user)
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
				purchase_cart(user)
			return TRUE

		// Selling
		if("scan_crates")
			scan_nearby_crates()
			return TRUE

		if("toggle_crate")
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
				sell_selected(user)
			return TRUE

	return FALSE

// ===== Buy Modifier =====

/mob/living/simple_animal/faction_trader/proc/get_buy_modifier()
	if(!trading_faction)
		return 1.0
	return trading_faction.get_buy_modifier() * HUB_TRADING_DISCOUNT

// ===== Sell Modifier =====

/mob/living/simple_animal/faction_trader/proc/get_sell_modifier()
	if(!trading_faction)
		return 1.0
	// In-person selling gets a bonus (opposite of buy discount)
	return trading_faction.get_sell_modifier() * (1 + (1 - HUB_TRADING_DISCOUNT))

// ===== Cart Management =====

/mob/living/simple_animal/faction_trader/proc/add_to_cart(item_type_str, quantity, mob/buyer = null)
	if(!trading_faction || !trading_faction.can_trade)
		return

	// Find the stock item
	for(var/list/stock_item in trading_faction.stock)
		if("[stock_item["type"]]" == item_type_str)
			var/available = stock_item["quantity"]
			quantity = clamp(quantity, 1, available)

			// Minimum price of 3 even with discounts
			var/buy_price = max(3, round(stock_item["base_price"] * get_buy_modifier()))
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

/mob/living/simple_animal/faction_trader/proc/remove_from_cart(item_type_str)
	for(var/list/cart_item in shopping_cart)
		if(cart_item["type"] == item_type_str)
			shopping_cart -= list(cart_item)
			return

/mob/living/simple_animal/faction_trader/proc/purchase_cart(mob/user)
	if(busy)
		return
	if(!length(shopping_cart))
		to_chat(user, span_warning("Shopping cart is empty."))
		return

	if(!trading_faction || !trading_faction.can_trade)
		to_chat(user, span_warning("This trader cannot trade right now."))
		return

	// Calculate total cost
	var/total_cost = 0
	for(var/list/cart_item in shopping_cart)
		total_cost += cart_item["total"]

	// Check credits
	if(GLOB.resurgence_credits < total_cost)
		to_chat(user, span_warning("Not enough credits! Need [total_cost], have [GLOB.resurgence_credits]."))
		return

	// Verify stock availability
	for(var/list/cart_item in shopping_cart)
		var/found = FALSE
		for(var/list/stock_item in trading_faction.stock)
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
	trading_faction.current_cash += total_cost

	// Create an expedition crate to hold the purchased items
	var/obj/structure/closet/crate/expedition/purchase_crate = new(get_turf(user))
	purchase_crate.name = "trader's crate"
	purchase_crate.desc = "A crate provided by the trader containing your purchased goods. It will travel with you on expeditions."

	// Spawn items inside the crate and reduce stock
	for(var/list/cart_item in shopping_cart)
		for(var/list/stock_item in trading_faction.stock)
			if("[stock_item["type"]]" == cart_item["type"])
				var/item_path = stock_item["type"]
				var/qty = cart_item["quantity"]

				// Reduce stock
				stock_item["quantity"] -= qty

				// Spawn items inside the crate
				if(ispath(item_path, /obj/item/stack))
					new item_path(purchase_crate, qty)
				else
					for(var/i in 1 to qty)
						new item_path(purchase_crate)
				break

	// Open the crate so player can see contents
	purchase_crate.open(user)

	// Calculate and apply rep gain
	var/rep_gain = trading_faction.on_trade_completed(total_cost, FALSE)

	// Say dialogue
	say(trading_faction.get_dialogue("purchase_complete"))

	// Award social XP
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/xp_amount = max(1, round(total_cost / 10))
			core.award_xp("social", xp_amount)

	if(rep_gain > 0)
		to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits. (+[rep_gain] reputation)"))
	else
		to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits."))
	to_chat(user, span_notice("Your items have been placed in a crate that will travel with you on your expedition."))

	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)
	shopping_cart = list()
	busy = FALSE

// ===== Crate Scanning =====

/mob/living/simple_animal/faction_trader/proc/scan_nearby_crates()
	last_scan_results = list()
	selected_for_sale = list()

	// Scan for crates within 3 tiles
	for(var/obj/structure/closet/C in range(3, src))
		if(QDELETED(C))
			continue

		// Aggregate items by name
		var/list/item_aggregates = list()

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

/mob/living/simple_animal/faction_trader/proc/sell_selected(mob/user)
	if(busy)
		return
	if(!length(selected_for_sale))
		to_chat(user, span_warning("No crates selected for sale."))
		return

	if(!trading_faction || !trading_faction.can_trade)
		to_chat(user, span_warning("This trader cannot trade right now."))
		return

	// Calculate total value
	var/sell_mod = get_sell_modifier()
	var/total_value = 0
	for(var/obj/structure/closet/C in selected_for_sale)
		if(QDELETED(C) || !(C in last_scan_results))
			continue
		for(var/list/item_data in last_scan_results[C])
			total_value += round(item_data["value"] * sell_mod)

	// Check if faction can afford
	if(trading_faction.current_cash < total_value)
		to_chat(user, span_warning("[trading_faction.name] cannot afford this sale. They only have [trading_faction.current_cash] credits."))
		say(trading_faction.get_dialogue("low_stock"))
		return

	busy = TRUE
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)

	// Delete items from crates
	var/list/to_sell = selected_for_sale.Copy()
	for(var/obj/structure/closet/C in to_sell)
		if(QDELETED(C))
			continue
		// Delete all items in the crate
		for(var/obj/item/I in C.contents)
			qdel(I)

	// Add credits and adjust reputation
	GLOB.resurgence_trading.add_credits(total_value)
	trading_faction.current_cash -= total_value

	// Calculate and apply rep gain
	var/rep_gain = trading_faction.on_trade_completed(total_value, TRUE)

	// Say dialogue
	say(trading_faction.get_dialogue("sale_complete"))

	// Award social XP
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/xp_amount = max(1, round(total_value / 10))
			core.award_xp("social", xp_amount)

	if(rep_gain > 0)
		to_chat(user, span_notice("Sale complete! Earned [total_value] credits. (+[rep_gain] reputation with [trading_faction.name])"))
	else
		to_chat(user, span_notice("Sale complete! Earned [total_value] credits."))

	// Clear and rescan
	selected_for_sale = list()
	last_scan_results = list()
	busy = FALSE
	scan_nearby_crates()

// ============================================
// FACTION-SPECIFIC TRADERS
// ============================================

/mob/living/simple_animal/faction_trader/resurgence_clan
	name = "Ronan"
	desc = "A friendly clan trader running a humble shop."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_32x48.dmi'
	icon_state = "clan_citzen_trader"
	faction_id = "resurgence_clan"

/mob/living/simple_animal/faction_trader/resurgence_clan/Initialize(mapload)
	. = ..()
	// Override to keep Ronan's identity instead of The Historian
	name = "Ronan"
	desc = "Clan Trader. They represent [trading_faction?.name || "Resurgence Clan Village"]."

/mob/living/simple_animal/faction_trader/resurgence_clan/setup_idle_lines()
	idle_lines = list(
		"We-ell, Yo-ou may call me Ronan.",
		"Currently, I am ru-unning this humble sho-op for passerbys li-ike you!",
		"Ta-ake your ti-ime browsing.",
		"Le-et me know if you ne-eed anything.",
		"The vi-illage appreciates your bu-usiness.",
		"Hm... a-anything catch your eye?"
	)

/mob/living/simple_animal/faction_trader/jiajia_ren
	name = "Chir-rik"
	icon = 'icons/mob/cuckoospawn.dmi'
	icon_state = "cuckoospawn"
	faction_id = "jiajia_ren"

/mob/living/simple_animal/faction_trader/jiajia_ren/setup_idle_lines()
	idle_lines = list(
		"*Click-click* Shiny things, yes yes!",
		"*Trill* Flock has good trades today!",
		"*Whistle* You want feathers? Very soft!",
		"*Coo* Metal ones are funny. Chir-rik likes."
	)

/mob/living/simple_animal/faction_trader/santata_factory
	name = "Dodoru"
	faction_id = "santata_factory"
	icon_state = "faceless"

/mob/living/simple_animal/faction_trader/santata_factory/setup_idle_lines()
	idle_lines = list(
		"Production never stops-ome! Never-ome!",
		"You need tools-ome? We have the best-ome!",
		"The Factory provides-ome. Always provides-ome.",
		"Hehe-ome... busy busy-ome..."
	)

/mob/living/simple_animal/faction_trader/cloud_town
	name = "Domino"
	faction_id = "cloud_town"
	icon_state = "faceless"

/mob/living/simple_animal/faction_trader/cloud_town/setup_idle_lines()
	idle_lines = list(
		"Fair trade, fair prices. That's how we do things.",
		"Seeds are in season. Good time to stock up.",
		"Heard there's trouble in the wastes. Stay safe out there.",
		"The town's doing well. Trade's been good."
	)
