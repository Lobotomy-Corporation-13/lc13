/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream
	name = "Void Dream"
	desc = "A very fluffy floating sheep. Looking at it leaves you sleepy, if feeling too sleepy get someone to shake you."
	is_flying_animal = TRUE
	del_on_death = FALSE
	maxHealth = 600
	health = 600
	rapid_melee = 2
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	original_abno = /mob/living/simple_animal/hostile/abnormality/voiddream

	var/ability_cooldown
	var/ability_cooldown_time = 12 SECONDS

	abno_additional_instructions = "<h1>You are Void Dream, A Support Role Abnormality.</h1><br>\
		<b>|Dream Cloud|: Due to your capability to float you may fly over certain obstacles, useful around chasms.<br>\
		<br>\
		|Engulfing Dream|: Every 12 seconds you will automatically fire a projectile at any hostile non-sleeping human. \
		This projectile will have slight homing onto the closest valid target within 9 tiles. \
		Upon hitting it's target it will put them to sleep for 30 seconds. \
		This projectile will do nothing to non-human entities it hits. \
		</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/PickTarget(list/Targets)
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/death()
	..()
	animate(src, alpha = 0, time = 5)
	QDEL_IN(src, 5)

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/Life()
	. = ..()
	if(!.)
		return
	PerformAbility()

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/proc/PerformAbility()
	if(ability_cooldown > world.time)
		return
	ability_cooldown = world.time + ability_cooldown_time
	INVOKE_ASYNC(src, PROC_REF(SleepyDart))

/mob/living/simple_animal/hostile/rcorp_abno/easy/voiddream/proc/SleepyDart()
	var/list/possibletargets = list()
	for(var/mob/living/carbon/human/H in view(10, src))
		if(faction_check_mob(H))
			continue
		if(H.IsSleeping())
			continue
		if(H.stat >= SOFT_CRIT)
			continue
		possibletargets += H
	if(!LAZYLEN(possibletargets))
		return

	playsound(get_turf(src), 'sound/abnormalities/voiddream/fire.ogg', 50, TRUE)
	var/obj/projectile/P = new /obj/projectile/rca_sleepdart(get_turf(src))
	P.firer = src
	var/bullet_target = pick(possibletargets)
	P.original = bullet_target
	P.fire(Get_Angle(src, bullet_target))

// Projectile code
/obj/projectile/rca_sleepdart
	name = "void dream"
	icon_state = "antimagic"
	color = "#FCF344"
	damage = 0
	speed = 3
	homing = TRUE
	homing_turn_speed = 25 //Angle per tick.
	var/homing_range = 9

/obj/projectile/rca_sleepdart/Initialize()
	. = ..()
	var/list/targetslist = list()
	for(var/mob/living/carbon/human/H in view(homing_range, src))
		if(H.IsSleeping())
			continue
		targetslist += H
	if(!LAZYLEN(targetslist))
		return
	homing_target = pick(targetslist)

/obj/projectile/rca_sleepdart/on_hit(atom/target, blocked = FALSE)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	if(H.IsSleeping())
		return
	H.SetSleeping(30 SECONDS) // Used to be a full minute
	var/datum/status_effect/incapacitating/sleeping/S = H.IsSleeping()
	S.remove_on_damage = TRUE
	playsound(get_turf(H), 'sound/abnormalities/voiddream/skill.ogg', 50, TRUE)
