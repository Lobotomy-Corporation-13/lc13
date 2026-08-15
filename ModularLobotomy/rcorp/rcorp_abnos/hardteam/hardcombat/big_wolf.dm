#define BIGWOLF_COOLDOWN_DASH 30 SECONDS
#define BIGWOLF_COOLDOWN_HOWL 20 SECONDS
#define WOLF_HP_PERCENT 100 * (health / maxHealth)
//Combat because he can go one on one against rabbits due to AoE, Dash and good melee
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf
	name = "Big and Will be Bad Wolf"
	desc = "An abnormality taking the form of a large wolf. Its lunges may hurt but the howls are worse."
	maxHealth = 2500
	health = 2500
	del_on_death = FALSE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1)
	see_in_dark = 10
	rapid_melee = 1.5
	ranged = TRUE
	ranged_cooldown_time = BIGWOLF_COOLDOWN_DASH
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	move_to_delay = 2
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 40
	original_abno = /mob/living/simple_animal/hostile/abnormality/big_wolf

	//For when the wolf becomes incorporal and flees.
	var/last_reached_health = 75
	//For some reason wolf's AI just turns off when there is if(fleeing_now)
	var/fleeing_now = FALSE
	//Cooldowns for skills
	var/hp_check_cooldown = 0
	var/howl_cooldown = 0
	var/howl_cooldown_time = BIGWOLF_COOLDOWN_HOWL
	var/obj/effect/proc_holder/ability/aimed/rca_dash/big_wolf/ourdash
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/rival
	var/hit_rival = 1 //I LOVE FIGHTING MY LONGLIFE LIFELONG RIVAL
	//Dont get stuck in a wall for the love of god
	var/turf/starting_location

	attack_action_types = list(
		/datum/action/innate/rca_abnormality_attack/toggle/wolf_dash_toggle,
		/datum/action/cooldown/rca_wolf_howl,
	)

	abno_additional_instructions = "<h1>You are Big and Will be Bad Wolf, A Combat Role Abnormality.</h1><br>\
		<b>|Bloodstained Hunt|: When your dash is enabled perform a dash when you click at a distant tile. \
		Upon initiating your dash you will begin to shake and after a 1 second delay dash at your target. \
		This dash will travel 7 tiles and deal 50 damage RED to all hostiles targets along your path. \
		The width of this dash is that of 3 tiles and its cooldown is 30 seconds. <br>\
		<br>\
		|Roaring Wolf|: When pressing your 'Howl' ability you will begin to inhale. \
		After a 2 second delay you will howl, affecting all hostiles within a 20 tile range of yourself. \
		The howl will deal 50 WHITE damage to those affected and will go through walls. <br>\
		<br>\
		|Into the Dark|: When losing over 25% of your HP you will start skulking in the shadows for 3 seconds. \
		Your speed will be greatly boosted and you will phase through all obstacles. \
		You may not phase through certain map borders and team partitions. \
		If this state ends while within a wall you will return to your original position. \
		While in this state you may not perform any attacks or abilities. \
		This has a cooldown of 10 seconds and may be repeated when you lose the required amount of HP again. <br>\
		<br>\
		|Destined to be the Big Bad Wolf|: The Abnormality 'Little Red Riding Hooded Mercenary' is always harmed by your AoE attacks. \
		When 'Little Red Riding Hooded Mercenary' is caught in your attack all others hit by this same attack will take double the damage from it. </b>"

//Obligatory ability buttons for the dreaded player.
/datum/action/innate/rca_abnormality_attack/toggle/wolf_dash_toggle
	name = "Toggle Dash"
	desc = "Prepare to dash at the enemy dealing 50 RED damage to all in your way."
	button_icon_state = "wolf_toggle0"
	chosen_message = span_notice("You won't dash anymore.")
	chosen_attack_num = 2
	button_icon_toggle_activated = "wolf_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You prepare your dash.")
	button_icon_toggle_deactivated = "wolf_toggle0"

/datum/action/cooldown/rca_wolf_howl
	name = "Howl"
	desc = "Prepare to howl, dealing WHITE damage to nearby humans."
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "wolf_howl"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = BIGWOLF_COOLDOWN_HOWL

/datum/action/cooldown/rca_wolf_howl/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/wolf = owner
	wolf.Howl()
	StartCooldown()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/Initialize()
	.  = ..()
	ourdash = new()
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	pixel_x = -32
	base_pixel_x = -32

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/CanAttack(atom/the_target)
	if(!can_act || fleeing_now)
		return //If this isnt here the AI melees you mid dash or howl
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/death(gibbed)
	update_icon()
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/Move()
	if(!can_act)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/handle_automated_action()
	. = ..()
	if(!can_act || stat == DEAD)
		return

	if(target && ranged_cooldown <= world.time)
		OpenFire(target)
		return

	if(fleeing_now != TRUE && hp_check_cooldown <= world.time)
		var/our_hp = WOLF_HP_PERCENT
		if(our_hp <= last_reached_health)
			FleeNow()
			last_reached_health = last_reached_health - 25
		hp_check_cooldown = world.time + (10 SECONDS)
		return

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/Life()
	. = ..()
	if(fleeing_now != TRUE && hp_check_cooldown <= world.time && client)
		var/our_hp = WOLF_HP_PERCENT
		if(our_hp <= last_reached_health)
			FleeNow()
			last_reached_health = last_reached_health - 25
		hp_check_cooldown = world.time + (10 SECONDS)
	if(!client && can_act && howl_cooldown <= world.time && fleeing_now != TRUE)
		Howl()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/OpenFire(atom/A)
	if(!can_act || fleeing_now == TRUE)
		return

	if(client)
		switch(chosen_attack)
			if(1)
				if(ranged_cooldown > world.time)
					var/time_left =  (ranged_cooldown - world.time) / 10
					to_chat(src, span_userdanger("You must wait [time_left] seconds to regain your strength..."))
					return
				ScratchDash(A)
		return

	if(ranged_cooldown <= world.time)
		ScratchDash(A)

//Stuff that is overrided when fleeing
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/attacked_by(obj/item/I, mob/living/L)
	if(fleeing_now == TRUE)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/bullet_act(obj/projectile/P)
	if(fleeing_now == TRUE)
		return BULLET_ACT_BLOCK
	..()

//Unique Procs
//Here its changed to just make the AI retreat and the player instead gets buffed I guess
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/proc/FleeNow()
	icon_state = "big_wolf_flee"
	playsound(get_turf(src), 'sound/abnormalities/big_wolf/Wolf_FogChange.ogg', 75, 1)
	visible_message(span_danger("[src] retreats into the shadows!"))
	starting_location = get_turf(src)
	incorporeal_move = TRUE
	LoseTarget(FALSE)
	retreat_distance = 20
	TemporarySpeedChange(-2, 3 SECONDS)
	fleeing_now = TRUE
	density = FALSE
	addtimer(CALLBACK(src, PROC_REF(StopFleeing)), 3 SECONDS)

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/proc/StopFleeing()
	var/turf/current_turf = get_turf(src)
	if(current_turf && current_turf.density && starting_location)
		forceMove(starting_location)
		to_chat(src, span_danger("You were trapped in a wall and have been returned to your starting location!"))
	playsound(get_turf(src), 'sound/magic/ethereal_exit.ogg', 75, 1)
	visible_message(span_danger("[src] emerges from the shadows!"))
	retreat_distance = null
	fleeing_now = FALSE
	color = initial(color)
	incorporeal_move = FALSE
	density = TRUE
	icon_state = icon_living

//Combat Skills
// Simple dash attack that deals 50 damage to all those nearby. This is optimized for AI rather than players.
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/proc/ScratchDash(dash_target)
	ranged_cooldown = world.time + ranged_cooldown_time
	ourdash.Perform(dash_target, src)

/obj/effect/proc_holder/ability/aimed/rca_dash/big_wolf
	name = "big wolf dash"
	dash_speed =  0.5
	dash_damage = 50
	dash_range =  7
	windup_delay = 1 SECONDS
	cooldown_time = 30 SECONDS
	env_breaking = TRUE
	var/hit_rival = 1 //I LOVE FIGHTING MY LONGLIFE LIFELONG RIVAL

/obj/effect/proc_holder/ability/aimed/rca_dash/big_wolf/Finalize(target, mob/living/user, list/path_list)
	user.do_shaky_animation(2)
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/big_wolf/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
	var/list/hit_mob = list()
	for(var/turf/TF in GetRange(T, 1))
		if(!TF)
			break
		if(isclosedturf(TF))
			continue
		if(!HasIdentList(TF))
			FlickOnAtom(TF,'icons/effects/effects.dmi',"slice",4)
		if(istype(ourthing,/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf))
			for(var/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/rival in hit_mob)
				rival.deal_damage(dash_damage * 3, RED_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)) //triple damage to red and double damage to everyone else
				hit_rival = 2 //Janky way of doing it but eh
		hit_mob = HurtInTurf(ourthing, TF, hit_mob, dash_damage*hit_rival, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/big_wolf/EndCharge(mob/living/user)
	hit_rival = 1
	..()

// Very simple ranged howl that applies white damage.
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/proc/Howl()
	howl_cooldown = world.time + howl_cooldown_time
	var/mutable_appearance/visual_overlay = mutable_appearance('icons/effects/effects.dmi', "blip")
	visual_overlay.pixel_x = -pixel_x
	visual_overlay.pixel_y = -pixel_y
	add_overlay(visual_overlay)
	can_act = FALSE
	if(do_after(src, 2 SECONDS, target = src))
		new /obj/effect/temp_visual/fragment_song(get_turf(src))
		var/list/turfs_to_check = orange(20, src)
		for(var/mob/living/L in turfs_to_check)
			if(istype(L, rival))
				rival = L
				rival.deal_damage(150, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL)) //She takes triple damage from the wolf, because of the gimmick
				rival.RageUpdate(2)
				hit_rival = 2 //Used to multiply our damage later
			if(faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			L.deal_damage(50 * hit_rival, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
		for(var/obj/vehicle/V in turfs_to_check)
			V.take_damage(50 * hit_rival, WHITE_DAMAGE)
		playsound(get_turf(src), 'sound/abnormalities/big_wolf/Wolf_Howl.ogg', 30, 0, 4)
	cut_overlay(visual_overlay)
	hit_rival = 1
	can_act = TRUE

#undef BIGWOLF_COOLDOWN_HOWL
#undef BIGWOLF_COOLDOWN_DASH
