// Caravan Encounter System
// Handles the physical encounter area when players meet a caravan

// ============================================
// CARAVAN ENCOUNTER AREA
// ============================================

/area/resurgence/caravan_encounter
	name = "Caravan Encounter"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	static_lighting = TRUE
	base_lighting_alpha = 200

// ============================================
// CARAVAN ENCOUNTER LANDMARKS
// ============================================

/**
 * Spawn point for players entering caravan encounter
 */
/obj/effect/landmark/caravan_spawn
	name = "caravan player spawn"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Location where caravan wagon/cart spawns
 */
/obj/effect/landmark/caravan_wagon
	name = "caravan wagon location"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Exit point to return to corridor/expedition
 */
/obj/effect/landmark/caravan_exit
	name = "caravan exit"
	invisibility = INVISIBILITY_ABSTRACT

// ============================================
// CARAVAN ENCOUNTER CONTROLLER
// ============================================

/**
 * Caravan Encounter Controller
 *
 * Manages the caravan encounter area and player interactions.
 */
/datum/caravan_encounter_controller
	/// The caravan being encountered
	var/datum/faction_caravan/caravan
	/// The expedition party that triggered the encounter
	var/datum/expedition_party/expedition
	/// Spawn landmark reference
	var/obj/effect/landmark/caravan_spawn/spawn_point
	/// Wagon landmark reference
	var/obj/effect/landmark/caravan_wagon/wagon_point
	/// Exit landmark reference
	var/obj/effect/landmark/caravan_exit/exit_point
	/// Whether the encounter is resolved
	var/resolved = FALSE
	/// Outcome of the encounter
	var/outcome = "none"  // "trade", "attack", "steal", "ignore", "fled"
	/// List of spawned guards
	var/list/guards = list()

/datum/caravan_encounter_controller/New(datum/faction_caravan/C, datum/expedition_party/party)
	. = ..()
	caravan = C
	expedition = party

	// Find landmarks
	find_landmarks()

/datum/caravan_encounter_controller/Destroy()
	// Clean up guards
	for(var/mob/living/G in guards)
		qdel(G)
	guards = null
	caravan = null
	expedition = null
	spawn_point = null
	wagon_point = null
	exit_point = null
	return ..()

/**
 * Find landmarks in the caravan encounter area
 */
/datum/caravan_encounter_controller/proc/find_landmarks()
	if(!GLOB.caravan_encounter_z)
		return

	for(var/obj/effect/landmark/L in GLOB.landmarks_list)
		if(L.z != GLOB.caravan_encounter_z)
			continue
		if(istype(L, /obj/effect/landmark/caravan_spawn))
			spawn_point = L
		else if(istype(L, /obj/effect/landmark/caravan_wagon))
			wagon_point = L
		else if(istype(L, /obj/effect/landmark/caravan_exit))
			exit_point = L

/**
 * Start the encounter - teleport players and show UI
 */
/datum/caravan_encounter_controller/proc/start_encounter()
	if(!spawn_point)
		log_game("Caravan encounter failed: no spawn point found")
		return FALSE

	// Set current encounter globally
	GLOB.current_caravan_encounter = caravan

	// Spawn guards if hostile
	if(caravan.is_hostile())
		spawn_guards()

	// Teleport all expedition members
	var/turf/spawn_turf = get_turf(spawn_point)
	for(var/mob/living/M in expedition.members)
		M.forceMove(spawn_turf)
		// Show encounter popup
		show_encounter_popup(M)

	return TRUE

/**
 * Spawn caravan guards
 */
/datum/caravan_encounter_controller/proc/spawn_guards()
	if(!wagon_point)
		return

	var/turf/guard_turf = get_turf(wagon_point)
	for(var/i in 1 to caravan.guard_count)
		var/mob/living/simple_animal/hostile/caravan_guard/guard = new(guard_turf)
		guard.faction_id = caravan.faction_id
		guard.setup_appearance()
		guards += guard

/**
 * Show the encounter popup to a player
 */
/datum/caravan_encounter_controller/proc/show_encounter_popup(mob/living/user)
	var/datum/browser/popup = new(user, "caravan_encounter", "Caravan Encounter", 500, 450)

	var/html = {"
<!DOCTYPE html>
<html>
<head>
<style>
body {
	font-family: 'Segoe UI', Tahoma, sans-serif;
	background: #1a1a2e;
	color: #eee;
	margin: 0;
	padding: 15px;
}
.header {
	text-align: center;
	padding: 10px;
	background: linear-gradient(135deg, #16213e, #1a1a2e);
	border-radius: 8px;
	margin-bottom: 15px;
}
.header h2 {
	margin: 0;
	color: [caravan.display_color];
}
.header .subtitle {
	color: #888;
	font-size: 12px;
}
.info-box {
	background: #16213e;
	border-radius: 8px;
	padding: 12px;
	margin-bottom: 15px;
}
.info-row {
	display: flex;
	justify-content: space-between;
	margin: 5px 0;
}
.info-label {
	color: #888;
}
.info-value {
	color: #fff;
	font-weight: bold;
}
.hostile-warning {
	background: #4a1010;
	border: 2px solid #ff4444;
	border-radius: 8px;
	padding: 10px;
	text-align: center;
	color: #ff6666;
	margin-bottom: 15px;
}
.choices {
	display: flex;
	flex-direction: column;
	gap: 10px;
}
.choice-btn {
	background: #16213e;
	border: 2px solid #333;
	border-radius: 8px;
	padding: 12px;
	color: #fff;
	cursor: pointer;
	text-align: left;
	transition: all 0.2s;
}
.choice-btn:hover {
	border-color: [caravan.display_color];
	background: #1a2744;
}
.choice-btn.hostile {
	border-color: #ff4444;
}
.choice-btn.hostile:hover {
	background: #2a1010;
}
.choice-btn h4 {
	margin: 0 0 5px 0;
	color: [caravan.display_color];
}
.choice-btn.hostile h4 {
	color: #ff6666;
}
.choice-btn p {
	margin: 0;
	font-size: 12px;
	color: #aaa;
}
</style>
</head>
<body>
<div class="header">
	<h2>[caravan.name]</h2>
	<div class="subtitle">[caravan.owner_faction?.name || "Unknown Faction"]</div>
</div>

<div class="info-box">
	<div class="info-row">
		<span class="info-label">Guards:</span>
		<span class="info-value">[caravan.guard_count]</span>
	</div>
	<div class="info-row">
		<span class="info-label">Goods:</span>
		<span class="info-value">[length(caravan.stock)] items</span>
	</div>
	[caravan.is_hostile() ? "" : {"
	<div class="info-row">
		<span class="info-label">Cash:</span>
		<span class="info-value">[caravan.caravan_cash] credits</span>
	</div>
	"}]
</div>

[caravan.is_hostile() ? {"
<div class="hostile-warning">
	⚠️ HOSTILE PATROL - They attack on sight!
</div>
"} : ""]

<div class="choices">
	[caravan.is_hostile() ? "" : {"
	<a class="choice-btn" href="?src=\ref[src];action=trade">
		<h4>🤝 Trade</h4>
		<p>Open peaceful trade with the caravan. No price discount.</p>
	</a>
	"}]

	<a class="choice-btn hostile" href="?src=\ref[src];action=attack">
		<h4>⚔️ Attack</h4>
		<p>Fight the guards and loot the caravan. Major reputation loss.</p>
	</a>

	[caravan.is_hostile() ? "" : {"
	<a class="choice-btn" href="?src=\ref[src];action=steal">
		<h4>🤫 Steal</h4>
		<p>Attempt to pilfer goods unnoticed. Skill check required.</p>
	</a>
	"}]

	<a class="choice-btn" href="?src=\ref[src];action=ignore">
		<h4>👋 [caravan.is_hostile() ? "Flee" : "Ignore"]</h4>
		<p>[caravan.is_hostile() ? "Try to escape before they catch you." : "Let them pass and continue your journey."]</p>
	</a>
</div>
</body>
</html>
"}

	popup.set_content(html)
	popup.open()

/**
 * Handle player choice
 */
/datum/caravan_encounter_controller/proc/Topic(href, list/href_list)
	if(resolved)
		return

	var/mob/living/user = usr
	if(!istype(user) || !(user in expedition?.members))
		return

	var/action = href_list["action"]
	switch(action)
		if("trade")
			if(!caravan.is_hostile())
				do_trade(user)
		if("attack")
			do_attack(user)
		if("steal")
			if(!caravan.is_hostile())
				do_steal(user)
		if("ignore")
			do_ignore(user)

/**
 * Handle trade action
 */
/datum/caravan_encounter_controller/proc/do_trade(mob/living/user)
	// Close encounter popup
	user << browse(null, "window=caravan_encounter")

	// Show trading popup
	show_trade_popup(user)

/**
 * Show trading interface
 */
/datum/caravan_encounter_controller/proc/show_trade_popup(mob/living/user)
	var/datum/browser/popup = new(user, "caravan_trade", "Caravan Trading", 500, 500)

	var/stock_html = ""
	for(var/item_path in caravan.stock)
		var/obj/item/temp = item_path
		var/item_name = initial(temp.name)
		var/quantity = caravan.stock[item_path]
		var/price = caravan.get_item_price(item_path)
		stock_html += {"
		<div class="item-row">
			<span class="item-name">[item_name]</span>
			<span class="item-qty">x[quantity]</span>
			<span class="item-price">[price]c</span>
			<a class="buy-btn" href="?src=\ref[src];action=buy;item=[item_path]">Buy</a>
		</div>
		"}

	var/html = {"
<!DOCTYPE html>
<html>
<head>
<style>
body {
	font-family: 'Segoe UI', Tahoma, sans-serif;
	background: #1a1a2e;
	color: #eee;
	margin: 0;
	padding: 15px;
}
.header {
	text-align: center;
	padding: 10px;
	background: #16213e;
	border-radius: 8px;
	margin-bottom: 15px;
}
.item-row {
	display: flex;
	align-items: center;
	padding: 8px;
	background: #16213e;
	border-radius: 4px;
	margin-bottom: 5px;
}
.item-name {
	flex: 1;
}
.item-qty {
	color: #888;
	margin: 0 10px;
}
.item-price {
	color: #ffcc00;
	margin: 0 10px;
}
.buy-btn {
	background: #2d5a27;
	color: #fff;
	padding: 5px 10px;
	border-radius: 4px;
	text-decoration: none;
}
.buy-btn:hover {
	background: #3d7a37;
}
.done-btn {
	display: block;
	background: #16213e;
	color: #fff;
	padding: 12px;
	border-radius: 8px;
	text-align: center;
	text-decoration: none;
	margin-top: 15px;
}
.done-btn:hover {
	background: #1a2744;
}
</style>
</head>
<body>
<div class="header">
	<h3>Trading with [caravan.name]</h3>
	<p>Caravan Cash: [caravan.caravan_cash] credits</p>
</div>

[stock_html ? stock_html : "<p>No goods available.</p>"]

<a class="done-btn" href="?src=\ref[src];action=done_trade">Done Trading</a>
</body>
</html>
"}

	popup.set_content(html)
	popup.open()

/**
 * Handle buy action from trade popup
 */
/datum/caravan_encounter_controller/proc/handle_buy(mob/living/user, item_path)
	// Check item exists in stock
	if(!(item_path in caravan.stock) || caravan.stock[item_path] <= 0)
		to_chat(user, span_warning("That item is no longer available."))
		return

	var/price = caravan.get_item_price(item_path)

	// Check player has credits (would need credit system integration)
	// For now, just spawn the item and reduce stock
	var/obj/item/new_item = new item_path(get_turf(user))
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.put_in_hands(new_item)
	else
		new_item.forceMove(get_turf(user))

	caravan.stock[item_path]--
	if(caravan.stock[item_path] <= 0)
		caravan.stock -= item_path

	to_chat(user, span_notice("You purchased [new_item.name] for [price] credits."))

	// Small reputation gain
	apply_reputation_change(caravan.faction_id, CARAVAN_TRADE_REP_GAIN)

	// Refresh trade popup
	show_trade_popup(user)

/**
 * Handle attack action
 */
/datum/caravan_encounter_controller/proc/do_attack(mob/living/user)
	resolved = TRUE
	outcome = "attack"

	// Close popup
	user << browse(null, "window=caravan_encounter")

	// Make guards hostile
	for(var/mob/living/simple_animal/hostile/caravan_guard/guard in guards)
		guard.GiveTarget(user)

	// Apply reputation loss
	apply_reputation_change(caravan.faction_id, CARAVAN_ATTACK_REP_LOSS)
	// Other factions hear about it
	for(var/other_faction in list("resurgence_clan", "jiajia_ren", "santata_factory", "cloud_town"))
		if(other_faction != caravan.faction_id)
			apply_reputation_change(other_faction, CARAVAN_ATTACK_REP_LOSS_OTHER)

	to_chat(user, span_boldwarning("You attack the caravan! The guards defend their goods."))

	// Notify other party members
	for(var/mob/living/M in expedition.members)
		if(M != user)
			to_chat(M, span_boldwarning("[user.name] has attacked the caravan!"))

/**
 * Handle steal action
 */
/datum/caravan_encounter_controller/proc/do_steal(mob/living/user)
	// Close popup
	user << browse(null, "window=caravan_encounter")

	// Get player's crafting skill
	var/skill_level = 5  // Default
	if(user.mind?.resurgence_stats)
		skill_level = user.mind.resurgence_stats.get_stat("crafting")

	// Difficulty based on guard count
	var/difficulty = 5 + caravan.guard_count

	// Calculate success chance
	var/success_chance = clamp(50 + (skill_level - difficulty) * 5, 5, 95)

	if(prob(success_chance))
		// Success! Steal some items
		var/stolen_count = 0
		for(var/item_path in caravan.stock)
			if(caravan.stock[item_path] > 0 && prob(50))
				var/obj/item/stolen = new item_path(get_turf(user))
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					H.put_in_hands(stolen)
				caravan.stock[item_path]--
				stolen_count++
				if(stolen_count >= 2)
					break

		to_chat(user, span_notice("You successfully pilfer [stolen_count] item(s) from the caravan unnoticed!"))

		// End encounter peacefully
		outcome = "steal"
		end_encounter_success()
	else
		// Caught!
		to_chat(user, span_boldwarning("You've been caught stealing! The guards attack!"))

		// Apply reputation loss
		apply_reputation_change(caravan.faction_id, CARAVAN_STEAL_FAIL_REP_LOSS)

		// Trigger combat
		outcome = "steal_failed"
		for(var/mob/living/simple_animal/hostile/caravan_guard/guard in guards)
			guard.GiveTarget(user)

/**
 * Handle ignore/flee action
 */
/datum/caravan_encounter_controller/proc/do_ignore(mob/living/user)
	resolved = TRUE
	outcome = caravan.is_hostile() ? "fled" : "ignore"

	// Close popup
	user << browse(null, "window=caravan_encounter")

	if(caravan.is_hostile())
		to_chat(user, span_notice("You slip away before the patrol spots you."))
	else
		to_chat(user, span_notice("You let the caravan pass and continue on your way."))

	end_encounter_success()

/**
 * End the encounter and return players to expedition
 */
/datum/caravan_encounter_controller/proc/end_encounter_success()
	resolved = TRUE

	// Resume caravan travel
	caravan.resume_travel()

	// Clear global encounter
	GLOB.current_caravan_encounter = null

	// Return players to corridor
	return_to_corridor()

/**
 * Return all players to the expedition corridor
 */
/datum/caravan_encounter_controller/proc/return_to_corridor()
	if(!GLOB.expedition_corridor)
		return

	// Get corridor start position
	var/turf/return_turf = get_turf(GLOB.expedition_corridor.start_landmark)
	if(!return_turf)
		return

	// Teleport all expedition members back
	for(var/mob/living/M in expedition.members)
		// Fade effect
		if(M.client)
			M.client.color = "#000000"

		M.forceMove(return_turf)

		// Fade back in
		if(M.client)
			animate(M.client, color = null, time = 5)

		to_chat(M, span_notice("You continue your expedition..."))

/**
 * Called when all guards are defeated
 */
/datum/caravan_encounter_controller/proc/guards_defeated()
	if(resolved && outcome != "attack")
		return

	resolved = TRUE

	// Let players loot
	to_chat(expedition.members, span_boldnotice("The caravan guards have been defeated! Loot their goods!"))

	// Spawn loot at wagon point
	if(wagon_point)
		var/turf/loot_turf = get_turf(wagon_point)
		for(var/item_path in caravan.stock)
			for(var/i in 1 to caravan.stock[item_path])
				new item_path(loot_turf)

	// Destroy the caravan
	caravan.destroy_caravan()

	// Allow players to leave after looting
	addtimer(CALLBACK(src, PROC_REF(end_encounter_success)), 30 SECONDS)

/**
 * Apply reputation change with a faction
 */
/datum/caravan_encounter_controller/proc/apply_reputation_change(faction_id, amount)
	var/datum/trading_faction/faction = GLOB.resurgence_trading?.get_faction(faction_id)
	if(faction)
		faction.modify_reputation(amount)

// ============================================
// CARAVAN GUARD MOB
// ============================================

/mob/living/simple_animal/hostile/caravan_guard
	name = "caravan guard"
	desc = "A guard protecting a trading caravan."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "hostile"
	icon_living = "hostile"
	health = 80
	maxHealth = 80
	melee_damage_lower = 15
	melee_damage_upper = 25
	attacktext = "strikes"
	attack_sound = 'sound/weapons/punch1.ogg'
	speed = 1
	faction = list("caravan")
	robust_searching = TRUE
	/// Which faction this guard belongs to
	var/faction_id

/mob/living/simple_animal/hostile/caravan_guard/proc/setup_appearance()
	switch(faction_id)
		if("resurgence_clan")
			name = "clan pilgrim guard"
			desc = "A lightly armed pilgrim defending their caravan."
			health = 60
			maxHealth = 60
			melee_damage_lower = 10
			melee_damage_upper = 18
		if("jiajia_ren")
			name = "flock protector"
			desc = "A bird-folk warrior with sharp talons."
			melee_damage_lower = 18
			melee_damage_upper = 28
		if("santata_factory")
			name = "factory enforcer"
			desc = "A heavily armored gnome with industrial weapons."
			health = 100
			maxHealth = 100
			melee_damage_lower = 20
			melee_damage_upper = 30
		if("cloud_town")
			name = "frontier guard"
			desc = "A seasoned hunter protecting the wagon."
			health = 80
			maxHealth = 80
			melee_damage_lower = 15
			melee_damage_upper = 25
		if("insurgence_clan")
			name = "insurgence raider"
			desc = "A hostile raider looking for prey."
			health = 90
			maxHealth = 90
			melee_damage_lower = 20
			melee_damage_upper = 35

/mob/living/simple_animal/hostile/caravan_guard/death(gibbed)
	. = ..()
	// Check if all guards are dead
	if(GLOB.current_caravan_encounter)
		var/all_dead = TRUE
		var/datum/caravan_encounter_controller/controller = locate() in GLOB.active_expeditions
		// Find controller through caravan
		for(var/mob/living/simple_animal/hostile/caravan_guard/G in view(10, src))
			if(G.stat != DEAD)
				all_dead = FALSE
				break
		if(all_dead)
			// Signal guards defeated - would need proper controller reference
			log_game("All caravan guards defeated")
