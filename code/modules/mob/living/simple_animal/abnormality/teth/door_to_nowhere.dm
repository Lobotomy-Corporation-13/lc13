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

	var/list/trapped_employees = list()
	var/list/original_locations = list()
	var/list/backrooms_locations = list()
	var/list/backrooms_effects = list() // Track status effects

	// Spirit projection ability variable
	var/projecting_spirit = FALSE

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Initialize()
	. = ..()
	// Grant abilities
	var/datum/action/innate/targeted_whisper/whisper_ability = new
	whisper_ability.Grant(src)

	var/datum/action/innate/door_possession/possess_ability = new
	possess_ability.Grant(src)

	// Find all backrooms landmarks
	for(var/obj/effect/landmark/backrooms_spawn/L in GLOB.landmarks_list)
		backrooms_locations += get_turf(L)

	// Fallback if no landmarks exist
	if(!LAZYLEN(backrooms_locations))
		var/turf/T = locate(1, 1, z)
		if(T)
			backrooms_locations += T
		else
			backrooms_locations += get_turf(src)

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

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()
	// Handle Repression work - rescue trapped employees
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		if(LAZYLEN(trapped_employees))
			var/mob/living/carbon/human/rescued = pick(trapped_employees)
			RescueFromBackrooms(rescued)
			to_chat(user, span_notice("You manage to pull [rescued] back from that strange place!"))
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
	// 70% chance to send to backrooms on bad work (except Repression)
	if(work_type != ABNORMALITY_WORK_REPRESSION && prob(70))
		SendToBackrooms(user)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/SendToBackrooms(mob/living/carbon/human/H)
	if(!H || (H in trapped_employees))
		return

	trapped_employees += H
	original_locations[H] = get_turf(H)

	to_chat(H, span_userdanger("The door's chains rattle violently as it pulls you into a realm of sealed memories!"))
	playsound(get_turf(H), 'sound/abnormalities/dinner_chair/ragdoll_effect.ogg', 75, TRUE)

	// Apply violent spinning effect
	INVOKE_ASYNC(src, PROC_REF(ViolentSpin), H)

	// Wait for the spinning to finish before teleporting
	addtimer(CALLBACK(src, PROC_REF(FinishTeleport), H), 12 SECONDS)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/ViolentSpin(mob/living/M)
	if(!M)
		return

	var/matrix/initial_matrix = matrix(M.transform)
	// 10x more extreme than disco dance
	for(var/i in 1 to 120) // 12 seconds worth at 0.1 second intervals
		if(!M || QDELETED(M))
			return

		// Violent rotation
		initial_matrix = matrix(M.transform)
		initial_matrix.Turn(rand(45, 180)) // Random violent turns

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

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/FinishTeleport(mob/living/carbon/human/H)
	if(!H || !(H in trapped_employees))
		return

	to_chat(H, span_warning("You find yourself in a liminal space of forgotten memories. The walls echo with regrets that were never voiced, sealed away behind countless doors."))
	to_chat(H, span_warning("Each door you see is chained shut, hiding moments that someone desperately wanted to forget."))

	playsound(get_turf(H), 'sound/effects/podwoosh.ogg', 50, TRUE)

	// Pick a random backrooms location
	var/turf/destination = pick(backrooms_locations)
	H.forceMove(destination)

	H.Stun(30)
	H.adjustSanityLoss(20)

	// Apply backrooms status effect
	var/datum/status_effect/backrooms_ambience/B = H.apply_status_effect(/datum/status_effect/backrooms_ambience)
	if(B)
		backrooms_effects[H] = B

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/RescueFromBackrooms(mob/living/carbon/human/H)
	if(!H || !(H in trapped_employees))
		return

	trapped_employees -= H
	var/turf/return_turf = original_locations[H]
	if(!return_turf)
		return_turf = get_turf(src)

	original_locations -= H

	// Remove status effect
	if(backrooms_effects[H])
		H.remove_status_effect(/datum/status_effect/backrooms_ambience)
		backrooms_effects -= H

	to_chat(H, span_nicegreen("You feel a pull back to reality!"))
	playsound(get_turf(H), 'sound/magic/teleport_app.ogg', 50, TRUE)

	H.forceMove(return_turf)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/ZeroQliphoth(mob/living/carbon/human/user)
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		if(H in trapped_employees)
			continue
		if(!H.mind)
			continue
		potential_victims += H

	if(!LAZYLEN(potential_victims))
		return

	var/victims_count = min(rand(1, 3), LAZYLEN(potential_victims))

	for(var/i in 1 to victims_count)
		if(!LAZYLEN(potential_victims))
			break
		var/mob/living/carbon/human/victim = pick_n_take(potential_victims)
		SendToBackrooms(victim)
		to_chat(victim, span_userdanger("The door has dragged you behind its threshold, into the realm of sealed regrets!"))

	visible_message(span_danger("[src]'s chains burst open momentarily, releasing waves of forgotten regrets before sealing shut once more."))
	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Destroy()
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
	return ..()

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/death(gibbed)
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
		to_chat(H, span_notice("With the door shattered, the sealed memories dissipate and you are freed from that forsaken realm."))
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

// Backrooms landmark for mapping
/obj/effect/landmark/backrooms_spawn
	name = "backrooms spawn"
	icon_state = "x2"

/area/fishboat/backrooms
	name = "???"

// Status effect for ambient backrooms audio
/datum/status_effect/backrooms_ambience
	id = "backrooms_ambience"
	duration = -1 // Permanent until removed
	alert_type = null
	var/next_sound_time = 0

/datum/status_effect/backrooms_ambience/tick()
	if(world.time >= next_sound_time)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
			to_chat(H, span_warning("You hear whispers of regrets... memories trying to claw their way back into existence."))
		// Next sound in 5-10 minutes (converted to deciseconds)
		next_sound_time = world.time + rand(3000, 6000) // 300-600 seconds = 5-10 minutes

/datum/status_effect/backrooms_ambience/on_apply()
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
	var/door_name = ""
	var/door_desc = ""
	var/spirit_name = ""
	var/spirit_desc = ""
	var/mob/living/simple_animal/hostile/regret_spirit/associated_spirit

/obj/structure/regret_door/Initialize()
	. = ..()
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
	// Find all valid turfs in the backrooms area
	var/list/valid_turfs = list()
	for(var/turf/T in range(10, src))
		if(istype(T.loc, /area/fishboat/backrooms) && !T.density)
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

/obj/structure/regret_door/Destroy()
	if(associated_spirit)
		qdel(associated_spirit)
	return ..()

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
	maxHealth = 100
	health = 100
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

	// Store original body reference
	var/mob/living/original_body = src

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

	// Set timer to return
	addtimer(CALLBACK(src, PROC_REF(recall_spirit), P, original_body), 30 SECONDS)

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
		source_door.SendToBackrooms(owner)
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
	health = 50  // Fragile
	maxHealth = 50
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
	// Prevent infinite loops
	if(falling_atoms[AM] && falling_atoms[AM] > 30)
		return FALSE
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

	falling_atoms[AM] = (falling_atoms[AM] || 0) + 1

	// Visual feedback
	AM.visible_message(span_boldwarning("[AM] falls into the reality void!"), span_userdanger("You feel yourself being pulled back to your own dimension!"))

	// Animate the fall
	if(isliving(AM))
		var/mob/living/L = AM
		L.notransform = TRUE
		L.Paralyze(40) // 4 seconds

	// Falling animation
	var/oldtransform = AM.transform
	var/oldcolor = AM.color
	var/oldalpha = AM.alpha
	var/oldpixel_y = AM.pixel_y
	animate(AM, transform = matrix() - matrix(), alpha = 0, color = rgb(85, 26, 139), time = 10) // Purple fade

	for(var/i in 1 to 5)
		if(!AM || QDELETED(AM))
			// Reset appearance if interrupted
			if(AM)
				AM.alpha = oldalpha
				AM.color = oldcolor
				AM.transform = oldtransform
				AM.pixel_y = oldpixel_y
			return
		AM.pixel_y--
		sleep(2)

	// Make sure still exists
	if(!AM || QDELETED(AM))
		return

	// Always reset appearance before processing
	AM.alpha = oldalpha
	AM.color = oldcolor
	AM.transform = oldtransform
	AM.pixel_y = oldpixel_y

	// Teleport out instead of killing
	if(isliving(AM))
		var/mob/living/L = AM
		L.notransform = FALSE

		// Find ANY Door to Nowhere abnormality (even without datum_reference)
		var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/door = null
		for(var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/D in GLOB.abnormality_mob_list)
			door = D
			if(D.datum_reference) // Prefer one with datum
				break

		// If they're trapped and there's a door, use the rescue proc
		if(door && ishuman(L) && (L in door.trapped_employees))
			door.RescueFromBackrooms(L)
			to_chat(L, span_warning("The void expels you back to reality!"))
			// RescueFromBackrooms handles the teleport and effects
		else
			// Not trapped - need to manually clean up and teleport
			var/turf/destination

			// Check if they have backrooms status effect and remove it
			if(ishuman(L))
				var/mob/living/carbon/human/H = L
				if(H.has_status_effect(/datum/status_effect/backrooms_ambience))
					H.remove_status_effect(/datum/status_effect/backrooms_ambience)

				// Clean up from any door's tracking lists
				if(door)
					if(H in door.trapped_employees)
						door.trapped_employees -= H
					if(H in door.original_locations)
						door.original_locations -= H
					if(H in door.backrooms_effects)
						door.backrooms_effects -= H

			// Find destination
			if(door && door.datum_reference && door.datum_reference.landmark)
				destination = get_turf(door.datum_reference.landmark)
			else
				// Fallback to random teleport
				var/list/possible_turfs = list()
				for(var/turf/T in GLOB.station_turfs)
					if(T.density)
						continue
					possible_turfs += T
				if(length(possible_turfs))
					destination = pick(possible_turfs)

			if(destination)
				to_chat(L, span_warning("You are expelled from the door's dimension!"))
				L.forceMove(destination)
				playsound(destination, 'sound/effects/phasein.ogg', 50, TRUE)
			else
				// Emergency fallback - just move them up if we can't find anywhere
				L.forceMove(get_turf(parent))
				to_chat(L, span_warning("The void rejects you, spitting you back out!"))
	else if(isobj(AM))
		// Objects just get destroyed
		qdel(AM)

	falling_atoms -= AM
