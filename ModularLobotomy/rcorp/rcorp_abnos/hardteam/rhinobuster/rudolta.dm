//Does white on every pulse, very evil and such, this pierces rhinos so its rhinobuster
/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta
	name = "Rudolta of the Sleigh"
	desc = "An abnormality consisting of three parts: A hornless, disfigured reindeer, \"Santa\" and a sleigh. \
	Rudolta is a fair creature that will give gifts equally to everyone, even if said gifts feel like you are going mad."
	maxHealth = 1200
	health = 1200
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2, FIRE = 1.5)
	move_to_delay = 6
	minimum_distance = 2 // Don't move all the way to melee
	original_abno = /mob/living/simple_animal/hostile/abnormality/rudolta

	var/pulse_cooldown
	var/pulse_cooldown_time = 1.8 SECONDS
	var/pulse_damage = 20
	var/turf/same_turf

	abno_additional_instructions = "<h1>You are Rudolta, A Rhino Piercer Role Abnormality.</h1><br>\
		<b>|Christmas|: You are incapable of performing melee attacks, instead you will perform pulses of WHITE damage. \
		Every 1.8 seconds you will perform a 20 WHITE damage pulse hitting all hostiles within a 8 tile sightline of yourself. <br>\
		<br>\
		|Infinite Hatred|: If a lifetick has passed and you have not moved you will raise the damage of your pulse by 5. \
		This damage increase may be stacked multiple times up to 30 WHITE per pulse. \
		If moving the damage of your pulse resets back to 20. \
		This damage increase is visually indicated by your eyes glowing. <br>\
		<br>\
		|Unopened Present|: Every lifetick you have a 10% chance to leave behind a present under you. \
		When a hostile walks over a present a 3x3 AoE explosion centered around the present will be triggered. \
		This explosion does 100 WHITE damage to all targets within it's AOE, the damage is doubled to the one that stepped on it. \
		The explosion will also violently fling said targets with potential to stun with impact to wall. \
		The present cannot be triggered by corpses or insane people and may be safely destroyed by gunfire. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/Initialize()
	. = ..()
	same_turf = get_turf(src)

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/PickTarget(list/Targets)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/Destroy(list/Targets)
	same_turf = null
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/Life()
	. = ..()
	if(!.) // Dead
		return FALSE

	//The various attack stuff
	if(same_turf != get_turf(src))
		same_turf = get_turf(src)
		pulse_damage = initial(pulse_damage)
	else
		if(pulse_damage <= 30)	//A 70 damage pulse is so mean
			pulse_damage += 5	//If they try to lock you down, start ramping, also if you are in the same area for too long
			manual_emote("eye's gleam.")

	//Sometimes drop a bomb present, it's funny, trust
	if(prob(10))
		new /obj/item/rca_bomb_present(get_turf(src))
	if((pulse_cooldown < world.time))
		WhitePulse()

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/rudolta/proc/WhitePulse()
	pulse_cooldown = world.time + pulse_cooldown_time
	playsound(src, 'sound/abnormalities/rudolta/throw.ogg', 50, FALSE, 4)
	for(var/mob/living/L in livinginview(8, src))
		if(faction_check_mob(L))
			continue
		L.deal_damage(pulse_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))


/obj/item/rca_bomb_present
	name = "present bomb"
	desc = "It's ticking. You may shoot it to safely disarm it."
	icon = 'icons/obj/storage.dmi'
	icon_state = "giftdeliverypackage5"
	max_integrity = 36 //3 rabbit rifle shots, 1 rabbit sniper shot
	density = FALSE
	alpha = 30
	var/faction = list("hostile")
	var/lifetime = 3 MINUTES

/obj/item/rca_bomb_present/Initialize()
	. = ..()
	QDEL_IN(src, lifetime)

/obj/item/rca_bomb_present/Crossed(atom/movable/AM)	//Keeping it crossed in case
	. = ..()
	if(!isliving(AM))
		return
	//Sorry for the nesting
	if(isliving(AM))
		var/mob/living/M = AM
		if(faction_check(M.faction, src.faction))
			return
		else if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H.sanity_lost)
				return
	explode()

/obj/item/rca_bomb_present/proc/explode()
	playsound(get_turf(src), 'sound/effects/explosion2.ogg', 50, 0, 8)
	for(var/turf/T in range(1, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(faction_check(L.faction, src.faction))
				continue
			var/throw_dir = get_dir(src, L)
			if(!throw_dir)
				throw_dir = pick(NORTH, SOUTH, EAST, WEST) // random dir if on same tile
			var/throw_target = get_edge_target_turf(L, throw_dir)
			L.throw_at(throw_target, 4, 2)
			L.deal_damage(100, WHITE_DAMAGE)	//Fuck man, You're the one stepping on the present.
	qdel(src)


