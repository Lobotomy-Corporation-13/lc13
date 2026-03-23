// ============================================================
// Path Realm — Thematic Path Selection System
// ============================================================
// Teleports the player to a dedicated realm where they meet
// echoes of themselves, answer personality questions, and
// discover which Path resonates with their will.
// ============================================================

// ---- Area ----

/area/path_realm
	name = "???"
	icon_state = "away"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE

// ---- Landmarks ----

/obj/effect/landmark/path_realm
	name = "path realm landmark"
	icon_state = "yourstate"
	invisibility = INVISIBILITY_ABSTRACT

/obj/effect/landmark/path_realm/spawn
	name = "path realm spawn"

/obj/effect/landmark/path_realm/npc_1
	name = "path realm npc 1"

/obj/effect/landmark/path_realm/npc_2
	name = "path realm npc 2"

/obj/effect/landmark/path_realm/npc_3
	name = "path realm npc 3"

/obj/effect/landmark/path_realm/npc_4
	name = "path realm npc 4"

/obj/effect/landmark/path_realm/npc_5
	name = "path realm npc 5"

/obj/effect/landmark/path_realm/npc_6
	name = "path realm npc 6"

/obj/effect/landmark/path_realm/npc_7
	name = "path realm npc 7"

/obj/effect/landmark/path_realm/sword
	name = "path realm sword"

// ---- Questions ----
// Each question is a list: list(prompt, list(choice1, choice2, ...))
// Each choice is a list: list(text, list(path = points, ...))

/proc/GetPathQuestions()
	return list(
		list(
			"The universe stretches before you, vast and unknowable. What do you see?",
			list(
				list("A mistake waiting to be corrected.", list("Destruction" = 3)),
				list("An infinite equation begging to be solved.", list("Erudition" = 3)),
				list("A chorus of voices yearning to sing as one.", list("Harmony" = 3)),
				list("Nothing. And that is the only truth.", list("Nihility" = 3))
			)
		),
		list(
			"A plague spreads across a world. Millions suffer, yet the afflicted live forever, twisted beyond recognition. What is the answer?",
			list(
				list("Hunt down the source and eradicate it, no matter the cost.", list("The Hunt" = 3)),
				list("Heal what can be healed. Life must persist.", list("Abundance" = 3)),
				list("Build walls. Quarantine the afflicted to save the rest.", list("Preservation" = 3)),
				list("Let it run its course. Entropy claims all eventually.", list("Nihility" = 2, "Destruction" = 1))
			)
		),
		list(
			"You are given the power to reshape one thing in the world. What do you change?",
			list(
				list("I would tear down every unjust structure and start over.", list("Destruction" = 3)),
				list("I would uncover every hidden truth, no matter how painful.", list("Erudition" = 2, "Nihility" = 1)),
				list("I would unite every fractured people into one melody.", list("Harmony" = 3)),
				list("I would ensure no one ever suffers from illness again.", list("Abundance" = 2, "Preservation" = 1))
			)
		),
		list(
			"A comrade is corrupted by a power beyond their control. They beg you for help, but the corruption spreads to all they touch.",
			list(
				list("End their suffering. A clean death is mercy.", list("The Hunt" = 2, "Destruction" = 1)),
				list("Find a cure. There must be an answer somewhere.", list("Erudition" = 2, "Abundance" = 1)),
				list("Isolate them. Protect everyone else first.", list("Preservation" = 3)),
				list("Stand beside them anyway. No one should face this alone.", list("Harmony" = 2, "Abundance" = 1))
			)
		),
		list(
			"You stand at the edge of an abyss. Something gazes back. What do you feel?",
			list(
				list("Rage. I will not be consumed.", list("Destruction" = 2, "The Hunt" = 1)),
				list("Curiosity. What lies beyond the darkness?", list("Erudition" = 3)),
				list("Nothing. The void is familiar.", list("Nihility" = 3)),
				list("Resolve. I must build a barrier to keep others safe.", list("Preservation" = 3))
			)
		),
		list(
			"A war rages that cannot be won. Both sides have lost everything. What do you do?",
			list(
				list("Keep fighting. To stop now would make their sacrifice meaningless.", list("Destruction" = 3)),
				list("Track down the one who started it and end them.", list("The Hunt" = 3)),
				list("Broker peace. The strong must help the weak, or all is lost.", list("Harmony" = 3)),
				list("Tend to the wounded. That is all that matters now.", list("Abundance" = 3))
			)
		),
		list(
			"If you could hear the voice of a god, what would you want them to say?",
			list(
				list("Nothing. Gods are meant to be surpassed.", list("Destruction" = 2, "Nihility" = 1)),
				list("The answer to every question I have ever asked.", list("Erudition" = 3)),
				list("You are not alone.", list("Harmony" = 2, "Abundance" = 1)),
				list("I will keep you safe.", list("Preservation" = 3))
			)
		)
	)

// ---- Aeon Voice Lines ----

/proc/GetAeonVoiceLines(path_name)
	switch(path_name)
		if("Destruction")
			return list(
				"The birth of the universe is a mistake.",
				"...",
				"If civilization is a cancer emerging quietly from the boundless stars...",
				"Then war is the only common language known to all intelligent life.",
				"Destruction is not a process, but the outcome.",
				"All Paths and Aeons will terminate in the heat death of the universe.",
				"To welcome the new... first embrace the end.",
				"Rise, Pathstrider."
			)
		if("The Hunt")
			return list(
				"With no end to hate and no boundaries to war...",
				"How much concern do you shoulder?",
				"With determined eyes and the arrow drawn...",
				"The Reignbow Arbiter needs not turn back.",
				"...",
				"Salvation and ruin blur where the Lux Arrow flies.",
				"The arrow is drawn.",
				"Rise, Pathstrider. Do not look back."
			)
		if("Erudition")
			return list(
				"If the truth of the universe is cruel and stale...",
				"Would you still yearn for the answer to the ultimate question?",
				"...",
				"Knowledge seekers know not how to judge.",
				"For their core is cold and unwavering.",
				"All things bear unanswered questions. And there is an answer to everything.",
				"Every step taken was already within the calculations.",
				"Rise, Pathstrider. The question awaits."
			)
		if("Harmony")
			return list(
				"The world is in harmony and the stars shine bright.",
				"All are connected.",
				"The wind of blessing breathes across the lands.",
				"...",
				"To battle the brutality of the universe, the strong must help the weak.",
				"Protect life with death. Fuse into one singular melody.",
				"The hymn spreads to all corners of the world.",
				"Rise, Pathstrider. The melody continues."
			)
		if("Nihility")
			return list(
				"You may gaze deep into the vast grandeur of the stars...",
				"But do not glance at the abyss of the void.",
				"...",
				"For it holds nothing.",
				"...",
				"The ultimate fate of the multiverse is nothingness. And therefore... worthless.",
				"...",
				"Rise, Pathstrider. Or do not. It matters little."
			)
		if("Preservation")
			return list(
				"Build a wall.",
				"...",
				"Shield the weak.",
				"The hammer falls. A new amber era is heralded. The living worlds endure.",
				"What was separated shall remain separated. What was sealed shall remain sealed.",
				"The Dusk Wars ended. The Celestial Comet Wall still stands. As it always will.",
				"...The hammer falls once more.",
				"Rise, Pathstrider. You are the guardian now."
			)
		if("Abundance")
			return list(
				"The flowers share their petals without care, waiting for their inevitable withering.",
				"The birds fly high in song, moving toward their inevitable fall.",
				"The streams flow rapidly with life, toward where they inevitably run dry.",
				"...",
				"Why must all things come to an end?",
				"There must be a miracle somewhere that can cure the disease known as finality.",
				"All prayers are answered. All suffering is answered.",
				"Rise, Pathstrider. Let life persist. No matter the consequence."
			)
	return list("...", "Rise, Pathstrider.")

// ---- Global Lock ----
/// Only one path realm can exist at a time
GLOBAL_VAR(path_realm_active)

// ---- Path Realm Datum ----

/datum/path_realm
	/// The mob currently in the realm (the clone)
	var/mob/living/carbon/human/player
	/// The original body that is asleep
	var/mob/living/carbon/human/original_body
	var/turf/return_turf
	var/z_level
	var/list/question_scores = list()
	var/current_question = 0
	var/list/questions
	var/list/landmark_turfs = list()
	var/turf/sword_turf
	var/mob/living/simple_animal/hostile/path_npc/current_npc
	var/determined_path
	var/turf/sparkle_target
	var/active = TRUE

/datum/path_realm/New(mob/living/carbon/human/H)
	original_body = H
	return_turf = get_turf(H)
	questions = GetPathQuestions()
	GLOB.path_realm_active = src
	// Initialize scores
	for(var/pname in list("Destruction", "The Hunt", "Erudition", "Harmony", "Nihility", "Preservation", "Abundance"))
		question_scores[pname] = 0

/datum/path_realm/Destroy()
	GLOB.path_realm_active = null
	if(player && !QDELETED(player))
		qdel(player) // Delete the clone
	player = null
	original_body = null
	return_turf = null
	if(current_npc && !QDELETED(current_npc))
		qdel(current_npc)
	return ..()

/datum/path_realm/proc/Start()
	set waitfor = FALSE
	if(!original_body?.client || !original_body.mind)
		qdel(src)
		return

	// Put the real body to sleep and protect it
	to_chat(original_body, span_nicegreen("<b>Your vision blurs... the cosmos calls to you...</b>"))
	original_body.Sleeping(9999)
	original_body.status_flags |= GODMODE
	// Make all items on the body undroppable
	for(var/obj/item/I in original_body.GetAllContents())
		ADD_TRAIT(I, TRAIT_NODROP, "path_realm")

	// Load the realm map as a new Z-level
	var/datum/map_template/realm = new("_maps/templates/path_realm.dmm", "Path Realm")
	realm.load_new_z()

	// Find the newly loaded Z-level by finding the latest spawn landmark
	// (most recently created will be on the newest Z-level)
	var/turf/spawn_turf
	var/highest_z = 0
	for(var/obj/effect/landmark/path_realm/spawn/LM in GLOB.landmarks_list)
		var/turf/LT = get_turf(LM)
		if(LT && LT.z > highest_z)
			highest_z = LT.z
			spawn_turf = LT

	if(!spawn_turf)
		original_body.SetSleeping(0)
		qdel(src)
		return

	z_level = spawn_turf.z

	// Find sword landmark on the same Z-level
	for(var/obj/effect/landmark/path_realm/sword/LM in GLOB.landmarks_list)
		var/turf/LT = get_turf(LM)
		if(LT && LT.z == z_level)
			sword_turf = LT
			break

	// Collect NPC landmarks in order, filtered by Z-level
	for(var/i in 1 to 7)
		var/landmark_type = text2path("/obj/effect/landmark/path_realm/npc_[i]")
		for(var/obj/effect/landmark/path_realm/LM in GLOB.landmarks_list)
			if(istype(LM, landmark_type))
				var/turf/LT = get_turf(LM)
				if(LT && LT.z == z_level)
					landmark_turfs += LT
					break

	// Create clone at spawn point
	player = new /mob/living/carbon/human(spawn_turf)

	// Copy body appearance via DNA transfer
	player.real_name = original_body.real_name
	player.name = original_body.name
	player.gender = original_body.gender
	if(original_body.dna)
		original_body.dna.transfer_identity(player)
	player.underwear = original_body.underwear
	player.eye_color = original_body.eye_color
	player.hairstyle = original_body.hairstyle
	player.hair_color = original_body.hair_color
	player.facial_hairstyle = original_body.facial_hairstyle
	player.facial_hair_color = original_body.facial_hair_color
	player.updateappearance()

	// Copy suit, shoes, and gloves
	var/obj/item/clothing/suit/worn_suit = original_body.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(worn_suit)
		var/obj/item/S = new worn_suit.type()
		player.equip_to_slot_or_del(S, ITEM_SLOT_OCLOTHING, TRUE)
	var/obj/item/clothing/shoes/worn_shoes = original_body.get_item_by_slot(ITEM_SLOT_FEET)
	if(worn_shoes)
		var/obj/item/SH = new worn_shoes.type()
		player.equip_to_slot_or_del(SH, ITEM_SLOT_FEET, TRUE)
	var/obj/item/clothing/gloves/worn_gloves = original_body.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(worn_gloves)
		var/obj/item/G = new worn_gloves.type()
		player.equip_to_slot_or_del(G, ITEM_SLOT_GLOVES, TRUE)
	// Copy uniform too (needed for suit to display)
	var/obj/item/clothing/under/worn_uniform = original_body.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(worn_uniform)
		var/obj/item/U = new worn_uniform.type()
		player.equip_to_slot_or_del(U, ITEM_SLOT_ICLOTHING, TRUE)

	// Transfer mind to clone
	original_body.mind.transfer_to(player)

	// Start looping background music
	StartRealmMusic()

	to_chat(player, span_nicegreen("<b>You feel the cosmos shifting around you...</b>"))
	to_chat(player, span_nicegreen("<i>Echoes of yourself await. Walk towards the light.</i>"))

	// Start first question
	addtimer(CALLBACK(src, PROC_REF(SpawnNextNPC)), 2 SECONDS)

/datum/path_realm/proc/SpawnNextNPC()
	if(!active || QDELETED(player))
		return
	current_question++
	if(current_question > length(questions) || current_question > length(landmark_turfs))
		// All questions done — determine path
		DeterminePath()
		return

	var/turf/npc_turf = landmark_turfs[current_question]

	// Spawn NPC that looks like the player
	current_npc = new(npc_turf)
	current_npc.CopyAppearanceFrom(player)
	current_npc.setDir(NORTH)
	current_npc.linked_realm = src
	current_npc.question_index = current_question

	// Create sparkle trail from player to NPC
	CreateSparkleTrail(get_turf(player), npc_turf)

/datum/path_realm/proc/CreateSparkleTrail(turf/start, turf/end)
	sparkle_target = end
	SparkleLoop(end)

/// Loops the sparkle trail every 10 seconds, updating start from player position
/datum/path_realm/proc/SparkleLoop(turf/end)
	if(QDELETED(src) || !active)
		return
	if(sparkle_target != end)
		return // Target changed, stop this loop
	var/turf/start = get_turf(player)
	if(!start)
		return
	var/list/line = getline(start, end)
	var/delay = 0
	for(var/turf/T in line)
		addtimer(CALLBACK(src, PROC_REF(SpawnSparkle), T), delay)
		delay += 1
	// Repeat after 10 seconds
	addtimer(CALLBACK(src, PROC_REF(SparkleLoop), end), 10 SECONDS)

/datum/path_realm/proc/SpawnSparkle(turf/T)
	if(QDELETED(src) || !active)
		return
	new /obj/effect/temp_visual/path_sparkle(T)

/datum/path_realm/proc/OnQuestionAnswered(question_index, choice_index)
	if(!active)
		return
	var/list/question = questions[question_index]
	var/list/choices = question[2]
	var/list/chosen = choices[choice_index]
	var/list/scores = chosen[2]

	// Add scores
	for(var/pname in scores)
		question_scores[pname] += scores[pname]

	// Remove NPC
	if(current_npc && !QDELETED(current_npc))
		qdel(current_npc)
		current_npc = null

	// Next question after brief pause
	addtimer(CALLBACK(src, PROC_REF(SpawnNextNPC)), 1.5 SECONDS)

/datum/path_realm/proc/DeterminePath()
	// Find highest scoring path
	var/best_path = "Destruction"
	var/best_score = 0
	for(var/pname in question_scores)
		if(question_scores[pname] > best_score)
			best_score = question_scores[pname]
			best_path = pname

	determined_path = best_path
	to_chat(player, span_nicegreen("<b>The echoes converge... Your path becomes clear.</b>"))
	to_chat(player, span_nicegreen("<i>The Path of [best_path] resonates with your will.</i>"))

	// Spawn sword structure
	if(sword_turf)
		var/obj/structure/path_sword/S = new(sword_turf)
		S.linked_realm = src
		CreateSparkleTrail(get_turf(player), sword_turf)

/datum/path_realm/proc/OnSwordPulled()
	if(!active || !determined_path)
		return
	active = FALSE

	// Flash the Aeon's image across the clone's screen
	FlashAeonImage()

	// Return mind to original body after the Aeon flash
	addtimer(CALLBACK(src, PROC_REF(ReturnPlayer)), 3 SECONDS)

/// Flashes the Aeon's image across the player's screen
/datum/path_realm/proc/FlashAeonImage()
	if(!player?.client || !determined_path)
		return
	var/list/aeon_icons = list(
		"Destruction" = "nanook",
		"The Hunt" = "lan",
		"Erudition" = "nous",
		"Harmony" = "xipe",
		"Nihility" = "IX",
		"Preservation" = "qlipoth",
		"Abundance" = "yaoshi"
	)
	var/icon_state = aeon_icons[determined_path]
	if(!icon_state)
		return

	var/obj/effect/overlay/aeon = new()
	aeon.icon = 'ModularLobotomy/_Lobotomyicons/ender_sprites_aeons.dmi'
	aeon.icon_state = icon_state
	aeon.layer = FLOAT_LAYER
	aeon.plane = ABOVE_HUD_PLANE
	aeon.alpha = 0
	aeon.screen_loc = "CENTER-7,CENTER-7"
	aeon.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	aeon.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

	player.client.screen += aeon
	// Fade in over 0.5s
	animate(aeon, alpha = 200, time = 5)

	// Play Aeon entry sound and stop realm music
	StopRealmMusic()
	PlayAeonEntrySound()

	// Hold for 1.5s then fade out
	addtimer(CALLBACK(src, PROC_REF(FadeAeonImage), aeon), 15)

/// Fades out and removes the Aeon image
/datum/path_realm/proc/FadeAeonImage(obj/effect/overlay/aeon)
	if(!aeon || !player?.client)
		return
	animate(aeon, alpha = 0, time = 10)
	addtimer(CALLBACK(src, PROC_REF(RemoveAeonImage), aeon), 10)

/// Removes the Aeon image from the screen
/datum/path_realm/proc/RemoveAeonImage(obj/effect/overlay/aeon)
	if(!aeon)
		return
	if(player?.client)
		player.client.screen -= aeon
	qdel(aeon)

// ---- Music & Sound ----

#define PATH_REALM_SOUND_CHANNEL 1015

/// Starts looping the path realm background music
/datum/path_realm/proc/StartRealmMusic()
	if(!player?.client)
		return
	var/sound/music = sound('ModularLobotomy/enders_gimmicks/paths/path_sounds/path_realm.ogg', repeat = TRUE, channel = PATH_REALM_SOUND_CHANNEL)
	music.volume = 50
	SEND_SOUND(player, music)

/// Stops the path realm background music
/datum/path_realm/proc/StopRealmMusic()
	if(!player?.client)
		return
	var/sound/stop = sound(null, channel = PATH_REALM_SOUND_CHANNEL)
	SEND_SOUND(player, stop)

/// Plays the Aeon's entry sound effect
/datum/path_realm/proc/PlayAeonEntrySound()
	if(!player?.client || !determined_path)
		return
	var/list/aeon_sounds = list(
		"Destruction" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_nanook.ogg',
		"The Hunt" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_lan.ogg',
		"Erudition" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_nous.ogg',
		"Harmony" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_xipe.ogg',
		"Nihility" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_ix.ogg',
		"Preservation" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_qlipoth.ogg',
		"Abundance" = 'ModularLobotomy/enders_gimmicks/paths/path_sounds/entry_sound_yaoshi.ogg'
	)
	var/snd = aeon_sounds[determined_path]
	if(snd)
		SEND_SOUND(player, sound(snd, volume = 70))

/datum/path_realm/proc/ReturnPlayer()
	if(!original_body || QDELETED(original_body))
		qdel(src)
		return

	// Stop any lingering music
	StopRealmMusic()

	// Transfer mind back to original body
	if(player?.mind)
		player.mind.transfer_to(original_body)

	// Delete the clone
	if(player && !QDELETED(player))
		qdel(player)
	player = null

	// Remove protections and wake up original body
	original_body.status_flags &= ~GODMODE
	for(var/obj/item/I in original_body.GetAllContents())
		REMOVE_TRAIT(I, TRAIT_NODROP, "path_realm")
	original_body.SetSleeping(0)
	to_chat(original_body, span_nicegreen("<b>You awaken... the cosmos still echoes in your mind.</b>"))

	// Grant path after a brief delay
	addtimer(CALLBACK(src, PROC_REF(GrantPathDelayed)), 2 SECONDS)

/// Grants the determined path on the original body
/datum/path_realm/proc/GrantPathDelayed()
	if(!original_body || QDELETED(original_body) || !determined_path)
		qdel(src)
		return

	var/list/path_map = list(
		"Destruction" = /datum/path/destruction,
		"The Hunt" = /datum/path/hunt,
		"Erudition" = /datum/path/erudition,
		"Nihility" = /datum/path/nihility,
	)
	var/path_type = path_map[determined_path]
	if(path_type)
		original_body.GrantPath(path_type)
		to_chat(original_body, span_nicegreen("<b>You are now a Pathstrider of [determined_path].</b>"))
		to_chat(original_body, span_nicegreen("You return from the realm of Paths, forever changed."))
	qdel(src)

// ---- Path NPC ----

/mob/living/simple_animal/hostile/path_npc
	name = "Echo"
	desc = "An echo of yourself, shimmering with imaginary energy."
	icon = 'icons/mob/human.dmi'
	icon_state = "human"
	icon_living = "human"
	maxHealth = 9999
	health = 9999
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	faction = list("neutral")
	a_intent = INTENT_HELP
	stat_attack = CONSCIOUS
	move_resist = MOVE_FORCE_STRONG // They kept stealing my abnormalities
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE // Please. I beg you. Stop stealing my vending machines.
	mob_size = MOB_SIZE_HUGE // No more lockers, Whitaker
	wander = FALSE
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON

	var/datum/path_realm/linked_realm
	var/question_index = 0

/// Copy the full appearance of a human mob (body + outfit)
/mob/living/simple_animal/hostile/path_npc/proc/CopyAppearanceFrom(mob/living/carbon/human/H)
	var/icon/flat = getFlatIcon(H, no_anim = TRUE)
	if(flat)
		icon = flat
		icon_state = ""
		icon_living = ""
	name = "Echo of [H.name]"

/mob/living/simple_animal/hostile/path_npc/attack_hand(mob/living/user)
	if(!linked_realm || !linked_realm.active)
		return
	if(user != linked_realm.player)
		return

	var/list/questions = GetPathQuestions()
	if(question_index < 1 || question_index > length(questions))
		return

	var/list/question = questions[question_index]
	var/prompt = question[1]
	var/list/choices = question[2]

	// Build HTML window
	var/dat = "<center><h2>The Echo Speaks</h2></center>"
	dat += "<hr>"
	dat += "<center><i>[prompt]</i></center>"
	dat += "<br><br>"
	for(var/i in 1 to length(choices))
		var/list/choice = choices[i]
		dat += "<a href='byond://?src=[REF(src)];pick=[i]'>[choice[1]]</a><br><br>"

	var/datum/browser/popup = new(user, "path_echo", "The Echo Speaks", 450, 350)
	popup.set_content(dat)
	popup.open()

/mob/living/simple_animal/hostile/path_npc/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(!linked_realm?.active)
		return
	if(href_list["pick"])
		var/pick_index = text2num(href_list["pick"])
		if(pick_index)
			// Close the browser window
			usr << browse(null, "window=path_echo")
			linked_realm.OnQuestionAnswered(question_index, pick_index)

// ---- Path Sword Structure ----

/obj/structure/path_sword
	name = "crystallized blade"
	desc = "A blade embedded in crystallized imaginary energy. It pulses with power, waiting for one who walks a Path."
	icon = 'icons/obj/structures.dmi'
	icon_state = "icechunk"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

	var/datum/path_realm/linked_realm
	var/being_pulled = FALSE

/obj/structure/path_sword/Initialize()
	. = ..()
	update_icon()

/obj/structure/path_sword/update_overlays()
	. = ..()
	if(!being_pulled)
		. += "sword"

/obj/structure/path_sword/attack_hand(mob/living/user)
	if(!linked_realm || !linked_realm.active)
		return
	if(user != linked_realm.player)
		return
	if(being_pulled)
		return

	being_pulled = TRUE
	to_chat(user, span_nicegreen("<b>You grasp the blade and begin to pull...</b>"))

	// Play Aeon voice lines during the pull
	var/list/lines = GetAeonVoiceLines(linked_realm.determined_path)
	for(var/i in 1 to length(lines))
		var/line = lines[i]
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), user, span_nicegreen("<i>\"[line]\"</i>")), (i - 1) * 15)

	// Long do_after to pull the sword
	if(do_after(user, 10 SECONDS, target = src))
		to_chat(user, span_nicegreen("<b>The blade breaks free! Power surges through you!</b>"))
		// Screen shake
		for(var/mob/living/M in view(7, src))
			if(M.client)
				shake_camera(M, 5, 4)
		linked_realm.OnSwordPulled()
	else
		being_pulled = FALSE
		to_chat(user, span_warning("You release your grip on the blade..."))

// ---- Sparkle Trail Effect ----

/obj/effect/temp_visual/path_sparkle
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparkles"
	color = "#e7f712"
	duration = 30
	layer = ABOVE_MOB_LAYER
	randomdir = TRUE
