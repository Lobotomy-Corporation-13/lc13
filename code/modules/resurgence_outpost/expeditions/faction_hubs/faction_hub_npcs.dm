// Faction Hub NPCs
// Civilian NPCs that populate faction hubs

// ============================================
// GLOBAL ANGER TRACKING
// ============================================

/// Shared anger level for Jiajia-ren (Cuckoo) NPCs
GLOBAL_VAR_INIT(jiajia_ren_anger, 0)
/// Shared anger level for Cloud Town NPCs
GLOBAL_VAR_INIT(cloud_town_anger, 0)
/// Shared anger level for Santata Factory NPCs
GLOBAL_VAR_INIT(santata_factory_anger, 0)
/// Shared anger level for Resurgence Clan NPCs
GLOBAL_VAR_INIT(resurgence_clan_anger, 0)

/// Maximum anger before hostility triggers
#define JIAJIA_REN_ANGER_MAX 100
/// Anger threshold for warnings
#define JIAJIA_REN_ANGER_WARN 50
/// Anger gained per attack
#define JIAJIA_REN_ANGER_PER_ATTACK 25
/// Anger gained on NPC death
#define JIAJIA_REN_ANGER_ON_DEATH 100
/// Reputation threshold to calm down
#define JIAJIA_REN_CALM_REP 40
/// Reputation set when angered
#define JIAJIA_REN_HOSTILE_REP 10

// Cloud Town anger thresholds
#define CLOUD_TOWN_ANGER_MAX 100
#define CLOUD_TOWN_ANGER_WARN 50
#define CLOUD_TOWN_ANGER_PER_ATTACK 20
#define CLOUD_TOWN_CALM_REP 40
#define CLOUD_TOWN_HOSTILE_REP 10

// Santata Factory anger thresholds
#define SANTATA_FACTORY_ANGER_MAX 100
#define SANTATA_FACTORY_ANGER_WARN 50
#define SANTATA_FACTORY_ANGER_PER_ATTACK 20
#define SANTATA_FACTORY_CALM_REP 40
#define SANTATA_FACTORY_HOSTILE_REP 10

// Resurgence Clan anger thresholds
#define RESURGENCE_CLAN_ANGER_MAX 100
#define RESURGENCE_CLAN_ANGER_WARN 50
#define RESURGENCE_CLAN_ANGER_PER_ATTACK 20
#define RESURGENCE_CLAN_CALM_REP 40
#define RESURGENCE_CLAN_HOSTILE_REP 10

// ============================================
// BASE FACTION HUB CIVILIAN
// ============================================

/**
 * Base faction hub civilian NPC
 * Inherits from hostile for flee behavior but starts neutral
 */
/mob/living/simple_animal/hostile/faction_hub_civilian
	name = "Civilian"
	desc = "A faction civilian going about their day."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "faceless"
	maxHealth = 80
	health = 80

	// Non-hostile by default - starts neutral
	faction = list("neutral")
	wander = TRUE
	turns_per_move = 5
	density = TRUE
	anchored = FALSE
	mob_size = MOB_SIZE_HUMAN
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID

	// Interaction
	response_help_continuous = "looks at"
	response_help_simple = "look at"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "hits"
	response_harm_simple = "hit"

	// Speech
	speak_emote = list("says")

	/// The faction this civilian belongs to
	var/faction_id = null
	/// Whether this NPC can become hostile
	var/can_become_hostile = TRUE

/mob/living/simple_animal/hostile/faction_hub_civilian/death(gibbed)
	. = ..()
	on_civilian_killed()

/**
 * Called when this civilian is killed
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/proc/on_civilian_killed()
	return

/**
 * Called when this civilian is attacked
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/proc/on_attacked(mob/living/attacker)
	return

/mob/living/simple_animal/hostile/faction_hub_civilian/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		on_attacked(user)

/mob/living/simple_animal/hostile/faction_hub_civilian/attackby(obj/item/O, mob/user, params)
	. = ..()
	if(O.force > 0)
		on_attacked(user)

/mob/living/simple_animal/hostile/faction_hub_civilian/bullet_act(obj/projectile/P)
	. = ..()
	if(P.firer && isliving(P.firer))
		on_attacked(P.firer)

// ============================================
// JIAJIA-REN (CUCKOO) CIVILIANS
// ============================================

/**
 * Base Jiajia-ren civilian
 * Bird-folk that share anger and can become hostile
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren
	name = "Jiajia-ren Villager"
	desc = "A bird-like creature going about their daily business. They seem friendly enough."
	icon = 'icons/mob/cuckoospawn.dmi'
	icon_state = "cuckoospawn"
	maxHealth = 400
	health = 400
	faction_id = "jiajia_ren"

	// Combat stats when hostile
	melee_damage_lower = 10
	melee_damage_upper = 15
	attack_verb_continuous = "pecks"
	attack_verb_simple = "peck"
	attack_sound = 'sound/weapons/bite.ogg'

/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/Initialize(mapload)
	. = ..()
	// Check if we should start hostile (anger already high)
	check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/on_attacked(mob/living/attacker)
	if(!attacker)
		return

	// Increase shared anger
	GLOB.jiajia_ren_anger = min(GLOB.jiajia_ren_anger + JIAJIA_REN_ANGER_PER_ATTACK, JIAJIA_REN_ANGER_MAX)

	// Warn at threshold
	if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_WARN && GLOB.jiajia_ren_anger < JIAJIA_REN_ANGER_MAX)
		say("*Angry hiss* You attack flock? Flock remembers!")
		manual_emote("glares at [attacker].")
	else if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_MAX)
		say("*SCREECH* FLOCK ATTACKS!")

	// Check if this triggers hostility
	check_anger_state()

	// Notify all other Jiajia-ren
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/J in GLOB.mob_list)
		if(J != src && J.stat == CONSCIOUS)
			J.check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/on_civilian_killed()
	// Killing one makes them all hostile
	GLOB.jiajia_ren_anger = JIAJIA_REN_ANGER_MAX

	// Set reputation to hostile level
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("jiajia_ren")
		if(faction)
			faction.reputation = JIAJIA_REN_HOSTILE_REP
			log_game("Jiajia-ren reputation set to [JIAJIA_REN_HOSTILE_REP] due to civilian death")

	// Make all Jiajia-ren hostile
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/J in GLOB.mob_list)
		if(J.stat == CONSCIOUS)
			J.become_hostile()

/**
 * Check anger state and update hostility accordingly
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/proc/check_anger_state()
	// Check if we should be hostile
	if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_MAX)
		become_hostile()
		return

	// Check if we should calm down (based on reputation)
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("jiajia_ren")
		if(faction && faction.reputation >= JIAJIA_REN_CALM_REP)
			become_neutral()
			// Reset anger when calmed
			GLOB.jiajia_ren_anger = 0

/**
 * Make this NPC hostile
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/proc/become_hostile()
	if(!can_become_hostile)
		return
	if("hostile" in faction)
		return // Already hostile

	faction -= "neutral"
	faction += "hostile"
	desc = "A bird-like creature with rage in its eyes. The flock has turned against you!"

	// Set reputation to hostile level if not already
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/F = GLOB.resurgence_trading.get_faction("jiajia_ren")
		if(F && F.reputation > JIAJIA_REN_HOSTILE_REP)
			F.reputation = JIAJIA_REN_HOSTILE_REP
			log_game("Jiajia-ren reputation set to [JIAJIA_REN_HOSTILE_REP] due to anger")

/**
 * Make this NPC neutral again
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/proc/become_neutral()
	if(!("hostile" in faction))
		return // Already neutral

	faction -= "hostile"
	faction += "neutral"
	desc = "A bird-like creature going about their daily business. They seem friendly enough."

// ============================================
// JIAJIA-REN GUARD
// ============================================

/**
 * Jiajia-ren Guard
 * Stronger variant that protects the village
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/guard
	name = "Jiajia-ren Guard"
	desc = "A large, intimidating bird-creature. Its sharp talons look deadly."
	icon = 'icons/mob/cuckoospawn_big.dmi'
	icon_state = "evil_ass_bird"
	maxHealth = 1200
	health = 1200

	// Stronger combat stats
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/slice.ogg'

	wander = FALSE  // Guards stay in place

/mob/living/simple_animal/hostile/faction_hub_civilian/jiajia_ren/guard/on_attacked(mob/living/attacker)
	// Guards get angrier faster
	GLOB.jiajia_ren_anger = min(GLOB.jiajia_ren_anger + (JIAJIA_REN_ANGER_PER_ATTACK * 2), JIAJIA_REN_ANGER_MAX)

	if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_WARN && GLOB.jiajia_ren_anger < JIAJIA_REN_ANGER_MAX)
		say("*Threatening screech* You dare attack guard?! Leave NOW!")
	else if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_MAX)
		say("*BATTLE CRY* INTRUDERS WILL DIE!")

	// Call parent to handle the rest
	..()

// ============================================
// CLOUD TOWN CIVILIANS
// ============================================

/**
 * Base Cloud Town civilian
 * Peaceful farming folk from Cloud Town
 * Flees when attacked instead of fighting
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town
	name = "Cloud Town Villager"
	desc = "A humble villager from Cloud Town. They seem to be going about their daily business."
	icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
	icon_state = "cloud_villager"
	maxHealth = 150
	health = 150
	faction_id = "cloud_town"

	// Flee behavior - runs away when attacked
	ranged = TRUE
	retreat_distance = 10
	minimum_distance = 10

	// Minimal combat - civilians don't fight
	melee_damage_lower = 0
	melee_damage_upper = 4
	attack_verb_continuous = "shoves"
	attack_verb_simple = "shove"

	/// Idle dialogue lines
	var/list/idle_lines = list(
		"The harvest looks good this season.",
		"Have you tried our famous cloud bread?",
		"The hunters brought back a good haul today.",
		"Weather's been mild lately. Good for the crops."
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/Initialize(mapload)
	. = ..()
	check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/on_attacked(mob/living/attacker)
	if(!attacker)
		return

	// Increase shared anger
	GLOB.cloud_town_anger = min(GLOB.cloud_town_anger + CLOUD_TOWN_ANGER_PER_ATTACK, CLOUD_TOWN_ANGER_MAX)

	// Warn at threshold
	if(GLOB.cloud_town_anger >= CLOUD_TOWN_ANGER_WARN && GLOB.cloud_town_anger < CLOUD_TOWN_ANGER_MAX)
		say("You attack one of us? The town won't stand for this!")
	else if(GLOB.cloud_town_anger >= CLOUD_TOWN_ANGER_MAX)
		say("You've gone too far! Defend the town!")

	check_anger_state()

	// Notify all other Cloud Town NPCs
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/C in GLOB.mob_list)
		if(C != src && C.stat == CONSCIOUS)
			C.check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/on_civilian_killed()
	// Killing one makes them all hostile
	GLOB.cloud_town_anger = CLOUD_TOWN_ANGER_MAX

	// Set reputation to hostile level
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("cloud_town")
		if(faction)
			faction.reputation = CLOUD_TOWN_HOSTILE_REP
			log_game("Cloud Town reputation set to [CLOUD_TOWN_HOSTILE_REP] due to civilian death")

	// Make all Cloud Town NPCs hostile
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/C in GLOB.mob_list)
		if(C.stat == CONSCIOUS)
			C.become_hostile()

/**
 * Check anger state and update hostility accordingly
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/proc/check_anger_state()
	if(GLOB.cloud_town_anger >= CLOUD_TOWN_ANGER_MAX)
		become_hostile()
		return

	// Check if we should calm down (based on reputation)
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("cloud_town")
		if(faction && faction.reputation >= CLOUD_TOWN_CALM_REP)
			become_neutral()
			GLOB.cloud_town_anger = 0

/**
 * Make this NPC hostile
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/proc/become_hostile()
	if(!can_become_hostile)
		return
	if("hostile" in faction)
		return

	faction -= "neutral"
	faction += "hostile"
	desc = "A Cloud Town villager with fury in their eyes. The town has turned against you!"

	if(GLOB.resurgence_trading)
		var/datum/trading_faction/F = GLOB.resurgence_trading.get_faction("cloud_town")
		if(F && F.reputation > CLOUD_TOWN_HOSTILE_REP)
			F.reputation = CLOUD_TOWN_HOSTILE_REP

/**
 * Make this NPC neutral again
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/proc/become_neutral()
	if(!("hostile" in faction))
		return

	faction -= "hostile"
	faction += "neutral"
	desc = "A humble villager from Cloud Town. They seem to be going about their daily business."

/**
 * Cloud Town Hunter
 * Armed protectors who hunt in the wastes
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/hunter
	name = "Cloud Town Hunter"
	desc = "A skilled hunter from Cloud Town. They venture into the wastes for game and resources."
	maxHealth = 300
	health = 300

	// Hunters fight, not flee
	ranged = FALSE
	retreat_distance = null
	minimum_distance = null

	melee_damage_lower = 15
	melee_damage_upper = 25
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"

	wander = FALSE  // Hunters patrol or stand guard

/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/hunter/Initialize(mapload)
	. = ..()
	// Randomly pick one of the hunter variants
	icon_state = pick("cloud_hunter1", "cloud_hunter2", "cloud_hunter3")
	idle_lines = list(
		"Stay alert out there. The wastes are dangerous.",
		"Heard there's good hunting near the old ruins.",
		"My bow's been faithful for years now.",
		"Keep your wits about you, traveler."
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/cloud_town/hunter/on_attacked(mob/living/attacker)
	// Hunters get angrier faster
	GLOB.cloud_town_anger = min(GLOB.cloud_town_anger + (CLOUD_TOWN_ANGER_PER_ATTACK * 2), CLOUD_TOWN_ANGER_MAX)

	if(GLOB.cloud_town_anger >= CLOUD_TOWN_ANGER_WARN && GLOB.cloud_town_anger < CLOUD_TOWN_ANGER_MAX)
		say("You dare attack a hunter? You'll regret this!")
	else if(GLOB.cloud_town_anger >= CLOUD_TOWN_ANGER_MAX)
		say("To arms! Defend Cloud Town!")

	..()

// ============================================
// SANTATA FACTORY (GNOME) CIVILIANS
// ============================================

/**
 * Base Santata Factory gnome
 * Industrious little workers from the workshop
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory
	name = "Santata Worker"
	desc = "A small, industrious gnome working in the factory. They seem perpetually busy."
	icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
	icon_state = "gnome_green"
	maxHealth = 50
	health = 50
	faction_id = "santata_factory"

	// Gnomes are small
	mob_size = MOB_SIZE_SMALL

	// Combat stats if attacked
	melee_damage_lower = 8
	melee_damage_upper = 15
	attack_verb_continuous = "whacks"
	attack_verb_simple = "whack"

	/// Idle dialogue lines
	var/list/idle_lines = list(
		"Work work-ome! Always work-ome!",
		"The machines need oil-ome!",
		"Production quota-ome! Must meet quota-ome!",
		"Busy busy-ome! No time to chat-ome!"
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/Initialize(mapload)
	. = ..()
	// Randomly pick gnome color
	icon_state = pick("gnome_green", "gnome_purple")
	check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/on_attacked(mob/living/attacker)
	if(!attacker)
		return

	// Increase shared anger
	GLOB.santata_factory_anger = min(GLOB.santata_factory_anger + SANTATA_FACTORY_ANGER_PER_ATTACK, SANTATA_FACTORY_ANGER_MAX)

	// Warn at threshold
	if(GLOB.santata_factory_anger >= SANTATA_FACTORY_ANGER_WARN && GLOB.santata_factory_anger < SANTATA_FACTORY_ANGER_MAX)
		say("You attack worker-ome?! Factory remembers-ome!")
	else if(GLOB.santata_factory_anger >= SANTATA_FACTORY_ANGER_MAX)
		say("FACTORY DEFENDS-OME! CRUSH INTRUDER-OME!")

	check_anger_state()

	// Notify all other Santata Factory NPCs
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/S in GLOB.mob_list)
		if(S != src && S.stat == CONSCIOUS)
			S.check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/on_civilian_killed()
	// Killing one makes them all hostile
	GLOB.santata_factory_anger = SANTATA_FACTORY_ANGER_MAX

	// Set reputation to hostile level
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("santata_factory")
		if(faction)
			faction.reputation = SANTATA_FACTORY_HOSTILE_REP
			log_game("Santata Factory reputation set to [SANTATA_FACTORY_HOSTILE_REP] due to civilian death")

	// Make all Santata Factory NPCs hostile
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/S in GLOB.mob_list)
		if(S.stat == CONSCIOUS)
			S.become_hostile()

/**
 * Check anger state and update hostility accordingly
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/proc/check_anger_state()
	if(GLOB.santata_factory_anger >= SANTATA_FACTORY_ANGER_MAX)
		become_hostile()
		return

	// Check if we should calm down (based on reputation)
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("santata_factory")
		if(faction && faction.reputation >= SANTATA_FACTORY_CALM_REP)
			become_neutral()
			GLOB.santata_factory_anger = 0

/**
 * Make this NPC hostile
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/proc/become_hostile()
	if(!can_become_hostile)
		return
	if("hostile" in faction)
		return

	faction -= "neutral"
	faction += "hostile"
	desc = "A gnome with rage in its eyes. The Factory has turned against you-ome!"

	if(GLOB.resurgence_trading)
		var/datum/trading_faction/F = GLOB.resurgence_trading.get_faction("santata_factory")
		if(F && F.reputation > SANTATA_FACTORY_HOSTILE_REP)
			F.reputation = SANTATA_FACTORY_HOSTILE_REP

/**
 * Make this NPC neutral again
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/proc/become_neutral()
	if(!("hostile" in faction))
		return

	faction -= "hostile"
	faction += "neutral"
	desc = "A small, industrious gnome working in the factory. They seem perpetually busy."

/**
 * Santata Factory green gnome variant
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/green
	icon_state = "gnome_green"

/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/green/Initialize(mapload)
	icon_state = "gnome_green"  // Override the random selection
	. = ..()
	icon_state = "gnome_green"

/**
 * Santata Factory purple gnome variant
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/purple
	icon_state = "gnome_purple"

/mob/living/simple_animal/hostile/faction_hub_civilian/santata_factory/purple/Initialize(mapload)
	icon_state = "gnome_purple"  // Override the random selection
	. = ..()
	icon_state = "gnome_purple"

// ============================================
// RESURGENCE CLAN CIVILIANS
// ============================================

/**
 * Base Resurgence Clan civilian
 * Fellow clan members living in the village
 * Flees when attacked instead of fighting
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan
	name = "Clan Citizen"
	desc = "A member of the Resurgence Clan. They seem friendly and welcoming."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_32x48.dmi'
	icon_state = "clan_citzen_5"  // Most common variant
	maxHealth = 300
	health = 300
	faction_id = "resurgence_clan"

	// Flee behavior - civilians run away when attacked
	ranged = TRUE
	retreat_distance = 10
	minimum_distance = 10

	// Minimal combat - civilians don't fight
	melee_damage_lower = 0
	melee_damage_upper = 4
	attack_verb_continuous = "shoves"
	attack_verb_simple = "shove"

	/// Idle dialogue lines
	var/list/idle_lines = list(
		"We-elcome to our vi-illage!",
		"The cla-an grows stronger every da-ay.",
		"Ha-ave you me-et our trader, Ronan?",
		"Sta-ay as long as you li-ike.",
		"The Hi-istorian watches over us a-all."
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/Initialize(mapload)
	. = ..()
	// Pick variant based on rarity
	// clan_citzen_5 is most common (40%)
	// clan_citzen is common (25%)
	// clan_citzen_1 through 4 are uncommon (30% split)
	// clan_citzen_6 is rare (5%)
	var/roll = rand(1, 100)
	if(roll <= 5)
		icon_state = "clan_citzen_6"  // Rare
	else if(roll <= 45)
		icon_state = "clan_citzen_5"  // Most common
	else if(roll <= 70)
		icon_state = "clan_citzen"    // Common
	else
		icon_state = pick("clan_citzen_1", "clan_citzen_2", "clan_citzen_3", "clan_citzen_4")  // Uncommon

	check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/on_attacked(mob/living/attacker)
	if(!attacker)
		return

	// Increase shared anger
	GLOB.resurgence_clan_anger = min(GLOB.resurgence_clan_anger + RESURGENCE_CLAN_ANGER_PER_ATTACK, RESURGENCE_CLAN_ANGER_MAX)

	// Warn at threshold
	if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_WARN && GLOB.resurgence_clan_anger < RESURGENCE_CLAN_ANGER_MAX)
		say("You a-attack one of us?! The cla-an will not forget this!")
	else if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_MAX)
		say("De-efend the village! To a-arms!")

	check_anger_state()

	// Notify all other Resurgence Clan NPCs
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/R in GLOB.mob_list)
		if(R != src && R.stat == CONSCIOUS)
			R.check_anger_state()

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/on_civilian_killed()
	// Killing one makes them all hostile
	GLOB.resurgence_clan_anger = RESURGENCE_CLAN_ANGER_MAX

	// Set reputation to hostile level
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("resurgence_clan")
		if(faction)
			faction.reputation = RESURGENCE_CLAN_HOSTILE_REP
			log_game("Resurgence Clan reputation set to [RESURGENCE_CLAN_HOSTILE_REP] due to civilian death")

	// Make all Resurgence Clan NPCs hostile
	for(var/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/R in GLOB.mob_list)
		if(R.stat == CONSCIOUS)
			R.become_hostile()

/**
 * Check anger state and update hostility accordingly
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/proc/check_anger_state()
	if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_MAX)
		become_hostile()
		return

	// Check if we should calm down (based on reputation)
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("resurgence_clan")
		if(faction && faction.reputation >= RESURGENCE_CLAN_CALM_REP)
			become_neutral()
			GLOB.resurgence_clan_anger = 0

/**
 * Make this NPC hostile
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/proc/become_hostile()
	if(!can_become_hostile)
		return
	if("hostile" in faction)
		return

	faction -= "neutral"
	faction += "hostile"
	desc = "A Resurgence Clan member with fury in their eyes. The clan has turned against you!"

	if(GLOB.resurgence_trading)
		var/datum/trading_faction/F = GLOB.resurgence_trading.get_faction("resurgence_clan")
		if(F && F.reputation > RESURGENCE_CLAN_HOSTILE_REP)
			F.reputation = RESURGENCE_CLAN_HOSTILE_REP

/**
 * Make this NPC neutral again
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/proc/become_neutral()
	if(!("hostile" in faction))
		return

	faction -= "hostile"
	faction += "neutral"
	desc = "A member of the Resurgence Clan. They seem friendly and welcoming."

/**
 * Specific Resurgence Clan citizen variants for mapping
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant1
	icon_state = "clan_citzen_1"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant1/Initialize(mapload)
	icon_state = "clan_citzen_1"
	. = ..()
	icon_state = "clan_citzen_1"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant2
	icon_state = "clan_citzen_2"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant2/Initialize(mapload)
	icon_state = "clan_citzen_2"
	. = ..()
	icon_state = "clan_citzen_2"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant3
	icon_state = "clan_citzen_3"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant3/Initialize(mapload)
	icon_state = "clan_citzen_3"
	. = ..()
	icon_state = "clan_citzen_3"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant4
	icon_state = "clan_citzen_4"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant4/Initialize(mapload)
	icon_state = "clan_citzen_4"
	. = ..()
	icon_state = "clan_citzen_4"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant5
	icon_state = "clan_citzen_5"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant5/Initialize(mapload)
	icon_state = "clan_citzen_5"
	. = ..()
	icon_state = "clan_citzen_5"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant6
	icon_state = "clan_citzen_6"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/variant6/Initialize(mapload)
	icon_state = "clan_citzen_6"
	. = ..()
	icon_state = "clan_citzen_6"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/base
	icon_state = "clan_citzen"

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/base/Initialize(mapload)
	icon_state = "clan_citzen"
	. = ..()
	icon_state = "clan_citzen"

// ============================================
// RESURGENCE CLAN GUARDS
// ============================================

/**
 * Resurgence Clan Scout
 * Light patrol guard that watches the village perimeter
 * Stats match /mob/living/simple_animal/hostile/clan/scout
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/scout
	name = "Clan Scout"
	desc = "A vigilant scout of the Resurgence Clan. They keep watch over the village."
	icon_state = "clan_scout_normal"
	maxHealth = 500
	health = 500

	// Scouts fight, not flee
	ranged = FALSE
	retreat_distance = null
	minimum_distance = null

	melee_damage_lower = 5
	melee_damage_upper = 7
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/weapons/purple_tear/stab2.ogg'

	wander = FALSE  // Scouts stay at their post

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/scout/Initialize(mapload)
	icon_state = "clan_scout_normal"
	. = ..()
	icon_state = "clan_scout_normal"
	idle_lines = list(
		"Sta-ay alert. The wa-astes are dangerous.",
		"The vi-illage is under our pro-otection.",
		"I've se-een things out there... te-errible things.",
		"Mo-ove along, tra-aveler."
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/scout/on_attacked(mob/living/attacker)
	// Scouts get angrier faster
	GLOB.resurgence_clan_anger = min(GLOB.resurgence_clan_anger + (RESURGENCE_CLAN_ANGER_PER_ATTACK * 2), RESURGENCE_CLAN_ANGER_MAX)

	if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_WARN && GLOB.resurgence_clan_anger < RESURGENCE_CLAN_ANGER_MAX)
		say("You da-are attack a scout?! You'll re-egret this!")
	else if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_MAX)
		say("INTRU-UDERS! TO A-ARMS!")

	..()

/**
 * Resurgence Clan Defender
 * Heavy guard that protects important areas
 * Stats match /mob/living/simple_animal/hostile/clan/defender
 */
/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/defender
	name = "Clan Defender"
	desc = "A heavily armored defender of the Resurgence Clan. They look imposing."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_48x48.dmi'
	icon_state = "defender_normal"
	maxHealth = 1200
	health = 1200
	pixel_x = -8
	base_pixel_x = -8

	// Defenders fight, not flee
	ranged = FALSE
	retreat_distance = null
	minimum_distance = null

	melee_damage_lower = 20
	melee_damage_upper = 25
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/weapons/purple_tear/blunt2.ogg'

	wander = FALSE  // Defenders guard fixed positions

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/defender/Initialize(mapload)
	icon_state = "defender_normal"
	. = ..()
	icon_state = "defender_normal"
	idle_lines = list(
		"No-one passes wi-ithout permission.",
		"The cla-an's safety is my du-uty.",
		"Sta-and down or fa-ace consequences.",
		"I've cru-ushed raiders before. Do-on't test me."
	)

/mob/living/simple_animal/hostile/faction_hub_civilian/resurgence_clan/defender/on_attacked(mob/living/attacker)
	// Defenders get angrier faster
	GLOB.resurgence_clan_anger = min(GLOB.resurgence_clan_anger + (RESURGENCE_CLAN_ANGER_PER_ATTACK * 2), RESURGENCE_CLAN_ANGER_MAX)

	if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_WARN && GLOB.resurgence_clan_anger < RESURGENCE_CLAN_ANGER_MAX)
		say("You da-are attack a defe-ender?! FOOL!")
	else if(GLOB.resurgence_clan_anger >= RESURGENCE_CLAN_ANGER_MAX)
		say("CRU-USH THE INTRU-UDERS!")

	..()
