// Echo Office NPC Fixers
// Talkable NPCs that can be challenged to duels

/obj/item/quest_ticket/echo_office
	name = "'Echo Office' ticket"
	map = "_maps/Quests/echo_office.dmm"
	map_name = "echo_office_floor"
	ticket_name = "Echo Office"

// ==================== DUEL LANDMARKS ====================

// Each fixer has their own duel area with dedicated landmarks
// The fixer_id must match the duel_area_id on the NPC

/// Base landmark for fixer duels
/obj/effect/landmark/fixer_duel
	name = "fixer duel landmark"
	icon_state = "x2"
	/// Which fixer's duel area this belongs to (nicholas, asera, remus, lauel)
	var/fixer_id

/// Where the player is teleported to for the duel
/obj/effect/landmark/fixer_duel/player_spawn
	name = "fixer duel player spawn"

/// Where the fixer mob spawns for the duel
/obj/effect/landmark/fixer_duel/fixer_spawn
	name = "fixer duel fixer spawn"

// Nicholas duel area landmarks
/obj/effect/landmark/fixer_duel/player_spawn/nicholas
	fixer_id = "nicholas"

/obj/effect/landmark/fixer_duel/fixer_spawn/nicholas
	fixer_id = "nicholas"

// Asera duel area landmarks
/obj/effect/landmark/fixer_duel/player_spawn/asera
	fixer_id = "asera"

/obj/effect/landmark/fixer_duel/fixer_spawn/asera
	fixer_id = "asera"

// Remus duel area landmarks
/obj/effect/landmark/fixer_duel/player_spawn/remus
	fixer_id = "remus"

/obj/effect/landmark/fixer_duel/fixer_spawn/remus
	fixer_id = "remus"

// Lauel duel area landmarks
/obj/effect/landmark/fixer_duel/player_spawn/lauel
	fixer_id = "lauel"

/obj/effect/landmark/fixer_duel/fixer_spawn/lauel
	fixer_id = "lauel"

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
	/// Cooldown time after winning a duel (5 minutes)
	var/duel_win_cooldown = 5 MINUTES
	/// List of player ckeys and when their cooldown expires
	var/list/duel_cooldowns = list()
	/// Achievement type to award when beaten in solo duel
	var/achievement_type
	/// The duel area ID for this fixer (must match landmark fixer_id)
	var/duel_area_id
	/// Reference to the partner NPC during duo duels (to show/hide them)
	var/mob/living/simple_animal/hostile/ui_npc/echo_fixer/partner_npc
	/// The scene manager variable name to set when beaten (e.g., "beaten_nicholas")
	var/beaten_var_name

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/Initialize()
	. = ..()
	npc_original_turf = get_turf(src)

/// Find this fixer's player spawn landmark
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/get_player_spawn_landmark()
	for(var/obj/effect/landmark/fixer_duel/player_spawn/L in GLOB.landmarks_list)
		if(L.fixer_id == duel_area_id)
			return L
	return null

/// Find this fixer's fixer spawn landmark
/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/get_fixer_spawn_landmark()
	for(var/obj/effect/landmark/fixer_duel/fixer_spawn/L in GLOB.landmarks_list)
		if(L.fixer_id == duel_area_id)
			return L
	return null

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

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/StartDuel()
	var/mob/living/challenger = usr
	if(!isliving(challenger))
		return FALSE
	if(!can_duel)
		to_chat(challenger, span_warning("[src] cannot be challenged to a duel."))
		return FALSE
	if(in_duel)
		to_chat(challenger, span_warning("[src] is already in a duel with someone else."))
		return FALSE
	if(check_duel_cooldown(challenger))
		return FALSE
	if(!duel_fixer_type)
		to_chat(challenger, span_warning("[src] has no combat form."))
		return FALSE

	// Find this fixer's specific duel landmarks
	var/obj/effect/landmark/fixer_duel/player_spawn/player_landmark = get_player_spawn_landmark()
	var/obj/effect/landmark/fixer_duel/fixer_spawn/fixer_landmark = get_fixer_spawn_landmark()
	if(!player_landmark || !fixer_landmark)
		to_chat(challenger, span_warning("There is no duel arena available for [src]."))
		return FALSE

	// Set up duel state
	in_duel = TRUE
	current_duelist = challenger
	duelist_return_turf = get_turf(challenger)

	// Teleport player to this fixer's duel arena
	challenger.forceMove(get_turf(player_landmark))

	// Spawn the combat fixer at this fixer's spawn point
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

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/EndDuel(player_won = FALSE, skip_heal = FALSE)
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

		// Fully heal the player (unless skipped for insanity handling)
		if(!skip_heal)
			current_duelist.fully_heal(admin_revive = TRUE)

		// Remove overheat stacks
		current_duelist.remove_status_effect(/datum/status_effect/stacking/lc_overheat)

		if(player_won)
			to_chat(current_duelist, span_boldnotice("You have won the duel! [src] acknowledges your strength."))
			// Increment win counter for background dialogue unlocks
			if(beaten_var_name)
				var/current_wins = scene_manager.get_var(current_duelist, "player.[beaten_var_name]") || 0
				scene_manager.set_var(current_duelist, "player.[beaten_var_name]", current_wins + 1)
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

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/StartDuoDuel(partner_type)
	var/mob/living/challenger = usr
	if(!isliving(challenger))
		return FALSE
	if(!can_duo_duel)
		to_chat(challenger, span_warning("[src] cannot participate in duo duels."))
		return FALSE
	if(in_duel)
		to_chat(challenger, span_warning("[src] is already in a duel with someone else."))
		return FALSE
	if(check_duel_cooldown(challenger))
		return FALSE
	if(!duel_fixer_type)
		to_chat(challenger, span_warning("[src] has no combat form."))
		return FALSE
	if(!partner_type)
		to_chat(challenger, span_warning("No partner selected."))
		return FALSE

	// Find the partner NPC and check if they're available
	var/mob/living/simple_animal/hostile/ui_npc/echo_fixer/partner = find_fixer_by_type(partner_type)
	if(!partner)
		to_chat(challenger, span_warning("Could not find the partner fixer."))
		return FALSE
	if(partner.in_duel)
		to_chat(challenger, span_warning("[partner] is currently in a duel with someone else. Please choose a different partner."))
		return FALSE

	// Find this fixer's specific duel landmarks
	var/obj/effect/landmark/fixer_duel/player_spawn/player_landmark = get_player_spawn_landmark()
	var/obj/effect/landmark/fixer_duel/fixer_spawn/fixer_landmark = get_fixer_spawn_landmark()
	if(!player_landmark || !fixer_landmark)
		to_chat(challenger, span_warning("There is no duel arena available for [src]."))
		return FALSE

	// Set up duel state
	in_duel = TRUE
	is_duo_duel = TRUE
	current_duelist = challenger
	duelist_return_turf = get_turf(challenger)
	duo_fixers_defeated = 0
	partner_fixer_type = partner_type
	partner_npc = partner

	// Mark partner as also being in a duel (so they can't be selected by others)
	partner.in_duel = TRUE

	// Teleport player to this fixer's duel arena
	challenger.forceMove(get_turf(player_landmark))

	// Spawn both combat fixers at this fixer's spawn point
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

	// Hide both NPCs
	moveToNullspace()
	partner.moveToNullspace()

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
	// End duel first (teleports back, but don't heal yet)
	if(is_duo_duel)
		INVOKE_ASYNC(src, PROC_REF(EndDuoDuel), FALSE, TRUE) // skip_heal = TRUE
	else
		INVOKE_ASYNC(src, PROC_REF(EndDuel), FALSE, TRUE) // skip_heal = TRUE
	// Deal 9999 white damage to cure insanity after 1 second
	var/mob/living/L = source
	addtimer(CALLBACK(src, PROC_REF(CureInsanity), L), 1 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/CureInsanity(mob/living/target)
	var/mob/living/carbon/human/H = target
	if(!istype(H) || !H.sanity_lost)
		return
	H.adjustWhiteLoss(9999, updating_health = TRUE, forced = TRUE, white_healable = TRUE)

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

/mob/living/simple_animal/hostile/ui_npc/echo_fixer/proc/EndDuoDuel(player_won = FALSE, skip_heal = FALSE)
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

		// Fully heal the player (unless skipped for insanity handling)
		if(!skip_heal)
			current_duelist.fully_heal(admin_revive = TRUE)

		// Remove overheat stacks
		current_duelist.remove_status_effect(/datum/status_effect/stacking/lc_overheat)

		if(player_won)
			to_chat(current_duelist, span_boldnotice("You have won the duo duel!"))
			// Increment win counters for both fixers
			if(beaten_var_name)
				var/current_wins = scene_manager.get_var(current_duelist, "player.[beaten_var_name]") || 0
				scene_manager.set_var(current_duelist, "player.[beaten_var_name]", current_wins + 1)
			if(partner_npc?.beaten_var_name)
				var/partner_wins = partner_npc.scene_manager.get_var(current_duelist, "player.[partner_npc.beaten_var_name]") || 0
				partner_npc.scene_manager.set_var(current_duelist, "player.[partner_npc.beaten_var_name]", partner_wins + 1)
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

	// Show both NPCs again
	if(npc_original_turf)
		forceMove(npc_original_turf)
	if(partner_npc)
		partner_npc.in_duel = FALSE
		if(partner_npc.npc_original_turf)
			partner_npc.forceMove(partner_npc.npc_original_turf)

	// Reset duel state
	in_duel = FALSE
	is_duo_duel = FALSE
	current_duelist = null
	duelist_return_turf = null
	spawned_fixer = null
	spawned_fixer_2 = null
	duo_fixers_defeated = 0
	partner_fixer_type = null
	partner_npc = null

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
	duel_area_id = "nicholas"
	beaten_var_name = "beaten_nicholas"
	random_emotes = "adjusts his mask slightly;stares into the distance;taps his shield thoughtfully;shifts his weight slowly;tilts his head in contemplation"

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
				"background" = list(
					"text" = "I'd like to know more about you.",
					"enabled_expression" = "player.beaten_nicholas >= 1",
					"default_scene" = "background_menu"
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
					"text" = "Tell me about Redeemed Star.",
					"default_scene" = "about_lauel"
				),
				"asera" = list(
					"text" = "Tell me about Sanguine Flame.",
					"default_scene" = "about_asera"
				),
				"remus" = list(
					"text" = "Tell me about Amber Knight.",
					"default_scene" = "about_remus"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "...Redeemed Star. Our leader. He coordinates the team and provides support in combat. His wisps can protect and heal. A reliable person to have at your side.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "...Sanguine Flame. Our mobile fighter. Fast with his spear, and he can maintain equipment in the field. Useful skills for outskirts work.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_remus" = list(
			"text" = "...Amber Knight. Our co-leader and main combatant. Fast, aggressive, dual-wields twin blades. He handles the difficult fights.",
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
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel))),
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
					"text" = "Fight with Sanguine Flame.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Amber Knight.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Redeemed Star.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
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
		),
		"background_menu" = list(
			"text" = "...You wish to know more? Very well. I do not mind sharing.",
			"actions" = list(
				"weapons" = list(
					"text" = "Tell me about your weapons.",
					"default_scene" = "about_weapons"
				),
				"joining" = list(
					"text" = "How did you join Echo Office?",
					"default_scene" = "about_joining"
				),
				"statues" = list(
					"text" = "Why do you forge statues?",
					"enabled_expression" = "player.beaten_nicholas >= 2",
					"default_scene" = "about_statues"
				),
				"teammates" = list(
					"text" = "What do you think of your teammates?",
					"enabled_expression" = "player.beaten_nicholas >= 2",
					"default_scene" = "about_teammates"
				),
				"glimpses" = list(
					"text" = "You mentioned fragments in dreams. What do you see?",
					"enabled_expression" = "player.beaten_nicholas >= 3",
					"default_scene" = "about_glimpses"
				),
				"remembering" = list(
					"text" = "You were taught not to dwell on the past. Do you want to remember?",
					"enabled_expression" = "player.beaten_nicholas >= 3",
					"default_scene" = "about_remembering"
				),
				"back" = list(
					"text" = "That's all for now.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_weapons" = list(
			"text" = "...Eria and Iria. My shield and hammer. We found them in the outskirts. Strange thing is... they feel familiar. As if I've used them before.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_joining" = list(
			"text" = "...I do not remember much from before. The others found me after a battle in the outskirts. I was... forging something. A statue. I still do not know why. Lauel offered me a place. I followed. ...I was taught that dwelling on the past serves no purpose. But sometimes I wonder.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_statues" = list(
			"text" = "...The statues. When I use my talent to shape metal... memories fade. So I try to forge them into something solid before they disappear. Faces. Places. Feelings I cannot name. Sometimes... fragments surface. In dreams. Gone by morning, but... they were there.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_teammates" = list(
			"text" = "...They are good people. Lauel sees things others miss - he noticed me sitting in the wreckage and offered purpose instead of pity. Remus has more energy than I can comprehend, but his heart is genuine. Asera keeps our equipment running and rarely complains. ...They did not have to take me in. But they did.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_glimpses" = list(
			"text" = "...Sometimes, when I forge... faces appear in the metal. I do not know who they are. But my hands remember the shapes. Eria and Iria felt familiar from the moment I held them. Like meeting old friends I had forgotten. ...Fragments surface in dreams. They fade upon waking. But they were there.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_remembering" = list(
			"text" = "...Do I want to remember? I was taught that memories are burdens. That spending them freely was... efficient. Part of me still believes that. But now, when I prepare to forge... I hesitate. Some faces feel worth the pain of keeping. I cannot explain it. Perhaps that is the answer.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
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
	duel_area_id = "asera"
	beaten_var_name = "beaten_asera"
	random_emotes = "polishes his spear tip;bounces slightly on his heels;glances around nervously;adjusts his grip on Sunstrike;takes a deep breath"

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
				"background" = list(
					"text" = "I'd like to know more about you.",
					"enabled_expression" = "player.beaten_asera >= 1",
					"default_scene" = "background_menu"
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
					"text" = "Tell me about Redeemed Star.",
					"default_scene" = "about_lauel"
				),
				"nicholas" = list(
					"text" = "Tell me about Memory Forger.",
					"default_scene" = "about_nicholas"
				),
				"remus" = list(
					"text" = "Tell me about Amber Knight.",
					"default_scene" = "about_remus"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "Redeemed Star is our leader. He's really good at coordinating the team and keeping us safe with his support abilities. A calm presence in dangerous situations.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Memory Forger is our tank. He uses a shield and hammer, and he can shape metal with his talent. Really solid in a fight - you want him between you and danger.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_remus" = list(
			"text" = "Amber Knight is our other frontliner - fast and aggressive with his twin blades. Really inspiring to work with, always pushing forward!",
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
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel))),
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
					"text" = "Fight with Memory Forger.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Amber Knight.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Redeemed Star.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
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
		),
		"background_menu" = list(
			"text" = "Oh, you want to know more about me? That's... actually really nice. What would you like to know?",
			"actions" = list(
				"sunstrike" = list(
					"text" = "Tell me about Sunstrike.",
					"default_scene" = "about_sunstrike"
				),
				"past" = list(
					"text" = "What did you do before becoming a fixer?",
					"default_scene" = "about_past"
				),
				"feelings" = list(
					"text" = "How are you feeling these days?",
					"enabled_expression" = "player.beaten_asera >= 2",
					"default_scene" = "about_feelings"
				),
				"teammates" = list(
					"text" = "What do you think of your teammates?",
					"enabled_expression" = "player.beaten_asera >= 2",
					"default_scene" = "about_teammates"
				),
				"dreams" = list(
					"text" = "Sunstrike burns brighter with your dreams. What are those dreams?",
					"enabled_expression" = "player.beaten_asera >= 3",
					"default_scene" = "about_dreams"
				),
				"father" = list(
					"text" = "You mentioned wanting to visit your father. Do you keep in touch?",
					"enabled_expression" = "player.beaten_asera >= 3",
					"default_scene" = "about_father"
				),
				"back" = list(
					"text" = "That's all for now.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_sunstrike" = list(
			"text" = "Sunstrike! I forged the shaft myself, back in my father's workshop. But the tip... we found that in the outskirts. A relic. It burns hotter the more I fight for what I believe in. The closer I get to my dreams, the brighter it burns. Pretty cool, right?",
			"actions" = list(
				"back" = list(
					"text" = "That's amazing!",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_past" = list(
			"text" = "My father owned a workshop. I learned a lot from him, but... I wanted to be out there, you know? Making a difference as a fixer. It wasn't easy at first. A lot of offices turned me down. But Lauel saw something in me. Gave me a chance when no one else would.",
			"actions" = list(
				"back" = list(
					"text" = "I'm glad things worked out.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_feelings" = list(
			"text" = "Honestly? I think I'm doing better than I have in a while. Still nervous sometimes, but... I'm starting to believe I belong here. That I'm actually contributing something valuable. It's a nice feeling. I'm trying not to overthink it. ...I should visit my father soon. Tell him how things are going.",
			"actions" = list(
				"back" = list(
					"text" = "I'm glad to hear that.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_teammates" = list(
			"text" = "Remus is... a lot, sometimes. All that energy and optimism - part of me wonders how he keeps it up. But watching him charge into danger makes me want to be braver too. Lauel notices everything - it's a little scary, but also comforting? Like someone's watching out for you. And Nicholas is quieter, but he's found his place with us. We all have, I think.",
			"actions" = list(
				"back" = list(
					"text" = "Sounds like a good team.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_dreams" = list(
			"text" = "My dreams? I want to prove I belong here. That choosing to be a fixer wasn't just... running away from my father's workshop. I want to be someone others can rely on. Not just the guy who fixes gear in the back. And... I want to make my father proud. Even though I left.",
			"actions" = list(
				"back" = list(
					"text" = "Those are good dreams.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_father" = list(
			"text" = "Yeah, I visit when I can. He doesn't blame me for leaving - he never did. He just wanted me to be happy. I think... I think he's proud of how far I've come. He still worries, of course. But I hope someday I can bring him good news instead of just 'I'm still alive.'",
			"actions" = list(
				"back" = list(
					"text" = "He sounds like a good father.",
					"default_scene" = "background_menu"
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
	duel_area_id = "remus"
	beaten_var_name = "beaten_remus"
	random_emotes = "flourishes his twin blades dramatically;strikes a heroic pose;gazes dramatically toward the horizon;adjusts his stance with theatrical flair;nods approvingly to himself"

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
				"background" = list(
					"text" = "I'd like to know more about you.",
					"enabled_expression" = "player.beaten_remus >= 1",
					"default_scene" = "background_menu"
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
					"text" = "Tell me about Redeemed Star.",
					"default_scene" = "about_lauel"
				),
				"nicholas" = list(
					"text" = "Tell me about Memory Forger.",
					"default_scene" = "about_nicholas"
				),
				"asera" = list(
					"text" = "Tell me about Sanguine Flame.",
					"default_scene" = "about_asera"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_lauel" = list(
			"text" = "Redeemed Star! Our steadfast leader and protector! His wisps doth keep us shielded upon the field. Ever watching o'er the company - thou couldst not ask for finer coordination!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Memory Forger! Our stalwart defender! Shield and hammer, forging metal with his talent. When peril doth arise, he standeth firm. A true bulwark!",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "Sanguine Flame! Our blazing spearman! Swift and fierce with Sunstrike, and he doth keep our equipment hale upon the field. He hath been faring most wonderfully of late!",
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
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel))),
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
					"text" = "Fight with Memory Forger.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"asera" = list(
					"text" = "Fight with Sanguine Flame.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"lauel" = list(
					"text" = "Fight with Redeemed Star.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/priest)),
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
		),
		"background_menu" = list(
			"text" = "Thou wishest to know more of thy humble knight? I am honored! What dost thou seek to learn?",
			"actions" = list(
				"blades" = list(
					"text" = "Tell me about Sodom and Gomorrah.",
					"default_scene" = "about_blades"
				),
				"speech" = list(
					"text" = "Why do you speak so... theatrically?",
					"default_scene" = "about_speech"
				),
				"drive" = list(
					"text" = "What drives you forward?",
					"enabled_expression" = "player.beaten_remus >= 2",
					"default_scene" = "about_drive"
				),
				"teammates" = list(
					"text" = "What do you think of your teammates?",
					"enabled_expression" = "player.beaten_remus >= 2",
					"default_scene" = "about_teammates"
				),
				"aestus" = list(
					"text" = "You mentioned Aestus, your old office. What happened to them?",
					"enabled_expression" = "player.beaten_remus >= 3",
					"default_scene" = "about_aestus"
				),
				"darkness" = list(
					"text" = "You speak of reaching for light. What happens when you can't see it?",
					"enabled_expression" = "player.beaten_remus >= 3",
					"default_scene" = "about_darkness"
				),
				"back" = list(
					"text" = "That's all for now.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_blades" = list(
			"text" = "Sodom and Gomorrah! Mine twin blades! We discovered them in the outskirts, within an ancient ruin. They were... warm to the touch. Not hot, just... warm. Like a hearth. Like home. They resonate with something within me - a loss I carry. I know not fully what, but we fight as one.",
			"actions" = list(
				"back" = list(
					"text" = "Interesting.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_speech" = list(
			"text" = "Haha! Thou art not the first to ask! I speak this way because... it brings light to dark places, dost it not? When things are grim, when the path is unclear... a little theatrics maketh everything feel more heroic. More hopeful. And hope... hope is something thou must carry with thee, always.",
			"actions" = list(
				"back" = list(
					"text" = "That's a good way to look at it.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_drive" = list(
			"text" = "What keepeth me moving? Hm. 'Tis a belief, I suppose. That even when all seemeth dark, the light remaineth. I learned that from my old office... Aestus. They taught me to keep reaching. Stop reaching, and thou wilt never grasp it. So I choose to reach. Every single day. For them.",
			"actions" = list(
				"back" = list(
					"text" = "That's inspiring.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_teammates" = list(
			"text" = "Mine companions art precious to me! Lauel holdeth us together with quiet strength - I worry sometimes that he careth for everyone except himself. Asera hath grown much since we met - I am proud of him, truly! And Nicholas... he lost much before we found him. I cannot restore what was taken, but I can ensure he never faceth such loss alone again.",
			"actions" = list(
				"back" = list(
					"text" = "You're a good friend to them.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_aestus" = list(
			"text" = "...Aestus Office. They were small. Grade 8. But they had heart. They believed the City could be better. They became my family after my first one crumbled. I was not there when it happened. I was recovering from an injury. In another district. When I returned... there was nothing left.",
			"actions" = list(
				"back" = list(
					"text" = "I'm sorry.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_darkness" = list(
			"text" = "Some nights... the grey creeps in. The knowledge that 300,000 people are gone. That my family - both of them - are gone. And I survived. But morning comes. And Lauel smiles. And Asera fusses over equipment. And Nicholas forges his statues. So I keep reaching. Because they need me to.",
			"actions" = list(
				"back" = list(
					"text" = "They're lucky to have you.",
					"default_scene" = "background_menu"
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
	duel_area_id = "lauel"
	beaten_var_name = "beaten_lauel"
	random_emotes = "closes his eyes peacefully;clasps his hands gently;takes a slow, calming breath;watches over the area serenely;smiles softly"

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
				"background" = list(
					"text" = "I'd like to know more about you.",
					"enabled_expression" = "player.beaten_lauel >= 1",
					"default_scene" = "background_menu"
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
			"text" = "We started small. Myself and Amber Knight at first, then Sanguine Flame joined us for his technical expertise. Memory Forger came later - a skilled fighter we found in the outskirts. Now we are a capable team.",
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
					"text" = "Tell me about Amber Knight.",
					"default_scene" = "about_remus"
				),
				"asera" = list(
					"text" = "Tell me about Sanguine Flame.",
					"default_scene" = "about_asera"
				),
				"nicholas" = list(
					"text" = "Tell me about Memory Forger.",
					"default_scene" = "about_nicholas"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_remus" = list(
			"text" = "Sire Amber Knight is an excellent co-leader. His determination and combat prowess inspire the team. Quick with his twin blades and always pushing forward.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_asera" = list(
			"text" = "Friend Sanguine Flame handles our mobile combat and field maintenance. He forged his own spear, Sunstrike - the flames grow brighter as he fights. Quite reliable.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "teammates_menu"
				)
			)
		),
		"about_nicholas" = list(
			"text" = "Memory Forger serves as our tank. His metallurgy talent allows him to shape metal - useful for both combat and field repairs. Shield and hammer make him our frontline defender.",
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
					"text" = "Fight with Memory Forger.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/metal)),
					"default_scene" = "duo_duel_start"
				),
				"asera" = list(
					"text" = "Fight with Sanguine Flame.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/flame)),
					"default_scene" = "duo_duel_start"
				),
				"remus" = list(
					"text" = "Fight with Amber Knight.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuoDuel), /mob/living/simple_animal/hostile/humanoid/fixer/electric)),
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
		),
		"background_menu" = list(
			"text" = "You'd like to know more about me? I appreciate your curiosity. What would you like to ask?",
			"actions" = list(
				"wisps" = list(
					"text" = "Tell me about your wisps.",
					"default_scene" = "about_wisps"
				),
				"founding" = list(
					"text" = "How did you start Echo Office?",
					"default_scene" = "about_founding"
				),
				"smile" = list(
					"text" = "You always seem so calm. Is that real?",
					"enabled_expression" = "player.beaten_lauel >= 2",
					"default_scene" = "about_smile"
				),
				"teammates" = list(
					"text" = "What do you think of your teammates?",
					"enabled_expression" = "player.beaten_lauel >= 2",
					"default_scene" = "about_teammates"
				),
				"redeemed" = list(
					"text" = "The Church of Gears gave you that relic. Why do they call you 'Redeemed'?",
					"enabled_expression" = "player.beaten_lauel >= 3",
					"default_scene" = "about_redeemed"
				),
				"mask" = list(
					"text" = "You said other emotions are distractions. Have you always felt that way?",
					"enabled_expression" = "player.beaten_lauel >= 3",
					"default_scene" = "about_mask"
				),
				"back" = list(
					"text" = "That's all for now.",
					"default_scene" = "main_screen"
				)
			)
		),
		"about_wisps" = list(
			"text" = "My wisps? They come from a family relic. An heirloom from the Church of Gears... my family's faith. The Church granted me this tool to complete a mission. The wisps allow me to protect others, to support my teammates in battle. I find purpose in that - in keeping people safe.",
			"actions" = list(
				"back" = list(
					"text" = "That's admirable.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_founding" = list(
			"text" = "Echo Office began small. I met Remus first - he was... searching for something. Then Asera joined us. And finally Nicholas, whom we found in the outskirts. We were all looking for something, I suppose. A place to belong. Purpose. We found it in each other.",
			"actions" = list(
				"back" = list(
					"text" = "That's beautiful.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_smile" = list(
			"text" = "Ah... you're perceptive. Yes, the composure is genuine. This is who I am. I learned early that other emotions - fear, anger, doubt - are distractions. They cloud judgment and impede progress. The smile remained because it serves a purpose. It comforts others, facilitates cooperation, maintains focus. Why would I want anything else?",
			"actions" = list(
				"back" = list(
					"text" = "Thank you for sharing that.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_teammates" = list(
			"text" = "They each carry weight they don't speak of. Remus smiles so brightly because the alternative frightens him - I wish he knew it's safe to rest sometimes. Asera doubts himself more than he should - he has grown so much, if only he could see it. And Nicholas... he processes things differently, but he understands people better than he lets on. I am fortunate to work alongside all of them.",
			"actions" = list(
				"back" = list(
					"text" = "You care about them a lot.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_redeemed" = list(
			"text" = "My family was... disgraced. In the eyes of the Church. When my parent failed to become a gear, we were marked as tainted. The Church gave me a choice: be cast out, or prove my worth. The mission was meant to kill me. Collect relics from the outskirts. They expected me to die out there. 'Redeemed' is what they will call me when the debt is finally paid.",
			"actions" = list(
				"back" = list(
					"text" = "That's a heavy burden.",
					"default_scene" = "background_menu"
				)
			)
		),
		"about_mask" = list(
			"text" = "Always? No. The Church taught me. When my family was disgraced, I learned that weakness invites punishment. Doubt invites failure. The smile is efficient. It protects me and serves others. Everything else is... noise. Sometimes Echo Office makes me feel things I cannot immediately categorize. But that is simply data to be processed, not indulged.",
			"actions" = list(
				"back" = list(
					"text" = "I see.",
					"default_scene" = "background_menu"
				)
			)
		)
	))
