// Caravan Trader NPC
// Interactive trader found in caravan encounters

/**
 * Caravan Trader NPC
 *
 * A trader NPC that spawns during caravan encounters.
 * Uses the same TGUI interface as faction hub traders.
 */
/mob/living/simple_animal/caravan_trader
	name = "Caravan Trader"
	desc = "A traveling merchant."
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

	/// The caravan this trader represents
	var/datum/faction_caravan/caravan
	/// Reference to the faction datum (from caravan's owner)
	var/datum/trading_faction/trading_faction
	/// Faction ID string
	var/faction_id = null
	/// Idle dialogue lines to say randomly
	var/list/idle_lines = list()
	/// Time of last idle chat
	var/last_idle_chat = 0
	/// Minimum time between idle chats (in deciseconds)
	var/idle_chat_interval = 300  // 30 seconds
	/// Speech bubble icon state
	var/speech_bubble_type = "default2"

	// Trading state
	/// Last scan results: crate ref -> list of item data
	var/list/last_scan_results
	/// Currently selected crates for sale
	var/list/selected_for_sale = list()
	/// Whether a transaction is in progress
	var/busy = FALSE
	/// Shopping cart for purchases: list of (type, quantity, price)
	var/list/shopping_cart = list()

/mob/living/simple_animal/caravan_trader/Initialize(mapload)
	. = ..()
	// Add speech bubble overlay
	add_overlay(mutable_appearance('icons/mob/talk.dmi', speech_bubble_type, ABOVE_MOB_LAYER))

	// Set up idle chat
	setup_idle_lines()
	START_PROCESSING(SSobj, src)

/mob/living/simple_animal/caravan_trader/Destroy()
	STOP_PROCESSING(SSobj, src)
	caravan = null
	trading_faction = null
	last_scan_results = null
	selected_for_sale = null
	shopping_cart = null
	return ..()

/**
 * Link this trader to a caravan
 */
/mob/living/simple_animal/caravan_trader/proc/link_caravan(datum/faction_caravan/C)
	if(!C)
		return
	caravan = C
	faction_id = C.faction_id
	trading_faction = C.owner_faction

	if(trading_faction)
		name = "[trading_faction.speaker_name]"
		desc = "A traveling merchant representing [trading_faction.name]."
	else
		name = "Caravan Trader"
		desc = "A traveling merchant."

	setup_appearance()
	setup_idle_lines()

/**
 * Set up appearance based on faction
 * Uses the same sprites as faction hub traders
 */
/mob/living/simple_animal/caravan_trader/proc/setup_appearance()
	switch(faction_id)
		if("resurgence_clan")
			icon = 'ModularLobotomy/_Lobotomyicons/resurgence_32x48.dmi'
			icon_state = "clan_citzen_trader"
		if("jiajia_ren")
			icon = 'icons/mob/cuckoospawn.dmi'
			icon_state = "cuckoospawn"
		if("santata_factory")
			icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
			icon_state = "gnome_red"
			mob_size = MOB_SIZE_SMALL
		if("cloud_town")
			icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
			icon_state = "cloud_trader"

/**
 * Set up idle dialogue lines based on faction
 */
/mob/living/simple_animal/caravan_trader/proc/setup_idle_lines()
	switch(faction_id)
		if("resurgence_clan")
			idle_lines = list(
				"The road is lo-ong but the trade is go-ood!",
				"We-elcome, traveler!",
				"Ta-ake a look at our wa-ares."
			)
		if("jiajia_ren")
			idle_lines = list(
				"*Click-click* Good trades today!",
				"*Trill* Flock brings finest goods!",
				"*Whistle* What catches your eye?"
			)
		if("santata_factory")
			idle_lines = list(
				"Factory goods-ome! Best quality-ome!",
				"Need tools-ome? We have plenty-ome!",
				"Production never stops-ome!"
			)
		if("cloud_town")
			idle_lines = list(
				"Fresh supplies from Cloud Town.",
				"Fair prices for fair goods.",
				"Take a look, traveler."
			)
		else
			idle_lines = list(
				"Looking for something?",
				"Take your time browsing.",
				"Let me know if you need anything."
			)

/mob/living/simple_animal/caravan_trader/process(delta_time)
	// Random idle chat
	if(world.time - last_idle_chat > idle_chat_interval && prob(5))
		idle_chat()

/**
 * Say a random idle line
 */
/mob/living/simple_animal/caravan_trader/proc/idle_chat()
	if(!length(idle_lines))
		return
	last_idle_chat = world.time
	var/line = pick(idle_lines)
	say(line)

/**
 * Handle being clicked on
 */
/mob/living/simple_animal/caravan_trader/attack_hand(mob/living/carbon/human/user, list/modifiers)
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
/mob/living/simple_animal/caravan_trader/examine(mob/user)
	. = ..()
	if(caravan)
		. += span_notice("Click to open the trading interface.")
		. += span_notice("You can sell items from crates placed nearby.")

// ===== TGUI Interface =====

/mob/living/simple_animal/caravan_trader/ui_interact(mob/user, datum/tgui/ui)
	if(!caravan)
		to_chat(user, span_warning("[src] doesn't seem to have anything to trade."))
		return

	if(caravan.is_hostile())
		to_chat(user, span_warning("[src] refuses to trade with you."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		// Greet the player only on first interaction (new UI)
		if(trading_faction)
			say(trading_faction.get_dialogue("greeting"))
		else
			say("Welcome, traveler!")
		ui = new(user, src, "FactionTrader", "[name] - Trading")
		ui.open()

/mob/living/simple_animal/caravan_trader/ui_data(mob/user)
	var/list/data = list()

	data["trader_name"] = name
	data["trader_title"] = "Traveling Merchant"
	data["faction_name"] = trading_faction?.name || "Traveling Caravan"
	data["can_trade"] = caravan && !caravan.is_hostile()
	data["credits"] = GLOB.resurgence_credits
	data["discount_percent"] = 0  // No discount for caravan trading
	data["busy"] = busy
	data["faction_cash"] = caravan?.caravan_cash || 0

	// Caravan stock for buying (convert from caravan format)
	data["faction_stock"] = list()
	if(caravan && !caravan.is_hostile())
		for(var/item_path in caravan.stock)
			var/quantity = caravan.stock[item_path]
			if(quantity <= 0)
				continue
			var/obj/item/temp = item_path
			var/base_price = caravan.get_item_price(item_path)
			// Minimum price of 3
			var/buy_price = max(3, base_price)
			data["faction_stock"] += list(list(
				"type" = "[item_path]",
				"name" = initial(temp.name),
				"quantity" = quantity,
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
	if(last_scan_results && caravan)
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
	if(caravan)
		var/sell_mod = get_sell_modifier()
		for(var/obj/structure/closet/C in selected_for_sale)
			if(QDELETED(C) || !(C in last_scan_results))
				continue
			for(var/list/item_data in last_scan_results[C])
				selected_total += round(item_data["value"] * sell_mod)
	data["selected_total"] = selected_total

	return data

/mob/living/simple_animal/caravan_trader/ui_act(action, params)
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

// ===== Sell Modifier =====

/mob/living/simple_animal/caravan_trader/proc/get_sell_modifier()
	if(!trading_faction)
		return 1.0
	return trading_faction.get_sell_modifier()

// ===== Cart Management =====

/mob/living/simple_animal/caravan_trader/proc/add_to_cart(item_type_str, quantity, mob/buyer = null)
	if(!caravan)
		return

	// Find the stock item (caravan format: stock[path] = quantity)
	var/item_path = text2path(item_type_str)
	if(!item_path || !(item_path in caravan.stock))
		return

	var/available = caravan.stock[item_path]
	quantity = clamp(quantity, 1, available)

	var/base_price = caravan.get_item_price(item_path)
	var/buy_price = max(3, base_price)
	var/total = buy_price * quantity

	var/obj/item/temp = item_path
	var/item_name = initial(temp.name)

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
		"name" = item_name,
		"quantity" = quantity,
		"price" = buy_price,
		"total" = total
	))

/mob/living/simple_animal/caravan_trader/proc/remove_from_cart(item_type_str)
	for(var/list/cart_item in shopping_cart)
		if(cart_item["type"] == item_type_str)
			shopping_cart -= list(cart_item)
			return

/mob/living/simple_animal/caravan_trader/proc/purchase_cart(mob/user)
	if(busy)
		return
	if(!length(shopping_cart))
		to_chat(user, span_warning("Shopping cart is empty."))
		return

	if(!caravan)
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
		var/item_path = text2path(cart_item["type"])
		if(!item_path || !(item_path in caravan.stock))
			to_chat(user, span_warning("[cart_item["name"]] is no longer available!"))
			return
		if(caravan.stock[item_path] < cart_item["quantity"])
			to_chat(user, span_warning("Not enough [cart_item["name"]] in stock!"))
			return

	busy = TRUE

	// Deduct credits
	GLOB.resurgence_trading.remove_credits(total_cost)
	caravan.caravan_cash += total_cost

	// Create an expedition crate to hold the purchased items
	var/obj/structure/closet/crate/expedition/purchase_crate = new(get_turf(user))
	purchase_crate.name = "caravan trader's crate"
	purchase_crate.desc = "A crate provided by the caravan trader containing your purchased goods."

	// Spawn items inside the crate and reduce stock
	for(var/list/cart_item in shopping_cart)
		var/item_path = text2path(cart_item["type"])
		var/qty = cart_item["quantity"]

		// Reduce stock
		caravan.stock[item_path] -= qty
		if(caravan.stock[item_path] <= 0)
			caravan.stock -= item_path

		// Spawn items inside the crate
		if(ispath(item_path, /obj/item/stack))
			new item_path(purchase_crate, qty)
		else
			for(var/i in 1 to qty)
				new item_path(purchase_crate)

	// Open the crate so player can see contents
	purchase_crate.open(user)

	// Calculate and apply rep gain
	if(trading_faction)
		var/rep_gain = trading_faction.on_trade_completed(total_cost, FALSE)
		if(rep_gain > 0)
			to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits. (+[rep_gain] reputation)"))
		else
			to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits."))
	else
		to_chat(user, span_notice("Purchase complete! Spent [total_cost] credits."))

	// Say dialogue
	if(trading_faction)
		say(trading_faction.get_dialogue("purchase_complete"))
	else
		say("Pleasure doing business!")

	// Award social XP
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/xp_amount = max(1, round(total_cost / 10))
			core.award_xp("social", xp_amount)

	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, TRUE)
	shopping_cart = list()
	busy = FALSE

// ===== Crate Scanning =====

/mob/living/simple_animal/caravan_trader/proc/scan_nearby_crates()
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

/mob/living/simple_animal/caravan_trader/proc/sell_selected(mob/user)
	if(busy)
		return
	if(!length(selected_for_sale))
		to_chat(user, span_warning("No crates selected for sale."))
		return

	if(!caravan)
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

	// Check if caravan can afford
	if(caravan.caravan_cash < total_value)
		to_chat(user, span_warning("The caravan cannot afford this sale. They only have [caravan.caravan_cash] credits."))
		if(trading_faction)
			say(trading_faction.get_dialogue("low_stock"))
		else
			say("I don't have enough money for that...")
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

	// Add credits and deduct from caravan
	GLOB.resurgence_trading.add_credits(total_value)
	caravan.caravan_cash -= total_value

	// Calculate and apply rep gain
	if(trading_faction)
		var/rep_gain = trading_faction.on_trade_completed(total_value, TRUE)
		if(rep_gain > 0)
			to_chat(user, span_notice("Sale complete! Earned [total_value] credits. (+[rep_gain] reputation with [trading_faction.name])"))
		else
			to_chat(user, span_notice("Sale complete! Earned [total_value] credits."))
		say(trading_faction.get_dialogue("sale_complete"))
	else
		to_chat(user, span_notice("Sale complete! Earned [total_value] credits."))
		say("Thanks for the goods!")

	// Award social XP
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/xp_amount = max(1, round(total_value / 10))
			core.award_xp("social", xp_amount)

	// Clear and rescan
	selected_for_sale = list()
	last_scan_results = list()
	busy = FALSE
	scan_nearby_crates()
