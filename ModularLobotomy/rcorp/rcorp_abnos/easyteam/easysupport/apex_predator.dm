/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator
	name = "Apex Predator"
	desc = "An abnormality resembling a beaten up crash dummy."
	maxHealth = 1600
	health = 1600
	density = FALSE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	ranged = TRUE
	melee_damage_lower = 30
	melee_damage_upper = 40
	move_to_delay = 3
	melee_damage_type = RED_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/apex_predator

	var/revealed = TRUE
	var/backstab_damage = 200

	var/jumping	//Used so it can only start one jump at once
	var/busy	//Can we move now?

	var/jump_cooldown
	var/jump_cooldown_time = 5 SECONDS
	var/jump_damage = 60

	var/recloak_time = 0
	var/recloak_time_cooldown = 30 SECONDS

	abno_additional_instructions = "<h1>You are Apex Predator, A Support/Combat Role Abnormality.</h1><br>\
		<b>|Adaptation|: You possess two modes as Apex Predator, Hunting and Eliminating. \
		You will automatically enter Hunting mode upon joining the round.<br>\
		<br>\
		|Hunting|: When within hunting mode you are near entirely invisible and non-dense.\
		While non-dense you may walk through other living beings and avoid projectiles which are not directly aiming for you. \
		If performing a attack, or being attacked by a melee weapon or projectile you will be taken out of Hunting mode and enter Eliminating mode<br>\
		<br>\
		|Behind You|: When attempting to perform a melee attack while in Hunting mode you will reveal yourself and enter Eliminating before attempting a backstab.\
		Your target is given 1 second to respond, if they do not exit melee range within this timeframe they will be backstabbed for high RED damage.\
		You may also perform backstabs on mechs however this requires you to stand behind the direction they're currently facing.\
		If you successfully perform a backstab on your target you will re-enter Hunting mode after 2 seconds, being cloaked once more. \
		If you fail to perform a backstab you will enter Hunting mode and immediately perform a Leap instead. <br>\
		<br>\
		|Eliminating|: When revealed from Hunting mode causing the loss of cloak you will enter Eliminating Mode\
		When within Eliminating mode you gain the ability to Leap, when attempting a ranged attack you will initiate the Leap at the targetted tile.\
		Upon leaping to the target you will initiate a 3x3 Slam attack centered around yourself.<br>\
		<br>\
		|Calculating|: After 30 seconds of Eliminating mode you will automatically switch to Hunting mode being cloaked once again.</b>"


/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/Login()
	..()
	Cloak()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/examine(mob/user)
	. = ..()
	if(revealed)
		. += "You hear constant calculations coming from it as it's movements accelerate, neutralize it before it stabilizes."
	else
		. += "Their form is difficult to grasp due to the camoflauge, best disrupt it with damage."

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/Move()
	if(notransform)
		return ..()
	if(busy)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/Life()
	. = ..()
	if(. && revealed && recloak_time < world.time)
		Cloak()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	if(faction_check_mob(attacked_target))
		to_chat(src, span_notice("This is not our prey."))
		return
	if(!revealed)
		//Will want this to be crazy
		say("Behind you.")

		SLEEP_CHECK_DEATH(7)
		Decloak()
		SLEEP_CHECK_DEATH(3)
		//Backstab
		if(attacked_target in range(1, src))
			if(isliving(attacked_target))
				var/mob/living/V = attacked_target
				visible_message(span_danger("The [src] rips out [attacked_target]'s guts!"))
				new /obj/effect/gibspawner/generic(get_turf(V))
				V.deal_damage(backstab_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			//Backstab succeeds from any one of 3 tiles behind a mecha, backstab from directly behind gets boosted by mecha directional armor weakness
			else if(ismecha(attacked_target))
				var/relative_angle = abs(dir2angle(attacked_target.dir) - dir2angle(get_dir(attacked_target, src)))
				relative_angle = relative_angle > 180 ? 360 - relative_angle : relative_angle
				if(relative_angle >= 135)
					visible_message(span_danger("The [src] shreds [attacked_target]'s armor!"))
					var/obj/vehicle/sealed/mecha/M = attacked_target
					M.take_damage(backstab_damage, RED_DAMAGE, attack_dir = get_dir(M, src))
					new /obj/effect/temp_visual/kinetic_blast(get_turf(M))
				else
					visible_message(span_danger("The [src]'s attack misses [attacked_target]'s weakspots!"))
					..()
			else
				..()
			SLEEP_CHECK_DEATH(20)
			Cloak()
			//Remove target
			FindTarget()
		else
			if(!jumping)
				if(!target)
					GiveTarget(attacked_target)
				Jump()
		return
	..()

//Getting hit decloaks
/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/attackby(obj/item/I, mob/living/user, params)
	..()
	Decloak()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/bullet_act(obj/projectile/P)
	..()
	Decloak()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Cloak()
	alpha = 10
	revealed = FALSE
	density = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Decloak()
	recloak_time = world.time + recloak_time_cooldown
	alpha = 255
	revealed = TRUE
	density = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/OpenFire()
	if(!revealed)
		return

	//For readability
	if(!jumping && (jump_cooldown < world.time) && !(status_flags & GODMODE))
		Jump()

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Jump()
	jumping = TRUE
	busy = TRUE
	icon_state = "apex_crouch"
	addtimer(CALLBACK(src, PROC_REF(Leap)), 5)

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Leap()
	density = FALSE
	var/turf/target_turf = get_turf(target)
	playsound(src, 'sound/weapons/fwoosh.ogg', 300, FALSE, 9)
	notransform = TRUE
	throw_at(target_turf, 7, 1, src, FALSE, callback = CALLBACK(src, PROC_REF(Slam)))
	icon_state = "apex_leap"

	addtimer(CALLBACK(src, PROC_REF(Slam)), 10)

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Slam()
	notransform = FALSE
	icon_state = "apex_crouch"
	playsound(src, 'sound/effects/meteorimpact.ogg', 300, FALSE, 9)
	for(var/turf/T in range(1, src))
		HurtInTurf(T, list(), jump_damage, RED_DAMAGE, null, TRUE, FALSE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		new /obj/effect/temp_visual/kinetic_blast(T)
	addtimer(CALLBACK(src, PROC_REF(Reset)), 12)

/mob/living/simple_animal/hostile/rcorp_abno/easy/apex_predator/proc/Reset()
	density = TRUE
	busy = FALSE
	jumping = FALSE
	icon_state = "apex"
	jump_cooldown = world.time + jump_cooldown_time
