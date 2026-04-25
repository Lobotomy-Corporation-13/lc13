// Middle Nursefather — Stamp Card & Party System

// ============================================================
// Party Location Datums
// ============================================================

/datum/party_location
	/// Display name
	var/name = "Unknown"
	/// Area type path for validation
	var/area_type
	/// Flavor text
	var/flavor = ""
	/// Tier: 1 = always available, 2 = 30min OR 2 stamps, 3 = 60min AND 3 stamps
	var/tier = 1
	/// Status effect type applied to attendees
	var/buff_type = /datum/status_effect/party_buff
	/// Buff name shown in UI
	var/buff_name = "Party Buff"
	/// Buff description shown in UI
	var/buff_desc = "Passive sanity healing + purple glow."

/datum/party_location/proc/is_unlocked(stamp_count)
	switch(tier)
		if(1)
			return TRUE
		if(2)
			return (world.time >= 30 MINUTES) || (stamp_count >= 2)
		if(3)
			return (world.time >= 60 MINUTES) && (stamp_count >= 3)
	return FALSE

/datum/party_location/proc/get_unlock_text()
	switch(tier)
		if(2)
			return "30 minutes OR 2 stamps"
		if(3)
			return "60 minutes AND 3 stamps"
	return ""

// Tier 1
/datum/party_location/employee_housing
	name = "Employee Housing"
	area_type = /area/city/house
	flavor = "A cozy spot for a low-key gathering."
	buff_type = /datum/status_effect/party_buff/home_comfort
	buff_name = "Home Comfort"
	buff_desc = "+10 Prudence, 10% less WHITE damage."

/datum/party_location/shop
	name = "Shop"
	area_type = /area/city/shop
	flavor = "Party among the shelves."
	buff_type = /datum/status_effect/party_buff/retail_therapy
	buff_name = "Retail Therapy"
	buff_desc = "+10 Temperance, +10 Prudence."

/datum/party_location/bar
	name = "The Alibi"
	area_type = /area/city/bar
	flavor = "The natural party venue."
	buff_type = /datum/status_effect/party_buff/liquid_courage
	buff_name = "Liquid Courage"
	buff_desc = "+15 Fortitude, bonus RED damage on hit."

/datum/party_location/library
	name = "Library"
	area_type = /area/city/library
	flavor = "A 'quiet' celebration."
	buff_type = /datum/status_effect/party_buff/studied_mind
	buff_name = "Studied Mind"
	buff_desc = "+10 Prudence, +10 Justice, 10% less BLACK damage."

/datum/party_location/bistro
	name = "The Bistro"
	area_type = /area/city/bistro
	flavor = "Wine, food, and good company."
	buff_type = /datum/status_effect/party_buff/well_fed
	buff_name = "Well Fed"
	buff_desc = "+10 Fortitude, +10 Temperance, passive HP regen."

/datum/party_location/carnival
	name = "Carnival Base"
	area_type = /area/city/carnival
	flavor = "Already festive — just needs a host."
	buff_type = /datum/status_effect/party_buff/showtime
	buff_name = "Showtime"
	buff_desc = "+15 Justice, movement speed boost."

/datum/party_location/clinic
	name = "Clinic"
	area_type = /area/city/clinic
	flavor = "Nothing heals like a good time."
	buff_type = /datum/status_effect/party_buff/patched_up
	buff_name = "Patched Up"
	buff_desc = "+10 Prudence, enhanced sanity heal, 10% less PALE damage."

/datum/party_location/hhpp
	name = "HamHamPangPang"
	area_type = /area/city/hhpp
	flavor = "The arcade deserves a proper party."
	buff_type = /datum/status_effect/party_buff/masterwork_cooking
	buff_name = "Masterwork Cooking"
	buff_desc = "+15 Fortitude, +10 Temperance, inflict Bleed on hit."


// Tier 2
/datum/party_location/fixers
	name = "Fixer Office"
	area_type = /area/city/fixers
	flavor = "Bringing the party to the professionals."
	tier = 2
	buff_type = /datum/status_effect/party_buff/professional_edge
	buff_name = "Professional Edge"
	buff_desc = "+15 Justice, +10 Fortitude, bonus BLACK damage on hit."

/datum/party_location/roaming_base
	name = "Roaming Fixers Office"
	area_type = /area/city/roaming_base
	flavor = "Freelancers need fun too."
	tier = 2
	buff_type = /datum/status_effect/party_buff/freelancers_grit
	buff_name = "Freelancer's Grit"
	buff_desc = "+15 Fortitude, +15 Justice, 15% less RED damage."

// Tier 3
/datum/party_location/hana
	name = "Hana Office"
	area_type = /area/city/hana
	flavor = "Crashing the corporate scene."
	tier = 3
	buff_type = /datum/status_effect/party_buff/corporate_raid
	buff_name = "Corporate Raid"
	buff_desc = "+10 all stats, 5% lifesteal on hit."

/datum/party_location/assoc_base
	name = "Association Office"
	area_type = /area/city/assoc_base
	flavor = "Party in the syndicate's own turf."
	tier = 3
	buff_type = /datum/status_effect/party_buff/syndicate_bonds
	buff_name = "Syndicate Bonds"
	buff_desc = "+10 all stats, inflict Overheat on hit."

/datum/party_location/antag_base
	name = "Abandoned Hideout"
	area_type = /area/city/antag_base
	buff_name = "Hideout Hustle"
	buff_desc = "+20 Fort/Just, 15% more RED, 10% less all damage."
	flavor = "The ultimate bold move."
	tier = 3
	buff_type = /datum/status_effect/party_buff/hideout_hustle

// ============================================================
// Party Item Datums
// ============================================================

/datum/party_item
	var/name = "Item"
	var/cost = 100
	var/desc = ""
	var/category = "Misc"

/datum/party_item/proc/spawn_items(turf/T)
	return

// ----- Drinks -----
/datum/party_item/beer_keg
	name = "Beer Keg"
	cost = 300
	desc = "Tap and pour for everyone."
	category = "Drinks"

/datum/party_item/beer_keg/spawn_items(turf/T)
	new /obj/structure/reagent_dispensers/beerkeg(T)

/datum/party_item/bottle_service
	name = "Bottle Service"
	cost = 200
	desc = "3 random premium bottles."
	category = "Drinks"

/datum/party_item/bottle_service/spawn_items(turf/T)
	var/list/bottles = list(
		/obj/item/reagent_containers/food/drinks/bottle/whiskey,
		/obj/item/reagent_containers/food/drinks/bottle/vodka,
		/obj/item/reagent_containers/food/drinks/bottle/rum,
		/obj/item/reagent_containers/food/drinks/bottle/champagne,
		/obj/item/reagent_containers/food/drinks/bottle/cognac,
		/obj/item/reagent_containers/food/drinks/bottle/wine,
		/obj/item/reagent_containers/food/drinks/bottle/tequila,
	)
	for(var/i in 1 to 3)
		var/picked = pick(bottles)
		new picked(T)

/datum/party_item/malt_liquor
	name = "40oz Malt Liquor"
	cost = 50
	desc = "The classic."
	category = "Drinks"

/datum/party_item/malt_liquor/spawn_items(turf/T)
	new /obj/item/reagent_containers/food/drinks/bottle/maltliquor(T)

/datum/party_item/soda_cooler
	name = "Soda Cooler"
	cost = 100
	desc = "5 random soda cans."
	category = "Drinks"

/datum/party_item/soda_cooler/spawn_items(turf/T)
	var/list/sodas = list(
		/obj/item/reagent_containers/food/drinks/soda_cans/cola,
		/obj/item/reagent_containers/food/drinks/soda_cans/lemon_lime,
		/obj/item/reagent_containers/food/drinks/soda_cans/dr_gibb,
		/obj/item/reagent_containers/food/drinks/soda_cans/grey_bull,
		/obj/item/reagent_containers/food/drinks/soda_cans/thirteenloko,
	)
	for(var/i in 1 to 5)
		var/picked = pick(sodas)
		new picked(T)

/datum/party_item/sake_set
	name = "Sake Set"
	cost = 150
	desc = "2 bottles of sake."
	category = "Drinks"

/datum/party_item/sake_set/spawn_items(turf/T)
	for(var/i in 1 to 2)
		new /obj/item/reagent_containers/food/drinks/bottle/sake(T)

// ----- Food -----
/datum/party_item/pizza
	name = "Pizza Delivery"
	cost = 150
	desc = "3 random pizzas."
	category = "Food"

/datum/party_item/pizza/spawn_items(turf/T)
	var/list/pizzas = list(
		/obj/item/food/pizza/margherita,
		/obj/item/food/pizza/meat,
		/obj/item/food/pizza/mushroom,
		/obj/item/food/pizza/vegetable,
	)
	for(var/i in 1 to 3)
		var/picked = pick(pizzas)
		new picked(T)

/datum/party_item/snack_spread
	name = "Snack Spread"
	cost = 100
	desc = "Chips, nachos, popcorn, and more."
	category = "Food"

/datum/party_item/snack_spread/spawn_items(turf/T)
	new /obj/item/food/chips(T)
	new /obj/item/food/nachos(T)
	new /obj/item/food/popcorn(T)
	new /obj/item/food/cheesiehonkers(T)
	new /obj/item/food/sosjerky(T)

/datum/party_item/nachos
	name = "Nacho Platter"
	cost = 100
	desc = "3 plates of cheesy nachos."
	category = "Food"

/datum/party_item/nachos/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/food/nachos(T)

/datum/party_item/burgers
	name = "Burger Run"
	cost = 150
	desc = "3 burgers."
	category = "Food"

/datum/party_item/burgers/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/food/burger/plain(T)

/datum/party_item/donuts
	name = "Donut Box"
	cost = 100
	desc = "6 random donuts."
	category = "Food"

/datum/party_item/donuts/spawn_items(turf/T)
	var/list/donut_types = list(
		/obj/item/food/donut/plain,
		/obj/item/food/donut/jelly,
		/obj/item/food/donut/jelly/berry,
	)
	for(var/i in 1 to 6)
		var/picked = pick(donut_types)
		new picked(T)

/datum/party_item/cake
	name = "Birthday Cake"
	cost = 200
	desc = "Enough slices for the whole party."
	category = "Food"

/datum/party_item/cake/spawn_items(turf/T)
	new /obj/item/food/cake/birthday(T)

/datum/party_item/fries
	name = "Fries"
	cost = 75
	desc = "3 baskets of fries."
	category = "Food"

/datum/party_item/fries/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/food/fries(T)

/datum/party_item/candy
	name = "Candy Bowl"
	cost = 75
	desc = "Assorted candy and chocolates."
	category = "Food"

/datum/party_item/candy/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/food/candy(T)
	for(var/i in 1 to 2)
		new /obj/item/food/chocolatebar(T)

/datum/party_item/hotdogs
	name = "Hotdog Stand"
	cost = 100
	desc = "4 hotdogs — classic street food."
	category = "Food"

/datum/party_item/hotdogs/spawn_items(turf/T)
	for(var/i in 1 to 4)
		new /obj/item/food/hotdog(T)

/datum/party_item/burritos
	name = "Burrito Platter"
	cost = 125
	desc = "3 burritos."
	category = "Food"

/datum/party_item/burritos/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/food/burrito(T)

/datum/party_item/ice_cream
	name = "Ice Cream Sandwiches"
	cost = 100
	desc = "4 ice cream sandwiches."
	category = "Food"

/datum/party_item/ice_cream/spawn_items(turf/T)
	for(var/i in 1 to 4)
		new /obj/item/food/icecreamsandwich(T)

// ----- Drinks (continued) -----
/datum/party_item/absinthe
	name = "Absinthe"
	cost = 250
	desc = "A bottle of the green fairy."
	category = "Drinks"

/datum/party_item/absinthe/spawn_items(turf/T)
	new /obj/item/reagent_containers/food/drinks/bottle/absinthe(T)

/datum/party_item/party_cups
	name = "Party Cups"
	cost = 50
	desc = "6 red solo cups."
	category = "Drinks"

/datum/party_item/party_cups/spawn_items(turf/T)
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/food/drinks/colocup(T)

// ----- Substances -----
/datum/party_item/happy_pills
	name = "Happy Pills"
	cost = 200
	desc = "5 happy pills — pure ecstasy."
	category = "Substances"

/datum/party_item/happy_pills/spawn_items(turf/T)
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/happy(T)

/datum/party_item/sunshine_pills
	name = "Sunshine Pills"
	cost = 250
	desc = "3 sunshine pills — a wild trip."
	category = "Substances"

/datum/party_item/sunshine_pills/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/pill/lsd(T)

// ----- Entertainment -----
/datum/party_item/disco_ball
	name = "Disco Ball"
	cost = 500
	desc = "Music + lights. No access needed."
	category = "Entertainment"

/datum/party_item/disco_ball/spawn_items(turf/T)
	new /obj/structure/etherealball(T)

/datum/party_item/jukebox
	name = "Jukebox"
	cost = 400
	desc = "A jukebox — no access needed."
	category = "Entertainment"

/datum/party_item/jukebox/spawn_items(turf/T)
	var/obj/machinery/jukebox/J = new(T)
	J.req_access = null
	J.anchored = FALSE

/datum/party_item/middle_jukebox
	name = "Middle Jukebox"
	cost = 300
	desc = "The Middle's signature jukebox."
	category = "Entertainment"

/datum/party_item/middle_jukebox/spawn_items(turf/T)
	new /obj/machinery/jukebox/middle(T)

/datum/party_item/wrench
	name = "Wrench"
	cost = 25
	desc = "For anchoring jukeboxes and furniture."
	category = "Atmosphere"

/datum/party_item/wrench/spawn_items(turf/T)
	new /obj/item/wrench(T)

// ----- Arcade Machines -----
// Arcade party items track their spawned machine. Buying again teleports it instead of duplicating.
/datum/party_item/arcade
	category = "Arcade"
	/// The arcade machine type to spawn
	var/arcade_type
	/// Reference to the spawned machine
	var/obj/machinery/computer/arcade/spawned_machine

/datum/party_item/arcade/spawn_items(turf/T)
	if(spawned_machine && !QDELETED(spawned_machine))
		spawned_machine.forceMove(T)
		return
	var/obj/machinery/computer/arcade/machine = new arcade_type(T)
	machine.name = "Middle's [machine.name]"
	machine.density = FALSE
	machine.color = "#9b30ff"
	machine.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	machine.flags_1 |= NODECONSTRUCT_1
	spawned_machine = machine

/datum/party_item/arcade/cardgame
	name = "Card Game Arcade"
	cost = 200
	desc = "A card game machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/cardgame

/datum/party_item/arcade/checkpoint
	name = "Checkpoint Arcade"
	cost = 200
	desc = "A checkpoint racing machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/checkpoint

/datum/party_item/arcade/delivery
	name = "Delivery Arcade"
	cost = 200
	desc = "A delivery game machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/delivery

/datum/party_item/arcade/fps
	name = "FPS Arcade"
	cost = 200
	desc = "A first-person shooter machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/fps

/datum/party_item/arcade/greatlake
	name = "Great Lake Arcade"
	cost = 200
	desc = "A fishing game machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/greatlake

/datum/party_item/arcade/sweeper
	name = "Sweeper Arcade"
	cost = 200
	desc = "A minesweeper machine. Teleports to you if already placed."
	arcade_type = /obj/machinery/computer/arcade/sweeper

/datum/party_item/toy_box
	name = "Toy Box"
	cost = 100
	desc = "3 random toys."
	category = "Entertainment"

/datum/party_item/toy_box/spawn_items(turf/T)
	var/list/toys = list(
		/obj/item/toy/sword,
		/obj/item/toy/snappop,
		/obj/item/toy/foamblade,
		/obj/item/toy/waterballoon,
	)
	for(var/i in 1 to 3)
		var/picked = pick(toys)
		new picked(T)

/datum/party_item/cards
	name = "Card Deck"
	cost = 75
	desc = "Playing cards — poker night."
	category = "Entertainment"

/datum/party_item/cards/spawn_items(turf/T)
	new /obj/item/toy/cards/deck(T)

/datum/party_item/dice
	name = "Dice Set"
	cost = 75
	desc = "Assorted dice — gambling time."
	category = "Entertainment"

/datum/party_item/dice/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/dice(T)
	new /obj/item/dice/d20(T)

/datum/party_item/instruments
	name = "Instrument Set"
	cost = 200
	desc = "2 random instruments."
	category = "Entertainment"

/datum/party_item/instruments/spawn_items(turf/T)
	var/list/instruments = list(
		/obj/item/instrument/guitar,
		/obj/item/instrument/saxophone,
		/obj/item/instrument/trumpet,
		/obj/item/instrument/harmonica,
		/obj/item/instrument/eguitar,
	)
	for(var/i in 1 to 2)
		var/picked = pick(instruments)
		new picked(T)

/datum/party_item/fireworks
	name = "Fireworks Box"
	cost = 150
	desc = "Celebrate in style."
	category = "Entertainment"

/datum/party_item/fireworks/spawn_items(turf/T)
	new /obj/item/storage/box/fireworks(T)

/datum/party_item/balloons
	name = "Balloon Bundle"
	cost = 50
	desc = "5 random-color balloons."
	category = "Entertainment"

/datum/party_item/balloons/spawn_items(turf/T)
	for(var/i in 1 to 5)
		new /obj/item/toy/balloon(T)

/datum/party_item/plushies
	name = "Plushie Pile"
	cost = 100
	desc = "3 random LC plushies."
	category = "Entertainment"

/datum/party_item/plushies/spawn_items(turf/T)
	var/list/plush_types = list(
		/obj/item/toy/plush/malkuth,
		/obj/item/toy/plush/yesod,
		/obj/item/toy/plush/netzach,
		/obj/item/toy/plush/hod,
		/obj/item/toy/plush/lisa,
		/obj/item/toy/plush/enoch,
		/obj/item/toy/plush/gebura,
		/obj/item/toy/plush/hokma,
		/obj/item/toy/plush/binah,
		/obj/item/toy/plush/angela,
		/obj/item/toy/plush/bigbird,
		/obj/item/toy/plush/pbird,
		/obj/item/toy/plush/jbird,
		/obj/item/toy/plush/big_bad_wolf,
		/obj/item/toy/plush/rabbit,
		/obj/item/toy/plush/myo,
	)
	for(var/i in 1 to 3)
		var/picked = pick(plush_types)
		new picked(T)

/datum/party_item/action_figures
	name = "Action Figure Box"
	cost = 125
	desc = "3 random action figures."
	category = "Entertainment"

/datum/party_item/action_figures/spawn_items(turf/T)
	var/list/figure_types = list(
		/obj/item/toy/figure/assistant,
		/obj/item/toy/figure/bartender,
		/obj/item/toy/figure/captain,
		/obj/item/toy/figure/clown,
		/obj/item/toy/figure/chef,
		/obj/item/toy/figure/detective,
		/obj/item/toy/figure/chaplain,
		/obj/item/toy/figure/chemist,
		/obj/item/toy/figure/ian,
		/obj/item/toy/figure/dsquad,
	)
	for(var/i in 1 to 3)
		var/picked = pick(figure_types)
		new picked(T)

/datum/party_item/magic_8ball
	name = "Magic 8-Ball"
	cost = 75
	desc = "Ask it anything."
	category = "Entertainment"

/datum/party_item/magic_8ball/spawn_items(turf/T)
	new /obj/item/toy/eightball(T)

/datum/party_item/beach_balls
	name = "Beach Balls"
	cost = 50
	desc = "2 beach balls — toss them around."
	category = "Entertainment"

/datum/party_item/beach_balls/spawn_items(turf/T)
	for(var/i in 1 to 2)
		new /obj/item/toy/beach_ball(T)

// ----- Atmosphere -----
/datum/party_item/cigars
	name = "Cigar Box"
	cost = 100
	desc = "3 premium Havana cigars."
	category = "Atmosphere"

/datum/party_item/cigars/spawn_items(turf/T)
	for(var/i in 1 to 3)
		new /obj/item/clothing/mask/cigarette/cigar/havana(T)

/datum/party_item/furniture
	name = "Furniture Set"
	cost = 200
	desc = "2 comfy chairs + 1 wooden table."
	category = "Atmosphere"

/datum/party_item/furniture/spawn_items(turf/T)
	new /obj/structure/table/wood(T)
	var/list/cardinal_dirs = list(NORTH, SOUTH, EAST, WEST)
	for(var/i in 1 to 2)
		var/dir = pick_n_take(cardinal_dirs)
		var/turf/chair_turf = get_step(T, dir)
		if(chair_turf)
			new /obj/structure/chair/comfy(chair_turf)

/datum/party_item/gangster_kit
	name = "Gangster Kit"
	cost = 150
	desc = "2 fedoras + 2 sunglasses."
	category = "Atmosphere"

/datum/party_item/gangster_kit/spawn_items(turf/T)
	for(var/i in 1 to 2)
		new /obj/item/clothing/head/fedora(T)
		new /obj/item/clothing/glasses/sunglasses(T)

/datum/party_item/snap_pops
	name = "Snap Pops"
	cost = 25
	desc = "5 snap pops — pop on impact."
	category = "Atmosphere"

/datum/party_item/snap_pops/spawn_items(turf/T)
	for(var/i in 1 to 5)
		new /obj/item/toy/snappop(T)

// ============================================================
// Global Party Data
// ============================================================

GLOBAL_LIST_INIT(party_locations, init_party_locations())
GLOBAL_LIST_INIT(party_items, init_party_items())

/proc/init_party_locations()
	var/list/L = list()
	for(var/path in subtypesof(/datum/party_location))
		L += new path
	return L

/proc/init_party_items()
	var/list/L = list()
	for(var/path in subtypesof(/datum/party_item))
		L += new path
	return L

// ============================================================
// Stamp Card Item
// ============================================================

/obj/item/middle_stamp_card
	name = "stamp card"
	desc = "A well-worn card covered in purple ink stamps. Each one represents a successful party thrown by the Middle."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "ticket"
	color = "#9b30ff"
	w_class = WEIGHT_CLASS_SMALL
	/// List of area names where parties were completed
	var/list/stamps = list()
	/// Whether a party is currently active
	var/party_active = FALSE
	/// The area where the current party is being held
	var/area/party_area
	/// World time when the party started
	var/party_start_time = 0
	/// Number of host-absent warnings issued
	var/host_warnings = 0
	/// The active party location datum
	var/datum/party_location/current_location
	/// The host mob
	var/mob/living/carbon/human/host
	/// Timer ID for host presence checks
	var/host_check_timer
	/// Minimum living humans required to start a party (set to 0 to skip check)
	var/min_attendees = 3

/obj/item/middle_stamp_card/attack_self(mob/user)
	ui_interact(user)

/obj/item/middle_stamp_card/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MiddleStampCard", "Stamp Card")
		ui.open()

/obj/item/middle_stamp_card/ui_data(mob/user)
	var/list/data = list()
	data["stamps"] = stamps
	data["stamp_count"] = length(stamps)

	// Current area info
	var/area/user_area = get_area(user)
	data["current_area"] = user_area?.name || "Unknown"
	data["current_area_type"] = "[user_area?.type]"

	// Party state
	data["party_active"] = party_active
	if(party_active)
		data["party_time_elapsed"] = round((world.time - party_start_time) / 10)
		data["party_can_end"] = (world.time - party_start_time) >= 5 MINUTES
		data["party_location_name"] = current_location?.name || "Unknown"
		// Count living humans in the party area
		var/attendee_count = 0
		if(party_area)
			for(var/mob/living/carbon/human/H in party_area)
				if(H.stat != DEAD)
					attendee_count++
		data["party_attendees"] = attendee_count

	// Player ahn balance
	var/player_ahn = 0
	if(isliving(user))
		var/mob/living/L = user
		var/datum/bank_account/account = L.get_bank_account()
		if(account)
			player_ahn = account.account_balance
	data["player_ahn"] = player_ahn

	// Location data
	var/list/location_data = list()
	for(var/datum/party_location/loc in GLOB.party_locations)
		var/list/loc_info = list()
		loc_info["name"] = loc.name
		loc_info["flavor"] = loc.flavor
		loc_info["tier"] = loc.tier
		loc_info["area_type"] = "[loc.area_type]"
		loc_info["unlocked"] = loc.is_unlocked(length(stamps))
		loc_info["unlock_text"] = loc.get_unlock_text()
		loc_info["is_current_area"] = istype(user_area, loc.area_type)
		loc_info["buff_name"] = loc.buff_name
		loc_info["buff_desc"] = loc.buff_desc
		location_data += list(loc_info)
	data["locations"] = location_data

	// Item data
	var/list/item_data = list()
	for(var/datum/party_item/item in GLOB.party_items)
		var/list/item_info = list()
		item_info["name"] = item.name
		item_info["cost"] = item.cost
		item_info["desc"] = item.desc
		item_info["category"] = item.category
		item_info["type"] = "[item.type]"
		item_data += list(item_info)
	data["items"] = item_data

	return data

/obj/item/middle_stamp_card/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/user = usr
	if(!ishuman(user))
		return

	switch(action)
		if("start_party")
			var/area_type = text2path(params["area_type"])
			if(!area_type)
				return
			start_party(user, area_type)
			return TRUE
		if("spawn_item")
			var/item_type = text2path(params["item_type"])
			if(!item_type)
				return
			spawn_party_item(user, item_type)
			return TRUE
		if("end_party")
			end_party(user)
			return TRUE

// ============================================================
// Party Flow
// ============================================================

/obj/item/middle_stamp_card/proc/start_party(mob/living/carbon/human/user, area_type)
	if(party_active)
		to_chat(user, span_warning("A party is already in progress!"))
		return

	// Find matching location
	var/datum/party_location/target_loc
	for(var/datum/party_location/loc in GLOB.party_locations)
		if(loc.area_type == area_type)
			target_loc = loc
			break
	if(!target_loc)
		to_chat(user, span_warning("This isn't a valid party location!"))
		return
	if(!target_loc.is_unlocked(length(stamps)))
		to_chat(user, span_warning("This location isn't unlocked yet! Requires: [target_loc.get_unlock_text()]"))
		return

	// Verify user is in the correct area
	var/area/user_area = get_area(user)
	if(!istype(user_area, area_type))
		to_chat(user, span_warning("You need to be in [target_loc.name] to start a party there!"))
		return

	// Count living humans in the area (including user)
	if(min_attendees > 0)
		var/human_count = 0
		for(var/mob/living/carbon/human/H in user_area)
			if(H.stat != DEAD)
				human_count++
		if(human_count < min_attendees)
			to_chat(user, span_warning("Not enough people! Need at least [min_attendees] living humans. (Currently: [human_count])"))
			return

	// Start the party
	party_active = TRUE
	party_area = user_area
	party_start_time = world.time
	host_warnings = 0
	current_location = target_loc
	host = user

	// Announce
	for(var/mob/living/M in user_area)
		to_chat(M, span_notice("<b>[user] declares this a party zone! The Middle's celebration begins!</b>"))
	user.visible_message(span_notice("<b>[user] declares this a party zone! The Middle's celebration begins!</b>"))

	// Start host presence checks every 30 seconds
	host_check_timer = addtimer(CALLBACK(src, PROC_REF(check_host_presence)), 30 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/obj/item/middle_stamp_card/proc/check_host_presence()
	if(!party_active || !host || QDELETED(host))
		cancel_party("The party's host has vanished!")
		return

	if(host.stat == DEAD)
		cancel_party("The party's host has died! Party cancelled!")
		return

	var/area/host_area = get_area(host)
	if(!istype(host_area, current_location.area_type))
		host_warnings++
		switch(host_warnings)
			if(1)
				to_chat(host, span_warning("<b>You're drifting from the party! Get back in there!</b>"))
			if(2)
				to_chat(host, span_userdanger("<b>The party's losing its host! Return now!</b>"))
			if(3)
				cancel_party("The host abandoned the party!")
	else
		host_warnings = max(0, host_warnings - 1)

/obj/item/middle_stamp_card/proc/cancel_party(reason)
	if(!party_active)
		return
	if(party_area)
		for(var/mob/living/M in party_area)
			to_chat(M, span_warning("<b>[reason] No rewards earned.</b>"))
	cleanup_party()

/obj/item/middle_stamp_card/proc/end_party(mob/living/carbon/human/user)
	if(!party_active)
		to_chat(user, span_warning("No party is active!"))
		return
	if((world.time - party_start_time) < 5 MINUTES)
		var/time_left = DisplayTimeText(5 MINUTES - (world.time - party_start_time))
		to_chat(user, span_warning("The party needs more time! ([time_left] remaining)"))
		return

	// Apply buffs to all living humans in the party area
	if(party_area && current_location)
		for(var/mob/living/carbon/human/H in party_area)
			if(H.stat == DEAD)
				continue
			to_chat(H, span_notice("<b>The party wraps up! You leave feeling refreshed.</b>"))
			H.apply_status_effect(current_location.buff_type)
			apply_role_bonus(H)

	// Add stamp
	stamps += current_location.name

	cleanup_party()

/obj/item/middle_stamp_card/proc/apply_role_bonus(mob/living/carbon/human/H)
	// Civilians get permanent +3 to all attribute levels
	if(H.mind?.assigned_role == "Civilian")
		H.adjust_attribute_level(FORTITUDE_ATTRIBUTE, 3)
		H.adjust_attribute_level(PRUDENCE_ATTRIBUTE, 3)
		H.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, 3)
		H.adjust_attribute_level(JUSTICE_ATTRIBUTE, 3)
		to_chat(H, span_notice("As a civilian, you gain a permanent attribute boost from the experience!"))
		return

	// Association members get +50 EXP
	var/datum/component/association_exp/exp = H.GetComponent(/datum/component/association_exp)
	if(exp)
		exp.modify_exp(50)
		to_chat(H, span_notice("You earned 50 association EXP from the party!"))

/obj/item/middle_stamp_card/proc/cleanup_party()
	party_active = FALSE
	party_area = null
	party_start_time = 0
	host_warnings = 0
	current_location = null
	host = null
	if(host_check_timer)
		deltimer(host_check_timer)
		host_check_timer = null

/obj/item/middle_stamp_card/proc/spawn_party_item(mob/living/carbon/human/user, item_type)
	if(!party_active)
		to_chat(user, span_warning("No party is active!"))
		return

	var/datum/party_item/target_item
	for(var/datum/party_item/item in GLOB.party_items)
		if(item.type == item_type)
			target_item = item
			break
	if(!target_item)
		return

	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		to_chat(user, span_warning("You don't have a bank account!"))
		return
	if(!account.has_money(target_item.cost))
		to_chat(user, span_warning("Not enough ahn! Need [target_item.cost], have [account.account_balance]."))
		return

	// Arcade machines teleport for free if already spawned
	var/datum/party_item/arcade/arcade_item = target_item
	if(istype(arcade_item) && arcade_item.spawned_machine && !QDELETED(arcade_item.spawned_machine))
		arcade_item.spawn_items(get_turf(user))
		to_chat(user, span_notice("[target_item.name] teleported to you!"))
		return

	account.adjust_money(-target_item.cost)
	target_item.spawn_items(get_turf(user))
	to_chat(user, span_notice("[target_item.name] delivered! (-[target_item.cost] ahn)"))

/obj/item/middle_stamp_card/Destroy()
	if(party_active)
		cancel_party("The stamp card has been destroyed!")
	return ..()
