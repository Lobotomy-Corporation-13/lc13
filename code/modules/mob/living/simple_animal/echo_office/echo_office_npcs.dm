// Echo Office NPC Fixers
// Talkable NPCs that can be challenged to duels

/obj/item/quest_ticket/echo_office
	name = "'Echo Office' ticket"
	map = "_maps/Quests/echo_office.dmm"
	map_name = "echo_office_floor"
	ticket_name = "Echo Office"

// ==================== DUEL LANDMARKS ====================

GLOBAL_LIST_EMPTY(fixer_duel_player_spawns)
GLOBAL_LIST_EMPTY(fixer_duel_fixer_spawns)

// Where the player is teleported to for the duel
/obj/effect/landmark/fixer_duel/player_spawn
	name = "fixer duel player spawn"
	icon_state = "x2"

/obj/effect/landmark/fixer_duel/player_spawn/Initialize(mapload)
	. = ..()
	GLOB.fixer_duel_player_spawns += src

/obj/effect/landmark/fixer_duel/player_spawn/Destroy()
	GLOB.fixer_duel_player_spawns -= src
	return ..()

// Where the fixer mob spawns for the duel
/obj/effect/landmark/fixer_duel/fixer_spawn
	name = "fixer duel fixer spawn"
	icon_state = "x2"

/obj/effect/landmark/fixer_duel/fixer_spawn/Initialize(mapload)
	. = ..()
	GLOB.fixer_duel_fixer_spawns += src

/obj/effect/landmark/fixer_duel/fixer_spawn/Destroy()
	GLOB.fixer_duel_fixer_spawns -= src
	return ..()

// ==================== BASE NPC CLASS ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer
	name = "Echo Office Fixer"
	desc = "A member of the Echo Office."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "priest"
	icon_living = "priest"
	maxHealth = 500
	health = 500
	damage_coeff = list(BRUTE = 0, FIRE = 0, RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	faction = list("neutral")
	typing_interval = 30
	typing_volume = 25
	talking = sound('sound/creatures/lc13/mailman.ogg', repeat = TRUE)
	stat_attack = CONSCIOUS
	return_to_origin = TRUE
	mark_once_attacked = FALSE

	/// Can this NPC be challenged to a duel?
	var/can_duel = TRUE
	/// Can this NPC participate in duo duels?
	var/can_duo_duel = TRUE
	/// The mob type to spawn for duels
	var/duel_fixer_type
	/// List of replica gear types to reward on victory
	var/list/duel_rewards = list()
	/// Is this NPC currently in a duel?
	var/in_duel = FALSE
	/// The player currently dueling
	var/mob/living/current_duelist
	/// Where to return the duelist after the duel
	var/turf/duelist_return_turf
	/// The spawned fixer mob
	var/mob/living/spawned_fixer
	/// The second spawned fixer for duo duels
	var/mob/living/spawned_fixer_2
	/// Count of fixers defeated in duo duel
	var/duo_fixers_defeated = 0
	/// Is this a duo duel?
	var/is_duo_duel = FALSE
	/// Original turf of this NPC
	var/turf/npc_original_turf
	/// Has this fixer already given out their replica gear?
	var/has_given_rewards = FALSE
	/// The partner fixer type for duo duels (to find their NPC)
	var/partner_fixer_type
	/// Cooldown time after winning a duel (10 minutes)
	var/duel_win_cooldown = 10 MINUTES
	/// List of player ckeys and when their cooldown expires
	var/list/duel_cooldowns = list()
	/// Achievement type to award when beaten in solo duel
	var/achievement_type

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/Initialize()
	. = ..()
	npc_original_turf = get_turf(src)

/// Find a fixer NPC by their combat mob type
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/find_fixer_by_type(fixer_type)
	for(var/mob/living/simple_animal/hostile/ui_npc/echo_fixer/F in GLOB.alive_mob_list)
		if(F.duel_fixer_type == fixer_type)
			return F
	return null

/// Check if a player is on cooldown from winning a duel
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/check_duel_cooldown(mob/living/challenger)
	if(!challenger?.ckey)
		return FALSE
	var/cooldown_end = duel_cooldowns[challenger.ckey]
	if(cooldown_end && world.time < cooldown_end)
		var/remaining = (cooldown_end - world.time) / 10 // Convert to seconds
		var/minutes = round(remaining / 60)
		var/seconds = round(remaining % 60)
		to_chat(challenger, span_warning("You must wait [minutes]m [seconds]s before challenging [src] again."))
		return TRUE
	return FALSE

/// Set cooldown for a player after winning
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/set_duel_cooldown(mob/living/winner)
	if(!winner?.ckey)
		return
	duel_cooldowns[winner.ckey] = world.time + duel_win_cooldown

// ==================== DUEL SYSTEM ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/StartDuel(mob/living/challenger)
	if(!can_duel)
		to_chat(challenger, span_warning("[src] cannot be challenged to a duel."))
		return FALSE
	if(in_duel)
		to_chat(challenger, span_warning("[src] is already in a duel with someone else."))
		return FALSE
	if(check_duel_cooldown(challenger))
		return FALSE
	if(!length(GLOB.fixer_duel_player_spawns))
		to_chat(challenger, span_warning("There is no duel arena available."))
		return FALSE
	if(!length(GLOB.fixer_duel_fixer_spawns))
		to_chat(challenger, span_warning("There is no duel arena available."))
		return FALSE
	if(!duel_fixer_type)
		to_chat(challenger, span_warning("[src] has no combat form."))
		return FALSE

	// Set up duel state
	in_duel = TRUE
	current_duelist = challenger
	duelist_return_turf = get_turf(challenger)

	// Teleport player to duel arena
	var/obj/effect/landmark/fixer_duel/player_spawn/player_landmark = pick(GLOB.fixer_duel_player_spawns)
	challenger.forceMove(get_turf(player_landmark))

	// Spawn the combat fixer at fixer spawn point
	var/obj/effect/landmark/fixer_duel/fixer_spawn/fixer_landmark = pick(GLOB.fixer_duel_fixer_spawns)
	spawned_fixer = new duel_fixer_type(get_turf(fixer_landmark))
	spawned_fixer.faction = list("duel_enemy")
	// Prevent loot drops from duel mobs
	var/mob/living/simple_animal/hostile/humanoid/fixer/F = spawned_fixer
	if(istype(F))
		F.loot_weapon = null
		F.loot_armor = null

	// Hide the NPC
	moveToNullspace()

	// Register signals for duel end conditions
	RegisterSignal(challenger, COMSIG_MOB_STATCHANGE, PROC_REF(OnDuelistStatChange))
	RegisterSignal(challenger, COMSIG_HUMAN_INSANE, PROC_REF(OnDuelistInsane))
	RegisterSignal(spawned_fixer, COMSIG_LIVING_DEATH, PROC_REF(OnFixerDeath))

	to_chat(challenger, span_boldwarning("The duel begins! Defeat [spawned_fixer] or be defeated!"))
	return TRUE

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/OnDuelistStatChange(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat >= SOFT_CRIT)
		if(is_duo_duel)
			INVOKE_ASYNC(src, PROC_REF(EndDuoDuel), FALSE) // Player lost duo duel
		else
			INVOKE_ASYNC(src, PROC_REF(EndDuel), FALSE) // Player lost

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/OnFixerDeath(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(EndDuel), TRUE) // Player won

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/EndDuel(player_won = FALSE)
	if(!in_duel)
		return

	// Unregister signals
	if(current_duelist)
		UnregisterSignal(current_duelist, list(COMSIG_MOB_STATCHANGE, COMSIG_HUMAN_INSANE))
	if(spawned_fixer && !QDELETED(spawned_fixer))
		UnregisterSignal(spawned_fixer, COMSIG_LIVING_DEATH)
		qdel(spawned_fixer)

	// Teleport player back
	if(current_duelist && !QDELETED(current_duelist))
		if(duelist_return_turf)
			current_duelist.forceMove(duelist_return_turf)

		// Fully heal the player
		current_duelist.fully_heal(admin_revive = TRUE)

		if(player_won)
			to_chat(current_duelist, span_boldnotice("You have won the duel! [src] acknowledges your strength."))
			var/turf/reward_turf = get_turf(current_duelist)
			// Give replica gear if not already given, otherwise give 500 ahn
			if(!has_given_rewards && length(duel_rewards))
				for(var/reward_type in duel_rewards)
					new reward_type(reward_turf)
				has_given_rewards = TRUE
				to_chat(current_duelist, span_boldnotice("You received [src]'s replica gear!"))
			else
				var/obj/item/card/id/card = current_duelist.get_idcard(TRUE)
				if(card?.registered_account)
					card.registered_account.adjust_money(500)
					to_chat(current_duelist, span_boldnotice("You earned 500 ahn!"))
				else
					to_chat(current_duelist, span_boldnotice("You earned 500 ahn! (No ID card found for reward)"))
			playsound(reward_turf, 'sound/effects/cashregister.ogg', 50, TRUE)
			// Set cooldown after winning
			set_duel_cooldown(current_duelist)
			// Award achievement
			if(achievement_type && current_duelist.client)
				current_duelist.client.give_award(achievement_type, current_duelist)
				check_all_solo_achievement(current_duelist)
		else
			to_chat(current_duelist, span_boldwarning("You have been defeated. Train harder and try again."))

	// Show the NPC again
	if(npc_original_turf)
		forceMove(npc_original_turf)

	// Reset duel state
	in_duel = FALSE
	current_duelist = null
	duelist_return_turf = null
	spawned_fixer = null

// ==================== DUO DUEL SYSTEM ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/StartDuoDuel(mob/living/challenger, partner_type)
	if(!can_duo_duel)
		to_chat(challenger, span_warning("[src] cannot participate in duo duels."))
		return FALSE
	if(in_duel)
		to_chat(challenger, span_warning("[src] is already in a duel with someone else."))
		return FALSE
	if(check_duel_cooldown(challenger))
		return FALSE
	if(!length(GLOB.fixer_duel_player_spawns))
		to_chat(challenger, span_warning("There is no duel arena available."))
		return FALSE
	if(!length(GLOB.fixer_duel_fixer_spawns))
		to_chat(challenger, span_warning("There is no duel arena available."))
		return FALSE
	if(!duel_fixer_type)
		to_chat(challenger, span_warning("[src] has no combat form."))
		return FALSE
	if(!partner_type)
		to_chat(challenger, span_warning("No partner selected."))
		return FALSE

	// Set up duel state
	in_duel = TRUE
	is_duo_duel = TRUE
	current_duelist = challenger
	duelist_return_turf = get_turf(challenger)
	duo_fixers_defeated = 0
	partner_fixer_type = partner_type

	// Teleport player to duel arena
	var/obj/effect/landmark/fixer_duel/player_spawn/player_landmark = pick(GLOB.fixer_duel_player_spawns)
	challenger.forceMove(get_turf(player_landmark))

	// Spawn both combat fixers at fixer spawn point
	var/obj/effect/landmark/fixer_duel/fixer_spawn/fixer_landmark = pick(GLOB.fixer_duel_fixer_spawns)
	var/turf/fixer_turf = get_turf(fixer_landmark)

	spawned_fixer = new duel_fixer_type(fixer_turf)
	spawned_fixer.faction = list("duel_enemy")

	spawned_fixer_2 = new partner_type(fixer_turf)
	spawned_fixer_2.faction = list("duel_enemy")

	// Prevent loot drops from duel mobs
	var/mob/living/simple_animal/hostile/humanoid/fixer/F1 = spawned_fixer
	if(istype(F1))
		F1.loot_weapon = null
		F1.loot_armor = null
	var/mob/living/simple_animal/hostile/humanoid/fixer/F2 = spawned_fixer_2
	if(istype(F2))
		F2.loot_weapon = null
		F2.loot_armor = null

	// Hide the NPC
	moveToNullspace()

	// Register signals for duel end conditions
	RegisterSignal(challenger, COMSIG_MOB_STATCHANGE, PROC_REF(OnDuelistStatChange))
	RegisterSignal(challenger, COMSIG_HUMAN_INSANE, PROC_REF(OnDuelistInsane))
	RegisterSignal(spawned_fixer, COMSIG_LIVING_DEATH, PROC_REF(OnDuoFixerDeath))
	RegisterSignal(spawned_fixer_2, COMSIG_LIVING_DEATH, PROC_REF(OnDuoFixerDeath))

	to_chat(challenger, span_boldwarning("The duo duel begins! Defeat both [spawned_fixer] and [spawned_fixer_2] or be defeated!"))
	return TRUE

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/OnDuoFixerDeath(datum/source)
	SIGNAL_HANDLER
	duo_fixers_defeated++
	if(duo_fixers_defeated >= 2)
		INVOKE_ASYNC(src, PROC_REF(EndDuoDuel), TRUE) // Player won

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/OnDuelistInsane(datum/source, attribute)
	SIGNAL_HANDLER
	// End duel first (teleports back, heals)
	if(is_duo_duel)
		INVOKE_ASYNC(src, PROC_REF(EndDuoDuel), FALSE)
	else
		INVOKE_ASYNC(src, PROC_REF(EndDuel), FALSE)
	// Deal 9999 white damage to cure insanity after 1 second
	var/mob/living/L = source
	addtimer(CALLBACK(src, PROC_REF(CureInsanity), L), 1 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/CureInsanity(mob/living/target)
	var/mob/living/carbon/human/H = target
	if(!istype(H) || !H.sanity_lost)
		return
	H.deal_damage(9999, WHITE_DAMAGE)

/// Check if the player has beaten all three solo-duelable fixers
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/check_all_solo_achievement(mob/living/winner)
	if(!winner?.client)
		return
	var/client/C = winner.client
	// Check if player has all three solo achievements
	if(C.get_award_status(/datum/award/achievement/lc13/city/echo_nicholas) && \
		C.get_award_status(/datum/award/achievement/lc13/city/echo_asera) && \
		C.get_award_status(/datum/award/achievement/lc13/city/echo_remus))
		C.give_award(/datum/award/achievement/lc13/city/echo_all_solo, winner)

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/EndDuoDuel(player_won = FALSE)
	if(!in_duel)
		return

	// Unregister signals
	if(current_duelist)
		UnregisterSignal(current_duelist, list(COMSIG_MOB_STATCHANGE, COMSIG_HUMAN_INSANE))
	if(spawned_fixer && !QDELETED(spawned_fixer))
		UnregisterSignal(spawned_fixer, COMSIG_LIVING_DEATH)
		qdel(spawned_fixer)
	if(spawned_fixer_2 && !QDELETED(spawned_fixer_2))
		UnregisterSignal(spawned_fixer_2, COMSIG_LIVING_DEATH)
		qdel(spawned_fixer_2)

	// Teleport player back
	if(current_duelist && !QDELETED(current_duelist))
		if(duelist_return_turf)
			current_duelist.forceMove(duelist_return_turf)

		// Fully heal the player
		current_duelist.fully_heal(admin_revive = TRUE)

		if(player_won)
			to_chat(current_duelist, span_boldnotice("You have won the duo duel!"))
			var/turf/reward_turf = get_turf(current_duelist)

			// Give this fixer's gear if not already given
			if(!has_given_rewards && length(duel_rewards))
				for(var/reward_type in duel_rewards)
					new reward_type(reward_turf)
				has_given_rewards = TRUE
				to_chat(current_duelist, span_boldnotice("You received [src]'s replica gear!"))

			// Find partner NPC and give their gear if not already given
			var/mob/living/simple_animal/hostile/ui_npc/echo_fixer/partner = find_fixer_by_type(partner_fixer_type)
			if(partner && !partner.has_given_rewards && length(partner.duel_rewards))
				for(var/reward_type in partner.duel_rewards)
					new reward_type(reward_turf)
				partner.has_given_rewards = TRUE
				to_chat(current_duelist, span_boldnotice("You received [partner]'s replica gear!"))

			// Always give 1000 ahn for duo duels
			var/obj/item/card/id/card = current_duelist.get_idcard(TRUE)
			if(card?.registered_account)
				card.registered_account.adjust_money(1000)
				to_chat(current_duelist, span_boldnotice("You earned 1000 ahn!"))
			else
				to_chat(current_duelist, span_boldnotice("You earned 1000 ahn! (No ID card found for reward)"))
			playsound(reward_turf, 'sound/effects/cashregister.ogg', 50, TRUE)
			// Set cooldown for both fixers after winning
			set_duel_cooldown(current_duelist)
			if(partner)
				partner.set_duel_cooldown(current_duelist)
			// Award duo duel achievement
			if(current_duelist.client)
				current_duelist.client.give_award(/datum/award/achievement/lc13/city/echo_duo_win, current_duelist)
		else
			to_chat(current_duelist, span_boldwarning("You have been defeated. Train harder and try again."))

	// Show the NPC again
	if(npc_original_turf)
		forceMove(npc_original_turf)

	// Reset duel state
	in_duel = FALSE
	is_duo_duel = FALSE
	current_duelist = null
	duelist_return_turf = null
	spawned_fixer = null
	spawned_fixer_2 = null
	duo_fixers_defeated = 0
	partner_fixer_type = null

// ==================== NICHOLAS NPC ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/nicholas
	name = "Memory Forger"
	desc = "A dude covered in a full white cloak and always wears a white mask. He seems calm and speaks slowly."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "metal_fixer"
	icon_living = "metal_fixer"
	portrait = "nicholas.png"
	start_scene_id = "intro"
	duel_fixer_type = /mob/living/simple_animal/hostile/humanoid/fixer/metal
	duel_rewards = list(
		/obj/item/ego_weapon/shield/eria/replica,
		/obj/item/ego_weapon/city/echo/iria/replica,
		/obj/item/clothing/suit/armor/ego_gear/city/echo/plated/replica
	)
	achievement_type = /datum/award/achievement/lc13/city/echo_nicholas

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/nicholas/Initialize()
	. = ..()
	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "...Hm? Oh. A visitor. ...Give me a moment to gather my thoughts.",
			"actions" = list(
				"wait" = list(
					"text" = "Take your time.",
					"default_scene" = "main_screen"
				)
			)
		),
		"main_screen" = list(
			"text" = "...What would you like to know?",
			"actions" = list(
				"echo_office" = list(
					"text" = "Tell me about Echo Office.",
					"default_scene" = "echo_office"
				),
				"teammates" = list(
					"text" = "Tell me about your teammates.",
					"default_scene" = "teammates_menu"
				),
				"duel" = list(
					"text" = "I challenge you to a duel.",
					"default_scene" = "duel_offer"
				),
				"duo_duel" = list(
					"text" = "I want a Duo Duel.",
					"default_scene" = "duo_duel_menu"
				)
			)
		),
		"echo_office" = list(
			"text" = "...Echo Office. Grade 3. We specialize in outskirts work... taking contracts others refuse. The wilderness beyond the City... that is where we operate.",
			"actions" = list(
				"more" = list(
					"text" = "Tell me more.",
					"default_scene" = "echo_office_2"
				),
				"back" = list(
					"text" = "I see.",
					"default_scene" = "main_screen"
				)
			)
		),
		"echo_office_2" = list(
			"text" = "...We have found relics out there. Powerful weapons from the wilderness. My shield Eria and hammer Iria... they have served me well. Good tools for the work we do.",
			"actions" = list(
				"back" = list(
					"text" = "Interesting.",
					"default_scene" = "main_screen"
				)
			)
		),
		"teammates_menu" = list(
			"text" = "...Who do you want to know about?",
			"actions" = list(
				"lauel" = list(
					"text" = "Tell me about Lauel.",
					"default_scene" = "about_lauel"
				),
				"asera" = list(
					"text" = "Tell me about Asera.",
					"default_scene" = "about_asera"
				),
				"remus" = list(
					"text" = "Tell me about Remus.",
					"default_scene" = "about_remus"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "...Lauel. Our leader. He coordinates the team and provides support in combat. His wisps can protect and heal. A reliable person to have at your side.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "...Asera. Our mobile fighter. Fast with his spear, and he can maintain equipment in the field. Useful skills for outskirts work.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_remus" = list(
			"text" = "...Remus. Our co-leader and main combatant. Fast, aggressive, dual-wields twin blades. He handles the difficult fights.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"duel_offer" = list(
			"text" = "...A duel? ...Very well. I do not mind testing my skills. Are you prepared?",
			"actions" = list(
				"accept" = list(
					"text" = "I am ready.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel), usr)),
					"default_scene" = "duel_start"
				),
				"decline" = list(
					"text" = "Not yet.",
					"default_scene" = "duel_decline"
				)
			)
		),
		"duel_start" = list(
			"text" = "...Then let us begin.",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		),
		"duel_decline" = list(
			"text" = "...Take your time. I will be here.",
			"actions" = list(
				"back" = list(
					"text" = "Thanks.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_menu" = list(
			"text" = "...A duo duel. Who should I call?",
			"actions" = list(
				"asera" = list(
					"text" = "Fight with Asera.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Remus.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Lauel.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
					"default_scene" = "duo_duel_start"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_start" = list(
			"text" = "...Alright. We will face you together.",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		)
	))

// ==================== ASERA NPC ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/asera
	name = "Sanguine Flame"
	desc = "A fixer with vibrant energy despite seeming a bit anxious. He carries a decorated spear."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "flame_fixer"
	icon_living = "flame_fixer"
	portrait = "asera.png"
	start_scene_id = "intro"
	duel_fixer_type = /mob/living/simple_animal/hostile/humanoid/fixer/flame
	duel_rewards = list(
		/obj/item/ego_weapon/city/echo/sunstrike/replica,
		/obj/item/clothing/suit/armor/ego_gear/city/echo/faux/replica
	)
	achievement_type = /datum/award/achievement/lc13/city/echo_asera

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/asera/Initialize()
	. = ..()
	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "Oh! Hello there! I didn't see you coming. Can I help you with something?",
			"actions" = list(
				"yes" = list(
					"text" = "Yes, I have some questions.",
					"default_scene" = "main_screen"
				)
			)
		),
		"main_screen" = list(
			"text" = "Sure, what would you like to know? I'll try my best to answer!",
			"actions" = list(
				"echo_office" = list(
					"text" = "Tell me about Echo Office.",
					"default_scene" = "echo_office"
				),
				"teammates" = list(
					"text" = "Tell me about your teammates.",
					"default_scene" = "teammates_menu"
				),
				"duel" = list(
					"text" = "I challenge you to a duel.",
					"default_scene" = "duel_offer"
				),
				"duo_duel" = list(
					"text" = "I want a Duo Duel.",
					"default_scene" = "duo_duel_menu"
				)
			)
		),
		"echo_office" = list(
			"text" = "Echo Office! We're a Grade 3 office that specializes in outskirts work. It's dangerous out there, but... that's where we found our calling, you know?",
			"actions" = list(
				"more" = list(
					"text" = "Tell me more.",
					"default_scene" = "echo_office_2"
				),
				"back" = list(
					"text" = "I see.",
					"default_scene" = "main_screen"
				)
			)
		),
		"echo_office_2" = list(
			"text" = "I forged Sunstrike myself, back in my father's workshop. But the spear tip... that's a relic we found. It burns brighter the closer I get to my dreams. Pretty amazing, right?",
			"actions" = list(
				"back" = list(
					"text" = "That's impressive!",
					"default_scene" = "main_screen"
				)
			)
		),
		"teammates_menu" = list(
			"text" = "My teammates? Sure, who do you want to hear about?",
			"actions" = list(
				"lauel" = list(
					"text" = "Tell me about Lauel.",
					"default_scene" = "about_lauel"
				),
				"nicholas" = list(
					"text" = "Tell me about Nicholas.",
					"default_scene" = "about_nicholas"
				),
				"remus" = list(
					"text" = "Tell me about Remus.",
					"default_scene" = "about_remus"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "Lauel is our leader. He's really good at coordinating the team and keeping us safe with his support abilities. A calm presence in dangerous situations.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Nicholas is our tank. He uses a shield and hammer, and he can shape metal with his talent. Really solid in a fight - you want him between you and danger.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_remus" = list(
			"text" = "Remus is our other frontliner - fast and aggressive with his twin blades. Really inspiring to work with, always pushing forward!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"duel_offer" = list(
			"text" = "A duel? Oh, um... I mean, sure! I've been getting more confident lately. Let's see what you've got!",
			"actions" = list(
				"accept" = list(
					"text" = "I'm ready.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel), usr)),
					"default_scene" = "duel_start"
				),
				"decline" = list(
					"text" = "Not yet.",
					"default_scene" = "duel_decline"
				)
			)
		),
		"duel_start" = list(
			"text" = "Alright! Let's give it our all!",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		),
		"duel_decline" = list(
			"text" = "That's okay! Take your time. I'll be here when you're ready.",
			"actions" = list(
				"back" = list(
					"text" = "Thanks.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_menu" = list(
			"text" = "A duo duel? Sure! Who do you want me to fight alongside?",
			"actions" = list(
				"nicholas" = list(
					"text" = "Fight with Nicholas.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Remus.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Lauel.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
					"default_scene" = "duo_duel_start"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_start" = list(
			"text" = "This should be interesting! Let's do this!",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		)
	))

// ==================== REMUS NPC ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/remus
	name = "Amber Knight"
	desc = "A fixer with an almost too-bright smile. He radiates hopeful energy, though something seems to linger beneath."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "electic"
	icon_living = "electic"
	portrait = "remus.png"
	start_scene_id = "intro"
	duel_fixer_type = /mob/living/simple_animal/hostile/humanoid/fixer/electric
	duel_rewards = list(
		/obj/item/ego_weapon/city/echo/twins/sodom/replica,
		/obj/item/ego_weapon/city/echo/twins/gomorrah/replica,
		/obj/item/clothing/suit/armor/ego_gear/city/echo/maid_dress/replica
	)
	achievement_type = /datum/award/achievement/lc13/city/echo_remus

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/remus/Initialize()
	. = ..()
	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "Hark! A visitor doth grace our halls! Welcome, welcome! How may I be of service to thee this day?",
			"actions" = list(
				"continue" = list(
					"text" = "I have some questions.",
					"default_scene" = "main_screen"
				)
			)
		),
		"main_screen" = list(
			"text" = "But of course! What dost thou wish to know? I am an open tome!",
			"actions" = list(
				"echo_office" = list(
					"text" = "Tell me about Echo Office.",
					"default_scene" = "echo_office"
				),
				"teammates" = list(
					"text" = "Tell me about your teammates.",
					"default_scene" = "teammates_menu"
				),
				"duel" = list(
					"text" = "I challenge you to a duel.",
					"default_scene" = "duel_offer"
				),
				"duo_duel" = list(
					"text" = "I want a Duo Duel.",
					"default_scene" = "duo_duel_menu"
				)
			)
		),
		"echo_office" = list(
			"text" = "Echo Office! We art Grade 3, venturing into the outskirts where other fixers dare not tread! 'Tis dangerous, yet that is where the light shineth brightest!",
			"actions" = list(
				"more" = list(
					"text" = "Tell me more.",
					"default_scene" = "echo_office_2"
				),
				"back" = list(
					"text" = "I see.",
					"default_scene" = "main_screen"
				)
			)
		),
		"echo_office_2" = list(
			"text" = "Sodom and Gomorrah - mine twin blades! We didst find them in the outskirts. Relic weapons that groweth stronger in battle. They serve me most faithfully!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "main_screen"
				)
			)
		),
		"teammates_menu" = list(
			"text" = "Mine wonderful companions! Of whom dost thou wish to hear?",
			"actions" = list(
				"lauel" = list(
					"text" = "Tell me about Lauel.",
					"default_scene" = "about_lauel"
				),
				"nicholas" = list(
					"text" = "Tell me about Nicholas.",
					"default_scene" = "about_nicholas"
				),
				"asera" = list(
					"text" = "Tell me about Asera.",
					"default_scene" = "about_asera"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "Lauel! Our steadfast leader and protector! His wisps doth keep us shielded upon the field. Ever watching o'er the company - thou couldst not ask for finer coordination!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Nicholas! Our stalwart defender! Shield and hammer, forging metal with his talent. When peril doth arise, he standeth firm. A true bulwark!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "Asera! Our blazing spearman! Swift and fierce with Sunstrike, and he doth keep our equipment hale upon the field. He hath been faring most wonderfully of late!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"duel_offer" = list(
			"text" = "A duel?! Now that is the spirit! The stage is set, and the light doth await! Art thou ready to face the Amber Knight?",
			"actions" = list(
				"accept" = list(
					"text" = "I'm ready!",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel), usr)),
					"default_scene" = "duel_start"
				),
				"decline" = list(
					"text" = "Not yet.",
					"default_scene" = "duel_decline"
				)
			)
		),
		"duel_start" = list(
			"text" = "Excellent! Let the light guide us both! En garde!",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		),
		"duel_decline" = list(
			"text" = "'Tis quite alright! The light shall wait for thee. Return when thou art ready!",
			"actions" = list(
				"back" = list(
					"text" = "Thanks.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_menu" = list(
			"text" = "A duo duel! Most excellent! Which of mine companions shall join this grand battle?",
			"actions" = list(
				"nicholas" = list(
					"text" = "Fight with Nicholas.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"asera" = list(
					"text" = "Fight with Asera.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Lauel.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
					"default_scene" = "duo_duel_start"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_start" = list(
			"text" = "Together we shall shine! Prepare thyself!",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		)
	))

// ==================== LAUEL NPC ====================

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/lauel
	name = "Redeemed Star"
	desc = "A calm young man with white hair and a serene smile. His eyes are gentle but observant."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "priest"
	icon_living = "priest"
	portrait = "lauel.png"
	start_scene_id = "intro"
	can_duel = FALSE // Lauel is support, doesn't fight alone
	can_duo_duel = TRUE // But can participate in duo duels
	duel_fixer_type = /mob/living/simple_animal/hostile/humanoid/fixer/priest
	duel_rewards = list()

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/lauel/Initialize()
	. = ..()
	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "Ah, welcome. It's always a pleasure to meet new faces. How may I assist you today?",
			"actions" = list(
				"continue" = list(
					"text" = "I have some questions.",
					"default_scene" = "main_screen"
				)
			)
		),
		"main_screen" = list(
			"text" = "Of course. What would you like to know?",
			"actions" = list(
				"echo_office" = list(
					"text" = "Tell me about Echo Office.",
					"default_scene" = "echo_office"
				),
				"teammates" = list(
					"text" = "Tell me about your teammates.",
					"default_scene" = "teammates_menu"
				),
				"duel" = list(
					"text" = "I challenge you to a duel.",
					"default_scene" = "no_duel"
				)
			)
		),
		"echo_office" = list(
			"text" = "Echo Office is a Grade 3 office. We specialize in outskirts operations - work that other fixers consider too dangerous or too remote.",
			"actions" = list(
				"more" = list(
					"text" = "Tell me more.",
					"default_scene" = "echo_office_2"
				),
				"back" = list(
					"text" = "I see.",
					"default_scene" = "main_screen"
				)
			)
		),
		"echo_office_2" = list(
			"text" = "We started small. Myself and Remus at first, then Asera joined us for his technical expertise. Nicholas came later - a skilled fighter we found in the outskirts. Now we are a capable team.",
			"actions" = list(
				"back" = list(
					"text" = "That's beautiful.",
					"default_scene" = "main_screen"
				)
			)
		),
		"teammates_menu" = list(
			"text" = "My teammates are dear to me. Who would you like to hear about?",
			"actions" = list(
				"remus" = list(
					"text" = "Tell me about Remus.",
					"default_scene" = "about_remus"
				),
				"asera" = list(
					"text" = "Tell me about Asera.",
					"default_scene" = "about_asera"
				),
				"nicholas" = list(
					"text" = "Tell me about Nicholas.",
					"default_scene" = "about_nicholas"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_remus" = list(
			"text" = "Sire Remus is an excellent co-leader. His determination and combat prowess inspire the team. Quick with his twin blades and always pushing forward.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "Friend Asera handles our mobile combat and field maintenance. He forged his own spear, Sunstrike - the flames grow brighter as he fights. Quite reliable.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Nicholas serves as our tank. His metallurgy talent allows him to shape metal - useful for both combat and field repairs. Shield and hammer make him our frontline defender.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"no_duel" = list(
			"text" = "I appreciate the offer, but I cannot fight alone. My role has always been support. However... I could join one of my teammates if you would like a greater challenge.",
			"actions" = list(
				"duo" = list(
					"text" = "Request a Duo Duel.",
					"default_scene" = "duo_duel_menu"
				),
				"understand" = list(
					"text" = "I understand.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_menu" = list(
			"text" = "Very well. Which of my teammates would you like me to support?",
			"actions" = list(
				"nicholas" = list(
					"text" = "Fight with Nicholas.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"asera" = list(
					"text" = "Fight with Asera.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Remus.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), usr, /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
					"default_scene" = "duo_duel_start"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"duo_duel_start" = list(
			"text" = "We shall give you a proper challenge. Good luck.",
			"actions" = list(
				"go" = list(
					"text" = "Let's go!",
					"default_scene" = "main_screen"
				)
			)
		)
	))
