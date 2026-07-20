/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd
	maxHealth = 1200
	health = 1200
	desc = "A strange humanoid in blue robes. They seem poised to counter careless hits, avoid being predictable"
	rapid_melee = 2
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	melee_damage_lower = 22
	melee_damage_upper = 30
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/blue_shepherd

	var/slash_current = 4
	var/slash_cooldown = 4
	var/slash_damage = 40
	//Disables movement and attacks.
	var/slashing = FALSE
	var/range = 2

	//Here's for the large slash
	var/cleave_width = 2
	var/cleave_length = 3
	var/cleave_damage = 60
	var/cleave_delay = 6
	var/cleave_pause = 5

	//vars that do nothing until buddy is added to RCA
	var/mob/living/simple_animal/hostile/abnormality/red_buddy/awakened_buddy
	var/awakened = FALSE //if shepherd has seen red buddy or not
	var/buddy_hit = FALSE
	var/red_hit = FALSE // Controls Little Red Riding Hooded Mercenary's ability to be "hit" by slash attacks

	var/list/combat_lines = list(
		"Have at you!",
		"Take this!",
		"I'll kill you!",
		"This is for locking me up!",
		"Die!",
		"I'll cut you down!",
		"Get out of my way!",
		"Try and stop me!",
		"You can't keep me here forever!",
		"You'll regret this!"
	)

	var/no_counter = FALSE
	var/sidesteping = FALSE
	var/countering = FALSE
	/// This one keeps track of whether we've already counterattacked during our parry. This is so we can block multiple instances of damage during our parry, but only riposte once.
	var/riposted = FALSE
	var/counter_damage = 20
	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/toggle/sheperd_spin_toggle, /datum/action/cooldown/rca_evade, /datum/action/cooldown/rca_parry)

	abno_additional_instructions = "<h1>You are Blue Shepherd, A Combat Role Abnormality.</h1><br>\
		<b>|Slayer|: When you attack, if your spin attack is off cooldown you will use it. \
		Your spin attack is a 5x5 AoE centered around you, which deals medium BLACK damage. \
		You are able to toggle your spin attack on and off with your ability.<br>\
		<br>\
		|Sidestep|: You are able to trigger your 'Dodge' ability using the button on the top left of your screen, \
		Or you can use a hotkey. (Which is Spacebar by default). When you trigger your 'Dodge' ability you will gain a speed boost and lose density (Bullet will pass through you.) for 1 second. \
		Once the speed boost ends, you will be slowed down for 1.5 seconds.<br>\
		<br>\
		|Counter|: You are able to trigger your 'Counter' ability using the button on the top left of your screen, \
		Or you can use a hotkey. (Which is E by default). When you trigger your 'Counter' ability, If you take damage within the next second you will trigger a 5x5 AoE which deals BLACK damage. \
		Also, Anyone hit by this AoE will knockdown all humans who are hit by it.\
		</b>"

/datum/action/cooldown/rca_evade
	name = "Dodge"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "ruina_evade"
	desc = "Gain a short speed boost evade your foes!"
	cooldown_time = 30
	var/speeded_up = 2
	var/restspeed = 4
	var/speed_duration = 10
	var/weaken_duration = 15
	var/old_speed

/datum/action/cooldown/rca_evade/Trigger()
	if(!..())
		return FALSE
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd))
		var/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/H = owner
		old_speed = 3
		H.move_to_delay = speeded_up
		H.UpdateSpeed()
		H.sidesteping = TRUE
		H.density = FALSE
		H.no_counter = TRUE
		addtimer(CALLBACK(src, PROC_REF(slowdown)), speed_duration)
		StartCooldown()

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/Moved()
	. = ..()
	if (sidesteping)
		MoveVFX()

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/MoveVFX()
	set waitfor = FALSE
	var/obj/viscon_filtereffect/distortedform_trail/trail = new(src.loc,themob = src, waittime = 5)
	trail.vis_contents += src
	trail.filters += filter(type="drop_shadow", x=0, y=0, size=3, offset=2, color=rgb(0, 250, 229))
	trail.filters += filter(type = "blur", size = 3)
	animate(trail, alpha=120)
	animate(alpha = 0, time = 10)

/datum/action/cooldown/rca_evade/proc/slowdown()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd))
		var/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/H = owner
		H.move_to_delay = restspeed
		H.density = TRUE
		H.sidesteping = FALSE
		addtimer(CALLBACK(src, PROC_REF(recover)), weaken_duration)
		H.UpdateSpeed()

/datum/action/cooldown/rca_evade/proc/recover()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd))
		var/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/H = owner
		H.move_to_delay = old_speed
		H.no_counter = FALSE
		H.UpdateSpeed()

/datum/action/cooldown/rca_parry
	name = "Counter"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "hollowpoint_ability"
	desc = "Predict an attack, to deal damage to your foes!"
	cooldown_time = 100
	var/counter_duration = 1 SECONDS

/datum/action/cooldown/rca_parry/Trigger()
	if(!..())
		endcounter()
		return FALSE
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd))
		var/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/H = owner
		if(H.no_counter)
			to_chat(H, "You are currently dodging!")
			endcounter()
			return FALSE
		else
			H.countering = TRUE
			H.riposted = FALSE
			H.manual_emote("raises their blade...")
			H.color = "#26a2d4"
			playsound(H, 'sound/items/unsheath.ogg', 75, FALSE, 4)
			addtimer(CALLBACK(src, PROC_REF(endcounter)), counter_duration)
			StartCooldown()

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/PreDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if((!countering) || (attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))) // We don't parry these types of attacks.
		return
	if(!riposted)
		riposted = TRUE
		INVOKE_ASYNC(src, PROC_REF(counter))
	return FALSE // Damage of the types not checked in the first conditional is prevented on us for as long as 'countering' is true.

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/counter()
	var/list/been_hit = list()
	say(pick(combat_lines))
	playsound(src, 'sound/weapons/fixer/generic/finisher2.ogg', 75, TRUE, 2)
	for(var/turf/T in range(2, src))
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, counter_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, mech_damage = 15, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_COUNTER))
		for(var/mob/living/carbon/human/H in T)
			H.Knockdown(20)

/datum/action/cooldown/rca_parry/proc/endcounter()
	if(istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd))
		var/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/H = owner
		H.countering = FALSE
		H.slashing = FALSE
		H.color = null

/datum/action/innate/rca_abnormality_attack/toggle/sheperd_spin_toggle
	name = "Toggle Spinning Slash"
	button_icon_state = "sheperd_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You won't spin anymore.")
	button_icon_toggle_activated = "sheperd_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will now execute a spinning slash when ready.")
	button_icon_toggle_deactivated = "sheperd_toggle0"

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/AttackingTarget(atom/attacked_target)
	. = ..()
	if(client)
		switch(chosen_attack)
			if(1)
				if(isliving(attacked_target))
					slash_current-=1
				return OpenFire()
			if(2)
				return
		return

	slash_current-=1
	if(slash_current == 0)
		slash_current = slash_cooldown
		slashing = TRUE
		switch(rand(1,3))
			if(1)
				say(pick(combat_lines))
				slash()
			if(2)
				say(pick(combat_lines))
				cleave(target)
			if(3)
				TriggerCounter()

	if(awakened_buddy)
		awakened_buddy.GiveTarget(attacked_target)

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/OpenFire()
	if(prob(10))
		TriggerDodge()
	if(slash_current == 0)
		slash_current = slash_cooldown
		switch(rand(1,3))
			if(1)
				say(pick(combat_lines))
				slash()
			if(2)
				say(pick(combat_lines))
				cleave(target)
			if(3)
				TriggerCounter()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/CanAttack(atom/the_target)
	if(slashing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/slash()
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	playsound(src, 'sound/weapons/slice.ogg', 75, FALSE, 4)
	var/trigger_timer = FALSE
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			else
				trigger_timer = TRUE
				addtimer(CALLBACK(src, PROC_REF(SlashHit), T, all_turfs, i, buddy_hit), (3 * (i+1)) + 0.5 SECONDS)
	if(!trigger_timer)
		slashing = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/SlashHit(turf/T, list/all_turfs, slash_count, buddy_hit)
	if(stat == DEAD)
		slashing = FALSE
		return
	new /obj/effect/temp_visual/smash_effect(T)
	for(var/mob/living/L in HurtInTurf(T, list(), slash_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, break_not_destroy = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
		if(L == awakened_buddy && !buddy_hit)
			buddy_hit = TRUE //sometimes buddy get hit twice so we check if it got hit in this slash
			awakened_buddy.adjustHealth(700) //it would take approximatively 9 slashes to take buddy down
			break
	//Will be done when Im done making red hood
	/*	if(istype(L, /mob/living/simple_animal/hostile/rcorp_abno/hardcombat/red_hood))
			if(!red_hit)
				red_hit = TRUE
				var/mob/living/simple_animal/hostile/rcorp_abno/hardcombat/red_hood/current_red = L
				current_red.WatchIt() */
			all_turfs -= T
			continue // Red doesn't get hit.
		L.deal_damage(slash_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		all_turfs -= T
	if(slash_count >= range)
		buddy_hit = FALSE
		slashing = FALSE
		range = 2

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/cleave(target)
	if (get_dist(src, target) > 3)
		slashing = FALSE
		return

	//Turfs we will be hitting
	var/turf/area_of_effect = list()
	//We need 2 numbers. The lower left and the upper right of the square.
	//Lower Left
	var/offsetx1 = 0
	var/offsety1 = 0
	//Upper Right
	var/offsetx2 = 0
	var/offsety2 = 0
	//Give me where theoretically the center of the turf we would be hitting be.
	//Gimme a direction.
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	switch(dir_to_target)
		if(EAST)
			offsetx1 = 1
			offsety1 = -cleave_width
			offsetx2 = cleave_length
			offsety2 = cleave_width
		if(WEST)
			offsetx1 = -cleave_length
			offsety1 = -cleave_width
			offsetx2 = -1
			offsety2 = cleave_width
		if(SOUTH)
			offsetx1 = -cleave_width
			offsety1 = -cleave_length
			offsetx2 = cleave_width
			offsety2 = -1
		if(NORTH)
			offsetx1 = -cleave_width
			offsety1 = 1
			offsetx2 = cleave_width
			offsety2 = cleave_length
		else
			slashing = FALSE
			return

	//Give me ONLY the turfs between these cords
	area_of_effect = block(x+offsetx1,y+offsety1,z,x+offsetx2,y+offsety2)
	if (!LAZYLEN(area_of_effect))
		slashing = FALSE
		return
	dir = dir_to_target
	playsound(src, 'sound/weapons/etherealmiss.ogg', 100, FALSE, 4)
	SLEEP_CHECK_DEATH(cleave_delay)
	icon_state = icon_living
	var/list/been_hit = list()
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, cleave_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(src, 'sound/weapons/slice.ogg', 75, FALSE, 4)
	SLEEP_CHECK_DEATH(cleave_pause)
	slashing = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/TriggerDodge()
	var/triggered = FALSE
	for(var/datum/action/cooldown/evade/A in actions)
		if(A)
			triggered = TRUE
			A.Trigger()
	if(!triggered)
		slashing = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easycombat/blue_shepherd/proc/TriggerCounter()
	var/triggered = FALSE
	for(var/datum/action/cooldown/parry/A in actions)
		if(A)
			triggered = TRUE
			A.Trigger()
	if(!triggered)
		slashing = FALSE
