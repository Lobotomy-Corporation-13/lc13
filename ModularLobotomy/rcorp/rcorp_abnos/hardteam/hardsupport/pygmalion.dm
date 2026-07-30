//She cant even kill people on her own, the reason for support is obvious
/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion
	name = "Pygmalion"
	desc = "A tall statue of a humanoid abnormality in a pink dress holding a bouquet of light blue flowers. Whenever you see it hurt you feel like your soul hurts."
	ranged = TRUE
	ranged_cooldown_time = 2 SECONDS
	minimum_distance = 2
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	vision_range = 7
	del_on_death = FALSE
	move_to_delay = 4
	original_abno = /mob/living/simple_animal/hostile/abnormality/pygmalion

	var/retaliation = 10
	var/unfocused_talent_cooldown = 0
	var/unfocused_talent_delay = 10 SECONDS //AI Cooldown

	abno_additional_instructions = "<h1>You are Pygmalion, A Support Role Abnormality.</h1><br>\
		|Sculpted Matrimony|: You are unable to melee attack others, instead relying on ranged projectile attacks. \
		When performing a ranged attack you will summon 4 bolts behind you which you will then launch at your target for 25 WHITE each. \
		This attack has a cooldown of 2 seconds. <br>\
		<br>\
		|Heart Breaking|: Whenever you are attacked you will retaliate with 10 PALE to the attacker. <br>\
		<br>\
		|Unfocused Talent|: When used this ability will summon 3 motes that will move in a pattern around you. \
		Each mote does 50 WHITE to any hostiles it hits, allies are not affected by these motes. </b>"

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/cooldown/rca_unfocused_talent,)

/datum/action/cooldown/rca_unfocused_talent
	name = "Unfocused Talent"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "magicm"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 10 SECONDS //Player cooldown

/datum/action/cooldown/rca_unfocused_talent/Trigger()
	if(!..())
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/bride = owner
	if(!istype(bride))
		return FALSE
	if(!bride.client)
		return FALSE
	StartCooldown()
	bride.UnfocusedTalent()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/handle_automated_action()
	. = ..()
	if(stat == DEAD)
		return

	if(unfocused_talent_cooldown <= world.time)
		UnfocusedTalent()

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/CanAttack(atom/target)
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if (human_target.sanity_lost)
			return FALSE

	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/OpenFire()
	if(ranged_cooldown > world.time)
		return FALSE
	ranged_cooldown = world.time + ranged_cooldown_time
	var/tries = 8
	for(var/i = 1 to 4)
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		if(T.density)
			i -= 1
			tries--
			continue
		DeferProjectile(/obj/projectile/rca_bride_bolts, target, T, 3)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if((. <= 0) || (!isliving(source)) || (attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_STATUS | ATTACK_TYPE_ENVIRONMENT)))
		return
	CounterAttack(source)

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/proc/CounterAttack(mob/living/attacker)
	attacker.deal_damage(retaliation, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_COUNTER))
	to_chat(attacker, span_userdanger("You feel your heart break! Attacking Pygmalion is hurting you!"))

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/proc/UnfocusedTalent()
	var/our_turf = get_turf(src)
	unfocused_talent_cooldown = world.time + unfocused_talent_delay
	if(!our_turf)
		return
	var/list/directions = GLOB.cardinals.Copy()
	directions -= dir
	var/direction_pattern = FormatPattern()
	for(var/i = 1 to 3)
		var/turf/deploy = get_step(our_turf, pop(directions))
		if(deploy.density)
			continue
		var/obj/effect/ambient_danger/rca_pyg/P = new(deploy, faction, direction_pattern)
		if(!("neutral" in faction))
			P.color = "red"
	return direction_pattern

/mob/living/simple_animal/hostile/rcorp_abno/hard/pygmalion/proc/FormatPattern()
	var/list/return_list = list()
	//Gimme our cords. We arnt going to check anything on the turfs so just cords.
	var/originx = x
	var/originy = y
	for(var/cycle = 1 to 4)
		var/offsetx = 0
		var/offsety = 0
		var/turn_rate = 0
		var/initial_direction = NORTH
		switch(cycle)
			//South
			if(2)
				initial_direction = SOUTH
				offsety = -1
			//East
			if(3)
				initial_direction = EAST
				offsetx = 1
			//West
			if(4)
				initial_direction = WEST
				offsetx = -1
			//North
			else
				offsety = 1
		var/path_direction = initial_direction
		for(var/iteration = 1 to 5)
			var/x_tag = originx + offsetx
			var/y_tag = originy + offsety
			var/turf_tag = "[x_tag],[y_tag]"
			return_list += turf_tag
			turn_rate = turn_rate + 45
			path_direction = turn(initial_direction,turn_rate)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(locate(x_tag,y_tag,z), path_direction)
			return_list[turf_tag] = path_direction
			if(path_direction == NORTH || path_direction == NORTHWEST  || path_direction ==  NORTHEAST)
				offsety++
			if(path_direction == SOUTH  || path_direction ==  SOUTHWEST  || path_direction ==  SOUTHEAST)
				offsety--
			if(path_direction == EAST  || path_direction ==  NORTHEAST  || path_direction ==  SOUTHEAST)
				offsetx++
			if(path_direction == WEST  || path_direction ==  NORTHWEST  || path_direction ==  SOUTHWEST)
				offsetx--

	return return_list

/obj/effect/ambient_danger/rca_pyg
	name = "pygmalion mote"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bride_bolt"
	//Double that of the normal projectile due to the avoidability.
	damage = 50
	damage_type = WHITE_DAMAGE

/obj/projectile/rca_bride_bolts
	name = "mind bolts"
	desc = "A magic white bolt, enchanted to protect the sculptor."
	icon_state = "bride_bolt"
	damage_type = WHITE_DAMAGE

	damage = 25
	spread = 10

/obj/projectile/rca_bride_bolts/enraged
	desc = "A magic white bolt, enchanted to avenge the sculptor."
	icon_state = "bride_bolt_enraged"

	damage = 50
	spread = 5
