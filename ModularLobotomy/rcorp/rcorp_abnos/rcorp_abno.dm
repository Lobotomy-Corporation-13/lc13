//RCorp abnos are in a way similar to the common abnos but have a focus on PvP combat, and so adjustments need to be made, making them their own mobs avoids mode conflict and easier balancing.
//Majority of this work will simply be porting over (shameless copypasting) exclusively the breach and balance changes of abnos to be their own mob
/mob/living/simple_animal/hostile/rcorp_abno
	name = "Shit's fucked, ain't it?"
	desc = "Bug report this, I may have fucked up." //Rabbits are lobotomized so when adding a abno try to warn them of their gimmick in the description
	maxHealth = 99
	health = 99
	melee_damage_lower = 9
	melee_damage_upper = 99
	attack_sound = 'sound/voice/human/malescream_1.ogg' //This embodies my feelings if I see this shit ingame
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	stat_attack = HARD_CRIT
	layer = LARGE_MOB_LAYER
	a_intent = INTENT_HARM
	del_on_death = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	//For RCA abnos the threat level only matters if the abno lacking a death sprite has it replaced by abno cores.
	var/threat_level = ZAYIN_LEVEL
	faction = list("hostile")
	var/secret_chance = FALSE //Only toggle true if you have "alternate sprites" for the abno
	var/secret_abnormality = FALSE //This is only really here incase some funny guy decides to change something in a abno for its alternate sprite (such as its abilities)
	var/chosen_attack = 1
	var/small_sprite_type = /datum/action/small_sprite/abnormality //Tiny guy if your abno sprite is too large to click through, you can change it if you want but whose going to sprite extras amirite
	var/core_icon = ""
	var/core = TRUE

	// rcorp stuff
	var/rcorp_team

	var/list/attack_action_types = list()

	//The original abno type this is based on. If defined, it'll automatically add the name, description and sprite of that abno. Shamelessly ripped from LCL.
	var/mob/living/simple_animal/hostile/abnormality/original_abno = null

	//Descriptions and instructions
	var/abno_additional_instructions = "" //Insert gameplay tutorial here
	var/player_desc = "" //The description used when 'examine more' is done, writes down the name of a player here

	//Meme posting, if the 1% chance rolls these variables are replaced by whatever you shoved here
	var/secret_icon_state
	var/secret_icon_living
	var/secret_icon_dead
	var/secret_icon_file
	var/secret_horizontal_offset = 0
	var/secret_vertical_offset = 0

/mob/living/simple_animal/hostile/rcorp_abno/Initialize(mapload)
	. = ..()
	for(var/action_type in attack_action_types)
		var/datum/action/innate/abnormality_attack/attack_action = new action_type()
		attack_action.Grant(src)
	if(small_sprite_type)
		var/datum/action/small_sprite/small_action = new small_sprite_type()
		small_action.Grant(src)
	//Comically large list of things to steal, naturally these are all (mostly) cosmetic as they may be changed at anytime from the original abno
	if(!isnull(original_abno))
		icon = original_abno.icon
		icon_state = original_abno.icon_state
		icon_living = original_abno.icon_living
		icon_dead = original_abno.icon_dead
		attack_sound = original_abno.attack_sound
		attack_verb_continuous = original_abno.attack_verb_continuous
		attack_verb_simple = original_abno.attack_verb_simple
		speak_emote = original_abno.speak_emote
		speech_span = original_abno.speech_span
		threat_level = original_abno.threat_level
		core_icon = original_abno.core_icon
		death_message = original_abno.death_message
		death_sound = original_abno.death_sound
		blood_volume = original_abno.blood_volume
		pixel_x = original_abno.pixel_x
		base_pixel_x = original_abno.base_pixel_x
		pixel_y = original_abno.pixel_y
		base_pixel_y = original_abno.base_pixel_y
		response_help_continuous = original_abno.response_help_continuous
		response_help_simple = original_abno.response_help_simple
		pet_bonus = original_abno.pet_bonus
		pet_bonus_emote = original_abno.pet_bonus_emote
		projectilesound = original_abno.projectilesound
		gender = original_abno.gender //The most important var here
		attack_vis_effect = original_abno.attack_vis_effect
		friendly_verb_continuous = original_abno.friendly_verb_continuous
		friendly_verb_simple = original_abno.friendly_verb_simple
		emote_see = original_abno.emote_see
		emote_hear = original_abno.emote_hear
		attacked_sound = original_abno.attacked_sound
		//I assure you the wall of vars which are 99% cosmetic and useless is crucial to my ig immersion

	if(secret_chance && (prob(1)))
		InitializeSecretIcon()

/mob/living/simple_animal/hostile/rcorp_abno/proc/InitializeSecretIcon()
	//Can probably shove a if condition somewhere to change a abnos stats or gimmick if this is true
	secret_abnormality = TRUE

	if(secret_icon_file)
		icon = secret_icon_file

	if(secret_icon_state)
		icon_state = secret_icon_state

	if(secret_icon_living)
		icon_living = secret_icon_living

	if(secret_horizontal_offset)
		base_pixel_x = secret_horizontal_offset

	if(secret_vertical_offset)
		base_pixel_y = secret_vertical_offset

	if(secret_icon_dead)
		icon_dead = secret_icon_dead

/mob/living/simple_animal/hostile/rcorp_abno/proc/GetRiskLevel()
	return threat_level

/mob/living/simple_animal/hostile/rcorp_abno/Destroy()
	if(core)
		CreateAbnoCore(name, core_icon)
		. = ..()

/mob/living/simple_animal/hostile/rcorp_abno/proc/CreateAbnoCore()//this is called by abnormalities on Destroy()
	var/obj/structure/abno_core/C = new(get_turf(src))
	C.name = initial(name) + " Core"
	C.desc = "The core of [initial(name)]"
	C.icon_state = core_icon
	C.contained_abno = src.type
	C.threat_level = threat_level
	switch(GetRiskLevel())
		if(1)
			return
		if(2)
			C.icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/teth.dmi'
		if(3)
			C.icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
		if(4)
			C.icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/waw.dmi'
		if(5)
			C.icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/aleph.dmi'

// Actions
/datum/action/innate/rca_abnormality_attack
	name = "Abnormality Attack"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = ""
	background_icon_state = "bg_abnormality"
	var/mob/living/simple_animal/hostile/rcorp_abno/A
	var/chosen_message
	var/chosen_attack_num = 0

/datum/action/innate/rca_abnormality_attack/Destroy()
	A = null
	return ..()

/datum/action/innate/rca_abnormality_attack/Grant(mob/living/L)
	if(istype(L, /mob/living/simple_animal/hostile/rcorp_abno))
		A = L
		return ..()
	return FALSE

/datum/action/innate/rca_abnormality_attack/Activate()
	A.chosen_attack = chosen_attack_num
	to_chat(A, chosen_message)

/datum/action/innate/rca_abnormality_attack/toggle
	name = "Toggle Attack"
	var/toggle_message
	var/toggle_attack_num = 1
	var/button_icon_toggle_activated = ""
	var/button_icon_toggle_deactivated = ""

/datum/action/innate/rca_abnormality_attack/toggle/Activate()
	. = ..()
	button_icon_state = button_icon_toggle_activated
	UpdateButtonIcon()
	active = TRUE

/datum/action/innate/rca_abnormality_attack/toggle/Deactivate()
	A.chosen_attack = toggle_attack_num
	to_chat(A, toggle_message)
	button_icon_state = button_icon_toggle_deactivated
	UpdateButtonIcon()
	active = FALSE

/*
* Taken from _abno_abilities, necessary due to how many RCA abnos use this
*/
/obj/effect/proc_holder/ability/aimed/rca_dash
	name = "default dash"
	desc = "An ability that allows its user to dash six tiles forward in any direction."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 1 SECONDS

	//Amount of time in deciseconds to move from one tile to another.
	var/dash_speed = 1
	//Used inconsistently
	var/dash_damage = 0
	//How many tiles this dash can move if not stopped.
	var/dash_range = 6
	//Delay before the ability actually activates.
	var/windup_delay = 0
	//For attacks that pass through walls
	var/dash_ignore_walls = FALSE
	//If this dash can smash through windows
	var/env_breaking = FALSE
	//For stopping the dash NOW
	var/emergency_stop = FALSE
	//If we only do cardinals
	var/cardinal_only = FALSE

/obj/effect/proc_holder/ability/aimed/rca_dash/Perform(target, mob/living/user)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	emergency_stop = FALSE
	if(!user || !target)
		return
	ToggleAct(user,FALSE)
	var/overall_dir = get_dir(get_turf(user), get_turf(target))
	user.setDir(overall_dir)

	var/list/ourpath = Telegraph(target, user)

	if(length(ourpath))
		Finalize(target, user, ourpath)
		return
	EndCharge(user)

//Returns a list of the turfs we are dashing. See spear apostle dash for actual telegraphing.
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/Telegraph(atom/target, mob/living/user)
	. = list()
	if(!target || !user)
		stack_trace("Dash Skill Telegraph was called without a target or user.")
		return list()
	var/dir_to_target
	if(cardinal_only && !QDELETED(target))
		dir_to_target = get_cardinal_dir(get_turf(user), get_turf(target))
	else
		dir_to_target = get_dir(user, target)

	var/turf/T = get_turf(user)
	for(var/i = 1 to dash_range)
		T = get_step(T, dir_to_target)
		if(T.density)
			if(i < 4) // Mob attempted to dash into a wall too close, stop it
				return list()
			break
		. += T

// Truely preforms the dash.
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/Finalize(target, mob/living/user, list/path_list)
	if(windup_delay)
		if(!do_after(user, windup_delay, target = user))
			EndCharge(user)
			return

	if(!path_list)
		var/dir_to_target = get_dir(user, target)
		if(!dir_to_target)
			EndCharge(user)
			return
		var/somehowloc = get_ranged_target_turf(user, dir_to_target, dash_range)
		path_list = get_ranged_target_turf_direct(user, somehowloc, dash_range)

	addtimer(CALLBACK(src, PROC_REF(DashMove), user, get_turf(user), 1, path_list), dash_speed)

//Ends the charge offically
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/DashMove(mob/living/user, turf/last_turf, times_ran = 1, list/dash_list)
	var/list/mobs_to_hit = list()
	if(!islist(dash_list))
		stack_trace("Dash Skill path_list was not a list.")
		return EndCharge(user)

	var/turf/T = popleft(dash_list)

	if(times_ran >= dash_range)
		return EndCharge(user)
	if(!T || !user)
		return EndCharge(user)
	if(last_turf && last_turf != get_turf(user) && !dash_ignore_walls)
		//Really cool interception.
		return EndCharge(user)
	if(emergency_stop || user.stat == DEAD)
		return EndCharge(user)
	if(!PassCriteria(T, user))
		return EndCharge(user)
	user.forceMove(T)
	last_turf = T
	// Damage
	mobs_to_hit = TurfEffects(T, user, mobs_to_hit)

	//Unsure if sleep would cause issues with this thing so i resorted to the age old method -IP
	addtimer(CALLBACK(src, PROC_REF(DashMove), user, last_turf, (times_ran + 1), dash_list), dash_speed)

//Ends the charge offically
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/EndCharge(mob/living/user)
	if(user)
		AbnoInteraction(user)
		ToggleAct(user,TRUE)
	LAZYCLEARLIST(hit_identifiers)

/*
* If this returns false then the attack stops.
* Scans each turf during Telegraph.
*/
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/PassCriteria(turf/T, mob/living/user)
	if(dash_ignore_walls)
		return TRUE
	if(T.density)
		return FALSE
	for(var/obj/structure/window/W in T.contents)
		if(W.density)
			if(!env_breaking)
				return FALSE
			W.obj_destruction(name)
	for(var/obj/machinery/door/MD in T.contents)
		if(!MD.CanAStarPass(null))
			return FALSE
		if(MD.density)
			INVOKE_ASYNC(MD, TYPE_PROC_REF(/obj/machinery/door, open), 2)
	for(var/mob/living/simple_animal/hostile/rcorp_abno/D in T.contents)	//This caused issues earlier
		if(D.density && D != user)
			return FALSE
	return TRUE

/*
* Just does damage to people on tiles we havent hit.
*/
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/TurfEffects(turf/T, mob/living/ourthing)
	return

/*
* Gets only the turfs around us. No reason
* to check for all of the items if we are not looking for them
*/
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/GetRange(A, size = 1)
	if(!A)
		return
	var/turf/T = get_turf(A)

	if(size < 1)
		return list(T)
	var/turfz = T.z
	//Lower Left
	var/offsetx1 = T.x -size
	var/offsety1 = T.y -size
	//Upper Right
	var/offsetx2 = T.x +size
	var/offsety2 = T.y +size
	var/list/turfs_to_hit = block(offsetx1,offsety1,turfz,offsetx2,offsety2,turfz)
	turfs_to_hit -= T
	return turfs_to_hit

/*
* Requires a mob/living to call HurtInTurf
* Uses HasIdentList to sort out the things we have already hit.
*/
/obj/effect/proc_holder/ability/aimed/rca_dash/proc/HurtInTurf(mob/living/ourmob, turf/target, list/hit_list = list(), damage = 0, damage_type = RED_DAMAGE, def_zone = null, check_faction = FALSE, exact_faction_match = FALSE, hurt_mechs = FALSE, mech_damage = 0, hurt_hidden = FALSE, hurt_structure = FALSE, break_not_destroy = FALSE, attack_direction = null, flags = null, attack_type = null)
	var/list/do_not_hitlist = list()
	for(var/obj/thing in target)
		if(HasIdentList(thing))
			do_not_hitlist += thing
	for(var/mob/living/L in target)
		if(HasIdentList(L))
			do_not_hitlist += L
	return ourmob.HurtInTurf(target, hit_list, damage, damage_type, def_zone, check_faction, exact_faction_match, hurt_mechs, mech_damage, hurt_hidden, hurt_structure, break_not_destroy, attack_direction, flags, attack_type) - do_not_hitlist


//Debrief the player
/mob/living/simple_animal/hostile/rcorp_abno/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	manual_emote("awakens...") //Players need to know whos active
	to_chat(src, span_warning("[abno_additional_instructions] \n")) //Gameplay dump

/mob/living/simple_animal/hostile/rcorp_abno/ghost()
	..()
	mind = null //You left, give it to someone else
	player_desc = "" //You left, you are forgotten by history

//Note that this is all a template and the rest is just copypasting the breaches
