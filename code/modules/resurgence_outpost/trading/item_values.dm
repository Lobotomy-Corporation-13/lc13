/**
 * Resurgence Outpost - Item Values
 *
 * Uses the existing custom_price var on atoms for trading.
 * Provides fallback prices for common items without custom_price set.
 */

/// Default fallback prices for items without custom_price
GLOBAL_LIST_INIT(resurgence_fallback_prices, list(
	// ==================== Raw Ores ====================
	/obj/item/stack/ore/iron = 3,
	/obj/item/stack/ore/ironscrap = 2,
	/obj/item/stack/ore/glass = 2,
	/obj/item/stack/ore/glassrubble = 1,
	/obj/item/stack/ore/rock = 1,
	/obj/item/stack/ore/silver = 8,
	/obj/item/stack/ore/gold = 15,

	// ==================== Basic Sheets ====================
	/obj/item/stack/sheet/metal = 5,
	/obj/item/stack/sheet/glass = 4,
	/obj/item/stack/sheet/mineral/wood = 2,
	/obj/item/stack/sheet/mineral/sandstone = 2,
	/obj/item/stack/sheet/mineral/coal = 3,
	/obj/item/stack/sheet/mineral/silver = 12,
	/obj/item/stack/sheet/mineral/gold = 25,
	/obj/item/stack/sheet/plasteel = 30,
	/obj/item/stack/sheet/rglass = 8,

	// ==================== Textiles ====================
	/obj/item/stack/sheet/cotton = 1,
	/obj/item/stack/sheet/cotton/cloth = 3,
	/obj/item/stack/sheet/durathread = 15,

	// ==================== Leather Chain ====================
	/obj/item/stack/sheet/animalhide/generic = 3,
	/obj/item/stack/sheet/hairlesshide = 4,
	/obj/item/stack/sheet/wethide = 5,
	/obj/item/stack/sheet/leather = 6,

	// ==================== Crafting Components ====================
	/obj/item/stack/rods = 3,
	/obj/item/stack/cable_coil = 1,

	// ==================== Floor Tiles ====================
	/obj/item/stack/tile/wood = 2,
	/obj/item/stack/tile/plasteel = 8,
	/obj/item/stack/tile/carpet = 3,
	/obj/item/stack/tile/carpet/black = 3,
	/obj/item/stack/tile/carpet/blue = 3,
	/obj/item/stack/tile/carpet/cyan = 3,
	/obj/item/stack/tile/carpet/green = 3,
	/obj/item/stack/tile/carpet/orange = 3,
	/obj/item/stack/tile/carpet/purple = 3,
	/obj/item/stack/tile/carpet/red = 3,
	/obj/item/stack/tile/carpet/royalblack = 10,
	/obj/item/stack/tile/carpet/royalblue = 10,

	// ==================== Tools - Wood Tier ====================
	/obj/item/hatchet/wooden = 15,
	/obj/item/pickaxe/improvised = 12,
	/obj/item/scythe/wooden = 12,
	/obj/item/crowbar = 10,

	// ==================== Tools - Iron Tier ====================
	/obj/item/hatchet = 25,
	/obj/item/pickaxe = 30,
	/obj/item/pickaxe/mini = 25,
	/obj/item/scythe = 25,
	/obj/item/shovel = 20,
	/obj/item/crowbar/large = 25,

	// ==================== Tools - Silver Tier ====================
	/obj/item/pickaxe/silver = 60,

	// ==================== Seeds (base price, specific types may vary) ====================
	/obj/item/seeds = 3,
	/obj/item/seeds/wheat = 3,
	/obj/item/seeds/carrot = 3,
	/obj/item/seeds/potato = 3,
	/obj/item/seeds/tomato = 4,
	/obj/item/seeds/corn = 3,
	/obj/item/seeds/cabbage = 3,
	/obj/item/seeds/onion = 3,
	/obj/item/seeds/apple = 5,
	/obj/item/seeds/banana = 5,
	/obj/item/seeds/berry = 4,
	/obj/item/seeds/cotton = 4,
	/obj/item/seeds/sugarcane = 4,
	/obj/item/seeds/coffee = 6,
	/obj/item/seeds/tea = 6,
	/obj/item/seeds/tower = 8,
	/obj/item/seeds/cannabis = 6,
	/obj/item/seeds/starthistle = 2,
	/obj/item/seeds/grass = 2,
	/obj/item/seeds/random = 5,

	// ==================== Food/Grown ====================
	/obj/item/food/grown = 2,
	/obj/item/food/grown/wheat = 2,
	/obj/item/food/grown/carrot = 2,
	/obj/item/food/grown/potato = 2,
	/obj/item/food/grown/tomato = 3,
	/obj/item/food/grown/corn = 2,
	/obj/item/food/grown/cabbage = 2,
	/obj/item/food/grown/onion = 2,
	/obj/item/food/grown/apple = 3,
	/obj/item/food/grown/banana = 3,
	/obj/item/food = 3,

	// ==================== Meat ====================
	/obj/item/food/meat/slab = 5,
	/obj/item/food/meat/slab/chicken = 5,
	/obj/item/food/meat/slab/monkey = 5,
	/obj/item/food/meat/slab/bear = 8,
	/obj/item/food/meat/slab/penguin = 6,
	/obj/item/food/meat/slab/gondola = 12,
	/obj/item/food/meat/rawbacon = 4,
	/obj/item/food/meat/steak = 8,

	// ==================== Cooking Ingredients ====================
	/obj/item/reagent_containers/food/condiment/flour = 4,
	/obj/item/reagent_containers/food/condiment/rice = 4,
	/obj/item/reagent_containers/food/condiment/enzyme = 15,
	/obj/item/storage/fancy/egg_box = 10,

	// ==================== Crafting Table Products ====================
	/obj/item/storage/crayons = 10,
	/obj/item/stack/sheet/paperframes = 5,
	/obj/item/paper_bin = 8,
	/obj/item/folder = 3,
	/obj/item/reagent_containers/spray/cleaner = 15,
	/obj/item/mop = 10,
	/obj/item/pushbroom = 12,
	/obj/item/soap/homemade = 8,
	/obj/item/instrument/violin = 50,
	/obj/item/instrument/piano_synth = 80,
	/obj/item/instrument/banjo = 40,
	/obj/item/instrument/guitar = 45,
	/obj/item/instrument/eguitar = 60,
	/obj/item/instrument/accordion = 55,
	/obj/item/instrument/harmonica = 20,
	/obj/item/instrument/recorder = 15,
	/obj/item/instrument/trumpet = 45
))

/// Get the base value of an item (uses custom_price or fallback)
/proc/get_item_trade_value(obj/item/I)
	if(!I)
		return 0

	// Use custom_price if set
	if(I.custom_price)
		return I.custom_price

	// Check fallback prices
	var/item_type = I.type
	if(item_type in GLOB.resurgence_fallback_prices)
		return GLOB.resurgence_fallback_prices[item_type]

	// Check parent types in fallback
	for(var/check_type in GLOB.resurgence_fallback_prices)
		if(istype(I, check_type))
			return GLOB.resurgence_fallback_prices[check_type]

	// Default value for unknown items
	return 1

/// Get the sell value of an item to a faction (with reputation modifier)
/proc/get_item_sell_value(obj/item/I, datum/trading_faction/faction)
	var/base_value = get_item_trade_value(I)
	if(!faction)
		return base_value

	// Apply faction's sell modifier (reputation-based)
	var/final_value = base_value * faction.get_sell_modifier()

	// Handle stacks - multiply by amount
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		final_value *= S.amount

	return round(final_value)

/// Markup multiplier for buying from factions (1000% = 10x)
#define FACTION_BUY_MARKUP 10
/// Minimum price for any item (even with max reputation discount)
#define FACTION_MIN_BUY_PRICE 5

/// Get the buy value of an item from a faction (with reputation modifier)
/proc/get_item_buy_value(base_price, datum/trading_faction/faction)
	if(!faction)
		return max(base_price * FACTION_BUY_MARKUP, FACTION_MIN_BUY_PRICE)

	// Apply markup first, then faction's buy modifier (reputation-based discount)
	var/final_value = base_price * FACTION_BUY_MARKUP * faction.get_buy_modifier()

	// Ensure minimum price of 5 credits (no free items even with best discount)
	return max(round(final_value), FACTION_MIN_BUY_PRICE)

/// Get the total value of all items in a container for selling
/proc/get_container_sell_value(obj/structure/closet/container, datum/trading_faction/faction)
	var/total = 0
	for(var/obj/item/I in container.contents)
		total += get_item_sell_value(I, faction)
	return total
