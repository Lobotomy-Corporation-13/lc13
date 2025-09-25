
// realm of sealed regrets SYSTEM
// A standalone system for trapping players in an alternate dimension of regret and repentance
// Can be used by any game mechanic without requiring specific abnormalities

GLOBAL_LIST_EMPTY(repentance_trapped_players)         // List of all trapped players
GLOBAL_LIST_EMPTY(repentance_return_locations)        // Original locations to return players to
GLOBAL_LIST_EMPTY(repentance_status_effects)          // Status effects applied to trapped players
GLOBAL_LIST_EMPTY(repentance_spawn_points)            // Valid spawn locations in the dimension

/// Initializes repentance dimension spawn locations from landmarks
/proc/InitializeRepentanceLocations()
	GLOB.repentance_spawn_points = list()
	for(var/obj/effect/landmark/repentance_spawn/L in GLOB.landmarks_list)
		GLOB.repentance_spawn_points += get_turf(L)

	// Fallback if no landmarks exist - use z-level 1,1,1
	if(!LAZYLEN(GLOB.repentance_spawn_points))
		var/turf/T = locate(1, 1, 1)
		if(T)
			GLOB.repentance_spawn_points += T

/// Sends a player to the realm of sealed regrets
/// H - The human to send
/// send_message - Optional custom message to display (null = use default)
/// spin_effect - Whether to apply violent spinning effect
/// Returns TRUE if successful
/proc/SendToRepentanceDimension(mob/living/carbon/human/H, send_message = null, spin_effect = TRUE)
	if(!H || QDELETED(H))
		return FALSE

	// Already trapped check
	if(H in GLOB.repentance_trapped_players)
		return FALSE

	// Initialize spawn points if needed
	if(!LAZYLEN(GLOB.repentance_spawn_points))
		InitializeRepentanceLocations()

	// Add to global tracking
	GLOB.repentance_trapped_players += H
	GLOB.repentance_return_locations[H] = get_turf(H)

	// Display message
	if(send_message)
		to_chat(H, span_userdanger(send_message))
	else
		to_chat(H, span_userdanger("You are pulled into a strange dimension!"))

	// Apply spinning effect if requested
	if(spin_effect)
		playsound(get_turf(H), 'sound/abnormalities/dinner_chair/ragdoll_effect.ogg', 75, TRUE)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(RepentanceViolentSpin), H)
		// Wait for spinning to finish before teleporting
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(RepentanceFinishTeleport), H), 12 SECONDS)
	else
		RepentanceFinishTeleport(H)

	return TRUE

/// Violent spinning effect for dimension transport
/proc/RepentanceViolentSpin(mob/living/M)
	if(!M || QDELETED(M))
		return

	var/matrix/initial_matrix = matrix(M.transform)
	for(var/i in 1 to 120) // 12 seconds at 0.1 second intervals
		if(!M || QDELETED(M))
			return

		// Violent rotation
		initial_matrix = matrix(M.transform)
		initial_matrix.Turn(rand(45, 180))

		// Extreme position changes
		var/x_shift = rand(-10, 10)
		var/y_shift = rand(-10, 10)
		initial_matrix.Translate(x_shift, y_shift)

		animate(M, transform = initial_matrix, time = 1, loop = 0, easing = pick(LINEAR_EASING, SINE_EASING, CIRCULAR_EASING))

		// Rapid direction changes
		M.setDir(pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

		sleep(1)

	// Reset transformation
	animate(M, transform = null, time = 5, loop = 0)

/// Completes the teleportation to realm of sealed regrets
/proc/RepentanceFinishTeleport(mob/living/carbon/human/H)
	if(!H || QDELETED(H) || !(H in GLOB.repentance_trapped_players))
		return

	to_chat(H, span_warning("You find yourself in the realm of sealed regrets."))
	to_chat(H, span_warning("The air is heavy with regret and the weight of unspoken apologies."))

	playsound(get_turf(H), 'sound/effects/podwoosh.ogg', 50, TRUE)

	// Pick a random repentance dimension location
	var/turf/destination
	if(LAZYLEN(GLOB.repentance_spawn_points))
		destination = pick(GLOB.repentance_spawn_points)
	else
		destination = locate(1, 1, 1) // Emergency fallback

	if(destination)
		H.forceMove(destination)

	H.Stun(30)
	H.adjustSanityLoss(20)

	// Spawn an empty tape recorder for them to record their regrets
	var/obj/item/taperecorder/empty/recorder = new /obj/item/taperecorder/empty(destination)
	to_chat(H, span_notice("A tape recorder materializes before you, as if the dimension itself wants to hear your confession..."))

	// Try to put it in their hand if possible
	if(!H.put_in_hands(recorder))
		// If hands are full, place it next to them
		recorder.forceMove(get_step(destination, pick(NORTH, SOUTH, EAST, WEST)))

	// Apply repentance dimension status effect
	var/datum/status_effect/repentance_ambience/B = H.apply_status_effect(/datum/status_effect/repentance_ambience)
	if(B)
		GLOB.repentance_status_effects[H] = B

/// Rescues a player from the realm of sealed regrets
/// H - The human to rescue
/// return_turf - Optional specific return location (null = use saved location)
/// rescue_message - Optional custom message (null = use default)
/// Returns TRUE if successful
/proc/RescueFromRepentanceDimension(mob/living/carbon/human/H, turf/return_turf = null, rescue_message = null)
	if(!H || QDELETED(H))
		return FALSE

	// Not trapped check
	if(!(H in GLOB.repentance_trapped_players))
		return FALSE

	// Remove from global tracking
	GLOB.repentance_trapped_players -= H

	// Determine return location
	if(!return_turf)
		return_turf = GLOB.repentance_return_locations[H]
	if(!return_turf)
		// Find a safe station turf as fallback
		for(var/turf/T in GLOB.station_turfs)
			if(!T.density)
				return_turf = T
				break
	if(!return_turf)
		return_turf = locate(1, 1, 1) // Ultimate fallback

	GLOB.repentance_return_locations -= H

	// Remove status effect
	if(GLOB.repentance_status_effects[H])
		H.remove_status_effect(/datum/status_effect/repentance_ambience)
		GLOB.repentance_status_effects -= H

	// Display message
	if(rescue_message)
		to_chat(H, span_nicegreen(rescue_message))
	else
		to_chat(H, span_nicegreen("You feel a pull back to reality!"))

	playsound(get_turf(H), 'sound/magic/teleport_app.ogg', 50, TRUE)

	// Teleport back
	H.forceMove(return_turf)

	return TRUE

/// Checks if a player is trapped in the realm of sealed regrets
/proc/IsTrappedInRepentance(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	return (H in GLOB.repentance_trapped_players)

/// Returns a list of all trapped players
/proc/GetRepentanceTrappedList()
	return GLOB.repentance_trapped_players.Copy()

/// Rescues all trapped players (for emergency use)
/proc/RescueAllFromRepentance(rescue_message = "The dimension collapses, ejecting everyone!")
	for(var/mob/living/carbon/human/H in GLOB.repentance_trapped_players.Copy())
		RescueFromRepentanceDimension(H, null, rescue_message)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere
	name = "Door to Nowhere"
	desc = "A door wrapped in chains, floating ominously in the air. Behind it lies memories best left forgotten, regrets that should remain sealed."
	icon = 'ModularLobotomy/_Lobotomyicons/chain_door.dmi'
	icon_state = "chained_door"
	icon_living = "chained_door"
	icon_dead = "chained_door"
	maxHealth = 400
	health = 400
	threat_level = TETH_LEVEL
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "crashes into"
	attack_verb_simple = "crash into"
	attack_sound = 'sound/weapons/genhit1.ogg'
	can_breach = FALSE
	start_qliphoth = 3

	// Ranged attack configuration
	ranged = TRUE
	ranged_cooldown_time = 50  // 5 seconds between shots
	projectiletype = /obj/projectile/regret_hand
	projectilesound = 'sound/effects/curse3.ogg'
	retreat_distance = 3
	minimum_distance = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_INSIGHT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_ATTACHMENT = list(30, 30, 25, 25, 25),
		ABNORMALITY_WORK_REPRESSION = list(10, 10, 5, 0, 0),
	)
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/liminal,
		/datum/ego_datum/armor/liminal,
	)
	gift_type = /datum/ego_gifts/liminal
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "The chained door hovers before you, its surface scarred and weathered. You feel drawn to examine it closer..."
	observation_choices = list(
		"The chains seem to pulse with regret" = list(TRUE, "You notice the chains tighten rhythmically, as if trying to keep something locked away. Behind the door, you hear faint echoes of forgotten memories."),
		"It's just a locked door" = list(FALSE, "You turn away from the door. Some things are meant to stay locked."),
	)

	// Use global repentance dimension system - no local tracking needed

	// Spirit projection ability variable
	var/projecting_spirit = FALSE

	// Track who has received their first tape recorder
	var/list/workers_with_recorders = list()

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Initialize()
	. = ..()
	// Grant abilities
	var/datum/action/innate/targeted_whisper/whisper_ability = new
	whisper_ability.Grant(src)

	var/datum/action/innate/door_possession/possess_ability = new
	possess_ability.Grant(src)

	// Initialize global repentance dimension locations
	InitializeRepentanceLocations()

	// Register for insanity events
	RegisterSignal(SSdcs, COMSIG_GLOB_HUMAN_INSANE, PROC_REF(on_human_insane))

// Handle human insanity - decrease Qliphoth counter
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/on_human_insane(datum/source, mob/living/carbon/human/H, turf/T)
	SIGNAL_HANDLER

	// Only react to insanity on our Z-level
	if(!H || H.z != z)
		return

	// Decrease Qliphoth counter
	if(datum_reference)
		datum_reference.qliphoth_change(-1)
		visible_message(span_warning("[src]'s chains rattle ominously as madness spreads..."))

// Override say to use ethereal whispers instead
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	if(!message)
		return

	// Get all hearers in view
	var/list/hearers = get_hearers_in_view(7, src)

	// Send whisper to all visible entities
	for(var/mob/M in hearers)
		if(!M.client)
			continue
		to_chat(M, span_revennotice("You hear a cold whisper echoing from [src]... \"[message]\""))

	// Log the message
	log_say("[key_name(src)] (Door to Nowhere) whispers: [message]")

	// Visual effect
	manual_emote("'s chains rattle softly...")

	// Don't call parent - we don't want normal speech
	return

// Allow willing entry into the dimension
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(!ishuman(M))
		return

	// Only allow non-harmful intent
	if(M.a_intent == INTENT_HARM)
		to_chat(M, span_warning("You strike at the door, but the chains hold it firmly shut."))
		return

	// Check if already trapped
	if(IsTrappedInRepentance(M))
		to_chat(M, span_warning("You are already within the dimension..."))
		return

	// Confirm the action
	if(alert(M, "Do you wish to step through the Door to Nowhere and enter the realm of sealed regrets?", "Enter the Door", "Yes", "No") != "Yes")
		return

	to_chat(M, span_notice("You place your hand on the door. The chains begin to loosen as it recognizes your willing surrender..."))

	// Long channel time - 5 seconds
	if(do_after(M, 50, target = src))
		// Double-check they haven't been trapped in the meantime
		if(IsTrappedInRepentance(M))
			return

		to_chat(M, span_userdanger("You step through the door willingly, accepting whatever fate awaits within..."))
		visible_message(span_warning("[M] steps through [src], vanishing into the realm beyond!"))

		// Send them to the dimension without spinning
		var/message = "You willingly entered the realm of sealed regrets. The door closes gently behind you."
		SendToRepentanceDimension(M, message, FALSE)

		// Increase Qliphoth counter as reward for willing sacrifice
		if(datum_reference)
			datum_reference.qliphoth_change(1)
			visible_message(span_notice("The door seems satisfied with the willing offering, its chains tightening."))
	else
		to_chat(M, span_notice("You pull your hand back from the door."))

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()

	// 5% chance to drop a tape from the Mirror Worlds
	if(prob(5))
		var/turf/drop_location = get_turf(user)
		var/obj/item/tape/mirror_tape = new /obj/item/tape(drop_location)

		// Configure the tape
		mirror_tape.name = "mirror shattered tape"
		mirror_tape.desc = "A tape that seems to have fallen through the cracks of reality. It flickers with otherworldly static."
		mirror_tape.filters += filter(type = "blur", size = 1.5)

		// If available, copy content from persistence archive
		if(LAZYLEN(SSpersistence.door_to_nowhere_tapes))
			var/list/tape_data = pick(SSpersistence.door_to_nowhere_tapes)
			var/list/stored_info = tape_data["storedinfo"]
			var/list/stored_timestamp = tape_data["timestamp"]
			if(stored_info)
				mirror_tape.storedinfo = stored_info.Copy()
			if(stored_timestamp)
				mirror_tape.timestamp = stored_timestamp.Copy()
				mirror_tape.used_capacity = stored_timestamp[stored_timestamp.len]

		// Visual and audio feedback
		visible_message(span_warning("A tape materializes from the door's chains and falls to the floor!"))
		playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)

		// Check if this worker needs a tape recorder
		var/user_ckey = user.ckey
		if(user_ckey && !(user_ckey in workers_with_recorders))
			workers_with_recorders += user_ckey

			var/obj/item/taperecorder/empty/recorder = new /obj/item/taperecorder/empty(drop_location)
			to_chat(user, span_notice("A tape recorder materializes alongside the tape, as if the door wants you to listen..."))

			// Try to put recorder in their hand
			if(!user.put_in_hands(recorder))
				// If hands full, drop it nearby
				recorder.forceMove(get_step(drop_location, pick(NORTH, SOUTH, EAST, WEST)))

	// Handle Repression work - rescue trapped employees
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		var/list/trapped = GetRepentanceTrappedList()
		if(LAZYLEN(trapped))
			var/mob/living/carbon/human/rescued = pick(trapped)
			RescueFromRepentanceDimension(rescued, get_turf(src), "You manage to pull them back from that strange place!")
			to_chat(user, span_notice("You successfully rescued [rescued]!"))
		else
			to_chat(user, span_notice("There's no one to rescue."))
		return

	// Handle Insight work - increase Qliphoth counter
	if(work_type == ABNORMALITY_WORK_INSIGHT)
		datum_reference.qliphoth_change(2)
		to_chat(user, span_notice("The chains around the door tighten, keeping the regrets sealed within."))
		return

	// All other work types decrease Qliphoth counter
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	// 70% chance to send to repentance dimension on bad work (except Repression)
	if(work_type != ABNORMALITY_WORK_REPRESSION && prob(70))
		var/message = "The door's chains rattle violently as it pulls you into the realm of sealed regrets!"
		SendToRepentanceDimension(user, message, TRUE)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/ZeroQliphoth(mob/living/carbon/human/user)
	// Count active agents to determine victim count
	var/agent_count = 0
	var/list/agent_roles = list(
		"Agent Captain",
		"Agent",
		"Agent Intern"
	)

	for(var/mob/player in GLOB.player_list)
		if(!player.mind || !player.mind.assigned_role)
			continue
		if(player.stat == DEAD)
			continue
		if(player.mind.assigned_role in agent_roles)
			agent_count++

	// Calculate victims: 1 per 4 agents, minimum 1
	var/victims_to_send = max(1, round(agent_count / 4))

	// Build list of potential victims
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		if(IsTrappedInRepentance(H))
			continue
		if(!H.mind)
			continue
		potential_victims += H

	if(!LAZYLEN(potential_victims))
		return

	// Send victims up to calculated amount or available victims
	var/victims_count = min(victims_to_send, LAZYLEN(potential_victims))

	for(var/i in 1 to victims_count)
		if(!LAZYLEN(potential_victims))
			break
		var/mob/living/carbon/human/victim = pick_n_take(potential_victims)
		var/message = "The door has dragged you into the realm of sealed regrets!"
		SendToRepentanceDimension(victim, message, TRUE)
		to_chat(victim, span_userdanger("The door has dragged you into the realm of sealed regrets!"))

	visible_message(span_danger("[src]'s chains burst open momentarily, releasing waves of forgotten regrets before sealing shut once more."))

	// Announce the breach scale
	if(victims_count == 1)
		visible_message(span_warning("The door claims a single soul..."))
	else
		visible_message(span_warning("The door claims [victims_count] souls in its hunger for repentance!"))

	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Destroy()
	// Unregister signal
	UnregisterSignal(SSdcs, COMSIG_GLOB_HUMAN_INSANE)
	// Rescue all trapped players when destroyed
	for(var/mob/living/carbon/human/H in GetRepentanceTrappedList())
		RescueFromRepentanceDimension(H, get_turf(src))
	return ..()

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/death(gibbed)
	// Rescue all trapped players when killed
	for(var/mob/living/carbon/human/H in GetRepentanceTrappedList())
		var/message = "With the door shattered, the sealed memories dissipate and you are freed from that forsaken realm."
		RescueFromRepentanceDimension(H, get_turf(src), message)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

// Repentance dimension landmark for mapping
/obj/effect/landmark/repentance_spawn
	name = "repentance dimension spawn"
	icon_state = "x2"

/area/fishboat/repentance
	name = "realm of sealed regrets"

// Status effect for ambient repentance dimension audio
/datum/status_effect/repentance_ambience
	id = "repentance_ambience"
	duration = -1 // Permanent until removed
	alert_type = null
	var/next_sound_time = 0

/datum/status_effect/repentance_ambience/tick()
	if(world.time >= next_sound_time)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
			to_chat(H, span_warning("You hear whispers of repentance... souls seeking forgiveness for their regrets."))
		// Next sound in 5-10 minutes (converted to deciseconds)
		next_sound_time = world.time + rand(3000, 6000) // 300-600 seconds = 5-10 minutes

/datum/status_effect/repentance_ambience/on_apply()
	. = ..()
	// Play the sound immediately when first applied
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
	next_sound_time = world.time + rand(3000, 6000)

// Regret Door Structure
/obj/structure/regret_door
	name = "chained door"
	desc = "A door bound in rusted chains, keeping memories sealed away."
	icon = 'ModularLobotomy/_Lobotomyicons/chain_door.dmi'
	icon_state = "regret_door"
	anchored = TRUE
	opacity = FALSE
	resistance_flags = INDESTRUCTIBLE
	density = FALSE
	var/custom_name = FALSE
	var/door_name = ""
	var/door_desc = ""
	var/spirit_name = ""
	var/spirit_desc = ""
	var/mob/living/simple_animal/hostile/regret_spirit/associated_spirit

/obj/structure/regret_door/Initialize()
	. = ..()
	if(!custom_name)
		generate_regret_identity()
		spawn_associated_spirit()

/obj/structure/regret_door/proc/generate_regret_identity()
	// Lists of regret themes
	var/list/regret_types = list(
		"The Apology Never Given",
		"Mother's Last Words",
		"The Love Never Confessed",
		"Father's Disappointment",
		"The Friend You Betrayed",
		"The Opportunity Refused",
		"The Child Never Born",
		"The Truth Never Told",
		"The Promise Broken",
		"The Goodbye Never Said",
		"The Help Never Offered",
		"The Stand Never Taken",
		"The Dream Abandoned",
		"The Parent Never Visited",
		"The Forgiveness Withheld",
		"The Letter Never Sent",
		"The Call Never Made",
		"The Risk Never Taken",
		"The Words Too Late",
		"The Silence That Hurt"
	)

	var/list/spirit_first_names = list(
		"Marcus", "Elena", "James", "Sarah", "David", "Maria", "Thomas", "Anna",
		"Robert", "Lisa", "Michael", "Emma", "William", "Sophie", "Charles", "Grace",
		"Joseph", "Claire", "Daniel", "Helen", "Samuel", "Rose", "Henry", "Alice"
	)

	var/list/spirit_emotions = list(
		"weeping", "lamenting", "mourning", "grieving", "regretting",
		"yearning", "aching", "suffering", "remorseful", "tormented"
	)

	// Pick random elements
	door_name = pick(regret_types)
	name = door_name

	var/chosen_first_name = pick(spirit_first_names)
	var/chosen_emotion = pick(spirit_emotions)

	// Generate descriptions based on the door type
	switch(door_name)
		if("The Apology Never Given")
			door_desc = "Behind this door echoes an endless loop of 'I'm sorry' that was never spoken."
			spirit_name = "[chosen_first_name] the Unforgiving"
			spirit_desc = "A spectral figure eternally waiting for an apology that will never come."
		if("Mother's Last Words")
			door_desc = "You can hear a mother's voice calling for her child who never came."
			spirit_name = "[chosen_first_name] the Absent"
			spirit_desc = "This spirit clutches at empty air where a child's hand should have been."
		if("The Love Never Confessed")
			door_desc = "The chains tremble with the weight of unspoken affection."
			spirit_name = "[chosen_first_name] the Silent Heart"
			spirit_desc = "A ghost whose lips move constantly, practicing words they never had the courage to say."
		if("Father's Disappointment")
			door_desc = "A heavy silence emanates from within, thick with unmet expectations."
			spirit_name = "[chosen_first_name] the Insufficient"
			spirit_desc = "This shade carries the weight of never being good enough."
		if("The Friend You Betrayed")
			door_desc = "Muffled sobs and the sound of trust breaking echo from beyond."
			spirit_name = "[chosen_first_name] the Betrayed"
			spirit_desc = "A spirit with a knife-shaped wound that never stops bleeding ectoplasm."
		if("The Opportunity Refused")
			door_desc = "Behind this door lies every 'what if' that haunts the fearful."
			spirit_name = "[chosen_first_name] the Coward"
			spirit_desc = "This ghost eternally reaches for something just beyond their grasp."
		if("The Child Never Born")
			door_desc = "Empty lullabies drift through the chains."
			spirit_name = "[chosen_first_name] the Childless"
			spirit_desc = "A parental figure cradling nothing but air and sorrow."
		if("The Truth Never Told")
			door_desc = "Lies upon lies have crystallized into chains that bind this door."
			spirit_name = "[chosen_first_name] the Deceiver"
			spirit_desc = "A spirit whose form shifts constantly, never showing their true face."
		if("The Promise Broken")
			door_desc = "The chains here are made from shattered vows."
			spirit_name = "[chosen_first_name] the Oathbreaker"
			spirit_desc = "This shade's hands are bound by ethereal contracts they failed to honor."
		if("The Goodbye Never Said")
			door_desc = "The door rattles with the urgency of final words unspoken."
			spirit_name = "[chosen_first_name] the Departed"
			spirit_desc = "A ghost forever frozen in the moment they should have said farewell."
		else
			door_desc = "The chains pulse with the rhythm of a [chosen_emotion] heart."
			spirit_name = "[chosen_first_name] the [capitalize(chosen_emotion)]"
			spirit_desc = "A tormented soul forever bound to their deepest regret."

	desc = door_desc

/obj/structure/regret_door/proc/spawn_associated_spirit()
	// Find all valid turfs in the repentance dimension area
	var/list/valid_turfs = list()
	for(var/turf/T in range(10, src))
		if(istype(T.loc, /area/fishboat/repentance) && !T.density)
			var/blocked = FALSE
			for(var/atom/A in T)
				if(A.density)
					blocked = TRUE
					break
			if(!blocked)
				valid_turfs += T

	if(!LAZYLEN(valid_turfs))
		return

	// Spawn the spirit
	var/turf/spawn_loc = pick(valid_turfs)
	associated_spirit = new /mob/living/simple_animal/hostile/regret_spirit(spawn_loc)
	associated_spirit.name = spirit_name
	associated_spirit.desc = spirit_desc
	associated_spirit.associated_door = src

/obj/structure/regret_door/examine(mob/user)
	. = ..()
	. += span_warning("Looking at it fills you with an inexplicable sense of loss.")
	if(prob(30))
		to_chat(user, span_notice("You hear faint whispers: '[pick("I should have...", "Why didn't I...", "If only...", "I'm sorry...", "Please forgive me...")]'"))
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.adjustSanityLoss(5)

// Allow entering the door from outside the dimension
/obj/structure/regret_door/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(!ishuman(M))
		return

	// Check if already in the repentance dimension
	if(istype(M.loc.loc, /area/fishboat/repentance))
		to_chat(M, span_warning("You are already within the realm of sealed regrets. This door leads nowhere from here."))
		return

	// Check if already trapped (shouldn't happen but safety check)
	if(IsTrappedInRepentance(M))
		to_chat(M, span_warning("You are already bound to this dimension..."))
		return

	// Confirm the action
	if(alert(M, "Do you wish to open this door and step into the realm it guards? The name reads: '[name]'", "Open Regret Door", "Yes", "No") != "Yes")
		return

	to_chat(M, span_notice("You grasp the handle of [name]. The chains rattle as they slowly unwrap..."))
	to_chat(M, span_warning("You feel the weight of [pick("regret", "sorrow", "loss", "remorse")] pulling you forward..."))

	// Long channel time - 5 seconds
	if(do_after(M, 50, target = src))
		// Double-check they haven't been trapped in the meantime
		if(IsTrappedInRepentance(M))
			return

		to_chat(M, span_userdanger("You push open [name] and step through into the realm of repentance!"))
		visible_message(span_warning("[M] opens [name] and steps through, disappearing into the darkness beyond!"))

		// Custom message based on the door type
		var/entry_message = "You stepped through [name]. [door_desc]"
		SendToRepentanceDimension(M, entry_message, FALSE)

		// Visual effect
		playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)

		// The door closes behind them
		visible_message(span_notice("[name] swings shut with a heavy thud, the chains wrapping back around it."))
	else
		to_chat(M, span_notice("You release the handle, deciding against entering."))

/obj/structure/regret_door/Destroy()
	if(associated_spirit)
		qdel(associated_spirit)
	return ..()

/obj/structure/regret_door/custom
	custom_name = TRUE

// Regret Spirit Mob
/mob/living/simple_animal/hostile/regret_spirit
	name = "spirit of regret"
	desc = "A tormented soul bound to their eternal shame."
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	icon_living = "ghost"
	mob_biotypes = MOB_SPIRIT
	speak_chance = 0.1
	turns_per_move = 10
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	a_intent = INTENT_HELP
	friendly_verb_continuous = "mourns at"
	friendly_verb_simple = "mourn at"
	speed = 2
	maxHealth = 200
	health = 200
	faction = list("neutral")
	harm_intent_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "phases through"
	attack_verb_simple = "phase through"
	speak_emote = list("whispers", "laments", "weeps")
	emote_see = list(
		"stares at something that isn't there",
		"reaches out to empty air",
		"mouths silent words",
		"trembles with grief",
		"clutches at their ethereal chest"
	)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	is_flying_animal = TRUE
	pressure_resistance = 300
	light_system = MOVABLE_LIGHT
	light_range = 1
	light_power = 1
	light_color = "#7092BE"
	del_on_death = TRUE
	death_message = "lets out a final, mournful wail before fading into nothingness..."
	var/obj/structure/regret_door/associated_door
	var/list/regret_phrases = list()

/mob/living/simple_animal/hostile/regret_spirit/Initialize()
	. = ..()
	alpha = 180 // Semi-transparent
	generate_regret_phrases()

/mob/living/simple_animal/hostile/regret_spirit/proc/generate_regret_phrases()
	// Generate phrases based on the spirit's name/type
	if(findtext(name, "Unforgiving"))
		regret_phrases = list(
			"I waited so long for you to say it...",
			"Just one word would have been enough...",
			"Why couldn't you apologize?",
			"I would have forgiven you..."
		)
	else if(findtext(name, "Absent"))
		regret_phrases = list(
			"She called for you...",
			"You should have been there...",
			"She died alone because of you...",
			"Her last word was your name..."
		)
	else if(findtext(name, "Silent Heart"))
		regret_phrases = list(
			"I loved you... I loved you... I loved you...",
			"Three words I never said...",
			"Now you'll never know...",
			"My cowardice killed us both..."
		)
	else if(findtext(name, "Betrayed"))
		regret_phrases = list(
			"We were supposed to be friends...",
			"How could you do this to me?",
			"I trusted you with everything...",
			"Was any of it real?"
		)
	else
		regret_phrases = list(
			"If only...",
			"I should have...",
			"Why didn't I...",
			"It's too late now...",
			"I'm so sorry..."
		)

/mob/living/simple_animal/hostile/regret_spirit/Life()
	. = ..()
	if(prob(speak_chance))
		say(pick(regret_phrases))

/mob/living/simple_animal/hostile/regret_spirit/examine(mob/user)
	. = ..()
	. += span_warning("Looking at [src] fills you with secondhand sorrow.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(3)

/mob/living/simple_animal/hostile/regret_spirit/attack_hand(mob/living/carbon/human/M)
	if(M.a_intent == INTENT_HELP)
		to_chat(M, span_notice("Your hand passes through [src]. They don't even notice you're there."))
		playsound(loc, 'sound/effects/ghost2.ogg', 30, TRUE)
	else
		to_chat(M, span_warning("[src] is already suffering enough."))

/mob/living/simple_animal/hostile/regret_spirit/attackby(obj/item/W, mob/user, params)
	to_chat(user, span_notice("[W] passes harmlessly through [src]."))
	playsound(loc, 'sound/effects/ghost2.ogg', 30, TRUE)

/mob/living/simple_animal/hostile/regret_spirit/Destroy()
	if(associated_door)
		associated_door.associated_spirit = null
	return ..()

// ABILITY IMPLEMENTATIONS

// Override OpenFire to add visual feedback when firing projectiles
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/OpenFire(atom/A)
	if(ranged_cooldown > world.time)
		return

	// Visual feedback when firing
	visible_message(span_danger("[src]'s chains rattle as a spectral hand emerges!"))

	return ..()

// Override Move to prevent movement while projecting
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Move()
	if(projecting_spirit)
		return FALSE
	return ..()

// Override CanAttack to prevent attacks while projecting
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/CanAttack(atom/the_target)
	if(projecting_spirit)
		return FALSE
	return ..()

// Override OpenFire to prevent projectile attacks while projecting
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/OpenFire(atom/A)
	if(projecting_spirit)
		return FALSE
	return ..()

// Spirit projection ability
/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/project_spirit()
	if(projecting_spirit || !client)
		return FALSE

	projecting_spirit = TRUE

	// Create the spirit
	var/mob/living/simple_animal/hostile/regret_spirit/projection/P = new(get_turf(src))
	P.name = "projection of [name]"
	P.source_door = src
	P.faction = faction.Copy()

	// Transfer mind
	var/datum/mind/door_mind = mind
	if(door_mind)
		door_mind.transfer_to(P)

	// Make spirit incorporeal
	P.incorporeal_move = INCORPOREAL_MOVE_BASIC
	P.pass_flags = PASSTABLE | PASSGRILLE | PASSMOB | PASSMACHINE | PASSSTRUCTURE | PASSCLOSEDTURF
	P.density = FALSE

	// Give control abilities
	var/datum/action/innate/return_to_door/return_ability = new
	return_ability.Grant(P)

	// Visual feedback
	visible_message(span_warning("[src] shudders as a ghostly form emerges from within! The door becomes completely still..."))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)

	// Set timer to return (using src as the original body)
	addtimer(CALLBACK(src, PROC_REF(recall_spirit), P, src), 30 SECONDS)

	return TRUE

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/recall_spirit(mob/living/simple_animal/hostile/regret_spirit/projection/P, mob/living/original_body)
	if(!P || QDELETED(P))
		projecting_spirit = FALSE
		return

	// Transfer mind back
	if(P.mind)
		P.mind.transfer_to(original_body)

	// Effects
	playsound(original_body, 'sound/effects/ghost.ogg', 50, TRUE)
	to_chat(original_body, span_notice("Your consciousness returns to your true form."))
	visible_message(span_notice("[original_body] shudders back to life as the spirit returns!"))

	// Clean up - setting projecting_spirit to FALSE will allow movement and attacks again
	projecting_spirit = FALSE
	qdel(P)

// ABILITY DATUMS

// Targeted whisper ability
/datum/action/innate/targeted_whisper
	name = "Focused Whisper"
	desc = "Send a chilling whisper directly into someone's mind."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "telepathy"
	check_flags = AB_CHECK_CONSCIOUS
	var/cooldown_time = 50  // 5 second cooldown
	var/next_use = 0

/datum/action/innate/targeted_whisper/Activate()
	if(!IsAvailable())
		return FALSE

	if(world.time < next_use)
		to_chat(owner, span_warning("This ability is on cooldown."))
		return FALSE

	var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/D = owner

	// Get possible targets
	var/list/possible_targets = list()
	for(var/mob/living/L in view(7, D))
		if(L == D || !L.client)
			continue
		possible_targets[L.name] = L

	if(!possible_targets.len)
		to_chat(D, span_warning("There is no one nearby to whisper to..."))
		return FALSE

	// Choose target
	var/target_name = input(D, "Choose your target...", "Focused Whisper") as null|anything in possible_targets
	if(!target_name)
		return FALSE

	var/mob/living/target = possible_targets[target_name]
	if(!target || get_dist(D, target) > 7 || !target.client)
		return FALSE

	// Get message
	var/message = input(D, "What chilling message do you wish to send?", "Whisper") as text|null
	if(!message)
		return FALSE

	// Verify target is still valid
	if(!target || QDELETED(target) || get_dist(D, target) > 7)
		to_chat(D, span_warning("Your target is no longer in range."))
		return FALSE

	// Send the whisper
	to_chat(target, span_boldwarning("You feel a presence focus on you... A cold whisper penetrates your mind: \"[message]\""))
	to_chat(D, span_notice("You whisper to [target]: \"[message]\""))

	// Visual feedback for others
	for(var/mob/M in viewers(target, 7))
		if(M != target && M != D)
			to_chat(M, span_warning("[target] shivers as if touched by something unseen..."))

	// Logging
	log_directed_talk(D, target, message, LOG_SAY, "door whisper")

	// Start cooldown
	next_use = world.time + cooldown_time
	return TRUE

// Spirit possession ability
/datum/action/innate/door_possession
	name = "Project Regret Spirit"
	desc = "Project your consciousness into a spirit of regret for 30 seconds."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "teleport"
	check_flags = AB_CHECK_CONSCIOUS
	var/cooldown_time = 1200  // 2 minute cooldown
	var/next_use = 0

/datum/action/innate/door_possession/Activate()
	if(!IsAvailable())
		return FALSE

	if(world.time < next_use)
		to_chat(owner, span_warning("This ability is on cooldown."))
		return FALSE

	var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/D = owner
	if(D.project_spirit())
		next_use = world.time + cooldown_time
		return TRUE
	return FALSE

// Return to door ability for projected spirits
/datum/action/innate/return_to_door
	name = "Return to Form"
	desc = "Return your consciousness to your true form."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "exit_possession"

/datum/action/innate/return_to_door/Activate()
	var/mob/living/simple_animal/hostile/regret_spirit/projection/P = owner
	if(!istype(P) || !P.source_door)
		return FALSE

	P.source_door.recall_spirit(P, P.source_door)
	return TRUE

// PROJECTILE DEFINITIONS

/obj/projectile/regret_hand
	name = "hand of regret"
	icon_state = "cursehand0"
	hitsound = 'sound/effects/curse4.ogg'
	layer = LARGE_MOB_LAYER
	damage_type = WHITE_DAMAGE  // Psychological damage
	damage = 15
	speed = 2
	range = 10
	var/datum/beam/arm
	var/handedness = 0

/obj/projectile/regret_hand/Initialize(mapload)
	. = ..()
	handedness = prob(50)
	icon_state = "cursehand[handedness]"

/obj/projectile/regret_hand/fire(setAngle)
	if(starting)
		arm = starting.Beam(src, icon_state = "curse[handedness]", beam_type=/obj/effect/ebeam/curse_arm)
	..()

/obj/projectile/regret_hand/Destroy()
	if(arm)
		QDEL_NULL(arm)
	return ..()

/obj/projectile/regret_hand/on_hit(atom/target, blocked)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		// Apply or stack regret
		var/datum/status_effect/regret_stacks/R = H.has_status_effect(/datum/status_effect/regret_stacks)
		if(R)
			R.add_stack()
		else
			H.apply_status_effect(/datum/status_effect/regret_stacks, firer)

// STATUS EFFECT DEFINITIONS

/datum/status_effect/regret_stacks
	id = "regret_stacks"
	duration = -1  // Permanent until removed
	tick_interval = 600  // 60 seconds
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/regret
	var/stacks = 1
	var/max_stacks = 10
	var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/source_door

/datum/status_effect/regret_stacks/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/abnormality/door_to_nowhere/door)
	. = ..()
	source_door = door

/datum/status_effect/regret_stacks/on_apply()
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	to_chat(owner, span_userdanger("You feel the weight of regret settling upon your soul..."))
	return TRUE

/datum/status_effect/regret_stacks/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_DEATH)
	to_chat(owner, span_notice("The weight of regret lifts from your soul."))

/datum/status_effect/regret_stacks/tick()
	// Decay one stack per minute
	remove_stack()

/datum/status_effect/regret_stacks/proc/add_stack()
	stacks = min(stacks + 1, max_stacks)

	// Update alert
	if(linked_alert)
		linked_alert.desc = "You carry [stacks] burden\s of regret. At 5 stacks, you will be pulled into the realm of sealed memories."

	// Check for teleportation
	if(stacks >= 5 && source_door && !QDELETED(source_door))
		var/message = "The weight of accumulated regret pulls you into the realm of sealed regrets!"
		SendToRepentanceDimension(owner, message, TRUE)
		qdel(src)
		return

	// Flavor text based on stack count
	switch(stacks)
		if(2)
			to_chat(owner, span_warning("The weight of unspoken words grows heavier..."))
		if(3)
			to_chat(owner, span_warning("Memories of things left undone flash before your eyes..."))
		if(4)
			to_chat(owner, span_danger("The chains of regret tighten around your soul!"))

/datum/status_effect/regret_stacks/proc/remove_stack()
	stacks--
	if(stacks <= 0)
		qdel(src)
		return
	if(linked_alert)
		linked_alert.desc = "You carry [stacks] burden\s of regret."

/datum/status_effect/regret_stacks/proc/on_death()
	SIGNAL_HANDLER
	qdel(src)

// Alert for regret status
/atom/movable/screen/alert/status_effect/regret
	name = "Burden of Regret"
	desc = "You carry burdens of regret. At 5 stacks, you will be pulled into the realm of sealed memories."
	icon_state = "wounded_soldier"

// SPIRIT PROJECTION MOB

/mob/living/simple_animal/hostile/regret_spirit/projection
	name = "projected spirit"
	desc = "A temporary manifestation of regret and sorrow."
	health = 250  // Fragile
	maxHealth = 250
	var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/source_door
	del_on_death = TRUE

/mob/living/simple_animal/hostile/regret_spirit/projection/death(gibbed)
	if(source_door && !QDELETED(source_door))
		source_door.recall_spirit(src, source_door)
	return ..()

/mob/living/simple_animal/hostile/regret_spirit/projection/Life()
	. = ..()
	// Slowly drain health as time passes
	adjustBruteLoss(1.5)

// Tape Archive Machine for storing regret tapes persistently
/obj/machinery/tape_archive
	name = "regret tape archive"
	desc = "A strange machine that resonates with echoes from parallel realities. Insert tapes to preserve them across Mirror Worlds."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "circuit_imprinter"
	density = TRUE
	var/list/stored_tapes = list()
	var/processing = FALSE
	var/list/users_who_archived = list()  // Track who has archived this round

/obj/machinery/tape_archive/Initialize()
	. = ..()
	LAZYADD(SSpersistence.tape_archive_machines, src)

/obj/machinery/tape_archive/Destroy()
	LAZYREMOVE(SSpersistence.tape_archive_machines, src)
	return ..()

/obj/machinery/tape_archive/attackby(obj/item/I, mob/user, params)
	// Only accept exact tape type, no subtypes
	if(I.type != /obj/item/tape)
		to_chat(user, span_warning("[src] only accepts standard recording tapes."))
		return

	if(processing)
		to_chat(user, span_warning("[src] is currently processing another tape."))
		return

	var/obj/item/tape/T = I

	if(T.ruined)
		to_chat(user, span_warning("The tape is too damaged to archive."))
		return

	if(!T.storedinfo || !T.storedinfo.len)
		to_chat(user, span_warning("The tape is blank and cannot be archived."))
		return

	// Check if user has already archived a tape this round
	var/user_key = user.ckey
	if(user_key in users_who_archived)
		to_chat(user, span_warning("The machine resonates strangely... You have already contributed an echo to the Mirror Worlds this shift."))
		to_chat(user, span_notice("Only one tape per person can cross the dimensional barrier each shift."))
		return

	// Check if tape already exists in persistence
	for(var/list/tape_data in SSpersistence.door_to_nowhere_tapes)
		if(tape_data["storedinfo"] ~= T.storedinfo)
			to_chat(user, span_notice("This tape already exists within the Mirror Worlds archive."))
			return

	if(!user.transferItemToLoc(I, src))
		return

	processing = TRUE
	to_chat(user, span_notice("You insert [T] into [src]. The machine begins resonating with otherworldly energy..."))
	playsound(src, 'sound/machines/terminal_processing.ogg', 50, TRUE)
	icon_state = "circuit_imprinter_ani"

	addtimer(CALLBACK(src, PROC_REF(archive_tape), T, user), 3 SECONDS)

/obj/machinery/tape_archive/proc/archive_tape(obj/item/tape/T, mob/user)
	if(!T || QDELETED(T))
		processing = FALSE
		icon_state = initial(icon_state)
		return

	// Create tape data for persistence
	var/list/tape_data = list(
		"name" = T.name,
		"desc" = T.desc,
		"icon_state" = T.icon_state,
		"storedinfo" = T.storedinfo.Copy(),
		"timestamp" = T.timestamp.Copy(),
		"original_round" = GLOB.round_id
	)

	// Add to persistence list - ensure we're adding as a single item
	if(!SSpersistence.door_to_nowhere_tapes)
		SSpersistence.door_to_nowhere_tapes = list()
	SSpersistence.door_to_nowhere_tapes += list(tape_data)  // Wrap in list to ensure it's added as single element

	// Mark this user as having archived this round
	if(user && user.ckey)
		users_who_archived += user.ckey

	to_chat(user, span_nicegreen("The tape phases between dimensions, creating echoes across Mirror Worlds."))
	to_chat(user, span_notice("Your recording will resonate through parallel realities, preserved in the spaces between."))
	visible_message(span_warning("[src] shimmers briefly as reality bends around it..."), vision_distance = 3)
	playsound(src, 'sound/machines/terminal_success.ogg', 50, TRUE)

	// Consume the tape
	qdel(T)
	processing = FALSE
	icon_state = initial(icon_state)

/obj/machinery/tape_archive/examine(mob/user)
	. = ..()
	var/tape_count = LAZYLEN(SSpersistence.door_to_nowhere_tapes)
	if(tape_count)
		if(tape_count == 1)
			. += span_notice("The archive resonates with 1 echo from across the Mirror Worlds.")
		else
			. += span_notice("The archive resonates with [tape_count] echoes from across the Mirror Worlds.")
		// Count tapes from this round
		var/current_round_count = 0
		for(var/list/tape_data in SSpersistence.door_to_nowhere_tapes)
			if(tape_data["original_round"] == GLOB.round_id)
				current_round_count++
		if(current_round_count)
			if(current_round_count == 1)
				. += span_notice("1 new echo was captured from this reality.")
			else
				. += span_notice("[current_round_count] new echoes were captured from this reality.")
	else
		. += span_notice("The archive is silent, awaiting echoes from the Mirror Worlds.")

	// Check if this user has already archived
	if(user && user.ckey && (user.ckey in users_who_archived))
		. += span_warning("You have already contributed your echo to the Mirror Worlds this shift.")

// Landmark that spawns random archived tapes
/obj/effect/landmark/tape_spawner/door_to_nowhere
	name = "door to nowhere tape spawn"
	icon_state = "x"

/obj/effect/landmark/tape_spawner/door_to_nowhere/Initialize()
	. = ..()

	// Wait a bit for persistence to load
	addtimer(CALLBACK(src, PROC_REF(spawn_tape)), 1 SECONDS)

/obj/effect/landmark/tape_spawner/door_to_nowhere/proc/spawn_tape()
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	var/obj/item/tape/new_tape

	// Try to spawn from archive first
	if(LAZYLEN(SSpersistence.door_to_nowhere_tapes))
		world.log << "Tape spawner: Found [LAZYLEN(SSpersistence.door_to_nowhere_tapes)] tapes in archive"
		var/list/tape_data = pick(SSpersistence.door_to_nowhere_tapes)
		new_tape = new /obj/item/tape(T)

		// Check if the name is just "tape" and rename it
		if(tape_data["name"] == "tape")
			new_tape.name = "mirror shattered tape"
		else
			new_tape.name = tape_data["name"]

		new_tape.desc = tape_data["desc"]
		new_tape.icon_state = tape_data["icon_state"]
		var/list/stored_info = tape_data["storedinfo"]
		var/list/stored_timestamp = tape_data["timestamp"]
		if(stored_info)
			new_tape.storedinfo = stored_info.Copy()
			world.log << "Tape spawner: Copied [LAZYLEN(stored_info)] lines to new tape"
		else
			new_tape.storedinfo = list()
			world.log << "Tape spawner: Warning - stored_info was null!"
		if(stored_timestamp)
			new_tape.timestamp = stored_timestamp.Copy()
			new_tape.used_capacity = stored_timestamp[stored_timestamp.len]
		else
			new_tape.timestamp = list()
			new_tape.used_capacity = 0
			world.log << "Tape spawner: Warning - stored_timestamp was null!"

		// Add blur effect to the tape
		new_tape.filters += filter(type = "blur", size = 1.5)

	qdel(src)

// REGRET PUZZLE SYSTEM FOR SECRET ARCHIVE ROOM

// Shrine base type
/obj/structure/regret_shrine
	name = "shrine of regret"
	desc = "A small monument that resonates with deep sorrow. There's an inscription you can barely make out."
	icon = 'icons/obj/structures.dmi'
	icon_state = "shrine"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/shrine_type = "generic"
	var/activated = FALSE
	var/activation_message = "The shrine resonates with your action."
	var/hint_message = "You must show your regret."
	var/required_action = "" // What the player needs to do

/obj/structure/regret_shrine/Initialize()
	. = ..()
	GLOB.regret_shrines += src

/obj/structure/regret_shrine/Destroy()
	GLOB.regret_shrines -= src
	return ..()

/obj/structure/regret_shrine/examine(mob/user)
	. = ..()
	if(!activated)
		. += span_notice("The inscription reads: \"[hint_message]\"")
	else
		. += span_nicegreen("This shrine has accepted your offering of regret.")

/obj/structure/regret_shrine/proc/check_activation()
	// Check if all shrines are activated
	var/all_activated = TRUE
	for(var/obj/structure/regret_shrine/S in GLOB.regret_shrines)
		if(!S.activated)
			all_activated = FALSE
			break

	if(all_activated)
		create_regret_key()

/obj/structure/regret_shrine/proc/create_regret_key()
	// Find a central location or the first shrine
	var/turf/key_location = get_turf(GLOB.regret_shrines[1])

	// Create dramatic effect
	for(var/obj/structure/regret_shrine/S in GLOB.regret_shrines)
		playsound(S, 'sound/effects/ghost2.ogg', 50, TRUE)
		var/obj/effect/temp_visual/dir_setting/curse/grasp_portal/G = new(get_turf(S), S.dir)
		G.icon_state = "curse0"

	// Create the key
	sleep(20)
	new /obj/item/regret_key(key_location)
	visible_message(span_boldnotice("The shrines resonate in unison, manifesting a key from collective regret!"))

	// Reset shrines after a delay
	addtimer(CALLBACK(src, PROC_REF(reset_all_shrines)), 10 MINUTES)

/obj/structure/regret_shrine/proc/reset_all_shrines()
	for(var/obj/structure/regret_shrine/S in GLOB.regret_shrines)
		S.activated = FALSE
		S.update_icon()

/obj/structure/regret_shrine/proc/activate(mob/user)
	if(activated)
		to_chat(user, span_notice("This shrine has already accepted an offering."))
		return

	activated = TRUE
	to_chat(user, span_nicegreen("[activation_message]"))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
	update_icon()
	check_activation()

/obj/structure/regret_shrine/update_icon()
	if(activated)
		icon_state = "[initial(icon_state)]_active"
	else
		icon_state = initial(icon_state)

// Shrine of Unspoken Words - requires saying something while next to it
/obj/structure/regret_shrine/unspoken
	name = "shrine of unspoken words"
	shrine_type = "unspoken"
	hint_message = "Speak what was never said. Let your voice carry the words you kept inside."
	activation_message = "The shrine accepts your unspoken words, absorbing what was left unsaid."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "convertaltar"

/obj/structure/regret_shrine/unspoken/attack_hand(mob/living/user)
	. = ..()
	if(!activated && ishuman(user))
		to_chat(user, span_notice("Speak near the shrine to activate it..."))
		addtimer(CALLBACK(src, PROC_REF(listen_for_speech), user), 1)

/obj/structure/regret_shrine/unspoken/proc/listen_for_speech(mob/living/user)
	if(!activated && get_dist(user, src) <= 4 && ishuman(user))
		to_chat(user, span_notice("Say something to activate the shrine."))
		if(do_after(user, 30, target = src))
			if(!activated)
				activate(user)
				to_chat(user, span_notice("Your words echo strangely, as if finally reaching someone who needed to hear them..."))

// Shrine of Abandoned Dreams - requires dropping an item (sacrifice)
/obj/structure/regret_shrine/abandoned
	name = "shrine of abandoned dreams"
	shrine_type = "abandoned"
	hint_message = "Leave behind what you carry. Sometimes we must let go of what we hold dear."
	activation_message = "The shrine accepts your sacrifice, taking with it a piece of what could have been."
	icon = 'icons/obj/tomb.dmi'
	icon_state = "memorial"

/obj/structure/regret_shrine/abandoned/attackby(obj/item/I, mob/user, params)
	if(!activated && !istype(I, /obj/item/regret_key))
		if(user.transferItemToLoc(I, src))
			activate(user)
			to_chat(user, span_notice("[I] fades into the shrine, becoming one with abandoned possibilities..."))
			qdel(I)
		return
	..()

// Shrine of Lost Time - requires standing still near it for 30 seconds
/obj/structure/regret_shrine/lost_time
	name = "shrine of lost time"
	shrine_type = "lost_time"
	hint_message = "Stand still and reflect. Time lost to hesitation can never be reclaimed."
	activation_message = "The shrine accepts your patience, acknowledging the moments you've given."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "fallen_armor"
	var/mob/living/waiting_user = null
	var/wait_start = 0

/obj/structure/regret_shrine/lost_time/proc/check_wait_completion()
	if(!waiting_user || get_dist(waiting_user, src) > 4)
		waiting_user = null
		return

	if(world.time - wait_start >= 300) // 30 seconds
		activate(waiting_user)
		to_chat(waiting_user, span_notice("Time flows differently here... You feel the weight of moments that slipped away."))
		waiting_user = null

/obj/structure/regret_shrine/lost_time/attack_hand(mob/living/user)
	. = ..()
	if(!activated && !waiting_user && ishuman(user))
		waiting_user = user
		wait_start = world.time
		to_chat(user, span_notice("You begin to reflect at the shrine. Stand still and wait..."))
		addtimer(CALLBACK(src, PROC_REF(check_wait_completion)), 305)

// The Key of Acceptance
/obj/item/regret_key
	name = "key of acceptance"
	desc = "A old photo formed from acknowledged regrets. It feels both heavy and liberating to hold."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "photo_old"
	w_class = WEIGHT_CLASS_SMALL
	var/used = FALSE

/obj/item/regret_key/examine(mob/user)
	. = ..()
	. += span_notice("This key seems to resonate with hidden spaces where regrets are preserved.")

// Secret door to archive room
/obj/machinery/door/airlock/regret_archive
	name = "sealed archive door"
	desc = "A heavy door marked with chains and seals. It seems to guard something that transcends realities."
	icon = 'icons/obj/doors/airlocks/centcom/centcom.dmi'
	overlays_file = 'icons/obj/doors/airlocks/centcom/overlays.dmi'
	opacity = TRUE
	req_access = list("regret_key") // Requires special key
	resistance_flags = INDESTRUCTIBLE

/obj/machinery/door/airlock/regret_archive/allowed(mob/M)
	if(istype(M.pulling, /obj/item/regret_key))
		return TRUE
	for(var/obj/item/I in M.contents)
		if(istype(I, /obj/item/regret_key))
			return TRUE
	return FALSE

/obj/machinery/door/airlock/regret_archive/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/regret_key))
		var/obj/item/regret_key/K = I
		if(!K.used)
			K.used = TRUE
			to_chat(user, span_notice("The key resonates with the door, causing the seals to fade temporarily..."))
			playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
			open()
			addtimer(CALLBACK(src, PROC_REF(close)), 30 SECONDS)
			addtimer(CALLBACK(K, TYPE_PROC_REF(/obj/item/regret_key, reset_key)), 5 MINUTES)
		else
			to_chat(user, span_warning("The key needs time to regain its resonance."))
		return
	..()

/obj/item/regret_key/proc/reset_key()
	used = FALSE

// Add to globals
GLOBAL_LIST_EMPTY(regret_shrines)

// Door Dimension Void - A chasm that teleports instead of kills
/turf/open/chasm/door_dimension
	name = "reality void"
	desc = "A tear in the fabric of this dimension. You can feel yourself being pulled back to your own reality."
	icon = 'icons/turf/floors/chasms.dmi'
	icon_state = "chasms-255"
	base_icon_state = "chasms"
	baseturfs = /turf/open/chasm/door_dimension
	light_range = 2
	light_power = 0.8
	light_color = "#551A8B" // Dark purple

/turf/open/chasm/door_dimension/Initialize()
	. = ..()
	// Remove the default chasm component and add our custom one
	var/datum/component/chasm/old_chasm = GetComponent(/datum/component/chasm)
	if(old_chasm)
		qdel(old_chasm)
	AddComponent(/datum/component/door_dimension_void)

// Custom component that teleports instead of kills
/datum/component/door_dimension_void
	var/static/list/falling_atoms = list() // Track who's falling
	var/static/list/forbidden_types = typecacheof(list(
		/obj/singularity,
		/obj/energy_ball,
		/obj/narsie,
		/obj/docking_port,
		/obj/structure/lattice,
		/obj/structure/stone_tile,
		/obj/projectile,
		/obj/effect/projectile,
		/obj/effect/portal,
		/obj/effect/abstract,
		/obj/effect/hotspot,
		/obj/effect/landmark,
		/obj/effect/temp_visual,
		/obj/effect/light_emitter/tendril,
		/obj/effect/collapse,
		/obj/effect/particle_effect/ion_trails,
		/obj/effect/dummy/phased_mob,
		/obj/effect/mapping_helpers,
		/obj/effect/wisp,
		/mob/living/simple_animal/hostile/abnormality/door_to_nowhere // Don't let the abnormality fall into its own void
	))

/datum/component/door_dimension_void/Initialize()
	RegisterSignal(parent, list(COMSIG_MOVABLE_CROSSED, COMSIG_ATOM_ENTERED), PROC_REF(Entered))
	START_PROCESSING(SSobj, src)

/datum/component/door_dimension_void/proc/Entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	START_PROCESSING(SSobj, src)
	drop_stuff(AM)

/datum/component/door_dimension_void/process()
	if (!drop_stuff())
		STOP_PROCESSING(SSobj, src)

/datum/component/door_dimension_void/proc/is_safe()
	// Check for catwalks or stone tiles that prevent falling
	var/static/list/chasm_safeties_typecache = typecacheof(list(/obj/structure/lattice/catwalk, /obj/structure/stone_tile))
	var/atom/parent = src.parent
	var/list/found_safeties = typecache_filter_list(parent.contents, chasm_safeties_typecache)
	for(var/obj/structure/stone_tile/S in found_safeties)
		if(S.fallen)
			LAZYREMOVE(found_safeties, S)
	return LAZYLEN(found_safeties)

/datum/component/door_dimension_void/proc/drop_stuff(AM)
	. = 0
	if (is_safe())
		return FALSE

	var/atom/parent = src.parent
	var/to_check = AM ? list(AM) : parent.contents
	for (var/thing in to_check)
		if (droppable(thing))
			. = 1
			INVOKE_ASYNC(src, PROC_REF(drop), thing)

/datum/component/door_dimension_void/proc/droppable(atom/movable/AM)
	// Prevent infinite loops and re-triggering
	if(falling_atoms[AM])
		return FALSE // Already falling, don't process again
	if(!isliving(AM) && !isobj(AM))
		return FALSE
	if(is_type_in_typecache(AM, forbidden_types) || AM.throwing || (AM.movement_type & (FLOATING|FLYING)))
		return FALSE

	// Check for buckled mobs
	if(ismob(AM))
		var/mob/M = AM
		if(M.buckled)
			var/mob/buckled_to = M.buckled
			if((!ismob(M.buckled) || (buckled_to.buckled != M)) && !droppable(M.buckled))
				return FALSE
		// Check for wormhole jaunter
		if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			if(istype(H.belt, /obj/item/wormhole_jaunter))
				var/obj/item/wormhole_jaunter/J = H.belt
				H.visible_message(span_boldwarning("[H] falls into the [parent]!"))
				J.chasm_react(H)
				return FALSE
	return TRUE

/datum/component/door_dimension_void/proc/drop(atom/movable/AM)
	// Make sure the atom is still there
	if(!AM || QDELETED(AM))
		return

	// Mark as falling
	falling_atoms[AM] = TRUE

	// Visual feedback - only show generic message if not trapped in repentance
	var/is_trapped = FALSE
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		is_trapped = IsTrappedInRepentance(H)

	if(!is_trapped)
		AM.visible_message(span_boldwarning("[AM] falls into the reality void!"), span_userdanger("You feel yourself being pulled back to your own dimension!"))
	else
		AM.visible_message(span_boldwarning("[AM] falls into the reality void!"))

	// Animate the fall
	if(isliving(AM))
		var/mob/living/L = AM
		L.notransform = TRUE
		L.Stun(20) // 2 seconds - match the animation duration

	// Falling animation - removed transform manipulation to fix reset bug
	var/oldcolor = AM.color
	var/oldalpha = AM.alpha
	var/oldpixel_y = AM.pixel_y
	animate(AM, alpha = 0, color = rgb(85, 26, 139), pixel_y = AM.pixel_y - 10, time = 10) // Purple fade with downward movement

	for(var/i in 1 to 5)
		if(!AM || QDELETED(AM))
			// Reset appearance if interrupted
			if(AM)
				AM.alpha = oldalpha
				AM.color = oldcolor
				AM.pixel_y = oldpixel_y
				if(isliving(AM))
					var/mob/living/L = AM
					L.notransform = FALSE
			falling_atoms -= AM
			return
		sleep(2)

	// Make sure still exists
	if(!AM || QDELETED(AM))
		falling_atoms -= AM
		return

	// Always reset appearance before processing
	AM.alpha = oldalpha
	AM.color = oldcolor
	AM.pixel_y = oldpixel_y

	// Teleport out instead of killing
	if(isliving(AM))
		var/mob/living/L = AM
		L.notransform = FALSE

		// Use global repentance dimension rescue system
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(IsTrappedInRepentance(H))
				RescueFromRepentanceDimension(H, null, "The void expels you back to reality!")
				// Return early - rescue is complete
				falling_atoms -= AM
				return

		// Not trapped or not human - just teleport them somewhere safe
		var/turf/destination
		var/list/possible_turfs = list()
		for(var/turf/T in GLOB.station_turfs)
			if(T.density)
				continue
			possible_turfs += T
		if(length(possible_turfs))
			destination = pick(possible_turfs)
		else
			destination = get_turf(parent)

		to_chat(L, span_warning("The void rejects you, spitting you back out!"))
		L.forceMove(destination)
		playsound(destination, 'sound/effects/phasein.ogg', 50, TRUE)
	else if(isobj(AM))
		// Objects just get destroyed
		qdel(AM)

	falling_atoms -= AM
