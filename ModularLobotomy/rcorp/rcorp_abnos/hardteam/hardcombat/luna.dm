//Combat abno because its absolutely fucking balling
/* Monster Half */
/mob/living/simple_animal/hostile/rcorp_abno/hard/luna
	name = "La Luna"
	desc = "A tall, cloaked figure. Seems to be immune to WHITE damage."
	icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
	icon_state = "luna"
	base_pixel_x = -8
	pixel_x = -8
	health = 2600
	maxHealth = 2600
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 32
	melee_damage_upper = 41
	rapid_melee = 2
	robust_searching = TRUE
	ranged = TRUE
	threat_level = WAW_LEVEL
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "beats"
	attack_verb_simple = "beat"
	attack_sound = 'sound/weapons/teasmack.ogg'
	can_patrol = TRUE
	var/aoeactive
	var/canaoe = TRUE
	var/aoerange = 5
	var/aoedamage = 60
	var/datum/looping_sound/laluna/soundloop

	abno_additional_instructions = "<h1>You are La Luna, A Combat Role Abnormality.</h1><br>\
		<b>|La Luna|: You are immune to WHITE damage.<br>\
		<br>\
		|Moonlight Sonata|: Upon spawning you will begin to play the Third Movement of Beethoven's Moonlight Sonata, this can be heard within a 45 tile range of your location.<br>\
		<br>\
		|Il Pianto|: When attempting to perform a ranged attack initiate a 11x11 AOE centered around yourself that does BLACK to all enemies afflicted. \
		This AOE has short cooldown and may be initiated again almost immediately after it's end. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/Initialize()
	..()
	soundloop = new(list(src), FALSE)
	soundloop.start()	//Let the people know.

/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/Destroy()
	soundloop.start()	//Dont let the people know
	QDEL_NULL(soundloop)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/Move()
	if(aoeactive)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/OpenFire()
	if(!canaoe)
		return
	aoeactive = TRUE
	canaoe = FALSE
	playsound(src, 'sound/magic/wandodeath.ogg', 200, FALSE, 9)
	addtimer(CALLBACK(src, PROC_REF(AOE)), 9)
	addtimer(CALLBACK(src, PROC_REF(Reset)), 7 SECONDS)


/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/proc/AOE()
	for(var/turf/T in view(aoerange, src))
		new /obj/effect/temp_visual/revenant(T)
		HurtInTurf(T, list(), aoedamage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_SPECIAL))
	aoeactive = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/luna/proc/Reset()
	canaoe = TRUE
