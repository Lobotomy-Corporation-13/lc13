// Faction Hub NPCs
// Civilian NPCs that populate faction hubs

// ============================================
// GLOBAL ANGER TRACKING
// ============================================

/// Shared anger level for Jiajia-ren (Cuckoo) NPCs
GLOBAL_VAR_INIT(jiajia_ren_anger, 0)

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

// ============================================
// BASE FACTION HUB CIVILIAN
// ============================================

/**
 * Base faction hub civilian NPC
 * Non-hostile civilians that populate faction hubs
 */
/mob/living/simple_animal/faction_hub_civilian
	name = "Civilian"
	desc = "A faction civilian going about their day."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "faceless"
	maxHealth = 80
	health = 80

	// Non-hostile by default
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

/mob/living/simple_animal/faction_hub_civilian/death(gibbed)
	. = ..()
	on_civilian_killed()

/**
 * Called when this civilian is killed
 */
/mob/living/simple_animal/faction_hub_civilian/proc/on_civilian_killed()
	return

/**
 * Called when this civilian is attacked
 */
/mob/living/simple_animal/faction_hub_civilian/proc/on_attacked(mob/living/attacker)
	return

/mob/living/simple_animal/faction_hub_civilian/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		on_attacked(user)

/mob/living/simple_animal/faction_hub_civilian/attackby(obj/item/O, mob/user, params)
	. = ..()
	if(O.force > 0)
		on_attacked(user)

/mob/living/simple_animal/faction_hub_civilian/bullet_act(obj/projectile/P)
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
/mob/living/simple_animal/faction_hub_civilian/jiajia_ren
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

/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/Initialize(mapload)
	. = ..()
	// Check if we should start hostile (anger already high)
	check_anger_state()

/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/on_attacked(mob/living/attacker)
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
	for(var/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/J in GLOB.mob_list)
		if(J != src && J.stat == CONSCIOUS)
			J.check_anger_state()

/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/on_civilian_killed()
	// Killing one makes them all hostile
	GLOB.jiajia_ren_anger = JIAJIA_REN_ANGER_MAX

	// Set reputation to hostile level
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction("jiajia_ren")
		if(faction)
			faction.reputation = JIAJIA_REN_HOSTILE_REP
			log_game("Jiajia-ren reputation set to [JIAJIA_REN_HOSTILE_REP] due to civilian death")

	// Make all Jiajia-ren hostile
	for(var/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/J in GLOB.mob_list)
		if(J.stat == CONSCIOUS)
			J.become_hostile()

/**
 * Check anger state and update hostility accordingly
 */
/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/proc/check_anger_state()
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
/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/proc/become_hostile()
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
/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/proc/become_neutral()
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
/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/guard
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

/mob/living/simple_animal/faction_hub_civilian/jiajia_ren/guard/on_attacked(mob/living/attacker)
	// Guards get angrier faster
	GLOB.jiajia_ren_anger = min(GLOB.jiajia_ren_anger + (JIAJIA_REN_ANGER_PER_ATTACK * 2), JIAJIA_REN_ANGER_MAX)

	if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_WARN && GLOB.jiajia_ren_anger < JIAJIA_REN_ANGER_MAX)
		say("*Threatening screech* You dare attack guard?! Leave NOW!")
	else if(GLOB.jiajia_ren_anger >= JIAJIA_REN_ANGER_MAX)
		say("*BATTLE CRY* INTRUDERS WILL DIE!")

	// Call parent to handle the rest
	..()
