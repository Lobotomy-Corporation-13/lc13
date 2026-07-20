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
	faction = list("hostile")
	var/secret_chance = FALSE //Only toggle true if you have "alternate sprites" for the abno
	var/secret_abnormality = FALSE //This is only really here incase some funny guy decides to change something in a abno for its alternate sprite (such as its abilities)
	var/chosen_attack = 1
	var/small_sprite_type = /datum/action/small_sprite/abnormality //Tiny guy if your abno sprite is too large to click through, you can change it if you want but whose going to sprite extras amirite

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
	if(!isnull(original_abno))
		name = original_abno.name
		icon = original_abno.icon
		icon_state = original_abno.icon_state
		icon_living = original_abno.icon_living
		icon_dead = original_abno.icon_dead
		attack_sound = original_abno.attack_sound
		attack_verb_continuous = original_abno.attack_verb_continuous
		attack_verb_simple = original_abno.attack_verb_simple
	if(secret_chance && (prob(1)))
		InitializeSecretIcon()

/mob/living/simple_animal/hostile/rcorp_abno/proc/InitializeSecretIcon()
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

/mob/living/simple_animal/hostile/rcorp_abno/examine_more(mob/user)
	. = ..()
	. += span_notice("You see a hastily written note on the side, it says '1215-1217, PICK A SIDE'.")

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
