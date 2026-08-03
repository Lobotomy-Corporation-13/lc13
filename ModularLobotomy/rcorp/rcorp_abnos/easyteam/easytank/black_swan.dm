#define SWAN_UMBRELLA_COOLDOWN (30 SECONDS)
#define SWAN_UMBRELLA_DURATION (8 SECONDS)
//Tank because it can reflect projectiles
/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan
	name = "Dream of Black Swan"
	desc = "A young woman with the body of a black swan. Her eyes dart around looking for something."
	del_on_death = FALSE
	maxHealth = 3000
	health = 3000
	ranged_cooldown_time = 10 SECONDS
	move_to_delay = 4
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 1)
	ranged = TRUE
	vision_range = 14
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 40
	original_abno = /mob/living/simple_animal/hostile/abnormality/black_swan

	abno_additional_instructions = "<h1>You are Dream of Black Swan, A Tank Role Abnormality.</h1><br>\
		<b>|Well-worn Parasol|: When your primary ability is used, you will begin blocking with a Parasol. \
		While blocking with this Parasol any projectile shot your way will be reflected the same way they came from. \
		You may only block in the direction you are facing and are vulnerable to being shot from behind.<br>\
		<br>\
		|Broken Dream|: When falling below 50% health |Broken Dream| activates, when this effect is activated you will gain the Wail ability.\
		Whenever attempting a ranged attack you will initiate a wail, this wail has a reach of 9 tiles.\
		Any within this 9 tile sightline will be hit for 70 WHITE damage. </b>"

	//If is in closed or open mode
	var/beak_closed = FALSE
	var/umbrella_open = FALSE
	//cooldowns
	var/umbrella_cooldown = 0

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/cooldown/rca_blackswan_umbrella)

/datum/action/cooldown/rca_blackswan_umbrella
	name = "Black Swan's Umbrella"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "swan"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = SWAN_UMBRELLA_COOLDOWN

/datum/action/cooldown/rca_blackswan_umbrella/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/swan = owner
	swan.OpenUmbrella()
	StartCooldown()
	return TRUE


/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/Initialize()
	. = ..()
	icon_state = "blackswan"
	playsound(get_turf(src), 'sound/abnormalities/blackswan/sis_transformation.ogg', 30, 0, 4)

//Different descriptions for different forms.
/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/examine(mob/user)
	. = ..()
	if(umbrella_open)
		. += "She is holding a large umbrella infront of herself, projectiles seem to just bounce off it."

//i think this only procs if the AI is on.
/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/handle_automated_action()
	. = ..()
	if(!can_act || stat == DEAD)
		return
	if(target && !umbrella_open && umbrella_cooldown <= world.time)
		OpenUmbrella()

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/Life()
	. = ..()
	if(!beak_closed && health <= (maxHealth*0.5))
		beak_closed = TRUE
		icon_state = "blackswan_closed"

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/bullet_act(obj/projectile/P) //umbrella shield code
	if(umbrella_open)
		if(is_A_facing_B(src,P.firer))
			if(P.reflectable != NONE)
				visible_message(span_userdanger("[src] deflects [P] with their umbrella!"))
				ReflectProjectile(P)
				return BULLET_ACT_FORCE_PIERCE
			return BULLET_ACT_BLOCK
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/OpenFire()
	if(!can_act)
		return
	else if(beak_closed && ranged_cooldown <= world.time) //redundant check if player controlled.
		Wail()
		ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/proc/OpenUmbrella()
	if(umbrella_open)
		return
	playsound(get_turf(src), 'sound/abnormalities/blackswan/sis_swoop.ogg', 10, 0, 4)
	umbrella_open = TRUE
	umbrella_cooldown = world.time + SWAN_UMBRELLA_COOLDOWN
	if(beak_closed)
		icon_state = "blackswan_closedr"
	else
		icon_state = "blackswan_r"
	visible_message(span_userdanger("[src] opens up their umbrella!"), span_notice("You open up your umbrella"))
	addtimer(CALLBACK(src, PROC_REF(CloseUmbrella)), SWAN_UMBRELLA_DURATION)

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/proc/CloseUmbrella()
	if(QDELETED(src))
		return
	umbrella_open = FALSE
	if(beak_closed)
		icon_state = "blackswan_closed"
	else
		icon_state = "blackswan"

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/proc/Wail()
	var/mutable_appearance/visual_overlay = mutable_appearance('icons/effects/effects.dmi', "blip")
	visual_overlay.pixel_x = -pixel_x
	visual_overlay.pixel_y = -pixel_y
	add_overlay(visual_overlay)
	can_act = FALSE
	if(do_after(src, 2 SECONDS, target = src))
		new /obj/effect/temp_visual/fragment_song(get_turf(src))
		var/list/turfs_to_check = orange(9, src)
		for(var/obj/vehicle/sealed/mecha/V in turfs_to_check)
			V.take_damage(70, WHITE_DAMAGE)
		for(var/mob/living/L in turfs_to_check)
			if(faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			L.deal_damage(70, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
		playsound(get_turf(src), 'sound/abnormalities/blackswan/sis_roar.ogg', 30, 0, 4)
	cut_overlay(visual_overlay)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/black_swan/proc/ReflectProjectile(obj/projectile/P) //reflection code from human_defense.dm
	if(P.starting)
		var/new_x = P.starting.x + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
		var/new_y = P.starting.y + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
		// redirect the projectile
		P.firer = src
		P.preparePixelProjectile(locate(clamp(new_x, 1, world.maxx), clamp(new_y, 1, world.maxy), z), src)

#undef SWAN_UMBRELLA_COOLDOWN
#undef SWAN_UMBRELLA_DURATION
