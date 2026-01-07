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

/mob/living/simple_animal/faction_trader/Initialize(mapload)
	. = ..()
	// Find our faction
	if(faction_id && GLOB.resurgence_trading)
		trading_faction = GLOB.resurgence_trading.get_faction(faction_id)
		if(trading_faction)
			name = trading_faction.speaker_name
			desc = "[trading_faction.speaker_title]. They represent [trading_faction.name]."

	// Set up idle chat
	setup_idle_lines()
	START_PROCESSING(SSobj, src)

/mob/living/simple_animal/faction_trader/Destroy()
	STOP_PROCESSING(SSobj, src)
	trading_faction = null
	controller = null
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
	open_trading(user)
	return TRUE

/**
 * Handle being examined
 */
/mob/living/simple_animal/faction_trader/examine(mob/user)
	. = ..()
	if(trading_faction)
		. += span_notice("Click to open the trading interface.")
		. += span_notice("Trading here gives you a 10% discount on purchases!")

/**
 * Open the trading interface for a user
 */
/mob/living/simple_animal/faction_trader/proc/open_trading(mob/living/user)
	if(!trading_faction)
		to_chat(user, span_warning("[src] doesn't seem to have anything to trade."))
		return

	if(!trading_faction.can_trade)
		to_chat(user, span_warning("[src] refuses to trade with you."))
		say(trading_faction.get_dialogue("low_rep"))
		return

	// Greet the player
	say(trading_faction.get_dialogue("greeting"))

	// Open trading UI
	// For now, just show a message - full UI would require TGUI integration
	var/html = get_trading_html(user)
	user << browse(html, "window=faction_trading_[faction_id];size=500x600;can_close=1;can_minimize=0;can_maximize=0;can_resize=0;titlebar=1")

/**
 * Generate trading HTML interface
 */
/mob/living/simple_animal/faction_trader/proc/get_trading_html(mob/living/user)
	var/buy_mod = controller ? controller.get_hub_buy_modifier() : (trading_faction.get_buy_modifier() * HUB_TRADING_DISCOUNT)
	// var/sell_mod = controller ? controller.get_hub_sell_modifier() : trading_faction.get_sell_modifier()  // Unused for now
	var/discount_percent = round((1 - HUB_TRADING_DISCOUNT) * 100)

	var/html = {"
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>[trading_faction.name] Trading</title>
	<style>
		body {
			font-family: Verdana, sans-serif;
			background-color: #1a1a2e;
			color: #eee;
			padding: 15px;
			margin: 0;
		}
		.header {
			text-align: center;
			border-bottom: 2px solid #ffd700;
			padding-bottom: 10px;
			margin-bottom: 15px;
		}
		.trader-name {
			font-size: 18px;
			font-weight: bold;
			color: #ffd700;
		}
		.trader-title {
			font-size: 12px;
			color: #888;
		}
		.faction-name {
			font-size: 14px;
			color: #4da6ff;
			margin-top: 5px;
		}
		.bonus-box {
			background-color: #2d4a2d;
			border: 1px solid #4a7c4a;
			border-radius: 5px;
			padding: 10px;
			margin-bottom: 15px;
			text-align: center;
		}
		.bonus-title {
			font-weight: bold;
			color: #7fff7f;
		}
		.dialogue-box {
			background-color: #252540;
			border-radius: 5px;
			padding: 12px;
			margin-bottom: 15px;
			font-style: italic;
		}
		.stock-header {
			font-size: 14px;
			font-weight: bold;
			color: #ffd700;
			margin-bottom: 10px;
		}
		.stock-item {
			background-color: #252540;
			border-radius: 5px;
			padding: 8px 12px;
			margin-bottom: 5px;
			display: flex;
			justify-content: space-between;
			align-items: center;
		}
		.item-name {
			font-weight: bold;
		}
		.item-qty {
			color: #888;
			font-size: 12px;
		}
		.item-price {
			color: #7fff7f;
			font-weight: bold;
		}
		.item-price.expensive {
			color: #ff6b6b;
		}
		.buy-btn {
			background-color: #4CAF50;
			color: white;
			border: none;
			padding: 5px 12px;
			border-radius: 3px;
			cursor: pointer;
			font-size: 12px;
		}
		.buy-btn:hover {
			background-color: #45a049;
		}
		.buy-btn:disabled {
			background-color: #555;
			color: #999;
			cursor: not-allowed;
		}
		.stats-row {
			display: flex;
			justify-content: space-between;
			font-size: 12px;
			color: #aaa;
			margin-bottom: 10px;
		}
		.note {
			font-size: 11px;
			color: #888;
			text-align: center;
			margin-top: 15px;
			padding-top: 10px;
			border-top: 1px solid #333;
		}
	</style>
</head>
<body>
	<div class="header">
		<div class="trader-name">[trading_faction.speaker_name]</div>
		<div class="trader-title">[trading_faction.speaker_title]</div>
		<div class="faction-name">[trading_faction.name]</div>
	</div>

	<div class="bonus-box">
		<span class="bonus-title">In-Person Trading Bonus!</span><br>
		<span>[discount_percent]% discount on all purchases</span>
	</div>

	<div class="dialogue-box">
		"[trading_faction.get_current_dialogue()]"
	</div>

	<div class="stats-row">
		<span>Reputation: [trading_faction.get_reputation_label()] ([trading_faction.reputation])</span>
		<span>Faction Cash: [trading_faction.current_cash]</span>
	</div>

	<div class="stock-header">Available Stock</div>
"}

	// List stock items
	if(!length(trading_faction.stock))
		html += {"<div class="stock-item">No items available at this time.</div>"}
	else
		for(var/list/item_entry in trading_faction.stock)
			var/item_name = item_entry["name"]
			var/quantity = item_entry["quantity"]
			var/base_price = item_entry["base_price"]
			var/final_price = round(base_price * buy_mod)

			if(quantity <= 0)
				continue

			html += {"
	<div class="stock-item">
		<div>
			<span class="item-name">[item_name]</span>
			<span class="item-qty">(x[quantity])</span>
		</div>
		<div>
			<span class="item-price">[final_price] credits</span>
			<a href="?src=[REF(src)];action=buy;item=[item_name]" class="buy-btn">Buy</a>
		</div>
	</div>
"}

	html += {"
	<div class="note">
		Use the outpost trading console for selling items.<br>
		Visit in person for the best prices!
	</div>
</body>
</html>
"}

	return html

/**
 * Handle Topic calls from the trading UI
 */
/mob/living/simple_animal/faction_trader/Topic(href, href_list)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!isliving(user))
		return

	if(get_dist(user, src) > 2)
		to_chat(user, span_warning("You're too far away!"))
		return

	switch(href_list["action"])
		if("buy")
			var/item_name = href_list["item"]
			attempt_purchase(user, item_name)

/**
 * Attempt to purchase an item
 */
/mob/living/simple_animal/faction_trader/proc/attempt_purchase(mob/living/user, item_name)
	if(!trading_faction || !item_name)
		return

	// Find the item in stock
	var/list/target_item = null
	for(var/list/item_entry in trading_faction.stock)
		if(item_entry["name"] == item_name)
			target_item = item_entry
			break

	if(!target_item)
		to_chat(user, span_warning("That item is not available."))
		return

	if(target_item["quantity"] <= 0)
		to_chat(user, span_warning("That item is out of stock."))
		say(trading_faction.get_dialogue("low_stock"))
		return

	// Calculate price with hub discount
	var/buy_mod = controller ? controller.get_hub_buy_modifier() : (trading_faction.get_buy_modifier() * HUB_TRADING_DISCOUNT)
	var/final_price = round(target_item["base_price"] * buy_mod)

	// Check if user can afford it
	// TODO: Integrate with actual credit system
	// For now, just process the purchase
	to_chat(user, span_notice("Purchase system not yet fully integrated. Item: [item_name], Price: [final_price] credits"))

	// Decrease quantity
	target_item["quantity"]--

	// Create the item
	var/item_type = target_item["type"]
	if(item_type)
		var/obj/item/I = new item_type(get_turf(user))
		to_chat(user, span_notice("You receive: [I.name]"))
		say(trading_faction.get_dialogue("purchase_complete"))

		// Give reputation for trading
		trading_faction.on_trade_completed(final_price, FALSE)

	// Refresh UI
	open_trading(user)

// ============================================
// FACTION-SPECIFIC TRADERS
// ============================================

/mob/living/simple_animal/faction_trader/resurgence_clan
	name = "The Historian"
	faction_id = "resurgence_clan"
	icon_state = "faceless"

/mob/living/simple_animal/faction_trader/resurgence_clan/setup_idle_lines()
	idle_lines = list(
		"The old ways still hold wisdom, young one.",
		"Your success brings hope to our people.",
		"The Weaver watches over all our kind.",
		"Tell me of your travels when you have time."
	)

/mob/living/simple_animal/faction_trader/jiajia_ren
	name = "Chir-rik"
	faction_id = "jiajia_ren"
	icon_state = "faceless"

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
