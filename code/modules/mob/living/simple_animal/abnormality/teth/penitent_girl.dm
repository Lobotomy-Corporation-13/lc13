#define STATUS_EFFECT_PENITENCE /datum/status_effect/penitence
//Sorry Lads, not much I can do here - Kirie
//I tried to improve it. - Coxswain



// TODO:
// TIMER TO DECREASE MOOD.
// MAYBE CHANGE HER BREACH TO BE MORE LIKE SIREN. aka MOVING THINGS TO LIFE() AND SHIT.
// MAYBE GIVE HER A SPECIAL MELTDOWN EFFECT? PERHAPS TANKING MOOD.
// INTERACTION WITH RED SHOES.
// USE REMEMBERVAR FOR SILLIER THINGS (I trust in you Future Me)
// MAKE A MANUAL STAT-GIVING PROC WHEN WORK IS PERFORMED ON HARDMODE
/mob/living/simple_animal/hostile/abnormality/penitentgirl
	name = "Penitent Girl"
	desc = "A girl with hair flowing over her eyes."
	icon = 'ModularTegustation/Teguicons/tegumobs.dmi'
	icon_state = "penitent"
	portrait = "penitent"
	maxHealth = 400
	health = 400
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	fear_level = 0
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = list(50, 70, 80, 80, 85),
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	is_flying_animal = TRUE
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom

	ego_list = list(
		/datum/ego_datum/weapon/sorrow,
		/datum/ego_datum/armor/sorrow,
	)
	gift_type =  /datum/ego_gifts/sorrow
	abnormality_origin = ABNORMALITY_ORIGIN_WONDERLAB

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/red_shoes = 5, // Teehee
		// /mob/living/simple_animal/hostile/abnormality/pink_shoes = 3  Would be nice...
	)

	var/mood_level = 0// From min_mood_level to max_mood_level
	var/min_mood_level = 0
	var/max_mood_level = 6
	var/mood = 0
	var/min_mood = 0
	var/max_mood = 2
	var/mood_level_change = 0 // This var exists just so we dont call ChangeMood() one billion times

	var/calmness_threshold = 5 // Equal or above this mood level, she is calm.
	var/tormented_threshold = 1 // Equal or below this mood level, she is tormented.
	var/mortified_threshold = -1 // Equal or below this mood level, she is in her special mood (Only available with Red Shoes.)
	var/empathize_threshold = 40

	var/qli_change = 0
	var/desire = FALSE // Is Red Shoes in the facility?
	var/haunting = FALSE

	var/mob/living/carbon/human/haunted
	var/datum/abnormality/the_shoes

	var/remember
	var/debug

	observation_prompt = "A girl in front of you dances, stumbling to and fro. <br>\
		Her feet are chopped off at the ankles, and yet they still move. <br>\
		You..."
	observation_choices = list(
		"Put on the shoes" = list(TRUE, "You remove the severed feet, and put on the shoes. <br>\
			It feels good. <br>You want to dance. <br>Please, chop off my feet."),
		"Don't put on the shoes" = list(FALSE, "How could you do something so gross? <br>\
			You leave the shoes where they are. <br>\
			The girl continues shifting about without a care in the world."),
	)

/mob/living/simple_animal/hostile/abnormality/penitentgirl/PostSpawn()
	. = ..()
	// debug = datum_reference.transferable_var
	// remember = RememberVar(1)
	// if(!LAZYLEN(remember))
	// 	CheckForShoes()
	// 	return
	mood = RememberVar("mood")
	if(!mood)
		mood = 0
	InitializeMoodLevel() // We are initializing mood after getting obliterated.
	desire = RememberVar("desire")
	if(!desire)
		CheckForShoes() // ARE THOSE FUCKING ACURSED SHOES IN HERE???
	the_shoes = RememberVar("red_shoes")
	if(!the_shoes)
		desire = FALSE // Just in case something went wrong.
		return
	Hardmode() // You, my friend, gonna have one extra HE abnormality.

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/Hardmode()
	datum_reference.max_boxes = 18
	min_mood = -1
	min_mood_level = -2
	max_mood_level = 5
	tormented_threshold = 2
	empathize_threshold = 60
	// icon = agitated_penitent

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/OnAbnoSpawn(datum/source, datum/abnormality/abno)
	SIGNAL_HANDLER
	if(abno.name == "Red Shoes")
		the_shoes = abno
		desire = TRUE
		ShoeWarning()
		UnregisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_SPAWN)

/mob/living/simple_animal/hostile/abnormality/penitentgirl/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/penitentgirl/CanAttack()
	return FALSE

// /mob/living/simple_animal/hostile/abnormality/penitentgirl/AttackingTarget(atom/attacked_target)
// 	return FALSE // NO MORE NUZZLES

/mob/living/simple_animal/hostile/abnormality/penitentgirl/Destroy()
	// var/list/PenitentVars = list(mood, desire, the_shoes)
	TransferVar("mood", mood) // This is gonna get silly.
	TransferVar("desire", desire)
	TransferVar("red_shoes", the_shoes)
	return ..()

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/CheckForShoes()
	if(LAZYLEN(SSlobotomy_corp.all_abnormality_datums))
		for(var/datum/abnormality/R in SSlobotomy_corp.all_abnormality_datums)
			if(ispath(R.abno_path, /mob/living/simple_animal/hostile/abnormality/red_shoes))
				the_shoes = R
				desire = TRUE
				ShoeWarning()
				return
	if(!the_shoes)
		RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_SPAWN, PROC_REF(OnAbnoSpawn)) // If there are no Red Shoes, we still are wary of it arriving at any moment.

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/ShoeWarning()
	sound_to_playing_players_on_level("sound/voice/human/femalescream_3.ogg", 90, zlevel = z) // Do not fucking say I did not warn you.
	for(var/mob/living/carbon/human/M in GLOB.player_list)
		var/check_z = M.z
		if(isatom(M.loc))
			check_z = M.loc.z // So it plays even when you are in a locker/sleeper
		if((check_z == z) && M.client)
			to_chat(M, span_userdanger("A horrified scream comes from inside [src]'s cell!!"))

//Work Mechanics
/mob/living/simple_animal/hostile/abnormality/penitentgirl/AttemptWork(mob/living/carbon/human/user, work_type)
	switch(work_type)
		if(ABNORMALITY_WORK_ATTACHMENT)
			if(haunting)
				to_chat(user, span_info("You cannot do this type of work while the abnormality is not present."))
				return FALSE // You are talking to an empty cell idiot.
			if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) >= empathize_threshold) // Stop being nice to the abno right NOW.
				work_damage_amount = user.maxSanity * (0.1 + (0.1 * mood)) // The more calm she is, the more she gets into your mind. (Max 40% of max Sanity as damage at max mood.)
		if(ABNORMALITY_WORK_INSTINCT)
			if(haunting)
				to_chat(user, span_info("You cannot do this type of work while the abnormality is not present."))
				return FALSE // You are feeding an empty cell dummy.
	/* My logic is that insight work can be cleaning the surroundings of the abnormality, not needing the abnormality to be necessarily present (but being a ghost, it still reacts and produces PE.)
	While repression work can be increasing the qliphoth supression or other esoteric procedures (repression is the weirdest work type in-lore) that again, do not necessarily require the abnormality physically present */
	return TRUE

/mob/living/simple_animal/hostile/abnormality/penitentgirl/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	work_damage_amount = initial(work_damage_amount)
	if((get_attribute_level(user, TEMPERANCE_ATTRIBUTE) < empathize_threshold) && (get_attribute_level(user, PRUDENCE_ATTRIBUTE) < empathize_threshold))
		ChangeMood(-(calmness_threshold)) // Brother in Christ, you are cooked.
		if(StartHaunting(user))
			user.adjustSanityLoss(400) // PENITENT BLAST!
		datum_reference.qliphoth_change(-999)
		return
	ChangeMood(mood_level_change)
	switch(work_type) // Boss, I am tired of using switch statements.
		if(ABNORMALITY_WORK_INSIGHT)
			if(haunting)
				haunted.adjustSanityLoss(-25)
				if(prob((mood + 1) * 15)) // 0% for mortified, 15% for tormented, 30% for neutral, 45% for good.
					StopHaunting()
		if(ABNORMALITY_WORK_ATTACHMENT)
			if(!haunting)
				qli_change -= 1
		if(ABNORMALITY_WORK_REPRESSION)
			if(haunting && !desire) // Brother in christ, if Red Shoes is in you are cooked.
				haunted.adjustSanityLoss(haunted.maxSanity * (0.5 - (mood * 0.1))) // Higher mood = less sanity damage.
				StopHaunting()
	datum_reference.qliphoth_change(qli_change)
	qli_change = initial(qli_change)

/mob/living/simple_animal/hostile/abnormality/penitentgirl/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) >= empathize_threshold && work_type == ABNORMALITY_WORK_ATTACHMENT)
		if(prob(30)) // Harder to raise the mood.
			mood_level_change += 3
		else if(prob(75))
			mood_level_change += 2
	ChangeMood(mood_level_change)
	return

/mob/living/simple_animal/hostile/abnormality/penitentgirl/NeutralEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(work_type == ABNORMALITY_WORK_ATTACHMENT)
		mood_level_change -= 1
	if(prob(50))
		mood_level_change -= 1
	ChangeMood(mood_level_change)

/mob/living/simple_animal/hostile/abnormality/penitentgirl/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(work_type == ABNORMALITY_WORK_ATTACHMENT) // You fucked up.
		mood_level_change -= 3
		qli_change -= 1
	mood_level_change -= 2

// Happiness Mechanics
/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/ChangeMood(variable)
	if(haunting)
		return // Nuh uh
	mood_level = clamp((mood_level + mood_level_change, min_mood_level, max_mood_level))
	mood_level_change = initial(mood_level_change)
	UpdateMoodEffects()

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/InitializeMoodLevel()
	switch(mood)
		if(-1) // Mortified
			mood_level = min_mood_level
		if(0) // Tormented
			mood_level = mortified_threshold + 1
		if(1) // Neutral
			mood_level = tormented_threshold + 1
		if(2) // Calm
			mood_level = calmness_threshold
	return

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/UpdateMoodEffects() // Remember to make icons for the different Penitent moods.
	if(mood_level >= calmness_threshold) // Calm
		mood = 2
	else if(mood_level > tormented_threshold) // Neutral
		mood = 1
	else if(mood_level > mortified_threshold) // Tormented
		mood = 0
	else if(desire) // Mortified, only reachable with Red Shoes on the facility.
		mood = -1
	return

// Breach Mechanics
/mob/living/simple_animal/hostile/abnormality/penitentgirl/ZeroQliphoth(mob/living/carbon/human/user)
	. = ..()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_ABNORMALITY_BREACH, src) // It's basically a breach, I just want people to be able to work while its ongoing.
	if(!haunting)
		if(user)
			StartHaunting(user)
		else
			var/list/potentialghostbearer = list()
			for(var/mob/living/carbon/human/L in GLOB.player_list)
				if(L.stat >= HARD_CRIT || z != L.z) // Dead, in hard crit or on a different Z level.
					continue
				potentialghostbearer += L
			StartHaunting(pick(potentialghostbearer))
	return

// Haunting Mechanics
/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/StartHaunting(mob/living/carbon/human/ghostbearer)
	haunting = TRUE
	switch(mood)
		if(0)
			to_chat(ghostbearer, span_warning("PLACEHOLDER BAD!"))
		if(1)
			to_chat(ghostbearer, span_info("PLACEHOLDER NEUTRAL!"))
		if(2)
			to_chat(ghostbearer, span_nicegreen("PLACEHOLDER GOOD!"))
	spooky = ghostbearer.apply_status_effect(STATUS_EFFECT_PENITENCE, src, mood)
	haunted = ghostbearer
	forceMove(ghostbearer)
	if(spooky)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/StopHaunting(mob/living/carbon/human/ghostbearer = haunted)
	haunting = FALSE
	if(ghostbearer)
		switch(mood)
			if(-1)
				to_chat(ghostbearer, span_nicegreen("The voices subside, your head stops hurting and your thoughts become clearer. You are safe."))
			if(0)
				to_chat(ghostbearer, span_nicegreen("The ominous presence stops following your every move. You feel safer."))
			if(1)
				to_chat(ghostbearer, span_info("You feel like a weight has beenlifted from your shoulders."))
			if(2)
				to_chat(ghostbearer, span_warning("The spirit bids you goodbye as she returns to her containment cell. You feel a bit sad."))
	datum_reference.qliphoth_change(start_qliphoth)
	EvilAxeDrop(ghostbearer)
	haunted = null
	mood = clamp((mood - 1), min_mood, max_mood)
	qdel(src)
	return

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/OverwhelmingDesire(mob/living/carbon/human/possessed)
	// possessed.apply_status_effect(STATUS_EFFECT_RETURNING_DESIRES)
	if(!possessed.sanity_lost)
		debug = "Okay this is fucked up"
	Relapse(possessed)

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/Relapse(mob/living/carbon/human/possessed)
	var/obj/item/held = possessed.get_active_held_item()
	var/obj/item/wep = new /obj/item/ego_weapon/wield/supressed(possessed) // Change this one for a new EGO weapon (Suppressed Desire)
	possessed.dropItemToGround(held) //Drop weapon
	ADD_TRAIT(wep, TRAIT_NODROP, wep)
	possessed.put_in_hands(wep, FALSE, FALSE, TRUE) // Time for evil ass black damage.

/mob/living/simple_animal/hostile/abnormality/penitentgirl/proc/EvilAxeDrop(mob/living/carbon/human/possessed)
	var/obj/item/ego_weapon/wield/supressed/axe
	axe = possessed.is_holding_item_of_type(/obj/item/ego_weapon/wield/supressed)
	if(axe)
		REMOVE_TRAIT(axe, TRAIT_NODROP, src)
		possessed.dropItemToGround(axe)

//Status Effect
/datum/status_effect/penitence
	id = "penitence"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 3 MINUTES // 36 ticks, get fucked if in bad mood, its nice if in good mood.
	tick_interval = 5 SECONDS
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/penitence

	var/mob/living/simple_animal/hostile/abnormality/penitentgirl/ghost
	var/attachment_level // Determines the entirety of the behaviour of the status effect.
	var/prudence_change
	var/temperance_change
	var/sanity_change
	var/penitent

/atom/movable/screen/alert/status_effect/penitence
	name = "Penitence"
	desc = "For better or for worse, a ghostly abnormality has attached itself to you."
	icon = 'ModularTegustation/Teguicons/status_sprites.dmi'
	icon_state = "rose_sign"

/datum/status_effect/penitence/on_creation(mob/living/new_owner, master, mood) // Easy way to make sure that we do not get fucked by the ghost define being too late
	ghost = master
	attachment_level = mood
	return ..()

/datum/status_effect/penitence/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE //Autoremoves it
	var/mob/living/carbon/human/possessed = owner
	if(possessed.sanity_lost)
		Penitence()
		return
	switch(attachment_level)
		if(-1) // Red Shoes is in the facility and you forgot about Penitent, fool.
			ghost.say("My beautiful red shoes, I am on my way!!")
			to_chat(possessed, span_userdanger("Your sanity is crumbling apart!"))
			prudence_change = -50 // Holy fuck.
			temperance_change = -30
			sanity_change = 0.125 // 12.5% of max sanity damage per tick, smile!
			duration = 1.5 MINUTES // Halved duration (18 ticks), I am not a monster.
		if(0) // Bad mood haunting.
			prudence_change = -20 // One full level, fuck you.
			temperance_change = -10 // Half a level, half fuck you.
			sanity_change = 0.05 // 5% of max sanity damage per tick, fuck you.
		if(1) // Neutral mood haunting.
			prudence_change = 5
			temperance_change = -10
		if(2) // Good mood haunting
			prudence_change = 20
			temperance_change = 10
			sanity_change = -0.05 // 5% of max sanity heal per tick, <3.
	possessed.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, prudence_change) // Changes your max sanity
	possessed.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, temperance_change) // Changes your workrates (lol)
	RegisterSignal(possessed, COMSIG_HUMAN_INSANE, PROC_REF(StartPenitence))
	RegisterSignal(possessed, COMSIG_LIVING_DEATH, PROC_REF(RemovePenitence))

/datum/status_effect/penitence/tick()
	. = ..()
	if(!ghost) // Penitent got fucking obliterated, abort the mission.
		qdel(src)
	var/mob/living/carbon/human/possessed = owner
	if(sanity_change)
		possessed.adjustSanityLoss(possessed.maxSanity * sanity_change)
	return

/datum/status_effect/penitence/proc/StartPenitence()
	SIGNAL_HANDLER
	penitent = TRUE
	addtimer(CALLBACK(src, PROC_REF(Penitence)), 1) // Sanity signal gets send before the whole SanityLoss proc is completed, so we need to give it time.

/datum/status_effect/penitence/proc/Penitence()
	var/mob/living/carbon/human/possessed = owner
	UnregisterSignal(possessed, COMSIG_HUMAN_INSANE, PROC_REF(Penitence))
	QDEL_NULL(possessed.ai_controller)
	duration = -1 // This shit not gonna end until you go die or become sane again.
	switch(attachment_level)
		if(-1)
			ghost.OverwhelmingDesire(possessed)
			possessed.ai_controller = /datum/ai_controller/insane/red_possess/penitent_sanguine
			possessed.apply_status_effect(/datum/status_effect/panicked_type/penitence/sanguine)
			possessed.visible_message(span_bolddanger("Crimson shoes suddenly materialize in [possessed.p_their()] feet, from where did [possessed.p_they()] get that axe?!"))
		if(0)
			possessed.ai_controller = /datum/ai_controller/insane/wander/penitent_reddish // PLACEHOOOOOLDER
			possessed.apply_status_effect(/datum/status_effect/panicked_type/penitence/penitent_reddish)
			possessed.visible_message(span_warning("Reddish shoes suddenly materialize in [possessed.p_their()] feet and they begin laughing maniacally!"))
		if(1)
			possessed.ai_controller = /datum/ai_controller/insane/penitence
			possessed.apply_status_effect(/datum/status_effect/panicked_type/penitence)
			possessed.visible_message(span_warning("Worn-out shoes suddenly materialize in [possessed.p_their()] feet...are those bloodstains?"))
		if(2)
			possessed.ai_controller = /datum/ai_controller/insane/penitence/contrition
			possessed.apply_status_effect(/datum/status_effect/panicked_type/penitence)
	possessed.InitializeAIController()

/datum/status_effect/penitence/proc/RemovePenitence()
	SIGNAL_HANDLER
	penitent = FALSE
	qdel(src)

/datum/status_effect/penitence/on_remove() // Might change the low mood effects and put them directly in the special insane.
	. = ..()
	if(!owner)
		qdel(ghost)
		return
	var/mob/living/carbon/human/possessed = owner
	UnregisterSignal(possessed, COMSIG_LIVING_DEATH, PROC_REF(RemovePenitence))
	UnregisterSignal(possessed, COMSIG_HUMAN_INSANE, PROC_REF(Penitence))
	possessed.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -prudence_change)
	possessed.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -temperance_change)
	if(!ghost)
		to_chat(possessed, span_info("The ghostly presence stops following you."))
		return
	ghost.StopHaunting(possessed)

// Insanity Mechanics

/datum/ai_controller/insane/penitence // This is the neutral mood insanity, it makes you a slightly more annoying suicide insane.
	lines_type = /datum/ai_behavior/say_line/insanity_wander/penitence

	var/last_action
	var/sanity_degradation = 0.1
	var/action_cooldown = 5 SECONDS // You are gonna die in 30 seconds,
	var/counter
	var/counter_threshold = 6
	var/Counter_threshold_line = "Please, forgive me....I'll just cut off my own feet."

/datum/ai_controller/insane/penitence/PerformIdleBehavior(delta_time)
	var/mob/living/carbon/human/human_pawn = pawn
	if(world.time > last_action + action_cooldown)
		current_behaviors += GET_AI_BEHAVIOR(lines_type)
		human_pawn.jitteriness += 10
		human_pawn.do_jitter_animation(human_pawn.jitteriness)
		if(counter >= counter_threshold)
			if(human_pawn.stat < UNCONSCIOUS) // Not unconscious/dead
				human_pawn.say("[Counter_threshold_line]")
			addtimer(CALLBACK(src, PROC_REF(DoTheThing)), 25) // They are gonna do the thing!!!
			action_cooldown = 100 // I just dont want them talking again before they do the thing.
			return
		human_pawn.adjustSanityLoss(human_pawn.maxSanity * sanity_degradation) // At neutral it makes you slightly harder to resane, in good it slowly resanes you.
		last_action = world.time
		counter++

/datum/ai_controller/insane/penitence/proc/DoTheThing()
	var/mob/living/carbon/human/human_pawn = pawn
	if(!human_pawn.sanity_lost) // Saved by the bell
		return
	if(HAS_TRAIT(human_pawn, TRAIT_NODISMEMBER))
		return
	var/obj/item/bodypart/left_leg = human_pawn.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/right_leg = human_pawn.get_bodypart(BODY_ZONE_R_LEG)
	var/did_the_thing = (left_leg?.dismember() && right_leg?.dismember()) // Not all limbs can be removed, so important to check that we did. the. thing.
	if(!did_the_thing)
		return // They did not do the thing =(
	human_pawn.cut_overlay(mutable_appearance('icons/mob/clothing/feet.dmi', "red_shoes", -ABOVE_MOB_LAYER))
	human_pawn.adjustBruteLoss(300)// DIE! For real, this time.


/datum/ai_controller/insane/penitence/contrition // The GOOD haunting, this actually makes you a harmless catatonic and slowly resanes you.
	lines_type = /datum/ai_behavior/say_line/contrition

	sanity_degradation = -0.2
	action_cooldown = 15 SECONDS
	counter_threshold = 10 // You SHOULD resane before this goes off, but just in the case that you do not, I got you homie.
	Counter_threshold_line = "So...tired..." // This is lazy, but it should not trigger like, ever.

/datum/ai_controller/insane/penitence/contrition/DoTheThing()
	var/mob/living/carbon/human/human_pawn = pawn
	if(!human_pawn.sanity_lost) // No need for this if you got resanned.
		return
	human_pawn.Sleeping(30 SECONDS) // A mimir.
	human_pawn.adjustSanityLoss(-1000) // Hurray, you are sane again.


/datum/ai_controller/insane/red_possess/penitent_sanguine // The "You fucked up" special insanity, basically Red Shoes insane who attacks anyone who tries to stop it.
	lines_type = /datum/ai_behavior/say_line/penitent_sanguine

/datum/ai_controller/insane/red_possess/penitent_sanguine/proc/CanTarget(mob/living/L)
	if(L.stat == DEAD)
		return FALSE
	return TRUE

/datum/ai_controller/insane/red_possess/penitent_sanguine/retaliate(mob/living/L) // Yes, I copied a fuckton of code from murder insane, sue me.
	if(!CanTarget(L))
		return
	for(var/datum/ai_behavior/I in current_behaviors)
		I.finish_action(src, FALSE)
	blackboard[BB_INSANE_CURRENT_ATTACK_TARGET] = L
	current_behaviors += GET_AI_BEHAVIOR(/datum/ai_behavior/insanity_attack_mob)
	return

/datum/ai_controller/insane/red_possess/penitent_sanguine/on_attackby(datum/source, obj/item/I, mob/user)
	..()
	retaliate(user)
	return

/datum/ai_controller/insane/red_possess/on_attack_hand(datum/source, mob/living/L)
	..()
	retaliate(L)
	return

/datum/ai_controller/insane/red_possess/penitent_sanguine/on_attack_paw(datum/source, mob/living/L)
	..()
	retaliate(L)
	return

/datum/ai_controller/insane/red_possess/penitent_sanguine/on_bullet_act(datum/source, obj/projectile/Proj)
	..()
	if(isliving(Proj.firer))
		retaliate(Proj.firer)
		return

/datum/ai_controller/insane/red_possess/on_hitby(datum/source, atom/movable/AM, skipcatch = FALSE, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	..()
	if(istype(AM, /obj/item))
		var/obj/item/I = AM
		if(I.throwforce > 0 && ishuman(I.thrownby))
			var/mob/living/carbon/human/H = I.thrownby
			retaliate(H)
	return

/datum/ai_controller/insane/red_possess/on_Crossed(datum/source, atom/movable/AM)
	..()
	var/mob/living/living_pawn = pawn
	if(IS_DEAD_OR_INCAP(living_pawn))
		return
	var/mob/living/living_thing = AM
	if(istype(living_thing) && !(living_thing.status_flags & GODMODE) && living_thing.stat != DEAD)
		retaliate(living_thing)

/datum/ai_controller/insane/red_possess/penitent_sanguine/on_startpulling(datum/source, atom/movable/puller, state, force)
	..()
	var/mob/living/living_pawn = pawn
	if(!IS_DEAD_OR_INCAP(living_pawn))
		retaliate(living_pawn.pulledby)
		return TRUE
	return FALSE

// Insanity lines

/datum/ai_behavior/say_line/insanity_wander/penitence // Wander lines deal white damage, FUNNY.
	lines = list(
		"The halls are painted red, everyone is dead...",
		"These accursed shoes, it was all my fault!!",
		"Their heads caving in, the red axe between my hands....I can still feel it all.",
		"AAAAAAAHHH GET OUT OF MY HEAD GET OUT OF MY HEAD GET OUT OF MY HEAD!!",
		"I am sorry....I am so sorry...",
	)

/datum/ai_behavior/say_line/contrition // Flavour lines, the idea is that the ghost is beaming therapy into your brain.
	lines = list(
		"I am sorry, but I cannot handle this anymore...",
		"Even if you say that...I can't keep going.",
		"Do you really believe that there is any hope left?",
		"It will all end soon, no matter what you say...",
		"I am not strong enough, I am so sorry.",
	)

/datum/ai_behavior/say_line/penitent_sanguine // Falling right back into old habits
	lines = list(
		"Where is everyone?",
		"Guys, look at me! I've got such nice shoes on!",
		"You all need to see how lovely my shoes are!",
		"They're much prettier with blood on them.",
	)

/datum/status_effect/panicked_type/penitence // Neutral insane status effect.
	icon = "penitence"
	var/shoes = "red_shoes" // Remember to make one variant for the good haunting/insanity

/datum/status_effect/panicked_type/penitence/on_apply()
	. = ..()
	owner.add_overlay(mutable_appearance('icons/mob/clothing/feet.dmi', "[shoes]", -ABOVE_MOB_LAYER)) //Yes I am reusing assets! No, I am not sorry!

/datum/status_effect/panicked_type/penitence/on_remove()
	. = ..()
	owner.cut_overlay(mutable_appearance('icons/mob/clothing/feet.dmi', "[shoes]", -ABOVE_MOB_LAYER))
	var/mob/living/carbon/human/possessed = owner
	var/datum/status_effect/penitence/S = possessed.has_status_effect(/datum/status_effect/penitence)
	if(S.penitent)
		S.RemovePenitence() // This handles what happens after resanning a possessed person.

/datum/ai_controller/insane/wander/penitent_reddish
	lines_type = /datum/ai_behavior/say_line/cinderella // PLACEHOLDER

/datum/status_effect/panicked_type/penitence/penitent_reddish
	icon = "penitence"

/datum/status_effect/panicked_type/penitence/penitent_reddish/tick()
	. = ..()
	var/mob/living/carbon/human/status_holder = owner
	status_holder.emote("spin")

// VERY bad insane status effect
/datum/status_effect/panicked_type/penitence/sanguine
	icon = "penitence"
	shoes = "red_shoes"

/datum/status_effect/panicked_type/penitence/sanguine/on_apply()
	. = ..()

/datum/status_effect/panicked_type/penitence/sanguine/on_remove()
	. = ..()

#undef STATUS_EFFECT_PENITENCE
