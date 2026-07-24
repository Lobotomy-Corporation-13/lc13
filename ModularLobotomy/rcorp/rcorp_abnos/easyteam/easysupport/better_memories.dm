#define MEMORY_DEBUFF /datum/status_effect/display/rca_better_memories_curse
#define CAMERAFLASH_RANGE 7

/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion
	name = "Memories from a Better Time"
	desc = "A human with a old styled camera for a head and 8 slender spider legs. More nimble than it looks, however there's something about that camera that you are forgetting."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "better_memories_a"
	core_icon = "memories_egg"
	threat_level = HE_LEVEL
	base_pixel_x = -16
	pixel_x = -16
	health = 1000
	maxHealth = 1000
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.5)
	melee_damage_lower = 4
	melee_damage_upper = 8
	rapid_melee = 2
	move_to_delay = 2
	var/spawned = FALSE
	ranged = TRUE
	ranged_cooldown_time = 4 SECONDS
	attack_verb_continuous = "jabs"
	attack_verb_simple = "jab"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	//Youre a fragile little goon so you get privileges
	layer = MOB_LAYER
	a_intent = INTENT_HELP
	//But also a few cons
	ranged_ignores_vision = FALSE
	move_resist = MOVE_FORCE_DEFAULT
	pull_force = MOVE_FORCE_DEFAULT
	mob_size = MOB_SIZE_HUMAN

	abno_additional_instructions = "<h1>You are Memories from a Better Time, A Support Role Abnormality.</h1><br>\
		<b>|Reminiscence|: When possessed for the first time you will spawn a second instance of Memories from a Better Time.<br>\
		<br>\
		|Scattered Memories|: You have a 50% chance to dodge any projectiles that would have otherwise hit you. <br>\
		<br>\
		|Morii|: When attempting to perform a ranged attack you will take a picture in a 6 tile long cone. \
		Any hostiles hit by this attack will be inflicted with Nostalgia. <br>\
		<br>\
		|Nostalgia|: Those afflicted by this effect will take 10 white damage every 0.5 seconds and lose 30 stats in Temperance and Prudence. \
		Loss of stats may render one unable to use their weapon or vulnerable to other abnormalities which perform statchecks. \
		This effect will last until 15 seconds have passed or they have lost their sanity or life. \
		</b>"

//If one memories is taken a second one spawns
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/Login()
	..()
	SpawnMinion(get_turf(src))

/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/SpawnMinion(turf/spawn_turf)
	if(spawned)
		return
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/spawningmonster = new(spawn_turf)
	spawningmonster.spawned = TRUE
	spawned = TRUE



/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/Move()
	if(!can_act)
		return FALSE
	return ..()

//The creature can walk over entities that are human sized or smaller.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/CanPassThrough(atom/blocker, turf/target, blocker_opinion)
	if(isliving(blocker))
		var/mob/living/M = blocker
		if(M.mob_size <= MOB_SIZE_HUMAN)
			return TRUE
	return ..()

//Directional Cone Flash Attack that applies a work success and stat debuff.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/OpenFire()
	if(!can_act)
		return FALSE
	if(ranged_cooldown > world.time)
		return FALSE
	//Measure once.
	var/targ_dist = get_dist(src, target)
	if(!client && (targ_dist >= (CAMERAFLASH_RANGE - 1)))
		return FALSE
	if(!AngleCamera(target))
		if(!client)
			retreat_distance = null
			minimum_distance = 1
		return FALSE
	can_act = FALSE
	CameraFlash(src)
	ranged_cooldown = world.time + ranged_cooldown_time
	can_act = TRUE

/*
* If the target has the
* debuff ignore them unless they have done more than 50 damage
* to you.
*/
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/CanAttack(atom/the_target)
	. = ..()
	if(!ishuman(the_target))
		return
	var/mob/living/carbon/human/H = the_target
	if(H.has_status_effect(MEMORY_DEBUFF))
		//You have inflicted 100 damage to us. Get jabbed.
		if(target_memory[AddIdentifier(H)] <= 100)
			return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	if(!client)
		if(!target)
			GiveTarget(attacked_target)
		if(OpenFire())
			return
	return ..()

//Experiment with construct.dm code where the artificers have a melee range condition.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/MoveToTarget(list/possible_targets)
	. = ..()
	//If not human then attack with jabs
	if(!ishuman(target))
		retreat_distance = null
		minimum_distance = 1
		return
	else
		//If you are adjacent to me or my health is below 30%. Im going to jab you.
		if((((get_dist(get_turf(src), get_turf(target)) <= 1)) || health < maxHealth * 0.3))
			retreat_distance = null
			minimum_distance = 1
			return
	retreat_distance = 4
	minimum_distance = 4

/*
* This is embarrassing code i had 2 choices and it was to add
* a overridable proc in line 169 of hostile.dm to override the
* goto that i had put there or create this monster of a code.
* -IP
*/
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/bullet_act(obj/projectile/P)
	if(prob(50))
		visible_message(span_userdanger("[src] dodges the [P]!"))
		return BULLET_ACT_FORCE_PIERCE
	if(stat == CONSCIOUS && AIStatus != AI_OFF && !client)
		var/secondarmor = run_armor_check(null, P.damage_type, "","",P.armour_penetration)
		var/second_on_hit_state = P.on_hit(src, secondarmor)
		if(!P.nodamage && second_on_hit_state != BULLET_ACT_BLOCK)
			deal_damage(P.damage, P.damage_type, source = P.firer, attack_type = (ATTACK_TYPE_RANGED), blocked = secondarmor)
			apply_effects(P.stun, P.knockdown, P.unconscious, P.irradiate, P.slur, P.stutter, P.eyeblur, P.drowsy, secondarmor, P.stamina, P.jitter, P.paralyze, P.immobilize)
			//If the projectile had no firer then just list it as nobuddy
			if(isliving(P.firer))
				var/mob/living/L = P.firer
				//If our damage value for that person exceeds this number then we consider targeting them.
				if(target_memory[AddIdentifier(L)] > 100)
					FindTarget(list(L), 1)
			return second_on_hit_state
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/attacked_by(obj/item/I, mob/living/L)
	//Stolen MOSB code.
	if(!client && CanAttack(L))
		L.attack_animal(src)
	return ..()

//Prevents accumulation of hate when actively fleeing.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/RegisterAggroValue(atom/remembered_target, value, damage_type)
	if(!can_act)
		return
	..()

//This proc is for preventing the camera from firing at a target that is in its blind spot.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/AngleCamera(atom/cam_focus)
	switch(Get_Angle(src, cam_focus))
		//North 0 angle
		if(340 to 360)
			return TRUE
		if(0 to 20)
			return TRUE
		//South 180 angle
		if(160 to 200)
			return TRUE
		//East 90 angle
		if(70 to 110)
			return TRUE
		//West 270 angle
		if(250 to 290)
			return TRUE

	/*Attack code stolen from cone_spells.dm
	This proc creates a list of turfs that are hit by the cone */
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/CameraFlash(mob/living/user)
	var/blind_direction
	if(client)
		blind_direction = user.dir
	else
		blind_direction = get_cardinal_dir(get_turf(src), get_turf(target))
	var/list/cone_turfs = ConeHelper(get_turf(user), blind_direction)
	for(var/list/turf_list in cone_turfs)
		DoConeEffects(turf_list, user, TRUE)

	playsound(loc, 'sound/weapons/armbomb.ogg', 75, TRUE, -3)
	if(do_after(user, 1.5 SECONDS, target = user))
		for(var/list/turf_list in cone_turfs)
			DoConeEffects(turf_list, user, FALSE)
		playsound(loc, 'sound/effects/pop_expl.ogg', 75, TRUE, -3)

/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/ConeHelper(turf/starter_turf, dir_to_use, cone_levels = CAMERAFLASH_RANGE)
	var/list/turfs_to_return = list()
	var/turf/turf_to_use = starter_turf
	var/turf/left_turf
	var/turf/right_turf
	var/right_dir
	var/left_dir
	switch(dir_to_use)
		if(NORTH)
			left_dir = WEST
			right_dir = EAST
		if(SOUTH)
			left_dir = EAST
			right_dir = WEST
		if(EAST)
			left_dir = NORTH
			right_dir = SOUTH
		if(WEST)
			left_dir = SOUTH
			right_dir = NORTH

	for(var/i in 1 to cone_levels)
		if(i == 1)
			continue
		var/list/level_turfs = list()
		turf_to_use = get_step(turf_to_use, dir_to_use)
		level_turfs += turf_to_use
		if(i != 1)
			left_turf = get_step(turf_to_use, left_dir)
			level_turfs += left_turf
			right_turf = get_step(turf_to_use, right_dir)
			level_turfs += right_turf
			for(var/left_i in 1 to i -CalculateConeShape(i))
				if(left_turf.density)
					break
				left_turf = get_step(left_turf, left_dir)
				level_turfs += left_turf
			for(var/right_i in 1 to i -CalculateConeShape(i))
				if(right_turf.density)
					break
				right_turf = get_step(right_turf, right_dir)
				level_turfs += right_turf
		turfs_to_return += list(level_turfs)
		if(i == cone_levels)
			continue
		if(turf_to_use.density)
			break
	return turfs_to_return

	///This proc does obj, mob and turf cone effects on all targets in a list
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/DoConeEffects(list/target_turf_list, mob/user, telegraph)
	for(var/target_turf in target_turf_list)
		//if turf is no longer there
		if(!target_turf)
			continue
		if(telegraph)
			DoConeTurfEffects(target_turf, 1)
		if(!telegraph)
			DoConeTurfEffects(target_turf, 2)
			if(isopenturf(target_turf))
				var/turf/open/open_turf = target_turf
				for(var/mob/living/movable_content in open_turf)
					if(isliving(movable_content))
						DoConeMobEffect(movable_content)

	///This proc deterimines how the spell will affect turfs.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/DoConeTurfEffects(turf/target_turf, type)
	if(type == 1)
		new /obj/effect/temp_visual/sparkles/purple(target_turf)
	if(type == 2)
		new /obj/effect/temp_visual/dir_setting/ninja/phase(target_turf)

	///This proc deterimines how the spell will affect mobs.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/DoConeMobEffect(mob/living/target_mob)
	if(ishuman(target_mob))
		if(!faction_check_mob(target_mob))
			target_mob.flash_act()
			target_mob.apply_status_effect(MEMORY_DEBUFF)

	///This proc adjusts the cones width depending on the level.
/mob/living/simple_animal/hostile/rcorp_abno/easy/better_memories_minion/proc/CalculateConeShape(current_level)
	var/end_taper_start = round(CAMERAFLASH_RANGE * 0.8)
	if(current_level > end_taper_start)
		//someone more talented and probably come up with a better formula.
		return (current_level % end_taper_start) * 2
	else
		return 2

//Debuff Status Effect
/datum/status_effect/display/rca_better_memories_curse
	id = "rca_better_memories_curse"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	tick_interval = 50
	alert_type = null
	display_name = "down_arrow"

/datum/status_effect/display/rca_better_memories_curse/on_apply()
	. = ..()
	var/mob/living/carbon/human/L = owner
	L.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -30)
	L.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -30)
	to_chat(owner, span_warning("You're distracted by memories of your past. Your stats have been reduced and take constant WHITE damage."))

/datum/status_effect/display/rca_better_memories_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/L = owner
	if(L.sanity_lost || L.stat == DEAD)
		qdel(src)
	L.deal_damage(10, WHITE_DAMAGE, attack_type = (ATTACK_TYPE_STATUS))
	//Unsure if these statements explain what is happening to your character but its enough. -IP
	to_chat(owner, pick(
		span_warning("You have trouble recalling your life before this job."),
		span_warning("You forget your happiest moments."),
		span_warning("You wonder why your face is wet with tears."),
		span_warning("You try your best to hold onto the memory of your loved ones."),
		span_warning("You're forced to reminiscence on a happier time, then its gone."),
		))

/datum/status_effect/display/rca_better_memories_curse/on_remove()
	var/mob/living/carbon/human/L = owner
	L.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 30)
	L.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 30)
	return ..()

#undef MEMORY_DEBUFF
#undef CAMERAFLASH_RANGE
