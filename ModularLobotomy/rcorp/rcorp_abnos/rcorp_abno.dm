//RCorp abnos are in a way similar to the common abnos but have a focus on PvP combat, and so adjustments need to be made, making them their own mobs avoids mode conflict and easier balancing.
//Majority of this work will simply be porting over (shameless copypasting) exclusively the breach and balance changes of abnos to be their own mob
/mob/living/simple_animal/hostile/rcorp_abno
	name = "Shit's fucked, ain't it?"
	desc = "Bug report this, I may have fucked up." //Rabbits are lobotomized so when adding a abno try to warn them of their gimmick in the description
	maxHealth = 99
	health = 99
	melee_damage_lower = 99
	melee_damage_upper = 999
	attack_sound = 'sound/voice/human/malescream_1.ogg' //This embodies my feelings if I see this shit ingame
	a_intent = INTENT_HARM
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	faction = list("hostile")
	var/dupe = FALSE //Some abnos are so absurdly weak they come in groups of 2 to do anything, this var handles that
	var/secret_chance = FALSE //Only toggle true if you have "alternate sprites" for the abno
	var/secret_abnormality = FALSE //This is only really here incase some funny guy decides to change something in a abno for its alternate sprite (such as its abilities)
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
	if(dupe)
		new.src
	if(!isnull(original_abno))
		icon = original_abno.icon
		icon_state = original_abno.icon_state
		icon_living = original_abno.icon_living
		icon_dead = original_abno.icon_dead
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
