//In combat due to being a frontliner, wants to evade to heal, wants to be at the front due to spammable low damage projectiles
/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood
	name = "Little Red Riding Hooded Mercenary"
	desc = "A tall humanoid in ragged red robes. Seems obsessed with a wolf of sorts, this can be leveraged if needed."
	maxHealth = 2400 // More health than standard
	health = 2400 // Since she was apparently too easy to suppress
	rapid_melee = 2
	speed = 0.5
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5) // Fuck you, blue shepherd.
	ranged = TRUE
	melee_damage_lower = 30
	melee_damage_upper = 45
	melee_damage_type = RED_DAMAGE
	density = FALSE // the no density is her trademark now
	status_flags = MUST_HIT_PROJECTILE // Allows projectiles to hit even though she's not dense.
	original_abno = /mob/living/simple_animal/hostile/abnormality/red_hood

	//General idea for things
	//With the wolf, she will instantly enrage, and continue enraged once he's dead if she didn't see the killing blow. Otherwise, de-enrage.
	//With a lone Buddy, she will enrage if brought to 80% HP, then de-enrage even if she doesn't see the killing blow, because she'll see through the ruse.
	//If Blue Smocked Shepherd is within range of the above interaction, she will enrage against him, but de-enrage even if she doesn't get the kill.

	var/kill_confirmed = FALSE //Checks if you killed wolf infront of her or not
	var/raging = FALSE //Keeps rage from needlessly updating by showing its already active
	var/red_rage = 0 // Goes up to 3; 1 for "weak rage" (against buddy and blue), 2 for "strong rage" (against wolf), 3 for "aimless rage" (denied wolf kill)
	var/special_attacking = FALSE // Are you currently performing a special attack
	var/special_windup = 8 // How many deciseconds between showing a tell for a special attack and using it
	var/evade_timer = 0
	var/evade_cooldown = 5 SECONDS // Doubled on failed evade
	var/evading_attack = FALSE // Are you currently EVADING damage
	var/gun_timer = 0
	var/gun_cooldown = 5 SECONDS
	var/gun_multishot_pause = 2.5 // How long to pause between shots in a volley
	var/bullet_additional = 0 // How many extra times to shoot
	var/bullet_damage = 30 // How much damage each hollowpoint shell does
	var/throw_timer = 0
	var/throw_cooldown = 11 SECONDS
	var/throw_amount = 3 // How many blades to throw at once
	var/throw_cone = 25 // Total firing angle of all red's projectiles.
	var/throw_damage = 40 // Damage of each thrown blade
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/big_wolf/rival

	var/list/wolf_encounter_lines = list( // Encountering Big and Will Be Bad Wolf
		"Found you, you bastard!",
		"I'll have your head!",
		"You won't get away this time!"
	)
	var/list/denied_kill_lines = list( // After being denied the killing blow on Wolf. Randomly during rage level 3.
		"HE WAS MINE!!",
		"YOU BASTARDS!!",
		"I'LL KILL EVERY LAST ONE OF YOU!!"
	)

	var/list/buddy_encounter_lines = list( // Will find a way to use when adding Buddy to RCA
		"A wolf?! But I didn't...",
		"Right now?! How did...",
		"No... I couldn't have..."
	)

	var/list/blue_evade_lines = list( // Evading blue's AOE while fighting something else.
		"Watch it!",
		"Idiot!",
		"What are you aiming at?!",
		"Get your eye checked."
	)

	var/list/blue_evade_taunt_lines = list( // Evading blue's AOE while hostile to him.
		"You're slow!",
		"What's the matter, scared?",
		"Get your eye checked." //The eye isnt duped its just her favourite insult
	)

	var/list/weapon_throw_lines = list( // Using the weapon throw attack.
		"No hesitation!",
		"You're dead!",
		"Eat this!"
	)

	attack_action_types = list(
	/datum/action/innate/rca_abnormality_attack/catch_breath,
	/datum/action/innate/rca_abnormality_attack/hollowpoint_shell,
	/datum/action/innate/rca_abnormality_attack/strike_without_hesitation,
	)

	abno_additional_instructions = "<h1>You are Little Red Riding Hooded Mercenary, A Combat Role Abnormality.</h1><br>\
		<b>|Beast Hunt|: When attacked in melee automatically retaliate with your own melee attack. \
		When moving you may go past others instead of being blocked. <br>\
		<br>\
		|Catch Breath|: When activating your Evade ability you will avoid all attacks for 2 seconds. \
		Upon evading a attack you will heal 2% (50) of your HP, this may be triggered multiple times in one evade. \
		Your evade cooldown is 5 seconds, however if you made no evasions while your Evade was active the cooldown is doubled to 10 secodns. <br>\
		<br>\
		|Hollow-Point Shell|: When you perform a ranged attack with this ability selected you will raise your gun and immobilize yourself before firing 1 hollow-point shell. \
		This hollow-point shell will deal 40 RED damage on impact with target. \
		If 'Rage' is active you will fire 3 hollow-point shells instead. \
		The cooldown of this attack is 5 seconds, if 'Rage' is active cooldown is reduced to 3 seconds. <br>\
		<br>\
		|Strike Without Hesitation|: When you perform a ranged attack with this ability selected you will throw 3 scythe axes in a spread. \
		These scythe axes will deal 40 RED damage on impact and pierce any targets they hit continuing to travel in their trajectory. \
		If 'Rage' is active you will throw 5 scythe axes in a greater cone instead. \
		The cooldown of this attack is 11 seconds, if 'Rage' is active cooldown is reduced to 8 seconds. <br>\
		<br>\
		|Rage|: If your health is below 80% and you are hit by a attack from 'Big and Will be Bad Wolf' or 'Reddened Buddy' you will enter a Rage state. \
		While Rage is active your speed and melee attack speed drastically increase, all your attacks are also buffed. \
		When the source of your Rage is killed (depending on circumstance) it is possible that Rage will be cancelled and you will return to your default state. <br>\
		<br>\
		|Fury with No Outlet|: If in a 'Rage' state caused by 'Big and Will be Bad Wolf' your Rage may be removed through seeing his death. \
		If 'Big and Will be Bad Wolf' dies outside of view you will trigger this passive. \
		While this passive is active your 'Rage' will not be dispelled and all your resistances except PALE will be doubled. </b>"

/datum/action/innate/rca_abnormality_attack/catch_breath // AI-controlled Red technically doesn't use this one EITHER.
	name = "Evade"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "ruina_evade"
	chosen_message = span_danger("You prepare to avoid an incoming attack.")
	chosen_attack_num = 2

/datum/action/innate/rca_abnormality_attack/catch_breath/Activate()
	addtimer(CALLBACK(A, TYPE_PROC_REF(/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood, AttemptEvade)), 1)
	to_chat(A, chosen_message)

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/AttemptEvade()
	if((world.time < evade_timer) || evading_attack)
		if(client)
			to_chat(src, span_danger(" You can't do that now!"))
		return FALSE
	evading_attack = TRUE
	addtimer(CALLBACK(src, PROC_REF(EndEvade)), 20)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/PreDamageReaction(damage_amount, damage_type, source, attack_type)
	if(evading_attack)
		evading_attack = FALSE
		EndEvade()
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(health > (maxHealth * 0.8))
		return
	if(istype(source, rival))
		RageUpdate(2)
/*	else if(istype(source, /mob/living/simple_animal/hostile/abnormality/red_buddy) && red_rage < 1) //Red buddy isnt in RCA yet
		RageUpdate(1) */ //Buddy update any day now

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/WatchIt() // Evade Blue's indiscriminate attacks, just to fuck him even harder.
	if(red_rage < 2)
		say(pick(blue_evade_lines))
	else
		say(pick(blue_evade_taunt_lines))
	manual_emote("acrobatically spins out of the way.")
	SpinAnimation(7, 1)
	adjustBruteLoss(-50)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/RageUpdate(rage_change) // Always call this after changing red_rage manually, or call it to change red_rage
	if(red_rage >= 3) //Never back down after enraging
		return
	if(rage_change)
		red_rage = rage_change
	if(red_rage == 2)
		say(pick(wolf_encounter_lines))
	if(red_rage == 3)
		ChangeResistances(list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5)) // She takes... very little damage.
	if(red_rage > 0 && !raging) //Normal rage
		raging = TRUE
		speed = 0
		rapid_melee = 3
		gun_cooldown = 3 SECONDS
		bullet_additional = 2
		throw_cooldown = 8 SECONDS
		throw_amount = 5
		throw_cone = 35
		color = rgb(255, 64, 64)
		set_light(1, 8, COLOR_VIVID_RED)
		set_light_on(TRUE)
		update_light()
	else
		raging = FALSE
		ChangeResistances(list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5)) // She takes normal damage now
		speed = initial(speed)
		rapid_melee = initial(rapid_melee)
		gun_cooldown = initial(gun_cooldown)
		bullet_additional = initial(bullet_additional)
		throw_cooldown = initial(throw_cooldown)
		throw_amount = initial(throw_amount)
		throw_cone = initial(throw_cone)
		color = initial(color)
		set_light()
		set_light_on(FALSE)
		update_light()

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/EndEvade()
	if(evading_attack)
		evading_attack = FALSE
		visible_message(span_notice("[src] seems out of breath!"), span_warning("You didn't dodge anything!"))
		evade_timer = world.time + evade_cooldown * 2
		return
	SpinAnimation(7, 1)
	visible_message(span_notice("[src] evades the attack!"), span_nicegreen("You evade the attack!"))
	adjustBruteLoss(-50) // Recover a little HP for your dodge
	evade_timer = world.time + evade_cooldown
	return

/datum/action/innate/rca_abnormality_attack/hollowpoint_shell
	name = "Hollowpoint Shell"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "hollowpoint_ability"
	chosen_message = span_danger("You will now fire at whatever you next click on.")
	chosen_attack_num = 3

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/Hollowpoint(atom/target) // Fire a round in the direction of the enemy. When enraged, shoot multiple times.
	if(world.time < gun_timer)
		if(client)
			to_chat(src, span_danger("You can't do that now!"))
		return FALSE
	special_attacking = TRUE
	gun_timer = world.time + gun_cooldown
	addtimer(CALLBACK(src, PROC_REF(SpecialReset)), 10 + bullet_additional * gun_multishot_pause)
	manual_emote("raises her gun.")
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	icon_state = "redhood_shoot"
	icon_living = "redhood_shoot"
	pixel_x = -32
	base_pixel_x = -32
	addtimer(CALLBACK(src, PROC_REF(HunterBullet), target, bullet_additional), special_windup * 0.75)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/HunterBullet(atom/target, shots_remaining = 0)
	var/turf/startloc = get_turf(src)
	var/angle_to_target = Get_Angle(src, target)
	var/obj/projectile/rca_red_hollowpoint/P = new(get_turf(src))
	P.starting = startloc
	P.firer = src
	P.fired_from = src
	P.Angle = angle_to_target
	P.original = target
	P.preparePixelProjectile(target, src)
	P.damage = bullet_damage
	P.fire()
	playsound(src, 'sound/abnormalities/redhood/fire.ogg', 50, FALSE, 4)
	if(shots_remaining)
		addtimer(CALLBACK(src, PROC_REF(HunterBullet), target, shots_remaining - 1), gun_multishot_pause)
	return

/datum/action/innate/rca_abnormality_attack/strike_without_hesitation
	name = "Blade Throw"
	icon_icon = 'icons/obj/projectiles.dmi'
	button_icon_state = "hunter_blade"
	chosen_message = span_danger("You will throw a spread of blades at whatever you next click on.")
	chosen_attack_num = 4

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/BladeThrow(atom/target) // Throw a barrage of piercing blades in the direction of the enemy.
	if(throw_timer > world.time)
		if(client)
			to_chat(src, span_danger("You can't do that now!"))
		return FALSE
	special_attacking = TRUE
	addtimer(CALLBACK(src, PROC_REF(SpecialReset)), 15)
	throw_timer = world.time + throw_cooldown
	say(pick(weapon_throw_lines))
	addtimer(CALLBACK(src, PROC_REF(GetThrown), target), special_windup)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/GetThrown(atom/target)
	playsound(src, 'sound/abnormalities/redhood/throw.ogg', 50, FALSE, 4)
	var/turf/startloc = get_turf(src)
	var/angle_to_target = Get_Angle(src, target)
	var/projectile_angle_difference = (throw_cone / (throw_amount - 1))
	for(var/i = 0 to throw_amount - 1) // Create throw_amount projectiles evenly spaced across an arc of throw_cone degrees centered aiming at enemy, and fire them.
		var/obj/projectile/rca_hunter_blade/P = new(get_turf(src))
		P.nondirectional_sprite = TRUE
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.original = target
		P.preparePixelProjectile(target, src)
		P.damage = throw_damage
		P.fire(angle_to_target - (throw_cone / 2) + projectile_angle_difference * i)

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/SpecialReset()
	special_attacking = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
	icon_state = "red_hood"
	icon_living = "red_hood"
	pixel_x = -8
	base_pixel_x = -8

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/Move()
	if(special_attacking)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/Initialize()
	. = ..()
	RegisterSignal(rival, COMSIG_LIVING_DEATH, PROC_REF(NightmareEnd))

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/Destroy()
	UnregisterSignal(rival, COMSIG_LIVING_DEATH)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/attacked_by(obj/item/I, mob/living/user)
	say(pick(blue_evade_lines))
	user.attack_animal(src)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/OpenFire()
	if(special_attacking || evading_attack)
		return FALSE
	if(client)
		switch(chosen_attack)
			if(1, 2)
				return FALSE // this should never be the case, 1 isn't an attack, but for safety...
			if(3)
				Hollowpoint(target)
			if(4)
				BladeThrow(target)
		return
	if(world.time > gun_timer && prob(85)) // She usually goes for the gun first
		Hollowpoint(target)
		return
	if(world.time > throw_timer && prob(45)) // Then if she doesn't, chance to use blades
		BladeThrow(target)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/red_hood/proc/NightmareEnd()
	for(rival in view(src, 10))
		if(rival.stat != DEAD)
			return
		say("Finally, the nightmare is over... I'll go a bit easier on ya for killing that bastard.")
		RageUpdate(0)
		kill_confirmed = TRUE //Wolf died in our view
	if(!kill_confirmed) //Somehow we completed the contract but the wolf was too far away. Likely died off-screen
		say(pick(denied_kill_lines))
		RageUpdate(3)
		return

/obj/projectile/rca_hunter_blade
	name = "hunter's scythe"
	desc = "A weapon thrown with deadly accuracy."
	icon_state = "hunter_blade_animated"
	projectile_piercing = PASSMOB
	range = 10
	nondirectional_sprite = TRUE
	speed = 1
	pixel_y = 16
	hitsound = 'sound/abnormalities/redhood/attack_2.ogg'

/obj/projectile/rca_red_hollowpoint
	name = "hollowpoint shell"
	desc = "A bullet fired from a red-cloaked mercenary's ruthless weapon."
	icon_state = "loyalty"
	range = 15
	speed = 0.6
	spread = 10
	pixel_y = 30
