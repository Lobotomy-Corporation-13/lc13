/mob/living/simple_animal/hostile/humanoid
	name = "humanoid"
	desc = "A miserable pile of secrets, and this is one of them, you shouldn't be seeing this!"
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "humanoid_hostile"
	icon_living = "humanoid_hostile"
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 4
	stat_attack = HARD_CRIT
	melee_damage_type = RED_DAMAGE
	butcher_results = list(/obj/item/food/meat/slab = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab = 1)
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	blood_volume = BLOOD_VOLUME_NORMAL
	mob_size = MOB_SIZE_HUGE
	a_intent = INTENT_HARM

/*
RAT MOBS -
Extremely weak mobs that are a threat only if you are a unarmed civilian.
Skittish, they prefer to move in groups and will run away if the enemies are in superior numbers.
*/

//Rat - no special abilities, attacks fast
GLOBAL_LIST_EMPTY(nuke_rats_players)
/mob/living/simple_animal/hostile/humanoid/rat
	name = "rat"
	desc = "One of the many inhabitants of the backstreets, extremely weak and skittish."
	icon_state = "rat"
	icon_living = "rat"
	icon_dead = "rat_dead"
	maxHealth = 100
	health = 100
	move_to_delay = 4
	melee_damage_lower = 5
	melee_damage_upper = 6
	rapid_melee = 2
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	del_on_death = TRUE
	retreat_distance = 0
	butcher_results = list(/obj/item/food/meat/slab/human = 1, /obj/item/stack/spacecash/c10 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/human_simple = 1)
	attacked_line = "You will pay for this!"
	starting_looting_line = "Hand off, that is ours."
	ending_looting_line = "That's it, you asked for this."
	var/retreat_distance_default = 0

/mob/living/simple_animal/hostile/humanoid/rat/GiveTarget(new_target)
	var/strength_difference = -1
	for(var/mob/living/living_mob_in_view in livinginview(7,src) - src) //Doesn't count ourselves
		if(living_mob_in_view.stat == DEAD) //Doesn't count dead mobs
			continue
		if(!faction_check_mob(living_mob_in_view)) //Not an ally...
			strength_difference += 1
			continue
		strength_difference -= 1 //An ally!

	//If outnumbered by enemies, we act skittishly
	if(strength_difference > 0)
		retreat_distance = retreat_distance_default + 3
		return ..()

	//Else act as normal
	retreat_distance = retreat_distance_default
	. = ..()

/mob/living/simple_animal/hostile/humanoid/rat/Initialize()
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		del_on_death = FALSE

//Knife - The leader, has a pathetically weak dash, attacks fast
/mob/living/simple_animal/hostile/humanoid/rat/knife
	name = "leader rat"
	desc = "One of the many inhabitants of the backstreets, this one seems stronger than most rats, not like that's a hard feat."
	icon_state = "rat_knife"
	icon_living = "rat_knife"
	icon_dead = "rat_knife_dead"
	maxHealth = 250
	health = 250
	move_to_delay = 3
	ranged = TRUE
	melee_damage_lower = 8
	melee_damage_upper = 9
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	var/dash_cooldown
	var/dash_cooldown_time = 10 SECONDS
	var/dash_damage = 20
	var/dash_range = 2

/mob/living/simple_animal/hostile/humanoid/rat/knife/proc/BackstreetsDash(target)
	if(dash_cooldown > world.time)
		return
	dash_cooldown = world.time + dash_cooldown_time
	can_act = FALSE
	var/turf/slash_start = get_turf(src)
	var/turf/slash_end = get_ranged_target_turf_direct(slash_start, target, dash_range)
	var/list/hitline = getline(slash_start, slash_end)
	face_atom(target)
	for(var/turf/T in hitline)
		new /obj/effect/temp_visual/cult/sparks(T)
	SLEEP_CHECK_DEATH(1 SECONDS)
	forceMove(slash_end)
	for(var/turf/T in hitline)
		for(var/mob/living/L in HurtInTurf(T, list(), dash_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			to_chat(L, span_userdanger("[src] quickly slashes you!"))
	new /datum/beam(slash_start.Beam(slash_end, "1-full", time=3))
	playsound(src, attack_sound, 50, FALSE, 4)
	can_act = TRUE

/mob/living/simple_animal/hostile/humanoid/rat/knife/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/humanoid/rat/knife/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	..()
	if(dash_cooldown < world.time)
		BackstreetsDash(attacked_target)
		return

/mob/living/simple_animal/hostile/humanoid/rat/knife/OpenFire()
	if(!can_act)
		return
	if(prob(50) && (get_dist(src, target) < dash_range) && (dash_cooldown < world.time))
		BackstreetsDash(target)
		return
	return

//Pipe - Big windup before each attack, hits very hard
/mob/living/simple_animal/hostile/humanoid/rat/pipe
	name = "brute rat"
	desc = "One of the many inhabitants of the backstreets, armed with an odd pipe."
	icon_state = "rat_pipe"
	icon_living = "rat_pipe"
	icon_dead = "rat_pipe_dead"
	melee_damage_lower = 20
	melee_damage_upper = 25
	rapid_melee = 1
	attack_sound = 'sound/weapons/ego/pipesuffering.ogg'
	melee_damage_type = WHITE_DAMAGE
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bash"

/mob/living/simple_animal/hostile/humanoid/rat/pipe/AttackingTarget(atom/attacked_target)
	playsound(get_turf(src), 'sound/abnormalities/apocalypse/swing.ogg', 75, 0, 3)
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	if(QDELETED(attacked_target) || !attacked_target.Adjacent(targets_from))
		return
	. = ..()

/mob/living/simple_animal/hostile/humanoid/rat/pipe/scavenger
	name = "brute scavenger"
	mark_once_attacked = TRUE
	return_to_origin = TRUE

/mob/living/simple_animal/hostile/humanoid/rat/pipe/scavenger/Initialize()
	. = ..()
	glob_faction = GLOB.nuke_rats_players
	faction = list("neutral")

//Hammer - Tanky rat, but runs away at half health
/mob/living/simple_animal/hostile/humanoid/rat/hammer
	name = "cowardly rat"
	desc = "One of the many inhabitants of the backstreets, they seem like they're barely holding on to their weapon."
	icon_state = "rat_hammer"
	icon_living = "rat_hammer"
	icon_dead = "rat_hammer_dead"
	maxHealth = 150
	health = 150
	move_to_delay = 5
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	melee_damage_lower = 12
	melee_damage_upper = 15
	rapid_melee = 1
	attack_sound = 'sound/weapons/fixer/generic/gen1.ogg'
	attack_verb_continuous = "hammers"
	attack_verb_simple = "hammer"
	retreat_distance = 1
	retreat_distance_default = 1
	var/coward_health_threshold = 75

/mob/living/simple_animal/hostile/humanoid/rat/hammer/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(health < coward_health_threshold)
		retreat_distance_default = 4

/mob/living/simple_animal/hostile/humanoid/rat/hammer/scavenger
	name = "cowardly scavenger"
	mark_once_attacked = TRUE
	return_to_origin = TRUE

/mob/living/simple_animal/hostile/humanoid/rat/hammer/scavenger/Initialize()
	. = ..()
	glob_faction = GLOB.nuke_rats_players
	faction = list("neutral")

//Zippy - Uses a gun that fires 70% of the time and has a 1% chance to explode, leaving them without a gun.
/mob/living/simple_animal/hostile/humanoid/rat/zippy
	name = "fidgety rat"
	desc = "One of the many inhabitants of the backstreets, this one is armed with a shoddy gun!"
	icon_state = "rat_zippy"
	icon_living = "rat_zippy"
	icon_dead = "rat_zippy_dead"
	maxHealth = 80
	health = 80
	move_to_delay = 5
	melee_damage_lower = 4
	melee_damage_upper = 6
	rapid_melee = 1
	attack_sound = 'sound/weapons/fixer/generic/gen1.ogg'
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bash"
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 3
	retreat_distance_default = 3
	casingtype = /obj/item/ammo_casing/caseless/ego_kcorp
	projectilesound = 'sound/weapons/gun/pistol/shot.ogg'

/mob/living/simple_animal/hostile/humanoid/rat/zippy/OpenFire(atom/A)
	switch(rand(1,100))
		if(71 to 100) //29% for jamming.
			visible_message(span_notice("[src]'s gun jams."))
			playsound(src, 'sound/weapons/gun/general/dry_fire.ogg', 30, TRUE)
			return
		if(70) //1% for gun to explode.
			ranged = FALSE
			minimum_distance = 0
			retreat_distance = 1
			retreat_distance_default = 1
			visible_message(span_notice("The gun explodes on [src]'s hands!."))
			playsound(src, 'sound/abnormalities/scorchedgirl/explosion.ogg', 30, TRUE)
			adjustBruteLoss(20)
			return
		else
			. = ..()

/mob/living/simple_animal/hostile/humanoid/rat/zippy/scavenger
	name = "fidgety scavenger"
	mark_once_attacked = TRUE
	return_to_origin = TRUE

/mob/living/simple_animal/hostile/humanoid/rat/zippy/scavenger/Initialize()
	. = ..()
	glob_faction = GLOB.nuke_rats_players
	faction = list("neutral")

/mob/living/simple_animal/hostile/humanoid/fixer
	name = "fixer"
	desc = "One of the many inhabitants of the backstreets, extremely weak and skittish."
	icon_state = "flame_fixer"
	icon_living = "flame_fixer"
	icon_dead = "flame_fixer"
	move_resist = MOVE_FORCE_STRONG
	maxHealth = 1500
	health = 1500
	move_to_delay = 4
	melee_damage_lower = 11
	melee_damage_upper = 16
	rapid_melee = 2
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	del_on_death = TRUE
	var/list/loot_weapon = list(
	)
	var/list/loot_armor = list(
	)

/mob/living/simple_animal/hostile/humanoid/fixer/drop_loot()
	// Drop both weapon and armor
	if(loot_weapon?.len)
		for(var/i in loot_weapon)
			new i(loc)
	if(loot_armor?.len)
		for(var/i in loot_armor)
			new i(loc)

/mob/living/simple_animal/hostile/humanoid/fixer/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/humanoid/fixer/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/humanoid/fixer/metal
	name = "Memory Forger"
	desc = "A dude covered in a full white cloak and always wear a white mask. He seems to be wearing a tactical vest."
	icon_state = "metal_fixer"
	icon_living = "metal_fixer"
	icon_dead = "metal_fixer"
	faction = list("echo_office")
	var/icon_attacking = "metal_fixer_weapon"
	maxHealth = 2000
	health = 2000
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.3)
	move_to_delay = 5
	melee_damage_lower = 12
	melee_damage_upper = 16
	melee_damage_type = BLACK_DAMAGE
	rapid_melee = 2
	attack_sound = 'sound/weapons/fixer/generic/blade3.ogg'
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	del_on_death = TRUE
	ranged = TRUE
	loot_weapon = list (
		/obj/item/ego_weapon/shield/eria,
		/obj/item/ego_weapon/city/echo/iria,
	)
	loot_armor = list (
	/obj/item/clothing/suit/armor/ego_gear/city/echo/plated,
	)
	var/statue_type = /mob/living/simple_animal/hostile/metal_fixer_statue
	var/shots_cooldown = 50
	var/max_statues = 12
	var/health_lost_per_statue = 100
	var/list/statues = list()
	var/current_healthloss = 0
	var/aoe_cooldown = 150
	var/last_aoe_time = 0
	var/aoe_damage = 50
	var/stun_duration = 50
	var/spike_line_cooldown = 150
	var/last_spike_line_time = 0
	var/creation_line_cooldown = 100
	var/last_creation_line_time = 0
	var/statue_cooldown = 25
	var/last_statue_cooldown_time = 0
	var/self_damage_statue = 250

/mob/living/simple_animal/hostile/humanoid/fixer/metal/Destroy()
	DeregisterAll()
	return ..()

/mob/living/simple_animal/hostile/humanoid/fixer/metal/Aggro()
	icon_state = icon_attacking
	. = ..()

/mob/living/simple_animal/hostile/humanoid/fixer/metal/LoseTarget()
	icon_state = icon_living
	. = ..()

/mob/living/simple_animal/hostile/humanoid/fixer/metal/OpenFire()
	ranged_cooldown = world.time + shots_cooldown
	if (world.time > last_spike_line_time + spike_line_cooldown)
		last_spike_line_time = world.time
		say("Experience is what brought me here.")

	playsound(src, 'sound/weapons/fixer/hana_pierce.ogg', 50, TRUE, 2) // pick sound
	for(var/d in GLOB.cardinals)
		var/turf/E = get_step(src, d)
		shoot_projectile(E)

/mob/living/simple_animal/hostile/humanoid/fixer/metal/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE

	if(ranged_cooldown <= world.time)
		OpenFire()

	// do AOE
	if(world.time < (last_aoe_time + aoe_cooldown))
		return ..()

	last_aoe_time = world.time
	can_act = FALSE
	say("This is the culmination of my work.")
	SLEEP_CHECK_DEATH(2 SECONDS)
	var/hit_statue = FALSE
	for(var/turf/T in view(2, src))
		playsound(src, 'sound/weapons/fixer/generic/finisher2.ogg', 75, TRUE, 2)
		new /obj/effect/temp_visual/slice(T)
		for(var/mob/living/L in T)
			if(istype(L, /mob/living/simple_animal/hostile/metal_fixer_statue))
				var/mob/living/simple_animal/hostile/metal_fixer_statue/S = L
				DeregisterStatue(S)
				qdel(S)
				hit_statue = TRUE
		HurtInTurf(T, list(), aoe_damage, BLACK_DAMAGE, null, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

	if(hit_statue)
		say("...")
		adjustHealth(self_damage_statue)
		var/mutable_appearance/colored_overlay = mutable_appearance(icon, "small_stagger", layer + 0.1)
		add_overlay(colored_overlay)
		ChangeResistances(list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2.6))
		SLEEP_CHECK_DEATH(stun_duration)
		ChangeResistances(list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.3))
		cut_overlays()
	can_act = TRUE

/mob/living/simple_animal/hostile/humanoid/fixer/metal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/old_health = health
	. = ..()
	var/health_loss = old_health - health
	current_healthloss += health_loss
	if(current_healthloss > health_lost_per_statue)
		current_healthloss -= health_lost_per_statue
		spawn_statue()

/mob/living/simple_animal/hostile/humanoid/fixer/metal/proc/spawn_statue()
	if(statues.len < max_statues && world.time > last_statue_cooldown_time + statue_cooldown)
		last_statue_cooldown_time = world.time
		var/list/available_turfs = list()
		for(var/turf/T in view(4, loc))
			if(isfloorturf(T) && !T.density && !locate(/mob/living) in T)
				available_turfs += T
		visible_message("<span class='danger'>[src] starts spawning a statue!</span>")
		if(world.time > last_creation_line_time + creation_line_cooldown)
			last_creation_line_time = world.time
			say("The days of the past.")

		if(available_turfs.len)
			var/turf/statue_turf = pick(available_turfs)
			var/mob/living/simple_animal/hostile/metal_fixer_statue/S = new statue_type(statue_turf)
			RegisterStatue(S)
			S.icon_state = "memory_statute_grow" // Set the initial icon state to the rising animation
			flick("memory_statute_grow", S) // Play the rising animation
			spawn(10) // Wait for the animation to finish
				S.icon_state = initial(S.icon_state) // Set the icon state back to the default statue icon
			visible_message("<span class='danger'>[src] spawns a statue. </span>")

/mob/living/simple_animal/hostile/humanoid/fixer/metal/proc/shoot_projectile(turf/marker, set_angle)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new /obj/projectile/metal_fixer(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/humanoid/fixer/metal/proc/RegisterStatue(mob/living/simple_animal/hostile/metal_fixer_statue/marble)
	RegisterSignal(marble, list(COMSIG_PARENT_QDELETING), PROC_REF(DeregisterStatue))
	statues += marble
	marble.metal = src

/mob/living/simple_animal/hostile/humanoid/fixer/metal/proc/DeregisterStatue(mob/living/simple_animal/hostile/metal_fixer_statue/granite)
	UnregisterSignal(granite, list(COMSIG_PARENT_QDELETING))
	statues -= granite
	granite.metal = null

/mob/living/simple_animal/hostile/humanoid/fixer/metal/proc/DeregisterAll()
	for(var/mob/living/grabbo in statues)
		DeregisterStatue(grabbo)
	statues.Cut()

/mob/living/simple_animal/hostile/humanoid/fixer/metal/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(!istype(P, /obj/projectile/metal_fixer))
		return ..()

	adjustHealth(-(P.damage/4))
	playsound(src, 'sound/abnormalities/voiddream/skill.ogg', 50, TRUE, 2)
	visible_message(span_warning("[P] contacts with [src] and heals them!"))
	DamageEffect(P.damage_type)

/obj/projectile/metal_fixer
	name ="metal bolt"
	icon_state= "chronobolt"
	damage = 25
	speed = 1
	damage_type = BLACK_DAMAGE
	projectile_piercing = PASSMOB
	ricochets_max = 3
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_incidence_leeway = 0

/obj/projectile/metal_fixer/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	return FALSE

/obj/projectile/metal_fixer/on_hit(atom/target, blocked = FALSE)
	if(firer==target)
		//var/mob/living/simple_animal/hostile/humanoid/fixer/metal/M = target
		qdel(src)
		return BULLET_ACT_BLOCK
	var/mob/living/simple_animal/hostile/humanoid/fixer/metal/M = firer

	if (istype(target, /mob))

		var/mob/MOB = target
		if (MOB.faction_check_mob(M, FALSE))
			return BULLET_ACT_BLOCK
	. = ..()


/mob/living/simple_animal/hostile/metal_fixer_statue
	name = "Memory Statue"
	desc = "A statue created by the Memory Forger."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "memory_statute"
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 0, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	health = 100
	maxHealth = 100
	speed = 0
	move_resist = INFINITY
	mob_size = MOB_SIZE_HUGE
	var/mob/living/simple_animal/hostile/humanoid/fixer/metal/metal
	var/heal_cooldown = 50
	var/heal_timer
	var/heal_per_tick = 25
	var/self_destruct_timer


/mob/living/simple_animal/hostile/metal_fixer_statue/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(!istype(P, /obj/projectile/metal_fixer))
		return ..()

	DamageEffect(P.damage_type)

/mob/living/simple_animal/hostile/metal_fixer_statue/Initialize()
	. = ..()
	heal_timer = addtimer(CALLBACK(src, .proc/heal_metal_fixer), heal_cooldown, TIMER_STOPPABLE)
	self_destruct_timer = addtimer(CALLBACK(src, .proc/self_destruct), 0.5 MINUTES, TIMER_STOPPABLE)
	AIStatus = AI_OFF
	stop_automated_movement = TRUE
	anchored = TRUE

/mob/living/simple_animal/hostile/metal_fixer_statue/Destroy()
	deltimer(heal_timer)
	deltimer(self_destruct_timer)
	metal = null
	return ..()

/mob/living/simple_animal/hostile/metal_fixer_statue/proc/self_destruct()
	visible_message("<span class='danger'>The statue crumbles and self-destructs!</span>")
	qdel(src)

/mob/living/simple_animal/hostile/metal_fixer_statue/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(health <= 0)
		visible_message("<span class='danger'>The statue crumbles into pieces!</span>")
		qdel(src)

/mob/living/simple_animal/hostile/metal_fixer_statue/proc/heal_metal_fixer()
	if(metal)
		metal.adjustHealth(-heal_per_tick)
		visible_message("<span class='notice'>The statue heals the Memory Forger!</span>")
		playsound(src, 'sound/abnormalities/rosesign/rose_summon.ogg', 75, TRUE, 2)
		icon_state = "memory_statute_heal" // Set the initial icon state to the rising animation
		flick("memory_statute_heal", src) // Play the rising animation
		spawn(10) // Wait for the animation to finish
			icon_state = initial(icon_state) // Set the icon state back to the default statue icon
	heal_timer = addtimer(CALLBACK(src, .proc/heal_metal_fixer), heal_cooldown, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/metal_fixer_statue/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/metal_fixer_statue/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/humanoid/fixer/flame
	name = "Sanguine Flame"
	desc = "A lanky young man with fair skin, dark eyes, and an often overoptimistic expression. A heavy spear decorated with vibrant patterns on the head."
	icon_state = "flame_fixer"
	icon_living = "flame_fixer"
	icon_dead = "flame_fixer"
	faction = list("echo_office")
	maxHealth = 2500
	health = 2500
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.3)
	move_to_delay = 4
	melee_damage_lower = 20
	melee_damage_upper = 24
	melee_damage_type = RED_DAMAGE
	rapid_melee = 0.5
	attack_sound = 'sound/weapons/fixer/generic/spear3.ogg'
	attack_verb_continuous = "pierces"
	attack_verb_simple = "pierce"
	del_on_death = TRUE
	ranged = TRUE
	ranged_cooldown_time = 45
	loot_weapon = list (
	/obj/item/ego_weapon/city/echo/sunstrike,
	)
	loot_armor = list (
	/obj/item/clothing/suit/armor/ego_gear/city/echo/faux,
	)
	var/burn_stacks = 2
	projectiletype = /obj/projectile/flame_fixer
	var/damage_reflection = FALSE
	var/dash_cooldown = 150
	var/last_dash = 0
	var/dash_damage = 50
	var/last_counter = 0
	var/counter_cooldown = 30
	var/last_voice_line = 0
	var/voice_line_cooldown = 250
	var/counter_timer
	var/counter_duration = 4 SECONDS
	var/got_hit = FALSE


/mob/living/simple_animal/hostile/humanoid/fixer/flame/proc/TripleDash()
	// if dash is off cooldown stun until the end of dashes and say quote
	// wait 2 sec for the first dash
	// after 2 sec dash towards the target dealing red dmg and applying burn
	// repeat 3 times with 1 sec delay between each
	// unstun
	if (world.time > last_dash + dash_cooldown)
		got_hit = FALSE
		last_dash = world.time
		can_act = FALSE
		say("Dissatisfaction.")
		icon_state = "flame_fixer_dashing"
		SLEEP_CHECK_DEATH(20)
		Dash(target)
		Dash(target)
		Dash(target)
		icon_state = initial(icon_state)
		last_dash = world.time
		if (!got_hit)
			can_act = TRUE
		got_hit = FALSE

/mob/living/simple_animal/hostile/humanoid/fixer/flame/proc/Dash(dash_target)
	if (got_hit)
		return
	if (!dash_target)
		return
	var/turf/target_turf = get_turf(dash_target)
	var/list/hit_mob = list()
	//do_shaky_animation(2)
	if(do_after(src, 0.5 SECONDS, target = src))
		var/turf/wallcheck = get_turf(src)
		var/enemy_direction = get_dir(src, target_turf)
		for(var/i=0 to 7)
			if(get_turf(src) != wallcheck || stat == DEAD )
				break
			wallcheck = get_step(src, enemy_direction)
			if(!ClearSky(wallcheck))
				break
			//without this the attack happens instantly
			sleep(0.5)
			forceMove(wallcheck)
			playsound(wallcheck, 'sound/weapons/ego/burn_sword.ogg', 20, 0, 4)
			for(var/turf/T in orange(get_turf(src), 1))
				if(isclosedturf(T))
					continue
				new /obj/effect/temp_visual/mech_fire(T)
				for(var/mob/living/L in T)
					if(!faction_check_mob(L, FALSE) && !(locate(L) in hit_mob))
						L.deal_damage(dash_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
						LAZYADD(hit_mob, L)


/mob/living/simple_animal/hostile/humanoid/fixer/flame/OpenFire(atom/A)
	if (!can_act)
		return
	TripleDash()
	. = ..()

/mob/living/simple_animal/hostile/humanoid/fixer/flame/Shoot(atom/targeted_atom)
	var/obj/projectile/flame_fixer/P = ..()
	P.set_homing_target(target)
	if (world.time > last_voice_line + voice_line_cooldown)
		say("Helios fire!")
		last_voice_line = world.time

/mob/living/simple_animal/hostile/humanoid/fixer/flame/AttackingTarget(atom/attacked_target)
	// check cooldown and start countering
	// stop melee start stun for 4 sec
	// animate windup  for 1 sec
	// change icon_state to counter
	// if they hit after wind up during counter deal RED damage and stamina damage
	// counter has random cooldown 15-40 sec
	if (!can_act)
		return

	if (world.time > last_counter + counter_cooldown)
		last_counter = world.time
		got_hit = FALSE
		can_act = FALSE
		icon_state = "flame_fixer_counter_start"
		say("Debilitation.")
		SLEEP_CHECK_DEATH(10)
		if (!got_hit)
			damage_reflection = TRUE
			icon_state = "flame_fixer_counter"
			counter_timer = addtimer(CALLBACK(src, PROC_REF(EndCounter)), counter_duration, TIMER_STOPPABLE)
		return

	. = ..()
	if (istype(attacked_target, /mob/living))
		var/mob/living/L = attacked_target
		L.apply_lc_burn(burn_stacks)
	TripleDash()

/mob/living/simple_animal/hostile/humanoid/fixer/flame/proc/EndCounter()
	if (damage_reflection)
		//delete timer
		if (counter_timer !=0)
			deltimer(counter_timer)
		damage_reflection = FALSE
		can_act = TRUE
		icon_state = initial(icon_state)
		last_counter = world.time
		counter_cooldown = rand(100, 250)

/mob/living/simple_animal/hostile/humanoid/fixer/flame/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	..()
	if(damage_reflection && Proj.firer)
		if(get_dist(Proj.firer, src) < 8)
			ReflectDamage(Proj.firer, Proj.damage_type, Proj.damage)

/mob/living/simple_animal/hostile/humanoid/fixer/flame/attackby(obj/item/I, mob/living/user, params)
	..()
	if(!damage_reflection)
		return
	ReflectDamage(user, I.damtype, I.force)

/mob/living/simple_animal/hostile/humanoid/fixer/flame/proc/ReflectDamage(mob/living/attacker, attack_type = RED_DAMAGE, damage)
	if(damage < 1)
		return
	if(!damage_reflection)
		return
	var/turf/jump_turf = get_step(attacker, pick(GLOB.alldirs))
	if(jump_turf.is_blocked_turf(exclude_mobs = TRUE))
		jump_turf = get_turf(attacker)
	forceMove(jump_turf)
	playsound(src, 'sound/weapons/ego/burn_guard.ogg', min(15 + damage, 75), TRUE, 4)
	attacker.visible_message(span_danger("[src] hits [attacker] with a counterattack!"), span_userdanger("[src] counters your attack!"))
	do_attack_animation(attacker)
	attacker.deal_damage(damage * 2, attack_type, source = src, attack_type = (ATTACK_TYPE_COUNTER))
	attacker.deal_damage(damage, STAMINA, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_COUNTER))



/obj/projectile/flame_fixer
	name ="flame bolt"
	icon_state= "helios_fire"
	damage = 15
	speed = 8
	damage_type = RED_DAMAGE
	//projectile_piercing = PASSMOB
	ricochets_max = 20
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_incidence_leeway = 0
	homing = TRUE
	homing_turn_speed = 10		//Angle per tick.
	var/stun_duration = 75
	var/burn_stacks = 20


/obj/projectile/flame_fixer/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	return FALSE

/obj/projectile/flame_fixer/on_hit(atom/target, blocked = FALSE)
	if (istype(target, /mob/living))
		var/mob/living/L = target
		L.apply_lc_burn(burn_stacks)
	if(firer==target)
		var/mob/living/simple_animal/hostile/humanoid/fixer/flame/F = target
		F.EndCounter()
		F.got_hit = TRUE
		qdel(src)
		F.can_act = FALSE
		F.say("Derealization...")
		var/mutable_appearance/colored_overlay = mutable_appearance(F.icon, "small_stagger", F.layer + 0.1)
		F.add_overlay(colored_overlay)
		F.ChangeResistances(list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 2, PALE_DAMAGE = 2.6))
		sleep(stun_duration)
		F.ChangeResistances(list(RED_DAMAGE = 0.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.3))
		F.cut_overlays()
		F.can_act = TRUE
		return BULLET_ACT_BLOCK
	. = ..()

// Electric Fixer - Amber Knight
// An aggressive combo-based attacker with Ramp Up system

#define ABILITY_NONE 0
#define ABILITY_DASH 1
#define ABILITY_JUMP 2
#define ABILITY_CIRCUIT 3

/mob/living/simple_animal/hostile/humanoid/fixer/electric
	name = "Amber Knight"
	desc = "Feminine guy, dressed in mainly black with neon accents, with bright amber eyes."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "electic"
	icon_living = "electic"
	faction = list("echo_office")
	gender = MALE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 3
	stat_attack = HARD_CRIT
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 14
	melee_damage_upper = 20
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	a_intent = INTENT_HARM
	mob_size = MOB_SIZE_HUGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	loot_weapon = list(
		/obj/item/ego_weapon/city/echo/twins/sodom,
		/obj/item/ego_weapon/city/echo/twins/gomorrah,
	)
	loot_armor = list(
		/obj/item/clothing/suit/armor/ego_gear/city/echo/maid_dress,
	)

	// Ramp Up System
	var/ramp_up = 0
	var/max_ramp_up = 10
	var/showtime_ramp_up = 15
	var/in_showtime = FALSE
	var/showtime_duration = 10 SECONDS
	var/showtime_damage_mult = 0.25  // 75% less damage
	var/post_showtime_stun = 8 SECONDS
	var/base_ability_delay = 3 SECONDS
	var/ramp_up_reduction = 0.1 SECONDS

	// Ability State
	var/current_ability = ABILITY_NONE
	var/last_ability_time = 0
	var/ability_cooldown = 1 SECONDS

	// Dash Variables
	var/dash_damage = 20
	var/dash_count = 2

	// Jump Variables
	var/jump_damage = 20
	var/jump_aoe = 1

	// Circuit Variables
	var/circuit_damage = 20
	var/circuit_max_range = 5

	// Stagger state
	var/is_staggered = FALSE

	// Voice line cooldown
	var/last_voice_line = 0
	var/voice_line_cooldown = 3 SECONDS

	// Stagger resistance changes (more vulnerable when staggered after Showtime)
	var/list/stagger_resistances = list(RED_DAMAGE = 2.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 3.0)
	var/list/normal_resistances = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/Initialize()
	. = ..()
	// Start ability loop
	addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 1 SECONDS)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/Destroy()
	return ..()

// Get current ability delay based on ramp up
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/GetAbilityDelay()
	var/effective_ramp = in_showtime ? showtime_ramp_up : ramp_up
	return max(0.5 SECONDS, base_ability_delay - (effective_ramp * ramp_up_reduction))

// Get current damage multiplier
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/GetDamageMult()
	return in_showtime ? showtime_damage_mult : 1

// Voice line with cooldown check
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/TrySay(message)
	if(world.time < last_voice_line + voice_line_cooldown)
		return
	last_voice_line = world.time
	say(message)

// Add ramp up and check for showtime
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/AddRampUp()
	if(in_showtime)
		return
	ramp_up++
	if(ramp_up >= max_ramp_up)
		EnterShowtime()

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/EnterShowtime()
	in_showtime = TRUE
	say("The light's never been brighter!")
	visible_message(span_danger("[src]'s movements become blindingly fast!"))
	playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 75, TRUE)
	// Add visual effect
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "blessed", ABOVE_MOB_LAYER))
	// Timer to end showtime
	addtimer(CALLBACK(src, PROC_REF(EndShowtime)), showtime_duration)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/EndShowtime()
	in_showtime = FALSE
	ramp_up = 0
	// Enter stagger state - this prevents abilities from re-enabling can_act
	is_staggered = TRUE
	can_act = FALSE
	// Remove showtime overlay, add stagger overlay
	cut_overlays()
	var/mutable_appearance/stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "small_stagger", layer + 0.1)
	add_overlay(stagger_overlay)
	// Make more vulnerable during stagger
	ChangeResistances(stagger_resistances)
	visible_message(span_warning("[src] collapses from exhaustion!"))
	say("Nothing but grey now.")
	// Use SLEEP_CHECK_DEATH pattern
	SLEEP_CHECK_DEATH(post_showtime_stun)
	// Recovery
	ChangeResistances(normal_resistances)
	cut_overlay(stagger_overlay)
	is_staggered = FALSE
	can_act = TRUE
	say("...The colors are coming back.")
	visible_message(span_notice("[src] recovers and rises back up."))

// Main ability loop
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/AbilityLoop()
	if(stat == DEAD)
		return
	if(!can_act || !target || is_staggered)
		addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 1 SECONDS)
		return
	if(world.time < last_ability_time + ability_cooldown)
		addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), 0.5 SECONDS)
		return
	// Roll for next ability
	RollNextAbility()
	addtimer(CALLBACK(src, PROC_REF(AbilityLoop)), GetAbilityDelay())

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/RollNextAbility()
	var/roll = rand(1, 100)
	switch(current_ability)
		if(ABILITY_NONE)
			// First ability - equal chance
			if(roll <= 33)
				StartBlazingDash()
			else if(roll <= 66)
				StartFantasiaLights()
			else
				StartAmberCircuits()
		if(ABILITY_DASH)
			// 50% Dash, 25% Jump, 25% Circuit
			if(roll <= 50)
				StartBlazingDash()
			else if(roll <= 75)
				StartFantasiaLights()
			else
				StartAmberCircuits()
		if(ABILITY_JUMP)
			// 50% Jump, 25% Dash, 25% Circuit
			if(roll <= 50)
				StartFantasiaLights()
			else if(roll <= 75)
				StartBlazingDash()
			else
				StartAmberCircuits()
		if(ABILITY_CIRCUIT)
			// 50% Circuit, 25% Dash, 25% Jump
			if(roll <= 50)
				StartAmberCircuits()
			else if(roll <= 75)
				StartBlazingDash()
			else
				StartFantasiaLights()

// Ability 1: Blazing Dash
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartBlazingDash()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_DASH
	last_ability_time = world.time
	// Wind-up delay
	var/delay = GetAbilityDelay()
	// Add warning overlays for dash path
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	var/dash_direction = get_dir(my_turf, target_turf)
	var/turf/check_turf = my_turf
	for(var/i in 1 to 7)
		check_turf = get_step(check_turf, dash_direction)
		if(!check_turf || isclosedturf(check_turf))
			break
		check_turf.add_overlay(warning_icon)
		addtimer(CALLBACK(check_turf, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), delay)
	// Visual telegraph
	TrySay(pick("Keep moving forward!", "Chase the light!", "Don't look back!"))
	visible_message(span_warning("[src] crouches, electricity crackling around them!"))
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 50, TRUE)
	// Execute after delay - pass saved target position
	addtimer(CALLBACK(src, PROC_REF(ExecuteBlazingDash), target_turf), delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteBlazingDash(turf/initial_target)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	// First dash to saved position (where warning was shown)
	if(initial_target)
		DashToTurf(initial_target)
	// Second dash to current target position
	if(stat != DEAD && target && !is_staggered)
		DashToTarget()
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/DashToTarget()
	if(!target || stat == DEAD)
		return
	// Recalculate direction each dash (allows tracking moving targets)
	var/turf/target_turf = get_turf(target)
	DashToTurf(target_turf)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/DashToTurf(turf/destination)
	if(!destination || stat == DEAD || is_staggered)
		return
	var/list/hit_mobs = list()
	// Small delay before dash starts, scales with ramp up (0.8s base, 0.4s at 10 ramp up, 0.3s showtime)
	var/dash_delay
	if(in_showtime)
		dash_delay = 0.3 SECONDS
	else
		dash_delay = max(0.4 SECONDS, 0.8 SECONDS - (ramp_up * 0.04 SECONDS))
	if(!do_after(src, dash_delay, target = src))
		return
	var/turf/current = get_turf(src)
	var/enemy_direction = get_dir(src, destination)
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 50, TRUE)
	for(var/i in 1 to 7)
		if(get_turf(src) != current || stat == DEAD)
			break
		var/turf/next = get_step(src, enemy_direction)
		if(isclosedturf(next))
			break
		sleep(0.5)
		current = next
		forceMove(next)
		// Electric trail effect and damage in 3x3 area around dash path
		for(var/turf/T in range(1, next))
			if(isclosedturf(T))
				continue
			new /obj/effect/temp_visual/justitia_effect(T)
			for(var/mob/living/L in T)
				if(!faction_check_mob(L, FALSE) && !(L in hit_mobs))
					var/actual_damage = dash_damage * GetDamageMult()
					L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
					hit_mobs += L

// Ability 2: Fantasia Lights (Jump Attack)
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartFantasiaLights()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_JUMP
	last_ability_time = world.time
	// Mark target position
	var/turf/target_turf = get_turf(target)
	// Warning duration (0.8s base, 0.4s at 10 ramp up, 0.3s showtime)
	var/warning_delay
	if(in_showtime)
		warning_delay = 0.3 SECONDS
	else
		warning_delay = max(0.4 SECONDS, 0.8 SECONDS - (ramp_up * 0.04 SECONDS))
	// Add warning overlays to landing zone
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	for(var/turf/T in range(jump_aoe, target_turf))
		T.add_overlay(warning_icon)
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), warning_delay)
	// Visual telegraph - NO jump animation yet, just prepare
	TrySay(pick("Reach for the sky!", "If you can see the light...", "Higher and higher!"))
	visible_message(span_warning("[src] prepares to leap!"))
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 50, TRUE)
	// Execute after warning delay
	addtimer(CALLBACK(src, PROC_REF(ExecuteFantasiaLights), target_turf), warning_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteFantasiaLights(turf/landing_turf)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	if(!landing_turf)
		landing_turf = get_turf(src)
	// Jump UP first
	visible_message(span_warning("[src] leaps into the air!"))
	animate(src, pixel_z = 32, time = 0.2 SECONDS)
	sleep(2)
	// Land at marked position
	forceMove(landing_turf)
	animate(src, pixel_z = 0, time = 0.1 SECONDS)
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 75, TRUE)
	// AoE damage at landing
	for(var/turf/T in range(jump_aoe, landing_turf))
		new /obj/effect/temp_visual/justitia_effect(T)
		for(var/mob/living/L in T)
			if(!faction_check_mob(L, FALSE))
				var/actual_damage = jump_damage * GetDamageMult()
				L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

// Ability 3: Amber Circuits (Circle AoE)
/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/StartAmberCircuits()
	if(!target || stat == DEAD || !can_act)
		return
	can_act = FALSE
	current_ability = ABILITY_CIRCUIT
	last_ability_time = world.time
	// Stop moving
	var/turf/my_turf = get_turf(src)
	// Warning duration (0.8s base, 0.4s at 10 ramp up, 0.3s showtime)
	var/warning_delay
	if(in_showtime)
		warning_delay = 0.3 SECONDS
	else
		warning_delay = max(0.4 SECONDS, 0.8 SECONDS - (ramp_up * 0.04 SECONDS))
	// Mark concentric circles with 1-tile gaps (distance 1, 3)
	var/list/marked_turfs = list()
	var/static/warning_icon = icon('icons/effects/effects.dmi', "dancing_lights")
	for(var/turf/T in range(circuit_max_range, my_turf))
		var/dist = get_dist(my_turf, T)
		if(dist == 1 || dist == 3 || dist == 5) // Rings at distance 1, 3, 4, and 5
			marked_turfs += T
			// Add warning overlay that lasts until attack executes
			T.add_overlay(warning_icon)
			addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), warning_icon), warning_delay)
	TrySay(pick("Let the light spread!", "Illuminate the path!", "Can you see it now?"))
	visible_message(span_warning("Amber circuits spread out from [src]!"))
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 50, TRUE)
	// Execute after warning delay
	addtimer(CALLBACK(src, PROC_REF(ExecuteAmberCircuits), marked_turfs), warning_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/electric/proc/ExecuteAmberCircuits(list/turfs)
	if(stat == DEAD || is_staggered)
		if(!is_staggered)
			can_act = TRUE
		return
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 75, TRUE)
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/justitia_effect(T)
		for(var/mob/living/L in T)
			if(!faction_check_mob(L, FALSE))
				var/actual_damage = circuit_damage * GetDamageMult()
				L.deal_damage(actual_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	AddRampUp()
	if(!is_staggered)
		can_act = TRUE

// Don't move during abilities or stagger
/mob/living/simple_animal/hostile/humanoid/fixer/electric/Move()
	if(!can_act || is_staggered)
		return FALSE
	return ..()

// Attack handling - instant kill insane/panicking targets
/mob/living/simple_animal/hostile/humanoid/fixer/electric/AttackingTarget(atom/attacked_target)
	if(!can_act || is_staggered)
		return FALSE
	// Check for sanity_lost before the attack (like Liu weapons)
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		if(H.sanity_lost)
			say(pick("...The light's gone from your eyes.", "You stopped seeing it, didn't you?", "Nothing but grey now."))
			visible_message(span_danger("[src] executes [H] mercilessly!"))
			playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 75, TRUE)
			H.death()
	. = ..()

// Visual effects
/obj/effect/temp_visual/electric_sparks
	name = "electric sparks"
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity2"
	duration = 5
	layer = ABOVE_MOB_LAYER

#undef ABILITY_NONE
#undef ABILITY_DASH
#undef ABILITY_JUMP
#undef ABILITY_CIRCUIT

// Priest Fixer - Lauel / Redeemed Star
// A pacifist support/tank boss that protects allies via Lifelink

/mob/living/simple_animal/hostile/humanoid/fixer/priest
	name = "Redeemed Star"
	desc = "Too young to be called a man, but too mature to be called a boy. He had white hair and white skin. His eyes are calm and he had stubborn lips."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "priest"
	icon_living = "priest"
	faction = list("echo_office")
	gender = MALE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	density = FALSE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 4
	stat_attack = HARD_CRIT
	maxHealth = 2500
	health = 2500
	melee_damage_lower = 0
	melee_damage_upper = 0
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.8)
	a_intent = INTENT_HARM
	mob_size = MOB_SIZE_HUGE
	loot_armor = list(
		/obj/item/clothing/suit/armor/ego_gear/city/echo/stars,
	)

	// Lifelink System
	var/list/lifelinked_mobs = list()
	var/max_lifelinks = 4
	var/lifelink_range = 6
	var/list/lifelink_beams = list()
	var/lifelink_damage_reduction = 0.5

	// Feeble System (tracked as vars, not status effect)
	var/feeble_stacks = 0
	var/max_feeble_stacks = 5
	var/base_stagger_mult = 0.5
	var/feeble_stagger_bonus = 0.3
	var/feeble_decay_time = 10 SECONDS
	var/list/feeble_wisps = list()

	// Stagger System
	var/stagger_amount = 0
	var/max_stagger = 750
	var/stagger_decay_rate = 40
	var/stagger_decay_time = 2 SECONDS
	var/stagger_stun_duration = 5 SECONDS
	var/is_staggered = FALSE
	// Stagger resistance changes (more vulnerable when staggered)
	var/list/stagger_resistances = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 1.6)
	var/list/normal_resistances = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.8)

	// Intercept System
	var/counter_delay = 1.5 SECONDS
	var/counter_damage = 40
	var/counter_range = 2
	var/guard_sound = 'sound/weapons/purple_tear/guard.ogg'
	var/guard_sound_cooldown = 1 SECONDS
	var/last_guard_sound = 0
	var/intercept_count = 0
	var/intercepts_per_feeble = 2
	var/performing_counter = FALSE

	// Crisis Mode
	var/crisis_mode = FALSE
	var/crisis_power_boost = 0.3

	// Voice line cooldown
	var/last_voice_line = 0
	var/voice_line_cooldown = 4 SECONDS

	// Processing
	var/lifelink_update_timer
	var/stagger_decay_timer
	var/feeble_decay_timer
	/// Current stagger bar overlay reference
	var/mutable_appearance/current_stagger_bar

/mob/living/simple_animal/hostile/humanoid/fixer/priest/Initialize()
	. = ..()
	// Create wisps
	SpawnWisps()
	// Create stagger bar
	CreateStaggerBar()
	// Start processing timers
	lifelink_update_timer = addtimer(CALLBACK(src, PROC_REF(UpdateLifelinks)), 1 SECONDS, TIMER_LOOP|TIMER_STOPPABLE)
	stagger_decay_timer = addtimer(CALLBACK(src, PROC_REF(DecayStagger)), stagger_decay_time, TIMER_LOOP|TIMER_STOPPABLE)
	feeble_decay_timer = addtimer(CALLBACK(src, PROC_REF(DecayFeeble)), feeble_decay_time, TIMER_LOOP|TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/Destroy()
	// Clean up beams
	for(var/datum/beam/B in lifelink_beams)
		QDEL_NULL(B)
	lifelink_beams.Cut()
	// Clean up wisps
	for(var/obj/effect/wisp/W in feeble_wisps)
		QDEL_NULL(W)
	feeble_wisps.Cut()
	// Clean up timers
	deltimer(lifelink_update_timer)
	deltimer(stagger_decay_timer)
	deltimer(feeble_decay_timer)
	// Remove lifelinks from allies
	for(var/mob/living/M in lifelinked_mobs)
		M.remove_status_effect(/datum/status_effect/lifelinked)
	lifelinked_mobs.Cut()
	return ..()

// Voice line with cooldown check
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/TrySay(message)
	if(world.time < last_voice_line + voice_line_cooldown)
		return
	last_voice_line = world.time
	say(message)

// Wisps represent Feeble stacks (5 wisps = 0 stacks, 0 wisps = 5 stacks)
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/SpawnWisps()
	var/wisps_to_spawn = max_feeble_stacks - feeble_stacks
	// Remove existing wisps first
	for(var/obj/effect/wisp/W in feeble_wisps)
		qdel(W)
	feeble_wisps.Cut()
	// Spawn new wisps with delays so they spread out in orbit
	for(var/i in 1 to wisps_to_spawn)
		addtimer(CALLBACK(src, PROC_REF(SpawnSingleWisp)), (i - 1) * 3)  // 0.3 second delay between each

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/SpawnSingleWisp()
	if(stat == DEAD)
		return
	var/obj/effect/wisp/priest/W = new(get_turf(src))
	W.orbit(src, 20)
	feeble_wisps += W

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateWisps()
	var/target_wisps = max_feeble_stacks - feeble_stacks
	var/current_wisps = feeble_wisps.len
	if(target_wisps < current_wisps)
		// Remove wisps
		var/to_remove = current_wisps - target_wisps
		for(var/i in 1 to to_remove)
			if(feeble_wisps.len)
				var/obj/effect/wisp/W = feeble_wisps[feeble_wisps.len]
				feeble_wisps -= W
				qdel(W)
	else if(target_wisps > current_wisps)
		// Add wisps with delays so they spread out
		var/wisps_to_add = target_wisps - current_wisps
		for(var/i in 1 to wisps_to_add)
			addtimer(CALLBACK(src, PROC_REF(SpawnSingleWisp)), (i - 1) * 3)

// Stagger bar (inverted - shows stability remaining)
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CreateStaggerBar()
	current_stagger_bar = mutable_appearance('icons/effects/progessbar.dmi', "prog_bar_100", ABOVE_MOB_LAYER)
	current_stagger_bar.pixel_y = 32
	add_overlay(current_stagger_bar)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateStaggerBar()
	// Remove only the stagger bar overlay, preserve other overlays
	if(current_stagger_bar)
		cut_overlay(current_stagger_bar)
	var/stability_percent = round(((max_stagger - stagger_amount) / max_stagger) * 100, 5)
	stability_percent = clamp(stability_percent, 0, 100)
	current_stagger_bar = mutable_appearance('icons/effects/progessbar.dmi', "prog_bar_[stability_percent]", ABOVE_MOB_LAYER)
	current_stagger_bar.pixel_y = 32
	add_overlay(current_stagger_bar)

// Lifelink Management
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateLifelinks()
	if(stat == DEAD || is_staggered)
		return
	// Find potential allies to link
	var/list/potential_allies = list()
	for(var/mob/living/M in view(lifelink_range, src))
		if(M == src)
			continue
		if(M.stat == DEAD)
			continue
		if(!faction_check_mob(M, FALSE))
			continue
		if(M in lifelinked_mobs)
			continue
		potential_allies += M
	// Prioritize echo_office faction allies
	var/list/echo_allies = list()
	var/list/other_allies = list()
	for(var/mob/living/M in potential_allies)
		if(istype(M, /mob/living/simple_animal/hostile))
			var/mob/living/simple_animal/hostile/H = M
			if("echo_office" in H.faction)
				echo_allies += M
				continue
		other_allies += M
	// Add links up to max
	while(lifelinked_mobs.len < max_lifelinks && (echo_allies.len || other_allies.len))
		var/mob/living/to_link
		if(echo_allies.len)
			to_link = echo_allies[1]
			echo_allies -= to_link
		else if(other_allies.len)
			to_link = other_allies[1]
			other_allies -= to_link
		if(to_link)
			CreateLifelink(to_link)
	// Remove links to dead/distant allies
	for(var/mob/living/M in lifelinked_mobs)
		if(M.stat == DEAD || get_dist(src, M) > lifelink_range * 2)
			RemoveLifelink(M)
	// Update movement target to follow lowest HP ally
	FollowLowestHPAlly()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CreateLifelink(mob/living/ally)
	if(ally in lifelinked_mobs)
		return
	lifelinked_mobs += ally
	// Apply status effect to ally
	ally.apply_status_effect(/datum/status_effect/lifelinked, src)
	// Create beam
	var/datum/beam/B = Beam(ally, icon_state="medbeam", time=INFINITY, maxdistance=lifelink_range * 2, beam_type=/obj/effect/ebeam/medical)
	lifelink_beams[ally] = B

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/RemoveLifelink(mob/living/ally)
	if(!(ally in lifelinked_mobs))
		return
	lifelinked_mobs -= ally
	// Remove status effect
	ally.remove_status_effect(/datum/status_effect/lifelinked)
	// Remove beam
	if(lifelink_beams[ally])
		var/datum/beam/B = lifelink_beams[ally]
		qdel(B)
		lifelink_beams -= ally

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/RemoveAllLifelinks()
	for(var/mob/living/M in lifelinked_mobs)
		RemoveLifelink(M)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/FollowLowestHPAlly()
	if(!lifelinked_mobs.len)
		return
	var/mob/living/lowest_hp_ally
	var/lowest_hp_percent = 1
	for(var/mob/living/M in lifelinked_mobs)
		var/hp_percent = M.health / M.maxHealth
		if(hp_percent < lowest_hp_percent)
			lowest_hp_percent = hp_percent
			lowest_hp_ally = M
	if(lowest_hp_ally && lowest_hp_ally != target)
		// Follow the ally like the clan drone does
		target = lowest_hp_ally
		if(ai_controller)
			ai_controller.current_movement_target = target

// Called by lifelinked status effect when ally takes damage
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/OnAllyDamaged(mob/living/ally, damage, damage_type, mob/living/attacker)
	if(is_staggered || performing_counter)
		return FALSE
	// Teleport to ally
	var/turf/ally_turf = get_turf(ally)
	forceMove(ally_turf)
	// Play guard sound (with cooldown)
	if(world.time > last_guard_sound + guard_sound_cooldown)
		playsound(src, guard_sound, 75, TRUE)
		TrySay(pick("I'm here.", "It's alright.", "Don't worry, friend."))
		last_guard_sound = world.time
	// Apply reduced damage to self (no stagger)
	var/redirected_damage = damage * lifelink_damage_reduction
	ApplyLifelinkDamage(redirected_damage, damage_type)
	// Increment intercept count
	intercept_count++
	if(intercept_count >= intercepts_per_feeble)
		intercept_count = 0
		AddFeebleStack()
	// Start counter attack
	StartCounterAttack(attacker)
	return TRUE

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/ApplyLifelinkDamage(damage, damage_type)
	// Apply damage without triggering stagger
	switch(damage_type)
		if(RED_DAMAGE)
			adjustRedLoss(damage)
		if(WHITE_DAMAGE)
			adjustWhiteLoss(damage)
		if(BLACK_DAMAGE)
			adjustBlackLoss(damage)
		if(PALE_DAMAGE)
			adjustPaleLoss(damage)
		else
			adjustBruteLoss(damage)

// Don't move during counter attacks or when staggered
/mob/living/simple_animal/hostile/humanoid/fixer/priest/Move()
	if(performing_counter || is_staggered)
		return FALSE
	return ..()

// Counter Attack
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/StartCounterAttack(mob/living/attacker)
	performing_counter = TRUE
	// Add warning overlay to all turfs in counter range
	for(var/turf/T in range(counter_range, src))
		T.add_overlay(icon('icons/effects/effects.dmi', "galaxy_aura"))
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), icon('icons/effects/effects.dmi', "galaxy_aura")), counter_delay)
	// Visual telegraph on self
	new /obj/effect/temp_visual/cult/sparks(get_turf(src))
	// Delayed AoE counter
	addtimer(CALLBACK(src, PROC_REF(ExecuteCounterAttack)), counter_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/ExecuteCounterAttack()
	performing_counter = FALSE
	if(stat == DEAD || is_staggered)
		return
	var/actual_damage = counter_damage
	if(crisis_mode)
		actual_damage *= (1 + crisis_power_boost)
	// Deal damage to all enemies in range
	var/list/been_hit = list()
	TrySay(pick("Please, step back.", "I'd rather not do this.", "...If you insist."))
	playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 50, TRUE)
	for(var/turf/T in range(counter_range, src))
		new /obj/effect/temp_visual/cult/sparks(T)
		been_hit = HurtInTurf(T, been_hit, actual_damage, PALE_DAMAGE, check_faction = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_COUNTER))

// Stagger System
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/AddStagger(damage)
	if(is_staggered)
		return
	var/stagger_mult = base_stagger_mult + (feeble_stacks * feeble_stagger_bonus)
	stagger_amount += damage * stagger_mult
	UpdateStaggerBar()
	if(stagger_amount >= max_stagger)
		TriggerStagger()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/DecayStagger()
	if(is_staggered)
		return
	if(stagger_amount > 0)
		stagger_amount = max(0, stagger_amount - stagger_decay_rate)
		UpdateStaggerBar()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/TriggerStagger()
	is_staggered = TRUE
	stagger_amount = max_stagger
	UpdateStaggerBar()
	// Disconnect all lifelinks
	RemoveAllLifelinks()
	// Reset feeble stacks
	feeble_stacks = 0
	UpdateWisps()
	// Add stagger overlay and change resistances
	var/mutable_appearance/stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "small_stagger", layer + 0.1)
	add_overlay(stagger_overlay)
	ChangeResistances(stagger_resistances)
	say("...Ah. I see.")
	visible_message(span_danger("[src] staggers and falls to their knees!"))
	// Use SLEEP_CHECK_DEATH pattern
	SLEEP_CHECK_DEATH(stagger_stun_duration)
	// Recovery
	ChangeResistances(normal_resistances)
	cut_overlay(stagger_overlay)
	is_staggered = FALSE
	stagger_amount = 0
	UpdateStaggerBar()
	say("...Right. Let's continue, shall we?")
	visible_message(span_notice("[src] recovers their composure."))

// Feeble System
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/AddFeebleStack()
	if(feeble_stacks < max_feeble_stacks)
		feeble_stacks++
		UpdateWisps()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/DecayFeeble()
	if(feeble_stacks > 0)
		feeble_stacks--
		UpdateWisps()

// Crisis Mode
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CheckCrisisMode()
	if(crisis_mode)
		return
	if(health <= maxHealth * 0.25)
		EnterCrisisMode()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/EnterCrisisMode()
	crisis_mode = TRUE
	// Heal 50% of missing HP
	var/missing_hp = maxHealth - health
	var/heal_amount = missing_hp * 0.5
	adjustBruteLoss(-heal_amount)
	// Add wing overlays
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "breach", ABOVE_MOB_LAYER))
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "galaxy_aura", ABOVE_MOB_LAYER))
	say("Despite all the struggles, I shall remain myself...")
	visible_message(span_danger("Wings of light emerge from [src]'s back!"))

// Override damage handling
/mob/living/simple_animal/hostile/humanoid/fixer/priest/deal_damage(damage_amount, damage_type = BRUTE, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	// Only add stagger from direct damage (not lifelink)
	AddStagger(damage_amount)
	CheckCrisisMode()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	// Stagger is handled in deal_damage

/mob/living/simple_animal/hostile/humanoid/fixer/priest/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	// Stagger is handled in deal_damage

// Pacifist - no direct attacks
/mob/living/simple_animal/hostile/humanoid/fixer/priest/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/humanoid/fixer/priest/OpenFire()
	return FALSE

// Custom wisp subtype for the priest
/obj/effect/wisp/priest
	name = "light fragment"
	desc = "A gentle fragment of light orbiting the priest."
	light_range = 3

// Lifelinked status effect
/datum/status_effect/lifelinked
	id = "lifelinked"
	duration = -1
	alert_type = null
	var/mob/living/simple_animal/hostile/humanoid/fixer/priest/linked_priest

/datum/status_effect/lifelinked/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/humanoid/fixer/priest)
	linked_priest = priest
	return ..()

/datum/status_effect/lifelinked/on_apply()
	if(!linked_priest || QDELETED(linked_priest))
		return FALSE
	// Register damage signal
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnOwnerDamaged))
	// Visual indicator
	owner.add_overlay(mutable_appearance('icons/effects/effects.dmi', "shield1", -MUTATIONS_LAYER))
	return TRUE

/datum/status_effect/lifelinked/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	owner.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "shield1", -MUTATIONS_LAYER))
	linked_priest = null

/datum/status_effect/lifelinked/proc/OnOwnerDamaged(datum/source, damage, damage_type, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!linked_priest || QDELETED(linked_priest) || linked_priest.stat == DEAD)
		qdel(src)
		return
	// Get attacker
	var/mob/living/attacker
	if(isliving(attack_source))
		attacker = attack_source
	// Redirect damage to priest (use INVOKE_ASYNC to avoid sleep issues)
	INVOKE_ASYNC(src, PROC_REF(ProcessDamageRedirect), damage, damage_type, attacker)
	// Cancel damage on the ally
	return COMPONENT_MOB_DENY_DAMAGE

/datum/status_effect/lifelinked/proc/ProcessDamageRedirect(damage, damage_type, mob/living/attacker)
	if(!linked_priest || QDELETED(linked_priest) || linked_priest.stat == DEAD)
		return
	linked_priest.OnAllyDamaged(owner, damage, damage_type, attacker)
