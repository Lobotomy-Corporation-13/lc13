//Coded by Kitsunemitsu, InsightfulParasite and Blim!
/mob/living/simple_animal/hostile/abnormality/nihil
	name = "The Jester of Nihil"
	desc = "What the heck is this... A clown?"
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "nihil"
	icon_living = "nihil"
	portrait = "nihil"
	pixel_x = -16
	base_pixel_x = -16


	//Are we doing our MMO attacks?
	var/area_active

	//So I'm PRETTY sure it's much faster to use individual vars than a list
	var/queen_active
	var/king_active
	var/servant_active
	var/knight_active

	//Kinda need this unfortunately
	var/obj/effect/proc_holder/ability/aimed/dash/kog/ourdash
	var/void_range = 5


/mob/living/simple_animal/hostile/abnormality/nihil/Initialize()
	.  = ..()
	ourdash = new()


/mob/living/simple_animal/hostile/abnormality/nihil/Move()
	if(!can_act)
		return FALSE
	if(area_active)
		return FALSE
	return ..()


//All of the attacks are below.
/mob/living/simple_animal/hostile/abnormality/nihil/OpenFire()
	if(!can_act)
		return
	//Jester has two separate attack types, one if he is in a Department Centre with Area active
	//And one if he is not.
	if(area_active)
		switch(rand(1,5))


		return

	//We're gonna roll the attacks, and if there's no magical girl, he will default to a different set of abilities.
	switch(rand(1,8))
		if(1)
			if(queen_active)
				ArcanaBeats()
			else
				NihilAttacks()
		if(2)
			if(queen_active)
				//ArcanaSlave()
			else
				NihilAttacks()
		if(3)
			if(knight_active)
				for(var/i = 1 to 4)
					SwordVolley()
			else
				NihilAttacks()
		if(4)
			if(knight_active)
				for(var/i = 1 to 4)
					SwordGatling()
			else
				NihilAttacks()
		if(5)
			if(king_active)
				Beatdown()
			else
				NihilAttacks()
		if(6)
			if(king_active)
				KOGCharge()
			else
				NihilAttacks()
		if(7)
			if(servant_active)
				PoisonAOE()
			else
				NihilAttacks()
		if(8)
			if(servant_active)
				RepeatedSlams()
			else
				NihilAttacks()

/mob/living/simple_animal/hostile/abnormality/nihil/proc/NihilAttacks()
	switch(rand(1,7))
		//First 4 are Projectile attacks
		if(1)
			HomingBolts()
		if(2)
			RapidBolts()
		if(3)
			Pushback()
		if(4)
			Flak()
		if(5)
			VoidAOE()
		if(6)
			ChasingShot()
		if(7)
			if(prob(30))
				return
				//StartRabbit()
			else
				WideVoid()

//Nihil Attacks
/mob/living/simple_animal/hostile/abnormality/nihil/proc/HomingBolts()
	if(!isliving(target))
		return
	var/mob/living/shootat = target
	can_act = FALSE
	manual_emote("points at [shootat].")
	SLEEP_CHECK_DEATH(5)
	for(var/i in 1 to 10)
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		DeferProjectile(/obj/projectile/nihilspade, shootat, T, 5)

	SLEEP_CHECK_DEATH(10)
	can_act = TRUE


/mob/living/simple_animal/hostile/abnormality/nihil/proc/RapidBolts()
	if(!isliving(target))
		return
	var/mob/living/shootat = target
	can_act = FALSE
	manual_emote("grins at [shootat].")
	SLEEP_CHECK_DEATH(5)
	for(var/i in 1 to 7)
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		DeferProjectile(/obj/projectile/nihilheart, shootat, T, 3)
		SLEEP_CHECK_DEATH(2)

	SLEEP_CHECK_DEATH(10)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/nihil/proc/Pushback()
	if(!isliving(target))
		return
	var/mob/living/shootat = target
	new /obj/effect/temp_visual/voidout(get_turf(src))
	playsound(src, 'sound/effects/phasein.ogg', 75, FALSE, 4)
	can_act = FALSE
	SLEEP_CHECK_DEATH(7)
	goonchem_vortex(get_turf(src), 1, 10)
	SLEEP_CHECK_DEATH(15)

	for(var/i in 1 to 5)
		var/turf/T = get_turf(src)
		DeferProjectile(/obj/projectile/nihildiamond, shootat, T, 3)
		SLEEP_CHECK_DEATH(8)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/nihil/proc/Flak()
	if(!isliving(target))
		return
	var/mob/living/exploder = target
	new /obj/effect/temp_visual/voidout(get_turf(exploder))
	can_act = FALSE
	SLEEP_CHECK_DEATH(25)
	var/turf/T = get_turf(exploder)
	exploder.Immobilize(5)
	for(var/i in 1 to 10)
		//This is subtly the most evil and fucked up line of code I have ever written.
		DeferProjectile(/obj/projectile/nihilclub, src, T, 2)

	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/nihil/proc/VoidAOE()
	can_act = FALSE
	new /obj/effect/temp_visual/voidout(get_turf(src))
	SLEEP_CHECK_DEATH(25)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(void_range, orgin)
	for(var/i = 0 to void_range)
		playsound(src, 'sound/effects/empulse.ogg', 75, FALSE, 4)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			new /obj/effect/temp_visual/negativelook(T)
			for(var/mob/living/carbon/human/L in T)
				L.apply_void(2)

			all_turfs -= T
		SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/nihil/proc/ChasingShot()
	for(var/i in 1 to 7)
		new /obj/effect/void_small(get_turf(target))
		SLEEP_CHECK_DEATH(5)

/mob/living/simple_animal/hostile/abnormality/nihil/proc/WideVoid()
	var/list/voidtargets = list()
	for(var/mob/living/carbon/human/H in view(7, src))
		voidtargets+= H

	var/mob/living/voidattack
	for(var/i in 1 to 7)
		if(!length(voidattack))
			return
		voidattack = pick(voidtargets)
		new /obj/effect/void_small(get_turf(target))
		SLEEP_CHECK_DEATH(3)



//Magical Girl attacks below
/mob/living/simple_animal/hostile/abnormality/nihil/proc/ArcanaBeats()
	can_act = FALSE
	if(target)
		face_atom(target)
	var/list/spawned_effects = list()
	visible_message(span_danger("[src] prepares to smite their enemies!"))
	var/turf/target_turf = get_ranged_target_turf_direct(src, target, 5)
	var/list/turfs_to_hit = getline(src, target_turf)
	var/obj/effect/qoh_sygil/S = new(get_turf(src))
	S.icon_state = "qoh1"
	spawned_effects += S
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "Arcana Beats!"))
	switch(dir)
		if(EAST)
			S.pixel_x += 16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(WEST)
			S.pixel_x += -16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(SOUTH)
			S.pixel_y += -16
			S.layer = (src.layer + 0.1)
		if(NORTH)
			S.pixel_y += 16
			S.layer -= 0.1
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(src, 'sound/abnormalities/hatredqueen/gun.ogg', 65, FALSE, 10)
	var/i = 1
	for(var/turf/T in turfs_to_hit)
		addtimer(CALLBACK(src, PROC_REF(BeatsTurf), T), i*0.4)
		i++
	SLEEP_CHECK_DEATH(1 SECONDS)
	for(var/obj/effect/qoh_sygil/SE in spawned_effects)
		SE.fade_out()
	spawned_effects.Cut()
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/nihil/proc/BeatsTurf(turf/T)
	var/list/affected_turfs = list()
	for(var/turf/TT in range(1, T))
		if(locate(/obj/effect/temp_visual/revenant) in TT)
			continue
		affected_turfs += TT
		var/obj/effect/temp_visual/TV = new /obj/effect/temp_visual/revenant(TT)
		TV.color = COLOR_SOFT_RED
		var/list/beats_hit = list()
		beats_hit = HurtInTurf(TT, beats_hit, 100, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_SPECIAL))



/mob/living/simple_animal/hostile/abnormality/nihil/proc/SwordVolley()
	if(!can_act)
		return FALSE
	var/tries = 8
	for(var/i = 1 to 4)
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		if(T.density)
			i -= 1
			tries--
			continue
		DeferProjectile(/obj/projectile/despair_rapier, target, T, 3)
	SLEEP_CHECK_DEATH(3)
	playsound(get_turf(src), 'sound/abnormalities/despairknight/attack.ogg', 50, 0, 4)
	return


/mob/living/simple_animal/hostile/abnormality/nihil/proc/SwordGatling()
	can_act = FALSE
	var/our_projectile_path = /obj/projectile/despair_rapier
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))

	var/list/origin_turfs = list()
	//Give me all the  turfs that are 2 tiles away
	//Default is EAST
	var/invert = -1
	//Ill figure out a way to write this shorter someday
	if(dir_to_target == WEST || dir_to_target == SOUTH)
		invert = 1
	var/positionx = x+(2*invert)
	var/positiony = 0
	if(dir_to_target == NORTH || dir_to_target == SOUTH)
		positionx = 0
		positiony = y+(2*invert)

	for(var/turf/T in orange(get_turf(src),2))
		if(!isopenturf(T))
			continue
		if(positionx && positionx != T.x)
			continue
		if(positiony && positiony != T.y)
			continue
		if(z != T.z)
			//Just in case
			continue
		origin_turfs += T

	if(!length(origin_turfs))
		can_act = TRUE
		return

	var/turf_dir
	var/delay = 3
	for(var/turf/bullet_turfs in origin_turfs)
		if(!turf_dir)
			turf_dir = dir_to_target
		DeferProjectile(our_projectile_path, get_step(bullet_turfs, turf_dir), bullet_turfs, delay)
		delay++
	SLEEP_CHECK_DEATH(5)
	can_act = TRUE


//A form of cleave attack
/mob/living/simple_animal/hostile/abnormality/nihil/proc/Beatdown()
	can_act = FALSE
	manual_emote("winds up...")
	playsound(src, 'sound/items/unsheath.ogg', 75, FALSE, 4)

	//Turfs we will be hitting
	var/turf/area_of_effect = list()
	//We need 2 numbers. The lower left and the upper right of the square.
	//Lower Left
	var/offsetx1 = 0
	var/offsety1 = 0
	//Upper Right
	var/offsetx2 = 0
	var/offsety2 = 0

	var/cleave_width = 2
	var/cleave_length = 3
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
			can_act = TRUE
			return

	//Give me ONLY the turfs between these cords
	area_of_effect = block(x+offsetx1,y+offsety1,z,x+offsetx2,y+offsety2)
	if (!LAZYLEN(area_of_effect))
		can_act = TRUE
		return
	dir = dir_to_target
	SLEEP_CHECK_DEATH(15)

	var/list/been_hit = list()
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, 80, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(anchored)
				continue
			var/turf/target_turf = get_ranged_target_turf(L, dir_to_target, 7)
			L.throw_at(target_turf, 7, 7, src)
	playsound(src, 'sound/weapons/fixer/generic/gen2.ogg', 50, TRUE)
	SLEEP_CHECK_DEATH(10)
	can_act = TRUE


/mob/living/simple_animal/hostile/abnormality/nihil/proc/KOGCharge()
	if(!can_act)
		return
	manual_emote("rears up to charge!")
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/H in view(20, src))
		possible_targets += H
	if(LAZYLEN(possible_targets))
		FindTarget(list(pick(possible_targets)), TRUE) // The list(pick()) here makes it equally likely for anyone to be targeted. If you removed it, it'd be based on individual threat level
		if(target)
			ourdash.Perform(target, src)
			return
	return

/mob/living/simple_animal/hostile/abnormality/nihil/proc/PoisonAOE()
	can_act = FALSE
	playsound(src, 'sound/abnormalities/wrath_servant/enrage.ogg', 75, FALSE, 20, falloff_distance = 10)
	for(var/i = 1 to 30)
		new /obj/effect/gibspawner/generic/silent/wrath_acid/bad(get_turf(src))
		SLEEP_CHECK_DEATH(2)
	can_act = TRUE


/mob/living/simple_animal/hostile/abnormality/nihil/proc/RepeatedSlams()
	can_act = FALSE
	var/list/turf/hit_turfs = list()
	playsound(src, 'sound/abnormalities/wrath_servant/enrage.ogg', 75, FALSE, 20, falloff_distance = 10)
	manual_emote("raises it's arms!")
	var/list/show_area = list()
	show_area |= range(3, src)
	show_area |= view(3, src)
	for(var/turf/sT in show_area)
		new /obj/effect/temp_visual/cult/sparks(sT)
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	for(var/x = 1 to 3)
		var/list/been_hit = list()
		playsound(src, "sound/abnormalities/wrath_servant/big_smash[x].ogg", 75, FALSE, 20, falloff_distance = 10) // heard from a distance
		for(var/i = 1 to 3)
			if(i < 4)
				hit_turfs = (range(i, src) - range(i-1, src)) // Ignores walls for first 3
				if(i == 1)
					hit_turfs += get_turf(src)
			else
				hit_turfs = (view(i, src) - range(i-1, src)) // Respects walls for last 2
			for(var/turf/T in hit_turfs)
				been_hit = HurtInTurf(T, been_hit, 60, WHITE_DAMAGE, null, TRUE, FALSE, TRUE, FALSE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				new /obj/effect/temp_visual/kinetic_blast(T)
				if(prob(3))
					new /obj/effect/gibspawner/generic/silent/wrath_acid/bad(T)
			SLEEP_CHECK_DEATH(1)
	can_act = TRUE


//Projectiles
/obj/projectile/nihilheart
	name = "heart attack"
	icon_state = "nihil_heart"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a heart-shaped card"
	hitsound = "sound/weapons/throwtap.ogg"
	speed = 4
	damage = 40
	damage_type = BLACK_DAMAGE
	white_healing = FALSE


/obj/projectile/nihilspade
	name = "spade certainty"
	icon_state = "nihil_spade"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a spade-shaped card"
	hitsound = "sound/weapons/throwtap.ogg"
	spread = 360	//Fires in a 360 Degree radius
	speed = 4
	damage = 30
	damage_type = PALE_DAMAGE

	ricochets_max = 3
	ricochet_chance = 70
	ricochet_decay_chance = 1
	ricochet_decay_damage = 0.7	//Decays a bit
	ricochet_auto_aim_range = 5	//Bounces towards you
	ricochet_auto_aim_angle = 180
	ricochet_incidence_leeway = 0

/obj/projectile/nihilspade/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure/window))
		return TRUE
	if(istype(A, /obj/machinery/door))
		return TRUE

	return FALSE


/obj/projectile/nihildiamond
	name = "diamond sharp"
	icon_state = "nihil_diamond"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a diamond-shaped card"
	speed = 4
	damage = 20	//Should hit a few times.
	damage_type = RED_DAMAGE
	paralyze = 5
	hitsound = 'sound/effects/meteorimpact.ogg'

/obj/projectile/nihildiamond/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(ismovable(target))
		var/atom/movable/M = target
		var/atom/throw_target = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
		M.safe_throw_at(throw_target, 3, 2)


/obj/projectile/nihilclub
	name = "clubbed"
	icon_state = "nihil_club"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a club-shaped card"
	hitsound = "sound/weapons/throwtap.ogg"
	spread = 360	//Fires in a 360 Degree radius
	speed = 4
	damage = 30
	damage_type = WHITE_DAMAGE



//AOE
/obj/effect/void_small
	name = "void warning"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/effects.dmi'
	icon_state = "anom"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 40 //Applies fragile
	var/lifetime = 1.2 SECONDS
	layer = POINT_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.

/obj/effect/void_small/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(explode)), lifetime)

/obj/effect/void_small/proc/explode()
	playsound(get_turf(src), 'sound/magic/blind.ogg', 50, 0, 8)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))
	for(var/mob/living/L in get_turf(src))
		L.deal_damage(boom_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
		L.apply_void(3)
	qdel(src)


//Items

//Items - Loot
/obj/item/nihil
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	desc = "A playing card that seems to resonate with certain E.G.O."
	var/special

/obj/item/nihil/examine(mob/user)
	. = ..()
	if(special)
		. += span_notice("[special]")

/obj/item/nihil/heart
	name = "ace of hearts"
	icon_state = "nihil_heart"
	special = "Someone has to be the villain..."

/obj/item/nihil/spade
	name = "ace of spades"
	icon_state = "nihil_spade"
	special = "If I can't protect others, I may as well disappear..."

/obj/item/nihil/diamond
	name = "ace of diamonds"
	icon_state = "nihil_diamond"
	special = "I feel empty inside... Hungry. I want more things!"

/obj/item/nihil/club
	name = "ace of clubs"
	icon_state = "nihil_club"
	special = "Sinners of the otherworlds! Embodiments of evil!!!"



#define STATUS_EFFECT_VOID /datum/status_effect/stacking/void

//Void Status effect
//Decrease everyone's attributes.
/datum/status_effect/stacking/void
	id = "stacking_void"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 20 SECONDS
	alert_type = null
	stack_decay = 0
	stacks = 1
	max_stacks = 13
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/void
	consumed_on_threshold = FALSE

/atom/movable/screen/alert/status_effect/void
	name = "Void"
	desc = "You are empty inside."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "nihil"

/datum/status_effect/stacking/void/on_apply()
	. = ..()
	to_chat(owner, span_warning("The whole world feels dark and empty..."))
	if(owner.client)
		owner.add_client_colour(/datum/client_colour/monochrome)

/datum/status_effect/stacking/void/add_stacks(stacks_added)
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, -10 * stacks_added)
	status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -10 * stacks_added)
	status_holder.adjust_attribute_bonus(TEMPERANCE_ATTRIBUTE, -10 * stacks_added)
	status_holder.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -10 * stacks_added)

/datum/status_effect/stacking/void/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, 10 * stacks)
	status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, 10 * stacks)
	status_holder.adjust_attribute_bonus(TEMPERANCE_ATTRIBUTE, 10 * stacks)
	status_holder.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, 10 * stacks)
	to_chat(owner, span_nicegreen("You feel normal again."))
	if(owner.client)
		owner.remove_client_colour(/datum/client_colour/monochrome)


//Mob Proc
/mob/living/proc/apply_void(stacks)
	var/datum/status_effect/stacking/void/V = src.has_status_effect(/datum/status_effect/stacking/void)
	if(!V)
		src.apply_status_effect(STATUS_EFFECT_VOID)
		if(stacks <= 1)
			return
		var/datum/status_effect/stacking/void/G = src.has_status_effect(/datum/status_effect/stacking/void)
		SLEEP_CHECK_DEATH(1) //Prevent runtimes
		G.add_stacks(stacks - 1)
	else
		V.add_stacks(stacks)
		V.refresh()
		playsound(src, 'sound/abnormalities/nihil/filter.ogg', 15, FALSE, -3)

#undef STATUS_EFFECT_VOID
